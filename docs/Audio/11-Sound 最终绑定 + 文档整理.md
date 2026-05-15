## 1. trace_pipe 实锤：`snd_soc_lookup_component` 零命中

内存写入 `twrp_audio_runtime_defer.md`。

之前有一个半悬着的点：既然 `trace_pipe` 已经通了，就直接验证 reload 路径里到底有没有进入 `snd_soc_lookup_component`。如果仍然没有，就能更硬地说明失败点在 machine 私有组装里，而不是 ASoC 核心 component lookup。

```bash
adb -s 70a91f89 shell "mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; echo 1 > /sys/kernel/debug/tracing/tracing_on; for e in vr mp mr lk lkn lr rkn ln fd fr rr derr depr dr br pr; do echo 0 > /sys/kernel/debug/tracing/events/kprobes/\$e/enable 2>/dev/null; done; echo 1 > /sys/kernel/debug/tracing/events/kprobes/lk/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/lkn/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/lr/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/rkn/enable; rm -f /data/local/tmp/lk.out; cat /sys/kernel/debug/tracing/trace_pipe > /data/local/tmp/lk.out & tp=\$!; sleep 1; rmmod machine_dlkm; insmod /vendor/lib/modules/machine_dlkm.ko; sleep 2; kill \$tp; sleep 1; echo ===lookup-count===; grep -c -E ' lk: | lkn: | lr: | rkn: ' /data/local/tmp/lk.out; echo ===lookup-tail===; grep -E ' lk: | lkn: | lr: | rkn: ' /data/local/tmp/lk.out | tail -n 80"
```

**结论：** 这个点被坐实了——在 machine 重载的完整重放里，`snd_soc_lookup_component` 和 `_nolocked` 命中数都是 0。也就是说当前路径根本没走到 ASoC 核心 component lookup。失败点更明确地落在 machine 自己的私有组装逻辑。

文档 patch（29 行）写入 `TWRP音频手动Bring-up.md`。内存 `twrp_audio_runtime_defer.md` 更新。

继续推进后的新增硬结论有四条：

1. `sound` 这个 platform device 现在不是"没创建出来"，而是已经真实存在，但始终没有绑定到 `sun-asoc-snd`，并且一直挂在 deferred 队列里；同时 `waiting_for_supplier=0`，所以当前不是卡在 supplier 未就绪。
2. 手工重载 `machine_dlkm` 时，`msm_asoc_machine_probe` 会真实重新进入，而且能稳定跑过 Oplus/aw882xx 那段 dailink 扩展日志。
3. 用 `trace_pipe` 重新抓返回链后，当前路径再次坐实：
   `snd_soc_add_pcm_runtimes -> -517`
   `snd_soc_bind_card -> -517`
   `devm_snd_soc_register_card -> -517`
4. 同一次重放里，`snd_soc_find_dai` 一共返回了 72 次，空返回是 0，顺序还是只到 `rx_macro_rx1..5 + wcd939x_cdc`、`snd-soc-dummy-dai`、`msm-stub-rx/tx`，仍然没有进入 `rx_macro_rx6`。

还有一条非常关键的新负结果：单独抓了 `snd_soc_lookup_component` 和 `_nolocked`，命中数是 0。也就是说，当前失败路径甚至还没走到 ASoC 核心通用的 component lookup helper，失败点更像是在 machine 自己的私有 dailink/component 组装逻辑里就已经决定 defer 了。

下一步最值得做的，不再是继续盯 generic ASoC 核心，而是回到 machine_dlkm.ko 本体，按 `wsa-codec.* component is NULL`、`failed to add wcd9378 routes` 这组私有字符串去反推具体分支。

---

## 2. 离线反汇编：从私有字符串反推 helper 位置

转回离线模块本体，目标是把 `wsa-codec.* component is NULL` 和 `failed to add wcd9378 routes` 这些私有字符串，反推出对应 helper 和分支位置。

```bash
cd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" && "$READELF" -S machine_dlkm.ko | sed -n '1,200p'
```

```bash
cd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" && "$READELF" -r machine_dlkm.ko | rg -n "rodata|data\.ro|strtab|debug" | head -n 120
```

```bash
cd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" && strings -t x machine_dlkm.ko | rg "wsa-codec\.[1-4] component is NULL|failed to add wcd9378 routes|could not find component for lpass-cdc|could not find component for %s|component is NULL"
```

节布局已经清楚了：关键字符串都落在 `.rodata.str1.1`。下一步只需要把 `.rela.text` 里指向这些字符串的引用挖出来，就能知道是哪段代码在用它们。

按字符串在 `.rodata.str1.1` 里的节内偏移做精确交叉引用：

```bash
cd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" && "$READELF" -r machine_dlkm.ko | rg "\.rodata\.str1\.1 \+ (56|985|c8b|129d|1b00|1d33|23f2|2a05|2b9d)$"
```

```bash
cd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" && /Users/Laurie/.swiftly/bin/llvm-nm -an machine_dlkm.ko | rg "msm_asoc_machine_probe|populate_snd_card_dailinks|msm_populate_dai_link_component_of_node| add_qcom_wcd9378_routes|wcd9378"
```

精确匹配太严格，放宽成节内偏移关键字搜索：

```bash
cd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" && "$READELF" -r machine_dlkm.ko | rg "\.rodata\.str1\.1 \+ (56|985|c8b|129d|1b00|1d33|23f2|2a05|2b9d)\b"
```

换成 `llvm-objdump -dr`，它通常会把重定位直接贴在指令旁边：

```bash
cd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" && /Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump -dr machine_dlkm.ko | rg "\.rodata\.str1\.1\+0x(56|985|c8b|129d|1b00|1d33|23f2|2a05|2b9d)|\.rodata\.str1\.1 \+ (56|985|c8b|129d|1b00|1d33|23f2|2a05|2b9d)"
```

```bash
cd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" && /Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump -s -j .rodata.str1.1 machine_dlkm.ko | sed -n '1,220p'
```

`objdump -dr` 也没直接给出命中，先把 `.rodata.str1.1` 里这几段字符串周边读出来确认节内偏移计算没跑偏。

关键点找到了：这些日志字符串前面都带了一个不可见控制字节，所以真正的重定位偏移要比 `strings` 看到的起始字节再减 1。按修正后的节内偏移再查：

```bash
cd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" && "$READELF" --wide -r machine_dlkm.ko | rg "\.rodata\.str1\.1 \+ (55|984|c8a|129c|1aff|1d32|23f1|2a04|2b9c)\b"
```

xref 已经出来了。下一步把这些 `.text` 偏移周边反汇编出来：

```bash
cd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" && OBJ=/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump && for r in 0x1cf0:0x1d50 0x4f80:0x5010 0x5560:0x57c0 0x6b40:0x6f20 0x75c0:0x7610 0x7760:0x7790; do a=${r%:*}; b=${r#*:}; printf 'SECTION %s %s\n' "$a" "$b"; "$OBJ" -dr --no-show-raw-insn --start-address=$a --stop-address=$b machine_dlkm.ko; done
```

中间最大的 `0x6b40-0x6f20` 这段同时命中了 `wsa-codec.1/2/3/4` 和 `failed to add wcd9378 routes`。分析反汇编窗口（120-730 行）。

**结论：** `wsa-codec.2/3/4` 这组字符串都落在 `msm_int_wsa_init` / `msm_int_wsa2_init`，而且前面不是走 `snd_soc_lookup_component`，而是直接走 `snd_soc_rtdcom_lookup`。

进一步确认组件名字符串：

```bash
cd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" && strings -t x machine_dlkm.ko | rg "wsa-codec\.1$|wsa-codec\.2$|wsa-codec\.3$|wsa-codec\.4$|lpass-cdc$|wcd9378_codec$|rx_macro_rx6$|wcd939x_codec$|wcd939x_cdc$"
```

```bash
cd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" && "$READELF" --wide -r machine_dlkm.ko | rg "\.rodata\.str1\.1 \+ (4c4|7eb|984|bee|e38|129c|1445|1aff|1d32|2277|23f1|2422|2596|29f8|2a04|2ae7|2b9c)\b"
```

名字偏移也出来了。再定位 `failed to add wcd9378 routes` 完整上下文（反汇编 1-140 行），确认它在 `msm_rx_tx_codec_init` 的私有错误分支里。

文档 patch（49 行）写入 `TWRP音频手动Bring-up.md`。内存写入 `twrp_audio_component_gap.md`。

**该阶段核心结论：**

1. `wsa-codec.1..4 component is NULL` 这组错误，已经能明确落到 `msm_int_wsa_init` 和 `msm_int_wsa2_init`。
2. 这两个 helper 不是走 generic ASoC core 的 `snd_soc_lookup_component`，而是直接调用 `snd_soc_rtdcom_lookup` 去找 runtime component。
3. 模块里的 component 名字符串也已经对上：`wsa-codec.1`、`wsa-codec.2`、`wsa-codec.3`、`wsa-codec.4`。
4. 也就是说，当前 machine 路径里只要 runtime 没有这些 `wsa-codec.*`，这两个 helper 自己就会先报错并错误返回，根本不需要等 generic ASoC core 去失败。
5. `could not find component for lpass-cdc` 落在 `msm_common_dai_link_init` 和 `msm_rx_tx_codec_init` 周边。
6. `failed to add wcd9378 routes` 落在 `msm_rx_tx_codec_init` 的私有错误分支里。

---

## 3. 调用链追踪：`msm_int_wsa_init` / `msm_int_wsa2_init` 的调用点

把 `msm_int_wsa_init` / `msm_int_wsa2_init` 的调用点找出来，这样主线就能从"它们会失败"变成"谁在 machine 注册过程中调用了它们"。

```bash
cd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" && /Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump -dr --no-show-raw-insn machine_dlkm.ko | rg "CALL26\s+msm_int_wsa_init|CALL26\s+msm_int_wsa2_init|<msm_int_wsa_init>|<msm_int_wsa2_init>"
```

```bash
cd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" && /Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump -dr --no-show-raw-insn --start-address=0x198c --stop-address=0x2244 machine_dlkm.ko
```

整份窗口已经拉下来了，做文本定位找 `bl 0x67c4` 和 `bl 0x6c54`：

```bash
rg -n "bl\s+0x67c4|bl\s+0x6c54|<msm_int_wsa_init>|<msm_int_wsa2_init>" "/Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_RhxIIJf4W2R4tW4X945jozq2__vscode-1773326352404/content.txt"
```

这次窗口里没直接命中，改成全模块直接搜目标地址：

```bash
cd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" && /Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump -d --no-show-raw-insn machine_dlkm.ko | rg -n "67c4|6c54" | head -n 80
```

又往前推进了一层，而且这次已经不是"怀疑哪条线"，而是把私有 helper 对上了。

**主线现在可以更精确地说：**

1. 问题核心不在 generic ASoC 框架。
2. 当前最高优先级的失败 helper 是 `msm_int_wsa_init` / `msm_int_wsa2_init`。
3. `wcd9378 routes` 和 `lpass-cdc component` 仍然是同一段 machine 私有组装逻辑里的并列高价值分支。

---

## 4. 运行态 kprobe + 离线数据结构：WSA helper 结构性存在但未执行

继续把两条 WSA helper 往前推进一层：一边确认它们在运行态是否真的被调用、返回什么值，一边离线找谁把它们挂进 machine 的 dailink 结构里。

```bash
adb -s 70a91f89 shell 'grep -E "snd_soc_rtdcom_lookup|msm_int_wsa_init|msm_int_wsa2_init" /proc/kallsyms | head -n 40'
```

```bash
cd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" && "$READELF" --wide -r machine_dlkm.ko | rg "67c4|6c54|msm_int_wsa_init|msm_int_wsa2_init"
```

```bash
cd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" && /Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump -r machine_dlkm.ko | rg "67c4|6c54|msm_int_wsa_init|msm_int_wsa2_init"
```

引用已经有了，而且是 `ABS64`，这很像被直接塞进 dailink 结构体的函数指针。下一步直接解数据偏移附近的内容：

```bash
cd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" && "$READELF" -S machine_dlkm.ko | sed -n '16,24p'
```

```bash
cd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" && /Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump -s -j .data machine_dlkm.ko | sed -n '1,220p'
```

设置 kprobe 抓取 `msm_int_wsa_init` 和 `msm_int_wsa2_init` 的入口和返回：

```bash
adb -s 70a91f89 shell "mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; grep -q 'kprobes/wi .*msm_int_wsa_init' /sys/kernel/debug/tracing/kprobe_events || echo 'p:wi msm_int_wsa_init' >> /sys/kernel/debug/tracing/kprobe_events; grep -q 'kprobes/wr .*msm_int_wsa_init' /sys/kernel/debug/tracing/kprobe_events || echo 'r:wr msm_int_wsa_init ret=\$retval' >> /sys/kernel/debug/tracing/kprobe_events; grep -q 'kprobes/w2i .*msm_int_wsa2_init' /sys/kernel/debug/tracing/kprobe_events || echo 'p:w2i msm_int_wsa2_init' >> /sys/kernel/debug/tracing/kprobe_events; grep -q 'kprobes/w2r .*msm_int_wsa2_init' /sys/kernel/debug/tracing/kprobe_events || echo 'r:w2r msm_int_wsa2_init ret=\$retval' >> /sys/kernel/debug/tracing/kprobe_events; echo 1 > /sys/kernel/debug/tracing/tracing_on; for e in wi wr w2i w2r vr mp mr lk lkn lr rkn ln fd fr rr derr depr dr br pr; do echo 0 > /sys/kernel/debug/tracing/events/kprobes/\$e/enable 2>/dev/null; done; echo 1 > /sys/kernel/debug/tracing/events/kprobes/wi/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/wr/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/w2i/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/w2r/enable; rm -f /data/local/tmp/wsa.out; cat /sys/kernel/debug/tracing/trace_pipe > /data/local/tmp/wsa.out & tp=\$!; sleep 1; rmmod machine_dlkm; insmod /vendor/lib/modules/machine_dlkm.ko; sleep 2; kill \$tp; sleep 1; grep -E ' wi: | wr: | w2i: | w2r: ' /data/local/tmp/wsa.out | tail -n 120"
```

读取设备上的 wsa.out：

```bash
adb -s 70a91f89 shell "grep -E ' wi: | wr: | w2i: | w2r: ' /data/local/tmp/wsa.out | tail -n 120"
```

运行态抓取命令本身执行了，但工具输出被共享终端头部冲掉了。直接读设备上的原始 `wsa.out`，扩大筛选范围看完整内容：

```bash
adb -s 70a91f89 shell "grep -n 'msm_int_wsa\| wi: \| wr: \| w2i: \| w2r: ' /data/local/tmp/wsa.out | tail -n 120"
```

设备侧 `wsa.out` 里没有任何 WSA helper 事件。先读 `.data` 窗口确认函数指针是不是同一组 dailink 模板：

```bash
cd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" && /Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump -s -j .data --start-address=0x1e20 --stop-address=0x23c0 machine_dlkm.ko
```

按 `.data` 地址附近的符号名找最近的数据对象：

```bash
cd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" && /Users/Laurie/.swiftly/bin/llvm-nm -an machine_dlkm.ko | awk '$1 ~ /^[0-9a-f]+$/ {addr=strtonum("0x"$1); if (addr>=0x1800 && addr<=0x2900) print}'
```

确认 probe 注册和启用状态：

```bash
adb -s 70a91f89 shell 'cat /sys/kernel/debug/tracing/kprobe_events 2>/dev/null | grep -E "kprobes/(wi|wr|w2i|w2r)"'
```

```bash
adb -s 70a91f89 shell 'for e in wi wr w2i w2r; do echo ===$e===; cat /sys/kernel/debug/tracing/events/kprobes/$e/enable 2>/dev/null; done'
```

probe 已经确认挂上且 enable=1，所以 `wsa.out` 为空更像是这两个 helper 在当前 reload 路径下根本没执行。改用 perl 过滤地址把数据对象名补出来：

```bash
cd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" && /Users/Laurie/.swiftly/bin/llvm-nm -an machine_dlkm.ko | perl -ne 'if(/^([0-9a-f]+)\s+(\w)\s+(.*)$/){$a=hex($1); print if $a>=0x1800 && $a<=0x2900;}'
```

文档 patch（40 行）写入 `TWRP音频手动Bring-up.md`。内存 `twrp_audio_component_gap.md` 更新。

**该阶段核心结论：**

1. `msm_int_wsa_init` 和 `msm_int_wsa2_init` 确实不是死代码。
2. `.rela.data` 里已经能看到对 `.text + 0x67c4` 和 `.text + 0x6c54` 的 `ABS64` 引用，说明它们被挂进了 dailink 数据结构。
3. 按邻近数据符号看，这些引用至少部分落在：
   `msm_wsa2_cdc_dma_be_dai_links`
   `msm_wsa_wsa2_cdc_dma_be_dai_links`
   这一组 WSA 相关 dailink 模板附近。
4. 但运行态对这两个 helper 的 kprobe 已确认注册成功且 enable=1，在当前 `machine_dlkm` reload 重放路径下仍然完全没有命中。

**主线修正：**

1. machine 内部确实存在一整套 WSA component 依赖逻辑，这点已经被函数、字符串、数据结构三层同时坐实。
2. 但当前 recovery 这次实际走到的 defer 路径，未必真的已经进入那组 WSA dailink 模板。
3. 所以现在不能再直接说"当前这次 defer 就是 `msm_int_wsa_init/_wsa2_init` 当场触发的"。
4. 更合理的表述是：WSA 仍然是强结构性缺口证据，但当前更像是更早的私有组装路径先掉下去，尤其还是 `msm_rx_tx_codec_init` / `msm_common_dai_link_init` 这组更早执行的 helper。

---

## 5. 转攻更早私有 helper 路径：`msm_common_dai_link_init` / `msm_rx_tx_codec_init`

目标是把 `msm_common_dai_link_init`、`msm_rx_tx_codec_init` 和 `snd_soc_rtdcom_lookup` 的运行态调用顺序抓出来。

```bash
adb -s 70a91f89 shell 'grep -E "msm_common_dai_link_init|msm_rx_tx_codec_init|snd_soc_rtdcom_lookup" /proc/kallsyms | head -n 40'
```

挂载 kprobe 事件：

```bash
adb -s 70a91f89 shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; grep -q "kprobes/ci .*msm_common_dai_link_init" /sys/kernel/debug/tracing/kprobe_events || echo "p:ci msm_common_dai_link_init" >> /sys/kernel/debug/tracing/kprobe_events; grep -q "kprobes/cr .*msm_common_dai_link_init" /sys/kernel/debug/tracing/kprobe_events || echo "r:cr msm_common_dai_link_init ret=\$retval" >> /sys/kernel/debug/tracing/kprobe_events; grep -q "kprobes/ri .*msm_rx_tx_codec_init" /sys/kernel/debug/tracing/kprobe_events || echo "p:ri msm_rx_tx_codec_init" >> /sys/kernel/debug/tracing/kprobe_events; grep -q "kprobes/rrx .*msm_rx_tx_codec_init" /sys/kernel/debug/tracing/kprobe_events || echo "r:rrx msm_rx_tx_codec_init ret=\$retval" >> /sys/kernel/debug/tracing/kprobe_events; grep -q "kprobes/rc snd_soc_rtdcom_lookup" /sys/kernel/debug/tracing/kprobe_events || echo "p:rc snd_soc_rtdcom_lookup name=+0(\$arg2):string" >> /sys/kernel/debug/tracing/kprobe_events; grep -q "kprobes/rrc snd_soc_rtdcom_lookup" /sys/kernel/debug/tracing/kprobe_events || echo "r:rrc snd_soc_rtdcom_lookup ret=\$retval" >> /sys/kernel/debug/tracing/kprobe_events; cat /sys/kernel/debug/tracing/kprobe_events | grep -E "kprobes/(ci|cr|ri|rrx|rc|rrc)"'
```

用 `trace_pipe` 重放 `machine_dlkm`：

```bash
adb -s 70a91f89 shell "mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; echo 1 > /sys/kernel/debug/tracing/tracing_on; for e in ci cr ri rrx rc rrc wi wr w2i w2r vr mp mr lk lkn lr rkn ln fd fr rr derr depr dr br pr; do echo 0 > /sys/kernel/debug/tracing/events/kprobes/\$e/enable 2>/dev/null; done; echo 1 > /sys/kernel/debug/tracing/events/kprobes/ci/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/cr/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/ri/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/rrx/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/rc/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/rrc/enable; rm -f /data/local/tmp/priv.out; cat /sys/kernel/debug/tracing/trace_pipe > /data/local/tmp/priv.out & tp=\$!; sleep 1; rmmod machine_dlkm; insmod /vendor/lib/modules/machine_dlkm.ko; sleep 2; kill \$tp; sleep 1; echo ===helper-events===; grep -E ' ci: | cr: | ri: | rrx: ' /data/local/tmp/priv.out | tail -n 120; echo ===rtdcom-names===; grep ' rc: ' /data/local/tmp/priv.out | cut -d '\"' -f2 | nl -ba | tail -n 120; echo ===rtdcom-null===; grep 'rrc: ' /data/local/tmp/priv.out | grep -c 'ret=0x0'"
```

`priv.out` 里一个私有 helper 事件都没有，补一个对照组把 `msm_asoc_machine_probe` 和 `devm_snd_soc_register_card` 一起开上：

```bash
adb -s 70a91f89 shell "mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; echo 1 > /sys/kernel/debug/tracing/tracing_on; for e in ci cr ri rrx rc rrc mp mr dr br pr vr wi wr w2i w2r lk lkn lr rkn ln fd fr rr derr depr; do echo 0 > /sys/kernel/debug/tracing/events/kprobes/\$e/enable 2>/dev/null; done; echo 1 > /sys/kernel/debug/tracing/events/kprobes/mp/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/mr/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/dr/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/ci/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/cr/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/ri/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/rrx/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/rc/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/rrc/enable; rm -f /data/local/tmp/priv2.out; cat /sys/kernel/debug/tracing/trace_pipe > /data/local/tmp/priv2.out & tp=\$!; sleep 1; rmmod machine_dlkm; insmod /vendor/lib/modules/machine_dlkm.ko; sleep 2; kill \$tp; sleep 1; echo ===machine===; grep -E ' mp: | mr: | dr: ' /data/local/tmp/priv2.out | tail -n 40; echo ===private===; grep -E ' ci: | cr: | ri: | rrx: | rc: | rrc: ' /data/local/tmp/priv2.out | tail -n 80"
```

**结论：** 对照组说明这次 trace 是有效的——`msm_asoc_machine_probe` 和 `devm_snd_soc_register_card` 命中了，但 `msm_common_dai_link_init`、`msm_rx_tx_codec_init`、`snd_soc_rtdcom_lookup` 全都没命中。也就是说，当前这次实际 defer 还掉在比这些 helper 更早的位置。

补查符号表和 dmesg 确认是否有其他入口线索：

```bash
adb -s 70a91f89 shell 'grep -E "populate_snd_card_dailinks|msm_populate_dai_link_component_of_node|msm_populate_dai_link_component|populate_snd_card" /proc/kallsyms | head -n 80'
```

```bash
cd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" && /Users/Laurie/.swiftly/bin/llvm-nm -an machine_dlkm.ko | rg "populate_snd_card_dailinks|msm_populate_dai_link_component_of_node|msm_populate_dai_link_component"
```

```bash
adb -s 70a91f89 shell 'dmesg | tail -n 120 | grep -E "extend_codec_i2s_be_dailinks|extend_codec_be_dailink|msm_asoc_machine_probe"'
```

设备端隐藏符号查不到，dmesg 也没有额外 clue。改成离线从 `msm_asoc_machine_probe` 的反汇编里直接找本地 `bl` 目标：

```bash
cd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" && /Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump -d --no-show-raw-insn machine_dlkm.ko | rg -n "bl\s+0x198c|bl\s+0x5028|bl\s+0x67c4|bl\s+0x6c54|<msm_asoc_machine_probe>|<msm_common_dai_link_init>|<msm_rx_tx_codec_init>|<msm_int_wsa_init>|<msm_int_wsa2_init>"
```

```bash
cd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" && OBJ=/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump && "$OBJ" -d --no-show-raw-insn --start-address=0x2244 --stop-address=0x3a90 machine_dlkm.ko | rg -n "\bbl\b|<msm_asoc_machine_probe>" | head -n 240
```

读 `msm_asoc_machine_probe` 的 call 摘要。模块里的 `bl 自己` 往往只是未解析前的占位，真正目标要看 `.rela.text`。把 probe 区间的分支重定位拉出来还原实际 call 了谁：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && OBJ='/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump' && "$OBJ" -dr --no-show-raw-insn --start-address=0x2244 --stop-address=0x3a90 machine_dlkm.ko | rg 'R_AARCH64_(CALL26|JUMP26)|<msm_asoc_machine_probe>|\bbl\b'
```

读反汇编窗口（1-394 行）。

**结论：** `msm_asoc_machine_probe` 里没有别的早期私有 helper 了，只有 `msm_parse_upd_configuration`，最后直接 `devm_snd_soc_register_card`。所以真正的未知点已经收缩成"`register_card` 内部在处理哪条 dailink 时先 defer"。

尝试直接搜 ASoC core 源码和确认 tracing 能力：

```bash
adb -s 70a91f89 shell 'cat /sys/kernel/tracing/available_tracers'
```

```bash
adb -s 70a91f89 shell 'cat /sys/kernel/debug/tracing/available_tracers'
```

`function_graph` 这台机子不可用，只剩 kprobe 路线。

---

## 6. `msm_parse_upd_configuration` 反汇编和 probe call graph 确认

在拆开本地 helper 之前，先尝试从 kallsyms 和本地源码树找 ASoC core 符号和源码：

```bash
adb -s 70a91f89 shell 'cat /proc/kallsyms | grep -E "soc_bind_dai_link|snd_soc_add_pcm_runtime|snd_soc_add_pcm_runtimes|soc_init_dai_link" | head -n 40'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n 'snd_soc_add_pcm_runtimes|snd_soc_bind_card|soc_init_dai_link' twrp_a12_compile twrp_a16_compile -g '*.[ch]'
```

源码侧未命中，只能继续 kprobe 离线路线。拆开唯一的本地 helper `msm_parse_upd_configuration`，看它到底把哪些 backend dailink 塞进 card 里：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && OBJ='/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump' && "$OBJ" -dr --no-show-raw-insn --start-address=0x4574 --stop-address=0x5200 machine_dlkm.ko | head -n 260
```

读反汇编窗口（1-260 行）。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && strings -a machine_dlkm.ko | rg -n 'upd|backend|wsa|wcd9378|codec.*NULL|could not find component' | head -n 120
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && OBJ='/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump' && "$OBJ" -dr --no-show-raw-insn --start-address=0x34b0 --stop-address=0x3a90 machine_dlkm.ko
```

读 probe 后半段反汇编（1-505 行）。

**结论：** `probe` 后半段坐实了：`msm_parse_upd_configuration` 之后，只做了两次 phandle 解析、一个 `qcom,pri_mi2s_auxpcm` 之类的属性读取、可选的 `soc_aux_init_only_sia81xx`，然后立刻 `devm_snd_soc_register_card`。也就是说，当前 defer 确实不在 `probe` 显式代码里，而是在 card 注册阶段吃进去的数据表里。

用 `llvm-nm` 和重定位表进一步确认数据符号：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && /Users/Laurie/.swiftly/bin/llvm-nm -n machine_dlkm.ko | rg ' upd|wsa.*dai_links|wcd9378|msm_set_upd_config|msm_parse_upd_configuration'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && OBJ='/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump' && "$OBJ" -r machine_dlkm.ko | rg '0000000000004e(b8|e0|f08|f30|f58)|0000000000001de8|0000000000002328|00000000000027d0|00000000000067c4|0000000000006c54|0000000000005028|000000000000198c'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && RE='/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-readelf' && "$RE" -x .data machine_dlkm.ko | rg '0x00004e|0x00004f|0x00001de0|0x00002320|0x000027d0'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && RE='/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-readelf' && "$RE" -r machine_dlkm.ko | rg '4eb8|4ec0|4ec8|4ed0|4ed8|4ee0|4ef0|4f00|4f10|4f20|4f30|4f40|4f50|4f60'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && OBJ='/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump' && "$OBJ" -dr --no-show-raw-insn --start-address=0x72d0 --stop-address=0x7700 machine_dlkm.ko
```

读反汇编窗口（1-260 行）。

**新的收敛点：** `probe` 显式 call graph 里只有 `msm_parse_upd_configuration` 和最终 `devm_snd_soc_register_card`，没有直接打到 `msm_common_dai_link_init` / `msm_rx_tx_codec_init` / `msm_int_wsa*_init`。这会把后续 tracing 的重点从"继续找 probe 里的私有 helper"转成"抓 register_card 内部正在消费哪条 link"。

文档 patch（48 行）写入 `TWRP音频手动Bring-up.md`。内存 `twrp_audio_runtime_defer.md` 和 `twrp_audio_component_gap.md` 更新。

---

## 7. `snd_soc_link_init` / `soc_new_pcm` 边界验证：defer 发生在 link init 之前

直接验证"是不是连 `link_init` / `soc_new_pcm` 都没走到"。如果这两个 core 边界在重放里完全不命中，就能把当前 defer 位置正式钉在"link init callback 之前"。

提前确认是否有可用的 kallsyms 符号和结构体定义：

```bash
adb -s 70a91f89 shell 'cat /proc/kallsyms | grep -i pcm_runtime | head -n 40'
```

```bash
adb -s 70a91f89 shell 'cat /proc/kallsyms | grep -E "snd_soc_(get|remove)_pcm_runtime|soc_new_pcm|soc_probe_link|soc_link_init|dai_link" | head -n 80'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n 'struct snd_soc_pcm_runtime|struct snd_soc_dai_link \{' twrp_a12_compile twrp_a16_compile -g '*.[ch]' | head -n 40
```

本地树里没有 ASoC 头定义。直接开始边界验证：

```bash
S=70a91f89
adb -s $S shell 'T=/sys/kernel/debug/tracing; : > $T/trace; : > $T/kprobe_events; echo p:kprobes/li snd_soc_link_init >> $T/kprobe_events; echo r:kprobes/lr snd_soc_link_init ret=\$retval >> $T/kprobe_events; echo p:kprobes/np soc_new_pcm >> $T/kprobe_events; echo r:kprobes/nr soc_new_pcm ret=\$retval >> $T/kprobe_events; echo r:kprobes/dr devm_snd_soc_register_card ret=\$retval >> $T/kprobe_events; for e in li lr np nr dr; do echo 1 > $T/events/kprobes/$e/enable; done; echo 1 > $T/tracing_on'
adb -s $S shell 'cat /sys/kernel/debug/tracing/trace_pipe' > /tmp/twrp_asoc_stage.out &
TP=$!
sleep 1
adb -s $S shell 'rmmod machine_dlkm; insmod /vendor/lib/modules/machine_dlkm.ko'
sleep 2
kill $TP
wait $TP 2>/dev/null
adb -s $S shell 'echo 0 > /sys/kernel/debug/tracing/tracing_on'
cat /tmp/twrp_asoc_stage.out | grep -E 'kprobes/(li|lr|np|nr|dr)'
```

本地采集命令被终端改写了，改成分步用工作区文件重跑：

```bash
S=70a91f89
adb -s $S shell 'T=/sys/kernel/debug/tracing; echo 0 > $T/tracing_on; : > $T/trace; : > $T/kprobe_events; echo p:kprobes/li snd_soc_link_init >> $T/kprobe_events; echo r:kprobes/lr snd_soc_link_init ret=\$retval >> $T/kprobe_events; echo p:kprobes/np soc_new_pcm >> $T/kprobe_events; echo r:kprobes/nr soc_new_pcm ret=\$retval >> $T/kprobe_events; echo r:kprobes/dr devm_snd_soc_register_card ret=\$retval >> $T/kprobe_events; for e in li lr np nr dr; do echo 1 > $T/events/kprobes/$e/enable; done; echo 1 > $T/tracing_on'
```

```bash
rm -f '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/asoc_stage.out'
```

```bash
S=70a91f89
adb -s $S shell 'T=/sys/kernel/debug/tracing; echo 0 > $T/tracing_on; : > $T/trace; : > $T/kprobe_events'
```

```bash
S=70a91f89
adb -s $S shell 'T=/sys/kernel/debug/tracing; echo p:kprobes/li snd_soc_link_init >> $T/kprobe_events; echo r:kprobes/lr snd_soc_link_init ret=\$retval >> $T/kprobe_events; echo p:kprobes/np soc_new_pcm >> $T/kprobe_events; echo r:kprobes/nr soc_new_pcm ret=\$retval >> $T/kprobe_events; echo r:kprobes/dr devm_snd_soc_register_card ret=\$retval >> $T/kprobe_events'
```

确认 kprobe 事件注册：

```bash
adb -s 70a91f89 shell 'cat /sys/kernel/debug/tracing/kprobe_events'
```

修正事件名（`lr` 已存在时改用 `lx`）并启用：

```bash
adb -s 70a91f89 shell 'T=/sys/kernel/debug/tracing; echo r:kprobes/lx snd_soc_link_init ret=\$retval >> $T/kprobe_events; for e in li lx np nr dr; do echo 1 > $T/events/kprobes/$e/enable; done; echo 1 > $T/tracing_on'
```

采集 trace：

```bash
adb -s 70a91f89 shell 'cat /sys/kernel/debug/tracing/trace_pipe' > '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/asoc_stage.out'
```

触发 reload：

```bash
adb -s 70a91f89 shell 'rmmod machine_dlkm; insmod /vendor/lib/modules/machine_dlkm.ko'
```

kill trace_pipe 后过滤结果：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && rg 'kprobes/(li|lx|np|nr|dr)' asoc_stage.out
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && wc -l asoc_stage.out && head -n 20 asoc_stage.out
```

**结论：** 重放结果出来了，而且是硬证据——同一轮里 `devm_snd_soc_register_card -> -517` 命中了，但 `snd_soc_link_init` 和 `soc_new_pcm` 完全没命中。这样就不是"推测早于 link init"，而是已经被运行态钉死了。

文档 patch（23 行）写入 `TWRP音频手动Bring-up.md`。内存 `twrp_audio_runtime_defer.md` 更新。

**该阶段最准确的表述：**

1. 问题不在 `msm_asoc_machine_probe` 的显式前半段。
2. 问题也还没走到 link init callback 或 new pcm。
3. 真正未知点已经收缩为 `devm_snd_soc_register_card -> snd_soc_bind_card -> snd_soc_add_pcm_runtimes` 这段内部，在消费某条 dailink/component 组合时先回了 `-EPROBE_DEFER`。

---

## 8. 抓 dailink 名：`snd_soc_card_add_dai_link` 和 `snd_soc_find_dai`

先把 `snd_soc_add_pcm_runtimes` 之前还能命中的 core 符号边界再缩一圈，目标是找出"早于 `link_init/new_pcm` 的最后一个可见函数"。

```bash
adb -s 70a91f89 shell 'grep -E "snd_soc_(bind_card|add_pcm_runtimes|get_pcm_runtime|link_init)|soc_(new_pcm|dai_link_sanity_check|add_dai_link|init_dai_link|remove_pcm_runtime)" /proc/kallsyms | head -n 80'
```

能见到的早期 core 符号有限，转从机器驱动字符串侧找 UPD backend 选择逻辑：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && strings -a machine_dlkm.ko | rg -n 'Invalid backend|failed to get backend name|upd static configuration|wsa-max-devs|dedicated-wsa2|backend_id' | head -n 80
```

本地找 BE dailink 数组符号，确认总装顺序：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && /Users/Laurie/.swiftly/bin/llvm-nm -n machine_dlkm.ko | rg 'msm_rx_cdc_dma_be_dai_links|msm_common_be_dai_links|msm_stub_be_dai_links|msm_wsa_cdc_dma_be_dai_links|msm_wsa2_cdc_dma_be_dai_links|msm_wsa_wsa2_cdc_dma_be_dai_links|ext_disp_be_dai_link|msm_tx_cdc_dma_be_dai_links|msm_va_cdc_dma_be_dai_links'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && RE='/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-readelf' && "$RE" -Ws machine_dlkm.ko | rg 'msm_rx_cdc_dma_be_dai_links|msm_common_be_dai_links|msm_stub_be_dai_links|msm_wsa_cdc_dma_be_dai_links|msm_wsa2_cdc_dma_be_dai_links|msm_wsa_wsa2_cdc_dma_be_dai_links|ext_disp_be_dai_link|msm_tx_cdc_dma_be_dai_links|msm_va_cdc_dma_be_dai_links'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && strings -a machine_dlkm.ko | rg -n 'CODEC_DMA-LPAIF_RXTX-RX-[1-9]|CODEC_DMA-LPAIF_RXTX-TX-[1-9]|WSA|wsa|stub|BT|VA|AUXPCM|TDM' | head -n 200
```

**关键信号：** 这些 BE 数组的尺寸都像是固定 `224` 字节一条 `snd_soc_dai_link`。这意味着 `msm_rx_cdc_dma_be_dai_links` 正好只有 `5` 条，和运行态只走到 `RX-1..RX-5` 完整对上。

确认总装时到底拼了哪些数组：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && /Users/Laurie/.swiftly/bin/llvm-nm -n machine_dlkm.ko | rg 'msm_sun_dai_links|msm_stub_dai_links|populate_snd_card_dailinks|num_links|snd_soc_card(_stub)?_msm|snd_soc_card_msm'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && RE='/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-readelf' && "$RE" -Ws machine_dlkm.ko | rg 'msm_sun_dai_links|msm_stub_dai_links|populate_snd_card_dailinks|snd_soc_card_stub_msm|snd_soc_card_msm'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && OBJ='/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump' && "$OBJ" -r machine_dlkm.ko | rg 'msm_sun_dai_links|msm_stub_dai_links|populate_snd_card_dailinks|snd_soc_card_stub_msm|snd_soc_card_msm'
```

`msm_sun_dai_links` 不是静态填好的只读表，它在 `.bss`，说明 probe 里是运行时拼出来的。反查是谁在往这个大数组里灌各个分组：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && OBJ='/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump' && "$OBJ" -r machine_dlkm.ko | rg '\.bss\+0x400|\.bss\+0x43e0|populate_snd_card_dailinks\.\_rs'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && OBJ='/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump' && "$OBJ" -dr --no-show-raw-insn --start-address=0x3000 --stop-address=0x34b0 machine_dlkm.ko | head -n 260
```

读反汇编窗口（1-260 行）。

---

## 9. 直接抓 `snd_soc_card_add_dai_link` 的 link name

源码侧补齐后，方向已经变了：可以直接在 `snd_soc_card_add_dai_link(card, link)` 入口抓 `link->name`。它发生在 `sanity_check` 之前，正好能把"最后一个进入的 dailink 名"抓出来。

```bash
adb -s 70a91f89 shell 'grep snd_soc_card_add_dai_link /proc/kallsyms'
```

设置抓取探针：

```bash
adb -s 70a91f89 shell 'T=/sys/kernel/debug/tracing; echo 0 > $T/tracing_on; : > $T/trace; : > $T/kprobe_events; echo p:kprobes/ad snd_soc_card_add_dai_link name=+0($arg2):string >> $T/kprobe_events; echo p:kprobes/fd snd_soc_find_dai dname=+0(+16($arg1)):string >> $T/kprobe_events; echo r:kprobes/pr snd_soc_add_pcm_runtimes ret=\$retval >> $T/kprobe_events; echo r:kprobes/br snd_soc_bind_card ret=\$retval >> $T/kprobe_events; echo r:kprobes/dr devm_snd_soc_register_card ret=\$retval >> $T/kprobe_events; for e in ad fd pr br dr; do echo 1 > $T/events/kprobes/$e/enable; done; echo 1 > $T/tracing_on'
```

用户在此要求记录当前方法和技巧到文档，然后继续。文档 patch（80 行）写入 `TWRP音频手动Bring-up.md`，补上三块内容：当前主线、源码对齐探针方向、用 `224` 字节步长反推 dailink 组规模。

清理 kprobe_events 并重新设置（用双引号避免 quoting 问题）：

```bash
adb -s 70a91f89 shell "T=/sys/kernel/debug/tracing; echo 0 > \$T/tracing_on; : > \$T/trace; : > \$T/kprobe_events"
```

```bash
adb -s 70a91f89 shell "T=/sys/kernel/debug/tracing; echo 'p:kprobes/ad snd_soc_card_add_dai_link name=+0(\$arg2):string' >> \$T/kprobe_events; echo 'p:kprobes/fd snd_soc_find_dai dname=+0(+16(\$arg1)):string' >> \$T/kprobe_events; echo 'r:kprobes/pr snd_soc_add_pcm_runtimes ret=\$retval' >> \$T/kprobe_events; echo 'r:kprobes/br snd_soc_bind_card ret=\$retval' >> \$T/kprobe_events; echo 'r:kprobes/dr devm_snd_soc_register_card ret=\$retval' >> \$T/kprobe_events"
```

```bash
adb -s 70a91f89 shell "cat /sys/kernel/debug/tracing/kprobe_events | tail -n 8"
```

启用现成事件并采一次最小 trace：

```bash
adb -s 70a91f89 shell "T=/sys/kernel/debug/tracing; for e in ad fd pr br dr; do echo 1 > \$T/events/kprobes/\$e/enable; done; echo 1 > \$T/tracing_on"
```

```bash
rm -f '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/dailink_order.out'
```

```bash
adb -s 70a91f89 shell 'cat /sys/kernel/debug/tracing/trace_pipe' > '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/dailink_order.out'
```

```bash
adb -s 70a91f89 shell 'rmmod machine_dlkm; insmod /vendor/lib/modules/machine_dlkm.ko'
```

Kill trace_pipe 后过滤：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && wc -l dailink_order.out && rg 'kprobes/(ad|fd|pr|br|dr)' dailink_order.out | tail -n 120
```

采集到了 104 行但 `rg` 过滤没打出来，说明格式跟前面预期不一样。直接读原始尾部：

读 `dailink_order.out` 文件。

```bash
adb -s 70a91f89 shell "T=/sys/kernel/debug/tracing; echo 0 > \$T/tracing_on"
```

**结果：** `ad` 事件每次都正好夹在一组 `find_dai` 之前，说明探针点选对了，只是参数索引拿错了。`snd_soc_card_add_dai_link(card, link)` 里真正的 `link` 应该抓 `$arg1`。改成新事件名重跑：

```bash
adb -s 70a91f89 shell "echo 'p:kprobes/a1 snd_soc_card_add_dai_link name=+0(\$arg1):string' >> /sys/kernel/debug/tracing/kprobe_events"
```

```bash
adb -s 70a91f89 shell "T=/sys/kernel/debug/tracing; echo 1 > \$T/events/kprobes/a1/enable; echo 1 > \$T/events/kprobes/fd/enable; echo 1 > \$T/events/kprobes/pr/enable; echo 1 > \$T/events/kprobes/br/enable; echo 1 > \$T/events/kprobes/dr/enable; echo 1 > \$T/tracing_on"
```

```bash
rm -f '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/dailink_order2.out'
```

---

## 10. 反汇编技巧记录 + `DISPLAY_PORT-RX-0` 边界发现

用户要求把反汇编的技巧记录下来。

文档 patch（93 行）写入 `TWRP音频手动Bring-up.md`，补上反汇编方法本身和 `DISPLAY_PORT-RX-0` 这个新边界。

沿 `DISPLAY_PORT-RX-0` 继续推进，查 ext display audio codec 为什么有设备但没有 ASoC component：

```bash
adb -s 70a91f89 shell 'D=/sys/devices/platform/soc/soc:spf_core_platform/qcom,msm-ext-disp; find $D -maxdepth 3 \( -name qcom,msm-ext-disp-audio-codec-rx -o -name modalias -o -name driver -o -name uevent \) 2>/dev/null | sed -n "1,80p"'
```

```bash
adb -s 70a91f89 shell 'grep -R "qcom,msm-ext-disp-audio-codec-rx" /vendor/lib/modules 2>/dev/null | head -n 40'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && strings -a machine_dlkm.ko | rg -n 'DISPLAY_PORT-RX-0|msm_dp_audio_codec_rx_dai|qcom,msm-ext-disp-audio-codec-rx|msm-ext-disp' | head -n 80
```

刚才那组三个检查都没直接回内容，说明不是“明确不存在”，更像是路径/命令打得还不够准。直接反过来全局找 `qcom,msm-ext-disp-audio-codec-rx` 设备节点，再顺着它读 `modalias` 和 `driver`。

```bash
adb -s 70a91f89 shell 'find /sys/devices -name qcom,msm-ext-disp-audio-codec-rx 2>/dev/null | sed -n "1,20p"'
```

```bash
adb -s 70a91f89 shell 'find /sys/devices -name msm-ext-disp\* 2>/dev/null | sed -n "1,40p"'
```

```bash
adb -s 70a91f89 shell 'cat /vendor/lib/modules/modules.alias 2>/dev/null | grep -n "msm-ext-disp\|ext-disp\|audio-codec-rx" | sed -n "1,40p"'
```

全局 `find` 和 `modules.alias` 也没回内容，这反而更像命名并不在普通平台设备路径里。我再从平台总线和运行态 DT 两头各补一刀，确认这个 component 到底是“设备没枚举”还是“枚举了但名字不一样”

```bash
adb -s 70a91f89 shell 'ls /sys/bus/platform/devices 2>/dev/null | grep -n "ext\|disp\|dp" | sed -n "1,80p"'
```

```bash
adb -s 70a91f89 shell 'find /proc/device-tree -name "*ext*disp*" -o -name "*audio*codec*rx*" 2>/dev/null | sed -n "1,80p"'
```

```bash
adb -s 70a91f89 shell 'cat /sys/kernel/debug/asoc/components 2>/dev/null | grep -n "disp\|dp\|hdmi" | sed -n "1,40p"'
```

运行态没看到任何 `dp/disp/hdmi` component，这已经很像“这条 codec 根本没注册成 ASoC component”。我接着从模块侧补证据，看看 `msm_ext_display` / `snd_soc_hdmi_codec` 到底声明了什么符号和 alias。

```bash
adb -s 70a91f89 shell 'ls /vendor/lib/modules 2>/dev/null | grep -n "disp\|dp\|hdmi" | sed -n "1,80p"'
```

```bash
adb -s 70a91f89 shell 'cat /proc/modules | grep -n "disp\|dp\|hdmi" | sed -n "1,80p"'
```

离线这边已经把 `ext_disp_be_dai_link` 的字段引用点打出来了，我现在把那些 `.rodata` 偏移直接解成字符串，这样就能把 `DISPLAY_PORT-RX-0` 的静态组成在文档里写得更硬。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && OBJ='/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump' && "$OBJ" -r machine_dlkm.ko | rg '0000000000003410|0000000000003418|0000000000003420|0000000000003428|0000000000003430|0000000000003438|0000000000003440|0000000000003448'
```

把 `.rodata` 偏移解成字符串：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && strings -a -t x machine_dlkm.ko | rg ' 774 | 11c3 | 3a1 |40e0|4100|4120|DISPLAY_PORT-RX-0|msm_dp_audio_codec_rx_dai|qcom,msm-ext-disp-audio-codec-rx|snd-soc-dummy'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && RE='/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-readelf' && "$RE" -x .data machine_dlkm.ko | rg '0x000040e0|0x00004100|0x00004120'
```

**字符串已对上：** `DISPLAY_PORT-RX-0`、`msm_dp_audio_codec_rx_dai`、`soc:qcom,msm-ext-disp:qcom,msm-ext-disp-audio-codec-rx`、`snd-soc-dummy` 都在模块里。

补 `.rela.data` 交叉引用确认：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && RE='/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-readelf' && "$RE" -r machine_dlkm.ko | rg '00000000000040e0|0000000000004100|0000000000004120|0000000000003410|0000000000003418|0000000000003420|0000000000003430|0000000000003448'
```

```bash
adb -s 70a91f89 shell 'cat /sys/kernel/debug/devices_deferred 2>/dev/null | sed -n "1,120p"'
```

**结论：** `DISPLAY_PORT-RX-0` 这条静态链已经够硬了，deferred 列表里仍然只有 `sound`。

继续从模块字符串侧找 `msm_dp_audio_codec_rx_dai` 和 ext display codec 名，目的是定位真正应该提供这个 component 的模块。

---

## 11. 追踪 ext display codec 模块：`msm_ext_display.ko` / `snd-soc-hdmi-codec.ko` / `hdmi_dlkm.ko`

在设备端找 `msm_dp_audio_codec_rx_dai` 对应的模块：

```bash
adb -s 70a91f89 shell 'grep -R "msm_dp_audio_codec_rx_dai" /vendor/lib/modules 2>/dev/null | sed -n "1,40p"'
```

```bash
adb -s 70a91f89 shell 'grep -R "qcom,msm-ext-disp-audio-codec-rx" /vendor/lib/modules 2>/dev/null | sed -n "1,40p"'
```

```bash
adb -s 70a91f89 shell 'grep -R "snd_soc_hdmi_codec\|msm_ext_display" /vendor/lib/modules 2>/dev/null | sed -n "1,60p"'
```

设备端直接 grep 二进制没出结果，换成本地工作区找：

```bash
rg 'msm_dp_audio_codec_rx_dai|qcom,msm-ext-disp-audio-codec-rx|snd_soc_hdmi_codec|msm_ext_display' /Volumes/Case-sensitive\ APFS/TWRP/audio_dtb_probe/vendor_modules/
```

（等价于用 find 找到 `*ext*disp*` 和 `*hdmi*codec*` 文件，然后用 rg 搜索这些字符串）

本地已找到两个关键模块：`msm_ext_display.ko` 和 `snd-soc-hdmi-codec.ko`。直接做字符串和 alias 检查，看看谁该提供 `DISPLAY_PORT-RX-0` 对应 component。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/vendor_modules' && strings -a msm_ext_display.ko | rg -n 'msm_dp_audio_codec_rx_dai|qcom,msm-ext-disp-audio-codec-rx|snd_soc|component|audio-codec|ext-disp' | sed -n '1,120p'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/vendor_modules' && strings -a snd-soc-hdmi-codec.ko | rg -n 'msm_dp_audio_codec_rx_dai|qcom,msm-ext-disp-audio-codec-rx|hdmi|dp_audio|snd_soc|component' | sed -n '1,120p'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/vendor_modules' && RE='/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-readelf' && "$RE" -p .modinfo msm_ext_display.ko snd-soc-hdmi-codec.ko | sed -n '1,200p'
```

**关键不对位：** `msm_ext_display.ko` 只认 `qcom,msm-ext-disp`，`snd-soc-hdmi-codec.ko` 只认 `platform:hdmi-audio-codec`。

补交叉检查看 `msm_ext_display.ko` 有没有创建/引用 `hdmi-audio-codec` 这条桥：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/vendor_modules' && strings -a msm_ext_display.ko | rg -n 'hdmi-audio-codec|hdmi_codec|audio-codec-rx|msm_dp_audio_codec_rx_dai|platform_device|of_platform' | sed -n "1,120p"
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/vendor_modules' && /Users/Laurie/.swiftly/bin/llvm-nm -n msm_ext_display.ko | rg 'hdmi|audio|codec|platform|of' | sed -n "1,120p"
```

```bash
adb -s 70a91f89 shell 'cat /sys/kernel/debug/asoc/dais 2>/dev/null | grep -n "hdmi\|dp_audio\|display" | sed -n "1,40p"'
```

**新线索：** msm_ext_display.ko 自己就带着 `msm_ext_disp_register_audio_codec` / `msm_hdmi_register_audio_codec` / `msm_ext_disp_select_audio_codec` 这组音频桥接符号。这说明 `DISPLAY_PORT-RX-0` 更像是 ext display 注册链没走通，而不是 machine 自己凭空引用了一个不存在的 codec。再补一刀看 snd-soc-hdmi-codec.ko 是否和这组符号对接。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/vendor_modules' && /Users/Laurie/.swiftly/bin/llvm-nm -n snd-soc-hdmi-codec.ko | rg 'msm_ext_disp|hdmi_register_audio_codec|register_audio_codec|select_audio_codec|hdmi-audio-codec' | sed -n "1,120p"
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/vendor_modules' && strings -a snd-soc-hdmi-codec.ko | rg -n 'msm_ext_disp|hdmi-audio-codec|msm_dp_audio_codec_rx_dai|select_audio_codec|register_audio_codec' | sed -n "1,120p"
```

```bash
adb -s 70a91f89 shell 'cat /proc/modules | grep -n "snd_soc_hdmi_codec\|msm_ext_display" | sed -n "1,40p"'
```

**关键发现：** msm_ext_display.ko 明确带着 `msm_ext_disp_register_audio_codec` 这组音频桥接符号，而运行态里又看不到任何 `dp/hdmi/display` ASoC DAI 或 component。这已经很像“桥接模块根本没起来”。我直接做最小化验证：确认这两个模块在设备上是否存在、能不能手工加载、加载后 ASoC 列表有没有变化。

```bash
adb -s 70a91f89 shell 'ls /vendor/lib/modules/msm_ext_display.ko /vendor/lib/modules/snd-soc-hdmi-codec.ko 2>/dev/null'
```

```bash
adb -s 70a91f89 shell 'insmod /vendor/lib/modules/msm_ext_display.ko 2>/dev/null; insmod /vendor/lib/modules/snd-soc-hdmi-codec.ko 2>/dev/null; cat /proc/modules | grep -n "msm_ext_display\|snd_soc_hdmi_codec" | sed -n "1,20p"'
```

```bash
adb -s 70a91f89 shell 'cat /sys/kernel/debug/asoc/components 2>/dev/null | grep -n "disp\|dp\|hdmi" | sed -n "1,40p"; echo ====; cat /sys/kernel/debug/asoc/dais 2>/dev/null | grep -n "hdmi\|dp_audio\|display" | sed -n "1,40p"'
```

手工加载后列表还是空，说明不是“加载成功但没注册”，更像是模块根本没插进去。我补抓 `insmod` 的真实报错，确认是缺依赖、重复加载，还是别的失败。

```bash
adb -s 70a91f89 shell 'insmod /vendor/lib/modules/msm_ext_display.ko; echo ret=$?'
```

```bash
adb -s 70a91f89 shell 'insmod /vendor/lib/modules/snd-soc-hdmi-codec.ko; echo ret=$?'
```

```bash
adb -s 70a91f89 shell 'dmesg | tail -n 80 | grep -n "ext_display\|hdmi\|codec\|Unknown symbol\|insmod"'
```

**纠偏：** `File exists` 说明两个模块其实都在内核里了，不是没加载。接下来不是"模块起没起来"的问题，而是"模块起来了为什么没注册出 display audio component"。

文档 patch（26 行）写入 `TWRP音频手动Bring-up.md`。内存 `twrp_audio_component_gap.md` 和 `twrp_audio_runtime_defer.md` 更新。

---

## 12. 拆 `msm_ext_display.ko` 音频桥接函数 + 发现 `hdmi_dlkm.ko` 是真正调用方

拆 `msm_ext_display.ko` 自己的音频桥接函数，看看 `msm_ext_disp_register_audio_codec` / `msm_ext_disp_select_audio_codec` 到底在等什么前提：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/vendor_modules' && /Users/Laurie/.swiftly/bin/llvm-nm -n msm_ext_display.ko | rg 'msm_ext_disp_register_audio_codec|msm_ext_disp_select_audio_codec|msm_hdmi_register_audio_codec|msm_ext_disp_audio_config|msm_ext_disp_audio_notify'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/vendor_modules' && OBJ='/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump' && "$OBJ" -dr --no-show-raw-insn msm_ext_display.ko | rg 'msm_ext_disp_register_audio_codec|msm_ext_disp_select_audio_codec|msm_hdmi_register_audio_codec|hdmi-audio-codec|snd_soc|platform_device|of_platform_populate' | sed -n "1,200p"
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/vendor_modules' && strings -a msm_ext_display.ko | rg -n 'audio|codec|hdmi-audio-codec|register_audio_codec|select_audio_codec|notify|config' | sed -n "1,160p"
```

**新线索：** msm_ext_display.ko 自己带着 `codec not registered, skip notification` 和 `audio registration failed` 这些字符串。也就是说，它内部确实存在“音频 codec 尚未注册”的失败分支。我再查一件事：到底是谁应该来调用它导出的 `msm_ext_disp_register_audio_codec`。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/vendor_modules' && for f in *.ko; do /Users/Laurie/.swiftly/bin/llvm-nm "$f" 2>/dev/null | grep -q ' U msm_ext_disp_register_audio_codec' && echo "$f"; done
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/vendor_modules' && for f in *.ko; do /Users/Laurie/.swiftly/bin/llvm-nm "$f" 2>/dev/null | grep -q ' U msm_ext_disp_select_audio_codec' && echo "$f"; done
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/vendor_modules' && for f in *.ko; do strings -a "$f" 2>/dev/null | grep -q 'hdmi-audio-codec' && echo "$f"; done
```

**关键发现：** 桥接调用方不是 `snd-soc-hdmi-codec.ko`，而是 `hdmi_dlkm.ko`。这说明真正的注册链大概率是 `hdmi_dlkm -> msm_ext_display -> snd-soc-hdmi-codec`。

拆 `hdmi_dlkm.ko`：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/vendor_modules' && RE='/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-readelf' && "$RE" -p .modinfo hdmi_dlkm.ko | sed -n "1,200p"
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/vendor_modules' && strings -a hdmi_dlkm.ko | rg -n 'msm_ext_disp_register_audio_codec|msm_ext_disp_select_audio_codec|hdmi-audio-codec|audio registration failed|codec not registered|ext-disp|hdmi' | sed -n "1,200p"
```

```bash
adb -s 70a91f89 shell 'cat /proc/modules | grep -n "hdmi_dlkm\|hdmi\|msm_ext_display\|snd_soc_hdmi_codec" | sed -n "1,80p"'
```

**重要纠偏：** 之前"没有模块 alias 匹配 `qcom,msm-ext-disp-audio-codec-rx`"的判断被推翻了。`hdmi_dlkm.ko` 明确就带这个 `of` alias，而且它还依赖 `msm_ext_display`。现在最像的情况不是"没驱动"，而是"运行态根本没有这个 DT 节点实例，所以驱动虽然在内核里，却没有绑定出 component"。

本地 DTS/DTBO 确认：

```bash
rg 'qcom,msm-ext-disp-audio-codec-rx|msm_hdmi_audio_codec_rx_dai|msm_dp_audio_codec_rx_dai' /Volumes/Case-sensitive\ APFS/TWRP/audio_dtb_probe/ -g '*.dts'
```

（等价于 find `**/audio_dtb_probe/**/*.dts` 然后 rg 搜索这些 regex）

运行态 `/proc/device-tree` 验证：

```bash
adb -s 70a91f89 shell 'xxd -g 1 /proc/device-tree/soc/qcom,msm-ext-disp/qcom,msm-ext-disp-audio-codec-rx/compatible 2>/dev/null | head -n 4'
```

```bash
adb -s 70a91f89 shell 'ls /proc/device-tree/soc/qcom,msm-ext-disp 2>/dev/null | sed -n "1,80p"'
```

```bash
adb -s 70a91f89 shell 'xxd -g 1 /proc/device-tree/soc/spf_core_platform/sound/ext_disp_audio_codec 2>/dev/null | head -n 4'
```

**结论：** 运行态 DT 这条节点是存在的，之前那条怀疑也要收回。现在前沿更具体了：`qcom,msm-ext-disp-audio-codec-rx` 节点确实在 recovery 里，但它没有变成 ASoC component。我直接查它在平台总线上的设备和绑定状态。

---

## 13. 平台设备绑定状态追查：子设备存在但无 driver

查平台总线上的设备和绑定状态：

```bash
adb -s 70a91f89 shell 'ls -l /sys/bus/platform/devices/qcom,msm-ext-disp-audio-codec-rx 2>/dev/null'
```

```bash
adb -s 70a91f89 shell 'cat /sys/bus/platform/devices/qcom,msm-ext-disp-audio-codec-rx/modalias 2>/dev/null; echo ====; ls -l /sys/bus/platform/devices/qcom,msm-ext-disp-audio-codec-rx/driver 2>/dev/null'
```

```bash
adb -s 70a91f89 shell 'echo qcom,msm-ext-disp-audio-codec-rx > /sys/bus/platform/drivers_probe 2>/dev/null; dmesg | tail -n 60 | grep -n "ext-disp\|hdmi\|audio-codec-rx"'
```

**结论：** DT 子节点在，但平台设备不在。也就是说，问题已经从“子 codec 驱动没绑上”前移到“父节点根本没把子节点 populate 成 platform device”。我接着只查父节点 `qcom,msm-ext-disp` 自己有没有设备、有没有 driver。

查父节点：

```bash
adb -s 70a91f89 shell 'ls -l /sys/bus/platform/devices/qcom,msm-ext-disp 2>/dev/null'
```

```bash
adb -s 70a91f89 shell 'cat /sys/bus/platform/devices/qcom,msm-ext-disp/modalias 2>/dev/null; echo ====; ls -l /sys/bus/platform/devices/qcom,msm-ext-disp/driver 2>/dev/null'
```

```bash
adb -s 70a91f89 shell 'cat /sys/kernel/debug/devices_deferred 2>/dev/null | grep -n "msm-ext-disp\|ext-disp" | sed -n "1,40p"'
```

父节点 `qcom,msm-ext-disp` 本身也没有平台设备，这已经很像 recovery 里整个 external display 栈没有被实例化。最后我再补两项最小检查：父子节点的 `status`，以及有没有 `qcom,msm-ext-disp` 这个 compatible 的平台设备藏在别的命名下。

```bash
adb -s 70a91f89 shell 'xxd -g 1 /proc/device-tree/soc/qcom,msm-ext-disp/status 2>/dev/null | head -n 2; echo ====; xxd -g 1 /proc/device-tree/soc/qcom,msm-ext-disp/qcom,msm-ext-disp-audio-codec-rx/status 2>/dev/null | head -n 2'
```

```bash
adb -s 70a91f89 shell 'grep -R "qcom,msm-ext-disp" /sys/bus/platform/devices/*/modalias 2>/dev/null | sed -n "1,40p"'
```

```bash
adb -s 70a91f89 shell 'grep -R "qcom,msm-ext-disp-audio-codec-rx" /sys/bus/platform/devices/*/modalias 2>/dev/null | sed -n "1,40p"'
```

**修正：** 父子平台设备其实都存在，只是设备名带了 `soc:` 前缀，之前按裸节点名查错了。现在只剩最后一个关键问题：这两个设备有没有真正绑到 `msm_ext_display` / `hdmi_dlkm` 驱动。

确认这两个设备有没有真正绑到驱动：

```bash
adb -s 70a91f89 shell 'ls -l /sys/bus/platform/devices/soc:qcom,msm-ext-disp/driver 2>/dev/null; echo ====; ls -l /sys/bus/platform/devices/soc:qcom,msm-ext-disp:qcom,msm-ext-disp-audio-codec-rx/driver 2>/dev/null'
```

```bash
adb -s 70a91f89 shell 'readlink /sys/bus/platform/devices/soc:qcom,msm-ext-disp/driver 2>/dev/null; echo ====; readlink /sys/bus/platform/devices/soc:qcom,msm-ext-disp:qcom,msm-ext-disp-audio-codec-rx/driver 2>/dev/null'
```

```bash
adb -s 70a91f89 shell 'cat /sys/kernel/debug/asoc/components 2>/dev/null | grep -n "qcom,msm-ext-disp\|audio-codec-rx\|hdmi" | sed -n "1,60p"'
```

**断点已非常具体：** 父设备 `soc:qcom,msm-ext-disp` 已经绑定到 `msm-ext-disp`，子设备 `soc:qcom,msm-ext-disp:qcom,msm-ext-disp-audio-codec-rx` 存在但没有 `driver`，同时 ASoC components 里也没有对应项。

确认这条子设备应该绑定到哪个 platform driver：

```bash
adb -s 70a91f89 shell 'ls /sys/bus/platform/drivers 2>/dev/null | grep -n "ext-disp\|hdmi\|audio-codec" | sed -n "1,80p"'
```

```bash
adb -s 70a91f89 shell 'for d in /sys/bus/platform/drivers/*; do [ -f "$d/modalias" ] && grep -q "qcom,msm-ext-disp-audio-codec-rx\|hdmi-audio-codec" "$d/modalias" && echo "$d"; done'
```

尝试手动触发子设备绑定：

```bash
adb -s 70a91f89 shell 'echo soc:qcom,msm-ext-disp:qcom,msm-ext-disp-audio-codec-rx > /sys/bus/platform/drivers_probe 2>/dev/null; ls -l /sys/bus/platform/devices/soc:qcom,msm-ext-disp:qcom,msm-ext-disp-audio-codec-rx/driver 2>/dev/null; echo ====; dmesg | tail -n 60 | grep -n "audio-codec-rx\|hdmi\|ext-disp"'
```

子设备重放后依然没有 `driver`，而且平台驱动目录里也没直接看到候选项。我最后补一组最小状态检查：看 `sys/module` 里这三个模块是否真的在，以及 `hdmi_dlkm.ko` 本地是不是确实注册 platform driver。这样就能把“模块已装但驱动未注册”与“驱动已注册但没匹配”区分开。

```bash
adb -s 70a91f89 shell 'ls /sys/module 2>/dev/null | grep -n "hdmi\|ext_display\|snd_soc_hdmi" | sed -n "1,40p"'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/vendor_modules' && /Users/Laurie/.swiftly/bin/llvm-nm -n hdmi_dlkm.ko | rg '__platform_driver_register|platform_driver_unregister|devm_snd_soc_register_component|snd_soc_register_component' | sed -n "1,80p"
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/vendor_modules' && strings -a hdmi_dlkm.ko | rg -n 'platform_driver|probe|remove|audio-codec-rx|snd_soc_register_component|devm_snd_soc_register_component' | sed -n "1,160p"
```

直接看 `/proc/modules` 头部和精确检索，确认 `hdmi_dlkm` 这类模块在当前 recovery 里到底以什么名字挂着。这样这条“子设备未绑定”的链就算彻底闭环了

```bash
adb -s 70a91f89 shell 'cat /proc/modules | head -n 40'
```

```bash
adb -s 70a91f89 shell 'cat /proc/modules | grep -n "^hdmi_dlkm \|^msm_ext_display \|^snd_soc_hdmi_codec " | sed -n "1,20p"'
```

```bash
adb -s 70a91f89 shell 'ls /sys/bus/platform/drivers 2>/dev/null | grep -n "audio\|codec\|rx" | sed -n "1,120p"'
```

**矛盾：** 模块列表里看不到 `hdmi_dlkm/msm_ext_display/snd_soc_hdmi_codec`，和前面的 `File exists` 结果有冲突。做直接验证——单独 `insmod hdmi_dlkm.ko`：

```bash
adb -s 70a91f89 shell 'insmod /vendor/lib/modules/hdmi_dlkm.ko; echo ret=$?'
```

```bash
adb -s 70a91f89 shell 'cat /proc/modules | grep -n "^hdmi_dlkm " | sed -n "1,20p"; echo ====; ls /sys/bus/platform/drivers 2>/dev/null | grep -n "hdmi\|ext-disp\|audio-codec-rx" | sed -n "1,40p"'
```

```bash
adb -s 70a91f89 shell 'dmesg | tail -n 80 | grep -n "hdmi_dlkm\|audio-codec-rx\|Unknown symbol\|msm_ext_disp"'
```

**关键突破：** `hdmi_dlkm.ko` 手工 `insmod` 这次是 `ret=0`，而且已经进了 `/proc/modules`。也就是说，`DISPLAY_PORT-RX-0` 这条线之前至少缺了 `hdmi_dlkm` 这一段。

---

## 14. 验证 `hdmi_dlkm` 加载后的绑定 + 修复验证

复查子设备绑定和 ASoC component：

```bash
adb -s 70a91f89 shell 'ls -l /sys/bus/platform/devices/soc:qcom,msm-ext-disp:qcom,msm-ext-disp-audio-codec-rx/driver 2>/dev/null; echo ====; readlink /sys/bus/platform/devices/soc:qcom,msm-ext-disp:qcom,msm-ext-disp-audio-codec-rx/driver 2>/dev/null'
```

```bash
adb -s 70a91f89 shell 'cat /sys/kernel/debug/asoc/components 2>/dev/null | grep -n "qcom,msm-ext-disp\|audio-codec-rx\|hdmi" | sed -n "1,60p"; echo ====; cat /sys/kernel/debug/asoc/dais 2>/dev/null | grep -n "hdmi\|dp_audio\|msm_hdmi\|display" | sed -n "1,80p"'
```

```bash
adb -s 70a91f89 shell 'echo soc:qcom,msm-ext-disp:qcom,msm-ext-disp-audio-codec-rx > /sys/bus/platform/drivers_probe 2>/dev/null; dmesg | tail -n 80 | grep -n "audio-codec-rx\|hdmi\|snd_soc_register_component"'
```

**更细了：** `hdmi_dlkm` 一加载，子设备立刻绑到了 `msm-ext-disp-audio-codec-rx` 驱动；但 ASoC `components` 和 `dais` 里仍然没有任何 display audio 项。问题已经从"平台设备未绑定"再前进一步，变成"驱动 probe 了，但没有把 ASoC component/DAI 成功注册出来"。

查驱动报错字符串：

```bash
adb -s 70a91f89 shell 'dmesg | grep -n "codec not registered\|audio registration failed\|Invalid codec\|msm-ext-disp-audio-codec-rx\|hdmi_dlkm\|msm_hdmi" | tail -n 80'
```

```bash
adb -s 70a91f89 shell 'cat /sys/kernel/debug/asoc/components 2>/dev/null | tail -n 80'
```

```bash
adb -s 70a91f89 shell 'cat /sys/kernel/debug/asoc/dais 2>/dev/null | tail -n 120'
```

**链条已补齐：** `hdmi_dlkm` 加载后，`soc:qcom,msm-ext-disp:qcom,msm-ext-disp-audio-codec-rx` component 和 `msm_dp_audio_codec_rx_dai` 都已经出现在 ASoC 里。接下来就是主问题本身：在这个缺口补上之后，重新触发 `sound` probe，看 `-EPROBE_DEFER` 会不会前移、消失，或者卡到下一条边界。

**主验证——重新触发 `sound` probe：**

```bash
adb -s 70a91f89 shell 'echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; cat /proc/asound/cards 2>/dev/null; echo ====; ls /dev/snd 2>/dev/null; echo ====; ls -l /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver 2>/dev/null'
```

```bash
adb -s 70a91f89 shell 'cat /sys/kernel/debug/devices_deferred 2>/dev/null | sed -n "1,80p"; echo ====; dmesg | tail -n 120 | grep -n "sun-asoc-snd\|snd_soc_bind_card\|snd_soc_add_pcm_runtimes\|wcd9378\|wsa-codec\|DISPLAY_PORT-RX-0"'
```

验证 ASoC component 和 DAI：

```bash
adb -s 70a91f89 shell 'cat /sys/kernel/debug/asoc/components 2>/dev/null | grep -n "audio-codec-rx"; echo ====; cat /sys/kernel/debug/asoc/dais 2>/dev/null | grep -n "msm_dp_audio_codec_rx_dai\|msm_dp_audio_codec_rx1_dai"'
```

**关键状态已变：** `sound` 现在成功绑定到了 `sun-asoc-snd`，`/proc/asound/cards` 里已经有 `sun-mtp-snd-card`，`/dev/snd` 也已经生成了一整套 PCM 节点。这说明之前卡住整个声卡注册的缺口，确实就是 display audio 那条链。

---

## 15. 声卡已注册——检查用户态播放入口

```bash
adb -s 70a91f89 shell 'which tinyplay; which tinymix; which tinypcminfo; which tinycap; which aplay'
```

```bash
adb -s 70a91f89 shell 'cat /proc/asound/pcm 2>/dev/null | sed -n "1,120p"'
```

```bash
adb -s 70a91f89 shell 'cat /proc/asound/cards 2>/dev/null; echo ====; cat /proc/asound/devices 2>/dev/null | sed -n "1,120p"'
```

声卡已经起来了，下一步不是继续猜，而是进入“能不能从某个 PCM 真正打出声音”的阶段。我先把 recovery 里可用的音频用户态工具和 mixer 入口摸出来；如果系统自带了 `tinymix`/`tinyplay`，就直接走它，如果没有，就要改成从现有节点手动驱动

```bash
adb -s 70a91f89 shell 'for d in /system/bin /system_ext/bin /vendor/bin /sbin; do [ -d "$d" ] && find "$d" -maxdepth 1 \( -name "tiny*" -o -name "*mixer*" -o -name "aplay" -o -name "speaker-test" \) 2>/dev/null; done'
```

```bash
adb -s 70a91f89 shell 'ls /sys/class/sound 2>/dev/null | sed -n "1,120p"; echo ====; for f in /sys/class/sound/controlC0/device/id /sys/class/sound/pcmC0D0p/device/id /sys/class/sound/pcmC0D1p/device/id /sys/class/sound/pcmC0D2p/device/id /sys/class/sound/pcmC0D3p/device/id /sys/class/sound/pcmC0D4p/device/id; do [ -f "$f" ] && echo "$f: $(cat $f)"; done'
```

```bash
adb -s 70a91f89 shell 'for d in /proc/asound/card0 /sys/kernel/debug/asoc; do [ -d "$d" ] && echo ==== $d && find "$d" -maxdepth 2 -type f 2>/dev/null | sed -n "1,200p"; done'
```

内核侧已经从"卡没起来"推进到了"卡已注册"。如果要再往前一步做到"真的响"，要么复用 recovery 里已有的播放入口，要么找到现成的用户态小工具。

在代码库中搜索现成的音频播放入口：

- 搜索 `**/*tinyalsa*`（101 hits）
- 搜索 `**/*wav*`（200 hits）
- 搜索 `**/*audio*`（200 hits）
- 搜索 `pcm_open|mixer_open|tinymix|tinyplay|playwav|mixer_ctl|pcm_write|pcm_readi` 在 `**/*.{c,cc,cpp,h,hpp,sh,rc,bp,mk}`（200 hits）
- 搜索 `DataManager.*audio|audio.*DataManager|twrp.audio|audio.autoload|beep|wav|sound|play.*audio|play.*wav` 在 `**/*.{c,cc,cpp,h,hpp,sh,rc,xml}`（200 hits）
- 搜索 `tinyalsa|tinymix|tinyplay|tinycap|tinypcminfo` 在 `**/*.{bp,mk,c,cc,cpp,h,sh,rc,txt}`（200 hits）
- 找 `**/playwav.c`（2 matches）
- 找 `**/tinymix`（no matches）
- 找 `**/tinyplay*`（no matches）

读关键文件：

- `init.recovery.qcom.rc` 第 35-85 行
- `twrp-audio-autoload.sh`
- `vendor.audio-recovery-services.rc`
- `injected.rc`

**发现：** 代码库里其实已经有一条现成的"手动拉起 recovery 音频"的入口：`twrp-audio-autoload.sh`。而它现在的模块加载序列里没有 `hdmi_dlkm`，这和真机上验证出来的现象完全对上了。

---

## 16. 固化修复：把 `hdmi_dlkm` 加入自动加载脚本

准备把修复固化到 recovery 自己的拉起脚本里，而不是只停留在一次性的 adb 手工步骤上。

patch（85 行）写入：
- `twrp-audio-autoload.sh`：把 `hdmi_dlkm` 纳入现有模块加载序列
- `TWRP音频手动Bring-up.md`：补入修复和完整因果链

更新 repo memory：
- `twrp_audio_component_gap.md` 更新
- `twrp_audio_runtime_defer.md` 更新

脚本语法校验：

```bash
sh -n '/Volumes/Case-sensitive APFS/TWRP/device_tree/twrp_device_oplus_ossi_source_built/recovery/root/system/bin/twrp-audio-autoload.sh'
```

语法检查通过。

---

## 最终结论

主缺口已经打通。实机验证结果：

之前把整张 ASoC 卡卡在 `snd_soc_add_pcm_runtimes -> -517` 的，不是 `RX-6`，也不是 `wsa/wcd9378` 先掉，而是 `DISPLAY_PORT-RX-0` 这条 display audio 注册链没补齐。手工加载 `hdmi_dlkm` 之后，ext display audio codec 子设备完成绑定，ASoC 里出现了对应 component 和 `msm_dp_audio_codec_rx_dai`，随后重新触发 `probe_sound`，声卡已经成功注册，`/proc/asound/cards` 里出现了 `sun-mtp-snd-card`，`/dev/snd` 也生成了完整 PCM 节点。

已经把修复固化进 recovery 的音频自动拉起脚本：把 `hdmi_dlkm` 加入到 `probe_sound` 之前的模块加载序列里。文档也补了两件事：一是这次真正的根因链，二是修正了之前对 `insmod ... File exists` 的过度解读，它只能算弱线索，不能当作"模块已经完整生效"的证据。

当前 recovery 环境里没有找到 `tinyplay`、`tinymix` 一类现成工具，所以这次已经确认"声卡和 PCM 已起来"，但还没直接把一个 WAV 从用户态打到扬声器。下一步：
1. 把带有这次脚本修复的新 recovery 刷进去，直接验证开机后是否自动出现 `sun-mtp-snd-card`。
2. 继续补一个最小用户态播放入口，比如把 `tinyplay/tinymix` 带进 recovery，或者复用现有 TWRP 代码里的播放入口，做真正的出声验证。

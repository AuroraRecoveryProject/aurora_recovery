## 1. 从 machine_dlkm.ko 二进制字符串开始探查

**目的**：从 `machine_dlkm.ko` 二进制里直接捞字符串，查看模块内部可能存在的失败分支和日志点，弥补 dmesg 未输出的信息。

在 TWRP recovery 运行态中，直接对 machine 模块做 strings 提取：

```bash
adb shell 'strings /vendor_dlkm/lib/modules/machine_dlkm.ko | grep -i -E "snd_soc_register_card|register_card|asoc|failed|defer|aw882|sipa pvdd|oplus pa manager|exchanged tdm|backend|codec|phandle" | head -n 260'
```

**结论**：二进制字符串中确认模块内部带有 `snd_soc_register_card failed (%d)` 和 `asoc machine probe done.` 这类日志点，但当前两者都没在 dmesg 中出现，说明函数可能在更前面的某个返回路径静默退出。下一步直接用返回值跟踪确认 `msm_asoc_machine_probe` 到底返回了什么。

---

## 2. 用 kprobe 抓 msm_asoc_machine_probe 的返回值

**目的**：确认 machine probe 的真实返回值，判断是否是因为 defer 导致注册未完成。

挂载 debugfs 并设置 kretprobe：

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; echo > /sys/kernel/debug/tracing/kprobe_events; echo "r:msmret msm_asoc_machine_probe ret=%x0" > /sys/kernel/debug/tracing/kprobe_events; echo 1 > /sys/kernel/debug/tracing/events/kprobes/msmret/enable; echo 0 > /sys/kernel/debug/tracing/trace; echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; cat /sys/kernel/debug/tracing/trace | tail -n 80; echo 0 > /sys/kernel/debug/tracing/events/kprobes/msmret/enable; echo > /sys/kernel/debug/tracing/kprobe_events'
```

**结论**：`msm_asoc_machine_probe` 的返回值是 `0xfffffdfb`，即 `-517`（`EPROBE_DEFER`）。说明 probe 末端仍在主动 defer，不是"静默成功但没注册"，只是 dmesg 没把具体 defer 原因打出来。

---

## 3. 进一步确认 defer 来源：devm_snd_soc_register_card

**目的**：下沉一层，确认是不是 `devm_snd_soc_register_card` 本身就返回了 `-517`。

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; echo > /sys/kernel/debug/tracing/kprobe_events; echo "r:msmret msm_asoc_machine_probe ret=%x0" > /sys/kernel/debug/tracing/kprobe_events; echo "r:cardret devm_snd_soc_register_card ret=%x0" >> /sys/kernel/debug/tracing/kprobe_events; echo 1 > /sys/kernel/debug/tracing/events/kprobes/msmret/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/cardret/enable; echo 0 > /sys/kernel/debug/tracing/trace; echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; cat /sys/kernel/debug/tracing/trace | tail -n 120; echo 0 > /sys/kernel/debug/tracing/events/kprobes/msmret/enable; echo 0 > /sys/kernel/debug/tracing/events/kprobes/cardret/enable; echo > /sys/kernel/debug/tracing/kprobe_events'
```

**结论**：返回值链已经定死 —— `devm_snd_soc_register_card` 自己就是 `-EPROBE_DEFER`。卡点不在 machine probe 前半段，而是声卡注册阶段还在等某个 component 或 dai。

---

## 4. 读 sound 节点的 asoc-codec 列表对照当前 ASoC components

**目的**：直接读 `sound` 节点声明的 codec 列表，对照当前 ASoC components，找出谁还没齐。

```bash
adb shell 'node=/sys/firmware/devicetree/base/soc/spf_core_platform/sound; for f in asoc-codec-names asoc-codec; do echo ===$f===; for p in $node/$f*; do echo [$p]; cat $p 2>/dev/null | tr "\000" "\n"; done; done'
```

**结论**：`asoc-codec-names` 里声明的 3 个主 codec 名称现在都已经对上了，defer 点更像在 dailink 绑定阶段，不是顶层 codec 名称缺失。

---

## 5. 再下钻：snd_soc_bind_card / snd_soc_instantiate_card

**目的**：确认 `snd_soc_bind_card` 和 `snd_soc_instantiate_card` 谁先开始返回 `-EPROBE_DEFER`。

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; echo > /sys/kernel/debug/tracing/kprobe_events; echo "r:cardret devm_snd_soc_register_card ret=%x0" > /sys/kernel/debug/tracing/kprobe_events; echo "r:bindret snd_soc_bind_card ret=%x0" >> /sys/kernel/debug/tracing/kprobe_events; echo "r:instret snd_soc_instantiate_card ret=%x0" >> /sys/kernel/debug/tracing/kprobe_events; echo 1 > /sys/kernel/debug/tracing/events/kprobes/cardret/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/bindret/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/instret/enable; echo 0 > /sys/kernel/debug/tracing/trace; echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; cat /sys/kernel/debug/tracing/trace | tail -n 120; echo 0 > /sys/kernel/debug/tracing/events/kprobes/cardret/enable; echo 0 > /sys/kernel/debug/tracing/events/kprobes/bindret/enable; echo 0 > /sys/kernel/debug/tracing/events/kprobes/instret/enable; echo > /sys/kernel/debug/tracing/kprobe_events'
```

**结论**：`snd_soc_bind_card` 本身就在回 `-EPROBE_DEFER`。精确前沿：不是泛泛的"sound 还在 deferred"，而是"card bind 阶段仍有未就绪的 ASoC endpoint / component / dai"。这条结论比前面所有现象描述都更硬。

---

## 6. machine_dlkm 内提到的 codec/component 与 ASoC 运行态差集检查

**目的**：把 machine 模块里明显提到的 codec/component 名字与当前 recovery 真正注册出来的 components 做差集，看出缺口。

```bash
adb shell 'echo ---expected-like---; strings /vendor_dlkm/lib/modules/machine_dlkm.ko | grep -E "^(wsa-codec(\.|[0-9])|wcd939x_codec|wcd9378_codec|msm-stub-codec\.1|lpass-cdc|aw882xx)" | sort -u; echo ---components---; cat /sys/kernel/debug/asoc/components 2>/dev/null | sort -u'
```

**结论**：`machine_dlkm` 二进制里明确提到了 `wsa-codec.1..4` 和 `wcd9378_codec`，但当前 recovery 的 ASoC components 里完全没有这些实体。

进一步确认底层 codec 设备是否有枚举：

```bash
adb shell 'echo ---modules---; grep -i -E "wsa883x|wsa884x|wcd9378" /proc/modules; echo ---soundwire-devices---; find /sys/bus/soundwire/devices -maxdepth 1 -type l | sed "s#.*/##" | sort'
```

```bash
adb shell 'for n in wcd9378 wsa883x wsa884x; do echo ===$n===; find /sys/bus -iname "*${n}*" 2>/dev/null | head -n 80; done'
```

**结论**：差集中已出现新可疑点。`machine_dlkm` 点名提到 `wsa-codec.1..4` 和 `wcd9378_codec`，但 recovery 当前的 ASoC components 里完全没有它们；同时 SoundWire 设备里也只有 `wcd939x-slave.*` 和 `btfmswr_slave.*`。这很像 `snd_soc_bind_card` 仍在等待的那批实体。

当前关键结论：

1. 只加载 aw882xx 时设备保持稳定，6 个 smart PA 实例都能完成注册，machine probe 也会稳定打印 `use aw882xx dailink replace`。说明 aw882xx 本身已不是阻塞点，aw87xxx 也不是 card0 出现前的必要前置。
2. 用 kprobe 抓到 `msm_asoc_machine_probe` 返回值是 `0xfffffdfb`（`-517` / `EPROBE_DEFER`）。
3. 继续下钻后，`devm_snd_soc_register_card` 和 `snd_soc_bind_card` 也都返回 `-EPROBE_DEFER`。可以明确说声卡注册阶段还在等某个 ASoC endpoint、component 或 dai。
4. 差集中最可疑的是 `wcd9378_codec` 和 `wsa-codec.1..4`：模块都加载了，但对应 component 没真正出现，SoundWire 侧也只看到 `wcd939x` 和 `btfm` 实体。

---

## 7. wcd9378 与 wsa883x/wsa884x 的 DT 与总线枚举链排查

**目的**：确认 `wcd9378` 和 `wsa883x/wsa884x` 为什么只有驱动、没有实际设备实例。

### 7.1 DT 节点搜素

```bash
adb shell 'for n in wcd9378 wsa883x wsa884x; do echo ===DT:$n===; find /sys/firmware/devicetree/base -iname "*${n}*" 2>/dev/null | head -n 80; done'
```

```bash
adb shell 'for n in wcd9378 wsa883x wsa884x; do echo ===BUS:$n===; find /sys/bus -iname "*${n}*" 2>/dev/null | head -n 120; done'
```

### 7.2 SoundWire master 状态

```bash
adb shell 'echo ---soundwire-masters---; for d in /sys/bus/soundwire/devices/swr*; do [ -d "$d" ] || continue; echo ===$d===; ls "$d" 2>/dev/null | head -n 80; done'
```

**结论**：`wsa883x/wsa884x` 的 DT 节点在 recovery 里存在，但总线下没有对应设备实例；`wcd9378` 更激进，连 DT 节点名都没直接搜到。

### 7.3 读 lpass-cdc 子树的 upstream master 和 status

```bash
adb shell 'base=/sys/firmware/devicetree/base/soc/spf_core_platform/lpass-cdc; for p in "$base" "$base"/wsa-macro@6B00000 "$base"/wsa2-macro@6AA0000; do echo ===$p===; for f in name compatible status reg; do echo [$f]; cat "$p"/$f 2>/dev/null | tr "\000" "\n"; done; done'
```

### 7.4 读 WSA swr master 子节点

```bash
adb shell 'for p in /sys/firmware/devicetree/base/soc/spf_core_platform/lpass-cdc/wsa-macro@6B00000/wsa_swr_master /sys/firmware/devicetree/base/soc/spf_core_platform/lpass-cdc/wsa2-macro@6AA0000/wsa2_swr_master; do echo ===$p===; ls "$p" 2>/dev/null; for c in "$p"/*; do [ -e "$c" ] || continue; echo ---$c---; for f in name compatible status reg; do echo [$f]; cat "$c"/$f 2>/dev/null | tr "\000" "\n"; done; done; done'
```

### 7.5 读 wsa-macro / wsa2-macro 平台设备绑定状态

```bash
adb shell 'for d in /sys/bus/platform/devices/wsa-macro /sys/bus/platform/devices/wsa2-macro; do echo ===$d===; ls "$d" 2>/dev/null | head -n 80; echo ---driver---; readlink "$d"/driver 2>/dev/null || echo no_driver; echo ---of_node---; readlink "$d"/of_node 2>/dev/null; done'
```

**结论**：WSA 这条线出现了非常强的新信号 —— `wsa-macro` 和 `wsa2-macro` 在 recovery DT 里是 `status = "disabled"`，而平台设备虽然存在，但没有 driver 绑定。整棵 WSA 子树都被 DT 关掉了。

### 7.6 wcd9378 相关 DT 搜索

WSA 分支的根因已经非常接近了：宏节点本身被 DT 设成 `disabled`，子节点大多也被关着，所以它们不出 component 是合理的。现在我要把另一半 `wcd9378` 也查清，看它是不是同样被 DT 关掉，还是它属于另一条总线。

```bash
adb shell 'find /sys/firmware/devicetree/base/soc/spf_core_platform/lpass-cdc -maxdepth 4 \( -iname "*wcd*" -o -iname "*rx*" -o -iname "*tx*" -o -iname "*va*" \) 2>/dev/null | head -n 220'
```

```bash
adb shell 'find /sys/firmware/devicetree/base -maxdepth 8 \( -iname "*9378*" -o -iname "*wcd9378*" -o -iname "*wcd*slave*" -o -iname "*tx_macro*" -o -iname "*rx_macro*" -o -iname "*va_macro*" \) 2>/dev/null | head -n 260'
```

```bash
adb shell 'for d in /sys/bus/platform/devices/rx-macro /sys/bus/platform/devices/tx-macro /sys/bus/platform/devices/va-macro; do echo ===$d===; readlink "$d"/driver 2>/dev/null || echo no_driver; readlink "$d"/of_node 2>/dev/null || echo no_of; done'
```

---

## 8. 尝试在源码树中搜索 machine 驱动和 ASoC core 实现

**目的**：在工作区里找 `machine_dlkm` 和 ASoC core 的实现，直接看 bind 阶段有哪些返回 `-EPROBE_DEFER` 的路径。

先通过子代理在整个工作区做粗筛：

```bash
# 搜索 ASoC 核心函数和 machine probe 符号
rg -n 'qcom,sun-asoc-snd|msm_asoc_machine_probe|extend_codec_i2s_be_dailinks|snd_soc_bind_card|devm_snd_soc_register_card' --type-add 'code:*.{c,h,dtsi,dts,txt,yaml}' -t code 2>/dev/null | head -n 200
```

```bash
# 搜索音频相关关键字
rg -n 'aw882xx|wsa|wcd9378' --type-add 'code:*.{c,h,dtsi,dts,txt,yaml}' -t code 2>/dev/null | head -n 200
```

```bash
# 搜索 kernel 目录（粗）
find . -path '*/kernel/*' -type f 2>/dev/null | head -n 200
# 200 matches
```

```bash
# 搜索特定文件名模式
find . \( -name '*msm*asoc*machine*.c' -o -name '*machine_dlkm*' -o -name '*sun-asoc-snd*' \) 2>/dev/null | head -n 80
```

```bash
# 搜索 sound/soc 目录
find . -path '*/sound/soc/*' -type f 2>/dev/null | head -n 80
```

子代理未给出有效命中，于是在 `twrp_a16_compile` 目录下做精确搜索：

```bash
rg -n --hidden --glob '!out/**' 'msm_asoc_machine_probe|qcom,sun-asoc-snd|extend_codec_i2s_be_dailinks' kernel vendor hardware device 2>/dev/null | head -n 200
```

```bash
rg -n --hidden --glob '!out/**' 'snd_soc_bind_card|devm_snd_soc_register_card|snd_soc_register_card' kernel 2>/dev/null | head -n 200
```

```bash
# 遍历所有 .c 文件确认范围
find twrp_a16_compile -name '*.c' 2>/dev/null | head -n 300
# 300 matches
```

检查 kernel/vendor 目录结构，确认是否有音频相关子目录：

```bash
find kernel vendor -maxdepth 3 \( -iname '*audio*' -o -iname '*asoc*' -o -iname '*sound*' -o -iname '*machine*' \) 2>/dev/null | head -n 240
```

**结论**：源码树里没直接搜到实现，说明当前同步下来的目录可能没有完整厂商音频内核源码，需要完全回到运行态。

---

## 9. kallsyms 符号摸底：确认 ASoC core 可 kprobe 符号

**目的**：确认 ASoC core 里哪些查找函数可以被 kprobe，以便把 `-EPROBE_DEFER` 继续拆成"到底缺哪个 lookup"。

```bash
adb shell 'grep -E " snd_soc_(bind_card|instantiate_card|find|lookup|rtdcom_lookup|find_dai|find_component|register_card)" /proc/kallsyms | head -n 120'
```

```bash
adb shell 'grep -E " msm_asoc_machine_probe|extend_codec_i2s_be_dailinks|msm_common_get_backend_name|snd_soc_bind_card|devm_snd_soc_register_card" /proc/kallsyms | head -n 120'
```

**结论**：`snd_soc_find_dai` 和 `snd_soc_lookup_component` 等符号可用。

---

## 10. 用 kprobe 抓 snd_soc_find_dai / snd_soc_lookup_component 返回值

**目的**：直接抓 `snd_soc_find_dai` 和 `snd_soc_lookup_component` 的返回值，判断 defer 是不是因为找不到 DAI 或 component。

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; echo > /sys/kernel/debug/tracing/kprobe_events; echo "r:bindret snd_soc_bind_card ret=%x0" > /sys/kernel/debug/tracing/kprobe_events; echo "r:finddai snd_soc_find_dai ret=%x0" >> /sys/kernel/debug/tracing/kprobe_events; echo "r:findcomp snd_soc_lookup_component ret=%x0" >> /sys/kernel/debug/tracing/kprobe_events; echo "r:rtdcom snd_soc_rtdcom_lookup ret=%x0" >> /sys/kernel/debug/tracing/kprobe_events; for e in bindret finddai findcomp rtdcom; do echo 1 > /sys/kernel/debug/tracing/events/kprobes/$e/enable; done; echo 0 > /sys/kernel/debug/tracing/trace; echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; cat /sys/kernel/debug/tracing/trace | tail -n 200; for e in bindret finddai findcomp rtdcom; do echo 0 > /sys/kernel/debug/tracing/events/kprobes/$e/enable; done; echo > /sys/kernel/debug/tracing/kprobe_events'
```

**结论**：`snd_soc_find_dai` 在单次 bind 里全部返回非空指针，没有直接暴露"某个 DAI 名字找不到"。说明 defer 更可能落在 `snd_soc_add_pcm_runtimes` 之后的组件探测或 PCM/runtime 建立阶段。

---

## 11. 再下钻：snd_soc_add_pcm_runtimes / soc_new_pcm / soc_probe_component

### 11.1 确认可用符号

```bash
adb shell 'grep -E " snd_soc_add_pcm_runtimes| soc_probe_link| soc_new_pcm| soc_probe_.*component| soc_probe_.*dai| soc_link_init" /proc/kallsyms | head -n 200'
```

```bash
adb shell 'grep -E " snd_soc_add_pcm_runtimes| soc_.*pcm| soc_.*runtime| soc_.*widget| soc_.*link" /proc/kallsyms | head -n 200'
```

### 11.2 挂 kretprobe

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; echo > /sys/kernel/debug/tracing/kprobe_events; echo "r:addrt snd_soc_add_pcm_runtimes ret=%x0" > /sys/kernel/debug/tracing/kprobe_events; echo "r:newpcm soc_new_pcm ret=%x0" >> /sys/kernel/debug/tracing/kprobe_events; echo "r:probecomp soc_probe_component ret=%x0" >> /sys/kernel/debug/tracing/kprobe_events; echo "r:bindret snd_soc_bind_card ret=%x0" >> /sys/kernel/debug/tracing/kprobe_events; for e in addrt newpcm probecomp bindret; do echo 1 > /sys/kernel/debug/tracing/events/kprobes/$e/enable; done; echo 0 > /sys/kernel/debug/tracing/trace; echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; cat /sys/kernel/debug/tracing/trace | tail -n 200; for e in addrt newpcm probecomp bindret; do echo 0 > /sys/kernel/debug/tracing/events/kprobes/$e/enable; done; echo > /sys/kernel/debug/tracing/kprobe_events'
```

**结论**：把范围又砍掉了一半。`-EPROBE_DEFER` 不是在 component probe 或 `soc_new_pcm` 阶段才出现，而是 `snd_soc_add_pcm_runtimes` 自己就已经返回了 `-EPROBE_DEFER`。卡点就在"为 dailink 建 runtime"的阶段。

### 11.3 尝试 function_graph tracer

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; cd /sys/kernel/debug/tracing || exit 1; echo function_graph > current_tracer; echo snd_soc_add_pcm_runtimes > set_graph_function; echo 0 > trace; echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; cat trace | tail -n 220; echo nop > current_tracer; : > set_graph_function'
```

**结论**：这轮形成了新的硬边界 —— WSA 宏在 DT 里是 disabled，且 `-EPROBE_DEFER` 已被压到 `snd_soc_add_pcm_runtimes`。

---

## 12. 外部源码参考确认 defer 路径

**目的**：本地没内核源码，用外部源码参考确认 `snd_soc_add_pcm_runtimes` 在 ASoC core 里通常有哪些 `-EPROBE_DEFER` 返回路径。

通过 WebFetch 获取了 `https://codebrowser.dev/linux/linux/sound/soc/soc-core.c.html`。

**结论**：外部源码说明 `snd_soc_add_pcm_runtimes` 里真正会返回 `-EPROBE_DEFER` 的地方，最典型就是 `soc_dai_link_sanity_check` 发现某个 component 不在 component list，或者 `snd_soc_add_pcm_runtime` 里 CPU/CODEC DAI 没注册。

---

## 13. 抓 soc_dai_link_sanity_check 返回值

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; echo > /sys/kernel/debug/tracing/kprobe_events; echo "r:sanity soc_dai_link_sanity_check ret=%x0" > /sys/kernel/debug/tracing/kprobe_events; echo "r:addrt snd_soc_add_pcm_runtimes ret=%x0" >> /sys/kernel/debug/tracing/kprobe_events; echo "r:finddai snd_soc_find_dai ret=%x0" >> /sys/kernel/debug/tracing/kprobe_events; for e in sanity addrt finddai; do echo 1 > /sys/kernel/debug/tracing/events/kprobes/$e/enable; done; echo 0 > /sys/kernel/debug/tracing/trace; echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; cat /sys/kernel/debug/tracing/trace | tail -n 220; for e in sanity addrt finddai; do echo 0 > /sys/kernel/debug/tracing/events/kprobes/$e/enable; done; echo > /sys/kernel/debug/tracing/kprobe_events'
```

如果 `soc_dai_link_sanity_check` 也直接回 `-EPROBE_DEFER`，那就几乎可以确认是 component list 缺项，而不是某个 DAI 晚注册。我要把这次 trace 读完。

---

## 14. 尝试打开 ASoC core 的 dynamic debug

运行态和外部源码已经把 `-EPROBE_DEFER` 压到 `snd_soc_add_pcm_runtimes`，剩下最值钱的一步就是把 ASoC core 的 `dev_dbg` 打开，看它会不会直接打印出“哪个 link / 哪个 component 不存在”。如果能打出来，就不用再盲猜结构体内容。

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; grep -i -E "soc-core|snd_soc_add_pcm_runtime|soc_dai_link_sanity_check|Component .* not found|CPU DAI .* not registered|CODEC DAI .* not registered" /sys/kernel/debug/dynamic_debug/control | head -n 120'
```

```bash
adb shell 'grep -i -E "sound/soc/soc-core.c|ASoC: binding|Component .* not found|CPU DAI .* not registered|CODEC DAI .* not registered" /sys/kernel/debug/dynamic_debug/control | head -n 120'
```

**结论**：当前内核里没搜到可用的 soc-core dynamic_debug 控制项，这条路暂时拿不到增量信息。

---

## 15. 阶段性结论（第一轮收敛）

运行态和外部源码已经把 `-EPROBE_DEFER` 压到了 `snd_soc_add_pcm_runtimes`：

1. 运行态 DT 里 `wsa-macro@6B00000` 和 `wsa2-macro@6AA0000` 直接是 disabled，下面多数 WSA 子节点也被关掉了。看不到 `wsa883x`、`wsa884x` 对应的 ASoC component 不一定是 recovery 漏加载，更可能是板级分支本来就没启用。
2. 结合运行态 kprobe 和外部 ASoC core 源码，把 `-EPROBE_DEFER` 落点压到了 `snd_soc_add_pcm_runtimes`。`snd_soc_find_dai` 在单次 bind 过程中反复返回非空指针，没看到前台的"某个 DAI 名字找不到"；`soc_new_pcm` 还没走到可见返回点。最精确前沿：
   `snd_soc_bind_card -> snd_soc_add_pcm_runtimes -> -EPROBE_DEFER`

---

## 16. wcd9378 模块信息采集

### 16.1 确认模块别名与 DT 兼容串

```bash
adb shell 'grep -E " soc_dai_link_sanity_check$| snd_soc_add_pcm_runtime$| snd_soc_add_pcm_runtimes$| snd_soc_bind_card$" /proc/kallsyms'
```

当前文档尾部还是我上轮收敛后的版本，没有冲突；符号核对也说明 `soc_dai_link_sanity_check` 和 `snd_soc_add_pcm_runtime` 这两个静态函数不能直接拿来打 kprobe。下一步我改查模块别名和 DT 兼容串，验证 `wcd9378` 到底是不是当前 recovery 根本没有对应设备节点。

```bash
adb shell 'for m in /vendor_dlkm/lib/modules/wcd9378_dlkm.ko /vendor_dlkm/lib/modules/wsa883x_dlkm.ko /vendor_dlkm/lib/modules/wsa884x_dlkm.ko; do echo ===$m===; modinfo "$m" | grep -i -E "^(name|alias|description):"; done'
```

```bash
adb shell 'find /sys/firmware/devicetree/base -type f -name compatible 2>/dev/null | while read f; do s=$(cat "$f" 2>/dev/null | tr "\000" "\n"); echo "$s|$f"; done | grep -i -E "qcom,wcd9378|qcom,wsa883x|qcom,wsa884x|qcom,wsa883x_2|qcom,wsa884x_2" | head -n 120'
```

```bash
adb shell 'for d in /sys/bus/platform/drivers/wcd9378_codec /sys/bus/soundwire/drivers/wsa883x /sys/bus/soundwire/drivers/wsa884x; do echo ===$d===; ls "$d" 2>/dev/null; done'
```

**结论**：WSA 的 compatible 在 DT 里确实存在，但整支多数是 `disabled`；`wcd9378_codec` 更可疑，模块已加载但驱动目录下连一个已绑定设备都没有。

### 16.2 从 wcd9378_dlkm.ko 二进制捞匹配字符串

```bash
adb shell 'strings /vendor_dlkm/lib/modules/wcd9378_dlkm.ko | grep -i -E "qcom,|wcd9378|9378|slim|swr|codec" | head -n 220'
```

```bash
adb shell 'find /sys/bus -iname "*9378*" -o -iname "*wcd*" 2>/dev/null | head -n 260'

adb shell 'for p in /sys/firmware/devicetree/base/soc/spf_core_platform/lpass-cdc/wcd939x-codec/qcom,rx-slave /sys/firmware/devicetree/base/soc/spf_core_platform/lpass-cdc/wcd939x-codec/qcom,tx-slave; do echo ===$p===; hexdump -Cv "$p" 2>/dev/null; done'
```

`wcd9378` 这条线已经比上一轮清楚很多了：模块二进制里明确写着它期望匹配 `qcom,wcd9378-codec`，而当前 recovery 运行时 DT 里没搜到这个 compatible；同时 sysfs 里也完全没有 `wcd9378` 对应设备，只剩一个空的 `wcd9378_codec` 驱动目录。下一步我再把 machine 模块里和 `wcd9378` 相关的 DAI 名称捞出来，和当前 ASoC `dais` 做直接差集，给 `snd_soc_add_pcm_runtimes -> -EPROBE_DEFER` 再补一层证据。

### 16.3 machine_dlkm 内 wcd9378 相关字符串 & ASoC DAI 差集

```bash
adb shell 'echo ---machine-wcd9378---; strings /vendor_dlkm/lib/modules/machine_dlkm.ko | grep -i -E "wcd9378|AIF Playback|AIF Capture|codec_dma|wsa-codec|wcd939x" | sort -u | head -n 220; echo ---asoc-dais---; cat /sys/kernel/debug/asoc/dais 2>/dev/null | sort -u | grep -i -E "wcd9378|AIF|wcd939x|wsa|rx_macro|tx_macro|va_macro|msm-stub|aw882"'
```

```bash
adb shell 'echo ---machine-expected-components---; strings /vendor_dlkm/lib/modules/machine_dlkm.ko | grep -E "^(wcd9378_codec|wcd939x_codec|wsa-codec(\.|[0-9])|msm-stub-codec\.1|lpass-cdc)$" | sort -u; echo ---current-components---; cat /sys/kernel/debug/asoc/components 2>/dev/null | sort -u'
```

差集证据已经明显加重到 `wcd9378`：`machine_dlkm` 二进制里明确带着 `wcd9378_codec`、`wcd9378_cdc` 和 “failed to add wcd9378 routes”，但当前 ASoC 里只有 `wcd939x-codec`，完全没有 `wcd9378` 的 component 或 DAI。下一步我不改镜像，只重新打开 `machine_dlkm` 的动态调试，看它是否愿意把这条缺口直接打到 dmesg。

### 16.4 尝试打开 machine_dlkm 动态调试

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; echo "module machine_dlkm +p" > /sys/kernel/debug/dynamic_debug/control 2>/dev/null; dmesg -c >/dev/null 2>&1; echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; dmesg | grep -i -E "wcd9378|wsa-codec|component is NULL|failed to add|snd_soc_register_card|machine probe|extend_codec|asoc" | tail -n 220'
```

这轮 live 证据已经够形成新的前沿，不再继续盲打点了。我先把两条新增硬结论落文档：`wcd9378` 当前在 recovery 里没有任何匹配设备，以及 machine 动态调试仍只停在 `aw882xx dailink replace`，没有吐出更后段缺口。

---

## 17. wcd9378 缺口收敛结论

最可疑的缺口从泛化的 `wsa/wcd` 收敛到了 `wcd9378`。确认三件事：

1. `wcd9378_dlkm.ko` 二进制里明确写着它期望的对象是 `qcom,wcd9378-codec`，还带着 `WCD9378_AIF Playback`、`WCD9378_AIF Capture`、`Could not find RX/TX swr slave device`、`Codec registration failed` 这类字符串。
2. 当前 recovery 运行时 DT 里没有任何 `qcom,wcd9378-codec` 节点，sysfs 里也只有一个空的 `wcd9378_codec` 驱动目录，没有已绑定设备。
3. 当前 ASoC 组件和 DAI 里都没有任何 `wcd9378` 实体，只有 `wcd939x`、macro、`msm-stub`、`aw882xx` 这些已经起来的部分。

同时，`wsa` 这条线这次反而变得没那么优先了，因为它对应的宏节点和大多数子节点在 recovery DT 里本身就是 `disabled`。这意味着 `wsa` 缺实体虽然仍然成立，但更像板级配置未启用，不像 `wcd9378` 这样是“模块明确想找、但运行态完全没有对象”。

我也重新开了 `machine_dlkm` 的动态调试再触发了一次 probe，结果日志还是只停在 `use aw882xx dailink replace`，并没有把 `wcd9378 component is NULL` 或 `failed to add wcd9378 routes` 这类字符串真正打出来。所以当前最精确的前沿可以更新成：
`snd_soc_bind_card -> snd_soc_add_pcm_runtimes -> -EPROBE_DEFER`
而最值得优先怀疑的 active missing piece，是某条依赖 `wcd9378` 的 runtime 或 link。

---

## 18. 文档整理与阶段性小结

在 TWRP音频手动Bring-up.md 中补入阶段性小结，把从 `aw882xx`、supplier、`-EPROBE_DEFER` 到 `wcd9378` 缺口的收敛压成几条主结论。

整理文档前，先定位需要修改的段落：

```bash
# 搜索文档中已有的相关小节
rg -n '12\.26|12\.25|snd_soc_find_dai|wcd9378|aw882xx' docs/TWRP音频手动Bring-up.md | head -n 80
```

后续多次编辑文档时，都先用 `rg` 定位目标段落再修改，避免覆盖他人改动：

```bash
# 搜索技巧小节位置
rg -n '12\.26\.5|12\.26\.6|DT 定向抽取技巧|排障技巧清单' docs/TWRP音频手动Bring-up.md | head -n 10
```

```bash
# 搜索结论段位置
rg -n '12\.26\.1|12\.26\.2|12\.26\.3|12\.26\.4|drivers_probe|snd_soc_find_dai|asoc-codec-names' docs/TWRP音频手动Bring-up.md | head -n 40
```

```bash
# 搜索旧结论需要修正的文本
rg -n 'DT 输入面不完整|asoc-codec-names|wcd9378|wsa' docs/TWRP音频手动Bring-up.md | head -n 80
```

```bash
# 搜索结论和 WSA backend 相关段落
rg -n '12\.26\.|RX-6|asoc-codec-names|devm_snd_soc_register_card|这轮已经验证过有效的排障技巧' docs/TWRP音频手动Bring-up.md | head -n 50
```

```bash
# 搜索具体小节编号
rg -n '12\.26\.8|wsa-codec\.1 component is NULL|WSA backend 被宣告使用' docs/TWRP音频手动Bring-up.md | head -n 10
```

---

## 19. 用 kprobe 直接抓 snd_soc_find_dai 的入参名称

### 19.1 尝试结构体偏移取字段

只做 tracing 能力探测，目标是确认能不能用 `set_ftrace_filter` 或类似入口，把 `snd_soc_add_pcm_runtimes` 的内部调用链抓出来。

```bash
adb shell 'cd /sys/kernel/debug/tracing 2>/dev/null || exit 1; echo ---files---; ls | grep -E "current_tracer|available_tracers|set_ftrace_filter|set_graph_function|set_graph_notrace|trace_options"; echo ---tracers---; cat available_tracers 2>/dev/null'

adb shell 'cd /sys/kernel/debug/tracing 2>/dev/null || exit 1; for f in current_tracer set_ftrace_filter set_graph_function set_graph_notrace trace_options; do echo ===$f===; ls -l "$f" 2>/dev/null; done'
```

function tracer 这条路在当前内核上走不通了：`available_tracers` 只有 `nop`，没有 `function` 或 `function_graph`。所以我改用另一种低风险办法，直接探 `snd_soc_find_dai` 入参，尝试把每次 lookup 的 DAI 名称从结构体里捞出来。能成功的话，就能把 defer 压到具体 link。

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; echo > /sys/kernel/debug/tracing/kprobe_events; echo "p:fdai snd_soc_find_dai name0=+0(\$arg1):string name8=+8(\$arg1):string name16=+16(\$arg1):string name24=+24(\$arg1):string" > /sys/kernel/debug/tracing/kprobe_events 2>/tmp/kp.err; rc=$?; echo rc:$rc; cat /tmp/kp.err 2>/dev/null; cat /sys/kernel/debug/tracing/kprobe_events 2>/dev/null; echo > /sys/kernel/debug/tracing/kprobe_events'
```

这个方向可行，内核接受了 `snd_soc_find_dai` 的结构体偏移取字符串。下一步我直接触发一次 probe，看 `0/8/16/24` 这些偏移里哪个是真正的 `dai_name`。

### 19.2 触发一次 probe 看偏移量

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; echo > /sys/kernel/debug/tracing/kprobe_events; echo "p:fdai snd_soc_find_dai name0=+0(\$arg1):string name8=+8(\$arg1):string name16=+16(\$arg1):string name24=+24(\$arg1):string" > /sys/kernel/debug/tracing/kprobe_events; echo 1 > /sys/kernel/debug/tracing/events/kprobes/fdai/enable; echo 0 > /sys/kernel/debug/tracing/trace; echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; cat /sys/kernel/debug/tracing/trace | tail -n 140; echo 0 > /sys/kernel/debug/tracing/events/kprobes/fdai/enable; echo > /sys/kernel/debug/tracing/kprobe_events'
```

如果这次 trace 里能看到像 `aw882xx-aif-*`、`wcd939x_cdc`、`msm-stub-rx` 这类名字，就能把偏移定下来；之后我就能直接抓“最后一个成功 lookup 到了哪组 DAI”。

### 19.3 改用二次解引用语法

直接把结构体字段当字符串读不行，出来的是指针内容的乱码。下一步我改成“先取指针，再二次解引用成字符串”，如果内核接受这种 fetch 语法，就能直接拿到 `dai_name` 或 `component name`。

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; echo > /sys/kernel/debug/tracing/kprobe_events; echo "p:fdai2 snd_soc_find_dai s0=+0(+0(\$arg1)):string s16=+0(+16(\$arg1)):string" > /sys/kernel/debug/tracing/kprobe_events 2>/tmp/kp2.err; rc=$?; echo rc:$rc; cat /tmp/kp2.err 2>/dev/null; cat /sys/kernel/debug/tracing/kprobe_events 2>/dev/null; echo > /sys/kernel/debug/tracing/kprobe_events'
```

**结论**：内核接受了 `+0(+16($arg1))` 这种二次解引用语法。

### 19.4 触发抓取真实 dai_name

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; echo > /sys/kernel/debug/tracing/kprobe_events; echo "p:fdai2 snd_soc_find_dai s0=+0(+0(\$arg1)):string s16=+0(+16(\$arg1)):string" > /sys/kernel/debug/tracing/kprobe_events; echo 1 > /sys/kernel/debug/tracing/events/kprobes/fdai2/enable; echo 0 > /sys/kernel/debug/tracing/trace; echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; cat /sys/kernel/debug/tracing/trace | tail -n 140; echo 0 > /sys/kernel/debug/tracing/events/kprobes/fdai2/enable; echo > /sys/kernel/debug/tracing/kprobe_events'
```

**结论**：`snd_soc_find_dai` 实际查找过的名字可以被直接抓到。目前看到的名字包括 `aw882xx-aif-*`、`wcd939x_cdc`、`rx_macro_rx1..5`、`msm-stub-rx/tx`、`snd-soc-dummy-dai`，没有 `wcd9378` 或 `wsa`。

---

## 20. entry/return 配对抓验证 DAI 查找全部成功

运行态这边又多了一条高价值线索：`snd_soc_find_dai` 实际查找过的名字已经能被直接抓到，而且目前看到的是 `aw882xx-aif-*`、`wcd939x_cdc`、`rx_macro_rx1..5`、`msm-stub-rx/tx`、`snd-soc-dummy-dai`，没有 `wcd9378` 或 `wsa`。我再补最后一刀，把这些 lookup 的返回值一并抓出来，确认是不是“根本没走到缺 DAI”，而是更早就卡在缺 component。

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; echo > /sys/kernel/debug/tracing/kprobe_events; echo "p:fdai_e snd_soc_find_dai s16=+0(+16(\$arg1)):string" > /sys/kernel/debug/tracing/kprobe_events; echo "r:fdai_r snd_soc_find_dai ret=%x0" >> /sys/kernel/debug/tracing/kprobe_events; echo 1 > /sys/kernel/debug/tracing/events/kprobes/fdai_e/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/fdai_r/enable; echo 0 > /sys/kernel/debug/tracing/trace; echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; cat /sys/kernel/debug/tracing/trace | tail -n 220; echo 0 > /sys/kernel/debug/tracing/events/kprobes/fdai_e/enable; echo 0 > /sys/kernel/debug/tracing/events/kprobes/fdai_r/enable; echo > /sys/kernel/debug/tracing/kprobe_events'
```

如果返回值全部非空，那当前就能基本排掉“缺 DAI 名称注册”的可能性，直接把前沿写成“某条后续 link 在 `soc_dai_link_sanity_check` 阶段就被 component 缺失挡住了”。

**目的**：把 `snd_soc_find_dai` 的查找顺序整理成可读序列，看它到底成功处理到哪一组 link 才停。

继续往“失败的那条 link 名字”推进，这一轮先不碰模块，只探内核符号和 tracing，目标是看看能不能直接命中 `soc_find_component` 或 `snd_soc_add_pcm_runtime` 这层函数。

---

## 21. snd_soc_find_dai 完整 lookup 顺序提取

只探内核符号和 tracing，目标是看看能不能直接命中 `soc_find_component` 或 `snd_soc_add_pcm_runtime` 这层函数。

```bash
adb shell 'grep -E "soc_find_component|soc_dai_link_sanity_check|snd_soc_add_pcm_runtime|snd_soc_add_pcm_runtimes|snd_soc_add_pcm_runtime\.|soc_find_component\." /proc/kallsyms | head -n 120'

adb shell 'grep -E "snd_soc_lookup_component|snd_soc_rtd_add_component|soc_probe_link_components|soc_bind_aux_dev|soc_probe_aux_devices" /proc/kallsyms | head -n 120'
```

这批只读探测已经说明一件事：更深层的静态符号还是拿不到，当前能稳定利用的 component 侧入口只有 `snd_soc_lookup_component`。所以下一步我改成从“成功处理了哪些 link”反推断点，先把 `snd_soc_find_dai` 的顺序整理成一组完整链，再看是在哪一组之后停止。我现在只做一次轻量提取，把 `snd_soc_find_dai` 的查找顺序整理成可读序列，目标是看它到底成功处理到哪一组 link 才停。

```bash
adb shell "mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; echo > /sys/kernel/debug/tracing/kprobe_events; echo 'p:fdai_e snd_soc_find_dai s16=+0(+16(\$arg1)):string' > /sys/kernel/debug/tracing/kprobe_events; echo 1 > /sys/kernel/debug/tracing/events/kprobes/fdai_e/enable; echo 0 > /sys/kernel/debug/tracing/trace; echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; cat /sys/kernel/debug/tracing/trace | sed -n \"s/.*s16=\\\"\\([^\\\"]*\\)\\\".*/\\1/p\" | nl -ba; echo 0 > /sys/kernel/debug/tracing/events/kprobes/fdai_e/enable; echo > /sys/kernel/debug/tracing/kprobe_events"
```

（终端曾被 shell 引号卡住，改用独立后台 shell 重新执行后成功提取。）

**结论**：72 次 lookup 顺序中，实际只走到了 `aw882xx-aif-*`、`rx_macro_rx1..5`、`wcd939x_cdc`、`msm-stub-rx/tx`、`snd-soc-dummy-dai`，完全没碰到 `wcd9378`。这基本支持"失败发生在更靠后的 component 校验阶段"。

---

## 22. 尝试抓 snd_soc_lookup_component

现在继续提取 `snd_soc_find_dai` 的顺序序列。

```bash
adb shell "mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; echo > /sys/kernel/debug/tracing/kprobe_events; echo 'p:fdai_e snd_soc_find_dai s16=+0(+16(\$arg1)):string' > /sys/kernel/debug/tracing/kprobe_events; echo 1 > /sys/kernel/debug/tracing/events/kprobes/fdai_e/enable; echo 0 > /sys/kernel/debug/tracing/trace; echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; cat /sys/kernel/debug/tracing/trace | sed -n \"s/.*s16=\\\"\\([^\\\"]*\\)\\\".*/\\1/p\" | nl -ba; echo 0 > /sys/kernel/debug/tracing/events/kprobes/fdai_e/enable; echo > /sys/kernel/debug/tracing/kprobe_events"
```

已经把 `snd_soc_find_dai` 的完整顺序提出来了，当前 probe 在 ASoC runtime 里实际只走到了 `aw882xx-aif-*`、`rx_macro_rx1..5`、`wcd939x_cdc`、`msm-stub-rx/tx`、`snd-soc-dummy-dai` 这几组，完全没碰到 `wcd9378`。这基本支持“失败发生在更靠后的 component 校验阶段”这个判断。下一步我直接探 `snd_soc_lookup_component`，看 component 侧有没有出现显式的空返回或失败名字

```bash
adb shell "mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; echo > /sys/kernel/debug/tracing/kprobe_events; echo 'p:fcomp_e snd_soc_lookup_component drv=+0(\$arg2):string' > /sys/kernel/debug/tracing/kprobe_events; echo 'r:fcomp_r snd_soc_lookup_component ret=%x0' >> /sys/kernel/debug/tracing/kprobe_events; echo 1 > /sys/kernel/debug/tracing/events/kprobes/fcomp_e/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/fcomp_r/enable; echo 0 > /sys/kernel/debug/tracing/trace; echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; cat /sys/kernel/debug/tracing/trace | tail -n 220; echo 0 > /sys/kernel/debug/tracing/events/kprobes/fcomp_e/enable; echo 0 > /sys/kernel/debug/tracing/events/kprobes/fcomp_r/enable; echo > /sys/kernel/debug/tracing/kprobe_events"
```

这条线上没有抓到任何事件，说明当前这轮 defer 至少没有走到公开的 `snd_soc_lookup_component` 符号。我要换一个更接近 runtime 构建边界的办法：直接用源码和 machine dailink 定义对齐刚才那 72 条 DAI 顺序，反推出卡在哪一组 link。

---

## 23. DAI lookup 序列与 machine 内部 link 名称对齐

**目的**：把 72 次 `snd_soc_find_dai` lookup 和 machine 里可见的 BE 名称对齐，判断断点到底落在哪一组 link 前面。

先在源码树中搜索 dailink 相关名称：

```bash
rg -n 'aw882xx-aif-|wcd939x_cdc|rx_macro_rx1|msm-stub-rx|WCD9378_AIF|wcd9378' twrp_a16_compile/ 2>/dev/null | head -n 80
```

```bash
# 扩大搜索范围到整个工作区
rg -rn 'sun-asoc-snd|spf_core_platform|aw882xx-aif|wcd939x_cdc|rx_macro_rx1|msm-stub-rx|msm-stub-tx|WCD9378_AIF' --type-add 'src:*.{c,h,dts,dtsi,txt}' -t src 2>/dev/null | head -n 200
```

```bash
# 遍历所有文件确认搜索范围
find twrp_a16_compile -type f 2>/dev/null | head -n 200
```

### 23.1 提取 machine_dlkm 内 BE link 名称

先把当前已经抓到的 DAI lookup 序列压成可读分组，再顺手复查一次有没有可探的更深层静态符号。

```bash
adb shell 'grep -E "snd_soc_add_pcm_runtime|soc_dai_link_sanity_check|snd_soc_add_pcm_runtimes|snd_soc_bind_card|soc_find_component|snd_soc_lookup_component" /proc/kallsyms | head -n 80'

adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; echo > /sys/kernel/debug/tracing/kprobe_events; echo "p:fdai_e snd_soc_find_dai s16=+0(+16(\$arg1)):string" > /sys/kernel/debug/tracing/kprobe_events; echo 1 > /sys/kernel/debug/tracing/events/kprobes/fdai_e/enable; echo 0 > /sys/kernel/debug/tracing/trace; echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; cat /sys/kernel/debug/tracing/trace | sed -n "s/.*s16=\"\([^\"]*\)\".*/\1/p" | nl -ba | tail -n 120; echo 0 > /sys/kernel/debug/tracing/events/kprobes/fdai_e/enable; echo > /sys/kernel/debug/tracing/kprobe_events'
```

前台共享终端又被引号卡住了，这轮不再用它；我改用独立后台 shell 跑一次性命令，这样不会被当前交互状态拖住。

```bash
adb shell 'grep -E "snd_soc_add_pcm_runtime|soc_dai_link_sanity_check|snd_soc_add_pcm_runtimes|snd_soc_bind_card|soc_find_component|snd_soc_lookup_component" /proc/kallsyms | head -n 80'

adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; echo > /sys/kernel/debug/tracing/kprobe_events; echo "p:fdai_e snd_soc_find_dai s16=+0(+16(\$arg1)):string" > /sys/kernel/debug/tracing/kprobe_events; echo 1 > /sys/kernel/debug/tracing/events/kprobes/fdai_e/enable; echo 0 > /sys/kernel/debug/tracing/trace; echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; sed -n "s/.*s16=\"\([^\"]*\)\".*/\1/p" /sys/kernel/debug/tracing/trace | nl -ba | tail -n 120; echo 0 > /sys/kernel/debug/tracing/events/kprobes/fdai_e/enable; echo > /sys/kernel/debug/tracing/kprobe_events'
```

后台命令已经结束了，但工具层把第二条输出误判掉了；我直接读取后台终端的原始输出，把真正结果捞出来。

已经把 `snd_soc_find_dai` 的完整顺序稳定提出来了，下一步不是再盲探，而是把这 72 次 lookup 和 machine 里可见的 BE 名称对齐，判断断点到底落在哪一组 link 前面。


```bash
adb shell 'strings /vendor_dlkm/lib/modules/machine_dlkm.ko | grep -E "^CODEC_DMA-LPAIF_|^PCM_|^TDM-LPAIF_|^BTFM_PROXY|^USB_AUDIO|^AUXPCM|^VA_|^PROXY_|^DISPLAY_PORT|^wsa-codec|^wcd9378_|^wcd939x_" | sort -u | nl -ba | head -n 260'
```

### 23.2 运行态 ASoC dais 对照

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; cat /sys/kernel/debug/asoc/dais 2>/dev/null | sort -u | nl -ba | grep -E "rx_macro|tx_macro|va_macro|msm-stub|aw882xx|wcd939x|btaudio"'
```

### 23.3 特殊字符串确认

```bash
adb shell 'strings /vendor_dlkm/lib/modules/machine_dlkm.ko | grep -i -E "rx_macro_rx6|rx_macro_echo|va_macro_tx[123]|tx_macro_tx[123]|msm-stub-rx|msm-stub-tx|wcd939x_cdc|aw882xx-aif" | sort -u'
```

machine_dlkm 里的 link 名称已经说明两件事：一是 `CODEC_DMA-LPAIF_RXTX-RX-4` 根本不存在，但 `RX-5/6` 存在；二是模块字符串里明确还有 `rx_macro_rx6`、`tx_macro_tx1/2`、`va_macro_tx1/2/3`、`wcd9378_*` 这批后续对象。现在要确认运行态 ASoC debugfs 里到底暴露了哪些组件和 DAI，判断卡在 `RX-6` 之后还是更靠后。Optimizing tool selection...

### 23.4 运行态 ASoC debugfs 全量读取

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; ls -R /sys/kernel/debug/asoc 2>/dev/null | head -n 200'
```

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; for f in /sys/kernel/debug/asoc/*; do echo ====:$f; [ -f "$f" ] && head -n 80 "$f"; done'
```

**结论**：运行态 debugfs 把边界压得更窄了。`tx_macro_tx1/2/3`、`rx_macro_rx6`、`va_macro_tx1/2/3` 都实际存在，缺的不是这些 DAI；真正缺的是 component 层的 `wcd9378-codec` 和整组 `wsa-codec.*`。

---

## 24. 用 drivers_probe 稳定重放 sound probe（关键技巧发现）

**目的**：找到稳定重触发 probe 的方法，因为之前的触发方式不稳定。

### 24.1 检查设备当前状态

```bash
adb shell 'ls /sys/bus/platform/drivers | grep asoc'
```

```bash
adb shell 'grep -R "soc:spf_core_platform:sound" /sys/bus/platform/drivers/*/bind 2>/dev/null || true'
```

```bash
adb shell 'readlink /sys/bus/platform/devices/soc:spf_core_platform:sound/driver 2>/dev/null'
```

```bash
adb shell 'ls -l /sys/bus/platform/devices/soc:spf_core_platform:sound 2>/dev/null'
```

现在直接抓 component lookup。只要 `snd_soc_lookup_component` 里出现 `wcd9378-codec` 或 `wsa-codec.*` 并返回空，这条链就闭合了，不需要再靠猜。

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; cd /sys/kernel/debug/tracing; echo 0 > tracing_on; echo > trace; echo > kprobe_events; echo "p:lk snd_soc_lookup_component name=+0(\$arg2):string" >> kprobe_events; echo "r:lr snd_soc_lookup_component ret=\$retval" >> kprobe_events; echo 1 > events/kprobes/lk/enable; echo 1 > events/kprobes/lr/enable; echo 1 > tracing_on; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe; sleep 1; echo 0 > tracing_on; cat trace | tail -n 200'

adb shell 'dmesg | tail -n 120 | grep -i -E "wcd9378|wsa-codec|snd_soc|asoc|defer|sound"'
```

这次没打到 trace，不是结论反转，而是重触发 probe 没命中。现在要先把“如何稳定重放一次 `sound` deferred probe”这件事重新钉死，再挂 component 级探针。

### 24.2 尝试 uevent 触发（不稳定）

```bash
adb shell 'dmesg -c >/dev/null 2>&1; echo add > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/uevent; sleep 1; dmesg | tail -n 80'
```

### 24.3 drivers_probe 方式（稳定）

```bash
adb shell 'ls /sys/kernel/debug | grep defer; ls /sys/kernel | grep defer; find /sys -maxdepth 3 -name "*defer*" 2>/dev/null | head -n 80'

adb shell 'test -e /sys/bus/platform/devices/soc:spf_core_platform:sound/driver_override && cat /sys/bus/platform/devices/soc:spf_core_platform:sound/driver_override || echo no_override'

adb shell 'find /sys/bus/platform/devices/soc:spf_core_platform:sound -maxdepth 2 -type l -o -type f 2>/dev/null | sed -n "1,120p"'

adb shell 'ls -l /sys/bus/platform/drivers/sun-asoc-snd 2>/dev/null; find /sys/bus/platform/drivers/sun-asoc-snd -maxdepth 1 -type f -o -type l 2>/dev/null | sed -n "1,120p"'

adb shell 'cat /sys/kernel/debug/devices_deferred 2>/dev/null | grep sound'

`sun-asoc-snd` 这个驱动目录没有 `bind/unbind`，说明重放不能走我们之前想的那条标准路径。现在转到设备侧 sysfs，看能不能用 `uevent` 或目标目录下的 probe 入口把 deferred 再推一次。

adb shell 'ls -l /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound 2>/dev/null; find /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound -maxdepth 1 2>/dev/null | sed -n "1,120p"'

adb shell 'cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/uevent 2>/dev/null'

adb shell 'ls /sys/bus/platform 2>/dev/null; test -e /sys/bus/platform/drivers_probe && echo has_drivers_probe || echo no_drivers_probe'

adb shell 'dmesg -c >/dev/null 2>&1; echo add > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/uevent; sleep 1; dmesg | tail -n 80'

adb shell 'dmesg -c >/dev/null 2>&1; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe; sleep 1; dmesg | tail -n 80'
```

`drivers_probe` 这条路是有效的，刚才已经稳定重放了一次完整 machine probe。现在把同一触发方式挂到 `snd_soc_lookup_component` 上，直接拿缺失 component 名字和返回值。

---

## 25. 尝试 component lookup 探针（未命中）

**准备**：先在本地内核源码树中搜索相关函数原型，以确定 kprobe 应该抓哪个参数：

### 25.1 挂 snd_soc_lookup_component

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; cd /sys/kernel/debug/tracing; echo 0 > tracing_on; echo > trace; echo > kprobe_events; echo "p:lk snd_soc_lookup_component name=+0(\$arg2):string" >> kprobe_events; echo "r:lr snd_soc_lookup_component ret=\$retval" >> kprobe_events; echo 1 > events/kprobes/lk/enable; echo 1 > events/kprobes/lr/enable; echo 1 > tracing_on; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe; sleep 1; echo 0 > tracing_on; cat trace | tail -n 200'

adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; cat /sys/kernel/debug/tracing/kprobe_events 2>/dev/null'
```

`snd_soc_lookup_component` 本身注册成功但没有命中，说明真正走的很可能是 `snd_soc_lookup_component_nolocked`。这不是坏消息，反而更接近核心路径了，我切到那个符号继续抓。

**结论**：`snd_soc_lookup_component` 注册成功但没有命中，说明真正走的很可能是 `snd_soc_lookup_component_nolocked`。切到那个符号继续抓。

### 25.2 切到 snd_soc_lookup_component_nolocked

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; cd /sys/kernel/debug/tracing; echo 0 > tracing_on; echo > trace; echo "-:lk" >> kprobe_events; echo "-:lr" >> kprobe_events; echo "p:ln snd_soc_lookup_component_nolocked name=+0(\$arg2):string" >> kprobe_events; echo "r:rn snd_soc_lookup_component_nolocked ret=\$retval" >> kprobe_events; echo 1 > events/kprobes/ln/enable; echo 1 > events/kprobes/rn/enable; echo 1 > tracing_on; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe; sleep 1; echo 0 > tracing_on; cat trace | tail -n 200'
```

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; cat /sys/kernel/debug/tracing/kprobe_events 2>/dev/null'
```

component lookup 这条路没有打到，说明 defer 不是经由那两个全局 helper 暴露出来的。接下来我回到已经验证可命中的 `snd_soc_find_dai`，用同样的 `drivers_probe` 方式把完整顺序重新抓一遍，确认它到底停在 `rx5` 还是只是之前抓短了。

---

## 26. 用 drivers_probe 重新抓 snd_soc_find_dai 完整顺序

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; cd /sys/kernel/debug/tracing; echo 0 > tracing_on; echo > trace; echo > kprobe_events; echo "p:fd snd_soc_find_dai name=+0(+16(\$arg1)):string" >> kprobe_events; echo 1 > events/kprobes/fd/enable; echo 1 > tracing_on; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe; sleep 1; echo 0 > tracing_on; cat trace | grep fd: | sed -n "1,240p"'
```

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; cd /sys/kernel/debug/tracing; echo 0 > tracing_on; echo > trace; echo > kprobe_events; echo "p:fr snd_soc_find_dai name=+0(+16(\$arg1)):string" >> kprobe_events; echo "r:rr snd_soc_find_dai ret=\$retval" >> kprobe_events; echo 1 > events/kprobes/fr/enable; echo 1 > events/kprobes/rr/enable; echo 1 > tracing_on; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe; sleep 1; echo 0 > tracing_on; cat trace | grep -E "fr:|rr:" | sed -n "1,260p"'
```

**结论**：完整顺序重新抓稳了。`snd_soc_add_pcm_runtimes+0x614/0x710` 两个固定偏移对应一种 link 模式——在 `rx5/wcd939x` 后面直接转入大量 dummy/stub，再没有 `rx6/tx_macro/va_macro`。真正的断点可以从顺序反推：machine 明明有 6 个 `CODEC_DMA-LPAIF_RXTX-RX-*`，但运行时只走到 5 组 `rx_macro_rxN + wcd939x_cdc`。缺掉的那一组最可疑的是 `RX-6`，而模块字符串里旁边又有 `rx_macro_rx6` 和 `wcd9378_cdc`。

---

## 27. machine_dlkm.ko 内部错误字符串深度挖掘

先把相关字符串的相对位置拉出来：

```bash
adb shell 'strings -td /vendor_dlkm/lib/modules/machine_dlkm.ko | grep -E "CODEC_DMA-LPAIF_RXTX-RX-[056]|rx_macro_rx[56]|wcd9378_cdc|wcd939x_cdc" | sed -n "1,80p"'
```

```bash
adb shell 'strings -td /vendor_dlkm/lib/modules/machine_dlkm.ko | grep -E "wsa-codec\.[1-4]|CODEC_DMA-LPAIF_WSA2?-RX-[01]|CODEC_DMA-LPAIF_WSA2?-TX-[012]" | sed -n "1,120p"'
```

这里已经挖到比 probe 更硬的东西了：`machine_dlkm.ko` 里直接带着 `wsa-codec.N component is NULL` 这些错误字符串，说明 machine 驱动自己就有针对 component 缺失的判错分支，不是我在外面硬推的。下一步把 `wcd9378` 同类字符串一并找出来，看它是不是同一类“component is NULL”或 codec 路由失败路径。

```bash
adb shell 'strings /vendor_dlkm/lib/modules/machine_dlkm.ko | grep -i -E "wcd9378|component is NULL|failed to add .*routes|codec is NULL|wcd939x|wsa-codec" | sort -u | sed -n "1,200p"'
```

```bash
adb shell 'strings /vendor_dlkm/lib/modules/machine_dlkm.ko | grep -i -E "rx6|RX-6|wcd9378|wsa-codec|component|route" | sed -n "1,240p"'
```

**结论**：证据链明显收敛到 `RX-6 / wcd9378` 支路——运行时 `rx_macro_rx6` DAI 明明存在但 `snd_soc_find_dai` 顺序里始终没进入；`machine_dlkm.ko` 暴露了 `CODEC_DMA-LPAIF_RXTX-RX-6`、`rx_dma_rx6_codecs`、`wcd9378_cdc`、`failed to add wcd9378 routes` 整组字符串。

---

## 28. 运行态 DT 属性比对

再压实一层：直接看运行态 DT的 `sound` 子树里 `rx_dma_rx6_*` 节点/属性是否存在，以及它引用的是不是 `wcd9378` 相关 codec：

```bash
adb shell 'find /proc/device-tree/soc/spf_core_platform/sound -maxdepth 3 | grep -E "rx6|rx_dma_rx6|wcd9378|wsa" | sed -n "1,200p"'
```

```bash
adb shell 'grep -R -a -n "wcd9378\|rx_dma_rx6\|rx_macro_rx6" /proc/device-tree/soc/spf_core_platform/sound 2>/dev/null | sed -n "1,200p"'
```

```bash
adb shell 'find /proc/device-tree/soc/spf_core_platform/sound -maxdepth 2 -type f | sed -n "1,200p"'
```

运行态 DT 的 `sound` 节点比预期更扁平，没有把每条 `rx_dma_rx6_*` 子节点直接暴露出来，但它至少还保留了全局 `asoc-codec` / `asoc-codec-names` 这层。再往下看这两个属性，就能判断 DT 这边到底声明了哪些 codec 端点。

```bash
adb shell 'xxd -g 1 /proc/device-tree/soc/spf_core_platform/sound/asoc-codec-names 2>/dev/null | head -n 80'
```

```bash
adb shell 'xxd -g 4 /proc/device-tree/soc/spf_core_platform/sound/asoc-codec 2>/dev/null | head -n 80'
```

```bash
adb shell 'strings /proc/device-tree/soc/spf_core_platform/sound/asoc-codec-names 2>/dev/null'
```

**结论**：运行态 DT 的 `sound/asoc-codec-names` 里只有 `msm-stub-codec.1`、`lpass-cdc`、`wcd939x_codec`。全局 codec 名单里没有 `wcd9378` 或 `wsa`。不是 machine 到运行时才"偶然没找到 component"，而是 DT 提供的 codec 集合一开始就不完整。

这轮还钉死了重放入口：对 `soc:spf_core_platform:sound` 执行 `echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe` 可稳定重新进入 `msm_asoc_machine_probe`。关键结论：

1. 运行态 ASoC `dais` 里已有 `rx_macro_rx6`、`tx_macro_tx1..3`、`va_macro_tx1..3`——这些 DAI 本身不是"没注册"
2. 但完整 `snd_soc_find_dai` 顺序只走到 5 组 `rx_macro_rx1..5 + wcd939x_cdc`，始终没进入 `rx_macro_rx6`
3. 运行态 `sound/asoc-codec-names` 只有 3 个 codec，没有 `wcd9378`、没有 `wsa-codec.*`

结合 `machine_dlkm.ko` 字符串：`CODEC_DMA-LPAIF_RXTX-RX-6`、`rx_dma_rx6_codecs`、`wcd9378_cdc`、`qcom_wcd9378_rx_audio_map`、`failed to add wcd9378 routes`、`wsa-codec.N component is NULL`。

最像根因的描述：恢复环境的运行态 `sound` DT 输入面不完整，提供给 machine 的 codec 集合只有 `stub + lpass-cdc + wcd939x`，没有 `wcd9378`、也没有 `wsa`。依赖 `wcd9378` 的 `RX-6` link 在 `snd_soc_add_pcm_runtimes` 里进不到正常的 `snd_soc_find_dai` / card bind 流程。

---

## 29. 开始两条线并行推进

两条线一起推进：一条去源码/DT 侧找 `sound` 节点原本应声明的 codec 集合，另一条继续从设备上把 recovery 当前的 `sound` 节点属性读全。

### 29.1 搜索 DT 源文件

先在工作区中搜索 DT 定义和 sound 相关配置：

```bash
# 搜索机型相关关键字
rg -rn 'ossi|infiniti|oneplus pad2 pro|pad2 pro' --type-add 'dt:*.{dts,dtsi,dtb,dtbo,txt,md}' -t dt 2>/dev/null | head -n 200
# 200 results
```

```bash
# 搜索 DT 相关文件
find . \( -name '*.dts' -o -name '*.dtsi' -o -name '*.dtb' -o -name '*.dtbo' -o -name '*.img' -o -name '*.zip' \) 2>/dev/null | head -n 300
# 300 matches
```

```bash
# 搜索 sound 相关配置属性
rg -rn 'qcom,sun-asoc-snd|asoc-codec-names|asoc-codec|wcd9378|wsa-codec|wcd939x_codec|sound' --type-add 'cfg:*.{dts,dtsi,txt,conf,xml,mk,rc}' -t cfg 2>/dev/null | head -n 200
# 200 matches
```

```bash
# 更宽泛的 wcd9378/wsa 搜索
rg -rn 'wcd9378|wcd939x_codec|wsa-codec|asoc-codec-names|qcom,sun-asoc-snd|qcom,.*asoc.*snd' 2>/dev/null | head -n 200
```

```bash
# 在 audio_dtb_probe 目录搜索
rg -rn 'infiniti|ossi' audio_dtb_probe/ 2>/dev/null | head -n 20
# 1 result
find audio_dtb_probe \( -name '*.dts' -o -name '*.dtsi' -o -name '*.dtb' -o -name '*.dtbo' \) 2>/dev/null | head -n 20
# no matches
find audio_dtb_probe -type f 2>/dev/null | head -n 20
# 15 matches
```

### 29.2 读全运行态 sound 属性

```bash
adb shell 'for f in compatible name qcom,model asoc-codec-names qcom,audio-core-list qcom,upd_backends_used; do echo ====:$f; [ -f /proc/device-tree/soc/spf_core_platform/sound/$f ] && xxd -g 1 /proc/device-tree/soc/spf_core_platform/sound/$f | head -n 80; done'
```

```bash
adb shell 'for n in asoc-codec-names qcom,audio-routing qcom,audio-core-list qcom,upd_backends_used; do echo ====:$n; [ -f /proc/device-tree/soc/spf_core_platform/sound/$n ] && strings /proc/device-tree/soc/spf_core_platform/sound/$n 2>/dev/null; done'
```

新的增量有两个。第一，recovery 运行态 `sound` 节点里 `qcom,model` 仍是正常的 `sun-mtp-snd-card`，不是名字被改坏；第二，`qcom,upd_backends_used` 明确还是 `wsa`，但同一个节点的 `asoc-codec-names` 却只有 `msm-stub-codec.1`、`lpass-cdc`、`wcd939x_codec`。这说明现在更像是“后端类型标志还在，具体 codec 列表却被裁掉了”。

### 29.3 继续在本地和配置中搜索

```bash
# 在更广泛的文件类型中搜索
rg -rn 'asoc-codec-names|qcom,upd_backends_used|qcom,sun-asoc-snd|wcd939x_codec|wcd9378_codec|wsa-codec' --type-add 'cfg:*.{dts,dtsi,dtb,dtbo,txt,md,rc,xml}' -t cfg 2>/dev/null | head -n 40
# 34 matches
```

```bash
# 搜索 ossi 相关 DT 文件
find . -name '*ossi*' \( -name '*.dts' -o -name '*.dtsi' -o -name '*.dtb' -o -name '*.dtbo' -o -name '*.img' -o -name '*.bin' \) 2>/dev/null | head -n 20
# 8 matches

```

源码树里还没直接搜到现成的 DTS 命中，但设备侧已经多了一条很关键的矛盾：`qcom,upd_backends_used` 仍然是 `wsa`，说明 machine 预期确实还要走 WSA 后端；可 `asoc-codec-names` 却没有任何 `wsa-codec.*` 或 `wcd9378_codec`。现在最有价值的是去本地已解包产物里找 recovery 镜像和 stock DT 的原始 `sound` 输入，确认到底是解包前就少，还是 recovery 运行时才少。

### 29.4 搜索 vendor_boot 和 dtb 产物

```bash
# 搜索 docs 中的相关讨论
rg -rn 'vendor_boot|dtb|magiskboot|asoc-codec-names|wcd9378|wsa-codec' docs/ 2>/dev/null | head -n 120
# 120 matches
```

```bash
# 搜索 vendor_boot 和 dtb 文件
find . \( -name '*vendor_boot*' \) 2>/dev/null
# 20 matches
find . \( -name '*kernel_dtb*' \) 2>/dev/null
# no matches
find . \( -name '*dtb*' \) 2>/dev/null
# 20 matches
```

已经找到现成的原厂 vendor_boot_a.img 和两个解包目录。下一步在现成 dtb 产物上对比 `sound` 节点相关字符串，判断原厂输入面是否本来就有 `wcd9378` / `wsa`。

```bash
strings /Volumes/Case-sensitive\ APFS/TWRP/audio_dtb_probe/vendor_boot_unpack/dtb | grep -E 'qcom,sun-asoc-snd|asoc-codec-names|wcd9378|wsa-codec|wcd939x_codec|lpass-cdc|msm-stub-codec|RXTX-RX-6|rx_macro_rx6' | sed -n '1,200p'
```

原厂 `vendor_boot` 的 dtb 至少已经说明一件事：`wsa-macro`、`wsa2-macro` 这些路径在原始输入里是存在的，不是 recovery 凭空编出来的。现在差最后一步，把这个 dtb 里的 `sound` 节点真正读出来，确认原厂 `asoc-codec-names` 到底有没有比 recovery 运行态多出 `wcd9378` / `wsa`。

---

## 30. stock vendor_boot dtb 反编译分析

### 30.1 用 dtc 反编译 stock dtb

现成的 `vendor_boot` 解包产物和本地 dtc 都在，接下来直接把 dtb 反编译/定向抽取 `sound` 节点，看看 stock 输入面的 `asoc-codec-names` 到底长什么样。

```bash
./twrp_a16_compile/prebuilts/tools-lineage/darwin-x86/dtc/dtc -I dtb -O dts -q -o audio_dtb_probe/vendor_boot_unpack/vendor_boot_sound.dts audio_dtb_probe/vendor_boot_unpack/dtb && rg -n "sound|asoc-codec|wcd9378|wsa-codec|wcd939x|lpass-cdc|msm-stub-codec|spf_core_platform" audio_dtb_probe/vendor_boot_unpack/vendor_boot_sound.dts | sed -n '1,260p'
```

```bash
./twrp_a16_compile/prebuilts/tools-lineage/darwin-x86/dtc/dtc -I dtb -O dts -q -o audio_dtb_probe/unpack_compare/unpack_compare_sound.dts audio_dtb_probe/unpack_compare/dtb && rg -n "sound|asoc-codec|wcd9378|wsa-codec|wcd939x|lpass-cdc|msm-stub-codec|spf_core_platform" audio_dtb_probe/unpack_compare/unpack_compare_sound.dts | sed -n '1,260p'
```

两个 stock dtb 反编译结果一致，说明解包源没问题。base `vendor_boot` 里的 `sound` 节点只有兼容串和几个接口开关，没有 `asoc-codec-names`。说明不能把 base dtb 当成最终输入面，下一步查 dtbo/overlay 有没有把 codec 名单补进去。

先检查 dtbo_a.img overlay 里有没有带相关属性：

```bash
strings audio_dtb_probe/dtbo_a.img | grep -E 'asoc-codec-names|wcd9378|wsa-codec|wcd939x_codec|lpass-cdc|msm-stub-codec|sun-asoc-snd|upd_backends_used|qcom,model' | sed -n '1,240p'
```

同时把运行态 `sound` 属性清单抓全：

```bash
adb shell 'for f in /proc/device-tree/soc/spf_core_platform/sound/*; do echo ==== ${f##*/}; [ -f "$f" ] && (strings "$f" 2>/dev/null || xxd -g 4 "$f" 2>/dev/null | head -n 8); done' | sed -n '1,260p'
```

运行态关键信息：`qcom,model = sun-mtp-snd-card`、`asoc-codec-names` 只有 3 项、`qcom,upd_backends_used` 确实存在。把运行态关键属性值读干净：

现在能确定 overlay 里确实带了 `asoc-codec-names`、`qcom,model`、`qcom,upd_backends_used` 这些属性名，但还没把具体值拆出来。我先把运行态关键属性值读干净，再把 dtbo 真正解出来，确认这些值是不是由 overlay 写入。

```bash
adb shell 'for f in qcom,upd_backends_used qcom,audio-core-list qcom,wsa-max-devs qcom,dedicated-wsa2 qcom,mi2s-audio-intf qcom,auxpcm-audio-intf; do echo ==== $f; strings /proc/device-tree/soc/spf_core_platform/sound/$f 2>/dev/null || xxd -g 4 /proc/device-tree/soc/spf_core_platform/sound/$f 2>/dev/null | head -n 8; done'
```

【此处的 dtc + rg 定向抽取 dtb 技巧被记入文档和 repo memory】

---

## 30.2 回归主线：继续 dtbo overlay 分析

回到主线收窄 `sound` 最后一跳，确认 `wsa/wcd9378` 缺口是运行态合成裁掉的还是 overlay 本来就没给。

先读运行态二进制属性，并尝试 magiskboot 解包 dtbo：

```bash
adb shell 'for f in qcom,upd_backends_used qcom,audio-core-list qcom,wsa-max-devs qcom,dedicated-wsa2 qcom,mi2s-audio-intf qcom,auxpcm-audio-intf qcom,tdm-audio-intf; do echo ==== $f; xxd -g 4 /proc/device-tree/soc/spf_core_platform/sound/$f 2>/dev/null | head -n 8; done'
```

```bash
cd audio_dtb_probe/dtbo_unpack && rm -f kernel kernel_dtb dtb dtbo extra* new-* && /Volumes/Case-sensitive\ APFS/TWRP/magiskboot unpack ../dtbo_a.img && ls -la
```

```bash
strings audio_dtb_probe/dtbo_a.img | grep -E 'asoc-codec-names|qcom,model|qcom,upd_backends_used|wcd9378|wsa-codec|wcd939x_codec|msm-stub-codec.1|lpass-cdc' | sed -n '1,200p'
```

`adb` 出现多设备，后续命令固定序列号。确认设备并重跑：

```bash
adb devices
```

```bash
pwd
```

锁定 `-s 70a91f89` 后继续：

```bash
adb -s 70a91f89 shell 'for f in qcom,upd_backends_used qcom,audio-core-list qcom,wsa-max-devs qcom,dedicated-wsa2 qcom,mi2s-audio-intf qcom,auxpcm-audio-intf qcom,tdm-audio-intf; do echo ==== $f; xxd -g 4 /proc/device-tree/soc/spf_core_platform/sound/$f 2>/dev/null | head -n 8; done'
```

```bash
cd /Volumes/Case-sensitive\ APFS/TWRP/audio_dtb_probe/dtbo_unpack && find . -maxdepth 1 \( -name kernel -o -name kernel_dtb -o -name dtb -o -name dtbo -o -name 'extra*' -o -name 'new-*' \) -delete && /Volumes/Case-sensitive\ APFS/TWRP/magiskboot unpack ../dtbo_a.img && ls -la
```

```bash
strings /Volumes/Case-sensitive\ APFS/TWRP/audio_dtb_probe/dtbo_a.img | grep -E 'asoc-codec-names|qcom,model|qcom,upd_backends_used|wcd9378|wsa-codec|wcd939x_codec|msm-stub-codec.1|lpass-cdc' | sed -n '1,200p'
```

主线又往前推了一小步：recovery 运行态 `sound/qcom,upd_backends_used` 的值已经明确就是 `wsa`，不是空属性；但同一个节点的 `asoc-codec-names` 里仍然没有任何 `wsa-codec.*` 或 `wcd9378`。这说明现在更像是“后端类型标志还在，具体 codec 输入被裁掉了”。

dtbo_a.img 已经被解开，只是 magiskboot 输出太长把关键信息淹掉了。下一步我直接看解包目录里生成了什么文件，再对 overlay 本体做定向抽取，不再读整段噪音输出。

# Searched for files matching `**/audio_dtb_probe/dtbo_unpack/**`, no matches

cd /Volumes/Case-sensitive\ APFS/TWRP/audio_dtb_probe/dtbo_unpack && file * 2>/dev/null | sed -n '1,80p'

`magiskboot unpack` 这条路对这个 dtbo_a.img 没有产出可读文件，我换一条更适合 DTBO 表镜像的路径，直接用现成的 mkdtboimg.py / `extract_dtb` 类工具把 overlay 条目拆出来。


```bash
find . -name 'mkdtboimg.py' 2>/dev/null | head -n 10
# 2 matches
```

```bash
find . -name 'extract_dtb*' 2>/dev/null | head -n 10
# 4 matches
```

尝试使用：

```bash
python3 /Volumes/Case-sensitive\ APFS/TWRP/twrp_a12_compile/system/libufdt/utils/src/mkdtboimg.py dump /Volumes/Case-sensitive\ APFS/TWRP/audio_dtb_probe/dtbo_a.img | sed -n '1,200p'
```

`mkdtboimg.py dump` 这条路能走，但当前终端里被中断了。我先做两件更稳的短动作：确认 dtbo_a.img 的真实格式，再看 extract_dtb 的用法，避免继续在长输出里空耗。

```bash
file /Volumes/Case-sensitive\ APFS/TWRP/audio_dtb_probe/dtbo_a.img
```

```bash
'/Volumes/Case-sensitive APFS/TWRP/twrp_a16_compile/prebuilts/misc/linux-x86/libufdt/extract_dtb' --help | head -n 80
# exec format error (Linux binary on mac)
```

```bash
python3 /Volumes/Case-sensitive\ APFS/TWRP/twrp_a16_compile/system/libufdt/utils/src/mkdtboimg.py --help | head -n 80
```

extract_dtb 是 Linux 预编译版（mac 上 `exec format error`），mkdtboimg.py 能跑。改用后台 shell 重跑：

```bash
/Volumes/Case-sensitive\ APFS/TWRP/twrp_a16_compile/prebuilts/misc/linux-x86/libufdt/extract_dtb --help | head -n 40
```

```bash
python3 twrp_a16_compile/system/libufdt/utils/src/mkdtboimg.py --help | head -n 60
```

```bash
python3 twrp_a16_compile/system/libufdt/utils/src/mkdtboimg.py dump audio_dtb_probe/dtbo_a.img | head -n 120
```

dtbo_a.img 已确认是标准 DTBO table，有 16 个 overlay 条目。按 offset/size 切出条目做字符串和 DTS 检查：

```bash
dd if=audio_dtb_probe/dtbo_a.img of=audio_dtb_probe/dtbo_entry0.dtb bs=1 skip=544 count=1252840 status=none && strings audio_dtb_probe/dtbo_entry0.dtb | grep -E 'asoc-codec-names|qcom,model|qcom,upd_backends_used|wcd9378|wsa-codec|wcd939x_codec|msm-stub-codec.1|lpass-cdc|sun-mtp-snd-card' | sed -n '1,200p'
```

```bash
./twrp_a16_compile/prebuilts/tools-lineage/darwin-x86/dtc/dtc -I dtb -O dts -q -o audio_dtb_probe/dtbo_entry0.dts audio_dtb_probe/dtbo_entry0.dtb && rg -n 'asoc-codec-names|qcom,model|qcom,upd_backends_used|wcd9378|wsa-codec|wcd939x_codec|msm-stub-codec.1|lpass-cdc|sound' audio_dtb_probe/dtbo_entry0.dts | sed -n '1,240p'
```

检查 entry6 是否同样结构：

```bash
dd if=audio_dtb_probe/dtbo_a.img of=audio_dtb_probe/dtbo_entry6.dtb bs=1 skip=7528990 count=1171344 status=none && strings audio_dtb_probe/dtbo_entry6.dtb | grep -E 'asoc-codec-names|qcom,model|qcom,upd_backends_used|wcd9378|wsa-codec|wcd939x_codec|msm-stub-codec.1|lpass-cdc|sun-mtp-snd-card' | sed -n '1,200p'
```

**关键结论**：不是 recovery 运行时把 `wsa/wcd9378` 裁掉，而是 `dtbo` overlay 里的 `sound` 节点本来就只写了 `msm-stub-codec.1`、`lpass-cdc`、`wcd939x_codec` 这 3 个 `asoc-codec-names`，同时 `qcom,upd_backends_used = "wsa"`。"声明要走 `wsa` 后端"和"实际 codec 名单里没有 `wsa`/`wcd9378`"这组矛盾在 overlay 输入面里就已存在。

确认 asoc-codec 具体属性值：

```bash
rg -n 'asoc-codec =|asoc-codec-names =|qcom,upd_backends_used =|qcom,model =' audio_dtb_probe/dtbo_entry0.dts | sed -n '1,40p'
```

在 recovery 运行态确认 ASoC status：

```bash
adb -s 70a91f89 shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; cat /sys/kernel/debug/asoc/components 2>/dev/null; echo ====; cat /sys/kernel/debug/asoc/dais 2>/dev/null' | grep -E 'wcd9378|wsa|wcd939x|rx_macro_rx6|msm-stub|aw882xx'
```

这一步把主线判断改掉了一层：`wcd9378 / wsa` 不在 `asoc-codec-names` 里，未必是 recovery 异常，因为 stock 的 `dtbo` overlay 自己就把 `sound` 节点写成了 `asoc-codec-names = "msm-stub-codec.1", "lpass-cdc", "wcd939x_codec"`，同时又声明 `qcom,upd_backends_used = "wsa"`。也就是说，`asoc-codec-names` 这 3 项很可能是这台机原本就如此，之前把它直接当成“DT 输入面缺失”的结论，需要收紧甚至修正。

搜索 doc 中需修正的旧结论文本：

```bash
rg -n 'DT 输入面不完整|asoc-codec-names|wcd9378|wsa' docs/TWRP音频手动Bring-up.md | head -n 80
# 80 results
```

把修正写回文档和 memory，然后沿修正后的主线继续——既然 stock overlay 自己就只有 3 个 codec 名单，直接看正常系统运行态是不是也没有 `wcd9378/wsa` component：

```bash
adb -s 3B15AN013GM00000 shell su -c 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; cat /sys/kernel/debug/asoc/components 2>/dev/null' | grep -E 'wcd9378|wsa|wcd939x|msm-stub|aw882xx|btfm'
```

```bash
adb -s 3B15AN013GM00000 shell su -c 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; cat /sys/kernel/debug/asoc/dais 2>/dev/null' | grep -E 'wcd9378|wsa|wcd939x|rx_macro_rx6|msm-stub|aw882xx|btaudio'
```

```bash
adb -s 3B15AN013GM00000 shell su -c 'strings /proc/device-tree/soc/spf_core_platform/sound/asoc-codec-names 2>/dev/null; echo ====; xxd -g 4 /proc/device-tree/soc/spf_core_platform/sound/asoc-codec 2>/dev/null | head -n 8'
```

系统侧设备不在线，确认当前状态后回 recovery：

```bash
adb devices
```

```bash
adb -s 70a91f89 shell 'cat /proc/asound/cards 2>/dev/null; echo ====; ls -l /dev/snd 2>/dev/null'
```

---

## 31. 回到 recovery 查 machine 内部符号

把主线从 `wcd9378` 猜测再往里收一层：既然 stock overlay 自己就只有 3 个 codec 名单，那现在更该直接找 machine 驱动内部真正会返回 `-EPROBE_DEFER` 的函数，而不是继续盯 `asoc-codec-names`。先查这些 machine 内部符号在不在 `kallsyms` 里。

```bash
adb -s 70a91f89 shell 'grep -E "msm_populate_dai_link_component_of_node|msm_asoc_machine_probe|extend_codec_be_dailink|populate_snd_card_dailinks|snd_soc_add_pcm_runtimes|snd_soc_bind_card|snd_soc_find_dai" /proc/kallsyms | head -n 120'
```

```bash
adb -s 70a91f89 shell 'strings /vendor_dlkm/lib/modules/machine_dlkm.ko | grep -E "msm_populate_dai_link_component_of_node|could not find component for|component is error|dailink codec component alloc failed|failed to add routes" | sed -n "1,120p"'
```

```bash
adb -s 70a91f89 shell 'grep -E "msm_populate_dai_link_component_of_node|snd_soc_lookup_component_nolocked|snd_soc_lookup_component|snd_soc_add_pcm_runtimes|snd_soc_bind_card" /proc/kallsyms | tail -n 80'
```

`machine_dlkm` 里真正像根因的错误路径已经更清楚了：它明确有 `msm_populate_dai_link_component_of_node` 和 `could not find component for ...` 这类分支，但该函数本身在 `kallsyms` 里没暴露成可直接探针的符号。下一步我回到还能探的公共 helper，重新抓 `snd_soc_lookup_component_nolocked`，看这次能不能直接打到缺失 component 的名字。

```bash
adb -s 70a91f89 shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; cd /sys/kernel/debug/tracing; echo 0 > tracing_on; echo > trace; echo > kprobe_events; echo "p:lkn snd_soc_lookup_component_nolocked name=+0(\$arg2):string" >> kprobe_events; echo "r:rkn snd_soc_lookup_component_nolocked ret=\$retval" >> kprobe_events; echo 1 > events/kprobes/lkn/enable; echo 1 > events/kprobes/rkn/enable; echo 1 > tracing_on; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe; sleep 1; echo 0 > tracing_on; cat trace | tail -n 200'
```

```bash
adb -s 70a91f89 shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; cat /sys/kernel/debug/tracing/kprobe_events 2>/dev/null'
```

上一次没抓到是因为旧的 `find_dai` 事件还挂着。先把旧事件逐个关掉，只保留 `lkn/rkn`，再重放一次：

```bash
adb -s 70a91f89 shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; cd /sys/kernel/debug/tracing; echo 0 > tracing_on; for e in fd fr rr lk lr ln rn; do test -e events/kprobes/$e/enable && echo 0 > events/kprobes/$e/enable; done; echo 0 > events/kprobes/lkn/enable; echo 0 > events/kprobes/rkn/enable; echo > trace; echo 1 > events/kprobes/lkn/enable; echo 1 > events/kprobes/rkn/enable; echo 1 > tracing_on; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe; sleep 1; echo 0 > tracing_on; cat trace | tail -n 200'
```

**结论**：`lookup_component` 这次还是没命中，说明 machine 在更私有的组装路径里就先返回了。转到离线分析模块本体。

---

## 32. 离线反汇编：machine_dlkm.ko

先搜索本机和 NDK 中可用的 ELF 工具：

```bash
find . -name 'machine_dlkm.ko' 2>/dev/null | head -n 10
# no matches
```

```bash
find . -name '*llvm-objdump*' -type f 2>/dev/null | head -n 20
# 17 matches
```

```bash
find . -name 'nm' -type f 2>/dev/null | head -n 10
# 6 matches
```

```bash
find . -name 'llvm-nm' -type f 2>/dev/null | head -n 10
# 9 matches
```

确认本机可用工具：

```bash
command -v llvm-objdump || true; command -v llvm-nm || true; command -v readelf || true; command -v nm || true; command -v objdump || true
```

用户提供了 NDK `llvm-readelf` 路径：`/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-readelf`。

拉取模块：

```bash
adb -s 70a91f89 pull /vendor_dlkm/lib/modules/machine_dlkm.ko /Volumes/Case-sensitive\ APFS/TWRP/audio_dtb_probe/machine_dlkm.ko
```

用 llvm-nm 和 llvm-readelf 看符号：

```bash
cd /Volumes/Case-sensitive\ APFS/TWRP && '/Users/Laurie/.swiftly/bin/llvm-nm' -an audio_dtb_probe/machine_dlkm.ko | grep -E 'msm_populate_dai_link_component_of_node|populate_snd_card_dailinks|msm_asoc_machine_probe|snd_soc_add_pcm_runtimes|snd_soc_bind_card' | sed -n '1,120p'
```

```bash
cd /Volumes/Case-sensitive\ APFS/TWRP && '/Users/Laurie/.swiftly/bin/llvm-objdump' -d audio_dtb_probe/machine_dlkm.ko | grep -n 'msm_populate_dai_link_component_of_node\|msm_asoc_machine_probe\|populate_snd_card_dailinks' | sed -n '1,80p'
```

继续沿离线模块分析这条主线，把 `machine_dlkm.ko` 里和 `msm_populate_dai_link_component_of_node` 相关的符号与调用关系钉出来。

```bash
cd /Volumes/Case-sensitive\ APFS/TWRP && '/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-readelf' -Ws audio_dtb_probe/machine_dlkm.ko | grep -E 'msm_populate_dai_link_component_of_node|populate_snd_card_dailinks|msm_asoc_machine_probe' | sed -n '1,120p'
```

```bash
'/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-readelf' -Ws audio_dtb_probe/machine_dlkm.ko | grep -E 'msm_populate_dai_link_component_of_node|populate_snd_card_dailinks|msm_asoc_machine_probe' | sed -n '1,120p'
```

继续离线拆 `msm_asoc_machine_probe`，优先找它到底调用了哪些本地 helper，以及 `msm_populate_dai_link_component_of_node` 这类路径是不是被内联或静态化了。

反汇编 `msm_asoc_machine_probe`：

```bash
'/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump' -d --no-show-raw-insn --symbolize-operands audio_dtb_probe/machine_dlkm.ko | sed -n '/<msm_asoc_machine_probe>:/,/^$/p' | sed -n '1,260p'

'/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-readelf' -Wr audio_dtb_probe/machine_dlkm.ko | grep -E 'msm_populate_dai_link_component_of_node|populate_snd_card_dailinks|snd_soc_bind_card|snd_soc_add_pcm_runtimes|devm_snd_soc_register_card' | sed -n '1,160p'
```

`readelf` 先给了一个很有价值的硬点：`msm_asoc_machine_probe` 模块里至少明确直调了 `devm_snd_soc_register_card`，和我们运行时 kretprobe 的链条是对得上的。现在直接读反汇编，把前半段本地 helper 链和后半段错误返回路径拼起来。

我继续把 `msm_asoc_machine_probe` 的后半段读完，并把 0x2000 到 0x4000 这一段的局部符号映射出来，目标是把那些目前只显示成“跳到本函数内某地址”的 call 还原成具体 helper。

```bash
cd /Volumes/Case-sensitive\ APFS/TWRP && '/Users/Laurie/.swiftly/bin/llvm-nm' -an audio_dtb_probe/machine_dlkm.ko | awk '$1 >= "0000000000002000" && $1 <= "0000000000004000" {print}' | sed -n '1,240p'
```

局部符号表给了一个很关键的线索：`0x2320` 到 `0x3f70` 这一大片其实不是代码，而是各种 `*_dai_links` 数据表。也就是说 `msm_asoc_machine_probe` 前半段在大量拼装 dailink 数组，真正靠近 `devm_snd_soc_register_card` 的代码应该在更后面。我继续读反汇编尾段。

继续读反汇编：

```bash
'/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump' -d --no-show-raw-insn --symbolize-operands audio_dtb_probe/machine_dlkm.ko | sed -n '/<msm_asoc_machine_probe>:/,/^$/p' | sed -n '240,520p'
```

```bash
strings -td audio_dtb_probe/machine_dlkm.ko | grep -E 'could not find component for|component is NULL|failed to add wcd9378 routes|use aw882xx dailink replace|not use sipa pvdd limit' | sed -n '1,120p'
```

现在已经看到 `msm_asoc_machine_probe` 前半段确实在按不同模板批量拼 dailink，后面还有大量按索引循环的逻辑。真正和我们运行时返回码对应的关键点还在更尾部，尤其是接近 `0x3a70` 的 `devm_snd_soc_register_card` 调用，我直接读这一段。

```bash
'/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump' -d --no-show-raw-insn --symbolize-operands audio_dtb_probe/machine_dlkm.ko | sed -n '/<msm_asoc_machine_probe>:/,/^$/p' | sed -n '520,760p'
```

```bash
strings -t d audio_dtb_probe/machine_dlkm.ko | grep -E 'could not find component for|component is NULL|failed to add wcd9378 routes|use aw882xx dailink replace|not use sipa pvdd limit' | sed -n '1,120p'
```

---

## 33. 尝试用 dev_err / dev_err_probe 抓隐藏日志

离线反汇编已经证明 `msm_asoc_machine_probe` 在大段本地逻辑后才会走到 `devm_snd_soc_register_card`，但仅靠反汇编还不够快。现在我切回运行态，先查 `dev_err` / `dev_err_probe` 这类公共错误出口在不在 `kallsyms`，如果在，就直接用它们来抓 machine 没打印出来的隐藏错误。

```bash
adb -s 70a91f89 shell 'grep -E "[[:space:]](dev_err|_dev_err|dev_err_probe|__dev_printk|dev_printk_emit)[[:space:]]" /proc/kallsyms | head -n 80'
```

```bash
adb -s 70a91f89 shell 'grep -E "[[:space:]](__dynamic_dev_dbg|dynamic_dev_dbg|dev_dbg)[[:space:]]" /proc/kallsyms | head -n 80'
```

```bash
adb -s 70a91f89 shell 'dmesg | tail -n 40 | grep -i -E "aw882xx|wcd9378|wsa-codec|component|defer|sun-asoc|snd_soc"'
```

公共 `dev_err` 这一层很可能没暴露成可探针符号，或者当前命令根本没有命中。为了避免被 `grep -E` 这种边界条件误导，我再用更宽松的搜索确认一次，然后决定是继续走运行态日志钩子，还是回到离线模块。

```bash
adb -s 70a91f89 shell 'grep -i "dev_err" /proc/kallsyms | head -n 40 || true'
```

```bash
adb -s 70a91f89 shell 'grep -i "dev_printk\|dynamic_dev_dbg\|dev_dbg" /proc/kallsyms | head -n 60 || true'
```

```bash
adb -s 70a91f89 shell 'grep -i "snd_soc_lookup_component\|snd_soc_lookup_component_nolocked\|snd_soc_find_dai" /proc/kallsyms | head -n 40'
```

`dev_err_probe` 和 `_dev_err` 都在 `kallsyms` 里，终于有可抓的公共错误出口了。我现在直接挂这两个点，只在重放一次 `sound` probe 的窗口里抓格式串，看 machine 有没有把“component is NULL / could not find component”这种错误吞在公共日志层。

```bash
adb -s 70a91f89 shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; cd /sys/kernel/debug/tracing; echo 0 > tracing_on; echo > trace; echo > kprobe_events; echo "p:derr _dev_err fmt=+0(\$arg2):string" >> kprobe_events; echo "p:depr dev_err_probe err=\$arg2 fmt=+0(\$arg3):string" >> kprobe_events; echo 1 > events/kprobes/derr/enable; echo 1 > events/kprobes/depr/enable; echo 1 > tracing_on; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe; sleep 1; echo 0 > tracing_on; cat trace | grep -E "derr:|depr:" | tail -n 200'
```

```bash
adb -s 70a91f89 shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; cat /sys/kernel/debug/tracing/kprobe_events 2>/dev/null'
```

探针已注册，刚才失败只是因为试图清空 `kprobe_events`。不再重建，只保留 `derr/depr` 启用，再重放：

```bash
adb -s 70a91f89 shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; cd /sys/kernel/debug/tracing; echo 0 > tracing_on; echo 0 > events/kprobes/lk/enable 2>/dev/null; echo 0 > events/kprobes/lr/enable 2>/dev/null; echo 0 > events/kprobes/ln/enable 2>/dev/null; echo 0 > events/kprobes/rn/enable 2>/dev/null; echo 0 > events/kprobes/fd/enable 2>/dev/null; echo 0 > events/kprobes/fr/enable 2>/dev/null; echo 0 > events/kprobes/rr/enable 2>/dev/null; echo 0 > events/kprobes/lkn/enable 2>/dev/null; echo 0 > events/kprobes/rkn/enable 2>/dev/null; echo 1 > events/kprobes/derr/enable; echo 1 > events/kprobes/depr/enable; echo > trace; echo 1 > tracing_on; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe; sleep 1; echo 0 > tracing_on; cat trace | grep -E "derr:|depr:" | tail -n 200'
```

```bash
adb -s 70a91f89 shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; cd /sys/kernel/debug/tracing; for e in lk lr ln rn fd fr rr lkn rkn derr depr; do [ -e events/kprobes/$e/enable ] && echo $e=$(cat events/kprobes/$e/enable); done'
```

**结论**：重放 `sound` probe 时 `_dev_err` 和 `dev_err_probe` 都没有命中。machine 的静默失败不是简单地通过公共错误出口被吞掉。回到离线反汇编尾段：

```bash
'/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump' -d --no-show-raw-insn --symbolize-operands audio_dtb_probe/machine_dlkm.ko | sed -n '/<msm_asoc_machine_probe>:/,/^$/p' | sed -n '980,1120p'
```

```bash
cd /Volumes/Case-sensitive\ APFS/TWRP && '/Users/Laurie/.swiftly/bin/llvm-nm' -an audio_dtb_probe/machine_dlkm.ko | awk '$1 >= "0000000000003a00" && $1 <= "0000000000004600" {print}' | sed -n '1,240p'
```

尾段还没读到 `0x3a70`，但已经能看到一段非常像“按每个 codec component 循环检查并在失败时把对应 entry 清空/跳过”的逻辑。现在我继续直接跳到 `0x3900` 附近，看最后的 card 注册和错误出口。

```bash
'/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump' -d --no-show-raw-insn --symbolize-operands --start-address=0x3900 --stop-address=0x3b30 audio_dtb_probe/machine_dlkm.ko
```

```bash
'/Users/Laurie/Library/Android/sdk/ndk/27.3.13750724/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump' -d --no-show-raw-insn --symbolize-operands --start-address=0x3380 --stop-address=0x3910 audio_dtb_probe/machine_dlkm.ko | sed -n '1,260p'
```

两个已坐实的结论：`asoc-codec-names` 只有 3 项不再是 recovery 特有缺口；离线反汇编把 `msm_asoc_machine_probe -> devm_snd_soc_register_card -> -EPROBE_DEFER` 链在模块本体里也对上了。继续查更靠前的失败 helper：

```bash
cd /Volumes/Case-sensitive\ APFS/TWRP && '/Users/Laurie/.swiftly/bin/llvm-nm' -an audio_dtb_probe/machine_dlkm.ko | grep -E '3a70|3a54|3a98|3ad8|36cc|3dd8|3b18|37f0|43bc' | sed -n '1,80p'
```

---

## 34. 源码搜索未果

在工作区里搜索 machine 源码或相近实现：

```bash
rg -n 'msm_asoc_machine_probe|populate_snd_card_dailinks|msm_populate_dai_link_component_of_node|qcom,sun-asoc-snd|could not find component for|component is NULL|failed to add wcd9378 routes' --type-add 'src:*.{c,h,dts,dtsi,txt,yaml,xml,mk}' -t src 2>/dev/null | head -n 5000
# 5000 matches (范围太广)
```

```bash
find . \( -name '*machine*.c' -o -name '*asoc*.c' -o -name '*wcd9378*.c' \) 2>/dev/null | head -n 80
# 13 matches (machine*.c), no matches (asoc*.c, wcd9378*.c)
```

```bash
find . \( -name '*sound*.dts' -o -name '*sound*.dtsi' \) 2>/dev/null | head -n 40
# 2 matches (sound*.dts), no matches (sound*.dtsi)
```

逐个文本搜索：

```bash
rg -n 'qcom,sun-asoc-snd' --type-add 'src:*.{dts,dtsi,c,h,txt,yaml,xml}' -t src 2>/dev/null | head -n 200
rg -n 'msm_asoc_machine_probe' --type-add 'src:*.{c,h,S,s,txt}' -t src 2>/dev/null | head -n 200
rg -n 'populate_snd_card_dailinks' --type-add 'src:*.{c,h,S,s,txt}' -t src 2>/dev/null | head -n 200
rg -n 'msm_populate_dai_link_component_of_node' --type-add 'src:*.{c,h,S,s,txt}' -t src 2>/dev/null | head -n 200
rg -n 'could not find component for' --type-add 'src:*.{c,h,S,s,txt}' -t src 2>/dev/null | head -n 200
rg -n 'component is NULL' --type-add 'src:*.{c,h,S,s,txt}' -t src 2>/dev/null | head -n 200
rg -n 'failed to add wcd9378 routes' --type-add 'src:*.{c,h,S,s,txt}' -t src 2>/dev/null | head -n 200
# 均无对应 C 源命中
```

```bash
find . -path '*/vendor/qcom/opensource/*' -type f 2>/dev/null | head -n 200
# 200 matches
find . -path '*/sound/soc/qcom/*' -type f 2>/dev/null | head -n 200
# no matches
```

第二轮更精确的搜索：

```bash
rg -n 'qcom,sun-asoc-snd|msm_asoc_machine_probe|populate_snd_card_dailinks|msm_populate_dai_link_component_of_node|could not find component for lpass-cdc|wsa-codec\.1 component is NULL|failed to add wcd9378 routes' --type-add 'src:*.{c,h,dtsi,dts,txt,md,yaml,patch}' -t src 2>/dev/null | head -n 2000
# 2000 matches (范围太大)
```

```bash
rg -rn 'qcom,sun-asoc-snd' 2>/dev/null | head -n 80
rg -rn 'msm_asoc_machine_probe' 2>/dev/null | head -n 80
rg -rn 'populate_snd_card_dailinks' 2>/dev/null | head -n 80
rg -rn 'msm_populate_dai_link_component_of_node' 2>/dev/null | head -n 80
rg -rn 'could not find component for lpass-cdc' 2>/dev/null | head -n 40
rg -rn 'wsa-codec.1 component is NULL' 2>/dev/null | head -n 40
rg -rn 'failed to add wcd9378 routes' 2>/dev/null | head -n 40
# 均无命中
```

```bash
find . \( -name '*msm*asoc*machine*.c' -o -name '*asoc*sun*.c' -o -name '*audio*kernel*' \) 2>/dev/null | head -n 40
# no matches
```

搜 audio_dtb_probe DTS 和 device_tree 配置：

```bash
rg -n 'qcom,sun-asoc-snd|sound|wcd9378|audio-routing|dai-link' audio_dtb_probe/**/*.dts 2>/dev/null | head -n 40
# 31 results
```

```bash
rg -n 'TARGET_KERNEL_SOURCE|TARGET_KERNEL_CONFIG|BOARD_USES_QCOM_HARDWARE|TARGET_USES_QCOM_BSP' device_tree/**/*.mk 2>/dev/null | head -n 20
# no matches
```

```bash
rg -n 'manifest_audiocorehal_default|audioeffectservice_qti|audiocorehal|audio' device_tree/**/*manifest*.xml 2>/dev/null | head -n 20
# 9 results
```

**结论**：工作区里没有现成的 machine 驱动源码命中，主要是 DTS 和音频文档。

---

## 35. 回到 overlay DTS 做第二轮深层核对 + 所有 DT 产物彻底搜索

在 overlay entry0 DTS 中搜索关键属性：

```bash
rg -n 'wsa-codec|wcd9378|wcd939x_codec|lpass-cdc|msm-stub-codec|qcom,msm_audio_ssr_devs|qcom,upd_backends_used' audio_dtb_probe/dtbo_entry0.dts | head -n 40
# 37 results
```

```bash
rg -rn 'component is NULL|could not find component for|failed to add wcd9378 routes|rx_dma_rx6_codecs|CODEC_DMA-LPAIF_RXTX-RX-6|wcd9378_cdc' --include='*machine*' 2>/dev/null | head -n 20
# no matches
```

```bash
find . -name '*machine*' -type f 2>/dev/null | head -n 20
# 20 matches
find . \( -name '*objdump*' -o -name '*disasm*' \) -type f 2>/dev/null | head -n 20
# 20 matches each
```

```bash
rg -n 'wsa-macro@6B00000|wsa2-macro@6AA0000|status = ' audio_dtb_probe/dtbo_entry0.dts | head -n 80
# 80 results
```

在所有 DT 产物中彻底搜索 wcd9378：

```bash
rg -n 'qcom,wcd9378-codec|wcd9378_codec|wcd9378' audio_dtb_probe/dtbo_entry0.dts 2>/dev/null | head -n 10
# no results
rg -n 'qcom,wcd9378-codec|wcd9378_codec|wcd9378' audio_dtb_probe/vendor_boot_unpack/vendor_boot_sound.dts 2>/dev/null | head -n 10
# no results
rg -n 'qcom,wcd9378-codec|wcd9378_codec|wcd9378' audio_dtb_probe/unpack_compare/unpack_compare_sound.dts 2>/dev/null | head -n 10
# no results
```

```bash
rg -rn 'wcd9378|wsa-macro@6B00000|wsa2-macro@6AA0000|qcom,sun-asoc-snd' audio_dtb_probe/dtbo_unpack/ 2>/dev/null | head -n 40
# no results
```

---

## 36. dtbo entry 交叉验证

确认是否有别的 dtbo entry 把 entry0 里 disabled 的 WSA 分支重新打开：

```bash
find . -name 'dtc' -type f 2>/dev/null | head -n 10
# 6 matches
find . -name 'mkdtboimg.py' 2>/dev/null | head -n 10
# 2 matches
```

```bash
cd "$PWD/audio_dtb_probe" && python3 ../twrp_a16_compile/system/libufdt/utils/src/mkdtboimg.py dump dtbo_a.img
```

用 dtc 反编译 entry6 并做属性搜索：

```bash
cd "$PWD/audio_dtb_probe" && ../twrp_a16_compile/prebuilts/tools-lineage/darwin-x86/dtc/dtc -I dtb -O dts dtbo_entry6.dtb | rg -n "sound \{|qcom,sun-asoc-snd|qcom,upd_backends_used|asoc-codec-names|wsa-macro@6B00000|wsa2-macro@6AA0000|wcd9378|status = \"disabled\""
```

改用绝对路径重跑（避免共享 shell cwd 污染）：

```bash
pushd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" >/dev/null && ../twrp_a16_compile/prebuilts/tools-lineage/darwin-x86/dtc/dtc -I dtb -O dts dtbo_entry6.dtb | rg -n 'sound \{|qcom,sun-asoc-snd|qcom,upd_backends_used|asoc-codec-names|wsa-macro@6B00000|wsa2-macro@6AA0000|wcd9378|status = "disabled"'
```

缩减输出噪音重新搜索：

```bash
pushd "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe" >/dev/null && ../twrp_a16_compile/prebuilts/tools-lineage/darwin-x86/dtc/dtc -q -I dtb -O dts dtbo_entry6.dtb 2>/dev/null | rg -n 'qcom,sun-asoc-snd|qcom,upd_backends_used|asoc-codec-names|wsa-macro@6B00000|wsa2-macro@6AA0000|wcd9378'
```

**结论**：关键属性在两个 entry 里相同，`wsa-macro`/`wsa2-macro` 均为 disabled。现在比"盯 wcd9378"更硬的收敛点——运行态明确宣称用 `wsa` backend，但 live DT 里 WSA 宏和 component 实体都不成立，而 machine 二进制里正好有 `wsa-codec.N component is NULL` 分支。

---

## 37. WSA backend 矛盾：运行态取证

把主线优先级从"优先盯 RX-6 / wcd9378"调整为"先解释 `upd_backends_used = wsa` 与 disabled WSA 实体的矛盾"。补一刀运行态取证：

```bash
adb -s 70a91f89 shell 'for p in /proc/device-tree/soc/spf_core_platform/sound/qcom,upd_backends_used /proc/device-tree/soc/spf_core_platform/lpass-cdc/wsa-macro@6B00000/status /proc/device-tree/soc/spf_core_platform/lpass-cdc/wsa2-macro@6AA0000/status; do echo ===$p===; cat "$p" 2>/dev/null | tr -d "\000"; echo; done; echo ===components===; cat /sys/kernel/debug/asoc/components 2>/dev/null | grep wsa-codec'
```

**结论**：live DT 显示 `sound/qcom,upd_backends_used = wsa`，同时两个 WSA macro 都是 `disabled`，`asoc/components` 里也没有任何 `wsa-codec`。

搜索 doc 中需更新的章节：

```bash
rg -n '12\.26\.8|wsa-codec\.1 component is NULL|WSA backend 被宣告使用' docs/TWRP音频手动Bring-up.md | head -n 10
# 4 results
```

当前最硬证据链：

1. stock overlay 和 recovery 运行态都表明 `qcom,upd_backends_used = wsa`
2. 同一套 DT 里 `wsa-macro`/`wsa2-macro` 都是 `disabled`
3. ASoC components 里没有任何 `wsa-codec`
4. `machine_dlkm.ko` 有 `wsa-codec.1` 到 `.4 component is NULL` 错误分支

---

## 38. 继续往 component 组装路径下钻

查 kallsyms 中可打点的 component lookup 符号：

```bash
adb -s 70a91f89 shell 'grep -E "snd_soc_add_pcm_runtime|soc_dai_link_sanity_check|snd_soc_add_pcm_runtimes|snd_soc_bind_card|soc_find_component|snd_soc_lookup_component" /proc/kallsyms | head -n 80'
```

在内核树中确认函数原型（无命中，靠设备打点）：

```bash
cd "/Volumes/Case-sensitive APFS/TWRP" && rg -n "snd_soc_lookup_component(_nolocked)?\s*\(|soc_find_component\s*\(" twrp_a16_compile/kernel twrp_a12_compile/kernel | head -n 80
```

试探性挂 component lookup probe：

```bash
adb -s 70a91f89 shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; echo > /sys/kernel/debug/tracing/kprobe_events; echo "p:lkc snd_soc_lookup_component s16=+0(\$arg2):string" > /sys/kernel/debug/tracing/kprobe_events; echo 1 > /sys/kernel/debug/tracing/events/kprobes/lkc/enable; echo 0 > /sys/kernel/debug/tracing/trace; echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; tail -n 120 /sys/kernel/debug/tracing/trace; echo 0 > /sys/kernel/debug/tracing/events/kprobes/lkc/enable; echo > /sys/kernel/debug/tracing/kprobe_events'
```

旧 probe 残留占入口，清理：

```bash
adb -s 70a91f89 shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; cat /sys/kernel/debug/tracing/kprobe_events 2>/dev/null | tail -n 40'
```

```bash
adb -s 70a91f89 shell 'ls /sys/kernel/debug/tracing/events/kprobes 2>/dev/null | tail -n 40'
```

启用现成事件并重放：

```bash
adb -s 70a91f89 shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; for e in lk lkn lr rn rkn rr ln fd fr derr depr; do echo 0 > /sys/kernel/debug/tracing/events/kprobes/$e/enable 2>/dev/null; done; echo 1 > /sys/kernel/debug/tracing/events/kprobes/lk/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/lkn/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/lr/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/rkn/enable; echo 0 > /sys/kernel/debug/tracing/trace; echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; cat /sys/kernel/debug/tracing/trace | tail -n 160'
```

未命中。确认设备绑定和实例化状态：

```bash
adb -s 70a91f89 shell 'ls -l /sys/bus/platform/drivers/sun-asoc-snd 2>/dev/null'
adb -s 70a91f89 shell 'ls -l /sys/devices/platform/soc/soc:spf_core_platform 2>/dev/null | tail -n 80'
```

`soc:spf_core_platform:sound` 现在其实已经实例化了，只是没绑到 `sun-asoc-snd`。我直接看这个子设备当前 driver 关系和 reprobe 可写点，然后再重放。

```bash
adb -s 70a91f89 shell 'ls -l /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound 2>/dev/null'
adb -s 70a91f89 shell 'cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/modalias 2>/dev/null; echo; cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/uevent 2>/dev/null'
```

这里冒出一个更前面的硬信号了：`sound` 设备目录里有 `waiting_for_supplier`。我先把这个状态读出来，确认是不是 machine probe 压根没开始，而不是开始后才在 component 组装里 defer。

```bash
adb -s 70a91f89 shell 'echo ===sound===; cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/waiting_for_supplier 2>/dev/null; echo; echo ===spf_core_platform===; cat /sys/devices/platform/soc/soc:spf_core_platform/waiting_for_supplier 2>/dev/null'
```

```bash
adb -s 70a91f89 shell 'for d in /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/supplier:*; do echo ===$d===; readlink "$d"; done 2>/dev/null'
```

`sound` 设备已经存在且 supplier 不是阻塞，所以下一刀应该直接验证 machine probe 本身有没有再次进入。我要给 `msm_asoc_machine_probe` 挂最小入口/返回 probe。

```bash
adb -s 70a91f89 shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; echo "p:mp msm_asoc_machine_probe" >> /sys/kernel/debug/tracing/kprobe_events; echo "r:mr msm_asoc_machine_probe ret=\$retval" >> /sys/kernel/debug/tracing/kprobe_events; for e in mp mr lk lkn lr rkn ln fd fr rr derr depr; do echo 0 > /sys/kernel/debug/tracing/events/kprobes/$e/enable 2>/dev/null; done; echo 1 > /sys/kernel/debug/tracing/events/kprobes/mp/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/mr/enable; echo 0 > /sys/kernel/debug/tracing/trace; echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; cat /sys/kernel/debug/tracing/trace | tail -n 80'
```

`drivers_probe` 这次没有真正触发 probe，说明当前卡点已经偏向总线/驱动匹配层了。我先看 deferred 列表和 `driver_override` 实际内容，确认它是不是还留在待探测状态。

```bash
adb -s 70a91f89 shell 'cat /sys/kernel/debug/devices_deferred 2>/dev/null | tail -n 80'
adb -s 70a91f89 shell 'echo ===override===; cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; echo; echo ===modalias===; cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/modalias 2>/dev/null'
adb -s 70a91f89 shell 'cat /sys/bus/platform/drivers_probe 2>/dev/null | head -n 5'
```

现在最像的状态是：`sound` 设备曾经 defer 过，但没有被再次重试。要把运行态证据往前推，最直接的办法是重载 `machine_dlkm` 触发一次干净的 `sun-asoc-snd` 重新注册。

```bash
adb -s 70a91f89 shell 'cat /proc/modules | grep -E "(^machine_dlkm | sun_asoc|wcd9378_dlkm|wsa883x_dlkm|wsa884x_dlkm|lpass_cdc_dlkm)"'
adb -s 70a91f89 shell 'ls -l /vendor/lib/modules/machine_dlkm.ko /vendor_dlkm/lib/modules/machine_dlkm.ko /vendor/lib/modules/*machine* /vendor_dlkm/lib/modules/*machine* 2>/dev/null'
```

`machine_dlkm` 当前引用计数是 0，可以安全做一次最小重载。这样比继续等 deferred 队列更直接，加载瞬间如果 `sun-asoc-snd` 真进 probe，kprobe 一定会留下痕迹。

```bash
adb -s 70a91f89 shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; for e in mp mr lk lkn lr rkn ln fd fr rr derr depr; do echo 0 > /sys/kernel/debug/tracing/events/kprobes/$e/enable 2>/dev/null; done; echo 1 > /sys/kernel/debug/tracing/events/kprobes/mp/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/mr/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/lk/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/lkn/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/lr/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/rkn/enable; echo 0 > /sys/kernel/debug/tracing/trace; rmmod machine_dlkm; insmod /vendor/lib/modules/machine_dlkm.ko; sleep 1; cat /sys/kernel/debug/tracing/trace | tail -n 200'
```

这说明不是重放方式的问题，而是我们新加的 probe 本身大概率没真正挂上。我先核对 `kprobe_events` 里有没有 `mp/mr`，再看 enable 状态。

```bash
adb -s 70a91f89 shell 'cat /sys/kernel/debug/tracing/kprobe_events 2>/dev/null | tail -n 40'
adb -s 70a91f89 shell 'for e in mp mr lk lkn lr rkn; do echo ===$e===; cat /sys/kernel/debug/tracing/events/kprobes/$e/enable 2>/dev/null; done'
```

probe 已经挂上而且 enable=1，但 trace 还是空，这更像是 tracing 总开关被关了。我先查 `tracing_on`，如果是 0，就把它打开再重跑一次。

```bash
adb -s 70a91f89 shell 'cat /sys/kernel/debug/tracing/tracing_on 2>/dev/null'
# 0 — 关键发现！
```

```bash
adb -s 70a91f89 shell 'cat /sys/kernel/debug/tracing/current_tracer 2>/dev/null'
```

问题找到了：`tracing_on` 现在是 0，之前所有 probe 都在“静音录制”。我把总开关打开后再做一次 machine 重载，这次应该能拿到真正的 probe 路径。

```bash
adb -s 70a91f89 shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; echo 1 > /sys/kernel/debug/tracing/tracing_on; for e in mp mr lk lkn lr rkn ln fd fr rr derr depr; do echo 0 > /sys/kernel/debug/tracing/events/kprobes/$e/enable 2>/dev/null; done; echo 1 > /sys/kernel/debug/tracing/events/kprobes/mp/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/mr/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/lk/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/lkn/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/lr/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/rkn/enable; echo 0 > /sys/kernel/debug/tracing/trace; rmmod machine_dlkm; insmod /vendor/lib/modules/machine_dlkm.ko; sleep 1; cat /sys/kernel/debug/tracing/trace | tail -n 240'
```

trace 还是空，说明这不是“抓错函数”，而是当前这次操作根本没碰到任何已挂 probe 的路径。我先做一个最小自检，确认 tracefs 在当前设备上还能正常记 kprobe 事件。

```bash
adb -s 70a91f89 shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; grep -q "p:kprobes/vr vfs_read" /sys/kernel/debug/tracing/kprobe_events || echo "p:vr vfs_read" >> /sys/kernel/debug/tracing/kprobe_events; for e in vr mp mr lk lkn lr rkn; do echo 0 > /sys/kernel/debug/tracing/events/kprobes/$e/enable 2>/dev/null; done; echo 1 > /sys/kernel/debug/tracing/tracing_on; echo 1 > /sys/kernel/debug/tracing/events/kprobes/vr/enable; echo 0 > /sys/kernel/debug/tracing/trace; cat /proc/version >/dev/null; sleep 1; cat /sys/kernel/debug/tracing/trace | tail -n 20'
```

我拿到了自检结果文件，先读尾部看看 `vfs_read` 有没有命中；如果命中，问题就只剩“这次 machine 路径根本没被触发”。

直接只抓 trace 里有没有 `vr` 事件。这个结果只要一行就够判断 tracefs 是否活着。

```bash
adb -s 70a91f89 shell 'head -n 80 /sys/kernel/debug/tracing/trace | grep " vr: "'
```

kprobe 这条线暂时被 tracefs 读法卡住了，我先换一个更稳的方向：看 deferred probe 子系统自己有没有可调参数或额外状态，争取直接拿到 `sound` 为什么一直留在 deferred 列表。

```bash
adb -s 70a91f89 shell 'ls -R /sys/module/deferred_probe 2>/dev/null'
adb -s 70a91f89 shell 'ls /sys/kernel/debug 2>/dev/null | grep deferred'
adb -s 70a91f89 shell 'dmesg | grep -i deferred | tail -n 40'
```

我已经拿到一个新的硬边界：`sound` 设备现在真实存在、未绑定驱动、并且还挂在 `devices_deferred` 里，同时 `waiting_for_supplier=0`，所以它不是卡在 fw_devlink supplier。接下来我直接抓一次 machine 重载前后的内核日志增量，看内核自己有没有吐出新的 defer 线索。

---

## 39. machine 重载抓 dmesg 增量

```bash
adb -s 70a91f89 shell 'before=$(dmesg | wc -l); rmmod machine_dlkm; insmod /vendor/lib/modules/machine_dlkm.ko; sleep 1; dmesg | tail -n +$((before+1)) | grep -E "sun-asoc-snd|msm_asoc_machine_probe|spf_core_platform:sound|snd_soc|wsa-codec|wcd9378|lpass-cdc|defer|probe"'
```

machine 重载后终于有新的直接日志了，至少已经坐实 `msm_asoc_machine_probe` 确实重新进入。现在我把这次增量前后多抓一点上下文，看看这些 Oplus 私有日志后面有没有紧跟的失败点。

```bash
adb -s 70a91f89 shell 'before=$(dmesg | wc -l); rmmod machine_dlkm; insmod /vendor/lib/modules/machine_dlkm.ko; sleep 1; dmesg | tail -n +$((before+1)) | tail -n 120'
```

这次日志里冒出了一个新的硬异常，而且比 `-EPROBE_DEFER` 更具体：`snd_card_sysfs_init: Failed to add kobject snd_card, err = -17`。我先核对当前 `/sys/class/sound` 和 `snd_card` 相关对象，判断这是不是一个真实的“全局 kobject 已存在”冲突。

```bash
adb -s 70a91f89 shell 'ls -l /sys/class/sound 2>/dev/null; echo ===proc===; cat /proc/asound/cards 2>/dev/null; echo ===dev===; ls -l /dev/snd 2>/dev/null'
```

```bash
adb -s 70a91f89 shell 'find /sys -maxdepth 4 \( -name snd_card -o -name card0 -o -name controlC0 \) 2>/dev/null | head -n 80'
```

```bash
adb -s 70a91f89 shell 'dmesg | grep -n "snd_card_sysfs_init\|kobject_add_internal failed for snd_card" | tail -n 20'
```

换成 `trace_pipe` 实时抓流，这比读 `trace` 文件稳得多。目标还是一样：在 machine 重载瞬间拿到 `lookup_component` 的真实名字和返回。

---

## 40. trace_pipe 实时抓返回值链

换 `trace_pipe`（比 `trace` 文件稳）：

```bash
adb -s 70a91f89 shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; echo 1 > /sys/kernel/debug/tracing/tracing_on; for e in vr mp mr lk lkn lr rkn ln fd fr rr derr depr; do echo 0 > /sys/kernel/debug/tracing/events/kprobes/$e/enable 2>/dev/null; done; echo 1 > /sys/kernel/debug/tracing/events/kprobes/mp/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/mr/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/lk/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/lkn/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/lr/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/rkn/enable; rm -f /data/local/tmp/trace.out; cat /sys/kernel/debug/tracing/trace_pipe > /data/local/tmp/trace.out & tp=$!; sleep 1; rmmod machine_dlkm; insmod /vendor/lib/modules/machine_dlkm.ko; sleep 2; kill $tp; sleep 1; tail -n 200 /data/local/tmp/trace.out'
```

这次拿到的是独立结果文件，不会再被共享终端污染。我先读尾部，重点看有没有 `mp:`、`lk:`、`lkn:`、`rkn:`。

设备上筛事件（VSCode 缓存 trace 文件用 rg 搜索事件名均无命中，改用设备侧 grep 直接有效）：

```bash
adb -s 70a91f89 shell 'grep -E " mp: | mr: | lk: | lkn: | lr: | rkn: " /data/local/tmp/trace.out | tail -n 120'
```

再补一个状态闭环：重载 `machine_dlkm` 之后，确认 `sound` 还在 deferred 列表里，以及它依然没有绑上 `sun-asoc-snd`。这样我们就能把新日志和 sysfs 状态对齐。

```bash
adb -s 70a91f89 shell 'echo ===deferred===; cat /sys/kernel/debug/devices_deferred 2>/dev/null; echo ===sound-driver===; ls -l /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver 2>/dev/null; echo ===sun-asoc-snd===; ls -l /sys/bus/platform/drivers/sun-asoc-snd 2>/dev/null'
```

```bash
adb -s 70a91f89 shell 'dmesg | tail -n 60 | grep -E "msm_asoc_machine_probe|snd_card_sysfs_init|kobject_add_internal failed for snd_card|extend_codec_be_dailink|not use sipa pvdd limit"'
```

现在把这轮新增的两个边界写进去：一是 `sound` 设备已实例化但未绑定且仍在 deferred 队列；二是手工重载 `machine_dlkm` 时 `msm_asoc_machine_probe` 会重新进入并跑过 aw882xx 扩展日志。这样主线就从“抽象 defer”变成更具体的设备状态。

```bash
adb -s 70a91f89 shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; grep -q "kprobes/dr .*devm_snd_soc_register_card" /sys/kernel/debug/tracing/kprobe_events || echo "r:dr devm_snd_soc_register_card ret=\$retval" >> /sys/kernel/debug/tracing/kprobe_events; grep -q "kprobes/br .*snd_soc_bind_card" /sys/kernel/debug/tracing/kprobe_events || echo "r:br snd_soc_bind_card ret=\$retval" >> /sys/kernel/debug/tracing/kprobe_events; grep -q "kprobes/pr .*snd_soc_add_pcm_runtimes" /sys/kernel/debug/tracing/kprobe_events || echo "r:pr snd_soc_add_pcm_runtimes ret=\$retval" >> /sys/kernel/debug/tracing/kprobe_events; echo 1 > /sys/kernel/debug/tracing/tracing_on; for e in vr mp mr lk lkn lr rkn ln fd fr rr derr depr dr br pr; do echo 0 > /sys/kernel/debug/tracing/events/kprobes/$e/enable 2>/dev/null; done; echo 1 > /sys/kernel/debug/tracing/events/kprobes/dr/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/br/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/pr/enable; rm -f /data/local/tmp/ret.out; cat /sys/kernel/debug/tracing/trace_pipe > /data/local/tmp/ret.out & tp=$!; sleep 1; rmmod machine_dlkm; insmod /vendor/lib/modules/machine_dlkm.ko; sleep 2; kill $tp; sleep 1; grep -E " dr: | br: | pr: " /data/local/tmp/ret.out | tail -n 80'
```

返回链已经被当前这次重载重新坐实了。趁 `trace_pipe` 这条路通了，我再顺手把 `snd_soc_find_dai` 的真实查找顺序抓一遍，确认当前 reload 路径下它仍然停在同一条边界。

```bash
adb -s 70a91f89 shell "mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; echo 1 > /sys/kernel/debug/tracing/tracing_on; for e in vr mp mr lk lkn lr rkn ln fd fr rr derr depr dr br pr; do echo 0 > /sys/kernel/debug/tracing/events/kprobes/\$e/enable 2>/dev/null; done; echo 1 > /sys/kernel/debug/tracing/events/kprobes/fd/enable; echo 1 > /sys/kernel/debug/tracing/events/kprobes/rr/enable; rm -f /data/local/tmp/fd.out; cat /sys/kernel/debug/tracing/trace_pipe > /data/local/tmp/fd.out & tp=\$!; sleep 1; rmmod machine_dlkm; insmod /vendor/lib/modules/machine_dlkm.ko; sleep 2; kill \$tp; sleep 1; grep 'fd: (snd_soc_find_dai' /data/local/tmp/fd.out | cut -d '\"' -f2 | nl -ba | tail -n 120"
```

顺序抓到了，而且边界和前面一致：仍然只走到 `rx_macro_rx5 / wcd939x_cdc` 一带，没有进入 `rx_macro_rx6`。我再补一眼返回值，确认这些已进入的 `find_dai` lookup 这次是不是也全部成功。

```bash
adb -s 70a91f89 shell "echo ===null-returns===; grep 'rr: ' /data/local/tmp/fd.out | grep 'ret=0x0' | tail -n 20; echo ===return-count===; grep -c 'rr: ' /data/local/tmp/fd.out; echo ===null-count===; grep 'rr: ' /data/local/tmp/fd.out | grep -c 'ret=0x0'"
# return-count: 72, null-count: 0
```

**结论**：72 次 lookup 全部非空且成功。返回链 `devm_snd_soc_register_card -> snd_soc_bind_card -> snd_soc_add_pcm_runtimes` 仍然 `-517`。

---

## 41. 本轮排障技巧汇总

以下技巧在本轮音频 bring-up 中被实际验证有效：

1. **用 `drivers_probe` 稳定重放 deferred probe**：`echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe`
2. **用 kprobe 直接抓 `snd_soc_find_dai` 的 `dai_name`**：`s16=+0(+16($arg1)):string` 二次解引用
3. **entry/return 配对抓**：排掉 DAI lookup 失败误判
4. **把 `asoc/components` 和 `asoc/dais` 分开看**：`rx_macro_rx6` DAI 存在但 component 不存在
5. **直接读 `/proc/device-tree/.../sound/*` 单个属性**：比全量 dump DT 快
6. **用 module 二进制 strings 反推内部失败分支**：`strings machine_dlkm.ko | grep` 找 `component is NULL`
7. **用"顺序缺口"定位**：72 次 lookup 只到 `rx_macro_rx1..5`，未到 `rx_macro_rx6`
8. **`dtc + rg` 定向抽取 DT**：dtc 反编译 dtb 再用 rg 搜，不盲读整份 DTS
9. **`trace_pipe` 代替 `trace` 文件**：避免共享终端污染
10. **`tracing_on` 检查**：kprobe trace 为空时先查 `tracing_on`
11. **量化返回值验证**：`grep -c 'rr:' / grep -c 'ret=0x0'` 确认全部成功

---

## 42. 最终收敛结论

1. `msm_asoc_machine_probe` 返回 `0xfffffdfb`（`-517` / `EPROBE_DEFER`）
2. 返回链全程：`devm_snd_soc_register_card -> snd_soc_bind_card -> snd_soc_add_pcm_runtimes` 全部 `-517`
3. 72 次 `snd_soc_find_dai` lookup 全部非空成功，只到 `rx_macro_rx1..5 / wcd939x_cdc`，未到 `rx_macro_rx6`
4. stock `dtbo` overlay 的 `asoc-codec-names` 本身就是 3 项（不是 recovery 特有缺口）
5. `qcom,upd_backends_used = "wsa"` 但 `wsa-macro`/`wsa2-macro` 都是 `disabled`
6. `machine_dlkm.ko` 有 `wsa-codec.N component is NULL` 和 `failed to add wcd9378 routes` 分支
7. 运行态 ASoC components 无 `wsa-codec.*` 或 `wcd9378-codec`
8. 离线反汇编坐实 `msm_asoc_machine_probe` 直调 `devm_snd_soc_register_card`
9. 重载后 dmesg 冒出 `snd_card_sysfs_init: Failed to add kobject snd_card, err = -17`
10. `tracing_on` 曾被关为 0，导致前期多轮 kprobe "静音录制"

最可能根因：machine 在 component 组装阶段因缺少 `wsa-codec`（及可能 `wcd9378-codec`）而在进入 DAI lookup 前触发 defer。WSA backend 被宣告使用但 DT 实体 disabled / component 未实例化的矛盾，是当前最硬的突破口。

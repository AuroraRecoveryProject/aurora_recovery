# 第2章：Plugin/libagmmixer逆向——从日志定位到agmplay调用链分析
GitHub Copilot: 我转到 plugin 侧追根因，先在仓库里定位 `Failed to mixer_ctl_get_array`、`Instance key is added` 和 `agm_pcm_plugin_open` 的来源，目标是找到 card100/plugin 真实缺的 ctl 类型。

Searched codebase for "Failed to mixer_ctl_get_array agm pcm plugin mixer plugin card100", 24 results

Searching for regex `Failed to mixer_ctl_get_array|Instance key is added|agm_pcm_plugin_open|agm_mixer_plugin_open`

Searched for files matching `**/*agm*plugin*`, 8 matches

我直接从 plugin 二进制里抠错误字符串上下文，目标是把 `Failed to mixer_ctl_get_array` 对应的控件名或调用分支找出来，而不是继续在 probe 侧盲试。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && strings -a -t x libagm_pcm_plugin.so | grep -E 'Failed to mixer_ctl_get_array|Instance key is added|agm_pcm_plugin_open|device_config not found|pcm plugin|rate ch fmt|getTaggedInfo|setParam|metadata'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && strings -a -t x libagm_mixer_plugin.so | grep -E 'Failed to mixer_ctl_get_array|Instance key is added|agm_mixer_plugin_open|mixer plugin|rate ch fmt|getTaggedInfo|setParam|metadata'

字符串层面已经有了一个方向：libagm_mixer_plugin.so 明确包含 `getTaggedInfo / rate ch fmt / metadata / setParam / setParamTag`，说明 plugin 自己确实会走这些控件。下一步我直接找 `mixer_ctl_get_array` 相关字符串和邻近日志，确认失败是不是出在 mixer plugin 侧而不是 pcm plugin 侧。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && strings -a -t x libagm_mixer_plugin.so | grep -i 'mixer_ctl\|get_array\|Failed\|failed\|Instance key'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && strings -a -t x libagm_pcm_plugin.so | grep -i 'mixer_ctl\|get_array\|Failed\|failed\|Instance key'

`Failed to mixer_ctl_get_array` 不在两个 plugin 里作为明文存在，`Instance key is added` 也不在这里。说明日志更可能来自 `libagm` / `libagmmixer` / `libagmclient` 本体，而不是 plugin 包装层。我继续往这三库里抠。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && for f in libagm.so libagmmixer.so libagmclient.so; do echo "== $f =="; strings -a -t x "$f" | grep -i 'Instance key is added\|Failed to mixer_ctl_get_array\|get_array\|set_media_config failed\|set_params failed\|graph_open\|MFC not present'; done
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && for f in libagm.so libagmmixer.so libagmclient.so; do echo "== $f =="; strings -a -t x "$f" | grep -i 'Instance key is added\|Failed to mixer_ctl_get_array\|get_array\|set_media_config failed\|set_params failed\|graph_open\|MFC not present'; done

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && for f in libagm.so libagmmixer.so libagmclient.so; do echo "== $f =="; strings -a -t x "$f" | grep -i 'rate ch fmt\|getTaggedInfo\|setParamTag\|setParam\|metadata'; done

Compacted conversation定位结果已经出来了：这两个关键日志都在 `libagmmixer.so`，不是 plugin。下一步不是继续猜控制顺序，而是把 `libagmmixer.so` 里发这两条日志的函数抠出来，看它在找哪个 mixer ctl。Optimizing tool selection...

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && file libagmmixer.so && command -v llvm-objdump && command -v readelf && command -v nm
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && file libagmmixer.so && command -v llvm-objdump && command -v readelf && command -v nm

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && strings -a -t x libagmmixer.so | grep -i -n 'Failed to mixer_ctl_get_array\|Instance key is added\|rate ch fmt\|getTaggedInfo\|setParamTag\|setParam\|metadata'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -h libagmmixer.so | sed -n '1,20p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -h libagmmixer.so | sed -n '20,40p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d libagmmixer.so | grep -n '0x2b6b\|0x2cde\|0x2ab8\|0x2a7c\|0x2956\|0x2910\|0x2879' | sed -n '1,80p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --print-imm-hex libagmmixer.so | grep -n '#0x2b6b\|#0x2cde\|#0x2ab8\|#0x2a7c\|#0x2956\|#0x2910\|#0x2879' | head -n 80

我已经确认两点：`Failed to mixer_ctl_get_array` 和 `Instance key is added` 同时都在 `libagmmixer.so`。现在要做的是把这段日志和导出函数对上，尤其是 `set_agm_streamdevice_metadata` 这类元数据入口，因为当前最像是它在找某个缺失 ctl。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && nm -D libagmmixer.so | sed -n '1,200p'

Searched for regex `set_agm_streamdevice_metadata|set_agm_stream_metadata_type|set_agm_stream_metadata|set_agm_audio_intf_metadata|connect_agm_audio_intf_to_stream|configure_mfc` (`**/video_player/pure_c_agm_probe.c`), 17 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/strace_tinyplay_open_20260318.txt#1660-1660), lines 1660 to 1725

Searched for files matching `**/pure_c_agm_probe.c`, no matches

Searched for regex `AGM_PRIMARY_INTF|pure-c probe|PCM100 control` (`**/*.{c,cpp,h,md,sh}`), 50 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1028-1028), lines 1028 to 1088

Searched for regex `Instance key is added|set_agm_streamdevice_metadata|instance_kv` (`**/docs/TWRP音频手动Bring-up.md`), 34 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#4500-4500), lines 4500 to 4688

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#4668-4668), lines 4668 to 4760

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#4760-4760), lines 4760 to 4845

前面的文档其实已经给了下一步：`libagmmixer.so` 里关键日志在 metadata 路径，`tinyplay_ftm` 还存在两类更大的 payload helper，分别对应 `pcm metadata` 和 `device metadata`。我先核对当前 probe 有没有真的复刻这两类 payload；如果没有，就直接补一个最小实验入口。

Searched for regex `pcm metadata|device metadata|split metadata|setParamTag|getTaggedInfo|0x689c|0x6a54|metadata payload|streamdevice` (`**//Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c`), 12 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#860-860), lines 860 to 1015

Searched for regex `0x689c|0x6a54|Failed to set device metadata|Failed to set pcm metadata|pcm metadata|device metadata` (`**/docs/TWRP音频手动Bring-up.md`), 41 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2000-2000), lines 2000 to 2220

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2220-2220), lines 2220 to 2520

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2520-2520), lines 2520 to 2820

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2820-2820), lines 2820 to 3080

Searched for regex `bl\s+0x689c|bl\s+0x6a54|bl\s+0x6628|bl\s+0x63d8|bl\s+0x629c|bl\s+0x60f4` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), 7 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#520-520), lines 520 to 790

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#60-60), lines 60 to 150

Searched for regex `set_agm_device_custom_payload|group_device_config|group_mux_config|device_custom_payload` (`**/docs/TWRP音频手动Bring-up.md`), 3 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3776-3776), lines 3776 to 3802

Searched for regex `set_agm_device_custom_payload\s*\(|get_agm_usb_audio_config_payload\s*\(` (`**/*.{h,c,cpp,cc,md}`), no results

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n "set_agm_device_custom_payload|get_agm_usb_audio_config_payload"

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_rVFFkqxxlVW9Sm3yuLATvcS4__vscode-1773795047695/content.txt#1-1), lines 1 to 220

当前最像漏掉的不是“metadata 要不要写”，而是“写进 PCM100 metadata 的值形态不对”。现有 probe 的 split-KV 只写了低 24 位，而 `0x689c` 更像是写 `[tag_base, full_kv]` 这种 20B payload。我先补这个变体，直接看它会不会把 `-5` 或 `getTaggedInfo` 再往前推。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1180-1180), lines 1180 to 1495

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1495-1495), lines 1495 to 1550

`PCM100 metadata` 现在只有一种写法，过于死板。我准备加第二种 689c 风格：同样是 20B，但 value 槽位直接放完整 `kv`，不是低 24 位拆值。这样能直接验证“不是 metadata 缺失，而是 metadata 编码错形”。

Generating patch (103 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```


Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh

新变体已经编译过了。我现在直接把二进制推到设备上，先测最小链 `control + rate + metadata(full-kv) + connect`，看 `pcm_open` 还停不停在同一个 `-5`。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && adb -s 70a91f89 push pure_c_agm_probe /tmp/pure_c_agm_probe

Ran terminal command:  adb -s 70a91f89 shell /tmp/pure_c_agm_probe --skip-helper-prep --rate-ch-fmt-1
Completed with input:  adb -s 70a91f89 shell /tmp/pure_c_agm_probe --skip-helper-prep --rate-ch-fmt-1

Ran terminal command:  adb -s 70a91f89 shell /tmp/pure_c_agm_probe --skip-helper-prep --rate-ch-fmt-1 --metadata-689c-full-kv
Completed with input:  adb -s 70a91f89 shell /tmp/pure_c_agm_probe --skip-helper-prep --rate-ch-fmt-1 --metadata-689c-full-kv

20B 的 689c full-kv 变体已经验证过，结果完全不动。说明问题不只是“低 24 位 vs 完整 kv”这一级。下一步我补一个更接近 `0x6a54` 的 40B `PCM100 metadata` 负载，把 `stream_kv + devicepp_kv + A400 block` 一次性塞进去。

Using "Apply Patch"

`0x689c` 这条 20B payload 没有任何边界变化，说明问题大概率不在“小 metadata 值写法”。我再补一个更接近 `0x6a54` 的 32B 最小块，测试“大 payload 本身”是不是进入图建立的必要前置。

Generating patch (69 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```


Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb -s 70a91f89 push pure_c_agm_probe /tmp/pure_c_agm_probe

Ran terminal command:  adb -s 70a91f89 shell /tmp/pure_c_agm_probe --skip-helper-prep --rate-ch-fmt-1 --metadata-6a54-min
Completed with input:  adb -s 70a91f89 shell /tmp/pure_c_agm_probe --skip-helper-prep --rate-ch-fmt-1 --metadata-6a54-min

Ran terminal command:  adb -s 70a91f89 shell /tmp/pure_c_agm_probe --skip-helper-prep --rate-ch-fmt-1 --metadata-6a54-plus-689c
Completed with input:  adb -s 70a91f89 shell /tmp/pure_c_agm_probe --skip-helper-prep --rate-ch-fmt-1 --metadata-6a54-plus-689c

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#1490-1490), lines 1490 to 1535

Read memory twrp_audio_helper_timing_delta_20260317.md

Read memory twrp_audio_pcm100_setparamtag.md

结果很硬：20B 的 689c full-kv、32B 的 6a54 最小大 payload、以及两者叠加，全部都没有把边界从 `-5` 再往前推，而且 `getTaggedInfo` 仍然是 `-19`。我把这个结论落到文档和 repo memory，避免后面再回头试同一类 payload 猜法。

Generating patch (42 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```


Inserted into memory file twrp_audio_helper_timing_delta_20260317.md

Inserted into memory file twrp_audio_pcm100_setparamtag.md

继续做完了一轮更贴近 tinyplay_ftm 的 metadata payload 验证，结论是否定的：

1. 我给 pure_c_agm_probe 加了三个新实验开关：
1. --metadata-689c-full-kv
2. --metadata-6a54-min
3. --metadata-6a54-plus-689c

2. 这三组分别对应：
1. 20B 的 0x689c 风格 full-kv metadata
2. 32B 的 0x6a54 最小大块 metadata
3. 先 6a54 再叠 689c

3. 实机结果完全一致：
1. 都还是 pcm_open 到 Unknown error -5
2. PCM100 metadata 写入本身都是 rc=0
3. PCM100 getTaggedInfo 还是 rc=-19
4. 最终读回依然全零，没有任何新增推进

这轮新结论很明确：

1. 当前缺口不在 PCM100 metadata 的小 payload 编码形态
2. 也不是缺一块 20B 或 32B 的 metadata
3. control + 32 位四槽 rate 写入 + connect 仍然是唯一被证明能把边界推进到 -5 的最小集合
4. 真正还缺的，更像是 Instance key is added 之后那次 mixer_ctl_get_array 依赖的高阶 graph 或 tagged-info 前置状态

我已经把这轮结果同步进主文档和 repo memory，避免后面再回头试同一类 metadata 猜法。

这轮还实际改了 probe，后面如果继续可以直接沿这条线往下加实验，不用重做脚手架。

下一步最有价值的方向只剩一个：

1. 继续静态拆 libagmmixer.so，定位 Instance key is added 后面那次 Failed to mixer_ctl_get_array 到底在读哪个控件
2. 一旦把那个控件名和 payload 结构抠出来，再回到纯 C probe 里补真正缺的前置链，而不是继续猜 metadata 小块布局

如果你要我继续，我下一步就直接转去抠 libagmmixer.so 里这条 get_array 调用链。

Made changes.

User: 继续

GitHub Copilot: 我继续往 libagmmixer.so 里抠那条 get_array 调用链，目标是把 Instance key is added 后面失败的那个控件名和调用分支真正定位出来。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d libagmmixer.so | grep -n '912c3c42\|912ac042\|91284842\|9129b842\|9129ac42\|91289c42' | sed -n '1,120p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d libagmmixer.so | grep -n 'mixer_ctl_get_array@plt\|mixer_get_ctl_by_name@plt' | sed -n '1,120p'

现在已经收窄到 libagmmixer.so 里只有三个 get_array 调用点。下一步我直接看这三段反汇编，把哪个分支会打出 Instance key is added 和 Failed to mixer_ctl_get_array 对上。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d libagmmixer.so | sed -n '2788,2860p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d libagmmixer.so | sed -n '4390,4448p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d libagmmixer.so | sed -n '4478,4528p'

三个 get_array 位点的形态已经分出来了：

1. aa88 读 1024B 缓冲并在里面按 tag 扫描条目，这就是 getTaggedInfo 那条
2. c370 先写 24B 再读回 24B，更像某个 payload builder 的回读 helper
3. c4a0 只读 8B，明显不是当前图里的大块 metadata

下一步我把导出 wrapper 和这三个内部 helper 对上，确认哪个导出 API 最终会落到 aa88 这条失败链。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d libagmmixer.so | sed -n '5000,5095p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d libagmmixer.so | grep -n 'bl\s\+0xaa88\|bl\s\+0xc370\|bl\s\+0xc4a0\|bl\s\+0xaa5c\|bl\s\+0xc490' | sed -n '1,120p'

调用者搜索没直接出结果，说明这几个 helper 不是被简单直呼号进去的，而是被更大的内部函数包着。现在我改看导出符号的 wrapper 入口，直接找它们各自跳到哪个内部地址。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0xd470 --stop-address=0xd5f8 libagmmixer.so

导出入口已经对上了：

1. agm_mixer_get_miid 直接跳到 a988，里面就是 aa88 那条 1024B getTaggedInfo 路
2. set_agm_streamdevice_metadata 跳到 b9c8
3. agm_mixer_get_event_param 跳到 c22c
4. agm_mixer_get_buf_tstamp 跳到 c3d4

我现在直接看 a988 和 b9c8，这两处最可能一个负责失败日志，一个负责 Instance key is added。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d libagmmixer.so | sed -n '2748,2865p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d libagmmixer.so | sed -n '3750,3928p'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_KJDCaI8J5M12je367YOyldls__vscode-1773795047723/content.txt)

结果已经很清楚了：

1. set_agm_streamdevice_metadata 落到的正是 tinyplay_ftm 里那条 20B payload helper
2. 它本身不读 get_array，也不会直接产出 Failed to mixer_ctl_get_array
3. agm_mixer_get_miid 才是唯一那条 1024B getTaggedInfo 扫描链

还差一块：把 Instance key is added 这条日志在 libagmmixer.so 里的具体位置抓出来，看它是不是就在 stream metadata 那一层。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d libagmmixer.so | grep -n 'add     x0, x0, #0xcde\|add     x1, x1, #0xcde\|add     x2, x2, #0xcde\|add     x8, x8, #0xcde' | sed -n '1,80p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d libagmmixer.so | grep -n '#0xcde\|0xcde' | sed -n '1,120p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --print-imm-hex libagmmixer.so | grep -n '0x2cde\|0xcde' | sed -n '1,120p'

抓到了，Instance key is added 的引用点在 bcf0。我现在把这一小段上下文展开，看它到底属于 set_agm_stream_metadata 还是别的 metadata helper，以及触发条件是什么。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d libagmmixer.so | sed -n '3970,4025p'

关键落点已经出来了：

1. Instance key is added 不在 set_agm_streamdevice_metadata
2. 它在 set_agm_stream_metadata 后半段那条更大的 payload 分支里
3. 也就是说，当前日志序列其实是：
1. set_agm_stream_metadata 里把 instance key 塞进 payload
2. 然后后续某一步去走 agm_mixer_get_miid 或相关 get_array 路，失败在 getTaggedInfo

这意味着下一步要回头核对的，不是 streamdevice metadata，而是我们现在对 set_agm_stream_metadata 的调用形态到底有没有传错。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1038-1038), lines 1038 to 1074

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3768-3768), lines 3768 to 3800

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n "set_agm_stream_metadata\s*\(" android_vendor_twrp device_tree twrp_a12_compile twrp_a16_compile audio_manual docs -g '*.[ch]' -g '*.cpp' -g '*.cc' -g '*.hpp' -g '*.md'
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n "set_agm_stream_metadata\s*\(" android_vendor_twrp device_tree twrp_a12_compile twrp_a16_compile audio_manual docs -g '*.[ch]' -g '*.cpp' -g '*.cc' -g '*.hpp' -g '*.md'

我已经确认了一个关键方向变化：问题链现在更像是 set_agm_stream_metadata 的 instance 部分没真正对上，而不是 streamdevice metadata。本体里那条 Instance key is added 就是在 stream metadata 的大 payload 分支里打的。接下来我直接对齐这个 helper 的实参语义。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1048-1048), lines 1048 to 1068

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1068-1068), lines 1068 to 1095

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1095-1095), lines 1095 to 1125

我找到一个比前面 payload 猜法更硬的点了：libagmmixer.so 里 set_agm_stream_metadata 在拼 payload 时，是把最后一个参数直接当成 instance 值写进去的，不像是再左移 16 位后使用。我们现在 helper-prep 传的是 0x00010000，不是 1，这很可能就是 Instance key 虽然被“添加”了，但图没法继续往下走的原因。

Searched for regex `instance_kv << 16|instance_kv=0x1|instance_bits|set_agm_stream_metadata` (`**/docs/TWRP音频手动Bring-up.md`), 10 results

前面的文档结论和这段新反汇编现在冲突了，不能靠口头判断。我先给 probe 加一个原始 instance 值开关，直接做 A/B：0x00010000 对 1，看看 helper-prep 基线会不会立刻动边界。

Generating patch (63 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```


Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb -s 70a91f89 push pure_c_agm_probe /tmp/pure_c_agm_probe

新开关已经上机。我直接跑 helper-prep 基线 A/B，对比 0x00010000 和 1 两种 instance 传参是否会改变 getTaggedInfo 或 pcm_open 的边界。

Ran terminal command:  adb -s 70a91f89 shell /tmp/pure_c_agm_probe
Completed with input:  adb -s 70a91f89 shell /tmp/pure_c_agm_probe

Ran terminal command:  adb -s 70a91f89 shell /tmp/pure_c_agm_probe --stream-metadata-instance-raw
Completed with input:  adb -s 70a91f89 shell /tmp/pure_c_agm_probe --stream-metadata-instance-raw

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_2El7EQaniiakXY1ZmFABiULQ__vscode-1773795047738/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_4wwKd9PquloyUmxtbbCdNgpY__vscode-1773795047739/content.txt)

我再往下把 set_agm_stream_metadata 这条大 payload helper 读完，重点看它在加完 instance 之后还会不会用到别的调用参数。现在不能排除我们不是 instance 值错，而是别的实参一直传 0，导致后半段 payload 少了一截。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d libagmmixer.so | sed -n '4025,4098p'

我先不再猜 helper 参数排列了，改去确认 pcm 插件自己在 open 路里到底调用哪个 agmmixer helper、带哪个 tag。只要把插件这条调用链钉死，就能知道我们该补的是哪一类前置状态。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && nm -D libagm_pcm_plugin.so | sed -n '1,220p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d libagm_pcm_plugin.so | grep -n 'agm_mixer_get_miid\|configure_mfc\|agm_mixer_set_param\|connect_agm_audio_intf_to_stream\|set_agm_stream_metadata\|set_agm_streamdevice_metadata' | sed -n '1,120p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && readelf -Ws libagm_pcm_plugin.so | grep 'agm_' | sed -n '1,160p'

pcm 插件这边反而给了一个排除项：它根本不直接依赖 libagmmixer 的那些 helper，只走 agm_session_open、agm_session_set_config、agm_session_prepare 这一套。也就是说，Failed to mixer_ctl_get_array 更像是 mixer 插件或 libagmmixer 侧在 card100 的 mixer 初始化阶段打出来的，不是 pcm 插件自己直接读 getTaggedInfo。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && nm -D libagm_mixer_plugin.so | sed -n '1,260p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && readelf -Ws libagm_mixer_plugin.so | grep 'agm_' | sed -n '1,220p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d libagm_mixer_plugin.so | grep -n 'agm_mixer_get_miid\|set_agm_stream_metadata\|set_agm_streamdevice_metadata\|set_agm_audio_intf_metadata\|connect_agm_audio_intf_to_stream\|agm_mixer_set_param' | sed -n '1,160p'

新信息又缩了一层：

1. mixer 插件和 pcm 插件都不直接调 libagmmixer 这些高层 helper
2. 它们直接依赖的是底层 agm_session_open、agm_session_set_metadata、agm_session_aif_set_metadata、agm_set_params_with_tag 这一套
3. 这说明 card100 的 plugin 成功路径，真正可能缺的已经更像 AGM session 层状态，而不是再补一层 mixer 控件 helper

我先查工作区里有没有现成的 AGM session API 声明或调用样例，能的话就直接把纯 C probe 往这层扩。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n "agm_session_open|agm_session_set_config|agm_session_prepare|agm_session_set_metadata|agm_session_aif_set_metadata|agm_set_params_with_tag|agm_session_aif_get_tag_module_info" audio_dtb_probe android_vendor_twrp device_tree twrp_a12_compile twrp_a16_compile docs -g '*.[ch]' -g '*.cpp' -g '*.cc' -g '*.hpp' -g '*.md'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && strings -a agmplay | grep -n 'agm_session_open\|agm_session_set_config\|agm_session_prepare\|agm_session_start\|agm_set_params_with_tag\|agm_session_aif_set_metadata' | sed -n '1,120p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && nm -D agmplay | grep 'agm_' | sed -n '1,160p'

我回看了一下另外一个被我们放低优先级的缺口：agmplay 确实还导入了 set_agm_group_device_config 和 set_agm_group_mux_config，而 pure_c_agm_probe 目前完全没碰这两条。相比继续猜 metadata 小块，这两个未覆盖的 helper 现在反而更值得追。

Searched for regex `set_agm_group_device_config|set_agm_group_mux_config` (`**/docs/TWRP音频手动Bring-up.md`), 2 results

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d libagmmixer.so | sed -n '2360,2460p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d libagmmixer.so | sed -n '2525,2635p'

group_device_config 这条不像之前担心的“超复杂 hidden graph helper”，它更像是另一种 media-config 写法，复杂度不高。group_mux_config 我再看一眼；如果它也是简单控件，那就值得直接补进 probe 做实验。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0xa69c --stop-address=0xa874 libagmmixer.so

这一轮已经有两个硬结论值得固化了：

1. Instance key is added 的真实来源已经定位到 libagmmixer.so 的 set_agm_stream_metadata 大 payload 分支
2. 把 stream metadata 的 instance 从 0x00010000 改成 1，实机完全没有变化

我先把这两个结论记到文档和 repo memory，后面就不会再在这个歧路上来回。

Generating patch (61 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```


Inserted into memory file twrp_audio_helper_timing_delta_20260317.md

Inserted into memory file twrp_audio_pcm100_setparamtag.md

这一轮继续往前压出了两个硬结论。

1. 日志来源已经钉死
1. Instance key is added 不是 set_agm_streamdevice_metadata 打的
2. 它实际来自 libagmmixer.so 里的 set_agm_stream_metadata 大 payload 分支
3. Failed to mixer_ctl_get_array 则来自 agm_mixer_get_miid 内部对 PCM100 getTaggedInfo 的 1024B 读回链

2. 我把 stream metadata 的 instance 传参做了直接 A/B
1. 现有 helper-prep 传 0x00010000
2. 新增开关传原始值 1
3. 两边结果完全一样：
1. stream metadata 后仍然是 getTaggedInfo = -22
2. streamdevice metadata 后仍然推进到 -19
3. 最终还是 pcm_open = -5
4. 运行时照样出现 Instance key is added 和 Failed to mixer_ctl_get_array

3. 这说明一个重要纠偏
1. 当前问题确实和 stream metadata 这条大 payload 链有关
2. 但不是 instance 从 0x00010000 改成 1 这种小编码问题
3. 现在真正缺的，还是 Instance key is added 之后、getTaggedInfo 能真正读出 tag/module 信息之前的更高阶 graph 状态

4. 额外确认了一条结构性信息
1. libagm_pcm_plugin.so 并不直接依赖这些 agmmixer 高层 helper
2. 它直接走 agm_session_open、agm_session_set_config、agm_session_prepare 这一层
3. libagm_mixer_plugin.so 也主要依赖底层 agm_session 和 agm_aif 接口
4. 所以 plugin 成功路径本质上更靠近 AGM session 状态，而不是单纯的 mixer 控件 helper

我已经把这轮结论写进文档和 repo memory，并把 probe 保留了新开关，后面不用重复搭脚手架。

下一步最有价值的方向已经更明确了：
1. 继续抠是谁负责把 getTaggedInfo 所需状态真正立起来
2. 优先看 agm_session 侧和 group mux/group device 这类还没接进 probe 的 helper
3. 不再继续围绕 stream metadata 的 instance 小编码来回试错

Made changes.

User: 继续

GitHub Copilot: 我先把 agmplay 里 group_device_config 和 group_mux_config 的实际调用点抠出来，目标是确认它们是不是主路径前置动作，以及实参长什么样。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d agmplay | grep -n 'set_agm_group_device_config@plt\|set_agm_group_mux_config@plt' | sed -n '1,120p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && nm -D agmplay | grep 'set_agm_group_device_config\|set_agm_group_mux_config'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d agmplay | grep -n 'get_agm_usb_audio_config_payload@plt\|set_agm_device_custom_payload@plt' | sed -n '1,120p'

调用点已经找到了，group helper 确实在 agmplay 主链里，而且它们出现在 custom payload 之后。我现在展开这段主链，直接看实参来源和顺序。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d agmplay | sed -n '2608,2778p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && strings -a -t x agmplay | grep -n 'group device\|group mux\|speaker\|usb\|TDM-LPAIF-RX-SECONDARY\|PCM100' | sed -n '1,120p'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_1pbLcoLoLh02DDP1otslLwDu__vscode-1773795047762/content.txt)

agplay 主链时序已经对上了：group_device_config 是 pre-open 条件分支，group_mux_config 是 pcm_open 成功后的后处理，不是当前 `-5` 之前的必要动作。我再把那个 pre-open 条件字符串抠出来，确认 TDM-LPAIF-RX-SECONDARY 这条 speaker 路到底会不会命中。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && xxd -g 1 -s 0x2920 -l 0xc0 agmplay

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && xxd -g 1 -s 0x2980 -l 0x80 agmplay

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && xxd -g 1 -s 0x28e0 -l 0x60 agmplay

新的收窄结果已经出来了：`set_agm_group_device_config` 只在接口名包含 `VIRT-` 时才走，`set_agm_device_custom_payload` 只在 `USB_AUDIO-RX` 才走。它们对当前 `TDM-LPAIF-RX-SECONDARY` speaker 路都不生效，所以这两条又可以从主线里排掉。下一步我直接核对 agmplay 对四个核心 helper 的真实实参。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d agmplay | sed -n '2530,2685p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d agmplay | grep -n 'set_agm_device_media_config@plt\|set_agm_audio_intf_metadata@plt\|set_agm_stream_metadata@plt\|set_agm_streamdevice_metadata@plt' | sed -n '1,120p'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_PNN6GQ5Dh3iFb7oEzsaSVctj__vscode-1773795047768/content.txt)

我这里发现了一个比前面更值得试的差异：agmplay 主链里确实存在两处 set_agm_stream_metadata 调用点，不是单一静态调用点。我要把这两处的分支条件看清楚，判断当前 speaker 路是不是其实应该走第二次调用。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d agmplay | sed -n '2475,2675p'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_wYBxEj1Q1v4jEn5hgflzux43__vscode-1773795047771/content.txt)

我把 agmplay 的两次 set_agm_stream_metadata 分支看清了：正常有 interface 列表的路径只会调用一次，第二次调用只走“没有 interface”的退化分支，所以这条不是当前差异。下一步我去核对 set_agm_audio_intf_metadata 和 set_agm_stream_metadata 的实参语义本身。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0xb26c --stop-address=0xb5dc libagmmixer.so

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0xbb90 --stop-address=0xbe70 libagmmixer.so

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_VmTslYSiPiXleEMWLJflzWMz__vscode-1773795047773/content.txt)

我这里补一个更值钱的实机对照：把 pure_c_agm_probe 收到更接近 agmplay 真路径，去掉我们自己额外塞进去的初始 PCM100 control，只保留 helper-prep 和 helper-connect，看是不是这些“补救性手写控件”反而把路径拐偏了。

Generating patch (58 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
我已经把“去掉初始 control”这个对照入口加进 probe。现在直接编译上机，跑两组更接近 agmplay 的 helper-only 路径，看是否会改变当前 `-5` 前沿。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb -s 70a91f89 push pure_c_agm_probe /tmp/pure_c_agm_probe

这次实验只测 agmplay 风格的 helper-only 分支，目标很单一：确认是不是我们后续手工 control/rate/split 直写把真实路径污染了。

Ran terminal command:  adb -s 70a91f89 shell /tmp/pure_c_agm_probe --skip-rate-write --skip-split-metadata --helper-connect
Completed with input:  adb -s 70a91f89 shell /tmp/pure_c_agm_probe --skip-rate-write --skip-split-metadata --helper-connect

Ran terminal command:  adb -s 70a91f89 shell /tmp/pure_c_agm_probe --skip-rate-write --skip-split-metadata --helper-connect --skip-initial-control
Completed with input:  adb -s 70a91f89 shell /tmp/pure_c_agm_probe --skip-rate-write --skip-split-metadata --helper-connect --skip-initial-control

Ran terminal command:  adb -s 70a91f89 shell /tmp/pure_c_agm_probe --skip-rate-write --skip-split-metadata --helper-connect --skip-initial-control --stream-metadata-instance-raw
Completed with input:  adb -s 70a91f89 shell /tmp/pure_c_agm_probe --skip-rate-write --skip-split-metadata --helper-connect --skip-initial-control --stream-metadata-instance-raw

三组结果已经回来了。我只看两件事：有没有从 `-5` 脱离，以及 `Failed to mixer_ctl_get_array` / `getTaggedInfo` 的边界有没有发生变化。

Searched for regex `Unknown error -5|Unknown error -19|Unknown error -22|Unknown error -32|Failed to mixer_ctl_get_array|Instance key is added|getTaggedInfo type=BYTE rc=-19|getTaggedInfo type=BYTE rc=-22|getTaggedInfo type=BYTE rc=0` (`**//Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_2tJjxTAZxmiSxIbHe0DTOTYF__vscode-1773795047778/content.txt`), no results

Searched for regex `Unknown error -5|Unknown error -19|Unknown error -22|Unknown error -32|Failed to mixer_ctl_get_array|Instance key is added|getTaggedInfo type=BYTE rc=-19|getTaggedInfo type=BYTE rc=-22|getTaggedInfo type=BYTE rc=0` (`**//Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_4A5qNS7Wlj1jJ0OPrr9Emfso__vscode-1773795047779/content.txt`), no results

Searched for regex `Unknown error -5|Unknown error -19|Unknown error -22|Unknown error -32|Failed to mixer_ctl_get_array|Instance key is added|getTaggedInfo type=BYTE rc=-19|getTaggedInfo type=BYTE rc=-22|getTaggedInfo type=BYTE rc=0` (`**//Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_gcMjAfjkPkFyyrvGoxxYg6ex__vscode-1773795047780/content.txt`), no results

搜索视图没吃到这些会话文件，我直接读取结果尾段，确认最终错误和关键日志有没有变化。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_2tJjxTAZxmiSxIbHe0DTOTYF__vscode-1773795047778/content.txt#111-111), lines 111 to 111

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_4A5qNS7Wlj1jJ0OPrr9Emfso__vscode-1773795047779/content.txt#111-111), lines 111 to 111

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_gcMjAfjkPkFyyrvGoxxYg6ex__vscode-1773795047780/content.txt#111-111), lines 111 to 111

读取工具不认这些临时输出文件，我改用终端直接抽关键行，结果会更快更干净。

Ran terminal command:  grep -E 'Unknown error|Failed to mixer_ctl_get_array|Instance key is added|getTaggedInfo type=BYTE rc=' '/Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_2tJjxTAZxmiSxIbHe0DTOTYF__vscode-1773795047778/content.txt' | tail -n 20

Ran terminal command:  grep -E 'Unknown error|Failed to mixer_ctl_get_array|Instance key is added|getTaggedInfo type=BYTE rc=' '/Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_4A5qNS7Wlj1jJ0OPrr9Emfso__vscode-1773795047779/content.txt' | tail -n 20

Ran terminal command:  grep -E 'Unknown error|Failed to mixer_ctl_get_array|Instance key is added|getTaggedInfo type=BYTE rc=' '/Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_gcMjAfjkPkFyyrvGoxxYg6ex__vscode-1773795047780/content.txt' | tail -n 20

这轮新边界也出来了：只保留 agmplay 风格 helper-prep 和 helper-connect、完全去掉手工 rate/split 直写时，结果会统一退回 `pcm_open -19`。这说明 recovery 里高层 helper 自己并没有把 `<intf> rate ch fmt` 这一步真正立起来，手工 rate 写入依然是把边界推到 `-5` 的必要条件。下一步我去找工作区里有没有现成 AGM 头文件，争取把主线往 session API 真原型推进，而不是再猜。

Searched for files matching `**/*agm*.h`, 120 matches

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n "agm_session_open\s*\(|agm_session_set_config\s*\(|agm_session_prepare\s*\(|agm_aif_set_metadata\s*\(|agm_session_aif_set_metadata\s*\(|agm_set_params_with_tag\s*\(" android_vendor_twrp device_tree twrp_a12_compile twrp_a16_compile -g '*.[ch]' -g '*.hpp' -g '*.cpp' -g '*.cc'
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n "agm_session_open\s*\(|agm_session_set_config\s*\(|agm_session_prepare\s*\(|agm_aif_set_metadata\s*\(|agm_session_aif_set_metadata\s*\(|agm_set_params_with_tag\s*\(" android_vendor_twrp device_tree twrp_a12_compile twrp_a16_compile -g '*.[ch]' -g '*.hpp' -g '*.cpp' -g '*.cc'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n "typedef .*agm_.*session|struct agm_.*config|enum agm_.*mode|AGM_SESSION_" twrp_a12_compile twrp_a16_compile android_vendor_twrp device_tree -g '*.[ch]' -g '*.hpp'
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n "typedef .*agm_.*session|struct agm_.*config|enum agm_.*mode|AGM_SESSION_" twrp_a12_compile twrp_a16_compile android_vendor_twrp device_tree -g '*.[ch]' -g '*.hpp'

工作区源码里没直接搜到 AGM session 原型，但我还没放弃这个方向。我先按更像样的头文件名去搜一轮，看看树里有没有被藏在 vendor/qcom 或预编译导出目录里的 AGM 头。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg --files | rg '/(agm|libagm|audio).*\.h$|agm_.*\.h$' | sed -n '1,200p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg --files | rg 'audio.*(vendor|qcom|kernel|hal).*\.(h|hpp)$|qti.*audio.*\.(h|hpp)$' | sed -n '1,200p'

Ran terminal command:  grep -i '/agm\|agm_' '/Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_mIqVsnL5GrOOKe6umc0oQpaZ__vscode-1773795047793/content.txt' | head -n 120

Ran terminal command:  grep -i 'agm\|qti.*audio\|pal_' '/Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_UFkuFH7WqU20QEjH1EBLm5hp__vscode-1773795047794/content.txt' | head -n 120

这一轮再落两条结论就够了：`VIRT-/USB` 相关 helper 对 speaker 路无关；更接近 agmplay 的 helper-only 分支反而稳定退回 `-19`，说明 recovery 里真正缺的仍是那次手工 rate 写入。 ես

Generating patch (73 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```


Inserted into memory file twrp_audio_helper_timing_delta_20260317.md

Inserted into memory file twrp_audio_pcm100_setparamtag.md

我再往前探一格，把 libagm.so 里的 agm_session_open 和 set_config wrapper 入口定位出来。这样即使这轮还不直接接进 probe，下一步也不再是盲猜 ABI。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && nm -D libagm.so | grep ' agm_session_open\| agm_session_set_config\| agm_session_prepare\| agm_session_start\| agm_session_aif_set_metadata\| agm_aif_set_metadata\| agm_set_params_with_tag' | sed -n '1,160p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0xd5a0 --stop-address=0xd760 libagm.so

继续推进了一轮，新增的有效结论有四个。

1. agmplay 里剩余那几条 helper 已经排干净了
1. set_agm_group_device_config 只对接口名包含 VIRT- 的路径生效
2. set_agm_device_custom_payload 只对 USB_AUDIO-RX 生效
3. set_agm_group_mux_config 是 pcm_open 成功之后的 post-open 动作
4. 所以这三条都不是当前 TDM-LPAIF-RX-SECONDARY speaker 路的 pre-open 缺口

2. 更接近 agmplay 的 helper-only 路径，实机会统一退回 -19
1. 我给 probe 加了 skip-initial-control 开关
2. 跑了三组更接近 agmplay 的分支：
1. skip-rate-write + skip-split-metadata + helper-connect
2. 再去掉初始 PCM100 control
3. 再叠 raw instance
3. 三组结果完全一致：
1. stream metadata 后还是 getTaggedInfo = -22
2. streamdevice metadata 后还是 getTaggedInfo = -19
3. pcm_open 从之前的 -5 退回 Unknown error -19
4. 仍然出现 Instance key is added 和 Failed to mixer_ctl_get_array

3. 这把当前边界又钉死了一层
1. recovery 里单靠 agmplay 风格的高层 helper 链，不足以推进到 -5
2. 手工 32 位四槽的 intf rate ch fmt 写入，仍然是把 -19 推到 -5 的必要动作
3. 去掉初始 control 没用
4. 把 stream metadata 的 instance 改成 1 也没用

4. 我还顺手把下一跳入口定位了
1. libagm.so 里关键导出地址已经拿到了：
1. agm_session_open 在 0x37430
2. agm_session_set_config 在 0x37440
3. agm_session_prepare 在 0x377c0
4. agm_session_start 在 0x377c8
5. agm_aif_set_metadata 在 0x37370
6. agm_session_aif_set_metadata 在 0x37380
7. agm_set_params_with_tag 在 0x373e0
2. 这意味着下一步不再需要盲找导出名，直接可以从这些入口反推 session ABI

我已经把这轮结果同步进文档和 repo memory。

当前最靠谱的下一步只剩一个方向：
1. 直接逆 libagm.so 这几个 session 导出入口
2. 先把 agm_session_open 和 agm_session_set_config 的真实 ABI 抠出来
3. 再决定是把 pure_c_agm_probe 扩到 session 层，还是继续从 plugin 调用链倒推前置状态

Made changes.

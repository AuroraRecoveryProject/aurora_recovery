# 第5章：Tinyplay FTM反汇编分析与Direct-Control探针

User: 继续

GitHub Copilot: 我先把反推面扩大到 AIDL/parcelable 层，目标是不再盲猜 `agm_session_open`，而是从 `vendor.qti.hardware.agm-V1-ndk.so` 和相关库把真实入参模型挖出来。

Searched for regex `AgmSessionConfig|AgmMediaConfig|AgmBufferConfig|IAGM` (`**/extracted_20260318_034751/**`), 10 results

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP/extracted_20260318_034751 && strings vendor/vendor/lib64/vendor.qti.hardware.agm-V1-ndk.so | grep -E "AgmSessionConfig|AgmMediaConfig|AgmBufferConfig|AifInfo|openSession|setConfig|prepare|start|close|write|IAGM" | head -n 300

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP/extracted_20260318_034751 && llvm-nm -D vendor/vendor/lib64/vendor.qti.hardware.agm-V1-ndk.so | head -n 200

AIDL 库的字符串已经抓到了，我先读关键片段，优先看 `IAGM` 方法名和 `AgmSessionConfig` 相关 parcelable。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_rV0NCKaHe5NNWsJsMOBvwm8c__vscode-1773775025716/content.txt)

AIDL 符号已经把关键形状暴露出来了：`session_open` 是 `(int session_id, AgmSessionMode, long* handle)`，而后续 `set_config/prepare/start/close` 吃的是那个 `long handle`，不再是 `session_id`。我先按这个形状修探针，再上机验证是否摆脱崩溃。

Generating patch (129 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
原型已经按 AIDL 形状改正。我现在直接重编并重跑 `--probe-session`，看是否从“立刻崩溃”推进到“至少拿到 handle 和返回码”。

Ran terminal command:  cd /Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player && ./build_agm_demo.sh

Ran terminal command:  adb -s 70a91f89 push agm_audio_demo /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell 'logcat -c && /data/local/tmp/agm_audio_demo --probe-session >/data/local/tmp/agm_probe.out 2>&1; echo EXIT:$?; tail -n 160 /data/local/tmp/agm_probe.out'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -E "debug probe session|AGM: API: agm_session_(open|set_config|prepare|start|close|aif_connect)|AgmIpc::|graph_open|graph_start|Error:" | tail -n 220'

现在已经前进了一大步：`agm_session_open` 不再崩了，真实形状基本坐实，而且 `mode=0` 时返回 `-32`。下一步我补 `agm_init()` 并把 `session mode` 做一个小范围枚举，看看是“少初始化”还是“mode 选错”。

Generating patch (63 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
我继续做最小代价回归：重编、上机跑 probe，目标是拿到 `agm_init` 返回值和各个 `session mode` 的 open 结果。

Ran terminal command:  ./build_agm_demo.sh

Ran terminal command:  adb -s 70a91f89 push agm_audio_demo /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell 'logcat -c && /data/local/tmp/agm_audio_demo --probe-session >/data/local/tmp/agm_probe.out 2>&1; echo EXIT:$?; tail -n 200 /data/local/tmp/agm_probe.out'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -E "debug probe session|AGM: API: agm_init|AgmIpc::|agm_session_open|Error:" | tail -n 220'

`agm_init` 已经确认不是缺口，`session_open` 在 mode `0..5` 全部稳定返回 `-32`。下一步我直接去抠 `AgmSessionMode` 的枚举名和 `tinyplay_ftm` 的 open 前上下文，避免继续在错误 mode 上空转。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP/extracted_20260318_034751 && strings vendor/vendor/lib64/vendor.qti.hardware.agm-V1-ndk.so | grep -E "AgmSessionMode|TUNNEL|NON_TUNNEL|LOW_LATENCY|PCM|COMPRESS|ULL|ULLPP|DEEP_BUFFER" | head -n 200

Ran terminal command:  adb -s 70a91f89 shell 'logcat -c && setprop vendor.oplus.mm.ftm_spk 1 && /odm/bin/tinyplay_ftm /data/local/tmp/test440_mid_10s.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY >/dev/null 2>&1 && logcat -d | grep -E "tinyplay_ftm|AGM: API: agm_session_|AgmIpc::|graph_open|graph_start|stream_kv|device_kv|Instance key" | tail -n 260'

Ran terminal command:  adb -s 70a91f89 shell 'strace -f -o /data/local/tmp/strace_tinyplay_open.txt /odm/bin/tinyplay_ftm /data/local/tmp/test440_mid_10s.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY >/dev/null 2>&1; tail -n 200 /data/local/tmp/strace_tinyplay_open.txt | grep -E "libagmclient|libagm|ioctl|binder|AIBinder|openat"'

现在有个更关键的偏移：`tinyplay_ftm` 的公开日志里根本没出现 `session_open`，`SessionInfo created` 反而是在 `aif_connect` 时生成的。也就是说主线很可能不在 `session_open`，而在“`aif_connect` 之后 tinyplay_ftm 到底打开了哪个 PCM/插件节点、用了什么前置动作”。我直接抓它的完整 `strace` 文件来对齐这一段。

Ran terminal command:  adb -s 70a91f89 shell 'rm -f /data/local/tmp/strace_tinyplay_open.txt; strace -f -o /data/local/tmp/strace_tinyplay_open.txt /odm/bin/tinyplay_ftm /data/local/tmp/test440_mid_10s.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY >/dev/null 2>&1; wc -l /data/local/tmp/strace_tinyplay_open.txt'

Ran terminal command:  adb -s 70a91f89 pull /data/local/tmp/strace_tinyplay_open.txt /Volumes/Case-sensitive\ APFS/TWRP/audio_manual/strace_tinyplay_open_20260318.txt

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && rg -n "libagm|libagmclient|libagmmixer|pcmC|/dev/snd|backend_conf|usecaseKvManager|binder|ioctl\(|openat\(" audio_manual/strace_tinyplay_open_20260318.txt | head -n 260

完整 `strace` 已经落到工作区了。我先读筛选结果，确认 `tinyplay_ftm` 到底开的是什么设备和配置文件。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_AD7kcPUfqgSh3pUIiMQtQDD4__vscode-1773775025733/content.txt#1-1), lines 1 to 260

筛选结果已经给出一个方向：`tinyplay_ftm` 明确走的是 `libagm_mixer_plugin.so + libagmclient.so + binder + /odm/etc/backend_conf.xml`，而不是先 `session_open`。我继续读它在 `binder` 之后、`graph_open` 之前以及之后的几十行，确认有没有真正打开 `pcmC100D100p` 或其他节点。

Searched for regex `/dev/snd/pcm|pcmC100|pcmC0D|SNDRV_PCM|HW_PARAMS|SW_PARAMS` (`**/audio_manual/strace_tinyplay_open_20260318.txt`), 2 results

Searched for regex `libagm_pcm_plugin|agm_pcm_plugin_open|pcm_plug_open|mixer_plugin_open` (`**/audio_manual/strace_tinyplay_open_20260318.txt`), 11 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/strace_tinyplay_open_20260318.txt#1640-1640), lines 1640 to 1765

关键点已经露出来了：`tinyplay_ftm` 在 binder 建链后，确实 `dlopen` 了 `libagm_pcm_plugin.so`，并进入 `agm_pcm_hw_params`。我再读这一小段，确认它喂给插件的采样参数和是否还有额外 ioctl。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/strace_tinyplay_open_20260318.txt#1766-1766), lines 1766 to 1815

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/strace_tinyplay_open_20260318.txt#2426-2426), lines 2426 to 2445

`strace` 已经把一个旧假设推翻了：`tinyplay_ftm` 成功链里根本没有去 `open /dev/snd/pcmC100D100p`，而是直接走 `libagm_pcm_plugin.so` 的 plugin 数据面。也就是说，主线现在应该从“直开 PCM100”收回来，转去对齐 `agm_pcm_plugin_open + agm_pcm_hw_params`。我先把 plugin 这段在 `tinyplay_ftm` 里的证据再压实。

Searched for regex `pcm_plug_open|agm_pcm_hw_params|agm_pcm_plugin_open|PLUGIN: pcm` (`**/audio_manual/strace_tinyplay_open_20260318.txt`), 5 results

Searched for regex `AGM plugin open 失败: mode=1 card=100 device=100 rc=-5|打开 AGM plugin 成功|AGM hw_params 失败|AGM sw_params 失败|AGM prepare 失败` (`**/video_player/video_player_ffi.c`), 8 results

Ran terminal command:  adb -s 70a91f89 shell 'strings /odm/bin/tinyplay_ftm | grep -E "pcm_plug_open|agm_pcm_hw_params|plugin open|card=|device=|hw_params" | head -n 120'

`strace` 已经给出一个可实现的改动方向：`tinyplay_ftm` 是先 `aif_connect`，然后直接进 `agm_pcm_plugin_open + agm_pcm_hw_params`，并没有先去撞 `pcm_open(card100,device100)`。我先把当前主线改成 plugin-first，避免我们自己把 AGM 状态先撞坏。

Generating patch (46 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
我现在直接用独立 demo 验证这个排序改动，因为它最快、最干净，也最接近 `tinyplay_ftm` 的成功路径。

Ran terminal command:  cd /Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player && ./build_agm_demo.sh

Ran terminal command:  adb -s 70a91f89 push agm_audio_demo /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell 'logcat -c && /data/local/tmp/agm_audio_demo /data/local/tmp/test440_mid_10s.wav >/data/local/tmp/agm_audio_demo.out 2>&1; echo EXIT:$?; tail -n 220 /data/local/tmp/agm_audio_demo.out'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -E "VideoPlayer|PLUGIN: pcm|agm_pcm_hw_params|pcm_plug_open|AGM plugin open|AgmIpc::|graph_open|graph_start|aw882xx_start_pa|serviceDied" | tail -n 320'

Compacted conversation编译已经完成。我先读回运行输出和设备日志，确认 `plugin-first` 是真正改变了路径，还是只是换了失败顺序。Optimizing tool selection...

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_6lv3yP8pZPk00TdN25pZy18T__vscode-1773775025746/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_4KFJ89kMXnZoO927q7USH4RH__vscode-1773775025745/content.txt)

这次结果说明顺序不是根因。`plugin-first` 已经生效了，但 `agm_pcm_plugin_open` 仍旧在第一步就失败，说明现在要查的是“传给 plugin 的参数形状”而不是“先后顺序”。

Searched for regex `open_agm_plugin_output|agm_plugin open|pcm_plug_open|mixer_plugin_open|agm_pcm_plugin_open|open_agm_output` (`**/video_player_ffi.c`), 11 results

Searched for regex `PLUGIN: pcm agm_pcm_hw_params|pcm_plug_open|mixer_plugin_open|backend_conf.xml|device_config not found|Instance key is added` (`**/audio_manual/strace_tinyplay_open_20260318.txt`), 10 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#2288-2288), lines 2288 to 2575

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/strace_tinyplay_open_20260318.txt#1328-1328), lines 1328 to 1788

我现在把对比缩到更小范围：看 `tinyplay_ftm` 成功时传给 plugin 的参数，以及我们当前打开路径到底差在哪一层。 եթե是 ABI/参数错，继续调顺序没有意义。

Searched for files matching `**/tinyplay_ftm*`, no matches

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && sed -n '1766,1778p' audio_manual/strace_tinyplay_open_20260318.txt

Ran terminal command:  cd /Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player && rg -n "typedef.*AgmPcmPluginOpenFn|AgmPcmPluginOpenFn|struct pcm_plugin|pcm_plugin_ops" video_player_ffi.c

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#90-90), lines 90 to 140

Ran terminal command:  adb -s 70a91f89 shell 'strings /vendor/lib64/libagm_pcm_plugin.so | grep -E "agm_pcm_plugin_open|agm_pcm_hw_params|pcm_plug_open|snd_pcm_hw_params|period_size|channels|rate|format" | head -n 120'

Ran terminal command:  adb -s 70a91f89 shell 'strings /vendor/lib64/libagm_mixer_plugin.so | grep -E "agm_mixer_plugin_open|connect_agm_audio_intf_to_stream|set_agm_streamdevice_metadata|get_miid|session_open|prepare|start" | head -n 120'

我去代码树里找有没有 AGM plugin 的头文件或老源码。只要能拿到真实 struct/函数签名，当前这层盲猜就可以结束。

Searched codebase for "AGM pcm plugin open struct pcm_plugin agm_pcm_plugin_open header or source", 22 results

Searching for regex `agm_pcm_plugin_open|agm_mixer_plugin_open|pcm_plugin_ops|struct pcm_plugin` (`**/*.{c,cc,cpp,h,hpp,txt,md,mk,bp}`)

Searching for regex `connect_agm_audio_intf_to_stream|set_agm_streamdevice_metadata|get_device_media_config|backend_conf.xml` (`**/*.{c,cc,cpp,h,hpp,xml,txt,md}`)

文档里已经有一条关键旧结论了：`agmplay` 成功时其实不需要我们现在这么多“手动补 metadata”的动作。我先把那条最小成功条件翻出来，对照当前实现。

Read memory twrp_audio_agmplay_minimal_success.md

Read memory twrp_audio_standard_path_priority.md

Read memory twrp_audio_helper_timing_delta_20260317.md

现在最值得试的不是再补更多控制，而是做一条“更像最小 agmplay”的路径：少写控件，只保留 vendor 已验证必要的那几个前置。先把当前代码里 `instance_kv` 和 metadata 下发点梳理出来。

Searched for regex `instance_kv|set_agm_stream_metadata|set_agm_streamdevice_metadata|set_agm_audio_intf_metadata|connect_agm_audio_intf_to_stream` (`**/video_player_ffi.c`), 55 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#2060-2060), lines 2060 to 2298

我准备加一个“零手工 metadata”的最小 AGM 探针：只走 `pcm_open(card100, device100, 2ch/48k/16bit)`，不碰当前那串 helper。这个实验能直接回答一个关键问题：到底是我们把图写坏了，还是连 pristine 的 plugin/open 也起不来。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/audio_demo_main.c)

Searched for regex `open_plain_pcm|probe write|pcm_write initial|debug play|vp_debug_` (`**/video_player_ffi.c`), 16 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1840-1840), lines 1840 to 1895

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#2930-2930), lines 2930 to 3095

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.h)

我加一个单独的最小探针，不碰现有主路径逻辑。这样能快速判断“pristine `pcm_open(card100,device100)`”是不是本来就可行。

Generating patch (99 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.h), [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/audio_demo_main.c), [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```

```

```

```

```
最小探针已经加进去。接下来直接实跑，看 `card100/device100` 在完全不碰 helper 时，plugin 能不能自己把图拉起来。

Ran terminal command:  ./build_agm_demo.sh

Ran terminal command:  adb -s 70a91f89 push agm_audio_demo /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell 'logcat -c && /data/local/tmp/agm_audio_demo --probe-minimal-agm-pcm >/data/local/tmp/agm_probe_minimal.out 2>&1; echo EXIT:$?; cat /data/local/tmp/agm_probe_minimal.out'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -E "VideoPlayer|pcm_plug_open|PLUGIN: pcm|graph_open|graph_start|AgmIpc::|aw882xx_start_pa|serviceDied" | tail -n 220'

这个结果很关键：即使完全不碰我们自己的 helper，`pcm_open(card100,device100)` 也还是 `Unknown error -32`。所以“我们把图写坏了”这条怀疑可以先降级，差异更可能在 `tinyplay_ftm` 之前那层初始化。

Searched for regex `AgmMixerPluginOpenFn|agm_mixer_plugin_open|load_agm_mixer_plugin` (`**/video_player_ffi.c`), no results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#140-140), lines 140 to 220

Ran terminal command:  adb -s 70a91f89 shell 'strings /vendor/lib64/libagm_mixer_plugin.so | grep -n "agm_mixer_plugin_open" -n'

下一步我不去猜新的 vendor ABI，而是复现 `tinyplay_ftm` 的前置条件本身。它在 `pcm_open` 之前明显先做了 `agm_mixer_plugin_open`，这很可能只是 `mixer_open(100)` 触发的。

Searched for regex `mixer_open\(|struct mixer\* \(\*mixer_open|mixer_close\(` (`**/video_player_ffi.c`), 19 results

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && sed -n '1342,1705p' audio_manual/strace_tinyplay_open_20260318.txt | grep -E 'PLUGIN: mixer|backend_conf.xml|Instance key is added|BINDER_WRITE_READ' | head -n 80

我把最小探针再推进一层：先只做 `mixer_open(100)`，然后原样 `pcm_open(100,100)`。这正对应 `tinyplay_ftm` 在 `pcm_open` 前已经出现的 `agm_mixer_plugin_open`。

Generating patch (131 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
我直接跑双阶段最小探针，确认 `mixer_open(100)` 是否就是 `tinyplay_ftm` 和我们之间那道关键分水岭。

Ran terminal command:  cd /Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player && ./build_agm_demo.sh

Ran terminal command:  adb -s 70a91f89 push agm_audio_demo /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell 'logcat -c && /data/local/tmp/agm_audio_demo --probe-minimal-agm-pcm >/data/local/tmp/agm_probe_minimal.out 2>&1; echo EXIT:$?; cat /data/local/tmp/agm_probe_minimal.out'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -E "VideoPlayer|PLUGIN: mixer|pcm_plug_open|PLUGIN: pcm|AgmIpc::|aw882xx_start_pa|graph_open|graph_start" | tail -n 260'

有一个新的硬线索了：`tinyplay_ftm` 在成功路径里反复读 `/proc/self/cmdline`，而我们的进程名完全不同。下一步我直接做最便宜的验证，看看“进程名像不像 `tinyplay_ftm`”会不会影响 plugin 初始化。

Ran terminal command:  adb -s 70a91f89 push agm_audio_demo /data/local/tmp/tinyplay_ftm && adb -s 70a91f89 shell chmod 755 /data/local/tmp/tinyplay_ftm && adb -s 70a91f89 shell 'logcat -c && /data/local/tmp/tinyplay_ftm --probe-minimal-agm-pcm >/data/local/tmp/agm_probe_cmdline.out 2>&1; echo EXIT:$?; cat /data/local/tmp/agm_probe_cmdline.out'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -E "VideoPlayer|PLUGIN: mixer|pcm_plug_open|PLUGIN: pcm|AgmIpc::|graph_open|graph_start|aw882xx_start_pa|tinyplay_ftm" | tail -n 280'

现在还有一条更强的工程性怀疑：不是 AGM 参数错，而是我们这边调用的 tinyalsa/plugin ABI 本身和 vendor 进程不一致。我要先核对 demo 到底链接了哪套 `libtinyalsa`。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/build_agm_demo.sh)

Searched for regex `dlopen\("libtinyalsa|libtinyalsa.so|mixer_open|pcm_open` (`**/video_player_ffi.c`), 23 results

Ran terminal command:  otool -L agm_audio_demo | head -n 80

下一层我用 `strace` 对我们自己的最小探针做同样的切片。不是为了看报错字符串，而是为了比对它到底有没有走到 `backend_conf.xml` 和后续 binder 循环。

Ran terminal command:  adb -s 70a91f89 shell 'rm -f /data/local/tmp/strace_demo_minimal.txt; strace -f -o /data/local/tmp/strace_demo_minimal.txt /data/local/tmp/agm_audio_demo --probe-minimal-agm-pcm >/dev/null 2>&1; tail -n 240 /data/local/tmp/strace_demo_minimal.txt'

Ran terminal command:  adb -s 70a91f89 pull /data/local/tmp/strace_demo_minimal.txt /Volumes/Case-sensitive\ APFS/TWRP/audio_manual/strace_demo_minimal_20260318.txt

`strace` 已经拉回来了。我先对比三个信号点：`agm_mixer_plugin_open`、`backend_conf.xml`、`agm_pcm_hw_params`。这三个能直接告诉我们失败卡在哪一级。

Searched for regex `agm_mixer_plugin_open|backend_conf.xml|device_config not found|Instance key is added|agm_pcm_hw_params|pcm_plug_open|BINDER_WRITE_READ` (`**/audio_manual/strace_demo_minimal_20260318.txt`), 28 results

Searched for regex `agm_mixer_plugin_open|backend_conf.xml|device_config not found|Instance key is added|agm_pcm_hw_params|pcm_plug_open|BINDER_WRITE_READ` (`**/audio_manual/strace_tinyplay_open_20260318.txt`), 200 results

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_9XMeyGrkRQ5VNUmFVmuXXGyN__vscode-1773775025790/content.txt)

我现在做一个很有判别力的实验：把官方 `tinyplay_ftm` 拷到 `/data/local/tmp` 再跑。如果它一搬家就失败，问题就不在我们代码，而在执行上下文。

Ran terminal command:  adb -s 70a91f89 shell 'cp /odm/bin/tinyplay_ftm /data/local/tmp/tinyplay_ftm_copy && chmod 755 /data/local/tmp/tinyplay_ftm_copy && logcat -c && /data/local/tmp/tinyplay_ftm_copy /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY >/data/local/tmp/tinyplay_ftm_copy.out 2>&1; echo EXIT:$?; tail -n 220 /data/local/tmp/tinyplay_ftm_copy.out'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -E "tinyplay_ftm|graph_open|graph_start|pcm_plug_open|PLUGIN: mixer|PLUGIN: pcm|aw882xx_start_pa|AgmIpc::|avc:" | tail -n 320'

这次实验把一条大分支直接砍掉了：官方 `tinyplay_ftm` 拷到 `/data/local/tmp` 以后仍然成功，所以不是文件路径、exec 位置或 SELinux 转换在救它。接下来只剩“进程里做了什么不一样”。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_S3s3a6pDRXeHxE9k7cnSW64D__vscode-1773775025796/content.txt)

Ran terminal command:  adb -s 70a91f89 shell 'readelf -d /odm/bin/tinyplay_ftm | head -n 120'

Ran terminal command:  adb -s 70a91f89 shell 'readelf -d /data/local/tmp/agm_audio_demo | head -n 120'

现在已经能下结论了：`tinyplay_ftm` 成功路径不是“裸 `pcm_open` 自带魔法”，因为它在 `agm_pcm_hw_params` 之前已经自己算出了 `stream_kv/device_kv/instance_kv`。我接下来直接看它导入了哪些接口，确认它在用户态还做了哪层准备。

Ran terminal command:  adb -s 70a91f89 shell 'readelf -Ws /odm/bin/tinyplay_ftm | grep -E "UND|mixer_|pcm_|str_parms|audio_|expat|XML_|property_|dlopen|agm|card" | head -n 220'

Ran terminal command:  adb -s 70a91f89 shell 'strings /odm/bin/tinyplay_ftm | grep -E "device_config not found|Backend .* rate ch bit|stream_kv:|Instance key is added|card-defs.xml|backend_conf.xml|usecaseKvManager|session_mode|agm_|mixer_|pcm_" | head -n 260'

这下路径清楚了：`tinyplay_ftm` 根本不是靠 `libagmmixer`/`libagmclient` helper 成功的，它自己只用 `tinyalsa + expat + mixer_ctl_set_array/enum`，解析 `backend_conf.xml` 后把状态写进去，再 `pcm_open`。这正是我们该复刻的那条纯 C 路。

Searched for regex `set_agm_group_device_config|Backend %s rate ch bit|device_config not found|Instance key is added|mixer_ctl_set_array|backend_conf.xml` (`**/*.{md,txt,c,cpp,h,xml}`), 77 results

Read memory twrp_audio_qualcomm_tinyalsa_doc_mapping.md

Read memory twrp_audio_pcm100_setparamtag.md

我先不盲写大段 XML 解析。先把文档里已有的 `tinyplay_ftm` 控件写法证据翻出来，确认要复刻的是哪几条 mixer control。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3600-3600), lines 3600 to 3645

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#250-250), lines 250 to 330

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3138-3138), lines 3138 to 3188

我先把 `tinyplay_ftm` 直接写的控件名抠出来。如果它确实在写 `PCM100 metadata / setParamTag / <intf> rate ch fmt` 这类名字，我们就可以开始复刻同一路径。

Searched for regex `set_agm_group_device_config|group_device_config|PCM100 metadata|rate ch fmt|setParamTag|getTaggedInfo` (`**/docs/TWRP音频手动Bring-up.md`), 55 results

Ran terminal command:  adb -s 70a91f89 shell 'strings /odm/bin/tinyplay_ftm | grep -E "rate ch fmt|metadata|setParamTag|getTaggedInfo|connect|disconnect|PCM100|TDM-LPAIF|VIRT-|control" | head -n 260'

我先把这轮硬结论写进文档和 repo memory。现在前沿已经明显换了，继续沿旧 helper 线会浪费时间。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3968-3968), lines 3968 to 3998

Read memory twrp_audio_qualcomm_tinyalsa_doc_mapping.md

Read memory /memories/repo/

Generating patch (122 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```


Inserted into memory file twrp_audio_qualcomm_tinyalsa_doc_mapping.md

本轮已经把前沿继续收紧了，而且方向发生了实质变化。

关键结论

1. plugin-first 不是根因
我先把独立 demo 的 AGM 打开顺序改成了先 plugin、后 direct PCM，再实跑验证。
结果没有改善：
AGM plugin open 仍然先失败
card100/device100 仍然打不开
PCM100 metadata / setParam / setParamTag 仍然全零
MIID 仍然拿不到

这说明问题不在“先后顺序”。

2. 裸 pcm_open(card100, device100) 也不行
我新增了一个最小 AGM 探针，分两种方式跑：
完全不走现有 helper，只直接 pcm_open(card100, device100, 48k/2ch/16bit)
先 mixer_open(100)，再同样 pcm_open

两种都失败：
不先 mixer_open 时，plugin 直接 Unknown error -32
先 mixer_open(100) 时，agm_mixer_plugin_open 先返回 -12，随后 pcm_open 仍是 -32

这一步很重要，因为它排除了“是我们现有 helper 把图写坏了”这一条怀疑。

3. tinyplay_ftm 成功不靠执行位置
我把官方 tinyplay_ftm 直接拷到 /data/local/tmp 再跑，仍然成功进入：
device_config not found
Backend ... 48000, 8, 32
Instance key is added
graph_open ret 0
agm_pcm_hw_params
graph_start ret 0

所以关键差异不在 /odm/bin 路径、不在“原始二进制位置”、也不在这个级别的执行上下文。

4. 真正的差异已经找到了
我继续看了 tinyplay_ftm 的依赖和导入符号，结论很明确：

它不是靠 libagmmixer / libagmclient 这套高层 helper 直接成功的。
它自己的用户态路径是：
tinyalsa
expat
mixer_ctl_set_array / mixer_ctl_set_enum_by_string / mixer_ctl_get_array
property_get / property_set
解析 backend_conf.xml
算出 stream_kv / device_kv / instance_kv / devicepp_kv
然后再进入 pcm_open(card100, device100)

也就是说，tinyplay_ftm 成功不是“裸 pcm_open 自带 AGM 魔法”，而是它在 pcm_open 之前，自己已经把 AGM 所需的 mixer/config 状态补好了。

这轮我实际做了什么

1. 保留并验证了 plugin-first 的独立 demo 路径
2. 新增了零 helper 的最小 AGM PCM 探针
3. 对这个最小探针做了 strace，对比 tinyplay_ftm 成功路径
4. 验证 tinyplay_ftm 拷到 /data/local/tmp 后仍然成功
5. 反查 tinyplay_ftm 的 readelf 和 strings，确认它依赖的是 tinyalsa + XML + mixer_ctl 这条用户态准备链
6. 已把这轮结论同步写进文档和 repo memory

当前主线已经调整

后续不应该再把时间主要花在：
继续盲猜 agm_session_open ABI
继续排列组合 streamdevice metadata 次数
继续试 plugin-first / direct-first 的顺序变化

下一步最值得做的是：
1. 直接复刻 tinyplay_ftm 的用户态准备链
2. 先实现 backend_conf.xml 解析
3. 再实现对应的 mixer_ctl_set_array / set_enum 写入
4. 最后再接 pcm_open(card100, device100)

如果你不改方向，我下一轮就直接开始写这条 tinyplay_ftm 风格的纯 C 路径，而不是继续在 agmmixer helper 上兜圈。

Made changes.

User: 记录文档，然后继续

GitHub Copilot: 文档我已经补到最新结论，接下来直接推进到 `tinyplay_ftm` 风格的用户态准备链，目标是先把它在 `pcm_open` 前做的 XML 和 mixer 控件动作抠出来。

Updated todo list

我先抓 `tinyplay_ftm` 在 `pcm_open` 之前真正碰过哪些配置和控件，产出应该是一份可直接照着写纯 C 版的最小动作清单。

Searched for files matching `**/card-defs.xml`, 2 matches

Ran terminal command:  adb -s 70a91f89 shell 'strings /odm/bin/tinyplay_ftm | grep -E "set_agm_group_device_config|device_kv|stream_kv|instance_kv|devicepp_kv|metadata|setParamTag|connect|disconnect|rate ch fmt|control|VIRT-|backend_conf.xml" | head -n 400'

Ran terminal command:  adb -s 70a91f89 shell 'readelf -Ws /odm/bin/tinyplay_ftm | grep -E "XML_|mixer_|pcm_|property_|calloc|realloc|strdup|fopen|fread|strcmp|strstr|atoi" | head -n 260'

第一轮信息已经够用了：`tinyplay_ftm` 明确是 `XML + mixer_ctl_* + pcm_open` 的路线，不是 `libagmclient` 直控。我现在补齐它实际读的配置文件和 card-defs.xml 内容，下一步就能写最小复刻。

Searched for files matching `**/backend_conf.xml`, no matches

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/extracted_20260318_034751/vendor/vendor/etc/card-defs.xml#1-1), lines 1 to 260

Ran terminal command:  adb -s 70a91f89 shell 'cat /odm/etc/backend_conf.xml | sed -n "1,220p"'

Ran terminal command:  adb -s 70a91f89 shell 'cat /vendor/etc/card-defs.xml | sed -n "1,260p"'

配置输入已经确认了：`backend_conf.xml` 只给出 backend 的 48k/8ch/32bit，card-defs.xml 说明 `PCM100` 的 `session_mode` 就是 0。下一步我直接复用现有 tinyalsa helper，做一条“只写 `tinyplay_ftm` 明面上需要的控件”的最小原生路径。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#980-980), lines 980 to 1155

Searched for regex `prime_agm_named_backend_controls|force_agm_named_backend_connect|probe_agm_rate_ch_fmt_direct_write|mixer_ctl_set_enum_by_string|mixer_ctl_set_array` (`**/video_player_ffi.c`), 21 results

Ran terminal command:  adb -s 70a91f89 shell 'tinymix -D 100 | grep -E "PCM100|TDM-LPAIF-RX-SECONDARY|metadata|setParamTag|connect|disconnect|control|rate ch fmt" | head -n 260'

Ran terminal command:  adb -s 70a91f89 shell 'tinymix -D 100 "PCM100 control" ; tinymix -D 100 "TDM-LPAIF-RX-SECONDARY rate ch fmt"'
Completed with input:  adb -s 70a91f89 shell 'tinymix -D 100 "PCM100 control" ; tinymix -D 100 "TDM-LPAIF-RX-SECONDARY rate ch fmt"'

设备里没有现成 `tinymix` 可用，所以我直接复用现有 tinyalsa 写控件 helper。现在要看的就是：我们手头这些 helper 能不能拼出一条比 `agmmixer` 更接近 `tinyplay_ftm` 的最小 direct-control 路径。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1368-1368), lines 1368 to 1498

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1498-1498), lines 1498 to 1565

Ran terminal command:  adb -s 70a91f89 shell 'strings /data/local/tmp/tinyplay_ftm_copy | grep -E "Failed to set device metadata|Failed to set pcm metadata|set_agm_group_device_config|device_config not found|Instance key is added"'

我开始把 direct-control 探针写进 demo，先只试 `tinyplay_ftm` 明面上那几步：`PCM100 control`、`<intf> rate ch fmt`、`PCM100 metadata/setParamTag/setParam`，然后再 `pcm_open`。这样能最快验证“自己写 mixer_ctl_*”这条路值不值得继续。

Searched for regex `#define AGM_STREAM_KV|#define AGM_DEVICE_KV|#define AGM_DEVICE_PP_KV|#define AGM_INSTANCE_KV|#define AGM_PRIMARY_INTF|#define AGM_PCM_CARD|#define AGM_PCM_DEVICE|#define AGM_` (`**/video_player_ffi.c`), 15 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#240-240), lines 240 to 320

我把现成常量和控件 helper 对上了，接下来直接做一个新探针，不再走 `agmmixer`，而是用这些原始 tinyalsa 写操作去逼近 `tinyplay_ftm`。

Searched for regex `force_agm_pcm100_connect\(|PCM100 connect|PCM100 disconnect` (`**/video_player_ffi.c`), 5 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1240-1240), lines 1240 to 1375

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1670-1670), lines 1670 to 1748

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1748-1748), lines 1748 to 1788

我现在把 direct-control 探针加进 demo，并且按阶梯方式试 4 个变体。这样很快就能看出，是哪一步第一次让 `pcm_open(card100,device100)` 往前动。

Generating patch (181 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.h), [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/audio_demo_main.c), [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```

```

```

```

```
探针已经加进去了。现在直接上机，看哪一个 direct-control 变体第一次改变 `pcm_open` 的失败层级，或者让控件出现非零状态。

Ran terminal command:  ./build_agm_demo.sh

Ran terminal command:  adb -s 70a91f89 push agm_audio_demo /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell 'logcat -c && /data/local/tmp/agm_audio_demo --probe-direct-controls >/data/local/tmp/agm_probe_direct.out 2>&1; echo EXIT:$?; tail -n 260 /data/local/tmp/agm_probe_direct.out'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -E "VideoPlayer|PLUGIN: mixer|pcm_plug_open|PLUGIN: pcm|graph_open|graph_start|AgmIpc::|aw882xx_start_pa|serviceDied" | tail -n 320'

这次 probe 已经给出新信号了：我们第一次拿到了 plugin 内部更细的报错，不再只是外层 `pcm_open -32`。我先把运行输出读全，然后据此决定下一步是修 payload 形状，还是先补缺失的 precondition。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_EiohdgHmKQq67S9wdSIzqZnw__vscode-1773775025839/content.txt)

Ran terminal command:  adb -s 70a91f89 shell 'strings /vendor/lib64/libagm_mixer_plugin.so | grep -E "amp_be_media_fmt_put|amp_pcm_metadata_put|amp_pcm_set_param_put|amp_pcm_aif_connect_put|set_media_config|set_aif_ses_metadata|set_params|connect failed" | head -n 200'

这一轮最有价值的新发现不是“还没成功”，而是 plugin 已经把我们喂进去的参数拆出来报错了。现在我去对照文档里已有的反汇编结论，核对 `rate ch fmt` 这 4 个槽位的真实顺序。

Searched for regex `rate ch bit fmt|rate ch fmt|set_media_config failed|channels 32 fmt 0|data_fmt|slot_mask|0x50|0x54|0x58|0x5c` (`**/docs/TWRP音频手动Bring-up.md`), 36 results

Read memory twrp_audio_helper_timing_delta_20260317.md

Read memory twrp_audio_agmmixer_helper_semantics.md

这次日志把 precondition 又压了一层：我们直接写 `rate ch fmt / metadata / connect` 时，plugin 统一回 `-32`，而且这次没有 `SessionInfo created for session 100`。我先补一个更针对性的实验：在 direct-control 之前先做一次 `agm_session_aif_connect(100,16,1)`，看这些控件是不是立刻变得可写。

Searched for regex `connect_agm_session_aif\(|agm_session_aif_connect rc|SessionInfo created for session` (`**/video_player_ffi.c`), 8 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1980-1980), lines 1980 to 2238

我准备把 `agm_session_aif_connect` 作为 direct-control 的前置条件加进去做对照，因为这次日志最像“控件写得对不对先不谈，session 根本还没建立”。

Generating patch (59 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
这个改动只测一个问题：先建 session，会不会让 `rate ch fmt / metadata / connect` 从统一 `-32` 变成可写。结果会直接告诉我们下一步该追 session 还是 payload。

Ran terminal command:  ./build_agm_demo.sh

Ran terminal command:  adb -s 70a91f89 push agm_audio_demo /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell 'logcat -c && /data/local/tmp/agm_audio_demo --probe-direct-controls >/data/local/tmp/agm_probe_direct2.out 2>&1; echo EXIT:$?; tail -n 320 /data/local/tmp/agm_probe_direct2.out'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -E "VideoPlayer|SessionInfo created|agm_session_aif_connect|PLUGIN: mixer|amp_be_media_fmt_put|amp_pcm_metadata_put|amp_pcm_set_param_put|amp_pcm_aif_connect_put|pcm_plug_open|PLUGIN: pcm|graph_open|graph_start" | tail -n 360'

session 对照已经跑完。我要先把完整输出里和 `session_connect` 相关的部分读出来，确认它到底有没有真正创建 `SessionInfo`，还是连这一步都没成立。

Searched for regex `session_connect rc|session_disconnect rc|agm_session_aif_connect rc|SessionInfo created|control-rate-payload-connect|session-control-plus-rate|session-control-rate-payload-connect` (`**/call_H1SwyhvfRaCGIqXa3HOrYcNr__vscode-1773775025850/content.txt`), no results

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_H1SwyhvfRaCGIqXa3HOrYcNr__vscode-1773775025850/content.txt#180-180), lines 180 to 276

我现在把怀疑点收成一个更具体的问题：`rate ch fmt` 这条控件很可能根本不吃 `bits`，而是吃 ALSA `format` 枚举。先做这个对照，比继续猜 raw payload 更值。

Searched for regex `pcm_format_to_alsa_format\(|SNDRV_PCM_FORMAT_|PCM_FORMAT_S32_LE|PCM_FORMAT_S16_LE` (`**/video_player_ffi.c`), 17 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#2240-2240), lines 2240 to 2315

当前代码里已经有 bits 到 ALSA format 枚举的转换函数，所以这个对照几乎零成本。我直接把 `rate ch fmt` 增加一组“写 ALSA format 而不是 raw bits”的变体。

Generating patch (46 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
我先跑这个 format 对照，不改更多变量。只要看到 `set_media_config failed` 里的字段变化，就能判断第三个槽位是不是确实被我们喂错了。

Ran terminal command:  ./build_agm_demo.sh

Ran terminal command:  adb -s 70a91f89 push agm_audio_demo /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell 'logcat -c && /data/local/tmp/agm_audio_demo --probe-direct-controls >/data/local/tmp/agm_probe_direct3.out 2>&1; echo EXIT:$?; tail -n 360 /data/local/tmp/agm_probe_direct3.out'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -E "VideoPlayer|control-plus-rate-alsa-format|session-control-plus-rate-alsa-format|amp_be_media_fmt_put|pcm_plug_open|PLUGIN: pcm|agm_session_aif_connect rc" | tail -n 320'

我已经从错误字段里反推出一个更像真实结构的候选：`rate ch fmt` 这条控件实际很可能吃的是 `[rate, bits, channels, fmt]`。我直接把这个顺序加成新对照。

Generating patch (84 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
这次只看一个现象：如果顺序改成 `[rate,bits,channels,fmt]`，plugin 报错里的 `channels` 应该从 `32` 变成 `8`。只要变了，就说明槽位顺序基本被我们摸到了。

Ran terminal command:  ./build_agm_demo.sh

Ran terminal command:  adb -s 70a91f89 push agm_audio_demo /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell 'logcat -c && /data/local/tmp/agm_audio_demo --probe-direct-controls >/data/local/tmp/agm_probe_direct4.out 2>&1; echo EXIT:$?; tail -n 420 /data/local/tmp/agm_probe_direct4.out'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -E "control-plus-rate-bits-ch|session-control-plus-rate-bits-ch|amp_be_media_fmt_put|pcm_plug_open|agm_session_aif_connect rc|VideoPlayer" | tail -n 360'

字段顺序这次已经被我们钉出一半了：把数组改成 `[rate,bits,channels,fmt]` 后，plugin 的 `channels` 确实从 `32` 变成了 `8`。这说明 `rate ch fmt` 名字是误导，真实布局更像 `rate bit ch fmt`。我继续往前追它为什么还停在 `-32`。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#4030-4030), lines 4030 to 4111

Ran terminal command:  adb -s 70a91f89 shell 'cat /odm/etc/usecaseKvManager.xml | sed -n "1,260p"'

Ran terminal command:  adb -s 70a91f89 shell 'grep -n -E "A100000E|A2000001|AC000002|TDM-LPAIF-RX-SECONDARY|PCM_LL|speaker|instance" /odm/etc/usecaseKvManager.xml | head -n 160'

`usecaseKvManager.xml` 里相关 KV 组合已经对上了，说明我们用的 `stream_kv/device_kv/devicepp_kv` 并没有跑偏。现在剩下的主疑点只剩两个：`rate ch fmt` 的真实字段顺序，以及这些控件的调用时机。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_jA9QD7axZXxqoA1E2Pkj0Bx7__vscode-1773775025864/content.txt#262-262), lines 262 to 262

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_ZFB2NKeMV38hSOlwKCLxdA4U__vscode-1773775025862/content.txt#120-120), lines 120 to 300

我把实机结论先固定下来：`[rate,bits,channels,fmt]` 这个顺序已经比之前更接近真实布局，但它仍然不够让控件可写。下一步我转去静态看 `tinyplay_ftm` 本体，确认这些控件到底是在 `pcm_open` 前还是 `pcm_open/hw_params` 里被写的。

Ran terminal command:  adb -s 70a91f89 pull /odm/bin/tinyplay_ftm /Volumes/Case-sensitive\ APFS/TWRP/audio_manual/tinyplay_ftm_bin_20260318

Ran terminal command:  command -v llvm-objdump || command -v objdump || command -v gobjdump

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && strings -t x audio_manual/tinyplay_ftm_bin_20260318 | grep -E "set_agm_group_device_config|device_config not found|Instance key is added|Failed to set device metadata|Failed to set pcm metadata|Playing sample"

二进制已经拉回来了，而且本机有 `llvm-objdump`。我现在直接用字符串偏移做锚点反汇编，目标不是全量逆向，而是确认“解析 XML / 写 mixer_ctl / pcm_open”这几步的先后顺序。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && /Users/Laurie/.swiftly/bin/llvm-objdump -d audio_manual/tinyplay_ftm_bin_20260318 | grep -nE "19c0|1a42|1aa7|1390|1886|1443" | head -n 80

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && readelf -S audio_manual/tinyplay_ftm_bin_20260318 | head -n 80

地址交叉引用这条路不够经济，我换个更稳的切法：直接围绕 `XML_ParserCreate@plt`、`mixer_ctl_set_array@plt`、`pcm_open@plt` 这些导入点看调用分布。只要顺序清楚，就知道后面该补哪段。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && /Users/Laurie/.swiftly/bin/llvm-objdump -d audio_manual/tinyplay_ftm_bin_20260318 | grep -n "<XML_ParserCreate@plt>\|<mixer_ctl_set_array@plt>\|<mixer_ctl_set_enum_by_string@plt>\|<pcm_open@plt>\|<mixer_open@plt>" | head -n 120

Ran terminal command:  command -v llvm-readelf || command -v readelf
Completed with input:  command -v llvm-readelf || command -v readelf

现在已经拿到骨架了：`mixer_open`、`pcm_open`、XML 解析、`mixer_ctl_set_array`/`set_enum` 都在主程序里。下一步只看这些调用点附近的几十行，足够判断调用顺序。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && /Users/Laurie/.swiftly/bin/llvm-objdump -d audio_manual/tinyplay_ftm_bin_20260318 | sed -n '460,530p'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && /Users/Laurie/.swiftly/bin/llvm-objdump -d audio_manual/tinyplay_ftm_bin_20260318 | sed -n '780,840p'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && /Users/Laurie/.swiftly/bin/llvm-objdump -d audio_manual/tinyplay_ftm_bin_20260318 | sed -n '1410,2010p'

反汇编已经给出一个关键骨架：`mixer_open` 明显早于 `pcm_open`，而 `pcm_open` 前还有至少两段本地函数在跑。这已经比之前“只靠 strace 猜”更实了。我把 XML/mixer 这一块读出来，看看控件写入到底发生在 `pcm_open` 前还是后。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_Khnj6c89g7EMBT6QqoMvAb32__vscode-1773775025878/content.txt#1-1), lines 1 to 220

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_Khnj6c89g7EMBT6QqoMvAb32__vscode-1773775025878/content.txt#220-220), lines 220 to 420

反汇编已经给出硬信息了：`tinyplay_ftm` 写 `rate ch fmt` 时不是 4 个值，而是 5 个值，并且会先把 bit width 映射成 format 枚举再下发。我直接补一个 5-int 正确形态的对照。

Generating patch (48 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
Compacted conversation

Made changes.

User: 每次记录文档啊，怎么又不记，继续

GitHub Copilot: 这次我先补齐文档缺口，再接着推进 `tinyplay_ftm` 的用户态链，结果应该是把刚才那串新发现写死，避免再次丢状态。

Read changed files in [](file:///Volumes/Case-sensitive%20APFS/TWRP)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#4030-4030), lines 4030 to 4111

Got last terminal command

文档停在上一个阶段，后面那串 `rate ch fmt` / 5-int / 调用顺序的新结论还没落盘。我先把这些增量事实补齐，再继续写代码。

Searched for regex `5-int|rate ch fmt|set_media_config failed|SessionInfo created|probe direct|direct-control|format 对照|rate,bits,channels,fmt|5 values` (`**/video_player_ffi.c`), 17 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#900-900), lines 900 to 1260

我先把 direct-control 探针的现状和 `tinyplay_ftm` 反汇编里已经抠出来的骨架对齐，结果要么是补文档，要么直接进下一轮 payload 修正。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#3140-3140), lines 3140 to 3355

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && /Users/Laurie/.swiftly/bin/llvm-objdump -d audio_manual/tinyplay_ftm_bin_20260318 | sed -n '1410,2010p' | rg -n "mixer_ctl_set_array|mixer_ctl_set_enum_by_string|pcm_open|XML_|Backend|Instance key|rate ch fmt|set device media|set pcm metadata|connect pcm"

Ran terminal command:  adb -s 70a91f89 shell 'strings /data/local/tmp/agm_audio_demo | grep -E "debug probe direct controls|rate-bits-ch|five-int|session_connect|alsa format|5 values|rate ch fmt" | head -n 120'

增量已经对上了：当前代码里确实有 direct-control 多变体和 5-int 写法，而反汇编也已经坐实了 `tinyplay_ftm` 的骨架是 `XML -> mixer_ctl_set_array -> mixer_ctl_set_enum_by_string`。我现在先把这部分写进文档，然后继续把 5-int 形态往实机上收敛。

Searched for regex `probe direct controls|vp_debug_probe_direct|direct controls` (`**/audio_demo_main.c|**/video_player_ffi.h|**/video_player_ffi.c`), no results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/audio_demo_main.c)

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.h)

我先把 direct-control 阶段的已验证结论落文档，然后马上重跑当前探针，看看 5-int 版本现在把失败层级推进到哪一步。

Ran terminal command:  cd /Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player && ./build_agm_demo.sh && adb -s 70a91f89 push agm_audio_demo /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell 'logcat -c && /data/local/tmp/agm_audio_demo --probe-direct-controls >/data/local/tmp/agm_probe_direct.out 2>&1; echo EXIT:$?; tail -n 260 /data/local/tmp/agm_probe_direct.out'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -E "VideoPlayer|set device media|set pcm metadata|device_config not found|Instance key is added|SessionInfo created|pcm_plug_open|PLUGIN: pcm|PLUGIN: mixer|graph_open|graph_start|AgmIpc::|rate ch fmt" | tail -n 360'

实机结果已经出来了。我先读回运行输出和 logcat，再把这轮新证据一并补进文档。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_ixvRTk4PwXj3SZk4PNJkqswj__vscode-1773775025894/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_5F1Ija3y6h1kMXiIQJKwpNT1__vscode-1773775025895/content.txt)

这轮 direct-control 的新证据已经足够改变判断：不是 payload 顺序先错，而是当前路径压根没创建 session。先记文档，再去抠 `tinyplay_ftm` 在 `mixer_ctl_set_array` 前到底准备了什么。

Generating patch (108 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```


Inserted into memory file twrp_audio_qualcomm_tinyalsa_doc_mapping.md

文档已补上这轮结论。下一步我直接追 `tinyplay_ftm` 在第一次 `mixer_ctl_set_array` 前的本地准备函数，并把配置输入一起对上。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/extracted_20260318_034751/vendor/vendor/etc/card-defs.xml#1-1), lines 1 to 260

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && /Users/Laurie/.swiftly/bin/llvm-objdump -d audio_manual/tinyplay_ftm_bin_20260318 | sed -n '5480,5885p'

配置文件路径和我刚才假设的不一致，得先把抽取树里的真实位置对上；同时 `objdump` 直接按行切不稳，我改成先落文本再搜符号窗口。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/extracted_20260318_034751)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/extracted_20260318_034751/odm)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/extracted_20260318_034751/vendor)

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && /Users/Laurie/.swiftly/bin/llvm-objdump -d audio_manual/tinyplay_ftm_bin_20260318 > audio_manual/tinyplay_ftm_objdump_20260318.txt && rg -n "XML_ParserCreate@plt|mixer_ctl_set_array@plt|mixer_ctl_set_enum_by_string@plt|pcm_open@plt" audio_manual/tinyplay_ftm_objdump_20260318.txt

现在锚点有了：`pcm_open` 在更早的位置，`XML_ParserCreate` 后面一路到第一次 `mixer_ctl_set_array` 是我们要抠的窗口。我先读这个窗口，并把实际配置文件位置找正。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/extracted_20260318_034751/vendor/config)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/extracted_20260318_034751/vendor/vendor/etc)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#1410-1410), lines 1410 to 1775

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#1776-1776), lines 1776 to 2005

反汇编已经给出两个很值钱的点：`mixer_ctl_set_array` 的第一处确实是 5 个值，而且 bit depth 会先被映射成 format 枚举；另外还有一组单独的 enum 写函数。现在我把实际 XML 输入补上，准备开始照着这两类调用复刻。

Searched for files matching `**/backend_conf.xml`, no matches

Searched for files matching `**/usecaseKvManager.xml`, 2 matches

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/extracted_20260318_034751/vendor/vendor/etc/usecaseKvManager.xml#1-1), lines 1 to 260

Ran terminal command:  adb -s 70a91f89 shell 'cat /odm/etc/backend_conf.xml; echo __SEP__; cat /odm/etc/usecaseKvManager.xml | head -n 220'

设备侧 XML 已经拿到了，我先把 `backend_conf` 和 `usecaseKvManager` 里对 speaker 这条路的实际输入摘出来，再继续对照反汇编里的 5-int 写法。

Searched for regex `A100000E|A2000001|AC000002|AB000000|PAL_STREAM_LOW_LATENCY|TDM-LPAIF-RX-SECONDARY` (`**/extracted_20260318_034751/vendor/vendor/etc/usecaseKvManager.xml`), 120 results

Searched for regex `TDM-LPAIF-RX-SECONDARY|48000|8|32` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), 80 results

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_3Za0Lwr6Fog27jpyjj37KZlU__vscode-1773775025915/content.txt)

现在常量侧已经对齐了，缺的明显不是 `0xA100000E / 0xA2000001 / 0xAC000002` 这些值本身。我再往前抠一层，把 `tinyplay_ftm` 里这几个本地函数到底在构造什么控件名、什么 payload 形态读出来。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#1960-1960), lines 1960 to 2310

Ran terminal command:  adb -s 70a91f89 shell 'strings /odm/bin/tinyplay_ftm | grep -n -E "set_agm_group_device_config|Failed to set device metadata|Failed to set pcm metadata|Failed to connect pcm to audio interface|rate ch fmt|metadata|setParamTag|setParam|connect|VIRT-|PCM100|TDM-LPAIF" | head -n 200'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && rg -n "0x5b24|0x5d68|0x5eb8|0x6258|0x6364|0x6598|0x6834|0x69e4|set_media_config failed|set_aif_ses_metadata failed|set_params failed|connect failed" audio_manual/tinyplay_ftm_objdump_20260318.txt
Completed with input:  cd /Volumes/Case-sensitive\ APFS/TWRP && rg -n "0x5b24|0x5d68|0x5eb8|0x6258|0x6364|0x6598|0x6834|0x69e4|set_media_config failed|set_aif_ses_metadata failed|set_params failed|connect failed" audio_manual/tinyplay_ftm_objdump_20260318.txt

现在已经能看出几段本地 helper 的轮廓了。我再补一层调用关系，目标是找出 `tinyplay_ftm` 主流程里在 `pcm_open` 前到底按什么顺序调了这些 helper。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && rg -n "bl\s+0x5888|bl\s+0x5974|bl\s+0x5c40|bl\s+0x60f4|bl\s+0x62a0|bl\s+0x63d8|bl\s+0x5f28" audio_manual/tinyplay_ftm_objdump_20260318.txt

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#720-720), lines 720 to 950

Compacted conversation

Made changes.

User: 你怎么老是空转啊，让你补文档，文档没补禁止执行任何操作

GitHub Copilot: 先补文档，只做文档同步，不执行其他操作。

Generating patch (89 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```
文档已经补上，后续我会先记文档再继续。

这次补进去的是本轮已经实证的几条硬结论：

1. `plugin-first` 没有推进问题层级
2. “零 helper 最小 AGM 探针”也证明裸 `pcm_open(card100,device100)` 不通
3. `tinyplay_ftm` 复制到 `/data/local/tmp` 以后仍然成功，说明关键差异不在执行路径
4. 主线应正式转向复刻 `tinyplay_ftm` 的 `tinyalsa + expat + mixer_ctl_*` 用户态准备链

现在文档同步完成了。下一步我继续按这条主线往下抠 `tinyplay_ftm` 在 `pcm_open` 前的本地 helper 调用顺序，并把可直接复刻的控件写入步骤整理出来。

Made changes.

User: 继续

GitHub Copilot: 我先把 `tinyplay_ftm` 在 `pcm_open` 前那几段本地 helper 读成可执行顺序，结果应该能落成一份“先写哪些控件、再开 PCM”的最小动作表。

Searched for regex `<main>|XML_ParserCreate@plt|mixer_ctl_set_array@plt|mixer_ctl_set_enum_by_string@plt|pcm_open@plt|mixer_open@plt` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), 17 results

Searched for regex `bl\s+0x5888|bl\s+0x5974|bl\s+0x5c40|bl\s+0x60f4|bl\s+0x62a0|bl\s+0x63d8|bl\s+0x5f28` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), 6 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#1-1), lines 1 to 260

我已经拿到主流程里的关键 call 点了，下一步把这些 call 点前后的几十行读出来，结果应该能还原出 `mixer_open -> 本地 helper -> pcm_open` 的顺序。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#500-500), lines 500 to 880

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#1700-1700), lines 1700 to 2305

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/extracted_20260318_034751/vendor/vendor/etc/card-defs.xml#1-1), lines 1 to 240

主流程顺序已经出来了，而且第一批 helper 的职责也能分层了。下一步只补一个缺口：把真实 `usecaseKvManager.xml` 路径找正，再把这几段 helper 对应到具体控件名。

Searched for files matching `**/usecaseKvManager*.xml`, 4 matches

Searched for regex `Backend %s rate ch bit|stream_kv: %x device_kv\[%d\]: %x instance_kv: %x devicepp_kv\[%d\]: %x|Instance key is added|device_config not found` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), no results

Searched for regex `TDM-LPAIF-RX-SECONDARY|A100000E|A2000001|AC000002|stream_kv|device_kv|instance_kv|devicepp_kv` (`**/usecaseKvManager*.xml`), 92 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2260-2260), lines 2260 to 2710

新信息已经出来了，而且足够落一次文档：`tinyplay_ftm` 主流程里 `mixer_open` 确实先于 `pcm_open`，中间至少串了三类本地 helper，分别负责 `rate ch fmt`、enum 控件、以及大块 payload。下一步我先把这批 helper 角色写进文档，再继续把控件名和参数形态收成最小复刻表。

Generating patch (85 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```
文档已经补到这轮反汇编结论。现在我把 helper 和具体控件名一一对上，结果应该能产出一张“控件名 + 类型 + payload 长度”的最小复刻表。

Searched for text `0x5e1c|0x5f28|0x5974|0x60f4|0x63d8|0x6628|0x629c` (`**/docs/TWRP音频手动Bring-up.md`), 14 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#1540-1540), lines 1540 to 1765

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && strings audio_manual/tinyplay_ftm_bin_20260318 | grep -E '^metadata$|^setParamTag$|^getTaggedInfo$|^rate ch fmt$|^connect$|^disconnect$|^control$|^VIRT-$|^PCM[0-9]+|TDM-LPAIF-RX-SECONDARY|set_agm_group_device_config'

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/extracted_20260318_034751/vendor/vendor/etc/usecaseKvManager.xml#930-930), lines 930 to 1015

已经能看到最小复刻表的轮廓了：`0x60f4` 是 FE 的 `rate ch fmt`，`0x629c` 是 enum 控件，`0x6628`/`0x689c` 是两类大 payload。下一步我把 `0x689c` 和 `0x6a54` 也拆出来，补完“哪条控件吃哪种 payload 长度”这张表。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2710-2710), lines 2710 to 2925

Searched for text `0x6a54|0x689c` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), 2 results

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && strings audio_manual/tinyplay_ftm_bin_20260318 | grep -E 'Failed to set device metadata|Failed to set pcm metadata|Failed to connect pcm to audio interface|Failed to set device media config|MFC not present|graph_open|graph_start'

这轮 helper 语义又收紧了一层，已经能把错误字符串和大 payload helper 对上了。我先把这层 mapping 写进文档，后面就可以直接照着实现最小 direct-control 路径。

Generating patch (78 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```
文档已经补到最新 helper 语义。现在我回到代码里看现有 direct-control 探针到了哪一步，目标是避免重复造轮子，直接把缺的 `pcm metadata / device metadata` 两层补上。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c), [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.h), [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/audio_demo_main.c), 29 problems found

Searched for regex `direct-control|direct control|probe_direct|minimal agm pcm|set device metadata|set pcm metadata|rate ch fmt|getTaggedInfo` (`**/video_player_ffi.c`), 33 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#3000-3000), lines 3000 to 3360

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/audio_demo_main.c)

代码里 direct-control 探针已经在了，所以我不重写这层。我先看现有 tinyalsa helper 能不能直接构造 `pcm metadata / device metadata` 两类 payload，能的话就直接加新变体上机验证。

Searched for regex `set_mixer_int_words|set_mixer_.*array|mixer_ctl_set_array|find_mixer_ctl|force_agm_pcm100_enum_state|force_agm_pcm100_connect|prime_pcm100_payload_controls` (`**/video_player_ffi.c`), 23 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#980-980), lines 980 to 1175

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1176-1176), lines 1176 to 1465

Compacted conversation我已经确认底层 helper 够用了：现在既能写 enum，也能按控件类型写 int/byte array，还能按关键字模糊找控件。下一步直接补一个更贴近 `tinyplay_ftm` 的顺序，把 `metadata/setParamTag/getTaggedInfo` 这几层塞进现有 direct probe。Optimizing tool selection...

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1466-1466), lines 1466 to 1775

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#3160-3160), lines 3160 to 3338

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2100-2100), lines 2100 to 2345

现在已有 `prime_pcm100_payload_controls()` 只是在写一组很平的 4/8 word。和 objdump 对上后，真正缺的不是“有没有 payload”，而是 payload 的形状和写入顺序还太粗，所以我先把 `0x689c/0x6a54` 对应的那两段补成独立阶段。

Searched for text `689c:|6a54:|6628:|5f28:` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), 4 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2440-2440), lines 2440 to 2735

Searched for regex `struct DirectControlVariant|do_payload|rate_word_mode` (`**/video_player_ffi.c`), 9 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#3130-3130), lines 3130 to 3178

继续动代码前，我先把“已有 direct-control 探针，不重写、直接扩展”的结论补进 bring-up 文档，避免再偏离流程。然后只做最小代码改动并上机验证。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#1030-1030), lines 1030 to 1085

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2716-2716), lines 2716 to 2865

Searched for regex `AGM_DEVICE_CUSTOM_PAYLOAD_TAG|AGM_STREAM_KV_PCM_LL_PLAYBACK|AGM_DEVICE_KV_SPEAKER|AGM_DEVICEPP_KV_SPEAKER|AGM_INSTANCE_KV|#define AGM_` (`**/video_player_ffi.c`), 52 results

Searched for text `media config|device metadata|pcm metadata|set device metadata|set pcm metadata|getTaggedInfo|setParamTag` (`**/video_player_ffi.c`), 20 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#2028-2028), lines 2028 to 2185

为了避免再拍脑袋，我先读一下仓库记忆里已经整理过的 agmmixer/helper 语义，看看前面有没有把 `setParamTag` 或 `metadata` 的形状记下来。能复用就不重复逆向。

Read memory twrp_audio_agmmixer_helper_semantics.md

Read memory twrp_audio_pcm100_setparamtag.md

Read memory twrp_audio_helper_timing_delta_20260317.md

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2866-2866), lines 2866 to 3035

我这次改动会收得很窄：只给现有 direct probe 增加一类“split-KV 的 PCM100 metadata 变体”，不去碰主播放路径，也不重写旧 helper。这样能尽快验证 `PCM100 metadata` 之前是不是确实写错了形状。

Generating patch (20 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```


Generating patch (127 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
代码已经补完了，变动点只有一个新 helper 和三组新变体。现在直接编译 `agm_audio_demo`，确认这次改动至少不会把现有 harness 编坏，再上机跑 `--probe-direct-controls` 看 `PCM100 metadata` 有没有出现非零变化。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c), 28 problems found

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/build_agm_demo.sh)

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_agm_demo.sh

编译通过了，说明这次改动没有把现有 harness 打坏。现在直接把新二进制推到设备上跑 `--probe-direct-controls`，先看新增的 split-KV 变体有没有把 `PCM100 metadata` 从全零状态推开。

Ran terminal command:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/agm_audio_demo' /data/local/tmp/agm_audio_demo

Ran terminal command:  adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell /data/local/tmp/agm_audio_demo --probe-direct-controls
Completed with input:  adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell /data/local/tmp/agm_audio_demo --probe-direct-controls

设备输出比较长，我先只抓关键字：新增 phase、`split metadata rc`、`PCM100 array: PCM100 metadata`、`pcm_open` 的结果。这样能尽快判断这次是不是至少把 metadata 形状推进了一步。

Searched for regex `split metadata|control-rate-split-metadata|session-control-rate-split-metadata|PCM100 array: PCM100 metadata|打开成功|pcm_open|Unknown error -32|direct controls 成功` (`**//Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_KukfTg8wPvdIS01G6Uvw3spz__vscode-1773775025974/content.txt`), no results

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_KukfTg8wPvdIS01G6Uvw3spz__vscode-1773775025974/content.txt#1-1), lines 1 to 260

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_KukfTg8wPvdIS01G6Uvw3spz__vscode-1773775025974/content.txt#261-261), lines 261 to 520

这轮上机已经给出一个更硬的边界了：问题不只是 payload 形状不对，而是只要碰到 `rate ch fmt / metadata / connect` 这类真正下发 AGM 状态的写入，内核就直接回 `-32`。我先把这个新边界补进文档和仓库记忆，再决定下一步是不是要回头补 `<intf> metadata / stream metadata` 前置阶段。

Generating patch (38 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```


Inserted into memory file twrp_audio_helper_timing_delta_20260317.md

这轮已经做完并验证了，结论比之前更硬：

1. 我没有重写探针，而是在现有 direct-control 路径里新增了 split-KV 的 `PCM100 metadata` 变体。
2. 本地重新编译通过，并把新 `agm_audio_demo` 推到设备上跑了 `--probe-direct-controls`。
3. 新结果说明问题不只是 `PCM100 metadata` 的 payload 形状。

关键发现：

1. `PCM100 control=TDM-LPAIF-RX-SECONDARY` 依旧能返回 `rc=0`。
2. 但一旦进入真正会建立 graph 的写入阶段，下面这些操作全部直接返回 `-32`：
   - `<intf> rate ch fmt`
   - 旧的 raw `PCM100 metadata/setParamTag/setParam`
   - 新增的 split-KV `PCM100 metadata`
   - `PCM100 connect`
3. 新增 split-KV 变体的实际日志已经证明写入请求真的发出去了：
   - `PCM100 metadata rc=-32 payload=20`
   - `stream_tag=0xa1000000 stream_value=0xe route_tag=0xac000000 route_value=0x2`
4. 写完后再读回，`PCM100 metadata`、`PCM100 setParamTag`、`PCM100 setParam`、`<intf> metadata` 仍然全零。
5. `pcm_open(card100, device100)` 结果没有变化，还是 plugin open 后 `Unknown error -32`。

这意味着当前前沿进一步收敛为：

1. `PCM100 control` 能切过去，不代表后续 `rate/metadata/connect` 已经具备可写前置条件。
2. 阻塞点还在“控件写阶段”，比“payload 字段还原错了”更靠前。
3. 继续只在 `PCM100 metadata` 的字段布局里打转，价值已经下降。

我已经同步补了文档，也把这条新边界写进了仓库记忆。

下一步最自然的是二选一：

1. 继续扩 direct-control，优先补 `tinyplay_ftm` 在 `PCM100 metadata` 之前的 `<intf> metadata / stream metadata / getTaggedInfo` 前置阶段。
2. 先把 `tinyplay_ftm` 的 pre-PCM 控件顺序再压实成“控件名 + payload 长度 + 顺序”的表，再回填到 probe，避免继续试错。

Made changes.


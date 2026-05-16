# 第7章：Agmplay快照、Route排除、6a54修正与纯C最终出声
User: 继续

GitHub Copilot: 我把主线切到“谁真正建立 connect/media/metadata 前置状态”这件事上，先对齐现有记忆和二进制调用点，目标是确认应该继续抠 `agmplay/tinyplay_ftm` 还是别的库。

Read memory twrp_audio_agmplay_minimal_success.md

Read memory twrp_audio_agmmixer_helper_semantics.md

Ran terminal command:  strings -a -t x '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/agmplay' | rg 'set_agm_device_media_config|set_agm_audio_intf_metadata|set_agm_stream_metadata|set_agm_streamdevice_metadata|connect_agm_audio_intf_to_stream|agm_mixer_get_miid|configure_mfc|agm_session_aif_connect|agm_aif_set_media_config|agm_session_set_metadata|agm_session_aif_set_metadata'

现有证据更偏向 `agmplay` 主程序直接用 agmmixer helper 建前置状态，而不是交给 pcm plugin。下一步我去抓 `agmplay` 的 helper 调用顺序和参数落点，尤其是 `instance_kv << 16`、双 tag `get_miid`、以及有没有我们还没复刻的前置分支。

Ran terminal command:  llvm-objdump -d --no-show-raw-insn '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/agmplay' | rg -n 'set_agm_device_media_config@plt|set_agm_audio_intf_metadata@plt|set_agm_stream_metadata@plt|set_agm_streamdevice_metadata@plt|agm_mixer_get_miid@plt|connect_agm_audio_intf_to_stream@plt|configure_mfc@plt'

Ran terminal command:  llvm-objdump -d --no-show-raw-insn --start-address=0x6600 --stop-address=0x6b80 '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/agmplay'

主路径窗口已经拿到了，我现在只读关键片段，提炼每个 helper 的参数，不再做大范围反汇编噪音扫描。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_XQ6K8c4gtovEDpDnt2E5bprr__vscode-1773803651581/content.txt#45-45), lines 45 to 200

我还差主路径开头那一小段参数准备，尤其是第一次 `set_agm_stream_metadata` 前 `instance_kv` 和首个 `get_miid` 的构造；把这段补齐就能更精确地对照 probe。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_XQ6K8c4gtovEDpDnt2E5bprr__vscode-1773803651581/content.txt#1-1), lines 1 to 70

我转回代码里核对一下当前 probe 喂给 `set_agm_stream_metadata` 的参数，确认是不是已经和 `agmplay` 的 `instance_kv << 16` 对齐，还是还留着旧假设。

Searched for regex `set_agm_stream_metadata\(|instance_kv|raw_instance_kv|AGM_INSTANCE_KV` (`**/pure_c_agm_probe.c`), 17 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1587-1587), lines 1587 to 1675

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1880-1880), lines 1880 to 1985

我怀疑还有一个更具体的参数错位：`set_agm_audio_intf_metadata` 第四个参数在 `agmplay` 里不是硬编码 0，而是 `w26 & 3`。我去补前一段反汇编，确认这个值在 speaker playback 路上到底是什么。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_XQ6K8c4gtovEDpDnt2E5bprr__vscode-1773803651581/content.txt#1-1), lines 1 to 45

还需要往前再看几十条，确认 `w26` 的来源；如果它是 playback/capture 模式位，那我们现在 helper 里把它写死成 0 可能就是一个真实缺口。

Ran terminal command:  llvm-objdump -d --no-show-raw-insn --start-address=0x6500 --stop-address=0x6600 '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/agmplay'

这段已经够用了，`w26` 不是常量 0，它来自 `sbfx w26, w22, #0, #1`，也就是直接从某个模式字的 bit0 抽出来。我要把这条假设落到 probe 里，新增一个可切换的 `audio_intf_metadata dir` 试验，而不是继续把它写死。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#2248-2248), lines 2248 to 2298

我做一个最小可验证改动：不给默认行为拍脑袋改值，只新增一个 `audio_intf_metadata dir=1` 实验开关，把这个从 `agmplay` 抓出来的位差异变成可直接上机 A/B。

Using "Apply Patch"

补丁上下文没对上，我先把几个精确落点读出来，再一次性做最小修改，不在大块上下文里硬撞。

Searched for regex `static int prime_agm_helper_prep\(|static int probe_agm_session_open_close\(|static int run_probe\(` (`**/pure_c_agm_probe.c`), 4 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#200-200), lines 200 to 235

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#425-425), lines 425 to 438

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1925-1925), lines 1925 to 1948

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#2254-2254), lines 2254 to 2338

Searched for regex `prime_agm_helper_prep\(|return probe_agm_session_open_close\(|return run_probe\(` (`**/pure_c_agm_probe.c`), 6 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#2368-2368), lines 2368 to 2475

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#2475-2475), lines 2475 to 2478

我已经把精确落点都找齐了，现在做最小补丁：只新增一个 `--audio-intf-dir-1` A/B 开关，并把它贯通到 helper-prep 和 session-open helper-prep，两边都能直接复跑。

Using "Apply Patch"

我把补丁合并成单文件多段更新，再落一次。

Using "Apply Patch"

我分成几个小补丁来打，避免上下文匹配再错。

Generating patch (10 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
继续把函数签名和调用点逐个接上，保持每次只改一小段。

Generating patch (26 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```


Generating patch (24 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```


Generating patch (19 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
参数链已经接到核心函数了。最后一段是 CLI 开关和主调度，把它补完后就能直接上机 A/B `dir=0/1`。

Generating patch (38 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
代码改完了。我先快速编译，然后直接做两组最有信息量的 A/B：
1. helper-prep 观测链 `dir=0 vs dir=1`
2. best-known direct/session 链 `dir=0 vs dir=1`
看 `<intf> rate ch fmt`、`getTaggedInfo`、`session_open` 有没有任何前移。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c), 24 problems found

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh

本地编译通过了，编辑器报的还是宿主机 Android 头文件噪音。现在开始上机做 `dir=0/1` 的最小 A/B，先看 helper-prep 是否能让 `<intf> rate ch fmt` 或 `getTaggedInfo` 出现任何变化。

Ran terminal command:  adb push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe' /data/local/tmp/pure_c_agm_probe

Ran terminal command:  adb shell chmod 755 /data/local/tmp/pure_c_agm_probe

我先跑 helper-prep 观测链的 `dir=0` 基线，再跑 `dir=1` 对照，只抓 `set_audio_intf_metadata`、`rate ch fmt` 和 `getTaggedInfo` 这些关键信号。

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --inspect-only' | rg 'set_audio_intf_metadata|helper-prep after device media config|helper-prep after audio intf metadata|rate ch fmt values=4|PCM100 get_array: PCM100 getTaggedInfo|helper_prep rc'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --inspect-only' | rg 'set_audio_intf_metadata|helper-prep after device media config|helper-prep after audio intf metadata|rate ch fmt values=4|PCM100 get_array: PCM100 getTaggedInfo|helper_prep rc'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --inspect-only --audio-intf-dir-1' | rg 'set_audio_intf_metadata|helper-prep after device media config|helper-prep after audio intf metadata|rate ch fmt values=4|PCM100 get_array: PCM100 getTaggedInfo|helper_prep rc'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --inspect-only --audio-intf-dir-1' | rg 'set_audio_intf_metadata|helper-prep after device media config|helper-prep after audio intf metadata|rate ch fmt values=4|PCM100 get_array: PCM100 getTaggedInfo|helper_prep rc'

两组结果都出来了，我只读过滤后的关键行，确认这个方向位到底有没有实际影响。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_gH2WvslLowNLoUHOSLjl11Di__vscode-1773803651610/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_ho679XyGk6UuDDGCQ9TFAlue__vscode-1773803651611/content.txt)

`audio_intf_dir=1` 完全没改边界，helper-prep 观测面和 `dir=0` 一样。这个参数不是当前缺口。我再补最后一组最有价值的 A/B：把它叠到 best-known session-open 链上，确认 `-19` 也不变，然后就可以正式把这条支线降级。

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-devicepp-aif-media-preconnect-init' | rg 'aif_set_media_config|session_set_metadata|session_aif_set_metadata|pre-connect|agm_session_open rc'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-devicepp-aif-media-preconnect-init' | rg 'aif_set_media_config|session_set_metadata|session_aif_set_metadata|pre-connect|agm_session_open rc'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-devicepp-aif-media-preconnect-init --audio-intf-dir-1' | rg 'aif_set_media_config|session_set_metadata|session_aif_set_metadata|pre-connect|agm_session_open rc'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-devicepp-aif-media-preconnect-init --audio-intf-dir-1' | rg 'aif_set_media_config|session_set_metadata|session_aif_set_metadata|pre-connect|agm_session_open rc'

我准备做一个更硬的现场对照：在设备上把 `agmplay` 挂后台跑起来，然后立刻用现有 `--inspect-only` 抓 `<intf> rate ch fmt` 和 `PCM100 getTaggedInfo`。如果成功的 `agmplay` 窗口里这些控件仍然是 0，那当前“helper 应该把它们立起来”的假设就得继续降级。

Ran terminal command:  adb shell 'ls /data/local/tmp | rg "test440|10s|wav"'
Completed with input:  adb shell 'ls /data/local/tmp | rg "test440|10s|wav"'

Ran terminal command:  adb shell 'ls /vendor/bin/agmplay && echo ok'

设备 shell 里没有 `rg`，我改用最小命令再确认样本文件，然后直接抓 agmplay 运行窗口。

Ran terminal command:  adb shell 'ls /data/local/tmp | grep -E "test440|10s|wav"'

Ran terminal command:  adb shell 'ls /data/local/tmp/*.wav 2>/dev/null | head'

我现在直接起一个 10 秒的 `agmplay` 窗口，再立刻用 `inspect-only` 抓现场，目标是验证成功链里这些控件到底会不会真的变非零。

Ran terminal command:  adb shell 'rm -f /data/local/tmp/agmplay_bg.log; nohup /vendor/bin/agmplay /data/local/tmp/test440_mid_10s_32bit.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY >/data/local/tmp/agmplay_bg.log 2>&1 &'

Ran terminal command:  sleep 1 && adb shell '/data/local/tmp/pure_c_agm_probe --inspect-only' | rg 'PCM100 get_array: PCM100 getTaggedInfo|PCM100 enum: PCM100 control|TDM-LPAIF-RX-SECONDARY rate ch fmt values=4|AGM interface 运行态快照: pure-c final snapshot|pure-c probe: inspect-only'
Completed with input:  sleep 1 && adb shell '/data/local/tmp/pure_c_agm_probe --inspect-only' | rg 'PCM100 get_array: PCM100 getTaggedInfo|PCM100 enum: PCM100 control|TDM-LPAIF-RX-SECONDARY rate ch fmt values=4|AGM interface 运行态快照: pure-c final snapshot|pure-c probe: inspect-only'

Ran terminal command:  adb shell 'cat /data/local/tmp/agmplay_bg.log | tail -n 40'

现场快照已经抓到，我先读关键行；如果日志还没刷完，我再补一眼 agmplay 的收尾输出。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_l4VOJXS5IEAQmT2pgvJCQGx7__vscode-1773803651621/content.txt)

Ran terminal command:  sleep 2 && adb shell 'cat /data/local/tmp/agmplay_bg.log | tail -n 80'

刚才那个快照把 probe 自己的 helper-prep 也带进去了，不是纯现场。我现在用真正的“只读快照”方式重抓一次：跳过 helper-prep、初始 control、split metadata 和 connect，只看 agmplay 运行窗口本身留下的状态。

Ran terminal command:  adb shell 'rm -f /data/local/tmp/agmplay_bg.log; nohup /vendor/bin/agmplay /data/local/tmp/test440_mid_10s_32bit.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY >/data/local/tmp/agmplay_bg.log 2>&1 &'

Ran terminal command:  sleep 1 && adb shell '/data/local/tmp/pure_c_agm_probe --inspect-only --skip-helper-prep --skip-initial-control --skip-split-metadata --skip-connect' | rg 'PCM100 enum: PCM100 control|PCM100 get_array: PCM100 getTaggedInfo|TDM-LPAIF-RX-SECONDARY rate ch fmt values=4|pure-c probe: inspect-only'
Completed with input:  sleep 1 && adb shell '/data/local/tmp/pure_c_agm_probe --inspect-only --skip-helper-prep --skip-initial-control --skip-split-metadata --skip-connect' | rg 'PCM100 enum: PCM100 control|PCM100 get_array: PCM100 getTaggedInfo|TDM-LPAIF-RX-SECONDARY rate ch fmt values=4|pure-c probe: inspect-only'

Ran terminal command:  sleep 2 && adb shell 'cat /data/local/tmp/agmplay_bg.log | tail -n 80'

刚才这次 still 带了 probe 自己的 `<intf> rate ch fmt` 直写，因为没加 `--skip-rate-write`。我补最后一次真正被动的现场抓取，只保留只读路径。

Ran terminal command:  adb shell 'rm -f /data/local/tmp/agmplay_bg.log; nohup /vendor/bin/agmplay /data/local/tmp/test440_mid_10s_32bit.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY >/data/local/tmp/agmplay_bg.log 2>&1 &'

Ran terminal command:  sleep 1 && adb shell '/data/local/tmp/pure_c_agm_probe --inspect-only --skip-helper-prep --skip-initial-control --skip-split-metadata --skip-connect --skip-rate-write' | rg 'PCM100 enum: PCM100 control|PCM100 get_array: PCM100 getTaggedInfo|TDM-LPAIF-RX-SECONDARY rate ch fmt values=4|pure-c probe: inspect-only|跳过 helper-prep|跳过初始 PCM100 control|跳过 PCM100 split metadata 直写|跳过 connect'
Completed with input:  sleep 1 && adb shell '/data/local/tmp/pure_c_agm_probe --inspect-only --skip-helper-prep --skip-initial-control --skip-split-metadata --skip-connect --skip-rate-write' | rg 'PCM100 enum: PCM100 control|PCM100 get_array: PCM100 getTaggedInfo|TDM-LPAIF-RX-SECONDARY rate ch fmt values=4|pure-c probe: inspect-only|跳过 helper-prep|跳过初始 PCM100 control|跳过 PCM100 split metadata 直写|跳过 connect'

这次被动现场结果很关键：即使在 `agmplay` 运行窗口里，外部可见的控制面仍然是
1. `PCM100 control = ZERO`
2. `PCM100 getTaggedInfo = -22`
3. `<intf> rate ch fmt = 0,0,0,0`

也就是说，成功播放链并不会在这些可见控件上留下“helper 已经把状态写起来”的稳定痕迹。这个方向现在可以正式降级。接下来我补最后一个只读验证：在 `agmplay` 运行窗口里直接调用我们的 `direct-tagged-info` 路径，看 `tag=0xC0000019`/`miid` 是不是同样拿不到，这样就能把“缺的是外部可见 tagged-info”也一起钉死。

Searched for regex `direct_tagged_info|probe_agm_tagged_miid|AGM_MFC_TAG` (`**/pure_c_agm_probe.c`), 13 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#2040-2040), lines 2040 to 2145

Ran terminal command:  adb shell 'rm -f /data/local/tmp/agmplay_bg.log; nohup /vendor/bin/agmplay /data/local/tmp/test440_mid_10s_32bit.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY >/data/local/tmp/agmplay_bg.log 2>&1 &' && sleep 1 && adb shell '/data/local/tmp/pure_c_agm_probe --inspect-only --skip-helper-prep --skip-initial-control --skip-split-metadata --skip-connect --skip-rate-write --direct-tagged-info' | rg 'direct getTaggedInfo|direct agm_mixer_get_miid|PCM100 get_array: PCM100 getTaggedInfo|inspect-only'
Completed with input:  adb shell 'rm -f /data/local/tmp/agmplay_bg.log; nohup /vendor/bin/agmplay /data/local/tmp/test440_mid_10s_32bit.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY >/data/local/tmp/agmplay_bg.log 2>&1 &' && sleep 1 && adb shell '/data/local/tmp/pure_c_agm_probe --inspect-only --skip-helper-prep --skip-initial-control --skip-split-metadata --skip-connect --skip-rate-write --direct-tagged-info' | rg 'direct getTaggedInfo|direct agm_mixer_get_miid|PCM100 get_array: PCM100 getTaggedInfo|inspect-only'

我已经把“成功链外部可见控件仍然全零、`getTaggedInfo` 仍然 `-22`”钉住了。下一步我不再盯 mixer 表面状态，而是直接抓服务/内核日志，确认 `agmplay` 确实在这段窗口里走到了 `graph_open/start` 成功链。

Ran terminal command:  adb shell 'logcat -d -v brief | grep -E "graph_open|graph_start|aw882xx_start_pa|session_open_with_first_device|get_tags_with_module_info" | tail -n 80'

Ran terminal command:  adb shell 'dmesg | grep -E "aw882xx|graph_open|graph_start|sun-mtp-snd-card" | tail -n 80'

我把这轮最硬的新结论记进仓库记忆，避免后面再回到“盯控件表面状态”这条已经被现场否掉的路。

Inserted into memory file twrp_audio_pure_c_frontier_20260318.md

继续做了，而且这轮把主线又收紧了一层。

这轮新增的硬结论：

1. audio_intf_metadata 的 dir 位不是当前缺口
我给 pure_c_agm_probe 加了一个 audio-intf-dir-1 开关，做了 dir=0 和 dir=1 的 A/B。
结果两边完全一样：
- interface 的 rate ch fmt 仍然是 0,0,0,0
- PCM100 getTaggedInfo 仍然是 -22 或 -19
- best-known session_open 链仍然停在 -19

所以这条支线可以降级，不值得再继续猜 dir。

2. 成功的 agmplay 链，不会在外部可见 mixer 控件上留下稳定的“非零状态”
我在设备上把 agmplay 挂后台跑 10 秒，然后用完全被动的 inspect-only 去抓现场。
这次是纯只读，不再让 probe 自己做 helper-prep、rate 写入、metadata 写入、connect。

抓到的现场是：
- PCM100 control = ZERO
- PCM100 getTaggedInfo = -22
- TDM-LPAIF-RX-SECONDARY rate ch fmt = 0,0,0,0

同时 logcat 明确显示：
- graph_open ret 0
- graph_start ret 0
- aw882xx_start_pa start success

这说明一件很关键的事：
成功播放链并不要求这些外部可见控件在运行窗口里呈现非零或可读状态。
所以当前主线不该再把“helper 调用后 mixer 读回必须变化”当成必要前提。

3. 成功窗口里，外部可见的 tagged-info 也仍然拿不到
我又在同一个 agmplay 窗口内做了完全被动的 direct-tagged-info 探测。
结果还是：
- PCM100 getTaggedInfo 直接 rc=-22
- tag 0xC0000019 value=0

这进一步说明：
成功链依赖的状态，不是通过当前这套外部可见的 PCM100 getTaggedInfo 控件直接暴露出来的。

4. 之前新增的 preopen/postopen set_config 支线，价值继续下降
这轮之前已经确认：
- preopen set_config 不管怎么改 buffer 形态，仍是 -22
- plugin 的两次 agm_session_set_config 在时序上都在 agm_session_open 之后
- 但把 post-open 分支叠到 best-known 前置链上，agm_session_open 仍然到不了成功

现在再结合上面“成功链不在可见控件上留痕”的新事实，说明继续围着这些表面参数做 set_config 猜测，收益更低了。

当前主线应当更新为：

1. 不再把 interface rate ch fmt、PCM100 metadata、PCM100 getTaggedInfo 这些外部可见控件当成成功链必须可见的中间状态。
2. 不再优先追 helper 为什么 rc=0 但控件读回为 0。
3. 下一步该追的，是成功链内部真正建立 graph/session 状态的那段不可见路径，而不是 mixer 表面读回。

我已经把这些结论写进仓库记忆，避免后面再回到已经被实机否掉的方向。

下一步我建议直接继续做这一件事：
1. 反查 agmplay 成功链对应的服务侧 graph_open 日志里那些 tag 和 miid，倒推 pure C 现在缺的不是“可见控件写入”，而是哪个内部 graph key 或 session 路径没有建立起来。

Made changes.

User: 继续

GitHub Copilot: 我把下一步收敛成“成功链日志 vs 失败链日志”的正面对照，目标是直接看 graph_open 里到底缺了哪些 tag/miid，而不是继续猜控件表面状态。

Ran terminal command:  adb logcat -c && adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-devicepp-aif-media-preconnect-init' >/dev/null 2>&1; adb shell 'logcat -d -v brief | grep -E "graph_open|graph_start|get_tags_with_module_info|session_open_with_first_device|Metadata GKV size|CKV count|Connect failed" | tail -n 120'

Ran terminal command:  adb logcat -c && adb shell '/vendor/bin/agmplay /data/local/tmp/test440_mid_10s_32bit.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY' >/dev/null 2>&1; adb shell 'logcat -d -v brief | grep -E "graph_open|graph_start|get_tags_with_module_info|session_open_with_first_device|Metadata GKV size|CKV count|Connect failed|miid .* tag c000" | tail -n 160'

刚才这个对照已经说明关键差异不在 CKV 数量，成功和失败两边都是 4。下一步我直接抓“best-known 直链”的 `-5` 日志，看它和 agmplay 成功链相比究竟缺到哪一步。

Ran terminal command:  adb logcat -c && adb shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --rate-60f4-words --pre-setparam-63d8 --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend' >/dev/null 2>&1; adb shell 'logcat -d -v brief | grep -E "graph_open|graph_start|get_tags_with_module_info|session_open_with_first_device|Metadata GKV size|CKV count|Connect failed|miid .* tag c000|MFC not present" | tail -n 180'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --rate-60f4-words --pre-setparam-63d8 --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend' | rg 'direct_get_tagged_info|agm_mixer_get_miid|pcm_open|configure_mfc|helper_connect|metadata-63d8|metadata-6a54|min|metadata-689c'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --rate-60f4-words --pre-setparam-63d8 --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend' | rg 'direct_get_tagged_info|agm_mixer_get_miid|pcm_open|configure_mfc|helper_connect|metadata-63d8|metadata-6a54|min|metadata-689c'

服务侧日志已经把 `-5` 钉成了更具体的 ACDB/GKV 失败。我现在只读 probe 自己的关键输出，把这条失败和我们送进去的 metadata 组合起来。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_pYf8QNejeBoCUs5oYCaXA8IQ__vscode-1773803651639/content.txt)

我把主线继续收紧到“GKV 具体缺哪一组键”。现在最值得做的是核对 `set_agm_streamdevice_metadata` 的真实 payload 形态，看我们当前 `0xac000000/0x2` 这组直写是不是还差了另一半。

Read memory twrp_audio_devicepp_kv_frontier.md

Read memory twrp_audio_session_gkv_a300_candidates_20260318.md

Ran terminal command:  strings -a -t x '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt' | grep -E 'AC000|AD000|A2000001|A3000004|A3000006|A2000009' | head -n 40

现有记忆只够说明 `devicepp` 进图了，但还不够解释为什么 `-5`。我继续直接翻反汇编文本里的十六进制立即数和 `streamdevice metadata` 段，目标是把第二组 GKV 的真实 tag/value 形态抠出来。

Searched for regex `ac000000|ad000000|a2000001|a3000004|a3000006|a2000009` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), no results

Searched for regex `set_agm_streamdevice_metadata|streamdevice metadata|0x7250|674c` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), 1 result

Searched for regex `ac000000|ad000000|a2000001|a3000004|a3000006|a2000009` (`**/audio_dtb_probe/agmplay`), no results

我已经定位到 tinyplay_ftm 对应的 `streamdevice metadata` 代码段了，现在直接读那一段，看看它到底往 payload 里塞了哪些常量和长度。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2490-2490), lines 2490 to 2585

我把这个局部反汇编交给只读子代理做一次定向整理，目标是尽快把 `0x689c/0x6a54/streamdevice` 这几种 payload 的真实常量和 speaker 路使用哪一支理清。

解析 metadata payload

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#1-1), lines 1 to 100

Searched for regex `66e8|66ec|66f0|66f4|66f8|66fc|6700|6704|6708|670c|6710|6714|6718|671c|6720` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), 19 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2400-2400), lines 2400 to 2600

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2690-2690), lines 2690 to 2750

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2280-2280), lines 2280 to 2350

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2380-2380), lines 2380 to 2450

Searched for regex `6400|6408|6414|6418|6560|6568|67bc|67c8` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), 8 results

Searched for regex `Contents of section|.rodata|.data` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), 3 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2450-2450), lines 2450 to 2500

Searched for regex `bl.*6628|\tb.* 0x6628|0x6628` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), 1 result

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#1100-1100), lines 1100 to 1200

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#1130-1130), lines 1130 to 1220

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#1080-1080), lines 1080 to 1170

Searched for regex `^\s+4c00:|^\s+4bf8:|^\s+4bf4:` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), 3 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#760-760), lines 760 to 800

Searched for regex `^\s+4[ab][0-9a-f]{2}:|^\s+4a[0-9a-f]{2}:|bl 0x4` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), 20 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#620-620), lines 620 to 700

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#480-480), lines 480 to 550

Searched for regex `^[0-9a-f]+.*paciasp|^[0-9a-f]+.*<\.text` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), 1 result

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#750-750), lines 750 to 775

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2280-2280), lines 2280 to 2310

Read memory [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/memory-tool/memories/NDE1OGQ0YzMtZmE4Ny00MjBiLTg1NjMtOTM3Y2UwY2FkNzk5)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2495-2495), lines 2495 to 2520

Created memory file [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/memory-tool/memories/NDE1OGQ0YzMtZmE4Ny00MjBiLTg1NjMtOTM3Y2UwY2FkNzk5/objdump_analysis_20260319.md)

子代理的结果给了一个新分叉：它把第二组键指向了 `0xA2000000/0xA2000001` 家族，而不是我们之前在直链里手写的 `0xac000000/0x2`。我先快速核对这段反汇编，再把它落成可上机的 payload A/B。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2400-2400), lines 2400 to 2495

Searched for regex `6598|6484|6478|6834|0x30` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), 40 results

Searched for regex `prime_pcm100_metadata_689c_full_kv|metadata-689c|PCM100 split-kv metadata` (`**/pure_c_agm_probe.c`), 7 results

反汇编里这段更像“按路由类型生成第二段 metadata payload”，而我们现在手写的 `689c` 仍是固定的单一 `0xac000000/0x2`。我先把现有 689c 生成函数读出来，然后加两个最小 A/B 变体去撞服务侧 GKV。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1430-1430), lines 1430 to 1515

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#2120-2120), lines 2120 to 2155

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#2288-2288), lines 2288 to 2348

在动代码之前，我先把现有几种 metadata 形态重新跑一遍做基线对照，避免为一个其实早就退化过的 payload 变体浪费编辑轮次。

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --rate-60f4-words --pre-setparam-63d8 --helper-connect --direct-tagged-info --with-mfc --pcm-backend' | rg 'split-kv metadata|metadata-689c|metadata-6a54|min|direct_get_tagged_info|post_connect_mfc|打开失败|pcm_open|helper_connect'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --rate-60f4-words --pre-setparam-63d8 --helper-connect --direct-tagged-info --with-mfc --pcm-backend' | rg 'split-kv metadata|metadata-689c|metadata-6a54|min|direct_get_tagged_info|post_connect_mfc|打开失败|pcm_open|helper_connect'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --rate-60f4-words --pre-setparam-63d8 --metadata-689c-full-kv --helper-connect --direct-tagged-info --with-mfc --pcm-backend' | rg 'split-kv metadata|metadata-689c|metadata-6a54|min|direct_get_tagged_info|post_connect_mfc|打开失败|pcm_open|helper_connect'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --rate-60f4-words --pre-setparam-63d8 --metadata-689c-full-kv --helper-connect --direct-tagged-info --with-mfc --pcm-backend' | rg 'split-kv metadata|metadata-689c|metadata-6a54|min|direct_get_tagged_info|post_connect_mfc|打开失败|pcm_open|helper_connect'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --rate-60f4-words --pre-setparam-63d8 --metadata-6a54-min --helper-connect --direct-tagged-info --with-mfc --pcm-backend' | rg 'split-kv metadata|metadata-689c|metadata-6a54|min|direct_get_tagged_info|post_connect_mfc|打开失败|pcm_open|helper_connect'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --rate-60f4-words --pre-setparam-63d8 --metadata-6a54-min --helper-connect --direct-tagged-info --with-mfc --pcm-backend' | rg 'split-kv metadata|metadata-689c|metadata-6a54|min|direct_get_tagged_info|post_connect_mfc|打开失败|pcm_open|helper_connect'

三组基线都出来了，我只读关键行，先看现有 metadata 变体之间有没有明显的层级差，这决定我接下来该加哪种新 payload。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_3eR7IOUSec0dIUqGnPjHt2Xf__vscode-1773803651679/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_zgvQRBRkmze2MAHKhIyvsi75__vscode-1773803651681/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_MfilMTdQNdyvIzN0e2oO1c9a__vscode-1773803651680/content.txt)

我做一个最小的 payload 试探，不碰现有默认路径：只新增 `metadata-route-a200-speaker` 变体，把第二组键从 `ac000000/ac000002` 切到 `a2000000/a2000001`，然后直接复跑 best-known 直链看 `-5` 有没有变化。

Generating patch (28 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
我继续把这个新 route 变体贯通到 CLI 和调用点，只加一个开关，不改现有默认行为。

Generating patch (24 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
最后把 metadata 写入调用点接上这个 route 选择，然后就能直接编译复跑。

Generating patch (34 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
代码改完了。我先重编，然后直接跑两组 best-known 直链 A/B：
1. 默认 AC 路由
2. 新的 A200 speaker 路由
同时抓服务侧 `gkv failed` / `Connect failed`，看有没有层级变化。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh
Completed with input:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh

Ran terminal command:  adb push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe' /data/local/tmp/pure_c_agm_probe && adb shell chmod 755 /data/local/tmp/pure_c_agm_probe

编译错误说明 route 选择只接到了 main，还没传进 run_probe。我把参数链补完整，再重编。

Generating patch (31 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
我再编一次，确认参数链补齐，然后继续 AC vs A200 的服务侧 A/B。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c), 24 problems found

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh

编译通过了。现在直接上机跑两组最小 A/B：默认 AC 路由和新的 A200 路由，统一抓服务侧 `gkv failed` / `Connect failed`，看有没有从 `-5` 或 `-19` 再往前移动。

Ran terminal command:  adb push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe' /data/local/tmp/pure_c_agm_probe && adb shell chmod 755 /data/local/tmp/pure_c_agm_probe

Ran terminal command:  adb logcat -c && adb shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --rate-60f4-words --pre-setparam-63d8 --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend' >/dev/null 2>&1; adb shell 'logcat -d -v brief | grep -E "gsl_graph_get_tags_with_module_info|Connect failed error|graph_open|graph_start" | tail -n 120'

Ran terminal command:  adb logcat -c && adb shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --rate-60f4-words --pre-setparam-63d8 --metadata-6a54-plus-689c --metadata-route-a200-speaker --helper-connect --direct-tagged-info --with-mfc --pcm-backend' >/dev/null 2>&1; adb shell 'logcat -d -v brief | grep -E "gsl_graph_get_tags_with_module_info|Connect failed error|graph_open|graph_start" | tail -n 120'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --rate-60f4-words --pre-setparam-63d8 --metadata-6a54-plus-689c --metadata-route-a200-speaker --helper-connect --direct-tagged-info --with-mfc --pcm-backend' | rg 'metadata-689c|direct_get_tagged_info|post_connect_mfc|打开失败|helper_connect'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --rate-60f4-words --pre-setparam-63d8 --metadata-6a54-plus-689c --metadata-route-a200-speaker --helper-connect --direct-tagged-info --with-mfc --pcm-backend' | rg 'metadata-689c|direct_get_tagged_info|post_connect_mfc|打开失败|helper_connect'

服务侧没变化，我读一下用户态输出，确认 A200 变体确实已经按预期发出，而不是没切到。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_Olmjk3s5ZqVg83aONT8OCe6Y__vscode-1773803651696/content.txt)

当前最值得继续追的是 case 6/7 里那几个从数据段加载的常量。我先直接把 tinyplay_ftm 的对应数据段字节 dump 出来，看看能不能把那 20B/32B payload 恢复到“可直接编码”的程度。

Searched for files matching `**/tinyplay_ftm`, no matches

Ran terminal command:  llvm-objdump -s --start-address=0x1120 --stop-address=0x1160 '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/agmplay'

Ran terminal command:  file '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm'

工作区里没有原始 tinyplay_ftm 二进制，只剩 objdump 文本；我先从刚才 dump 出来的输出里看看 agmplay 的数据段读法是否成立，如果成立，我再找同源二进制或改从现有设备上拉原始 tinyplay_ftm。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_Pun2G8YN6yBcLGNrZ0zNiF9p__vscode-1773803651698/content.txt#1-1), lines 1 to 80

直接从设备拉原始 tinyplay_ftm 会比继续啃 objdump 文本更省时间。我先确认路径，然后拉回工作区做数据段解析。

Ran terminal command:  adb shell 'ls /odm/bin/tinyplay_ftm /vendor/bin/tinyplay_ftm 2>/dev/null'
Completed with input:  adb shell 'ls /odm/bin/tinyplay_ftm /vendor/bin/tinyplay_ftm 2>/dev/null'

Ran terminal command:  adb pull /odm/bin/tinyplay_ftm '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

原始二进制已经拉回来了。现在我直接查节区布局并 dump `0x1000` 页附近那几个被 helper 用到的常量地址。

Ran terminal command:  llvm-objdump -h '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

Ran terminal command:  llvm-objdump -s --start-address=0x1120 --stop-address=0x11a0 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

Ran terminal command:  llvm-objdump -s --start-address=0x1ac0 --stop-address=0x1af0 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

Compacted conversation节区已经确认：常量都在 `.rodata`，起始就是 `0x1120`。我接着读刚才的 dump 结果，先把 helper 引用的几组字面量还原出来。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_2KEOLkEZbAwqv5SVhInkZ5fs__vscode-1773803651705/content.txt#1-1), lines 1 to 120

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_rRP1jYpn3frjN2gkFeZlvIHr__vscode-1773803651706/content.txt#1-1), lines 1 to 80

Ran terminal command:  llvm-objdump -d --start-address=0x4660 --stop-address=0x4840 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

刚才那个 section dump 工具不按 section 过滤，噪音太大。我改用原始字节视图直接看偏移，把 0x1120、0x1248、0x1270 一带的常量捞出来，再把 0x65xx-0x68xx helper 主体对齐。

Ran terminal command:  xxd -g 4 -s 0x1120 -l 256 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

Ran terminal command:  xxd -g 4 -s 0x1240 -l 160 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

Ran terminal command:  llvm-objdump -d --start-address=0x6590 --stop-address=0x6840 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

常量已经出来了，前两组不是猜测，是真实 rodata 字面量：

- `0x1120`: `0xC0000040, 0x00000001, 0x00020001, 0x00060003`
- `0x1130`: `0xB1000000, 0xB1000003, 0x00020001, 0x00080003`
- `0x1140`: `0x00000400, 0x00000004, 0xA2000000, 0xA2000009`
- `0x1150`: `0x00020001, 0x00090008`

我继续把 helper 分支读出来，确认这些块分别落在哪几个 case 上。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_GvSVoQQrkuM2V4X8UxLqQOV2__vscode-1773803651712/content.txt)

Ran terminal command:  xxd -g 4 -s 0x1130 -l 64 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

Ran terminal command:  xxd -g 4 -s 0x1400 -l 96 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

分支关系已经对齐了：

- case `5` 用 rodata `0x1138`
- case `6` 用 `0x1128` 再补一个 `0x00090008`
- case `7` 也是 `0x1128`，但额外在 `+0x24` 写入 `0x0007`
- case `8` 用 `0x1ad0` 的 16 字节整块
- case `4` 用 `0x1150`

我现在补看 `0x1ad0`，然后进 probe 代码，把现有 5-word 近似扩成跟 tinyplay_ftm 一致的 case 6/7 payload。

Searched for files matching `**/pure_c_agm_probe.c`, no matches

Ran terminal command:  xxd -g 4 -s 0x1ad0 -l 32 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

Read memory twrp_audio_pure_c_frontier_20260318.md

`0x1ad0` 也确认了，是一整块 4-word 常量：`0x00020001, 0x00060003, 0x00090008, 0x00050004`。接下来我先定位 probe 源文件，再看 repo memory 里的当前前沿记录，避免把新实验和旧结论打架。

Ran terminal command:  rg --files '/Volumes/Case-sensitive APFS/TWRP' | rg 'pure_c_agm_probe\.c$'
Completed with input:  rg --files '/Volumes/Case-sensitive APFS/TWRP' | rg 'pure_c_agm_probe\.c$'

Read memory twrp_audio_pure_c_frontier_20260318.md

Ran terminal command:  rg -n "metadata_689c|streamdevice|route_tag|metadata-route-a200-speaker|metadata-6a54-plus-689c" '/Volumes/Case-sensitive APFS/TWRP'

源文件不在简单文件名匹配里，我直接按函数名定位。这个仓里文档噪音很多，继续按文件名找只是在浪费时间。

Ran terminal command:  rg -n "probe_agm_session_open_close|prime_pcm100_metadata_689c_full_kv|prime_agm_helper_prep|run_probe\(" '/Volumes/Case-sensitive APFS/TWRP'
Completed with input:  rg -n "probe_agm_session_open_close|prime_pcm100_metadata_689c_full_kv|prime_agm_helper_prep|run_probe\(" '/Volumes/Case-sensitive APFS/TWRP'

Search complete: 定位 probe 源码

Searched codebase for "probe_agm_session_open_close prime_pcm100_metadata_689c_full_kv prime_agm_helper_prep metadata-route-a200-speaker AGM probe pure AGM C source", 21 results

Searching for regex `probe_agm_session_open_close|prime_pcm100_metadata_689c_full_kv|prime_agm_helper_prep|metadata-route-a200-speaker`

Searching for text `probe_agm_session_open_close`

Searching for text `prime_pcm100_metadata_689c_full_kv`

Searching for text `prime_agm_helper_prep`

Searching for text `metadata-route-a200-speaker`

Searched for files matching `**/*agm*.{c,cc,cpp,h,hpp,mk,sh,py}`, 200 matches

Searched for files matching `**/*probe*.{c,cc,cpp,h,hpp,mk,sh,py}`, 200 matches

Searched for files matching `**/*audio*.{c,cc,cpp,h,hpp,mk,sh,py}`, 200 matches

函数名搜索没命中，说明源文件大概率在被忽略目录或不叫这些函数名。我改从构建脚本反推输入文件，这比盲搜稳。

Searching for regex `build_pure_c_agm_probe.sh|pure_c_agm_probe`

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual)

Ran terminal command:  rg -n "build_pure_c_agm_probe|pure_c_agm_probe" '/Volumes/Case-sensitive APFS/TWRP' --hidden -g '!*.o' -g '!*.so'

文档里已经给了真实路径线索：源码在 `Flutter_On_Recovery/video_player`。我先确认这个目录实际存在，再读代码改 payload。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/Flutter_On_Recovery)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/Flutter_On_Recovery/video_player)

文档记录的是旧工作目录，不在当前根目录下。现在我从根目录里找实际的 `video_player` 工程和构建脚本所在位置，再直接进源文件。

Ran terminal command:  find '/Volumes/Case-sensitive APFS/TWRP' -name build_pure_c_agm_probe.sh -o -name pure_c_agm_probe.c -o -path '*/video_player'

Ran terminal command:  find '/Volumes/Case-sensitive APFS/TWRP' -path '*/video_player' -type d

工作区里没搜到源码实体，但终端提示符一直在 `video_player`。我先确认当前 shell 的真实 cwd，这很可能就是源码目录。

Ran terminal command:  pwd

Ran terminal command:  ls

源码找到了，确实在当前 shell 的外部工作目录里。我现在直接读 pure_c_agm_probe.c 的 metadata helper 和 CLI 分支，把 tinyplay_ftm 的 case 6/7 payload 挂进去。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1-1), lines 1 to 260

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#260-260), lines 260 to 620

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#620-620), lines 620 to 1120

我已经拿到源码。下一步只读 metadata 函数和 CLI 分支，不会大面积动。目标是最小改动增加一个“按 tinyplay_ftm case 6/7 真实字面量写 streamdevice metadata”的实验开关。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1120-1120), lines 1120 to 1700

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1700-1700), lines 1700 to 2400

Ran terminal command:  rg -n "prime_pcm100_metadata_689c_full_kv|prime_pcm100_streamdevice_split_kv|metadata-route-a200-speaker|metadata_mode|metadata-689c-full-kv|metadata-6a54-plus-689c" '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c'

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#2400-2400), lines 2400 to 2509

helper 主体够清楚了，但要写出同构 payload 还差调用实参，也就是 case 号和头部 0x10/0x14/0x16 这几个字段是谁传进去的。我先回看 6628 的调用点，只追这一条，不扩散。

Ran terminal command:  llvm-objdump -d --start-address=0x6460 --stop-address=0x65a8 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

Ran terminal command:  llvm-objdump -d --start-address=0x6880 --stop-address=0x69c0 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

`0x6628` 这段就是我要复刻的 helper 本体。现在只差谁在调它、传的 case 值是多少。我直接找对它的 `bl 0x6628` 调用点。

Ran terminal command:  llvm-objdump -d '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin' | rg "bl\s+0x6628"

Ran terminal command:  llvm-objdump -d '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin' | rg "bl\s+0x689c"

Ran terminal command:  llvm-objdump -d --start-address=0x4b20 --stop-address=0x4c40 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

我不打算把 6628 误接到当前主线里。它是 `get_miid(0xC0000019)` 之后的 post-connect helper，更像 MFC/tag payload，不是现在卡住 `-5` 的前置 GKV。当前更值得落地的是 689c helper 暴露出的 `AD000000` 分支，我直接加一个 AD route 变体并跑 A/B。

Created 5 todos

我现在改 pure_c_agm_probe.c，只加一个新的 route family 开关 `AD`，不碰现有默认路径。这样可以直接和现有 `AC`、`A200` 做三路 A/B。

Generating patch (18 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
代码改完了，改动很小：只新增 `AD000000/AD000002` 路由族开关。接下来直接编译，不先做无意义重读。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c), 24 problems found

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh

二进制已经编过，hash 是 `350382b0...`。我现在推到设备上，分别跑默认 AC 和新加的 AD，直接看 service 侧是否还停在同一个 `acdb get tags from gkv failed with 19 / Connect failed error:-5`。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && adb -s 70a91f89 push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /data/local/tmp/pure_c_agm_probe

Ran terminal command:  p='/data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --rate-60f4-words --pre-setparam-63d8 --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend'
adb -s 70a91f89 logcat -c
adb -s 70a91f89 shell "$p" | rg 'metadata-689c|direct_get_tagged_info|post_connect_mfc|pcm_open|打开失败'
adb -s 70a91f89 logcat -d | rg 'gsl_graph_get_tags_with_module_info|Connect failed error|graph_open ret|graph_start ret'

刚才那次返回被终端提示行污染了，我重跑成单行，不换行。目标不变，只取关键字段。

Ran terminal command:  adb -s 70a91f89 logcat -c && adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --rate-60f4-words --pre-setparam-63d8 --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend | rg 'metadata-689c|direct_get_tagged_info|post_connect_mfc|pcm_open|打开失败' && adb -s 70a91f89 logcat -d | rg 'gsl_graph_get_tags_with_module_info|Connect failed error|graph_open ret|graph_start ret'
Completed with input:  adb -s 70a91f89 logcat -c && adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --rate-60f4-words --pre-setparam-63d8 --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend | rg 'metadata-689c|direct_get_tagged_info|post_connect_mfc|pcm_open|打开失败' && adb -s 70a91f89 logcat -d | rg 'gsl_graph_get_tags_with_module_info|Connect failed error|graph_open ret|graph_start ret'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_PzxXIes9h8CRpoeUcYMgocSk__vscode-1773803651761/content.txt)

Ran terminal command:  adb -s 70a91f89 logcat -c; adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --rate-60f4-words --pre-setparam-63d8 --metadata-6a54-plus-689c --metadata-route-ad-devicepp --helper-connect --direct-tagged-info --with-mfc --pcm-backend | rg 'metadata-689c|direct_get_tagged_info|post_connect_mfc|pcm_open|打开失败'; adb -s 70a91f89 logcat -d | rg 'gsl_graph_get_tags_with_module_info|Connect failed error|graph_open ret|graph_start ret'

我已经把 AD 跑起来了。现在直接读回关键行，确认 route 确实切到了 `AD`，以及 service 侧有没有从 `-5` 挪动。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_bjdSIlja6IWwb4xZjCFWxSvJ__vscode-1773803651763/content.txt)

Ran terminal command:  adb -s 70a91f89 logcat -c; adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --rate-60f4-words --pre-setparam-63d8 --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend >/dev/null 2>&1; adb -s 70a91f89 logcat -d | rg 'gsl_graph_get_tags_with_module_info|Connect failed error|graph_open ret|graph_start ret'

A/B 已经完成，结论很明确：`AD` 不是当前缺口。现在我把这次从原始二进制里确认下来的 helper 角色映射和 AD 无效结论存成 repo memory，避免后面再回头猜。

Read changed files in the active git repository

Starting: *记录新前沿结论* (5/5)

Read memory

Created memory file twrp_audio_tinyplay_ftm_helper_roles_20260319.md

Completed: *记录新前沿结论* (5/5)

这轮已经把一个关键分叉砍掉了：我新增了 AD route family 的纯 C 实验，并完成了真机 A/B。结论是，单纯把 route 从 AC 切到 AD 没有推进前沿，服务侧仍然稳定卡在 “acdb get tags from gkv failed with 19” 然后 “Connect failed error:-5”。

具体结果：

1. 我先直接分析了从设备拉回来的 tinyplay_ftm 原始二进制。
2. 现在可以确认：
   - 0x6628 那个 helper 不是当前 -5 前沿的前置 metadata helper。
   - 它只会在先拿到 tag=0xC0000019 的 MIID 之后才调用，属于 post-connect 的 setParamTag/MFC 类 helper。
   - 所以把 0x6628 那套 case6/case7 常量直接接到当前主线，没有价值。
3. 真正更接近当前主线的是 0x689c 那个 2-pair metadata helper。
   - 它的正常形态就是一对 stream kv 加一对 route kv。
   - 它确实存在一个 AD route family 分支，不只是 AC。

我已经做的代码改动：

1. 在纯 C probe 里新增了一个开关：
   - --metadata-route-ad-devicepp
2. 这个开关会把 route pair 切到：
   - route_tag = 0xAD000000
   - route_value = 0xAD000002
3. 重新编译、推送到设备，并按当前 best-known direct chain 实跑了。

真机结果：

1. 用户态确认新分支确实生效了：
   - metadata-689c(full-kv) 打印的是 AD route，不是 AC。
2. 但关键观测没有任何推进：
   - direct_get_tagged_info 仍然是 -19
   - post_connect_mfc 仍然是 -1
   - 最终 pcm_open 仍然是 Unknown error -5
3. 服务侧日志与默认 AC 路线同构：
   - 多次出现 acdb get tags from gkv failed with 19
   - 最终仍是 Connect failed error:-5

这次得到的有效结论：

1. 0x6628 可以从当前主线降级。
   - 它是 post-connect/MFC helper，不是当前 -5 的根因入口。
2. 单纯把 route family 从 AC 换成 AD，也可以降级。
   - 这不是当前缺失的 GKV 组件。
3. 0x689c 仍然值得继续追，但重点不再是 AC/AD 二选一。
   - 更可能缺的是它的上游实参来源，尤其是：
   - 第二对 kv 的真实 value 来源
   - 是否存在非零 selector
   - 是否需要走它那个 B100 特判分支

我还把这次确认下来的 helper 角色映射和 AD 无效结论存进 repo memory 了，后面不用再回头重复猜。

下一步最合理的是：

1. 继续回看 0x689c 的调用点，把传给它的 w24、w25、w23 真实语义彻底还原，尤其确认 AD 分支到底由哪个条件触发。
2. 如果调用点显示存在 B100 特判路径，就把纯 C probe 再加一个 B100 stream 变体，直接和现有 A100 路径做真机 A/B。

Made changes.

User: 继续

GitHub Copilot: 我继续顺着 0x689c 的调用链往上追实参，目标是把它的各个分支条件从“常量猜测”变成“调用点已证实”。

Ran terminal command:  llvm-objdump -d --start-address=0x5df0 --stop-address=0x5ef0 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

Ran terminal command:  llvm-objdump -d --start-address=0x4a80 --stop-address=0x4b90 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

Ran terminal command:  xxd -g 4 -s 0x1160 -l 96 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

我已经把 0x689c 前半段拆开了：它一上来先调 0x5e1c，而 0x5e1c 的作用已经明确，就是“按控件名找 mixer enum，然后 set_enum_by_string”。也就是说 0x689c 不是单纯写 metadata，它前面还会先切一个 enum 控件。接下来我把它用到的几个字符串地址解出来，确认切的是 `control` 还是 `connect`。

Ran terminal command:  xxd -g 1 -s 0x13e0 -l 96 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

Ran terminal command:  xxd -g 1 -s 0x1a50 -l 96 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

Ran terminal command:  xxd -g 1 -s 0x15b0 -l 48 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

我准备把 0x689c 的真实特判分支落成一个新实验：B100 stream kv。只做最小改动，不碰默认链路。

Using "Apply Patch"

补丁上下文没对上，我先精确读几个改动点再一次性落 patch，避免反复试错。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1460-1460), lines 1460 to 1515

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1928-1928), lines 1928 to 2175

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#2270-2270), lines 2270 to 2513

Generating patch (97 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
改动已落下去：现在 689c full helper 不再写死 A100，并且新增了一个 B100 专用实验开关。下一步直接编译上机，看 vendor 特判分支是否能把 service 侧日志从当前 -5 前沿挪开。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c), 24 problems found

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && adb -s 70a91f89 push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /data/local/tmp/pure_c_agm_probe

新二进制已经上机，hash 是 `011feac3...`。我现在先跑一组 B100 特判链，再补一组只用 689c full-kv 的窄链，避免和 6a54 或 63d8 叠加后看不清。

Ran terminal command:  adb -s 70a91f89 logcat -c; adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --rate-60f4-words --pre-setparam-63d8 --metadata-6a54-plus-689c --metadata-stream-b100-compress --helper-connect --direct-tagged-info --with-mfc --pcm-backend | rg 'metadata-6a54|min|metadata-689c|direct_get_tagged_info|post_connect_mfc|pcm_config|打开失败'; adb -s 70a91f89 logcat -d | rg 'gsl_graph_get_tags_with_module_info|Connect failed error|graph_open ret|graph_start ret'

Ran terminal command:  adb -s 70a91f89 logcat -c; adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --skip-rate-write --skip-connect --metadata-689c-full-kv --metadata-stream-b100-compress --inspect-only | rg 'metadata-689c|PCM100 metadata|PCM100 control|direct_get_tagged_info|inspect-only'; adb -s 70a91f89 logcat -d | rg 'gsl_graph_get_tags_with_module_info|Connect failed error|graph_open ret|graph_start ret'

窄链验证通过了：B100/AD 这组 payload 确实按我们预期写进去了，而且即使不 connect/open，后台也已经冒出了同一个 GKV 解析失败。这说明问题比 FE 打开更早。现在我读完整链结果，确认它是继续卡在 -5 还是退回 -19。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_uIAj3FOtOYb8LGAuz9wDCDGB__vscode-1773803651785/content.txt)

B100 特判也已经实测完了，结果还是同一个 -5。而且连 inspect-only 只写 689c payload 都能立刻触发同一条 GKV 失败，这说明缺口已经锁定在 metadata 内容本身，不是后面的 connect/open。现在我继续往上追 0x4b74 调用点的两个核心实参来源：`stream_kv` 和第二对 route value。

Ran terminal command:  llvm-objdump -d --start-address=0x48a0 --stop-address=0x4b20 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

Ran terminal command:  xxd -g 4 -s 0x1ae0 -l 64 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

Ran terminal command:  llvm-objdump -d '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin' | rg '\[sp, #0x54\]|\[sp, #0x60\]'

我已经抓到关键栈槽的写入点了，接下来只看 0x4520、0x47c8、0x48ac 这一段，能直接把 `route_value` 和 `stream_kv` 的来源钉死。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_qBqe9k6kBVdEBHfDwWXrsMjw__vscode-1773803651788/content.txt)

现在已经看到 0x689c 之前先跑了一次 0x6a54 helper。剩下关键就是更早那一段初始化：它把 `sp+0x54` 和 `sp+0x60` 设成什么。那两个值基本就是我们现在还没钉死的 route_value / stream_kv 输入。

Ran terminal command:  llvm-objdump -d --start-address=0x478c --stop-address=0x47f0 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

Ran terminal command:  llvm-objdump -d --start-address=0x6a54 --stop-address=0x6b30 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

现在最大的不确定量不是 stream tag，而是 0x689c 循环里那个 `w6` 数组元素，也就是真正的 route value 来源。最省时间的办法不是继续死抠栈，而是直接跑一次 vendor 路径，看它自己有没有把 `stream_kv / device_kv[%d]` 打到 logcat。

Searched for regex `tinyplay_ftm|stream_kv:|device_kv` (`**/docs/**`), 80 results

Searched for regex `tinyplay_ftm|stream_kv:|device_kv` (`**/*.md`), 120 results

Ran terminal command:  adb -s 70a91f89 shell ls /data/local/tmp | rg 'test440|wav|pcm'

文档里其实已经有一条很强的实证：当前成功的 tinyplay_ftm 路径打印的是 `a100000e / a2000001 / ac000002`，不是 B100。我现在直接在设备上复跑一次 vendor 成功链，把这条 runtime 事实重新钉死。

Ran terminal command:  adb -s 70a91f89 logcat -c; adb -s 70a91f89 shell 'setprop vendor.oplus.mm.ftm_spk 1; /odm/bin/tinyplay_ftm /data/local/tmp/test440_low.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY' >/dev/null 2>&1; adb -s 70a91f89 logcat -d | rg 'stream_kv:|device_kv\[|devicepp_kv\[|graph_open ret|graph_start ret|Playing sample|thread_result'

Ran terminal command:  adb -s 70a91f89 logcat -c; adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --skip-rate-write --skip-connect --metadata-689c-full-kv --inspect-only >/dev/null 2>&1; adb -s 70a91f89 logcat -d | rg 'gsl_graph_get_tags_with_module_info|Connect failed error'
Completed with input:  adb -s 70a91f89 logcat -c; adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --skip-rate-write --skip-connect --metadata-689c-full-kv --inspect-only >/dev/null 2>&1; adb -s 70a91f89 logcat -d | rg 'gsl_graph_get_tags_with_module_info|Connect failed error'

新信息已经很硬了：

- vendor 成功链再次确认，真实运行时还是 `stream_kv=a100000e device_kv=a2000001 devicepp_kv=ac000002`
- 默认 A100/AC 的 `inspect-only --metadata-689c-full-kv` 不会触发 service 侧 GKV 报错
- 但 B100/AD 的 `inspect-only` 会立刻触发 `acdb get tags from gkv failed with 19`

所以 B100 分支现在可以明确降级，它更像 helper 的另一条业务路径，不是当前 speaker 成功链。下一步我不再扩展 B100，而是把 0x6a54 的 A100/AC payload 结构拆出来，看看我们现在那个 “6a54(min)” 到底缺了哪些字。

Ran terminal command:  llvm-objdump -d --start-address=0x6b20 --stop-address=0x6d30 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

Ran terminal command:  xxd -g 4 -s 0x1140 -l 32 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

Ran terminal command:  xxd -g 1 -s 0x12a0 -l 64 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

0x6a54 已经给出一个很重要的事实：它的 A100 主路径根本不是我们现在的“1 对 stream + 一个 A400 尾巴”这种简化版。它至少还会根据另一个实参补一对 `0xAB000000` 的 kv。现在我要把那条日志字符串读出来，看看这个额外实参到底是什么语义。

Ran terminal command:  xxd -g 1 -s 0x1aa0 -l 96 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

Ran terminal command:  llvm-objdump -d '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin' | rg 'bl\s+0x6a54|bl\s+0x689c' -n

Ran terminal command:  llvm-objdump -d '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin' | rg '0xab000000|0xa4000000|0xb1000003'
Completed with input:  llvm-objdump -d '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin' | rg '0xab000000|0xa4000000|0xb1000003'

0x6a54 的 A100 主路径已经够清楚了，我准备把当前那个过于粗糙的 “6a54(min)” 修到更接近 vendor 实际形态：补上 `0xAB000000 / instance_kv=1` 这一对。

Generating patch (39 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
6a54 现在已经补上 instance kv。下一步直接重编并复跑当前最值钱的 A100/AC 主链，看 service 侧是否还卡在完全相同的 `-5`。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb -s 70a91f89 push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /data/local/tmp/pure_c_agm_probe

Ran terminal command:  adb -s 70a91f89 logcat -c; adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --rate-60f4-words --pre-setparam-63d8 --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend | rg 'metadata-6a54|min|metadata-689c|direct_get_tagged_info|post_connect_mfc|pcm_config|打开失败'; adb -s 70a91f89 logcat -d | rg 'gsl_graph_get_tags_with_module_info|Connect failed error|graph_open ret|graph_start ret'

Ran terminal command:  adb -s 70a91f89 logcat -c; adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --skip-rate-write --skip-connect --metadata-6a54-min --inspect-only >/dev/null 2>&1; adb -s 70a91f89 logcat -d | rg 'gsl_graph_get_tags_with_module_info|Connect failed error'
Completed with input:  adb -s 70a91f89 logcat -c; adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --skip-rate-write --skip-connect --metadata-6a54-min --inspect-only >/dev/null 2>&1; adb -s 70a91f89 logcat -d | rg 'gsl_graph_get_tags_with_module_info|Connect failed error'

修正后的 6a54 单独 inspect-only 没有提前触发 service 侧错误，这至少说明它不像 B100 那样是明显错误 payload。现在我读回完整主链结果，看这次有没有把 -5 推动。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_ZFyZHf6ndNugWYK20jiXGFjQ__vscode-1773803651807/content.txt)

前沿已经变了：这次不再出现 `acdb get tags from gkv failed with 19`，而是直接拿到了可读的 tagged-info、成功取到 MFC MIID，并且 `configure_mfc rc=0`。现在最值得做的是趁这个新前沿，快速试两条最便宜的补充动作：补上 `agm_session_aif_connect`，以及去掉 63d8 看它是不是已经变成冗余。

Ran terminal command:  adb -s 70a91f89 logcat -c; echo '=== with-session ==='; adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --with-session --skip-helper-prep --skip-initial-control --rate-60f4-words --pre-setparam-63d8 --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend | rg 'session_connect|metadata-6a54|min|metadata-689c|agm_mixer_get_miid|post_connect_mfc|打开失败'; adb -s 70a91f89 logcat -d | rg 'Connect failed error|graph_open ret|graph_start ret|gsl_graph_get_tags_with_module_info'; echo '=== no-63d8 ==='; adb -s 70a91f89 logcat -c; adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --rate-60f4-words --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend | rg 'metadata-6a54|min|metadata-689c|agm_mixer_get_miid|post_connect_mfc|打开失败'; adb -s 70a91f89 logcat -d | rg 'Connect failed error|graph_open ret|graph_start ret|gsl_graph_get_tags_with_module_info'

我已经把两条新分支都跑了。现在只读关键结果，不再重复刷整段日志。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_ieRduwUxl06UUJar3btClq5O__vscode-1773803651810/content.txt)

这两条低成本分支已经排掉了：

- `agm_session_aif_connect` 加不加都不改变最终 `-5`
- `63d8` 去掉也不改变最终 `-5`

现在还剩一个同样应该顺手排掉的变量：`rate ch fmt` 直写本身一直 `verify failed`。我直接跑一遍完全去掉 rate 写入的主链，看它是不是纯噪音。

Ran terminal command:  adb -s 70a91f89 logcat -c; adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --skip-rate-write --pre-setparam-63d8 --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend | rg 'metadata-6a54|min|metadata-689c|direct_get_tagged_info|post_connect_mfc|pcm_config|打开失败|rate ch fmt'; adb -s 70a91f89 logcat -d | rg 'Connect failed error|graph_open ret|graph_start ret|gsl_graph_get_tags_with_module_info'

我已经把 rate 写入这条变量也跑了。现在只取关键行，看它到底是必要前置还是纯噪音。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_jXry51W9lnM7JhFk9164tmRz__vscode-1773803651812/content.txt)

观测面还有一个明显错误：`direct_get_tagged_info` 现在已经能读到有效 entry，但解析条件还是旧的，所以误报失败。我把它修成按当前实测布局解析，这样后面就能直接拿到 `0xC0000019` 的 value。

Generating patch (10 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
解析条件已经修正。我只做一次最小复跑，确认它现在能直接报出 `0xC0000019` 的值，而不是继续误报失败。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb -s 70a91f89 push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /data/local/tmp/pure_c_agm_probe

Ran terminal command:  adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --skip-rate-write --pre-setparam-63d8 --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend | rg 'direct_get_tagged_info|post_connect_mfc|打开失败'
Completed with input:  adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --skip-rate-write --pre-setparam-63d8 --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend | rg 'direct_get_tagged_info|post_connect_mfc|打开失败'

Created memory file twrp_audio_pure_c_frontier_20260319_mfc_breakthrough.md

前沿和 repo memory 都已经更新好了。最后我只确认一件事：`direct_get_tagged_info` 现在是否已经从“误报失败”变成直接返回 MFC tag value。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_GC94in30VJE0q4LTJcSzRj2E__vscode-1773803651816/content.txt)

这次继续推进后，前沿已经实质前移了，但还没出声。

当前有效结果：

1. 我把 0x6a54 这段 metadata 从原来过于粗糙的占位写法，修成了更接近 tinyplay_ftm A100 主路径的形态。
2. 补完之后，纯 C 主链第一次出现了这组新信号：
   - 不再出现 `acdb get tags from gkv failed with 19`
   - `PCM100 getTaggedInfo` 能读到完整 entry 表
   - `agm_mixer_get_miid(tag=0xC0000019)` 成功
   - `configure_mfc rc=0` 成功
3. 我顺手把 `direct_get_tagged_info` 的解析也修了，现在它会正确返回：
   - `rc=0`
   - `tag=0xC0000019`
   - `value=0x1`

也就是说，当前纯 C 路径已经不是之前那个“连 tag/GKV 都起不来”的阶段了。现在已经能把图推进到 MFC 可配置，只是最终 `pcm_open` 仍然停在：

- `Unknown error -5`
- service 侧仍是 `Connect failed error:-5`

这轮排掉的分支：

1. `B100` 分支可以降级。
   - vendor 成功链再次确认，真实 runtime 仍然是：
   - `stream_kv=a100000e`
   - `device_kv=a2000001`
   - `instance_kv=1`
   - `devicepp_kv=ac000002`
   - 纯 C 的 `B100` 变体在 inspect-only 下就会触发错误，不是当前 speaker 主线。
2. `agm_session_aif_connect` 不是当前缺口。
   - 加上 `--with-session` 之后最终还是 `-5`
3. `63d8` 不是当前缺口。
   - 去掉 `pre-setparam-63d8` 之后最终还是 `-5`
4. `rate ch fmt` 手工直写现在可以降级。
   - 去掉 `--rate-60f4-words` 后，tagged-info、MIID、MFC 仍然都能起来
   - 最终仍然是 `-5`

这轮最重要的新判断：

- 之前的根因是 metadata 不够像 vendor
- 现在把 6a54 的 instance kv 补进去以后，GKV/MIID/MFC 这一层已经通了
- 剩下的 `-5` 更像是 graph 已经进入更后面的 connect/open 阶段缺口，而不是早期 kv 解析失败

我还把这次突破写进 repo memory 了，后面不用再回头重复试 B100、with-session、63d8、rate-write 这些低价值分支。

下一步最合理的是：

1. 直接对照 tinyplay_ftm 成功窗口，补抓更完整的 AGM 服务日志，看看当前 `Connect failed error:-5` 前一跳到底缺的是哪一个 connect/module。
2. 开始复刻 0x6628 之后那层 post-connect setParamTag payload，因为现在 MFC tag 已经起来了，这条线才真正进入可验证区。

Made changes.

User: 继续

GitHub Copilot: 我先做一轮干净对照：抓当前纯 C 新前沿和 vendor 成功链的 service 侧关键日志，目标是确认现在还差的是哪一步 connect/module。

Ran terminal command:  adb -s 70a91f89 logcat -c; adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --skip-rate-write --pre-setparam-63d8 --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend >/dev/null 2>&1; adb -s 70a91f89 logcat -d | rg 'graph_open|graph_start|Connect failed error|miid |tag c000|gsl_graph_get_tags_with_module_info|session_open_with_first_device|configure_mfc|MFC|c0000019|c0000004'

Ran terminal command:  adb -s 70a91f89 logcat -c; adb -s 70a91f89 shell 'setprop vendor.oplus.mm.ftm_spk 1; /odm/bin/tinyplay_ftm /data/local/tmp/test440_low.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY' >/dev/null 2>&1; adb -s 70a91f89 logcat -d | rg 'graph_open|graph_start|Connect failed error|miid |tag c000|gsl_graph_get_tags_with_module_info|session_open_with_first_device|configure_mfc|MFC|c0000019|c0000004'

Ran terminal command:  adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --skip-rate-write --pre-setparam-63d8 --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend | rg 'direct_get_tagged_info|post_connect_mfc|agm_mixer_get_miid 成功|configure_mfc rc|打开失败'
Completed with input:  adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --skip-rate-write --pre-setparam-63d8 --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend | rg 'direct_get_tagged_info|post_connect_mfc|agm_mixer_get_miid 成功|configure_mfc rc|打开失败'

对照已经很清楚了：vendor 成功链能走到 `graph_open ret 0 -> configure_* -> graph_start ret 0`，而纯 C 现在仍直接死在 `session_open_with_first_device ... Connect failed error:-5`，说明缺口还在 graph_open 前，而不是 MFC 后处理。下一步我直接拆 tinyplay_ftm 的前置 0x30 固定 payload helper。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_EoWgt6UfYN6FpZqWpnyXLaHO__vscode-1773803651821/content.txt)

Ran terminal command:  llvm-objdump -d --start-address=0x6468 --stop-address=0x65a0 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

Ran terminal command:  xxd -g 4 -s 0x1148 -l 24 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm.bin'

前沿又动了，而且是关键跃迁：这次纯 C 主链已经不是 `pcm_open -5`，而是直接 `打开成功`。我现在立刻把它切到 `play-after-open`，验证是否能稳定写入测试音，以及服务侧有没有真正 start。

Ran terminal command:  adb -s 70a91f89 logcat -c; adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --skip-rate-write --pre-setparam-63d8 --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend --play-after-open --play-seconds 5 | rg 'direct_get_tagged_info|post_connect_mfc|pcm_config|打开成功|write_test_tone|pcm_write|打开失败'; adb -s 70a91f89 logcat -d | rg 'graph_open|graph_start|Connect failed error|aw882xx|pcm_prepare|pcm_start|write done|write_test_tone|gsl_graph_get_tags_with_module_info'

Ran terminal command:  adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --skip-rate-write --pre-setparam-63d8 --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend | rg '打开成功|打开失败|post_connect_mfc|direct_get_tagged_info'
Completed with input:  adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --skip-rate-write --pre-setparam-63d8 --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend | rg '打开成功|打开失败|post_connect_mfc|direct_get_tagged_info'

Ran terminal command:  adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend | rg '打开成功|打开失败|post_connect_mfc|direct_get_tagged_info'
Completed with input:  adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend | rg '打开成功|打开失败|post_connect_mfc|direct_get_tagged_info'

我已经把“可复现 open”和“实际写音”都跑了。现在只读关键结果，确认是不是已经进入真正播放态。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_cu9EPCx6syBTulvAhSskmT8Z__vscode-1773803651825/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_HralbEcoWKNM2u0xmUQn68A9__vscode-1773803651826/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_5yAwr5sOhW5XRTq9aUmQ1oIZ__vscode-1773803651827/content.txt)

前沿已经从“打不开”变成“能 open 也能进 graph_open”，现在新的 blocker 是写流第 5 个 chunk 报 `Unknown error -131`。最值得先排的是 PCM 配置本身，所以我直接对比 `2ch/16bit` 和 `8ch/32bit` 两种打开形态。

Ran terminal command:  adb -s 70a91f89 logcat -c; adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --skip-rate-write --pre-setparam-63d8 --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --play-after-open --play-seconds 5 | rg 'pcm_config|打开成功|write_test_tone|pcm_write|打开失败'; adb -s 70a91f89 logcat -d | rg 'graph_open|graph_start|aw882xx|Connect failed error|gsl_graph_get_tags_with_module_info'

Ran terminal command:  adb -s 70a91f89 logcat -c; adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --skip-rate-write --pre-setparam-63d8 --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend --play-after-open --play-seconds 1 | rg 'pcm_config|打开成功|write_test_tone|pcm_write|打开失败'; adb -s 70a91f89 logcat -d | rg 'graph_open|graph_start|aw882xx|Connect failed error|gsl_graph_get_tags_with_module_info'

Ran terminal command:  adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --play-after-open --play-seconds 5 | rg 'pcm_config|打开成功|write_test_tone|pcm_write|打开失败'
Completed with input:  adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --play-after-open --play-seconds 5 | rg 'pcm_config|打开成功|write_test_tone|pcm_write|打开失败'

三组播放链都已经跑完。我现在只读关键结果，判断是不是应该把默认 PCM 配置切回 2ch/16bit。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_IZt3OxikGA1QGRx3dDpGMo8k__vscode-1773803651831/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_VxqG6CaaIGrD4IHRJJa2wJBI__vscode-1773803651832/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_jTZh092BcwPDCTEYX6sLvfg2__vscode-1773803651833/content.txt)

现在的新症状很聚焦：`graph_open ret 0` 已经有了，但始终看不到 `graph_start`，而 `pcm_write` 固定在第 5 个 chunk 报 `-131`。我先验证 tinyalsa 里有没有现成的 `pcm_prepare/pcm_start` 可直接调用，如果有就把它们接进 probe 做最小试验。

Ran terminal command:  nm -D /vendor/lib64/libtinyalsa.so 2>/dev/null | rg ' pcm_(prepare|start|drain|drop|stop|writei?)$'
Completed with input:  nm -D /vendor/lib64/libtinyalsa.so 2>/dev/null | rg ' pcm_(prepare|start|drain|drop|stop|writei?)$'

Ran terminal command:  adb -s 70a91f89 shell 'nm -D /vendor/lib64/libtinyalsa.so 2>/dev/null | grep pcm_'
Completed with input:  adb -s 70a91f89 shell 'nm -D /vendor/lib64/libtinyalsa.so 2>/dev/null | grep pcm_'

Ran terminal command:  adb -s 70a91f89 logcat -c; adb -s 70a91f89 shell /odm/bin/tinyplay_ftm /data/local/tmp/test440_low.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY >/dev/null 2>&1; adb -s 70a91f89 logcat -d | rg 'graph_open|graph_start|aw882xx_start|aw882xx_hw_params|thread_result|Playing sample'

Compacted conversationvendor 成功链已经确认了关键差异：它在 `graph_open ret 0` 后紧接着有 `graph_start ret 0`，而当前纯 C 路径没有。下一步我直接改 probe，加一个最小的显式 start 尝试，验证 `-131` 是不是因为流根本没被启动。

Ran terminal command:  rg --files /Volumes/Case-sensitive\ APFS/TWRP /Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery | rg 'pure_c_agm_probe\.c|build_pure_c_agm_probe\.sh'

Ran terminal command:  adb -s 70a91f89 shell 'toybox strings /vendor/lib64/libtinyalsa.so | grep -E "pcm_(start|prepare|drain|drop|stop)"'

Created 3 todos

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1-1), lines 1 to 260

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#261-261), lines 261 to 620

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#621-621), lines 621 to 1040

我已经确认设备侧 `libtinyalsa.so` 里确实有 `pcm_prepare` 和 `pcm_start` 字符串，方向成立。现在直接改 pure_c_agm_probe.c，把这两个符号按“可选能力”接进来，并在打开成功后做一次显式 prepare/start 试验。

Searched for regex `play-after-open|pcm_open|pcm_write|打开成功|开始写测试音` (`**/pure_c_agm_probe.c`), 16 results

Searched for regex `struct pcm_config|period_size|period_count|PCM_OUT` (`**/pure_c_agm_probe.c`), 18 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1780-1780), lines 1780 to 1885

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#2210-2210), lines 2210 to 2465

Searched for regex `static int run_probe\(|return run_probe\(` (`**/pure_c_agm_probe.c`), 2 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1936-1936), lines 1936 to 2010

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#2490-2490), lines 2490 to 2527

准备做的改动很小：不碰已有 metadata 主线，只给 `pcm_open` 后加一个“可选但默认启用”的显式 prepare/start。这样能直接验证 `graph_start` 缺失是不是根因，同时不扩大改动面。

Generating patch (76 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```


Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c), 24 problems found

编辑已经完成，接下来直接用现有脚本重编译并推到设备复测。重点看两件事：用户态是否打印 `pcm_start rc=0`，以及服务端是否终于出现 `graph_start ret 0`。

Ran terminal command:  ./build_pure_c_agm_probe.sh

Ran terminal command:  adb -s 70a91f89 push /Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /data/local/tmp/pure_c_agm_probe

Ran terminal command:  adb -s 70a91f89 logcat -c && adb -s 70a91f89 shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend --play-after-open --play-seconds 2' 2>&1 && adb -s 70a91f89 logcat -d | rg 'graph_open|graph_start|aw882xx_start|aw882xx_hw_params|PureCAgmProbe|pcm_start|pcm_prepare'

第一次验证跑完了，结果比较大。我先只读关键输出，确认 `pcm_prepare/pcm_start` 和 `graph_start` 是否真的出现，以及 `-131` 还在不在。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_3SWOZSfurTUMRODp3unAE0r7__vscode-1773803651857/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_3SWOZSfurTUMRODp3unAE0r7__vscode-1773803651857/content.txt#129-129), lines 129 to 129

根因已经被钉住了：不是 metadata，也不是 PCM 格式，而是流没有被显式启动。现在我补一条 repo 记忆，记录这次突破点，避免后面再在 `-131` 上兜圈子。

Read memory

Starting: *重编译并回归播放* (3/3)

Created memory file twrp_audio_pure_c_graph_start_fix_20260319.md

Ran terminal command:  adb -s 70a91f89 logcat -c && adb -s 70a91f89 shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend --play-after-open --play-seconds 5' 2>&1 | tail -n 20 && adb -s 70a91f89 logcat -d | rg 'graph_start|aw882xx_start_pa|thread_result|pcm_write|Unknown error -131'

Completed: *重编译并回归播放* (3/3)

问题已经推进到下一阶段了，当前纯 C 主线不再卡在写第 5 个 chunk 的 -131。

我做的改动很直接：
1. 在 pure C probe 里补上了 tinyalsa 的 pcm_prepare 和 pcm_start 动态加载
2. 在 pcm_open 成功后、进入 pcm_write 循环前，显式执行了一次 prepare 和 start
3. 保持原来的 metadata 和 MFC 主线不动，只修启动时序

验证结果：
1. 用户态现在明确打印
   - pcm_prepare rc=0
   - pcm_start rc=0
2. 服务端现在出现了之前缺失的
   - graph_start entry
   - graph_start ret 0
3. Awinic 路径进入了完整的 start_pa success
4. 5 秒测试音连续写完，结果是
   - 测试音写入完成 chunks=235
   - write_test_tone rc=0
5. 之前稳定复现的 Unknown error -131 没再出现

这说明根因不是前面的 metadata、PCM 格式或 63d8，而是流虽然 open 成功了，但之前没有被显式 start，所以一直停在 graph_open 之后的半启动状态。

当前结论：
1. 纯 C 路径已经能走到 graph_start
2. 连续写入已经稳定通过
3. 从日志看，播放链路已经真正进入功放启动阶段

我不能直接替你听设备是否已经出声，但从当前日志强度看，已经非常接近“实际出声”而不是“仅仅 open 成功”。

如果你要，我下一步可以继续做两件事里的一个：
1. 把现在这条成功主线收敛成最小可复现命令，删掉无关实验分支
2. 继续把测试音改成读 wav 文件，做成更接近最终可交付的纯 C 播放 demo

Made changes.

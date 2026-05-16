# 第7章：最小链路收缩与0x63d8-Style Pre-Open SetParam探索

User: 我搞不懂你改ffi有狗屁意义，让你用纯c先跑起来

GitHub Copilot: 你这个点对，我刚才那步虽然产出的是独立二进制，但源码仍挂在 video_player_ffi.c 上，方向不够干净。现在我直接切到“纯 C 独立 probe”，把和 FFI/播放器生命周期无关的部分拆成单独文件和单独构建入口。

Starting: *定位纯C最小依赖* (1/5)

我先只读“独立 probe 必需”的段落，目标是把运行时加载、mixer 写控件、helper-prep 这几块抽出来，不再依赖播放器/FFmpeg。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1-1), lines 1 to 260

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#780-780), lines 780 to 980

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#980-980), lines 980 to 1180

我已经把纯 C 需要的最小骨架找到了。现在再补两块：运行时环境/依赖预加载，以及 `helper-prep`/控件快照，这样就能单独生成一个完全不含播放器代码的新程序。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#480-480), lines 480 to 780

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1780-1780), lines 1780 to 2015

Ran terminal command:  cd "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery" && rg -n "prepare_agm_runtime_env|load_agm_runtime_deps|log_agm_pcm100_controls|log_pcm100_control|trace_agm_interface_controls|log_agm_interface_runtime_controls|prime_agm_helper_prep_for_direct_probe|prime_pcm100_streamdevice_split_kv|probe_agm_rate_ch_fmt_direct_write|force_agm_pcm100_connect|force_agm_pcm100_enum_state|read_u32_at|write_u32_at" video_player/video_player_ffi.c

还差最后一块：设备端音频路由预热。我把这段也带上，保证这个新程序是真正“纯 C 独立跑”，不是靠播放器残留环境。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#360-360), lines 360 to 480

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#2015-2015), lines 2015 to 2198

Ran terminal command:  rg -n "ensure_recovery_audio_route|setup_recovery_audio_route|vendor.oplus.mm.ftm_spk|QUAT_TDM_RX_0 Audio Mixer MultiMedia1|SpkrLeft PA Volume|RX_MACRO RX0 MUX" video_player/video_player_ffi.c

我现在不再碰 video_player_ffi.c 逻辑本体，直接新建一个独立源文件和独立构建脚本。这个二进制只保留 AGM probe 最小依赖，单文件、单入口、纯 C。

Generating patch (1097 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```


Generating patch (31 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/build_pure_c_agm_probe.sh)


```

```
纯 C 独立源文件和独立构建脚本已经落了。下一步我先本地编译，确保它不再拉进 FFmpeg/FFI 头。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c), 23 problems found

Ran terminal command:  chmod 755 "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/build_pure_c_agm_probe.sh" && cd "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player" && ./build_pure_c_agm_probe.sh

纯 C 二进制已经单独编出来了，大小只有 23K，和 FFI/FFmpeg 已经彻底切开。现在直接上机跑纯 C 路径。

Ran terminal command:  adb -s 70a91f89 push "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe" /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe

Ran terminal command:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe'
Completed with input:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe'

Ran terminal command:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-session --with-mfc'
Completed with input:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-session --with-mfc'

纯 C 两条路径都已经跑完。我现在只看三个点：有没有复现 `-5`，有没有复现 `MFC tag rc=-19 miid=0`，以及有没有和 FFI 版不同的行为。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_TIi8nE63YsNBIhOWQgtMRARQ__vscode-1773775026202/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_plfsHo5Xpi6LNwo8Kij9OAWn__vscode-1773775026203/content.txt)

纯 C 已经把结论钉死了：行为和之前一模一样，所以现在可以明确把“FFI 干扰”排除掉。我先把这个硬结论写进文档和仓库记忆。

Generating patch (47 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```


Inserted into memory file twrp_audio_helper_timing_delta_20260317.md

Inserted into memory file twrp_audio_pcm100_setparamtag.md

你这个纠正是对的，所以我已经把路径切干净了。

这次我没再靠 FFI 入口跑，而是做了一个真正独立的纯 C 二进制：

1. 单独新建了纯 C probe 源文件
2. 单独新建了纯 C 构建脚本
3. 本地编译通过，产物只有 23K
4. 已经推到设备上实跑了两种模式
   - 基线纯 C
   - 纯 C + session + mfc

实机结果很明确，而且和之前一模一样：

1. `helper-prep` 主链还是全 `rc=0`
2. `PCM100 control` 还是会切到 `TDM-LPAIF-RX-SECONDARY`
3. split metadata 还是 `rc=0`
4. `PCM100 connect` 还是 `rc=0`
5. `getTaggedInfo` 还是 `rc=-19`
6. `MFC tag` 还是 `miid=0`
7. 即使 `agm_session_aif_connect rc=0`，结果也没变
8. `pcm_open` 还是稳定卡在 `Unknown error -5`
9. plugin 日志还是 `Instance key is added` 和 `Failed to mixer_ctl_get_array`

所以现在可以把一件事彻底关掉：

1. 当前问题和 FFI 没关系
2. 纯 C 独立程序完整复现了同样的边界
3. 后面继续查，只需要盯 AGM/tinyalsa/driver 时序本身

这轮我也把文档和仓库记忆更新了。

接下来如果继续，我会只用这个纯 C probe 往下推，不再拿 FFI 那套当主战场。

Made changes.

User: 继续

GitHub Copilot: 我回到 `tinyplay_ftm` 的 pre-open 主链本身，先把 `0x5e1c / 0x629c / 0x6628 / 0x689c` 实际拼出来的控件名和 payload 语义钉死，结果会直接决定纯 C probe 下一刀改哪里。

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && llvm-objdump -h audio_manual/tinyplay_ftm_bin_20260318 | head -n 40

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && llvm-objdump -s --start-address=0x13d0 --stop-address=0x1a90 audio_manual/tinyplay_ftm_bin_20260318 | head -n 260

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && llvm-objdump -s --start-address=0x1100 --stop-address=0x1140 audio_manual/tinyplay_ftm_bin_20260318 | cat

地址映射已经对上了，`0x3ee/0x3f7` 这类偏移其实都在 `.rodata` 里。现在我直接读对应窗口，把 helper 关联的字符串翻出来。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_MD0fleYJV73JjFB84brGqKe6__vscode-1773775026210/content.txt#1-1), lines 1 to 120

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_m3deG3Y45fjv2rzvX8BuRJLd__vscode-1773775026211/content.txt#35-35), lines 35 to 120

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_m3deG3Y45fjv2rzvX8BuRJLd__vscode-1773775026211/content.txt#140-140), lines 140 to 210

刚才读到的是节头前半段，还没落到 `.rodata` 具体内容。我直接在转储结果里定位 `.rodata` 起点和 `0x13xx/0x15xx/0x17xx/0x19xx` 这些窗口。

Searched for regex `Contents of section \.rodata:| 13e0 | 13f0 | 1470 | 1560 | 17e0 | 1820 | 19d0 | 1a60 ` (`**//Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_m3deG3Y45fjv2rzvX8BuRJLd__vscode-1773775026211/content.txt`), no results

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && llvm-objdump -s --start-address=0x13e0 --stop-address=0x1a80 audio_manual/tinyplay_ftm_bin_20260318 | tail -n 120

我改成只转 `.rodata`，这样能直接把 helper 用到的控件名字符串抽出来，不再被其他节区淹没。

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && llvm-objdump -s --section=.rodata audio_manual/tinyplay_ftm_bin_20260318 | rg -n "13e0|13f0|1470|1560|17e0|1820|19d0|1a60|1ae0|1af0"

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && llvm-objdump -s --section=.rodata audio_manual/tinyplay_ftm_bin_20260318 | sed -n '1,140p'

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && llvm-objdump -s --section=.rodata audio_manual/tinyplay_ftm_bin_20260318 | sed -n '140,220p'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_hPclU5nhG7mXa0pI2AIUcAUR__vscode-1773775026218/content.txt#40-40), lines 40 to 130

现在 helper 名字已经钉住了：`5e1c=control`，`629c=connect/disconnect`，`689c=metadata`，`6628=setParam`。下一步我直接拆 `5f28(getTaggedInfo)`，看它在读数组前还做了什么前置动作。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_hPclU5nhG7mXa0pI2AIUcAUR__vscode-1773775026218/content.txt#1-1), lines 1 to 30

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2001-2001), lines 2001 to 2088

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2088-2088), lines 2088 to 2218

我继续只在纯 C 程序上动手，这一刀只去掉一个最可疑的污染项：`<intf> rate ch fmt` 的手工直写。它在我们路径里一直 `rc=-1`，但 tinyplay 那段 pre-open 主链并不这么干。

Generating patch (53 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
我先快速重编译，然后只跑“纯 C + session + mfc + skip-rate-write”这一条，直接看 `getTaggedInfo/MFC tag/pcm_open` 有没有前移。

Ran terminal command:  cd "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player" && ./build_pure_c_agm_probe.sh

Ran terminal command:  adb -s 70a91f89 push "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe" /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe && adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-session --with-mfc --skip-rate-write'
Completed with input:  adb -s 70a91f89 push "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe" /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe && adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-session --with-mfc --skip-rate-write'

新二进制已经跑完。我只抓对结论有用的几行：是否真的跳过了 rate 写入，`MFC tag` 有没有起来，`pcm_open` 有没有脱离 `-5`。

Ran terminal command:  rg -n "跳过手工 rate|session_connect rc|post-connect mfc miid|agm_mixer_get_miid 失败|post_connect_mfc rc|pure-c probe: 打开失败|Unknown error -5|Failed to mixer_ctl_get_array|Instance key is added" "/Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_PpQpL37W0I1gB5UEbCClOuQF__vscode-1773775026226/content.txt"

这轮 `skip-rate-write` 也跑完了，关键日志已经出来。我补读失败点前后 10 行，把结论钉死后继续推进。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_PpQpL37W0I1gB5UEbCClOuQF__vscode-1773775026226/content.txt#72-72), lines 72 to 128

新结果说明这条手工 rate 写入不是纯噪音，反而在把错误码从 `-19` 推到 `-5`。我继续只在纯 C 上做下一刀：把 rate 写入模式参数化，直接测更接近 vendor helper 的写法。

Generating patch (125 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
我只跑最有价值的一种：`--rate-5int`。它最接近 vendor helper 里那种多字段布局，比继续试普通 4-int 更值得。

Ran terminal command:  ./build_pure_c_agm_probe.sh

Ran terminal command:  adb -s 70a91f89 push "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe" /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe && adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-session --with-mfc --rate-5int'
Completed with input:  adb -s 70a91f89 push "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe" /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe && adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-session --with-mfc --rate-5int'

5-int 模式已经跑完。我还是只看边界：`rate write` 返回如何，`MFC tag` 是否有变化，最终 `pcm_open` 停在哪里。

Ran terminal command:  rg -n "5int rate write|session_connect rc|post-connect mfc miid|agm_mixer_get_miid 失败|post_connect_mfc rc|pure-c probe: 打开失败|Unknown error -5|Unknown error -19|Failed to mixer_ctl_get_array|Instance key is added" "/Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_LCnEsgvNWJngd4fgdZJlxn5x__vscode-1773775026231/content.txt"

再补一个不改代码的快测：把 rate 第三个 word 从 `32` 改成真正的 ALSA format 值，看看 `-5` 是不是只需要“某种 rate 写入”，还是已经开始对字段语义敏感。

Ran terminal command:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-session --with-mfc --rate-alsa-format'
Completed with input:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-session --with-mfc --rate-alsa-format'

ALSA-format 模式已经跑完。我只取关键边界，不再读整份日志。

Ran terminal command:  rg -n "write rc|session_connect rc|post-connect mfc miid|agm_mixer_get_miid 失败|post_connect_mfc rc|pure-c probe: 打开失败|Unknown error -5|Unknown error -19|Instance key is added|Failed to mixer_ctl_get_array" "/Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_jKrH3kPpKJWCzUCP40WSFpVG__vscode-1773775026233/content.txt"

现在有个更直接的纯 C 变量还没打掉：`pcm_open` 的前端参数。当前 probe 还是用 `2ch/16bit` 去开，我下一刀把它参数化，先试和 backend 对齐的 `8ch/32bit`。

Generating patch (48 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
我用最有意义的一组去试：`session + mfc + rate-alsa-format + pcm-backend`。这样只变 `pcm_open` 前端配置，不再引入额外时序差异。

Ran terminal command:  ./build_pure_c_agm_probe.sh

Ran terminal command:  adb -s 70a91f89 push "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe" /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe && adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-session --with-mfc --rate-alsa-format --pcm-backend'
Completed with input:  adb -s 70a91f89 push "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe" /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe && adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-session --with-mfc --rate-alsa-format --pcm-backend'

backend 对齐配置也跑完了。我只读 `pcm_config`、最终错误码和 `MFC tag`，看它是不是只是 FE 打开参数不对。

Ran terminal command:  rg -n "pcm_config|session_connect rc|post-connect mfc miid|agm_mixer_get_miid 失败|post_connect_mfc rc|pure-c probe: 打开失败|Unknown error -5|Unknown error -19|Instance key is added|Failed to mixer_ctl_get_array" "/Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_XZo9HHluYUdNOzF2xNtzBIoC__vscode-1773775026237/content.txt"

这两轮纯 C 新结果够硬，先按你的流程把文档和 repo memory 补上，再继续下一刀。核心结论是：手工 rate 写入不是污染项，反而是把错误从 `-19` 推到 `-5` 的必要条件；而前端 `pcm_open` 参数改成 backend 对齐并不能再往前走。

Generating patch (35 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```


Inserted into memory file twrp_audio_helper_timing_delta_20260317.md

Inserted into memory file twrp_audio_pcm100_setparamtag.md

Compacted conversation文档和 memory 已补齐。下一步我只在纯 C probe 里继续收缩变量，优先判断 `split metadata` 和 `PCM100 control/connect` 哪一步对 `-5` 真有贡献，避免再在无效分支上绕。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1-1), lines 1 to 260

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#261-261), lines 261 to 620

Searched for regex `run_probe|skip_rate|rate_mode|pcm_backend|split metadata|control rc|connect rc` (`**/pure_c_agm_probe.c`), 18 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#620-620), lines 620 to 980

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#980-980), lines 980 to 1178

我准备在纯 C probe 里加两个窄开关：一个跳过 `split metadata`，一个改用 `agmmixer helper connect` 而不是手写 `PCM100 connect`。这两个点都直接对应“哪些 pre-open/post-connect 动作真的在建 graph”，比继续猜 `pcm_open` 参数更接近根因。

Generating patch (94 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
我先把新纯 C probe 编出来并推到设备上，然后只跑两组对照：`--skip-split-metadata` 和 `--helper-connect`。如果这两组都不改边界，就可以把注意力从 connect/route metadata 继续前移。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh

Ran terminal command:  adb -s 70a91f89 shell true

Ran terminal command:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe' /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe && adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-session --with-mfc --skip-split-metadata'
Completed with input:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe' /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe && adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-session --with-mfc --skip-split-metadata'

第一组跑完了，我先读关键日志确认 `skip-split-metadata` 是把边界拉回去还是根本没影响，再决定第二组要不要继续追 `helper-connect`。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_K2ArmHKiB5YSWjtxUmNou4vR__vscode-1773775026250/content.txt)

`skip-split-metadata` 已经给出有效收缩：边界仍然是 `-5`，说明这条 `PCM100 metadata` 拆 KV 直写不是把系统推进到当前前沿的关键动作。接着跑 `helper-connect`，看 `PCM100 connect` 手写枚举是不是也只是表象。

Ran terminal command:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-session --with-mfc --helper-connect'
Completed with input:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-session --with-mfc --helper-connect'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_EmwSHhmNs3ndFacaVqQjoNcl__vscode-1773775026252/content.txt)

这两组对照已经把前沿再收了一圈：`split metadata` 不是关键动作，`helper connect` 也没有比手写 `PCM100 connect` 多建立出任何可见状态。也就是说，当前真正有推进作用的只剩 `helper-prep` 和那条虽然读不回但确实改变边界的 `rate ch fmt` 写入。

Generating patch (32 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```


Inserted into memory file twrp_audio_helper_timing_delta_20260317.md

Inserted into memory file twrp_audio_pcm100_setparamtag.md

我再补一刀最直接的对照：跳过 `helper-prep`。现在变量已经缩到只剩 `helper-prep` 和 `rate ch fmt` 两个可疑主动作，这一组能直接回答“是不是 `helper-prep` 本身在把 graph 从更早错误推进到 `-5`”。

Generating patch (56 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```


Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb -s 70a91f89 push './pure_c_agm_probe' /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe && adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-session --with-mfc --skip-helper-prep'
Completed with input:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb -s 70a91f89 push './pure_c_agm_probe' /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe && adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-session --with-mfc --skip-helper-prep'

这组结果最关键，我先读它。只要 `skip-helper-prep` 不是 `-5`，就能把“真正有效的推进动作”继续从两项缩成一项。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_FF4uE708ZL0iki2iCgVEUT5Q__vscode-1773775026258/content.txt)

`skip-helper-prep` 结果比预期还狠：没有 helper-prep 也还是 `-5`。而且 plugin 日志从 `Instance key is added + 2 次 Failed to mixer_ctl_get_array` 变成只剩 1 次 `Failed to mixer_ctl_get_array`，说明 helper-prep 确实在改状态，但它不是把边界推进到 `-5` 的必要条件。现在最值得再补一枪的是同时去掉 helper-prep 和 split metadata，看是不是只靠那条 `rate ch fmt` 写入就能维持 `-5`。

Ran terminal command:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-session --with-mfc --skip-helper-prep --skip-split-metadata'
Completed with input:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-session --with-mfc --skip-helper-prep --skip-split-metadata'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_vyvQQblmZlfIWamy8vysa2ns__vscode-1773775026260/content.txt)

我再把 session 和 MFC 也一起拿掉做最小链路验证。因为纯 C 最初无 session 的基线本来就能到 `-5`，现在把 helper-prep 和 split metadata 也剥掉后，如果还保持 `-5`，就基本可以把必要动作收缩到“control + rate 写入 + connect”这一组。

Ran terminal command:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --skip-helper-prep --skip-split-metadata'
Completed with input:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --skip-helper-prep --skip-split-metadata'

现在差最后一个关键变量：`connect` 本身。最小链路已经缩到 `control + rate 写入 + connect -> -5`，而 `skip-rate-write -> -19` 已经确定。再去掉 `connect`，就能判断是不是实际上只有 `rate 写入` 在起作用。

Generating patch (54 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```


Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb -s 70a91f89 push './pure_c_agm_probe' /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe && adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --skip-helper-prep --skip-split-metadata --skip-connect'
Completed with input:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb -s 70a91f89 push './pure_c_agm_probe' /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe && adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --skip-helper-prep --skip-split-metadata --skip-connect'

关键结论出来了：`connect` 不能去掉。最小链路里如果保留 `rate ch fmt` 但去掉 `connect`，错误会从 `-5` 退回 `-32`。这说明当前把边界推进到 `-5` 的最小必要集已经缩成两项：`control + rate 写入 + connect`，而 `helper-prep`、split metadata、session、MFC 都不是必要条件。

Generating patch (46 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```


Inserted into memory file twrp_audio_helper_timing_delta_20260317.md

Inserted into memory file twrp_audio_pcm100_setparamtag.md

当前前沿已经压到很窄了。

结论
1. 把边界推进到 pcm_open -5 的最小必要集合，已经收缩为三步：
   1. PCM100 control = TDM-LPAIF-RX-SECONDARY
   2. 手工写入 TDM-LPAIF-RX-SECONDARY rate ch fmt
   3. PCM100 connect = TDM-LPAIF-RX-SECONDARY
2. 这三步里少了 connect，会从 -5 退回到 -32。
3. 少了手工 rate 写入，会从 -5 退回到 -19。
4. 下面这些都已经证明不是推进到 -5 的必要条件：
   1. helper-prep
   2. PCM100 metadata 的 split-kv 直写
   3. agm_session_aif_connect
   4. post-connect MFC 探测/配置
   5. helper connect 替代手写 PCM100 connect
   6. FE 的 pcm_open 参数改成 backend 对齐 8ch/48000/S32_LE
5. 纯 C 最小链路下，MFC tag 仍然拿不到，getTaggedInfo 仍是空，声音还是没有出来。

这轮我实际做了什么
1. 继续只在纯 C probe 上动手，没有再碰 FFI 主线。
2. 给 probe 新增了几个开关用于收缩变量：
   1. skip-split-metadata
   2. helper-connect
   3. skip-helper-prep
   4. skip-connect
3. 重新编译并推到设备 70a91f89 上逐组实跑。
4. 同步把文档和 repo memory 更新到最新结论。

关键实验结果
1. skip-split-metadata 仍然是 -5
   1. split metadata 不是关键推进动作
2. helper-connect 仍然是 -5
   1. agmmixer 的 connect helper 没有比手写 PCM100 connect 多建立出有效状态
3. skip-helper-prep 仍然是 -5
   1. helper-prep 会改状态，但不是推进到 -5 的必要条件
4. skip-helper-prep + skip-split-metadata 仍然是 -5
   1. 说明最小必要集合进一步缩小
5. skip-helper-prep + skip-split-metadata + skip-connect 退回到 -32
   1. 说明 connect 仍然是必要条件
6. 之前已经确认 skip-rate-write 会退回到 -19
   1. 说明 rate 写入同样是必要条件

现在的判断
1. 当前主缺口已经不在 metadata、session、MFC 这些支线。
2. 真正需要继续对齐的，是 tinyplay_ftm 里 control、rate ch fmt、connect 这三步之间更细的参数语义和调用时序。
3. 换句话说，问题已经从“缺不缺更多 AGM helper”收缩成“这三步里 vendor 私有语义还差什么”。

下一步最自然的是：
1. 继续逆向并对齐 tinyplay_ftm 中 rate ch fmt 的真实字段布局，重点看第 3、4 个 word 以及是否还有前置 control 状态写入
2. 在纯 C probe 里枚举 control → rate → connect 的更细顺序变化，验证哪一种能把 -5 再往前推一步

Made changes.

User: 继续

GitHub Copilot: 我继续往最小链路里挖真实 vendor 语义，先回到 tinyplay_ftm 反汇编，专盯 control、rate ch fmt、connect 三步之间到底还做了什么。

Searched for regex `5e1c|60f4|629c|rate ch fmt|connect|control` (`**/audio_manual/**/tinyplay_ftm_objdump_20260318.txt`), 10 results

Read memory twrp_audio_pcm100_setparamtag.md

Read memory twrp_audio_helper_timing_delta_20260317.md

内存里的结论和现状一致。下一步直接读 0x60f4、0x629c 以及它们的调用点，把最小三步之间有没有隐藏参数或重复调用拆出来。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2108-2108), lines 2108 to 2235

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#520-520), lines 520 to 780

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2220-2220), lines 2220 to 2325

0x60f4 已经给出一个重要细节：它不是简单把 backend_bits 原样塞进去，而是在根据 media_config[0x58]/[0x5c] 映射第三、第四个值。我要再把 0x63d8 读出来，它紧跟在 0x60f4 后面，更像是最小三步里我们还没补齐的那段 vendor 私有写入。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2325-2325), lines 2325 to 2515

Searched for regex `1af8|82e|a5f|a65|9dc|3ee|5bd|561` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), 41 results

Searched for regex `rate ch fmt|setParam|metadata|disconnect|connect|control` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), no results

0x63d8 这段不像 connect，更像是在构造一个 0x30 字节的 setParam payload，然后写到某个以 interface 名称拼出来的控件上。我要把它后半段读完，把控件名和字段分支完全抠出来。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2515-2515), lines 2515 to 2710

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#1660-1660), lines 1660 to 1775

我先不猜空的，直接在仓库里搜这几个常量。要是 0xA5000000、0xA6000000、0xD2000000、0xA3000004/6 在别处有名字，就能把 0x63d8 那个 pre-open setParam payload 还原得更准。

Searched codebase for "A5000000 A6000000 D2000000 A3000004 A3000006 A2000001 B1000003 audio AGM setParam metadata", 27 results

Searched for regex `A5000000|A6000000|D2000000|A3000004|A3000006|A2000001|B1000003` (`**/*.{c,cc,cpp,h,hpp,txt,md,xml}`), 200 results

Searched for files matching `**/*agmmixer*`, 5 matches

常量搜索补了两点硬信息：
1. 0xA2000000→0xA2000001、0xA3000000→0xA3000004/6、0xB1000000→0xB1000003，确实都在 vendor 的 usecaseKvManager 里成对出现，不是我瞎猜。
2. 0x63d8 这段大概率就是一个 pre-open 的 PCM100 setParam helper，而且它正好夹在 rate helper 和后续链路之间。

下一步我不再泛分析，直接回收之前“setParam payload=32 可写”的最小经验，给纯 C probe 加一个贴近 0x63d8 的 pre-open setParam 试探，把它插到 rate 和 connect 之间上机看边界会不会动。

Searched for regex `payload=32|PCM100 setParam rc=0|setParam payload|setParam rc=0 payload=32|A2000000|A3000000|A5000000|A6000000` (`**/*.{c,md,txt}`), 163 results

Searched for text `setParam` (`**//Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c`), 22 results

Searched for regex `graph_kv key="0xA2000000"|graph_kv key="0xA3000000"|graph_kv key="0xB1000000"` (`**/usecaseKvManager.xml`), 60 results

仓库里已经有一版“能写进去但没推动边界”的最小 setParam 经验，我先把那段旧 payload 读出来，对照 0x63d8 的字段后再落到纯 C 里，避免重新瞎拼。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1600-1600), lines 1600 to 1665

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#1230-1230), lines 1230 to 1255

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/extracted_20260318_034751/vendor/vendor/etc/usecaseKvManager.xml#450-450), lines 450 to 545

我准备把 0x63d8 还原成一个可开关的 pre-open PCM100 setParam 试探：48-byte、12-word、按 speaker playback 路径先用 A2000000/A2000001、A5000000/rate、A6000000/bits、D2000000 这组字段。先做最保守的一版，看它能不能让最小链路越过当前 -5。

Generating patch (98 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
纯 C probe 已加上 0x63d8 风格的 pre-open setParam 试探开关。现在直接编译并跑最小链路加这个新动作，最能看出它是不是当前缺失的 vendor 私有语义。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb -s 70a91f89 push './pure_c_agm_probe' /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe && adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --skip-helper-prep --skip-split-metadata --pre-setparam-63d8'
Completed with input:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb -s 70a91f89 push './pure_c_agm_probe' /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe && adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --skip-helper-prep --skip-split-metadata --pre-setparam-63d8'

这版 0x63d8 风格 pre-open setParam 已经确认两件事：
1. `PCM100 setParam rc=0 payload=48`，控件层接受了这版更贴近反汇编的 48-byte 结构。
2. 但在最小链路里它没有把边界推过 `-5`，`getTaggedInfo` 也没有立起来。

我再补一个更有信息量的对照：把 helper-prep 保留下来，再叠这个 48-byte pre-open setParam，看它能不能在已经是 `-19` 的 helper-prep 态上再往前推。

Ran terminal command:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-mfc --pre-setparam-63d8 --skip-split-metadata'
Completed with input:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-mfc --pre-setparam-63d8 --skip-split-metadata'

我要只抓关键行，看 helper-prep 加 48-byte setParam 后，`getTaggedInfo`、`MFC tag` 和 `pcm_open` 有没有新变化。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_draSeEuuDkLjNvdkDdFTok9b__vscode-1773775026290/content.txt)

A200 speaker 版 48-byte setParam 只能证明 payload 形状可写，没把状态再往前推。0x63d8 本身是分支构造的，我下一步把另外两条分支也补出来：A3000004 和 A3000006，对应 usecaseKvManager 里真实存在的 graph_kv，再各跑一遍 helper-prep 场景。

Generating patch (88 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
我现在只做两次上机：A3000004 和 A3000006，各自放在 helper-prep 后、split metadata 关掉的场景里。结果要么把状态往前推，要么彻底排掉 0x63d8 这条 pre-open setParam 分支。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb -s 70a91f89 push './pure_c_agm_probe' /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe && adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-mfc --skip-split-metadata --pre-setparam-63d8-a3004' && adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-mfc --skip-split-metadata --pre-setparam-63d8-a3006'
Completed with input:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb -s 70a91f89 push './pure_c_agm_probe' /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe && adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-mfc --skip-split-metadata --pre-setparam-63d8-a3004' && adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-mfc --skip-split-metadata --pre-setparam-63d8-a3006'

我只读关键段，不铺整份日志。重点看两种 A300 分支各自的 `setParam rc`、`getTaggedInfo`、`MFC tag` 和 `pcm_open`。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_6UzkT2UXLiVa6uDXLe3DjVWh__vscode-1773775026293/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_6UzkT2UXLiVa6uDXLe3DjVWh__vscode-1773775026293/content.txt#136-136), lines 136 to 136

A3000004 已经跑出来了，结果和 A200 版一样：payload 被接受，但 `getTaggedInfo`

Made changes.

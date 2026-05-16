# 第6章：Pre-Open链逆向与MFC/Session叠加

User: 别二选一了。能不能只给一个选择，继续

GitHub Copilot: 我只走一条路：继续扩现有 direct-control，把 tinyplay_ftm 在 PCM100 metadata 之前的前置阶段补进去，不再分叉。先把现有 helper 和反汇编顺序再对一遍，然后直接加新 phase 上机。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#560-560), lines 560 to 770

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#1970-1970), lines 1970 to 2055

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2320-2320), lines 2320 to 2475

我已经把顺序对上了。下一步不再猜 payload 本体，而是把 tinyplay_ftm 之前那套前置阶段直接塞进现有 direct probe：先做 helper-prep，再跑 control/rate/metadata/connect，看能不能把写阶段的 -32 往后推。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1980-1980), lines 1980 to 2215

Searched for regex `set_agm_device_media_config|set_agm_audio_intf_metadata|set_agm_stream_metadata|set_agm_streamdevice_metadata|connect_agm_audio_intf_to_stream` (`**/video_player_ffi.c`), 31 results

我先把“只走 helper-prep 这一条路”的选择记进文档，然后直接补代码。接下来只新增一个 phase：先跑前置 helper，再接 direct-control，不再扩别的试验面。

Generating patch (23 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```


Generating patch (198 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
代码已经加上单一的新 phase 了。现在先做一轮编译确认，再只抓这个新 phase 的日志，看 helper-prep 有没有把任何控件从全零推开，或者把 -32 往后推。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c), 28 problems found

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_agm_demo.sh

编译通过，编辑器报错还是老的 include-path 噪音，不影响这次构建。现在直接部署并只盯新 phase，判断 helper-prep 前置态有没有把写控件或 pcm_open 往前推进。

Ran terminal command:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/agm_audio_demo' /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell /data/local/tmp/agm_audio_demo --probe-direct-controls
Completed with input:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/agm_audio_demo' /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell /data/local/tmp/agm_audio_demo --probe-direct-controls

输出已经出来了，我只抓新 phase 附近的关键行：helper-prep 各步 rc、控件读回、split metadata、connect 和最终 pcm_open。这样能最快给出这条单一路径有没有推进。

Searched for regex `helper-prep-rate-split-metadata-connect|AGM helper prep:|helper-prep after|split-kv metadata|PCM100 set enum: PCM100 connect|pcm_plug_open|Unknown error -32|打开成功` (`**//Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_hyLHctXVdvw5FCBPMVv641rR__vscode-1773775025989/content.txt`), no results

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_hyLHctXVdvw5FCBPMVv641rR__vscode-1773775025989/content.txt#330-330), lines 330 to 470

这轮结果里有个更关键的问题：helper-prep phase 不是一个干净起点，它复用了前面几轮已经被污染过的同一个 mixer。这个结论比日志本身更重要，所以我先修成“每个 phase 重新开一套 mixer”，再重跑 helper-prep，避免拿脏状态做判断。

Generating patch (28 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```


Generating patch (93 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
隔离已经补上了。现在重编并重跑同一个 probe，但这次只验证一点：干净 mixer 上的 helper-prep 首步 `set_agm_device_media_config` 还会不会直接 `-32`。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c), 28 problems found

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_agm_demo.sh

Ran terminal command:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/agm_audio_demo' /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell /data/local/tmp/agm_audio_demo --probe-direct-controls
Completed with input:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/agm_audio_demo' /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell /data/local/tmp/agm_audio_demo --probe-direct-controls

这次输出短很多，说明 phase 隔离已经生效。我现在只读 helper-prep 这一段，确认干净 mixer 上的首步结果。

Searched for regex `helper-prep-rate-split-metadata-connect|AGM helper prep:|helper_prep rc|split-kv metadata|PCM100 set enum: PCM100 connect|Unknown error -32|打开失败` (`**//Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_dSxyutRocHlO85WOwNCPGrcJ__vscode-1773775025996/content.txt`), no results

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_dSxyutRocHlO85WOwNCPGrcJ__vscode-1773775025996/content.txt)

phase 级 reopen 反而暴露了另一个更前面的实验问题：同一进程里第二次 `mixer_open(100)` 就开始被 plugin 侧 `-12` 拦住，所以 helper-prep 根本没真正跑到。我要把 probe 改成“可指定单一 phase 单独运行”，用全新进程只跑 helper-prep，这样才能拿到干净结论。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/audio_demo_main.c)

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.h)

Searched for regex `vp_debug_probe_tinyplay_direct_controls\(|vp_debug_probe_` (`**/video_player_ffi.*`), 7 results

我先把“单进程重复 mixer_open 会被 plugin -12 卡住，所以必须单 phase 单进程跑”的新边界记进文档，再改 CLI。这样后面每一步日志都能对得上。

Generating patch (25 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```


Generating patch (46 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.h), [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/audio_demo_main.c), [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```

```

```

```

```
现在已经能单 phase 单进程跑了。接下来不再跑整轮 probe，只跑 helper-prep 这一项，直接看它在真正干净进程里的首步和后续 rc。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c), [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.h), [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/audio_demo_main.c), 29 problems found

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_agm_demo.sh

Ran terminal command:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/agm_audio_demo' /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell /data/local/tmp/agm_audio_demo --probe-direct-controls-phase helper-prep-rate-split-metadata-connect
Completed with input:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/agm_audio_demo' /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell /data/local/tmp/agm_audio_demo --probe-direct-controls-phase helper-prep-rate-split-metadata-connect

这次终于是干净结果了。我只读这个单 phase 的完整输出，然后把结论和下一步最小动作收束掉。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_nx9pM3BatQTWo7Ku8q0p1Ssy__vscode-1773775026006/content.txt)

Read memory twrp_audio_component_gap.md

这次有实质推进了，不只是观察：在单 phase 干净进程里，helper-prep 把边界从 `-32` 推到了 `-5`。下一步我不再扩面，只补一个最小缺口：在 helper-prep 之后给 `PCM100 setParamTag` 下发 payload，看能不能把现在的 `Failed to mixer_ctl_get_array` 再往后推。

Generating patch (35 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```


Inserted into memory file twrp_audio_pcm100_setparamtag.md

文档和记忆已经同步。现在只补最小一刀：在 helper-prep 内部、pre-connect MIID 查询之前写一次 `PCM100 setParamTag`，不碰别的 payload。

Generating patch (64 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
改动已经落下去了。现在还是同一套单 phase 单进程流程，只看三件事：`setParamTag` 是否被接受、`getTaggedInfo/miid` 是否变化、`pcm_open` 是否继续从 `-5` 往后推。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c), 28 problems found

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_agm_demo.sh

Ran terminal command:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/agm_audio_demo' /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell /data/local/tmp/agm_audio_demo --probe-direct-controls-phase helper-prep-rate-split-metadata-connect
Completed with input:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/agm_audio_demo' /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell /data/local/tmp/agm_audio_demo --probe-direct-controls-phase helper-prep-rate-split-metadata-connect

结果回来了。我只读这一个 phase 的输出，然后把这次新增 setParamTag 的真实作用锁死。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_bqoFEOLx9Pmk1DoSOGhbtv5U__vscode-1773775026014/content.txt)

Read memory twrp_audio_true_tinyplay_probe.md

这次又推进了一步：`setParamTag` 的裸 16 字节写法本身被控件层拒绝了，`rc=-22`，但 helper-prep 主线仍保持在 `pcm_open -5`，而且上次那条 `Failed to mixer_ctl_get_array` 日志消失了。下一刀我还是只补最小闭环，把 `setParam` 也接上去，和 `setParamTag` 组成一对看 plugin 路径会不会再前进一步。

Generating patch (28 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```
文档已经补上。我现在只做一个配套动作：在 helper-prep 里把最小 `setParam` 和 `setParamTag` 配成对，不改别的顺序。

Generating patch (90 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
改完了，继续按同一个单 phase 单进程流程验证。重点只看两个新点：`PCM100 setParam` 是否接受，以及 `pcm_open -5` 有没有变化。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c), 28 problems found

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_agm_demo.sh

Ran terminal command:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/agm_audio_demo' /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell /data/local/tmp/agm_audio_demo --probe-direct-controls-phase helper-prep-rate-split-metadata-connect
Completed with input:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/agm_audio_demo' /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell /data/local/tmp/agm_audio_demo --probe-direct-controls-phase helper-prep-rate-split-metadata-connect

我继续只读这一段单 phase 结果，然后把这轮闭环收束出来。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_p9DqmCelc8fnDROPvw9ir0uu__vscode-1773775026021/content.txt)

这轮没有新增信息点，因为 `setParamTag rc=-22` 把 helper-prep 提前截断了，`setParam` 根本没真正跑到。我要把这两个写入改成“都执行并分别记日志”，不再让 `setParamTag` 先把实验短路掉。

Generating patch (39 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
现在这两个控件都会真实跑到。我继续按同一条单 phase 路径复测，重点是把 `PCM100 setParam` 的实际 rc 拿出来。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_agm_demo.sh
Completed with input:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_agm_demo.sh

Ran terminal command:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/agm_audio_demo' /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell /data/local/tmp/agm_audio_demo --probe-direct-controls-phase helper-prep-rate-split-metadata-connect
Completed with input:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/agm_audio_demo' /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell /data/local/tmp/agm_audio_demo --probe-direct-controls-phase helper-prep-rate-split-metadata-connect

编译没过，是我把状态变量落错作用域了。先把这个小错误修掉，再继续同一条测试，不换方向。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1688-1688), lines 1688 to 1795

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1618-1618), lines 1618 to 1687

Generating patch (9 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
编译错误已经修正。继续按同一条单 phase 流程把 `setParam` 的真实 rc 跑出来。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_agm_demo.sh

Ran terminal command:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/agm_audio_demo' /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell /data/local/tmp/agm_audio_demo --probe-direct-controls-phase helper-prep-rate-split-metadata-connect
Completed with input:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/agm_audio_demo' /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell /data/local/tmp/agm_audio_demo --probe-direct-controls-phase helper-prep-rate-split-metadata-connect

这次应该有结论了。我只读 helper-prep phase 关键段，然后把当前真正有效的前沿锁定。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_ESd0tAC5Lit9GxLbnH0UhUmV__vscode-1773775026030/content.txt#90-90), lines 90 to 177

这轮已经把真正的缺口钉得更准了：`setParam` 本身能写进去，`setParamTag` 这版格式不行，所以我现在不再改代码，而是反查 `tinyplay_ftm` 里到底是谁在写 `setParamTag`、写多大。先把这个长度和形状摸出来，再落回代码，不继续盲试。

Searched for text `setParamTag|Failed to mixer_ctl_get_array|getTaggedInfo|mixer_ctl_set_array@plt` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), 8 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#1840-1840), lines 1840 to 2015

Ran terminal command:  strings -a '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm_bin_20260318' | rg 'setParamTag|getTaggedInfo|Failed to mixer_ctl_get_array|metadata|setParam'

我再做一小步定向逆向，不盲改：把 `tinyplay_ftm` 里那段 16-byte helper 用到的 rodata 常量直接 dump 出来。这样如果要补下一版 `setParamTag`，就不是拍脑袋。

Ran terminal command:  llvm-objdump -s --start-address=0x1120 --stop-address=0x1160 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm_bin_20260318'

Ran terminal command:  llvm-objdump -s --start-address=0x1470 --stop-address=0x1490 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm_bin_20260318'

输出被 objdump 全量头吃掉了，我直接只读目标地址附近的几行，把常量值拿出来。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_woCxLWgKR7Y61VJh8WiJDZ8M__vscode-1773775026035/content.txt#1-1), lines 1 to 120

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_vG1yC2J3PjGLueUDNJHZaBBC__vscode-1773775026036/content.txt#1-1), lines 1 to 120

这轮已经把 `setParam` 和 `setParamTag` 分开坐实了，我先把结论补文档和仓库记忆，避免下一步又重复试。

Generating patch (31 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```


Inserted into memory file twrp_audio_pcm100_setparamtag.md

继续做完了一轮，前沿已经压得很窄了。

这次实际完成的事：

1. 把 direct-control 改成支持单 phase 单独运行，避免多 phase 互相污染。
2. 证明 helper-prep 这条路是有效的。
3. 在单 phase 干净进程里，把 helper-prep、split metadata、connect、setParamTag、setParam 都分别上机验证了。
4. 文档和仓库记忆都已同步更新。

当前已经坐实的结论：

1. helper-prep 确实把边界从 `pcm_open -32` 推到了 `pcm_open -5`。
2. 下面这些已经能被控件层接受：
   - `set_agm_device_media_config rc=0`
   - `set_agm_audio_intf_metadata rc=0`
   - `set_agm_stream_metadata rc=0`
   - `set_agm_streamdevice_metadata rc=0`
   - `PCM100 metadata rc=0`
   - `PCM100 connect rc=0`
   - `PCM100 setParam rc=0`
3. 现在唯一持续失败的关键点是：
   - `PCM100 setParamTag rc=-22`
4. 同时 `getTaggedInfo` 和 `agm_mixer_get_miid` 还是起不来：
   - `getTaggedInfo rc=-19`
   - `miid=0`
5. plugin 侧现在稳定停在更靠后的位置：
   - `Instance key is added`
   - `Failed to mixer_ctl_get_array`
   - 最终 `pcm_open` 还是 `Unknown error -5`

这意味着根因已经进一步收敛成一句话：

不是 helper-prep 没用，不是 metadata/connect/setParam 不通，当前最像单点缺口的就是 `PCM100 setParamTag` 的 payload 形状不对。

我下一步只会继续这一条，不再扩散：
直接照着 `tinyplay_ftm` 那段 16-byte helper 去还原 `setParamTag` 的固定头和最后一个 word 来源。现在不该再花时间碰已经通过的 `setParam`、`metadata`、`connect`。

Made changes.

User: 继续

GitHub Copilot: 我继续只追 `setParamTag` 这一处，不再碰别的控件。先把 `tinyplay_ftm` 里 16-byte helper 用到的 rodata 常量和最后一个 word 来源映射出来，目标是得到一个可下发的新 payload 形状。

Ran terminal command:  readelf -S '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm_bin_20260318' | rg '\.rodata|\.data|\.text'
Completed with input:  readelf -S '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm_bin_20260318' | rg '\.rodata|\.data|\.text'

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#1860-1860), lines 1860 to 1945

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#1998-1998), lines 1998 to 2068

我已经把 `setParamTag` helper 的调用骨架抠出来了：它不是纯 `tag+0+0+0`，最后一个 word 很可能来自 backend struct 的 `+0x5c`。现在再补一个只读批次，把 rodata 常量值本身和相关字符串地址对出来，目标是拿到 16-byte 四个 word 的完整候选。

Ran terminal command:  command -v llvm-readelf && llvm-readelf -S '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm_bin_20260318' | rg '\.rodata|\.text|\.data'
Completed with input:  command -v llvm-readelf && llvm-readelf -S '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm_bin_20260318' | rg '\.rodata|\.text|\.data'

Ran terminal command:  strings -t x '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm_bin_20260318' | rg 'setParamTag|getTaggedInfo|USB|TDM-LPAIF|PCM%d|Failed to mixer_ctl_get_array'

字符串偏移已经对上了：`setParamTag` 在 `0x147b`，`getTaggedInfo` 在 `0x17e5`。我再读二进制本体的几个固定偏移，直接把 `0x1120` 常量和 `0x1561` 那个 substring 拿出来。

Ran terminal command:  xxd -g 4 -s 0x1120 -l 0x20 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm_bin_20260318'

Ran terminal command:  xxd -g 1 -s 0x1550 -l 0x40 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm_bin_20260318'

Ran terminal command:  llvm-objdump -h '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm_bin_20260318' | rg '\.rodata|\.text|\.data'

我已经拿到 `setParamTag` helper 的关键固定头了：前 8 字节不是自定义 tag，而是常量 `[0xc0000040, 0x1]`，第三个 word 也是固定的 `0xe0000000`。我现在只把 `setParamTag` 改成这版 16-byte 结构，再单 phase 重跑，看它能不能从 `-22` 变成被控件接受。

Generating patch (43 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
这版改动只动了 `setParamTag` 的 16-byte 结构，其他路径不变。现在直接编译并单 phase 复测，只看它是不是还 `-22`、MIID 有没有变化、`pcm_open -5` 有没有推进。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_agm_demo.sh

Ran terminal command:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/agm_audio_demo' /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell /data/local/tmp/agm_audio_demo --probe-direct-controls-phase helper-prep-rate-split-metadata-connect
Completed with input:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/agm_audio_demo' /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell /data/local/tmp/agm_audio_demo --probe-direct-controls-phase helper-prep-rate-split-metadata-connect

结果已经回来了，我只看 `setParamTag`、`setParam`、MIID 和最终 `pcm_open` 这几行，确认这次固定头是不是对上了。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_aQ6QNuk15QO4am2v5UgBUY0a__vscode-1773775026051/content.txt#88-88), lines 88 to 177

固定头已经验证过了，`setParamTag` 还是 `-22`，所以问题不在前 3 个 word。下一步不盲改第 4 个 word，我先把 `getTaggedInfo` helper 的返回语义读完整，确认 `tinyplay_ftm` 什么时候才会真正去写 `setParamTag`。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2068-2068), lines 2068 to 2218

Ran terminal command:  xxd -g 4 -s 0x1ae0 -l 0x80 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm_bin_20260318'

Ran terminal command:  strings -t x '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm_bin_20260318' | awk '$1 >= "17d0" && $1 <= "1800"'

我还差一块上下文才能把 `setParamTag` 完全闭环：`5ca4` 那个 helper 的寄存器绑定。现在补读它的函数头，目标是确认 `w21` 到底是不是 tag，还是别的索引。确认这一点后，才能正确决定第 4 个 word 该怎么填。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#1790-1790), lines 1790 to 1875

Ran terminal command:  xxd -g 4 -s 0x1af8 -l 0x40 '/Volumes/Case-sensitive APFS/TWRP/audio_manual/tinyplay_ftm_bin_20260318'

我已经把 `5c40` 的寄存器绑定位出来了：我们当前这条 `TDM-LPAIF` 路径不是 `VIRT-` 分支，`setParamTag` 的第 4 个 word 更像来自 `0x1ae0` 那个小表，而不是 backend format。先不扩散，我只把第 4 个 word 从 `0xffffffff` 改成表里的最小候选 `0x0`，再单 phase 复测一次。

Generating patch (9 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
这次只变了 `setParamTag` 的最后一个 word。现在直接编译并单 phase 重跑，看 `-22` 是否松动。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_agm_demo.sh

Ran terminal command:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/agm_audio_demo' /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell /data/local/tmp/agm_audio_demo --probe-direct-controls-phase helper-prep-rate-split-metadata-connect
Completed with input:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/agm_audio_demo' /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell /data/local/tmp/agm_audio_demo --probe-direct-controls-phase helper-prep-rate-split-metadata-connect

我只看新改的那一行和最终 `pcm_open`，确认这个候选有没有价值。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_FGop3bzTglYUZjRU3tPqgmWT__vscode-1773775026060/content.txt#88-88), lines 88 to 177

我先不再改代码了，这轮把 `setParamTag` 的两个候选都排掉了。下一步只做定向逆向：看主流程到底是怎么调用 `5c40(setParamTag helper)` 的，确认第 5 个参数传的是 `0` 还是 `1`，以及它在主流程里是不是根本会被跳过。

Searched for regex `bl\s+0x5c40|<\.text\+0x1c40>|0x5c40` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), 2 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#1500-1500), lines 1500 to 1785

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2950-2950), lines 2950 to 3085

我已经确认 `5c40` 的第 5 个参数不是 tag，而是一个小模式值，所以我们刚才改第 4 个 word 的方向是对的。现在补读唯一的调用点 `0x4d00`，把这个模式值和调用前置条件锁死。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#800-800), lines 800 to 875

我把调用点也抠出来了：`5c40` 的第 5 个参数来自当前 backend 记录的 `+0x54` 字段，和我们这条 `48k/8ch/32bit` 路径高度像是“8ch 对应的表项索引”。按 `0x1ae0` 那张小表，`8` 对应的候选值是 `2`。我再只试这一个更像主流程的第 4 个 word。

Generating patch (9 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
这次还是只改了一个字。直接编译并单 phase 验证 `w3=2` 这一版。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_agm_demo.sh

Ran terminal command:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/agm_audio_demo' /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell /data/local/tmp/agm_audio_demo --probe-direct-controls-phase helper-prep-rate-split-metadata-connect
Completed with input:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/agm_audio_demo' /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell /data/local/tmp/agm_audio_demo --probe-direct-controls-phase helper-prep-rate-split-metadata-connect

我只读 `setParamTag` 那一段和最终结果，确认这条候选是否还有价值。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_QuuHSKulEs9wJ4uBid7ei12a__vscode-1773775026068/content.txt#88-88), lines 88 to 177

我刚把唯一调用点看到了，结论很关键：`5c40(setParamTag helper)` 是在 `pcm_open` 成功之后才跑的，不是 pre-open 链。也就是说我们这几轮把 `setParamTag` 强塞进 helper-prep，本身顺序就是错的。我先把这条纠偏记进文档，然后把 pre-open phase 里的 `setParamTag/setParam` 去掉，避免继续用错误顺序污染判断。

Generating patch (24 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```


Inserted into memory file twrp_audio_pcm100_setparamtag.md

文档和记忆都改完了。现在我把 pre-open phase 里的错误顺序去掉，再重跑一次，拿到一个更干净的 `pcm_open -5` 基线，后面就专心回到真正的 pre-open helper。

Generating patch (35 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
现在 helper-prep 已经恢复成更接近真实 pre-open 顺序。最后再跑一遍单 phase，把这条纠偏后的干净基线拿下来。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_agm_demo.sh

Ran terminal command:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/agm_audio_demo' /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell /data/local/tmp/agm_audio_demo --probe-direct-controls-phase helper-prep-rate-split-metadata-connect
Completed with input:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/agm_audio_demo' /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell /data/local/tmp/agm_audio_demo --probe-direct-controls-phase helper-prep-rate-split-metadata-connect

我只读关键段确认纠偏后的基线，然后就把这轮推进收束给你。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_SZrSm9z3tF8q6ZnWDp0njkoP__vscode-1773775026074/content.txt#60-60), lines 60 to 149

Compacted conversation这轮结果已经明确了：去掉误加的 pre-open setParamTag/setParam 之后，干净基线仍然是 `helper-prep` 把失败点稳定推进到 `pcm_open -> -5`。我先把这个硬结论写回文档和仓库记忆，再继续追真正还缺的 pre-open 链。

Starting: *记录纠偏后 -5 基线* (1/4)

Searched for regex `13\.68|13\.67|13\.66` (`**/docs/TWRP音频手动Bring-up.md`), 4 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#1248-1248), lines 1248 to 1288

Read memory twrp_audio_pcm100_setparamtag.md

文档尾部我再核一下结构，避免把新结论写到错位置；然后把 repo memory 一并修正成“`setParamTag` 已降级为 post-open 事实，不再是 pre-open 首要缺口”。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#1288-1288), lines 1288 to 1328

Read memory twrp_audio_helper_timing_delta_20260317.md

基线已经坐实。我现在不再碰 post-open 控件，直接回到 `pcm_open` 之前的调用链，确认 `tinyplay_ftm` 在 open 前到底还做了哪些 helper。

Searched for regex `4c8c|pcm_open@plt|5c40|5e1c|5f28` (`**/tinyplay_ftm_objdump_20260318.txt`), 13 results

Searched for files matching `**/tinyplay_ftm_objdump_20260318.txt`, 1 match

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#730-730), lines 730 to 835

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#835-835), lines 835 to 930

Searched for regex `000000000000629c|0000000000006628|000000000000689c|00000000000058d8|0000000000005974` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), no results

Searched for regex `PCM100 connect|getTaggedInfo|setParamTag|metadata|connect|disconnect` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), no results

Searched for regex `000000000000629c|0000000000006628|000000000000689c|00000000000058d8|0000000000005974` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), no results

Searched for regex `setParamTag|getTaggedInfo|PCM100|connect|metadata` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), no results

我在反汇编里直接追 `0x629c / 0x6628 / 0x689c / 0x58d8 / 0x5974` 这些 pre-open helper，本轮先拿到它们各自的语义，再决定要不要落代码。

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && rg -n "^000000000000(629c|6628|689c|58d8|5974)" audio_manual/tinyplay_ftm_objdump_20260318.txt
Completed with input:  cd "/Volumes/Case-sensitive APFS/TWRP" && rg -n "^000000000000(629c|6628|689c|58d8|5974)" audio_manual/tinyplay_ftm_objdump_20260318.txt

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && for a in 629c 6628 689c 58d8 5974; do rg -n "^000000000000${a}" audio_manual/tinyplay_ftm_objdump_20260318.txt; done
Completed with input:  cd "/Volumes/Case-sensitive APFS/TWRP" && for a in 629c 6628 689c 58d8 5974; do rg -n "^000000000000${a}" audio_manual/tinyplay_ftm_objdump_20260318.txt; done

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && for a in 629c 6628 689c 58d8 5974; do rg -n "${a}:" audio_manual/tinyplay_ftm_objdump_20260318.txt; done

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#1597-1597), lines 1597 to 1688

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2222-2222), lines 2222 to 2298

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2449-2449), lines 2449 to 2528

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2606-2606), lines 2606 to 2688

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2688-2688), lines 2688 to 2748

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && rg -n "set_agm_device_media_config|set_agm_audio_intf_metadata|set_agm_stream_metadata|set_agm_streamdevice_metadata|connect_agm_audio_intf_to_stream|agm_mixer_get_miid" aurora_recovery/native -g '*.[ch]'
Completed with input:  cd "/Volumes/Case-sensitive APFS/TWRP" && rg -n "set_agm_device_media_config|set_agm_audio_intf_metadata|set_agm_stream_metadata|set_agm_streamdevice_metadata|connect_agm_audio_intf_to_stream|agm_mixer_get_miid" aurora_recovery/native -g '*.[ch]'

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && rg -n "set_agm_device_media_config|set_agm_audio_intf_metadata|set_agm_stream_metadata|set_agm_streamdevice_metadata|connect_agm_audio_intf_to_stream|agm_mixer_get_miid"

Searched for files matching `**/video_player_ffi.c`, no matches

Searched for files matching `**/audio_demo_main.c`, no matches

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && rg -n "vp_debug_probe_tinyplay_direct_controls_phase|prime_agm_helper_prep_for_direct_probe|set_agm_streamdevice_metadata"

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/aurora_recovery)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/flutter-embedded-linux)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/aurora_recovery/native)

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && rg -n "vp_debug_probe_tinyplay_direct_controls_phase|prime_agm_helper_prep_for_direct_probe|set_agm_streamdevice_metadata" aurora_recovery/native
Completed with input:  cd "/Volumes/Case-sensitive APFS/TWRP" && rg -n "vp_debug_probe_tinyplay_direct_controls_phase|prime_agm_helper_prep_for_direct_probe|set_agm_streamdevice_metadata" aurora_recovery/native

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && rg --files | rg "video_player_ffi\.c|audio_demo_main\.c|video_player_ffi\.h|build_agm_demo\.sh"
Completed with input:  cd "/Volumes/Case-sensitive APFS/TWRP" && rg --files | rg "video_player_ffi\.c|audio_demo_main\.c|video_player_ffi\.h|build_agm_demo\.sh"

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && rg --files | rg "agm_audio_demo|video_player|audio_demo|agm_demo|build_so\.sh"

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && find . -name video_player_ffi.c -o -name audio_demo_main.c -o -name video_player_ffi.h -o -name build_agm_demo.sh

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && rg -n "debug probe direct controls|helper-prep-rate-split-metadata-connect|PCM100 split-kv metadata|AGM helper prep"

我把 `pcm_open` 前的关键 helper 串起来了：`689c -> 629c -> 5f28(tag=0xc0000019) -> 6628`，其中 `5f28/6628` 很像 connect 后的 MIID 读取与 MFC 配置。接下来我直接拆 `5e1c` 和相关字符串，判断 `689c/629c` 各自到底对应现有哪一步。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#1934-1934), lines 1934 to 2008

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && strings -a -t x audio_manual/tinyplay_ftm_bin_20260318 | rg "VIRT-|connect|disconnect|control|metadata|rate ch fmt|getTaggedInfo|setParamTag|setParam"

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && rg -n "bl\s+0x6a54|bl\s+0x689c|bl\s+0x6628|bl\s+0x629c|bl\s+0x5974|bl\s+0x58d8" audio_manual/tinyplay_ftm_objdump_20260318.txt

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#540-540), lines 540 to 610

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#955-955), lines 955 to 990

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2748-2748), lines 2748 to 2860

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2860-2860), lines 2860 to 2928

硬结论已经够支撑下一步了：`setParamTag` 退场后，真正值得追的是 `connect` 之后、`pcm_open` 之前那条 `getTaggedInfo(tag=0xc0000019) -> 6628` 链。先把这个判断落到文档/记忆里，再看当前源码树是否还在工作区里。

Read changed files in [](file:///Volumes/Case-sensitive%20APFS/TWRP)

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && find . -name '*.c' -o -name '*.h' | rg "video_player|audio_demo|agm|ffi" | head -n 80

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_BXY4D7YXfFyQLnQiGy9qd0wS__vscode-1773775026120/content.txt)

我先只做最小文档修正，不碰无关段落：补一节“纠偏后单 phase 干净复跑结果”，把下一条单一路径固定成 `connect` 之后的 `getTaggedInfo(tag=0xC0000019) -> 0x6628`。

Generating patch (29 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```


Updated memory file twrp_audio_pcm100_setparamtag.md

Inserted into memory file twrp_audio_helper_timing_delta_20260317.md

文档和记忆已对齐。最后再把 `0x6628` 本体看完整，确认它更像 `configure_mfc` 还是别的 pre-open payload helper，这样下一轮代码改动就不会再乱试。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2528-2528), lines 2528 to 2605

新的硬结论出来了：`0x6628` 不是泛化 payload helper，它就是 pre-open 的真实 `setParam` helper；也就是说这轮不是把 `setParam` 整体踢出 pre-open，而是要把“错误顺序的最小假 payload”换成“connect 后 + `getTaggedInfo(tag=0xC0000019)` 后的真实 `setParam`”。我把这点也补进文档和记忆。

Generating patch (13 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```


Updated memory file twrp_audio_pcm100_setparamtag.md

Updated memory file twrp_audio_helper_timing_delta_20260317.md

Completed: *记录纠偏后 -5 基线* (1/4)

本轮把基线和下一条主线重新钉实了。

1. 纠偏后的单 phase 干净复跑已经确认：
   - 去掉误加的 pre-open `setParamTag/setParam` 之后，没有回退到 `pcm_open -32`
   - `helper-prep + split metadata + connect` 仍然稳定把边界推进到 `pcm_open -> Unknown error -5`
   - `getTaggedInfo` 仍是 `rc=-19`
   - plugin 侧仍是 `Instance key is added` 后跟 `Failed to mixer_ctl_get_array`
   - `<intf> rate ch fmt` 这轮依旧是表面 `rc=0`，但 verify 全零，不能算真正落进 driver

2. 反汇编这轮有一个新的硬结论：
   - `0x5c40` 确实是 post-open 的 `setParamTag`
   - 但 `0x6628` 不是泛化 helper，它构造控件名时用的就是 `setParam` 字符串
   - 也就是说，真正该补的是：
     - `connect` 之后
     - `pcm_open` 之前
     - `getTaggedInfo(tag=0xC0000019) + 真正 setParam(0x6628)`
   - 不是继续猜 `setParamTag` 的 16-byte payload

3. 我已经把这个结论写回持续文档和 repo memory，避免后面再回到错误方向。

4. 这轮没有继续改代码。
   - 当前工作区里没找到先前那套 `agm_audio_demo` / video_player_ffi.c 可编辑源码树，只能先把基线和逆向结论收紧。
   - 现在唯一合理的下一步，就是找到那套实际源码位置，然后按 `tinyplay_ftm` 的时序补 `post-connect getTaggedInfo(tag=0xC0000019) + 真实 setParam(0x6628)`。

Made changes.

User: 继续

GitHub Copilot: 我先顺着你刚建的源码软链把实际可编辑工程找出来，目标是直接回到 `agm_audio_demo` 那套源码继续补 `post-connect getTaggedInfo + 真正 setParam`。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP)

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && ls -l | rg extracted_20260318_034751

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && find extracted_20260318_034751 -name video_player_ffi.c -o -name audio_demo_main.c -o -name video_player_ffi.h -o -name build_agm_demo.sh

软链已经接进来了，但里面没有直接叫这些名字的文件。我继续按日志字符串和构建脚本特征反查实际源码目录。

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && find extracted_20260318_034751 -maxdepth 3 -type d | head -n 120

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && rg -n "helper-prep-rate-split-metadata-connect|PCM100 split-kv metadata|debug probe direct controls|AGM helper prep" extracted_20260318_034751
Completed with input:  cd "/Volumes/Case-sensitive APFS/TWRP" && rg -n "helper-prep-rate-split-metadata-connect|PCM100 split-kv metadata|debug probe direct controls|AGM helper prep" extracted_20260318_034751

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && find extracted_20260318_034751 -name '*.sh' | rg "build|agm|audio|demo|video" | head -n 120

这个软链目标看起来不是源码工程本体，或者当前目录下没有可遍历内容。我先确认它实际指向的内容类型，再反查你桌面那边的工程。

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && ls -ld extracted_20260318_034751 && file extracted_20260318_034751

Ran terminal command:  ls -la "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/aurora_recovery/rom_extract/extracted_20260318_034751" | head -n 80

Ran terminal command:  cd "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/aurora_recovery" && find . -name video_player_ffi.c -o -name audio_demo_main.c -o -name video_player_ffi.h -o -name build_agm_demo.sh

软链确认只是 ROM 解包目录，不是源码树。我直接在桌面那套 Flutter 工程里按日志字符串和 `PCM100` 关键字反查。

Ran terminal command:  rg -n "PCM100|helper-prep-rate-split-metadata-connect|debug probe direct controls|AGM helper prep|getTaggedInfo|setParamTag"

Ran terminal command:  find . -maxdepth 4 \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.h' \) | head -n 200
Completed with input:  find . -maxdepth 4 \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.h' \) | head -n 200

Ran terminal command:  find . -name '*.so' | rg "video|ffi|agm|audio" | head -n 120

桌面工程本体里没直接搜到这些字符串，说明源码很可能不在 aurora_recovery 根仓，而是在旁边的 native 子工程或另一个目录。我先看现有产物分布，再扩大一层搜索范围。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_sAXuw1Lfw2qt1HjM6HqE7Idv__vscode-1773775026141/content.txt)

Ran terminal command:  cd "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery" && rg -n "helper-prep-rate-split-metadata-connect|debug probe direct controls|AGM helper prep|PCM100 setParamTag|PCM100 split-kv metadata|getTaggedInfo"

Ran terminal command:  find . -name '*.c' -o -name '*.h' | rg "video|audio|agm|ffi|player|demo" | head -n 200

源码找到了，在 `Flutter_On_Recovery/video_player` 这套工程里。下一步我直接读相关段落，把 `post-connect getTaggedInfo + 真正 setParam` 怎么补进现有 probe 定死。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1500-1500), lines 1500 to 1785

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#3360-3360), lines 3360 to 3635

Ran terminal command:  find . -name audio_demo_main.c -o -name video_player_ffi.h -o -name build_agm_demo.sh -o -name CMakeLists.txt | rg "video_player|audio_demo|agm|build"

现有 probe 里确实只做到 pre-connect MIID 探测，还没补 `connect` 之后的 `getTaggedInfo(tag=0xC0000019) + 真正 setParam`。我继续把已有工具函数和 tinyplay 参数布局读全，然后直接落代码。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1320-1320), lines 1320 to 1515

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1160-1160), lines 1160 to 1320

Ran terminal command:  rg -n "probe_agm_tagged_miid|write_pcm100_words|set_mixer_int_words|log_agm_pcm100_controls|AGM_DEVICE_CUSTOM_PAYLOAD_TAG|AGM_INSTANCE_KV|AGM_STREAM_KV_PCM_LL_PLAYBACK|AGM_DEVICEPP_KV_SPEAKER" video_player/video_player_ffi.c

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1900-1900), lines 1900 to 2015

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#2370-2370), lines 2370 to 2488

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#2488-2488), lines 2488 to 2548

现有主 AGM 路径里其实已经有一条现成的 `connect -> MFC tag MIID -> configure_mfc` 链，只是 direct probe 没接上。这比手搓未知 payload 更稳，我先确认 helper 可用性，然后直接把它接进 direct probe。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#200-200), lines 200 to 360

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.h)

Ran terminal command:  rg -n "configure_mfc|AGM_MFC_TAG|connect_agm_audio_intf_to_stream|get_device_media_config|set_agm_streamdevice_metadata|agm_mixer_get_miid" video_player/video_player_ffi.c video_player/video_player_ffi.h

补丁方向已经定了：不引入新入口，只在 direct probe 里新增一个 `...-mfc` phase，复用现有 `configure_mfc` helper 去对齐 `tinyplay_ftm` 那段真实 pre-open `setParam`。我先读构建脚本，随后直接改代码并上机验证。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/build_agm_demo.sh)

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/audio_demo_main.c)

我开始改 video_player_ffi.c：只加一个 post-connect MFC helper 和一个新 phase，保持旧基线 phase 不动，便于对照验证。

Generating patch (135 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
代码已经补上。我先本地编译确认没有引入错误，然后把新 phase 推到设备上做单独验证。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c), 28 problems found

Ran terminal command:  cd "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player" && ./build_agm_demo.sh

本地编译通过，编辑器诊断还是之前那批 include-path 噪音，没有新增实错。现在直接把新二进制推到设备，单跑新 phase 看 `MFC tag MIID` 和 `configure_mfc` 有没有把 `-5` 再往前推。

Ran terminal command:  cd "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery" && rg -n "agm_audio_demo|LD_LIBRARY_PATH|--probe-direct-controls-phase|data/local/tmp|vendor/lib64|libagm" docs video_player README.md
Completed with input:  cd "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery" && rg -n "agm_audio_demo|LD_LIBRARY_PATH|--probe-direct-controls-phase|data/local/tmp|vendor/lib64|libagm" docs video_player README.md

Ran terminal command:  adb -s 70a91f89 devices

设备在线于 recovery。接下来我用最保守的方式走 tmp 部署，复用程序内自带的 AGM 运行时环境设置，不额外引入新的变量扰动。

Ran terminal command:  adb -s 70a91f89 push "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/agm_audio_demo" /tmp/agm_audio_demo

Ran terminal command:  adb -s 70a91f89 shell chmod 755 /tmp/agm_audio_demo

Ran terminal command:  adb -s 70a91f89 shell '/tmp/agm_audio_demo --probe-direct-controls-phase helper-prep-rate-split-metadata-connect-mfc'
Completed with input:  adb -s 70a91f89 shell '/tmp/agm_audio_demo --probe-direct-controls-phase helper-prep-rate-split-metadata-connect-mfc'

新 phase 已经跑完，我先抓关键日志判断 `MFC tag MIID` 和 `configure_mfc` 有没有真正动起来，再决定是否还要补第二刀。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_CPu6V7sc50KtSglCdAA5HqKR__vscode-1773775026166/content.txt)

这轮新增 MFC phase 没把边界再推一步，关键是 `MFC tag MIID` 仍然拿不到，`configure_mfc` 根本没机会执行。我要把 `0x629c/0x5e1c` 对应的控件名彻底解出来，避免在错误时序上继续试。

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && strings -a -t x audio_manual/tinyplay_ftm_bin_20260318 | rg "^(3ee|3f7|a5b|a65|a70|9dc|2ec|589|5bd|a5f|a70)\s"

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2222-2222), lines 2222 to 2268

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#1934-1934), lines 1934 to 1978

`0x629c` 和 `0x5e1c` 都是“按字符串写 enum”类 helper，但仅靠 `strings` 还没把 rodata 标签完整捞出来。我直接扫二进制附近的字节，把这些字符串对上。

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && xxd -g 1 -s 0x3d0 -l 128 audio_manual/tinyplay_ftm_bin_20260318 | cat

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && xxd -g 1 -s 0xa50 -l 64 audio_manual/tinyplay_ftm_bin_20260318 | cat

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && xxd -g 1 -s 0x2e0 -l 32 audio_manual/tinyplay_ftm_bin_20260318 | cat

MFC helper 本身已经接上，但 `miid=0` 说明更早还缺一步。当前最像缺口的是 session 层，因为这条新 phase 只做了 enum/connect，没有把 `agm_session_aif_connect` 也叠进去。我直接补一个“helper-prep + session + connect + mfc”单相位再跑。

Generating patch (11 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
我只改了 phase 表，接着快速重编译并复跑这个新单相位，确认 session 层是否就是缺的那一步。

Ran terminal command:  cd "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player" && ./build_agm_demo.sh

Ran terminal command:  adb -s 70a91f89 push "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/agm_audio_demo" /tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /tmp/agm_audio_demo && adb -s 70a91f89 shell '/tmp/agm_audio_demo --probe-direct-controls-phase session-helper-prep-rate-split-metadata-connect-mfc'
Completed with input:  adb -s 70a91f89 push "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/agm_audio_demo" /tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /tmp/agm_audio_demo && adb -s 70a91f89 shell '/tmp/agm_audio_demo --probe-direct-controls-phase session-helper-prep-rate-split-metadata-connect-mfc'

新 session 叠加相位也跑完了。我只抓两类结果：`session_connect` 是否真生效，以及 `MFC tag/pcm_open` 有没有变化。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_kCiBBMxssuqBb6TcpACwGfLE__vscode-1773775026176/content.txt#120-120), lines 120 to 167

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_kCiBBMxssuqBb6TcpACwGfLE__vscode-1773775026176/content.txt#70-70), lines 70 to 125

Ran terminal command:  rg -n "session_connect|session_disconnect|agm_session_aif_connect" "/Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_kCiBBMxssuqBb6TcpACwGfLE__vscode-1773775026176/content.txt"

这轮实验已经形成新硬结论：`post-connect MFC` 路径接上了，但无论有没有 `agm_session_aif_connect rc=0`，`MFC tag` 还是 `rc=-19 miid=0`，所以缺口继续前移，不在 session 这一层。现在我把这点写进文档和仓库记忆。

Searched for regex `13\.69` (`**/docs/TWRP音频手动Bring-up.md`), 1 result

Read memory twrp_audio_pcm100_setparamtag.md

Read memory twrp_audio_helper_timing_delta_20260317.md

Generating patch (42 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```


Inserted into memory file twrp_audio_pcm100_setparamtag.md

Inserted into memory file twrp_audio_helper_timing_delta_20260317.md

代码和实机验证都做完了，我把计划也收口：这轮不是停在分析，而是已经把 MFC 路径接上并证伪了 session 缺口。

Completed: *如需修改代码再验证* (4/4)

继续推进了，而且这轮已经把一条可能路径实机证伪。

这次我做了两件事：

1. 在实际源码树 `Flutter_On_Recovery/video_player` 里补了 direct probe 的 post-connect MFC 路径
   - 新增了一个 post-connect helper
   - 在 direct probe 里加了两个新 phase
   - `helper-prep-rate-split-metadata-connect-mfc`
   - `session-helper-prep-rate-split-metadata-connect-mfc`

2. 本地重编译并上机实跑
   - 新二进制哈希先后是
   - `f97a7aa1145b479355460b04e2a878d6ce2ce702b048403f4fa57aadec202f1f`
   - `cc12c000a8395fc4221997b79397eca2edda1ebaa249d2dff773551a78886b13`
   - 都已推到设备 `70a91f89` 的 `/tmp/agm_audio_demo`
   - 分别跑了两个新 phase

硬结论：

1. `helper-prep` 主链还是有效
   - `set_device_media_config rc=0`
   - `set_audio_intf_metadata rc=0`
   - `set_stream_metadata rc=0`
   - `set_streamdevice_metadata rc=0`

2. direct probe 里新增的 post-connect MFC 路径已经真的接上了
   - 会去查 `agm_mixer_get_miid(tag=0xC0000019)`
   - 如果拿到 MIID 才会继续 `configure_mfc`

3. 但现在的真正阻塞更清楚了
   - 不带 session 的新 phase：`agm_mixer_get_miid(tag=0xC0000019) -> rc=-19, miid=0`
   - 叠加 `agm_session_aif_connect rc=0` 的新 phase：结果完全一样，还是 `rc=-19, miid=0`
   - 所以 `configure_mfc` 根本没有机会真正执行
   - `pcm_open` 也仍然稳定停在 `Unknown error -5`

4. 这说明当前缺口已经不是这些层
   - 不是 `setParamTag`
   - 不是少一次 `agm_session_aif_connect`
   - 不是没把 `configure_mfc` 接进来
   - 而是更早阶段没有把 `MFC tag` 所需的 `getTaggedInfo` 内容真正立起来

5. plugin 日志也支持这个判断
   - 仍然有 `Instance key is added`
   - 现在是连续两条 `Failed to mixer_ctl_get_array`
   - 说明我们确实碰到了 plugin 期待读取的那段路径，但内容还是空的

另外我已经同步更新了：
1. bring-up 文档
2. repo memory

下一步单一路径已经收窄成：
1. 回到 `tinyplay_ftm` 在 `0x4b98 -> 0x4c00` 之前那两段 helper
2. 查清到底是哪一步“表面 rc=0，但实际上没有把 `getTaggedInfo` 所需内容写进 driver”

Made changes.


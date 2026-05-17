# 第2章：Connect门控深度A/B与gate-window插桩

GitHub Copilot: 我不再扩外围采样了，直接把 `agm_audio_minimal` 补成“程序内自己打印 `PCM100 control/connect`”。这样下一轮 recovery 对照就不需要再依赖外部 mixer 猜 `PCM100`。

Searched for regex `PCM100|getTaggedInfo|mixer_ctl_get_enum_string|mixer_ctl_get_num_enums|mixer_ctl_get_value` (`**/video_player/agm_audio_minimal.c`), 29 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#430-430), lines 430 to 760

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#1180-1180), lines 1180 to 1325

我现在直接做一个最小代码改动：不给 `agm_audio_minimal` 加大块调试框架，只补“程序内打印 `PCM100 control/connect` + `0xc0000019/miid`”。这样下一轮 recovery 对照就能绕开外部 `tinymix_stock` 的边界。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#680-680), lines 680 to 1160

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#1160-1160), lines 1160 to 1434

我现在改的范围很小：只给 `agm_audio_minimal` 加程序内 `PCM100 control/connect + tagged_info/miid` 快照，不碰播放逻辑和 public API。改完立刻编译并在 recovery 下跑一轮。

Generating patch (123 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c)


```

```
改动已经落下去，范围只在程序内日志。现在我直接编译新二进制并在 recovery 下跑一次，确认 helper-connect 路径内部到底有没有把 `PCM100 connect=ZERO` 打破。

Checked [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c), 24 problems found

Ran terminal command:  bash '/Volumes/Case-sensitive APFS/TWRP/video_player/build_agm_audio_minimal.sh'
Completed with input:  bash '/Volumes/Case-sensitive APFS/TWRP/video_player/build_agm_audio_minimal.sh'

编译只暴露出一个我这次新改动引入的真实问题：`direct_get_tagged_info` 的声明顺序。我先补前置声明，马上重编并跑 recovery，对别的噪声不动。

Generating patch (20 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c)


```

```
声明顺序已经修好。我现在直接重编、下发、在 recovery 下跑新日志版 `agm_audio_minimal_bin`，只抓它自己打印出来的 `PCM100` 关键行。

Ran terminal command:  bash '/Volumes/Case-sensitive APFS/TWRP/video_player/build_agm_audio_minimal.sh' && adb push '/Volumes/Case-sensitive APFS/TWRP/video_player/agm_audio_minimal_bin' /data/local/tmp/agm_audio_minimal_bin && adb shell chmod 755 /data/local/tmp/agm_audio_minimal_bin && adb shell '/data/local/tmp/agm_audio_minimal_bin --play-seconds 5' | grep -E 'AGM runtime snapshot|PCM100 enum: PCM100 (control|connect)|runtime direct_get_tagged_info|runtime agm_mixer_get_miid|play_tone reinforce route audio_ms'
Completed with input:  bash '/Volumes/Case-sensitive APFS/TWRP/video_player/build_agm_audio_minimal.sh' && adb push '/Volumes/Case-sensitive APFS/TWRP/video_player/agm_audio_minimal_bin' /data/local/tmp/agm_audio_minimal_bin && adb shell chmod 755 /data/local/tmp/agm_audio_minimal_bin && adb shell '/data/local/tmp/agm_audio_minimal_bin --play-seconds 5' | grep -E 'AGM runtime snapshot|PCM100 enum: PCM100 (control|connect)|runtime direct_get_tagged_info|runtime agm_mixer_get_miid|play_tone reinforce route audio_ms'

新日志版已经跑完了。我现在只读关键输出，不再追加任何额外命令；这一步会直接告诉我们 helper-connect 最小库路径内部有没有打破 `PCM100 connect=ZERO`。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_QzD6PdfG9aQ5SoYpEzDJlv85__vscode-1774271681876/content.txt)

关键点已经钉死了：连 `agm_audio_minimal` 这条明确走 `helper_connect + post-connect MFC` 的最小库路径，程序内自己打印出来的 `PCM100 connect` 也一直是 `ZERO`。我把这个结果补到文档末尾，后面就不必再猜“是不是 pure C 少了一步 connect”。

Ran terminal command:  wc -l '/Volumes/Case-sensitive APFS/TWRP/docs/TWRP音频手动Bring-up-续.md'

Ran terminal command:  rg -n '^### 14\.' '/Volumes/Case-sensitive APFS/TWRP/docs/TWRP音频手动Bring-up-续.md' | tail -n 2

Generating patch (72 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Created memory file twrp_audio_agm_audio_minimal_connect_zero_20260323.md

继续压下去之后，主线又少掉了一条大分叉。

这次我没有再靠外部 `tinymix` 猜 `PCM100`，而是直接把 `agm_audio_minimal` 补成程序内自己打印：

1. `PCM100 control`
2. `PCM100 connect`
3. `0xc0000019`
4. `miid`

然后在 recovery 下重编、下发、直接跑。

关键结果很硬：

1. `helper_connect intf=TDM-LPAIF-RX-SECONDARY connect=1 rc=0`
2. 但紧接着程序内回读就是：
   - `PCM100 control = TDM-LPAIF-RX-SECONDARY`
   - `PCM100 connect = ZERO`
   - `0xc0000019 value = 0x1`
   - `miid = 16584`

而且这不是只在一个点上发生：

1. `after helper_connect`
2. `after post-connect mfc`
3. `play_tone 1000ms`
4. `play_tone 2000ms`
5. `play_tone 3000ms`

这几个窗口里，结果都一样：
`PCM100 connect` 一直是 `ZERO`

所以这条误判现在可以明确排掉了：

不是 `pure_c_agm_probe` 少调了一步 `helper_connect` 才异常。

因为连 `agm_audio_minimal` 这条明确走了：

1. `helper_connect`
2. `post-connect MFC`

的最小库路径里，程序内自己回读出来的 `PCM100 connect` 也还是 `ZERO`。

这一步把主线又收紧了一层：

1. `helper_connect` 确实被调用了
2. `helper_connect` 也确实返回成功了
3. `0xc0000019` 和 `miid` 也一直稳定存在
4. 但可见的 `PCM100 connect` 枚举态仍然始终停在 `ZERO`

也就是说，现在更贴近事实的描述已经不是“少了一步 connect”，而是：

共享播放图里存在一层更深的状态错位，使得：
1. connect 调用可以成功返回
2. MFC 也可以成功配置
3. tagged info 和 miid 也都在
4. 但 `PCM100 connect` 这个可见状态始终不进入非 `ZERO`

我已经把这轮结果补进文档和仓库记忆了。

下一步最值钱的方向只剩两个，而且我会继续用短命令/小改动来做：

1. 继续给 `agm_audio_minimal` 补 `play_wav` 同样的 recovery 程序内快照，看 tone 和 wav 是否完全同型
2. 直接围绕“connect 调用成功但可见 connect 枚举仍是 ZERO”继续做最小对照，查这是不是 AGM 插件/控件投影层和真实内部连接状态脱节

Made changes.

User: 继续

GitHub Copilot: 我继续沿同一主线，不再改代码。下一步先看 `agm_audio_minimal` 的 `wav` 路径是不是和 `tone` 完全同型，这能直接判断问题是不是连媒体形态都无关。

Ran terminal command:  adb shell '/data/local/tmp/agm_audio_minimal_bin --wav /data/local/tmp/test440_mid_10s.wav' | grep -E 'AGM runtime snapshot|PCM100 enum: PCM100 (control|connect)|runtime direct_get_tagged_info|runtime agm_mixer_get_miid|play_wav reinforce route audio_ms|play_wav start|play_wav done'
Completed with input:  adb shell '/data/local/tmp/agm_audio_minimal_bin --wav /data/local/tmp/test440_mid_10s.wav' | grep -E 'AGM runtime snapshot|PCM100 enum: PCM100 (control|connect)|runtime direct_get_tagged_info|runtime agm_mixer_get_miid|play_wav reinforce route audio_ms|play_wav start|play_wav done'

Ran terminal command:  adb shell 'ls /data/local/tmp/test440_mid_10s.wav'

样本文件在，`wav` 路径已经跑了。我现在只读关键日志，不再补任何确认命令；这一步会直接告诉我们 tone/wav 是否真的一模一样。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_ETUxsTkKu3WjypP8SuHjXQUE__vscode-1774271681882/content.txt)

`wav` 路径的结果已经出来了，而且信息量很高：它和 `tone` 完全同型。现在我只把这条结论补到文档末尾，不再开新分叉。

Ran terminal command:  wc -l '/Volumes/Case-sensitive APFS/TWRP/docs/TWRP音频手动Bring-up-续.md'

Ran terminal command:  rg -n '^### 14\.' '/Volumes/Case-sensitive APFS/TWRP/docs/TWRP音频手动Bring-up-续.md' | tail -n 2

Generating patch (67 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Created memory file twrp_audio_agm_audio_minimal_wav_same_as_tone_20260323.md

继续压下去后的新增结论是：

`wav` 路径和 `tone` 路径也完全同型。

这次我没有再改代码，只是直接在 recovery 下跑了新日志版：

1. `agm_audio_minimal_bin --wav /data/local/tmp/test440_mid_10s.wav`

结果和之前 `tone` 的那条最小库路径逐项一致：

1. `after helper_connect`
   - `PCM100 control = TDM-LPAIF-RX-SECONDARY`
   - `PCM100 connect = ZERO`
   - `0xc0000019 value = 0x1`
   - `miid = 16584`
2. `after post-connect mfc`
   - 还是同一组值
3. `play_wav 1000ms / 2000ms / 3000ms`
   - 还是同一组值

也就是说，现在这条共享异常已经跨过了三层切换，仍然不变：

1. `pure_c_agm_probe / agm_audio_minimal`
2. `system / recovery`
3. `tone / wav`

另外，`wav` 本身不是没跑起来：

1. 文件头解析正常
   - `rate=48000`
   - `ch=2`
   - `fmt=0`
   - `bytes=1920000`
2. 生命周期也正常
   - 从 `1000ms` 一直走到 `10000ms`
   - `play_wav done` 正常收尾

所以这条分叉现在也可以明确排掉了：

不是“人工 tone 写流才会这样，正常 wav 就不会”。

到这一步，主线已经被压得很窄了：

1. 不是 boot mode 差异
2. 不是 recovery 抓不到 active
3. 不是 pure C 默认 PCM / AW baseline 分叉
4. 不是 pure C 少了 helper_connect
5. 不是 tone / wav 媒体形态差异

当前最硬的事实只剩这一句：

`helper_connect` 可以成功返回，`post-connect MFC` 也可以成功，`0xc0000019` 和 `miid` 也一直稳定存在，但 `PCM100 connect` 的可见枚举态始终停在 `ZERO`。

我已经把这轮结果补进文档末尾和仓库记忆。

下一步最有价值的方向只剩一个了：

继续围着“为什么 connect 成功而 connect 枚举投影始终不变”去压，不再靠换路径、换媒体、换模式找差异。

Made changes.

User: 继续

GitHub Copilot: 我继续压这一点，不再换媒体或路径。下一步只验证一个更硬的问题：`PCM100 connect` 会不会根本就是“触发型写控件”，所以读回 `ZERO` 并不代表内部没连上。

Searched for regex `PCM100 connect|disconnect|force_agm_pcm100_connect|helper_connect|connect_agm_audio_intf_to_stream` (`**/video_player/pure_c_agm_probe.c`), 23 results

Searched for regex `PCM100 connect|disconnect|helper_connect|connect_agm_audio_intf_to_stream` (`**/video_player/agm_audio_minimal.c`), 8 results

Read memory twrp_audio_pcm100_connect_zero_not_equal_no_tags_20260320.md

我先把已有记忆对齐一下，再决定最小实验。重点不是再证明 `ZERO`，而是证明“`ZERO` 是否只是读回投影，不等于内部没连”。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#1568-1568), lines 1568 to 1610

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2288-2288), lines 2288 to 2310

Read memory twrp_audio_pcm100_connect_zero_not_equal_no_tags_20260320.md

我现在做一个比“再看 ZERO”更有信息量的最小 A/B：同一条 recovery 最短链，只改 `--skip-connect`。如果 `0xc0000019/miid` 也掉了，说明 connect 步骤虽然读回 `ZERO`，但对内部状态仍然是必需触发。

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --play-after-open --play-seconds 5 --skip-connect' | grep -E 'PCM100 enum: PCM100 (control|connect)|runtime direct_get_tagged_info|runtime agm_mixer_get_miid|write_test_tone rc|helper_connect|pure-c probe: 跳过 connect'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --play-after-open --play-seconds 5 --skip-connect' | grep -E 'PCM100 enum: PCM100 (control|connect)|runtime direct_get_tagged_info|runtime agm_mixer_get_miid|write_test_tone rc|helper_connect|pure-c probe: 跳过 connect'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --play-after-open --play-seconds 5 --helper-connect' | grep -E 'PCM100 enum: PCM100 (control|connect)|runtime direct_get_tagged_info|runtime agm_mixer_get_miid|write_test_tone rc|helper_connect rc'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --play-after-open --play-seconds 5 --helper-connect' | grep -E 'PCM100 enum: PCM100 (control|connect)|runtime direct_get_tagged_info|runtime agm_mixer_get_miid|write_test_tone rc|helper_connect rc'

A/B 已经跑完了。我现在只读关键输出，不再追加任何命令；这一步会直接告诉我们 `connect` 究竟是“读回不可信但内部必要”，还是“连内部也不是硬前置”。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_k9qtNFAHESxbo6b6981oI8y4__vscode-1774271681895/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_yWWSDX9IVfoAPsOuawvjxCbV__vscode-1774271681896/content.txt#1-1), lines 1 to 220

这轮 A/B 已经有新信息了，而且比单纯“还是 ZERO”更值钱：`connect` 步骤对“能不能真正 open/跑起来”是必需的，但对 `tag/miid` 并不是前置。我把这条增量直接补到文档末尾。

Generating patch (75 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Created memory file twrp_audio_connect_required_for_pcmopen_but_not_for_tag_miid_20260323.md

这轮比前面单纯重复 “`PCM100 connect=ZERO`” 更有推进。

我做了一个真正有区分度的最小 A/B：

1. recovery 下同一条 `pure_c_agm_probe` 最短链
2. 一次只改一个变量
3. 对照：
   - `--skip-connect`
   - `--helper-connect`

结果把 `connect` 这件事拆成了两层，不再混在一起。

`--skip-connect` 的结果：

1. 日志明确显示：
   - `pure-c probe: 跳过 connect`
2. 但在真正 `pcm_open` 之前，final snapshot 里已经仍然存在：
   - `PCM100 control = TDM-LPAIF-RX-SECONDARY`
   - `PCM100 connect = ZERO`
   - `PCM100 getTaggedInfo` 非零
   - `0xc0000019 value = 0x1`
   - `miid = 16584`
3. 随后真正起播时直接失败：
   - `cannot open device 100 for card 100: Unknown error -32`

这说明：

1. `tag/miid` 的出现，不以最后那一步 `connect` 为前置
2. 仅凭 `0xc0000019` 和 `miid=16584` 存在，不能推出“已经真正满足可起播条件”
3. 但 `connect` 这一步对“真正能把 `pcm_open` 打开”仍然是必要触发

`--helper-connect` 的对照结果：

1. `helper_connect rc=0`
2. `pcm_open / pcm_start / write` 都能正常跑通
3. 但 `PCM100 connect` 读回仍然是 `ZERO`

所以现在可以把这条主线写得更准确：

1. `PCM100 connect=ZERO` 不是“内部没 connect”的充分证据
2. `tag/miid` 存在也不是“已经可起播”的充分证据
3. `connect` 更像一个内部起播门控触发，而不是可靠的表层状态投影

这是当前最重要的新收敛。

因为它把之前那团混在一起的现象拆开了：

1. 一层是“内部准备态已经存在”
   - metadata
   - tag
   - miid
2. 另一层是“真正可起播门控”
   - 跳过 connect 就会卡死在 `pcm_open`
   - 但 connect 读回又始终还是 `ZERO`

我已经把这轮结果追加进文档和仓库记忆。

现在主线只剩最后那种真正有价值的问题了：

不是“怎么把 `PCM100 connect` 读成非 `ZERO`”，而是：

为什么这一步内部触发已经真实影响了 `pcm_open` 成败，但它的表层枚举投影却长期不变。

Made changes.

User: 继续

GitHub Copilot: 我继续沿 `connect` 这条主线压“时序是否关键”，不再换媒体也不再扩外围。先把 `connect-before-rate` 和 `reconnect-cycle` 这两个现成开关对应的执行顺序看清，再做 recovery 下最小 A/B。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2112-2112), lines 2112 to 2310

Searched for regex `reconnect_cycle|connect_before_rate|helper_connect rc|执行 connect-disconnect-connect 循环` (`**/video_player/pure_c_agm_probe.c`), 13 results

Read memory twrp_audio_connect_required_for_pcmopen_but_not_for_tag_miid_20260323.md

顺序已经看清了：`connect-before-rate` 只是把 helper connect 提前，`reconnect-cycle` 则是在末尾再打一遍 disconnect/control/connect。下一步我直接在 recovery 下做这两个最小 A/B，看它们会不会改变“`ZERO` 但可起播”的骨架。

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --play-after-open --play-seconds 5 --helper-connect --connect-before-rate' | grep -E 'helper_connect\(before-rate\)|PCM100 enum: PCM100 (control|connect)|runtime direct_get_tagged_info|runtime agm_mixer_get_miid|write_test_tone rc'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --play-after-open --play-seconds 5 --helper-connect --connect-before-rate' | grep -E 'helper_connect\(before-rate\)|PCM100 enum: PCM100 (control|connect)|runtime direct_get_tagged_info|runtime agm_mixer_get_miid|write_test_tone rc'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --play-after-open --play-seconds 5 --helper-connect --reconnect-cycle' | grep -E 'helper_connect rc|执行 connect-disconnect-connect 循环|PCM100 enum: PCM100 (control|connect)|runtime direct_get_tagged_info|runtime agm_mixer_get_miid|write_test_tone rc'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --play-after-open --play-seconds 5 --helper-connect --reconnect-cycle' | grep -E 'helper_connect rc|执行 connect-disconnect-connect 循环|PCM100 enum: PCM100 (control|connect)|runtime direct_get_tagged_info|runtime agm_mixer_get_miid|write_test_tone rc'

A/B 已经跑完。我现在只读关键输出，不补别的命令；这一步只看时序变化有没有真正撬动 `connect` 这层共享骨架。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_EzM9lHwUBbgSo7dUTf3SeF4I__vscode-1774271681904/content.txt#1-1), lines 1 to 220

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_2mjJhzZQACluufeZj0Qc7rY1__vscode-1774271681905/content.txt#1-1), lines 1 to 220

Compacted conversation两组结果已经够明确了：不管把 `helper_connect` 提前，还是强行做一轮 `connect-disconnect-connect`，运行态骨架都没动。我先补文档和仓库记忆，把这条支线封死，再收敛下一步假设。Optimizing tool selection...

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#1-1), lines 1 to 260

Read memory twrp_audio_connect_required_for_pcmopen_but_not_for_tag_miid_20260323.md

我先取文档尾部，确认真实 EOF 和当前最大节号，再只往末尾追加一节，不在中间插。

Searched for regex `^### ` (`**/docs/TWRP音频手动Bring-up-续.md`), 20 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#1800-1800), lines 1800 to 1980

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#3200-3200), lines 3200 to 3385

Searched for regex `^### 14\.` (`**/docs/TWRP音频手动Bring-up-续.md`), 74 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#4681-4681), lines 4681 to 4749

Read memory /memories/repo/

我现在只做两处落地：文档末尾追加一节，仓库记忆新增一条。代码先不动，因为这轮已经证明不是 connect 时序问题。

Generating patch (85 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Created memory file twrp_audio_connect_timing_nochange_20260323.md

结论已经固定下来了。我再取一下新增节的行号，最后给你一个可直接接着干的收口结论。

Searched for regex `14\.74|connect 时序 A/B` (`**/docs/TWRP音频手动Bring-up-续.md`), 2 results

Searched for regex `connect 时序 A/B|结论：connect 是起播必要触发` (`**/memories/repo/twrp_audio_connect_timing_nochange_20260323.md`), no results

这轮已经收口成一条明确结论：

- connect 仍然是起播必要触发，这一点 14.73 的 “跳过 connect 后 pcm_open 直接失败” 没变。
- 但只要不跳过 connect，那么不管是把 helper_connect 提前到 rate 之前，还是额外强打一轮 connect-disconnect-connect，可见运行态都完全不变。
- 两组 A/B 的共同结果都是：
  - PCM100 control 仍是 TDM-LPAIF-RX-SECONDARY
  - PCM100 connect 仍长期是 ZERO
  - 0xc0000019 仍是 0x1
  - miid 仍是 16584
  - pcm_open、pcm_start、write 仍都能正常走通

这说明当前已经可以把“connect 时序不对”这条支线封死。现在更窄的前沿只剩一件事：

- connect 在内部到底写通了什么不可见门控，能把 “已有 tag 和 miid 但不可起播” 推进成 “可起播”
- 为什么这层内部变化在外部只投影成一组长期不变的表象

已追加到文档末尾：
TWRP音频手动Bring-up-续.md

下一步如果继续压，我建议直接选一条，不再回头试 connect 变体：

1. 盯 helper_connect 前后和 pcm_open 前后，再扩一层程序内快照，找“可起播门”真正变化的内部项
2. 去对 stock 路径里同一阶段的内部调用顺序，确认是不是还有一个当前 pure C 没显式打到的隐藏 setParam 或状态迁移

Made changes.

User: 继续

GitHub Copilot: 我继续沿当前唯一剩下的窄前沿推进：先回到 pure C 源码里把 connect 前后、pcm_open 前后的内部门控点再压一层，目标是找出“可起播”到底比“已有 tag/miid”多了哪一步。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#1-1), lines 1 to 260

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#261-261), lines 261 to 620

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#621-621), lines 621 to 1120

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#1121-1121), lines 1121 to 1700

源码结构已经够了。下一步我只补读 `pcm_open` 前后的调用面和 CLI 分支，确定最省事的插桩位置，再直接改代码。

Searched for regex `prepare_and_start|pcm_open|pcm_prepare|pcm_start|main\(|skip-connect|connect-before-rate|reconnect-cycle|helper_connect` (`**/video_player/pure_c_agm_probe.c`), 39 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#1701-1701), lines 1701 to 2350

插桩点已经很清楚：现在缺的是“final snapshot 之后、pcm_open 前后”的内部对比，而不是播放中再看老三样。我直接在 pure C 里补一组最小快照，并给它一个单独开关，避免污染默认链。

Using "Apply Patch"

补丁没套上，我先只读精确上下文再重打一次，避免大块上下文漂移。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#880-880), lines 880 to 1015

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2330-2330), lines 2330 to 2415

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2396-2396), lines 2396 to 2575

Generating patch (68 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```


Generating patch (60 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```


Generating patch (30 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
插桩已经落下去了。现在先做本地编译校验，目标是确认新增开关能进二进制，再直接上设备跑最短 A/B。

Checked [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c), 24 problems found

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/build_pure_c_agm_probe.sh)

编辑侧没再报结构性问题，接下来直接走现有构建脚本和最短设备验证。我要拿到的结果只有一个：`pcm_open` 这一瞬间前后，门控快照到底有没有变化。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/build_pure_c_agm_probe.sh)

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP/video_player && bash ./build_pure_c_agm_probe.sh

编译已经过了。现在只做两步短命令：推新二进制，然后跑一个 `--skip-connect` 对照和一个 `--helper-connect` 对照，专门看 `before/after pcm_open` 这组新快照。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP/video_player && adb push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe

下面这批只读设备输出，目标是比较 `skip-connect` 和 `helper-connect` 在 `before/after pcm_open`、`pcm_ready` 这些点上的差异，不再看播放中途噪声。

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --trace-gate-window --skip-connect' | grep -E 'runtime gate snapshot|runtime gate tagged_info|runtime gate miid|pcm_open|pcm_not_ready|pcm_ready|打开失败|打开成功'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --trace-gate-window --skip-connect' | grep -E 'runtime gate snapshot|runtime gate tagged_info|runtime gate miid|pcm_open|pcm_not_ready|pcm_ready|打开失败|打开成功'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --trace-gate-window --helper-connect' | grep -E 'runtime gate snapshot|runtime gate tagged_info|runtime gate miid|pcm_open|pcm_not_ready|pcm_ready|after prepare_start|打开失败|打开成功'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --trace-gate-window --helper-connect' | grep -E 'runtime gate snapshot|runtime gate tagged_info|runtime gate miid|pcm_open|pcm_not_ready|pcm_ready|after prepare_start|打开失败|打开成功'

两组运行都回来了。我现在只读关键片段，判断 `pcm_open` 这一瞬间有没有把 `tag/miid` 或别的可见门控推进一步。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_HobRPO2EtyPotloRxOPCyZh8__vscode-1774271681938/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_oQF2eYbOwna4zOvEGyDlg4nb__vscode-1774271681939/content.txt)

新的差异已经出来了：不是 `pcm_open` 把 tag/miid 从 0 推到 1，而是 `skip-connect` 时一旦 `pcm_open` 失败，连 `getTaggedInfo/miid` 访问本身都会一起塌成 `-32`。我再补一个 1 秒短跑，只确认 `prepare/start` 成功后这组值是否仍完全不动。

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --trace-gate-window --helper-connect --play-after-open --play-seconds 1' | grep -E 'runtime gate snapshot|runtime gate tagged_info|runtime gate miid|after prepare_start|打开成功|prepare_and_start rc'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --trace-gate-window --helper-connect --play-after-open --play-seconds 1' | grep -E 'runtime gate snapshot|runtime gate tagged_info|runtime gate miid|after prepare_start|打开成功|prepare_and_start rc'

这一步还是只读关键输出，目标很单一：看 `after prepare_start` 有没有任何额外可见变化。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_xNqetN9HKGnJubDcbaUxeJGV__vscode-1774271681942/content.txt)

这轮的增量已经足够写结论了。我把新发现追加到文档末尾，并存一条仓库记忆，免得后面又重复试 `pcm_open` 是否会“生成” tag/miid。

Generating patch (99 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Created memory file twrp_audio_pcmopen_gate_window_20260323.md

文档和记忆都补完了。我最后取一下新节行号，方便你继续看当前结论落点。

Searched for regex `^### 14\.75` (`**/docs/TWRP音频手动Bring-up-续.md`), 1 result

Searched for regex `pcm_open gate|before pcm_open|Unknown error -32` (`**/memories/repo/twrp_audio_pcmopen_gate_window_20260323.md`), no results

继续推进后的新增结论已经出来了，而且比前一轮更硬：

1. 成功链里，tag=0x1 和 miid=16584 早在 pcm_open 之前就已经存在。
2. pcm_open、pcm_prepare、pcm_start 都不会再把这组值推进一步。
3. 失败链里，真正的新变化不是“pcm_open 发现 tag/miid 不够”，而是 pcm_open 报 -32 之后，连 getTaggedInfo 和 miid 查询面本身都会一起塌成 -32。

这轮我实际做了这些事：

1. 给 pure_c_agm_probe 加了一个最小插桩开关，专门抓 gate window：
   - before pcm_open
   - after pcm_open
   - pcm_ready
   - after prepare_start
2. 本地重新编译并推到了设备。
3. 跑了三组最小对照：
   - skip-connect + trace-gate-window
   - helper-connect + trace-gate-window
   - helper-connect + trace-gate-window + play-after-open + 1 秒短跑

得到的关键结果是：

1. skip-connect 链：
   - before pcm_open 时已经是 tagged_info rc=0, value=0x1，miid rc=0, miid=16584
   - 说明 tag/miid 不是由 pcm_open 生成的
   - 但一旦 pcm_open 失败，after pcm_open 和 pcm_not_ready 立刻一起变成：
     - tagged_info rc=-32, value=0
     - miid rc=-32, miid=0
2. helper-connect 成功链：
   - before pcm_open、after pcm_open、pcm_ready、after prepare_start 全都保持不变
   - 一直都是 value=0x1、miid=16584
   - 所以 prepare/start 也不是“最终成图”的那一步

这意味着当前前沿又收窄了一层：

1. 不是 connect 时序问题
2. 不是 pcm_open 前后会把 tag/miid 推进到最终态
3. 更像是 connect 先满足了 libagm_pcm_plugin 或 pcm_open 所依赖的一项不可见前置条件
4. tag/miid 只是并行投影，不能代表 plugin/open 可达性

我已经把这个结论追加到文档末尾，新增节号是 14.75。

下一步最值钱的方向只剩一个：

1. 直接追 libagm_pcm_plugin 在成功链和失败链里依赖的隐藏前置条件
2. 不再继续围着 connect 变体、pcm_open 前后、prepare/start 前后打转

如果你继续让我推，我下一轮就改成只抓 plugin 侧前置依赖，不再重复现有 A/B。

Made changes.


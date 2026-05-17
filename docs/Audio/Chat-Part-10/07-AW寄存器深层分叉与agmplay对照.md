# 第7章：AW寄存器深层分叉与agmplay对照

GitHub Copilot: 我继续往“持续出声链”收敛，先找现成的播放中途采样脚本或相关实验入口，避免重复造轮子；如果没有，就直接补一个最小采样流程去抓 1 秒附近的状态变化。

Ran terminal command:  rg -n "tinymix|mixer|sample.*play|play.*sample|route snapshot|audio_ms|wall_ms|agmplay" audio_manual docs TWRP\ WIFI video_player

Read memory twrp_audio_manual_playback.md

Read memory twrp_audio_standard_path_priority.md

仓库里已有不少手工播放和 baseline 记录，但还没看到现成的“播放中途连续采样”脚本。我缩小搜索范围，直接找跟播放期快照和 tinymix 轮询最接近的材料。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_7JdMBO21NxJNgBebml6V3dpL__vscode-1774359791819/content.txt#1-1), lines 1 to 220

Ran terminal command:  rg -n "play_tone 1000ms|runtime snapshot|tinymix.*loop|while .*tinymix|sleep 1.*tinymix|audio_ms=1000|wall_ms=1000|Speaker_Mute_Switch|aw_dev_.*volume|WSA RX0 MUX|WSA RX1 MUX" docs video_player audio_manual

仓库里其实已经有一次“1 秒到 8 秒 mixer 没漂”的结论。我先把那段上下文读出来，确认它覆盖的是哪条播放路径；如果只是 probe 路径，我下一步就直接去跑 `tinyplay_ftm` 或 `agmplay` 做横向对照。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#1528-1528), lines 1528 to 1588

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#4588-4588), lines 4588 to 4610

Ran terminal command:  rg -n "tinyplay_ftm .*test440|agmplay .*test440|thread_result ok|graph_open ret 0|play cycle|open-close-cycles" docs/TWRP音频手动Bring-up-续.md docs/TWRP音频手动Bring-up.md

现在线索更集中在“helper 链虽然连续成功，但 PCM100 connect 仍是 ZERO；而 agmplay 以前能走到 graph_start/PA 成功”。我补读 agmplay 那段，再决定是直接复跑 agmplay 还是给最小播放器加更深的运行态快照。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3228-3228), lines 3228 to 3260

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3358-3358), lines 3358 to 3385

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#6498-6498), lines 6498 to 6538

下一步我直接做设备侧对照，不再停在代码阅读：先各跑一轮 `agm_audio_minimal` 和 `agmplay`，然后抓它们之后最新的 `aw882xx` / `graph` 相关内核日志，确认差异到底落在 PA 启动还是更前面的 graph/runtime。

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --play-seconds 3'

Ran terminal command:  adb shell 'dmesg | grep -E "aw882xx|graph_open|graph_start|audioreach" | tail -n 120'

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY -dkv 0xA2000001 -ikv 1 -skv 0xA100000E -dppkv 0xAC000002'

Ran terminal command:  adb shell 'dmesg | grep -E "aw882xx|graph_open|graph_start|audioreach" | tail -n 160'

命令已经跑完，接下来只读关键输出：一份看 helper 自身日志，一份看 helper 后的内核信号，一份看 agmplay 后的内核信号。这样能直接判断两条链是不是都停在同一个 AW/PA 层。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_vfmpfLnLkhYpdUKKPUVghqZi__vscode-1774359791833/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_lBDW5KOlIs5vmxpevLjs44Jm__vscode-1774359791830/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_dDU5aLfsGcbiRBEx2i4UUSID__vscode-1774359791831/content.txt)

对照已经有差异了：`agmplay` 明确打出了完整的 `startup -> hw_params -> start_pa: start success`；而 helper 这轮只看到大量 `already start`，没看到同样干净的一次启动序列。我要再补一轮更聚焦的 helper 日志，把 `startup/hw_params/start_pa/shutdown` 单独抓出来，避免被大量 volume/monitor 日志淹没。

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --play-seconds 1'

Ran terminal command:  adb shell 'dmesg | grep -E "aw882xx_(startup|hw_params|start_pa|shutdown|mute)" | tail -n 120'

上一条读取路径拼错了，我直接重读正确的输出文件，只看精简后的 AW 启停序列。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_4bhVvGqqRMbOlYPcdbn6SI3q__vscode-1774359791838/content.txt)

新结果比刚才更关键：helper 并不是没走到 PA 启动，它也会完整经过 `startup -> hw_params -> start_pa: start success`，只是 1 秒重打路由时会再次看到 `already start`。这说明问题边界又往后缩了一层，我先确认文档里有没有写过这个点，没有的话就追加进去。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#6510-6510), lines 6510 to 6544

Ran terminal command:  rg -n "agm_audio_minimal.*start success|helper.*start_pa|start_pa: start success|already start|PCM100 connect = ZERO" docs/TWRP音频手动Bring-up-续.md docs/TWRP音频手动Bring-up.md

我把这个新边界固化到记录里：不是只有 agmplay，helper 播放链也能完整打到 `aw882xx_start_pa: start success`；同时 `PCM100 connect=ZERO` 仍然伴随存在，所以它至少不是阻止 PA 启动的充分条件。

Generating patch (74 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Updated memory file twrp_audio_session_open_two_error_planes_20260324.md

我再往后推进一步，不停在“PA 已启动”这个节点：直接跑一轮 10 秒 helper 播放，然后专门筛 AW 侧的异常关键词，看持续阶段有没有保护、告警或中途状态切换。

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --play-seconds 10'

Ran terminal command:  adb shell 'dmesg | grep -iE "aw882xx|awinic|protect|fault|error|oc|ov|uv|temp|interrupt|monitor|start_pa|shutdown" | tail -n 260'

10 秒播放和日志都拿到了。我只提取两类信息：一是 10 秒 helper 自身是否完整跑完，二是 AW 侧有没有 `fail/protect/fault` 这类异常，而不是再看重复的常规 monitor/volume 噪声。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_JdZd0aos3ryFz4MkXLHQbyBN__vscode-1774359791845/content.txt)

Ran terminal command:  rg -n "fail|error|protect|fault|interrupt|already start|start success|shutdown|mute state=1|mute state=0" '/Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_8fUagQGwWNKeXP1bfw7mGeOP__vscode-1774359791846/content.txt'

又多了一条负面证据：10 秒 helper 播放期间没抓到 `fail/protect/fault/error` 这类 AW 异常，只有每秒 route reinforce 带来的 `already start`，最后正常 `mute/shutdown`。我把这个也补到记录里，避免后面又回头怀疑“1 秒后是保护告警直接打断”。

Generating patch (75 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Updated memory file twrp_audio_session_open_two_error_planes_20260324.md

我再判断一下还有没有现成的“后级物理输出保持”证据可复用，重点看 DAPM / bias / Speaker_Playback 一类节点；如果仓库里已经做过这一层，就不重复抓了。

Ran terminal command:  rg -n "Speaker_Playback|bias_level|DAPM|speaker playback|codec bias|aw882xx_start_pa|start success.*1s|1s -> 8s|8s" docs/TWRP音频手动Bring-up-续.md docs/TWRP音频手动Bring-up.md memories/repo
Completed with input:  rg -n "Speaker_Playback|bias_level|DAPM|speaker playback|codec bias|aw882xx_start_pa|start success.*1s|1s -> 8s|8s" docs/TWRP音频手动Bring-up-续.md docs/TWRP音频手动Bring-up.md memories/repo

Read memory twrp_audio_aw882xx_frontier.md

继续推进后的增量结论：

1. 真实 helper 播放链并不是卡在 `pcm_start` 前后，它和 `agmplay` 一样，都能完整打到 AW 的成功面：
   - `aw882xx_startup`
   - `aw882xx_hw_params`
   - `aw882xx_start_pa: start success`
   - 结束时正常 `mute=1` 和 `shutdown`

2. helper 自身日志里 `PCM100 connect` 依然一直是 `ZERO`，但这并没有阻止 AW 进入 `start success`。
   - 所以 `PCM100 connect=ZERO` 现在更像“稳定异常表征”
   - 还不能直接把它当成“PA 起不来”的根因

3. 10 秒 helper 播放又复测了一轮：
   - `audio_ms` 从 `1000` 一直推进到 `10000`
   - `wall_ms` 仍然基本同步
   - 最终正常 `play_tone done`

4. 10 秒持续阶段的 `dmesg` 里，目前没抓到这类硬故障证据：
   - `start failed`
   - `protect`
   - `fault`
   - `error`
   - 中途 `shutdown`

5. 播放过程中能稳定看到的，主要还是 route reinforce 带来的 `aw882xx_start_pa: already start`，最后再正常 `mute/shutdown`。
   - 这说明当前也不适合再优先怀疑“约 1 秒后被 AW 保护直接切断”

我已经把这些结果追加进实验记录和仓库记忆里了。

当前前沿因此又往后收了一层：

1. 不是 helper 同进程复用污染
2. 不是 graph / connect / PA 首次 bring-up 失败
3. 不是目前日志可见的 AW 保护/故障在 1 秒处直接打断

更像的问题边界是：

1. 用户态持续写流是正常的
2. AW PA 也确实已经进入成功态
3. 但“持续可闻输出”没有稳定维持下来

下一步最值钱的两个方向是：

1. 直接抓当前这版 helper 播放时 `1s` 和 `8s` 的 DAPM / `bias_level` / `Speaker_Playback_*` 现场，确认后级物理输出保持有没有掉态
2. 如果这层也稳定，再往 FE/BE 数据面继续收，找 recovery 下是否缺少某个持续维持的后端状态，而不是启动状态

Made changes.

User: 继续

GitHub Copilot: 我继续往“后级物理输出保持”推进，先复用仓库里已有的 DAPM/bias 采样线索；如果路径还有效，就直接在当前 helper 10 秒播放里抓 `1s` 和 `8s` 两个现场。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_RFlVpzfvD4RIOR3Q6XbR2slT__vscode-1774359791851/content.txt)

Ran terminal command:  rg -n "Speaker_Playback|bias_level|dapm|stream active|widget.*Off|widget.*On|codec bias|card0.*bias" docs/TWRP音频手动Bring-up.md docs/TWRP音频手动Bring-up-续.md

Ran terminal command:  adb shell 'find /sys -iname "*bias_level*" -o -iname "*Speaker_Playback*" 2>/dev/null | head -n 120'

现成路径已经有了，我直接做当前 helper 10 秒播放的实时采样：在播放后台运行时抓 `1s` 和 `8s` 两拍的 `bias_level` 与 `Speaker_Playback_*`，看它是否还停留在过去那组“PA success 但 DAPM 仍 Off”的骨架。

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --play-seconds 10'

Ran terminal command:  sleep 1.2 && adb shell 'for p in /sys/kernel/debug/asoc/sun-mtp-snd-card/dapm/bias_level /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0034/dapm/bias_level /sys/kernel/debug/asoc/sun-mtp-snd-card/soc:spf_core_platform:lpass-cdc/dapm/bias_level /sys/kernel/debug/asoc/sun-mtp-snd-card/wcd939x-codec/dapm/bias_level /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0034/dapm/Speaker_Playback_4_34; do echo ==== $p; cat $p 2>/dev/null; done'

Ran terminal command:  sleep 8 && adb shell 'for p in /sys/kernel/debug/asoc/sun-mtp-snd-card/dapm/bias_level /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0034/dapm/bias_level /sys/kernel/debug/asoc/sun-mtp-snd-card/soc:spf_core_platform:lpass-cdc/dapm/bias_level /sys/kernel/debug/asoc/sun-mtp-snd-card/wcd939x-codec/dapm/bias_level /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0034/dapm/Speaker_Playback_4_34; do echo ==== $p; cat $p 2>/dev/null; done'

当前 helper 路径在本次实时采样里更偏“彻底不亮”而不是“1 秒后掉态”：`1s` 和 `8s` 都是 `bias=Off`，而且 `Speaker_Playback_4_34` 一直 `inactive`。我补读这次后台播放自身输出，确认是不是这轮根本没进入有效播放窗口。

Awaited terminal completion

这轮后台播放本身确实完整跑了 10 秒，但实时 DAPM 采样却完全没亮。我再补一刀内核侧 AW 启停序列，确认这次是不是连 `start success` 都没出现，还是又出现了“PA success 与 DAPM inactive 并存”的分叉。

Ran terminal command:  adb shell 'dmesg | grep -E "aw882xx_(startup|hw_params|start_pa|shutdown|mute)" | tail -n 120'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_lp5E4JCVWb1ApjfHcDsG4tXv__vscode-1774360490899/content.txt)

这轮已经形成一个新分叉：同一轮里 AW 明确 `start success`，但我抽的 `Speaker_Playback_4_34` 仍是 `inactive`。我补一轮 3 秒短播放，把 6 路 `Speaker_Playback_*` 一次性全抓出来，确认是不是单节点巧合。

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --play-seconds 3'

Ran terminal command:  sleep 1.2 && adb shell 'for p in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*-*/dapm/Speaker_Playback_*; do echo ==== $p; cat $p 2>/dev/null; done'

6 路都一样，说明不是单节点巧合。我等这轮短播放收尾，然后把这个“AW `start success` 与全部 `Speaker_Playback_* inactive` 并存”的新边界落到记录里。

Awaited terminal completion

我同步一下任务状态，避免旧计划还停在“定位入口”这一步。现在入口定位和真实链路验证已经做完，当前主要在补日志和收紧结论边界。

Starting: *补日志与结论* (4/4)

我把这轮最关键的新矛盾记下来：同一轮 helper 播放里，用户态持续 10 秒、AW 也 `start success`，但实时抓到的 6 路 `Speaker_Playback_*` 和各级 `bias_level` 仍全部 `Off/inactive`。这会直接影响后面怎么解读 DAPM 证据。

Generating patch (84 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Updated memory file twrp_audio_aw882xx_frontier.md

DAPM 这条线的判别力已经明显不够了。我再补一个更靠近数据面的观察：播放窗口里直接读 ALSA PCM runtime 状态，看当前子流在 `1s` 和 `8s` 是不是仍保持 `RUNNING`，而不是只剩用户态自说自话。

Ran terminal command:  adb shell 'find /proc/asound -path "*/sub*/status" | sort'

Ran terminal command:  adb shell 'cat /proc/asound/pcm'

`/proc/asound/pcm` 还在，但当前 recovery 没把常见的 `sub0/status` 节点直接列出来。我补一刀对目标后端的目录结构，看这条内核接口是不是根本没导出。

Ran terminal command:  adb shell 'ls -R /proc/asound/card0/pcm16p 2>/dev/null | head -n 80'

这条 ALSA runtime 状态接口在当前 recovery 看起来没导出来，我再确认一下 `card0` 下面到底暴露了哪些子目录，避免在不存在的路径上浪费时间。

Ran terminal command:  adb shell 'ls /proc/asound/card0 2>/dev/null'

这轮又把边界往后压了一层，新增结论有三条：

1. 当前 helper 主线里，`AW start success` 和 `DAPM/Speaker_Playback 全灭` 可以在同一轮实测里并存。
   - 后台跑 `agm_audio_minimal_bin --play-seconds 10` 时，用户态仍完整推进到 `10000ms`
   - 同一轮内核日志仍明确出现：
     - `aw882xx_startup`
     - `aw882xx_hw_params`
     - `aw882xx_start_pa: start success`
     - 最后正常 `mute=1` 和 `shutdown`
   - 但实时采样到的：
     - `sun-mtp-snd-card / lpass-cdc / wcd939x / aw882xx_smartpa` 的 `bias_level` 全是 `Off`
     - `Speaker_Playback_4_34` 在 `1s` 和 `8s` 都是 `Off + stream inactive`

2. 这不是单节点巧合。
   - 我又补了一轮 3 秒 helper 播放
   - 在约 `1.2s` 一次性抓了 6 路 `Speaker_Playback_*`
   - 结果 6 路全部都是：
     - `Off`
     - `stream inactive`

3. 因此，当前 recovery 场景下，这组 DAPM/sysfs 节点已经不能再当作可靠的“是否真的在持续放音”判据。
   - 不能再简单把 `bias_level=Off` 推成“后级一定没工作”
   - 也不能再把 `Speaker_Playback_* inactive` 直接推成“这一轮根本没播”
   - 因为就在同一轮里，用户态 10 秒写流和 AW `start success` 都已经成立

另外我还试了一步更靠近数据面的验证：

1. 想从 `/proc/asound` 里抓 ALSA PCM runtime `status`
2. 但当前 recovery 只暴露了 `card0/codecs` 和 `card0/id`
3. 常见的 `pcmXXp/sub0/status` 这类接口没导出来，所以这条路现在拿不到可用证据

我已经把这轮结果补进实验记录和仓库记忆了。

当前前沿因此变成：

1. 不是 helper 同进程污染
2. 不是 AW 没 `start success`
3. 不是已见日志里的 AW `protect/fault/error`
4. 也不是当前这组 DAPM/sysfs 能稳定解释播放真值

更接近的结论是：

1. 用户态真实时长正常
2. AW 驱动启停也正常
3. 但 recovery 下“持续可闻输出”的真值，已经不能靠当前 DAPM/sysfs 节点判断

下一步最自然的两个方向是：

1. 去抓更靠近物理输出面的证据，比如 AW 寄存器或更低层运行态，在同一轮 helper 播放下做 `idle / 1s / 8s` 对照
2. 反过来做有声基线对照，把当前 helper 播放窗口和历史“确认可闻”的基线放到同一套采样脚本里，找第一处真正分叉的低层状态

如果你继续让我推进，我下一轮会直接走第 1 条，不再重复 DAPM 这组低判别力节点。

Made changes.

User: 继续

GitHub Copilot: 我直接转向更低层 AW 现场，先复用之前已经跑通过的寄存器/深层 sysfs 采样路径，然后在当前 helper 播放窗口下做 `idle / 1s / 8s` 对照。

Ran terminal command:  rg -n "4-0034/reg|dsp_re|re_show|f0_show|monitor|idle / 1s / 8s|寄存器快照|reg snapshot|aw882xx_smartpa.4-0034/reg" docs/TWRP音频手动Bring-up-续.md docs/TWRP音频手动Bring-up.md

Read memory twrp_audio_aw882xx_frontier.md

我已经拿到低层采样线索：前面真正有信息量的是 `/sys/bus/i2c/devices/4-0034/reg` 和 `dsp_re/re_show/f0_show/monitor`，不是 DAPM。下一步我直接在当前 helper 播放窗口里抓这组 `idle / 1s / 8s` 对照。

Read memory twrp_audio_aw882xx_frontier.md

Ran terminal command:  adb shell 'for p in /sys/bus/i2c/devices/4-0034/reg /sys/bus/i2c/devices/4-0034/dsp_re /sys/bus/i2c/devices/4-0034/re_show /sys/bus/i2c/devices/4-0034/f0_show /sys/bus/i2c/devices/4-0034/monitor; do echo ==== $p; head -n 80 $p 2>/dev/null; done'

我先补读前面那轮寄存器对照里真正有判别力的寄存器位，避免这次盲抓整份 `reg` 又淹没在噪声里。然后我只盯那几组在 `1s -> 8s` 有过变化的值。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#1408-1408), lines 1408 to 1456

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#1514-1514), lines 1514 to 1534

我现在只盯前面证明最有信息量的寄存器位和 4 个深层节点，直接做当前 helper 路径的 `idle / 1s / 8s` 低层对照，结果要么把“工作态仍在”复现出来，要么说明 helper 路径和旧基线在更低层已经分叉。

Ran terminal command:  adb shell 'echo ==== reg; cat /sys/bus/i2c/devices/4-0034/reg 2>/dev/null | grep -E "^reg:0x(04|08|20|23|24|25|26|28|2b)="; echo ==== dsp_re; cat /sys/bus/i2c/devices/4-0034/dsp_re 2>/dev/null; echo ==== re_show; cat /sys/bus/i2c/devices/4-0034/re_show 2>/dev/null; echo ==== f0_show; cat /sys/bus/i2c/devices/4-0034/f0_show 2>/dev/null; echo ==== monitor; cat /sys/bus/i2c/devices/4-0034/monitor 2>/dev/null'

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --play-seconds 10'

Ran terminal command:  sleep 1.2 && adb shell 'echo ==== reg; cat /sys/bus/i2c/devices/4-0034/reg 2>/dev/null | grep -E "^reg:0x(04|08|20|23|24|25|26|28|2b)="; echo ==== dsp_re; cat /sys/bus/i2c/devices/4-0034/dsp_re 2>/dev/null; echo ==== re_show; cat /sys/bus/i2c/devices/4-0034/re_show 2>/dev/null; echo ==== f0_show; cat /sys/bus/i2c/devices/4-0034/f0_show 2>/dev/null; echo ==== monitor; cat /sys/bus/i2c/devices/4-0034/monitor 2>/dev/null'

Ran terminal command:  sleep 8 && adb shell 'echo ==== reg; cat /sys/bus/i2c/devices/4-0034/reg 2>/dev/null | grep -E "^reg:0x(04|08|20|23|24|25|26|28|2b)="; echo ==== dsp_re; cat /sys/bus/i2c/devices/4-0034/dsp_re 2>/dev/null; echo ==== re_show; cat /sys/bus/i2c/devices/4-0034/re_show 2>/dev/null; echo ==== f0_show; cat /sys/bus/i2c/devices/4-0034/f0_show 2>/dev/null; echo ==== monitor; cat /sys/bus/i2c/devices/4-0034/monitor 2>/dev/null'

这轮结果比 DAPM 还硬：`4-0034` 的关键寄存器位和 `dsp_re/re_show/f0_show/monitor` 在 `idle / 1s / 8s` 三拍里完全没变。我再把这同一轮的 helper 输出和 AW 启停日志收尾对上，确认不是采样撞空窗口。

Awaited terminal completion

Ran terminal command:  adb shell 'dmesg | grep -E "aw882xx_(startup|hw_params|start_pa|shutdown|mute)" | tail -n 120'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_08osi5LW2vI7vDBK5lU7hI22__vscode-1774360490922/content.txt)

我继续把矛盾下压到 6 颗 AW 横向层面，避免 `4-0034` 只是个误导样本：直接看 6 个器件在 `idle` 和 `1s` 时这几组关键寄存器位有没有分化。

Ran terminal command:  adb shell 'for d in 4-0034 4-0035 4-0036 9-0034 9-0035 9-0036; do echo ==== $d; cat /sys/bus/i2c/devices/$d/reg 2>/dev/null | grep -E "^reg:0x(04|08|20|23|24|25|26|28|2b)="; done'

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --play-seconds 3'

Ran terminal command:  sleep 1.2 && adb shell 'for d in 4-0034 4-0035 4-0036 9-0034 9-0035 9-0036; do echo ==== $d; cat /sys/bus/i2c/devices/$d/reg 2>/dev/null | grep -E "^reg:0x(04|08|20|23|24|25|26|28|2b)="; done'

结果已经够硬，不需要再猜 `4-0034` 是不是特例了：6 颗 AW 的关键寄存器位在 `idle` 和 helper 播放 `1s` 完全一致，而同一阶段 AW 日志仍然是 `start success`。我先把这条边界固化进记录，再决定要不要继续追更底层的真值源。

Generating patch (113 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Updated memory file twrp_audio_aw882xx_frontier.md

我继续把“可读寄存器是不是完全失真”这个问题做成横向对照，不只看 helper：用同一套采样去抓一轮 `agmplay`，看这些关键寄存器位在 `1s` 会不会进入工作态。

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY -dkv 0xA2000001 -ikv 1 -skv 0xA100000E -dppkv 0xAC000002'

Ran terminal command:  sleep 1.2 && adb shell 'for d in 4-0034 4-0035 4-0036 9-0034 9-0035 9-0036; do echo ==== $d; cat /sys/bus/i2c/devices/$d/reg 2>/dev/null | grep -E "^reg:0x(04|08|20|23|24|25|26|28|2b)="; done'

Ran terminal command:  sleep 1.2 && adb shell 'for p in /sys/kernel/debug/asoc/sun-mtp-snd-card/dapm/bias_level /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0034/dapm/Speaker_Playback_4_34; do echo ==== $p; cat $p 2>/dev/null; done'

这轮横向对照终于出来了：同样的 1 秒采样下，`agmplay` 会把 6 颗 AW 寄存器明确推到工作态，而 helper 不会。也就是说，两条链在更低层终于出现了可复现的真正分叉。 আমি先把后台 `agmplay` 收尾对齐，再把这个结论落进文档。

Awaited terminal completion

Ran terminal command:  adb shell 'dmesg | grep -E "aw882xx_(startup|hw_params|start_pa|shutdown|mute)" | tail -n 80'

我顺着刚找到的真实分叉继续下钻到代码常量，不停在“现象不一样”：下一步直接对照 helper 里写死的 metadata/kv 与 `agmplay` 命令行参数，看它们到底差在哪。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#700-700), lines 700 to 960

Ran terminal command:  rg -n "A2000001|A100000E|AC000002|PCM_LL_PLAYBACK|STREAM_KV|INSTANCE|device metadata|streamdevice|audio intf metadata|689c|6a54|PCM100" video_player/agm_audio_minimal.c video_player/agm_audio_minimal.h

这一步已经把“差异到底在哪一层”从模糊现象变成了可复现的实验结果：同样 `start success`，只有 `agmplay` 会把 6 颗 AW 寄存器真正推到工作态。我要把这条结论写进记录，后面才有资格回到代码改动。

Generating patch (91 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Updated memory file twrp_audio_aw882xx_frontier.md

现在线索已经从“日志像不像”收敛到“`agmplay` 能把 AW 寄存器推活，helper 不能”。我再往代码里补最后一刀静态对照，确认 helper 在 `pcm_open` 这层选的 card/device/format 是否和 `agmplay` 的有效路径存在硬差异。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#1-1), lines 1 to 180

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#1090-1090), lines 1090 to 1185

Ran terminal command:  rg -n "#define AGM_PCM_CARD|#define AGM_PCM_DEVICE|pcm_config\.channels|pcm_config\.format|pcm_open\(|AGM_PRIMARY_INTF|AGM_BACKEND_RATE|AGM_BACKEND_CHANNELS|AGM_BACKEND_BITS" video_player/agm_audio_minimal.c

我不先改代码，先做一个代价更低的分叉排除：helper 当前跑的是 8ch32 纯音，而 `agmplay` 日志里读的是 2ch16 WAV。我先确认 helper CLI 是否能直接播同一个 WAV，如果可以，就用同一套 1 秒寄存器采样看差异是不是来自“输入形态”而不是“helper 路径本身”。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal_main.c)

Ran terminal command:  rg -n "Usage:|--play-seconds|wav|argv\[|open-close-cycles|play-cycles|play_wav|tone" video_player/agm_audio_minimal_main.c

helper 支持直接播 WAV，我现在就用和 `agmplay` 同一个 `test440_mid_10s.wav` 做对照。这样可以把“8ch32 纯音生成”和“helper 路径本身”这两个变量拆开。

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --wav /data/local/tmp/test440_mid_10s.wav'

Ran terminal command:  sleep 1.2 && adb shell 'for d in 4-0034 4-0035 4-0036 9-0034 9-0035 9-0036; do echo ==== $d; cat /sys/bus/i2c/devices/$d/reg 2>/dev/null | grep -E "^reg:0x(04|08|20|23|24|25|26|28|2b)="; done'

Ran terminal command:  sleep 1.2 && adb shell 'for p in /sys/kernel/debug/asoc/sun-mtp-snd-card/dapm/bias_level /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0034/dapm/Speaker_Playback_4_34; do echo ==== $p; cat $p 2>/dev/null; done'

我把这个最后一个变量也收尾对齐：等 helper 的 WAV 路径跑完，确认它本身确实在播。这样就能把“输入样本差异”彻底排除掉。

Awaited terminal completion

输入样本这个变量也已经排干净了：helper 换成和 `agmplay` 同一个 2ch16 WAV 后，用户态仍然完整跑满 10 秒，但 1 秒时 6 颗 AW 寄存器还是完全停在 idle 图谱。我要把这条结论补进去，后面就可以把焦点彻底收敛到 helper 路径自身缺的那一步。

Generating patch (65 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Updated memory file twrp_audio_aw882xx_frontier.md

我不在这里停住，直接顺着新前沿去找“helper 比 agmplay 少的到底是哪一步”。先复用仓库里已有的 `graph_open/graph_start` 分析，不盲猜。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3218-3218), lines 3218 to 3252

Ran terminal command:  rg -n "graph_open|graph_start|graph.*start|agmplay.*graph|helper_connect|set_agm_streamdevice_metadata|set_agm_stream_metadata|set_agm_audio_intf_metadata|connect_agm_audio_intf_to_stream|set_agm_device_media_config" docs/TWRP音频手动Bring-up.md docs/TWRP音频手动Bring-up-续.md video_player

现成分析已经指出过关键边界：`agmplay` 的价值不只是 PCM 打流，而是它真正走到了 `graph_open/graph_start` 那条 agmmixer 编排链。结合我刚跑出来的对照，现在可以把前沿收得更硬。新增推进已经把主线真正收敛到 helper 和 `agmplay` 的用户态 bring-up 差异，不再是泛泛的“为什么只有 1 秒可闻”。

这轮最重要的结论有 4 条：

1. `helper` 与 `agmplay` 的差异，已经落到 AW 关键寄存器位这一层。
   - `agmplay` 在 `1.2s` 抓 6 颗 AW 时，全部都会从 idle 图谱进入明显工作态：
     - 例如 `0x04=0x3250/0x3650`
     - `0x20=0x81ac`
     - `0x23≈0x0166~0x016a`
     - `0x28=0x2708/0x4708`
     - `0x2b≈0x0169~0x02d9`
   - `helper` 在同样时间点、同样采样方法下，6 颗器件全部仍停在 idle 图谱：
     - `0x04=0x7353/0x7753`
     - `0x20=0x9300`
     - `0x23=0x0263`
     - `0x28=0x1708`
     - `0x2b=0x0000`

2. 这不是单颗器件误导。
   - 我先看了 `4-0034`
   - 然后横向扩到 `4-0034/35/36` 和 `9-0034/35/36`
   - 结果 helper 在 `idle -> 1s` 六颗全部不变

3. 这也不是 tone 和 WAV 输入形态差异。
   - helper 播放内部生成 tone 时，寄存器保持 idle
   - helper 直接播放和 `agmplay` 完全相同的 `/data/local/tmp/test440_mid_10s.wav` 时，用户态仍正常推进到 10 秒，但 1.2 秒寄存器仍全部保持 idle
   - 所以差异不在 `8ch32 tone` vs `2ch16 wav`

4. 当前可直接落地的前沿是：
   - `helper` 路径本身相较 `agmplay`，还缺了能把 AW 真正推进到工作态的关键一步
   - 这一步不是简单的：
     - PCM card/device 不同
     - 输入 WAV 不同
     - 通道数表象不同
   - 更像是 `graph_open/graph_start` 级别的 agmmixer 编排差异

我还顺手确认了 helper 代码里的常量：

1. `AGM_PCM_CARD = 100`
2. `AGM_PCM_DEVICE = 100`
3. `AGM_PRIMARY_INTF = TDM-LPAIF-RX-SECONDARY`
4. `AGM_DEVICE_KV_SPEAKER = 0xA2000001`
5. `AGM_DEVICEPP_KV_SPEAKER = 0xAC000002`
6. `AGM_STREAM_KV_PCM_LL_PLAYBACK = 0xA100000E`

也就是说，helper 并不是连这些最表层的 `kv/card/device/intf` 都写错了。它和 `agmplay` 表面参数已经很接近，但仍没有把 AW 寄存器推进到同一层级。

我已经把这几条补进实验记录和仓库记忆了。

当前最硬的工作结论可以写成一句话：

1. 不是 AW 节点全失真
2. 不是输入样本差异
3. 是 `helper` 路径本身相比 `agmplay` 少了关键的 graph / bring-up / 数据面推进动作

下一步最自然的是直接做这两个方向里的一个：

1. 继续静态对照 `helper` 和 Qualcomm 文档里的 `graph_open/graph_start` 所需序列，找 helper 当前还没做的调用
2. 在代码里给 helper 增加更接近 `agmplay` 的 graph 编排实验入口，然后编译实机验证 AW 寄存器是否能从 idle 跳到工作态

如果继续，我下一轮会直接走第 1 条，把缺失调用压到能改代码的粒度。

Made changes.

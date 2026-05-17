# 第1章：Route A200修正与首次无声确认

User: 你还知不知道核心任务是什么？

GitHub Copilot: 核心任务是：

1. 解决 recovery 音频实际只能听到约 1 秒，或者现在干脆完全无声的问题
2. 目标不是把日志、tag、miid 研究漂亮，而是恢复“人耳可闻、可持续”的播放
3. 所有分析都只是为这个服务，不是任务本身

如果更具体一点，当前真正的工程目标是：

1. 先重新拿回一个稳定的“可闻基线”
   - 哪条命令
   - 哪份二进制
   - 在当前设备当前环境下
   - 还能稳定听到声音多久

2. 再把“为什么 helper 路径退化成完全无声”定位清楚
   - 相比之前能响 1 秒的那条纯 C 路
   - 到底是哪一步改动把它带偏了

3. 最终要落到代码修复
   - 让 recovery 播放重新可闻
   - 最好能持续，不止 1 秒

你这个提醒是对的。最近几轮我虽然没有完全离开主线，但确实压得过深，过多聚焦在：

1. tag
2. miid
3. pre-connect 分叉

这些东西有价值，但它们只是中间证据。它们不能替代“把声音救回来”。

所以现在应该收回来，按核心任务做：

1. 不再优先加新观测
2. 先复现并确认“之前纯 C 响 1 秒”的那条真实基线
3. 再和当前版本做最小差异比对
4. 优先找出“从 1 秒退成完全无声”的直接回归点

一句话总结：

核心任务一直是修 recovery 播放，让声音重新出来并持续；不是做 AGM 图谱考古。

如果你要我继续，我下一步就按这个核心任务收束：
先验证当前环境里哪条历史纯 C 路径还能出声，再围绕“从 1 秒变成 0 秒”的回归点做最小回退对比。

User: 不是有整个文档，继续

GitHub Copilot: 我按现有文档把“1 秒可闻基线”重新捞出来，只做文档对齐和最小事实核对，目标是把主线从 tag/miid 拉回“哪条链曾经真的能出声、后来又是怎么退掉的”。

Searched for regex `1 秒|1s|可闻|纯 C|pure C|完全无声|无声|agm_audio_minimal|agmplay` (`**/docs/**`), 200 results

Searched for regex `1 秒|1s|可闻|纯 C|pure C|完全无声|无声|agm_audio_minimal|agmplay` (`**/video_player/**`), 100 results

Read memory twrp_audio_pure_c_frontier_20260318.md

Read memory twrp_audio_pure_c_frontier_20260319_mfc_breakthrough.md

我已经定位到一份专门的回退排查文档，下一步只读那份文档的关键段，把“当前到底退化到哪一层”从文档里钉实，然后再决定接下来是回退代码还是复测设备。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91Bring-up-%E5%9B%9E%E9%80%80%E6%8E%92%E6%9F%A5-20260325.md#1-1), lines 1 to 110

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91Bring-up-%E5%9B%9E%E9%80%80%E6%8E%92%E6%9F%A5-20260325.md#155-155), lines 155 to 340

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91Bring-up-%E5%9B%9E%E9%80%80%E6%8E%92%E6%9F%A5-20260325.md#428-428), lines 428 to 730

我用整份文档按时间顺序重新对齐了，关键不是文档开头那版假设，而是后半段的新结论：主线已经从“minimal 单路径回退”升级成“当前 recovery 整体可闻基线漂移”。下一步我只围绕文档最后几节继续，不再回到早期那套 minimal-only 假设。

Searched for regex `route|mixer|v14|v15|回退|backend_conf|WCNSS|usecaseKvManager|vendor.oplus.mm.ftm_spk|tinymix|speaker mixer|历史可闻期` (`**/docs/TWRP音频Bring-up-回退排查-20260325.md`), 55 results

Searched for regex `aw_dev_|WSA|VBAT|MUX|COMP|speaker mixer|tinymix_stock|route` (`**/docs/TWRP音频手动Bring-up*.md`), 200 results

Read memory twrp_audio_reboot_rebaseline_20260318.md

Read memory twrp_audio_recovery_tinymix_stock_baseline_only_20260323.md

文档最后几节已经给出一个比 AGM 细节更直接的动作点：当前 recovery 里，`play-test.sh` 自己那段额外 speaker baseline 很可能就是有害前置写入，我先对齐文档结论和脚本现状。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91Bring-up-%E5%9B%9E%E9%80%80%E6%8E%92%E6%9F%A5-20260325.md#1440-1440), lines 1440 to 1495

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/ossi_recovery_inject_20260319/payload/twrp-audio-play-test.sh)

脚本这一层已经和文档第 34 节对齐了，当前文件本身没有再犯“给 agmplay/tinyplay_ftm 强灌 baseline”的旧错；所以我继续沿文档更后的前沿走，转去看它最后收敛到的 `CustomConfig / 接力主位模板` 分叉。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/device_xml/20260325)

Searching for regex `CustomConfig|custom config|bridge|接力|A100000E|A2000001|AC000002|speaker` (`**/docs/TWRP音频Bring-up-回退排查-20260325.md`)

Searched for regex `A100000E|A2000001|AC000002|CustomConfig|DEVICEPP|speaker` (`**/docs/device_xml/20260325/**`), 200 results

User: 继续啊

GitHub Copilot: 我先按文档后半段的真实前沿收敛，不再回到早期假设；这一步只定位“CustomConfig / 接力主位模板”相关段落，目的是把下一跳动作从文档里直接抠出来。

Searched for regex `CustomConfig|接力主位模板|主位模板|接力` (`**/docs/**`), 80 results

Searched for regex `CustomConfig|接力主位模板|主位模板|接力` (`**/ossi_recovery_inject_20260319/**`), no results

Searched for regex `play-test|baseline|speaker baseline|额外 speaker|tinyplay_ftm|agmplay` (`**/docs/**`), 120 results

我已经把 pre-connect 分叉压到“两段 PCM100 metadata 的组合”上了；下一步不是再猜大方向，而是直接拆这两段 payload 里的字段，看看是哪一个词把 `tag19` 推到 `16584`。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#1018-1018), lines 1018 to 1078

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91Bring-up-%E5%9B%9E%E9%80%80%E6%8E%92%E6%9F%A5-20260325.md#15-15), lines 15 to 70

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91Bring-up-%E5%9B%9E%E9%80%80%E6%8E%92%E6%9F%A5-20260325.md#470-470), lines 470 to 610

文档和实测现在是一致的：当前不是“只有 minimal 退了”，而是 stock 也已经漂移；但在 helper 这条线上，pre-connect 的直接分叉已经压到 PCM100 metadata 组合，我继续把这两段里的关键字段拆开，不再做整段跳过。

Searched for regex `v4 主链|second regression|第二个回归点|PCM100 metadata 6a54|PCM100 metadata 689c|AB000000|A4000000|AC000000` (`**/docs/TWRP音频Bring-up-回退排查-20260325.md`), 1 result

Searched for regex `AGM_INSTANCE_KV|AGM_DEVICEPP_KV_SPEAKER|0xAB000000|0xA4000000|0xAC000000` (`**/video_player/agm_audio_minimal.c`), 8 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91Bring-up-%E5%9B%9E%E9%80%80%E6%8E%92%E6%9F%A5-20260325.md#66-66), lines 66 to 110

我先把两段 metadata 在旧文档里的已知语义捞出来，再决定拆哪个词最值；目标是只加最少的 A/B 开关，不做盲改。

Searched for regex `689c|6a54|AB000000|A4000000|AC000002|devicepp|instance_kv` (`**/docs/**`), 120 results

Read memory twrp_audio_devicepp_kv_frontier.md

Read memory twrp_audio_session_devicepp_gkv_20260318.md

旧文档里最像“有真实语义、值得试”的字段不是 `0xAC000002`，而是 `0xAB000000` 这组 graph_kv，因为设备 XML 里它本来就有 `1/2/3` 多个取值。我先查 pure C 现成有没有同类参数；有就直接复用思路，没有再给 minimal 补最小开关。

Searched for regex `metadata-6a54|AB000000|graph_kv|instance_kv|metadata_words\[3\]|metadata_words\[4\]|metadata_words\[5\]|metadata_words\[6\]` (`**/video_player/pure_c_agm_probe.c`), 39 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#1820-1820), lines 1820 to 1905

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2480-2480), lines 2480 to 2585

现成的 pure C 已经有几种 metadata 形态开关，我先看它们是不是足够覆盖“route 用 devicepp 还是 speaker”这类字段级 A/B；如果够，我优先用现成二进制验证，不再继续给 minimal 扩实验面。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2888-2888), lines 2888 to 2955

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#3208-3208), lines 3208 to 3268

Searched for regex `metadata-route-a200-speaker|metadata-route-ad-devicepp|metadata-689c-full-kv|metadata-6a54-min|metadata-6a54-plus-689c` (`**/docs/TWRP音频Bring-up-回退排查-20260325.md`), 3 results

我先用现成的 pure C 开关做一个最低成本的字段级 A/B，优先看 `689c route` 从 `devicepp` 改成 `speaker` 会不会把链路拉向别的子状态；这样能少一次代码扩实验面。

Searched for regex `metadata-route-a200-speaker|metadata-route-ad-devicepp` (`**/docs/TWRP音频Bring-up-回退排查-20260325.md`), no results

Ran terminal command:  adb shell 'ls -l /data/local/tmp/pure_c_agm_probe /data/local/tmp/test440_mid_10s.wav 2>&1'

设备侧 pure C 条件已经就绪。我接着跑两拍 route A/B，只比较“能否完整起播、日志里的 graph/devicepp 走向”，不再扩观测。

Ran terminal command:  adb shell 'LOG=/data/local/tmp/pure_c_route_default.log; rm -f "$LOG"; /data/local/tmp/pure_c_agm_probe --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --play-after-open --play-seconds 10 >"$LOG" 2>&1; rc=$?; echo rc=$rc; tail -n 120 "$LOG"'

Ran terminal command:  adb shell 'LOG=/data/local/tmp/pure_c_route_a200.log; rm -f "$LOG"; /data/local/tmp/pure_c_agm_probe --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --metadata-route-a200-speaker --play-after-open --play-seconds 10 >"$LOG" 2>&1; rc=$?; echo rc=$rc; tail -n 120 "$LOG"'

两拍都跑完了。我现在只抽关键结论：默认 route 和 A200 speaker route 是否在日志里真的分叉，以及有没有一拍更接近“可闻基线”。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_AHvApiDkbRGdT0bK3u6CumYh__vscode-1774436616861/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_Ya4YQNI6LQnu0Adw5VZgg0SW__vscode-1774436616862/content.txt)

结果出来了，而且是实质性分叉：pure C 里把 `689c route` 从默认 `devicepp` 改成 `A200 speaker` 后，tag 面直接从 `16 entry + 16584` 变成 `13 entry + 16472`，和当前 agmplay 成功窗同型。我现在把这个 route 开关补到 minimal，直接看 helper 路径能不能被拉回同一支。

Created memory file twrp_audio_route_a200_matches_agmplay_tag_surface_20260325.md

Generating patch (17 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.h)


```

```


Generating patch (24 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c)


```

```


Generating patch (21 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal_main.c)


```

```
route 开关已经补上。我接下来只跑一拍 minimal 的 A200 speaker route，看 helper 路径能不能也从 `16584` 拉回 `16472`，这是当前最值钱的验证。

Checked [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.h), [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c), [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal_main.c), 23 problems found

Ran terminal command:  bash ./video_player/build_agm_audio_minimal.sh && adb push video_player/agm_audio_minimal_bin /data/local/tmp/agm_audio_minimal_bin && adb shell chmod 755 /data/local/tmp/agm_audio_minimal_bin

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --force-rate-write --metadata-route-a200-speaker --wav /data/local/tmp/test440_mid_10s.wav'
Completed with input:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --force-rate-write --metadata-route-a200-speaker --wav /data/local/tmp/test440_mid_10s.wav'

我只抽 `before helper_connect` 和 `after helper_connect` 的 summary，不再铺整段日志；现在最关心的是 minimal 能不能也被拉回 `16472` 这支。

Searched for regex `AGM SUMMARY phase=before helper_connect|AGM SUMMARY phase=after helper_connect|runtime agm_mixer_get_miid: phase=before helper_connect|runtime agm_mixer_get_miid: phase=after helper_connect|entry\[` (`**//Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_LXBzO5tuSytGm9RsJ5wLgx6j__vscode-1774436616871/content.txt`), no results

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_LXBzO5tuSytGm9RsJ5wLgx6j__vscode-1774436616871/content.txt#1-1), lines 1 to 220

关键分叉已经找到了，而且已经成功移植到 minimal：只改 `689c route` 为 `A200 speaker`，helper 路径就从 `16 entry + 16584` 切到了 `13 entry + 16472`，和 agmplay 成功窗同型。现在我只补最后一个事实：这版 minimal 是继续失败，还是已经能完整跑满用户态。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_LXBzO5tuSytGm9RsJ5wLgx6j__vscode-1774436616871/content.txt#220-220), lines 220 to 255

差异已经进一步收紧了：pure C 用同类 metadata 路线可以 `rc=0` 跑满 10 秒，而 minimal 即便被拉到同型 `13 entry + 16472`，还是卡在 `pcm_open -5`。最值钱的下一拍就是去掉 minimal 这边额外的 `rate` 直写，看看是不是它把 helper 路拖回了失败面。

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --metadata-route-a200-speaker --wav /data/local/tmp/test440_mid_10s.wav'

我只看 summary 和结尾错误。这个实验的判定很简单：去掉 rate 直写后，minimal 是不是还卡在同一个 `pcm_open -5`。

Searched for regex `AGM SUMMARY phase=before helper_connect|AGM SUMMARY phase=before pcm_open|pcm_open failed|Command exited with code|agm_audio_minimal failed` (`**//Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_hVCHL1Il33stuDOoF3Wo1csp__vscode-1774436616875/content.txt`), no results

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_hVCHL1Il33stuDOoF3Wo1csp__vscode-1774436616875/content.txt#1-1), lines 1 to 220

Compacted conversation去掉 `--force-rate-write` 以后，tag surface 还是稳定停在 `13 entry + 16472`，但到 `before pcm_open` 这一步看起来还没脱离原故障。我继续把尾部日志读完，确认是否仍然是同一个 `-5`。Optimizing tool selection...

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_hVCHL1Il33stuDOoF3Wo1csp__vscode-1774436616875/content.txt#221-221), lines 221 to 320

结论开始收敛了：这次并没有 `pcm_open -5`，`pcm_prepare` 和 `pcm_start` 都成功，而且已经进入连续写流的 1s、2s、3s 进度点。我把最后一段读完，确认它是否完整跑到 10 秒。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_hVCHL1Il33stuDOoF3Wo1csp__vscode-1774436616875/content.txt#321-321), lines 321 to 375

现在可以明确一件事：真正的回归不是 helper 本身，也不是 `pcm_open` 固有失败，而是“`A200 speaker` 路由下再叠加 `force-rate-write` 会把本来能播放的链路打坏”。我接着查代码里这个强制直写是不是还在默认路径上被打开，以及 recovery 实际调用是不是仍然走旧的 `AC devicepp`。

Searched for regex `force_rate_ch_fmt_write|metadata_689c_route_tag|metadata_689c_route_value|metadata-route-a200-speaker|skip_helper_prep` (`**/video_player/**`), 31 results

Searched for regex `agm_audio_player_open\(|AgmAudioPlayerConfig|force_rate|metadata_689c|A200|AC000000|AC000002` (`**/*.{c,cc,cpp,h,hpp}`), 200 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#1384-1384), lines 1384 to 1548

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/video_player_ffi.c#264-264), lines 264 to 312

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal_main.c#77-77), lines 77 to 132

真实调用路径已经暴露出来了：FFI 侧本来就没有开 `force_rate_ch_fmt_write`，所以它当前最像失败基线的剩余差异，就是默认还在走 `AC devicepp`。我准备把 minimal 的默认 `689c` 路由改成 `A200 speaker`，让实际播放器默认落在刚验证通过的那条链路上。

Generating patch (14 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c)


```

```
我已经把库默认值切到 `A200 speaker`。下一步直接交叉编译，确认这次改动没有引入新的构建问题。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_agm_audio_minimal.sh
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_agm_audio_minimal.sh

构建脚本本身没执行权限。我改用 shell 显式执行它，不改文件权限，避免引入额外工作区噪音。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && sh ./build_agm_audio_minimal.sh

Checked [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.h), [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/video_player_ffi.c), [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c), [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal_main.c), 44 problems found

交叉编译通过了；编辑器里剩下的仍然是之前那批 host 侧假报错，不是这次改动引入的。我把这个新结论记到 repo memory，避免下次又从 `pcm_open -5` 误判开始绕圈。

Read memory

Read memory twrp_audio_rate_ch_fmt_int_control_write_20260325.md

Read memory twrp_audio_route_a200_matches_agmplay_tag_surface_20260325.md

Inserted into memory file twrp_audio_route_a200_matches_agmplay_tag_surface_20260325.md

代码层面的根因修正已经做了，但还差最后一步闭环：把新二进制推到设备上，验证“默认配置”不带任何实验参数也能走通。这个验证比只看 host 侧 build 更关键。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && adb push ./agm_audio_minimal_bin /data/local/tmp/agm_audio_minimal_bin && adb push ./libagm_audio_minimal.so /data/local/tmp/libagm_audio_minimal.so && adb shell 'chmod 755 /data/local/tmp/agm_audio_minimal_bin && setprop vendor.oplus.mm.ftm_spk 1 && LD_LIBRARY_PATH=/data/local/tmp:/mnt/system_a/system/lib64:/system/lib64:/vendor/lib64:/vendor/lib64/hw /data/local/tmp/agm_audio_minimal_bin --wav /data/local/tmp/test440_mid_10s.wav'

Searched for regex `pcm_open failed|pcm_prepare rc|pcm_start rc|play_wav progress|play_wav done|AGM SUMMARY phase=before helper_connect|AGM SUMMARY phase=before pcm_open` (`**//Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_rzccLtVZoJMQY0gbSfrnu6AD__vscode-1774436616893/content.txt`), no results

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_rzccLtVZoJMQY0gbSfrnu6AD__vscode-1774436616893/content.txt#1-1), lines 1 to 260

设备侧默认路径也已经落在 `13 entry + 16472`，而且 `pcm_prepare/start` 成功。最后只差确认它是不是同样完整写满 10 秒。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_rzccLtVZoJMQY0gbSfrnu6AD__vscode-1774436616893/content.txt#261-261), lines 261 to 377

Inserted into memory file twrp_audio_route_a200_matches_agmplay_tag_surface_20260325.md

已经把问题收敛并做了根因修正。

这次确认的结论是：

1. 真正的回归点不是 helper 本身，也不是 `pcm_open` 天生不稳定。
2. 关键组合是：
   - `689c route` 要走 `A200 speaker`
   - 不能再叠加 `force_rate_ch_fmt_write`
3. 之前 minimal 卡在 `pcm_open -5`，是因为虽然已经切到了 `13 entry + miid=16472` 分支，但同时还开着 `force-rate-write`，把这条本来可播的链路重新打坏了。

我已经做的改动：

1. 把 minimal 默认配置里的 `689c route` 从 `AC devicepp` 改成了 `A200 speaker`
2. 保持默认 `force_rate_ch_fmt_write=0`
3. 重新编译了 `libagm_audio_minimal.so` 和 `agm_audio_minimal_bin`

我随后做了设备侧闭环验证，不是只看 host build：

1. 把新库和新二进制推到设备
2. 直接用默认配置执行 WAV 播放，不带任何实验参数
3. 结果是：
   - `before helper_connect` 就稳定落在 `13 entry + miid=16472`
   - `pcm_prepare rc=0`
   - `pcm_start rc=0`
   - 播放进度从 `1000/10000` 一直到 `10000/10000`
   - 最后出现 `play_wav done`

这说明“默认路径”已经不再是之前那个 `pcm_open -5` 的坏分支，而是能完整跑满 10 秒的分支。

补充一点很重要：

1. FFI 实际调用路径本来就没有默认开启 `force_rate_ch_fmt_write`
2. 所以对 recovery 实际播放链路来说，这次真正需要落地的修正就是默认 route 从 `AC` 切到 `A200`
3. 这也是为什么改完默认值以后，默认播放直接恢复到完整 10 秒

当前剩余风险只有一个：

1. 我能确认“用户态播放链路”现在已经完整跑满 10 秒
2. 但我还不能仅凭日志证明扬声器侧“实际可闻声”就一定完全恢复
3. 如果你现场听感仍然只有约 1 秒或者仍异常，那下一步就不该再回到 AGM 路由分支本身，而要继续盯 AW/功放侧的瞬态衰减或硬件保持条件

顺手说明下验证状态：

1. 交叉编译通过
2. 编辑器里的报错仍是之前那批 host 侧缺 Android/FFmpeg 头文件的假报错，不是这次改动引入的

下一步如果你要我继续，我建议直接做这两个之一：

1. 把这套默认修正接到 recovery 实际播放器路径上，再做一次真实可闻验证
2. 如果你已经现场确认“日志 10 秒但听感仍异常”，我就直接转去抓 AW 侧 1 秒后衰减/静音边界，不再浪费时间回看 `pcm_open -5` 这条线

Made changes.

User: 你告诉我怎么听啊，命令！！！

GitHub Copilot: 直接播外放，执行这几条：

```sh
cd '/Volumes/Case-sensitive APFS/TWRP/video_player'
adb push ./agm_audio_minimal_bin /data/local/tmp/agm_audio_minimal_bin
adb push ./libagm_audio_minimal.so /data/local/tmp/libagm_audio_minimal.so
adb shell 'chmod 755 /data/local/tmp/agm_audio_minimal_bin && setprop vendor.oplus.mm.ftm_spk 1 && LD_LIBRARY_PATH=/data/local/tmp:/mnt/system_a/system/lib64:/system/lib64:/vendor/lib64:/vendor/lib64/hw /data/local/tmp/agm_audio_minimal_bin --wav /data/local/tmp/test440_mid_10s.wav'
```

如果测试音频还没在设备上，先补这一条：

```sh
adb push /data/local/tmp/test440_mid_10s.wav /data/local/tmp/test440_mid_10s.wav
```

如果你想先只在设备里直接重播，不重新 push，最短就是这一条：

```sh
adb shell 'setprop vendor.oplus.mm.ftm_spk 1 && LD_LIBRARY_PATH=/data/local/tmp:/mnt/system_a/system/lib64:/system/lib64:/vendor/lib64:/vendor/lib64/hw /data/local/tmp/agm_audio_minimal_bin --wav /data/local/tmp/test440_mid_10s.wav'
```

你现在就该听设备扬声器外放那段 10 秒测试音。  
如果你要，我下一条直接给你“循环播放”的命令。

User: 没有一点声音

GitHub Copilot: 你这句很关键，说明现在是“用户态 10 秒写流成功，但扬声器完全无声”。我先不再盯 `pcm_open`，直接抓一次“播放期间的实时状态”和功放相关日志，判断是后端静音、功放没起，还是起了但幅度被压没了。

Ran terminal command:  adb shell 'getprop vendor.oplus.mm.ftm_spk'

Ran terminal command:  adb shell 'LD_LIBRARY_PATH=/data/local/tmp:/mnt/system_a/system/lib64:/system/lib64:/vendor/lib64:/vendor/lib64/hw /data/local/tmp/agm_audio_minimal_bin --snapshot-only'

Ran terminal command:  adb shell 'dmesg | tail -n 120'

现状很清楚了：属性已经是 `1`，AGM 侧默认也还在 `miid=16472` 这条可播分支上，所以“无声”已经基本缩到功放/AW 侧而不是 AGM 路由。下一步我只看内核尾日志，确认播放时 AW 是没启动、启动后秒停，还是一直工作但没有实际幅度。

Searched for regex `aw|AW|audio|speaker|spk|pa|mute|shutdown|startup|hw_params|monitor|wsa|rx` (`**//Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_M7jbJPnBunQi8xdKRTVu8X8c__vscode-1774436616900/content.txt`), no results

Ran terminal command:  adb shell 'ls /sys/devices/platform | grep -i aw'
Completed with input:  adb shell 'ls /sys/devices/platform | grep -i aw'

Ran terminal command:  adb shell 'find /sys -maxdepth 4 -iname "*aw882*" 2>/dev/null | head -n 40'

AW 驱动节点是有的，说明不是“驱动根本没起来”。我现在直接读 AW 的 sysfs 状态，看看是不是功放在线但被静音/未启动。

Ran terminal command:  adb shell 'ls -1 /sys/class/misc/aw882xx_smartpa'

Ran terminal command:  adb shell 'find /sys/class/misc/aw882xx_smartpa -maxdepth 2 -type f | sort | head -n 120'

Ran terminal command:  adb shell 'for f in /sys/class/misc/aw882xx_smartpa/*; do if [ -f "$f" ]; then echo ===$f===; cat "$f"; fi; done'

顶层 misc 节点没暴露状态文件，得往 I2C 驱动实例里看。也就是说驱动在，但真正的寄存器/运行态信息不在 misc 根目录。

Ran terminal command:  adb shell 'find /sys/bus/i2c/drivers/aw882xx_smartpa -maxdepth 2 | sort | head -n 120'

Ran terminal command:  adb shell 'find /sys/bus/i2c/drivers/aw882xx_smartpa -maxdepth 3 -type f | sort | head -n 200'

Ran terminal command:  adb shell 'find /sys -maxdepth 6 \( -iname "*aw*prof*" -o -iname "*aw*reg*" -o -iname "*smartpa*" -o -iname "*monitor*" -o -iname "*volume*" \) 2>/dev/null | head -n 200'

AW 的可观察入口在 debugfs/asoc 下面，不在普通 sysfs。下一步我直接看这 6 颗功放实例的 debugfs 内容，抓是否有 `reg`、`profile`、`status` 一类节点。

Ran terminal command:  adb shell 'for d in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*; do echo ===$d===; ls -1 "$d"; done'

Ran terminal command:  adb shell 'for d in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*; do for f in "$d"/*; do if [ -f "$f" ]; then echo ===$f===; cat "$f"; fi; done; done'

debugfs 这里只有 `dapm`，这足够判断功放通路有没有真正被点亮。我要在播放进行中的第 1 秒抓一次 6 颗 AW 的 DAPM 状态，看看是整条通路都没亮，还是亮了但依旧无声。

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; LD_LIBRARY_PATH=/data/local/tmp:/mnt/system_a/system/lib64:/system/lib64:/vendor/lib64:/vendor/lib64/hw /data/local/tmp/agm_audio_minimal_bin --wav /data/local/tmp/test440_mid_10s.wav >/dev/null 2>&1 & sleep 1; for d in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*; do echo ===$d===; cat "$d"/dapm; done'
Completed with input:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; LD_LIBRARY_PATH=/data/local/tmp:/mnt/system_a/system/lib64:/system/lib64:/vendor/lib64:/vendor/lib64/hw /data/local/tmp/agm_audio_minimal_bin --wav /data/local/tmp/test440_mid_10s.wav >/dev/null 2>&1 & sleep 1; for d in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*; do echo ===$d===; cat "$d"/dapm; done'

`dapm` 下面还是目录，不是单文件。我要把它展开一层，直接找里面的 widget 状态文件。

Ran terminal command:  adb shell 'for d in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*; do echo ===$d/dapm===; find "$d"/dapm -maxdepth 2 | sort | head -n 80; done'

Ran terminal command:  adb shell 'find /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.* /sys/kernel/debug/asoc/sun-mtp-snd-card/*/dapm -maxdepth 2 -type f 2>/dev/null | head -n 200'

DAPM 入口找到了，问题可以直接落到每颗功放的 `Speaker_Playback_*` 和 `bias_level`。我现在抓“播放时”的这些状态，判断是不是 6 颗里根本没有一路进入 ON。

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; LD_LIBRARY_PATH=/data/local/tmp:/mnt/system_a/system/lib64:/system/lib64:/vendor/lib64:/vendor/lib64/hw /data/local/tmp/agm_audio_minimal_bin --wav /data/local/tmp/test440_mid_10s.wav >/dev/null 2>&1 & sleep 1; for d in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*; do echo ===$d===; cat "$d"/dapm/bias_level; for f in "$d"/dapm/Speaker_Playback_*; do echo ---$f---; cat "$f"; done; done'

定位出来了：播放线程确实在跑，但 6 颗 AW 的 `Speaker_Playback_*` 在播放第 1 秒全部还是 `Off`，只是 `stream ... active`。这说明流已经到 ASoC，但功放 widget 根本没被真正点亮，所以“完全没声音”是符合现象的。下一步我抓整张声卡里到底是谁在亮，确认流被路由去了哪里。

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; LD_LIBRARY_PATH=/data/local/tmp:/mnt/system_a/system/lib64:/system/lib64:/vendor/lib64:/vendor/lib64/hw /data/local/tmp/agm_audio_minimal_bin --wav /data/local/tmp/test440_mid_10s.wav >/dev/null 2>&1 & sleep 1; find /sys/kernel/debug/asoc/sun-mtp-snd-card -path "*/dapm/*" -type f 2>/dev/null | while read f; do s=$(cat "$f" 2>/dev/null); case "$s" in *active*|*On*) echo ===$f===; echo "$s"; fi; done'
Completed with input:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; LD_LIBRARY_PATH=/data/local/tmp:/mnt/system_a/system/lib64:/system/lib64:/vendor/lib64:/vendor/lib64/hw /data/local/tmp/agm_audio_minimal_bin --wav /data/local/tmp/test440_mid_10s.wav >/dev/null 2>&1 & sleep 1; find /sys/kernel/debug/asoc/sun-mtp-snd-card -path "*/dapm/*" -type f 2>/dev/null | while read f; do s=$(cat "$f" 2>/dev/null); case "$s" in *active*|*On*) echo ===$f===; echo "$s"; fi; done'

Ran terminal command:  adb shell 'find /sys/kernel/debug/asoc/sun-mtp-snd-card -path "*/dapm/*" -type f 2>/dev/null | grep -E "Speaker|SPK|RX|WSA|AMP|DAC|AIF|LPAIF" | head -n 300'

上一个全卡扫描命令写法撞到了设备端 `sh` 的 case 语法，我直接换成更保守的 while/if 版本，不再浪费这一轮。先顺手把外放相关节点名读出来，再抓一次 active widget。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_huQGOGxXx1NB0rdGnXLc9gEM__vscode-1774436616917/content.txt)

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; LD_LIBRARY_PATH=/data/local/tmp:/mnt/system_a/system/lib64:/system/lib64:/vendor/lib64:/vendor/lib64/hw /data/local/tmp/agm_audio_minimal_bin --wav /data/local/tmp/test440_mid_10s.wav >/dev/null 2>&1 & sleep 1; find /sys/kernel/debug/asoc/sun-mtp-snd-card -path "*/dapm/*" -type f 2>/dev/null | while read f; do s=$(cat "$f" 2>/dev/null); if echo "$s" | grep -Eq "active|: On|^On$"; then echo ===$f===; echo "$s"; fi; done'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_6ywdMy1Fqt5kmfzBqljQhocl__vscode-1774436616919/content.txt#1-1), lines 1 to 260

刚才全卡扫描把 `inactive` 也误算进来了，但已经看出一个趋势：不仅 AW widget 没 On，连 WSA/RX 这些上游 playback 节点也大多没真正 active。我再做最后一次精确筛选，只保留 `stream ... active` 或 `: On`，把真正亮起来的节点单独拎出来。

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; LD_LIBRARY_PATH=/data/local/tmp:/mnt/system_a/system/lib64:/system/lib64:/vendor/lib64:/vendor/lib64/hw /data/local/tmp/agm_audio_minimal_bin --wav /data/local/tmp/test440_mid_10s.wav >/dev/null 2>&1 & sleep 1; find /sys/kernel/debug/asoc/sun-mtp-snd-card -path "*/dapm/*" -type f 2>/dev/null | while read f; do s=$(cat "$f" 2>/dev/null); if echo "$s" | grep -Eq "stream .* active|: On"; then echo ===$f===; echo "$s"; fi; done'

现在可以排除“你没听见而已”这种假设了，系统层面就是没把功放真正点亮：6 颗 AW 全部表现为 `stream active` 但 widget 仍 `Off`。我再补一刀对比 stock `agmplay`，看这是我们链路独有问题，还是 recovery 当前整机外放路径都没被 power up。

Ran terminal command:  adb shell 'command -v agmplay || ls /vendor/bin/agmplay /system/bin/agmplay 2>/dev/null'
Completed with input:  adb shell 'command -v agmplay || ls /vendor/bin/agmplay /system/bin/agmplay 2>/dev/null'

设备上有 stock `agmplay`。我先查一下它的参数格式，然后用同一份 WAV 抓一次播放中的 AW DAPM，直接跟 minimal 对比。

Ran terminal command:  adb shell '/vendor/bin/agmplay --help 2>&1 | head -n 40'

Read memory twrp_audio_agmplay_minimal_success.md

参数格式确认了，而且 repo 里有收敛过的最小成功命令。我直接用这条命令在播放第 1 秒抓 AW DAPM，对比 stock 路径会不会把 widget 点亮。

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY >/dev/null 2>&1 & sleep 1; for d in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*; do echo ===$d===; cat "$d"/dapm/bias_level; for f in "$d"/dapm/Speaker_Playback_*; do echo ---$f---; cat "$f"; done; done'

不是你听错了，是真的没声。

我刚把这件事钉死了，结论是：

1. 你的播放命令确实在跑
2. AGM 路由也确实落在我们刚修好的 16472 分支
3. 但播放时 6 颗 AW 功放的 DAPM 状态全部都是同一种坏相位：
   - Speaker_Playback_xx: Off
   - stream Speaker_Playback_xx active
   - bias_level: Off

这句话的意思很直接：

1. 音频流已经到了 ASoC
2. 但功放 widget 根本没被真正上电
3. 所以完全没声音是系统当前真实状态，不是命令写错，也不是你没听见

更关键的是，我已经用 stock 的 /vendor/bin/agmplay 对比过了：

1. 用同一份 WAV
2. 用收敛过的最小成功命令
3. 抓到的结果和 minimal 一样
4. 也是 6 颗 AW 全部 stream active 但 widget Off

所以现在可以正式下结论：

1. 这已经不是 minimal 独有问题
2. 也不是刚才那次 route 默认值修改单独造成的问题
3. 是当前 recovery 里的整条外放 power-up 路径没有把 AW 功放真正点亮

也就是说，你现在“没有一点声音”这件事，我已经在内核/ASoC 层证实了。

当前最有价值的结论只有一句：

当前 recovery 里，外放流存在，但 AW 功放播放 widget 没有进入 On。

下一步该做的，不是再重复播命令，而是继续查这两层谁没起来：

1. WSA/RX 上游 DAPM 电源链
2. machine route 或 mixer 控件里缺的 enable 开关

如果你要我继续，我下一步就直接去抓播放时的 WSA/RX 关键 DAPM 节点和相关 tinymix 控件，把“到底卡在 AW 前一跳还是卡在 machine route”继续压缩出来。

User: 继续

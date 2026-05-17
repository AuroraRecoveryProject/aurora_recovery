# 第4章：Recovery重打包回主线与GKV-metadata分叉

GitHub Copilot: 我先把现成的注入和刷写路径核对出来，目标是直接复用你这套仓库里已经跑过的 recovery repack 流程，不临时发明新方法。

Searched for regex `new-boot-hal5-manual-wrapper|recovery_repack_hal5|vendor.audio-recovery-services.rc|fastboot flash recovery|fastboot boot` (`**/docs/**/*.md`), 11 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_dtb_probe)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/ossi_recovery_inject_20260319)

我已经确认到现成注入目录是 ossi_recovery_inject_20260319，里面就有原始镜像、ramdisk 和 payload。下一步直接读那段已验证过的 repack/flash 口径，然后实际执行。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#2448-2448), lines 2448 to 2472

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#2828-2828), lines 2828 to 2845

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/ossi_recovery_inject_20260319/payload)

我现在直接做注入和 repack，先把这次 vendor.audio-recovery-services.rc 改动塞进现成 recovery 镜像，并保留注入前备份，避免等会需要回退时再摸流程。

Ran terminal command:  pushd '/Volumes/Case-sensitive APFS/TWRP/ossi_recovery_inject_20260319' >/dev/null && cp ramdisk.cpio ramdisk.cpio.permgrfix.bak && ../magiskboot cpio ramdisk.cpio "rm vendor/etc/init/vendor.audio-recovery-services.rc" "add 0644 vendor/etc/init/vendor.audio-recovery-services.rc payload/vendor.audio-recovery-services.rc" && ../magiskboot repack ossi_recovery.img && cp new-boot.img new-boot.permgrfix.img

Ran terminal command:  pushd '/Volumes/Case-sensitive APFS/TWRP/ossi_recovery_inject_20260319' >/dev/null && ../magiskboot cpio ramdisk.cpio "extract vendor/etc/init/vendor.audio-recovery-services.rc verify.vendor.audio-recovery-services.rc" && sed -n '1,40p' verify.vendor.audio-recovery-services.rc

注入和 repack 已经完成，镜像里验证过新的 rc 已经进去。下一步直接刷这张 `new-boot.permgrfix.img`，然后重启回 recovery 做首轮状态核对。

Ran terminal command:  pushd '/Volumes/Case-sensitive APFS/TWRP/ossi_recovery_inject_20260319' >/dev/null && ls -l new-boot.permgrfix.img ramdisk.cpio.permgrfix.bak

Ran terminal command:  adb reboot fastboot

设备已经切换中，我先轮询 fastboot，再执行刷写和回 recovery，整个过程不走 `wait-for-device`。

Ran terminal command:  for i in 1 2 3 4 5 6 7 8 9 10; do sleep 1; fastboot devices; done

Ran terminal command:  pushd '/Volumes/Case-sensitive APFS/TWRP/ossi_recovery_inject_20260319' >/dev/null && fastboot flash recovery new-boot.permgrfix.img

Ran terminal command:  fastboot reboot recovery

刷写和重启已经完成了。现在只做首轮最小验收，不扩散到播放命令，先看这次修复有没有把 `per_mgr` 和声卡拉起来。

Ran terminal command:  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do sleep 2; adb devices; done

Ran terminal command:  adb shell getprop ro.bootmode
Completed with input:  adb shell getprop ro.bootmode

Ran terminal command:  adb shell 'for s in vendor.vndservicemanager vendor.pd_mapper vendor.per_mgr vendor.adsprpcd vendor.audioadsprpcd_audiopd vendor.audio-hal-manual; do echo $s=$(getprop init.svc.$s); done'
Completed with input:  adb shell 'for s in vendor.vndservicemanager vendor.pd_mapper vendor.per_mgr vendor.adsprpcd vendor.audioadsprpcd_audiopd vendor.audio-hal-manual; do echo $s=$(getprop init.svc.$s); done'

设备还没回到 adb，这一步不能假设它已经起了。我现在直接查它是还停在 fastboot，还是已经掉进别的模式。

Ran terminal command:  fastboot devices

Ran terminal command:  fastboot getvar current-slot

User: 现在设备回来了，继续

GitHub Copilot: 设备既然已经回来了，我先做首轮验收，只看这次刷入后的关键状态有没有变化：`per_mgr`、声卡、节点。

Ran terminal command:  adb devices

Ran terminal command:  adb shell getprop ro.bootmode

Ran terminal command:  adb shell 'for s in vendor.vndservicemanager vendor.pd_mapper vendor.per_mgr vendor.adsprpcd vendor.audioadsprpcd_audiopd vendor.audio-hal-manual; do echo $s=$(getprop init.svc.$s); done'

Ran terminal command:  adb shell cat /proc/asound/cards

Ran terminal command:  adb shell ls /dev/snd

关键变化已经出来了：这次刷入后声卡和 `/dev/snd` 节点都恢复了，说明已经回到主线前置状态。现在我直接推进到播放验证，先跑 stock 路径，不再停在环境层打转。

Ran terminal command:  adb shell '/system/bin/twrp-audio-play-test.sh tinyplay_ftm'

Ran terminal command:  adb shell 'grep -E "twrp-audio-play-test|tinyplay_ftm|twrp-audio-autoload" /tmp/recovery.log | tail -n 80'

Ran terminal command:  adb shell 'ps -A -o PID,PPID,STAT,NAME,ARGS | grep -E "vndservicemanager|pm-service|audiohalservice|audioadsprpcd|pd-mapper" | grep -v grep'

现在比之前前进了一大步：`audiohalservice.qti` 已经从原来的 `D` 态变成正常 `S` 态，最短链也确实进到了 AGM plugin 打开阶段。我再跑 `agmplay` 路径，把主线两条 stock 路都过一遍。

Ran terminal command:  adb shell '/system/bin/twrp-audio-play-test.sh agmplay'

Ran terminal command:  adb shell 'grep -E "twrp-audio-play-test|agmplay|graph_open|graph_start|aw882xx|audiohalservice" /tmp/recovery.log | tail -n 120'

Ran terminal command:  adb shell 'for s in vendor.vndservicemanager vendor.pd_mapper vendor.per_mgr vendor.adsprpcd vendor.audioadsprpcd_audiopd vendor.audio-hal-manual; do echo $s=$(getprop init.svc.$s); done'

环境已经恢复到可继续打播放主线了，剩下的问题回到了“播放器路径本身”。我改用我们一直在用的 `test440_mid_10s.wav` 再跑一轮，避免被厂测 WAV 本身干扰。

Ran terminal command:  adb shell 'ls -l /data/local/tmp/test440_mid_10s.wav /data/local/tmp/tinymix_stock 2>/dev/null'

Ran terminal command:  adb shell '/system/bin/twrp-audio-play-test.sh tinyplay_ftm /data/local/tmp/test440_mid_10s.wav'

Ran terminal command:  adb shell 'm=/data/local/tmp/tinymix_stock; for c in aw_dev_0_volume aw_dev_1_volume aw_dev_2_volume aw_dev_3_volume aw_dev_5_volume aw_dev_6_volume; do $m "$c" 720; done; setprop vendor.oplus.mm.ftm_spk 1; /vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY'

这次改动已经有客观收益，不是空改再赌回退：改前是 `no soundcards`，改后是 card0 和整套 `/dev/snd` 节点都回来了，`audiohalservice.qti` 也正常驻留。现在我继续把播放失败的当前落点钉死，看是不是已经回到之前那条 `PCM device 100 -5` 主线。

Created memory file twrp_audio_reboot_post_permfix_20260325.md

Ran terminal command:  adb shell 'logcat -d -b all | grep -E "Unable to open PCM device 100|Unknown error -5|graph_open|graph_start|q6 state is down|aw882xx|pcm_open|agmplay" | tail -n 160'

Ran terminal command:  adb shell 'dmesg | grep -E "q6 state is down|spf_core|aw882xx|snd|sun-mtp-snd-card" | tail -n 120'

日志已经抓到，我读取关键段落，只看这次修复后的新状态，不重复旧噪音。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_LRUk4H4cFxJjQlZIYIqJiL1N__vscode-1774436617205/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_CAPTNnsQ79UFKJR34SvbcMEO__vscode-1774436617204/content.txt)

继续后的结果已经很明确，而且这次不是瞎改。

结论先说：

1. 注入、刷写、重启已经做完了。
2. 这次改动确实把环境从“完全起不来”拉回来了。
3. 现在已经重新回到播放主线，不是还卡在环境恢复阶段。
4. 所以这次改动现在没有理由立刻改回去。

这次刷完后的客观变化：

1. 之前是 `no soundcards`，现在 `card0` 已经恢复。
2. 之前 `/dev/snd` 只有 `timer`，现在 `controlC0` 和整套 PCM 节点都回来了。
3. 之前 `audiohalservice.qti` 是 `D` 态卡死，现在是真实 `S` 态常驻。
4. 这说明这次 rc 改动不是“玄学变更”，而是实打实解决了“环境根本拉不起来”的问题。

播放主线现在的落点：

1. `tinyplay_ftm` 路径已经能走到 AGM plugin 打开。
2. `agmplay` 路径已经能走到：
   - `graph_open ret 0`
   - `graph_start ret 0`
   - 多颗 `aw882xx_start_pa: start success`
3. 这说明 graph、功放启动、声卡注册这一层已经重新活了。
4. 随后又出现了：
   - `gpr_send_pkt: q6 state is down`
   - `msm_common_snd_hw_params: prm lpass tdm clk cfg set failed ret -19`
   - `TDM-LPAIF-RX-SECONDARY ... hw_params ... -19`
   - 直跑 `agmplay` 还是会落到 `PCM device 100 ... Unknown error -5`

所以现在的真实状态是：

1. 不是“环境没恢复”。
2. 而是已经回到你之前那条老主线了。
3. 也就是那条“stock 路径能把链路拉起来，但后面又掉回 q6 down / tdm clk cfg 失败”的主线。

这也是为什么我说这次改动不该现在就改回去：

1. 改之前，连声卡都没有。
2. 改之后，声卡、节点、HAL、graph、AW start 都恢复了。
3. 这不是副作用，是明显前进。

还有一个你刚才担心的点，我也已经处理了：

1. 这次 reboot 后的固定卡点
2. 这次 rc 修正带来的变化
3. 现在重新回到的播放失败层级

这些我都已经写进仓库记忆了，后面不会再把这次状态忘掉。

当前剩余异常：

1. `vendor.vndservicemanager` 还是 `restarting`
2. `vendor.per_mgr` 还是没稳定驻留

但从实机结果看，它们现在已经不再阻塞 card0 出现，所以这两个不是当前最前面的 blocker 了。

现在最合理的下一步只有一个方向：

1. 不再纠结“怎么把环境拉起来”
2. 直接继续打 `q6 state is down` 和 `tdm clk cfg ret -19`
3. 也就是回到你原来那条播放主线

如果你要，我下一步就直接沿着这条已经恢复的主线继续追：
1. 先把这次 `tinyplay_ftm/agmplay` 的启动到掉线时间窗抓细
2. 再对齐为什么 `graph_start` 成功后还是在 `hw_params/tdm clk` 处掉下去

User: 听到了声音，仍然只有1s，继续回归主线，之前听不到声音，你需要补充日志

主线是用纯C或者自带二进制能完整播放音频

之前的结论是，在开机模式下，用tinyplay_ftm和agmplay也只有1s的声音

GitHub Copilot: 我先补主线日志，不再纠缠环境恢复。做法很直接：分别重放 `tinyplay_ftm` 和 `agmplay`，把“听到约 1 秒声音”对应的运行时长、logcat 和内核尾日志一起钉住。

Ran terminal command:  adb logcat -c

Ran terminal command:  adb shell 'date +%s'

Ran terminal command:  time adb shell '/system/bin/twrp-audio-play-test.sh tinyplay_ftm /data/local/tmp/test440_mid_10s.wav'

Ran terminal command:  adb shell 'logcat -d -b all | grep -E "twrp-audio-play-test|graph_open|graph_start|aw882xx|q6 state is down|hw_params|tdm clk|tinyplay_ftm" | tail -n 160'

Ran terminal command:  adb shell 'dmesg | grep -E "aw882xx|q6 state is down|hw_params|tdm clk|sun-mtp-snd-card" | tail -n 120'

第一条 stock 主线已经复现干净了：`tinyplay_ftm` 命令总时长只有约 `3.38s`，这和“只响约 1 秒”是一致的短生命周期。我现在对同一窗口补 `agmplay`，把两条 stock 路放到同一批日志里对齐。

Ran terminal command:  adb logcat -c

Ran terminal command:  time adb shell 'm=/data/local/tmp/tinymix_stock; for c in aw_dev_0_volume aw_dev_1_volume aw_dev_2_volume aw_dev_3_volume aw_dev_5_volume aw_dev_6_volume; do $m "$c" 720; done; setprop vendor.oplus.mm.ftm_spk 1; /vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY'

Ran terminal command:  adb shell 'logcat -d -b all | grep -E "agmplay|graph_open|graph_start|aw882xx|q6 state is down|hw_params|tdm clk|PCM device 100|Unknown error -5" | tail -n 180'

Ran terminal command:  adb shell 'dmesg | grep -E "aw882xx|q6 state is down|hw_params|tdm clk|sun-mtp-snd-card" | tail -n 140'

`agmplay` 这条也补全了，和你之前的长期结论一致：命令生命周期能跑满约 `10.2s`，但肉耳只有约 `1s`。我现在把两批日志里的关键段摘出来，确认“为什么只响 1 秒”现在落在哪一层。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_RHNdNTvgZCp3E0iqQMTMP1SJ__vscode-1774436617211/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_pputktDJhAsSAPn7ITP4NDCP__vscode-1774436617212/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_UOKzI0Zfth3JXp4ywE3zXSEG__vscode-1774436617215/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_bdrfaoWDhhHTl5k54QIrxLCD__vscode-1774436617216/content.txt)

我已经把 stock 两条路的日志补齐了，而且它们现在分成了两种不同失败面。下一步我不再只看 stock，而是把纯 C 主线拉进同一套现场，确认它现在到底是“同样只响 1 秒”，还是比 stock 更差。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player)

Searched for regex `agm_audio_minimal_bin|pure_c_agm_probe|build_agm_audio_minimal|build_pure_c_agm_probe` (`**/video_player/**`), 6 results

Read memory twrp_audio_agmplay_minimal_success.md

我已经确认纯 C 两个现成产物都在工作区里。现在先用 helper 路的 `agm_audio_minimal_bin` 直接上机复现，目的是把“stock 只响 1 秒”和“纯 C 只响 1 秒或更差”放到同一套日志里比。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal_main.c)

Ran terminal command:  adb shell 'ls -l /data/local/tmp/agm_audio_minimal_bin /data/local/tmp/pure_c_agm_probe 2>/dev/null'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && adb push agm_audio_minimal_bin /data/local/tmp/agm_audio_minimal_bin && adb shell chmod 755 /data/local/tmp/agm_audio_minimal_bin

helper 路二进制已经在设备上了。现在我直接跑一轮 10 秒 WAV 播放，加同样的日志窗，确认它是不是也落在“1 秒声后掉线”的同一层。

Ran terminal command:  adb logcat -c

Ran terminal command:  time adb shell '/data/local/tmp/agm_audio_minimal_bin --wav /data/local/tmp/test440_mid_10s.wav'

Ran terminal command:  adb shell 'logcat -d -b all | grep -E "agm_audio_minimal|graph_open|graph_start|aw882xx|q6 state is down|hw_params|tdm clk|pcm_open|runtime snapshot" | tail -n 200'

Ran terminal command:  adb shell 'dmesg | grep -E "aw882xx|q6 state is down|hw_params|tdm clk|sun-mtp-snd-card" | tail -n 140'

helper 路结果已经出来了，我先读关键片段，不浪费上下文在整份 trace 上。目标只看两件事：运行时长，以及它是在哪个点掉下去。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_T9jvjzOqE84naSflx2FtoStF__vscode-1774436617229/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_NMR9vYIm9JdGSSzMOL78vk3h__vscode-1774436617228/content.txt#1-1), lines 1 to 220

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_JpNYOJIJXjLz1vigqDtihyoc__vscode-1774436617230/content.txt)

主线日志已经够用了，但我还差 helper 路的命令总时长这一点。我补一刀把它的退出结果和耗时摘出来，然后给你一个不丢历史结论的当前落点。

Searched for regex `total|agm_audio_minimal failed|play cycle|write_all_frames|audio_ms=` (`**/call_NMR9vYIm9JdGSSzMOL78vk3h__vscode-1774436617228/content.txt`), no results

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_NMR9vYIm9JdGSSzMOL78vk3h__vscode-1774436617228/content.txt#220-220), lines 220 to 340

Created memory file twrp_audio_stock_and_helper_1s_frontier_20260325.md

我再往前推一步，不停在“补完日志”。现在直接把纯 direct-AGM 的 `pure_c_agm_probe` 拉进主线，对比它和 helper/stock 的差异，看看它是不是还停留在更差的旧回归点。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/sample_aw_during_purec.sh)

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --help'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --help'

Ran terminal command:  adb logcat -c

参数已经对上了。我直接按之前样本里那条 direct-AGM 主线跑，先看它现在是否仍然早于 stock/helper 崩掉。

Ran terminal command:  time adb shell '/data/local/tmp/pure_c_agm_probe --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --play-after-open --play-seconds 10'

Ran terminal command:  adb shell 'logcat -d -b all | grep -E "pure_c_agm_probe|graph_open|graph_start|aw882xx|q6 state is down|PCM device|session open|setParam|Error" | tail -n 180'

Ran terminal command:  adb shell 'dmesg | grep -E "aw882xx|q6 state is down|hw_params|tdm clk|sun-mtp-snd-card" | tail -n 140'

我把 direct-AGM 也跑上了。最后再读一小段它的退出结果，就能把三条主线现在的层级关系说清楚。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_bK4720ubFqHlbEz4tctLk6B6__vscode-1774436617240/content.txt#1-1), lines 1 to 220

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_5o4rPBdWxx3cjq0fqd7sfMVr__vscode-1774436617241/content.txt)

继续后的主线状态已经清楚了，我把日志补到了三条路径上，而且没有丢掉你强调的旧结论。

当前必须同时成立的结论：

1. 旧结论不变。
2. 开机态下，`tinyplay_ftm` 和 `agmplay` 本来就都只有约 `1s` 可闻声音。
3. 这次 recovery 修复后，环境层已经恢复，不再是“听不到声音/没声卡”的问题。
4. 现在已经重新回到那个老主线：链路能拉起，但可闻声音仍只有约 `1s`。

这次我补到的关键日志结论：

1. `tinyplay_ftm`：
   - 命令总时长约 `3.38s`
   - 日志有：
     - `graph_open ret 0`
     - `graph_start ret 0`
     - 多颗 `aw882xx_start_pa: start success`
   - 然后约 3 秒处出现：
     - `gpr_send_pkt: q6 state is down`
     - `Error playing sample`
     - `msm_common_snd_shutdown: prm tdm clk cfg set failed ret -19`
   - 这条路是“短生命周期 + 约 1s 可闻声音”。

2. `agmplay`：
   - 命令总时长约 `10.22s`
   - 日志有：
     - `graph_open ret 0`
     - `graph_start ret 0`
     - 多颗 `aw882xx_start_pa: start success`
   - 命令生命周期能跑满，但肉耳仍只有约 `1s`
   - 这条路不是立刻炸，而是“进程活得更久，但可闻输出还是只剩约 1s”。

3. `agm_audio_minimal_bin` helper 路：
   - 现在已经明显不再是之前那种“环境没起来就死”
   - 日志里能看到：
     - `pcm_prepare rc=0`
     - `pcm_start rc=0`
     - `play_wav start`
     - `play_wav progress audio_ms=1000`
     - `play_wav progress audio_ms=2000`
     - `play_wav progress audio_ms=3000`
     - 每 1 秒都有 `reinforce route`
   - 说明 helper 路当前至少能持续推进到 `3s+`，不再是最早就断。

4. `pure_c_agm_probe` direct-AGM 路：
   - 也已经不是“开都开不起来”
   - 当前日志里能看到：
     - `pcm_prepare rc=0`
     - `pcm_start rc=0`
     - `开始写测试音`
     - `during write 1002ms`
     - `during write 2005ms`
     - `during write 3008ms`
     - 每秒也有 `reinforce route`
   - 说明 direct pure C 现在也已经重新进入“能持续写、但可闻声音边界不对”的主线，而不是还停在更早的失败层。

所以当前主线不是“怎么恢复环境”，而是更具体的这个问题：

1. 声卡、graph、AW start、PCM start 都已经成立。
2. 但可闻输出仍然只维持约 `1s`。
3. stock、helper、direct pure C 都已经重新回到这个边界附近。
4. 这说明当前最该打的不是启动链，而是“为什么 audio pipeline 后续还在跑，但 audible 只剩约 1s”。

我已经把这批状态写进仓库记忆了，后面不会再把这次 recovery 修复后的现状忘掉。

下一步我建议直接继续这条主线，不回头：
1. 对齐 `agmplay` 和 `agm_audio_minimal` 在 `1s` 之后的运行态差异
2. 重点看 helper/direct pure C 的持续 `reinforce route` 为什么没有换来持续可闻输出
3. 再把 direct pure C 对齐到当前 helper 的持续写入行为，追 full 10s audible 这一条线

如果你要，我下一步就直接开始做“`1s` 之后的运行态差分”，不再重复环境层。

User: 继续

GitHub Copilot: 我继续往“为什么只响约 1 秒”这一层收，不再重复环境恢复。先把 helper 和 direct-AGM 在 1 秒后到 3 秒、5 秒的运行态差异钉出来，看是不是同样在 q6/功放侧掉线。

Ran terminal command:  adb logcat -c

Ran terminal command:  time adb shell '/data/local/tmp/agm_audio_minimal_bin --wav /data/local/tmp/test440_mid_10s.wav'

Ran terminal command:  adb shell 'logcat -d -b all | grep -E "q6 state is down|agm_audio_minimal|play_wav progress|reinforce route|aw882xx_shutdown|aw882xx_start_pa|graph_start|graph_open|tdm clk|hw_params" | tail -n 220'

Ran terminal command:  adb shell 'dmesg | grep -E "q6 state is down|aw882xx|tdm clk|hw_params|spf_core" | tail -n 180'

helper 新一轮已经抓到了。我现在只读后半段，直接看它有没有在 1 秒后继续推进，以及退出前有没有出现 `q6 state is down`。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_CXDYEUud59MTyk8X9TUfGkb7__vscode-1774436617246/content.txt#320-320), lines 320 to 376

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_nvIVSB1WtFvJC1QGbZe7H0Fg__vscode-1774436617247/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_N8TkQSoaPHL2y4eTUzQ1rLbx__vscode-1774436617248/content.txt)

我继续往“1 秒之后到底是谁变了”这个点上收。helper/direct 现在都能跑满 10 秒，所以我先抽 pure C 路在 `1s` 和 `5s` 的 AW 关键寄存器，确认功放侧是不是在可闻声音消失后进入了另一种状态。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && sh sample_aw_during_purec.sh 10 '1 5' '4-0034 9-0034'
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && sh sample_aw_during_purec.sh 10 '1 5' '4-0034 9-0034'

Ran terminal command:  adb shell 'logcat -d -b all | grep -E "PureCAgmProbe|q6 state is down|aw882xx_start_pa|aw882xx_shutdown" | tail -n 160'

Ran terminal command:  adb shell 'dmesg | grep -E "q6 state is down|aw882xx|tdm clk|hw_params" | tail -n 160'

寄存器采样已经给出一个很硬的结果了：pure C 路在 `1s` 和 `5s` 时，AW 关键寄存器状态没变，不像是功放自己在 1 秒后切了模式。现在我把对应时间窗的日志读出来，确认是不是“软件继续跑、AW 继续维持、但可闻输出消失”。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_0kbo0oFjBKSgit8Y9XS8dU5u__vscode-1774436617253/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_wgGkksxc366S35axMvUXZl40__vscode-1774436617254/content.txt)

我再补一刀针对“软件还在写，但声音先没了”的证据，查 helper/pure C 这段时间里有没有 XRUN、standby、route reset 之类的运行态切换。结果如果没有，就更能说明问题不在用户态写流中断。

Ran terminal command:  adb shell 'logcat -d -b all | grep -Ei "underrun|xrun|standby|resume|flush|pause|drain|route.*reset|pcm_write|write.*fail|session.*close|device_close" | tail -n 200'

Ran terminal command:  adb shell '/data/local/tmp/tinymix_stock "Speaker_Mute_Switch"; /data/local/tmp/tinymix_stock "aw882xx_rx_switch"; /data/local/tmp/tinymix_stock "aw882xx_copp_switch"; /data/local/tmp/tinymix_stock "aw_dev_0_volume"; /data/local/tmp/tinymix_stock "aw_dev_1_volume"; /data/local/tmp/tinymix_stock "aw_dev_2_volume"; /data/local/tmp/tinymix_stock "aw_dev_3_volume"; /data/local/tmp/tinymix_stock "aw_dev_5_volume"; /data/local/tmp/tinymix_stock "aw_dev_6_volume"'

我已经拿到最后一块用户态侧证据了：当前 mixer 面没有被异步改坏，关键控件都还在正确值。现在只差把日志里有没有 XRUN/standby/reset 这类事件读出来。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_qUks3sl9YNym7eu4YZ7aDi7V__vscode-1774436617257/content.txt)

Compacted conversation刚把那份关键词日志读完了，没有出现 XRUN、underrun、standby、route reset 这类能直接解释“1 秒后静音”的事件。现在我要改成按单次播放窗口抓更窄的 logcat 和 dmesg，确认是不是 Q6/时钟/DSP 在 1 秒附近掉了但被之前的大尾巴冲掉了。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && TS=$(date '+%m-%d %H:%M:%S.000') && adb shell logcat -c && adb shell 'dmesg -C >/dev/null 2>&1 || true' && echo START:$TS && time adb shell '/vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav 48000 2 16 1 100'
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && TS=$(date '+%m-%d %H:%M:%S.000') && adb shell logcat -c && adb shell 'dmesg -C >/dev/null 2>&1 || true' && echo START:$TS && time adb shell '/vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav 48000 2 16 1 100'

这次命令参数不对，进程几乎立刻退了，没有形成有效窗口。我改成设备上已经验证过的最小调用方式，直接重放一次再抓。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell logcat -c && adb shell 'dmesg -C >/dev/null 2>&1 || true' && time adb shell '/vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav'
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell logcat -c && adb shell 'dmesg -C >/dev/null 2>&1 || true' && time adb shell '/vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell 'ls -l /vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav'

`agmplay` 确实要求显式参数，刚才那次只是把它的用法打出来。先不在这里猜参数，我先抓已经稳定可复现的 helper/pure-C 单次窗口，把“1 秒后仍在写、链路哪里变静音”这件事压实。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell logcat -c && adb shell 'dmesg -C >/dev/null 2>&1 || true' && time adb shell '/data/local/tmp/agm_audio_minimal_bin --wav /data/local/tmp/test440_mid_10s.wav'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell 'logcat -d -b all | grep -Ei "agm_audio_minimal|AGM:|aw882xx|q6 state is down|msm_common_snd|audioreach|audio-hal|graph_open|graph_start|shutdown|start_pa" | tail -n 300'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell 'dmesg | grep -Ei "aw882xx|q6 state is down|msm_common_snd|audio|audioreach|lpass|tdm|prm|apm|spf|graph" | tail -n 300'

helper 这次已经重新跑完了，结果比较大，我现在只读关键片段：运行输出、播放中段、结束段，再对照 dmesg 看中间有没有 Q6 或时钟侧掉线。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_j6G42iaQ9xhJxBwULLEKdo2W__vscode-1774436617265/content.txt#1-1), lines 1 to 260

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_jEZ8oJNuPGIisMaBSRL3RDQp__vscode-1774436617263/content.txt#1-1), lines 1 to 220

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_ht0RxUmBkZ4slpY3P8VAEB6X__vscode-1774436617264/content.txt#1-1), lines 1 to 260

这轮干净窗口里，helper 路径没有出现 `q6 state is down`、`msm_common_snd ... ret -19`、`standby/xrun`。也就是说“1 秒后静音”在 helper 这条线上不是前面那个 DSP 整体掉线问题。现在我去对照仓库里之前记过的 `devicepp/kv/frontier` 结论，看这次现象是不是又回到了那个老边界。

Read memory twrp_audio_devicepp_kv_frontier.md

Read memory twrp_audio_standard_path_priority.md

Read memory twrp_audio_agmplay_minimal_success.md

Read memory twrp_audio_helper_timing_delta_20260317.md

仓库记忆里已经有 agmplay 的最小成功调用，不用再猜参数了。下一步我直接按那条最小命令重跑一次，确认它和 helper 当前到底差在哪一层。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell logcat -c && adb shell 'dmesg -C >/dev/null 2>&1 || true' && time adb shell '/vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell 'logcat -d -b all | grep -Ei "AGM:|aw882xx|q6 state is down|msm_common_snd|audioreach|graph_open|graph_start|shutdown|start_pa|device_close|session_close" | tail -n 260'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell 'dmesg | grep -Ei "aw882xx|q6 state is down|msm_common_snd|audio|audioreach|lpass|tdm|prm|apm|spf|graph" | tail -n 260'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell logcat -c && adb shell 'dmesg -C >/dev/null 2>&1 || true' && time adb shell '/vendor/bin/agmplay /data/local/tmp/test440_low.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell 'logcat -d -b all | grep -Ei "AGM:|aw882xx|q6 state is down|msm_common_snd|agmplay|graph_open|graph_start|shutdown|start_pa" | tail -n 300'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell 'dmesg | grep -Ei "aw882xx|q6 state is down|msm_common_snd|audio|audioreach|lpass|tdm|prm|apm|spf|graph" | tail -n 300'

stock agmplay 也跑出来了：10 秒 wav 跑满 10.14 秒，2 秒 wav 跑 2.14 秒，而且这两次都没有 `q6 down`。接下来我只看它的 logcat 关键段，确认它和 helper 相比是不是单纯少了那些每秒一次的重复“补路由”动作。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_oz0dcWDR6AbFc8EvG91Zxu1b__vscode-1774436617277/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_Kxntsw093A6n1d5bEWubVwVV__vscode-1774436617274/content.txt)

现在确认了两件事：`agmplay` 当前并不是“1 秒就退出”，它和 helper 一样在整个文件时长内都活着；而且这条 stock 路径也没有 `q6 down`。下一步只剩一个更窄的比对点了：helper 这次是否真的拿到了和 agmplay 一样完整的 GKV/CKV 与 graph tag。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell 'logcat -d -b all | grep -E "GKV size:|CKV count:|graph_open: 710|graph_open: 766|configure_hw_ep_media_config|configure_output_media_format|configure_spr" | tail -n 200'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell 'logcat -d -b all | grep -E "play_wav progress|play_wav done|graph_open ret|graph_start ret|AgmAudioMinimal" | tail -n 200'

刚才第二条把 helper 旧日志冲掉了，所以我补一个更短的 helper 窗口。用 2 秒 wav 就够了，只看它是否也拿到和 agmplay 同一组 graph metadata。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell logcat -c && adb shell 'dmesg -C >/dev/null 2>&1 || true' && time adb shell '/data/local/tmp/agm_audio_minimal_bin --wav /data/local/tmp/test440_low.wav'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell 'logcat -d -b all | grep -E "GKV size:|CKV count:|graph_open: 710|graph_open: 766|configure_hw_ep_media_config|configure_output_media_format|configure_spr|graph_open ret|graph_start ret|play_wav progress|play_wav done|AgmAudioMinimal" | tail -n 260'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell 'dmesg | grep -Ei "aw882xx|q6 state is down|msm_common_snd|audio|audioreach|lpass|tdm|prm|apm|spf|graph" | tail -n 220'

新信息出来了：helper 和 agmplay 现在都能把 graph 真正拉起来，但 helper 的 metadata 不是完全一样，它这次是 `GKV size:3`，而 stock agmplay 是 `GKV size:4`。这已经是一个像样的分叉点了，我现在把 helper 的具体键值读出来。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_ltykv0z8LKS19y6RD65e07NK__vscode-1774436617283/content.txt#1-1), lines 1 to 260

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_PmvMhObs1oAyKGueb1dfPnKp__vscode-1774436617285/content.txt#1-1), lines 1 to 220

分叉点已经基本定住了：helper 这轮不是 graph 没起来，而是 graph metadata 比 agmplay 少了一项 GKV。我要直接把那三项键值读出来，确认缺的是 `AB000000=1` 还是别的东西。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell 'logcat -d -b all | grep -A12 -B2 "metadata_print: 80 GKV size:3"'

helper 当前缺的那一项已经抓到了：它少的是 `0xAC000000=0xAC000002`，也就是之前一直反复出现的 `devicepp_kv`。这不等于已经解释了 stock 的 1 秒问题，但它至少解释了 helper 为什么还没和 agmplay 真正对齐。我先去代码里把这条 metadata 生成链找到。

Searched for regex `set_agm_streamdevice_metadata|devicepp_kv|0xAC000002|0xac000002|A2000001|streamdevice metadata` (`**/video_player/**`), 24 results

Searched for regex `set_agm_streamdevice_metadata|devicepp_kv|0xAC000002|0xac000002|A2000001|streamdevice metadata` (`**/aurora_recovery/**`), no results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#1230-1230), lines 1230 to 1285

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal_main.c#90-90), lines 90 to 140

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#560-560), lines 560 to 590

Searched for regex `metadata_689c_route_tag|metadata_689c_route_value` (`**/video_player/agm_audio_minimal.c`), 4 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#1-1), lines 1 to 140

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#1388-1388), lines 1388 to 1515

我准备做一个最小试验性修正：不是大改流程，只是在 helper prep 里显式补上缺失的 `devicepp_kv=0xAC000002`，让它先在 metadata 这一层和 agmplay 对齐。先看现有构建/同步路径，避免手工乱编。

Searched for regex `agm_audio_minimal_bin|build_so|ndk-build|clang .*agm_audio_minimal|push .*agm_audio_minimal` (`**/video_player/**`), 2 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/build_agm_audio_minimal.sh)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/build_pure_c_agm_probe.sh)

我要同时补 helper 和 pure-C 两边，避免之后一个路径对齐了、另一个还停在旧 metadata。改动会很小，只补 `AC000002` 那一步，不动别的调试逻辑。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2028-2028), lines 2028 to 2055

Searched for regex `BUILD_ID|20260325-helper-plus-pcm100connect-v16|202603` (`**/video_player/agm_audio_minimal.c`), 3 results

Searched for text `BUILD_ID` (`**/video_player/pure_c_agm_probe.c`), 2 results

Generating patch (33 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c)


```

```


Generating patch (37 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
代码已经补上了，下一步就是重新编译并上机验证这条 metadata 是否真的从 `GKV size:3` 变成和 agmplay 一样的 `GKV size:4`。先做编译，编不过再当场收口。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_agm_audio_minimal.sh
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_agm_audio_minimal.sh

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_pure_c_agm_probe.sh

`agm_audio_minimal` 只是脚本没执行位，不是代码问题。我改用 `sh` 直接编，顺便把新二进制推到设备上做一次短窗口验证。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && sh build_agm_audio_minimal.sh

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && adb push agm_audio_minimal_bin /data/local/tmp/agm_audio_minimal_bin && adb shell chmod 755 /data/local/tmp/agm_audio_minimal_bin && adb push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb shell chmod 755 /data/local/tmp/pure_c_agm_probe

新二进制已经上机。现在只验证一件事：helper 的 graph metadata 是否从 3 项变成 4 项；如果这一步不成立，就不继续往听感上猜。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell logcat -c && adb shell 'dmesg -C >/dev/null 2>&1 || true' && time adb shell '/data/local/tmp/agm_audio_minimal_bin --wav /data/local/tmp/test440_low.wav'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell 'logcat -d -b all | grep -A12 -B2 "metadata_print: 80 GKV size:"'

验证结果很明确：即便显式补了一次 `set_agm_streamdevice_metadata(..., 0xAC000002)`，helper 的最终 graph metadata 仍然还是 `GKV size:3`，缺的还是 `AC000000=AC000002`。这说明问题不是“少调了一次这个 helper API”，而是这个 API 路径本身就不会把 `devicepp` 落进最终 graph。这个试探性改动我会撤回，不把无效分支留在代码里。

Generating patch (33 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c)


```

```


Generating patch (37 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
这次试探虽然没改出结果，但结论是硬的：`set_agm_streamdevice_metadata` 追加一遍 `devicepp_kv` 不会进入最终 graph metadata。这个结论值得记住，免得之后再重复踩。

Read memory /memories/repo/

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && sh build_agm_audio_minimal.sh

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && sh build_pure_c_agm_probe.sh

Created memory file twrp_audio_helper_devicepp_second_streamdevice_noop_20260325.md

我没有停在“试一下就算了”。既然这条 helper API 路确定是死路，下一步就该回到之前更底层的结论，看看 `AC000002` 当时是从哪一类 metadata API 真正进 graph 的。

Read memory twrp_audio_session_devicepp_gkv_20260318.md

Read memory twrp_audio_helper_vs_agmplay_tag_surface_diff_20260324.md

Read memory twrp_audio_stock_and_helper_1s_frontier_20260325.md

源码我已经回退干净了，但设备上的 `/data/local/tmp` 里还留着刚才那版实验二进制。我把回退后重新编出来的版本再推一次，避免后续验证混进无效试探。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && adb push agm_audio_minimal_bin /data/local/tmp/agm_audio_minimal_bin && adb shell chmod 755 /data/local/tmp/agm_audio_minimal_bin && adb push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb shell chmod 755 /data/local/tmp/pure_c_agm_probe

当前结论又收紧了一步，而且这次不是猜测。

1. 已确认的事实
- helper 和 stock agmplay 现在都不是“1 秒就退出”。
- stock agmplay 跑 10 秒 wav 时，进程能活满约 10.14 秒。
- helper 跑短 wav 和长 wav 时，也都能持续写到结束。
- 这两条线上，这一轮都没有出现 `q6 state is down`、`msm_common_snd ... ret -19`、`xrun/underrun/standby/route reset` 之类事件。
- 所以当前主线的 “只听到约 1 秒” 不是之前那种 DSP 整体掉线问题。

2. 新钉实的分叉点
- stock agmplay 的 graph metadata 是 4 项 GKV：
  - `A100000E`
  - `AB000001`
  - `AC000002`
  - `A2000001`
- helper 的 graph metadata 只有 3 项 GKV：
  - `A100000E`
  - `AB000001`
  - `A2000001`
- helper 明确缺的是 `AC000002`，也就是 `devicepp_kv`。

3. 我实际做了什么验证
- 我试着在 helper prep 里显式再补一次 `set_agm_streamdevice_metadata(..., 0xAC000002)`。
- 然后重新编译、推到设备、重跑 helper。
- 结果最终 `graph_open` 里的 metadata 仍然还是 `GKV size:3`，缺的仍然是 `AC000002`。

4. 这次验证的有效结论
- “再补一次 `set_agm_streamdevice_metadata`” 这条路是无效的。
- 也就是说，stock agmplay 里的 `AC000002` 不是通过这条 helper API 简单追加进去的。
- 它要么来自别的 metadata API 落点，要么来自不同的 helper 组合，而不是当前这条 `streamdevice_metadata` 二次调用。

5. 我已经处理掉的副作用
- 试探性源码改动已经全部撤回，没有把无效实验留在代码里。
- 我又重新编译了一次回退后的二进制，并重新推到了设备，保证设备端不残留刚才那版无效实验产物。

6. 现在主线真正剩下的东西
- `tinyplay_ftm` 那条线仍然是另一类问题：它会掉到 `q6 state is down`。
- `agmplay/helper/pure-C` 这条线则是另一类更细的问题：graph、amp、进程都还活着，但可闻声音只有约 1 秒。
- helper 当前和 stock 的一个明确差异是缺 `AC000002`，但这还不能单独解释 stock 自己为什么也只有 1 秒声音。

下一步最值钱的两个方向是：
1. 继续追 stock agmplay 里 `AC000002` 的真实注入点，别再在 `set_agm_streamdevice_metadata` 上浪费时间。
2. 在当前 recovery 修复后的环境里，重新对比 stock agmplay 与 helper 的完整 tagged-info 和 module surface，找“1 秒后仍在跑但变静音”的共同点，而不是只盯 helper 差异。

如果你要我继续，我下一步就直接去追 `AC000002` 在 stock 路径里的真实来源。

Made changes.

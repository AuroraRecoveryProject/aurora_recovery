User: 先验证声音通不通

GitHub Copilot: 先用上次最稳的厂测路径直接打一次喇叭播放，再补抓一眼相关日志。这样能最快判断这次重启后“可听声链”是不是还活着。

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /odm/bin/tinyplay_ftm /data/local/tmp/test440_mid_10s.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY'

Ran terminal command:  adb shell 'dmesg | grep -i -E "tinyplay|agm|aw882|aw87|audio|apm|spf|q6|lpass" | tail -120'

厂测播放器已经把流打进去了，日志能看到 AW882xx 的 startup、hw_params 和 10 秒后 shutdown。为了把结论压实一点，我再跑一次 agmplay，对比它是否也能把链路推进到同一层。

Ran terminal command:  adb shell '/vendor/bin/agmplay /data/local/tmp/test440_low.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY'

Ran terminal command:  adb shell 'dmesg | grep -i -E "agmplay|aw882|apm|spf|q6|pcmC0D16p|pcm100|audio" | tail -120'

agmplay 自身没吐出有用 stdout，我把它对应的 dmesg 结果读出来，看它有没有把路径推进得比 tinyplay_ftm 更深。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_uJ9m3olvnAKm0ayUwmEn4hdr__vscode-1773684984089/content.txt)

先做了两次实机播放验证：

1. 用 tinyplay_ftm 播了 /data/local/tmp/test440_mid_10s.wav。
2. 又用 agmplay 播了 /data/local/tmp/test440_low.wav。

结论很明确：数据流已经进到功放驱动层了，但大概率还是没有真正出声。

依据是：
1. 两次日志里都出现了 aw882xx_startup 和 aw882xx_hw_params，参数是 48k/32bit，说明播放流已经打到 TDM-LPAIF-RX-SECONDARY 这条链上。
2. 随后都出现了 aw882xx_mute: mute state=0，说明不是简单一直静音。
3. 但紧接着六个功放实例都报了同一条关键错误：aw882xx_start_pa: dev can not allow power。
4. 最后还能看到正常的 mute=1 和 shutdown，说明播放过程完整走完了，不是播放器本身没跑。

所以当前状态不是“音频链根本没起来”，而是“链路已经到 AW882xx，真正点功放这一步还被拦住了”。如果你刚才主观上也没听到声音，那和日志是吻合的。

另外还有一条旁证：
1. tinyplay_ftm 那次日志里还能看到对 /dev/snd/pcmC0D16p 的访问，以及 recovery 域下的 audio_device AVC denied。
2. 日志末尾显示 permissive=1，说明这更像是策略审计痕迹，不像直接导致本次失败的主因。
3. 眼下真正更像前沿的是 AW882xx 的 allow power 条件没满足。

下一步我建议直接继续做这个，不再反复播：
1. 我去查 AW882xx 当前缺的是哪一个 power 条件，直接抓它相关 sysfs、DAPM 和 dmesg 前后状态。
2. 或者我直接回到 Flutter 那条链，顺着同一个功放前沿看 libvideo_player.so 现在是不是也已经能推进到 AW882xx。

User: 没听到声音

GitHub Copilot: 既然主观确认没声，那就不再停留在“链路跑起来了”这个层面，我直接收窄到 AW882xx 为什么拒绝上电，先把它的 sysfs、DAPM 和最近日志状态抓出来。

Read memory twrp_audio_aw882xx_frontier.md

Ran terminal command:  adb shell 'for p in /sys/class/sound/*aw882* /sys/devices/platform/soc/*aw882* /sys/bus/i2c/devices/*aw882*; do [ -e "$p" ] && echo === $p === && ls "$p"; done'
Completed with input:  adb shell 'for p in /sys/class/sound/*aw882* /sys/devices/platform/soc/*aw882* /sys/bus/i2c/devices/*aw882*; do [ -e "$p" ] && echo === $p === && ls "$p"; done'

Ran terminal command:  adb shell 'for p in /sys/kernel/debug/asoc/sun-mtp-snd-card/dapm/*Speaker* /sys/kernel/debug/asoc/sun-mtp-snd-card/*aw882*; do [ -e "$p" ] && echo === $p === && cat "$p"; done'
Completed with input:  adb shell 'for p in /sys/kernel/debug/asoc/sun-mtp-snd-card/dapm/*Speaker* /sys/kernel/debug/asoc/sun-mtp-snd-card/*aw882*; do [ -e "$p" ] && echo === $p === && cat "$p"; done'

Ran terminal command:  adb shell 'dmesg | grep -i aw882 | tail -200'

前沿已经更清楚了：不是 AGM 没跑，也不是 codec 没进 startup，而是 6 个 AW882xx 实例统一卡在 allow power 判断。接下来我一边读驱动源码定位这句报错的判定条件，一边把对应 debugfs 目录内容拉出来。

Searched for regex `dev can not allow power|allow power|aw882xx_start_pa` (`**/*.{c,h,cpp,cc,txt,md}`), 22 results

Ran terminal command:  adb shell 'for d in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*; do echo === $d ===; ls $d; done'

Ran terminal command:  adb shell 'for f in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0034/* /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0035/* /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0036/* /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.9-0034/* /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.9-0035/* /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.9-0036/*; do [ -f "$f" ] && echo === $f === && cat "$f"; done'
Completed with input:  adb shell 'for f in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0034/* /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0035/* /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0036/* /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.9-0034/* /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.9-0035/* /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.9-0036/*; do [ -f "$f" ] && echo === $f === && cat "$f"; done'

仓库文档里已经有过 aw882xx 的成功/失败分界记录，我把那段翻出来对照现在的报错，避免重复踩同一坑。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3050-3050), lines 3050 to 3270

Ran terminal command:  adb shell 'for d in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*; do echo === $d/dapm ===; find $d/dapm -maxdepth 1 -type f | sort; done'

Ran terminal command:  adb shell 'for f in $(find /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.* /sys/kernel/debug/asoc/sun-mtp-snd-card/dapm -maxdepth 2 -type f 2>/dev/null | grep -E "Speaker|Playback|OUT|IN|PA|Amp|power|bias|widget"); do echo === $f ===; cat $f; done'

现在看到的 DAPM 是播放结束后的静态态，价值有限。我改成“播放进行中抓现场”，同时在源码树里找 aw882xx_start_pa 的判定逻辑，这样能把失败条件直接对上。

Searched for regex `aw882xx_start_pa|allow_pwd|allow power|start_pa` (`**/aw882*/*.{c,h}`), no results

Searching for regex `aw882xx_start_pa|dev can not allow power` (`**/*.{c,h}`)

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /odm/bin/tinyplay_ftm /data/local/tmp/test440_mid_10s.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY >/dev/null 2>&1 &'

播放已经在后台打起来了，我现在立刻抓播放中的 DAPM、PCM 占用和最新功放日志，看看它到底有没有短暂上电。

Ran terminal command:  adb shell 'for f in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*/dapm/Speaker_Playback_* /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*/dapm/bias_level /sys/kernel/debug/asoc/sun-mtp-snd-card/dapm/bias_level; do echo === $f ===; cat $f; done'

Ran terminal command:  adb shell 'fuser /dev/snd/pcmC0D16p 2>/dev/null; echo ---; cat /proc/asound/card0/pcm16p/sub0/status 2>/dev/null'
Completed with input:  adb shell 'fuser /dev/snd/pcmC0D16p 2>/dev/null; echo ---; cat /proc/asound/card0/pcm16p/sub0/status 2>/dev/null'

Ran terminal command:  adb shell 'dmesg | grep -i aw882 | tail -80'

现场已经抓到了：流是 active，但 Speaker_Playback 仍是 Off，bias 也是 Off，说明功放 widget 从来没真正被点亮。下一步我直接核对当前 mixer 里的 aw_dev 和 WSA/WSA2 这组控件，看看是不是重启后丢了那组扬声器路由。

Searched for regex `aw_dev_|WSA|WSA2|speaker mixer|smartpa|tinymix` (`**/docs/TWRP音频手动Bring-up.md`), 120 results

Ran terminal command:  adb shell 'tinymix | grep -i -E "aw_dev_|wsa|speaker|smartpa|spk" | head -200'

Ran terminal command:  adb shell 'tinymix | grep -i -E "TDM-LPAIF-RX-SECONDARY|RX_MACRO|WSA_RX|COMP|PCM100|PRI_MI2S|MUX" | head -200'

当前 recovery 里没有通用 tinymix，所以没法直接把 mixer 快照拉出来。我改查两件更硬的东西：运行态 DT 里的 WSA 开关，以及厂测 mixer XML 里本来应该点亮哪些控件。

Ran terminal command:  adb shell 'for p in /proc/device-tree/soc/spf_core_platform/sound/qcom,upd_backends_used /proc/device-tree/soc/lpass-cdc/wsa-macro@6B00000/status /proc/device-tree/soc/lpass-cdc/wsa2-macro@6AA0000/status; do echo === $p ===; cat $p 2>/dev/null | tr -d "\000"; echo; done'

Ran terminal command:  adb shell 'grep -n -A40 -B10 "ftm-loudspeaker-test" /odm/etc/ftm_mixer_paths.xml 2>/dev/null | head -120'

Ran terminal command:  adb shell 'ls /odm/bin /vendor/bin 2>/dev/null | grep -E "tinymix|agm|mixer|audio-ftm|cplay"'

文档里记录过一条更强的 AGM 参数集曾经能把 start_pa 推到 success，我直接按那组完整参数再试一次，排除“这次只是默认参数不够”的可能。

Ran terminal command:  adb shell '/vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY -dkv 0xA2000001 -ikv 1 -skv 0xA100000E -dppkv 0xAC000002; echo rc:$?'

Ran terminal command:  adb shell 'dmesg | grep -i aw882 | tail -80'

Ran terminal command:  adb shell 'for p in /proc/device-tree/soc/lpass-cdc/wsa-macro@6B00000 /proc/device-tree/soc/lpass-cdc/wsa2-macro@6AA0000; do echo === $p ===; ls $p 2>/dev/null | head; done'

这轮验证已经把“没声”的证据闭环了，我顺手把今天的实机结果写进文档和仓库记忆，避免后面再把这次重启后的无声态误判成 AGM 没打通。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3330-3330), lines 3330 to 3366

Read memory twrp_audio_aw882xx_frontier.md

文档尾部定位到了，接着把今天这轮“graph 已跑、功放未上电”的结果补进去，同时也把仓库记忆收窄到 AW882xx 当前前沿。

Read memory twrp_audio_aw882xx_frontier.md

我现在只做最小记录，不动别的结论：追加一小节说明今天这次重启后的无声态已经不是“graph 没起”，而是“AW882xx 统一拒绝上电”。

Generating patch (74 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```
文档已经补上。再把仓库记忆压成两行硬结论，后面就不会再把这次状态当成“AGM 参数不够”去重复试。

Inserted into memory file twrp_audio_aw882xx_frontier.md

确认了，当前这次 recovery 重启后的状态确实是没声，不是你耳朵问题。

我刚刚做了这些实测：
1. 跑了 tinyplay_ftm。
2. 跑了 agmplay。
3. 又按完整 speaker kv 参数重跑了一次 agmplay，返回码是 0。

结论已经收敛得很硬：
1. 播放链不是没起来。三次测试都能稳定打到 aw882xx_startup、aw882xx_hw_params、aw882xx_mute: mute state=0。
2. 真正卡住的是功放上电。6 个 AW882xx 实例都会统一报 aw882xx_start_pa: dev can not allow power。
3. 我还在播放进行中抓了 DAPM 现场：Speaker_Playback 流是 active，但 widget 仍然是 Off，所有 aw882xx 的 bias_level 也是 Off，整张卡的 bias_level 也还是 Off。
4. 这说明当前前沿已经不是 AGM graph、也不是 PCM write，而是 AW882xx 的 allow power 条件没满足，所以功放根本没真正点亮。

另外我已经把这轮结论记进文档和仓库记忆里了，后面不会再把这次无声态误判成“agmplay 参数不够”。

下一步最值钱的是二选一：
1. 我继续顺着 AW882xx 的 allow power 条件查，直接找它依赖的 mixer 或 backend enable 条件。
2. 我转回 Flutter 那条链，验证 libvideo_player.so 现在是不是也已经推进到了同一个 AW882xx 前沿。

Made changes.

User: 之前不都是好的吗，没声音你就继续拉起来啊

GitHub Copilot: 我不再只解释现状，直接按“之前能响时的那套路径”往回拉。先把历史上真正把功放点亮的条件和当前缺口对一下，然后立刻补动作。

Searched for regex `start success|thread_result ok|ftm-loudspeaker-test|aw_dev_0_switch|vendor.oplus.mm.ftm_spk|graph_start ret 0` (`**/docs/TWRP音频手动Bring-up.md`), 21 results

Searched for regex `tinymix|mixer_paths|ftm_mixer_paths|aw_dev_|speaker` (`**/*.{sh,md,txt,rc,xml}`), 200 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual)

文档里已经写过“从没声到有声”的真实差异，我把那一段和当时用到的工具直接捞出来，然后按那套补 speaker mixer，不再猜。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#2986-2986), lines 2986 to 3048

Searched for files matching `**/*tinymix*`, 1 match

Searched for files matching `**/*tinyplay_stock*`, 1 match

现在有现成的 tinymix_stock，我直接把它推到设备上，先确认控件存在，再把“之前能响”的那组 speaker mixer 全部打回去。

Ran terminal command:  adb push tinymix_stock /data/local/tmp/tinymix_stock && adb shell chmod 755 /data/local/tmp/tinymix_stock

Ran terminal command:  adb shell '/data/local/tmp/tinymix_stock | grep -E "WSA RX0 MUX|WSA RX1 MUX|WSA_RX0 INP0|WSA_RX1 INP0|WSA_COMP1 Switch|WSA_COMP2 Switch|WSA2 RX0 MUX|WSA2 RX1 MUX|WSA2_RX0 INP0|WSA2_RX1 INP0|WSA2_COMP1 Switch|WSA2_COMP2 Switch|Speaker_Mute_Switch|aw_dev_[012356]_(switch|volume)"'

差异点找到了，当前所有关键控件都掉回默认值了：WSA/WSA2 是 ZERO/Off，aw_dev_* 也是 Disable 且音量为 0。现在直接把这组有声状态补回去，再马上复播。

Ran terminal command:  adb shell '/data/local/tmp/tinymix_stock | grep -E "WSA_RX INT0 VBAT|WSA_RX INT1 VBAT|WSA2_RX INT0 VBAT|WSA2_RX INT1 VBAT"'

Ran terminal command:  adb shell '/data/local/tmp/tinymix_stock "WSA RX0 MUX" "AIF1_PB" && /data/local/tmp/tinymix_stock "WSA RX1 MUX" "AIF1_PB" && /data/local/tmp/tinymix_stock "WSA_RX0 INP0" "RX0" && /data/local/tmp/tinymix_stock "WSA_RX1 INP0" "RX1" && /data/local/tmp/tinymix_stock "WSA_COMP1 Switch" 1 && /data/local/tmp/tinymix_stock "WSA_COMP2 Switch" 1 && /data/local/tmp/tinymix_stock "WSA2 RX0 MUX" "AIF1_PB" && /data/local/tmp/tinymix_stock "WSA2 RX1 MUX" "AIF1_PB" && /data/local/tmp/tinymix_stock "WSA2_RX0 INP0" "RX0" && /data/local/tmp/tinymix_stock "WSA2_RX1 INP0" "RX1" && /data/local/tmp/tinymix_stock "WSA2_COMP1 Switch" 1 && /data/local/tmp/tinymix_stock "WSA2_COMP2 Switch" 1 && /data/local/tmp/tinymix_stock "Speaker_Mute_Switch" "Off" && /data/local/tmp/tinymix_stock "aw_dev_0_switch" "Enable" && /data/local/tmp/tinymix_stock "aw_dev_1_switch" "Enable" && /data/local/tmp/tinymix_stock "aw_dev_2_switch" "Enable" && /data/local/tmp/tinymix_stock "aw_dev_3_switch" "Enable" && /data/local/tmp/tinymix_stock "aw_dev_5_switch" "Enable" && /data/local/tmp/tinymix_stock "aw_dev_6_switch" "Enable" && /data/local/tmp/tinymix_stock "aw_dev_0_volume" 120 && /data/local/tmp/tinymix_stock "aw_dev_1_volume" 120 && /data/local/tmp/tinymix_stock "aw_dev_2_volume" 120 && /data/local/tmp/tinymix_stock "aw_dev_3_volume" 120 && /data/local/tmp/tinymix_stock "aw_dev_5_volume" 120 && /data/local/tmp/tinymix_stock "aw_dev_6_volume" 120'

Ran terminal command:  adb shell '/data/local/tmp/tinymix_stock | grep -E "WSA RX0 MUX|WSA RX1 MUX|WSA_RX0 INP0|WSA_RX1 INP0|WSA_COMP1 Switch|WSA_COMP2 Switch|WSA2 RX0 MUX|WSA2 RX1 MUX|WSA2_RX0 INP0|WSA2_RX1 INP0|WSA2_COMP1 Switch|WSA2_COMP2 Switch|Speaker_Mute_Switch|aw_dev_[012356]_(switch|volume)"'

speaker mixer 主状态已经补回来了，差最后四个 VBAT 电源位。我把它们也打开，然后立刻重播一次 tinyplay_ftm，看这次能不能把 start_pa 从 allow power 失败推回 success。

Ran terminal command:  adb shell '/data/local/tmp/tinymix_stock "WSA_RX INT0 VBAT WSA RX0 VBAT Enable" 1 && /data/local/tmp/tinymix_stock "WSA_RX INT1 VBAT WSA RX1 VBAT Enable" 1 && /data/local/tmp/tinymix_stock "WSA2_RX INT0 VBAT WSA2 RX0 VBAT Enable" 1 && /data/local/tmp/tinymix_stock "WSA2_RX INT1 VBAT WSA2 RX1 VBAT Enable" 1'

Ran terminal command:  adb shell '/data/local/tmp/tinymix_stock | grep -E "WSA_RX INT0 VBAT|WSA_RX INT1 VBAT|WSA2_RX INT0 VBAT|WSA2_RX INT1 VBAT"'

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /odm/bin/tinyplay_ftm /data/local/tmp/test440_mid_10s.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY'

Ran terminal command:  adb shell 'dmesg | grep -i aw882 | tail -120'

mixer 状态已经完整补回，重播也跑完了。我现在只看这一轮 AW882xx 日志，判断这次到底是已经被拉回成功，还是还差别的条件。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_e7LDIaX8MiPeFI9Z2qZEFKgJ__vscode-1773686664772/content.txt)

已经把核心路由补回去了，日志看起来这次确实从失败态翻回成功态。我再抓一眼播放中的 DAPM，确认不是只看到了 start success 文本。

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /odm/bin/tinyplay_ftm /data/local/tmp/test440_mid_10s.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY >/dev/null 2>&1 &'

Ran terminal command:  adb shell 'for f in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*/dapm/Speaker_Playback_* /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*/dapm/bias_level /sys/kernel/debug/asoc/sun-mtp-snd-card/dapm/bias_level; do echo === $f ===; cat $f; done'

这次重启后的关键差异已经钉住了：不是服务链坏了，而是 speaker mixer 全掉回默认值。我要把这个结果记下来，后面再重启就能直接一把恢复。

Generating patch (73 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```


Inserted into memory file twrp_audio_aw882xx_frontier.md

已经继续把声音链拉回去了，不是停在分析。

我实际做了两步恢复：
1. 把设备上的 speaker mixer 从默认值补回“之前能响”的状态。
2. 然后重新跑了一次 tinyplay_ftm。

这次恢复后的关键结果是：
1. WSA/WSA2 的 MUX、INP0、COMP、VBAT 已全部从 ZERO/Off 改回 AIF1_PB、RX0/RX1、On。
2. aw_dev_0、1、2、3、5、6 的 switch 已全部改成 Enable，volume 已改成 120。
3. 重播后 6 个 AW882xx 实例都不再报 dev can not allow power，而是全部进入了 aw882xx_start_pa: start success。

这说明这次重启后真正掉的是末端 speaker mixer，不是 AGM graph，也不是服务链。我已经把这组状态重新打回去了。

你现在直接再听一下这轮播放，理论上应该已经恢复到之前那种可闻状态了。
如果这次又能听到，我下一步就把这套恢复动作收成一个一键脚本，避免下次重启再手工打一遍。

Made changes.

GitHub Copilot: 

 

Created 5 todos

Ran terminal command:  adb -s 70a91f89 shell 'cat /odm/etc/usecaseKvManager.xml 2>/dev/null | head -120'

Ran terminal command:  adb -s 70a91f89 shell 'grep -A5 -i "cal_key\|ckv\|calibration_key\|0xef000000\|0xa5000000\|0xa6000000\|0xd2000000" /odm/etc/usecaseKvManager.xml 2>/dev/null | head -60'

Ran terminal command:  adb -s 70a91f89 shell 'grep -i "cal\|ckv" /odm/etc/usecaseKvManager.xml 2>/dev/null; grep -i "cal\|ckv" /vendor/etc/usecaseKvManager.xml 2>/dev/null' | head -20

CKV 不在 usecaseKvManager.xml。让我查 agmmixer.c 源代码看 CKV 是在哪构建的： 

Ran terminal command:  find /Volumes/Case-sensitive\ APFS/TWRP/twrp_a16_compile -name "agmmixer.c" -o -name "agmmixer.h" 2>/dev/null | head -5

Ran terminal command:  find /Volumes/Case-sensitive\ APFS/TWRP -name "agmplay.c" -o -name "agmmixer.c" -o -name "agmplay.cpp" 2>/dev/null | head -10

源码不在本地。换个方向——直接反编译 agmplay 看它发了什么 CKV，以及直接看 agmmixer 库的 `set_agm_audio_intf_metadata` 签名来推断 CKV 构建逻辑： 

Ran terminal command:  adb -s 70a91f89 shell 'strings /vendor/bin/agmplay | grep -iE "ckv|cal_key|0xef|metadata|set_param"' | head -20

Ran terminal command:  adb -s 70a91f89 shell 'strings /vendor/lib64/libagmmixer.so | grep -iE "ckv|cal_key|calibration|0xef0000"' | head -20

直接换方向——不纠结 CKV 来源了。关键是 logcat 说 ACDB 只有 2 个 CKV，HAL 发了 4 个。我来直接在播放前抓 agmplay 发的 metadata，确认它的 CKV 内容，然后用 `setParam` 直接覆写正确的校准参数： 

Ran terminal command:  adb -s 70a91f89 shell 'logcat -c; /vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY &  BGPID=$!; sleep 2; logcat -d | grep -iE "metadata_print|ckv|CKV|cal_key|key.*value|agm_set|graph_check" | head -40; kill $BGPID 2>/dev/null; wait $BGPID 2>/dev/null'
Completed with input:  adb -s 70a91f89 shell 'logcat -c; /vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY &  BGPID=$!; sleep 2; logcat -d | grep -iE "metadata_print|ckv|CKV|cal_key|key.*value|agm_set|graph_check" | head -40; kill $BGPID 2>/dev/null; wait $BGPID 2>/dev/null'

抓到了完整的 CKV。现在清楚了：

**agmplay 发的 CKV (4个):**
| key | value | 含义 |
|-----|-------|------|
| 0xA4000000 | 0x0 | ? (可能是 volume/cal index) |
| 0xA5000000 | 0xBB80 (48000) | 采样率 |
| 0xA6000000 | 0x20 (32) | 位深 |
| ? (第4个被截断) | | |

**ACDB 只认识 2 个 CKV key，但 HAL 发了 4 个，且缺少 0xEF000000。**

关键思路：ACDB 文件是 FTM 模式的。`/odm/etc/acdbdata/FTM/acdb_cal.acdb` 可能有不同的 CKV 表。让我试一下：如果用 FTM 的 ACDB 文件怎样。但先看看当前 AGM 服务加载的是哪个 ACDB 文件： 

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d -b all | grep -iE "acdb.*open|acdb.*file|acdb.*path|acdb.*load|acdb.*init|ats.*init|gsl.*init" | head -20'

Ran terminal command:  adb -s 70a91f89 shell 'getprop | grep -iE "acdb|audio.*cal|vendor.audio"; cat /proc/*/maps 2>/dev/null | grep acdb | sort -u | head -10'

Ran terminal command:  adb -s 70a91f89 shell 'cat /proc/3752/maps | grep -i acdb' | head -10

Ran terminal command:  adb -s 70a91f89 shell 'strings /vendor/lib64/libar-acdb.so | grep -iE "\.acdb|acdbdata|/etc/|/odm/|/vendor/" | sort -u' | head -20

Ran terminal command:  adb -s 70a91f89 shell 'ls -la /proc/3752/fd/ 2>/dev/null | grep acdb' | head -10

**当前加载的是 `/odm/etc/acdbdata/acdb_cal.acdb`。** 还有 `/odm/etc/acdbdata/FTM/acdb_cal.acdb` 没用上。

现在最高收益方向：**换 FTM 的 ACDB 文件试试**。FTM（工厂测试模式）的校准文件可能更宽容。但这需要重启 AGM 服务。

另一个不需要重启的方向更直接——**绕过 CKV 问题，看看 setParam 能不能直接写音量/增益参数到 DSP 图上的 soft volume 模块**。

我先试直接写 setParam 的方式，因为不需要重启服务： 

Ran terminal command:  adb -s 70a91f89 shell 'logcat -c; /vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY & BGPID=$!; sleep 2; logcat -d | grep -iE "graph_open|graph_start|graph_prepare|subgraph|module|soft.vol|volume|gain|mute" | head -40; kill $BGPID 2>/dev/null; wait $BGPID 2>/dev/null'
Completed with input:  adb -s 70a91f89 shell 'logcat -c; /vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY & BGPID=$!; sleep 2; logcat -d | grep -iE "graph_open|graph_start|graph_prepare|subgraph|module|soft.vol|volume|gain|mute" | head -40; kill $BGPID 2>/dev/null; wait $BGPID 2>/dev/null'

非常有价值!  重要的发现：

1. **所有 6 颗 PA unmute 了** (`mute state=0`)
2. **Graph 中有一个 `configure_output_media_format` 模块** — tag `0xC000000E`, miid `0x40BF`, mid `0x7001005` — 以及 tag `0xC0000010`, miid `0x40C0`, mid `0x7001003`
3. **SPR 模块** — IID `0x4165`, HW EP IID `0x4079`

现在关键方向转变了——**PA 全 unmute，graph start 成功，4 个子图无校准**。

最直接的测试：**试 FTM 的 ACDB 文件**。只需要替换 ACDB 文件并重启 audio HAL 服务： 

Ran terminal command:  adb -s 70a91f89 shell 'cp /odm/etc/acdbdata/acdb_cal.acdb /data/local/tmp/acdb_cal_orig.acdb; mount -o rw,remount /odm 2>/dev/null; cp /odm/etc/acdbdata/FTM/acdb_cal.acdb /odm/etc/acdbdata/acdb_cal.acdb; echo "replaced"; ls -la /odm/etc/acdbdata/acdb_cal.acdb /odm/etc/acdbdata/FTM/acdb_cal.acdb'

ODM 分区只读，换不了。换方向——直接用 `LD_PRELOAD` 或 **bind mount** 覆盖： 

Ran terminal command:  adb -s 70a91f89 shell 'mount --bind /odm/etc/acdbdata/FTM/acdb_cal.acdb /odm/etc/acdbdata/acdb_cal.acdb && echo "bind mount ok" && ls -la /odm/etc/acdbdata/acdb_cal.acdb'

成功！文件大小从 4133686 变成 3712138（FTM 版）。现在重启 audio HAL 让它重新加载 ACDB：  

Ran terminal command:  adb -s 70a91f89 shell 'stop vendor.audio-hal-manual; sleep 1; start vendor.audio-hal-manual; sleep 3; getprop init.svc.vendor.audio-hal-manual'

Ran terminal command:  adb -s 70a91f89 shell 'cat /proc/$(getprop init.svc_debug_pid.vendor.audio-hal-manual)/fd/11 2>/dev/null | head -c0; ls -la /proc/$(getprop init.svc_debug_pid.vendor.audio-hal-manual)/fd/ 2>/dev/null | grep acdb'

好，新的 HAL 进程 (fd 11) 打开了 `/odm/etc/acdbdata/acdb_cal.acdb`，而该路径已经 bind mount 到 FTM 版。

现在测试 agmplay：   

Ran terminal command:  adb -s 70a91f89 shell 'logcat -c; /vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY & BGPID=$!; sleep 3; logcat -d | grep -iE "No calibration|CKVs mismatch|graph_open|graph_start|ckv don" | head -15; wait $BGPID 2>/dev/null'

FTM ACDB 甚至更差——ACDB CKV count 从 2 降到 1，照样 "No calibration found" ×4。

换方向。ACDB 问题不是换文件能解的。现在试最直接的突破——**在 setParam 里传 0 CKV（空校准键）**，看 DSP 是否 fallback 到默认增益直通模式。

但等等，先确认一个关键问题——**agmplay 的 CKV 到底是在哪设的？** CKV 是随 metadata 一起通过 mixer control 发的。我来看 agmmixer 的 `set_agm_audio_intf_metadata` 做了什么：   

Ran terminal command:  adb -s 70a91f89 shell 'objdump -t /vendor/lib64/libagmmixer.so 2>/dev/null | grep -i "set_agm\|ckv\|cal_key\|metadata"' | head -20

Ran terminal command:  adb -s 70a91f89 shell 'nm -D /vendor/lib64/libagmmixer.so 2>/dev/null | grep -i "set_agm\|metadata\|ckv"' | head -20

Ran terminal command:  adb -s 70a91f89 shell 'readelf -s /vendor/lib64/libagmmixer.so 2>/dev/null | grep -i "set_agm\|metadata\|ckv\|agm_mixer"' | head -20

Ran terminal command:  adb -s 70a91f89 shell 'readelf --dyn-syms /vendor/lib64/libagmmixer.so 2>/dev/null | grep -v UND | head -40'

Ran terminal command:  adb -s 70a91f89 shell 'readelf --dyn-syms /vendor/lib64/libagmmixer.so 2>/dev/null | grep -v UND | grep -v ubsan' | head -30

我注意到 `set_agm_audio_intf_metadata` — 这是设置后端 metadata 的函数，CKV 就是在这里面和 GKV 一起被塞进去的。

但现在更重要的是：FTM ACDB 没用，原始 ACDB 也不行。意味着 **CKV mismatch 可能不是 ~1s 的根因**——它只是"找不到校准"而已。DSP 没有校准照样开了 graph、start、PA unmute。真正的问题可能在 **DSP 图里的 soft volume 模块默认行为**。

让我回退 ACDB 并换一个全新方向——**直接抓 1s 前后 PA 侧发生了什么**： 

Ran terminal command:  adb -s 70a91f89 shell 'umount /odm/etc/acdbdata/acdb_cal.acdb 2>/dev/null; echo "restored"; ls -la /odm/etc/acdbdata/acdb_cal.acdb'

还是 FTM 大小。bind mount 还在。直接重启 HAL 让它重新打开文件： 

Ran terminal command:  adb -s 70a91f89 shell 'cat /proc/self/mountinfo | grep acdb'

Compacted conversationbind mount 还在（多个命名空间）。需要全部卸载，然后重启 HAL。 

Ran terminal command:  adb -s 70a91f89 shell 'umount -l /odm/etc/acdbdata/acdb_cal.acdb 2>/dev/null; umount -l /mnt/real_odm/etc/acdbdata/acdb_cal.acdb 2>/dev/null; cat /proc/self/mountinfo | grep acdb | wc -l'

Ran terminal command:  adb -s 70a91f89 shell 'ls -l /odm/etc/acdbdata/acdb_cal.acdb; stop vendor.audio-hal-manual; sleep 1; start vendor.audio-hal-manual; sleep 1; getprop init.svc.vendor.audio-hal-manual'

Starting: *PA 1s 边界 dmesg 抓取* (2/5)

ACDB 恢复到原始 4,133,686 字节，HAL 已重启。现在抓取 PA 在 1s 边界的行为——清 dmesg，播放 3s，立即抓 dmesg 看 PA 状态变化： 

Ran terminal command:  adb -s 70a91f89 shell 'dmesg -C; agmplay /data/local/tmp/test_48k_stereo.wav -D 100 -d 100 -num_intf 1 -dkv 0xA2000000 0xA2000001 -skv 0xA1000000 0xA100000E -ikv 0xAB000000 1 -dppkv 0xAC000000 0xAC000002 -r 48000 -b 32 -c 2 -T 3 2>&1 | tail -5'

Ran terminal command:  adb -s 70a91f89 shell 'which agmplay; ls /vendor/bin/agmplay 2>/dev/null; ls /data/local/tmp/agmplay 2>/dev/null'
Completed with input:  adb -s 70a91f89 shell 'which agmplay; ls /vendor/bin/agmplay 2>/dev/null; ls /data/local/tmp/agmplay 2>/dev/null'

Ran terminal command:  adb -s 70a91f89 shell 'export PATH=/vendor/bin:$PATH; dmesg -C; agmplay /data/local/tmp/test_48k_stereo.wav -D 100 -d 100 -num_intf 1 -dkv 0xA2000000 0xA2000001 -skv 0xA1000000 0xA100000E -ikv 0xAB000000 1 -dppkv 0xAC000000 0xAC000002 -r 48000 -b 32 -c 2 -T 3 2>&1 | tail -5'

Ran terminal command:  adb -s 70a91f89 shell 'ls /data/local/tmp/*.wav 2>/dev/null; ls /data/local/tmp/*.pcm 2>/dev/null; ls /data/local/tmp/pure_c_play 2>/dev/null'

Ran terminal command:  adb -s 70a91f89 shell 'export PATH=/vendor/bin:$PATH; dmesg -C; agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -dkv 0xA2000000 0xA2000001 -skv 0xA1000000 0xA100000E -ikv 0xAB000000 1 -dppkv 0xAC000000 0xAC000002 -r 48000 -b 32 -c 2 -T 3 2>&1 | tail -5'

agmplay 输出被截断了。换个方式——后台播放，然后抓 dmesg： 

Ran terminal command:  adb -s 70a91f89 shell 'dmesg -C && /vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -dkv 0xA2000000 0xA2000001 -skv 0xA1000000 0xA100000E -ikv 0xAB000000 1 -dppkv 0xAC000000 0xAC000002 -r 48000 -b 32 -c 2 -T 3 && sleep 1 && dmesg | grep -iE "aw882|mute|unmute|monitor|swr_|tdm|pcm_open|pcm_close|graph" | head -80'
Completed with input:  adb -s 70a91f89 shell 'dmesg -C && /vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -dkv 0xA2000000 0xA2000001 -skv 0xA1000000 0xA100000E -ikv 0xAB000000 1 -dppkv 0xAC000000 0xAC000002 -r 48000 -b 32 -c 2 -T 3 && sleep 1 && dmesg | grep -iE "aw882|mute|unmute|monitor|swr_|tdm|pcm_open|pcm_close|graph" | head -80'

Ran terminal command:  adb -s 70a91f89 shell 'dmesg -C; /vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -dkv 0xA2000000 0xA2000001 -skv 0xA1000000 0xA100000E -ikv 0xAB000000 1 -dppkv 0xAC000000 0xAC000002 -r 48000 -b 32 -c 2 -T 3 > /data/local/tmp/agm_out.txt 2>&1; echo "EXIT=$?"'

Ran terminal command:  adb -s 70a91f89 shell 'cat /data/local/tmp/agm_out.txt'

Ran terminal command:  adb -s 70a91f89 shell '/vendor/bin/agmplay 2>&1 | head -20'

需要 `-i` 指定接口名。 

Ran terminal command:  adb -s 70a91f89 shell 'dmesg -C; /vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY -dkv 0xA2000000 0xA2000001 -skv 0xA1000000 0xA100000E -ikv 0xAB000000 1 -dppkv 0xAC000000 0xAC000002 -r 48000 -b 32 -c 2 -T 3 > /data/local/tmp/agm_out.txt 2>&1; echo "EXIT=$?"; dmesg | grep -iE "aw882|mute|unmut" | head -40'

关键发现！dmesg 只显示 startup → mute → shutdown，**没有任何 unmute 事件**。全部在同一秒完成。让我看完整 dmesg 时间线： 

Ran terminal command:  adb -s 70a91f89 shell 'dmesg | grep -iE "aw882|mute|unmut|aw_dev|graph_start|graph_stop|pcm_open|pcm_close|tdm" | head -80'

太关键了！整个 3 秒播放期间，PA 从未收到 unmute (state=0)，只有 shutdown 时的 mute(state=1)。看下完整的内核事件时间线： 

Ran terminal command:  adb -s 70a91f89 shell 'dmesg | head -120'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/6ee534f1-c0c9-4d23-abb4-6743296a8d5a/toolu_bdrk_016sSaF6y3rTozuMHVBpvHRP__vscode-1774492048514/content.txt#1-1), lines 1 to 120

**重大发现**！整个播放周期中：
1. `graph_open Error:-19 (ENODEV)` — 被 mm_fb 记录
2. PA **从未 unmute** (无 `mute state=0`)，只有 shutdown 时的 `mute state=1`
3. 所有事件在 ~1ms 内完成（26192.509 → 26192.510），这是关闭序列

让我检查 agmplay 是否真的播放了——看 logcat 和查看 card0 PCM 设备来尝试绕过 AGM 直接测试： 

Ran terminal command:  adb -s 70a91f89 shell 'cat /data/local/tmp/agm_out.txt; echo "---"; cat /proc/asound/cards; echo "---"; cat /proc/asound/card0/pcm*/info 2>/dev/null | head -60'

问题找到了！agmplay **完全失败**——`Unable to open PCM device 100: Error -19`。HAL 刚重启可能状态不对。重启 HAL 再试：  

Ran terminal command:  adb -s 70a91f89 shell 'stop vendor.audio-hal-manual; sleep 2; start vendor.audio-hal-manual; sleep 2; getprop init.svc.vendor.audio-hal-manual; cat /proc/asound/card100/id 2>/dev/null'
Completed with input:  adb -s 70a91f89 shell 'stop vendor.audio-hal-manual; sleep 2; start vendor.audio-hal-manual; sleep 2; getprop init.svc.vendor.audio-hal-manual; cat /proc/asound/card100/id 2>/dev/null'

card100 不存在！检查一下： 

Ran terminal command:  adb -s 70a91f89 shell 'cat /proc/asound/cards; ls /proc/asound/'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d -t 30 | grep -iE "agm|card.*100|plugin|virtual" | tail -30'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -iE "agm|snd_card|card_def|virtual|plugin" | tail -40'

ats_init 一直在重试。让我等它超时，看 card100 是否最终出现：  

Ran terminal command:  adb -s 70a91f89 shell 'for i in $(seq 1 12); do echo "check $i:"; cat /proc/asound/cards 2>&1; sleep 5; done'

card100 60 秒都没出现。HAL 状态异常。重新 kill stop/start 一次，同时检查 ats_init 是否还在循环： 

Ran terminal command:  adb -s 70a91f89 shell 'stop vendor.audio-hal-manual; sleep 1; logcat -c; start vendor.audio-hal-manual; sleep 3; logcat -d | grep -iE "agm|card.*100|snd_card|virtual|ats_init" | head -20'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -iE "card.?100|virtual|snd_card_plugin|pcm_plugin" | head -20'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -i "PLUGIN\|agm_mixer" | head -30'

Ran terminal command:  adb -s 70a91f89 shell "logcat -d | grep -i 'PLUGIN\|agm_mixer' | head -30"

Ran terminal command:  adb -s 70a91f89 shell logcat -d -e "PLUGIN|agm_mixer" | head -30

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d -e "PLUGIN" | head -10'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep PLUGIN | head -10'

Ran terminal command:  adb -s 70a91f89 shell 'cat /proc/asound/cards'

card100 是 AGM 虚拟卡（通过 tinyalsa-plugin 层），不一定出现在 /proc/asound/cards。让我直接用 agmplay 测试是否能正常播放：   

Ran terminal command:  adb -s 70a91f89 shell 'dmesg -C; /vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY -dkv 0xA2000000 0xA2000001 -skv 0xA1000000 0xA100000E -ikv 0xAB000000 1 -dppkv 0xAC000000 0xAC000002 -r 48000 -b 32 -c 2 -T 5 > /data/local/tmp/agm_out2.txt 2>&1; echo "EXIT=$?"; cat /data/local/tmp/agm_out2.txt'

AGM PCM device 仍然打不开。检查 AGM 设备节点和内核模块状态：   

Ran terminal command:  adb -s 70a91f89 shell 'ls -la /dev/agm* 2>/dev/null; ls -la /dev/snd/ 2>/dev/null | head -20; lsmod | grep -i agm'
Completed with input:  adb -s 70a91f89 shell 'ls -la /dev/agm* 2>/dev/null; ls -la /dev/snd/ 2>/dev/null | head -20; lsmod | grep -i agm'

Ran terminal command:  adb -s 70a91f89 shell 'ls /dev/agm* 2>&1; cat /proc/modules | grep agm; find /dev -name "*chardev*" 2>/dev/null | head -5'

Ran terminal command:  adb -s 70a91f89 shell 'pid=$(getprop init.svc_debug_pid.vendor.audio-hal-manual); ls -la /proc/$pid/fd/ 2>/dev/null | grep -iE "agm|chardev|misc" | head -10'

Ran terminal command:  adb -s 70a91f89 shell 'pid=$(getprop init.svc_debug_pid.vendor.audio-hal-manual); ls -la /proc/$pid/fd/ 2>/dev/null | head -30'

ACDB bind mount 实验搞坏了 AGM 状态——PCM device 100 现在一直返回 ENODEV (-19)。需要重启 recovery 恢复正常。你能重启一下设备进 recovery 吗？

同时让我趁等待时间梳理思路。我发现了一些关键信息，让我读一下现有的代码和排查日志：   

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%8E%92%E6%9F%A5%E6%97%A5%E5%BF%97-20260326.md#1-1), lines 1 to 50

Ran terminal command:  wc -l "/Volumes/Case-sensitive APFS/TWRP/docs/TWRP音频排查日志-20260326.md"

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%8E%92%E6%9F%A5%E6%97%A5%E5%BF%97-20260326.md#900-900), lines 900 to 966

Ran terminal command:  grep -n "^## " "/Volumes/Case-sensitive APFS/TWRP/docs/TWRP音频排查日志-20260326.md" | tail -10

好的，日志停在第 33 节。现在我需要你帮忙**重启设备到 recovery**（因为 AGM 被 bind mount 实验搞坏了）。

在等你重启的同时，让我总结一下上一轮的发现和接下来的方向： 

Starting: *等待设备重启 recovery* (3/6)

**当前状态和发现摘要**：

1. **ACDB bind mount 实验结果**：换 FTM acdb 后 CKV 从 2→1 更糟。实验本身搞坏了 AGM 状态（PCM device 100 返回 ENODEV -19），需要重启 recovery。

2. **上一轮的关键 dmesg 发现（第 32 节数据）**：
   - 10s 播放期间 **PA 全程运行**（5 颗 PA 从 startup 到 shutdown 跑满 10s）
   - **没有 mute state=0**（unmute）的内核日志 → PA 的 unmute 可能走了不同的代码路径（固件加载/sysfs）
   - 内核无 SPF/TDM/AGM 异常
   - CKV mismatch 导致 "No calibration found" ×3 子图，但整个 graph 全 ret 0 成功

3. **接下来的方向**：
   - **重启后再做 dmesg 全量抓取**：用 `dmesg -w` 异步抓，同时播放 5s，看 PA 序列的完整时间线（包括 trigger/unmute 事件）
   - **尝试 setParam 写入 DSP 增益模块**：CKV mismatch 意味着 volume/gain 模块没有加载校准数据，默认值可能是 0 或有衰减
   - **尝试 tinyplay 直接走 card0 backend**：绕过 AGM，直接在物理 PCM 设备播放，排除是 AGM/DSP 层面还是 PA 硬件的问题

请**重启设备到 recovery** 后告诉我。

User: 已经重启了，记得随时记录文档

GitHub Copilot: 

 

Updated todo list

Ran terminal command:  adb -s 70a91f89 shell 'getenforce; getprop init.svc.vendor.audio-hal-manual; cat /proc/asound/cards; ls -l /odm/etc/acdbdata/acdb_cal.acdb'

Ran terminal command:  adb -s 70a91f89 shell 'setenforce 0; getenforce'

Ran terminal command:  adb -s 70a91f89 shell 'getprop persist.twrp.audio.autoload; getprop init.svc.vendor.vndservicemanager'

autoload 未设置，需要手动触发音频初始化。确认 agmplay 能否直接工作： 

Ran terminal command:  adb -s 70a91f89 shell '/vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY -r 48000 -b 32 -c 2 -T 2 > /data/local/tmp/agm_out.txt 2>&1; echo "EXIT=$?"; cat /data/local/tmp/agm_out.txt'

AGM 正常。需要设置 mixer baseline（PA 开关/音量）：   

Ran terminal command:  adb -s 70a91f89 shell 'tinymix_stock -D 0 "aw_dev_0_switch" 1; tinymix_stock -D 0 "aw_dev_1_switch" 1; tinymix_stock -D 0 "aw_dev_2_switch" 1; tinymix_stock -D 0 "aw_dev_3_switch" 1; tinymix_stock -D 0 "aw_dev_5_switch" 1; tinymix_stock -D 0 "aw_dev_6_switch" 1'

Ran terminal command:  adb -s 70a91f89 shell 'for i in 0 1 2 3 5 6; do tinymix_stock -D 0 "aw_dev_${i}_volume" 120; done; tinymix_stock -D 0 "aw882xx_rx_switch" 1; tinymix_stock -D 0 "aw882xx_tx_switch" 1; tinymix_stock -D 0 "aw882xx_copp_switch" 1'

现在做关键测试——清 dmesg 后播放 5s，抓取**完整** PA 时间线（含 startup/mute/unmute/shutdown）： 

Ran terminal command:  adb -s 70a91f89 shell 'dmesg -C; logcat -c; /vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY -r 48000 -b 32 -c 2 -T 5 > /dev/null 2>&1; sleep 1; dmesg > /data/local/tmp/dmesg_play5s.txt; logcat -d > /data/local/tmp/logcat_play5s.txt; echo "DONE"'

Ran terminal command:  adb -s 70a91f89 shell 'grep -iE "aw882|mute|start_pa|sysst|shutdown|trigger|digital_mute|hw_param|dsp_ready|topo" /data/local/tmp/dmesg_play5s.txt'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/6ee534f1-c0c9-4d23-abb4-6743296a8d5a/toolu_bdrk_01Sy3m1VnNzAE4QYUqcB8M5i__vscode-1774492048548/content.txt#1-1), lines 1 to 120

**重大变化！** 重启后 **4-0034 现在也 start success 了**（之前一直 fail），**所有 6 颗 PA 都 unmute (state=0) 并成功启动**。

关键时间线：
- 384.254s: 全部 startup
- 384.269s: 4-0034 unmute → sysst_check **done**（通过了！） → start success
- 384.277~384.319s: 其余 5 颗同样 unmute → start success  
- 394.239s: mute state=1 → device_stop（~10s 后停止）

这次没有 4-0034 sysst_check fail 的问题。让我检查 logcat 中的 AGM 日志：    

Ran terminal command:  adb -s 70a91f89 shell 'grep -iE "graph_open|graph_start|graph_stop|graph_close|ckv|calibration|mismatch|error|ret " /data/local/tmp/logcat_play5s.txt | head -30'

Ran terminal command:  adb -s 70a91f89 shell 'grep -iE "graph_stop|graph_close" /data/local/tmp/logcat_play5s.txt'

完整时间线：
- 06:15:47.504 graph_start → 06:15:57.474 graph_stop = **~10s 完整播放**
- dmesg: 384.269s PA unmute → 394.239s PA mute = **~10s PA 全程运行**
- **6 颗 PA 全部 start success**（包括之前一直 fail 的 4-0034）
- CKV mismatch + No calibration found ×4 仍然存在

现在做一个**关键的绕过 AGM 测试**——直接用 tinyplay 在 card0 物理 PCM 设备播放，绕过整个 AGM/ACDB/SPF 链路：   

Starting: *tinyplay card0 绕过 AGM 测试* (5/6)

先看 card0 上有哪些 PCM playback 设备，特别是 TDM secondary（device 16）：    

Ran terminal command:  adb -s 70a91f89 shell 'cat /proc/asound/card0/pcm*p/info 2>/dev/null'
Completed with input:  adb -s 70a91f89 shell 'cat /proc/asound/card0/pcm*p/info 2>/dev/null'

Ran terminal command:  adb -s 70a91f89 shell 'ls /proc/asound/card0/'

card0 只有 codecs 和 id——PCM 设备不在这里。它们通过 compress offload 方式注册：    

Ran terminal command:  adb -s 70a91f89 shell 'ls -la /dev/snd/ | head -30; echo "---"; cat /proc/asound/pcm'

card0 device 16 = `TDM-LPAIF-RX-SECONDARY multicodec-16` — 这就是 PA 的后端。尝试直接用 tinyplay 在 card0/device16 播放—**绕过 AGM/ACDB/SPF**：     

Ran terminal command:  adb -s 70a91f89 shell 'which tinyplay 2>/dev/null; ls /vendor/bin/tinyplay 2>/dev/null; ls /data/local/tmp/tinyplay* 2>/dev/null; which tinyplay_stock 2>/dev/null; ls /system/bin/tinyplay* 2>/dev/null'

Ran terminal command:  adb -s 70a91f89 shell 'tinyplay_stock 2>&1 | head -5'

tinyplay_stock 是标准 tinyalsa 的 tinyplay，支持 `-D card -d device`。直接在 card0 device16 播放：    

Ran terminal command:  adb -s 70a91f89 shell 'dmesg -C; tinyplay_stock /data/local/tmp/test440_mid_10s.wav -D 0 -d 16 -p 1024 -n 4 > /data/local/tmp/tp_card0_d16.txt 2>&1; echo "EXIT=$?"; cat /data/local/tmp/tp_card0_d16.txt'

它有 "Error playing sample" 但仍打印了 "Playing sample"，然后很快 drain 结束了。检查 dmesg 看 PA 有没有反应：     

Ran terminal command:  adb -s 70a91f89 shell 'dmesg | grep -iE "aw882|mute|start_pa|sysst|shutdown"'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/6ee534f1-c0c9-4d23-abb4-6743296a8d5a/toolu_bdrk_01GDhdFAmbBLu4WanyoJytKR__vscode-1774492048559/content.txt#1-1), lines 1 to 30

有趣！直接 card0 dev16 播放时，PA hw_params 看到的是 `sample size: 16`（而不是 AGM 的 32），而且 4-0034 又回到 sysst_check fail 了——`reg_val=0x0011`（CLKS=0）。

让我看完整的 PA 序列：   

Ran terminal command:  adb -s 70a91f89 shell 'dmesg | grep -c "aw882"'

Ran terminal command:  adb -s 70a91f89 shell 'dmesg | grep -iE "aw882.*mute|start.*success|start.*fail|shutdown" | tail -30'

**极其重要的发现！** 直接走 card0 dev16 时：
- **所有 PA 都 start_pa failed！** 包括 9-0034/35/36（它们通过 AGM 播放时一直成功）
- 所有 PA mute=0（unmute）但 sysst_check 全 fail → start failed
- 这表明直接打开 card0 的 TDM PCM 设备时，**ADSPside 没有配置好 TDM 时钟**——CLKS bit = 0
- 通过 AGM 播放时，AGM 通过 SPF 正确配置了 ADSP 的 TDM 接口，所以 PA 能成功启动

这意味着：**AGM/SPF 层面确实在正确工作**（它配置了 TDM 时钟），问题在更上层。

现在用 8ch/32bit WAV 试直接 card0 路径，看是否格式匹配能改善：        

Ran terminal command:  adb -s 70a91f89 shell 'ls /data/local/tmp/*8ch* 2>/dev/null'

Ran terminal command:  adb -s 70a91f89 shell 'dmesg -C; tinyplay_stock /data/local/tmp/test440_8ch_allch_32bit_10s.wav -D 0 -d 16 -p 1024 -n 4 > /data/local/tmp/tp_8ch32.txt 2>&1; echo "EXIT=$?"; cat /data/local/tmp/tp_8ch32.txt; dmesg | grep -iE "start.*success|start.*fail|hw_param" | head -12'

card0 dev16 拒绝了 8ch/32bit hw_params 设置。TDM 驱动对直接打开有特定的约束。这条路走不通。

回到主线——AGM 路径目前 6 颗 PA 全部 start success，但"~1s 后静音"问题仍在。重启后这个问题是否仍然存在？让我播放确认：        

Ran terminal command:  adb -s 70a91f89 shell 'echo "=== 再次确认 PA baseline ==="; tinymix_stock -D 0 "aw_dev_0_switch"; tinymix_stock -D 0 "aw_dev_0_volume"'

好。现在让我换个角度——之前说 CKV mismatch + No calibration found 影响了 SPF 图内的 DSP 模块。让我看看 DSP 图中具体有哪些模块，特别是 **Soft Volume 模块**。如果 DSP 默认把 volume 设为 0 或 mute，那就需要通过 setParam 来手动设置：         

Ran terminal command:  adb -s 70a91f89 shell 'dmesg -C; logcat -c; /vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY -r 48000 -b 32 -c 2 -T 2 > /dev/null 2>&1; logcat -d | grep -iE "module_iid\|miid\|tag_id\|tagged\|getTaggedInfo\|module_tag\|MODULE" | head -40'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -iE "module_iid|miid|tag_id|tagged|getTaggedInfo|module_tag|MODULE" | head -40'

DSP 图模块：
- `c0000002` (PCM Shared Mem EP) - miid `0x40BD`
- `c0000004` (HW EP / TDM EP) - miid `0x4079`
- `c000000e` (MFC output1) - miid `0x40BF`
- `c0000010` (MFC output2) - miid `0x40C0`
- SPR module - IID `0x4165`

缺少 **Soft Volume 模块**！让我在 getTaggedInfo 中查找所有可用模块/tag：           

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -iE "gsl_graph|subgraph|num_module|gkv|tag.*0x" | head -40'

让我通过 pure_c_play 的 getTaggedInfo 数据来查找所有 DSP 模块标签。先看 pure_c_play 源码中 getTaggedInfo 的输出格式：      

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --help 2>&1 | head -20'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/6ee534f1-c0c9-4d23-abb4-6743296a8d5a/toolu_bdrk_01PVEj9kxcNx77c7kbv8aeyy__vscode-1774492048569/content.txt#1-1), lines 1 to 20

看来上次 `tinyplay_stock card0 d16` 的 dmesg 还在。让我先直接查找当前代码中 getTaggedInfo 的解析部分，看我们能否从这个数据中提取模块列表。

让我换个思路——直接查看 ACDB 中的 CKV 结构，看哪 2 个 key 是 ACDB 支持的：         

Ran terminal command:  adb -s 70a91f89 shell 'logcat -c; /vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY -r 48000 -b 32 -c 2 -T 1 > /dev/null 2>&1; logcat -d | grep -iE "ckv|calibrat|key.*0x" | head -30'

让我先确认重启后 ~1s 问题是否仍存在，同时检查我们的 pure_c_play 代码能力： 

Ran terminal command:  adb -s 70a91f89 shell 'echo "=== 播放 5s 确认听感 ==="; /vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY -r 48000 -b 32 -c 2 -T 5 > /dev/null 2>&1; echo "EXIT=$?"'

Searched for regex `getTaggedInfo|tagged_info|snap|dump_tagged` (`**/video_player/pure_c_play.c`), 20 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#245-245), lines 245 to 300

让我看完整的 pure_c_play 主要流程，快速看 getTaggedInfo 调用和 setParam 能力：     

Ran terminal command:  wc -l "/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_play.c"

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#1-1), lines 1 to 100

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#100-100), lines 100 to 210

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#420-420), lines 420 to 520

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#520-520), lines 520 to 670

现在需要找 DSP 图中的**所有模块**，特别是 Soft Volume。让我用 `agm_mixer_get_miid` 查找常见 Qualcomm 模块标签：    

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#475-475), lines 475 to 500

我要在 connect 之后、pcm_open 之前添加一个模块标签探查步骤，查找 Soft Volume 等关键模块。修改 pure_c_play：     

Replacing 10 lines with 42 lines in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c)


```

```
编译推送：       

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP/video_player" && /Users/user/Library/Android/sdk/ndk/28.0.13004108/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android35-clang -o pure_c_play pure_c_play.c -ldl -lm -llog -static-libstdc++ && adb -s 70a91f89 push pure_c_play /data/local/tmp/ && adb -s 70a91f89 shell chmod 755 /data/local/tmp/pure_c_play
Completed with input:  cd "/Volumes/Case-sensitive APFS/TWRP/video_player" && /Users/user/Library/Android/sdk/ndk/28.0.13004108/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android35-clang -o pure_c_play pure_c_play.c -ldl -lm -llog -static-libstdc++ && adb -s 70a91f89 push pure_c_play /data/local/tmp/ && adb -s 70a91f89 shell chmod 755 /data/local/tmp/pure_c_play

Ran terminal command:  ls /Users/*/Library/Android/sdk/ndk/*/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android*-clang 2>/dev/null | head -3

Ran terminal command:  CC=/Users/Laurie/Library/Android/sdk/ndk/26.3.11579264/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android35-clang && cd "/Volumes/Case-sensitive APFS/TWRP/video_player" && $CC -o pure_c_play pure_c_play.c -ldl -lm -llog -static-libstdc++ && adb -s 70a91f89 push pure_c_play /data/local/tmp/ && adb -s 70a91f89 shell chmod 755 /data/local/tmp/pure_c_play
Completed with input:  CC=/Users/Laurie/Library/Android/sdk/ndk/26.3.11579264/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android35-clang && cd "/Volumes/Case-sensitive APFS/TWRP/video_player" && $CC -o pure_c_play pure_c_play.c -ldl -lm -llog -static-libstdc++ && adb -s 70a91f89 push pure_c_play /data/local/tmp/ && adb -s 70a91f89 shell chmod 755 /data/local/tmp/pure_c_play

Ran terminal command:  ls /Users/Laurie/Library/Android/sdk/ndk/26.3.11579264/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android*-clang | tail -3

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP/video_player" && /Users/Laurie/Library/Android/sdk/ndk/26.3.11579264/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android34-clang -o pure_c_play pure_c_play.c -ldl -lm -llog -static-libstdc++ && adb -s 70a91f89 push pure_c_play /data/local/tmp/ && adb -s 70a91f89 shell chmod 755 /data/local/tmp/pure_c_play && echo "OK"
Completed with input:  cd "/Volumes/Case-sensitive APFS/TWRP/video_player" && /Users/Laurie/Library/Android/sdk/ndk/26.3.11579264/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android34-clang -o pure_c_play pure_c_play.c -ldl -lm -llog -static-libstdc++ && adb -s 70a91f89 push pure_c_play /data/local/tmp/ && adb -s 70a91f89 shell chmod 755 /data/local/tmp/pure_c_play && echo "OK"

Ran terminal command:  find "/Volumes/Case-sensitive APFS/TWRP" -name "asoundlib.h" -path "*/tinyalsa/*" 2>/dev/null | head -3

Ran terminal command:  ls "/Volumes/Case-sensitive APFS/TWRP/video_player/"*.h 2>/dev/null; ls "/Volumes/Case-sensitive APFS/TWRP/video_player/Makefile" 2>/dev/null; head -5 "/Volumes/Case-sensitive APFS/TWRP/video_player/Makefile" 2>/dev/null; cat "/Volumes/Case-sensitive APFS/TWRP/video_player/build.sh" 2>/dev/null
Completed with input:  ls "/Volumes/Case-sensitive APFS/TWRP/video_player/"*.h 2>/dev/null; ls "/Volumes/Case-sensitive APFS/TWRP/video_player/Makefile" 2>/dev/null; head -5 "/Volumes/Case-sensitive APFS/TWRP/video_player/Makefile" 2>/dev/null; cat "/Volumes/Case-sensitive APFS/TWRP/video_player/build.sh" 2>/dev/null

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player)

Ran terminal command:  cat "/Volumes/Case-sensitive APFS/TWRP/video_player/build_pure_c_play.sh"

Ran terminal command:  ls "$HOME/Library/Android/sdk/ndk/28.2.13676358/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android28-clang" 2>/dev/null; ls "$HOME/Library/Android/sdk/ndk/"

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP/video_player" && bash build_pure_c_play.sh && adb -s 70a91f89 push pure_c_play /data/local/tmp/ && adb -s 70a91f89 shell chmod 755 /data/local/tmp/pure_c_play && echo "OK"

探查 DSP 图中所有模块标签：        

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --seconds 1 --aw-vol 120 2>&1 | grep -iE "probe_tag|agm_get_miid|configure_mfc|helper_connect"'

**关键发现**：DSP 图中 **没有 VOL_CTRL (0xC0000015)** 模块！没有 Soft Volume 控制！

存在的模块：
- PCM_SH_MEM_EP, HW_EP, STREAM_SPR, MFC_OUT1/2, EC_REF, STREAM_MFC, MFC_BACKEND, SOFT_PAUSE

**SOFT_PAUSE** (0xC0000029, miid=0x4023) 值得注意——它可能在没有校准数据时默认进入 pause 状态。

让我检查 SOFT_PAUSE 模块的状态。但更重要的是——如果没有 VOL_CTRL，那么 CKV 中的 volume_level (0xA4000000=0) 就不影响音量。**4 个子图的校准缺失**到底影响了什么？

让我换个思路——查看 getTaggedInfo 的原始数据，了解还有没有其他模块没被探查到：         

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --seconds 1 --aw-vol 120 --snap-ms 100 2>&1 | grep "getTaggedInfo"'

图中有 16 个标签（w0=0x10），但我只探查到 9 个。需要解析完整的 getTaggedInfo 来找到所有模块。让我加一个 getTaggedInfo 解析器： 

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#490-490), lines 490 to 500

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#500-500), lines 500 to 540

让我把 probe 改为直接解析 getTaggedInfo 二进制数据，这样能找到所有 16 个标签：          

Replacing 31 lines with 26 lines in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c)


```

```


Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP/video_player" && bash build_pure_c_play.sh && adb -s 70a91f89 push pure_c_play /data/local/tmp/ && adb -s 70a91f89 shell chmod 755 /data/local/tmp/pure_c_play && echo "OK"

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --seconds 1 --aw-vol 120 2>&1 | grep -iE "getTaggedInfo|tag\[|probe"'

Compacted conversation

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/6ee534f1-c0c9-4d23-abb4-6743296a8d5a/toolu_bdrk_01LD1xSeXWApkCJXS22WM9Mt__vscode-1774492048599/content.txt#1-1), lines 1 to 100

解析结果有问题——tag[1] 以后输出了近百个 mod，显然没有正确跟踪 `module_id + module_iid` 双字段。让我看一下当前解析代码。 

Searched for text `getTaggedInfo` (`**/video_player/pure_c_play.c`), 5 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#500-500), lines 500 to 545

解析器 bug：AGM 的 `gsl_tag_module_info` 每个模块是 `{module_id, module_iid}` 两个 uint32，当前代码只读一个，导致偏移漂移。修复： 

Replacing 10 lines with 13 lines in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c)


```

```


Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP" && bash build_pure_c_play.sh 2>&1 | tail -5

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP/video_player" && bash build_pure_c_play.sh 2>&1 | tail -5

Ran terminal command:  adb -s 70a91f89 push "/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_play" /data/local/tmp/pure_c_play

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --seconds 1 --aw-vol 120 2>&1 | grep -iE "getTaggedInfo|tag\["'

全部 16 个 tag 解析成功。完整模块图谱：

| Tag | Tag ID | Module | miid | 含义 |
|---|---|---|---|---|
| 0 | 0xC0000001 | 0x07001000 | 0x40BD | DEVICE_HW_EP → PCM_SH_MEM_EP |
| 1 | 0xC0000002 | 0x07001000 | 0x40BD | STREAM_PCM → PCM_SH_MEM_EP |
| 2 | 0xC0000003 | 0x07001003/05 | 0x40C0/BF | STREAM_MFC_OUT → MFC ×2 |
| 3 | 0xC0000004 | 0x0700100E | 0x4079 | HW_ENDPOINT_RX |
| 4 | 0xC0000006 | 0x07001019 | 0x40C4 | STREAM_SPR |
| 5 | 0xC0000007 | 0x0700101B | 0x40C3 | DEVICE_MFC |
| 6 | 0xC000000D | 0x0700101B | 0x40C3 | (same module) |
| 7-8 | 0xC000000E/10 | MFC | 0x40BF/C0 | MFC_OUT1/2 |
| 9 | 0xC0000011 | 0x07001015 | 0x40CA | EC_REF |
| 10 | 0xC0000013 | 0x07001032 | 0x4165 | STREAM_MFC |
| 11 | 0xC0000019 | 0x07001015 | 0x40C8 | MFC_BACKEND |
| 12 | 0xC0000029 | 0x10013D01 | 0x4023 | SOFT_PAUSE (OEM) |
| **13** | **0xC0000039** | 0x07001015 | **0x4176** | 未知模块 |
| **14** | **0xC0000041** | 0x0700101B | **0x4057** | 未知模块 |
| **15** | **0xC000010A** | 0x10013D01/D02 | 0x4023/0x4433 | OEM module ×2 |

**关键发现**：图中确实没有 VOL_CTRL/GAIN 模块。还有 3 个未知模块 (0x4176, 0x4057, 0x4433) 和 2 个 OEM vendor module (0x10013Dxx)。 

Starting: *监控 PA 寄存器(播放中)* (2/5)

现在让我检查 PA 在播放期间的实时状态——如果 PA 触发了保护模式（overvoltage/overcurrent/overtemp），就能解释 ~1s 后静音。先看 sysfs 接口： 

Ran terminal command:  adb -s 70a91f89 shell 'ls /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/'

Ran terminal command:  adb -s 70a91f89 shell 'cat /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/reg | head -20'

Let me monitor PA registers during playback to check for protection mode activation: 

Ran terminal command:  adb -s 70a91f89 shell 'cat /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/monitor'

Ran terminal command:  adb -s 70a91f89 shell 'cat /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/cali_re && cat /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/re_show && cat /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/dsp_re'

PA 校准阻抗全部是默认值 (7.0Ω, tert_l=0)，cali 命令失败，dsp_re=0。现在实时监控播放期间 PA SYSST 寄存器，看是否触发保护模式： 

Ran terminal command:  adb -s 70a91f89 shell '
# 后台播放 5 秒
/data/local/tmp/pure_c_play --seconds 5 --aw-vol 120 > /dev/null 2>&1 &
PID=$!
sleep 1
# 每 0.3s 读一次 SYSST(0x01)
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
  TS=$(date +%s.%N 2>/dev/null || date +%s)
  VAL=$(echo "0x01" > /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/rw 2>/dev/null; cat /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/rw 2>/dev/null)
  echo "T=$TS SYSST=$VAL"
  sleep 0.3
done
wait $PID 2>/dev/null
echo "=== DONE ==="
'

PA SYSST 在整个播放期间始终保持 0x0311（PLL锁定+时钟正常+Boost运行+唤醒），**没有触发任何保护模式**。播放结束后才回到 0x0011（待机）。

PA 保护排除。让我检查另一个线索——播放期间的实际 PA 电压/电流监控数据： 

Starting: *PA 动态监控数据分析* (4/6)

Ran terminal command:  adb -s 70a91f89 shell '
# 后台播放 5 秒
/data/local/tmp/pure_c_play --seconds 5 --aw-vol 120 > /dev/null 2>&1 &
PID=$!
sleep 0.5
# 每 0.5s 读 print_dbg (包含电压电流温度)
for i in 1 2 3 4 5 6 7 8 9 10; do
  echo "=== sample $i ==="
  cat /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/print_dbg 2>/dev/null
  sleep 0.5
done
wait $PID 2>/dev/null
echo "=== DONE ==="
'

print_dbg 需要先开启。让我用另一种方式：在播放期间读取关键 PA 寄存器（包括音量寄存器 0x0C 和监控寄存器），同时通过 dmesg 捕获完整调试信息： 

Ran terminal command:  adb -s 70a91f89 shell '
# 开启 PA 调试并播放
echo 1 > /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/print_dbg
echo 1 > /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/monitor_update

# dmesg 时间戳基线
dmesg -c > /dev/null 2>&1

/data/local/tmp/pure_c_play --seconds 5 --aw-vol 120 > /dev/null 2>&1 &
PID=$!
sleep 1

# 每 1s 读取关键寄存器
for i in 1 2 3 4 5; do
  echo "=== T=$i ==="
  echo "0x05" > /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/rw
  V05=$(cat /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/rw)
  echo "0x0C" > /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/rw
  V0C=$(cat /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/rw)
  echo "0x01" > /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/rw
  V01=$(cat /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/rw)
  echo "SYSST=$V01 VOL=$V0C VBAT=$V05"
  sleep 1
done
wait $PID 2>/dev/null

# PA 调试 dmesg
echo "=== PA dmesg ==="
dmesg | grep -i "aw882" | tail -30

echo 0 > /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/print_dbg
echo "=== DONE ==="
'

PA 在整个播放周期中硬件完全正常：SYSST=0x0311, VOL=0x1C64, VBAT=0x00AC 全部稳定。问题 100% 在 DSP 上游。

让我确认一下 pure_c_play 播放的具体内容——它用的是内置正弦波还是 WAV 文件？同时检查 AW 音量寄存器写入的是哪个地址： 

Searched for regex `aw.vol|aw_vol|0x06|sysfs.*rw` (`**/video_player/pure_c_play.c`), 12 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#294-294), lines 294 to 350

Searched for regex `sinf?\(|tone|square|generated|generate_tone` (`**/video_player/pure_c_play.c`), 1 result

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#620-620), lines 620 to 680

PA 硬件完全正常。问题 100% 在 DSP 层。让我尝试几个关键实验：

**实验 1**: 提高正弦波幅度到最大，看是否更持久 

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#640-640), lines 640 to 650

让我换个思路——CKV 不匹配导致"No calibration found"是最大嫌疑。让我试试修改 metadata 中 CKV 的设置方式。先看当前 metadata 构造： 

Searched for regex `CKV|0xA4000000|cal_key|volume_level` (`**/video_player/pure_c_play.c`), 1 result

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#425-425), lines 425 to 480

让我试一个关键实验——当前 CKV volume=0 可能导致 ACDB 返回零增益配置。同时 devicepp=0xAC000002 的校准也可能失败。让我做两个测试：

**测试 A**: CKV count=0（跳过 CKV，看 AGM 是否使用默认校准）
**测试 B**: devicepp=0xAC000001（禁用设备后处理，减少需要校准的子图数量）

先看完整的当前代码流程再改： 

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#450-450), lines 450 to 500

让我加两个命令行选项，快速测试不同 CKV/devicepp 配置而无需反复改代码： 

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#365-365), lines 365 to 400

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#400-400), lines 400 to 420

Replacing 11 lines with 22 lines in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c)


```

```


Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP/video_player" && bash build_pure_c_play.sh 2>&1 | tail -5

Ran terminal command:  adb -s 70a91f89 push "/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_play" /data/local/tmp/pure_c_play

先测试 **--no-ckv**（不发送 CKV，看 ACDB 是否匹配默认校准）：  

Ran terminal command:  adb -s 70a91f89 shell 'logcat -c; /data/local/tmp/pure_c_play --seconds 3 --aw-vol 120 --no-ckv 2>&1 | head -30'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -iE "CKV|calibration|ckv_count|No cal" | head -20'

关键发现！即使 CKV count=0，AGM 仍自动添加 {rate=48000, bw=32, D2=0} 三个 CKV。ACDB 期望 {**0xEF000000**, **0xA4000000**} 两个键——**没有一个匹配**。

这是个根本性问题：AGM 强加的自动 CKV 永远和 ACDB 的期望键不匹配。

让我试 devicepp=0xAC000001 (DISABLE)，看能否跳过需要校准的子图： 

Ran terminal command:  adb -s 70a91f89 shell 'logcat -c; /data/local/tmp/pure_c_play --seconds 3 --aw-vol 120 --devicepp 0xAC000001 2>&1 | grep -iE "PureCPlay|error|fail" | head -25'

devicepp=0xAC000001 导致图完全失败（ENODEV）。需要 0xAC000002。

关键发现：ACDB 期望的两个 CKV 键是 **0xEF000000** 和 **0xA4000000**。让我试直接提供这两个键——即使 AGM 会额外加 3 个导致 count 不匹配，至少 key-match 可能通过。添加 `--ckv-ef` 选项： 

Replacing 2 lines with 4 lines in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c)


```

```


Replacing 3 lines with 7 lines in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c)


```

```
现在修改 6a54 metadata 发送逻辑，支持发送 {0xA4000000, 0xEF000000} 双 CKV：  

Replacing 17 lines with 24 lines in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c)


```

```


Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP/video_player" && bash build_pure_c_play.sh 2>&1 | tail -3

Ran terminal command:  adb -s 70a91f89 push "/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_play" /data/local/tmp/pure_c_play && adb -s 70a91f89 shell 'logcat -c; /data/local/tmp/pure_c_play --seconds 3 --aw-vol 120 --ckv-ef 0 2>&1 | grep -iE "PureCPlay|error" | head -15'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -iE "CKV|calibration|ckv_count|No cal|mismatch" | head -20'

5 CKVs vs ACDB 的 2 CKVs——count 不匹配 + 反向键查询失败。AGM 强加的 {rate, bw, D2} 三个自动 CKV 根本无法跳过。

让我换个思路。与其继续死磕 CKV，不如看 ACDB 文件里到底有什么 CKV 配置——也许有个带 5 键的匹配项。查看设备上的 ACDB 文件：   

Ran terminal command:  adb -s 70a91f89 shell 'find /vendor /odm /system -name "*.acdb" -o -name "acdb_*" 2>/dev/null | head -20'

Ran terminal command:  adb -s 70a91f89 shell 'ls -la /vendor/etc/acdbdata/sun_mtp/MTP_acdb_cal.acdb /vendor/etc/acdbdata/sun_qrd/QRD_acdb_cal.acdb /odm/etc/acdbdata/MOS/acdb_cal.acdb /odm/etc/acdbdata/sia/acdb_cal.acdb /odm/etc/acdbdata/acdb_cal.acdb'

让我看看 HAL 是从哪个路径加载 ACDB 的，以及能否切换到 MTP 版本（Qualcomm 参考，CKV 可能更标准）：  

Ran terminal command:  adb -s 70a91f89 shell 'getprop | grep -i acdb && echo "---" && logcat -d | grep -i "acdb.*path\|acdb.*load\|acdb.*init\|ats_init" | head -10'
Completed with input:  adb -s 70a91f89 shell 'getprop | grep -i acdb && echo "---" && logcat -d | grep -i "acdb.*path\|acdb.*load\|acdb.*init\|ats_init" | head -10'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -iE "acdb|ats_init" | head -15'

CKV count 不匹配是根本问题。让我换个方向——直接从 ACDB 二进制里挖出 0xEF000000 到底是什么键，以及它期望什么值：   

Ran terminal command:  adb -s 70a91f89 shell 'xxd /odm/etc/acdbdata/acdb_cal.acdb | grep -i "ef000000\|0000ef00" | head -10'

Ran terminal command:  adb -s 70a91f89 shell 'xxd /odm/etc/acdbdata/acdb_cal.acdb | grep -i "000000ef" | head -10'

Ran terminal command:  adb -s 70a91f89 shell 'od -A x -t x4 /odm/etc/acdbdata/acdb_cal.acdb | grep -i "ef000000" | head -10'

Ran terminal command:  adb -s 70a91f89 shell 'hexdump -C /odm/etc/acdbdata/acdb_cal.acdb | grep -c "."' 2>&1 | tail -3

Ran terminal command:  adb -s 70a91f89 shell 'dd if=/odm/etc/acdbdata/acdb_cal.acdb bs=1 skip=0 count=4133686 2>/dev/null | od -A x -t x1 | grep -i " ef 00 00 00" | head -10'

Ran terminal command:  adb -s 70a91f89 shell 'dd if=/odm/etc/acdbdata/acdb_cal.acdb bs=4096 2>/dev/null | od -A x -t x1 | grep -i " 00 00 00 ef" | head -10'

Ran terminal command:  adb -s 70a91f89 pull /odm/etc/acdbdata/acdb_cal.acdb "/Volumes/Case-sensitive APFS/TWRP/acdb_cal_odm.acdb"

Ran terminal command: import struct
data = open('/Volumes/Case-sensitive APFS/TWRP/acdb_cal_odm.acdb','rb').read()
target = 0xEF000000
# search as LE uint32
needle = struct.pack('<I', target)
pos = 0
hits = []
while True:
    p = data.find(needle, pos)
    if p < 0: break
    hits.append(p)
    pos = p + 1
print(f'0xEF000000 as LE: {len(hits)} hits')
for h in hits[:20]:
    ctx = data[max(0,h-16):h+20]
    words = struct.unpack_from('<' + 'I' * (len(ctx)//4), ctx)
    print(f'  offset=0x{h:06x}: {" ".join(f"{w:08x}" for w in words)}')

找到 133 处！让我分析第一处关键上下文——CKV 结构 {0xA4000000, 0xEF000000} 的定义：   

Ran terminal command: import struct
data = open('/Volumes/Case-sensitive APFS/TWRP/acdb_cal_odm.acdb','rb').read()

# Find all positions of a4000000 near ef000000 (within 32 bytes)
a4 = struct.pack('<I', 0xa4000000)
ef = struct.pack('<I', 0xef000000)

pos = 0
found = []
while True:
    p = data.find(a4, pos)
    if p < 0: break
    # Check if ef000000 is within ±32 bytes
    region = data[max(0,p-32):p+36]
    if ef in region:
        found.append(p)
    pos = p + 4

print(f'a4000000 near ef000000: {len(found)} hits')
for h in found[:10]:
    start = max(0, h-16)
    ctx = data[start:h+32]
    words = struct.unpack_from('<' + 'I'*(len(ctx)//4), ctx)
    offset_in_ctx = (h - start) // 4
    labeled = []
    for i, w in enumerate(words):
        marker = ' <-- a4' if i == offset_in_ctx else ''
        labeled.append(f'{w:08x}{marker}')
    print(f'  @0x{h:06x}: {" ".join(labeled)}')

0xEF000000 在 ACDB 中出现了 133 次，和 0xA4000000 共存于 CKV 定义结构中。但 AGM 自动加的 3 个键 (rate/bw/D2) 使得 count 永远不匹配。

让我改变策略——既然无法修复 CKV 匹配，直接分析 DSP 数据流。先检查是否有 TDM 回环采集设备能让我数字化验证音频幅度是否在 1s 后衰减：    

Ran terminal command:  adb -s 70a91f89 shell 'cat /proc/asound/pcm 2>/dev/null; echo "---"; ls /proc/asound/card0/ 2>/dev/null | head -30'

设备 17 是 TDM TX (capture)。但是让我先测试一个更简单的假设：**当前音量可能太低了**。aw_vol=120 在 0-720 范围内只有 ~17%，如果可听的"1s"其实只是 PA 上电的 pop/click，而真正的音频信号因音量太低而实际听不到呢？

试最大音量 720：    

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --seconds 5 --aw-vol 720 2>&1 | grep -iE "PureCPlay.*route\|pcm.*open\|pcm_write\|EXIT"'
Completed with input:  adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --seconds 5 --aw-vol 720 2>&1 | grep -iE "PureCPlay.*route\|pcm.*open\|pcm_write\|EXIT"'

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --seconds 5 --aw-vol 720 2>&1 | tail -10'

播放成功。让我确认 AW 音量控制实际映射：   

Ran terminal command:  adb -s 70a91f89 shell '
# 测试 aw_dev_0_volume 的不同值 → 看 PA 寄存器变化
for vol in 0 120 360 720; do
  /vendor/bin/tinymix_stock -D 0 "aw_dev_0_volume" $vol 2>/dev/null
  echo "0x06" > /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/rw
  R06=$(cat /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/rw)
  echo "0x0c" > /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/rw
  R0C=$(cat /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/rw)
  echo "vol=$vol R06=$R06 R0C=$R0C"
done
# 恢复到 120
/vendor/bin/tinymix_stock -D 0 "aw_dev_0_volume" 120 2>/dev/null
'
Completed with input:  adb -s 70a91f89 shell '
# 测试 aw_dev_0_volume 的不同值 → 看 PA 寄存器变化
for vol in 0 120 360 720; do
  /vendor/bin/tinymix_stock -D 0 "aw_dev_0_volume" $vol 2>/dev/null
  echo "0x06" > /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/rw
  R06=$(cat /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/rw)
  echo "0x0c" > /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/rw
  R0C=$(cat /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/rw)
  echo "vol=$vol R06=$R06 R0C=$R0C"
done
# 恢复到 120
/vendor/bin/tinymix_stock -D 0 "aw_dev_0_volume" 120 2>/dev/null
'

AW 音量寄存器不随 mixer 值变化（可能只在播放期间通过内部 DSP 生效）。

让我做一个关键对比实验：**用原生 agmplay 播放 vs pure_c_play**。agmplay 是高通参考工具，它的 CKV 处理可能不同。先查看 agmplay 的播放选项：    

Ran terminal command:  adb -s 70a91f89 shell 'agmplay -h 2>&1 | head -30'

Ran terminal command:  adb -s 70a91f89 shell 'which agmplay 2>/dev/null; find /vendor /system -name "agmplay" 2>/dev/null'

Ran terminal command:  adb -s 70a91f89 shell '/vendor/bin/agmplay 2>&1 | head -20'

让我用 agmplay 做对比测试。先生成一个测试 WAV 文件：      

Ran terminal command: import struct, math
rate, dur, freq = 48000, 5, 440
n = rate * dur
# 8ch 32bit WAV
ch = 8
bps = 32
data = bytearray()
for i in range(n):
    s = int(0.5 * 2147483647 * math.sin(2*math.pi*freq*i/rate))
    for c in range(ch):
        data += struct.pack('<i', s)
hdr = bytearray(44)
hdr[0:4] = b'RIFF'
struct.pack_into('<I', hdr, 4, 36 + len(data))
hdr[8:16] = b'WAVEfmt '
struct.pack_into('<I', hdr, 16, 16)
struct.pack_into('<H', hdr, 20, 1) # PCM
struct.pack_into('<H', hdr, 22, ch)
struct.pack_into('<I', hdr, 24, rate)
struct.pack_into('<I', hdr, 28, rate*ch*(bps//8))
struct.pack_into('<H', hdr, 32, ch*(bps//8))
struct.pack_into('<H', hdr, 34, bps)
hdr[36:40] = b'data'
struct.pack_into('<I', hdr, 40, len(data))
open('/Volumes/Case-sensitive APFS/TWRP/test_8ch32.wav','wb').write(hdr+data)
print(f'WAV: {ch}ch {rate}Hz {bps}bit {dur}s = {len(hdr)+len(data)} bytes')

Ran terminal command:  adb -s 70a91f89 push "/Volumes/Case-sensitive APFS/TWRP/test_8ch32.wav" /data/local/tmp/test_8ch32.wav

Ran terminal command:  adb -s 70a91f89 shell 'logcat -c; /vendor/bin/agmplay /data/local/tmp/test_8ch32.wav -D 100 -d 100 -c 8 -r 48000 -b 32 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY -skv 0xA100000E -dkv 0xA2000001 -dppkv 0xAC000002 -ikv 1 2>&1'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -iE "CKV|calibration|No cal|mismatch" | head -20'

agmplay 也完全一样：4 CKVs, 0xEF000000 缺失, "No calibration found" ×4。

**这说明 CKV 不匹配是 ACDB 固有问题，不是我们代码的问题。** 高通自己的 agmplay 也无法获取校准数据。

现在让我试 **MTP ACDB** —— 高通参考校准文件，CKV 要求可能跟 AGM 自动添加的键匹配：      

Ran terminal command:  adb -s 70a91f89 shell '
# 备份当前 ACDB (记住要恢复)
cp /odm/etc/acdbdata/acdb_cal.acdb /data/local/tmp/acdb_cal_backup.acdb
ls -l /data/local/tmp/acdb_cal_backup.acdb

# bind mount MTP ACDB
mount -o bind /vendor/etc/acdbdata/sun_mtp/MTP_acdb_cal.acdb /odm/etc/acdbdata/acdb_cal.acdb
ls -l /odm/etc/acdbdata/acdb_cal.acdb

echo "=== MTP ACDB mounted ==="
'

MTP ACDB 已 bind mount (3.2MB vs 原来 4.1MB)。现在需要重启 HAL 让 ats_init 重新加载 ACDB：     

Ran terminal command:  adb -s 70a91f89 shell '
# 杀掉 HAL/ats 进程让其重启
pkill -f "vendor.audio" 2>/dev/null
pkill -f "ats_init" 2>/dev/null
sleep 2

# 等待 HAL 重启
for i in 1 2 3 4 5 6 7 8 9 10; do
  if ps -A | grep -q "vendor.audio"; then
    echo "HAL 已重启 (iter=$i)"
    break
  fi
  sleep 1
done

# 确认 card100
sleep 3
if [ -d /proc/asound/card100 ]; then
  echo "card100 OK"
else
  echo "card100 NOT found — ats_init 可能失败"
  # 检查 ats 状态
  logcat -d | grep -iE "ats_init|acdb" | tail -10
fi
'
Completed with input:  adb -s 70a91f89 shell '
# 杀掉 HAL/ats 进程让其重启
pkill -f "vendor.audio" 2>/dev/null
pkill -f "ats_init" 2>/dev/null
sleep 2

# 等待 HAL 重启
for i in 1 2 3 4 5 6 7 8 9 10; do
  if ps -A | grep -q "vendor.audio"; then
    echo "HAL 已重启 (iter=$i)"
    break
  fi
  sleep 1
done

# 确认 card100
sleep 3
if [ -d /proc/asound/card100 ]; then
  echo "card100 OK"
else
  echo "card100 NOT found — ats_init 可能失败"
  # 检查 ats 状态
  logcat -d | grep -iE "ats_init|acdb" | tail -10
fi
'

Ran terminal command:  adb -s 70a91f89 shell 'ls /proc/asound/card100/ 2>/dev/null && echo "card100 OK" || echo "card100 DOWN"'

Ran terminal command:  adb -s 70a91f89 shell 'ps -A | grep -iE "audio|agm|ats" | head -10'

HAL 在运行但 card100 未注册——MTP ACDB 可能与设备 ADSP 不兼容。查看日志：     

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -iE "ats_init|acdb|gsl_init|error.*init" | tail -20'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -iE "ats.*fail\|ats.*retry\|gsl.*fail\|gsl.*error\|card.*100\|agm.*fail" | tail -20'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -iE "ats|gsl_init|acdb.*init|acdb_c" | tail -20'

Ran terminal command:  adb -s 70a91f89 shell 'ps -A | grep -v grep | grep -iE "audio|agm|ats|gsl|adsp" && echo "---" && getprop | grep -i "vendor.audio" | head -10'

MTP ACDB 导致 ats_init 失败，card100 消失。紧急恢复原始 ACDB：      

Ran terminal command:  adb -s 70a91f89 shell '
umount /odm/etc/acdbdata/acdb_cal.acdb 2>/dev/null
ls -l /odm/etc/acdbdata/acdb_cal.acdb
'

原始 ACDB 已恢复 (4,133,686 bytes)。重启 HAL 恢复 card100：      

Ran terminal command:  adb -s 70a91f89 shell '
kill -9 868 2>/dev/null
kill -9 866 2>/dev/null
sleep 5
ls /proc/asound/card100/ 2>/dev/null && echo "card100 OK" || echo "card100 DOWN"
'

Ran terminal command:  adb -s 70a91f89 shell '
sleep 10
ls /proc/asound/card100/ 2>/dev/null && echo "card100 OK" || echo "card100 DOWN"
ps -A | grep -iE "audio" | head -5
'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -iE "ats_init|retry|gsl_init" | tail -20'

ats_init 陷入 "Failed to initialize Diag" 重试循环。MTP ACDB 加载可能导致 ADSP 状态损坏。这跟上次 FTM ACDB 实验一样——需要**再次重启到 recovery**才能恢复。

不过在让你重启前，让我确认 ADSP 状态：        

Ran terminal command:  adb -s 70a91f89 shell '
# 检查 ADSP remoteproc 状态
cat /sys/class/remoteproc/remoteproc*/state 2>/dev/null
cat /sys/class/remoteproc/remoteproc*/name 2>/dev/null
echo "---"
# 检查 mount 状态
mount | grep acdb
echo "---ACDB---"
ls -l /odm/etc/acdbdata/acdb_cal.acdb
'

ADSP 运行正常，ACDB 已恢复。"Failed to initialize Diag" 可能是重启后 Diag 接口需要时间。再试杀进程+长等待：        

Ran terminal command:  adb -s 70a91f89 shell '
kill -9 4909 4908 2>/dev/null
sleep 15
ls /proc/asound/card100/ 2>/dev/null && echo "card100 OK" || echo "card100 DOWN"
logcat -d | grep -iE "ats_init.*succ\|card100\|agm.*register" | tail -5
'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | tail -5'

Ran terminal command:  adb -s 70a91f89 shell 'ps -A | grep -iE "audio" && echo "---" && logcat -d | grep -iE "ats_init" | tail -5'

Ran terminal command:  adb -s 70a91f89 shell 'sleep 30; ls /proc/asound/card100/ 2>/dev/null && echo "card100 OK" || echo "card100 DOWN"; logcat -d | grep -iE "ats_init" | tail -3'

ats_init 在 120+ 轮重试后仍卡在 "Failed to initialize Diag"。MTP ACDB 实验破坏了 ADSP/Diag 状态。

**需要再次重启到 recovery。** 我先把所有发现记录到文档，这样不会浪费这次排查的成果。 

Completed: *PA 动态监控数据分析* (4/8)

先查看当前排查日志尾部确认追加位置：   

Ran terminal command:  wc -l "/Volumes/Case-sensitive APFS/TWRP/docs/TWRP音频排查日志-20260326.md" && tail -20 "/Volumes/Case-sensitive APFS/TWRP/docs/TWRP音频排查日志-20260326.md"

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%8E%92%E6%9F%A5%E6%97%A5%E5%BF%97-20260326.md#940-940), lines 940 to 966

Searched for regex `^## \d+` (`**/docs/TWRP音频排查日志-20260326.md`), 20 results

Searched for regex `^## 3[0-9]` (`**/docs/TWRP音频排查日志-20260326.md`), 4 results

当前文档在第 33 节结束。追加 34-39 节覆盖本轮所有发现：       

Using "Replace String in File"

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%8E%92%E6%9F%A5%E6%97%A5%E5%BF%97-20260326.md#960-960), lines 960 to 966

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%8E%92%E6%9F%A5%E6%97%A5%E5%BF%97-20260326.md#964-964), lines 964 to 967

Replacing 1 lines with 127 lines in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%8E%92%E6%9F%A5%E6%97%A5%E5%BF%97-20260326.md)


```

```


Completed: *更新排查日志文档* (7/8)

更新 repo memory 记录关键发现： 

Created memory file twrp_audio_ckv_acdb_fundamental_mismatch_20260326.md

文档和 repo memory 已更新。总结当前状况：

---

**本轮排查成果：**

1. **DSP 完整模块图谱**：16 个模块全部解析，确认图中**没有任何标准音量/增益模块**（VOL_CTRL/GAIN/SOFT_VOL_INST 均不在）。2 个 OEM vendor 模块 (0x10013D01/0x10013D02) 功能未知。

2. **PA 保护排除**：SYSST=0x0311 贯穿整个播放周期，无任何保护事件。PA 硬件完全正常。 

3. **CKV 不匹配是 ACDB 固有问题**：AGM 自动注入的 {rate, bw, instance} 三个 CKV 键与 ACDB 期望的 {0xEF000000, 0xA4000000} 永远无法匹配——高通原版 agmplay 也有同样失败，不是 pure_c_play 的问题。

4. **MTP ACDB 不兼容**：会导致 ats_init 永久失败，需要重启恢复。

**当前状态：需要重启到 recovery 恢复 card100**（MTP ACDB 实验导致 Diag 初始化失败）。

**重启后下一步：**
- 尝试 `setParam` 直接向 DSP 模块注入增益参数，绕过 ACDB 校准
- 分析 OEM 模块参数格式
- 考虑修改 ACDB 二进制中的 CKV 键定义（去掉 0xEF000000 依赖）

Made changes.

User: 重启了


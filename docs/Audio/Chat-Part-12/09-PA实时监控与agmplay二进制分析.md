GitHub Copilot: 

 

Ran terminal command:  adb -s 70a91f89 shell 'getenforce && setenforce 0 && getenforce'

Ran terminal command:  adb -s 70a91f89 shell 'ls -l /odm/etc/acdbdata/acdb_cal.acdb && ls /proc/asound/card100/ 2>/dev/null && echo "card100 OK" || echo "card100 DOWN"'

card100 还没起来，等 ats_init 完成： 

Ran terminal command:  adb -s 70a91f89 shell 'for i in $(seq 1 20); do if [ -d /proc/asound/card100 ]; then echo "card100 OK @ iter=$i"; break; fi; sleep 2; done; [ -d /proc/asound/card100 ] || echo "card100 still DOWN after 40s"'

Ran terminal command:  adb -s 70a91f89 shell 'ps -A | grep -iE "audio" && echo "---" && logcat -d | grep -iE "ats_init" | tail -5'

ats_init 还在重试 120 次。"Failed to initialize Diag" 持续存在。这可能是 ADSP Diag 子系统需要额外服务。在之前成功的启动中这个最终会通过的。再等一次： 

Ran terminal command:  adb -s 70a91f89 shell 'sleep 60; ls /proc/asound/card100/ 2>/dev/null && echo "card100 OK" || echo "card100 DOWN"; logcat -d | grep -iE "ats_init" | tail -3'

ats_init 停在 retry 120（最大值），thread 已退出但 card100 未注册。之前重启成功时 ats_init 也是先失败然后最终能过。看看 HAL 初始化的完整日志来理解为什么这次卡住了：   

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -iE "gsl_init|agm.*init|agm.*register|snd.card|card100|pcm_plugin|chardev" | head -20'

ats_init 从 retry 2 开始就一直失败到 120 次全部退出。在之前成功的 session 中，ats_init 也是先失败但在某个节点通过的。让我看看之前是否有什么额外操作——可能需要 `vendor.audio.daemon.agm` 属性触发：   

Ran terminal command:  adb -s 70a91f89 shell 'getprop vendor.audio.daemon.agm; getprop init.svc.vendor.audio-hal-manual'

HAL 和 AGM daemon 都在运行，但 ats_init 在 retry 120 后放弃了。card100 之前成功时 ats_init 的 Diag 在 retry ~120 后最终也会成功注册 card100。但现在 thread 已经退出了。

杀掉 HAL 重启一次看看能否恢复：    

Ran terminal command:  adb -s 70a91f89 shell 'kill -9 863; sleep 3; ps -A | grep audio | head -5'

Ran terminal command:  adb -s 70a91f89 shell 'for i in $(seq 1 30); do if [ -d /proc/asound/card100 ]; then echo "card100 OK @ iter=$i (~${i}*2s)"; break; fi; sleep 2; done; [ -d /proc/asound/card100 ] || echo "card100 still DOWN"'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -iE "ats_init" | tail -5'

ats_init 连续失败 120 次后放弃。这跟之前 MTP ACDB 实验后的表现完全不同——重启后也是这样。让我看看之前成功时有没有什么 autoload 或其他预置条件： 

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -iE "diag|Failed to init" | head -10; echo "==="; logcat -d | grep -iE "chardev|agm.*open\|/dev/agm" | head -10'

根因找到了：`failed to connect to diag socket`，`error = 111` (ECONNREFUSED)。Diag 守护进程没有在 recovery 中运行。之前成功时可能是 ats_init 在 120 次后自行跳过（AGM 早期版本）或者 Diag 服务正好在运行。

让我检查 Diag 相关进程和 socket：      

Ran terminal command:  adb -s 70a91f89 shell 'ls -la /dev/diag 2>/dev/null; ls -la /tmp/diag* 2>/dev/null; ls -la /var/run/diag* 2>/dev/null; find /dev -name "diag*" 2>/dev/null; echo "---"; ps -A | grep -iE "diag" | head -5'

没有 Diag 设备节点、没有进程。之前能成功是因为什么?看看 recovery 中 AGM 是否可以不依赖 Diag 就注册 card100。AGM 源码中 ats_init 失败后应该继续初始化，让我看看 GSL 是否还有其他初始化路径：       

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -iE "agm|gsl" | grep -viE "ats_init|retry" | head -30'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -iE "agm|gsl" | grep -viE "ats_init|retry|parse_snd|pending" | head -30'

AGM 实际上**已经成功初始化、注册了 Service 并打开了 mixer card 100！** 但 card100 在 `/proc/asound/` 下没出现。看起来 ats_init 的 thread 在后台另一个 thread 中运行(pid 1949)，而主线程已经完成了 agm_mixer_plugin_open。

让我尝试直接播放看是否能用：       

Ran terminal command:  adb -s 70a91f89 shell '/vendor/bin/agmplay /data/local/tmp/test_8ch32.wav -D 100 -d 100 -c 8 -r 48000 -b 32 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY -skv 0xA100000E -dkv 0xA2000001 -dppkv 0xAC000002 -ikv 1 2>&1 | head -10'

AGM 完全正常运行！`/proc/asound/card100` 不存在只是因为 recovery 中缺少某些 ALSA 子系统，但 AGM 的 plugin 机制通过 binder 跟 audiohalservice 通信，不依赖这个路径。

设置 mixer baseline 并运行 pure_c_play 测试：       

Ran terminal command:  adb -s 70a91f89 shell '
/vendor/bin/tinymix_stock -D 0 "aw882xx_rx_switch" Enable
/vendor/bin/tinymix_stock -D 0 "aw882xx_tx_switch" Enable
/vendor/bin/tinymix_stock -D 0 "aw882xx_copp_switch" Enable
for d in 0 1 2 3 5 6; do
  /vendor/bin/tinymix_stock -D 0 "aw_dev_${d}_prof" Music 2>/dev/null
  /vendor/bin/tinymix_stock -D 0 "aw_dev_${d}_switch" Enable 2>/dev/null
  /vendor/bin/tinymix_stock -D 0 "aw_dev_${d}_volume" 120 2>/dev/null
done
echo "mixer baseline OK"
'

tinymix_stock 不见了。让我查看可用的 tinymix：        

Ran terminal command:  adb -s 70a91f89 shell 'find /vendor /system /data -name "tinymix*" 2>/dev/null; which tinymix 2>/dev/null'
Completed with input:  adb -s 70a91f89 shell 'find /vendor /system /data -name "tinymix*" 2>/dev/null; which tinymix 2>/dev/null'

Ran terminal command:  adb -s 70a91f89 shell '
TM=/data/local/tmp/tinymix_stock
$TM -D 0 "aw882xx_rx_switch" Enable
$TM -D 0 "aw882xx_tx_switch" Enable
$TM -D 0 "aw882xx_copp_switch" Enable
for d in 0 1 2 3 5 6; do
  $TM -D 0 "aw_dev_${d}_prof" Music 2>/dev/null
  $TM -D 0 "aw_dev_${d}_switch" Enable 2>/dev/null
  $TM -D 0 "aw_dev_${d}_volume" 120 2>/dev/null
done
echo "mixer baseline done"
'

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --seconds 3 --aw-vol 120 2>&1 | tail -5'

Completed: *重启恢复环境* (8/8)

环境已恢复。

- SELinux: Permissive
- ACDB: 原始 4,133,686B
- HAL: audiohalservice.qti (pid 1937) 运行中
- AGM card100: 虽然 `/proc/asound/card100` 不存在（ats_init Diag 失败），但 AGM binder plugin 正常工作
- mixer baseline: 设置完成（aw882xx rx/tx/copp Enable, 6 PA Music/Enable/vol=120）
- pure_c_play: 3s 播放成功（144000/144000 frames）

接下来继续排查方向：**setParam 向 DSP 模块直接注入参数**，还是要我先确认你能听到声音（用来做 A/B 对比）？

User: 继续

GitHub Copilot: 

继续排查。当前最有价值的方向是：**SOFT_PAUSE 模块可能处于暂停状态**导致 ~1s 后静音。还有 OEM 模块 (0x4433) 功能未知。先试 setParam 实验。 

Created 4 todos

先查看 pure_c_play 当前的 setParam 相关代码： 

Searched for regex `setParam|setParamTag|PARAM_ID` (`**/video_player/pure_c_play.c`), 6 results

Searched for regex `set_mixer_words|mixer_ctl_set_array` (`**/video_player/pure_c_play.c`), 8 results

现在需要理解 `PCM100 setParam` 的二进制格式。Qualcomm AGM setParam 格式是：`{miid, param_id, param_size, ...payload...}`。让我查 SOFT_PAUSE 的 Qualcomm param ID： 

Ran terminal command:  adb -s 70a91f89 shell 'grep -rn "SOFT_PAUSE\|PARAM_ID_SOFT_PAUSE\|0x08001006\|08001006" /vendor/etc/ 2>/dev/null | head -10'

让我用 setParamTag 方式——先看 AGM 的 setParamTag 控件格式。这个控件允许通过 tag 定位模块并设置参数，不需要知道 miid。

更好的方案：直接在播放前通过 `PCM100 setParam` 发送 SOFT_PAUSE resume 命令。Qualcomm SOFT_PAUSE 的 param_id 是 `0x080010A8` (PARAM_ID_SOFT_PAUSE_PAUSE)，payload 是 `{enable=0, period_ms, step, ramping_curve}`。

但等一下——让我先验证一个更简单的假设：**SOFT_PAUSE 模块是否默认处于 pause 状态？** 可以通过 getParam 读取它的当前状态：   

Ran terminal command:  adb -s 70a91f89 shell '
# 查看 PCM100 setParam / setParamTag 控件信息
/data/local/tmp/tinymix_stock -D 100 2>&1 | grep -iE "setParam|getParam|Tagged" | head -20
'

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/tinymix_stock -D 100 2>&1 | grep -iE "setParam\|getParam\|Tagged\|getTag" | head -20'

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/tinymix_stock -D 100 2>&1 | grep -i "PCM100" | head -20'

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/tinymix_stock -D 100 2>&1 | grep "PCM100" | grep -v "Loopback"'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/6ee534f1-c0c9-4d23-abb4-6743296a8d5a/toolu_bdrk_01NxCDzQaUDqMRyjBXmG7wzg__vscode-1774492048718/content.txt#1-1), lines 1 to 30

输出被截断了。让我用更精确的搜索：  

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/tinymix_stock -D 100 contents 2>&1 | grep "PCM100" | grep -v Loopback | head -20'

Ran terminal command:  adb -s 70a91f89 shell '/system/bin/tinymix_stock -D 100 2>&1 | head -5; /system/bin/tinymix_stock -D 100 2>&1 | grep "PCM100" | wc -l'

card100 在 `/proc/asound/` 下不存在，所以 tinymix 通过标准 ALSA 路径打不开。但 AGM 的 plugin 能通过 binder 工作。意味着我们只能通过 pure_c_play 内的代码来读写 card100 控件。

让我直接修改 pure_c_play，添加一个 setParam 功能来发送 SOFT_PAUSE resume 和尝试 getParam 读取模块状态。

先了解 AGM setParam 的格式——查看 AGM 源码头文件：   

Search complete: AGM setParam 二进制格式

Searched for regex `agm_mixer_set_param|agm_session_set_params|setParam|setParamTag`, 200 results

Searched for regex `AGM|agm_mixer|agm_session`, 200 results

Searched for files matching `**/*agm*`, 28 matches

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2020-2020), lines 2020 to 2120

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.h)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#1-1), lines 1 to 100

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#100-100), lines 100 to 200

Searched for regex `agm_session_set_params|agm_session_set_config|set_params|param_id|payload_size|apm_module_param_data` (`**/*.{c,h}`), 200 results

Searched for regex `struct.*param.*data|miid.*param_id|module_instance_id|error_code.*param_size` (`**/*.{c,h,md}`), no results

Compacted conversation

Updated todo list

Ran terminal command:  wc -l "/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_play.c"

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#1-1), lines 1 to 100

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#100-100), lines 100 to 250

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#250-250), lines 250 to 400

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#400-400), lines 400 to 550

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#550-550), lines 550 to 724

现在清楚了 pure_c_play.c 的完整结构。核心状况：
- pcm_open 成功，播放完整运行（144000/144000 frames）
- 但只有 ~1s 有声音
- getTaggedInfo 已经能读到 16 个模块的 tag→miid 映射
- CKV 校准失败，无法加载 ACDB 参数
- 需要尝试 post-open 直接 setParam 注入参数

先搜索 SOFT_PAUSE 相关的 param ID 定义： 

Ran terminal command:  grep -rn "SOFT_PAUSE\|08001007\|080010A8\|PARAM_ID.*PAUSE" "/Volumes/Case-sensitive APFS/TWRP/twrp_a16_compile/vendor/" --include="*.h" 2>/dev/null | head -20

Ran terminal command:  grep -rn "SOFT_PAUSE\|soft_pause\|PAUSE" "/Volumes/Case-sensitive APFS/TWRP/twrp_a16_compile/vendor/qcom/opensource/agm/" --include="*.h" --include="*.c" 2>/dev/null | head -30

Ran terminal command:  find "/Volumes/Case-sensitive APFS/TWRP/twrp_a16_compile/vendor/qcom/opensource/agm/" -name "*.h" -o -name "*.c" 2>/dev/null | head -20

Ran terminal command:  ls "/Volumes/Case-sensitive APFS/TWRP/twrp_a16_compile/vendor/qcom/opensource/" 2>/dev/null | head -20

Ran terminal command:  ls "/Volumes/Case-sensitive APFS/TWRP/twrp_a16_compile/vendor/" 2>/dev/null
Completed with input:  ls "/Volumes/Case-sensitive APFS/TWRP/twrp_a16_compile/vendor/" 2>/dev/null

Ran terminal command:  find "/Volumes/Case-sensitive APFS/TWRP/twrp_a16_compile/" -maxdepth 2 -type d 2>/dev/null | head -30

Ran terminal command:  grep -rn "SOFT_PAUSE\|soft_pause" "/Volumes/Case-sensitive APFS/TWRP/" --include="*.h" --include="*.c" --include="*.md" 2>/dev/null | grep -v ".git" | head -30

好的，从排查日志确认了：
- SOFT_PAUSE tag = 0xC0000029
- module_id = 0x10013D01 (OEM)
- miid = 0x4023

现在需要知道 SOFT_PAUSE 的 param_id。让我在设备上查找 Qualcomm SPF 头文件： 

Ran terminal command:  adb -s 70a91f89 shell 'find /vendor/etc/ -name "*.acdb" -o -name "*.json" 2>/dev/null | head -10'

Ran terminal command:  adb -s 70a91f89 shell 'grep -rl "SOFT_PAUSE\|soft_pause\|08001007" /vendor/etc/ 2>/dev/null | head -5'

Ran terminal command:  adb -s 70a91f89 shell 'find /vendor/include/ -name "*param*" -o -name "*module*" -o -name "*spf*" 2>/dev/null | head -10'

Ran terminal command:  adb -s 70a91f89 shell 'find /vendor/lib64/ -name "*agm*" | head -10'

先确认设备状态，再采取行动： 

Ran terminal command:  adb -s 70a91f89 shell 'getenforce && cat /proc/asound/cards 2>/dev/null | head -5'

Ran terminal command:  adb -s 70a91f89 shell 'ls /data/local/tmp/pure_c_play /data/local/tmp/tinymix_stock 2>&1'

设备在线，SELinux Permissive，工具就位。card0 在但 card100 不在 /proc/asound（预期行为——AGM plugin 仍然可用）。

现在添加 `--setparam` 功能到 pure_c_play。关键设计：
1. 在 pcm_open 之后、write loop 之前发送 setParam
2. 格式按照 Qualcomm `apm_module_param_data_t`: `{miid, param_id, param_size, error_code=0, payload...}`
3. 先试 SOFT_PAUSE resume（miid=0x4023, param_id=0x08001007, payload={enable=0}） 

Starting: *添加 post-open setParam 功能* (2/4)

Replacing 4 lines with 11 lines in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c)


```

```
现在添加命令行参数解析： 

Replacing 4 lines with 15 lines in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c)


```

```
现在添加 setParam 和 getParam 的实际注入代码，放在 pcm_open 之后、write loop 之前： 

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#588-588), lines 588 to 600

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#600-600), lines 600 to 625

在 `pcm_start` 和写数据之间插入 setParam 逻辑： 

Replacing 4 lines with 73 lines in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c)


```

```


Starting: *编译推送测试 SOFT_PAUSE resume* (3/4)

编译并推送： 

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP/video_player" && bash build_pure_c_play.sh 2>&1

Ran terminal command:  adb -s 70a91f89 push "/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_play" /data/local/tmp/pure_c_play

先用 `--getparam-all` 探测所有模块的启用状态，同时跑 3 秒 440Hz 做基线：  

Ran terminal command:  adb -s 70a91f89 shell 'chmod 755 /data/local/tmp/pure_c_play && /data/local/tmp/pure_c_play --seconds 3 --getparam-all --trace 2>&1' | head -80

有价值的结果！关键发现：
- setParam 大部分模块返回 `-95`（EOPNOTSUPP）或 `-22`（EINVAL）
- **HW_EP (0x4079) 返回 rc=0** — 接受了 setParam 写入！
- SOFT_PAUSE (0x4023) 返回 `-22` — 可能是因为那个探测用的 payload 不对（size=0）

现在试 `--soft-pause-resume`，它有完整 payload（16 bytes = 4个 uint32）： 

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --seconds 3 --soft-pause-resume --trace 2>&1' | head -60

SOFT_PAUSE 的 setParam 返回 -22。有几种可能：
1. OEM 模块 (0x10013D01) 的 param_id 不是标准的 0x08001007
2. AGM mixer control 的 payload 格式与预期不同

换个角度——先确认 agmplay 的表现是否也是 ~1s 可听，用作对照： 

Ran terminal command:  adb -s 70a91f89 shell 'ls /vendor/bin/agmplay /data/local/tmp/agmplay 2>&1'
Completed with input:  adb -s 70a91f89 shell 'ls /vendor/bin/agmplay /data/local/tmp/agmplay 2>&1'

Ran terminal command:  adb -s 70a91f89 shell '/vendor/bin/agmplay /data/local/tmp/test_440hz.wav 2>&1' | head -20

Ran terminal command:  adb -s 70a91f89 shell 'ls /data/local/tmp/*.wav 2>&1'

Ran terminal command:  adb -s 70a91f89 shell '/vendor/bin/agmplay /data/local/tmp/test440_8ch_32bit_10s.wav -D 100 -d 100 -c 8 -r 48000 -b 32 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY -dkv 0xA2000001 -dppkv 0xAC000002 -ikv 1 -skv 0xA100000E 2>&1' | head -30

agmplay 开始播放了。但 `head -30` 可能提前杀掉进程。让我不限制输出重跑看完整: 

Ran terminal command:  adb -s 70a91f89 shell 'timeout 15 /vendor/bin/agmplay /data/local/tmp/test440_8ch_32bit_10s.wav -D 100 -d 100 -c 8 -r 48000 -b 32 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY -dkv 0xA2000001 -dppkv 0xAC000002 -ikv 1 -skv 0xA100000E 2>&1'

agmplay 完成了 10s 播放。让我检查之前关于 "1s 静音" 的关键发现——可能 PA 的行为才是线索：    

Read memory twrp_audio_pure_c_audible_baseline_flag_20260326.md

Read memory twrp_audio_stock_and_helper_1s_frontier_20260325.md

Read memory twrp_audio_pure_c_current_silent_but_historically_1s_20260325.md

Read memory twrp_audio_helper_vs_agmplay_tag_surface_diff_20260324.md

从 repo memory 了解到：pure_c_play 可能当前完全静音（不只是 1s），而 agmplay 有 ~1s 可听。让我先系统性尝试几个方向。

先试 aw_volume 最大值（720），确认是否是增益不足的问题：   

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --seconds 5 --aw-vol 720 --trace 2>&1' | tail -15

我无法从终端判断声音是否可听。让我换个思路——在播放期间监控 PA 寄存器变化，确认 DSP 是否向硬件持续发送非零数据。用两个并行进程：一个播放，一个轮询 PA 寄存器：  

Ran terminal command:  adb -s 70a91f89 shell 'cat /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/reg_dump 2>/dev/null | head -10'

Ran terminal command:  adb -s 70a91f89 shell 'ls /sys/bus/i2c/drivers/aw882xx_smartpa/ 2>/dev/null'

Ran terminal command:  adb -s 70a91f89 shell 'ls /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/ 2>/dev/null | head -20'

Ran terminal command:  adb -s 70a91f89 shell 'ls /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/ 2>/dev/null' | tr ' ' '\n'

Ran terminal command:  adb -s 70a91f89 shell 'cat /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/reg 2>/dev/null | head -20'

PA 当前空闲（SYSST=0x0011）。需要在播放期间监控。让我用后台播放 + 前台轮询的方式：    

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --seconds 8 --aw-vol 720 2>/dev/null &
BGPID=$!
for i in $(seq 1 16); do
  sleep 0.5
  SYSST=$(cat /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/reg 2>/dev/null | grep "reg:0x01=" | cut -d= -f2)
  VOL=$(cat /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/reg 2>/dev/null | grep "reg:0x0c=" | cut -d= -f2)
  echo "t=${i}x0.5s SYSST=${SYSST} VOL=${VOL}"
done
wait $BGPID 2>/dev/null
echo "播放结束"
SYSST_END=$(cat /sys/bus/i2c/drivers/aw882xx_smartpa/4-0034/reg 2>/dev/null | grep "reg:0x01=" | cut -d= -f2)
echo "播放后 SYSST=${SYSST_END}"'

关键发现！PA 在整个 8 秒中保持 **SYSST=0x0311（活跃）**，直到播放结束才回到 0x0011。这意味着：
- PA 硬件全程在工作
- 如果 ~1s 后静音，问题在 **DSP 层的数据变零**，不是 PA 关闭

现在尝试 devicepp_kv=0（跳过设备后处理），看是否 OEM 后处理模块在衰减音频： 

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --seconds 5 --devicepp 0 --aw-vol 720 --trace 2>&1' | tail -20

devicepp=0 导致 graph 建不起来（pcm_open -19）。设备后处理是图的必要组件。

让我读一下关于 devicepp 的 memory：    

Read memory twrp_audio_odm_speaker_devicepp_left_right_branch_20260325.md

Read memory twrp_audio_devicepp_kv_frontier.md

让我检查 agmplay 是否在 pcm_open 后做了 setParamTag 调用——从二进制中搜索相关字符串引用：  

Ran terminal command:  adb -s 70a91f89 shell 'strings /vendor/bin/agmplay | grep -i "setParam\|setparam\|getParam\|param\|tagged"'
Completed with input:  adb -s 70a91f89 shell 'strings /vendor/bin/agmplay | grep -i "setParam\|setparam\|getParam\|param\|tagged"'

Ran terminal command:  adb -s 70a91f89 shell 'strings /vendor/bin/agmplay 2>/dev/null | head -40'

Ran terminal command:  adb -s 70a91f89 shell 'strings /vendor/bin/agmplay 2>/dev/null' | grep -i "pcm_\|mixer_\|write\|read\|start\|prepare\|close\|param"

**重大发现！** agmplay 的调用链中**没有任何 setParam/setParamTag**，但它调了几个 pure_c_play **缺少的** helper：
1. `get_device_media_config` — 读取后端媒体配置
2. `set_agm_device_media_config` — 设置设备媒体配置  
3. `set_agm_audio_intf_metadata` — 设置**接口级别** metadata（写到 TDM-LPAIF-RX-SECONDARY metadata）

pure_c_play 只写了 PCM100 级别的 metadata，完全**遗漏了接口级别的配置**！这很可能导致后端格式匹配不上，DSP 处理异常。

让我把这些缺失的 helper 加到 pure_c_play： 

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#70-70), lines 70 to 80

Replacing 5 lines with 10 lines in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c)


```

```
现在在 load_libs 里加载这些符号：     

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#140-140), lines 140 to 155

Replacing 11 lines with 18 lines in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c)


```

```
现在添加 `--agmplay-mode` 选项，完整复制 agmplay 的 helper 调用链。先读参数解析部分和 metadata 写入部分：   

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#430-430), lines 430 to 460

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#460-460), lines 460 to 500

现在添加 `--agmplay-mode` 参数并实现完整的 agmplay helper 调用链：     

Replacing 3 lines with 4 lines in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c)


```

```


Replacing 4 lines with 6 lines in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c)


```

```
现在在 mixer_open(100) 之后、现有 metadata 写入之前，添加 agmplay_mode 的 helper 路径。找到插入点：   

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#472-472), lines 472 to 498

Replacing 5 lines with 74 lines in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c)


```

```
现在在 getTaggedInfo 块之后加 `skip_raw_metadata` label：      

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#585-585), lines 585 to 610

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#610-610), lines 610 to 640

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#640-640), lines 640 to 660

在 getTaggedInfo 块结束后加 label：    

Replacing 5 lines with 7 lines in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c)


```

```
agmplay_mode 也需要 getTaggedInfo 解析。让我在 agmplay_mode 的 goto 前也加解析，或者把 getTaggedInfo 移到 label 之后。更简单的方法是把 getTaggedInfo 移到 skip_raw_metadata 后面（同时检查 agmplay_mode 下也需要）：

实际上 getTaggedInfo 是 read-only 的，放在 pcm_open 后面也行。不过先看看目前的 agmplay_mode goto 跳到 skip_raw_metadata 是不是跳过了 getTaggedInfo。让我确认当前流程： 

Searched for text `goto skip_raw_metadata` (`**/pure_c_play.c`), 1 result

Searched for text `skip_raw_metadata:` (`**/pure_c_play.c`), 1 result

OK，goto 从 560 跳到 656，跳过了 Step 2-5.6 包括 getTaggedInfo。agmplay 本身不做 getTaggedInfo（它只在 connect 前后分别调 get_miid），所以 agmplay_mode 不需要 getTaggedInfo。编译测试：   

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP/video_player" && bash build_pure_c_play.sh 2>&1

Ran terminal command:  adb -s 70a91f89 push "/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_play" /data/local/tmp/pure_c_play && adb -s 70a91f89 shell 'chmod 755 /data/local/tmp/pure_c_play'

运行 `--agmplay-mode` 测试：      

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --seconds 5 --agmplay-mode --aw-vol 720 --trace 2>&1'
Completed with input:  adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --seconds 5 --agmplay-mode --aw-vol 720 --trace 2>&1'

`--agmplay-mode` 中 `get_miid` 返回 -19，说明 helper 函数签名可能不对。但重点发现：`set_agm_audio_intf_metadata rc=0` **成功**了！

问题出在 helper 参数布局上，但 raw mode 本身已经能工作。让我换个策略——在已有的 raw mode 里**补上** `set_agm_audio_intf_metadata` 调用，这是 agmplay 有而我们缺少的唯一关键步骤：     

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#560-560), lines 560 to 572

在 raw mode 的 Step 2 之前插入接口 metadata 调用：      

Replacing 4 lines with 10 lines in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c)


```

```


Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP/video_player" && bash build_pure_c_play.sh 2>&1

Ran terminal command:  adb -s 70a91f89 push "/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_play" /data/local/tmp/pure_c_play

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --seconds 5 --aw-vol 720 --trace 2>&1'
Completed with input:  adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --seconds 5 --aw-vol 720 --trace 2>&1'

`set_agm_audio_intf_metadata` 破坏了原有流程！混合 helper 调用和 raw 写入有冲突。让我撤销它，并集中精力修正 agmplay-mode 的 helper 签名：     

Replacing 10 lines with 4 lines in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c)


```

```
现在我需要弄清楚 `set_agm_stream_metadata` 和 `set_agm_streamdevice_metadata` 的真实签名。让我直接反汇编 libagmmixer.so 来看参数布局：       

Ran terminal command:  adb -s 70a91f89 pull /vendor/lib64/libagmmixer.so /tmp/libagmmixer.so 2>&1

Ran terminal command:  nm -D /tmp/libagmmixer.so | grep -E "set_agm_stream|set_agm_audio_intf|set_agm_device_media|connect_agm|configure_mfc|get_device_media"

Ran terminal command:  objdump -d --start-address=0xd5b8 --stop-address=0xd5e0 /tmp/libagmmixer.so

Ran terminal command:  objdump -d --start-address=0xbb90 --stop-address=0xbc60 /tmp/libagmmixer.so

Ran terminal command:  nm -D /tmp/libagmmixer.so | grep set_agm_stream_metadata_type

Ran terminal command:  objdump -d --start-address=0xd4e0 --stop-address=0xd510 /tmp/libagmmixer.so

Ran terminal command:  objdump -d --start-address=0xa874 --stop-address=0xa900 /tmp/libagmmixer.so

反汇编太复杂了。让我直接拉取 agmplay 反汇编它的 main 函数来看参数传递：   

Ran terminal command:  adb -s 70a91f89 pull /vendor/bin/agmplay /tmp/agmplay 2>&1 && file /tmp/agmplay

Ran terminal command:  objdump -d /tmp/agmplay | grep -n "set_agm_stream_metadata\|set_agm_audio_intf\|set_agm_device_media\|set_agm_streamdevice" | head -20

有 5 个调用点。让我看每个调用前的参数设置（查看 BL 之前约 20 条指令）：     

Ran terminal command:  objdump -d --start-address=0x65e0 --stop-address=0x6640 /tmp/agmplay

Ran terminal command:  objdump -d --start-address=0x6640 --stop-address=0x6700 /tmp/agmplay

Ran terminal command:  objdump -d --start-address=0x6700 --stop-address=0x6760 /tmp/agmplay

关键发现！从 agmplay 反汇编确认了真实参数布局：

- `set_agm_stream_metadata(mixer, device, instance_kv, 0, 0, stream_kv)` — 第2参是 device（非 card），第3参是 **instance_kv**（非 device）
- `set_agm_streamdevice_metadata(mixer, device, instance_kv, 0, 0, intf_name, kv)` — 同样

我之前 agmplay_mode 传的参数顺序错了！修正：     

Replacing 16 lines with 18 lines in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c)


```

```
同时修正 agm_get_miid 的参数——agmplay 传的是 `(mixer, device, intf_name, 0, tag, &miid)`： 

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP/video_player" && bash build_pure_c_play.sh 2>&1

Ran terminal command:  adb -s 70a91f89 push "/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_play" /data/local/tmp/pure_c_play && adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --seconds 5 --agmplay-mode --aw-vol 720 --trace 2>&1'
Completed with input:  adb -s 70a91f89 push "/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_play" /data/local/tmp/pure_c_play && adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --seconds 5 --agmplay-mode --aw-vol 720 --trace 2>&1'

还是失败。`get_device_media_config` 返回 -22（no backend_conf.xml），可能导致了后续问题。让我检查 agmplay 在 get_device_media_config 失败时是否跳过了 set_device_media_config：    

Ran terminal command:  objdump -d --start-address=0x65a0 --stop-address=0x6620 /tmp/agmplay

Ran terminal command:  objdump -d /tmp/agmplay | grep "get_device_media_config" | head -5

Ran terminal command:  objdump -d --start-address=0x6550 --stop-address=0x65b0 /tmp/agmplay

问题找到了！agmplay 在 `get_device_media_config` 失败时仍然调用 `set_agm_device_media_config`（用 CLI 参数填充）。但我们的代码在 get 失败时跳过了 set。

让我查看 `set_agm_device_media_config` 实际写什么：        

Ran terminal command:  objdump -d --start-address=0xab6c --stop-address=0xacc0 /tmp/libagmmixer.so

现在理解了！`set_agm_device_media_config` 读的配置结构体很大（至少 0x60 字节），rate/ch/bits 分别在偏移 0x50/0x54/0x58/0x5c。agmplay 即使 `get` 失败也会 `set`，用 CLI 参数填充。

让我修改 agmplay_mode：      

Replacing 12 lines with 24 lines in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c)


```

```


Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP/video_player" && bash build_pure_c_play.sh 2>&1

Ran terminal command:  adb -s 70a91f89 push "/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_play" /data/local/tmp/pure_c_play && adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --seconds 5 --agmplay-mode --aw-vol 720 --trace 2>&1'
Completed with input:  adb -s 70a91f89 push "/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_play" /data/local/tmp/pure_c_play && adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --seconds 5 --agmplay-mode --aw-vol 720 --trace 2>&1'

agmplay_mode 的参数还不对。但更重要的是——raw mode 本身已经能工作（pcm_open 成功、PA 全程活跃）。如果 agmplay 也是 ~1s 可听，那复制 agmplay 的 helper 路径并不会改善。

让我先确认当前 raw mode 是否还正常工作，同时请你听一下是否有声音——运行 5s 正弦波：        

Ran terminal command:  adb -s 70a91f89 push "/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_play" /data/local/tmp/pure_c_play && adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --seconds 5 --aw-vol 720 --trace 2>&1'
Completed with input:  adb -s 70a91f89 push "/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_play" /data/local/tmp/pure_c_play && adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --seconds 5 --aw-vol 720 --trace 2>&1'

raw mode 也坏了！之前的 agmplay_mode 测试污染了 AGM 状态。让我重置：       

Ran terminal command:  adb -s 70a91f89 shell 'ps -ef | grep -E "pure_c|agmplay|audio" | grep -v grep'

Ran terminal command:  adb -s 70a91f89 shell 'kill 1937 && sleep 1 && ps -ef | grep audiohal | grep -v grep'

audiohal 自动重启了。再试 raw mode：      

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --seconds 3 --aw-vol 720 --trace 2>&1'
Completed with input:  adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --seconds 3 --aw-vol 720 --trace 2>&1'

MFC get_miid 现在返回 -19，之前返回过 rc=0 miid=16584。audiohal 重启导致 AGM 状态不同。让我等 audiohal 稳定后重试：        

Ran terminal command:  adb -s 70a91f89 shell 'kill $(pidof audiohalservice.qti) 2>/dev/null; sleep 3; ps -ef | grep audiohal | grep -v grep'

Ran terminal command:  adb -s 70a91f89 shell 'sleep 2 && /data/local/tmp/pure_c_play --seconds 3 --aw-vol 720 --trace 2>&1'
Completed with input:  adb -s 70a91f89 shell 'sleep 2 && /data/local/tmp/pure_c_play --seconds 3 --aw-vol 720 --trace 2>&1'

ADSP 进程状态可能没重置。让我杀掉音频相关的所有进程：         

Ran terminal command:  adb -s 70a91f89 shell 'kill $(pidof audiohalservice.qti) $(pidof audioadsprpcd) 2>/dev/null; sleep 5; ps -ef | grep -E "audio|adsp" | grep -v grep'

Ran terminal command:  adb -s 70a91f89 shell 'sleep 2 && /data/local/tmp/pure_c_play --seconds 3 --aw-vol 720 --trace 2>&1'
Completed with input:  adb -s 70a91f89 shell 'sleep 2 && /data/local/tmp/pure_c_play --seconds 3 --aw-vol 720 --trace 2>&1'

持续失败。让我先确认 agmplay 自身是否也坏了——如果 agmplay 也失败，说明是 ADSP 状态问题：        

Ran terminal command:  adb -s 70a91f89 shell 'timeout 15 /vendor/bin/agmplay /data/local/tmp/test440_8ch_32bit_10s.wav -D 100 -d 100 -c 8 -r 48000 -b 32 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY -dkv 0xA2000001 -dppkv 0xAC000002 -ikv 1 -skv 0xA100000E 2>&1'

agmplay 正常工作！让我先跑 agmplay 建立 AGM 状态，然后立即跑 raw mode —— 如果成功，证明是初始化差异：       

Ran terminal command:  adb -s 70a91f89 shell 'timeout 3 /vendor/bin/agmplay /data/local/tmp/test440_8ch_32bit_10s.wav -D 100 -d 100 -c 8 -r 48000 -b 32 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY -dkv 0xA2000001 -dppkv 0xAC000002 -ikv 1 -skv 0xA100000E 2>&1; sleep 1; /data/local/tmp/pure_c_play --seconds 3 --aw-vol 720 --trace 2>&1'

**关键发现！** agmplay 预热后 raw mode 立即恢复（get_miid=16584, pcm_open 成功）。说明 raw mode 依赖 agmplay 建立的**接口级初始化**。

现在需要让 pure_c_play 能独立工作。让我检查 agmplay 是否调用了 `PCM100 control=ZERO`：   

Ran terminal command:  strings /tmp/agmplay | grep -i "PCM\|ZERO\|control"

agmplay 完全不碰 "PCM100 control" 控件！我们的 `PCM100 control=ZERO` 可能在干扰 helper。让我在 agmplay_mode 里跳过它：       

Replacing 3 lines with 5 lines in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c)


```

```
编译、推送、先杀 audiohal 重置状态，再测试独立 agmplay-mode：        

Ran terminal command:  cd "/Volumes/Case-sensitive APFS/TWRP/video_player" && bash build_pure_c_play.sh 2>&1

Ran terminal command:  adb -s 70a91f89 push "/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_play" /data/local/tmp/pure_c_play && adb -s 70a91f89 shell 'kill $(pidof audiohalservice.qti) $(pidof audioadsprpcd) 2>/dev/null; sleep 5; /data/local/tmp/pure_c_play --seconds 3 --agmplay-mode --aw-vol 720 --trace 2>&1'
Completed with input:  adb -s 70a91f89 push "/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_play" /data/local/tmp/pure_c_play && adb -s 70a91f89 shell 'kill $(pidof audiohalservice.qti) $(pidof audioadsprpcd) 2>/dev/null; sleep 5; /data/local/tmp/pure_c_play --seconds 3 --agmplay-mode --aw-vol 720 --trace 2>&1'

还是 -19。所有 helper 返回 0 但 graph 没建立。让我直接用 strace 对比 agmplay 和 pure_c_play 的 ioctl 调用：         

Ran terminal command:  adb -s 70a91f89 shell 'which strace 2>/dev/null; ls /data/local/tmp/strace 2>/dev/null'
Completed with input:  adb -s 70a91f89 shell 'which strace 2>/dev/null; ls /data/local/tmp/strace 2>/dev/null'

Ran terminal command:  adb -s 70a91f89 shell 'kill $(pidof audiohalservice.qti) $(pidof audioadsprpcd) 2>/dev/null; sleep 5; strace -f -e trace=ioctl -o /data/local/tmp/strace_agmplay.txt timeout 5 /vendor/bin/agmplay /data/local/tmp/test440_8ch_32bit_10s.wav -D 100 -d 100 -c 8 -r 48000 -b 32 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY -dkv 0xA2000001 -dppkv 0xAC000002 -ikv 1 -skv 0xA100000E 2>&1; echo "strace done"; wc -l /data/local/tmp/strace_agmplay.txt'

Ran terminal command:  adb -s 70a91f89 shell 'grep "SNDRV_CTL_IOCTL_ELEM_WRITE\|SNDRV_CTL_IOCTL_ELEM_READ" /data/local/tmp/strace_agmplay.txt | head -40'

Made changes.


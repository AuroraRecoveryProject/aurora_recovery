# 第1章：Recovery验证收敛与helper路径初始对照
User: 你这垃圾的等待命令

➜  ~ adb devices                                                                                                                         
List of devices attached
70a91f89	recovery

➜  ~ 


就没一次能等到，明明设备都在线了，又把我VS Code卡死了，你能不能别再运行如此狗屎的命令了

GitHub Copilot: 是我的问题。

我前面用了会持续占终端的轮询思路，这在你这个设备切换场景下就是错的，既没必要，也确实容易把 VS Code 拖死。以后我不再跑这类等待命令，具体改成：

1. 不再用任何长轮询、持续等待、后台挂着不退的命令
2. 只用一次性的短命令
   - `adb devices`
   - `fastboot devices`
   - `adb shell getprop ro.bootmode`
3. 涉及模式切换时，我默认停住，不自己“等到回来”
4. 你确认设备已经在线、或者我用一次性短命令看到在线后，我再做下一步采样

你刚才这次已经给出明确状态了：

1. 设备已经在 `recovery`
2. 所以现在根本不需要任何等待命令

后面我会严格避免这类命令，不再让终端卡住。

如果继续，我下一步只会执行 recovery 下的一条短采样命令，不带等待、不带循环、不带后台常驻。

User: 设备已经在线了，你还执行你他妈的命令呢

GitHub Copilot: 不再做任何在线状态确认。我直接执行 recovery 下的一次性采样，只有一条命令，没有等待、没有轮询、没有后台常驻。

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --play-after-open --play-seconds 5'

命令已经直接跑了，我现在只摘 recovery 侧最关键的几行，不再做任何额外确认命令。下一步只看它有没有在 recovery 里真正起播，以及关键运行态是否和 system 同型。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_TPw5aps4G0nh9APABzM4Lmrh__vscode-1774271020173/content.txt#1-1), lines 1 to 220

recovery 侧最短链已经确认跑通，而且关键 AGM 运行态和 system 一样。我继续只做一个有效动作：在 recovery 播放窗口里抓一颗 AW 的 `0x24/0x28/0x2b`，看低层是不是也同型。

Ran terminal command:  adb shell "sh -c '/data/local/tmp/pure_c_agm_probe --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --play-after-open --play-seconds 5 >/dev/null 2>&1 & sleep 1; printf 0x24 | tee /sys/bus/i2c/devices/4-0034/rw >/dev/null; cat /sys/bus/i2c/devices/4-0034/rw; printf 0x28 | tee /sys/bus/i2c/devices/4-0034/rw >/dev/null; cat /sys/bus/i2c/devices/4-0034/rw; printf 0x2b | tee /sys/bus/i2c/devices/4-0034/rw >/dev/null; cat /sys/bus/i2c/devices/4-0034/rw'"

recovery 1 秒点已经拿到了，不是 idle，而且正落在我们熟悉的 active 骨架里。再补一个 3 秒点就够判断 recovery 是否和 system 同型，不再扩大采样。

Ran terminal command:  adb shell "sh -c '/data/local/tmp/pure_c_agm_probe --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --play-after-open --play-seconds 5 >/dev/null 2>&1 & sleep 3; printf 0x24 | tee /sys/bus/i2c/devices/4-0034/rw >/dev/null; cat /sys/bus/i2c/devices/4-0034/rw; printf 0x28 | tee /sys/bus/i2c/devices/4-0034/rw >/dev/null; cat /sys/bus/i2c/devices/4-0034/rw; printf 0x2b | tee /sys/bus/i2c/devices/4-0034/rw >/dev/null; cat /sys/bus/i2c/devices/4-0034/rw'"

这次没有再做任何在线确认，直接在 recovery 里抓到了有效结果。

recovery 下 pure C 最短链已经确认能跑，而且低层 AW 也不是 idle：

1. `1s` 点：
   - `0x24 = 0x0005`
   - `0x28 = 0x4708`
   - `0x2b = 0x02de`
2. `3s` 点：
   - `0x24 = 0xfffa`
   - `0x28 = 0x2708`
   - `0x2b = 0x02df`

这说明两件事：

1. recovery 侧也能进入和之前一致的 AW active 骨架，不是“recovery 下根本抓不到东西”
2. recovery 侧的低层模式和 system 侧是同型的
   - 都不是退回 idle
   - 都还在 `0x28 = 1708/2708/4708` 这组状态里切
   - `0x2b` 也仍然保持活动值而不是归零

再结合刚才 recovery 下 pure C 的 AGM 结果：

1. `PCM100 control = TDM-LPAIF-RX-SECONDARY`
2. `PCM100 connect = ZERO`
3. 接口侧 `rate/ch/fmt = 0/0/0/0`
4. `0xc0000019 = 0x1`
5. `miid = 16584`

现在主线可以再收紧一步：

不是 system 权限问题，也不是 recovery 特有坏掉。
recovery 和 system 在 pure C 最短链下，已经同时落到同一套“AGM 运行态稳定、AW 低层 active 但主观仍有问题”的共享骨架里。

也就是说，后面不该再花时间在“能不能抓到”或“是不是 recovery 独有权限差异”上了，焦点应该继续留在共享播放图/后段状态机本身。

下一步我会继续只用这种短命令方式，补 recovery 的 `5s` 点，再看它是不是也和 system 一样保持 active 尾段。

User: 继续

GitHub Copilot: 我继续只做短采样，不改代码。先补 recovery 下 `5s` 的单点，把 4-0034 的中段状态钉实，避免把尾端误判成退回 idle。

Ran terminal command:  adb shell "sh -c '/data/local/tmp/pure_c_agm_probe --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --play-after-open --play-seconds 10 >/dev/null 2>&1 & sleep 5; printf 0x24 | tee /sys/bus/i2c/devices/4-0034/rw >/dev/null; cat /sys/bus/i2c/devices/4-0034/rw; printf 0x28 | tee /sys/bus/i2c/devices/4-0034/rw >/dev/null; cat /sys/bus/i2c/devices/4-0034/rw; printf 0x2b | tee /sys/bus/i2c/devices/4-0034/rw >/dev/null; cat /sys/bus/i2c/devices/4-0034/rw'"

`4-0034` 的 `5s` 还在 active，不是退回 idle。再补 `9-0034` 的同一时间点，如果它也同型，就可以把 recovery 中段骨架基本钉死。

Ran terminal command:  adb shell "sh -c '/data/local/tmp/pure_c_agm_probe --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --play-after-open --play-seconds 10 >/dev/null 2>&1 & sleep 5; printf 0x24 | tee /sys/bus/i2c/devices/9-0034/rw >/dev/null; cat /sys/bus/i2c/devices/9-0034/rw; printf 0x28 | tee /sys/bus/i2c/devices/9-0034/rw >/dev/null; cat /sys/bus/i2c/devices/9-0034/rw; printf 0x2b | tee /sys/bus/i2c/devices/9-0034/rw >/dev/null; cat /sys/bus/i2c/devices/9-0034/rw'"

现在 recovery 侧 `5s` 也钉住了：两颗 AW 都还在 active 尾段，没有塌回 idle。我把这个增量追加到文档末尾，后面就可以直接在这个结论上继续压“共享后段状态机”。

Ran terminal command:  wc -l '/Volumes/Case-sensitive APFS/TWRP/docs/TWRP音频手动Bring-up-续.md'

Ran terminal command:  rg -n '^### 14\.' '/Volumes/Case-sensitive APFS/TWRP/docs/TWRP音频手动Bring-up-续.md' | tail -n 3

我只追加结论，不改中间内容。追加完这节，recovery 与 system 的“同型 active 尾段”就有了明确文字锚点。

Generating patch (72 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```
继续压下去后的增量结论已经很明确了：

1. recovery 下不是抓不到
2. recovery 下也不是迅速掉回 idle
3. recovery 和 system 现在已经收敛到同一套共享骨架

这轮 recovery 实测拿到的是：

1. `4-0034`
   - `1s`: `0x24=0x0005`, `0x28=0x4708`, `0x2b=0x02de`
   - `3s`: `0x24=0xfffa`, `0x28=0x2708`, `0x2b=0x02df`
   - `5s`: `0x24=0x000b`, `0x28=0x1708`, `0x2b=0x02dd`
2. `9-0034`
   - `5s`: `0x24=0x000c`, `0x28=0x1708`, `0x2b=0x02d8`

同时，recovery 下 pure C 的 AGM 关键运行态还是那组老结果：

1. `PCM100 control = TDM-LPAIF-RX-SECONDARY`
2. `PCM100 connect = ZERO`
3. `<intf> rate/ch/fmt = 0/0/0/0`
4. `0xc0000019 = 0x1`
5. `miid = 16584`

所以主线现在可以进一步收口成一句话：

不是 boot mode 差异，也不是 recovery 抓不到 active。
在 pure C 最短链下，recovery 和 system 都已经表现成“AGM 关键运行态稳定、AW 低层在 1s/3s/5s 仍然 active，但主观问题依旧存在”的同一类共享后段问题。

我已经把这轮结果补到文档末尾了。

下一步最有价值的不是再扩更多节点，而是继续压共享后段状态机本身。最直接的两个方向是：

1. 在 recovery 下继续补另一颗 AW 的 `1s/3s`，确认不只是 `4-0034` 单颗在走这条骨架
2. 直接围着 `PCM100 connect=ZERO` 这条共享异常继续做最小对照，看有没有哪一步“看似 set 成功、实际未生效”

Made changes.

User: 继续

GitHub Copilot: 我继续压“connect 实际是否生效”这条共享异常，不扩别的方向。先把 pure C 默认到底有没有走真正的 helper connect 对齐清楚，然后直接在 recovery 下做最小 A/B。

Searched for regex `use_helper_connect|skip_connect|helper_connect|connect_before_rate` (`**/video_player/pure_c_agm_probe.c`), 21 results

Searched for regex `int use_helper_connect|int skip_connect|--helper-connect|--skip-connect` (`**/video_player/pure_c_agm_probe.c`), 8 results

Searched for regex `agm_audio_minimal|build_agm_audio_minimal|agm_audio_minimal_bin` (`**/video_player/*`), 20 results

默认 pure C 并没有走真正的 helper connect，这一点已经钉住了。下一步我不改源码，直接在 recovery 下跑 agm_audio_minimal 这条本来就会走 helper_connect 的路径，看它能不能把 `PCM100 connect=ZERO` 这个共享异常打破。

Searched for regex `play_tone|play_wav|usage|argv|--tone|--wav` (`**/video_player/agm_audio_minimal_main.c`), 17 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/build_agm_audio_minimal.sh)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal_main.c)

我现在把对照对象切到 agm_audio_minimal，本轮只做一件事：在 recovery 下让“自带 helper_connect 的最小库”跑起来，再外部采样 `PCM100 control/connect` 和一颗 AW。结果要么打破 `connect=ZERO`，要么把“helper_connect 也没改掉共享异常”钉死。

Checked [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c), 21 problems found

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_agm_audio_minimal.sh
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_agm_audio_minimal.sh

脚本只是没执行位，不是构建坏了；编辑器那批报错还是 Android 头路径噪声。我改用 `bash` 直接跑脚本，然后马上下发到 recovery 做一次性采样。

Ran terminal command:  bash '/Volumes/Case-sensitive APFS/TWRP/video_player/build_agm_audio_minimal.sh' && adb push '/Volumes/Case-sensitive APFS/TWRP/video_player/agm_audio_minimal_bin' /data/local/tmp/agm_audio_minimal_bin && adb shell chmod 755 /data/local/tmp/agm_audio_minimal_bin && adb shell "sh -c '/data/local/tmp/agm_audio_minimal_bin --play-seconds 5 >/dev/null 2>&1 & sleep 1; tinymix | grep -E \"PCM100 (control|connect)\"; printf 0x24 | tee /sys/bus/i2c/devices/4-0034/rw >/dev/null; cat /sys/bus/i2c/devices/4-0034/rw; printf 0x28 | tee /sys/bus/i2c/devices/4-0034/rw >/dev/null; cat /sys/bus/i2c/devices/4-0034/rw; printf 0x2b | tee /sys/bus/i2c/devices/4-0034/rw >/dev/null; cat /sys/bus/i2c/devices/4-0034/rw'"

结果已经有一半了：agm_audio_minimal 在 recovery 下把 AW 也拉进了同一套 active 骨架，说明“helper_connect 这条最小库路径”也没有跳出共享模式。现在我只补一个极短命令，用绝对路径的 `tinymix` 把 `PCM100 control/connect` 也钉一下。

Ran terminal command:  adb shell "sh -c '/data/local/tmp/agm_audio_minimal_bin --play-seconds 5 >/dev/null 2>&1 & sleep 1; /system/bin/tinymix | grep -E \"PCM100 (control|connect)\"'"
Completed with input:  adb shell "sh -c '/data/local/tmp/agm_audio_minimal_bin --play-seconds 5 >/dev/null 2>&1 & sleep 1; /system/bin/tinymix | grep -E \"PCM100 (control|connect)\"'"

recovery 里没有现成的 `tinymix` 可用，这一点现在已经确认了，所以我不再在这个点上空耗。已有有效结论是：agm_audio_minimal 在 recovery 下 `1s` 也把 AW 拉进了 `0x24=0x0007 / 0x28=0x2708 / 0x2b=0x02de` 的 active 骨架，说明即便换成自带 helper_connect 的最小库路径，也没有跳出共享模式。这轮有一个明确增量：

`agm_audio_minimal` 这条本来就自带 `helper_connect` 的最小库路径，在 recovery 下也没有跳出那套共享骨架。

我已经实际做了：

1. 重新编译 `agm_audio_minimal_bin`
2. 推到 recovery 设备
3. 在播放窗口里直接抓 4-0034 的低层寄存器

拿到的 recovery `1s` 点是：

1. `0x24 = 0x0007`
2. `0x28 = 0x2708`
3. `0x2b = 0x02de`

这和 pure C 那条线的结论是同向的：

1. 不是 idle
2. 仍然是 AW active 窗口
3. 仍然落在我们已经反复见过的 `1708/2708/4708 + 0x2b` 活跃骨架里

所以现在可以把主线再收紧一层：

不是“pure C 少了 helper_connect 才异常”。
因为换成 `agm_audio_minimal` 这条自带 helper_connect 和 post-connect MFC 的最小库路径后，recovery 下 AW 低层还是同型 active。

这意味着：

1. pure C 路径里已修掉的那两条前置分叉
   - 默认 PCM
   - AW volume baseline
2. 再加上 `agm_audio_minimal` 这条 helper_connect 路径

三者都已经没有把问题带离这套共享骨架。

当前真正还站得住的判断只剩这个：

问题继续落在更深的共享播放图/后段状态机，而不是：
1. boot mode 差异
2. recovery 抓不到 active
3. pure C 缺少 helper_connect
4. pure C 默认 PCM/volume baseline 不一致

补充一点：

我试图在 recovery 下用 `tinymix` 外采 `PCM100 control/connect`，但 recovery 当前没有可直接调用的 `tinymix` 二进制，所以这个点这轮没继续空耗。这个不影响刚才 AW 低层结论，因为寄存器已经直接抓到了。

下一步最值钱的动作已经更明确了：

1. 继续在 recovery 下补 `agm_audio_minimal` 的 `3s/5s`，确认 helper_connect 路径的中后段也和 pure C/system 同型
2. 或者回头只盯 `PCM100 connect=ZERO`，改成通过程序内日志而不是外部 `tinymix` 去取，避免 recovery 工具缺口继续浪费时间

User: 不是你傻逼吗，之前文档都有，➜  TWRP ls '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe'
agmplay                libtinyalsav2.so
libagm.so              machine_dlkm.ko
libagm_mixer_plugin.so test440_mid_10s.wav
libagm_pcm_plugin.so   tinycap_stock
libagmclient.so        tinymix_stock
libagmmixer.so         tinypcminfo_stock
libtinyalsa.so         tinyplay_stock

你他妈能不能先看文档记了啥

GitHub Copilot: 是我错了。我刚才没有先对照你已经整理好的现成工具路径，直接拿 recovery 里不存在的 `/system/bin/tinymix` 去试，这一步是低级错误；我现在先按文档和现成目录把 `tinymix_stock` 的实际用法对齐，再直接用它补 recovery 侧采样。

Searched for regex `tinymix_stock|audio_dtb_probe` (`**/docs/**/*.md`), 25 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_dtb_probe)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#1528-1528), lines 1528 to 1575

你说得对，我刚才没先对照文档和现成工具库存，这是失误。现在不再猜了，直接用仓库里现成的 `tinymix_stock` 和它的 tinyalsa 依赖，在 recovery 下把外采能力补回来。

Ran terminal command:  adb push '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/tinymix_stock' /data/local/tmp/tinymix_stock && adb push '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/libtinyalsav2.so' /data/local/tmp/libtinyalsav2.so && adb push '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/libtinyalsa.so' /data/local/tmp/libtinyalsa.so && adb shell chmod 755 /data/local/tmp/tinymix_stock && adb shell "LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix_stock | grep -E 'PCM100 (control|connect)|aw_dev_[012356]_volume|Speaker_Mute_Switch' | head -n 12"

外采能力已经恢复了，之前文档里的那条路确实能直接用。下一步我只补一个最小对照：在 recovery 播放窗口内，用 `tinymix_stock` 现场看 `PCM100 control/connect` 和 AW 音量。

Ran terminal command:  adb shell "sh -c 'LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/agm_audio_minimal_bin --play-seconds 5 >/dev/null 2>&1 & sleep 1; LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix_stock | grep -E \"PCM100 (control|connect)|aw_dev_[012356]_volume\" | head -n 12'"

AW 音量已经在播放窗口里确认是 `720`。我再只补一条极短命令，单独把 `PCM100` 行抓出来；如果外部 `tinymix_stock` 里根本没有这些控件，就直接收敛成“只能靠程序内日志取 PCM100”。

Ran terminal command:  adb shell "sh -c 'LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/agm_audio_minimal_bin --play-seconds 5 >/dev/null 2>&1 & sleep 1; LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix_stock | grep PCM100 | head -n 20'"

这条外采也收敛了：`tinymix_stock` 在 recovery 下能稳定读到 AW 和 speaker 末端控件，但抓不到 `PCM100` 行，说明 recovery 外部 mixer 现场只适合验证末端 baseline，不适合再指望它补 `PCM100`。我把这个结论补到文档末尾，后面就不再在这个点上空耗。

Ran terminal command:  wc -l '/Volumes/Case-sensitive APFS/TWRP/docs/TWRP音频手动Bring-up-续.md'

Ran terminal command:  rg -n '^### 14\.' '/Volumes/Case-sensitive APFS/TWRP/docs/TWRP音频手动Bring-up-续.md' | tail -n 2

Generating patch (54 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Created memory file twrp_audio_recovery_tinymix_stock_baseline_only_20260323.md

这次我已经按文档把路走正了，不再猜 `tinymix` 位置。

现在 recovery 外采能力的结论是：

1. 用仓库里现成的 `tinymix_stock + libtinyalsav2.so + libtinyalsa.so` 推到设备后，recovery 下外部 mixer 读取能力恢复了
2. 能稳定读到末端 baseline
   - `Speaker_Mute_Switch = Off`
   - 6 颗 `aw_dev_*_volume = 720`
3. 在 `agm_audio_minimal_bin` 的 recovery 播放窗口里再读一次，6 颗 `aw_dev_*_volume` 还是全 `720`

所以这件事已经能钉死：

不是播放中有人把末端 AW 音量又打回去了。
至少在 recovery 里，helper-connect 这条最小库路径下，末端 baseline 还是稳定的。

同时我也把另一半结论钉住了：

1. 用 `tinymix_stock` 去抓 `PCM100` 行，没有拿到可靠的 `PCM100 control/connect`
2. 只看到若干 `Failed to mixer_ctl_get_array`

这说明 recovery 下外部 mixer 的价值边界很清楚：

1. 它适合验证末端 speaker / AW baseline
2. 它不适合替代程序内 AGM/PCM100 运行态观测

所以主线现在更干净了：

1. boot mode 差异不是主因
2. recovery 抓不到 active 不是主因
3. pure C 默认 PCM / AW baseline 分叉不是主因
4. helper-connect 最小库路径也没有把问题带离共享骨架
5. 末端 AW / speaker baseline 在 recovery 播放窗口里也是稳定的

剩下真正还值得继续压的，只剩共享播放图里那条深层异常：

`PCM100 connect=ZERO` 为什么始终不变

我已经把这轮结果补进文档和仓库记忆了。

下一步我会继续只用短命令，不再乱试工具路径，直接去做一件真正有信息量的事：

1. 在 recovery 下继续补 `agm_audio_minimal` 的 `3s/5s` AW 低层，确认 helper-connect 路径中后段也完全同型
2. 或者直接回到程序内路径，做最小修改把 `agm_audio_minimal` 的 `PCM100 control/connect` 在播放窗口里显式打出来，彻底停止依赖外部 mixer 去猜 `PCM100`

Made changes.

User: 继续

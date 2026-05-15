设备当前还在 recovery，原始 `dtbo_a` 已备份，SELinux 也已经恢复到 `Enforcing`。如果继续，我建议下一步只做下面两件事之一：

1. 直接追 `wsa_swr_ctrl` / `wsa2_swr_ctrl` 对应的 SWR controller 版本字段，做第四版最小 dtbo 修补。
2. 抓一份正常系统下这两个 SWR controller 的运行时 DT 或早期内核日志，对照 recovery 现在的 `0x2000000` 与 `0x2010000` 差异。

User: 继续，你建议哪个就执行哪个

GitHub Copilot: 先把 `swr-mgr` 的源码和它读取的 DT 字段钉死，这样第四版补丁就不是猜值，而是按驱动真实需求改。

Search complete: 追 SWR 驱动字段

Searching for regex `version specified in dtsi|num_dev > max limit|wsa_swr_ctrl|wsa2_swr_ctrl|swr-mgr|swr-mstr-ctrl`

Searched for files matching `**/*swr*{.c,.h,.dtsi,.dts,.yaml,.txt}`, 2 matches

Searching for text `num_dev > max limit` (`**/twrp_a12_compile/**`)

Searching for text `num_dev > max limit` (`**/twrp_a16_compile/**`)

Searching for text `version specified in dtsi` (`**/twrp_a12_compile/**`)

Searching for text `version specified in dtsi` (`**/twrp_a16_compile/**`)

Searched codebase for "Qualcomm SoundWire master driver logs "version specified in dtsi" and "num_dev > max limit" swr-mgr swr-mstr-ctrl", 14 results

Searched for regex `wsa_swr_ctrl|wsa2_swr_ctrl` (`**/twrp_a12_compile/**/arch/arm64/boot/dts/**/*.dts*`), no results

Searched for regex `wsa_swr_ctrl|wsa2_swr_ctrl` (`**/twrp_a16_compile/**/arch/arm64/boot/dts/**/*.dts*`), no results

上个检索没返回有效内容，我直接在源码树里做窄搜索，把 `swrm_probe` 和相关日志字符串定位出来。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg -a -n 'swrm_probe|version specified in dtsi|num_dev > max limit|swr link failed to connect' twrp_a12_compile twrp_a16_compile -g '*.{c,h}'
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg -a -n 'swrm_probe|version specified in dtsi|num_dev > max limit|swr link failed to connect' twrp_a12_compile twrp_a16_compile -g '*.{c,h}'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg -a -n 'compatible = "qcom,swr-mstr"|qcom,swr-num-dev|qcom,swr_master_id|swrm-io-base' audio_dtb_probe/dtbo_dts_patched3/entry0.dts

字符串搜索没命中源码文件名，我改成先找驱动文件本体，再读具体实现。

Searched for files matching `**/*swr*ctrl*.c`, no matches

Searched for files matching `**/*soundwire*.c`, no matches

Searched for files matching `**/*swr*.c`, 1 match

源码树里没有这份厂商驱动源码，那就直接解模块字符串，找它读取的 DT 属性名和错误路径。

Searched for files matching `**/swr_ctrl_dlkm.ko`, no matches

Searched for files matching `**/vendor_dlkm/**/swr*.ko`, no matches

Ran terminal command:  adb -s 70a91f89 shell 'find /vendor_dlkm /vendor/lib/modules /lib/modules -name "*swr*ko" 2>/dev/null | head -n 40'

模块路径拿到了，下一步直接扫 `swr_ctrl_dlkm.ko` 的字符串，看驱动真实关心哪些 DT 属性和值。

Ran terminal command:  adb -s 70a91f89 shell 'strings /vendor_dlkm/lib/modules/swr_ctrl_dlkm.ko | grep -E "version specified in dtsi|max limit|qcom,|swrm_probe|link status not connected|compatible" | head -n 200'

Ran terminal command:  adb -s 70a91f89 shell 'strings /vendor_dlkm/lib/modules/swr_ctrl_dlkm.ko | grep -E "num_dev|version|wake_irq|mipi|clock-stop|master_id|port-mapping|io-base|max-dev|clk_freq" | head -n 200'

现在已经拿到关键字段名了：驱动明确读取 `qcom,swr-master-version`。下一步只核对当前 DT 里这项到底写没写、写了什么。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && rg -n 'qcom,swr-master-version|qcom,swrm-hctl-reg|qcom,swr-master-ee-val|qcom,swr-wakeup-irq|qcom,is-always-on|qcom,disable-div2-clk-switch' dtbo_dts_patched3/entry0.dts

Ran terminal command:  adb -s 70a91f89 shell 'for p in /sys/firmware/devicetree/base/soc/spf_core_platform/lpass-cdc/wsa-macro@6B00000/wsa_swr_master /sys/firmware/devicetree/base/soc/spf_core_platform/lpass-cdc/wsa2-macro@6AA0000/wsa2_swr_master /sys/firmware/devicetree/base/soc/spf_core_platform/rx-macro@6AC0000/rx_swr_master /sys/firmware/devicetree/base/soc/spf_core_platform/va-macro@7660000/va_swr_master; do echo ===$p===; ls "$p" | grep "swr-master-version" || true; done'

Ran terminal command:  adb -s 70a91f89 shell 'for f in /sys/firmware/devicetree/base/soc/spf_core_platform/lpass-cdc/wsa-macro@6B00000/wsa_swr_master/qcom,swr-master-version /sys/firmware/devicetree/base/soc/spf_core_platform/lpass-cdc/wsa2-macro@6AA0000/wsa2_swr_master/qcom,swr-master-version /sys/firmware/devicetree/base/soc/spf_core_platform/rx-macro@6AC0000/rx_swr_master/qcom,swr-master-version /sys/firmware/devicetree/base/soc/spf_core_platform/va-macro@7660000/va_swr_master/qcom,swr-master-version; do echo ===$f===; [ -f "$f" ] && xxd -g 4 "$f" || echo missing; done'

驱动字段核对后有个关键信息：`qcom,swr-master-version` 在当前运行时 DT 里根本不存在，说明 `0x2000000` 很可能是驱动默认值，不是我们现有 overlay 明写的。接下来我对比“能工作的 `rx/va/bt` SWR master”与“失败的 `wsa/wsa2` SWR master”节点差异，找第二个真正缺项。

Ran terminal command:  adb -s 70a91f89 shell 'find /sys/firmware/devicetree/base -name "rx_swr_ctrl" -o -name "rx_swr_master" -o -name "va_swr_ctrl" -o -name "va_swr_master" -o -name "bt_swr_mstr" | head -n 80'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && for line in 22040 22090 22135 22233 22420; do sed -n "${line},$((line+28))p" dtbo_dts_patched3/entry0.dts; echo '---'; done

Ran terminal command:  adb -s 70a91f89 shell 'for d in /sys/bus/platform/devices/rx_swr_ctrl /sys/bus/platform/devices/va_swr_ctrl /sys/bus/platform/devices/wsa_swr_ctrl /sys/bus/platform/devices/wsa2_swr_ctrl /sys/bus/platform/devices/bt_swr_mstr; do echo ===$d===; ls "$d" 2>/dev/null | head -n 40; done'

对比已经很清楚了：绑定成功的 `rx/va/bt` 控制器目录下都会挂出 `driver` 和 `swrX` 子节点；`wsa/wsa2` 没有，说明它们就是在 SWR master 初始化时失败了，不是后面的 codec 才挂。现在读 DTS 具体块，只比较属性差异。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_4Be42FMoCW2uUe39No2JjRsC__vscode-1773445663946/content.txt)

当前 DTS 横向比对没暴露出一个明显“一眼就能改”的属性差，而 recovery 里的 `wsa` 路径又已经卡到了 SWR 链路层。下一步改成抓正常系统实况做对照，这比继续盲改第四版 dtbo 更稳。

Ran terminal command:  adb -s 70a91f89 shell 'ls /sys/bus/platform/devices | grep -E "wsa|wsa883|wsa884|swr"'

Ran terminal command:  adb -s 70a91f89 shell 'ls -1 /sys/bus/soundwire/devices 2>/dev/null'

Ran terminal command:  adb -s 70a91f89 reboot

现在设备在切正常系统。我会只采 WSA/SWR 相关最小基线，确认 stock 下到底有哪些节点、哪些 soundwire 从设备、哪些 DT 数值和 recovery 不一样。

Ran terminal command:  sleep 25; adb devices -l

Ran terminal command:  sleep 35; adb devices -l

正常系统已经起来了。下面只抓四类对照：WSA/SWR 平台设备、soundwire 从设备、运行时 DT 数值、以及当前 dtbo 槽位信息。

Ran terminal command:  adb -s 70a91f89 shell 'getprop ro.boot.slot_suffix; echo ---; ls /sys/bus/platform/devices | grep -E "wsa|wsa883|wsa884|swr"'

Ran terminal command:  adb -s 70a91f89 shell 'ls -1 /sys/bus/soundwire/devices 2>/dev/null'

Ran terminal command:  adb -s 70a91f89 shell 'for f in /sys/firmware/devicetree/base/soc/spf_core_platform/sound/qcom,wsa-max-devs /sys/firmware/devicetree/base/soc/spf_core_platform/lpass-cdc/wsa-macro@6B00000/wsa_swr_master/qcom,swr-num-dev /sys/firmware/devicetree/base/soc/spf_core_platform/lpass-cdc/wsa2-macro@6AA0000/wsa2_swr_master/qcom,swr-num-dev /sys/firmware/devicetree/base/soc/spf_core_platform/lpass-cdc/wsa-macro@6B00000/wsa_swr_master/qcom,swr-master-version /sys/firmware/devicetree/base/soc/spf_core_platform/lpass-cdc/wsa2-macro@6AA0000/wsa2_swr_master/qcom,swr-master-version; do echo ===$f===; [ -f "$f" ] && xxd -g 4 "$f" || echo missing; done'

Ran terminal command:  adb -s 70a91f89 shell 'for n in rx_swr_ctrl va_swr_ctrl wsa_swr_ctrl wsa2_swr_ctrl bt_swr_mstr; do echo ===$n===; readlink /sys/bus/platform/devices/$n/driver 2>/dev/null || echo unbound; done'

对照结果有个反常点：正常系统里 `wsa_swr_ctrl` / `wsa2_swr_ctrl` 竟然也是 `unbound`，soundwire 列表也和 recovery 很像。这意味着“WSA 没绑上”可能不是最终根因，至少不能再当成 recovery 独有差异。现在我直接抓系统侧内核日志和 ASoC 组件，验证这条假设是不是已经该推翻。

Ran terminal command:  adb -s 70a91f89 shell 'dmesg | grep -i -E "wsa_swr_ctrl|wsa2_swr_ctrl|version specified in dtsi|unknown pin WSA|wsa-codec|swrm_probe" | tail -n 120'

Ran terminal command:  adb -s 70a91f89 shell 'cat /sys/kernel/debug/asoc/components 2>/dev/null | grep -E "wsa|lpass-cdc|wcd939x|aw882"'
Completed with input:  adb -s 70a91f89 shell 'cat /sys/kernel/debug/asoc/components 2>/dev/null | grep -E "wsa|lpass-cdc|wcd939x|aw882"'

Ran terminal command:  adb -s 70a91f89 shell 'cat /proc/asound/cards; echo ---; cat /proc/asound/pcm | grep -E "WSA|sun-mtp|CODEC_DMA|TDM-LPAIF_WSA|AW"'
Completed with input:  adb -s 70a91f89 shell 'cat /proc/asound/cards; echo ---; cat /proc/asound/pcm | grep -E "WSA|sun-mtp|CODEC_DMA|TDM-LPAIF_WSA|AW"'

Ran terminal command:  adb -s 70a91f89 shell 'cmd media.audio_policy list-audio-patches 2>/dev/null || dumpsys media.audio_policy 2>/dev/null | grep -i -E "speaker|device 2|AUDIO_DEVICE_OUT_SPEAKER" | head -n 120'

系统侧有扬声器策略，但普通 shell 权限不够看内核和 ALSA 细节。我切一次 root，把同一批只读信息补齐。

Ran terminal command:  adb -s 70a91f89 root

Ran terminal command:  sleep 4; adb devices -l

`adbd root` 在系统侧不可用，但如果设备带 `su`，仍然能把内核和 ALSA 细节读出来。我先走这个通道验证。

Ran terminal command:  adb -s 70a91f89 shell 'which su; su -c id'

Ran terminal command:  adb -s 70a91f89 shell 'su -c "dmesg | grep -i -E \"wsa_swr_ctrl|wsa2_swr_ctrl|version specified in dtsi|unknown pin WSA|wsa-codec|swrm_probe\" | tail -n 120"'

Ran terminal command:  adb -s 70a91f89 shell 'su -c "cat /proc/asound/cards; echo ---; cat /proc/asound/pcm | grep -E \"WSA|sun-mtp|CODEC_DMA|TDM-LPAIF_WSA|AW\""'

`su` 可用，系统侧 ALSA 也和 recovery 几乎同构，连 `TDM-LPAIF_WSA-*` 都一样在。这进一步说明“WSA 控制器 unbound”不是 recovery 独有症状。现在看系统内核日志，确认它是否也同样报错。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_zaIIiCPKdPGn4MB3QejGchyF__vscode-1773445663965/content.txt)

正常系统也同样报 `wsa_swr_ctrl` / `wsa2_swr_ctrl` 初始化失败并保持 deferred，这基本把“WSA 是 recovery 最终独有阻塞”这条线推翻了。现在我转到更直接的对照项：看正常系统里那些我们在 recovery 里找不到或点不亮的 mixer / speaker 路径，到底是不是本来就不存在。

Ran terminal command:  adb -s 70a91f89 shell 'su -c "/vendor/bin/tinymix 2>/dev/null | grep -E \"rate ch fmt|TDM-LPAIF-RX-SECONDARY|TDM-LPAIF_WSA|WSA|Speaker|Mute|Spkr\" | head -n 200"'

Ran terminal command:  adb -s 70a91f89 shell 'su -c "cat /sys/kernel/debug/asoc/components 2>/dev/null | grep -E \"wsa|aw882|lpass-cdc|wcd939x\""'
Completed with input:  adb -s 70a91f89 shell 'su -c "cat /sys/kernel/debug/asoc/components 2>/dev/null | grep -E \"wsa|aw882|lpass-cdc|wcd939x\""'

Ran terminal command:  adb -s 70a91f89 shell 'su -c "find /sys/kernel/debug/asoc -maxdepth 2 -type d | grep -E \"sun-mtp-snd-card|Speaker_Playback|aw882\" | head -n 120"'

系统侧 debugfs 默认没挂，`tinymix` 这一条也没直接吐出关键信息。我先把最小工具面补齐：确认 `tinymix` 本身怎么用、debugfs 是否能临时挂上，然后继续对照控件。

Ran terminal command:  adb -s 70a91f89 shell 'su -c "/vendor/bin/tinymix | head -n 30"'

Ran terminal command:  adb -s 70a91f89 shell 'su -c "mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; ls /sys/kernel/debug/asoc 2>/dev/null | head -n 40"'

Ran terminal command:  adb -s 70a91f89 shell 'su -c "cmd media.audio_policy list-audio-patches | head -n 120"'

系统侧没有 `/vendor/bin/tinymix`，但 debugfs 已经能看了。这足够继续做结构对照；我再顺手把实际可用的 mixer 工具路径找出来。

Ran terminal command:  adb -s 70a91f89 shell 'su -c "find /vendor/bin /odm/bin /system/bin /system_ext/bin -maxdepth 1 \( -name tinymix -o -name tinyplay_ftm -o -name agmplay -o -name mm-audio-ftm -o -name cplay \) 2>/dev/null"'

Ran terminal command:  adb -s 70a91f89 shell 'su -c "cat /sys/kernel/debug/asoc/components | grep -E \"wsa|aw882|lpass-cdc|wcd939x\""'

Ran terminal command:  adb -s 70a91f89 shell 'su -c "find /sys/kernel/debug/asoc/sun-mtp-snd-card -maxdepth 2 -type d | grep -E \"Speaker|Spkr|aw882|snd-card$\" | head -n 120"'

真正的新差异出来了：正常系统的 ASoC 组件里有 6 个 `aw882xx_smartpa.*`，而 recovery 这边之前只有 `wcd939x-codec` 和 `lpass-cdc`。这比 WSA 那条线更像最终差异，因为扬声器实际就是走 AW882xx smart PA。现在我直接把系统侧控件和 DAPM 结构取出来，回到 recovery 后按这个差异追。

Ran terminal command:  adb -s 70a91f89 shell 'su -c "/system/bin/tinymix | grep -E \"Speaker_Mute_Switch|Spkr|aw882|AW882|smartpa|Speaker\" | head -n 200"'

Ran terminal command:  adb -s 70a91f89 shell 'su -c "for d in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*; do echo ===$d===; ls $d/dapm | head -n 20; done"'

Ran terminal command:  adb -s 70a91f89 shell 'su -c "for f in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*/dapm/widget; do echo ===$f===; cat $f; done"'

系统侧 mixer 已经给出最有价值的线索：`aw882xx_rx_switch`、`aw882xx_tx_switch`、`aw882xx_copp_switch` 在系统里都是 `Enable`。这三个控件在 recovery 之前从未进入过我们的视野，优先级已经很高。我再把系统侧 smartpa widget 状态补完整，然后回 recovery 验证这些控件是否缺失或默认关闭。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_PQRu5DlDkuO6AoYheLX6Vo9l__vscode-1773445663979/content.txt#1-1), lines 1 to 260

系统侧的新锚点已经够明确了，我再补一组最小 I2C/driver 证据，然后回 recovery 对比同一组对象，确认是不是 AW882xx probe 链没真正落地。

Ran terminal command:  adb -s 70a91f89 shell 'su -c "ls /sys/bus/i2c/devices | grep -E \"^(4|9)-0034$|^(4|9)-0035$|^(4|9)-0036$\""'
Completed with input:  adb -s 70a91f89 shell 'su -c "ls /sys/bus/i2c/devices | grep -E \"^(4|9)-0034$|^(4|9)-0035$|^(4|9)-0036$\""'

Ran terminal command:  adb -s 70a91f89 shell 'su -c "ls -la /sys/bus/i2c/drivers | grep -i aw882"'

Ran terminal command:  adb -s 70a91f89 shell 'su -c "for d in 4-0034 4-0035 4-0036 9-0034 9-0035 9-0036; do echo ===$d===; readlink /sys/bus/i2c/devices/$d/driver 2>/dev/null || echo unbound; done"'

系统侧又出现一个细节：`aw882xx_smartpa` 驱动目录在，但我刚才那条循环命令被 shell 展开搞坏了，设备绑定状态还没拿准。下一步我用不依赖变量展开的写法，把系统和 recovery 的 AW882xx I2C 设备一次性对齐。

Ran terminal command:  adb -s 70a91f89 shell 'su -c "for d in 4-0034 4-0035 4-0036 9-0034 9-0035 9-0036; do echo ===\$d===; if [ -e /sys/bus/i2c/devices/\$d ]; then readlink /sys/bus/i2c/devices/\$d/driver 2>/dev/null || echo no-driver; else echo missing; fi; done"'

Ran terminal command:  adb -s 70a91f89 reboot recovery

现在回 recovery，只对照 3 组东西：`aw882xx_smartpa` 组件、6 个 I2C 设备绑定、以及那 3 个 AW 控件。只要这三组里有缺口，根因就比 WSA 线更靠前。

Ran terminal command:  sleep 25; adb devices -l

Ran terminal command:  sleep 35; adb devices -l

recovery 这一轮起来得慢一些，我继续轮询，不会用 `wait-for-device`。设备一回来就直接采差异。

Ran terminal command:  sleep 30; adb devices -l

Ran terminal command:  sleep 5; fastboot devices

recovery 已回来了。现在只抓 AW882xx 这条链。

Ran terminal command:  adb -s 70a91f89 shell 'cat /sys/kernel/debug/asoc/components 2>/dev/null | grep -E "aw882|lpass-cdc|wcd939x"'

Ran terminal command:  adb -s 70a91f89 shell 'for d in 4-0034 4-0035 4-0036 9-0034 9-0035 9-0036; do echo ==='$'d===; if [ -e /sys/bus/i2c/devices/'$'d ]; then readlink /sys/bus/i2c/devices/'$'d/driver 2>/dev/null || echo no-driver; else echo missing; fi; done'

Ran terminal command:  adb -s 70a91f89 shell '/system/bin/tinymix 2>/dev/null | grep -E "Speaker_Mute_Switch|aw882xx_rx_switch|aw882xx_tx_switch|aw882xx_copp_switch|SpkrLeft|SpkrRight" | head -n 80'

Ran terminal command:  adb -s 70a91f89 shell 'find /sys/kernel/debug/asoc/sun-mtp-snd-card -maxdepth 2 -type d | grep -E "aw882|Speaker|Spkr" | head -n 80'

AW882xx 这条链现在也被实测推翻了：当前 recovery 里已经有 6 个 `aw882xx_smartpa.*` 组件和对应 dapm 目录，和正常系统这部分是一致的。说明真正差异不在“有没有 AW882xx”，而更像在它的控件状态或激活时序。我先把 recovery 里的实际控件值读出来。

Ran terminal command:  adb -s 70a91f89 shell '/system/bin/tinymix | head -n 50'

Ran terminal command:  adb -s 70a91f89 shell 'for f in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*/dapm/widget; do echo ===$f===; cat $f; done'
Completed with input:  adb -s 70a91f89 shell 'for f in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*/dapm/widget; do echo ===$f===; cat $f; done'

Ran terminal command:  adb -s 70a91f89 shell 'for f in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*/dapm/bias_level; do echo ===$f===; cat $f; done'

当前 recovery 里 AW882xx bias 全是 `Off`，但这只能说明“空闲时没亮”，还不能区分是播放器没拉起还是控件没切对。我先把 recovery 可用的 `tinymix` 路径找出来，能读控件值就能继续往前。

Ran terminal command:  adb -s 70a91f89 shell 'find /system /mnt /vendor /odm -maxdepth 4 -name tinymix 2>/dev/null | head -n 40'

Ran terminal command:  adb -s 70a91f89 shell 'for d in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*; do echo ===$d===; ls $d/dapm; done'

Ran terminal command:  adb -s 70a91f89 shell 'for f in $(find /sys/kernel/debug/asoc/sun-mtp-snd-card -path "*/aw882xx_smartpa.*/dapm/widget" 2>/dev/null); do echo ===$f===; cat $f; done'

结构已经看清了：AW882xx 的 DAPM 不是单个 `widget` 文件，而是每个 `Speaker_Playback_*` / `Speaker_Capture_*` 各自一个目录。下一步直接在这些目录里读状态。

Ran terminal command:  adb -s 70a91f89 shell 'for d in $(find /sys/kernel/debug/asoc/sun-mtp-snd-card -path "*/aw882xx_smartpa.*/dapm/Speaker_Playback_*" 2>/dev/null); do echo ===$d===; ls $d; done'

Ran terminal command:  adb -s 70a91f89 shell 'for d in $(find /sys/kernel/debug/asoc/sun-mtp-snd-card -path "*/aw882xx_smartpa.*/dapm/Speaker_Playback_*" 2>/dev/null); do echo ===$d===; for f in $d/*; do echo ---$f---; cat $f; done; done'
Completed with input:  adb -s 70a91f89 shell 'for d in $(find /sys/kernel/debug/asoc/sun-mtp-snd-card -path "*/aw882xx_smartpa.*/dapm/Speaker_Playback_*" 2>/dev/null); do echo ===$d===; for f in $d/*; do echo ---$f---; cat $f; done; done'

Ran terminal command:  adb -s 70a91f89 shell 'find / -name tinyalsa  -o -name tinymix -o -name libtinyalsa* 2>/dev/null | head -n 60'

debugfs 这边最后一个细节也确认一下：这些 `Speaker_Playback_*` 本身就是可直接读的状态节点，不是目录。读完它们，再决定要不要把系统的 `tinymix` 拿进 recovery。

Ran terminal command:  adb -s 70a91f89 shell 'for f in $(find /sys/kernel/debug/asoc/sun-mtp-snd-card -path "*/aw882xx_smartpa.*/dapm/Speaker_Playback_*" 2>/dev/null); do echo ===$f===; cat $f; done'

Ran terminal command:  adb -s 70a91f89 shell 'for f in $(find /sys/kernel/debug/asoc/sun-mtp-snd-card -path "*/aw882xx_smartpa.*/dapm/Speaker_Capture_*" 2>/dev/null); do echo ===$f===; cat $f; done'

Ran terminal command:  adb -s 70a91f89 shell '/odm/bin/tinyplay_ftm /sdcard/test440_low.wav 16 48000 2 >/data/local/tmp/tinyplay_aw.out 2>&1; cat /data/local/tmp/tinyplay_aw.out; echo ---; for f in $(find /sys/kernel/debug/asoc/sun-mtp-snd-card -path "*/aw882xx_smartpa.*/dapm/Speaker_Playback_*" 2>/dev/null); do echo ===$f===; cat $f; done; echo ---; for f in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*/dapm/bias_level; do echo ===$f===; cat $f; done'

到这一步，实机结论已经很稳定了：recovery 里 AW882xx 组件、DAPM 节点都在，但 `tinyplay_ftm` 播放后它们完全不被激活。下一步最值钱的动作是把系统里的 `tinymix` 拿进 recovery，直接读并改 `aw882xx_*` 控件，不再靠播放器黑箱试。

Ran terminal command:  adb -s 70a91f89 reboot

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && rm -f tinymix_stock

设备在回系统，我等它起来后直接导出 `tinymix`，然后再回 recovery 用它查 AW 控件。

Ran terminal command:  sleep 25; adb devices -l

User: 继续

GitHub Copilot: 把 `tinymix` 从正常系统导出来是当前最短路径，这样回 recovery 后就能直接读写 AW882xx 相关控件，而不是继续猜播放器内部行为。

Ran terminal command:  adb devices -l

Ran terminal command:  fastboot devices

设备已经在正常系统里，下一步直接把 `tinymix` 和它依赖的 `libtinyalsa` 抽出来，回 recovery 用同一套工具读 AW 控件。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && adb -s 70a91f89 pull /system/bin/tinymix tinymix_stock

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && adb -s 70a91f89 pull /vendor/lib64/libtinyalsa.so libtinyalsa.so && adb -s 70a91f89 pull /vendor/lib64/libtinyalsav2.so libtinyalsav2.so
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && adb -s 70a91f89 pull /vendor/lib64/libtinyalsa.so libtinyalsa.so && adb -s 70a91f89 pull /vendor/lib64/libtinyalsav2.so libtinyalsav2.so

Ran terminal command:  adb -s 70a91f89 shell 'sha1sum /system/bin/tinymix /vendor/lib64/libtinyalsa.so /vendor/lib64/libtinyalsav2.so'

`tinymix` 已经导出来了，`libtinyalsa` 直拉被系统权限拦住，但这不需要停下；我直接用 `su` 复制到可拉取位置再取出来。

Ran terminal command:  adb -s 70a91f89 shell 'su -c "cp /vendor/lib64/libtinyalsa.so /data/local/tmp/libtinyalsa.so && cp /vendor/lib64/libtinyalsav2.so /data/local/tmp/libtinyalsav2.so && chmod 0644 /data/local/tmp/libtinyalsa.so /data/local/tmp/libtinyalsav2.so"'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && adb -s 70a91f89 pull /data/local/tmp/libtinyalsa.so libtinyalsa.so && adb -s 70a91f89 pull /data/local/tmp/libtinyalsav2.so libtinyalsav2.so

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && shasum tinymix_stock libtinyalsa.so libtinyalsav2.so

工具包已经拿到本地，接下来回 recovery，把这三件东西推到 `/data/local/tmp`，直接读取 `aw882xx_rx_switch` / `aw882xx_tx_switch` / `aw882xx_copp_switch` 和 `Speaker_Mute_Switch`。

Ran terminal command:  adb -s 70a91f89 reboot recovery

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && ls -lh tinymix_stock libtinyalsa.so libtinyalsav2.so

现在等 recovery 起来后就能直接读控件，离“知道该手动切哪个开关”只差一步。

Ran terminal command:  sleep 30; adb devices -l

Ran terminal command:  sleep 45; adb devices -l

recovery 已上线。下面会把 `tinymix` 和库推进去，先读控件，再决定是否直接手动置位 AW 开关。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && adb -s 70a91f89 push tinymix_stock /data/local/tmp/tinymix && adb -s 70a91f89 push libtinyalsa.so /data/local/tmp/libtinyalsa.so && adb -s 70a91f89 push libtinyalsav2.so /data/local/tmp/libtinyalsav2.so && adb -s 70a91f89 shell 'chmod 0755 /data/local/tmp/tinymix && chmod 0644 /data/local/tmp/libtinyalsa.so /data/local/tmp/libtinyalsav2.so'

Ran terminal command:  adb -s 70a91f89 shell 'LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix | grep -E "Speaker_Mute_Switch|aw882xx_rx_switch|aw882xx_tx_switch|aw882xx_copp_switch|SpkrLeft|SpkrRight" | head -n 80'

Ran terminal command:  adb -s 70a91f89 shell 'LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix | grep -E "rate ch fmt|TDM-LPAIF-RX-SECONDARY|TDM-LPAIF_WSA|WSA" | head -n 120'

现在已经跨过“看不到控件”的阶段了：recovery 里 `aw882xx_rx_switch/tx_switch/copp_switch` 都已经是 `Enable`，真正空着的是整条 WSA 播放路由，大量 `WSA RX* MUX` 仍是 `ZERO`。下一步不该瞎调值，而是直接从厂商 mixer XML 里把“speaker 路由”对应控件抠出来。

Ran terminal command:  adb -s 70a91f89 shell 'find /vendor/etc /odm/etc -maxdepth 2 -iname "*mixer*xml" 2>/dev/null | head -n 80'

Ran terminal command:  adb -s 70a91f89 shell 'grep -R -n -E "WSA RX0 MUX|WSA2 RX0 MUX|aw882xx_rx_switch|Speaker_Mute_Switch|SpkrLeft|SpkrRight" /vendor/etc /odm/etc 2>/dev/null | head -n 200'

Ran terminal command:  adb -s 70a91f89 shell 'grep -R -n -E "speaker|spk|aw882|wsa" /vendor/etc /odm/etc 2>/dev/null | head -n 200'

XML 线索已经抓到了，我先只读和 speaker 直接相关的命名，避免再被大量无关条目淹没。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_syJoI92CuB9g4d4pugto5vJX__vscode-1773492594139/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_M49SX7AKwWKhoYVkj3X4rCMf__vscode-1773492594140/content.txt)

Compacted conversation已经看到标准 Qualcomm mixer 里 speaker path 的骨架了，下一步直接抽设备实际使用的 ODM speaker 段落，再把那组值手工打进 recovery。Optimizing tool selection...

Read memory

Created 4 todos

Read memory twrp_audio_aw882xx_frontier.md

Read memory twrp_audio_manual_playback.md

先把 ODM 的 speaker path 原文截出来，只看实际设备配置，不再参考通用 sku 文件。

Ran terminal command:  adb -s 70a91f89 shell sed -n '1,240p' /odm/etc/mixer_paths.xml

Ran terminal command:  adb -s 70a91f89 shell sed -n '1,260p' /odm/etc/ftm_mixer_paths.xml

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_lDBJMyf1iteY1guyU4QDSBWS__vscode-1773492594147/content.txt)

默认段只有功放 profile 和默认关断，真正关键还在后面的 path 定义。我继续抓 ODM 里 speaker 和 FTM loudspeaker 的具体 ctl 列表。

Ran terminal command:  adb -s 70a91f89 shell grep -n '<path name="speaker"\|<path name="speaker-prot"\|<path name="ftm-loudspeaker-test"' /odm/etc/mixer_paths.xml /odm/etc/ftm_mixer_paths.xml
Completed with input:  adb -s 70a91f89 shell grep -n '<path name="speaker"\|<path name="speaker-prot"\|<path name="ftm-loudspeaker-test"' /odm/etc/mixer_paths.xml /odm/etc/ftm_mixer_paths.xml

Ran terminal command:  adb -s 70a91f89 shell grep -n 'WSA RX0 MUX\|WSA2 RX0 MUX\|SpkrLeft\|SpkrRight\|aw_dev_.*switch' /odm/etc/mixer_paths.xml /odm/etc/ftm_mixer_paths.xml | head -n 200

远端 shell 引号被 adb 吃掉了，我改成单层的 `grep -nE` 形式重跑，避免再丢模式。

Ran terminal command:  adb -s 70a91f89 shell "grep -nE '<path name=\"speaker\"|<path name=\"speaker-prot\"|<path name=\"ftm-loudspeaker-test\"' /odm/etc/mixer_paths.xml /odm/etc/ftm_mixer_paths.xml"

Ran terminal command:  adb -s 70a91f89 shell "grep -nE 'WSA RX0 MUX|WSA2 RX0 MUX|SpkrLeft|SpkrRight|aw_dev_.*switch' /odm/etc/mixer_paths.xml /odm/etc/ftm_mixer_paths.xml | head -n 200"

Ran terminal command:  adb -s 70a91f89 shell sed -n '345,385p' /odm/etc/mixer_paths.xml

Ran terminal command:  adb -s 70a91f89 shell sed -n '595,620p' /odm/etc/mixer_paths.xml

Ran terminal command:  adb -s 70a91f89 shell sed -n '1508,1595p' /odm/etc/mixer_paths.xml

ODM 只负责开关 AW 功放，真正的 WSA 路由还是 Qualcomm 通用 mixer 在做。我现在抓 sun_mtp 的 speaker path 原文，直接按它的 ctl 顺序去打。

Ran terminal command:  adb -s 70a91f89 shell sed -n '275,325p' /vendor/etc/audio/sku_sun/mixer_paths_sun_mtp.xml

Ran terminal command:  adb -s 70a91f89 shell sed -n '325,380p' /vendor/etc/audio/sku_sun/mixer_paths_sun_mtp.xml

路由值已经明确了。我先验证 recovery 里这些具体控件名能不能被 `tinymix` 正常写入，再批量设整条 speaker-prot 路径。

Ran terminal command:  adb -s 70a91f89 shell 'LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix "WSA RX0 MUX" AIF1_PB'

Ran terminal command:  adb -s 70a91f89 shell 'LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix "SpkrLeft COMP Switch" 1'
Completed with input:  adb -s 70a91f89 shell 'LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix "SpkrLeft COMP Switch" 1'

`WSA RX0 MUX` 能写，说明路径有效；但 `SpkrLeft COMP Switch` 在 recovery 里根本没导出，控件集合和 vendor XML 不是完全同一版。我先把现有 `Spkr/WSA` 控件列表抓出来，再按 recovery 实际名字适配。

Ran terminal command:  adb -s 70a91f89 shell 'LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix | grep -i "Spkr" | head -n 120'

Ran terminal command:  adb -s 70a91f89 shell 'LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix | grep -i "WSA" | head -n 200'

recovery 导出的名字偏向 `WSA_COMP1`、`WSA2_COMP1` 这一套，不是 XML 里的 `SpkrLeft/Right` 别名。现在可以按实际控件名把主链路和 WSA2 链路都补齐。

Ran terminal command:  adb -s 70a91f89 shell 'LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix | grep -i "aw_dev_[0-9]_switch\|aw_dev_[0-9]_prof"'
Completed with input:  adb -s 70a91f89 shell 'LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix | grep -i "aw_dev_[0-9]_switch\|aw_dev_[0-9]_prof"'

Ran terminal command:  adb -s 70a91f89 shell 'LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix | grep -i "aw882xx_.*switch\|Speaker_Mute_Switch"'
Completed with input:  adb -s 70a91f89 shell 'LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix | grep -i "aw882xx_.*switch\|Speaker_Mute_Switch"'

刚才是 `grep` 基本正则又吞了 `|`。我改成 `grep -E`，顺手把 `tinymix` 全量输出落盘，后面就不再反复枚举。

Ran terminal command:  adb -s 70a91f89 shell 'LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix | grep -E "aw_dev_[0-9]_(switch|prof)"'

Ran terminal command:  adb -s 70a91f89 shell 'LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix | grep -E "aw882xx_.*switch|Speaker_Mute_Switch"'

Ran terminal command:  adb -s 70a91f89 shell 'LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix >/data/local/tmp/tinymix_dump.txt 2>/data/local/tmp/tinymix_dump.err && wc -l /data/local/tmp/tinymix_dump.txt'

控制面差异已经收敛到 WSA 这组。AW 开关其实早就是开的，我现在手工补齐 `speaker-prot` 对应的 WSA 路由，再直接触发 FTM 播放看 DAPM 有没有亮。

Ran terminal command:  adb -s 70a91f89 shell 'LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix "WSA RX0 MUX" AIF1_PB && LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix "WSA RX1 MUX" AIF1_PB && LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix "WSA_RX0 INP0" RX0 && LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix "WSA_RX1 INP0" RX1 && LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix "WSA_COMP1 Switch" 1 && LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix "WSA_COMP2 Switch" 1 && LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix "WSA_RX0 Digital Volume" 84 && LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix "WSA_RX1 Digital Volume" 84 && LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix "WSA_RX INT0 VBAT WSA RX0 VBAT Enable" 1 && LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix "WSA_RX INT1 VBAT WSA RX1 VBAT Enable" 1'

Ran terminal command:  adb -s 70a91f89 shell 'setprop vendor.oplus.mm.ftm_spk 1; /odm/bin/tinyplay_ftm /odm/etc/oplus_ftm_smart_pa.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY'

Ran terminal command:  adb -s 70a91f89 shell 'for d in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*; do echo ===$d===; cat $d/Speaker_Playback; cat $d/bias_level; done'
Completed with input:  adb -s 70a91f89 shell 'for d in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*; do echo ===$d===; cat $d/Speaker_Playback; cat $d/bias_level; done'

播放命令有明显长输出，我先把它读出来判断是成功播放、卡住，还是又在前面某层失败。然后单独回读 DAPM，避免和播放抢状态。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_PbUt4qrf7jC3qocR5uEVROOB__vscode-1773492594169/content.txt#1-1), lines 1 to 260

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_PbUt4qrf7jC3qocR5uEVROOB__vscode-1773492594169/content.txt#261-261), lines 261 to 312

先不猜播放结果。我直接看两个事实：`tinyplay_ftm` 进程现在在不在，以及刚写进去的 WSA 控件有没有真的生效。

Ran terminal command:  adb -s 70a91f89 shell 'ps -A | grep tinyplay_ftm'
Completed with input:  adb -s 70a91f89 shell 'ps -A | grep tinyplay_ftm'

Ran terminal command:  adb -s 70a91f89 shell 'LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix "WSA RX0 MUX" && LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix "WSA RX1 MUX" && LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix "WSA_RX0 INP0" && LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix "WSA_RX1 INP0" && LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix "WSA_COMP1 Switch" && LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix "WSA_COMP2 Switch" && LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix "WSA_RX INT0 VBAT WSA RX0 VBAT Enable" && LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/tinymix "WSA_RX INT1 VBAT WSA RX1 VBAT Enable"'

Ran terminal command:  adb -s 70a91f89 shell 'for d in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*; do echo ===$d===; cat $d/Speaker_Playback; cat $d/bias_level; done'
Completed with input:  adb -s 70a91f89 shell 'for d in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*; do echo ===$d===; cat $d/Speaker_Playback; cat $d/bias_level; done'

WSA 路由现在已经真的写进去了，但播放进程没有常驻，说明要么瞬间结束，要么仍在更上游失败。下一步我会把播放放到后台，再边播边看实际激活的控件和 ASoC 目录结构。

Ran terminal command:  adb -s 70a91f89 shell 'ls -1 /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0034 | head -n 80'

Ran terminal command:  adb -s 70a91f89 shell 'ls -1 /sys/kernel/debug/asoc/sun-mtp-snd-card | grep aw882xx | head -n 40'

Ran terminal command:  adb -s 70a91f89 shell 'setprop vendor.oplus.mm.ftm_spk 1; /odm/bin/tinyplay_ftm /odm/etc/oplus_ftm_smart_pa.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY'

Ran terminal command:  adb -s 70a91f89 shell 'ls -1 /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0034/dapm | head -n 80'

Ran terminal command:  adb -s 70a91f89 shell 'for d in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*; do echo ===$d===; grep -H . $d/dapm/* 2>/dev/null | grep -E "Speaker|bias"; done'

Awaited terminal completion

后台播放看起来没有立刻退出，我改成直接读具体 DAPM 文件和值，并同时确认 `tinyplay_ftm` 是否还活着。

Ran terminal command:  adb -s 70a91f89 shell 'ps -A | grep tinyplay_ftm'


# 第2章：WSA/SoundWire 排查与声卡 probe 时序修复

Read memory twrp_audio_component_gap.md

Read memory twrp_audio_wcd9378_gap.md

Read memory twrp_audio_aw882xx_frontier.md

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for n in rx_swr_ctrl wsa_swr_ctrl wsa2_swr_ctrl va_swr_ctrl bt_swr_mstr; do p=/sys/bus/platform/devices/soc:spf_core_platform:$n; echo ===$n===; [ -d "$p" ] || { echo missing; continue; }; echo driver:; readlink "$p/driver" 2>/dev/null || echo unbound; echo override:; cat "$p/driver_override" 2>/dev/null || true; echo of_node:; readlink "$p/of_node" 2>/dev/null || echo no_of_node; done'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for n in rx_swr_ctrl wsa_swr_ctrl wsa2_swr_ctrl va_swr_ctrl bt_swr_mstr; do p=/sys/bus/platform/devices/soc:spf_core_platform:$n/of_node; echo ===$n===; [ -d "$p" ] || { echo no_node; continue; }; for f in compatible reg qcom,swr-master-id qcom,swr-num-dev qcom,swr-port-mapping qcom,swr-version status; do printf "%s: " "$f"; if [ -f "$p/$f" ]; then cat "$p/$f" 2>/dev/null | xxd -p -c 256; else echo absent; fi; done; done'

User: 继续啊，我搞不懂你总是一半就停下来

GitHub Copilot: 我继续往下跑现场，不停在结论句上；这一步先把 `rx_swr_ctrl`、`wsa_swr_ctrl`、`wsa2_swr_ctrl` 的 live 属性、driver 绑定和最近错误并排拉平，结果要么落到 DT 输入差异，要么落到总线/硬件侧连不上。

Read memory twrp_audio_wcd9378_gap.md

Read memory twrp_audio_component_gap.md

Read memory twrp_audio_runtime_defer.md

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for n in rx_swr_ctrl wsa_swr_ctrl wsa2_swr_ctrl; do p=/sys/bus/platform/devices/soc:spf_core_platform:$n; echo ===$n===; [ -d "$p" ] || { echo missing; continue; }; echo driver:; readlink "$p/driver" 2>/dev/null || echo none; echo modalias:; cat "$p/modalias" 2>/dev/null || echo none; echo of_node:; readlink "$p/of_node" 2>/dev/null || echo none; echo status:; od -An -tx1 "$p/of_node/status" 2>/dev/null || echo none; echo qcom,swr-clock-stop-mode0:; od -An -tx4 "$p/of_node/qcom,swr-clock-stop-mode0" 2>/dev/null || echo none; echo qcom,swr-clock-stop-mode1:; od -An -tx4 "$p/of_node/qcom,swr-clock-stop-mode1" 2>/dev/null || echo none; echo qcom,swr-max-speed:; od -An -tx4 "$p/of_node/qcom,swr-max-speed" 2>/dev/null || echo none; echo qcom,swr_version:; od -An -tx4 "$p/of_node/qcom,swr-version" 2>/dev/null || od -An -tx4 "$p/of_node/qcom,swr_version" 2>/dev/null || echo none; done'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===drivers===; ls /sys/bus/platform/drivers | grep -E "swr|wsa|rx_swr|va_swr|bt_swr" | sed -n "1,120p"; echo ===devices===; ls /sys/bus/platform/devices | grep -E "swr|wsa" | sed -n "1,200p"; echo ===dmesg===; dmesg | grep -Ei "wsa(_| )swr|wsa2(_| )swr|rx_swr|swr link failed|swrm version|wcd9378|wsa883|wsa884" | tail -n 200'

刚才第一轮拿到了一个重要修正：这些节点在 `/sys/bus/platform/devices/` 下是裸名，不带 `soc:spf_core_platform:` 前缀，所以前一个属性抓取命中了错误路径。现在我按正确路径重抓绑定、of_node 和 SoundWire 实体，再做一次手工 probe 的前后对比。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for n in rx_swr_ctrl va_swr_ctrl wsa_swr_ctrl wsa2_swr_ctrl bt_swr_mstr; do p=/sys/bus/platform/devices/$n; echo ===$n===; [ -d "$p" ] || { echo missing; continue; }; echo driver=$(basename "$(readlink "$p/driver" 2>/dev/null)" 2>/dev/null || echo none); echo modalias=$(cat "$p/modalias" 2>/dev/null); echo of_node=$(readlink "$p/of_node" 2>/dev/null || echo none); echo status:; od -An -tc "$p/of_node/status" 2>/dev/null || echo none; echo swr-version:; od -An -tx4 "$p/of_node/qcom,swr-version" 2>/dev/null || od -An -tx4 "$p/of_node/qcom,swr_version" 2>/dev/null || echo none; echo max-speed:; od -An -tx4 "$p/of_node/qcom,swr-max-speed" 2>/dev/null || echo none; done; echo ===soundwire-devices===; ls /sys/bus/soundwire/devices 2>/dev/null | sed -n "1,200p"'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo before; for n in wsa_swr_ctrl wsa2_swr_ctrl; do p=/sys/bus/platform/devices/$n; echo ===$n===; readlink "$p/driver" 2>/dev/null || echo none; done; dmesg -c >/dev/null 2>&1; for n in wsa_swr_ctrl wsa2_swr_ctrl; do echo swr-mgr > /sys/bus/platform/devices/$n/driver_override 2>/dev/null; echo $n > /sys/bus/platform/drivers_probe 2>/dev/null; done; echo after; for n in wsa_swr_ctrl wsa2_swr_ctrl; do p=/sys/bus/platform/devices/$n; echo ===$n===; readlink "$p/driver" 2>/dev/null || echo none; done; echo ===new-dmesg===; dmesg | grep -Ei "wsa(_| )swr|wsa2(_| )swr|swr link failed|version|slave|connect|probe" | tail -n 120'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===components===; cat /sys/kernel/debug/asoc/components 2>/dev/null | grep -E "wsa|wcd9378|wcd939x|aw882xx|lpass-cdc"; echo ===dais===; cat /sys/kernel/debug/asoc/dais 2>/dev/null | grep -E "wsa|wcd9378|wcd939x|aw882xx|rx_macro|tx_macro|va_macro" | sed -n "1,200p"'

前沿已经实锤成两条现场证据，不是猜测了：`wsa_swr_ctrl/wsa2_swr_ctrl` 确实没绑 driver，手工 probe 后会稳定报 `version specified in dtsi: 0x2000000 not match with HW read version 0x2010000`，随后 `swr link failed to connect`；同时 SoundWire 设备列表里只有 `wcd939x` 和 BTFM，没有任何 `wsa883x/884x` 或 `wcd9378` slave。下一步不再盲试，我回到源码把这两个 WSA master 的 DT 输入定位出来，确认是不是就是版本值写死错了。

Searched for regex `wsa_swr_master|wsa2_swr_master|0x2000000|0x2010000|qcom,swr-mstr` (`**/device_tree/**/*.{dts,dtsi,txt,md}`), no results

Searched for regex `wsa_swr_master|wsa2_swr_master|0x2000000|0x2010000|qcom,swr-mstr` (`**/*.{dts,dtsi,h,md}`), 200 results

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for n in rx_swr_ctrl wsa_swr_ctrl wsa2_swr_ctrl; do p=/sys/bus/platform/devices/$n/of_node; echo ===$n===; for f in name compatible reg qcom,swr-port-mapping qcom,swr-num-dev qcom,swrm-io-base qcom,swr-clock-stop-mode0 qcom,swr-clock-stop-mode1 qcom,swr-version qcom,swr_version; do echo --$f--; x="$p/$f"; [ -e "$x" ] || { echo missing; continue; }; od -An -tx1 "$x" 2>/dev/null | sed -n "1,8p"; done; done'

现场又缩了一步：live DT 里 `wsa_swr_master`/`wsa2_swr_master` 节点本身并没有 `status=disabled`，而且 `qcom,swr-num-dev` 分别是 2 和 3，说明“节点压根没开”这条路可以先放掉。现在更像是节点开着，但总线那端没有任何 slave 实体响应。我去把离线 DTS 里的这两个 master 和对应 slave 配置翻出来，对照 `swr1/swr2/swr4` 当前只挂了 `wcd939x` 的现场。

Searched for regex `wsa_swr_master|wsa2_swr_master|rx_swr_master|qcom,swr-num-dev|qcom,swr-port-mapping` (`**/audio_dtb_probe/**/*.dts`), no results

Searched for regex `wsa_swr_master|wsa2_swr_master|rx_swr_master|qcom,swr-num-dev|qcom,swr-port-mapping` (`**/*.dts`), no results

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for d in /sys/bus/soundwire/devices/*; do [ -d "$d" ] || continue; echo ===$(basename "$d")===; for f in modalias status device_number mfg_id part_id class_id unique_id; do [ -e "$d/$f" ] && { printf "%s=" "$f"; cat "$d/$f"; }; done; [ -e "$d/slave_id" ] && { printf "slave_id="; cat "$d/slave_id"; }; done'
Completed with input:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for d in /sys/bus/soundwire/devices/*; do [ -d "$d" ] || continue; echo ===$(basename "$d")===; for f in modalias status device_number mfg_id part_id class_id unique_id; do [ -e "$d/$f" ] && { printf "%s=" "$f"; cat "$d/$f"; }; done; [ -e "$d/slave_id" ] && { printf "slave_id="; cat "$d/slave_id"; }; done'

离线 DTS 还没命中，说明这些节点更可能在更大的内核源码树或解包出来的 DT 产物里，不在我刚才扫的目录范围。下一步我扩大到整个工作区的 `.dtsi/.dts` 和已有的 DT 解包目录，同时把 live SoundWire 实体改成 `uevent` 方式读，避免空文件误导。

Searched for regex `wsa_swr_master|wsa2_swr_master|rx_swr_master|qcom,swr-mstr|qcom,swr-num-dev|qcom,swr-port-mapping` (`**/*.{dts,dtsi}`), no results

Searched for files matching `**/*wsa*master*`, no matches

Searched for files matching `**/audio_dtb_probe/**/dtbo*.dts`, no matches

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for d in /sys/bus/soundwire/devices/*; do [ -d "$d" ] || continue; echo ===$(basename "$d")===; cat "$d/uevent" 2>/dev/null; done'

这轮已经把总线拓扑说清了一半：`rx_swr_master -> wcd939x-rx-slave`，`va_swr_master -> wcd939x-tx-slave`，`bt_swr_mstr -> btfmswr-slave` 都是闭环的；唯独 `wsa_swr_master` 和 `wsa2_swr_master` 连 `swr` 总线实例都没长出来。下一步我直接看它们在 live DT 里各自声明了哪些子节点，以及 alias 是否缺位。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===aliases===; ls /sys/firmware/devicetree/base/aliases 2>/dev/null | grep -E "swr" | sed -n "1,80p"; for a in /sys/firmware/devicetree/base/aliases/swr*; do [ -e "$a" ] || continue; echo --$(basename "$a")--; od -An -tc "$a"; done; for n in rx_swr_ctrl va_swr_ctrl wsa_swr_ctrl wsa2_swr_ctrl; do p=/sys/bus/platform/devices/$n/of_node; echo ===children:$n===; find "$p" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sed -n "1,80p"; done'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for n in wsa_swr_ctrl wsa2_swr_ctrl; do p=/sys/bus/platform/devices/$n/of_node; echo ===$n===; for c in "$p"/*; do [ -d "$c" ] || continue; echo --child:$(basename "$c")--; [ -e "$c/name" ] && { printf name=; cat "$c/name"; }; [ -e "$c/compatible" ] && { printf compatible=; tr "\0" "|" < "$c/compatible"; echo; }; done; done'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for n in rx_swr_ctrl va_swr_ctrl wsa_swr_ctrl wsa2_swr_ctrl; do p=/sys/bus/platform/devices/$n/of_node; echo ===$n===; [ -e "$p/qcom,swr-num-dev" ] && { printf num-dev=; od -An -tu4 "$p/qcom,swr-num-dev"; }; [ -e "$p/qcom,swr-port-mapping" ] && { printf port-map-words=; wc -c < "$p/qcom,swr-port-mapping"; }; done'

这一步已经把 live DT 和 live 总线完全对上了：`swr0` 就是 `wsa_swr_master`，`swr3` 就是 `wsa2_swr_master`，而且它们下面明确声明了 `wsa883x`、`wsa884x` 以及 `swr_haptics` 子节点。也就是说现在不是“DT 没有声明 slave”，而是“slave 已声明但总线训练失败、一个都没枚举出来”。我去读之前那段成功样本，确认正常情况下这几条总线本该长成什么样。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#1160-1160), lines 1160 to 1215

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for n in wsa-macro wsa2-macro rx-macro va-macro; do p=/sys/bus/platform/devices/$n; echo ===$n===; [ -d "$p" ] || { echo missing; continue; }; echo driver=$(basename "$(readlink "$p/driver" 2>/dev/null)" 2>/dev/null || echo none); echo supplier-links:; find "$p" -maxdepth 1 -type l | sed -n "1,80p"; done'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for n in wsa_swr_ctrl wsa2_swr_ctrl; do p=/sys/bus/platform/devices/$n; echo ===$n===; echo driver_override=$(cat "$p/driver_override" 2>/dev/null); echo waiting_for_supplier=$(grep "$n" /sys/kernel/debug/devices_deferred 2>/dev/null || true); done'

又补到一条关键差异：`wsa-macro` / `wsa2-macro` 本体已经绑好了，但 `wsa_swr_ctrl` / `wsa2_swr_ctrl` 还躺在 `devices_deferred` 里。这说明失败层级就在 SWR master 自己，不是更上游 macro 没起。现在我直接把 deferred 原因和它们依赖的 pinctrl/clock 设备拎出来。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===devices_deferred===; grep -E "wsa_swr_ctrl|wsa2_swr_ctrl|rx_swr_ctrl|va_swr_ctrl|wsa_swr_clk_data_pinctrl|wsa2_swr_clk_data_pinctrl" /sys/kernel/debug/devices_deferred 2>/dev/null || cat /sys/kernel/debug/devices_deferred 2>/dev/null | tail -n 80'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for n in soc:spf_core_platform:wsa_swr_clk_data_pinctrl soc:spf_core_platform:wsa2_swr_clk_data_pinctrl soc:spf_core_platform:rx_swr_clk_data_pinctrl soc:spf_core_platform:tx_swr_clk_data_pinctrl; do p=/sys/bus/platform/devices/$n; echo ===$n===; [ -d "$p" ] || { echo missing; continue; }; echo driver=$(basename "$(readlink "$p/driver" 2>/dev/null)" 2>/dev/null || echo none); echo modalias=$(cat "$p/modalias" 2>/dev/null); done'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for n in wsa_swr_ctrl wsa2_swr_ctrl; do p=/sys/bus/platform/devices/$n; echo ===$n===; find "$p" -maxdepth 1 -type l | sed -n "1,120p"; done'

pinctrl 这一支也排除了：WSA 的 `clk_data_pinctrl` 已经和 RX/TX 一样绑到 `msm-cdc-pinctrl`，所以 `devices_deferred` 里只剩 WSA SWR master 自己，说明它不是卡在 supplier，而是 probe 里自己失败后被丢回 defer。现在我补读之前的正常系统对照段，看看当时正常系统到底比 recovery 多出来了什么。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#1215-1215), lines 1215 to 1275

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for n in swr0 swr1 swr2 swr3 swr4; do p=/sys/bus/soundwire/devices/$n; echo ===$n===; [ -d "$p" ] || { echo missing; continue; }; find "$p" -maxdepth 1 -type l | sed -n "1,80p"; [ -e "$p/uevent" ] && cat "$p/uevent"; done'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for n in wsa_swr_ctrl wsa2_swr_ctrl; do echo ===$n===; for f in /sys/kernel/debug/clk/*/enable_count; do :; done; done; ls /sys/kernel/debug/clk | grep -E "swr|wsa|rx|va" | sed -n "1,200p"'

现在最有价值的不是继续在 recovery 里猜，而是拿正常系统做一次现场对照，把 `swr0/swr3` 和 `wsa883x/884x` 在真机正常态下是否真的存在钉死。我要临时进一次系统抓最小对照，再回 recovery。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb reboot && sleep 8 && for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do echo ---$i---; adb devices; if adb devices | grep -E '\sdevice$' >/dev/null; then break; fi; sleep 3; done && adb devices

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'su -c "echo ===boot===; getprop ro.bootmode; echo ===soundwire===; ls /sys/bus/soundwire/devices | sed -n 1,200p; echo ===components===; cat /sys/kernel/debug/asoc/components | grep -E \"wsa|wcd9378|wcd939x|aw882xx|lpass-cdc\"; echo ===wsa-driver===; for n in wsa_swr_ctrl wsa2_swr_ctrl; do p=/sys/bus/platform/devices/\$n; echo ---\$n---; readlink \$p/driver 2>/dev/null || echo none; done; echo ===cards===; cat /proc/asound/cards"'

正常系统现场把 WSA 这条支线直接打掉了：系统里也没有 `swr0/swr3`，也没有 `wsa_swr_ctrl/wsa2_swr_ctrl` driver 绑定，但声卡照样正常注册。也就是说，我刚才追的 WSA/SWR 不是 recovery 主根因，这条线现在可以正式收口。趁还在系统里，我直接抓 `sound` 设备绑定和它下面展开出来的子图，再回 recovery 对照真正差异。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'su -c "mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; echo ===sound-driver===; readlink /sys/bus/platform/devices/soc:spf_core_platform:sound/driver 2>/dev/null || echo none; echo ===sound-children===; find /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound -maxdepth 1 -mindepth 1 | sed -n 1,120p; echo ===pcm===; cat /proc/asound/pcm | sed -n 1,120p; echo ===deferred===; cat /sys/kernel/debug/devices_deferred 2>/dev/null | tail -n 80"'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb reboot recovery && sleep 8 && for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do echo ---$i---; adb devices; if adb devices | grep -E '\srecovery$' >/dev/null; then break; fi; sleep 3; done && adb devices

系统对照已经抓到了，里面最关键的是：正常系统同样没有 WSA 这组总线，但 `sound` 绑定正常、PCM 全量存在，所以 WSA 前沿已经被实机否掉。现在我先把系统对照读出来，再判断设备回 recovery 的启动阶段。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_iR9ZHMGQwwM7luIHrexjlqko__vscode-1773949051738/content.txt)

这次系统对照已经把主线完全改写了：正常系统里 `devices_deferred` 也同样挂着 `wsa_swr_ctrl` 和 `wsa2_swr_ctrl`，但 `sun-asoc-snd` 依然成功绑定，整张卡和完整 PCM 仍然都在。所以 WSA defer 现在可以从“主嫌疑”降成“背景噪音”。真正差异回到了 `sound` 本体没有接管这件事上。先把设备拉回 recovery，再对着系统里那张 PCM 清单查 recovery 到底缺到哪一段。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do echo ---$i---; adb devices; fastboot devices; sleep 3; done

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb reboot recovery 2>/dev/null || true; sleep 6; for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do echo ---retry:$i---; adb devices; if adb devices | grep -E '\srecovery$' >/dev/null; then break; fi; fastboot devices; sleep 3; done && adb devices

设备刚才已经在 recovery 里稳定出现过，第二轮是我重复下发了 `adb reboot recovery`，现在只是又进入了一次重启窗口，不是新的故障。等它重新回到 `recovery` 后，我直接抓 `sound` 子图、`/proc/asound/pcm` 和 `cards`，对照系统里那张清单查出缺口。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do echo ---$i---; adb devices; if adb devices | grep -E '\srecovery$' >/dev/null; then break; fi; fastboot devices; sleep 3; done && adb devices

User: 你又在空转

GitHub Copilot: 我不再复述前情，直接抓当前现场的 `adb/fastboot`、声卡枚举和 `sound` 绑定，结果要么把缺口落到 `sun-asoc-snd` 没接管，要么落到更下游的 PCM/card 生成失败。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb devices -l && fastboot devices

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'getprop ro.bootmode 2>/dev/null; getprop init.svc.vendor.audio-hal-manual 2>/dev/null; cat /proc/asound/cards 2>/dev/null; echo ===pcm===; cat /proc/asound/pcm 2>/dev/null; echo ===sound===; ls -l /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound 2>/dev/null; echo ===asoc===; ls /sys/kernel/debug/asoc 2>/dev/null'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'dmesg | grep -Ei "sun-asoc-snd|asoc|snd_soc|wcd|lpass|spf|sound card|audio" | tail -n 200'

设备已经在 recovery，我现在把刚才那份大日志读出来，同时补一次更小的 `cards/pcm` 抓取，避免被空输出误导；这一步结束后我会给出具体断点，不再停在泛化判断。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_n7X6Y2G5xxMtLWpMVixmA3DZ__vscode-1773949840427/content.txt)

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo BOOT=$(getprop ro.bootmode); echo HAL=$(getprop init.svc.vendor.audio-hal-manual); echo ===cards===; cat /proc/asound/cards; echo ===pcm===; cat /proc/asound/pcm; echo ===sound_dir===; ls -ld /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound; echo ===asoc_dir===; ls /sys/kernel/debug/asoc'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'find /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound -maxdepth 2 -type f 2>/dev/null | sed -n "1,120p"'

现在断点已经具体了：不是 HAL 没起，也不是 `sound` 节点不存在，而是 `sun-asoc-snd`

User: @agent Try Again

GitHub Copilot: 现在不是空转了，断点已经缩到一个具体对象：`sun-asoc-snd` 在 probe 时反复报 `CODEC DAI rx_macro_rx1 not registered`，所以我直接围绕 `rx_macro` 抓组件、DAI、defer 和驱动绑定。

Read memory twrp_audio_component_gap.md

Read memory twrp_audio_wcd9378_gap.md

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===components===; sed -n "1,200p" /sys/kernel/debug/asoc/components; echo ===dais===; sed -n "1,240p" /sys/kernel/debug/asoc/dais'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===deferred===; cat /sys/kernel/debug/devices_deferred 2>/dev/null; echo ===rx_macro_dev===; ls -l /sys/bus/platform/devices | grep -E "rx.*macro|lpass.*rx" || true; echo ===rx_macro_drv===; ls -l /sys/bus/platform/drivers | grep -E "rx.*macro|lpass.*rx" || true'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'dmesg | grep -Ei "rx_macro|lpass_cdc_rx_macro|CODEC DAI rx_macro_rx1|wcd9378|wcd939x" | tail -n 200'

现场已经收紧成一句话：`sound` 之所以一直 defer，不是整卡没起来，而是 `rx_macro_rx1` 这条 DAI 根本没注册出来；我现在只追 `rx-macro` 这一支的 driver 绑定和缺失原因。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_UG6BINEGqxxtZePtVM24Vf8j__vscode-1773949840435/content.txt)

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===rx-macro===; ls -l /sys/bus/platform/devices/rx-macro; ls -l /sys/bus/platform/devices/rx-macro/driver 2>/dev/null; cat /sys/bus/platform/devices/rx-macro/modalias 2>/dev/null; echo ===rx_swr_ctrl===; ls -l /sys/bus/platform/devices/rx_swr_ctrl; ls -l /sys/bus/platform/devices/rx_swr_ctrl/driver 2>/dev/null; cat /sys/bus/platform/devices/rx_swr_ctrl/modalias 2>/dev/null'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for f in compatible status qcom,version qcom,swr-num-dev qcom,lpass-cdc-version; do echo ===$f===; od -An -tx1 -v /sys/bus/platform/devices/rx-macro/of_node/$f 2>/dev/null || true; od -An -tx1 -v /sys/bus/platform/devices/rx_swr_ctrl/of_node/$f 2>/dev/null || true; done'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'grep -R "rx_macro_rx1\|lpass_cdc_rx_macro\|rx-macro" /sys/kernel/debug 2>/dev/null | sed -n "1,200p"'
Completed with input:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'grep -R "rx_macro_rx1\|lpass_cdc_rx_macro\|rx-macro" /sys/kernel/debug 2>/dev/null | sed -n "1,200p"'

现在确认了两件硬事实：`rx-macro` 和 `rx_swr_ctrl` 都已经正常绑到 driver，不是“设备没起来”；但 `asoc/dais` 里就是没有任何 `rx_macro_*`，所以问题落在 `lpass_cdc_rx_macro` probe 之后的内部注册分支。下一步我回源码和日志里找这条分支为什么不出 DAI。

Searched for regex `rx_macro_rx1|Could not find RX/TX swr slave device|lpass_cdc_rx_macro|qcom,lpass-cdc-rx-macro` (`**/*.{c,h,dts,dtsi,md,txt}`), 10 results

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===swr_devices===; ls -l /sys/bus/soundwire/devices; echo ===swr_rx===; for d in /sys/bus/soundwire/devices/*; do [ -d "$d" ] || continue; echo ---$(basename "$d")---; cat "$d/modalias" 2>/dev/null; cat "$d/status" 2>/dev/null; done'
Completed with input:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===swr_devices===; ls -l /sys/bus/soundwire/devices; echo ===swr_rx===; for d in /sys/bus/soundwire/devices/*; do [ -d "$d" ] || continue; echo ---$(basename "$d")---; cat "$d/modalias" 2>/dev/null; cat "$d/status" 2>/dev/null; done'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'dmesg | grep -Ei "swr.*slave|rx.*swr|lpass.*rx.*macro|wcd9378.*slave|wcd939x.*slave|Could not find RX/TX swr slave device|Codec registration failed" | tail -n 200'
Completed with input:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'dmesg | grep -Ei "swr.*slave|rx.*swr|lpass.*rx.*macro|wcd9378.*slave|wcd939x.*slave|Could not find RX/TX swr slave device|Codec registration failed" | tail -n 200'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:lpass-cdc/rx-macro/uevent; echo ===rxswr===; cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:lpass-cdc/rx-macro/rx_swr_ctrl/uevent'
Completed with input:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:lpass-cdc/rx-macro/uevent; echo ===rxswr===; cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:lpass-cdc/rx-macro/rx_swr_ctrl/uevent'

设备刚才从 adb 枚举里掉了，这不是结论点；我先按你的规则用轮询把它现在所处阶段抓出来，再接着打 `rx_macro`，不使用 `adb wait-for-device`。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && for i in 1 2 3 4 5 6 7 8 9 10; do echo ---$i---; adb devices -l; fastboot devices; sleep 2; done

Ran terminal command:  system_profiler SPUSBDataType | grep -E 'OPD2413|OnePlus|QUSB|Qualcomm|Android|Fastboot' | tail -n 80

User: ➜  ~ adb devices
List of devices attached
70a91f89	recovery

➜  ~ 


GitHub Copilot: 设备已经回到 `recovery`，我直接抓 `rx-macro` 这条支线的现场和源码落点，目标是判断它是“driver 已绑但 DAI 没注册”，还是“probe 里被某个条件短路”。

Searched for regex `rx_macro_rx1|lpass_cdc_rx_macro|CODEC DAI rx_macro_rx1 not registered|rx-macro` (`**/*.{c,cpp,h,dts,dtsi,md}`), 15 results

Read memory twrp_audio_component_gap.md

Read memory twrp_audio_wcd9378_gap.md

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===devices===; ls -l /sys/bus/platform/devices/rx-macro /sys/bus/platform/devices/rx_swr_ctrl 2>/dev/null; echo ===drivers===; readlink /sys/bus/platform/devices/rx-macro/driver 2>/dev/null; readlink /sys/bus/platform/devices/rx_swr_ctrl/driver 2>/dev/null; echo ===asoc_components===; cat /sys/kernel/debug/asoc/components 2>/dev/null | grep -Ei "rx|wcd|macro|lpass"; echo ===asoc_dais===; cat /sys/kernel/debug/asoc/dais 2>/dev/null | grep -Ei "rx|wcd|macro|lpass"'

Search complete: 定位 rx_macro 注册路径

Searched for regex `lpass_cdc_rx_macro|rx_macro_rx1|wcd9378|bolero|rx macro variant|CODEC DAI .*not registered|not registered` (`**/*.{c,h,cpp,cc,txt,md,dtsi,dts,Kconfig,Makefile}`), 200 results

Searched for files matching `**/*rx*macro*`, no matches

Searched for files matching `**/*bolero*`, no matches

Searched for files matching `**/*wcd9378*`, no matches

Searched for text `lpass_cdc_rx_macro` (`**/*.{c,h,Makefile,Kconfig}`), no results

Searched for text `rx_macro_rx1` (`**/*.{c,h,dtsi,dts}`), no results

Searched for regex `qcom,wcd9378-codec|wcd9378_cdc|wcd939x_cdc|bolero` (`**/*.{c,h,dtsi,dts}`), no results

Searched for files matching `**/sound/**/*.c`, 2 matches

Searching for text `lpass_cdc_rx_macro`

Searching for text `rx_macro_rx1`

Searching for regex `wcd9378_cdc|wcd939x_cdc|bolero|qcom,wcd9378-codec`

Searched for files matching `**/vendor/**/audio*`, 1 match

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#1628-1628), lines 1628 to 1715

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#1908-1908), lines 1908 to 1995

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#2120-2120), lines 2120 to 2220

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#2398-2398), lines 2398 to 2420

当前现场已经纠偏了一个关键点：`rx_macro_rx1` 现在其实已经在 `asoc/dais` 里，不是“根本没注册”；真正异常变成了 `sound` 已绑定/存在、`dais` 已有，但 `/proc/asound/cards` 仍是空。下一步我直接查 `devices_deferred`、`sound` 的绑定状态，并手工重放一次 `probe_sound` 看它会不会补出声卡。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===sound_driver===; readlink /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver 2>/dev/null; echo ===uevent===; cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/uevent 2>/dev/null; echo ===deferred===; cat /sys/kernel/debug/devices_deferred 2>/dev/null | grep -Ei "sound|rx|macro|wcd|hdmi|display|spf|lpass"'
Completed with input:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===sound_driver===; readlink /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver 2>/dev/null; echo ===uevent===; cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/uevent 2>/dev/null; echo ===deferred===; cat /sys/kernel/debug/devices_deferred 2>/dev/null | grep -Ei "sound|rx|macro|wcd|hdmi|display|spf|lpass"'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 2; echo ===cards===; cat /proc/asound/cards 2>/dev/null; echo ===pcm===; cat /proc/asound/pcm 2>/dev/null; echo ===dmesg===; dmesg | tail -n 120 | grep -Ei "sun-asoc-snd|snd_soc|asoc|sound card|rx_macro_rx1|wcd|display"'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===components===; cat /sys/kernel/debug/asoc/components 2>/dev/null; echo ===dais_tail===; cat /sys/kernel/debug/asoc/dais 2>/dev/null | tail -n 80'

现场已经拿到根因级差异：不是组件缺失，而是自动路径没有把“组件全部到位后的 `sound` 重 probe”做实；手工 `drivers_probe` 一次，声卡和 PCM 立刻全出来。现在我回到自动脚本，把时序和 `probe_sound` 触发点钉死，然后直接改。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/device_tree/twrp_device_oplus_ossi_source_built/recovery/root/system/bin/twrp-audio-autoload.sh)

Searched for regex `probe_sound|drivers_probe|twrp.modules.loaded|hdmi_dlkm|rfkill|btpower|audio-hal-manual` (`**/device_tree/twrp_device_oplus_ossi_source_built/recovery/root/**/*`), 15 results

断点已经够具体，没必要再扩散到别的支线了：自动脚本只做了一次早期 `probe_sound`，而现场证明晚一点再 probe 一次就能把卡补出来。我再补一条启动触发和 live 日志，然后直接改成带重试的 `probe_sound`。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/device_tree/twrp_device_oplus_ossi_source_built/recovery/root/init.recovery.qcom.rc)

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'grep -n "twrp-audio-autoload\|cards:\|deferred:" /tmp/recovery.log | tail -n 80'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'cat /proc/asound/cards; echo ===rerun===; /system/bin/sh /system/bin/twrp-audio-autoload.sh >/dev/null 2>&1; sleep 3; cat /proc/asound/cards; echo ===log_tail===; grep -n "speaker mixer baseline applied\|cards:\|audio autoload" /tmp/recovery.log | tail -n 40'

我现在做的是最小、直接对应现场差异的修复：不给自动路径再猜别的依赖，只把 `sound` 的重 probe 做成带重试，直到卡真正出现，再去做 mixer baseline。

Generating patch (53 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/device_tree/twrp_device_oplus_ossi_source_built/recovery/root/system/bin/twrp-audio-autoload.sh)


```

```
补丁已经落下，逻辑很窄：自动脚本现在会明确检查 `/proc/asound/cards`，卡没出来就重复 `probe_sound`，而不是像之前那样一枪打完。下一步我先做静态错误检查，然后直接按同样的注入/刷写路径把这个修复刷到机上复测。

Checked [](file:///Volumes/Case-sensitive%20APFS/TWRP/device_tree/twrp_device_oplus_ossi_source_built/recovery/root/system/bin/twrp-audio-autoload.sh), no problems found

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && sh -n device_tree/twrp_device_oplus_ossi_source_built/recovery/root/system/bin/twrp-audio-autoload.sh

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP/verify_recovery_soundtrigger_20260320 && cp recovery_a_stock.img recovery_a_autoloadfix.img && /Volumes/Case-sensitive\ APFS/TWRP/magiskboot unpack -h recovery_a_autoloadfix.img >/dev/null && cp ramdisk.cpio ramdisk.cpio.autoloadfix.bak && /Volumes/Case-sensitive\ APFS/TWRP/magiskboot cpio ramdisk.cpio 'add 0755 system/bin/twrp-audio-autoload.sh ../device_tree/twrp_device_oplus_ossi_source_built/recovery/root/system/bin/twrp-audio-autoload.sh' && /Volumes/Case-sensitive\ APFS/TWRP/magiskboot cpio ramdisk.cpio 'add 0755 vendor/etc/vintf/manifest/soundtrigger.qti.xml ../device_tree/twrp_device_oplus_ossi_source_built/recovery/root/vendor/etc/vintf/manifest/soundtrigger.qti.xml' && /Volumes/Case-sensitive\ APFS/TWRP/magiskboot repack recovery_a_autoloadfix.img recovery_a_autoloadfix_patched.img && shasum -a 256 recovery_a_autoloadfix_patched.img

镜像已经重新打好，新的改动只有两类：保留之前已验证命中的 `soundtrigger` fragment，再加上 `autoload` 的声卡重试逻辑。现在我直接刷这个新镜像，并在冷启动后先验证“不手工干预时 cards 是否自动出来”，再看播放器状态。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb reboot bootloader && sleep 3 && for i in 1 2 3 4 5 6 7 8 9 10; do fastboot devices; if fastboot devices | grep -q .; then break; fi; sleep 2; done && fastboot flash recovery_a verify_recovery_soundtrigger_20260320/recovery_a_autoloadfix_patched.img && fastboot reboot recovery

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do echo ---$i---; adb devices; if adb devices | grep -E '\srecovery$' >/dev/null; then break; fi; sleep 2; done

镜像已刷入，当前只是在等待重启窗口结束；我继续同时轮询 `adb` 和 `fastboot`，一旦设备回到 `recovery` 就立刻验证这次是否还需要手工 `probe_sound`。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && for i in 1 2 3 4 5 6 7 8 9 10 11 12; do echo ---$i---; adb devices -l; fastboot devices; sleep 3; done

Ran terminal command:  system_profiler SPUSBDataType | grep -E 'OPD2413|OnePlus|QUSB|Qualcomm|Android|Fastboot' | tail -n 80

还没出现任何 USB 枚举，这已经超过正常 recovery 回来时间了；我再做一轮更长等待和主机侧 USB 枚举检查，若仍然完全不可见，就不是脚本逻辑问题而是设备当前没向主机暴露接口。

Ran terminal command:  for i in 1 2 3 4 5 6 7 8 9 10; do echo ---$i---; adb devices; fastboot devices; sleep 6; done

Made changes.

User: ➜  ~ adb devices
List of devices attached
70a91f89	recovery

不是你直接用这个不行吗

GitHub Copilot: 对，直接用 `adb` 就行，不需要再等主机侧别的枚举。现在我直接验证这次刷进去的自动修复有没有生效：先看冷启动后声卡是不是已经自动出来，再决定要不要继续追播放器。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo BOOT=$(getprop ro.bootmode); echo HAL=$(getprop init.svc.vendor.audio-hal-manual); echo ===cards===; cat /proc/asound/cards 2>/dev/null; echo ===pcm_head===; cat /proc/asound/pcm 2>/dev/null | sed -n "1,20p"; echo ===autoload_log===; grep -n "sound card ready\|sound card still missing\|sound card not ready\|audio autoload" /tmp/recovery.log 2>/dev/null | tail -n 80'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell '/data/local/tmp/agm_audio_minimal_bin --play-seconds 10 --tone-hz 440'
Completed with input:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell '/data/local/tmp/agm_audio_minimal_bin --play-seconds 10 --tone-hz 440'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend --play-after-open --play-seconds 10'
Completed with input:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend --play-after-open --play-seconds 10'

自动修复这次已经命中了：现在冷启动后不用手工 `probe_sound`，`cards` 和整套 `pcm` 已经自己出来了。下一步我不再回头碰 autoload，直接看新的前沿，也就是 `card100`/MFC 这条链为什么仍然在 `getTaggedInfo/miid` 阶段报 `-19`。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_I8pAyhwrINZYVcdr47i5KzB4__vscode-1773951028515/content.txt)

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'ps -A | grep audiohalservice.qti; getprop init.svc_debug_pid.vendor.audio-hal-manual; dmesg | grep -Ei "failed to register Interface|soundtrigger3|IAGM/default|IPAL/default|IModule/default|IConfig/default|IFactory/default|audiohalservice" | tail -n 120'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'tinymix_stock | grep -E "PCM100|TDM-LPAIF-RX-SECONDARY|getTaggedInfo|setParamTag|setParam|connect" | sed -n "1,120p"'

新的断点也很具体了：不是播放器自己坏，而是现在连 `tinymix_stock` 枚举关键控件都会打出 `Failed to mixer_ctl_get_array`。这说明 `mixer_ctl_get_array` 失败已经从 `card100` 扩大到了当前 mixer 访问层本身，我接着把它缩成“哪一个控件/哪一种控件类型在 recovery 里读不出来”。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'tinymix_stock "PCM100 control"; tinymix_stock "PCM100 connect"; tinymix_stock "PCM100 getTaggedInfo"; tinymix_stock "TDM-LPAIF-RX-SECONDARY rate ch fmt"; tinymix_stock "TDM-LPAIF-RX-SECONDARY setParam"'
Completed with input:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'tinymix_stock "PCM100 control"; tinymix_stock "PCM100 connect"; tinymix_stock "PCM100 getTaggedInfo"; tinymix_stock "TDM-LPAIF-RX-SECONDARY rate ch fmt"; tinymix_stock "TDM-LPAIF-RX-SECONDARY setParam"'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for name in "PCM100 control" "PCM100 connect" "PCM100 metadata" "PCM100 setParam" "PCM100 setParamTag" "PCM100 getTaggedInfo" "TDM-LPAIF-RX-SECONDARY rate ch fmt" "TDM-LPAIF-RX-SECONDARY metadata" "TDM-LPAIF-RX-SECONDARY setParam"; do echo ===$name===; tinymix_stock "$name" 2>&1 || true; done'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'dmesg | grep -Ei "mixer_ctl_get_array|agm_mixer|agm_pcm|tinymix|tinyalsa|audiohalservice|agm" | tail -n 120'

`PCM100` 这组名字本来就不在 card0，刚才那轮把范围缩清了：外部 `tinymix_stock` 读不到这些控件是预期，不是新故障。真正还没解释的是“进程内 plugin card100 为什么一到 `getTaggedInfo/miid` 就返回 `-19`”，我现在直接把 `audiohalservice.qti` 切到手工前台日志模式，边跑播放器边抓它的实时输出。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===fds===; ls -l /proc/900/fd/1 /proc/900/fd/2 2>/dev/null; echo ===env===; tr "\0" "\n" < /proc/900/environ | grep -E "^LD_LIBRARY_PATH=|^LD_CONFIG_FILE="'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'setprop ctl.stop vendor.audio-hal-manual; sleep 2; export LD_LIBRARY_PATH=/mnt/real_system/system/lib64:/system/lib64:/vendor/lib64:/vendor/lib64/hw; export LD_CONFIG_FILE=/system/etc/ld.config.txt; /vendor/bin/hw/audiohalservice.qti >/data/local/tmp/audiohalservice.manual.log 2>&1 & echo $! > /data/local/tmp/audiohalservice.manual.pid; sleep 5; cat /data/local/tmp/audiohalservice.manual.pid; ps -A | grep audiohalservice.qti || true'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell '/data/local/tmp/agm_audio_minimal_bin --play-seconds 10 --tone-hz 440 >/data/local/tmp/agm_audio_minimal.run.log 2>&1; echo ===player_exit:$?===; tail -n 120 /data/local/tmp/agm_audio_minimal.run.log; echo ===hal_log===; tail -n 200 /data/local/tmp/audiohalservice.manual.log'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'manual_pid=$(cat /data/local/tmp/audiohalservice.manual.pid 2>/dev/null); if [ -n "$manual_pid" ]; then kill $manual_pid 2>/dev/null || true; fi; setprop ctl.start vendor.audio-hal-manual; sleep 3; ps -A | grep audiohalservice.qti || true'

服务端前台日志这条路价值已经跑完了：`audiohalservice.qti` 本身没有吐出更深的错误，失败点仍然留在客户端 `libagm_mixer_plugin` 的 `mixer_ctl_get_array`。我现在换到更贴近 AGM 语义的路径，直接用仓库里已有的 `agmmixer`/文档线索对照 `PCM100` 这组控件应该怎样出现。

Searched for regex `agmmixer|PCM100|getTaggedInfo|setParamTag|TDM-LPAIF-RX-SECONDARY` (`**/*.{md,c,cpp,h,sh,txt}`), 200 results

Searched for files matching `**/agmmixer*`, no matches

Read memory twrp_audio_agmmixer_helper_semantics.md

Read memory twrp_audio_pcm100_setparamtag.md

接下来不该再用我们自己的最小 demo 盯死了，因为文档里已经有一条更接近真机主路径的基线：`tinyplay_ftm` 和原厂 `agmplay`。现在声卡已自动起来，我直接跑这两条原厂路径，看是“原厂路径恢复、我们的 demo 还差序列”，还是整个 AGM 图仍然没起来。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /odm/bin/tinyplay_ftm /data/local/tmp/test440_mid_10s.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell '/vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY -dkv 0xA2000001 -ikv 1 -skv 0xA100000E -dppkv 0xAC000002'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'dmesg | tail -n 200 | grep -Ei "tinyplay_ftm|agmplay|PCM100|set_aif_ses_metadata|set_params failed|amp_pcm|aw882xx|audio route|mfc|getTaggedInfo"'

这轮已经不是小进展了：原厂 `agmplay` 现在明显越过了我们自己 demo 卡住的 `post-connect MFC failed`，已经进到 `Playing sample` 阶段。接下来我先把这个变成硬证据，测它实际跑了多久、Awinic 是否整段保持工作，再决定是追“还只有 1 秒可闻”，还是直接反推我们 demo 少了哪段原厂前置。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'before=$(date +%s); setprop vendor.oplus.mm.ftm_spk 1; /vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY -dkv 0xA2000001 -ikv 1 -skv 0xA100000E -dppkv 0xAC000002 >/data/local/tmp/agmplay.stock.log 2>&1; rc=$?; after=$(date +%s); echo rc=$rc elapsed=$((after-before)); tail -n 120 /data/local/tmp/agmplay.stock.log'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'before=$(date +%s); setprop vendor.oplus.mm.ftm_spk 1; /odm/bin/tinyplay_ftm /data/local/tmp/test440_mid_10s.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY >/data/local/tmp/tinyplay_ftm.stock.log 2>&1; rc=$?; after=$(date +%s); echo rc=$rc elapsed=$((after-before)); tail -n 120 /data/local/tmp/tinyplay_ftm.stock.log'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'dmesg | grep -Ei "aw882xx_startup|aw882xx_hw_params|aw882xx_start_pa|aw882xx_monitor_start|aw882xx_mute|aw882xx_shutdown|agmplay|tinyplay_ftm" | tail -n 120'

现在已经确认原厂两条路径都能稳定跑满 10 秒，说明自动声卡修复把 recovery 拉回到了“原厂用户态可用”的阶段。最后我把 Awinic 生命周期也读出来，然后下一步就不再怀疑 recovery 基础环境，而是直接回到“我们的 demo 少了哪段原厂前置链”。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_8AkCiag3vHUnaUZ3jG3aSri5__vscode-1773951028535/content.txt)

现在可以正式下结论：recovery 基础环境这条主线已经修通了。原厂 `agmplay`、`tinyplay_ftm` 都能稳定跑满 10 秒，Awinic 生命周期也完整跟了 10 秒；还没过线的只剩我们自己的 demo。下一步我不再追 recovery 环境，而是直接对照原厂 `agmplay/tinyplay_ftm` 的用户态准备链，找出我们 demo 少掉的那一段。

Searched for regex `tinyplay_ftm|agmplay|Instance key is added|Backend TDM-LPAIF-RX-SECONDARY rate ch bit fmt|pcm_plug_open` (`**/*.{c,cpp,h,md,txt,log}`), 200 results

Searched for files matching `**/*tinyplay*ftm*`, 3 matches

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#4080-4080), lines 4080 to 4170

比对原厂成功路径

Searched codebase for "tinyplay_ftm agmplay Instance key is added getTaggedInfo miid pcm_open card100 success path strace disassembly documentation", 12 results

Searched for regex `tinyplay_ftm|agmplay|agm_audio_minimal|pure_c_agm_probe|Instance key is added|getTaggedInfo|miid|pcm_open\(card100\)|pcm_open\(.*100`, 200 results

Searched for files matching `**/*{tinyplay_ftm,agmplay,agm_audio_minimal,pure_c_agm_probe}*`, 14 matches

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3325-3325), lines 3325 to 3350

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3490-3490), lines 3490 to 3518

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#4036-4036), lines 4036 to 4175

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#4177-4177), lines 4177 to 4210

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#4210-4210), lines 4210 to 4255

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/strace_tinyplay_open_20260318.txt#1660-1660), lines 1660 to 1715

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#1-1), lines 1 to 250

Searching for regex `getTaggedInfo|agm_mixer_get_miid|set_agm_stream|pcm_open\(|plugin-first|Instance key|TDM-LPAIF-RX-SECONDARY|devicepp_kv|stream_kv|a100000e|a2000001|ac000002` (`**/video_player/agm_audio_minimal.c`)

Searching for regex `getTaggedInfo|agm_mixer_get_miid|pcm_open\(|plugin-first|Instance key|TDM-LPAIF-RX-SECONDARY|devicepp_kv|stream_kv|a100000e|a2000001|ac000002` (`**/video_player/pure_c_agm_probe.c`)

Searching for regex `getTaggedInfo|agm_mixer_get_miid|pcm_open\(|plugin-first|Instance key|TDM-LPAIF-RX-SECONDARY|devicepp_kv|stream_kv|a100000e|a2000001|ac000002` (`**/video_player/agm_audio_minimal_main.c`)

User: 随时更新文档docs/TWRP音频手动Bring-up-续.md

我现在没有听到任何声音

GitHub Copilot: 我按你现在的主观结果继续，不假设“已经有声”；先把当前 recovery 里的声卡、原厂播放链和我们自己的 demo 三条路径并排实测，再把新事实追加到续文档末尾。

Searched for regex `agmplay|tinyplay_ftm|tinymix_stock|play-test|播放 10 秒|10 秒` (`**/docs/**/*.md`), 200 results

Searched for files matching `**/*{agmplay,tinyplay_ftm,tinymix_stock}*`, 7 matches

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===cards===; cat /proc/asound/cards; echo ===pcm===; cat /proc/asound/pcm; echo ===hal===; getprop init.svc.vendor.audio-hal-manual; ps -A | grep audiohalservice.qti || true'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for f in /data/local/tmp/agmplay /data/local/tmp/tinyplay_ftm /system/bin/tinymix_stock /system/bin/agmplay /system/bin/tinyplay_ftm /vendor/bin/agmplay; do [ -e "$f" ] && ls -l "$f"; done'

基础环境已经确认，但这不等于“有声音”；我现在直接跑原厂 `tinyplay_ftm` 和 agmplay，并同步抓 Awinic/ASoC 日志，判断它们是“真成功但你听不到”，还是“高层返回看似正常但后段根本没点亮”。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for f in /odm/etc/oplus_ftm_smart_pa.wav /data/local/tmp/test440_low.wav /data/local/tmp/test440_mid_10s.wav /data/local/tmp/test.wav; do [ -f "$f" ] && ls -l "$f"; done'
Completed with input:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for f in /odm/etc/oplus_ftm_smart_pa.wav /data/local/tmp/test440_low.wav /data/local/tmp/test440_mid_10s.wav /data/local/tmp/test.wav; do [ -f "$f" ] && ls -l "$f"; done'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'dmesg -c >/dev/null 2>&1; setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/tinyplay_ftm /odm/etc/oplus_ftm_smart_pa.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY; echo ===rc:$?===; dmesg | grep -Ei "aw882xx|sun-asoc-snd|graph_open|graph_start|tinyplay_ftm|pcm|rx_macro|wcd" | tail -n 200'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'dmesg -c >/dev/null 2>&1; /vendor/bin/agmplay /odm/etc/oplus_ftm_smart_pa.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY; echo ===rc:$?===; dmesg | grep -Ei "aw882xx|agm|graph_open|graph_start|pcm|rx_macro|wcd" | tail -n 200'

新事实已经很硬了：agmplay 表面返回 `0`，但 Awinic 明确没有 `start success`，而是六路都报 `dev can not allow power`，这和“完全没声音”是一致的。我继续只盯这个前沿，不再泛化到别的路径。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'dmesg -c >/dev/null 2>&1; setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/tinyplay_ftm /odm/etc/oplus_ftm_smart_pa.wav; echo ===rc:$?===; dmesg | grep -Ei "aw882xx|tinyplay_ftm|graph_open|graph_start|pcm|wcd" | tail -n 200'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===aw===; /system/bin/tinymix_stock | grep -E "aw882xx_|aw_dev_[0-9]+_(prof|switch|monitor|volume)" | sed -n "1,120p"; echo ===wsa===; /system/bin/tinymix_stock | grep -E "WSA |WSA2 |Speaker_Mute_Switch" | sed -n "1,120p"'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'ls -l /system/bin/twrp-audio-play-test.sh /system/bin/twrp-audio-autoload.sh 2>/dev/null; sed -n "1,240p" /system/bin/twrp-audio-play-test.sh 2>/dev/null'

当前最像根因的不是 AGM graph，而是功放前级状态没真正被推到可上电：`aw_dev_*_switch` 现在全是 `Disable`。我直接用 recovery 里的标准播放脚本重跑一次，因为它会先做 `wait_for_audio_ready + mixer baseline`，这比裸调播放器更接近你实际使用路径。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'dmesg -c >/dev/null 2>&1; /system/bin/twrp-audio-play-test.sh tinyplay_ftm; echo ===rc:$?===; echo ===aw_after===; /system/bin/tinymix_stock | grep -E "aw_dev_[0-9]+_(switch|prof|monitor|volume)|aw882xx_(rx|tx|copp)_switch" | sed -n "1,120p"; echo ===dmesg===; dmesg | grep -Ei "aw882xx|tinyplay_ftm|graph_open|graph_start|pcm|wcd" | tail -n 200'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'dmesg -c >/dev/null 2>&1; /system/bin/twrp-audio-play-test.sh agmplay; echo ===rc:$?===; echo ===aw_after===; /system/bin/tinymix_stock | grep -E "aw_dev_[0-9]+_(switch|prof|monitor|volume)|aw882xx_(rx|tx|copp)_switch" | sed -n "1,120p"; echo ===dmesg===; dmesg | grep -Ei "aw882xx|agm|graph_open|graph_start|pcm|wcd" | tail -n 200'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'grep -n "twrp-audio-play-test\|tinyplay_ftm play\|agmplay play\|audio autoload\|sound card ready\|sound card still missing" /tmp/recovery.log 2>/dev/null | tail -n 120'

这轮结果需要把大输出拆开看，我先读 `tinyplay_ftm` 和 agmplay 两次标准脚本实测的关键信息，再决定是改 mixer baseline，还是继续追别的支线。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_tcJ3nevcZWxuqZmrDNrStvb9__vscode-1773952470517/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_muOjU9sYL6G08U3WXY7Mb01K__vscode-1773952470516/content.txt)

现在最有价值的新事实有两条：一是“裸跑播放器确实没声”对应 Awinic `dev can not allow power`，二是“走标准测试脚本后功放能正常 `start success`”。我先把这两条追加到续文档末尾，再继续做后台窗口抓取，确认 `start success` 期间后段到底有没有真正打开。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#560-560), lines 560 to 627

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'cat /sys/kernel/debug/asoc/components 2>/dev/null | grep -Ei "aw882xx|wcd939x|lpass|ext-disp|btfm"; echo ===dais===; cat /sys/kernel/debug/asoc/dais 2>/dev/null | grep -Ei "aw882xx|rx_macro|wcd939x|msm_dp|btaudio" | sed -n "1,120p"'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'dmesg -c >/dev/null 2>&1; /system/bin/twrp-audio-play-test.sh tinyplay_ftm >/dev/null 2>&1 & playpid=$!; sleep 1; echo ===cards===; cat /proc/asound/cards; echo ===wsa_dapm===; grep -Ei "Speaker_Playback|AIF1_PB|WSA|aw882xx" /sys/kernel/debug/asoc/* 2>/dev/null | sed -n "1,200p"; wait $playpid; echo ===rc:$?===; echo ===dmesg===; dmesg | grep -Ei "aw882xx_start_pa|aw882xx_monitor_start|aw882xx_device_start|aw882xx_shutdown|aw882xx_mute" | tail -n 200'

我先把已经拿到的硬事实写进续文档末尾，不等最终闭环；同时再补一次 card 级 DAPM 窗口抓取，确认“功放 start success 但你仍然没听到”时，卡级 widget 到底有没有真正打开。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'ls /sys/kernel/debug/asoc 2>/dev/null | sed -n "1,120p"; echo ===card_dirs===; find /sys/kernel/debug/asoc -maxdepth 2 -type d | sed -n "1,120p"'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'dmesg -c >/dev/null 2>&1; /system/bin/twrp-audio-play-test.sh tinyplay_ftm >/dev/null 2>&1 & playpid=$!; sleep 1; find /sys/kernel/debug/asoc -maxdepth 3 -type f | grep -Ei "dapm|widget|route|bias" | sed -n "1,200p"; wait $playpid'

我已经拿到 card 级 `dapm/bias_level` 的落点；先追加文档，再读一次播放窗口里的 `bias_level`，看它是不是至少真的从 `OFF` 拉到了工作态。

Generating patch (119 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'dmesg -c >/dev/null 2>&1; /system/bin/twrp-audio-play-test.sh tinyplay_ftm >/dev/null 2>&1 & playpid=$!; sleep 1; echo ===bias===; cat /sys/kernel/debug/asoc/sun-mtp-snd-card/dapm/bias_level 2>/dev/null; wait $playpid; echo ===rc:$?===; echo ===dmesg===; dmesg | grep -Ei "aw882xx_start_pa|aw882xx_monitor_start|aw882xx_device_start|aw882xx_shutdown|aw882xx_mute" | tail -n 120'

新的硬证据已经出来了：`tinyplay_ftm` 播放窗口里 Awinic 六路全都 `start success`，但整张卡的 `dapm/bias_level` 仍然是 `Off`。这解释了为什么日志看着像在播，你却还是听不到。我继续往 card 级 DAPM/widget 追，不再停在功放日志层。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'find /sys/kernel/debug/asoc/sun-mtp-snd-card -maxdepth 2 -type f | sed -n "1,240p"'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for d in /sys/kernel/debug/asoc/sun-mtp-snd-card/*; do [ -d "$d" ] || continue; echo ===$d===; find "$d" -maxdepth 1 -type f | sed -n "1,60p"; done'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'dmesg -c >/dev/null 2>&1; /system/bin/twrp-audio-play-test.sh tinyplay_ftm >/dev/null 2>&1 & playpid=$!; sleep 1; echo ===bias===; cat /sys/kernel/debug/asoc/sun-mtp-snd-card/dapm/bias_level; echo ===component_files===; for d in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.* /sys/kernel/debug/asoc/sun-mtp-snd-card/wcd939x-codec /sys/kernel/debug/asoc/sun-mtp-snd-card/soc:spf_core_platform:lpass-cdc; do [ -d "$d" ] || continue; echo ===$d===; for f in "$d"/*; do [ -f "$f" ] || continue; echo ---$f---; cat "$f" 2>/dev/null | sed -n "1,80p"; done; done; wait $playpid >/dev/null 2>&1'

`bias_level` 这一层也没有被点亮，说明“PA 起了”并不等于“整张卡真的进入播放工作态”。我再补一组最小事实：播放窗口里对应 PCM 子流是否真的在 `RUNNING`，这样能把断点缩到“数据没进后端”还是“后端活着但卡级 DAPM 仍没接通”。

Made changes.

User: 有声音，1s

GitHub Copilot: 这条主观反馈很关键：现在不是“完全没声”，而是已经变成“能出声，但只有约 1 秒”。我先用当前已成功的标准脚本跑 10 秒样本，把 `1 秒可闻` 和 `PA 全程/整卡 bias 仍 Off` 这两个现象钉在同一次实验里，然后立刻追加到续文档末尾。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#620-620), lines 620 to 739

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'dmesg -c >/dev/null 2>&1; /system/bin/twrp-audio-play-test.sh tinyplay_ftm /data/local/tmp/test440_mid_10s.wav TDM-LPAIF-RX-SECONDARY >/dev/null 2>&1 & playpid=$!; sleep 1; echo ===bias_1s===; cat /sys/kernel/debug/asoc/sun-mtp-snd-card/dapm/bias_level; sleep 3; echo ===bias_4s===; cat /sys/kernel/debug/asoc/sun-mtp-snd-card/dapm/bias_level; sleep 4; echo ===bias_8s===; cat /sys/kernel/debug/asoc/sun-mtp-snd-card/dapm/bias_level; wait $playpid; echo ===rc:$?===; echo ===dmesg===; dmesg | grep -Ei "aw882xx_start_pa|aw882xx_monitor_start|aw882xx_device_start|aw882xx_shutdown|aw882xx_mute|tinyplay_ftm|graph_open|graph_start" | tail -n 200'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell '/system/bin/tinymix_stock | grep -E "aw_dev_[0-9]+_(switch|prof|monitor|volume)|aw882xx_(rx|tx|copp)_switch|Speaker_Mute_Switch" | sed -n "1,120p"'

我先把你这条“有声音，1s”和刚才同轮实测到的 `10s` 样本现象一起写进续文档末尾，避免后面又把“完全无声”和“只能短促出声”混在一起。

Generating patch (63 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```

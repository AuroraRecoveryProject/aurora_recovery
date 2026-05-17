# 第7章：WSA-SoundWire-SWR控制器深层缺口
这说明 `Speaker_Playback` 这组 DAPM 不是区分点了，stock 对照在第 1 秒也同样是 `Off in 1 out 0`。我继续往更前一层找：接口到 MultiMedia 的 mixer 选择和 RX INT 路径。

Searched for regex `TDM-LPAIF-RX-SECONDARY Audio Mixer MultiMedia1|Audio Mixer MultiMedia1|RX INT0_1 MIX1|RX INT1_1 MIX1|WSA_RX0 INP0|WSA_RX1 INP0` (`**/docs/**/*.md`), 50 results

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/tinymix_stock -D 0 2>/dev/null | grep -E "TDM-LPAIF-RX-SECONDARY|Audio Mixer|MultiMedia1|RX INT0_1 MIX1|RX INT1_1 MIX1|RX INT0 MIX2|RX INT1 MIX2|RX0 INP0|RX1 INP0" | head -n 200'

仓库里已经有一条旧前沿和现在的现象对上了：上游 `RX INT*_MIX` 很可能还是 `ZERO`，也就是功放末端被拉起来了，但真正的播放数据没喂进去。我现在直接抓这组 live 值，再做一轮最小手工补路由。

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/pure_c_agm_probe --audible-baseline >/dev/null 2>&1 & pid=$!; sleep 1; echo PUREC; for c in "RX INT0_1 MIX1 INP0" "RX INT1_1 MIX1 INP0" "RX INT2_1 MIX1 INP0" "WSA RX0 MUX" "WSA RX1 MUX" "WSA2 RX0 MUX" "WSA2 RX1 MUX" "WSA_COMP1 Switch" "WSA_COMP2 Switch" "WSA2_COMP1 Switch" "WSA2_COMP2 Switch"; do echo ===$c===; /data/local/tmp/tinymix_stock -D 0 "$c" 2>/dev/null; done; wait $pid'

Ran terminal command:  adb -s 70a91f89 shell 'setprop vendor.oplus.mm.ftm_spk 1; /odm/bin/tinyplay_ftm /data/local/tmp/test440_mid_10s.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY >/dev/null 2>&1 & pid=$!; sleep 1; echo TINYPLAY; for c in "RX INT0_1 MIX1 INP0" "RX INT1_1 MIX1 INP0" "RX INT2_1 MIX1 INP0" "WSA RX0 MUX" "WSA RX1 MUX" "WSA2 RX0 MUX" "WSA2 RX1 MUX" "WSA_COMP1 Switch" "WSA_COMP2 Switch" "WSA2_COMP1 Switch" "WSA2_COMP2 Switch"; do echo ===$c===; /data/local/tmp/tinymix_stock -D 0 "$c" 2>/dev/null; done; wait $pid'

两条链现在连前级路由都一模一样，问题就更具体了：`WSA MUX` 已经对到 `AIF1_PB`，但 `RX INT0/1/2 MIX1 INP0` 还全是 `ZERO`。我直接做最小补路由实验，看 active widget 会不会往前推进。

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/tinymix_stock -D 0 "RX INT0_1 MIX1 INP0" RX0 >/dev/null 2>&1; /data/local/tmp/tinymix_stock -D 0 "RX INT1_1 MIX1 INP0" RX1 >/dev/null 2>&1; /data/local/tmp/tinymix_stock -D 0 "RX INT2_1 MIX1 INP0" RX2 >/dev/null 2>&1; /data/local/tmp/pure_c_agm_probe --audible-baseline >/dev/null 2>&1 & pid=$!; sleep 1; echo MIX; for c in "RX INT0_1 MIX1 INP0" "RX INT1_1 MIX1 INP0" "RX INT2_1 MIX1 INP0"; do /data/local/tmp/tinymix_stock -D 0 "$c" 2>/dev/null; done; echo ACTIVE; grep -R "stream .*active" /sys/kernel/debug/asoc/sun-mtp-snd-card 2>/dev/null | grep -E "RX AIF|RX_MACRO|WSA AIF|Speaker_Playback" | head -n 120; wait $pid'

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/tinymix_stock -D 0 "RX INT0_1 MIX1 INP0" ZERO >/dev/null 2>&1; /data/local/tmp/tinymix_stock -D 0 "RX INT1_1 MIX1 INP0" ZERO >/dev/null 2>&1; /data/local/tmp/tinymix_stock -D 0 "RX INT2_1 MIX1 INP0" ZERO >/dev/null 2>&1; echo RESET; for c in "RX INT0_1 MIX1 INP0" "RX INT1_1 MIX1 INP0" "RX INT2_1 MIX1 INP0"; do /data/local/tmp/tinymix_stock -D 0 "$c" 2>/dev/null; done'

User: 继续

GitHub Copilot: 我直接沿着你刚指出的方向查：不是再看“有没有跑起来”，而是确认前级 RX 路由是不是还停在 ZERO，以及手工补一路后会不会把数据真正送进 speaker 链。

Read memory twrp_audio_pcm_route_frontier.md

Read memory twrp_audio_stock_and_helper_1s_frontier_20260325.md

Ran terminal command:  adb -s 70a91f89 shell 'for x in /data/local/tmp/tinymix_stock /data/local/tmp/tinymix /odm/bin/tinymix /vendor/bin/tinymix /system/bin/tinymix; do [ -x "$x" ] && echo FOUND:$x; done'
Completed with input:  adb -s 70a91f89 shell 'for x in /data/local/tmp/tinymix_stock /data/local/tmp/tinymix /odm/bin/tinymix /vendor/bin/tinymix /system/bin/tinymix; do [ -x "$x" ] && echo FOUND:$x; done'

我先把可写的前级控件名筛出来，目标是避免盲写，只对 RX INT 和 WSA 这组真实控件做最小补路由实验。

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/tinymix_stock -D 0 | grep -E "RX INT|WSA_RX|WSA RX|MUX|AIF1_PB|MultiMedia|PCM[0-9]+" | head -n 240'

Ran terminal command:  adb -s 70a91f89 shell 'ls /sys/kernel/debug/asoc 2>/dev/null | head -n 40'

控件列表已经拿到了，我现在只读关键片段，然后直接做一轮“补 RX INT 输入”的最小 A/B，不再泛扫。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_ah3e5ANZ8K4F9h5Djp2bLj5y__vscode-1774458708100/content.txt)

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/tinymix_stock -D 0 | grep -E "RX INT[0-9].*MIX1 INP0|WSA.*MUX|WSA.*INP0|VBAT|PCM Playback|MultiMedia"'

我先从仓库里把这几个控件在原厂 mixer path 里的取值抠出来，目标是避免猜枚举值，直接按原厂 speaker 路由写一轮最小补路由。

Searched for regex `RX INT0_1 MIX1 INP0|RX INT1_1 MIX1 INP0|RX INT2_1 MIX1 INP0|RX_MACRO RX0 MUX|RX_MACRO RX1 MUX|WSA RX0 MUX|WSA2 RX0 MUX` (`**/*.{xml,md,txt}`), 74 results

Searched for regex `Speaker_Playback_|RX INT0_1 MIX1 INP0|RX_MACRO RX0 MUX` (`**/docs/**/*.md`), 120 results

仓库里其实已经有这条分支的旧实验记录，我现在直接把它在当前 recovery 上重跑一遍：先手工把 RX INT0/1/2 喂到 RX0/1/2，再跑 pure C 基线，看这组前级补路由有没有把静音边界推过去。

Ran terminal command:  adb -s 70a91f89 shell '/system/bin/twrp-audio-autoload.sh >/dev/null 2>&1; /data/local/tmp/tinymix_stock "RX INT0_1 MIX1 INP0" RX0; /data/local/tmp/tinymix_stock "RX INT1_1 MIX1 INP0" RX1; /data/local/tmp/tinymix_stock "RX INT2_1 MIX1 INP0" RX2; for c in "RX INT0_1 MIX1 INP0" "RX INT1_1 MIX1 INP0" "RX INT2_1 MIX1 INP0"; do echo ===$c===; /data/local/tmp/tinymix_stock "$c"; done'

Ran terminal command:  adb -s 70a91f89 shell 'rm -f /data/local/tmp/pure_c_routepatch.log; /data/local/tmp/pure_c_agm_probe --audible-baseline >/data/local/tmp/pure_c_routepatch.log 2>&1; echo RC:$?; grep -E "pcm_prepare rc|pcm_start rc|chunks=|write_test_tone rc" /data/local/tmp/pure_c_routepatch.log'

Ran terminal command:  adb -s 70a91f89 shell 'for c in "RX INT0_1 MIX1 INP0" "RX INT1_1 MIX1 INP0" "RX INT2_1 MIX1 INP0"; do echo ===$c===; /data/local/tmp/tinymix_stock "$c"; done'

前级补路由已经成功写进去了，但你刚才给的结论是“还是完全没声”，所以我继续往下看它有没有把平台侧 playback widget 真正点亮；这一步只抓 1 秒和 5 秒的 live 图，不再猜。

Ran terminal command:  adb -s 70a91f89 shell '/system/bin/twrp-audio-autoload.sh >/dev/null 2>&1; /data/local/tmp/tinymix_stock "RX INT0_1 MIX1 INP0" RX0; /data/local/tmp/tinymix_stock "RX INT1_1 MIX1 INP0" RX1; /data/local/tmp/tinymix_stock "RX INT2_1 MIX1 INP0" RX2; /data/local/tmp/pure_c_agm_probe --audible-baseline >/dev/null 2>&1 & pid=$!; sleep 1; echo [1s-mix]; for c in "RX INT0_1 MIX1 INP0" "RX INT1_1 MIX1 INP0" "RX INT2_1 MIX1 INP0"; do /data/local/tmp/tinymix_stock "$c"; done; echo [1s-active]; grep -R "stream .*active" /sys/kernel/debug/asoc/sun-mtp-snd-card 2>/dev/null | grep -E "RX AIF|RX_MACRO|WSA AIF|Speaker_Playback" | head -n 80; sleep 4; echo [5s-active]; grep -R "stream .*active" /sys/kernel/debug/asoc/sun-mtp-snd-card 2>/dev/null | grep -E "RX AIF|RX_MACRO|WSA AIF|Speaker_Playback" | head -n 80; wait $pid'

Ran terminal command:  adb -s 70a91f89 shell 'grep -E "q6 state is down|graph_start ret|aw882xx_start_pa|Error playing sample" /data/local/tmp/pure_c_routepatch.log | tail -n 40'

live 图结果已经落盘，我现在只读关键片段，判断这轮补路由到底有没有把 RX/WSA 平台侧从 inactive 推起来。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_zvhV1iqaSPjK5mbo998W9QdO__vscode-1774458708109/content.txt)

这轮结果已经很硬：补了 RX INT 输入以后，AW 端还是 active，但平台侧 `WSA_AIF1 / RX_MACRO_AIF1` 依旧全 inactive，所以缺口还在更上一层。我现在只查 `RX_MACRO RX* MUX` 这组候选源，看它们是不是还停在 ZERO。

Searched for regex `RX_MACRO RX0 MUX|RX_MACRO RX1 MUX|RX_MACRO RX2 MUX|RX_MACRO RX3 MUX` (`**/docs/**/*.md`), no results

Ran terminal command:  adb -s 70a91f89 shell 'for c in "RX_MACRO RX0 MUX" "RX_MACRO RX1 MUX" "RX_MACRO RX2 MUX" "RX_MACRO RX3 MUX"; do echo ===$c===; /data/local/tmp/tinymix_stock "$c"; done'

现在真正的新差异出来了：`RX_MACRO RX0..3 MUX` 还全停在 `ZERO`，而它们明确支持 `AIF1_PB`。我先做一轮更靠前的补路由，把这四个 MUX 直接切到 `AIF1_PB`，再看平台 playback 图会不会真正闭合。

Ran terminal command:  adb -s 70a91f89 shell '/system/bin/twrp-audio-autoload.sh >/dev/null 2>&1; /data/local/tmp/tinymix_stock "RX_MACRO RX0 MUX" AIF1_PB; /data/local/tmp/tinymix_stock "RX_MACRO RX1 MUX" AIF1_PB; /data/local/tmp/tinymix_stock "RX_MACRO RX2 MUX" AIF1_PB; /data/local/tmp/tinymix_stock "RX_MACRO RX3 MUX" AIF1_PB; for c in "RX_MACRO RX0 MUX" "RX_MACRO RX1 MUX" "RX_MACRO RX2 MUX" "RX_MACRO RX3 MUX"; do echo ===$c===; /data/local/tmp/tinymix_stock "$c"; done'

Ran terminal command:  adb -s 70a91f89 shell '/system/bin/twrp-audio-autoload.sh >/dev/null 2>&1; /data/local/tmp/tinymix_stock "RX INT0_1 MIX1 INP0" RX0; /data/local/tmp/tinymix_stock "RX INT1_1 MIX1 INP0" RX1; /data/local/tmp/tinymix_stock "RX INT2_1 MIX1 INP0" RX2; /data/local/tmp/tinymix_stock "RX_MACRO RX0 MUX" AIF1_PB; /data/local/tmp/tinymix_stock "RX_MACRO RX1 MUX" AIF1_PB; /data/local/tmp/tinymix_stock "RX_MACRO RX2 MUX" AIF1_PB; /data/local/tmp/tinymix_stock "RX_MACRO RX3 MUX" AIF1_PB; /data/local/tmp/pure_c_agm_probe --audible-baseline >/dev/null 2>&1 & pid=$!; sleep 1; echo [1s-active]; grep -R "stream .*active" /sys/kernel/debug/asoc/sun-mtp-snd-card 2>/dev/null | grep -E "RX AIF|RX_MACRO|WSA AIF|Speaker_Playback" | head -n 80; wait $pid'

这轮最小补路由已经证伪了：即使把 `RX INT` 和 `RX_MACRO RX* MUX` 都手工切到看起来合理的位置，平台侧 `WSA_AIF1 / RX_MACRO_AIF1` 还是全 inactive，所以问题不再是单个 mixer 控件没打上。我继续把面收回到系统侧，直接抓这一轮播放窗口里的 HAL/AGM 缺口日志。

Read memory twrp_audio_userspace_hal_gap.md

Read memory twrp_audio_component_gap.md

Ran terminal command:  adb -s 70a91f89 shell 'logcat -c; /data/local/tmp/pure_c_agm_probe --audible-baseline >/dev/null 2>&1; logcat -d | grep -Ei "audiohal|audio core|IModule|IAGM|agm|pal|binder|vintf|default" | tail -n 160'

仓库记忆已经把方向压得很窄了：如果这一轮 logcat 还在报 `IAGM/default` 或 `IModule/*` 缺口，那就不是 mixer 能救的。我现在只读刚抓的日志尾段。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_xO1risJsINZkOOiEDwbamjC7__vscode-1774458708118/content.txt)

这轮 logcat 已经排掉了一个猜法：播放窗口里 `IAGM/default` 是真的在工作的，`graph_start ret 0` 也正常出现，所以当前不是 “AGM 服务没起来”。我再补一刀当前设备上的 WSA 运行态，确认是不是还卡在 `wsa backend 被声明使用，但 WSA macro 实体根本没起来` 这条系统级缺口。

Ran terminal command:  adb -s 70a91f89 shell 'echo [upd]; cat /sys/firmware/devicetree/base/soc/spf_core_platform/sound/qcom,upd_backends_used 2>/dev/null; echo; echo [wsa]; cat /sys/firmware/devicetree/base/soc/spf_core_platform/lpass-cdc/wsa-macro@6B00000/status 2>/dev/null; echo; echo [wsa2]; cat /sys/firmware/devicetree/base/soc/spf_core_platform/lpass-cdc/wsa2-macro@6AA0000/status 2>/dev/null; echo; echo [components]; cat /sys/kernel/debug/asoc/components 2>/dev/null | grep -E "wsa-codec|wcd939x|aw882xx|lpass-cdc"'

Ran terminal command:  adb -s 70a91f89 shell 'find /sys/devices/platform/soc -maxdepth 3 \( -name "wsa-macro@6B00000" -o -name "wsa2-macro@6AA0000" -o -name "rx-macro@6D00000" -o -name "tx-macro@6C00000" \) 2>/dev/null | sed -n "1,40p"'

新的硬证据是：DT 里 `wsa/wsa2` 状态现在是 `okay`，但运行态 `asoc/components` 里仍然完全没有 `wsa-codec.*`。也就是问题已经收得更准了，不是单纯 DT 关掉，而是 WSA 这条 component 实体根本没注册出来。我再直接抓内核里和这条缺口对应的报错。

Ran terminal command:  adb -s 70a91f89 shell 'dmesg | grep -Ei "wsa-codec|component is NULL|could not find component for lpass-cdc|failed to add wcd9378 routes|wsa-macro|wsa2-macro" | tail -n 120'

Ran terminal command:  adb -s 70a91f89 shell 'cat /sys/kernel/debug/asoc/dais 2>/dev/null | grep -E "wsa|rx-macro|tx-macro|wcd939x" | head -n 120'

内核证据已经把缺口钉到了具体名字：`msm_set_upd_config` 反复报 `wsa-codec.1 component is NULL`，而 `asoc/dais` 里也只有 `wcd939x_cdc`。我再把模块装载面补一眼，看是 `wsa` 相关模块压根没进来，还是进了但没注册实体。

Searched for regex `wsa883x|wsa884x|wsa-codec|msm_set_upd_config|twrp-audio-autoload` (`**/*.{sh,rc,md,txt,c,cpp,h}`), 120 results

Ran terminal command:  adb -s 70a91f89 shell 'lsmod | grep -Ei "wsa|wcd|lpass|audio|machine" | head -n 200'

我现在不改镜像，先试最小运行态重探测：既然模块都在、但 `wsa-codec.1` 还是 NULL，最便宜的动作就是重绑 `spf_core_platform`，看它会不会把缺失的 WSA component 补出来。

Ran terminal command:  adb -s 70a91f89 shell 'ls /sys/bus/platform/drivers/spf-core-platform 2>/dev/null; echo ---; ls /sys/bus/platform/devices | grep -E "spf_core_platform|sun-asoc-snd|rx_swr_ctrl|va_swr_ctrl"'

Ran terminal command:  adb -s 70a91f89 shell 'cat /sys/kernel/debug/asoc/components 2>/dev/null | grep -E "wsa-codec|aw882xx|wcd939x|lpass-cdc"'

重绑路径是现成的，我现在只做一次最小 `unbind/bind`，然后立刻看 `wsa-codec.*` 和相关内核报错有没有变化。

Ran terminal command:  adb -s 70a91f89 shell 'echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/unbind; sleep 1; echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/bind; sleep 2; echo [components]; cat /sys/kernel/debug/asoc/components 2>/dev/null | grep -E "wsa-codec|aw882xx|wcd939x|lpass-cdc"; echo [dais]; cat /sys/kernel/debug/asoc/dais 2>/dev/null | grep -E "wsa|wcd939x|rx-macro|tx-macro" | head -n 80'

Ran terminal command:  adb -s 70a91f89 shell 'dmesg | grep -Ei "wsa-codec|component is NULL|spf_core_platform|q6 state is down|snd_soc" | tail -n 80'
Completed with input:  adb -s 70a91f89 shell 'dmesg | grep -Ei "wsa-codec|component is NULL|spf_core_platform|q6 state is down|snd_soc" | tail -n 80'

重绑已经执行完，组件结果落盘了；我先读这部分，如果还是没有 `wsa-codec.*`，就说明单次重绑也救不了，接下来该回到脚本时序或设备实例化链，而不是继续抡 mixer。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_rCEJevaZv4yqKPTTntfBIfnB__vscode-1774458708128/content.txt#1-1), lines 1 to 220

我把最后一个边界再补齐：现在只差确认 SoundWire 总线上到底有没有 `wsa883x/wsa884x` 实例；如果也没有，就可以把问题彻底从 mixer 收口到“WSA codec 设备没有实例化”。

Ran terminal command:  adb -s 70a91f89 shell 'find /sys/bus/soundwire/devices -maxdepth 1 -type l 2>/dev/null | sed "s#.*/##" | sort'

Ran terminal command:  adb -s 70a91f89 shell 'for n in wsa883x wsa884x wcd9378 wcd939x; do echo ===$n===; find /sys/bus -iname "*${n}*" 2>/dev/null | head -n 40; done'

我已经把“不是 mixer”的证据收齐了，下一步就该回到启动/探测时序本身。我先读当前自动加载脚本里和 `wsa`、`spf_core_platform`、`drivers_probe` 相关的实际逻辑，看看有没有直接可补的缺口。

Searched for regex `wsa883x|wsa884x|lpass_cdc_wsa|spf_core_platform|drivers_probe|soundwire|rx_swr_ctrl|va_swr_ctrl|bt_swr_mstr|swr-mgr` (`**/device_tree/twrp_device_oplus_ossi_source_built/recovery/root/system/bin/twrp-audio-autoload.sh`), 15 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/device_tree/twrp_device_oplus_ossi_source_built/recovery/root/system/bin/twrp-audio-autoload.sh#1-1), lines 1 to 320

脚本本身已经暴露出一个很像根因的缺口：它只重探测了 `rx_swr_ctrl / va_swr_ctrl / bt_swr_mstr`，没有任何 `wsa` 侧的 SWR 控制器或 codec 实体探测逻辑。我先把平台设备名里真正带 `wsa` 的节点列出来，确认能不能补这一层。

Ran terminal command:  adb -s 70a91f89 shell 'ls /sys/bus/platform/devices | grep -i wsa | sed -n "1,80p"'

Ran terminal command:  adb -s 70a91f89 shell 'find /sys/bus/platform/devices/soc:spf_core_platform:lpass-cdc -maxdepth 2 -iname "*wsa*" 2>/dev/null | sed -n "1,80p"'

这就有实货了：运行态确实存在 `wsa_swr_ctrl` 和 `wsa2_swr_ctrl`，但当前脚本完全没碰它们。我先做一次纯运行态验证，把这两个节点也按 `swr-mgr` 去 probe，再看 `wsa-codec.*` 会不会出现。

Ran terminal command:  adb -s 70a91f89 shell 'echo swr-mgr > /sys/bus/platform/devices/wsa_swr_ctrl/driver_override; echo wsa_swr_ctrl > /sys/bus/platform/drivers_probe; echo swr-mgr > /sys/bus/platform/devices/wsa2_swr_ctrl/driver_override; echo wsa2_swr_ctrl > /sys/bus/platform/drivers_probe; sleep 2; echo [components]; cat /sys/kernel/debug/asoc/components 2>/dev/null | grep -E "wsa-codec|wcd939x|aw882xx|lpass-cdc"; echo [dais]; cat /sys/kernel/debug/asoc/dais 2>/dev/null | grep -E "wsa|wcd939x" | head -n 80'

Ran terminal command:  adb -s 70a91f89 shell 'dmesg | grep -Ei "wsa-codec|wsa_swr_ctrl|wsa2_swr_ctrl|swr-mgr|component is NULL" | tail -n 120'
Completed with input:  adb -s 70a91f89 shell 'dmesg | grep -Ei "wsa-codec|wsa_swr_ctrl|wsa2_swr_ctrl|swr-mgr|component is NULL" | tail -n 120'

补探测已经执行了，我现在只读它的结果；如果 `wsa-codec.*` 还是不出现，那这条脚本缺口就证伪了，反过来如果出现了，就可以直接改脚本。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_8aItrmxJp5Fo2M6BtfECWszX__vscode-1774458708137/content.txt#1-1), lines 1 to 200

我不再停在分析层了，先把已经看到的脚本缺口补上：`probe_swr` 现在漏掉了现成存在的 `wsa_swr_ctrl / wsa2_swr_ctrl`，我把这两个节点加进去，然后直接把脚本推到设备上做一次运行态验证。

Searched for files matching `**/twrp-audio-autoload.sh`, 3 matches

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/ossi_recovery_inject_20260319/payload/twrp-audio-autoload.sh#150-150), lines 150 to 180

我先把 3 份脚本副本一起补齐，避免源码、注入包、ramdisk 展开树又分叉。补完后我只在当前设备上临时推一份脚本验证，不直接动镜像。

Using "Apply Patch"

我只做最小补丁：不碰别的逻辑，只把 `probe_swr` 的设备列表补成覆盖实际存在的 `wsa_swr_ctrl / wsa2_swr_ctrl`。

Generating patch (44 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/device_tree/twrp_device_oplus_ossi_source_built/recovery/root/system/bin/twrp-audio-autoload.sh), [](file:///Volumes/Case-sensitive%20APFS/TWRP/ossi_recovery_inject_20260319/payload/twrp-audio-autoload.sh), [](file:///Volumes/Case-sensitive%20APFS/TWRP/magisk_inject_ossi_20260312/ramdisk_out/system/bin/twrp-audio-autoload.sh)


```

```

```

```

```

```
补丁已经落了，我现在不等打包，先把脚本临时推到设备跑一遍，结果只看两个点：`wsa-codec.*` 有没有出现，`component is NULL` 有没有变化。

Ran terminal command:  adb -s 70a91f89 push '/Volumes/Case-sensitive APFS/TWRP/device_tree/twrp_device_oplus_ossi_source_built/recovery/root/system/bin/twrp-audio-autoload.sh' /data/local/tmp/twrp-audio-autoload.sh

Ran terminal command:  adb -s 70a91f89 shell 'chmod 755 /data/local/tmp/twrp-audio-autoload.sh && sh /data/local/tmp/twrp-audio-autoload.sh >/data/local/tmp/twrp-audio-autoload.run 2>&1; echo [components]; cat /sys/kernel/debug/asoc/components 2>/dev/null | grep -E "wsa-codec|wcd939x|aw882xx|lpass-cdc"; echo [dais]; cat /sys/kernel/debug/asoc/dais 2>/dev/null | grep -E "wsa|wcd939x" | head -n 80; echo [dmesg]; dmesg | grep -Ei "wsa-codec|component is NULL" | tail -n 20'

修补脚本已经跑完，结果被单独落盘了；我现在只读关键输出，不再刷整段日志。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_0TtbnBjzQ5fbraU4HfB8uIKn__vscode-1774458708144/content.txt#1-1), lines 1 to 220

继续到现在，新的硬结果有四条：

1. 这不是纯 C 命令参数问题。
   - 我把最可疑的前级路由都手工补了：
   - `RX INT0_1 MIX1 INP0 = RX0`
   - `RX INT1_1 MIX1 INP0 = RX1`
   - `RX INT2_1 MIX1 INP0 = RX2`
   - `RX_MACRO RX0..3 MUX = AIF1_PB`
   - 这些值都成功写进去了。
   - 但 pure C 仍然是完整跑满、完全无声。

2. 这也不是 AGM 服务没起来。
   - 当前播放窗口里 `IAGM/default` 是真的在工作。
   - `graph_start ret 0`
   - `pcm_prepare rc=0`
   - `pcm_start rc=0`
   - `chunks=375`
   - 所以“服务没起”这条已经可以排掉。

3. 真正没闭合的是 WSA 这条 component 链，不是 mixer 层。
   - 当前 `lsmod` 里相关模块都在：
     - `lpass_cdc_wsa_macro_dlkm`
     - `lpass_cdc_wsa2_macro_dlkm`
     - `wsa883x_dlkm`
     - `wsa884x_dlkm`
   - 但运行态 `asoc/components` 里仍然没有任何 `wsa-codec.*`
   - `asoc/dais` 里也只有 `wcd939x_cdc`
   - SoundWire 总线上只有：
     - `wcd939x-slave.*`
     - 没有 `wsa883x/wsa884x` 实例
   - 内核还在重复报：
     - `msm_set_upd_config: wsa-codec.1 component is NULL`

4. 我已经把一个真实脚本缺口补上了，但它还不够。
   - 现有 twrp-audio-autoload.sh 原来只 probe：
     - `rx_swr_ctrl`
     - `va_swr_ctrl`
     - `bt_swr_mstr`
   - 但设备运行态实际还有：
     - `wsa_swr_ctrl`
     - `wsa2_swr_ctrl`
   - 我已经把这两个节点补进了脚本的 `probe_swr`
   - 并同步改了三份脚本副本
   - 运行态直接验证后，结果是新的内核报错：
     - `platform wsa_swr_ctrl: swrm_wcd_notify: swrm is NULL`
     - `platform wsa2_swr_ctrl: swrm_wcd_notify: swrm is NULL`

这意味着当前主线已经进一步收紧成：

1. 不是播放器没跑
2. 不是前级 mixer 没打
3. 不是 AGM 服务没起
4. 而是 `WSA SWR manager / WSA codec 实体` 根本没建起来

也就是现在最像根因的点已经变成：

- `wsa_swr_ctrl / wsa2_swr_ctrl` 虽然存在
- 但它们 probe 时拿到的是 `swrm is NULL`
- 所以 `wsa-codec.*` 永远注册不出来
- `machine` 最后就一直落回 `wsa-codec.1 component is NULL`

我已经做掉的代码改动：

- 给 twrp-audio-autoload.sh 的 `probe_swr` 增加了：
  - `wsa_swr_ctrl`
  - `wsa2_swr_ctrl`
- 同时兼容两种设备路径：
  - `soc:spf_core_platform:$dev`
  - `$dev`

下一步我不再回去试播放器参数了，我会直接沿着这条线继续：

1. 查 `wsa_swr_ctrl / wsa2_swr_ctrl` 需要的 `swrm` 到底是谁创建的
2. 对照 `rx_swr_ctrl` 为什么有 manager、`wsa_swr_ctrl` 为什么是 NULL
3. 再决定是补 probe 顺序，还是补缺失的上游设备实例化步骤

如果你要我继续，我下一步就直接抓这两个控制器对应的上游 `swr-mgr` 绑定链。

Made changes.

User: 继续

GitHub Copilot: 我继续沿 `wsa_swr_ctrl -> swrm is NULL` 这条链往上追，目标是和正常工作的 `rx_swr_ctrl` 做对照，把缺的是设备实例、驱动绑定还是上游 manager 生成压实。

Ran terminal command:  adb -s 70a91f89 shell 'echo [drivers]; ls /sys/bus/platform/drivers | grep -E "swr|spf|lpass" | sed -n "1,80p"; echo [rx]; readlink /sys/bus/platform/devices/rx_swr_ctrl/driver 2>/dev/null; echo [wsa]; readlink /sys/bus/platform/devices/wsa_swr_ctrl/driver 2>/dev/null; echo [wsa2]; readlink /sys/bus/platform/devices/wsa2_swr_ctrl/driver 2>/dev/null'
Completed with input:  adb -s 70a91f89 shell 'echo [drivers]; ls /sys/bus/platform/drivers | grep -E "swr|spf|lpass" | sed -n "1,80p"; echo [rx]; readlink /sys/bus/platform/devices/rx_swr_ctrl/driver 2>/dev/null; echo [wsa]; readlink /sys/bus/platform/devices/wsa_swr_ctrl/driver 2>/dev/null; echo [wsa2]; readlink /sys/bus/platform/devices/wsa2_swr_ctrl/driver 2>/dev/null'

Ran terminal command:  adb -s 70a91f89 shell 'for d in rx_swr_ctrl wsa_swr_ctrl wsa2_swr_ctrl; do echo ===$d===; ls /sys/bus/platform/devices/$d 2>/dev/null | grep -E "driver_override|modalias|of_node|supplier|consumer|subsystem" | sed -n "1,80p"; done'
Completed with input:  adb -s 70a91f89 shell 'for d in rx_swr_ctrl wsa_swr_ctrl wsa2_swr_ctrl; do echo ===$d===; ls /sys/bus/platform/devices/$d 2>/dev/null | grep -E "driver_override|modalias|of_node|supplier|consumer|subsystem" | sed -n "1,80p"; done'

Ran terminal command:  adb -s 70a91f89 shell 'dmesg | grep -Ei "rx_swr_ctrl|wsa_swr_ctrl|wsa2_swr_ctrl|swr-mgr|swrm_wcd_notify" | tail -n 160'
Completed with input:  adb -s 70a91f89 shell 'dmesg | grep -Ei "rx_swr_ctrl|wsa_swr_ctrl|wsa2_swr_ctrl|swr-mgr|swrm_wcd_notify" | tail -n 160'

刚才三个 adb 查询被终端里的中断打断了，没有产出有效结果；我改成更短的单条命令逐个读，避免再被共享终端状态干扰。

Ran terminal command:  adb -s 70a91f89 shell 'readlink /sys/bus/platform/devices/rx_swr_ctrl/driver 2>/dev/null; readlink /sys/bus/platform/devices/wsa_swr_ctrl/driver 2>/dev/null; readlink /sys/bus/platform/devices/wsa2_swr_ctrl/driver 2>/dev/null'
Completed with input:  adb -s 70a91f89 shell 'readlink /sys/bus/platform/devices/rx_swr_ctrl/driver 2>/dev/null; readlink /sys/bus/platform/devices/wsa_swr_ctrl/driver 2>/dev/null; readlink /sys/bus/platform/devices/wsa2_swr_ctrl/driver 2>/dev/null'

Ran terminal command:  adb -s 70a91f89 shell 'for d in rx_swr_ctrl wsa_swr_ctrl wsa2_swr_ctrl; do echo ===$d===; cat /sys/bus/platform/devices/$d/modalias 2>/dev/null; done'

Ran terminal command:  adb -s 70a91f89 shell 'dmesg | tail -n 400 | grep -Ei "rx_swr_ctrl|wsa_swr_ctrl|wsa2_swr_ctrl|swrm_wcd_notify|swr-mgr"'
Completed with input:  adb -s 70a91f89 shell 'dmesg | tail -n 400 | grep -Ei "rx_swr_ctrl|wsa_swr_ctrl|wsa2_swr_ctrl|swrm_wcd_notify|swr-mgr"'

现在有一条差异已经出来了：`rx_swr_ctrl` 绑定到了 `swr-mgr`，而 `wsa_swr_ctrl/wsa2_swr_ctrl` 没回出任何 driver 路径。我再单独把这两个节点的绑定状态和可触发路径补齐。

Ran terminal command:  adb -s 70a91f89 shell 'for d in rx_swr_ctrl wsa_swr_ctrl wsa2_swr_ctrl; do echo ===$d===; if [ -L /sys/bus/platform/devices/$d/driver ]; then readlink /sys/bus/platform/devices/$d/driver; else echo no-driver; fi; done'

Ran terminal command:  adb -s 70a91f89 shell 'ls /sys/bus/platform/drivers/swr-mgr 2>/dev/null | sed -n "1,120p"'

Ran terminal command:  adb -s 70a91f89 shell 'for d in wsa_swr_ctrl wsa2_swr_ctrl; do echo ===$d===; cat /sys/bus/platform/devices/$d/driver_override 2>/dev/null; done'

差异已经压实了：`rx_swr_ctrl` 被 `swr-mgr` 正常接管，而 `wsa_swr_ctrl/wsa2_swr_ctrl` 虽然 `driver_override=swr-mgr`，却始终没绑定。我现在直接手动 bind 一次，拿到内核拒绝它们的第一现场。

Ran terminal command:  adb -s 70a91f89 shell 'echo wsa_swr_ctrl > /sys/bus/platform/drivers/swr-mgr/bind 2>/data/local/tmp/wsa_bind.err; echo RC:$?; cat /data/local/tmp/wsa_bind.err; echo ---; if [ -L /sys/bus/platform/devices/wsa_swr_ctrl/driver ]; then readlink /sys/bus/platform/devices/wsa_swr_ctrl/driver; else echo no-driver; fi'

Ran terminal command:  adb -s 70a91f89 shell 'echo wsa2_swr_ctrl > /sys/bus/platform/drivers/swr-mgr/bind 2>/data/local/tmp/wsa2_bind.err; echo RC:$?; cat /data/local/tmp/wsa2_bind.err; echo ---; if [ -L /sys/bus/platform/devices/wsa2_swr_ctrl/driver ]; then readlink /sys/bus/platform/devices/wsa2_swr_ctrl/driver; else echo no-driver; fi'

Ran terminal command:  adb -s 70a91f89 shell 'dmesg | tail -n 120 | grep -Ei "wsa_swr_ctrl|wsa2_swr_ctrl|swr-mgr|swrm_wcd_notify|probe"'
Completed with input:  adb -s 70a91f89 shell 'dmesg | tail -n 120 | grep -Ei "wsa_swr_ctrl|wsa2_swr_ctrl|swr-mgr|swrm_wcd_notify|probe"'

手动 `bind` 被 shell 重定向权限挡住了，但关键点没变：两个 WSA 控制器仍是 `no-driver`。我继续读它们和 `rx_swr_ctrl` 的设备依赖，把“为什么只有 RX 能被接管”压成更具体的差异。

Ran terminal command:  adb -s 70a91f89 shell 'for d in rx_swr_ctrl wsa_swr_ctrl wsa2_swr_ctrl; do echo ===$d===; ls /sys/bus/platform/devices/$d 2>/dev/null | grep "^supplier:" | sed -n "1,40p"; done'

Ran terminal command:  adb -s 70a91f89 shell 'for d in rx_swr_ctrl wsa_swr_ctrl wsa2_swr_ctrl; do echo ===$d===; cat /sys/bus/platform/devices/$d/of_node/name 2>/dev/null; echo; cat /sys/bus/platform/devices/$d/of_node/compatible 2>/dev/null; echo; done'

User: 继续

GitHub Copilot: 我直接把 `rx_swr_ctrl` 和两个 `wsa*_swr_ctrl` 的 sysfs 身份并排读出来，目标是把“为什么 RX 能绑上、WSA 绑不上”落到设备属性差异上。

Ran terminal command:  adb -s 70a91f89 shell 'for d in rx_swr_ctrl wsa_swr_ctrl wsa2_swr_ctrl; do p=/sys/bus/platform/devices/$d; echo ===$d===; readlink $p/driver 2>/dev/null || echo no-driver; cat $p/driver_override 2>/dev/null; cat $p/modalias 2>/dev/null; done'

Ran terminal command:  adb -s 70a91f89 shell 'for d in rx_swr_ctrl wsa_swr_ctrl wsa2_swr_ctrl; do p=/sys/bus/platform/devices/$d; echo ===$d-uevent===; cat $p/uevent 2>/dev/null; done'

我再把 `swr-mgr` 驱动侧状态读出来，并手动 bind 一次 `wsa_swr_ctrl/wsa2_swr_ctrl`，结果应该直接告诉我们是“没尝试绑定”还是“尝试后内核当场拒绝”。

Ran terminal command:  adb -s 70a91f89 shell 'echo [driver]; ls /sys/bus/platform/drivers/swr-mgr 2>/dev/null; echo [links]; find /sys/bus/platform/drivers/swr-mgr -maxdepth 1 -type l | sed "s#.*/##" | sort'

Ran terminal command:  adb -s 70a91f89 shell 'dmesg -c >/dev/null 2>&1; echo wsa_swr_ctrl > /sys/bus/platform/drivers/swr-mgr/bind 2>/dev/null; echo wsa2_swr_ctrl > /sys/bus/platform/drivers/swr-mgr/bind 2>/dev/null; echo [post]; for d in wsa_swr_ctrl wsa2_swr_ctrl; do p=/sys/bus/platform/devices/$d; echo ===$d===; readlink $p/driver 2>/dev/null || echo no-driver; done; echo [dmesg]; dmesg | tail -n 80'

关键差异已经开始露了：当前 SoundWire 只长出了 `swr1/swr2/swr4`，而两个 WSA 控制器的别名分别是 `swr0/swr3`。我现在把这个差异和 `rx/va/bt` 的 alias 对齐一下，确认是不是“WSA 两条总线根本没实例化”。

Ran terminal command:  adb -s 70a91f89 shell 'for d in bt_swr_mstr rx_swr_ctrl va_swr_ctrl wsa_swr_ctrl wsa2_swr_ctrl; do p=/sys/bus/platform/devices/$d; echo ===$d===; grep ^OF_ALIAS_0= $p/uevent 2>/dev/null; readlink $p/driver 2>/dev/null || echo no-driver; done; echo [soundwire]; find /sys/bus/soundwire/devices -maxdepth 1 -type l 2>/dev/null | sed "s#.*/##" | sort'

Ran terminal command:  adb -s 70a91f89 shell 'for n in swr0 swr1 swr2 swr3 swr4; do echo ===$n===; ls -ld /sys/bus/soundwire/devices/$n 2>/dev/null || echo missing; done'

现在差异已经收得很窄了：`swr0/swr3` 根本没创建出来。我继续直接比 `rx_swr_ctrl` 和 `wsa_swr_ctrl` 的设备目录与内核日志，目标是判断是 probe 根本没跑，还是 probe 跑了但在创建 `swr0` 前失败。

Ran terminal command:  adb -s 70a91f89 shell 'for d in rx_swr_ctrl wsa_swr_ctrl wsa2_swr_ctrl; do echo ===$d-dir===; ls /sys/bus/platform/devices/$d 2>/dev/null | sort; done'

Ran terminal command:  adb -s 70a91f89 shell 'dmesg | grep -Ei "wsa_swr_master|wsa2_swr_master|swr0|swr3|wsa_swr_ctrl|wsa2_swr_ctrl|swrm_wcd_notify|swr bus clsh" | tail -n 120'

我再往上一层比 `rx-macro` 和 `wsa-macro/wsa2-macro` 本体的绑定状态；如果宏设备自己就没绑上，`wsa_swr_ctrl` 起不来就不是意外了。

Ran terminal command:  adb -s 70a91f89 shell 'for d in rx-macro va-macro wsa-macro wsa2-macro; do p=/sys/bus/platform/devices/$d; echo ===$d===; readlink $p/driver 2>/dev/null || echo no-driver; ls $p 2>/dev/null | sort | head -n 40; done'

Ran terminal command:  adb -s 70a91f89 shell 'for d in rx-macro va-macro wsa-macro wsa2-macro; do echo ===$d-uevent===; cat /sys/bus/platform/devices/$d/uevent 2>/dev/null; done'

我不去碰受权限限制的 `bind` 文件，直接走内核通用的 `drivers_probe` 路径单独重打一次 `wsa_swr_ctrl/wsa2_swr_ctrl`，看它们是否会吐出明确失败点。

Ran terminal command:  adb -s 70a91f89 shell 'dmesg -c >/dev/null 2>&1; echo wsa_swr_ctrl > /sys/bus/platform/drivers_probe 2>/dev/null; echo wsa2_swr_ctrl > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; echo [state]; for d in wsa_swr_ctrl wsa2_swr_ctrl; do p=/sys/bus/platform/devices/$d; echo ===$d===; readlink $p/driver 2>/dev/null || echo no-driver; ls $p 2>/dev/null | grep -E "^swr[0-9]+$" || echo no-swr-child; done; echo [dmesg]; dmesg | tail -n 120'

Ran terminal command:  adb -s 70a91f89 shell 'dmesg -c >/dev/null 2>&1; echo rx_swr_ctrl > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; echo [state]; readlink /sys/bus/platform/devices/rx_swr_ctrl/driver 2>/dev/null || echo no-driver; ls /sys/bus/platform/devices/rx_swr_ctrl 2>/dev/null | grep -E "^swr[0-9]+$" || echo no-swr-child; echo [dmesg]; dmesg | tail -n 80'

我先验证“探测太早”这条分支：如果 `wsa_swr_ctrl` 失败是因为 SSR 还没结束，那延后再 probe 应该会变。下一步只做延时重 probe，不改别的。

Ran terminal command:  adb -s 70a91f89 shell 'for f in /sys/kernel/boot_adsp/* /sys/class/remoteproc/remoteproc*/state; do [ -e "$f" ] && echo ===$f=== && cat "$f" 2>/dev/null; done'

Ran terminal command:  adb -s 70a91f89 shell 'dmesg -c >/dev/null 2>&1; sleep 8; echo wsa_swr_ctrl > /sys/bus/platform/drivers_probe 2>/dev/null; echo wsa2_swr_ctrl > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; echo [state]; for d in wsa_swr_ctrl wsa2_swr_ctrl; do p=/sys/bus/platform/devices/$d; echo ===$d===; readlink $p/driver 2>/dev/null || echo no-driver; ls $p 2>/dev/null | grep -E "^swr[0-9]+$" || echo no-swr-child; done; echo [dmesg]; dmesg | tail -n 80'

延时重 probe 的结果已经出来了，我现在只读关键尾段，看 `SSR is in progress` 是瞬时窗口还是稳定状态。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_AvmyrFvihlDClN1xUp8r97jb__vscode-1774459638127/content.txt)

我继续把失败点压到宏设备的电源状态上：既然日志已经落到 `lpass_cdc_wsa_macro ... Tx core clk enable failed`，下一步就直接对比 `rx-macro` 和 `wsa-macro/wsa2-macro` 的 runtime 状态。

Ran terminal command:  adb -s 70a91f89 shell 'for d in rx-macro va-macro wsa-macro wsa2-macro; do p=/sys/bus/platform/devices/$d/power; echo ===$d===; for f in runtime_status runtime_enabled runtime_active_time runtime_suspended_time control autosuspend_delay_ms; do [ -e $p/$f ] && { printf "%s=" "$f"; cat $p/$f; }; done; done'

Ran terminal command:  adb -s 70a91f89 shell 'for d in rx-macro wsa-macro wsa2-macro; do echo ===$d-of===; find /sys/bus/platform/devices/$d/of_node -maxdepth 1 -type f \( -name status -o -name reg -o -name qcom,swr-clock-stop-mode0 -o -name qcom,swr-clock-stop-mode1 -o -name qcom,swr-num-dev -o -name qcom,swr-num-ports \) 2>/dev/null | while read f; do printf "%s=" "${f##*/}"; xxd -p "$f" 2>/dev/null | head -n 1; done; done'

runtime PM 没有显出本质差异，我直接把 OF 节点里和 SWR 相关的属性名列出来，找 WSA 和 RX 在声明面到底差了什么。

Ran terminal command:  adb -s 70a91f89 shell 'for d in rx-macro wsa-macro wsa2-macro; do echo ===$d-of-list===; ls /sys/bus/platform/devices/$d/of_node 2>/dev/null | sort | head -n 120; done'

Ran terminal command:  adb -s 70a91f89 shell 'for d in rx_swr_ctrl wsa_swr_ctrl wsa2_swr_ctrl; do echo ===$d-parent===; readlink /sys/bus/platform/devices/$d/of_node 2>/dev/null; readlink /sys/bus/platform/devices/$d/../of_node 2>/dev/null; done'

我再把 `rx_swr_master` 和 `wsa*_swr_master` 子节点本身的属性列出来，日志里已经点到了 `version`、`num_dev`，这一步就是把这些声明值直接读出来。

Ran terminal command:  adb -s 70a91f89 shell 'for d in rx_swr_ctrl wsa_swr_ctrl wsa2_swr_ctrl; do echo ===$d-child-of-list===; ls /sys/bus/platform/devices/$d/of_node 2>/dev/null | sort | head -n 120; done'

Ran terminal command:  adb -s 70a91f89 shell 'for d in rx_swr_ctrl wsa_swr_ctrl wsa2_swr_ctrl; do echo ===$d-props===; for f in /sys/bus/platform/devices/$d/of_node/*; do case ${f##*/} in compatible|qcom,swr-num-dev|qcom,swr-num-ports|qcom,swr-version|reg|status) printf "%s=" "${f##*/}"; xxd -p "$f" 2>/dev/null | head -n 1; esac; done; done'

现在设备树声明面也对上了：`wsa_swr_ctrl` 要带 2 个从设备，`wsa2_swr_ctrl` 要带 3 个，从日志里的 `num_dev 2/3 > max limit 0` 完全一致。下一步我直接追 `Tx core clk enable failed` 依赖的上游时钟/远端状态。

Ran terminal command:  adb -s 70a91f89 shell 'for rp in /sys/class/remoteproc/remoteproc*; do echo ===$rp===; cat $rp/name 2>/dev/null; cat $rp/state 2>/dev/null; done'

Ran terminal command:  adb -s 70a91f89 shell 'dmesg | grep -Ei "lpass_cdc_clk_rsc_request_clock|Tx core clk enable failed|__spf_core_is_apm_ready|SSR is in progress|q6 state is down" | tail -n 120'

我再补一块最可能相关的基线：WSA 失败点明确提到 `Tx core clk`，所以我直接核 `tx-macro` 这一支在运行态有没有真实实例和驱动绑定。

Ran terminal command:  adb -s 70a91f89 shell 'for d in tx-macro /sys/bus/platform/devices/tx-macro; do [ -e "$d" ] && echo found:$d; done; ls /sys/bus/platform/devices | grep -E "^tx-macro$|tx_swr"'

Ran terminal command:  adb -s 70a91f89 shell 'if [ -e /sys/bus/platform/devices/tx-macro ]; then echo [driver]; readlink /sys/bus/platform/devices/tx-macro/driver 2>/dev/null || echo no-driver; echo [uevent]; cat /sys/bus/platform/devices/tx-macro/uevent 2>/dev/null; else echo no-tx-macro; fi'

`tx-macro` 本体是存在并已绑定的，所以问题还不是“Tx 宏没起来”。我继续只看一层：`tx-macro` 的 runtime 状态和 WSA 失败时的时钟资源管理器是否一致。

Ran terminal command:  adb -s 70a91f89 shell 'for d in tx-macro wsa-macro wsa2-macro; do p=/sys/bus/platform/devices/$d/power; echo ===$d===; for f in runtime_status runtime_enabled runtime_active_time runtime_suspended_time control autosuspend_delay_ms; do [ -e $p/$f ] && { printf "%s=" "$f"; cat $p/$f; }; done; done'

Ran terminal command:  adb -s 70a91f89 shell 'dmesg | grep -Ei "tx-macro|lpass_cdc_tx_macro|clk-rsc-mngr|Tx core clk enable failed" | tail -n 120'

我再把最后一个上游对象补出来：失败日志里直接点名了 `lpass-cdc-clk-rsc-mngr`，所以我现在读它的运行态和设备关系，确认是不是它一直把 WSA 的时钟请求判成“SSR 中”。

Ran terminal command:  adb -s 70a91f89 shell 'ls /sys/bus/platform/devices | grep -i "clk-rsc-mngr"; for d in /sys/bus/platform/devices/*clk-rsc-mngr*; do echo ===$d===; readlink $d/driver 2>/dev/null || echo no-driver; [ -d $d/power ] && for f in runtime_status runtime_enabled runtime_active_time runtime_suspended_time control; do [ -e $d/power/$f ] && { printf "%s=" "$f"; cat $d/power/$f; }; done; done'

Ran terminal command:  adb -s 70a91f89 shell 'for d in /sys/bus/platform/devices/*clk-rsc-mngr*; do echo ===uevent:$d===; cat $d/uevent 2>/dev/null; done'

我再补一个低成本对照：查仓库历史里有没有正常系统侧的 `swr0/swr3` 或 `wsa-codec.*` 证据，这能判断当前是不是 recovery 专属缺口，而不是设备本来就这样。

Searched for regex `swr0|swr3|wsa-codec|wsa_swr_ctrl|wsa2_swr_ctrl` (`**/docs/**/*.md`), 120 results

Searched for regex `wsa-codec|swr0|swr3|wsa883x|wsa884x` (`**/memories/repo/*.md`), no results

Compacted conversation仓库历史里已经有一条更硬的旧结论：曾经把 DT 补到第三版后，WSA reprobe 的首错从 `max limit 0` 推进到了 `HW 0x2010000 + swr link failed to connect`。我现在直接对比现有 patched DTS 里的 WSA SWR 版本字段，看看当前回退到 `0x0` 是不是 DT 漂移了。Optimizing tool selection...

Searched for regex `wsa_swr_ctrl|wsa2_swr_ctrl|swr_master_id|version|wsa-max-devs` (`**/audio_dtb_probe/**/*.dts`), no results

Searched for regex `0x2010000|0x2000000|wsa-max-devs|swr link failed to connect|max limit 0` (`**/docs/TWRP音频手动Bring-up.md`), no results

搜索结果被忽略规则挡住了，我重跑一次包含被忽略目录，只取和当前前沿直接相关的字段。

Searched for regex `wsa_swr_ctrl|wsa2_swr_ctrl|swr_master_id|version|wsa-max-devs` (`**/audio_dtb_probe/**/*.dts`), no results

Searched for regex `0x2010000|0x2000000|wsa-max-devs|swr link failed to connect|max limit 0` (`**/docs/TWRP音频手动Bring-up.md`), no results

我先确认这些 DTS 产物现在还在不在工作区，避免继续对着旧路径空搜。

Searched for files matching `**/audio_dtb_probe/**/*.dts`, no matches

Searched for files matching `**/audio_dtb_probe/**/entry*.dts`, no matches

Searched for files matching `**/audio_dtb_probe/**/vendor_boot_sound.dts`, no matches

我继续补运行态 DT 的硬证据，不改任何东西，只确认 WSA SWR 节点现在到底带了哪些属性，尤其是 `version` 和 `wsa-max-devs`。

Ran terminal command:  cd "$PWD" && adb shell 'find /proc/device-tree/soc/spf_core_platform -maxdepth 3 \( -iname "*wsa*swr*" -o -iname "*wsa*macro*" -o -iname "*lpass-cdc*" \) | sed -n "1,120p"'

路径已经定位到了，下一步只读关键属性，确认当前 live DT 里 `wsa_swr_master`/`wsa2_swr_master` 是否真的还停在错误版本值。

Ran terminal command:  cd "$PWD" && adb shell 'for n in /proc/device-tree/soc/spf_core_platform/lpass-cdc/wsa-macro@6B00000/wsa_swr_master /proc/device-tree/soc/spf_core_platform/lpass-cdc/wsa2-macro@6AA0000/wsa2_swr_master; do echo ===$n===; ls "$n" | sed -n "1,80p"; for p in qcom,swr-version qcom,swr-num-dev qcom,swr-num-ports qcom,swr_master_id status; do if [ -f "$n/$p" ]; then echo --$p--; od -An -tx4 "$n/$p"; fi; done; done; echo ===sound===; for p in /proc/device-tree/soc/spf_core_platform/sound/qcom,wsa-max-devs /proc/device-tree/soc/spf_core_platform/sound/qcom,upd_backends_used; do echo --$p--; if [ -f "$p" ]; then od -An -tx4 "$p"; else echo missing; fi; done'

新的硬证据出来了：live DT 里已经有 `qcom,wsa-max-devs = 3`，说明之前那条补丁确实生效；但 `wsa_swr_master` 和 `wsa2_swr_master` 节点里根本没有 `qcom,swr-version` 这个属性。现在我再补读一下上层 `lpass-cdc` 版本值，判断版本不匹配是来自全局版本继承还是运行时读硬件失败。

Ran terminal command:  cd "$PWD" && adb shell 'echo ===lpass-cdc-version===; od -An -tx4 /proc/device-tree/soc/spf_core_platform/lpass-cdc/qcom,lpass-cdc-version; echo ===compat===; for n in /proc/device-tree/soc/spf_core_platform/lpass-cdc/wsa-macro@6B00000/wsa_swr_master /proc/device-tree/soc/spf_core_platform/lpass-cdc/wsa2-macro@6AA0000/wsa2_swr_master; do echo --$n--; tr -d "\000" < "$n/compatible"; echo; done; echo ===drivers===; for n in wsa_swr_ctrl wsa2_swr_ctrl; do echo --$n--; readlink /sys/bus/platform/devices/$n/driver 2>/dev/null || echo unbound; done; echo ===last-dmesg===; dmesg | grep -i -E "wsa_swr_ctrl|wsa2_swr_ctrl|swrm_probe|version specified|Tx core clk enable failed|SSR is in progress" | tail -n 80'

还有一个矛盾点要钉死：live DT 已经能读到 `sound/qcom,wsa-max-devs = 3`，但 probe 日志还是报 `max limit 0`。我再查一遍这个属性在 live DT 里到底只有一份还是还有别的上游节点。

Ran terminal command:  cd "$PWD" && adb shell 'find /proc/device-tree -name "qcom,wsa-max-devs" | sed -n "1,40p"; echo ===grep===; for p in $(find /proc/device-tree -name "qcom,wsa-max-devs" 2>/dev/null); do echo --$p--; od -An -tx4 "$p"; done'

我把当前主线压成 3 个动作，避免再回到播放器参数层：先钉死 `max limit 0` 的来源，再确认 `SSR is in progress` 是否是持续坏状态，最后再决定是修 DT 还是修启动时序。

Created 3 todos

我再做最后一个只读检查：看 ADSP/SSR 现在是不是一直卡在恢复中。如果是持续态，WSA SWR 的 `HW read version 0x0` 就更像上游电源/时钟没起来，而不是 DTS 数字本身错了。

Ran terminal command:  cd "$PWD" && adb shell 'echo ===remoteproc===; for f in /sys/class/remoteproc/remoteproc*/name /sys/class/remoteproc/remoteproc*/state 2>/dev/null; do echo --$f--; cat $f; done; echo ===subsys===; for d in /sys/bus/msm_subsys/devices/* 2>/dev/null; do echo --$d--; cat $d/name 2>/dev/null; cat $d/state 2>/dev/null; done; echo ===ssr===; dmesg | grep -i -E "SSR is in progress|subsys.*audio|adsprpc|adsp" | tail -n 120'
Completed with input:  cd "$PWD" && adb shell 'echo ===remoteproc===; for f in /sys/class/remoteproc/remoteproc*/name /sys/class/remoteproc/remoteproc*/state 2>/dev/null; do echo --$f--; cat $f; done; echo ===subsys===; for d in /sys/bus/msm_subsys/devices/* 2>/dev/null; do echo --$d--; cat $d/name 2>/dev/null; cat $d/state 2>/dev/null; done; echo ===ssr===; dmesg | grep -i -E "SSR is in progress|subsys.*audio|adsprpc|adsp" | tail -n 120'

刚才那条被设备端 `sh` 的重定向语法卡住了，我拆成更短的几段重跑。

Ran terminal command:  cd "$PWD" && adb shell 'echo ===remoteproc===; for d in /sys/class/remoteproc/remoteproc*; do [ -d "$d" ] || continue; echo --$d--; cat "$d/name"; cat "$d/state"; done; echo ===subsys===; for d in /sys/bus/msm_subsys/devices/*; do [ -d "$d" ] || continue; echo --$d--; cat "$d/name" 2>/dev/null; cat "$d/state" 2>/dev/null; done; echo ===ssr===; dmesg | grep -i -E "SSR is in progress|subsys.*audio|adsprpc|adsp" | tail -n 120'

结果被截到临时输出文件里了，我只读前面关键段落，不展开噪音。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_ZgpNMusBKslM9oswGHeRMWG5__vscode-1774459638158/content.txt)

我再补一个源码侧对照：直接在仓库里找 `wsa-max-devs`、`swrm_probe` 和版本判断，确认 `max limit 0` 究竟从哪个节点/默认值来，而不是继续猜。

Searched codebase for "swrm_probe version specified in dtsi max limit 0 qcom wsa max devs soundwire driver source", 17 results

Searched for regex `wsa-max-devs|swrm_probe|version specified in dtsi|max limit` (`**/*.{c,h,dts,dtsi,txt,md}`), 160 results

当前又收紧了一层，结论不是“播放器还要调”，而是 WSA SoundWire 初始化链本身没起来。

本轮新增硬结论：

1. live DT 里的 WSA 基本参数已经不是空的
- `wsa_swr_master` 读到 `qcom,swr-num-dev = 2`、`qcom,swr-num-ports = 13`、`qcom,swr_master_id = 1`
- `wsa2_swr_master` 读到 `qcom,swr-num-dev = 3`、`qcom,swr-num-ports = 13`、`qcom,swr_master_id = 4`
- `sound/qcom,wsa-max-devs = 3` 也确实在运行态生效了
- 所以现在日志里还出现的 `max limit 0`，已经不能再简单归因成 `sound` 节点没补上

2. 当前 WSA SWR 节点没有显式版本属性
- `wsa_swr_master` 和 `wsa2_swr_master` 下面都没看到 `qcom,swr-version`
- 但驱动 probe 仍然报：
  - `version specified in dtsi: 0x2000000 not match with HW read version 0x0`
- 这说明“期望版本 0x2000000”大概率来自驱动默认值或别的上游节点，不是当前这两个 WSA master 节点直接写出来的

3. ADSP 不是全局死掉
- `remoteproc-adsp` 当前状态是 `running`
- 所以这不是“整颗 ADSP 没起来”
- 但 WSA probe 时仍然同步报：
  - `lpass_cdc_clk_rsc_request_clock: SSR is in progress..`
  - `lpass_cdc_runtime_resume:lpass Tx core clk enable failed`
- 也就是：ADSP 活着，但 WSA 这条 LPASS/Tx/clock/SSR 子路径在 probe 时仍然没准备好

4. 现阶段最关键的运行态事实没变
- `wsa_swr_ctrl`、`wsa2_swr_ctrl` 仍然是 `unbound`
- reprobe 后仍然失败
- `HW read version` 现在是 `0x0`
- 所以 `swr0` / `swr3` 还是起不来，`wsa-codec.*` 也就还是不会出现
- 这直接解释了为什么 pure-C 运行完整、`pcm_start` 成功，但仍然完全无声

这轮之后，主线已经很明确：

- 不是 pure-C 参数问题
- 不是简单 mixer 问题
- 也不再是单纯 `qcom,wsa-max-devs` 漏补
- 当前前沿是：
  - WSA 专属 SWR controller 绑定失败
  - 首因更像 `WSA 的 LPASS Tx core/clock/SSR 时序` 或 `WSA SWR 版本来源/父节点配置`
  - 不是通用 ADSP 挂死

我下一步建议直接走这两个方向里的一个：

1. 继续做运行态只读对照
- 把 stock Android 正常开机态的同一组节点和日志抓出来
- 重点比 `wsa_swr_master`/`wsa2_swr_master`、`lpass-cdc-clk-rsc-mngr`、`wsa_swr_ctrl` 的绑定顺序和版本值

2. 继续做离线驱动反推
- 直接从 `swr_ctrl_dlkm.ko` 里反推 `version specified in dtsi` 和 `max limit` 具体取自哪个 DT 字段/默认值
- 这样能判断下一版该补 `version` 还是该补时序

如果你要我继续，我建议先做第 2 条，成本更低，而且能直接决定下一版 DT/脚本该改什么。

User: 继续

GitHub Copilot: 我先把 `swr_ctrl_dlkm.ko` 本体里的日志和属性名抠出来，目标是把 `max limit` 和 `version specified in dtsi` 的来源从猜测变成可定位的代码路径。

Searched for regex `version specified in dtsi|max limit|swr link failed to connect|qcom,swr-master-version|qcom,swr-version|qcom,wsa-max-devs` (`**/docs/History Chat.md`), 80 results

Searched for regex `swr_ctrl_dlkm|swr-mgr|soundwire|swrm_probe` (`**/*.{c,h,ko,md,txt}`), 120 results

Ran terminal command:  cd "$PWD" && adb shell 'strings /vendor_dlkm/lib/modules/swr_ctrl_dlkm.ko | grep -E "version specified in dtsi|max limit|qcom,swr|swr_master|link failed to connect|swrm_probe" | sed -n "1,220p"'

有实锤了：驱动本体明确读取的是 `qcom,swr-master-version`，不是我刚才看的 `qcom,swr-version`。我现在直接读 live DT 的这个字段，再和当前 dmesg 对上，结果会告诉我们该修 DT 版本值还是继续盯时序。

Ran terminal command:  cd "$PWD" && adb shell 'for f in /sys/firmware/devicetree/base/soc/spf_core_platform/lpass-cdc/wsa-macro@6B00000/wsa_swr_master/qcom,swr-master-version /sys/firmware/devicetree/base/soc/spf_core_platform/lpass-cdc/wsa2-macro@6AA0000/wsa2_swr_master/qcom,swr-master-version /sys/firmware/devicetree/base/soc/spf_core_platform/rx-macro@6AC0000/rx_swr_master/qcom,swr-master-version /sys/firmware/devicetree/base/soc/spf_core_platform/va-macro@7660000/va_swr_master/qcom,swr-master-version; do echo ===$f===; [ -f "$f" ] && od -An -tx4 "$f" || echo missing; done'

Ran terminal command:  cd "$PWD" && adb shell 'dmesg | grep -i -E "wsa_swr_ctrl|wsa2_swr_ctrl|version specified in dtsi|swr link failed to connect|max limit|Tx core clk enable failed|SSR is in progress" | tail -n 80'

Ran terminal command:  cd "$PWD" && adb shell 'for d in /sys/class/remoteproc/remoteproc*; do [ -d "$d" ] || continue; echo ===$d===; cat "$d/name"; cat "$d/state"; done'

增量结论出来了：live DT 里连 `rx/va` 这些正常工作的 master 也都没有 `qcom,swr-master-version` 文件，所以版本值更像驱动内置默认，不是当前 DT 节点直接提供的属性；接下来我主动重触发一次 WSA reprobe，把“版本不匹配”和“SSR/Tx clk”按当前现场重新采样。

Starting: *判断 SSR 持续状态* (3/3)

我现在只做一次最小复现：点 `wsa_swr_ctrl`/`wsa2_swr_ctrl`，立刻抓日志和绑定状态，目标是区分“持续时序坏状态”还是“偶发残留日志”。

Ran terminal command:  cd "$PWD" && adb shell 'echo wsa_swr_ctrl > /sys/bus/platform/drivers_probe; echo wsa2_swr_ctrl > /sys/bus/platform/drivers_probe; for n in wsa_swr_ctrl wsa2_swr_ctrl; do echo ===$n===; readlink /sys/bus/platform/devices/$n/driver 2>/dev/null || echo unbound; done'

Ran terminal command:  cd "$PWD" && adb shell 'dmesg | grep -i -E "wsa_swr_ctrl|wsa2_swr_ctrl|version specified in dtsi|swr link failed to connect|max limit|Tx core clk enable failed|SSR is in progress|core vote request failed" | tail -n 120'

Ran terminal command:  cd "$PWD" && adb shell 'for f in /sys/bus/platform/devices/lpass-cdc-clk-rsc-mngr/power/runtime_status /sys/bus/platform/devices/lpass-cdc-clk-rsc-mngr/power/runtime_enabled /sys/bus/platform/devices/wsa-macro/power/runtime_status /sys/bus/platform/devices/wsa2-macro/power/runtime_status /sys/bus/platform/devices/tx-macro/power/runtime_status; do echo ===$f===; cat "$f" 2>/dev/null || echo missing; done'

前沿又推进了：这次不再是 `HW read version 0x0 + SSR/Tx clk`，而是稳定复现成 `HW read version 0x2010000 + link status not connected`。这说明上游时钟/SSR 至少在这次 reprobe 时不是首错了，我接下来直接找当前仓库里可修改的 DTBO 补丁源，准备把 WSA master 版本值最小改到 `0x2010000` 做第四版验证。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_dtb_probe)

Searched for files matching `**/audio_dtb_probe/**/entry*.dts`, no matches

Searched for files matching `**/audio_dtb_probe/**/entry*.dtb`, no matches

我先确认补丁源现在落在哪个目录，避免对着旧路径空改；只要能找到现有 DTS/DTBO 产物，就能直接做最小版本修正。

Searched for regex `qcom,wsa-max-devs = <0x03>|qcom,wsa-max-devs = <0x00>|qcom,swr-master-version` (`**/*.{dts,dtsi,txt,md}`), 12 results

Searched for files matching `**/dtbo*.img`, 2 matches

Searched for files matching `**/*vendor_boot*.dtb`, no matches

补丁源目前不在工作区里，直接改第四版 DTBO 还做不了；我先把失败的 `wsa/wsa2` 和能工作的 `rx/va` master 节点属性差出来，找第二个真正缺项，这样即使稍后重建 DTBO 也不会盲改。

Ran terminal command:  cd "$PWD" && adb shell 'for n in /sys/firmware/devicetree/base/soc/spf_core_platform/rx-macro@6AC0000/rx_swr_master /sys/firmware/devicetree/base/soc/spf_core_platform/va-macro@7660000/va_swr_master /sys/firmware/devicetree/base/soc/spf_core_platform/lpass-cdc/wsa-macro@6B00000/wsa_swr_master /sys/firmware/devicetree/base/soc/spf_core_platform/lpass-cdc/wsa2-macro@6AA0000/wsa2_swr_master; do echo ===$n===; ls "$n" | sort | sed -n "1,120p"; done'

Ran terminal command:  cd "$PWD" && adb shell 'for n in rx_swr_ctrl va_swr_ctrl bt_swr_mstr wsa_swr_ctrl wsa2_swr_ctrl; do echo ===$n===; ls /sys/bus/platform/devices/$n 2>/dev/null | sort | sed -n "1,120p"; done'

Ran terminal command:  cd "$PWD" && adb shell 'for n in rx_swr_ctrl va_swr_ctrl bt_swr_mstr wsa_swr_ctrl wsa2_swr_ctrl; do echo ===$n compatible===; tr -d "\000" < /proc/device-tree/soc/spf_core_platform/${n%_*}${n#*_}/compatible 2>/dev/null || true; echo; done'

又钉掉一个可能性：平台设备层面差异非常直接，`rx/va/bt` 成功节点都有子总线 `swr1/2/4`，而 `wsa/wsa2` 失败节点只有裸 platform 设备，没有 `driver` 也没有子总线实例。这说明问题仍然卡在 `swr-mgr` 的 master 初始化本身，不是在更后面的 slave/codec 层。

Ran terminal command:  cd "$PWD" && adb shell 'find /proc/device-tree/soc/spf_core_platform -maxdepth 3 \( -name "rx_swr_master" -o -name "va_swr_master" -o -name "bt_swr_master" -o -name "bt_swr_mstr" \) | sed -n "1,80p"; echo ---; for p in $(find /proc/device-tree/soc/spf_core_platform -maxdepth 3 \( -name "rx_swr_master" -o -name "va_swr_master" -o -name "bt_swr_master" -o -name "bt_swr_mstr" \) 2>/dev/null); do echo ===$p===; ls "$p" | sort | sed -n "1,120p"; done'

我把对照再压一层到具体属性值：看 `rx/va/bt` 和 `wsa/wsa2` 的 `compatible`、`master_id`、设备数、以及是否缺 `is-always-on` / wakeup 类属性，这能判断 WSA 是不是少了某个最小开关。

Ran terminal command:  cd "$PWD" && adb shell 'for n in /proc/device-tree/soc/spf_core_platform/lpass-cdc/rx-macro@6AC0000/rx_swr_master /proc/device-tree/soc/spf_core_platform/lpass-cdc/va-macro@7660000/va_swr_master /proc/device-tree/soc/spf_core_platform/lpass_bt_swr@6CA0000/bt_swr_mstr /proc/device-tree/soc/spf_core_platform/lpass-cdc/wsa-macro@6B00000/wsa_swr_master /proc/device-tree/soc/spf_core_platform/lpass-cdc/wsa2-macro@6AA0000/wsa2_swr_master; do echo ===$n===; echo --compatible--; tr -d "\000" < "$n/compatible"; echo; for p in qcom,swr-num-dev qcom,swr-num-ports qcom,swr_master_id qcom,is-always-on qcom,swr-wakeup-required qcom,swr-mstr-irq-wakeup-capable qcom,dynamic-port-map-supported; do echo --$p--; [ -f "$n/$p" ] && od -An -tx4 "$n/$p" || echo missing; done; done'
Completed with input:  cd "$PWD" && adb shell 'for n in /proc/device-tree/soc/spf_core_platform/lpass-cdc/rx-macro@6AC0000/rx_swr_master /proc/device-tree/soc/spf_core_platform/lpass-cdc/va-macro@7660000/va_swr_master /proc/device-tree/soc/spf_core_platform/lpass_bt_swr@6CA0000/bt_swr_mstr /proc/device-tree/soc/spf_core_platform/lpass-cdc/wsa-macro@6B00000/wsa_swr_master /proc/device-tree/soc/spf_core_platform/lpass-cdc/wsa2-macro@6AA0000/wsa2_swr_master; do echo ===$n===; echo --compatible--; tr -d "\000" < "$n/compatible"; echo; for p in qcom,swr-num-dev qcom,swr-num-ports qcom,swr_master_id qcom,is-always-on qcom,swr-wakeup-required qcom,swr-mstr-irq-wakeup-capable qcom,dynamic-port-map-supported; do echo --$p--; [ -f "$n/$p" ] && od -An -tx4 "$n/$p" || echo missing; done; done'

Ran terminal command:  cd "$PWD" && adb shell 'for n in rx_swr_ctrl va_swr_ctrl bt_swr_mstr wsa_swr_ctrl wsa2_swr_ctrl; do echo ===$n===; readlink /sys/bus/platform/devices/$n/of_node 2>/dev/null || echo missing; done'
Completed with input:  cd "$PWD" && adb shell 'for n in rx_swr_ctrl va_swr_ctrl bt_swr_mstr wsa_swr_ctrl wsa2_swr_ctrl; do echo ===$n===; readlink /sys/bus/platform/devices/$n/of_node 2>/dev/null || echo missing; done'

现在环境里多了不止一个 `adb` 目标，刚才两条只读查询没带序列号所以失败了。我先锁定当前 recovery 设备的序列，再继续对照属性，不会改任何东西。

Ran terminal command:  cd "$PWD" && adb devices

我直接同时看两个 recovery 目标，哪台呈现出同样的 WSA 失败特征，就把后续检查锁到那台，避免误跟另一台设备。

Ran terminal command:  cd "$PWD" && adb -s 3B15AN013GM00000 shell 'dmesg | grep -i -E "wsa_swr_ctrl|wsa2_swr_ctrl|version specified in dtsi|swr link failed to connect" | tail -n 30'

Ran terminal command:  cd "$PWD" && adb -s 70a91f89 shell 'dmesg | grep -i -E "wsa_swr_ctrl|wsa2_swr_ctrl|version specified in dtsi|swr link failed to connect" | tail -n 30'

目标设备锁定了，后续都用 `70a91f89`。我把成功与失败 master 的关键属性值补齐，看看 WSA 是否只是少了 `always-on`/wakeup 这类小开关。

Ran terminal command:  cd "$PWD" && adb -s 70a91f89 shell 'for n in /proc/device-tree/soc/spf_core_platform/lpass-cdc/rx-macro@6AC0000/rx_swr_master /proc/device-tree/soc/spf_core_platform/lpass-cdc/va-macro@7660000/va_swr_master /proc/device-tree/soc/spf_core_platform/lpass_bt_swr@6CA0000/bt_swr_mstr /proc/device-tree/soc/spf_core_platform/lpass-cdc/wsa-macro@6B00000/wsa_swr_master /proc/device-tree/soc/spf_core_platform/lpass-cdc/wsa2-macro@6AA0000/wsa2_swr_master; do echo ===$n===; echo --compatible--; tr -d "\000" < "$n/compatible"; echo; for p in qcom,swr-num-dev qcom,swr-num-ports qcom,swr_master_id qcom,is-always-on qcom,swr-wakeup-required qcom,swr-mstr-irq-wakeup-capable qcom,dynamic-port-map-supported; do echo --$p--; [ -f "$n/$p" ] && od -An -tx4 "$n/$p" || echo missing; done; done'

Ran terminal command:  cd "$PWD" && adb -s 70a91f89 shell 'for n in rx_swr_ctrl va_swr_ctrl bt_swr_mstr wsa_swr_ctrl wsa2_swr_ctrl; do echo ===$n===; readlink /sys/bus/platform/devices/$n/of_node 2>/dev/null || echo missing; done'

现在信息已经足够支持下一步实操了：工作区里没有现成 DTBO 源，但目标设备本身在 recovery。我要直接从这台设备拉当前 `dtbo` 分区下来，用 magiskboot/`dtc` 还原出真实 overlay，再决定要不要做第四版版本修补。

Ran terminal command:  cd "$PWD" && adb -s 70a91f89 shell 'ls -l /dev/block/by-name/dtbo /dev/block/bootdevice/by-name/dtbo 2>/dev/null'
Completed with input:  cd "$PWD" && adb -s 70a91f89 shell 'ls -l /dev/block/by-name/dtbo /dev/block/bootdevice/by-name/dtbo 2>/dev/null'

Ran terminal command:  cd "$PWD" && /Volumes/Case-sensitive\ APFS/TWRP/magiskboot --help | sed -n '1,80p'

Ran terminal command:  cd "$PWD" && command -v dtc || find twrp_a16_compile -path '*dtc' | sed -n '1,5p'

工具链和分区路径都齐了，我开始拉当前 `dtbo_a` 到工作区并还原出 DTS；这一步的结果会直接决定第四版该不该补 `qcom,swr-master-version`。

Created [](file:///Volumes/Case-sensitive%20APFS/TWRP/runtime_dtbo)

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP/runtime_dtbo && adb -s 70a91f89 pull /dev/block/bootdevice/by-name/dtbo_a dtbo_a.img

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP/runtime_dtbo && /Volumes/Case-sensitive\ APFS/TWRP/magiskboot dtb dtbo_a.img print | sed -n '1,120p'

User: 捷豹的文件在这儿

/Users/Laurie/Desktop/nightmare-space/Android_Recovery/rom_extract/extracted_20260318_034751

GitHub Copilot: 我先核对这个提取目录里有没有能直接用来对照的 `dtbo`、`vendor_boot` 和解包后的 DTS/DTB，目标是尽快找到可比当前 recovery 的 stock 基线。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/rom_extract/extracted_20260318_034751)

Searched for files matching `**/*.{dtb,dts,dtbo,img,ko}`, 300 matches

这个提取目录已经有完整分区镜像，我先看里面是否已经解包过 `dtbo`/`vendor_boot`；如果没有，就直接在工作区里做最小解包，不走长链。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/rom_extract/extracted_20260318_034751/vendor_boot)

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/rom_extract/extracted_20260318_034751/boot)

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/rom_extract/extracted_20260318_034751/init_boot)

User: 继续

GitHub Copilot: 我先把你给的提取目录结构摸清，目标是确认 stock 基线里有没有现成的 `dtbo`、`vendor_boot` 或已解包产物，省掉重复解包。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/rom_extract/extracted_20260318_034751' && find . -maxdepth 2 | sed -n '1,200p'

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/rom_extract/extracted_20260318_034751' && find . -maxdepth 3 \( -iname '*dtbo*' -o -iname '*vendor_boot*' -o -iname '*.dts' -o -iname '*.dtb' \) | sed -n '1,200p'

这个提取目录够用了：已经有 `dtbo.img` 和 `vendor_boot/dtb`，但没有现成 DTS。下一步我直接对这两个 stock 产物做只读抽样，先看 WSA/SWR 相关字符串是否在原厂基线里出现。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/rom_extract/extracted_20260318_034751' && strings dtbo.img | rg 'wsa|max-devs|swr|wcd9378|wsa-codec|upd_backends_used' | sed -n '1,200p'

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/rom_extract/extracted_20260318_034751' && strings vendor_boot/dtb | rg 'wsa|max-devs|swr|wcd9378|wsa-codec|upd_backends_used' | sed -n '1,200p'

stock 基线已经给出一个重要对照：`vendor_boot/dtb` 里明确同时包含 `swr0` 和 `swr3`，也有 `wsa_swr_master`/`wsa2_swr_master`。我现在把 `dtbo.img` 那边的输出只读出来，重点看它有没有把这些节点覆写坏。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_ywdAuw0LbRir4Gqjj1JnVeR6__vscode-1774488593073/content.txt)

我先借用仓库里已经验证过的 DTBO 提取经验，目标是避免重新踩一次 table/offset 的坑，然后直接把 stock `dtbo.img` 解成可比的 DTS。

Read memory twrp_audio_dtb_extraction_tricks.md

仓库记忆里有个已验证过的关键点：stock overlay 本来就会把 `upd_backends_used` 写成 `wsa`，但 `asoc-codec-names` 只有 3 项，所以这条线不能再当 recovery 特异异常。现在我直接把你给的 stock `vendor_boot/dtb` 反编译，再确认 `sound` 与 WSA master 的原厂值。

Searched for files matching `**/dtc`, 6 matches

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/rom_extract/extracted_20260318_034751' && rg -n 'dtc' '/Volumes/Case-sensitive APFS/TWRP' -g '!**/.git/**' | sed -n '1,40p'

User: 现在换你执行，继续之前的任务

GitHub Copilot: Compacted conversation

 


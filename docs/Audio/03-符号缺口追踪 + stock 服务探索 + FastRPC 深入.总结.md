# 03-符号缺口追踪 + stock 服务探索 + FastRPC 深入 — 结构化总结

> 原始行范围：1-867

---

## 1. Compacted conversation 后重接：确认当前状况

对话 compact 后重新开始。此前已验证 `modules.alias` 中 `si,sia81xx` 绑定到 `oplus_audio_sipa`；`audio_pkt_dlkm` 缺 `msm_audio_ion_*` 符号（`audpkt_ion_dlkm` 是导出者）；`boot_adsp/boot` 和 `ssr` 两条路径均能触发 ADSP 重装，但 APM 仍不 ready；`vendor_a`/`odm_a` 已手动挂载，`audioadsprpcd`/`adsprpcd`/`audiohalservice.qti` 已手工拉起，但声卡仍没出现。

接上时 `adsp_loader` 在 probe 时重复注册 `audio_notifier_ssr_adsp_cb`，内核报 `already registered`——不能再碰 `adsp_loader` 的卸载/重载，应保留它常驻，只用 `remoteproc` 去重新拉起 ADSP。

采样当前模块状态和 GPR 设备：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'cat /sys/class/remoteproc/remoteproc1/state; echo ---; lsmod | grep -E "adsp_loader|q6_pdr|q6_notifier|gpr_dlkm|spf_core|snd_event|audio_prm|audio_pkt|machine_dlkm|wcd|lpass_cdc|swr"; echo ---; ls -l /sys/bus/gprbus/devices; echo ---; cat /proc/asound/cards; echo ---; ls -l /dev/snd'
```

查看 related dmesg：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'dmesg | grep -i -E "audio_notifier_ssr_adsp_cb|already registered|gpr_remove|Adding GPR dev|apm is not up|q6 state is down|remoteproc-adsp" | tail -n 120'
```

结果显示 `adsp_loader/q6/gpr/spf` 链都还在内核里，但 GPR 设备节点已经没了，ALSA 还是空。

---

## 2. 纯 remoteproc stop/start：GPR 未恢复

不动任何模块，只用 `remoteproc stop/start` 验证 GPR 能否重新挂回。如果这样都回不来，根因就不是装载顺序，而是 recovery 里缺少把 `adsp_loader` 和重启后的 ADSP 再次绑定起来的触发。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo stop > /sys/class/remoteproc/remoteproc1/state; sleep 2; cat /sys/class/remoteproc/remoteproc1/state; echo ---; echo start > /sys/class/remoteproc/remoteproc1/state; sleep 3; cat /sys/class/remoteproc/remoteproc1/state; echo ---; ls -l /sys/bus/gprbus/devices; echo ---; dmesg | grep -i -E "audio_notifier_ssr_adsp_cb|Adding GPR dev|gpr_remove|remoteproc-adsp|apm is not up|q6 state is down" | tail -n 120; echo ---; cat /proc/asound/cards; echo ---; ls -l /dev/snd'
```

纯 `remoteproc` 重启没有把 GPR 拉回来，说明不是"ADSP 没起来"，而是"ADSP 起了但相关 platform/gpr 侧没再完成 attach"。

---

## 3. 检查 platform 绑定关系

接着看 sysfs 里的 platform 绑定关系，确认到底是 `adsp_loader`、`gpr` 还是 `spf_core_platform` 没有 probe 到位。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'for d in /sys/bus/platform/drivers/adsp-loader /sys/bus/platform/drivers/qcom-spf-core /sys/bus/platform/drivers/spf-core-platform /sys/bus/gprbus/drivers/qcom-spf_core /sys/bus/platform/devices/*adsp* /sys/bus/platform/devices/*spf* /sys/bus/platform/devices/*audio*; do echo ===$d===; ls -l $d 2>/dev/null; done'
```

查找 platform devices 中所有音频相关设备：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'find /sys/bus/platform/devices -maxdepth 1 \( -name "*adsp*" -o -name "*gpr*" -o -name "*spf*" -o -name "*audio*" -o -name "*q6*" \) | sort'
```

查看 adsp_loader/spf_core/gpr/q6 的 dmesg：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'dmesg | grep -i -E "adsp_loader|spf_core|gpr|q6_pdr|q6_notifier|audio-pkt|q6prm" | tail -n 160'
```

结果表明 `adsp_loader` 和 `spf_core_platform` 的 platform 设备都还绑着，不是"驱动根本没挂上"，真正断掉的是 GPR 设备实例本身。

接着查这些设备节点下面有没有能手动触发重新握手的 sysfs 属性。优先找不需要重新装模块的方法：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo === adsp-loader device ===; ls -l /sys/devices/platform/soc/soc:qcom,msm-adsp-loader; echo ---; find /sys/devices/platform/soc/soc:qcom,msm-adsp-loader -maxdepth 2 -type f | sort; echo === remoteproc-adsp ===; ls -l /sys/devices/platform/soc/3000000.remoteproc-adsp; echo ---; find /sys/devices/platform/soc/3000000.remoteproc-adsp -maxdepth 2 -type f | sort; echo === spf_core_platform ===; ls -l /sys/devices/platform/soc/soc:spf_core_platform; echo ---; find /sys/devices/platform/soc/soc:spf_core_platform -maxdepth 2 -type f | sort'
```

查找 gpr/spf 相关的可操作节点：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'find /sys -path "*gpr*" -o -path "*spf*" | grep -E "(state|enable|boot|ssr|subsys|restart|online|load|probe|uevent)$" | sort | tail -n 200'
```

`adsp_loader` 设备下面几乎没有可操作节点，说明它不像 Wi‑Fi 那样能靠 shell 直接触发重跑。可疑点转到了 rpmsg/gpr 总线这一层。

---

## 4. 关键发现：remoteproc1 ≠ ADSP，它是 CDSP

看 rpmsg 总线发现一个更大的问题：rpmsg 总线上现在只有 `cdsp` 的端点，没有任何 `adsp` 的 glink/rpmsg 端点。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo === rpmsg devices ===; ls -l /sys/bus/rpmsg/devices 2>/dev/null; echo ---; echo === rpmsg qcom,gpr driver ===; ls -l /sys/bus/rpmsg/drivers/qcom,gpr 2>/dev/null; echo ---; find /sys/bus/rpmsg/devices -maxdepth 1 -type l 2>/dev/null | sort; echo ---; find /sys/bus/rpmsg/drivers/qcom,gpr -maxdepth 1 \( -type l -o -type f \) 2>/dev/null | sort'
```

查各总线的 drivers_probe 和 autoprobe 状态：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'for p in /sys/bus/rpmsg/drivers_probe /sys/bus/gprbus/drivers_probe /sys/bus/platform/drivers_probe /sys/bus/rpmsg/drivers_autoprobe /sys/bus/gprbus/drivers_autoprobe; do echo ===$p===; cat $p 2>/dev/null; done'
```

也就是说，之前一直操作的 `remoteproc1` 很可能根本不是 ADSP，而是 CDSP。这会直接解释为什么 state 变成 running 但音频链完全没回来。把 `/sys/class/remoteproc` 的映射查清楚：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'ls -l /sys/class/remoteproc; echo ---; for d in /sys/class/remoteproc/remoteproc*; do echo ===$d===; readlink $d; cat $d/name 2>/dev/null; cat $d/state 2>/dev/null; done'
```

根因确认：**`remoteproc1` 实际是 `cdsp`，真正的音频 DSP 是 `remoteproc0`，而它一直是 `offline`**。这就解释了为什么 GPR/ALSA 一直不回来。

---

## 5. 启动真正的 ADSP (remoteproc0)

纠正映射后只动真正的 ADSP：启动 `remoteproc0`，立刻看 rpmsg、gprbus 和 ALSA 有没有恢复。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo start > /sys/class/remoteproc/remoteproc0/state; sleep 4; echo === states ===; for d in /sys/class/remoteproc/remoteproc0 /sys/class/remoteproc/remoteproc1; do echo ---$d---; cat $d/name; cat $d/state; done; echo === rpmsg adsp/cdsp ===; ls -l /sys/bus/rpmsg/devices | grep -E "remoteproc-(adsp|cdsp)|glink-edge"; echo === gprbus ===; ls -l /sys/bus/gprbus/devices; echo === key logs ===; dmesg | grep -i -E "audio_notifier_ssr_adsp_cb|Adding GPR dev|gpr_remove|remoteproc-adsp|apm is not up|q6 state is down|spf_core_platform|gpr" | tail -n 160; echo === alsa ===; cat /proc/asound/cards; echo ---; ls -l /dev/snd'
```

真正 ADSP 起来后，rpmsg 和 `gprsvc:*` 也恢复了。剩下的卡点就是 `spf_core_platform` 在打 APM 命令时仍然报 `q6 state is down`——这通常说明 `q6_pdr/q6_notifier/gpr/spf` 链是在 DSP 没起来时就先加载了，内部状态没刷新。

---

## 6. 在正确 ADSP 下重建 q6/gpr/spf 链 → PDR_ADSP 污染

不动 `adsp_loader`，只卸掉重插 `spf_core/snd_event/gpr/q6_notifier/q6_pdr`：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'for m in spf_core_dlkm snd_event_dlkm gpr_dlkm q6_notifier_dlkm q6_pdr_dlkm; do rmmod $m 2>/dev/null && echo rm:$m; done; for m in q6_pdr_dlkm.ko q6_notifier_dlkm.ko gpr_dlkm.ko snd_event_dlkm.ko spf_core_dlkm.ko; do insmod /vendor_dlkm/lib/modules/$m && echo ins:$m:ok || echo ins:$m:fail; done; sleep 3; echo === lsmod ===; lsmod | grep -E "adsp_loader|q6_pdr|q6_notifier|gpr_dlkm|spf_core|snd_event"; echo === gprbus ===; ls -l /sys/bus/gprbus/devices; echo === logs ===; dmesg | grep -i -E "audio_notifier_ssr_adsp_cb|Adding GPR dev|gpr_probe|apm is not up|q6 state is down|spf_core_platform|gpr_send_pkt" | tail -n 120; echo === alsa ===; cat /proc/asound/cards; echo ---; ls -l /dev/snd'
```

adsp/gprsvc 已经恢复，但 `q6 state is down` 还是没翻过来，而且这次重建没有成功，因为这些模块根本没卸下来。查 `q6_pdr/q6_notifier` 在 ADSP 真正启动后的日志：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'dmesg | grep -i -E "q6_pdr|q6_notifier|pdr|sysmon|audio_ssr|spf|apm|audio-pkt|q6prm|adsp_loader" | tail -n 220'
```

日志给出更具体的阻塞点：`audio_notifier_reg_service: service PDR_ADSP is in use`。这不是"模块没在"，而是前面那次错误地重插 `adsp_loader` 之后，把 ADSP 的 PDR/notifier 状态污染了，导致后面即使真正拉起 `remoteproc0`，`spf_core` 仍然拿到一个失效的 Q6 状态。这个状态在当前内核里很难靠再卸载一次清干净，最直接的恢复办法是重启回 recovery，按正确顺序只启动真正的 ADSP。

---

## 7. 重启 recovery 清污染

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 reboot recovery
```

等待设备重进 recovery：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && for i in $(seq 1 60); do adb devices | grep -q '70a91f89[[:space:]]*recovery' && break; sleep 2; done; adb devices
```

不再碰 `remoteproc1`，先用正确顺序验证基线：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'ls -l /sys/class/remoteproc; echo ---; for d in /sys/class/remoteproc/remoteproc*; do echo ===$d===; cat $d/name; cat $d/state; done; echo ---; lsmod | grep -E "adsp_loader|q6_pdr|q6_notifier|gpr_dlkm|spf_core|snd_event|audio_prm|audio_pkt|machine_dlkm|wcd|lpass_cdc|swr"; echo ---; cat /proc/asound/cards; echo ---; ls -l /dev/snd'
```

查看关键 dmesg 确认污染已清除：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'dmesg | grep -i -E "audio_notifier_reg_service|already registered|remoteproc-adsp|gpr_probe|Adding GPR dev|q6 state is down|apm is not up|spf_core_platform" | tail -n 160'
```

重启后状态更干净了，也更明确了：现在不是"污染态"了，而是标准的 `apm is not up`。真正的 ADSP 已经按 recovery 默认流程起来了，但 APM 侧还没被后续音频模块链拉起来。

---

## 8. 全量加载音频模块链：发现符号缺口

在干净基线上按序加载完整 codec/machine 链：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell '
mods="audio_prm_dlkm.ko audio_pkt_dlkm.ko audpkt_ion_dlkm.ko lpass_cdc_dlkm.ko swr_dlkm.ko swr_ctrl_dlkm.ko wcd_core_dlkm.ko mbhc_dlkm.ko wcd9xxx_dlkm.ko wcd939x_dlkm.ko wcd939x_slave_dlkm.ko lpass_cdc_rx_macro_dlkm.ko lpass_cdc_tx_macro_dlkm.ko lpass_cdc_wsa_macro_dlkm.ko lpass_cdc_wsa2_macro_dlkm.ko wsa883x_dlkm.ko wsa884x_dlkm.ko wcd9378_dlkm.ko wcd9378_slave_dlkm.ko oplus_audio_extend.ko oplus_audio_pa_manager.ko oplus_audio_sipa.ko oplus_audio_sipa_tuning.ko oplus_audio_aw87xxx.ko oplus_audio_aw882xx.ko machine_dlkm.ko";
for m in $mods; do insmod /vendor_dlkm/lib/modules/$m >/dev/null 2>&1 && echo ins:$m:ok || echo ins:$m:skip; done;
sleep 4;
echo === loaded ===;
lsmod | grep -E "audio_prm|audio_pkt|audpkt_ion|lpass_cdc|swr(_ctrl)?|wcd9|wcd93|wcd9378|wsa88|machine_dlkm|oplus_audio_";
echo === logs ===;
dmesg | grep -i -E "apm is not up|q6 state is down|audio_prm|audio_pkt|lpass_cdc|wcd|wsa|machine|snd_soc|asoc|spf_core_platform" | tail -n 220;
echo === alsa ===;
cat /proc/asound/cards; echo ---; cat /proc/asound/pcm 2>/dev/null; echo ---; ls -l /dev/snd'
```

问题从"DSP 没起来"缩到"缺具体依赖模块"了，日志把缺的符号直接点名了。关键缺口：`oplus_audio_daemon`、`audpkt_ion_dlkm`、`swr_ctrl_dlkm`，还有一组 `wcd_cal / wcd_cls_h / sdca` 相关提供者。

列出 vendor_dlkm 里现成可用的音频相关 ko：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'ls /vendor_dlkm/lib/modules | grep -E "audio|audpkt|wcd|swr|lpass|sdca|cls|cal|machine|mbhc|prm|pkt|oplus_audio" | sort'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'ls /vendor_dlkm/lib/modules | grep -E "wcd|cal|cls|sdca|register|daemon|ion|audio" | sort'
```

在 `/proc/kallsyms` 中逐一验证缺失符号：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'for s in oplus_is_daemon_event_id oplus_audio_daemon_feedback_event msm_audio_ion_crash_handler msm_audio_get_phy_addr audio_prm_set_lpass_clk_cfg audio_prm_set_lpass_hw_core_req swrm_wcd_notify wcd939x_slave_register_notify wcd_cal_create_hwdep wcd_cls_h_init wcd_cls_h_fsm wcdcal_get_fw_cal sdca_devices_debugfs_dentry_create sdca_devices_debugfs_dentry_remove; do echo ===$s===; grep -w " $s" /proc/kallsyms | head; done'
```

`/proc/kallsyms` 说明这些符号现在一个都没导出来——不是"模块已加载但状态不对"，而是真缺 provider。

---

## 9. 补 provider 模块后重试主链

先把明显的 provider 模块补进来：`oplus_audio_daemon`、`oplus_audio_netlink`、`audpkt_ion_dlkm`、`sdca_registers_dlkm`、`swr_ctrl_dlkm`，再重试之前失败的模块：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell '
for m in oplus_audio_daemon.ko oplus_audio_netlink.ko audpkt_ion_dlkm.ko sdca_registers_dlkm.ko swr_ctrl_dlkm.ko wcd938x_slave_dlkm.ko wcd938x_dlkm.ko; do insmod /vendor_dlkm/lib/modules/$m && echo ins:$m:ok || echo ins:$m:fail; done;
echo === symbols after providers ===;
for s in oplus_is_daemon_event_id oplus_audio_daemon_feedback_event msm_audio_ion_crash_handler msm_audio_get_phy_addr swrm_wcd_notify wcd_cal_create_hwdep wcd_cls_h_init wcd_cls_h_fsm wcdcal_get_fw_cal sdca_devices_debugfs_dentry_create sdca_devices_debugfs_dentry_remove; do echo ---$s---; grep -w " $s" /proc/kallsyms | head -n 2; done;
echo === retry failed modules ===;
for m in audio_prm_dlkm.ko audio_pkt_dlkm.ko wcd9xxx_dlkm.ko wcd939x_dlkm.ko lpass_cdc_rx_macro_dlkm.ko lpass_cdc_wsa_macro_dlkm.ko lpass_cdc_wsa2_macro_dlkm.ko wcd9378_dlkm.ko machine_dlkm.ko; do insmod /vendor_dlkm/lib/modules/$m && echo retry:$m:ok || echo retry:$m:fail; done;
sleep 3;
echo === alsa ===; cat /proc/asound/cards; echo ---; cat /proc/asound/pcm 2>/dev/null; echo ---; ls -l /dev/snd;
echo === last logs ===; dmesg | tail -n 160'
```

又推进了一步：`audio_prm_probe: prm probe success`，说明 APM/Q6 这一层终于活了。新的主阻塞换成了 `spf_core_platform` 创建 device link 失败，目标全是 `vote_lpass_*` 和一串 `*_clk` provider。DSP 和主音频栈都起来了，但 LPASS 时钟/投票相关 platform provider 没有就位，ASoC 还没能完成注册。

---

## 10. 查 LPASS provider device link 时序问题

确认 `vote_lpass_*`/`*_clk` provider 在 sysfs 里是否存在、是否只是没绑定：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo === providers ===; for n in vote_lpass_core_hw vote_lpass_audio_hw va_core_clk rx_core_clk rx_core_tx_clk tx_core_clk rx_mclk2_2x_clk bt_swr_mclk_clk bt_swr_mclk_clk_2x; do echo ---$n---; find /sys/bus/platform/devices -maxdepth 1 -name "soc:$n" -o -name "*$n*"; done; echo === sound ===; ls -l /sys/class/sound 2>/dev/null; echo ---; find /sys/devices/platform/soc -maxdepth 1 \( -name "*snd*" -o -name "*asoc*" -o -name "*audio*" -o -name "*lpass*" -o -name "*vote*" \) | sort'
```

查看 device link 相关 dmesg：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'dmesg | grep -i -E "device link|vote_lpass|va_core_clk|rx_core_clk|tx_core_clk|snd_soc|asoc|machine_dlkm|sun-asoc-snd|audio_prm_probe|audio_pkt|wcd9xxx|wcd939x|wcd9378" | tail -n 220'
```

设备掉线，等 adb 回来：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && for i in $(seq 1 60); do adb devices | grep -q '70a91f89[[:space:]]*recovery' && break; sleep 2; done; adb devices
```

重连后再次确认 provider 存在性和 dmesg：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo === providers ===; for n in vote_lpass_core_hw vote_lpass_audio_hw va_core_clk rx_core_clk rx_core_tx_clk tx_core_clk rx_mclk2_2x_clk bt_swr_mclk_clk bt_swr_mclk_clk_2x; do echo ---$n---; find /sys/bus/platform/devices -maxdepth 1 \( -name "soc:$n" -o -name "*$n*" \); done; echo === sound ===; ls -l /sys/class/sound 2>/dev/null; echo ---; find /sys/devices/platform/soc -maxdepth 1 \( -name "*snd*" -o -name "*asoc*" -o -name "*audio*" -o -name "*lpass*" -o -name "*vote*" \) | sort'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'dmesg | grep -i -E "device link|vote_lpass|va_core_clk|rx_core_clk|tx_core_clk|snd_soc|asoc|machine_dlkm|sun-asoc-snd|audio_prm_probe|audio_pkt|wcd9xxx|wcd939x|wcd9378" | tail -n 220'
```

现在可以确定两层事实：`audio_prm/audio_pkt/wcd/machine` 主链已经能装起来了；阻塞点转向了 `spf_core_platform` 对 LPASS provider 建立 device link 失败。这些 provider 节点其实存在，接下来查的不是"有没有"，而是"有没有绑定到正确 driver"。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo === lsmod ===; lsmod | grep -E "audio_prm|audio_pkt|audpkt_ion|oplus_audio_daemon|swr_ctrl|wcd938x_slave|wcd9xxx|wcd939x|wcd9378|machine_dlkm|lpass_cdc_rx|lpass_cdc_wsa|lpass_cdc_wsa2"; echo === providers driver ===; for n in vote_lpass_core_hw vote_lpass_audio_hw va_core_clk rx_core_clk rx_core_tx_clk tx_core_clk rx_mclk2_2x_clk bt_swr_mclk_clk bt_swr_mclk_clk_2x; do p=/sys/devices/platform/soc/soc:$n; echo ---$n---; ls -l $p 2>/dev/null; done'
```

查看 probe success 日志：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'dmesg | grep -i -E "probe success|registered sound card|soc card|asoc:|snd_soc_register_card|machine|wcd939x.*probe|wcd9378.*probe|audio_pkt.*probe|audio_prm.*probe|lpass_cdc.*probe" | tail -n 220'
```

LPASS provider 现在都在，而且都已经绑定到了 `audio-ref-clk`。之前的 device link 失败大概率只是时序问题：`spf_core_platform` 当时 probe 太早，provider 还没就绪，但它后面没有自动重试。

---

## 11. 重绑 spf_core_platform + ADSP restart

在 provider 已经在线的情况下，只重绑 `spf_core_platform`：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/unbind; sleep 1; echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/bind; sleep 3; echo === sound ===; cat /proc/asound/cards; echo ---; cat /proc/asound/pcm 2>/dev/null; echo ---; ls -l /dev/snd; echo === logs ===; dmesg | grep -i -E "spf_core_platform|device link|snd_soc|asoc|soc card|registered sound card|apm is not up|q6 state is down" | tail -n 220'
```

这次重绑证明 `spf_core_platform` 确实重新 probe 了，但它重新回来时又落回了 `q6 state is down`。结合完整主链已经都在，反过来做一次真正的 ADSP restart——让已经装好的 `audio_prm/audio_pkt/wcd/machine` 在 DSP 重启事件里重新完成注册，而不是先有 DSP、后补模块：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo stop > /sys/class/remoteproc/remoteproc0/state; sleep 2; cat /sys/class/remoteproc/remoteproc0/state; echo ---; echo start > /sys/class/remoteproc/remoteproc0/state; sleep 6; cat /sys/class/remoteproc/remoteproc0/state; echo === gprbus ===; ls -l /sys/bus/gprbus/devices; echo === alsa ===; cat /proc/asound/cards; echo ---; cat /proc/asound/pcm 2>/dev/null; echo ---; ls -l /dev/snd; echo === logs ===; dmesg | grep -i -E "audio_notifier_ssr_adsp_cb|audio_prm_probe|audio_pkt|machine|spf_core_platform|apm is not up|q6 state is down|registered sound card|snd_soc|asoc|Adding GPR dev|gpr_probe" | tail -n 260'
```

ADSP restart 把 adb 打断了，这反而说明确实碰到了真正的音频 DSP 重启路径。等设备回到 recovery：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && for i in $(seq 1 90); do adb devices | grep -q '70a91f89[[:space:]]*recovery' && break; sleep 2; done; adb devices
```

重连后检查这次 restart 之后的最终状态：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo === remoteproc ===; cat /sys/class/remoteproc/remoteproc0/state; echo ---; ls -l /sys/bus/gprbus/devices; echo === alsa ===; cat /proc/asound/cards; echo ---; cat /proc/asound/pcm 2>/dev/null; echo ---; ls -l /dev/snd; echo === lsmod ===; lsmod | grep -E "machine_dlkm|audio_prm|audio_pkt|wcd9xxx|wcd939x|wcd9378|lpass_cdc_rx|lpass_cdc_wsa|swr_ctrl|oplus_audio_daemon"'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'dmesg | grep -i -E "audio_notifier_ssr_adsp_cb|audio_prm_probe|audio_pkt|machine|spf_core_platform|apm is not up|q6 state is down|registered sound card|snd_soc|asoc|Adding GPR dev|gpr_probe" | tail -n 260'
```

完整音频模块链都在，但这次重启把真正的 ADSP 留在了 `offline`。这已经不是"不会触发"，而是"触发后 DSP 没恢复"。

最后一轮最小动作：直接把 `remoteproc0` 再拉起一次，观察完整模块链常驻时 GPR 和 ALSA 是否会回来：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo start > /sys/class/remoteproc/remoteproc0/state; sleep 6; echo === remoteproc ===; cat /sys/class/remoteproc/remoteproc0/state; echo === gprbus ===; ls -l /sys/bus/gprbus/devices; echo === alsa ===; cat /proc/asound/cards; echo ---; cat /proc/asound/pcm 2>/dev/null; echo ---; ls -l /dev/snd; echo === logs ===; dmesg | grep -i -E "audio_notifier_ssr_adsp_cb|audio_prm_probe|spf_core_platform|apm is not up|q6 state is down|registered sound card|snd_soc|asoc|Adding GPR dev|'
```

再次触发 adb 中断。等回来后做最后一次状态核对：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && for i in $(seq 1 90); do adb devices | grep -q '70a91f89[[:space:]]*recovery' && break; sleep 2; done; adb devices
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'cat /sys/class/remoteproc/remoteproc0/state; echo ---; ls -l /sys/bus/gprbus/devices; echo ---; cat /proc/asound/cards; echo ---; ls -l /dev/snd'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'dmesg | grep -i -E "audio_notifier_ssr_adsp_cb|remoteproc-adsp|gpr_remove|Adding GPR dev|q6 state is down|apm is not up|subsystem event accepted|stopped remote processor|remote processor .* is now up" | tail -n 220'
```

这轮手动 bring-up 已经把问题收敛到很具体：真正音频 DSP 是 `remoteproc0`；完整音频链在 recovery 里手动装起来了；`audio_prm_probe: prm probe success` 已出现，`gprsvc:spf_core/q6prm/audio-pkt` 也能恢复。但 ALSA 仍没有注册出来，`/proc/asound/cards` 还是 `--- no soundcards ---`。

硬阻塞非常明确——即使 `remoteproc0` 处于 `running`，日志仍持续刷 `gpr_send_pkt: q6 state is down`，`spf_core_platform` 会不断卡在 APM 检查阶段。问题已经不是"少装哪个 codec ko"，而是 recovery 里缺了让 Q6 状态真正转成 ready 的那一步。

---

## 12. 搜索仓库和设备侧音频触发配置

不再碰源码，直接找出 recovery 里还缺的那个"把 Q6 状态从 down 推到 ready"的触发点。先并行查两边的证据：仓库里的 vendor/init 配置，以及设备当前分区里的音频相关 rc 和节点。

仓库并行搜索：
- regex `sm87xx|sun recovery|audio-ref-clk|vote_lpass_core_hw|vote_lpass_audio_hw|boot_adsp|spf_core_platform|q6_pdr|q6_notifier`
- regex `audio.*bring[- ]?up|bring[- ]?up.*audio|adsp|lpass|spf|q6` (`**/*.rc`) → 56 results
- regex `audio-ref-clk|vote_lpass_core_hw|vote_lpass_audio_hw|boot_adsp|spf_core_platform|q6_pdr|q6_notifier|adsp|lpass|spf|q6` (`**/*.{sh,rc,xml,conf,txt,te,mak,mk,bp,prop}`) → 200 results
- files matching `**/*init*.rc` → 65 matches; `**/*audio*` → 200 matches; `**/*q6*` → 2 matches
- text `audio-ref-clk` (`**/device_tree/**`) → no results
- regex `vote_lpass_core_hw|vote_lpass_audio_hw` (`**/device_tree/**`) → no results
- text `boot_adsp` (`**/device_tree/**`) → 12 results
- regex `spf_core_platform|q6_pdr|q6_notifier` (`**/device_tree/**`) → no results
- regex `adsp|lpass|spf|q6` (`**/device_tree/**/*.rc`) → 52 results
- regex `adsp|lpass|spf|q6` (`**/device_tree/**/*.{sh,xml,conf,prop,mk,bp}`) → 9 results
- files matching `**/device_tree/twrp_device_xiaomi_sm8750_thales/recovery/root/vendor/etc/init/*` → 7 matches
- files matching `**/device_tree/twrp_device_xiaomi_sm8750_thales/recovery/root/odm/etc/init/*` → 8 matches
- files matching `**/device_tree/twrp_device_xiaomi_sm8750_thales/recovery/root/system/etc/init/*` → no matches
- files matching `**/device_tree/twrp_device_xiaomi_sm8750_thales/recovery/root/**/*.rc` → 21 matches
- files matching `**/device_tree/twrp_device_xiaomi_sm8750_thales/recovery/root/**/*.sh` → 4 matches

设备侧搜索音频 init 服务和属性：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'for d in /vendor/etc/init /vendor/etc /odm/etc/init /odm/etc /system_ext/etc/init /system/etc/init; do [ -d "$d" ] && echo ===$d=== && grep -RniE "audio|adsp|lpass|spf|q6|oplus_audio|audio-ref-clk|vote_lpass" "$d" 2>/dev/null | head -n 240; done'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo === driver dirs ===; for d in /sys/bus/platform/drivers/audio-ref-clk /sys/bus/platform/drivers/spf-core-platform /sys/bus/platform/drivers/adsp-loader; do echo ---$d---; ls -l $d 2>/dev/null; done; echo === props ===; getprop | grep -iE "audio|adsp|lpass|q6|vendor.audio|sys.audio|init.svc.*audio|oplus.audio" | head -n 240'
```

增量结果有两个关键点：设备分区里几乎没有额外的音频 init 服务，说明缺的更像是内核侧重探测时序，不是用户态守护进程没起。

---

## 13. 查 platform 驱动和 sound 设备实例

区分两种可能：一是 `machine_dlkm` 已经装了但根本没 probe 到平台设备，二是 probe 了但卡死在更后面。

查看所有 platform 和 rpmsg 驱动：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo === platform drivers ===; find /sys/bus/platform/drivers -maxdepth 1 \( -name "*machine*" -o -name "*snd*" -o -name "*audio*" -o -name "*asoc*" -o -name "*wcd*" -o -name "*lpass*" \) | sort; echo === rpmsg drivers ===; find /sys/bus/rpmsg/drivers -maxdepth 1 \( -name "*audio*" -o -name "*gpr*" -o -name "*spf*" \) | sort'
```

查找 platform soc 下是否有 sound/snd/asoc/machine 设备路径：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'find /sys/devices/platform/soc -path "*snd*" -o -path "*asoc*" -o -path "*machine*" -o -path "*sound*" | sort | head -n 300'
```

查看 machine 和 codec probe 日志：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'dmesg | grep -iE "machine_dlkm|sun-asoc|asoc-snd|snd card|audio_prm_probe|audio_pkt_probe|wcd9xxx.*probe|wcd939x.*probe|wcd9378.*probe|lpass_cdc.*probe|spf_core_add_child_devices" | tail -n 260'
```

日志出现过一次 `spf_core_add_child_devices: enumarate machine driver`，说明 machine 路径至少被尝试过一次。现在直接查 `sun-asoc-snd` 当前有没有绑定对象：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'for d in /sys/bus/platform/drivers/sun-asoc-snd /sys/bus/platform/drivers/soc-audio /sys/bus/platform/drivers/audio-pkt /sys/bus/platform/drivers/audio-extend-drv /sys/bus/platform/drivers/lpass-cdc; do echo ===$d===; ls -l $d 2>/dev/null; done'
```

查找 platform devices 中所有音频相关设备实例：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'find /sys/bus/platform/devices -maxdepth 1 \( -name "*snd*" -o -name "*sound*" -o -name "*audio*" -o -name "*lpass*" -o -name "*wcd*" \) | sort'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'for p in /sys/bus/platform/drivers/sun-asoc-snd/bind /sys/bus/platform/drivers/sun-asoc-snd/unbind /sys/bus/platform/drivers/soc-audio/bind; do echo ===$p===; [ -e "$p" ] && ls -l "$p" && cat "$p" 2>/dev/null; done'
```

现在更像是 `sun-asoc-snd` 驱动已经注册，但对应的平台设备根本没有出现在 `/sys/bus/platform/devices`，所以它没有任何绑定对象。下一步直接核对设备树里的 sound 节点和 platform 设备实例是否断在"创建设备"这一步。

---

## 14. 设备树 sound 节点确认

查 DT 中 sound 节点的属性和 platform 设备实例：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo === dt sound nodes ===; find /sys/firmware/devicetree/base/soc -maxdepth 2 \( -name "sound" -o -name "*asoc*" -o -name "*snd*" \) | sort; echo === sound compatible ===; for n in /sys/firmware/devicetree/base/soc/sound* /sys/firmware/devicetree/base/soc/*sound* /sys/firmware/devicetree/base/soc/*asoc*; do [ -d "$n" ] || continue; echo ---$n---; for f in compatible status model qcom,msm-audio-card-name label; do [ -f "$n/$f" ] && echo $f: && cat "$n/$f" | tr "\0" "\n"; done; done'
```

确认没有任何平台设备实例的 of_node 指向 sound：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo === platform devices of/sound candidates ===; for d in /sys/bus/platform/devices/*; do [ -L "$d/of_node" ] || continue; target=$(readlink "$d/of_node"); case "$target" in *sound*|*asoc*|*snd* ) echo $d; echo of:$target; ls -l "$d"; echo ---;; esac; done'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'cat /sys/bus/platform/drivers_autoprobe; echo ---; cat /sys/bus/platform/drivers_probe 2>/dev/null; echo ---; ls -l /sys/bus/platform/drivers/sun-asoc-snd'
```

读 spf_core_platform/sound 节点的所有属性：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo === dt sound files ===; find /sys/firmware/devicetree/base/soc/spf_core_platform/sound -maxdepth 1 -type f | sort | while read f; do echo ---$f---; cat "$f" | tr "\0" "\n"; done'
```

查看 spf_core_platform 下是否有子设备目录：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo === spf_core_platform tree ===; find /sys/devices/platform/soc/soc:spf_core_platform -maxdepth 3 | sort | head -n 300'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'grep -Rsl "spf_core_platform/sound\|/soc/spf_core_platform/sound" /sys/devices /sys/bus 2>/dev/null | head -n 50'
```

现在定位到更根上的断点了：设备树里确实有 `spf_core_platform/sound` 子节点（compatible=`qcom,msm-audio-card-sun`，无 disabled），但系统里没有任何一个设备实例把 of_node 指向它，`spf_core_platform` 下面也没有任何子设备目录。这已经是"sound 子设备根本没被创建出来"，最可能的根因还是底层状态机卡住。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo === dt sound files ===; find /sys/firmware/devicetree/base/soc/spf_core_platform/sound -maxdepth 1 -type f | sort | while read f; do echo ---$f---; cat "$f" | tr "\0" "\n"; done'

cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo === spf_core_platform tree ===; find /sys/devices/platform/soc/soc:spf_core_platform -maxdepth 3 | sort | head -n 300'

cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'grep -Rsl "spf_core_platform/sound\|/soc/spf_core_platform/sound" /sys/devices /sys/bus 2>/dev/null | head -n 50'
```

现在最可能的根因还是底层状态机卡住，而不是缺模块。
---

## 15. 完整重建音频链（决定性测试）

既然 sound 节点根本没实例化出来，把整条音频链按"ADSP 已运行"的前提完整重建一次，尤其把 `adsp_loader` 也干净卸掉重来：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell '
set -x
mods_unload="machine_dlkm oplus_audio_pa_manager oplus_audio_sipa_tuning oplus_audio_sipa oplus_audio_aw87xxx oplus_audio_aw882xx oplus_audio_extend oplus_audio_netlink oplus_audio_daemon wcd9378_dlkm wcd939x_dlkm wcd9xxx_dlkm lpass_cdc_wsa2_macro_dlkm lpass_cdc_wsa_macro_dlkm lpass_cdc_rx_macro_dlkm lpass_cdc_tx_macro_dlkm wsa884x_dlkm wsa883x_dlkm wcd9378_slave_dlkm wcd939x_slave_dlkm mbhc_dlkm wcd_core_dlkm swr_ctrl_dlkm swr_dlkm lpass_cdc_dlkm sdca_registers_dlkm audio_pkt_dlkm audpkt_ion_dlkm audio_prm_dlkm snd_event_dlkm adsp_loader_dlkm spf_core_dlkm gpr_dlkm q6_notifier_dlkm q6_pdr_dlkm";
for m in $mods_unload; do rmmod $m >/dev/null 2>&1 && echo rm:$m:ok || echo rm:$m:skip; done;
echo === after unload ===;
lsmod | grep -E "machine_dlkm|audio_prm|audio_pkt|audpkt_ion|oplus_audio|wcd9xxx|wcd939x|wcd9378|lpass_cdc|wsa88|swr(_ctrl)?|mbhc|adsp_loader|spf_core|gpr_dlkm|q6_notifier|q6_pdr|snd_event";
echo === remoteproc before rebuild ===;
cat /sys/class/remoteproc/remoteproc0/state;
if [ "$(cat /sys/class/remoteproc/remoteproc0/state)" = running ]; then echo stop > /sys/class/remoteproc/remoteproc0/state; sleep 2; fi;
cat /sys/class/remoteproc/remoteproc0/state;
for m in q6_pdr_dlkm.ko q6_notifier_dlkm.ko gpr_dlkm.ko snd_event_dlkm.ko spf_core_dlkm.ko adsp_loader_dlkm.ko; do insmod /vendor_dlkm/lib/modules/$m && echo ins:$m:ok || echo ins:$m:fail; done;
echo start > /sys/class/remoteproc/remoteproc0/state; sleep 5;
for m in oplus_audio_netlink.ko oplus_audio_daemon.ko audpkt_ion_dlkm.ko sdca_registers_dlkm.ko audio_prm_dlkm.ko audio_pkt_dlkm.ko lpass_cdc_dlkm.ko swr_dlkm.ko swr_ctrl_dlkm.ko wcd_core_dlkm.ko mbhc_dlkm.ko wcd939x_slave_dlkm.ko wcd9378_slave_dlkm.ko wsa883x_dlkm.ko wsa884x_dlkm.ko lpass_cdc_tx_macro_dlkm.ko lpass_cdc_rx_macro_dlkm.ko lpass_cdc_wsa_macro_dlkm.ko lpass_cdc_wsa2_macro_dlkm.ko wcd9xxx_dlkm.ko wcd939x_dlkm.ko wcd9378_dlkm.ko oplus_audio_extend.ko oplus_audio_sipa.ko oplus_audio_sipa_tuning.ko oplus_audio_aw87xxx.ko oplus_audio_aw882xx.ko oplus_audio_pa_manager.ko machine_dlkm.ko; do insmod /vendor_dlkm/lib/modules/$m >/dev/null 2>&1 && echo ins:$m:ok || echo ins:$m:skip; done;
sleep 6;
echo === final state ===;
cat /sys/class/remoteproc/remoteproc0/state;
echo ---gpr---; ls -l /sys/bus/gprbus/devices;
echo ---platform drivers---; ls -l /sys/bus/platform/drivers/sun-asoc-snd /sys/bus/platform/drivers/soc-audio 2>/dev/null;
echo ---alsa---; cat /proc/asound/cards; echo ---; cat /proc/asound/pcm 2>/dev/null; echo ---; ls -l /dev/snd;
echo ---logs---; dmesg | grep -iE "audio_notifier_ssr_adsp_cb|already registered|audio_prm_probe|machine_dlkm|sun-asoc|asoc-snd|spf_core_platform|apm is not up|q6 state is down|Adding GPR dev|gpr_probe|remoteproc-adsp|registered sound card|snd_soc" | tail -n 320
'
```

结果坐实了两件关键事实：完整音频链能干净重建，`machine_dlkm` 的 `init_module` 确实跑到了，但声卡仍没出来。核心阻塞还是 `q6 state is down`，不是单纯"machine 没装上"。

---

## 16. 发现并加载 q6_dlkm.ko

查有没有还漏掉的 q6/sysmon 相关模块或节点：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'ls /vendor_dlkm/lib/modules | grep -iE "(^|_)q6|sysmon|apr|spf|pdr|glink|audio.*qmi|lpass.*rsc|rproc" | sort'
```

找到一个之前确实漏掉的底层件：`q6_dlkm.ko` 在分区里存在，但一直没加载。接着查设备节点和 proc：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo === devices ===; ls -l /dev | grep -iE "adsp|apr|audio|fastrpc|wcd|avtimer" | head -n 200; echo === proc ===; find /proc -maxdepth 2 \( -name "*audio*" -o -name "*asound*" -o -name "*wcd*" -o -name "*q6*" \) 2>/dev/null | sort | head -n 200'
```

查看 PDR/sysmon 相关 dmesg：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'dmesg | grep -iE "audio_prm_probe|q6 state is down|prm probe success|proc_dir_entry|already registered|q6_pdr|q6_notifier|sysmon|glink state|audio_notifier_reg_service|service PDR_ADSP|subsystem event accepted" | tail -n 260'
```

日志里 `audio_notifier_reg_service: service PDR_ADSP is in use` 还在反复出现。`q6_dlkm.ko` 依然没参与底层链。只插 `q6_dlkm.ko` 做最小验证：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'insmod /vendor_dlkm/lib/modules/q6_dlkm.ko && echo ins:q6_dlkm:ok || echo ins:q6_dlkm:fail; sleep 3; echo === lsmod ===; lsmod | grep -E "q6_dlkm|q6_pdr|q6_notifier|gpr_dlkm|spf_core|audio_prm|machine_dlkm"; echo === logs ===; dmesg | grep -iE "q6_dlkm|q6 state is down|audio_notifier_reg_service|service PDR_ADSP|audio_prm_probe|apm is not up|Adding GPR dev|gpr_probe|remoteproc-adsp" | tail -n 220; echo === alsa ===; cat /proc/asound/cards; echo ---; ls -l /dev/snd'
```

`q6_dlkm` 本身插进去后没有立刻生效，use count 是 0，大概率要靠下一次 ADSP 生命周期事件来挂上状态。保留 `q6_dlkm`，只重启 ADSP：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo stop > /sys/class/remoteproc/remoteproc0/state; sleep 2; echo start > /sys/class/remoteproc/remoteproc0/state; sleep 6; echo === remoteproc ===; cat /sys/class/remoteproc/remoteproc0/state; echo === gpr ===; ls -l /sys/bus/gprbus/devices; echo === alsa ===; cat /proc/asound/cards; echo ---; ls -l /dev/snd; echo === logs ===; dmesg | grep -iE "q6_dlkm|audio_notifier_ssr_adsp_cb|service PDR_ADSP|q6 state is down|audio_prm_probe|apm is not up|Adding GPR dev|gpr_probe|remoteproc-adsp|registered sound card|snd_soc|sun-asoc" | tail -n 260'
```

`q6_dlkm` 至少证明不是"模块文件不存在"，但这一步本身还没把症状翻过来。

做一次极短确认看当前状态：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'cat /sys/class/remoteproc/remoteproc0/state; echo ---; ls -l /sys/bus/gprbus/devices; echo ---; cat /proc/asound/cards; echo ---; lsmod | grep -E "q6_dlkm|machine_dlkm|audio_prm|q6_notifier|q6_pdr|gpr_dlkm|spf_core"'
```

短确认直接卡住了，不是正常返回——当前 recovery 音频栈已经进入一种半活跃、半阻塞状态。重新拿最小状态快照：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb devices
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'cat /sys/class/remoteproc/remoteproc0/state; echo ---; cat /proc/asound/cards'
```

---

## 17. 干净 recovery + q6_dlkm 先行 → 挖出 soc_aux_init_only_sia81xx 缺口

做最后一个有区分度的实验：清一次 recovery 状态，让 `q6_dlkm` 从一开始就参与，而不是后补：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 reboot recovery
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && for i in $(seq 1 60); do adb devices | grep -q '70a91f89[[:space:]]*recovery' && break; sleep 2; done; adb devices
```

基线确认——`ADSP running + no soundcards`：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'cat /sys/class/remoteproc/remoteproc0/state; echo ---; cat /proc/asound/cards'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'insmod /vendor_dlkm/lib/modules/q6_dlkm.ko && echo ok || echo skip'
```

`q6_dlkm` 已提前进去。按短分组补主链，避免终端截断——第一组：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'for m in oplus_audio_netlink.ko oplus_audio_daemon.ko audpkt_ion_dlkm.ko sdca_registers_dlkm.ko audio_prm_dlkm.ko audio_pkt_dlkm.ko; do insmod /vendor_dlkm/lib/modules/$m >/dev/null 2>&1 && echo $m:ok || echo $m:skip; done'
```

第二组：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'for m in lpass_cdc_dlkm.ko swr_dlkm.ko swr_ctrl_dlkm.ko wcd_core_dlkm.ko mbhc_dlkm.ko wcd939x_slave_dlkm.ko wcd9378_slave_dlkm.ko wsa883x_dlkm.ko wsa884x_dlkm.ko; do insmod /vendor_dlkm/lib/modules/$m >/dev/null 2>&1 && echo $m:ok || echo $m:skip; done'
```

第三组——含 machine_dlkm：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'for m in lpass_cdc_tx_macro_dlkm.ko lpass_cdc_rx_macro_dlkm.ko lpass_cdc_wsa_macro_dlkm.ko lpass_cdc_wsa2_macro_dlkm.ko wcd9xxx_dlkm.ko wcd939x_dlkm.ko wcd9378_dlkm.ko oplus_audio_extend.ko oplus_audio_sipa.ko oplus_audio_sipa_tuning.ko oplus_audio_aw87xxx.ko oplus_audio_aw882xx.ko oplus_audio_pa_manager.ko machine_dlkm.ko; do insmod /vendor_dlkm/lib/modules/$m >/dev/null 2>&1 && echo $m:ok || echo $m:skip; done'
```

machine_dlkm 这组没有完全干净重来，有部分变成 skip。直接看最终状态和日志：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'cat /sys/class/remoteproc/remoteproc0/state; echo ---; ls -l /sys/bus/gprbus/devices; echo ---; cat /proc/asound/cards; echo ---; ls -l /dev/snd; echo ---; lsmod | grep -E "q6_dlkm|machine_dlkm|audio_prm|audio_pkt|q6_notifier|q6_pdr|gpr_dlkm|spf_core|wcd9xxx|wcd939x|wcd9378|lpass_cdc_rx|lpass_cdc_wsa|oplus_audio_daemon"'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'dmesg | grep -iE "q6_dlkm|audio_prm_probe|service PDR_ADSP|q6 state is down|apm is not up|Adding GPR dev|gpr_probe|remoteproc-adsp|registered sound card|snd_soc|sun-asoc|device link|machine_dlkm" | tail -n 220'
```

最新一轮出现新的、比前面更具体的失败：`machine_dlkm: Unknown symbol soc_aux_init_only_sia81xx (err -2)`。在"干净 recovery + q6_dlkm 提前介入"的路径下，问题又往前推进了一步——machine 开始缺额外的功放 provider 符号。此时两个问题叠在一起：底层 Q6/APM/PDR 状态一直没真正 ready + machine_dlkm 还缺一个真实的功放 provider 符号。

---

## 18. 追踪 soc_aux_init_only_sia81xx 导出者

找出导出该符号的模块：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'ls /vendor_dlkm/lib/modules | grep -iE "sia|aux|speaker|pa_|sipa|aw87|aw88|tfa98|smartpa" | sort'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'dmesg | grep -iE "soc_aux_init_only_sia81xx|sia81|machine_dlkm: Unknown symbol|smartpa|aw87|aw882|sipa" | tail -n 120'
```

尝试加载功放候选模块：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'for m in oplus_audio_sipa.ko oplus_audio_sipa_tuning.ko oplus_audio_aw87xxx.ko oplus_audio_aw882xx.ko oplus_audio_pa_manager.ko oplus_audio_tfa98xx_v6.ko; do insmod /vendor_dlkm/lib/modules/$m >/dev/null 2>&1 && echo $m:ok || echo $m:skip; done'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'grep -w " soc_aux_init_only_sia81xx" /proc/kallsyms || true'
```

现在基本能确认：`soc_aux_init_only_sia81xx` 这个符号当前并没有被任何已加载模块导出，而最像 provider 的 `oplus_audio_pa_manager.ko` 也没能装上。最后再查一次仓库和设备模块名里有没有 `sia81xx` 对应模块；如果完全没有，这条手工 bring-up 路径就算被一个真实缺件卡死了。

搜其他分区有没有同名 provider 模块：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'ls /vendor/lib/modules 2>/dev/null | grep -iE "sia|aux|speaker|pa_|smartpa" | sort; echo ---; ls /odm/lib/modules 2>/dev/null | grep -iE "sia|aux|speaker|pa_|smartpa" | sort; echo ---; ls /system_dlkm/lib/modules 2>/dev/null | grep -iE "sia|aux|speaker|pa_|smartpa" | sort'
```

符号没有被任何已加载模块导出，其他分区也没有。当前手工 bring-up 已经摸到一个真实边界——recovery 当前可见模块集合里至少还缺一块能导出 `soc_aux_init_only_sia81xx` 的 PA/speaker provider，同时 `q6 state is down` 也还没被真正解开。


其他模块目录也是空的，没有任何 `sia`/`smartpa`/`speaker` 风格的 provider 模块。这已经很接近结论了，我再用文件名级别查一次仓库里有没有 `sia81xx` 痕迹，避免漏掉某个被拉到别处的预编译件。

Searched for files matching `**/*sia*`, 100 matches

继续查下去，结论已经明显收敛了，但这次还没把播放打通。

现在能确定的点：

1. `q6_dlkm.ko` 确实存在，而且我已经验证过两种路径：
   - 在脏状态里后补加载
   - 重启 recovery 后最早加载，再按顺序补整条音频链  
   结果都一样：`remoteproc0` 是 `running`，`gprsvc:spf_core/q6prm/audio-pkt` 都在，但 `ALSA` 还是空，`/dev/snd` 只有 `timer`。

2. `q6_dlkm` 不是决定性缺件。
   - 即使它提前参与，日志里还是持续刷：
     - `gpr_send_pkt: q6 state is down`
     - `audio_notifier_reg_service: service PDR_ADSP is in use`
     - `spf-core-platform ... Failed to create device link (0x180) with soc:vote_lpass_* / *_clk`

3. 这轮又挖出一个新的硬缺口：
   - 在干净 recovery + `q6_dlkm` 提前介入的路径里，`machine_dlkm` 没能稳定进入最终状态
   - 关键错误变成了：
     - `machine_dlkm: Unknown symbol soc_aux_init_only_sia81xx (err -2)`

4. 我已经把和功放/PA 相关的候选模块都摸了一遍：
   - 有：`oplus_audio_sipa`、`oplus_audio_sipa_tuning`、`oplus_audio_aw87xxx`、`oplus_audio_aw882xx`、`oplus_audio_pa_manager`、`oplus_audio_tfa98xx_v6`
   - 但当前内核里没有任何模块导出 `soc_aux_init_only_sia81xx`
   - 其他分区的模块目录里也没找到 `sia` / `smartpa` / `speaker` 风格的额外 provider

5. 这说明现在不是单一问题，而是两个问题叠在一起：
   - 底层 `Q6/APM/PDR` 状态一直没真正 ready
   - `machine_dlkm` 这边还缺一个真实的功放 provider 符号 `soc_aux_init_only_sia81xx`

所以当前手工 bring-up 已经摸到一个真实边界了：  
不是“顺序不对再试试”这么简单，而是 recovery 当前可见模块集合里，至少还缺一块能导出 `soc_aux_init_only_sia81xx` 的 PA/speaker provider；同时 `q6 state is down` 也还没被真正解开。

下一步最有价值的只有这两个方向：

1. 从 stock 系统实际运行环境里，找出是谁导出 `soc_aux_init_only_sia81xx`，再把这条 PA 依赖链补齐。
2. 对照 stock 的音频 bring-up 顺序，确认是谁把 `Q6` 从 `down` 推到 `ready`，因为光有 `q6_dlkm` 还不够。

如果继续，我下一步就直接做第 1 条：从系统侧把 `soc_aux_init_only_sia81xx` 的 provider 精确找出来。

---

## 19. User: 继续 — 仓库和设备并行追查

用户说"继续"。并行做两件事：一边在仓库和设备分区里追 `soc_aux_init_only_sia81xx` 的真实导出者，一边补查 stock 音频 bring-up 里把 Q6 从 down 推到 ready 的用户态或 init 触发链。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n "soc_aux_init_only_sia81xx|sia81xx|sun-asoc-snd|q6 state is down|apm is not up|PDR_ADSP|audio_prm_probe|spf_core_platform" .
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'for d in /vendor_dlkm/lib/modules /vendor/lib/modules /odm/lib/modules /system_dlkm/lib/modules; do [ -d "$d" ] || continue; echo ===$d===; for f in $d/*.ko; do grep -aq "soc_aux_init_only_sia81xx\|sia81xx" "$f" && echo $f; done; done'
```

查 stock 音频 init 服务：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'for d in /vendor/etc/init /odm/etc/init /system/etc/init; do [ -d "$d" ] || continue; echo ===$d===; grep -RinE "adsp|q6|pdr|pd-mapper|sysmon|spf|audio[-_ ]pkt|audio_prm|audiosphere|agm|audio hal|adsprpc|ssr" "$d" 2>/dev/null; done'
```

仓库里没有新的源码线索，设备分区里也没找到直接包含 `sia81xx` 字符串的已挂载模块；这更像是恢复环境没挂到真正的 provider 模块，或者该导出者藏在别的分区/镜像里。下一步我改查两个更具体的面：一是 workspace 里有没有现成的 `machine_dlkm.ko`/vendor 模块可离线验 undefined symbol，二是设备上有没有 stock 音频用户态二进制和属性能把 APM 真正拉起来。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'for d in /vendor/bin /vendor/bin/hw /system/bin /system_ext/bin /odm/bin; do [ -d "$d" ] || continue; echo ===$d===; ls $d 2>/dev/null | grep -iE "audio|agm|adsp|adsprpc|pd|pdr|sysmon|spf|gpr|q6"; done'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'getprop | grep -iE "audio|adsp|agm|vendor.qspa|sys.audio|persist.vendor.audio|ro.vendor.audio|media" | sed -n "1,240p"'
```

recovery 里几乎没有 stock 音频用户态服务在跑。转去看内核模块自己的依赖元数据——如果 `machine_dlkm` 在 `modules.dep` 或 `modules.alias` 里暴露出依赖链，就能更快确认缺的到底是谁：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'for f in /vendor_dlkm/lib/modules/modules.dep /vendor_dlkm/lib/modules/modules.softdep /vendor_dlkm/lib/modules/modules.alias; do [ -f "$f" ] && { echo ===$f===; grep -nE "machine_dlkm|oplus_audio_pa_manager|oplus_audio_sipa|aw87|aw882|tfa98|wcd939x|audio_prm_dlkm|q6_dlkm" "$f"; }; done'
```

**`modules.alias` 里有关键发现**：`si,sia81xx` 明确绑定到 `oplus_audio_sipa`。离线验证模块内部字符串：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 exec-out cat /vendor_dlkm/lib/modules/machine_dlkm.ko | strings | grep -nE "soc_aux_init_only_sia81xx|sia81xx|depends=|oplus_audio|aw87|aw882|tfa98|wsa|wcd|sun-asoc|snd-card|spf" | sed -n "1,220p"'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'find /vendor /odm /system_dlkm -type f \( -iname "*sia*" -o -iname "*smartpa*" -o -iname "*speaker*" -o -iname "*pa*" \) 2>/dev/null | sed -n "1,240p"'
```

`modules.dep` 这边已经有结果了，我先把那份长输出读出来；另外两条因为终端把引号吃坏了，我会用更短、更稳的命令重跑，不改设备状态。

依赖关系已经清楚一层了：`modules.alias` 明确把 `si,sia81xx` 绑到 `oplus_audio_sipa`，所以缺口不再是“谁可能是 provider”，而是“为什么 `oplus_audio_sipa` 已加载却没有导出 `soc_aux_init_only_sia81xx`”。我继续检查它是不是因为探测没成功、导出被条件编译掉，或者还卡在更早的设备枚举阶段。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 exec-out cat /vendor_dlkm/lib/modules/oplus_audio_sipa.ko | strings | rg -n "soc_aux_init_only|sia81|depends=|pa_manager|EXPORT|aux"
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 exec-out cat /vendor_dlkm/lib/modules/machine_dlkm.ko | strings | rg -n "soc_aux_init_only|sia81|depends=|oplus_audio|sun-asoc|snd-card|spf"
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell "grep -E ' soc_aux_init_only_| sia|sipa|aw87|aw882|tfa98' /proc/kallsyms | sed -n '1,240p'"
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell "dmesg | grep -iE 'oplus_audio_sipa|oplus_audio_pa_manager|sia81|sia91|smartpa|aw87|aw882|tfa98' | tail -n 240"
```

缺口不再是"谁可能是 provider"——`modules.alias` 明确把 `si,sia81xx` 绑到 `oplus_audio_sipa`，且该 ko 内部确实带着 `__ksymtab_soc_aux_init_only_sia81xx`。问题变成了"为什么 `oplus_audio_sipa` 已加载却没有导出该符号"。

---

## 20. 闭环验证：machine_dlkm 加载成功

在 oplus_audio_sipa 已成功插入之后，重新试一次 machine_dlkm：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell "lsmod | grep -E 'oplus_audio_sipa|oplus_audio_pa_manager|machine_dlkm|q6_dlkm|audio_prm_dlkm|spf_core_dlkm'"
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell "grep -E 'soc_aux_init_only_sia81xx|soc_aux_deinit_only_sia81xx|soc_sia81xx_init|soc_sia81xx_get_aux_num' /proc/kallsyms || true"
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell "insmod /vendor_dlkm/lib/modules/machine_dlkm.ko; echo rc:$?; cat /proc/asound/cards; echo ---; ls -l /dev/snd"
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell "dmesg | grep -iE 'machine_dlkm|soc_aux_init_only_sia81xx|sun-asoc|registered sound card|q6 state is down|apm is not up|snd_soc' | tail -n 220"
```

`machine_dlkm` 现在已经能正常插进去了，`soc_aux_init_only_sia81xx` 缺符号问题可以正式划掉。剩下的主阻塞收敛成一条：machine 在了，但 ASoC 设备和声卡还没真正枚举出来。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell "lsmod | grep -E 'machine_dlkm|sun_asoc|oplus_audio_sipa|q6_dlkm' ; echo ---; cat /proc/asound/cards; echo ---; cat /proc/asound/pcm 2>/dev/null || true"
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell "echo ===driver===; ls -l /sys/bus/platform/drivers/sun-asoc-snd 2>/dev/null; echo ===devices===; ls /sys/bus/platform/devices | grep -iE 'sound|snd|spf|audio' | sed -n '1,240p'"
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell "find /sys/devices/platform/soc/soc:spf_core_platform -maxdepth 3 | sed -n '1,240p'"
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell "dmesg | tail -n 500 | grep -iE 'machine_dlkm|sun-asoc|snd_card_sysfs_init|registered sound card|spf_core_add_child_devices|apm is not up|q6 state is down|audio_prm_probe|Adding GPR dev|service PDR_ADSP'"
```

`machine_dlkm` 已加载，但 `sun-asoc-snd` 仍然没有绑定实例，`spf_core_platform` 下面也没有任何 child。

---

## 21. DT sound 节点二次确认 + 重绑 spf_core_platform

补查两个关键点：spf_core_add_child_devices/q6 的精确日志，以及 DT sound 子节点状态位：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell "dmesg | grep -i 'spf_core_add_child_devices' | tail -n 60; echo ---; dmesg | grep -i 'q6 state is down' | tail -n 60; echo ---; dmesg | grep -i 'audio_prm_probe' | tail -n 30; echo ---; dmesg | grep -i 'service PDR_ADSP' | tail -n 30"
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell "for f in /sys/firmware/devicetree/base/soc/spf_core_platform/sound/name /sys/firmware/devicetree/base/soc/spf_core_platform/sound/compatible /sys/firmware/devicetree/base/soc/spf_core_platform/sound/status /sys/firmware/devicetree/base/soc/spf_core_platform/sound/qcom,model; do [ -e \"$f\" ] && { echo ===$f===; cat $f; echo; }; done"
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell "cat /sys/class/remoteproc/remoteproc0/state; echo ---; ls -1 /sys/bus/gprbus/devices; echo ---; ls -l /sys/bus/platform/drivers/spf-core-platform 2>/dev/null"
```

日志这轮反而很干净，更像是 `spf_core_platform` 在更早时机错过了 child 枚举。逐条读 sound 节点属性：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell cat /sys/firmware/devicetree/base/soc/spf_core_platform/sound/name
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell cat /sys/firmware/devicetree/base/soc/spf_core_platform/sound/compatible
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'cat /sys/firmware/devicetree/base/soc/spf_core_platform/sound/status 2>/dev/null || echo no-status'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell cat /sys/firmware/devicetree/base/soc/spf_core_platform/sound/qcom,model
```

sound 节点属性没问题，不是 DT 自己禁掉的。做最小化运行时重绑——只对 `spf_core_platform` 做 unbind/bind：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell "echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/unbind; sleep 1; echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/bind; echo rc:$?"
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell "echo ===platform===; ls /sys/bus/platform/devices | grep -iE 'sound|snd|spf|audio' | sed -n '1,240p'; echo ---; echo ===driver===; ls -l /sys/bus/platform/drivers/sun-asoc-snd 2>/dev/null; echo ---; echo ===asound===; cat /proc/asound/cards; echo ---; ls -l /dev/snd"
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell "dmesg | grep -iE 'spf_core|sun-asoc|machine_dlkm|registered sound card|snd_soc|apm|q6 state is down|audio_prm_probe' | tail -n 220"
```

重绑没有把 `sun-asoc-snd` 补出来。证据闭环了：重绑时 `spf_core_platform` 确实再次尝试枚举 machine，但卡在 `__spf_core_is_apm_ready`，并持续报 `gpr_send_pkt: q6 state is down`。声卡没出来的根因已经不是 machine/PA，而是 ADSP 里的 APM 服务仍然没 ready。

---

## 22. 查 boot_adsp/SSR 控制点并验证

查 recovery 里还有没有可手动触发的 ADSP loader/SSR 控制点：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell "find /sys -maxdepth 3 \( -path '/sys/kernel/boot_adsp*' -o -path '/sys/module/adsp_loader_dlkm*' -o -path '/sys/class/remoteproc/remoteproc0*' \) | sed -n '1,240p'"
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell "dmesg | grep -iE 'adsp_loader|boot_adsp|ssr|remoteproc0|remoteproc-adsp|pdr|sysmon' | tail -n 220"
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell "ls -l /proc/asound 2>/dev/null; echo ---; ls -l /sys/class/sound 2>/dev/null; echo ---; ls -l /dev | grep -iE 'apr|adsp|aud' | sed -n '1,240p'"
```

控制点存在：`/sys/kernel/boot_adsp/{boot,ssr,ssr_defer}` 都在。先看当前值：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell "for f in /sys/kernel/boot_adsp/boot /sys/kernel/boot_adsp/ssr /sys/kernel/boot_adsp/ssr_defer; do echo ===$f===; cat $f; done"
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell "dmesg | grep -iE 'remoteproc-adsp|boot_adsp|ssr|gprsvc|q6 state is down|apm is not up' | tail -n 120"
```

用户说"你在空转了，继续"。不再兜圈，直接确认权限后打 SSR：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'ls -l /sys/kernel/boot_adsp /sys/kernel/boot_adsp/*'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n "boot_adsp|ssr_defer|/sys/kernel/boot_adsp/ssr|remoteproc0|q6 state is down|apm is not up" device_tree docs twrp_a16_compile 2>/dev/null
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'id; getenforce 2>/dev/null || true'
```

当前 shell 是 root，`boot_adsp` 节点就是写触发器。打 SSR：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo 1 > /sys/kernel/boot_adsp/ssr; echo rc:$?'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'sleep 3; cat /sys/class/remoteproc/remoteproc0/state; echo ---; ls -1 /sys/bus/gprbus/devices; echo ---; cat /proc/asound/cards; echo ---; ls -l /dev/snd'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'dmesg | grep -iE "boot_adsp|remoteproc-adsp|pdr|q6 state is down|apm is not up|Adding GPR dev|spf_core_add_child_devices|registered sound card|sun-asoc|machine_dlkm" | tail -n 240'
```

SSR 触发成功但表面状态还没进到声卡出来。ADSP 固件会完整重装，GPR 也会重新出现，但 `spf_core` 一进入 APM 检测还是立刻 `q6 state is down`。

这轮 SSR 已经把结论压实了：ADSP 固件会完整重装，GPR 也会重新出现，但 `spf_core` 一进入 APM 检测还是立刻 `q6 state is down`。下一步我不再猜模块顺序，直接查 stock 挂载分区里有没有 recovery 没起的 ADSP 侧用户态服务或 manifest 项。

查 stock 挂载分区里的用户态服务和 manifest：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'find /vendor /odm /system /system_ext -type f \( -name "*pd-mapper*" -o -name "*adsprpc*" -o -name "*agm*" -o -name "*audio*hal*" -o -name "*audiosphere*" -o -name "*audio*service*" \) 2>/dev/null | sed -n "1,240p"'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'grep -RinE "pd-mapper|adsprpc|agm|audiosphere|audio.*hal|vendor.audio|Apm|AudioPdk|q6prm|audio-pkt|adsp" /vendor/etc /odm/etc /system/etc /system_ext/etc 2>/dev/null | sed -n "1,260p"'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'find /vendor/etc/vintf /odm/etc/vintf /system/etc/vintf /system_ext/etc/vintf -type f 2>/dev/null | while read f; do grep -HinE "audio|agm|adsprpc|pd-mapper|vendor.audio|qti.audio" "$f"; done | sed -n "1,260p"'
```

前面没看到新的 stock 服务线索，现阶段最值得试的不是继续扫文件，而是验证 `boot_adsp/boot` 和 `ssr` 是否语义不同。先打一次 `boot=1`，如果它仍然把系统带回同样的 `q6 state is down`，就说明要转向“卸载下层链后完整重建”。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo 1 > /sys/kernel/boot_adsp/boot; echo rc:$?'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'sleep 3; cat /sys/class/remoteproc/remoteproc0/state; echo ---; ls -1 /sys/bus/gprbus/devices; echo ---; cat /proc/asound/cards; echo ---; ls -l /dev/snd'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'dmesg | grep -iE "remoteproc-adsp|boot_adsp|q6 state is down|apm is not up|Adding GPR dev|spf_core_add_child_devices|service PDR_ADSP|registered sound card" | tail -n 240'
```

`boot=1` 表现和 `ssr=1` 一致。两条控制路径都证实无效。

---

## 23. 卸载大半模块后 SSR 清 PDR 污染

两条路都无效，做根因导向验证——把上层模块卸掉，清空 PDR_ADSP 旧注册，再 SSR 重建：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'for m in machine_dlkm audio_pkt_dlkm audio_prm_dlkm oplus_audio_daemon spf_core_dlkm gpr_dlkm q6_notifier_dlkm q6_pdr_dlkm q6_dlkm; do rmmod $m >/dev/null 2>&1 && echo $m:rm || echo $m:busy; done'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'lsmod | grep -E "machine_dlkm|audio_pkt_dlkm|audio_prm_dlkm|oplus_audio_daemon|spf_core_dlkm|gpr_dlkm|q6_notifier_dlkm|q6_pdr_dlkm|q6_dlkm" || true'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo 1 > /sys/kernel/boot_adsp/ssr; sleep 2; cat /sys/class/remoteproc/remoteproc0/state; echo ---; ls -1 /sys/bus/gprbus/devices'
```

SSR 这次把 adb 打断了，说明确实走了更重的重启路径。等设备回 recovery：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && for i in $(seq 1 90); do adb devices | grep -q '70a91f89[[:space:]]*recovery' && break; sleep 2; done; adb devices
```

---

## 24. User: 继续，设备重新连上了 — 半干净状态验证

用户确认设备重新连上。取最小状态快照确认当前状态：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'cat /sys/class/remoteproc/remoteproc0/state; echo ---; cat /proc/asound/cards; echo ---; ls -l /dev/snd'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'lsmod | grep -E "machine_dlkm|audio_pkt_dlkm|audio_prm_dlkm|q6_dlkm|spf_core_dlkm|gpr_dlkm|q6_notifier_dlkm|q6_pdr_dlkm|oplus_audio_sipa|oplus_audio_pa_manager"'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'ls -1 /sys/bus/gprbus/devices 2>/dev/null'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'dmesg | grep -iE "spf_core_add_child_devices|q6 state is down|apm is not up|audio_prm_probe|service PDR_ADSP|remoteproc-adsp|boot_adsp|ssr" | tail -n 120'
```

这次重连后状态比刚才更干净：只有 `adsp_loader/q6_pdr/q6_notifier/gpr/spf_core` 底层链自动起来了，上层全无。但 `spf_core_platform` 仍然卡在 `apm is not up`——根因在 APM/Q6，不在上层 codec/machine。

最小验证——补 `q6_dlkm` + 手动重绑 spf_core_platform：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'insmod /vendor_dlkm/lib/modules/q6_dlkm.ko && echo q6:ok || echo q6:skip'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/unbind; sleep 1; echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/bind; echo spf:rebind:$?'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'dmesg | grep -iE "spf_core_add_child_devices|q6 state is down|apm is not up|remoteproc-adsp|service PDR_ADSP" | tail -n 80'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'lsmod | grep -E "q6_dlkm|spf_core_dlkm|gpr_dlkm|q6_notifier_dlkm|q6_pdr_dlkm"; echo ---; cat /proc/asound/cards'
```

`q6_dlkm` 在干净基线上也完全没把 APM 推起来，这条路可以收掉。现在直接验证 `boot_adsp/ssr` 这个更重的恢复路径：如果它之后仍然是同样的 `q6 state is down`，那问题就不是“缺一个内核模块”，而是 recovery 环境缺了 ADSP 音频服务真正起稳所需的更上游条件。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'ls -l /sys/kernel/boot_adsp'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo 1 > /sys/kernel/boot_adsp/ssr; echo ssr:$?'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && for i in $(seq 1 45); do adb devices | grep -q '70a91f89[[:space:]]*recovery' && break; sleep 2; done; adb devices
```

重连后确认 SSR 结果：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'cat /sys/class/remoteproc/remoteproc0/state; echo ---; ls -1 /sys/bus/gprbus/devices 2>/dev/null; echo ---; dmesg | grep -iE "remoteproc-adsp|boot_adsp|ssr|spf_core_add_child_devices|q6 state is down|apm is not up" | tail -n 100'
```

这次 SSR 已经给了足够明确的信号：它是能触发的，但触发后系统还是回到同一组状态，`remoteproc` 仍是 `running`、GPR 仍在、APM 仍不 ready。现在我把 SSR 触发本身的原始结果读出来，确认它到底是“仅局部复位”还是“完整 ADSP restart 后仍失败”，然后就该转向检查 stock 分区里缺的 DSP 固件/校准文件而不是继续折腾模块顺序。

`q6_dlkm` 和 `ssr` 两条都已经证伪了，当前更像是 ADSP 音频服务在 recovery 里启动了框架，但没拿到完整的固件或校准环境。下一步我只查这类硬条件：有没有 DSP 固件目录、音频校准文件、以及内核里是否报过 firmware load 失败。

---

## 25. 检查 DSP 固件和分区挂载

查 DSP 固件目录、音频校准文件、以及内核是否报过 firmware load 失败：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'for d in /vendor/firmware_mnt /vendor/firmware /vendor/dsp /odm/firmware_mnt /mnt/vendor/persist /persist; do [ -d $d ] && { echo ===$d===; ls $d | sed -n "1,80p"; }; done'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'find /vendor /odm /persist /mnt/vendor/persist -maxdepth 4 -type f 2>/dev/null | grep -iE "acdb|audio|adsp|spf|q6|wcd|codec|calib|mixer" | sed -n "1,240p"'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'dmesg | grep -iE "firmware|request_firmware|acdb|adsp.*fail|spf.*fail|audio.*fail|q6.*fail|calib" | tail -n 200'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'mount | grep -iE "vendor|odm|persist|firmware"'
```

挂载状态冒出一个很具体的问题：当前只看到 `vendor_dlkm` 和 `/firmware`，没看到 `vendor`、`odm`、`persist` 正常挂载。ADSP 固件本体能从 `/firmware/image` 加载，但校准、配置和部分用户态依赖通常都在 vendor/odm/persist 里。

这轮有了新的硬证据：ADSP 固件本体是能从 `/firmware/image` 加载的，但 recovery 当前并没有把 `vendor`、`odm`、`persist` 正常挂上来。对音频来说，这比继续折腾模块更像根因，因为校准、配置和部分用户态依赖通常都在这些分区里。下一步我直接验证能不能手动把这些分区挂上，再重打一轮音频 bring-up。

查分区映射器和 fstab：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'ls -ld /vendor /odm /persist /mnt/vendor/persist 2>/dev/null; echo ---; ls /dev/block/mapper 2>/dev/null | grep -iE "vendor|odm|persist|system" | sed -n "1,120p"'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'command -v twrp || true; echo ---; twrp --help 2>/dev/null | sed -n "1,80p"'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'cat /etc/recovery.fstab 2>/dev/null | grep -iE "vendor|odm|persist|firmware" | sed -n "1,120p"'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'cat /etc/twrp.fstab 2>/dev/null | grep -iE "vendor|odm|persist|firmware" | sed -n "1,120p"'
```

现在方向已经够具体了：挂载点和 fstab 都在，TWRP 命令也可用，所以先把 `vendor`、`odm` 挂上来是最合理的下一步。挂上之后我不会立刻整套重建，只先确认关键目录和音频配置文件是否真正出现，再决定是 SSR 还是只重绑 `spf_core`。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'twrp listmounts'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'twrp mount /vendor; echo vendor:$?; twrp mount /odm; echo odm:$?'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'mount | grep -iE " on /vendor | on /odm | on /vendor_dlkm "; echo ---; ls /vendor/etc 2>/dev/null | sed -n "1,80p"; echo ---; ls /odm/etc 2>/dev/null | sed -n "1,80p"'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'find /vendor/etc /odm/etc -maxdepth 3 -type f 2>/dev/null | grep -iE "audio|mixer|acdb|codec|wcd|agm|spf" | sed -n "1,200p"'
```

twrp mount 命令频繁卡住。改成单条短命令：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'twrp mount /vendor'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'twrp mount /odm'
```

不碰 twrp mount，直接看 `/vendor`/`odm` 里有没有真实内容：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'ls /vendor | sed -n "1,80p"; echo ---; ls /vendor/etc 2>/dev/null | sed -n "1,80p"'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'ls /odm | sed -n "1,80p"; echo ---; ls /odm/etc 2>/dev/null | sed -n "1,80p"'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'find /vendor/etc /odm/etc -maxdepth 2 -type f 2>/dev/null | grep -iE "audio|mixer|acdb|agm|codec|wcd" | sed -n "1,120p"'
```

现在 `vendor` 和 `odm` 的内容已经能看到，音频配置、`acdb`、`mixer_paths` 都在。"分区内容缺失"不是最终卡点。更像是 recovery 没有跑正常系统那套音频相关 init 服务或导入它们的 rc。

---

## 26. 读取 stock 音频 RC 并手动拉起用户态服务

读几个关键的 audio rc 看 stock 到底还会额外拉起哪些进程：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'sed -n "1,220p" /vendor/etc/init/audiohalservice_qti.rc'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'sed -n "1,220p" /vendor/etc/init/vendor.qti.audio-adsprpc-service.rc'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'sed -n "1,220p" /odm/etc/init/init.audio.rc'
```

确认二进制存在：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'for p in /vendor/bin/hw /vendor/bin /odm/bin /system/bin; do [ -d $p ] && { echo ===$p===; ls $p | grep -iE "audio|adsprpc|agm|pal|acdb"; }; done'
```

stock 路径里有两个 recovery 目前没跑的关键用户态：`audioadsprpcd` 和 `audiohalservice.qti`。检查当前是否真的缺席：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'ps -A | grep -iE "audioadsprpcd|audiohalservice|audioserver|adsprpcd"'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'getprop | grep -iE "init.svc.*audio|audio.ssr|audioserver" | sed -n "1,120p"'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'ls -ld /data/vendor/audio /data/vendor/audio_dsp /data/vendor/audio/acdbdata /data/vendor/audio/acdbdata/delta 2>/dev/null'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'ls -l /dev/sipa_cmd /dev/sipa_tool /dev/aw882xx_smartpa 2>/dev/null'
```

当前最可疑的缺口已经缩到音频用户态：目录在，配置在，进程却全没跑。先只手动拉起 `audioadsprpcd audiopd adsp`，再重绑 `spf_core_platform` 看 APM 有没有从 `down` 变成可用；如果这一步没变化，再考虑 `audiohalservice.qti`。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell '/vendor/bin/audioadsprpcd audiopd adsp >/data/vendor/audio_dsp/audioadsprpcd.log 2>&1 &'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'sleep 2; ps -A | grep -i audioadsprpcd; echo ---; tail -n 60 /data/vendor/audio_dsp/audioadsprpcd.log 2>/dev/null'
```

重绑 spf_core_platform 看 APM 有没有变化：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/unbind; sleep 1; echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/bind; echo done'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'dmesg | grep -iE "spf_core_add_child_devices|q6 state is down|apm is not up|audioadsprpcd|adsprpc|registered sound card|sun-asoc" | tail -n 120; echo ---; cat /proc/asound/cards'
```

`audioadsprpcd` 已被证明能拉起来，但对 APM 没有任何作用。进一步查 adsprpcd 和 hal 服务：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'grep -RinE "adsprpcd|audiohalservice|audioserver|audioadsprpcd" /vendor/etc/init /odm/etc/init 2>/dev/null | sed -n "1,200p"'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'ps -A | grep -E "servicemanager|hwservicemanager|vndservicemanager"'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'for p in /vendor/bin/adsprpcd /vendor/bin/hw/audiohalservice.qti; do [ -x $p ] && { echo ===$p===; ls -l $p; }; done'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'dmesg | grep -iE "adsprpc|rpc|audioserver|audio hal|binder" | tail -n 120'
```

现在剩下最像"漏掉的 stock 关键进程"的是通用 `adsprpcd rootpd adsp`。`audioadsprpcd` 只负责 audio PD，缺了 root PD 时它自己起来也可能没法把 DSP 侧服务链打通。先补这一个：

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell '/vendor/bin/adsprpcd rootpd adsp >/data/vendor/audio_dsp/adsprpcd.log 2>&1 &'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'sleep 2; ps -A | grep -iE "adsprpcd|audioadsprpcd"; echo ---; tail -n 60 /data/vendor/audio_dsp/adsprpcd.log 2>/dev/null'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && adb -s 70a91f89 shell 'echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/unbind; sleep 1; echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/bind; echo done'
```

---

## 27. 本阶段总结

**完整过程（按时间顺序）**：

```
compacted 后重接 → 确认状态（adsp_loader already registered）
  → 纯 remoteproc stop/start → GPR 未恢复
  → 查 platform 绑定 → adsp_loader 无操作节点
  → 查 rpmsg 总线 → 发现 remoterpoc1=cdsp, remoterpoc0=ADSP ★
  → 启动真正 ADSP → GPR 恢复但 q6 state is down
  → 重建 q6/gpr/spf → PDR_ADSP 污染 → reboot 清污染
  → 全量加载音频模块 → 发现符号缺口 (daemon/audpkt_ion/swr_ctrl)
  → 补 provider 模块 → audio_prm probe success!
  → LPASS device link 失败（时序问题）
  → 重绑 spf_core_platform → 回到 q6 state is down
  → ADSP stop/start → DSP crash → 再次拉起仍 crash
  → 搜索仓库 & 设备侧 init 配置 → 无额外音频 init 服务
  → 查 platform 驱动和 sound 设备 → sun-asoc-snd 无绑定对象
  → DT sound 节点确认 → 属性完整但子设备未创建
  → 完整卸载重载 → machine_dlkm 跑到但声卡没出来
  → 发现 q6_dlkm.ko → 加载 → 无效
  → reboot: 干净基线 + q6_dlkm 先行 → 挖出 soc_aux_init_only_sia81xx
  → modules.alias 追踪 → si,sia81xx → oplus_audio_sipa 是导出者
  → __ksymtab 确认 → machine_dlkm 加载成功 → 声卡仍未出来
  → 重绑 spf_core_platform → 卡 __spf_core_is_apm_ready
  → SSR=1 和 boot=1 → 均无效
  → 卸载大半模块 + SSR → 相同
  → 干净基线上 q6_dlkm+重绑 → 无效
  → 再次 SSR → 相同
  → 检查 firmware/分区 → vendor/odm 内容已有
  → 手动拉起 audioadsprpcd audiopd adsp → 进程运行但 APM 无变化
  → 拉起 adsprpcd rootpd adsp → （会话结尾）
```

**核心阻塞**：`gpr_send_pkt: q6 state is down` → `__spf_core_is_apm_ready` 卡死。纯内核操作（模块重载/SSR/remoteproc stop-start/bind-unbind）已穷尽，stock 用户态服务已补但也无效。

**已建立的关键方法**：
- `modules.alias` 追踪模块-设备绑定（`si,sia81xx` → `oplus_audio_sipa`）
- `remoteproc0` ≠ `remoteproc1`：必须先确认 DSP 身份再操作
- `boot_adsp/{boot,ssr}` 行为一致，只做 firmware 重装不修复 APM 状态
- recovery 里有 stock 音频 RC 和二进制，需手动挂载分区 + 手动拉起

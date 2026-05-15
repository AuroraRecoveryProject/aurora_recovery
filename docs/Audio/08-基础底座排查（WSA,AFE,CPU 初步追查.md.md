## 回到 Recovery 并重跑最短音频链

先切回 recovery。

```bash
adb reboot recovery
```

```bash
adb wait-for-device && adb shell getprop ro.bootmode
```

设备正在切回 recovery，等待确认上线。

```bash
adb devices && adb shell getprop ro.bootmode
```

设备还在切换过程中，改用更保守的单步检查。

```bash
adb devices
```

```bash
fastboot devices
```

recovery 已经重新上线。按这轮收敛出来的最短顺序重跑一次：先补 `lpi-pinctrl` 和 `stub codec`，再补音频链和 `machine`，随后重绑 `spf-core-platform`，最后点 `swr-mgr` 和 `sun-asoc-snd`。

```bash
adb shell 'insmod /vendor_dlkm/lib/modules/pinctrl_lpi_dlkm.ko 2>/dev/null; insmod /vendor_dlkm/lib/modules/stub_dlkm.ko 2>/dev/null; for m in oplus_audio_daemon.ko audpkt_ion_dlkm.ko audio_prm_dlkm.ko audio_pkt_dlkm.ko frpc-adsprpc.ko wcd_core_dlkm.ko swr_dlkm.ko wcd939x_slave_dlkm.ko wcd9xxx_dlkm.ko mbhc_dlkm.ko wcd939x_dlkm.ko lpass_cdc_dlkm.ko swr_ctrl_dlkm.ko lpass_bt_swr_dlkm.ko oplus_audio_pa_manager.ko oplus_audio_sipa.ko oplus_audio_extend.ko sdca_registers_dlkm.ko wcd9378_dlkm.ko lpass_cdc_rx_macro_dlkm.ko lpass_cdc_tx_macro_dlkm.ko lpass_cdc_va_macro_dlkm.ko lpass_cdc_wsa_macro_dlkm.ko lpass_cdc_wsa2_macro_dlkm.ko wsa883x_dlkm.ko wsa884x_dlkm.ko q6_dlkm.ko machine_dlkm.ko; do insmod /vendor_dlkm/lib/modules/$m 2>/dev/null; done; echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/unbind; sleep 1; echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/bind; sleep 3; for n in rx_swr_ctrl va_swr_ctrl bt_swr_mstr; do [ -e /sys/bus/platform/devices/$n ] && { echo swr-mgr > /sys/bus/platform/devices/$n/driver_override; echo $n > /sys/bus/platform/drivers_probe; }; done; echo sun-asoc-snd > /sys/bus/platform/devices/soc:spf_core_platform:sound/driver_override; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe; sleep 3; echo ---sound---; readlink /sys/bus/platform/devices/soc:spf_core_platform:sound/driver 2>/dev/null || echo no_driver; echo ---cards---; cat /proc/asound/cards 2>/dev/null; echo ---pcm---; cat /proc/asound/pcm 2>/dev/null; echo ---snd---; ls /dev/snd 2>/dev/null; echo ---defer---; cat /sys/kernel/debug/devices_deferred 2>/dev/null; echo ---sdw---; ls -l /sys/bus/soundwire/devices 2>/dev/null | sed -n "1,120p"'
```

**结论**：这次最短链没有成功。`sound` 设备路径直接不存在，说明这次连 `spf_core_platform` 的子设备都没枚举出来，和刚才那次已经把 GPR/SWR 带起来的现场不是同一个状态。用户态前提被省掉了，需要先把当前 recovery 的 `spf` 树和服务基线核一下。

## 检查 Recovery 基线状态

```bash
adb shell 'ls /sys/devices/platform/soc/soc:spf_core_platform 2>/dev/null || echo no_spf_dir; echo ---; ls /sys/bus/gprbus/devices 2>/dev/null || echo no_gpr'
```

```bash
adb shell 'getprop init.svc.vendor.adsprpcd; getprop init.svc.vendor.audioadsprpcd_audiopd; getprop init.svc.vendor.audio-hal-aidl; getprop init.svc.vendor.pd_mapper; getprop init.svc.vendor.per_mgr'
```

```bash
adb shell 'ls /mnt/real_vendor/bin 2>/dev/null | head -5; ls /mnt/real_odm/lib/rfsa/adsp 2>/dev/null | head -5'
```

**结论**：GPR 还在，但当前会话里真实 `vendor/odm` 没挂，音频服务也都没起来，所以这次 `spf` 子树只剩空父节点是符合预期的。

## 补齐用户态前提后重新触发

把真实 `vendor/odm` 和服务前提补回去，再按优化过的内核顺序重走一次。

```bash
adb shell 'mkdir -p /mnt/real_vendor /mnt/real_odm; mount | grep -q " /mnt/real_vendor " || mount -t erofs -o ro /dev/block/dm-2 /mnt/real_vendor; mount | grep -q " /mnt/real_odm " || mount -t erofs -o ro /dev/block/dm-5 /mnt/real_odm; mount | grep -q " /vendor/bin " || mount -o bind /mnt/real_vendor/bin /vendor/bin; mount | grep -q " /vendor/bin/hw " || mount -o bind /mnt/real_vendor/bin/hw /vendor/bin/hw; mount | grep -q " /vendor/lib64 " || mount -o bind /mnt/real_vendor/lib64 /vendor/lib64; mount | grep -q " /odm " || mount -o bind /mnt/real_odm /odm; start vendor.vndservicemanager; start vendor.pd_mapper; start vendor.per_mgr; start vendor.adsprpcd; start vendor.audioadsprpcd_audiopd; start vendor.audio-hal-aidl; sleep 4; echo ---svc---; getprop init.svc.vendor.adsprpcd; getprop init.svc.vendor.audioadsprpcd_audiopd; getprop init.svc.vendor.audio-hal-aidl; getprop init.svc.vendor.pd_mapper; getprop init.svc.vendor.per_mgr; echo ---spf---; ls /sys/devices/platform/soc/soc:spf_core_platform'
```

服务前提已补回，`adsprpcd`、`audioadsprpcd`、`audio-hal`、`pd_mapper` 都在跑，`per_mgr` 还是重启状态但不影响推进。现在重新触发 `SSR + spf rebind + swr-mgr + sound probe`。

```bash
adb shell 'echo 1 > /sys/kernel/boot_adsp/ssr; sleep 4; echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/unbind; sleep 1; echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/bind; sleep 4; for n in rx_swr_ctrl va_swr_ctrl bt_swr_mstr; do [ -e /sys/bus/platform/devices/$n ] && { echo swr-mgr > /sys/bus/platform/devices/$n/driver_override; echo $n > /sys/bus/platform/drivers_probe; }; done; [ -e /sys/bus/platform/devices/soc:qcom,msm-stub-codec ] && { insmod /vendor_dlkm/lib/modules/stub_dlkm.ko 2>/dev/null || true; }; [ -e /sys/bus/platform/devices/soc:spf_core_platform:sound ] && { echo sun-asoc-snd > /sys/bus/platform/devices/soc:spf_core_platform:sound/driver_override; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe; }; sleep 4; echo ---spf---; ls /sys/devices/platform/soc/soc:spf_core_platform; echo ---sounddrv---; readlink /sys/bus/platform/devices/soc:spf_core_platform:sound/driver 2>/dev/null || echo no_driver; echo ---cards---; cat /proc/asound/cards 2>/dev/null; echo ---pcm---; cat /proc/asound/pcm 2>/dev/null; echo ---snd---; ls /dev/snd 2>/dev/null; echo ---defer---; cat /sys/kernel/debug/devices_deferred 2>/dev/null; echo ---sdw---; ls -l /sys/bus/soundwire/devices 2>/dev/null | sed -n "1,120p"'
```

**结论**：状态又前进了一点。`devices_deferred` 已经清空，说明内核不再把 `sound` 当成"还要等资源"的节点。但它依然没绑上 driver，最后差异已经从 "defer" 收敛成了 "`sun-asoc-snd` 没接管"。

## 确认 machine_dlkm 和 sun-asoc-snd 当前状态

```bash
adb shell 'ls /sys/bus/platform/drivers/sun-asoc-snd 2>/dev/null || echo no_sun_driver; echo ---; lsmod | grep machine_dlkm || echo no_machine'
```

```bash
adb shell 'cat /sys/bus/platform/devices/soc:spf_core_platform:sound/driver_override 2>/dev/null || echo no_override; echo ---; cat /sys/bus/platform/devices/soc:spf_core_platform:sound/modalias 2>/dev/null || echo no_modalias; echo ---; ls /sys/bus/platform/devices/soc:spf_core_platform:sound 2>/dev/null'
```

```bash
adb shell 'echo sun-asoc-snd > /sys/bus/platform/devices/soc:spf_core_platform:sound/driver_override; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe; sleep 1; readlink /sys/bus/platform/devices/soc:spf_core_platform:sound/driver 2>/dev/null || echo no_driver'
```

**结论**：`pinctrl_lpi`、`swr-mgr`、`stub codec` 都是 recovery 缺的关键环节，补完以后 `sound` 仍不绑定。

文档补入 TWRP音频手动Bring-up.md，记录当前收敛状态。

## 转向正常系统对照

不再盲试更多模块，走"正常系统对照 recovery"的路线。先确认设备模式，再在正常系统里拿 `sun-asoc-snd` 成功绑定时的内核/ASoC 细节。

```bash
adb shell getprop ro.bootmode
```

```bash
adb shell id
```

```bash
adb root
```

当前在 recovery，有 root。切回正常系统抓数据。

```bash
adb reboot
```

```bash
adb wait-for-device && adb shell 'until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 2; done; echo ready'
```

系统已启动，抓三组高价值数据。

```bash
adb shell 'readlink /sys/bus/platform/devices/soc:spf_core_platform:sound/driver 2>/dev/null || echo no_driver; echo ---; ls -1 /sys/bus/platform/drivers/sun-asoc-snd 2>/dev/null; echo ---; ls -1 /sys/bus/platform/devices/soc:spf_core_platform:sound 2>/dev/null'
```

```bash
adb shell 'echo ===components===; sed -n "1,200p" /sys/kernel/debug/asoc/components 2>/dev/null; echo ---; echo ===dais===; sed -n "1,260p" /sys/kernel/debug/asoc/dais 2>/dev/null; echo ---; echo ===cards===; find /sys/kernel/debug/asoc -maxdepth 2 -type f | sed -n "1,120p"'
```

```bash
adb shell 'dmesg | grep -i "sun-asoc-snd\|snd_soc_register_card\|wcd939x\|msm-stub-codec\|lpass-cdc\|rx_macro\|va_macro" | tail -120'
```

**新线索**：正常系统里 `soc:spf_core_platform:sound` 下面已经长出大量 `TDM-LPAIF_*`、`PCM_*`、`USB_AUDIO-*`、`DISPLAY_PORT-*` 这类子节点，说明 `sun-asoc-snd` 成功后会在 `sound` 下面继续挂出完整的音频前后端图。

## 尝试从内核日志获取更多细节

```bash
adb shell 'logcat -b kernel -d | grep -i "sun-asoc-snd\|snd_soc_register_card\|wcd939x\|msm-stub-codec\|lpass-cdc\|rx_macro\|va_macro\|LPAIF" | tail -160'
```

```bash
adb shell 'logcat -b kernel -d | grep -i "spf_core_platform\|swr-mgr\|qcom-lpi-pinctrl\|msm-stub-codec" | tail -160'
```

```bash
adb shell 'cat /proc/asound/pcm 2>/dev/null | sed -n "1,160p"'
```

正常系统的内核日志缓冲没给出可用信息。确认权限状态：

```bash
adb shell id
```

```bash
adb shell 'ls -l /proc/asound /proc/asound/pcm /proc/asound/cards 2>/dev/null; echo ---; cat /proc/asound/cards 2>/dev/null || echo no_cards; echo ---; cat /proc/asound/pcm 2>/dev/null || echo no_pcm'
```

```bash
adb shell 'getprop ro.bootmode; getprop sys.boot_completed'
```

系统里 adbd 掉回非 root 了，尝试拉回 root：

```bash
adb root
```

```bash
adb wait-for-device && adb shell id
```

```bash
adb shell 'getprop ro.bootmode; getprop sys.boot_completed; readlink /sys/bus/platform/devices/soc:spf_core_platform:sound/driver 2>/dev/null || echo no_driver'
```

系统侧 `adb root` 走不通。切回离线模块分析，从 `machine_dlkm.ko` 的字符串和参数里找 probe 条件。

## 离线分析 machine_dlkm.ko

```bash
adb shell 'strings /vendor_dlkm/lib/modules/machine_dlkm.ko 2>/dev/null | grep -i -E "defer|stub|wsa|mi2s|tdm|auxpcm|lpaif|snd_soc|register card|sun-asoc|probe fail|missing|No DT match|codec|component" | sed -n "1,240p"'
```

```bash
adb shell 'modinfo /vendor_dlkm/lib/modules/machine_dlkm.ko 2>/dev/null | sed -n "1,120p"'
```

```bash
adb shell 'ls /sys/module/machine_dlkm/parameters 2>/dev/null || echo no_params; echo ---; find /sys/module/machine_dlkm -maxdepth 2 -type f | sed -n "1,120p"'
```

**新方向**：`machine_dlkm.ko` 内部明确包含大量 `wsa-codec*`、`TDM-LPAIF_WSA*`、`wsa_max_devs` 相关逻辑，并且带了 `softdep=pre: btfmcodec`。做最小对照：正常系统里的 WSA 节点状态是否和 recovery 一样，以及 `btfmcodec` 在系统里到底有没有。

## WSA 节点与 btfmcodec 对照

```bash
adb shell 'for n in /proc/device-tree/soc/spf_core_platform/wsa_swr_clk_data_pinctrl/status /proc/device-tree/soc/spf_core_platform/wsa2_swr_clk_data_pinctrl/status /proc/device-tree/soc/spf_core_platform/lpass-cdc/wsa-macro@6B00000/status /proc/device-tree/soc/spf_core_platform/lpass-cdc/wsa2-macro@6AA0000/status; do echo ===$n===; strings $n 2>/dev/null || echo no_status; done'
```

```bash
adb shell 'ls /sys/bus/platform/drivers | grep -i btfm || echo none; echo ---; ls /sys/bus/platform/devices | grep -i btfm || echo none; echo ---; ls /sys/bus/soundwire/devices | grep -i btfm || echo none'
```

```bash
adb shell 'for f in /vendor_dlkm/lib/modules/*.ko; do strings $f 2>/dev/null | grep -q "btfmcodec" && echo $f; done'
```

**关键发现**：正常系统里同一批 `wsa_swr_clk_data_pinctrl`、`wsa2_swr_clk_data_pinctrl`、`wsa-macro`、`wsa2-macro` 节点都没有 `status=disabled`，而之前在 recovery 里读到的是明确的 `disabled`。recovery 和系统的运行时 DT 在 WSA 分支上确实不一致。

## 切回 Recovery 复核 WSA 和 btfmcodec

```bash
adb reboot recovery
```

```bash
adb wait-for-device && adb shell getprop ro.bootmode
```

设备在切回 recovery，确认是否已回来：

```bash
adb devices
```

```bash
fastboot devices
```

已回来，做 recovery 侧最小复核。

```bash
adb shell 'getprop ro.bootmode; for n in /proc/device-tree/soc/spf_core_platform/wsa_swr_clk_data_pinctrl/status /proc/device-tree/soc/spf_core_platform/wsa2_swr_clk_data_pinctrl/status /proc/device-tree/soc/spf_core_platform/lpass-cdc/wsa-macro@6B00000/status /proc/device-tree/soc/spf_core_platform/lpass-cdc/wsa2-macro@6AA0000/status; do echo ===$n===; strings $n 2>/dev/null || echo no_status; done'
```

```bash
adb shell 'insmod /vendor_dlkm/lib/modules/btfmcodec.ko 2>/dev/null || true; insmod /vendor_dlkm/lib/modules/bt_fm_swr.ko 2>/dev/null || true; insmod /vendor_dlkm/lib/modules/btfm_slim_codec.ko 2>/dev/null || true; echo ---mods---; lsmod | grep -i btfm || echo no_btfm; echo ---drv---; ls /sys/bus/platform/drivers | grep -i btfm || echo no_btfm_driver; echo ---sdw---; ls /sys/bus/soundwire/devices | grep -i btfm || echo no_btfm_sdw'
```

```bash
adb shell 'readlink /sys/bus/platform/devices/soc:spf_core_platform:sound/driver 2>/dev/null || echo no_driver; echo ---; cat /sys/kernel/debug/devices_deferred 2>/dev/null || echo no_defer'
```

**结论**：`btfmcodec` 不是决定性缺口，真正稳定可复现的新根因是 recovery 运行时 DT 里 WSA 分支被禁用了，而正常系统没有。

## 搜索 WSA 节点在源码中的来源

在工作区中搜索 WSA 相关 DT 节点：

```bash
rg -n "wsa_swr_clk_data_pinctrl|wsa2_swr_clk_data_pinctrl|wsa-macro@6B00000|wsa2-macro@6AA0000|qcom,dedicated-wsa2|qcom,wsa-max-devs" device_tree twrp_a12_compile twrp_a16_compile docs -g '!**/.git/**'
```

```bash
rg -n "pinctrl_lpi_dlkm|stub_dlkm|btfmcodec|machine_dlkm|TW_LOAD_VENDOR_MODULES" device_tree -g '!**/.git/**'
```

源码侧直接搜不到 WSA 节点文本，说明这批 DT 不是以明文 dts 放在当前工作区里。

## 定位 dtb/dtbo 产物来源

```bash
find device_tree -iname '*dtb*' -o -iname '*dtbo*' -o -iname 'vendor_boot*' | sed -n '1,200p'
```

确认 recovery 中已实测必须的模块：

```bash
adb shell 'ls /vendor_dlkm/lib/modules | grep -E "pinctrl_lpi_dlkm|stub_dlkm|swr_ctrl_dlkm|lpass_bt_swr_dlkm|machine_dlkm|audio_pkt_dlkm|audio_prm_dlkm|audpkt_ion_dlkm|frpc-adsprpc|oplus_audio_daemon" | sort'
```

把实测确认"默认 recovery 漏掉但确实能把链路向前推进"的模块清单落到设备树配置里（修改 BoardConfig.mk）。

## 搜索 vendor_boot / dtbo 构建配置

```bash
rg -n "vendor_boot|dtbo|BOARD_PREBUILT_DTBOIMAGE|BOARD_INCLUDE_DTB_IN_BOOTIMG|BOARD_BOOT_HEADER_VERSION|BOARD_MKBOOTIMG_ARGS|TW_LOAD_VENDOR_MODULES" device_tree/twrp_device_oplus_ossi_source_built -g '!**/.git/**'
```

```bash
rg -n "vendor_boot|dtbo|mkbootimg|recovery\.img|TWRP-3\.7\.1-16-ossi" device_tree/twrp_device_oplus_ossi_source_built docs README.md -g '!**/.git/**'
```

方向收紧到"recovery 运行时 DT 和正常系统在 WSA 分支上不一致"。先看工作区里有没有现成的 `vendor_boot`/`dtbo` 镜像。

```bash
find . -iname 'vendor_boot*.img' -o -iname 'dtbo*.img' | sed -n '1,200p'
```

```bash
adb shell 'ls -l /dev/block/by-name/vendor_boot_a /dev/block/by-name/dtbo_a 2>/dev/null'
```

## 离线解包 vendor_boot 和 dtbo 镜像

工作区里已有 `vendor_boot_a.img` 和 `dtbo_a.img`，用 magiskboot 解包。

```bash
./magiskboot --help | sed -n '1,120p'
```

```bash
./magiskboot dtb --help | sed -n '1,160p'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/unpack_compare' && cp -f ../vendor_boot_a.img . && cp -f ../dtbo_a.img . && ../../magiskboot unpack -n -h vendor_boot_a.img && ../../magiskboot unpack -n -h dtbo_a.img && ls -1
```

`vendor_boot` 已解出 `dtb`，`dtbo` 这边 magiskboot 直接崩了。用 `vendor_boot` 解出来的 `dtb` 做打印和关键字搜索。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/unpack_compare' && ls -1
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/unpack_compare' && ../../magiskboot dtb dtb print | grep -n -E 'wsa_swr_clk_data_pinctrl|wsa2_swr_clk_data_pinctrl|wsa-macro@6B00000|wsa2-macro@6AA0000|status = |spf_core_platform|sun-asoc-snd' | sed -n '1,240p'
```

`vendor_boot` 这边已能看到 WSA 分支完整存在，而且检索结果里没有把 `status = disabled` 打出来，基本支持"问题不在 vendor_boot 主 dtb"。只剩 `dtbo` 这层最可疑，直接对 `dtbo_a.img` 试 `dtb print`。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && ../magiskboot dtb dtbo_a.img print | grep -n -E 'wsa_swr_clk_data_pinctrl|wsa2_swr_clk_data_pinctrl|wsa-macro@6B00000|wsa2-macro@6AA0000|status = |spf_core_platform|sun-asoc-snd' | sed -n '1,240p'
```

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && strings dtbo_a.img | grep -n -E 'wsa_swr_clk_data_pinctrl|wsa2_swr_clk_data_pinctrl|wsa-macro@6B00000|wsa2-macro@6AA0000|disabled|spf_core_platform' | sed -n '1,240p'
```

## 纠正：系统侧改用 su -c 继续对照

之前的判断不够严谨，把"adbd 不是 root"误当成"系统侧拿不到 root"。系统侧 `su` 命令是可用的。后续全程改用 `adb shell su -c ...`。

```bash
adb devices
```

```bash
adb shell getprop ro.bootmode
```

```bash
adb shell 'su -c id'
```

当前设备在 recovery，这里没有 `su`。进正常系统后用 `su -c` 抓对照数据。

```bash
adb reboot
```

```bash
adb wait-for-device && adb shell 'until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 2; done; echo ready'
```

系统已启动，用 `su -c` 抓三件事：`sound` 绑定状态、ASoC 组件视图、WSA 节点状态。

```bash
adb shell 'su -c "id; getprop ro.bootmode; readlink /sys/bus/platform/devices/soc:spf_core_platform:sound/driver 2>/dev/null || echo no_driver"'
```

```bash
adb shell 'su -c "echo ===components===; sed -n 1,120p /sys/kernel/debug/asoc/components 2>/dev/null; echo ---; echo ===dais===; sed -n 1,160p /sys/kernel/debug/asoc/dais 2>/dev/null"'
```

```bash
adb shell 'su -c "for n in /proc/device-tree/soc/spf_core_platform/wsa_swr_clk_data_pinctrl/status /proc/device-tree/soc/spf_core_platform/wsa2_swr_clk_data_pinctrl/status /proc/device-tree/soc/spf_core_platform/lpass-cdc/wsa-macro@6B00000/status /proc/device-tree/soc/spf_core_platform/lpass-cdc/wsa2-macro@6AA0000/status; do echo ===$n===; strings $n 2>/dev/null || echo no_status; done"'
```

系统侧 `su` 已确认可用，`sound` 设备确实绑定到了 `sun-asoc-snd`。

改用 `tr -d '\0'` 准确读取 DT 属性状态：

```bash
adb shell 'su -c "for p in /proc/device-tree/soc/spf_core_platform/wsa_swr_clk_data_pinctrl/status /proc/device-tree/soc/spf_core_platform/wsa2_swr_clk_data_pinctrl/status /proc/device-tree/soc/spf_core_platform/lpass-cdc/wsa-macro@6B00000/status /proc/device-tree/soc/spf_core_platform/lpass-cdc/wsa2-macro@6AA0000/status; do echo ===$p===; if [ -e $p ]; then tr -d \"\\000\" < $p; echo; else echo no_status; fi; done"'
```

```bash
adb shell 'su -c "ls /sys/bus/platform/devices | grep -i \"wsa.*swr\|wsa.*macro\" || echo none; echo ---; ls -l /sys/bus/soundwire/devices 2>/dev/null | grep -i wsa || echo no_wsa_sdw"'
```

```bash
adb shell 'su -c "grep -i wsa /sys/kernel/debug/asoc/components 2>/dev/null || echo no_wsa_component; echo ---; grep -i wsa /sys/kernel/debug/asoc/dais 2>/dev/null || echo no_wsa_dai"'
```

改用更稳定的写法避免引号被吃掉：

```bash
adb shell 'for p in /proc/device-tree/soc/spf_core_platform/wsa_swr_clk_data_pinctrl/status /proc/device-tree/soc/spf_core_platform/wsa2_swr_clk_data_pinctrl/status /proc/device-tree/soc/spf_core_platform/lpass-cdc/wsa-macro@6B00000/status /proc/device-tree/soc/spf_core_platform/lpass-cdc/wsa2-macro@6AA0000/status; do echo ===$p===; su -c "if [ -e $p ]; then cat $p | tr -d \"\\000\"; echo; else echo no_status; fi"; done'
```

```bash
adb shell 'su -c "ls /sys/bus/platform/devices" | grep -i wsa || echo none; echo ---; su -c "ls -1 /sys/bus/soundwire/devices" | grep -i wsa || echo no_wsa_sdw'
```

```bash
adb shell 'su -c "cat /sys/kernel/debug/asoc/components 2>/dev/null" | grep -i wsa || echo no_wsa_component; echo ---; su -c "cat /sys/kernel/debug/asoc/dais 2>/dev/null" | grep -i wsa || echo no_wsa_dai'
```

## WSA 不是根因，回归 sound 子树差异

**重要推翻**：正常系统里这批 WSA 节点同样是 `disabled`，而且系统里也没有 WSA 的 platform 设备、SoundWire 设备和 ASoC 实体。所以 WSA 不是 recovery 最后卡住 `sun-asoc-snd` 的根因。

现在回到真正有差异的地方：系统里 `sound` 已经绑定后，下面多出了哪些子节点。

```bash
adb shell 'su -c "ls -R /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound 2>/dev/null" | sed -n 1,240p'
```

```bash
adb shell 'su -c "find /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound -maxdepth 2 -type l -name \"supplier:*\" -o -name \"consumer:*\"" | sed -n 1,120p'
```

```bash
adb shell 'su -c "for n in /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/*; do b=$(basename $n); case $b in TDM-*|PCM_*|MI2S*|USB_AUDIO-*|DISPLAY_PORT-*|VA_*|VOICE_*|AUDIO_*) echo $b; esac; done" | sort -u | sed -n 1,200p'
```

**新信息**：`sun-asoc-snd` 成功后，会在 `sound` 下面挂出一整套 `TDM-LPAIF_*`、`PCM_*`、`USB_AUDIO-*`、`DISPLAY_PORT-*`、`BTFM_PROXY-*` 后端节点。recovery 里完全没有这棵子树。问题仍然是 machine card 根本没被接管。

## 重新追查 btfmcodec

注意到 `machine_dlkm` 有 `softdep=pre: btfmcodec`，而系统成功后 `sound` 子树里又有 `BTFM_PROXY-*`，这值得直接验证。

```bash
adb shell 'su -c "ls /vendor_dlkm/lib/modules /vendor/lib/modules /system/lib/modules 2>/dev/null" | grep -i btfm || echo no_btfm_module'
```

```bash
adb shell 'su -c "for f in /vendor_dlkm/lib/modules/*.ko /vendor/lib/modules/*.ko /system/lib/modules/*.ko; do [ -f $f ] || continue; strings $f 2>/dev/null | grep -q btfmcodec && echo $f; done"'
```

```bash
adb shell 'su -c "lsmod" | grep -i btfm || echo no_btfm_loaded'
```

```bash
adb shell 'su -c "cat /proc/modules" | grep -i btfm || echo no_btfm_loaded'
```

系统里确实已加载 `btfmcodec` 和 `btfm_slim_codec`，而 `sound` 子树里也确实有 `BTFM_PROXY-*`。`btfmcodec` 重新变成了高价值怀疑点。

找全 recovery 可用的蓝牙音频模块名：

```bash
adb shell 'su -c "ls /vendor_dlkm/lib/modules /vendor/lib/modules 2>/dev/null" | grep -i btfm | sort -u'
```

```bash
adb shell 'su -c "for f in /vendor_dlkm/lib/modules/*btfm*.ko /vendor/lib/modules/*btfm*.ko; do [ -f $f ] || continue; echo ===$f===; modinfo $f 2>/dev/null | sed -n 1,40p; done"'
```

```bash
adb shell 'su -c "lsmod | grep -i bt_fm_swr || cat /proc/modules | grep -i bt_fm_swr || echo no_bt_fm_swr"'
```

蓝牙音频链最小集合：`bt_fm_swr`、`btfm_slim_codec`、`btfmcodec`。

## 带 btfm 的完整最短链验证

切回 recovery，把 btfm 插到已验证过的最短链里。

```bash
adb reboot recovery
```

```bash
adb wait-for-device && adb shell getprop ro.bootmode
```

确认是否已重新上线：

```bash
adb devices
```

```bash
fastboot devices
```

recovery 已回来，执行带 `btfm` 的完整最短链。

```bash
adb shell 'mkdir -p /mnt/real_vendor /mnt/real_odm; mount | grep -q " /mnt/real_vendor " || mount -t erofs -o ro /dev/block/dm-2 /mnt/real_vendor; mount | grep -q " /mnt/real_odm " || mount -t erofs -o ro /dev/block/dm-5 /mnt/real_odm; mount | grep -q " /vendor/bin " || mount -o bind /mnt/real_vendor/bin /vendor/bin; mount | grep -q " /vendor/bin/hw " || mount -o bind /mnt/real_vendor/bin/hw /vendor/bin/hw; mount | grep -q " /vendor/lib64 " || mount -o bind /mnt/real_vendor/lib64 /vendor/lib64; mount | grep -q " /odm " || mount -o bind /mnt/real_odm /odm; start vendor.vndservicemanager; start vendor.pd_mapper; start vendor.per_mgr; start vendor.adsprpcd; start vendor.audioadsprpcd_audiopd; start vendor.audio-hal-aidl; insmod /vendor_dlkm/lib/modules/pinctrl_lpi_dlkm.ko 2>/dev/null; insmod /vendor_dlkm/lib/modules/stub_dlkm.ko 2>/dev/null; for m in btfm_slim_codec.ko btfmcodec.ko btfm_slim_codec.ko bt_fm_swr.ko oplus_audio_daemon.ko audpkt_ion_dlkm.ko audio_prm_dlkm.ko audio_pkt_dlkm.ko frpc-adsprpc.ko wcd_core_dlkm.ko swr_dlkm.ko wcd939x_slave_dlkm.ko wcd9xxx_dlkm.ko mbhc_dlkm.ko wcd939x_dlkm.ko lpass_cdc_dlkm.ko swr_ctrl_dlkm.ko lpass_bt_swr_dlkm.ko oplus_audio_pa_manager.ko oplus_audio_sipa.ko oplus_audio_extend.ko sdca_registers_dlkm.ko wcd9378_dlkm.ko lpass_cdc_rx_macro_dlkm.ko lpass_cdc_tx_macro_dlkm.ko lpass_cdc_va_macro_dlkm.ko lpass_cdc_wsa_macro_dlkm.ko lpass_cdc_wsa2_macro_dlkm.ko wsa883x_dlkm.ko wsa884x_dlkm.ko q6_dlkm.ko machine_dlkm.ko; do [ -f /vendor_dlkm/lib/modules/$m ] && insmod /vendor_dlkm/lib/modules/$m 2>/dev/null; done; echo 1 > /sys/kernel/boot_adsp/ssr; sleep 4; echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/unbind; sleep 1; echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/bind; sleep 4; for n in rx_swr_ctrl va_swr_ctrl bt_swr_mstr; do [ -e /sys/bus/platform/devices/$n ] && { echo swr-mgr > /sys/bus/platform/devices/$n/driver_override; echo $n > /sys/bus/platform/drivers_probe; }; done; [ -e /sys/bus/platform/devices/soc:spf_core_platform:sound ] && { echo sun-asoc-snd > /sys/bus/platform/devices/soc:spf_core_platform:sound/driver_override; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe; }; sleep 4; echo ---sound---; readlink /sys/bus/platform/devices/soc:spf_core_platform:sound/driver 2>/dev/null || echo no_driver; echo ---cards---; cat /proc/asound/cards 2>/dev/null; echo ---pcm---; cat /proc/asound/pcm 2>/dev/null; echo ---snd---; ls /dev/snd 2>/dev/null; echo ---mods---; cat /proc/modules | grep -i btfm || echo no_btfm; echo ---defer---; cat /sys/kernel/debug/devices_deferred 2>/dev/null; echo ---sdw---; ls -l /sys/bus/soundwire/devices 2>/dev/null | sed -n "1,120p"'
```

## 确认 btfm 加入后的 ASoC 状态

```bash
adb shell 'grep -i btfm /sys/kernel/debug/asoc/components 2>/dev/null || echo no_btfm_component; echo ---; grep -i btfm /sys/kernel/debug/asoc/dais 2>/dev/null || echo no_btfm_dai'
```

```bash
adb shell 'sed -n 1,80p /sys/kernel/debug/asoc/components 2>/dev/null; echo ---; sed -n 1,120p /sys/kernel/debug/asoc/dais 2>/dev/null'
```

## 最终收敛结论

关于系统侧 root：系统侧 `su -c` 是可用的，拿到的是 `uid=0`，上下文是 `u:r:magisk:s0`。走不通的是 recovery 里的 `su`，那里根本没有这个命令。后面系统侧调试已改用 `su -c`，不再碰 `adb root`。

这轮排查排掉了以下关键底座：

1. `lpi-pinctrl` — 已补，`qcom-lpi-pinctrl` 成功绑定 `lpi_pinctrl@07760000`
2. `swr-mgr` — 已补，`rx_swr_ctrl`、`va_swr_ctrl`、`bt_swr_mstr` 都能被接管
3. `stub codec` — 已补，`msm-stub-codec` 已绑定
4. `btfmcodec` — 已补，`SoundWire` 里已出现 `btfmswr_slave`

这些补齐后的状态：

- `SoundWire` 总线已出现 `swr1`、`swr2`、`swr4`、`wcd939x-slave.*`、`btfmswr_slave.*`
- `rx/tx/va macro`、`lpass-cdc`、`stub codec`、`wcd939x codec` 等关键组件已接近正常系统
- `devices_deferred` 可以清空
- 但 `soc:spf_core_platform:sound` 依然不绑定 `sun-asoc-snd`
- `/dev/snd` 仍然只有 `timer`
- `/proc/asound/cards` 仍然为空

已排掉的根因：

1. 不是缺音频 DT
2. 不是缺主 VINTF
3. 不是缺 `aud_passthru`
4. 不是缺 `lpi-pinctrl`
5. 不是缺 `swr-mgr`
6. 不是缺 `msm-stub-codec`
7. 不是 `btfmcodec`
8. 不是 WSA 节点 `disabled`（系统侧同样是 `disabled`）
9. 也不再只是 "deferred probe 没清掉"

最后主阻塞收敛到唯一一点：`sun-asoc-snd` 在 recovery 中始终不接管 `soc:spf_core_platform:sound`，而正常系统里这一步是成立的。

下一步方向：
1. 直接对 `machine_dlkm` / `sun-asoc-snd` 的 probe 条件做源码级对照
2. 继续找 recovery 和系统在 CPU/AFE 侧还没显式暴露出来的最后差异

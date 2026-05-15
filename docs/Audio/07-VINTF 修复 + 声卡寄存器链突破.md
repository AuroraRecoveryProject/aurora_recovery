# VINTF 修复 + 声卡寄存器链突破

**行范围：5695-7387**

## 一、启动新注入镜像并验证服务注册状态

设备启动到 recovery，确认 adb 已连接后，读取最小基线状态。

```bash
adb devices -l
adb shell 'id; getenforce; getprop ro.bootmode; getprop ro.build.fingerprint; getprop ro.twrp.boot'
```

检查注入的 `vendor.audio-recovery-services.rc` 是否已落地：

```bash

adb shell 'ls -l /vendor/etc/init/vendor.audio-recovery-services.rc 2>/dev/null || echo missing; grep -n "service vendor.audioadsprpcd_audiopd\|service vendor.audio-hal-aidl\|service vendor.pd_mapper\|service vendor.per_mgr\|service vendor.adsprpcd" /vendor/etc/init/vendor.audio-recovery-services.rc 2>/dev/null || true'
```

注入已经生效，设备当前确实在 recovery，`/vendor/etc/init/vendor.audio-recovery-services.rc` 已存在。

## 二、验证音频服务启动与前线报错收敛

读取 `init.svc.*` 基线，然后依次启动关键服务并抓取状态和日志。

```bash
adb shell 'for s in vendor.pd_mapper vendor.per_mgr vendor.adsprpcd vendor.audioadsprpcd_audiopd vendor.audio-hal-aidl; do echo === $s ===; getprop init.svc.$s; done'
```

启动服务并观察状态变化：

```bash
adb shell 'dmesg -c >/dev/null 2>&1 || true; for s in vendor.pd_mapper vendor.per_mgr vendor.adsprpcd vendor.audioadsprpcd_audiopd vendor.audio-hal-aidl; do echo START:$s; start $s; sleep 1; echo STATE:$s=$(getprop init.svc.$s); done'
```

抓取日志查看 pd_mapper、adsprpcd、audiohalservice 等相关报错：

```bash
adb shell 'logcat -d -b all | grep -i "pd_mapper\|pm-service\|adsprpcd\|audioadsprpcd\|audiohalservice\|vendor.audio-hal-aidl\|Transport endpoint is not connected\|service vendor\." | tail -200'
```

**结论**：不是 `unknown service`，而是统一变成 `Unable to start service ... See dmesg`。注入方向是对的，当前阻塞收敛到 init 启动阶段本身。

抓取 init 的 dmesg 和 logcat 失败原因，重点检查 `file_contexts`、`service_contexts`、用户组、二进制是否存在：

```bash
adb shell 'dmesg | grep -i -E "init:.*(vendor\.pd_mapper|vendor\.per_mgr|vendor\.adsprpcd|vendor\.audioadsprpcd_audiopd|vendor\.audio-hal-aidl)|cannot find|Unable to start service|execv|setexeccon|service_contexts|seclabel|audioadsprpcd|adsprpcd|pd-mapper|pm-service|audiohalservice" | tail -200'
```

```bash
adb shell 'logcat -d -b kernel -b system -b main -b crash | grep -i -E "init.*(vendor\.pd_mapper|vendor\.per_mgr|vendor\.adsprpcd|vendor\.audioadsprpcd_audiopd|vendor\.audio-hal-aidl)|cannot find|Unable to start service|execv|setexeccon|audioadsprpcd|adsprpcd|pd-mapper|pm-service|audiohalservice" | tail -200'
```

检查二进制文件是否存在：

```bash
adb shell 'for f in /vendor/bin/pd-mapper /vendor/bin/pm-service /vendor/bin/adsprpcd /vendor/bin/audioadsprpcd /vendor/bin/hw/audiohalservice.qti; do echo === $f ===; ls -l $f 2>/dev/null || echo missing; done'
```

**结论**：不是 sepolicy，也不是 service 名没注册，而是 recovery 当前看到的 `/vendor` 里根本没有这些可执行文件。问题精确推进到"缺二进制落地"这一层。

## 三、手动挂载真实 vendor 分区

检查当前 vendor 分区挂载情况：

```bash
adb shell 'mount | grep -E " /vendor | /mnt/vendor|vendor_a|vendor_b"'
```

检查真实分区是否存在：

```bash
adb shell 'for d in /mnt/vendor_a /mnt/vendor_b /vendor /mnt/system_a /mnt/odm_a; do echo === $d ===; ls -ld $d 2>/dev/null || echo missing; done'
```

执行真实 vendor 二进制验证：

```bash
adb shell 'for f in /mnt/vendor_a/bin/pd-mapper /mnt/vendor_a/bin/pm-service /mnt/vendor_a/bin/adsprpcd /mnt/vendor_a/bin/audioadsprpcd /mnt/vendor_a/bin/hw/audiohalservice.qti; do echo === $f ===; ls -l $f 2>/dev/null || echo missing; done'
```

当前 recovery 还没把真实 vendor/system 挂出来，所以 `/vendor` 只是 ramdisk overlay，里面当然缺这些二进制。继续把真实分区手动挂到 `/mnt` 下，再验证这些服务能不能顺着真实 vendor 跑起来。

```bash
adb shell 'getprop ro.boot.slot_suffix; getprop ro.boot.slot; ls -l /dev/block/bootdevice/by-name | head -80'
```

```bash
adb shell 'cat /etc/fstab* 2>/dev/null | head -200'
```

```bash
adb shell 'find /dev/block/bootdevice/by-name -maxdepth 1 \( -name "vendor*" -o -name "system*" -o -name "odm*" -o -name "super" \) | sort'
```

这一步又有新信息：`fstab` 里声明了 `/vendor` 应该挂在 `dm-2` 上，但当前实际看到的 `/vendor/bin` 内容显然不像真实 vendor。我要把 `/vendor` 的实际挂载和目录来源查清，不然下一步没法做运行时嫁接。

```bash
adb shell 'mount | grep -w /vendor || cat /proc/mounts | grep -w /vendor || true'
```

```bash
adb shell 'ls -ld /vendor /vendor/bin /vendor/bin/hw; readlink /vendor 2>/dev/null || true; df /vendor 2>/dev/null || true; ls /vendor/bin | head -80; echo ---; ls /vendor/bin/hw | head -80'
```

```bash
adb shell 'ls -l /dev/block/dm-2 /dev/block/bootdevice/by-name/vendor; blkid /dev/block/dm-2 2>/dev/null || true'
```

**结论**：当前 `/vendor` 只是 rootfs 里的 recovery overlay，不是真实逻辑分区。

## 四、运行时嫁接真实 vendor/odm

将 `/dev/block/dm-2` 手动挂到临时目录并确认：

```bash
adb shell 'mkdir -p /mnt/real_vendor; mount -t erofs -o ro /dev/block/dm-2 /mnt/real_vendor && echo mounted || echo mount_failed; ls -ld /mnt/real_vendor; ls /mnt/real_vendor/bin | head -40'
```

确认目标二进制存在于真实 vendor 中：

```bash
adb shell 'for f in /mnt/real_vendor/bin/pd-mapper /mnt/real_vendor/bin/pm-service /mnt/real_vendor/bin/adsprpcd /mnt/real_vendor/bin/audioadsprpcd /mnt/real_vendor/bin/hw/audiohalservice.qti; do echo === $f ===; ls -l $f 2>/dev/null || echo missing; done'
```

```bash
adb shell 'for f in /mnt/real_vendor/etc/init/vendor.qti.audio-adsprpc-service.rc /mnt/real_vendor/etc/init/audiohalservice_qti.rc /mnt/real_vendor/etc/init/hw/init.target.rc; do echo === $f ===; ls -l $f 2>/dev/null || echo missing; done'
```

真实 vendor 已经挂出来，而且目标二进制都在。这就说明现在可以做纯运行时嫁接测试了，不需要再改镜像结构。关键点变成让 init 服务路径 `/vendor/bin/...` 能看到真实 vendor 的可执行文件和库。

### 4.1 绑定实时路径

检查 `/vendor` 当前缺哪些关键目录，再尽量用最小的 bind/symlink 嫁接方式恢复 `/vendor/bin`、`/vendor/bin/hw` 和库路径，然后马上重试服务启动。

```bash
adb shell 'for d in /vendor/bin /vendor/bin/hw /vendor/lib64 /vendor/etc/init /system/lib64 /odm/lib64; do echo === $d ===; ls -ld $d 2>/dev/null || echo missing; done'

adb shell 'for d in /mnt/real_vendor/bin /mnt/real_vendor/bin/hw /mnt/real_vendor/lib64 /system/lib64 /odm/lib64; do echo === $d ===; ls -ld $d 2>/dev/null || echo missing; done'
```

执行 bind mount 嫁接：

```bash
adb shell 'mount -o bind /mnt/real_vendor/bin /vendor/bin && mount -o bind /mnt/real_vendor/bin/hw /vendor/bin/hw && mount -o bind /mnt/real_vendor/lib64 /vendor/lib64 && echo bind_ok || echo bind_fail; for p in /vendor/bin/adsprpcd /vendor/bin/audioadsprpcd /vendor/bin/pd-mapper /vendor/bin/pm-service /vendor/bin/hw/audiohalservice.qti; do echo === $p ===; ls -l $p 2>/dev/null || echo missing; done'
```

运行时嫁接已经成了，`/vendor/bin` 和 `/vendor/lib64` 现在都能看到真实 vendor 的二进制和库。下面就该重试服务启动，看错误是否继续从 “找不到文件” 推进到真正的音频链路层。

```bash
adb shell 'dmesg -c >/dev/null 2>&1 || true; logcat -c >/dev/null 2>&1 || true; for s in vendor.pd_mapper vendor.per_mgr vendor.adsprpcd vendor.audioadsprpcd_audiopd vendor.audio-hal-aidl; do echo START:$s; start $s; sleep 2; echo STATE:$s=$(getprop init.svc.$s); done'
```

```bash
adb shell 'dmesg | grep -i -E "init:.*(vendor\.pd_mapper|vendor\.per_mgr|vendor\.adsprpcd|vendor\.audioadsprpcd_audiopd|vendor\.audio-hal-aidl)|Cannot find|error|failed|audioadsprpcd|adsprpcd|pd-mapper|pm-service|audiohalservice|Transport endpoint is not connected|execv|linker" | tail -300'
```

```bash
adb shell 'logcat -d -b all | grep -i -E "pd_mapper|pm-service|adsprpcd|audioadsprpcd|audiohalservice|vendor.audio-hal-aidl|Transport endpoint is not connected|linker|CANNOT LINK EXECUTABLE|ctl.start" | tail -300'
```

**结论**：已经跨过 init 启动层了，5 个服务都能保持 `running`。这说明注入 rc + 运行时嫁接二进制这套链路是有效的。

### 4.2 检查声卡与 DSP 状态

```bash
adb shell 'ps -A | grep -E "pd-mapper|pm-service|adsprpcd|audioadsprpcd|audiohalservice"; echo ---; ls -l /dev/snd; echo ---; cat /proc/asound/cards; echo ---; cat /proc/asound/pcm 2>/dev/null || true'
```

**结论**：`pd-mapper`、`pm-service`、`adsprpcd`、`audioadsprpcd`、`audiohalservice.qti` 全部常驻了，但 ALSA 还是没起来，`/proc/asound/cards` 仍然空。`pm-service` 卡在 `/dev/vndbinder` context object，`audioadsprpcd` 报 `/odm/lib/rfsa/adsp not found`。

## 五、补齐 odm 分区并诊断 DSP 日志

挂载真实 odm：

```bash
adb shell 'mkdir -p /mnt/real_odm; mount -t erofs -o ro /dev/block/dm-5 /mnt/real_odm && echo odm_mounted || echo odm_mount_failed; ls -ld /mnt/real_odm; ls -ld /mnt/real_odm/lib /mnt/real_odm/lib/rfsa /mnt/real_odm/lib/rfsa/adsp 2>/dev/null || true'
```

检查并 bind odm：

```bash
adb shell 'ls -ld /odm /odm/lib /odm/lib/rfsa /odm/lib/rfsa/adsp 2>/dev/null || true; mount -o bind /mnt/real_odm /odm && echo bind_odm_ok || echo bind_odm_fail; ls -ld /odm/lib /odm/lib/rfsa /odm/lib/rfsa/adsp 2>/dev/null || true'
```

检查 audio passthrough/FastRPC 设备节点和 DSP 日志：

```bash
adb shell 'ls -l /dev/aud_pasthru_adsp 2>/dev/null || echo no_aud_passthru; ls -l /dev/fastrpc-adsp* /dev/adsprpc-smd 2>/dev/null || true; dmesg | grep -i -E "q6 state is down|apm is not up|spf|gpr|sun-asoc-snd|asoc|snd card|sound card|audioreach|aud_pasthru|fastrpc|audio_pkt|q6core" | tail -300'
```

`/odm/lib/rfsa/adsp` 这条缺失路径已经补上了，而且 GPR 明确报了 `Q6 is Up`。现在重启音频相关服务看这个改动会不会把 `audioadsprpcd` 和 HAL 往前再推一步，并同时观察 `/dev/aud_pasthru_adsp` 和 ALSA 是否跟着出现。

重启音频相关服务看变化：

```bash
adb shell 'dmesg -c >/dev/null 2>&1 || true; logcat -c >/dev/null 2>&1 || true; stop vendor.audio-hal-aidl; stop vendor.audioadsprpcd_audiopd; stop vendor.adsprpcd; sleep 2; start vendor.adsprpcd; sleep 2; start vendor.audioadsprpcd_audiopd; sleep 2; start vendor.audio-hal-aidl; sleep 3; for s in vendor.adsprpcd vendor.audioadsprpcd_audiopd vendor.audio-hal-aidl; do echo STATE:$s=$(getprop init.svc.$s); done; echo ---; ls -l /dev/aud_pasthru_adsp 2>/dev/null || echo no_aud_passthru; ls -l /dev/snd; echo ---; cat /proc/asound/cards'
```

```bash
adb shell 'dmesg | grep -i -E "audioadsprpcd|adsprpcd|audiohalservice|aud_pasthru|apm|spf|gpr|q6 state is down|Transport endpoint is not connected|sun-asoc-snd|sound card|snd card" | tail -300'
```

```bash
adb shell 'logcat -d -b all | grep -i -E "audioadsprpcd|adsprpcd|audiohalservice|Transport endpoint is not connected|apm|spf|aud_pasthru|tinyalsa|sound card|snd card|binder" | tail -300'
```

**结论**：补齐 `odm` 之后，`audioadsprpcd` 和 HAL 仍然能稳定运行，但 `/dev/aud_pasthru_adsp`、`/dev/snd/controlC*` 和声卡枚举还是没有出现，说明问题已经不在“服务起不来”这一层了。现在要看的是服务起来以后，DSP/ASoC 为什么仍没把 machine/card 真正拉起来。

```bash
adb shell 'grep -R "sun-asoc-snd\|spf_core_platform\|qcom,sun-asoc-snd" /sys/bus/platform/drivers /sys/bus/platform/devices 2>/dev/null | head -200'
```

```bash
adb shell 'for p in /sys/bus/platform/drivers/sun-asoc-snd /sys/bus/platform/drivers/spf_core_platform /sys/bus/platform/devices/*sound* /sys/bus/platform/devices/*spf*; do ls -ld $p 2>/dev/null; done'
```

**结论**：最新线索基本收敛了：`audioadsprpcd` 现在已经能正确拿到 `DSP_LIBRARY_PATH=/odm/lib/rfsa/adsp`，所以 `odm` 路径问题已修好；但 sysfs 里仍然只看得到 `spf_core_platform` 父设备，没有 `sound`/machine 侧实例，这和声卡仍为空是一致的。下一步我直接核对内核音频模块和 ASoC 驱动绑定情况。

## 六、检查并加载内核音频模块链

检查已加载的内核模块：

```bash
adb shell 'lsmod | grep -i -E "audio|snd|asoc|spf|gpr|bolero|wsa|wcd|lpass|machine|q6|oplus_audio|audio_pkt|audpkt|audio_prm|fastrpc" | sort'
```

检查各模块目录是否存在：

```bash
adb shell 'for d in /sys/module/spf_core /sys/module/gpr /sys/module/audio_pkt /sys/module/audpkt_ion /sys/module/audio_prm /sys/module/oplus_audio_daemon /sys/module/machine_dlkm /sys/module/snd_soc_sun /sys/module/snd_soc_wcd937x /sys/module/snd_event /sys/module/bolero_cdc; do echo === $d ===; ls -ld $d 2>/dev/null || echo missing; done'

adb shell 'for p in /sys/bus/platform/drivers/spf_core_platform /sys/bus/platform/drivers/sun-asoc-snd /sys/bus/platform/drivers/*audio* /sys/bus/platform/drivers/*asoc*; do ls -ld $p 2>/dev/null; done'
```

**结论**：用户态已经起来，但内核侧并没有把音频 machine/packet/daemon 这条模块链带起来。当前只看到 `gpr_dlkm`、`spf_core_dlkm` 这类基础件，缺的正是之前已经确认过会影响 `/dev/aud_pasthru_adsp` 和声卡注册的那批模块。

### 6.1 定位并加载 vendor_dlkm 中的模块

列出 `vendor_dlkm` 中的音频相关模块：

```bash
adb shell 'ls -ld /vendor_dlkm /vendor_dlkm/lib/modules; find /vendor_dlkm/lib/modules -type f | grep -E "(frpc-adsprpc|audio_pkt_dlkm|audpkt_ion_dlkm|audio_prm_dlkm|oplus_audio_daemon|machine_dlkm|wcd|wsa|lpass|bolero|rx-macro|tx-macro|va-macro)\.ko$" | sort | head -200'
```

检查模块加载工具：

```bash
adb shell 'command -v modprobe || command -v insmod || command -v busybox'
```

检查模块依赖文件：

```bash
adb shell 'find /vendor_dlkm/lib/modules -maxdepth 2 \( -name modules.dep -o -name modules.alias -o -name modules.load -o -name modules.order \) -print | sort'
```

模块文件和 `modules.dep` 都在，`modprobe` 也可用，这就不需要手写一串 `insmod` 了。我接着按最小链路把缺失模块补齐，然后立刻检查设备节点和声卡枚举。

```bash
adb shell 'modprobe --help 2>&1 | head -80'
```

```bash
adb shell 'grep -E "^(frpc-adsprpc|audio_pkt_dlkm|audio_prm_dlkm|audpkt_ion_dlkm|oplus_audio_daemon|machine_dlkm):" /vendor_dlkm/lib/modules/modules.dep'
```

```bash
adb shell 'cat /vendor_dlkm/lib/modules/modules.load'
```

`modprobe` 支持指定目录，足够了。`modules.dep` 的 grep 没命中，多半只是条目写的是完整相对路径，我直接让 `modprobe -D` 展开依赖，再按它给的结果加载。

```bash
adb shell 'for m in frpc-adsprpc audio_pkt_dlkm audio_prm_dlkm audpkt_ion_dlkm oplus_audio_daemon machine_dlkm; do echo === $m ===; modprobe -D -d /vendor_dlkm/lib/modules $m 2>&1; done'
```

### 6.2 绑定模块目录并手动 insmod

```bash
adb shell 'lsmod | grep -E "frpc|audio_pkt|audio_prm|audpkt|oplus_audio|machine_dlkm" || true'
```

依赖已经很清楚了，而且这些模块当前确实没加载。还有一个细节要先处理：`modprobe -D` 展开的依赖路径指向的是 `/vendor/lib/modules`，先确认这个目录视图对不对，再执行实际加载，避免把模块目录喂错。

```bash
adb shell 'ls -ld /vendor/lib/modules /vendor_dlkm/lib/modules 2>/dev/null || true; ls /vendor/lib/modules 2>/dev/null | head -20 || true'
```

绑定模块目录：

```bash
adb shell 'mkdir -p /vendor/lib/modules && mount -o bind /vendor_dlkm/lib/modules /vendor/lib/modules && echo bind_modules_ok || echo bind_modules_fail; ls -ld /vendor/lib/modules; ls /vendor/lib/modules | grep -E "^(frpc-adsprpc|audio_pkt_dlkm|audio_prm_dlkm|audpkt_ion_dlkm|oplus_audio_daemon|machine_dlkm)\.ko$"'

adb shell 'for m in oplus_audio_daemon audpkt_ion_dlkm audio_prm_dlkm audio_pkt_dlkm frpc-adsprpc machine_dlkm; do echo LOAD:$m; modprobe -d /vendor/lib/modules $m || echo FAIL:$m; done; echo ---; lsmod | grep -E "frpc|audio_pkt|audio_prm|audpkt|oplus_audio|machine_dlkm|wcd|wsa|lpass_cdc|swr|mbhc" | sort'
```

`modprobe` 的 `-d` 不是直接喂模块目录，而是喂“根目录”。刚才失败就是这个原因。我先用最小改动修正成 `-d /vendor_dlkm`，必要时再补一个 `/vendor/lib/modules` 视图。

```bash
adb shell 'for m in oplus_audio_daemon audpkt_ion_dlkm audio_prm_dlkm audio_pkt_dlkm frpc-adsprpc machine_dlkm; do echo === $m ===; modprobe -D -d /vendor_dlkm $m 2>&1 | head -80; done'

adb shell 'mkdir -p /vendor/lib/modules && mount -o bind /vendor_dlkm/lib/modules /vendor/lib/modules && echo bind_modules_ok || echo bind_modules_fail; ls -ld /vendor/lib/modules; ls /vendor/lib/modules | grep -E "^(frpc-adsprpc|audio_pkt_dlkm|audio_prm_dlkm|audpkt_ion_dlkm|oplus_audio_daemon|machine_dlkm)\.ko$"'

adb shell 'for m in oplus_audio_daemon audpkt_ion_dlkm audio_prm_dlkm audio_pkt_dlkm frpc-adsprpc machine_dlkm; do echo LOAD:$m; modprobe -d /vendor_dlkm $m || echo FAIL:$m; done; echo ---; lsmod | grep -E "frpc|audio_pkt|audio_prm|audpkt|oplus_audio|machine_dlkm|wcd|wsa|lpass_cdc|swr|mbhc" | sort'
```

改用 `modprobe -d /vendor_dlkm` 尝试加载，但 `modprobe` 这版在 recovery 里不认这批 vendor 模块名。改用 `insmod` 直接硬插：

```bash
adb shell 'for f in /vendor/lib/modules/oplus_audio_daemon.ko /vendor/lib/modules/audpkt_ion_dlkm.ko /vendor/lib/modules/audio_prm_dlkm.ko /vendor/lib/modules/audio_pkt_dlkm.ko /vendor/lib/modules/frpc-adsprpc.ko /vendor/lib/modules/machine_dlkm.ko; do echo INSMOD:$f; insmod $f 2>&1 || echo FAIL:$f; done; echo ---; lsmod | grep -E "frpc|audio_pkt|audio_prm|audpkt|oplus_audio|machine_dlkm|wcd|wsa|lpass_cdc|swr|mbhc" | sort'
```

```bash
adb shell 'dmesg | tail -200 | grep -i -E "insmod|Unknown symbol|disagrees about version|module verification failed|audio_pkt|audio_prm|audpkt|oplus_audio|machine_dlkm|frpc|wcd|wsa|lpass|mbhc"'
```

```bash
adb shell 'ls -l /dev/aud_pasthru_adsp 2>/dev/null || echo no_aud_passthru; ls -l /dev/snd; cat /proc/asound/cards'
```

**结论**：音频 packet/PRM/FastRPC 内核链已插入，`/dev/aud_pasthru_adsp` 也出来了。`machine_dlkm` 失败，报一串 codec/CDC/PA 相关符号未满足。

### 6.3 补齐 codec/CDC/PA 模块

定位 machine 需要的 codec/CDC/PA 模块：

```bash
adb shell 'find /vendor/lib/modules -type f | grep -E "/(wcd_core_dlkm|swr_dlkm|wcd939x_slave_dlkm|wcd9xxx_dlkm|mbhc_dlkm|wcd939x_dlkm|lpass_cdc_dlkm|swr_ctrl_dlkm|oplus_audio_pa_manager|oplus_audio_sipa|oplus_audio_extend|sdca_registers_dlkm|wcd9378_dlkm|lpass_cdc_rx_macro_dlkm|wsa883x_dlkm|wsa884x_dlkm)\.ko$" | sort'
```

确认当前这些模块未加载：

```bash
adb shell 'lsmod | grep -E "wcd_core|swr_dlkm|wcd939x_slave|wcd9xxx|mbhc_dlkm|wcd939x_dlkm|lpass_cdc_dlkm|swr_ctrl_dlkm|oplus_audio_pa_manager|oplus_audio_sipa|oplus_audio_extend|sdca_registers_dlkm|wcd9378_dlkm|lpass_cdc_rx_macro_dlkm|wsa883x_dlkm|wsa884x_dlkm" || true'
```

按依赖顺序补齐 codec 侧模块：

```bash
adb shell 'for f in /vendor/lib/modules/wcd_core_dlkm.ko /vendor/lib/modules/swr_dlkm.ko /vendor/lib/modules/wcd939x_slave_dlkm.ko /vendor/lib/modules/wcd9xxx_dlkm.ko /vendor/lib/modules/mbhc_dlkm.ko /vendor/lib/modules/wcd939x_dlkm.ko /vendor/lib/modules/lpass_cdc_dlkm.ko /vendor/lib/modules/swr_ctrl_dlkm.ko /vendor/lib/modules/oplus_audio_pa_manager.ko /vendor/lib/modules/oplus_audio_sipa.ko /vendor/lib/modules/oplus_audio_extend.ko /vendor/lib/modules/sdca_registers_dlkm.ko /vendor/lib/modules/wcd9378_dlkm.ko /vendor/lib/modules/lpass_cdc_rx_macro_dlkm.ko /vendor/lib/modules/wsa883x_dlkm.ko /vendor/lib/modules/wsa884x_dlkm.ko /vendor/lib/modules/machine_dlkm.ko; do echo INSMOD:$f; insmod $f 2>&1 || echo FAIL:$f; done; echo ---; lsmod | grep -E "machine_dlkm|wcd_core|swr_dlkm|wcd939x_slave|wcd9xxx|mbhc_dlkm|wcd939x_dlkm|lpass_cdc_dlkm|swr_ctrl_dlkm|oplus_audio_pa_manager|oplus_audio_sipa|oplus_audio_extend|sdca_registers_dlkm|wcd9378_dlkm|lpass_cdc_rx_macro_dlkm|wsa883x_dlkm|wsa884x_dlkm" | sort'
```

**结论**：machine 依赖链已补齐，`machine_dlkm` 本体也成功插入。

检查声卡状态：

```bash
adb shell 'ls -l /dev/aud_pasthru_adsp 2>/dev/null || echo no_aud_passthru; echo ---; ls -l /dev/snd; echo ---; cat /proc/asound/cards; echo ---; cat /proc/asound/pcm 2>/dev/null || true'
```

```bash
adb shell 'for p in /sys/bus/platform/devices/*sound* /sys/bus/platform/devices/*spf* /sys/bus/platform/drivers/soc-audio/*; do ls -ld $p 2>/dev/null; done'
```

```bash
adb shell 'dmesg | grep -i -E "sun-asoc-snd|asoc|sound card|snd card|wcd|wsa|lpass|mbhc|audioreach|spf|apm|aud_pasthru|machine_dlkm" | tail -300'
```

**新阻塞点**：`machine_dlkm` 不再报未知符号，真正卡住的是 `spf-core-platform` 创建 device link 时找不到一批 LPASS 相关 provider（`vote_lpass_core_hw`、`vote_lpass_audio_hw`、`va_core_clk`、`rx_core_clk`、`tx_core_clk`）。

### 6.4 补充 LPASS provider 和 macro 模块

定位 LPASS 相关模块文件：

```bash
adb shell 'find /vendor/lib/modules -type f | grep -E "/(lpass_cdc_tx_macro_dlkm|lpass_cdc_va_macro_dlkm|lpass_cdc_wsa_macro_dlkm|lpass_cdc_wsa2_macro_dlkm|lpass_cdc_rx_macro_dlkm|lpass_cdc_dlkm|q6_dlkm|audio_ext_clk_.*|.*lpass.*|.*macro.*|.*vote.*)\.ko$" | sort | head -300'
```

检查 LPASS provider 设备节点：

```bash
adb shell 'for p in /sys/bus/platform/devices/soc:vote_lpass_core_hw /sys/bus/platform/devices/soc:vote_lpass_audio_hw /sys/bus/platform/devices/soc:va_core_clk /sys/bus/platform/devices/soc:rx_core_clk /sys/bus/platform/devices/soc:rx_core_tx_clk /sys/bus/platform/devices/soc:tx_core_clk /sys/bus/platform/devices/soc:bt_swr_mclk_clk /sys/bus/platform/devices/soc:bt_swr_mclk_clk_2x; do echo === $p ===; ls -ld $p 2>/dev/null || echo missing; done'

adb shell 'for d in /sys/bus/platform/drivers/*lpass* /sys/bus/platform/drivers/*macro* /sys/bus/platform/drivers/*wsa* /sys/bus/platform/drivers/*wcd*; do ls -ld $d 2>/dev/null; done'
```

这些 LPASS provider 设备节点现在其实已经出现了，所以刚才那批 `Failed to create device link` 更像是 machine 初次加载时机过早留下的旧报错。

加载剩余的 TX/VA/WSA macro 模块：

```bash
adb shell 'for f in /vendor/lib/modules/lpass_cdc_tx_macro_dlkm.ko /vendor/lib/modules/lpass_cdc_va_macro_dlkm.ko /vendor/lib/modules/lpass_cdc_wsa_macro_dlkm.ko /vendor/lib/modules/lpass_cdc_wsa2_macro_dlkm.ko /vendor/lib/modules/lpass_bt_swr_dlkm.ko /vendor/lib/modules/q6_dlkm.ko; do echo INSMOD:$f; insmod $f 2>&1 || echo FAIL:$f; done; echo ---; lsmod | grep -E "lpass_bt_swr|lpass_cdc_tx_macro|lpass_cdc_va_macro|lpass_cdc_wsa_macro|lpass_cdc_wsa2_macro|q6_dlkm" | sort'
```

验证驱动注册：

```bash
adb shell 'for d in /sys/bus/platform/drivers/lpass_cdc_tx_macro /sys/bus/platform/drivers/lpass_cdc_va_macro /sys/bus/platform/drivers/lpass_cdc_wsa_macro /sys/bus/platform/drivers/lpass_cdc_wsa2_macro /sys/bus/platform/drivers/lpass-bt-swr; do ls -ld $d 2>/dev/null || echo missing:$d; done'

adb shell 'dmesg | tail -220 | grep -i -E "lpass|macro|wsa|q6_dlkm|spf-core-platform|soc-audio|sun-asoc-snd|sound card|snd card"'
```

剩余 macro 模块都已经成功加载并注册了驱动，但声卡还没自动冒出来。

### 6.5 重探 spf_core_platform

检查 provider 设备和驱动绑定状态：

```bash
adb shell 'for p in /sys/bus/platform/devices/*macro* /sys/bus/platform/devices/*wsa* /sys/bus/platform/devices/*sound* /sys/bus/platform/devices/*spf* /sys/bus/platform/devices/*lpass*; do basename $p; done 2>/dev/null | sort | uniq | head -300'

adb shell 'for d in /sys/bus/platform/drivers/lpass_cdc_tx_macro /sys/bus/platform/drivers/lpass_cdc_va_macro /sys/bus/platform/drivers/lpass_cdc_wsa_macro /sys/bus/platform/drivers/lpass_cdc_wsa2_macro /sys/bus/platform/drivers/lpass-bt-swr /sys/bus/platform/drivers/spf_core_platform /sys/bus/platform/drivers/soc-audio; do echo === $d ===; ls -l $d 2>/dev/null || true; done'

adb shell 'for x in soc:spf_core_platform soc:tx_core_clk soc:va_core_clk soc:rx_core_clk soc:rx_core_tx_clk soc:bt_swr_mclk_clk soc:bt_swr_mclk_clk_2x soc:vote_lpass_core_hw soc:vote_lpass_audio_hw; do echo === $x ===; ls -l /sys/bus/platform/devices/$x/driver 2>/dev/null || echo unbound; done'
```

现在 provider 设备和对应 driver 都已经绑定好了，这说明 LPASS 这条链也补到了。剩下更像是 `spf_core_platform` 或 `soc-audio` 没有在 provider 补齐后自动重 probe，所以我直接看它的设备树子节点和驱动目录，再手动触发一次 bind。

```bash
adb shell 'find /sys/devices/platform/soc/soc:spf_core_platform -maxdepth 3 -mindepth 1 | sed -n "1,200p"'
```

```bash
adb shell 'ls /sys/bus/platform/drivers/spf-core-platform 2>/dev/null || ls /sys/bus/platform/drivers/spf_core_platform 2>/dev/null || true'

adb shell 'grep -R "qcom,sun-asoc-snd\|sound" /sys/firmware/devicetree/base/soc/spf_core_platform 2>/dev/null | head -100'
```

`spf_core_platform` 当前只有父设备，没有任何子节点，这和之前的核心判断完全一致。现在条件已经比之前完整得多，对这个父设备做一次 unbind/bind 触发重 probe，看它会不会终于把 `sound` 子设备实例化出来。

```bash
adb shell 'ls -la /sys/firmware/devicetree/base/soc/spf_core_platform 2>/dev/null | sed -n "1,120p"'

adb shell 'dmesg -c >/dev/null 2>&1 || true; echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/unbind; sleep 1; echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/bind; sleep 2; find /sys/devices/platform/soc/soc:spf_core_platform -maxdepth 3 -mindepth 1 | sed -n "1,120p"; echo ---; ls -l /dev/snd; echo ---; cat /proc/asound/cards'
```

```bash
adb shell 'dmesg | grep -i -E "spf-core-platform|soc-audio|sun-asoc-snd|sound card|snd card|audioreach|apm|gpr|lpass|failed to create device link|probe" | tail -300'
```

**核心结论**：依赖补齐后重 probe，`spf_core_platform` 不再报 device link，而是卡在 `__spf_core_is_apm_ready` 命令超时。

### 6.6 APM 超时时序验证

做最后一轮时序验证：把 FastRPC/音频用户态服务和 `spf_core_platform` 的重 probe 排成一条顺序，看 APM 超时是不是纯时序问题，还是在 recovery 里稳定不可达。

```bash
adb shell 'dmesg -c >/dev/null 2>&1 || true; stop vendor.audio-hal-aidl; stop vendor.audioadsprpcd_audiopd; stop vendor.adsprpcd; sleep 1; start vendor.adsprpcd; sleep 2; start vendor.audioadsprpcd_audiopd; sleep 3; echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/unbind; sleep 1; echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/bind; sleep 4; start vendor.audio-hal-aidl; sleep 2; echo ---SERVICES---; for s in vendor.adsprpcd vendor.audioadsprpcd_audiopd vendor.audio-hal-aidl; do echo $s=$(getprop init.svc.$s); done; echo ---NODES---; ls -l /dev/aud_pasthru_adsp 2>/dev/null || echo no_aud_passthru; ls -l /dev/snd; echo ---CARDS---; cat /proc/asound/cards'

adb shell 'dmesg | grep -i -E "__spf_core_is_apm_ready|command timedout|audioadsprpcd|adsprpcd|apm|spf_core_platform|Transport endpoint is not connected|q6 state is down|gpr_adsp_up" | tail -300'

adb shell 'logcat -d -b all | grep -i -E "audioadsprpcd|adsprpcd|audiohalservice|Transport endpoint is not connected|APM|spf|fastrpc|listener" | tail -300'
```

```bash
adb shell 'for s in vendor.pd_mapper vendor.per_mgr vendor.adsprpcd vendor.audioadsprpcd_audiopd vendor.audio-hal-aidl; do printf "%s=" "$s"; getprop init.svc.$s; done; echo ---; ls -l /dev/aud_pasthru_adsp 2>/dev/null || echo no_aud_passthru; ls -l /dev/snd; echo ---; cat /proc/asound/cards'

adb shell 'dmesg | grep -i "__spf_core_is_apm_ready\|command timedout\|spf_core_platform_driver_probe\|spf_core_probe" | tail -40'
```

**阶段结论**：

1. 注入的 recovery 镜像生效，`vendor.pd_mapper`、`vendor.per_mgr`、`vendor.adsprpcd`、`vendor.audioadsprpcd_audiopd` 都能稳定跑起来
2. 真实 `vendor` 和 `odm` 运行时嫁接成功
3. 内核音频模块链手动补到：`oplus_audio_daemon`、`audpkt_ion_dlkm`、`audio_prm_dlkm`、`audio_pkt_dlkm`、`frpc-adsprpc`、整套 codec/CDC/machine 模块
4. `/dev/aud_pasthru_adsp` 已出现
5. 但 `/proc/asound/cards` 仍然空，`/dev/snd` 仍只有 `timer`，`spf_core_platform` 卡在 `__spf_core_is_apm_ready` 超时

## 七、定位 HAL 循环重启根因：VINTF manifest 缺失

先同时抓 HAL 的停机原因、vendor binder 进程和 service manager 状态，这一批能直接判断 `pm-service` 卡 `/dev/vndbinder` 是旁支还是 APM 卡死前的真正前置条件

```bash
adb shell 'echo ---SVC---; for s in vendor.pd_mapper vendor.per_mgr vendor.adsprpcd vendor.audioadsprpcd_audiopd vendor.audio-hal-aidl vendor.vndservicemanager; do printf "%s=" "$s"; getprop init.svc.$s; done; echo ---PS---; ps -A | grep -E "servicemanager|vndservicemanager|audiohalservice|pm-service|pd-mapper|adsprpcd" || true'
```

```bash
adb shell 'logcat -d -b all | grep -i -E "audiohalservice|vendor.audio-hal-aidl|audioserver|vndbinder|vndservicemanager|servicemanager|IAGM|agm|sound card is not exist|wait_for_snd_card_to_online|gpr_lx_wrapper|Transport endpoint is not connected" | tail -300'
```

检查 binder 设备节点：

```bash
adb shell 'for f in /dev/binderfs/binder /dev/binderfs/vndbinder /dev/binderfs/hwbinder /dev/vndbinder /dev/hwbinder /dev/binder; do echo === $f ===; ls -l $f 2>/dev/null || echo missing; done; echo ---CTX---; service list 2>/dev/null | head -80 || true; echo ---VND---; cmd -l 2>/dev/null | head -80 || true'
```

现在很明确的一点是：`vndbinder` 设备节点本身在，缺的是 `vendor.vndservicemanager` 这条服务，当前根本没起来。下一步我直接从日志里确认 HAL 是不是因为拿不到 vendor service manager 或 AGM 服务而退出。

```bash
adb shell 'getprop | grep -i vndservicemanager || true; ls -l /vendor/bin/vndservicemanager /system/bin/vndservicemanager 2>/dev/null || echo no_vndservicemanager_bin; grep -R "service vendor.vndservicemanager\|service vndservicemanager" /vendor/etc/init /system/etc/init 2>/dev/null | head -40'
```

```bash
adb shell 'start vendor.vndservicemanager; sleep 1; getprop init.svc.vendor.vndservicemanager; ps -A | grep vndservicemanager || true; dmesg | tail -80 | grep -i vndservicemanager || true'
```

`vndservicemanager` 的二进制是有的，只是 recovery init 没导入它的 service。

手工把它拉起来，再看 `pm-service` 和 `audio-hal-aidl` 会不会因此从现在这层继续往前走。

```bash
adb shell 'pkill -f vndservicemanager 2>/dev/null || true; logcat -c >/dev/null 2>&1 || true; dmesg -c >/dev/null 2>&1 || true; LD_LIBRARY_PATH=/vendor/lib64 /vendor/bin/vndservicemanager >/tmp/vndservicemanager.out 2>&1 & sleep 2; ps -A | grep vndservicemanager || true; cat /tmp/vndservicemanager.out 2>/dev/null || true'

adb shell 'sleep 1; ps -A | grep -E "vndservicemanager|pm-service|audiohalservice" || true; echo ---; logcat -d -b all | grep -i -E "vndservicemanager|pm-service|audiohalservice|vndbinder|context object|IAGM|agm|AServiceManager|ServiceManagerCppClient" | tail -300'

adb shell 'start vendor.audio-hal-aidl; sleep 2; echo HAL=$(getprop init.svc.vendor.audio-hal-aidl); ps -A | grep audiohalservice || true; logcat -d -b all | grep -i -E "audiohalservice|vendor.audio-hal-aidl|sound card is not exist|wait_for_snd_card_to_online|gpr_lx_wrapper|IAGM|agm|vndservicemanager|vndbinder" | tail -300'
```

```bash
adb shell 'ps -A | grep -E "vndservicemanager|pm-service|audiohalservice" || true; getprop init.svc.vendor.audio-hal-aidl'
```

说明 `vendor.vndservicemanager` 缺失不是最前面的硬门槛，因为 `audiohalservice.qti` 现在在没有它的情况下也能稳定跑起来。

检查 audio HAL 文件描述符和日志：

```bash
adb shell 'pid=$(pidof audiohalservice.qti); echo PID=$pid; ls -l /proc/$pid/fd 2>/dev/null | grep -E "aud_pasthru|fastrpc|binder|snd|gpr|rpc|audio" || true'
```

```bash
adb shell 'logcat -d -b all | grep -i -E "audiohalservice|wait_for_snd_card_to_online|sound card is not exist|gpr_lx_wrapper|aud_pasthru|gpr_channel|IAGM|agm|AServiceManager|android.hardware.audio|hal audio" | tail -300'
```

```bash
adb shell 'pid=$(pidof audioadsprpcd); echo PID=$pid; ls -l /proc/$pid/fd 2>/dev/null | grep -E "fastrpc|aud_pasthru|binder|rpc|adsprpc" || true; echo ---; logcat -d -b all | grep -i -E "audioadsprpcd|Transport endpoint is not connected|adsp_default_listener|apps_dev_init|audiopd|listener" | tail -200'
```

`audiohalservice.qti` 现在其实非常“浅”地活着：它只拿了普通 binder，没有拿到 `aud_pasthru`、`snd`、`gpr` 或 FastRPC 相关 fd。`audioadsprpcd` 也还是只抓着 `/dev/fastrpc-adsp-secure`。我再把 HAL 的直接日志读出来，看它是在纯等声卡，还是已经有更具体的 AGM/GPR 失败。

```bash
adb shell 'pid=$(pidof audiohalservice.qti); echo PID=$pid; for f in /proc/$pid/maps /proc/$pid/status; do echo === $f ===; sed -n "1,120p" $f; done'

adb shell 'dmesg | grep -i -E "audiohalservice|hal_audio|gpr_lx_wrapper|wait_for_snd_card_to_online|sound card is not exist|aud_pasthru|agm|IAGM" | tail -200'
```

再补两个关键验证：一是确认 `audio-hal-aidl` 是否在反复退出重启，二是看把真实系统的 VINTF manifest 暂时嫁接进来，能不能让它不再因为服务注册失败而循环。这样可以把 “HAL 自身问题” 和 “APM timeout” 彻底拆开。

```bash
adb shell 'for i in 1 2 3 4 5; do date +%H:%M:%S; pidof audiohalservice.qti || echo none; sleep 2; done; echo ---; dmesg | grep -i -E "vendor.audio-hal-aidl|audio-hal-aidl|audiohalservice.qti|Service .*vendor.audio-hal-aidl|exited|restarting|received signal" | tail -120'
```

### 7.1 核验 VINTF manifest

检查 recovery 与真实系统的 VINTF 文件差异：

```bash
adb shell 'mkdir -p /mnt/real_system_root; mount -t erofs -o ro /dev/block/dm-0 /mnt/real_system_root >/dev/null 2>&1 || true; echo ---RECOVERY---; find /system/etc/vintf /vendor/etc/vintf -maxdepth 2 -type f 2>/dev/null | sort | head -80; echo ---REAL---; find /mnt/real_system_root/system/etc/vintf /mnt/real_vendor/etc/vintf -maxdepth 2 -type f 2>/dev/null | sort | head -120'
```

搜索音频 HAL 实例声明：

```bash
adb shell 'grep -R "android.hardware.audio.core.IConfig/default\|android.hardware.audio.effect.IFactory/default" /system/etc/vintf /vendor/etc/vintf /mnt/real_system_root/system/etc/vintf /mnt/real_vendor/etc/vintf 2>/dev/null | head -80'
```

**结论**：HAL 每次 `SIGABRT` 的直接原因找到。recovery 的 VINTF manifest 缺音频 HAL 实例声明，导致注册 `android.hardware.audio.core.IConfig/default` 和 effect factory 都失败后自杀重启。

查看真实 vendor 中的音频 VINTF 文件内容：

```bash
adb shell 'sed -n "1,220p" /mnt/real_vendor/etc/vintf/manifest/manifest_audiocorehal_default.xml; echo ---; sed -n "1,220p" /mnt/real_vendor/etc/vintf/manifest/audioeffectservice_qti.xml'
```

检查 recovery 中是否缺这些文件：

```bash
adb shell 'find /vendor/etc/vintf/manifest -maxdepth 1 -type f | sort | sed -n "1,120p"; echo ---; ls -l /vendor/etc/vintf/manifest/manifest_audiocorehal_default.xml /vendor/etc/vintf/manifest/audioeffectservice_qti.xml 2>/dev/null || echo missing_audio_vintf'
```

尝试运行时 bind VINTF manifest：

```bash
adb shell 'mount -o bind /mnt/real_vendor/etc/vintf/manifest /vendor/etc/vintf/manifest && echo bind_vintf_ok || echo bind_vintf_fail; stop vendor.audio-hal-aidl; sleep 1; start vendor.audio-hal-aidl; sleep 3; pidof audiohalservice.qti || echo no_hal; getprop init.svc.vendor.audio-hal-aidl; logcat -d -b all | grep -i -E "AHAL_DefaultService_QTI|android.hardware.audio.core.IConfig/default|android.hardware.audio.effect.IFactory/default|VINTF manifest|failed to register service" | tail -120'
```

**结论**：真实 vendor 的音频 VINTF 清单已经确认了，recovery 当前确实完全缺这两份文件。现在就看把真实 `manifest` 目录 bind 进来之后，HAL 的 `IConfig/default` 和 effect service 注册失败会不会消失。

两条并行阻塞确认：

- `audiohalservice.qti` 因缺音频 VINTF 声明而循环重启
- `spf_core_platform` 因 APM 不 ready 而无法实例化 `sound` 子设备

## 八、源侧修复 VINTF manifest 并制作新镜像

先把设备里的音频 VINTF manifest 和相关 init 定义提出来，对照 recovery 源树当前缺口，然后把最小必要文件补进镜像源。

```bash
ls device_tree/twrp_device_oplus_ossi_source_built/recovery/root/vendor/etc/ 
find device_tree/twrp_device_oplus_ossi_source_built/recovery/root/vendor/etc/vintf/ -type f | sort
# 6 matches — 已有 manifest.xml 等文件，但没有音频相关的 VINTF 文件                   
```

```bash
adb shell 'ls -l /mnt/real_vendor/etc/vintf/manifest/manifest_audiocorehal_default.xml /mnt/real_vendor/etc/vintf/manifest/audioeffectservice_qti.xml /mnt/real_vendor/etc/init/audiohalservice_qti.rc /mnt/real_vendor/etc/init/vendor.qti.audio-adsprpc-service.rc 2>/dev/null'
```

```bash
adb shell 'sed -n "1,220p" /mnt/real_vendor/etc/init/audiohalservice_qti.rc; echo ---; sed -n "1,220p" /mnt/real_vendor/etc/init/vendor.qti.audio-adsprpc-service.rc'
```

设备上的音频 VINTF 和 stock init 形态已经确认可提。下一步我先核对 recovery 源树当前 manifest.xml 和 init 目录的装配方式，再把缺的最小文件补进去，避免引入无关 vendor 配置。

```bash

rg -rn "vndservicemanager|vendor\.audio-hal-aidl|vendor\.audioadsprpcd_audiopd|manifest_audiocorehal_default|audioeffectservice_qti" device_tree/twrp_device_oplus_ossi_source_built/
# 2 results — 在 vendor.audio-recovery-services.rc 中有 audio-hal-aidl 和 audioadsprpcd 定义

cat device_tree/twrp_device_oplus_ossi_source_built/recovery/root/vendor/etc/vintf/manifest.xml
# 查看现有 manifest.xml，确认没有音频 HAL 实例声明入口
```

源树里当前确实只缺音频 VINTF 文件，没有别的音频 manifest 入口。vendor.audio-recovery-services.rc 已经在了，所以这一轮我优先补两份 VINTF manifest；如果还要把 `vndservicemanager` 一并固化，再补一条独立 service 就行。

```bash
rg -rn "service vendor\.vndservicemanager|/vendor/bin/vndservicemanager|vndservicemanager" device_tree/
# no results — device_tree 中没有任何 vndservicemanager 定义
```

在设备端确认 stock vndservicemanager 和 VINTF 内容：

```bash
adb shell 'grep -R "service vendor.vndservicemanager\|service vndservicemanager" /mnt/real_vendor/etc/init /mnt/real_system_root/system/etc/init 2>/dev/null | head -40'
adb shell 'sed -n "1,160p" /mnt/real_vendor/etc/vintf/manifest/manifest_audiocorehal_default.xml; echo ---; sed -n "1,120p" /mnt/real_vendor/etc/vintf/manifest/audioeffectservice_qti.xml'
```

不只把文件落到源码里。下一步把两份音频 VINTF 清单补进 recovery 源，同时给 `vndservicemanager` 补一条最小 recovery service，然后再出一版新的注入测试镜像，避免只停在“下次编译再说”。

```bash
rg -rn "service_manager|servicemanager|vndservicemanager" device_tree/twrp_device_oplus_ossi_source_built/recovery/root/
# 2 results — recovery 已有 servicemanager 定义，但 vndservicemanager 缺失

rg -rn "service vndservicemanager|service vendor\.vndservicemanager" --include='*.rc' --include='*.xml' --include='*.txt' --include='*.md'
# 3 results — 在 twrp_a16_compile 的 AOSP 源码中找到标准 vndservicemanager.rc

adb shell 'strings /vendor/bin/vndservicemanager | head -40'
# 确认 vndservicemanager 二进制行为：/vendor/bin/vndservicemanager

cat twrp_a16_compile/frameworks/native/cmds/servicemanager/vndservicemanager.rc
# 读取 AOSP 标准 vndservicemanager.rc 作为参考

cat device_tree/twrp_device_oplus_ossi_source_built/recovery/root/vendor/etc/init/vendor.audio-recovery-services.rc
# 读取当前 recovery 音频服务 rc
```

根据 AOSP recovery/servicemanager 定义，补入最小版的 vndservicemanager service。

在源树补入三处变更：

1. 两份音频 VINTF 声明（`manifest_audiocorehal_default.xml`、`audioeffectservice_qti.xml`）
2. 在 `vendor.audio-recovery-services.rc` 中加入 `vndservicemanager` service

用 magiskboot 二次注入制作新测试镜像：

```bash
cd /Volumes/Case-sensitive\ APFS/TWRP/magisk_inject_ossi_20260312 && ../magiskboot cpio ramdisk.cpio "add 0644 vendor/etc/init/vendor.audio-recovery-services.rc ../device_tree/twrp_device_oplus_ossi_source_built/recovery/root/vendor/etc/init/vendor.audio-recovery-services.rc" "add 0644 vendor/etc/vintf/manifest/manifest_audiocorehal_default.xml ../device_tree/twrp_device_oplus_ossi_source_built/recovery/root/vendor/etc/vintf/manifest/manifest_audiocorehal_default.xml" "add 0644 vendor/etc/vintf/manifest/audioeffectservice_qti.xml ../device_tree/twrp_device_oplus_ossi_source_built/recovery/root/vendor/etc/vintf/manifest/audioeffectservice_qti.xml" && ../magiskboot cpio ramdisk.cpio "exists vendor/etc/vintf/manifest/manifest_audiocorehal_default.xml" && ../magiskboot cpio ramdisk.cpio "exists vendor/etc/vintf/manifest/audioeffectservice_qti.xml"
```

```bash
cd /Volumes/Case-sensitive\ APFS/TWRP/magisk_inject_ossi_20260312 && ../magiskboot repack orig.img TWRP-3.7.1-16-ossi-2026-03-10-audio-vintf-test.img && ls -lh TWRP-3.7.1-16-ossi-2026-03-10-audio-vintf-test.img && shasum TWRP-3.7.1-16-ossi-2026-03-10-audio-vintf-test.img
```

二次解包校验：

```bash
cd /Volumes/Case-sensitive\ APFS/TWRP/magisk_inject_ossi_20260312 && mkdir -p verify_vintf && cp -f TWRP-3.7.1-16-ossi-2026-03-10-audio-vintf-test.img verify_vintf/test.img && cd verify_vintf && ../../magiskboot unpack -h test.img && ../../magiskboot cpio ramdisk.cpio "exists vendor/etc/vintf/manifest/manifest_audiocorehal_default.xml" && ../../magiskboot cpio ramdisk.cpio "exists vendor/etc/vintf/manifest/audioeffectservice_qti.xml"
```

新测试镜像已经打出来并通过二次解包校验，音频 VINTF 文件确实在里头。我把产物放回设备树目录，方便你直接 `fastboot boot`/刷入下一轮验证。

```bash
cp -f TWRP-3.7.1-16-ossi-2026-03-10-audio-vintf-test.img ../device_tree/twrp_device_oplus_ossi_source_built/
```

产物 SHA1: `9fe28136759110eed3284363a49807289be44529`。

## 九、fastboot 刷入新镜像并验证

设备切到 bootloader：

```bash
adb reboot bootloader
fastboot devices
```

确认分区信息：

```bash
fastboot getvar has-slot:recovery
fastboot getvar partition-type:recovery
```

设备存在独立 `recovery` 分区，类型 `raw`，可直接 `fastboot flash recovery`。

刷入新镜像：

```bash
fastboot flash recovery TWRP-3.7.1-16-ossi-2026-03-10-audio-vintf-test.img
fastboot reboot recovery
```

等待设备上线：

```bash
adb wait-for-device && adb shell getprop ro.bootmode
```

验证新镜像中文件和服务：

```bash
adb shell ls /vendor/etc/vintf/manifest
adb shell getprop init.svc.vendor.audio-hal-aidl
```

手动 bring-up 挂载真实 vendor/odm 并用 erofs 挂载：

```bash
adb shell 'mkdir -p /mnt/real_vendor /mnt/real_odm; mount -t erofs -o ro /dev/block/dm-2 /mnt/real_vendor; mount -t erofs -o ro /dev/block/dm-5 /mnt/real_odm; echo RET=$?; ls /mnt/real_vendor/bin | head -5; ls /mnt/real_odm/lib/rfsa/adsp | head -5'
```

真实 `vendor/odm` 已经按 `erofs` 成功挂上了，说明新镜像本身没问题，之前只是文件系统类型误判。现在重新绑定运行时路径并拉起服务，直接看 audio HAL 是否还会报 “not in VINTF manifest”。

```bash
adb shell 'mount -o bind /mnt/real_vendor/bin /vendor/bin; mount -o bind /mnt/real_vendor/bin/hw /vendor/bin/hw; mount -o bind /mnt/real_vendor/lib64 /vendor/lib64; mount -o bind /mnt/real_odm /odm; start vendor.vndservicemanager; start vendor.pd_mapper; start vendor.per_mgr; start vendor.adsprpcd; start vendor.audioadsprpcd_audiopd; start vendor.audio-hal-aidl; sleep 4; echo VND=$(getprop init.svc.vendor.vndservicemanager); echo PD=$(getprop init.svc.vendor.pd_mapper); echo PM=$(getprop init.svc.vendor.per_mgr); echo RPC=$(getprop init.svc.vendor.adsprpcd); echo ARPC=$(getprop init.svc.vendor.audioadsprpcd_audiopd); echo HAL=$(getprop init.svc.vendor.audio-hal-aidl); pidof audiohalservice.qti || echo PID=no_hal; logcat -d | grep -i "audio.effect.IFactory/default\|audio.core.IModule/default\|not find .*VINTF manifest" | tail -20'
```

关键差异已经出现了：`vendor.audio-hal-aidl` 现在能起来并保留 PID，之前那种起不来/秒退的状态已经没有了。为了把结论收紧，我再做一次延时复查，确认它不是短暂存活，同时看 ALSA 和 APM 这一层有没有变化。

延时复查稳定性：

```bash
adb shell 'sleep 12; echo HAL=$(getprop init.svc.vendor.audio-hal-aidl); pidof audiohalservice.qti || echo PID=no_hal'
```

检查 ALSA 和 APM 状态：

```bash
adb shell 'ls /dev/snd 2>/dev/null; echo ---; cat /proc/asound/cards 2>/dev/null'
adb shell 'dmesg | grep -i "__spf_core_is_apm_ready\|command timedout\|spf_core_platform" | tail -20'
```

VINTF 侧现在已经明显比上一版好很多，但我再补一个直接证据：查一次日志里有没有之前那句 “Could not find ... in the VINTF manifest”。这能把“文件在镜像里”升级成“服务注册时真的不再缺声明”。

```bash
adb shell 'logcat -d | grep -i "Could not find android.hardware.audio" | tail -20'
```

主 VINTF 缺项已经不是之前那组 `default/r_submix/usb/effect` 了，日志里现在只剩 `IModule/bluetooth` 这一项。这个实例本来就不在我们提取的 stock manifest 里，而且 HAL 仍然持续 `running`，所以它更像是可选模块提示，不是之前那种致命注册失败。

```
adb shell 'logcat -d | grep -i "audio.effect.IFactory/default" | tail -20'
adb shell 'logcat -d | grep -i "android.hardware.audio.core" | tail -40'
```

**刷入验证结论**：

1. 刷入成功，`recovery` 分区可直接写，不需要指定 `_a/_b`
2. 新镜像中两个音频 VINTF 文件已落地
3. `vendor.audio-hal-aidl` 能稳定拉起，12 秒后仍是 `running`
4. `android.hardware.audio.effect.IFactory/default` 注册成功
5. `android.hardware.audio.core.IConfig/default` 也能在 VINTF 里找到
6. 当前 `/dev/snd` 仍只有 `timer`，`/proc/asound/cards` 仍空

前沿问题重新收敛回内核侧声卡实例化。

## 十、在新 recovery 中重放模块链并确认前沿

检查当前服务状态和声卡：

```bash
adb shell 'getprop init.svc.vendor.audio-hal-aidl; getprop init.svc.vendor.audioadsprpcd_audiopd; getprop init.svc.vendor.adsprpcd; ls /dev/aud_pasthru_adsp /dev/snd 2>/dev/null; cat /proc/asound/cards 2>/dev/null'
```

列出 vendor_dlkm 中音频模块：

```bash
adb shell 'ls /vendor_dlkm/lib/modules | grep -E "audio|wcd|swr|q6|frpc|machine|lpass|wsa|mbhc|audpkt|sdca|oplus_audio" | sort | sed -n "1,200p"'
```

当前状态比上一轮干净：HAL、adsprpc 两条用户态链都已经在跑，但 ALSA 还是完全没起来，所以离“直接播放”差的已经不在用户态，而在内核声卡实例化。下一步我直接重放模块链，并同步盯 `/dev/aud_pasthru_adsp`、`/proc/asound/cards` 和 `spf_core_platform`。

```bash
adb shell 'dmesg | grep -i "spf_core_platform\|__spf_core_is_apm_ready\|soundcard\|asoc\|snd_soc" | tail -80'

adb shell 'lsmod 2>/dev/null | grep -E "audio|wcd|swr|q6|frpc|machine|lpass|wsa|mbhc|audpkt|sdca|oplus_audio" | sed -n "1,200p"'
```

现在差距已经能量化了：用户态主链基本通了，离“直接播放”主要还差两层。第一层是把 `aud_pasthru` 和 machine/provider 模块完整带起来，第二层是让 `spf_core_platform` 真正枚举出声卡；只要第二层不通，`/dev/snd` 就不会从 `timer` 变成可播放节点。

```bash
adb shell 'for m in oplus_audio_daemon.ko audpkt_ion_dlkm.ko audio_prm_dlkm.ko audio_pkt_dlkm.ko frpc-adsprpc.ko wcd_core_dlkm.ko swr_dlkm.ko wcd939x_slave_dlkm.ko wcd9xxx_dlkm.ko mbhc_dlkm.ko wcd939x_dlkm.ko lpass_cdc_dlkm.ko swr_ctrl_dlkm.ko oplus_audio_pa_manager.ko oplus_audio_sipa.ko oplus_audio_extend.ko sdca_registers_dlkm.ko wcd9378_dlkm.ko lpass_cdc_rx_macro_dlkm.ko wsa883x_dlkm.ko wsa884x_dlkm.ko lpass_cdc_tx_macro_dlkm.ko lpass_cdc_va_macro_dlkm.ko lpass_cdc_wsa_macro_dlkm.ko lpass_cdc_wsa2_macro_dlkm.ko lpass_bt_swr_dlkm.ko q6_dlkm.ko machine_dlkm.ko; do insmod /vendor_dlkm/lib/modules/$m 2>/dev/null && echo OK:$m || echo SKIP:$m; done; echo ---; ls /dev/aud_pasthru_adsp /dev/snd 2>/dev/null; echo ---; cat /proc/asound/cards 2>/dev/null'
```

模块链已经完整回来了，而且 `/dev/aud_pasthru_adsp` 也重新出现，这说明从 userspace 到 FastRPC 到 machine 依赖都不是主缺口。离“直接播放”现在只差最后一层：ALSA 声卡仍未被实例化，问题继续锁在 `spf_core_platform/APM`。

```bash
adb shell 'dmesg | grep -i "spf_core_platform\|__spf_core_is_apm_ready\|apm is not up\|enumarate machine driver\|gpr_send_pkt\|q6 state is down" | tail -80'
adb shell 'ls -R /sys/devices/platform/soc/soc:spf_core_platform 2>/dev/null | sed -n "1,120p"'
```

检查 SSR 节点：

```bash
adb shell 'for p in /sys/kernel/boot_adsp/ssr /sys/kernel/boot_adsp/ssr_defer; do [ -e $p ] && echo HAVE:$p || true; done'
```

`spf_core_platform` 下面依旧没有 `sound` 子设备，说明 machine 节点根本没被平台侧枚举出来，这和 “有 `/dev/aud_pasthru_adsp` 但没有声卡” 完全一致。下一步我做一次最接近根因的触发：ADSP SSR 加 `spf_core_platform` 重新绑定，看它能不能从 APM timeout 前进成真正的 sound 设备。

## 十一、SSR 触发 + spf_core_platform 重绑：sound 子设备出现

```bash
adb shell 'echo 1 > /sys/kernel/boot_adsp/ssr; sleep 4; echo soc:spf_core_platform > /sys/bus/platform/drivers/spf_core_platform/unbind; sleep 1; echo soc:spf_core_platform > /sys/bus/platform/drivers/spf_core_platform/bind; sleep 4; echo ---SPF---; dmesg | grep -i "spf_core_platform\|__spf_core_is_apm_ready\|apm is not up\|enumarate machine driver\|gpr_send_pkt\|q6 state is down" | tail -40; echo ---TREE---; ls -R /sys/devices/platform/soc/soc:spf_core_platform 2>/dev/null | sed -n "1,80p"; echo ---ALSA---; ls /dev/snd 2>/dev/null; echo ---CARDS---; cat /proc/asound/cards 2>/dev/null'
```

有新的实质性进展：这次 SSR 之后，`spf_core_platform` 下面已经真的长出了 `sound` 子设备。也就是说最硬的那层已经从“平台没枚举 child”前进到了“child 出来了但 ASoC 还没把它变成声卡”。离能播放又近了一层。

```bash
adb shell 'ls -R /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound 2>/dev/null | sed -n "1,160p"'
```

检查 sun-asoc-snd 驱动：

```bash
adb shell 'ls /sys/bus/platform/drivers 2>/dev/null | grep -E "sun|asoc|snd|spf" | sed -n "1,120p"'
```

```bash
adb shell 'dmesg | grep -i "sun-asoc-snd\|soc:spf_core_platform:sound\|snd_soc_register_card\|ASoC\|audio-card\|sound card" | tail -80'
```

**新阻塞点**：现在不是“声卡没节点”，而是 `soc:spf_core_platform:sound` 这个子设备还卡在 `waiting_for_supplier`，所以 ALSA card 没法注册。这比之前更具体了：要么是 supplier 链没 ready，要么是 `sun-asoc-snd` 没真正接手这个 sound 设备。

### 11.1 检查 supplier 状态

```bash
adb shell 'readlink /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/supplier:platform:soc:vote_lpass_audio_hw 2>/dev/null; readlink /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/supplier:platform:soc:spf_core_platform 2>/dev/null'
```

```bash
adb shell 'cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/modalias 2>/dev/null; echo ---; cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/uevent 2>/dev/null'


adb shell 'for p in /sys/devices/platform/soc/vote_lpass_audio_hw /sys/devices/platform/soc/vote_lpass_core_hw; do echo ===$p===; ls $p 2>/dev/null | sed -n "1,80p"; done'
```

`sound` 的 `modalias` 已经明确是 `qcom,sun-asoc-snd`，所以驱动目标没歧义。卡住点进一步缩小成一件事：它还在等 `vote_lpass_audio_hw` 这个 supplier 完全 ready，导致 `sun-asoc-snd` 没法接管。

```bash
adb shell 'find /sys/devices -name "*vote_lpass_audio_hw*" -o -name "*vote_lpass_core_hw*" 2>/dev/null | sed -n "1,120p"'

adb shell 'ls -R /sys/bus/platform/drivers/spf-core-platform 2>/dev/null | sed -n "1,160p"'

adb shell 'ls -R /sys/bus/platform/drivers/sun-asoc-snd 2>/dev/null | sed -n "1,160p"'
```

现在链路更清楚了：`spf-core-platform` 驱动已经接住了父节点，但 `sun-asoc-snd` 这边还没有绑定任何设备；与此同时 `vote_lpass_audio_hw` 和 `vote_lpass_core_hw` 这两个 supplier 实体其实已经存在。也就是说，离出声大概还差 “让 sound 节点脱离 waiting_for_supplier 并被 sun-asoc-snd 绑定” 这一跳。

```bash
adb shell 'for p in /sys/devices/platform/soc/soc:vote_lpass_audio_hw /sys/devices/platform/soc/soc:vote_lpass_core_hw; do echo ===$p===; ls -l $p 2>/dev/null | sed -n "1,120p"; echo ---; cat $p/uevent 2>/dev/null; echo ===; done'

adb shell 'cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/waiting_for_supplier 2>/dev/null || echo waiting_flag_present'

adb shell 'modprobe -d /vendor_dlkm/lib/modules snd-soc-dummy 2>/dev/null; echo RET=$?; ls /sys/bus/platform/drivers/sun-asoc-snd 2>/dev/null'
```

supplier 这一层已经不是阻塞了，`waiting_for_supplier` 现在是 `0`。所以最后一跳更明确了：`soc:spf_core_platform:sound` 已经 ready，但 `sun-asoc-snd` 还没有实际 probe 成功。

```bash
adb shell 'ls -l /sys/bus/platform/devices | grep "soc:spf_core_platform:sound"'

adb shell 'ls -l /sys/bus/platform/drivers_probe /sys/bus/platform/drivers_autoprobe 2>/dev/null'

adb shell 'cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null | sed -n "1,20p"'
```

设备已经在 platform 总线上，且总线支持 `drivers_probe`。我现在直接手工触发 `sun-asoc-snd` 的 probe，这一步能把“最后差多少”从推测变成直接证据。

### 11.2 手工触发 driver probe

```bash
adb shell 'echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe; sleep 2; echo ---DRV---; readlink /sys/bus/platform/devices/soc:spf_core_platform:sound/driver 2>/dev/null || echo no_driver; echo ---ALSA---; ls /dev/snd 2>/dev/null; echo ---CARDS---; cat /proc/asound/cards 2>/dev/null; echo ---DMESG---; dmesg | grep -i "sun-asoc-snd\|soc:spf_core_platform:sound\|snd_soc_register_card\|ASoC\|audio-card\|sound card" | tail -60'
```

手工 probe 没把设备绑上，也没有直接吐出新日志，这通常不是“名字不对”，而是 probe 被延迟或前置条件仍未满足。我接着查 deferred probe 列表，这能直接告诉我们离可播放还差哪一个前置设备。

```bash
adb shell 'cat /sys/kernel/debug/devices_deferred 2>/dev/null | sed -n "1,200p"'

adb shell 'readlink /sys/bus/platform/drivers/sun-asoc-snd/module 2>/dev/null; cat /sys/module/sun_asoc_snd/refcnt 2>/dev/null; ls /sys/module/sun_asoc_snd/parameters 2>/dev/null'


adb shell 'find /sys/bus/platform/devices/soc:spf_core_platform:sound -maxdepth 2 -type f | sed -n "1,120p"'
```

驱动模块本身已经在，`sun-asoc-snd` 对应的就是 `machine_dlkm`，不是没加载。现在更像是 machine probe 进去后又因为 codec/DAI/依赖不齐而静默失败，所以我再核一下这一代机器实际绑定到哪些 codec 与宏模块，避免只按上一轮的最小链做判断。

```bash
adb shell 'lsmod 2>/dev/null | grep -E "machine_dlkm|wcd93|wcd9|lpass_cdc|wsa88|mbhc|swr_ctrl|swr_dlkm|audio_pkt_dlkm|audio_prm_dlkm|audpkt_ion_dlkm|frpc-adsprpc|q6_dlkm|oplus_audio" | sed -n "1,200p"'

adb shell 'ls -R /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:lpass-cdc 2>/dev/null | sed -n "1,200p"'

adb shell 'ls -R /sys/class/sound 2>/dev/null | sed -n "1,120p"'
```

现在还差的不是所有 codec，而是 machine 下面的几个 macro 子节点没有真正绑上驱动。`wcd939x-codec` 已经有 driver 了，但 `rx-macro`、`tx-macro`、`va-macro` 还是裸设备，这会直接阻止 `sun-asoc-snd` 拼出完整声卡。

```bash
adb shell 'for n in rx-macro tx-macro va-macro; do echo ===$n===; cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:lpass-cdc/$n/modalias 2>/dev/null; cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:lpass-cdc/$n/uevent 2>/dev/null; done'

adb shell 'ls /sys/bus/platform/drivers 2>/dev/null | grep -E "rx-macro|tx-macro|va-macro|wsa-macro|lpass-cdc" | sed -n "1,120p"'

adb shell 'dmesg | grep -i "rx-macro\|tx-macro\|va-macro\|wsa-macro\|lpass-cdc" | tail -80'
```

再做一个低风险验证：补加载同目录里还没试过的 `wcd938x`/`wcd938x_slave`，看 machine 侧是不是还差同族 codec 组件。这个能快速区分“只差 probe 顺序”还是“确实还有 codec 件没到位”。

```bash
adb shell 'for m in wcd938x_slave_dlkm.ko wcd938x_dlkm.ko; do insmod /vendor_dlkm/lib/modules/$m 2>/dev/null && echo OK:$m || echo SKIP:$m; done; echo ---; lsmod | grep -E "wcd938x|wcd939x|wcd9378|machine_dlkm"; echo ---; ls -R /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:lpass-cdc 2>/dev/null | sed -n "1,200p"; echo ---; cat /proc/asound/cards 2>/dev/null'
```

`devices_deferred` 明确列出：`sound`、`rx-macro`、`tx-macro`、`va-macro`，以及上游的 `rx/tx/bt_swr_clk_data_pinctrl`。`sound` 的 `waiting_for_supplier` 已是 `0`。

### 11.3 检查 macro 节点和 pinctrl 上游

主 VINTF 缺项已不再是前沿，以及 `sound` 子设备已出现但仍未注册成 ALSA card。现在我继续现场追最后这层，优先看 `rx/tx/va macro` 为什么没有绑定驱动。我先回源码侧找 `qcom,lpass-cdc-rx-macro/tx-macro/va-macro` 的驱动注册关系，确认这些节点理论上应该由谁接管，以及是否还依赖额外模块或配置。找到对应代码后，就能判断当前是缺 probe 条件还是缺注册。

检查 macro 节点：

```bash
rg -n "qcom,lpass-cdc-(rx|tx|va)-macro|sun-asoc-snd|qcom,sun-asoc-snd" twrp_a16_compile kernel device_tree -g '!**/.git/**'


adb shell 'for n in rx-macro tx-macro va-macro; do echo ===$n===; readlink /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:lpass-cdc/$n/subsystem 2>/dev/null; done'
```

设备侧确认了：这几个 macro 子节点确实都在 platform 总线上，所以当前思路没偏。源码搜索那边我刚才路径写错了，改成实际目录后继续把驱动注册关系找出来。

```bash
rg -n "qcom,lpass-cdc-(rx|tx|va)-macro|sun-asoc-snd|qcom,sun-asoc-snd" twrp_a16_compile device_tree -g '!**/.git/**'
```

兼容串没有直接搜到，说明这套源码可能只保留了模块名或驱动名，不带完整 DT 串文本。我换成模块名和 `of_match` 常见命名继续找，这样更容易把 machine/macro 代码位置钉住。

```bash
rg -n "lpass_cdc_rx_macro|lpass_cdc_tx_macro|lpass_cdc_va_macro|wsa883x|wsa884x|machine_dlkm|sun-asoc-snd" twrp_a16_compile -g '!**/.git/**'


源码搜索没有给出直接文本命中，但设备态已经把问题钉住了：三个 macro 模块都在内核里，三个 macro 设备也都在 platform 总线上，但就是没绑定 driver。直接从运行态总线反查已注册的 platform 驱动名，确认这些模块到底注册出了什么 driver。

```bash
# 输出已注册的 macro 相关 platform driver 名称
adb shell 'ls /sys/bus/platform/drivers | grep -i macro | sed -n "1,200p"'

# 确认各模块 sysfs 目录存在
adb shell 'for m in lpass_cdc_rx_macro_dlkm lpass_cdc_tx_macro_dlkm lpass_cdc_va_macro_dlkm lpass_cdc_wsa_macro_dlkm lpass_cdc_wsa2_macro_dlkm; do echo ===$m===; ls /sys/module/$m 2>/dev/null | sed -n "1,80p"; done'

# 查看模块 holders 关系
adb shell 'for m in lpass_cdc_rx_macro_dlkm lpass_cdc_tx_macro_dlkm lpass_cdc_va_macro_dlkm; do echo ===$m===; readlink /sys/module/$m/holders 2>/dev/null || true; ls /sys/module/$m/holders 2>/dev/null; done'
```

关键信息出来：这些 macro 模块不只是装进内核了，它们确实已经各自注册了 platform driver。问题已经不是"模块装了但没注册驱动"，而是"driver 在，总线设备在，但自动匹配/绑定没发生"。继续直接看 driver 目录和手工 bind 接口。

```bash
# 查看各 macro 驱动目录内容
adb shell 'for d in lpass_cdc_rx_macro lpass_cdc_tx_macro lpass_cdc_va_macro; do echo ===$d===; ls -R /sys/bus/platform/drivers/$d 2>/dev/null | sed -n "1,120p"; done'

# 从模块侧查看注册的驱动
adb shell 'for m in lpass_cdc_rx_macro_dlkm lpass_cdc_tx_macro_dlkm lpass_cdc_va_macro_dlkm; do echo ===$m===; ls -R /sys/module/$m/drivers 2>/dev/null | sed -n "1,80p"; done'

# 查看各节点 driver_override，确认是否为空
adb shell 'for n in rx-macro tx-macro va-macro; do echo ===$n===; cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:lpass-cdc/$n/driver_override 2>/dev/null; done'
```

证据链已经闭合：macro 设备存在、macro driver 存在、`driver_override` 也是空的，但这些 driver 目录和 `sun-asoc-snd` 一样都没有现成的 `bind` 节点，所以只能走 `driver_override + drivers_probe` 这条总线触发路径。直接对 `rx/tx/va` 三个 macro 做一次手工 probe。

```bash
adb shell 'for pair in "rx-macro:lpass_cdc_rx_macro" "tx-macro:lpass_cdc_tx_macro" "va-macro:lpass_cdc_va_macro"; do n=${pair%%:*}; d=${pair##*:}; echo $d > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:lpass-cdc/$n/driver_override; echo soc:spf_core_platform:lpass-cdc:$n > /sys/bus/platform/drivers_probe; done; sleep 2; echo ---DRV---; for n in rx-macro tx-macro va-macro; do echo ===$n===; readlink /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:lpass-cdc/$n/driver 2>/dev/null || echo no_driver; done; echo ---CARDS---; cat /proc/asound/cards 2>/dev/null; echo ---SND---; ls /dev/snd 2>/dev/null; echo ---DMESG---; dmesg | grep -i "rx-macro\|tx-macro\|va-macro\|lpass_cdc_.*macro\|sun-asoc-snd\|snd_soc_register_card\|sound card" | tail -80'
```

手工 probe 也没把这三个 macro 绑上，而且没有新增日志。再确认一次它们在 platform 总线上的真实设备名和模态串，避免写给 `drivers_probe` 的设备名不对。

```bash
# 查看总线上的真实设备名
adb shell 'ls -l /sys/bus/platform/devices | grep -E "rx-macro|tx-macro|va-macro|spf_core_platform:sound|lpass-cdc" | sed -n "1,120p"'

# 查看各节点 uevent 信息
adb shell 'for n in rx-macro tx-macro va-macro; do echo ===$n===; cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:lpass-cdc/$n/uevent 2>/dev/null; done'
```

平台总线上的真实设备名就是简短的 `rx-macro`、`tx-macro`、`va-macro`，刚才给 `drivers_probe` 的名字写复杂了。按正确设备名再试一次。

```bash
adb shell 'echo lpass_cdc_rx_macro > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:lpass-cdc/rx-macro/driver_override; echo rx-macro > /sys/bus/platform/drivers_probe; echo lpass_cdc_tx_macro > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:lpass-cdc/tx-macro/driver_override; echo tx-macro > /sys/bus/platform/drivers_probe; echo lpass_cdc_va_macro > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:lpass-cdc/va-macro/driver_override; echo va-macro > /sys/bus/platform/drivers_probe; sleep 2; echo ---DRV---; for n in rx-macro tx-macro va-macro; do echo ===$n===; readlink /sys/bus/platform/devices/$n/driver 2>/dev/null || echo no_driver; done; echo ---CARDS---; cat /proc/asound/cards 2>/dev/null; echo ---SND---; ls /dev/snd 2>/dev/null; echo ---DMESG---; dmesg | grep -i "rx-macro\|tx-macro\|va-macro\|lpass_cdc_.*macro\|sun-asoc-snd\|snd_soc_register_card\|sound card" | tail -80'
```

重试后结果没变，"设备名写错"也排掉了。直接查模块别名表，看 `qcom,lpass-cdc-rx/tx/va-macro` 这些 OF 兼容串到底有没有进模块 alias。

```bash
# 检查 modules.alias 中是否有这些兼容串
adb shell 'grep -n "qcom,lpass-cdc-.*macro\|sun-asoc-snd\|qcom,sun-asoc-snd" /vendor_dlkm/lib/modules/modules.alias 2>/dev/null | sed -n "1,120p"'

# 检查 modules.dep 中对应条目
adb shell 'grep -n "lpass_cdc_rx_macro\|lpass_cdc_tx_macro\|lpass_cdc_va_macro\|machine_dlkm" /vendor_dlkm/lib/modules/modules.dep 2>/dev/null | sed -n "1,120p"'
```

别名表这边没直接给出结果，先确认 `modules.alias/modules.dep` 在当前 recovery 里是否可读，以及是不是压根没带这些文本索引。这个检查很快，能避免继续在空文件上做判断。

```bash
# 确认索引文件存在
adb shell 'ls -l /vendor_dlkm/lib/modules/modules.alias /vendor_dlkm/lib/modules/modules.dep /vendor_dlkm/lib/modules 2>/dev/null'

# 查看文件头部内容
adb shell 'for f in /vendor_dlkm/lib/modules/modules.alias /vendor_dlkm/lib/modules/modules.dep; do echo ===$f===; sed -n "1,20p" $f 2>/dev/null; done'
```

现在可以确认两件事：一是索引文件本身存在且可读；二是它们实际指向的是 `/vendor/lib/modules` 这套索引，而不是别的路径。接下来我直接在 alias 文件里精确搜 macro 和 `sun-asoc-snd` 的兼容串，看是 alias 缺失，还是 alias 有但自动匹配没发生。

```bash
# alias 文件没有这些兼容串
adb shell 'grep -n "qcom,lpass-cdc-rx-macro\|qcom,lpass-cdc-tx-macro\|qcom,lpass-cdc-va-macro\|qcom,sun-asoc-snd" /vendor_dlkm/lib/modules/modules.alias /vendor/lib/modules/modules.alias 2>/dev/null | sed -n "1,120p"'

# 检查 dep 文件中各模块条目
adb shell 'grep -n "lpass_cdc_rx_macro_dlkm.ko\|lpass_cdc_tx_macro_dlkm.ko\|lpass_cdc_va_macro_dlkm.ko\|machine_dlkm.ko" /vendor/lib/modules/modules.dep 2>/dev/null | sed -n "1,120p"'
```

alias 文件里没有这些兼容串，这已经很可疑了。我再做一个更直接的检查：从模块二进制本体里抓字符串，看 `qcom,lpass-cdc-rx/tx/va-macro` 和 `qcom,sun-asoc-snd` 是否真的编进了对应 ko。这样能区分是“sysfs 自动匹配异常”还是“模块本身就没带正确 of_match”。

```bash
adb shell 'for f in /vendor_dlkm/lib/modules/lpass_cdc_rx_macro_dlkm.ko /vendor_dlkm/lib/modules/lpass_cdc_tx_macro_dlkm.ko /vendor_dlkm/lib/modules/lpass_cdc_va_macro_dlkm.ko /vendor_dlkm/lib/modules/machine_dlkm.ko; do echo ===$f===; strings $f 2>/dev/null | grep -E "qcom,lpass-cdc-rx-macro|qcom,lpass-cdc-tx-macro|qcom,lpass-cdc-va-macro|qcom,sun-asoc-snd" | sed -n "1,20p"; done'
```

```bash
adb shell 'for f in /vendor_dlkm/lib/modules/lpass_cdc_rx_macro_dlkm.ko /vendor_dlkm/lib/modules/lpass_cdc_tx_macro_dlkm.ko /vendor_dlkm/lib/modules/lpass_cdc_va_macro_dlkm.ko /vendor_dlkm/lib/modules/machine_dlkm.ko; do echo ===$f===; modinfo $f 2>/dev/null | sed -n "1,40p"; done'
```

新线索：`machine_dlkm` 的 `modinfo` 明确导出了 `qcom,sun-asoc-snd` alias，但三个 macro 模块的 `modinfo` 里没有导出 alias。转去源码树和构建树里找这几个模块的源文件或对象名，看它们是不是走了"父驱动手工创建/注册子设备"而不是标准 OF 自动匹配。

```bash
# 搜索驱动注册文本和模块名
cd /Volumes/Case-sensitive\ APFS/TWRP
rg -n "RX macro driver|TX macro driver|LPASS codec VA macro driver|ALSA SoC msm|lpass_cdc_rx_macro_dlkm|lpass_cdc_tx_macro_dlkm|lpass_cdc_va_macro_dlkm|machine_dlkm" twrp_a12_compile twrp_a16_compile -g '!**/.git/**'
```

```bash
# 确认模块初始化状态和引用计数
adb shell 'for m in lpass_cdc_rx_macro_dlkm lpass_cdc_tx_macro_dlkm lpass_cdc_va_macro_dlkm; do echo ===$m===; cat /sys/module/$m/initstate 2>/dev/null; cat /sys/module/$m/refcnt 2>/dev/null; done'
```

继续往更直接的证据靠。现在最有价值的是把 `devices_deferred` 读出来。如果 debugfs 没挂，先挂上它，再看 `sound` 或 macro 有没有被内核明确标成 deferred probe。

```bash
adb shell 'mount | grep -q "/sys/kernel/debug " || mount -t debugfs debugfs /sys/kernel/debug; cat /sys/kernel/debug/devices_deferred 2>/dev/null | sed -n "1,200p"'
```

```bash
adb shell 'for n in sound rx-macro tx-macro va-macro; do p=/sys/devices/platform/soc/soc:spf_core_platform; case $n in sound) q=$p/soc:spf_core_platform:sound;; *) q=$p/soc:spf_core_platform:lpass-cdc/$n;; esac; echo ===$n===; [ -e $q/waiting_for_supplier ] && cat $q/waiting_for_supplier || echo no_wait_file; done'
```

这一步拿到的是硬证据：`sound`、`rx-macro`、`tx-macro`、`va-macro` 全都在 `devices_deferred` 里。当前不是"模块没注册"或"设备名不对"，而是这些设备的 probe 被内核明确延后了。顺着 deferred 列表里一起出现的几个 `*_swr_clk_data_pinctrl` 往前查，因为它们很可能就是把 macro 和 machine 一起卡住的更上游前置。

### 11.4 上游 pinctrl 阻塞定位

检查三个 `swr_clk_data_pinctrl` 节点——它们也都在 deferred 中：

```bash
adb shell 'for n in soc:spf_core_platform:rx_swr_clk_data_pinctrl soc:spf_core_platform:tx_swr_clk_data_pinctrl soc:spf_core_platform:bt_swr_clk_data_pinctrl; do echo ===$n===; ls -l /sys/bus/platform/devices/$n 2>/dev/null; echo ---; find /sys/bus/platform/devices/$n -maxdepth 1 -type f | sed -n "1,40p"; done'

adb shell 'for n in soc:spf_core_platform:rx_swr_clk_data_pinctrl soc:spf_core_platform:tx_swr_clk_data_pinctrl soc:spf_core_platform:bt_swr_clk_data_pinctrl; do echo ===$n===; cat /sys/bus/platform/devices/$n/uevent 2>/dev/null; done'

adb shell 'ls /sys/bus/platform/drivers | grep -E "pinctrl|swr" | sed -n "1,200p"'
```

上游线索也出来了：这三个一起 deferred 的 pinctrl 节点都指向 `qcom,msm-cdc-pinctrl`，而平台上确实注册了 `msm-cdc-pinctrl` 驱动。下一步我直接看它有没有接住任何设备；如果它自己也没绑定，那就很可能是整条 macro/machine 卡住的根因。

```bash
adb shell 'ls -R /sys/bus/platform/drivers/msm-cdc-pinctrl 2>/dev/null | sed -n "1,160p"'

adb shell 'for n in soc:spf_core_platform:rx_swr_clk_data_pinctrl soc:spf_core_platform:tx_swr_clk_data_pinctrl soc:spf_core_platform:bt_swr_clk_data_pinctrl; do echo ===$n===; cat /sys/bus/platform/devices/$n/driver_override 2>/dev/null; done'

adb shell 'strings /vendor_dlkm/lib/modules/lpass_cdc_dlkm.ko 2>/dev/null | grep -E "qcom,msm-cdc-pinctrl|msm-cdc-pinctrl" | sed -n "1,40p"'
```

`msm-cdc-pinctrl` 驱动本身是活的，而且已经接住了别的 pinctrl 设备，但没有接住这三个 `rx/tx/bt_swr_clk_data_pinctrl`。这基本说明最后的卡点还要再往上收一层。我直接对这三个 pinctrl 节点做一次手工 probe，看能不能把后面的 macro deferred 一起带活。

手工探针三个 pinctrl 节点：

```bash
adb shell 'for pair in "soc:spf_core_platform:rx_swr_clk_data_pinctrl:msm-cdc-pinctrl" "soc:spf_core_platform:tx_swr_clk_data_pinctrl:msm-cdc-pinctrl" "soc:spf_core_platform:bt_swr_clk_data_pinctrl:msm-cdc-pinctrl"; do n=${pair%:*}; d=${pair##*:}; echo $d > /sys/bus/platform/devices/$n/driver_override; echo ${n##*:} > /sys/bus/platform/drivers_probe; done; sleep 2; echo ---PINCTRL---; for n in soc:spf_core_platform:rx_swr_clk_data_pinctrl soc:spf_core_platform:tx_swr_clk_data_pinctrl soc:spf_core_platform:bt_swr_clk_data_pinctrl; do echo ===$n===; readlink /sys/bus/platform/devices/$n/driver 2>/dev/null || echo no_driver; done; echo ---DEFERRED---; cat /sys/kernel/debug/devices_deferred 2>/dev/null | sed -n "1,120p"; echo ---CARDS---; cat /proc/asound/cards 2>/dev/null'
```

`devices_deferred` 已明确列出 `sound`、三个 macro 和三个 `msm-cdc-pinctrl` 设备，这能把“没绑上”从现象升级成内核已确认的 deferred probe。补完这段后，这份文档就能准确反映当前前沿。

这轮新增的有效结论有三条：

1. 主 VINTF 缺项已经不再是前沿。新 recovery 刷入后，音频 HAL 相关主清单已经生效，`audio-hal`、`adsprpcd`、`audioadsprpcd` 都能稳定运行。
2. `sound` 子设备已经真实出现，不再是之前那种“`spf_core_platform` 根本没枚举 child”的状态。
3. 当前最硬的阻塞已经收敛成一整条 deferred probe 链，而不是单点问题。

我继续查到的关键证据是：

1. `devices_deferred` 里明确有 `sound`、`rx-macro`、`tx-macro`、`va-macro`，以及上游三个 `rx/tx/bt_swr_clk_data_pinctrl`。
2. `sound` 的 `waiting_for_supplier` 已经是 0，说明不是最表层 supplier 等待。
3. `machine_dlkm` 明确带有 `qcom,sun-asoc-snd` alias，但 `sun-asoc-snd` 还是没有绑上 `sound`。
4. `lpass_cdc_rx/tx/va_macro` 这三个模块都已经装载，也都注册了对应 platform driver，但对应设备还是没绑定。
5. 上游 `msm-cdc-pinctrl` 驱动本身是活的，也能绑定别的 pinctrl 设备，但偏偏没接住这三个音频相关 pinctrl 节点。

所以现在离直接播放还差的，不再是 HAL、VINTF、`aud_pasthru` 或大范围模块缺失，而是最后这段 deferred probe 链没打通。更具体地说，就是：

1. `msm-cdc-pinctrl` 相关 pinctrl 节点没就绪。
2. 导致 `rx/tx/va macro` 没 probe 成功。
3. 进而导致 `sun-asoc-snd` 不能完成 card probe。
4. 所以 `/dev/snd` 还是只有 `timer`，`/proc/asound/cards` 还是空。


## 十二、设备断连与离线分析

继续沿 deferred probe 这条链往上查。先把三个 `msm-cdc-pinctrl` 节点的依赖和真实设备名核清，再重试一次更准确的手工 probe。

```bash
adb shell 'for n in soc:spf_core_platform:rx_swr_clk_data_pinctrl soc:spf_core_platform:tx_swr_clk_data_pinctrl soc:spf_core_platform:bt_swr_clk_data_pinctrl; do echo ===$n===; ls -l /sys/bus/platform/devices/$n 2>/dev/null; find /sys/bus/platform/devices/$n -maxdepth 1 -type l | sed -n "1,80p"; done'
```

```bash
adb shell 'for n in soc:spf_core_platform:rx_swr_clk_data_pinctrl soc:spf_core_platform:tx_swr_clk_data_pinctrl soc:spf_core_platform:bt_swr_clk_data_pinctrl; do echo ===$n===; [ -e /sys/bus/platform/devices/$n/waiting_for_supplier ] && cat /sys/bus/platform/devices/$n/waiting_for_supplier || echo no_wait_file; done'
```

```bash
adb shell 'ls -l /sys/bus/platform/drivers/msm-cdc-pinctrl'
```

设备连接状态丢失，当前既不在 adb 也不在 fastboot。等待设备重新上线：

```bash
adb devices
fastboot devices
adb wait-for-device && adb devices
```

设备还没重新枚举回来，转做离线分析，把已经拿到的运行时证据再往前推一层。重点分析为什么 `driver` 在、`device` 在、但 probe 还是 deferred。

```bash
cd /Volumes/Case-sensitive\ APFS/TWRP
strings magisk_inject_ossi_20260312/orig.img >/dev/null

strings twrp_a16_compile/vendor/lib/modules/machine_dlkm.ko 2>/dev/null | grep -i -E 'deferr|supplier|clock|pinctrl|macro|snd_soc_register_card|asoc|probe|failed' | sed -n '1,160p'
```

## 十三、设备重连后继续 deferred probe 链追查

设备恢复连接后，回到 live recovery 现场，先确认当前会话状态，再看 `msm-cdc-pinctrl` 缺的到底是什么。

```bash
adb devices && adb shell getprop ro.bootmode
```

```bash
adb shell 'cat /proc/asound/cards 2>/dev/null; echo ---; ls /dev/snd 2>/dev/null; echo ---; cat /sys/kernel/debug/devices_deferred 2>/dev/null | sed -n "1,120p"'
```

```bash
adb shell 'for n in soc:spf_core_platform:rx_swr_clk_data_pinctrl soc:spf_core_platform:tx_swr_clk_data_pinctrl soc:spf_core_platform:bt_swr_clk_data_pinctrl; do echo ===$n===; cat /sys/bus/platform/devices/$n/uevent 2>/dev/null; done'
```

现场和刚才一致，没有回退：声卡仍未枚举，deferred 队列仍是同一串节点。直接看这些 deferred 设备各自缺什么 supplier 或资源。

```bash
adb shell 'for n in soc:spf_core_platform:rx_swr_clk_data_pinctrl soc:spf_core_platform:tx_swr_clk_data_pinctrl soc:spf_core_platform:bt_swr_clk_data_pinctrl; do echo ===$n===; ls -l /sys/bus/platform/devices/$n; echo ---; find /sys/bus/platform/devices/$n -maxdepth 1 -name "supplier:*" -o -name "consumer:*" | sed -n "1,80p"; done'
```

```bash
adb shell 'for n in rx-macro tx-macro va-macro; do echo ===$n===; ls -l /sys/bus/platform/devices/$n; echo ---; find /sys/bus/platform/devices/$n -maxdepth 1 -name "supplier:*" -o -name "consumer:*" | sed -n "1,80p"; done'
```

```bash
adb shell 'echo ===sound===; ls -l /sys/bus/platform/devices/soc:spf_core_platform:sound; echo ---; find /sys/bus/platform/devices/soc:spf_core_platform:sound -maxdepth 1 -name "supplier:*" -o -name "consumer:*" | sed -n "1,80p"; echo ---; cat /sys/bus/platform/devices/soc:spf_core_platform:sound/waiting_for_supplier 2>/dev/null'
```

总线视图没给出额外依赖，转到真实路径下的 supplier 链接和电源状态，判断 deferred 是卡在 regulator、clk，还是 pinctrl 自己的 probe。

```bash
adb shell 'base=/sys/devices/platform/soc/soc:spf_core_platform; for n in rx_swr_clk_data_pinctrl tx_swr_clk_data_pinctrl bt_swr_clk_data_pinctrl; do p=$base/soc:spf_core_platform:$n; echo ===$p===; find $p -maxdepth 1 \( -name "supplier:*" -o -name "consumer:*" \) | sed -n "1,80p"; echo ---; [ -d $p/power ] && cat $p/power/runtime_status 2>/dev/null; done'
```

```bash
adb shell 'base=/sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:lpass-cdc; for n in rx-macro tx-macro va-macro; do p=$base/$n; echo ===$p===; find $p -maxdepth 1 \( -name "supplier:*" -o -name "consumer:*" \) | sed -n "1,80p"; echo ---; [ -d $p/power ] && cat $p/power/runtime_status 2>/dev/null; done'
```

```bash
adb shell 'p=/sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound; echo ===$p===; find $p -maxdepth 1 \( -name "supplier:*" -o -name "consumer:*" \) | sed -n "1,80p"; echo ---; cat $p/power/runtime_status 2>/dev/null'
```

有了一个可比对对象：`msm-cdc-pinctrl` 已经接住了 `sec_i2s1_pinctrl`，但没接住 `rx/tx/bt_swr_clk_data_pinctrl`。把这两类节点逐项对比，找出 deferred 链真正缺的那一个属性或上游对象。

```bash
adb shell 'for n in soc:spf_core_platform:sec_i2s1_pinctrl soc:spf_core_platform:rx_swr_clk_data_pinctrl soc:spf_core_platform:tx_swr_clk_data_pinctrl soc:spf_core_platform:bt_swr_clk_data_pinctrl; do echo ===$n===; cat /sys/bus/platform/devices/$n/uevent 2>/dev/null; echo ---; readlink /sys/bus/platform/devices/$n/driver 2>/dev/null || echo no_driver; echo ---; find /sys/bus/platform/devices/$n -maxdepth 1 -name "supplier:*" | sed -n "1,40p"; done'
```

```bash
adb shell 'for n in sec_i2s1_pinctrl rx_swr_clk_data_pinctrl tx_swr_clk_data_pinctrl bt_swr_clk_data_pinctrl; do p=/sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:$n; echo ===$p===; ls -1 $p 2>/dev/null | sed -n "1,120p"; done'
```

```bash
adb shell 'cat /sys/kernel/debug/devices_deferred 2>/dev/null | grep -n "pinctrl\|macro\|sound"'
```

新差异已经抓到了：`sec_i2s1_pinctrl` 依赖的是 SoC 顶层 pinctrl，并且已经绑定；而 `rx/tx/bt_swr_clk_data_pinctrl` 这三个节点的 supplier 竟然是 `spf_core_platform` 自己。把 supplier 关系读全。

```bash
adb shell 'for n in rx_swr_clk_data_pinctrl tx_swr_clk_data_pinctrl bt_swr_clk_data_pinctrl; do p=/sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:$n; echo ===$n===; cat $p/waiting_for_supplier 2>/dev/null; readlink $p/supplier:platform:soc:spf_core_platform 2>/dev/null; done'
```

```bash
adb shell 'p=/sys/devices/platform/soc/soc:spf_core_platform; echo ===spf===; ls -1 $p | sed -n "1,120p"; echo ---; readlink $p/driver 2>/dev/null; echo ---; cat $p/uevent 2>/dev/null'
```

```bash
adb shell 'for n in rx_swr_clk_data_pinctrl tx_swr_clk_data_pinctrl bt_swr_clk_data_pinctrl; do p=/sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:$n; echo ===$n===; cat $p/modalias 2>/dev/null; echo ---; cat $p/driver_override 2>/dev/null; done'
```

现在有两个需要纠正的点：一是这三个 pinctrl 节点的 `waiting_for_supplier` 实际已经是 0；二是之前留下了 `driver_override=msm-cdc-pinctrl`。把 override 和 probe 都按"完整设备名"重新做一遍，排掉人为干扰。

```bash
adb shell 'for n in soc:spf_core_platform:rx_swr_clk_data_pinctrl soc:spf_core_platform:tx_swr_clk_data_pinctrl soc:spf_core_platform:bt_swr_clk_data_pinctrl; do echo msm-cdc-pinctrl > /sys/bus/platform/devices/$n/driver_override; echo $n > /sys/bus/platform/drivers_probe; done; sleep 2; for n in soc:spf_core_platform:rx_swr_clk_data_pinctrl soc:spf_core_platform:tx_swr_clk_data_pinctrl soc:spf_core_platform:bt_swr_clk_data_pinctrl; do echo ===$n===; readlink /sys/bus/platform/devices/$n/driver 2>/dev/null || echo no_driver; done'
```

```bash
adb shell 'for n in rx-macro tx-macro va-macro; do case $n in rx-macro) d=lpass_cdc_rx_macro;; tx-macro) d=lpass_cdc_tx_macro;; va-macro) d=lpass_cdc_va_macro;; esac; echo $d > /sys/bus/platform/devices/$n/driver_override; echo $n > /sys/bus/platform/drivers_probe; done; sleep 2; for n in rx-macro tx-macro va-macro; do echo ===$n===; readlink /sys/bus/platform/devices/$n/driver 2>/dev/null || echo no_driver; done'
```

```bash
adb shell 'echo sun-asoc-snd > /sys/bus/platform/devices/soc:spf_core_platform:sound/driver_override; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe; sleep 2; echo ===sound===; readlink /sys/bus/platform/devices/soc:spf_core_platform:sound/driver 2>/dev/null || echo no_driver; echo ---; cat /proc/asound/cards 2>/dev/null; echo ---; ls /dev/snd 2>/dev/null'
```

完整设备名也已经排掉了，行为没变。最有价值的是把 deferred 的"原因文本"挖出来，而不是继续盲目 probe；新内核有时会把 reason 单独放在 debugfs 里。

```bash
adb shell 'ls -l /sys/kernel/debug | grep devices_deferred; echo ---; find /sys/kernel/debug -maxdepth 2 -name "*deferred*" | sed -n "1,80p"'
```

```bash
adb shell 'for n in soc:spf_core_platform:rx_swr_clk_data_pinctrl soc:spf_core_platform:tx_swr_clk_data_pinctrl soc:spf_core_platform:bt_swr_clk_data_pinctrl rx-macro tx-macro va-macro soc:spf_core_platform:sound; do echo ===$n===; cat /sys/bus/platform/devices/$n/modalias 2>/dev/null; done'
```

```bash
adb shell 'for d in msm-cdc-pinctrl lpass_cdc_rx_macro lpass_cdc_tx_macro lpass_cdc_va_macro sun-asoc-snd; do echo ===$d===; ls -1 /sys/bus/platform/drivers/$d 2>/dev/null | sed -n "1,40p"; done'
```

现在最像的情况是：这些 driver 不是"没注册"，而是 probe 进去后直接 `-EPROBE_DEFER`，只是没把原因打到日志里。按 driver 名和节点名扫一遍 `dmesg`。

```bash
adb shell 'dmesg | grep -i "msm-cdc-pinctrl\|rx_swr_clk_data_pinctrl\|tx_swr_clk_data_pinctrl\|bt_swr_clk_data_pinctrl" | tail -80'
```

```bash
adb shell 'dmesg | grep -i "lpass_cdc_rx_macro\|lpass_cdc_tx_macro\|lpass_cdc_va_macro\|rx-macro\|tx-macro\|va-macro" | tail -80'
```

```bash
adb shell 'dmesg | grep -i "sun-asoc-snd\|snd_soc_register_card\|sound card\|asoc" | tail -120'
```

日志侧是静默的，所以接下来只能看 driver core 自己的设备链接状态。devlink 目录通常会直接暴露 supplier/consumer 的 `status` 或者关联对象，这一步能判断究竟是哪条链接还没 ready。

```bash
adb shell 'for l in /sys/devices/virtual/devlink/platform:soc:spf_core_platform--platform:soc:spf_core_platform:rx_swr_clk_data_pinctrl /sys/devices/virtual/devlink/platform:soc:spf_core_platform--platform:soc:spf_core_platform:tx_swr_clk_data_pinctrl /sys/devices/virtual/devlink/platform:soc:spf_core_platform--platform:soc:spf_core_platform:bt_swr_clk_data_pinctrl /sys/devices/virtual/devlink/platform:soc:spf_core_platform--platform:soc:spf_core_platform:sound; do echo ===$l===; ls -1 $l 2>/dev/null | sed -n "1,80p"; echo ---; for f in status state flags sync_state_only autosuspend_delay_ms; do [ -e $l/$f ] && { echo $f=; cat $l/$f; }; done; done'
```

```bash
adb shell 'for l in /sys/devices/virtual/devlink/platform:soc:vote_lpass_audio_hw--platform:soc:spf_core_platform:sound /sys/devices/virtual/devlink/platform:soc:vote_lpass_audio_hw--platform:soc:spf_core_platform:lpass-cdc; do echo ===$l===; ls -1 $l 2>/dev/null | sed -n "1,80p"; echo ---; for f in status state flags sync_state_only; do [ -e $l/$f ] && { echo $f=; cat $l/$f; }; done; done'
```

做对照，确认 `spf_core_platform` 作为 supplier 时哪些子链接是 `active`、哪些只是 `available`。

```bash
adb shell 'for l in /sys/devices/virtual/devlink/platform:soc:spf_core_platform--platform:soc:spf_core_platform:lpass-cdc /sys/devices/virtual/devlink/platform:soc:spf_core_platform--platform:soc:spf_core_platform:sound /sys/devices/virtual/devlink/platform:soc:spf_core_platform--platform:soc:spf_core_platform:rx_swr_clk_data_pinctrl /sys/devices/virtual/devlink/platform:soc:spf_core_platform--platform:soc:spf_core_platform:tx_swr_clk_data_pinctrl /sys/devices/virtual/devlink/platform:soc:spf_core_platform--platform:soc:spf_core_platform:bt_swr_clk_data_pinctrl; do echo ===$l===; cat $l/status 2>/dev/null; done'
```

```bash
adb shell 'for l in /sys/devices/virtual/devlink/platform:f000000.pinctrl--platform:soc:spf_core_platform:sec_i2s1_pinctrl /sys/devices/virtual/devlink/platform:soc:spf_core_platform--platform:soc:spf_core_platform:sound; do echo ===$l===; ls -1 $l 2>/dev/null | sed -n "1,40p"; echo ---; cat $l/status 2>/dev/null; done'
```

```bash
adb shell 'for n in soc:spf_core_platform:lpass-cdc soc:spf_core_platform:sound soc:spf_core_platform:rx_swr_clk_data_pinctrl; do echo ===$n===; readlink /sys/bus/platform/devices/$n/driver 2>/dev/null || echo no_driver; done'
```

线索基本指向节点属性本身，而不是总线或模块注册。把已绑定的 `sec_i2s1_pinctrl` 和未绑定的 `rx/tx/bt_swr_clk_data_pinctrl` 的 DT 属性名做对照，看是否少了某个关键 phandle 或资源声明。

```bash
adb shell 'for n in sec_i2s1_pinctrl rx_swr_clk_data_pinctrl tx_swr_clk_data_pinctrl bt_swr_clk_data_pinctrl; do p=/proc/device-tree/soc/spf_core_platform/$n; echo ===$n===; ls $p 2>/dev/null | sort | sed -n "1,120p"; done'
```

```bash
adb shell 'for n in sound lpass-cdc/rx-macro@6AC0000 lpass-cdc/tx-macro@6AE0000 lpass-cdc/va-macro@7660000; do p=/proc/device-tree/soc/spf_core_platform/$n; echo ===$n===; ls $p 2>/dev/null | sort | sed -n "1,120p"; done'
```

宏节点的 DT 属性里露出更像根因的东西了：`rx-macro` 和 `va-macro` 都带着 `*_swr_master`，而 deferred 列表里本来就还有 `lpass_bt_swr@6CA0000` 这类节点。接着查 SoundWire master 这一层是否真的没起来。

```bash
adb shell 'ls -l /sys/bus/platform/devices | grep -i swr | sed -n "1,120p"; echo ---; ls -l /sys/bus/soundwire/devices 2>/dev/null | sed -n "1,120p"'
```

```bash
adb shell 'for n in /proc/device-tree/soc/spf_core_platform/lpass-cdc/rx-macro@6AC0000/rx_swr_master /proc/device-tree/soc/spf_core_platform/lpass-cdc/va-macro@7660000/va_swr_master /proc/device-tree/soc/spf_core_platform/lpass_bt_swr@6CA0000; do echo ===$n===; ls $n 2>/dev/null | sed -n "1,80p"; done'
```

```bash
adb shell 'cat /sys/kernel/debug/devices_deferred 2>/dev/null | grep -i swr'
```

新的关键点出来了：`/sys/bus/soundwire/devices` 是空的，而 `rx_swr_master`、`va_swr_master` 的 DT 子节点明明都在。宏节点很可能不是直接缺 codec，而是更上游的 SoundWire master 根本没被带起来。

```bash
adb shell 'ls -R /sys/bus/platform/drivers/swr-mgr 2>/dev/null | sed -n "1,160p"; echo ---; ls -R /sys/bus/platform/drivers/lpass-bt-swr 2>/dev/null | sed -n "1,160p"'
```

```bash
adb shell 'ls -R /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:lpass_bt_swr@6CA0000 2>/dev/null | sed -n "1,160p"'
```

```bash
adb shell 'for d in swr-mgr lpass-bt-swr; do echo ===$d===; find /sys/module -path "*/drivers/*$d*" 2>/dev/null | sed -n "1,40p"; done'
```

SWR 这一层比前面更像根因了：相关驱动都注册了，但一个设备都没绑上，`soundwire` 总线也是空的。确认是 `lpass_bt_swr` 自己卡住，还是 `rx/va swr master` 这批根本没被实例化出来。

```bash
adb shell 'cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:lpass_bt_swr@6CA0000/waiting_for_supplier 2>/dev/null; echo ---; for s in supplier:platform:soc supplier:platform:soc:bt_swr_mclk_clk supplier:platform:soc:bt_swr_mclk_clk_2x supplier:platform:soc:spf_core_platform supplier:platform:soc:vote_lpass_audio_hw supplier:platform:soc:vote_lpass_core_hw; do readlink /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:lpass_bt_swr@6CA0000/$s 2>/dev/null; done'
```

```bash
adb shell 'ls -l /sys/bus/platform/devices | grep -E "rx_swr_master|va_swr_master|swrm|bt_swr" | sed -n "1,160p"; echo ---; find /sys/devices/platform -maxdepth 4 \( -name "*rx_swr_master*" -o -name "*va_swr_master*" -o -name "*swrm*" \) 2>/dev/null | sed -n "1,160p"'
```

```bash
adb shell 'for n in soc:spf_core_platform:rx_swr_clk_data_pinctrl soc:spf_core_platform:tx_swr_clk_data_pinctrl soc:spf_core_platform:bt_swr_clk_data_pinctrl soc:spf_core_platform:lpass_bt_swr@6CA0000; do echo ===$n===; [ -e /sys/bus/platform/devices/$n/waiting_for_supplier ] && cat /sys/bus/platform/devices/$n/waiting_for_supplier || echo no_wait; done'
```

现在可以明确：这些 SWR 相关节点已经不是在"等 supplier"，而是所有 supplier 都 ready 了，但 probe 还是被 defer。值得直接手工点一次 `lpass-bt-swr`，看能不能至少把 SoundWire 总线带活。

```bash
adb shell 'echo lpass-bt-swr > /sys/bus/platform/devices/soc:spf_core_platform:lpass_bt_swr@6CA0000/driver_override; echo soc:spf_core_platform:lpass_bt_swr@6CA0000 > /sys/bus/platform/drivers_probe; sleep 2; echo ===bt_swr===; readlink /sys/bus/platform/devices/soc:spf_core_platform:lpass_bt_swr@6CA0000/driver 2>/dev/null || echo no_driver; echo ---; ls -l /sys/bus/soundwire/devices 2>/dev/null | sed -n "1,120p"; echo ---; cat /sys/kernel/debug/devices_deferred 2>/dev/null | grep -i swr'
```

```bash
adb shell 'for l in /sys/devices/virtual/devlink/platform:soc:bt_swr_mclk_clk--platform:soc:spf_core_platform:lpass_bt_swr@6CA0000 /sys/devices/virtual/devlink/platform:soc:bt_swr_mclk_clk_2x--platform:soc:spf_core_platform:lpass_bt_swr@6CA0000 /sys/devices/virtual/devlink/platform:soc:vote_lpass_audio_hw--platform:soc:spf_core_platform:lpass_bt_swr@6CA0000 /sys/devices/virtual/devlink/platform:soc:vote_lpass_core_hw--platform:soc:spf_core_platform:lpass_bt_swr@6CA0000; do echo ===$l===; cat $l/status 2>/dev/null; done'
```

现场证据已经把根因收缩到 SWR 这一层了，但 live sysfs 给不出更细的 defer reason。转去源码树里找对应驱动实现，确认这些节点理论上会因为什么条件返回 `-EPROBE_DEFER`，这样下一步就不是盲试。

## 十四、离线源码检索：定位 deferred probe 根因

```bash
cd /Volumes/Case-sensitive\ APFS/TWRP

rg -rn "EPROBE_DEFER" twrp_a16_compile twrp_a12_compile -g '*.{c,h,dtsi,dts}' --no-ignore
# 22 results

rg -rn "of_match_table|platform_driver|probe\s*=|module_platform_driver" twrp_a16_compile twrp_a12_compile -g '*.{c,h}' --no-ignore
# 200 results
```

搜索驱动兼容串在源码中的位置——均无直接命中（工作区不含完整 kernel 驱动源码）：

```bash
rg -rn "qcom,msm-cdc-pinctrl" twrp_a16_compile twrp_a12_compile --no-ignore
# 搜索含该兼容串的源文件，编译产物中 modules.alias 有记录

rg -rn "lpass_cdc_rx_macro" twrp_a16_compile twrp_a12_compile --no-ignore
rg -rn "lpass_cdc_tx_macro" twrp_a16_compile twrp_a12_compile --no-ignore
rg -rn "lpass_cdc_va_macro" twrp_a16_compile twrp_a12_compile --no-ignore
rg -rn "qcom,sun-asoc-snd" twrp_a16_compile twrp_a12_compile --no-ignore
rg -rn "lpass_bt_swr" twrp_a16_compile twrp_a12_compile --no-ignore

find twrp_a16_compile twrp_a12_compile -name '*lpass*cdc*macro*' 2>/dev/null
# no matches

find twrp_a16_compile twrp_a12_compile -name '*msm*cdc*pinctrl*' 2>/dev/null
# no matches

find twrp_a16_compile twrp_a12_compile -name '*sun*asoc*snd*' 2>/dev/null
# no matches

find twrp_a16_compile twrp_a12_compile -name '*bt*swr*' 2>/dev/null
# no matches

find twrp_a16_compile -path '*/sound/*' 2>/dev/null | head -200
# 200 matches — sound 子目录存在但无对应驱动源文件

find twrp_a16_compile -path '*/Documentation/devicetree/bindings/*' 2>/dev/null
# no matches
```

工作区里直接搜源码没有命中，说明当前树里主要是编译产物或裁剪过的源码。换一个方式在更宽的目录做检索。

```bash
rg -rn "qcom,msm-cdc-pinctrl|lpass_cdc_rx_macro|lpass_cdc_tx_macro|lpass_cdc_va_macro|qcom,sun-asoc-snd|lpass_bt_swr|swr-mgr" twrp_a16_compile/ --no-ignore

rg -rn "qcom,msm-cdc-pinctrl|lpass_cdc_rx_macro|lpass_cdc_tx_macro|lpass_cdc_va_macro|qcom,sun-asoc-snd|lpass_bt_swr|swr-mgr" twrp_a12_compile/ --no-ignore
# twrp_a16_compile/vendor/lib/modules/ 下 modules.alias 和 modules.dep 中有记录

rg -rn "qcom,msm-cdc-pinctrl|lpass_cdc_rx_macro|lpass_cdc_tx_macro|lpass_cdc_va_macro|qcom,sun-asoc-snd|lpass_bt_swr|swr-mgr" device_tree/ --no-ignore
# no results

rg -rn "qcom,msm-cdc-pinctrl|lpass_cdc_rx_macro|lpass_cdc_tx_macro|lpass_cdc_va_macro|qcom,sun-asoc-snd|lpass_bt_swr|swr-mgr" audio_dtb_probe/ --no-ignore
# no results

rg -rn "qcom,msm-cdc-pinctrl|lpass_cdc_rx_macro|lpass_cdc_tx_macro|lpass_cdc_va_macro|qcom,sun-asoc-snd|lpass_bt_swr|swr-mgr" audio_manual/ --no-ignore
# no results
```

逐个目录搜索具体字符串：

```bash
rg -rn "msm-cdc-pinctrl" device_tree/ --no-ignore
# no results

rg -rn "lpass_cdc_rx_macro" device_tree/ --no-ignore

rg -rn "qcom,sun-asoc-snd" device_tree/ --no-ignore

rg -rn "swr-mgr" device_tree/ --no-ignore

find twrp_a16_compile -path '*/qcom/audio/*' 2>/dev/null
# no matches

find twrp_a12_compile -path '*/qcom/audio/*' 2>/dev/null
# no matches

rg -rn "msm-cdc-pinctrl" kernel/ -g '*.c' --no-ignore
# no results

rg -rn "msm-cdc-pinctrl" hardware/ -g '*.c' --no-ignore
# no results

rg -rn "msm-cdc-pinctrl" vendor/ -g '*.c' --no-ignore
# no results

rg -rn "msm-cdc-pinctrl" device_tree/ -g '*.dts' --no-ignore
# no results

rg -rn "msm-cdc-pinctrl" docs/ --no-ignore
# 3 results — 仅在 bring-up 文档中出现

rg -rn "msm-cdc-pinctrl" android_vendor_twrp/ --no-ignore
# no results

rg -rn "lpass_cdc" android_vendor_twrp/ --no-ignore
# no results

rg -rn "sun-asoc-snd" android_vendor_twrp/ --no-ignore
# no results

find device_tree -name '*.{dts,dtsi,txt,prop}' 2>/dev/null
# no matches — device_tree 目录下无 DT 源文件
```

排查 device_tree 和编译产物中的配置文件：

```bash
rg -rn "audio" device_tree/ -g '*.mk' --no-ignore
# 1 result — BoardConfig.mk 中的 audio 模块列表

rg -rn "audio" device_tree/ -g '*.prop' --no-ignore
# no results

rg -rn "lpass_cdc_rx_macro" twrp_a16_compile/ -g '*.dts' --no-ignore
# no results

rg -rn "lpass_cdc_rx_macro" twrp_a16_compile/ -g '*.dtsi' --no-ignore
# no results

rg -rn "audio_pkt" twrp_a16_compile/ -g '*.ko' --no-ignore
# no results（文本搜索无法匹配二进制文件）

rg -rn "lpass" twrp_a16_compile/ -g '*.mk' --no-ignore
# no results

rg -rn "lpass" twrp_a16_compile/ -g '*.rc' --no-ignore
# 4 results

rg -rn "lpass" twrp_a16_compile/ -g '*.bp' --no-ignore
# 2 results

rg -rn "cdc-pinctrl" twrp_a16_compile/ -g '*.rst' --no-ignore
# no results

rg -rn "sun-asoc" twrp_a16_compile/ -g '*.txt' --no-ignore
# no results

rg -rn "audio" device_tree/ -g 'BoardConfig.mk' --no-ignore
# 1 result — LOAD_VENDOR_MODULES 包含音频模块列表

rg -rn "audio" device_tree/ -g 'device.mk' --no-ignore
# no results
```

在编译产物目录做补充搜索：

```bash
rg -rn "sun-asoc" twrp_a16_compile/kernel/ -g '*.c' --no-ignore
# no results

rg -rn "lpass_cdc_rx_macro" twrp_a16_compile/hardware/ -g '*.c' --no-ignore
# no results

rg -rn "msm-cdc-pinctrl" twrp_a16_compile/vendor/ -g '*.c' --no-ignore
# no results

find twrp_a16_compile/kernel -path '*/audio/*' 2>/dev/null
# no matches

find twrp_a16_compile/vendor -path '*qcom*audio*' 2>/dev/null
# no matches
```

检查 init.recovery 中的音频初始化配置：

```bash
rg -rn "sound" audio_dtb_probe/ -g '*.rc' --no-ignore
# no results

rg -rn "msm-cdc-pinctrl" device_tree/ -path '*/recovery/root/*.rc' --no-ignore
# no results
```


排查 device_tree 中的 init 配置和内核模块加载列表：

```bash
rg -rn "LOAD_VENDOR_MODULES" android_vendor_twrp/ -g '*.mk' --no-ignore
# 2 results

rg -rn "LOAD_VENDOR_MODULES" device_tree/ -g 'BoardConfig.mk' --no-ignore
# 11 results — 多个设备的 BoardConfig.mk 中有音频模块列表

rg -rn "cdc_rx_macro" docs/ -g '*.md' --no-ignore
# 3 results — 仅在 bring-up 文档中出现

find docs/ -name '*.md' 2>/dev/null
# 20 matches
```


**源码检索总结**：当前工作区没有完整的 kernel 音频驱动源码（驱动以预编译 `.ko` 形式存在于 `vendor_dlkm/lib/modules/`），因此 deferred probe 的根因只能从 live sysfs 和 devlink 状态反推。下面回到设备现场继续推进。

## 十五、SWR 时钟与 DT 兼容串确认

补一个最上游的活性判断，把 `bt_swr_mclk_clk` 这类 SWR 时钟设备也看掉。如果这些时钟节点本身都只是 "available" 没进 active，那当前 deferred 链就可以进一步收敛到 SWR 时钟/控制器层。

```bash
adb shell 'for n in soc:bt_swr_mclk_clk soc:bt_swr_mclk_clk_2x; do echo ===$n===; cat /sys/bus/platform/devices/$n/uevent 2>/dev/null; echo ---; readlink /sys/bus/platform/devices/$n/driver 2>/dev/null || echo no_driver; echo ---; [ -d /sys/bus/platform/devices/$n/power ] && cat /sys/bus/platform/devices/$n/power/runtime_status 2>/dev/null; done'
```

```bash
adb shell 'for l in /sys/devices/virtual/devlink/platform:soc:bt_swr_mclk_clk--platform:soc:spf_core_platform:lpass_bt_swr@6CA0000 /sys/devices/virtual/devlink/platform:soc:bt_swr_mclk_clk_2x--platform:soc:spf_core_platform:lpass_bt_swr@6CA0000; do echo ===$l===; ls -1 $l 2>/dev/null | sed -n "1,40p"; echo ---; cat $l/status 2>/dev/null; done'
```

```bash
adb shell 'for n in soc:bt_swr_mclk_clk soc:bt_swr_mclk_clk_2x; do echo ===$n===; find /sys/bus/platform/devices/$n -maxdepth 1 -name "supplier:*" -o -name "consumer:*" | sed -n "1,60p"; done'
```

再补最后一层确认：`rx_swr_master` 和 `va_swr_master` 这两个 DT 子节点到底是什么兼容串。如果它们本来就该由 `swr-mgr` 接管，而现在一个实例都没有，那循环阻塞就基本能解释通。

```bash
adb shell 'for p in /proc/device-tree/soc/spf_core_platform/lpass-cdc/rx-macro@6AC0000/rx_swr_master/compatible /proc/device-tree/soc/spf_core_platform/lpass-cdc/va-macro@7660000/va_swr_master/compatible /proc/device-tree/soc/spf_core_platform/lpass_bt_swr@6CA0000/compatible; do echo ===$p===; strings $p 2>/dev/null; done'
```

```bash
adb shell 'for p in /proc/device-tree/soc/spf_core_platform/lpass-cdc/rx-macro@6AC0000/rx_swr_master /proc/device-tree/soc/spf_core_platform/lpass-cdc/va-macro@7660000/va_swr_master; do echo ===$p===; ls $p 2>/dev/null | sort | sed -n "1,80p"; done'
```

```bash
adb shell 'strings /vendor_dlkm/lib/modules/swr_ctrl_dlkm.ko 2>/dev/null | grep -E "qcom,.*swr|swr-mgr|soundwire" | sed -n "1,60p"'
```

前沿已经比"macro 没绑定"更具体了。现在最像根因的是 SoundWire master 这一层没有起来：

1. `rx_swr_master` 和 `va_swr_master` 这两个运行时 DT 子节点都在，兼容串明确是 `qcom,swr-mstr`。
2. `swr_ctrl_dlkm.ko` 二进制里也明确带了 `qcom,swr-mstr` 和 `swr-mgr` 相关字符串。
3. 但当前 `swr-mgr` 驱动目录下面没有绑定任何设备，`/sys/bus/soundwire/devices` 也是空的。
4. 同时 `lpass-bt-swr` 这条蓝牙 SWR 控制器链也一样，驱动在，但设备不绑定，仍留在 deferred 队列里。

这会形成一条更清楚的阻塞链：

1. `qcom,swr-mstr` 没有实例化成可工作的 SWR manager。
2. 所以 `rx-macro` / `tx-macro` / `va-macro` probe 继续 defer。
3. 所以 `sun-asoc-snd` 也没法完成 card probe。
4. 最终 `/dev/snd` 还是只有 `timer`，`/proc/asound/cards` 还是空。

还有一个重要修正：

1. 这批节点现在不是在"等 supplier"。
2. `rx/tx/bt_swr_clk_data_pinctrl`、`lpass_bt_swr@6CA0000` 的 `waiting_for_supplier` 都已经是 `0`。
3. 但它们仍然留在 `devices_deferred` 里。
4. 这说明当前是更深一层的 probe defer，不是最表层 devlink 没 ready。

所以现在离能直接播放还差的，基本可以收敛成一句话：

1. 不是 HAL。
2. 不是主 VINTF。
3. 不是 `aud_pasthru`。
4. 而是 `qcom,swr-mstr` / `swr-mgr` 这一层没有被真正带起来，导致后面的 macro 和声卡整条链都卡在 deferred probe。

下一步最值的是两件事：

1. 对照正常系统，确认 `qcom,swr-mstr` 在系统里是怎么被实例化到 platform 或 soundwire 总线上的。
2. 找 recovery 当前少掉的那个前置条件，是某个时钟、某个 parent device，还是 `spf_core_platform` 没有把这两个 `swr-mstr` 子节点注册出来。

## 十六、继续沿 SWR 线收敛：LPI pinctrl 突破

继续沿 SWR 这条线往上收敛，不动镜像、不重启设备。先确认 `qcom,swr-mstr` 在当前 recovery 里到底有没有被实例化成任何 platform 设备，以及 `lpass-cdc` 自己现在是否已经把子链带到了可 probe 的状态。

```bash
adb shell 'ls /sys/bus/platform/devices | grep -i swr'
```

```bash
adb shell 'ls /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:lpass-cdc'
```

```bash
adb shell 'for l in /sys/devices/virtual/devlink/platform:soc:vote_lpass_audio_hw--platform:soc:spf_core_platform:lpass-cdc /sys/devices/virtual/devlink/platform:soc:vote_lpass_core_hw--platform:soc:spf_core_platform:lpass-cdc; do echo ===$l===; cat $l/status 2>/dev/null; done'
```

上游状态已经更清楚了：`lpass-cdc` 自身的关键 devlink 是 `active`，但它下面还是只长出了 `rx/tx/va macro` 和 codec，没有任何 `qcom,swr-mstr` 实例。这更像是父节点要重走一遍 child 枚举，而不是再补一个普通模块。

```bash
adb shell 'ls /sys/bus/platform/drivers/spf-core-platform'
```

```bash
adb shell 'ls /sys/bus/platform/drivers/lpass-cdc'
```

```bash
adb shell 'cat /sys/bus/platform/drivers_autoprobe'
```

`platform` 总线自动探测是开的，`spf-core-platform` 也确实有标准的 `bind/unbind` 接口，所以可以做一次真正有效的父节点重绑。

```bash
adb shell 'echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/unbind; sleep 1; echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/bind; sleep 3; echo ---; ls /sys/bus/platform/devices | grep -i swr; echo ---; ls /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:lpass-cdc; echo ---; cat /sys/kernel/debug/devices_deferred 2>/dev/null'
```

父节点重绑已经验证过了，但没有带出新的 `swr-mstr` 实例，也没有让 deferred 链消退。直接看这次重绑前后有没有新的内核日志。

```bash
adb shell 'dmesg | grep -i "spf_core_platform\|swr-mgr\|lpass-bt-swr\|qcom,swr-mstr\|rx-macro\|tx-macro\|va-macro" | tail -120'
```

```bash
adb shell 'for n in soc:spf_core_platform:rx_swr_clk_data_pinctrl soc:spf_core_platform:tx_swr_clk_data_pinctrl soc:spf_core_platform:bt_swr_clk_data_pinctrl soc:spf_core_platform:lpass_bt_swr@6CA0000 rx-macro tx-macro va-macro soc:spf_core_platform:sound; do echo ===$n===; [ -e /sys/bus/platform/devices/$n/waiting_for_supplier ] && cat /sys/bus/platform/devices/$n/waiting_for_supplier || echo no_wait; done'
```

```bash
adb shell 'for l in /sys/devices/virtual/devlink/platform:soc:spf_core_platform--platform:soc:spf_core_platform:sound /sys/devices/virtual/devlink/platform:soc:spf_core_platform--platform:soc:spf_core_platform:rx_swr_clk_data_pinctrl /sys/devices/virtual/devlink/platform:soc:spf_core_platform--platform:soc:spf_core_platform:tx_swr_clk_data_pinctrl /sys/devices/virtual/devlink/platform:soc:spf_core_platform--platform:soc:spf_core_platform:bt_swr_clk_data_pinctrl /sys/devices/virtual/devlink/platform:soc:spf_core_platform--platform:soc:spf_core_platform:lpass_bt_swr@6CA0000; do echo ===$l===; cat $l/status 2>/dev/null; done'
```

继续往更像根因的地方收，不重启设备。整条 deferred 链的共同特征很清楚：`waiting_for_supplier` 全都是 `0`，但 `spf_core_platform` 指向这些子节点的 devlink 仍然只是 `available`，不是 `active`。直接查最可疑的中间层 `lpi_pinctrl@07760000`。

```bash
adb shell 'echo ===lpi===; ls /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:lpi_pinctrl@07760000; echo ---; readlink /sys/bus/platform/devices/soc:spf_core_platform:lpi_pinctrl@07760000/driver 2>/dev/null || echo no_driver; echo ---; cat /sys/bus/platform/devices/soc:spf_core_platform:lpi_pinctrl@07760000/uevent 2>/dev/null'
```

```bash
adb shell 'for l in /sys/devices/virtual/devlink/platform:soc:spf_core_platform--platform:soc:spf_core_platform:lpi_pinctrl@07760000 /sys/devices/virtual/devlink/platform:soc:vote_lpass_audio_hw--platform:soc:spf_core_platform:lpi_pinctrl@07760000 /sys/devices/virtual/devlink/platform:soc:vote_lpass_core_hw--platform:soc:spf_core_platform:lpi_pinctrl@07760000; do echo ===$l===; cat $l/status 2>/dev/null; done'
```

```bash
adb shell 'cat /sys/kernel/debug/devices_deferred 2>/dev/null | grep -i lpi_pinctrl || echo none'
```

找到一个更像根因的中间节点了：`lpi_pinctrl@07760000` 本身存在、兼容串是 `qcom,lpi-pinctrl`，但现在根本没有绑定任何 driver。它不在 deferred 队列里，反而说明更像是"缺驱动或驱动未注册"。

```bash
adb shell 'ls /sys/bus/platform/drivers | grep -i lpi || echo none'
```

```bash
adb shell 'ls /vendor_dlkm/lib/modules | grep -i lpi || echo none; echo ---; ls /vendor_dlkm/lib/modules | grep -i pinctrl || echo none'
```

```bash
adb shell 'strings /vendor_dlkm/lib/modules/*.ko 2>/dev/null | grep -m 20 "qcom,lpi-pinctrl" || echo none'
```

根因候选已经非常强了：`qcom,lpi-pinctrl` 的驱动现在完全没注册，但模块文件 `pinctrl_lpi_dlkm.ko` 就在 `vendor_dlkm` 里，而且二进制里明确带了 `qcom,lpi-pinctrl` alias。这条链很可能只是被一个漏加载的 LPI pinctrl 模块卡住了。

```bash
adb shell 'insmod /vendor_dlkm/lib/modules/pinctrl_lpi_dlkm.ko 2>/dev/null || true; echo ---drv---; ls /sys/bus/platform/drivers | grep -i lpi || echo none; echo ---bind---; readlink /sys/bus/platform/devices/soc:spf_core_platform:lpi_pinctrl@07760000/driver 2>/dev/null || echo no_driver; echo ---defer---; cat /sys/kernel/debug/devices_deferred 2>/dev/null; echo ---swr---; ls /sys/bus/platform/devices | grep -i swr; echo ---cards---; cat /proc/asound/cards 2>/dev/null; echo ---snd---; ls /dev/snd 2>/dev/null'
```

**突破**：这个模块一补，链路发生了实质性变化：deferred 队列从一长串直接缩成只剩 `sound`，而且新的 SWR 设备实例已经出来了。

```bash
adb shell 'for n in rx-macro tx-macro va-macro soc:spf_core_platform:sound; do echo ===$n===; readlink /sys/bus/platform/devices/$n/driver 2>/dev/null || echo no_driver; done'
```

```bash
adb shell 'ls -l /sys/bus/platform/devices | grep -E "rx_swr_ctrl|va_swr_ctrl|bt_swr_mstr"; echo ---; readlink /sys/bus/platform/devices/rx_swr_ctrl/driver 2>/dev/null || echo no_rx_driver; readlink /sys/bus/platform/devices/va_swr_ctrl/driver 2>/dev/null || echo no_va_driver; readlink /sys/bus/platform/devices/bt_swr_mstr/driver 2>/dev/null || echo no_bt_driver'
```

```bash
adb shell 'ls -l /sys/bus/soundwire/devices 2>/dev/null | sed -n "1,120p"; echo ---; cat /sys/kernel/debug/devices_deferred 2>/dev/null'
```

现在已经非常接近了：`rx/tx/va macro` 都绑上了，deferred 队列只剩 `sound` 一个节点。新的 SWR 控制器子设备也已经被创建出来，但它们自己还没有 driver。

## 十七、SWR mgr 绑定——SoundWire 总线出现

```bash
adb shell 'for n in rx_swr_ctrl va_swr_ctrl bt_swr_mstr; do echo ===$n===; cat /sys/bus/platform/devices/$n/uevent 2>/dev/null; done'
```

```bash
adb shell 'for d in swr-mgr lpass-bt-swr; do echo ===$d===; ls -1 /sys/bus/platform/drivers/$d 2>/dev/null; done'
```

```bash
adb shell 'for n in rx_swr_ctrl va_swr_ctrl bt_swr_mstr; do echo ===$n===; cat /sys/bus/platform/devices/$n/modalias 2>/dev/null; done'
```

目标已经明确了：三个新子设备都是 `qcom,swr-mstr`，而对应 platform driver 就是 `swr-mgr`。`lpass-bt-swr` 父设备已经绑定成功了，所以现在直接把 `swr-mgr` 点到这三个子设备上，看它能不能把 soundwire 总线和最后的声卡 probe 带起来。

```bash
adb shell 'for n in rx_swr_ctrl va_swr_ctrl bt_swr_mstr; do echo swr-mgr > /sys/bus/platform/devices/$n/driver_override; echo $n > /sys/bus/platform/drivers_probe; done; sleep 3; echo ---drv---; for n in rx_swr_ctrl va_swr_ctrl bt_swr_mstr; do echo ===$n===; readlink /sys/bus/platform/devices/$n/driver 2>/dev/null || echo no_driver; done; echo ---sdw---; ls -l /sys/bus/soundwire/devices 2>/dev/null | sed -n "1,120p"; echo ---defer---; cat /sys/kernel/debug/devices_deferred 2>/dev/null; echo ---cards---; cat /proc/asound/cards 2>/dev/null; echo ---snd---; ls /dev/snd 2>/dev/null'
```

**突破**：`swr-mgr` 绑上以后，SoundWire 总线和 `wcd939x-slave` 都真实出现了。现在 deferred 队列仍只剩 `sound`，所以最后一步已经非常明确了，就是让 `sun-asoc-snd` 再 probe 一次。

```bash
adb shell 'echo sun-asoc-snd > /sys/bus/platform/devices/soc:spf_core_platform:sound/driver_override; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe; sleep 3; echo ---sound---; readlink /sys/bus/platform/devices/soc:spf_core_platform:sound/driver 2>/dev/null || echo no_driver; echo ---cards---; cat /proc/asound/cards 2>/dev/null; echo ---pcm---; cat /proc/asound/pcm 2>/dev/null; echo ---snd---; ls /dev/snd 2>/dev/null; echo ---defer---; cat /sys/kernel/debug/devices_deferred 2>/dev/null; echo ---dmesg---; dmesg | grep -i "sun-asoc-snd\|snd_soc_register_card\|asoc\|sound card" | tail -80'
```

SWR 和 codec slave 已经起来了，但 `sound` 还是单点 defer，这通常说明 machine card 还在等某个 DAI/codec endpoint。下一步我不再盲 probe，而是直接把 `sound` 节点引用的 codec 名称和当前实际枚举出的 slave 做对照，看看还缺哪一路。

```bash
adb shell 'echo ===codec-names===; strings /proc/device-tree/soc/spf_core_platform/sound/asoc-codec-names 2>/dev/null; echo ---; echo ===model===; strings /proc/device-tree/soc/spf_core_platform/sound/qcom,model 2>/dev/null'
```

```bash
adb shell 'find /proc/device-tree/soc/spf_core_platform -maxdepth 4 -iname "*wsa*" -o -iname "*wcd*" | sed -n "1,160p"'
```

```bash
adb shell 'ls -l /sys/bus/soundwire/devices 2>/dev/null | sed -n "1,160p"'
```

运行时 DT 里其实还存在一整套 `wsa-macro`、`wsa2-macro`、`wsa_swr_master`、`wsa2_swr_master` 和对应 pinctrl 节点。当前 sysfs 里这些 WSA 分支根本没被实例化出来，这很可能就是 `sound` 最后还在 defer 的原因。

## 十八、补齐 msm-stub-codec + WSA/CPU-AFE 排查

先排查 WSA 分支在 sysfs 和 DT 中的状态：

```bash
adb shell 'ls /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:lpass-cdc | grep -i wsa || echo none; echo ---; ls /sys/bus/platform/devices | grep -i wsa || echo none'
```

```bash
adb shell 'find /proc/device-tree/soc/spf_core_platform/lpass-cdc -maxdepth 2 -iname "*wsa*" | sed -n "1,120p"'
```

```bash
adb shell 'cat /sys/kernel/debug/devices_deferred 2>/dev/null | grep -i wsa || echo none'
```

WSA 这条分支在 DT 里完整存在，但 sysfs 里连设备实例都没有，而且也不在 deferred 队列。这和之前缺 `lpi-pinctrl` 时的表现很像，说明父节点是在更早阶段就没把它们创建出来。现在 `qcom-lpi-pinctrl` 已经补上，最合理的动作就是再重绑一次 `spf-core-platform`，看 WSA 子树会不会这次被补出来。

```bash
adb shell 'echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/unbind; sleep 1; echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/bind; sleep 4; echo ---lpass-cdc---; ls /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:lpass-cdc; echo ---wsa---; ls /sys/bus/platform/devices | grep -i wsa || echo none; echo ---swr---; ls /sys/bus/platform/devices | grep -i swr; echo ---sdw---; ls -l /sys/bus/soundwire/devices 2>/dev/null | sed -n "1,120p"; echo ---defer---; cat /sys/kernel/debug/devices_deferred 2>/dev/null; echo ---cards---; cat /proc/asound/cards 2>/dev/null; echo ---snd---; ls /dev/snd 2>/dev/null'
```

重绑之后结果很稳定：WSA 这条分支还是没被创建出来。转去把 `sound` 节点明确引用的三个 codec 端点逐个核掉。

```bash
adb shell 'ls /sys/bus/platform/devices | grep -i stub || echo none; echo ---; ls /sys/bus/platform/drivers | grep -i stub || echo none'
```

```bash
adb shell 'for n in soc:qcom,msm-stub-codec soc:qcom,msm-stub-codec.1 msm-stub-codec.1; do echo ===$n===; readlink /sys/bus/platform/devices/$n/driver 2>/dev/null || echo no_dev; done'
```

```bash
adb shell 'ls -l /sys/bus/platform/devices | grep -E "lpass-cdc|wcd939x|stub|sound" | sed -n "1,120p"'
```

新的可疑点有了：`sound` 节点引用 `msm-stub-codec.1`，而平台上虽然能看到 `soc:qcom,msm-stub-codec` 这个设备，但还没确认它有没有真的绑上对应 driver。这个点和 `sound` 直接相关，我先把它核实掉。

```bash
adb shell 'echo ===stubdev===; ls /sys/devices/platform/soc/soc:qcom,msm-stub-codec; echo ---; cat /sys/devices/platform/soc/soc:qcom,msm-stub-codec/uevent 2>/dev/null; echo ---; readlink /sys/devices/platform/soc/soc:qcom,msm-stub-codec/driver 2>/dev/null || echo no_driver'
```

```bash
adb shell 'ls /sys/bus/platform/drivers | grep -i "stub.*codec\|msm-stub\|snd.*dummy" || echo none'
```

```bash
adb shell 'strings /vendor_dlkm/lib/modules/*.ko 2>/dev/null | grep -m 20 -E "msm-stub-codec|qcom,msm-stub-codec" || echo none'
```

这个点很像最后缺口之一：`msm-stub-codec` 设备现在没有 driver，而工作区里的模块二进制又明确包含 `qcom,msm-stub-codec` 字符串。也就是说，不是 DT 没有，也不是设备没出来，而是 stub codec 驱动根本没注册。现在直接把对应 ko 找出来。

```bash
adb shell 'for f in /vendor_dlkm/lib/modules/*.ko; do strings $f 2>/dev/null | grep -q "qcom,msm-stub-codec" && echo $f; done'
```

```bash
adb shell 'cat /sys/devices/platform/soc/soc:qcom,msm-stub-codec/waiting_for_supplier 2>/dev/null || echo no_wait'
```

```bash
adb shell 'cat /sys/kernel/debug/devices_deferred 2>/dev/null | grep -i stub || echo none'
```

`stub_dlkm.ko` 已经定位到了，而且 `msm-stub-codec` 设备当前 `waiting_for_supplier` 也是 `0`。这和之前缺 `lpi-pinctrl` 的模式完全一致，说明它就是另一个“设备在、驱动没注册”的点。现在把这个模块补上，再看 `sound` 会不会直接收敛。

```bash
adb shell 'insmod /vendor_dlkm/lib/modules/stub_dlkm.ko 2>/dev/null || true; echo ---drv---; ls /sys/bus/platform/drivers | grep -i "stub.*codec\|msm-stub" || echo none; echo ---stub---; readlink /sys/devices/platform/soc/soc:qcom,msm-stub-codec/driver 2>/dev/null || echo no_driver; echo ---sound---; readlink /sys/bus/platform/devices/soc:spf_core_platform:sound/driver 2>/dev/null || echo no_driver; echo ---cards---; cat /proc/asound/cards 2>/dev/null; echo ---pcm---; cat /proc/asound/pcm 2>/dev/null; echo ---snd---; ls /dev/snd 2>/dev/null; echo ---defer---; cat /sys/kernel/debug/devices_deferred 2>/dev/null'
```

`msm-stub-codec` 已经绑上了，说明这个缺口也被补掉了。现在 `sound` 还是唯一剩下的 deferred 点，所以条件已经又齐了一层。我马上重新触发一次 `sun-asoc-snd`，这次如果还不起来，就说明最后缺的已经不是 stub codec 了。

```bash
adb shell 'echo sun-asoc-snd > /sys/bus/platform/devices/soc:spf_core_platform:sound/driver_override; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe; sleep 3; echo ---sound---; readlink /sys/bus/platform/devices/soc:spf_core_platform:sound/driver 2>/dev/null || echo no_driver; echo ---cards---; cat /proc/asound/cards 2>/dev/null; echo ---pcm---; cat /proc/asound/pcm 2>/dev/null; echo ---snd---; ls /dev/snd 2>/dev/null; echo ---defer---; cat /sys/kernel/debug/devices_deferred 2>/dev/null; echo ---dmesg---; dmesg | grep -i "sun-asoc-snd\|snd_soc_register_card\|sound card\|defer" | tail -80'
```

已经把 `lpi-pinctrl`、`swr-mgr`、`msm-stub-codec` 这些明显缺的驱动都补齐了，`sound` 还是单点 defer。直接看 ASoC debugfs 里的组件和 card 视图。

```bash
adb shell 'ls /sys/kernel/debug/asoc 2>/dev/null || echo none'
```

```bash
adb shell 'for f in /sys/kernel/debug/asoc/components /sys/kernel/debug/asoc/cards /sys/kernel/debug/asoc/dais; do echo ===$f===; [ -f $f ] && sed -n "1,200p" $f || echo missing; done'
```

```bash
adb shell 'find /sys/kernel/debug/asoc -maxdepth 2 -type f | sed -n "1,120p"'
```

我再做最后一组定性验证，不再碰现有已通的链。现在最像的剩余缺口是 WSA 分支，因为 ASoC 组件里只有 `msm-stub-codec`、`wcd939x-codec`、`lpass-cdc`，但没有任何 WSA 相关 component/DAI。我要确认这是不是 machine card 迟迟不注册的最后原因。

```bash
adb shell 'for d in lpass_cdc_wsa_macro lpass_cdc_wsa2_macro; do echo ===$d===; ls -1 /sys/bus/platform/drivers/$d 2>/dev/null || echo no_driver; done'
```

```bash
adb shell 'for m in lpass_cdc_wsa_macro_dlkm lpass_cdc_wsa2_macro_dlkm wsa883x_dlkm wsa884x_dlkm; do echo ===$m===; cat /sys/module/$m/initstate 2>/dev/null; cat /sys/module/$m/refcnt 2>/dev/null; done'
```

```bash
adb shell 'for f in /sys/kernel/debug/asoc/components /sys/kernel/debug/asoc/dais; do echo ===$f===; grep -i wsa $f 2>/dev/null || echo none; done'
```

WSA 这一支现在基本能判定是缺席的：驱动都在、模块都 live，但没有任何 WSA component/DAI，也没有设备实例。这和之前 `lpi-pinctrl`、`stub-codec` 未加载时的模式很像，只不过现在缺的不是 driver，而是节点实例化本身。最后我把 `wsa_swr_clk_data_pinctrl` 这组节点也核一下，确认它们是不是连 platform 设备都还没出现。

```bash
adb shell 'ls /sys/bus/platform/devices | grep -i "wsa.*swr\|wsa.*macro" || echo none'
```

```bash
adb shell 'for n in /proc/device-tree/soc/spf_core_platform/wsa_swr_clk_data_pinctrl /proc/device-tree/soc/spf_core_platform/wsa2_swr_clk_data_pinctrl; do echo ===$n===; ls $n 2>/dev/null | sort | sed -n "1,80p"; done'
```

```bash
adb shell 'cat /sys/kernel/debug/devices_deferred 2>/dev/null | grep -i wsa || echo none'
```

我继续只做低风险核验，不碰当前已经带起来的链。现在最值得确认的是：这些 `wsa*_swr_clk_data_pinctrl` 节点之所以完全不被实例化，会不会其实是 DT 里被标成了 `disabled`。这一步能直接解释为什么它们既不出现在 sysfs，也不进 deferred 队列。

```bash
adb shell 'for n in sec_i2s1_pinctrl wsa_swr_clk_data_pinctrl wsa2_swr_clk_data_pinctrl; do echo ===$n===; strings /proc/device-tree/soc/spf_core_platform/$n/status 2>/dev/null || echo no_status; done'
```

```bash
adb shell 'for n in wsa-macro@6B00000 wsa2-macro@6AA0000; do echo ===$n===; strings /proc/device-tree/soc/spf_core_platform/lpass-cdc/$n/status 2>/dev/null || echo no_status; done'
```

```bash
adb shell 'for n in rx-macro@6AC0000 va-macro@7660000; do echo ===$n===; strings /proc/device-tree/soc/spf_core_platform/lpass-cdc/$n/status 2>/dev/null || echo no_status; done'
```

WSA 这条线已经被解释清楚了：运行时 DT 里它们就是 `disabled`，所以它们没实例化不是新的 bug。那 `sound` 还在 defer，就更像是 machine card 还在等 CPU/AFE 这一侧的 component。直接核 ASoC 里有没有 Q6/AFE 侧 component 或 DAI。

```bash
adb shell 'echo ===components===; grep -i "q6\|afe\|audio_pkt\|prm\|spf" /sys/kernel/debug/asoc/components 2>/dev/null || echo none; echo ---; echo ===dais===; grep -i "q6\|afe\|mi2s\|tdm\|auxpcm\|slim\|bt" /sys/kernel/debug/asoc/dais 2>/dev/null || echo none'
```

```bash
adb shell 'ls /sys/bus/platform/devices | grep -i "q6\|afe\|audio-pkt\|prm\|spf" | sed -n "1,160p"'
```

```bash
adb shell 'ls /sys/bus/gprbus/devices 2>/dev/null | sed -n "1,120p"'
```

这个差异非常关键：GPR 侧已经有 `gprsvc:spf_core`、`audio-pkt`、`q6prm`，但 ASoC debugfs 里完全没有任何 Q6/AFE/CPU DAI 实体。也就是说，machine card 现在更像是在等“CPU 端声学接口组件”，不是再等 codec 端。下面我直接在模块和总线里找这类 CPU/AFE 驱动。

```bash
adb shell 'ls /vendor_dlkm/lib/modules | grep -i "q6\|afe\|lpaif\|mi2s\|tdm\|auxpcm\|audio" | sed -n "1,200p"'
```

```bash
adb shell 'lsmod | grep -i "q6\|afe\|audio_pkt\|prm\|spf\|snd_event" | sed -n "1,200p"'
```

```bash
adb shell 'strings /vendor_dlkm/lib/modules/*.ko 2>/dev/null | grep -m 40 -E "q6afe|afe-port|mi2s|tdm|auxpcm|lpaif"'
```

线索已经足够说明 `sound` 现在卡在 CPU/AFE 一侧，但我还需要把它落到具体模块。接下来我只做一件事：把含有 `q6afe/mi2s/tdm/auxpcm` 这些字符串的 ko 文件名找出来，确认到底是谁应该提供 CPU DAI。

```bash
adb shell 'for f in /vendor_dlkm/lib/modules/*.ko; do strings $f 2>/dev/null | grep -q "q6afe" && echo q6afe:$f; done'
```

```bash
adb shell 'for f in /vendor_dlkm/lib/modules/*.ko; do strings $f 2>/dev/null | grep -q "pri_mi2s_tx_cpus" && echo mi2s:$f; done'
```

```bash
adb shell 'for f in /vendor_dlkm/lib/modules/*.ko; do strings $f 2>/dev/null | grep -q "auxpcm_tx_cpus" && echo auxpcm:$f; done'
```

现在可以确认一件事：`mi2s`、`auxpcm` 这些 CPU 接口描述都在 `machine_dlkm.ko` 里，不是在别的独立 AFE ko 里。也就是说，`sound` 最后 defer 不是“单纯少一个明显的 q6afe 模块文件”。我再把 `/vendor/lib/modules` 和 `/system/lib/modules` 也扫一遍，排掉遗漏路径。

```bash
adb shell 'for dir in /vendor/lib/modules /system/lib/modules; do echo ===$dir===; ls $dir 2>/dev/null | grep -i "q6\|afe\|audio\|lpaif" | sed -n "1,120p"; done'
```

```bash
adb shell 'for dir in /vendor/lib/modules /system/lib/modules; do for f in $dir/*.ko; do strings $f 2>/dev/null | grep -q "q6afe" && echo q6afe:$f; done; done'
```

```bash
adb shell 'for dir in /vendor/lib/modules /system/lib/modules; do for f in $dir/*.ko; do strings $f 2>/dev/null | grep -q "msm-stub-codec" && echo stub:$f; done; done'
```

当前 recovery 里已经把 codec、SWR、stub codec 都补到位了，剩下的差异明显落到 CPU/AFE 一侧。继续在 recovery 里盲试收益已经很低，下一步最有价值的是抓一份正常系统的 ASoC/SWR 视图做对照。我先把设备临时重启到正常系统，拿到最小对照集，再决定要不要回 recovery。

## 十九、正常系统对照

```bash
adb reboot
```

```bash
adb wait-for-device && adb shell getprop sys.boot_completed
```

```bash
adb devices
```

```bash
adb wait-for-device && adb shell 'until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 2; done; echo ready'
```

正常系统已经起来了。抓一组最小对照：ASoC 组件和 DAI、soundwire 设备，以及 recovery 里明显缺的 CPU/AFE 侧实体。

```bash
adb shell 'echo ===components===; sed -n "1,200p" /sys/kernel/debug/asoc/components 2>/dev/null; echo ---; echo ===dais===; sed -n "1,240p" /sys/kernel/debug/asoc/dais 2>/dev/null; echo ---; echo ===cards===; ls /sys/kernel/debug/asoc/cards 2>/dev/null || echo no_cards'
```

```bash
adb shell 'echo ===soundwire===; ls -l /sys/bus/soundwire/devices 2>/dev/null | sed -n "1,240p"; echo ---; echo ===snd===; ls /dev/snd 2>/dev/null; echo ---; cat /proc/asound/cards 2>/dev/null; echo ---; cat /proc/asound/pcm 2>/dev/null'
```

```bash
adb shell 'echo ===platform===; ls /sys/bus/platform/devices | grep -i "wsa\|swr\|q6\|afe\|spf\|stub\|lpass-cdc\|sound" | sed -n "1,240p"; echo ---; echo ===gpr===; ls /sys/bus/gprbus/devices 2>/dev/null | sed -n "1,120p"'
```

正常系统的关键对照已经给了一个很重要的结论：SoundWire 设备集合和 recovery 现在几乎一致，但系统里已经有完整 `/dev/snd`。所以差异进一步收敛到 `sun-asoc-snd` 最终 card 注册，而不是 SWR 子设备本身。现在我直接核系统里 `sound` 设备有没有绑上 `sun-asoc-snd`。

```bash
adb shell 'readlink /sys/bus/platform/devices/soc:spf_core_platform:sound/driver 2>/dev/null || echo no_driver; echo ---; ls /sys/bus/platform/drivers/sun-asoc-snd 2>/dev/null'
```

```bash
adb shell 'for n in rx-macro tx-macro va-macro soc:qcom,msm-stub-codec soc:spf_core_platform:lpass-cdc; do echo ===$n===; readlink /sys/bus/platform/devices/$n/driver 2>/dev/null || echo no_driver; done'
```

```bash
adb shell 'for n in soc:spf_core_platform:sound rx_swr_ctrl va_swr_ctrl bt_swr_mstr; do echo ===$n===; cat /sys/bus/platform/devices/$n/modalias 2>/dev/null; done'
```

对照现在已经很干净了：正常系统里，`rx/tx/va macro`、`lpass-cdc`、`msm-stub-codec` 这些绑定状态和 recovery 手工 bring-up 后已经一致，真正差的只剩一条：系统里 `soc:spf_core_platform:sound` 已经绑到 `sun-asoc-snd`，recovery 里没有。再抓一组系统侧 devlink 状态。

```bash
adb shell 'for l in /sys/devices/virtual/devlink/platform:soc:spf_core_platform--platform:soc:spf_core_platform:sound /sys/devices/virtual/devlink/platform:soc:spf_core_platform--platform:soc:spf_core_platform:rx_swr_clk_data_pinctrl /sys/devices/virtual/devlink/platform:soc:spf_core_platform--platform:soc:spf_core_platform:tx_swr_clk_data_pinctrl /sys/devices/virtual/devlink/platform:soc:spf_core_platform--platform:soc:spf_core_platform:bt_swr_clk_data_pinctrl /sys/devices/virtual/devlink/platform:soc:spf_core_platform--platform:soc:spf_core_platform:lpass_bt_swr@6CA0000 /sys/devices/virtual/devlink/platform:soc:spf_core_platform--platform:soc:spf_core_platform:lpi_pinctrl@07760000; do echo ===$l===; cat $l/status 2>/dev/null; done'
```

```bash
adb shell 'for l in /sys/devices/virtual/devlink/platform:soc:vote_lpass_audio_hw--platform:soc:spf_core_platform:lpass-cdc /sys/devices/virtual/devlink/platform:soc:vote_lpass_core_hw--platform:soc:spf_core_platform:lpass-cdc /sys/devices/virtual/devlink/platform:soc:vote_lpass_audio_hw--platform:soc:spf_core_platform:lpi_pinctrl@07760000 /sys/devices/virtual/devlink/platform:soc:vote_lpass_core_hw--platform:soc:spf_core_platform:lpi_pinctrl@07760000; do echo ===$l===; cat $l/status 2>/dev/null; done'
```

```bash
adb shell 'for n in soc:spf_core_platform:sound soc:spf_core_platform:lpi_pinctrl@07760000 soc:spf_core_platform:lpass_bt_swr@6CA0000 soc:spf_core_platform:rx_swr_clk_data_pinctrl; do echo ===$n===; [ -e /sys/bus/platform/devices/$n/waiting_for_supplier ] && cat /sys/bus/platform/devices/$n/waiting_for_supplier || echo no_wait; done'
```

拿到正常系统对照后，下一步不是继续看系统，而是把这些新结论带回 recovery 复试一次更合理的加载顺序：`lpi-pinctrl` 和 `stub codec` 提前，随后再上 `machine`。如果 `sun-asoc-snd` 只是因为前面时序太早被卡住，这次有机会直接把 card 带出来。

## 最终状态总结

**已打通部分**：

1. recovery 镜像侧 VINTF manifest 已修好，`audio-hal`、`adsprpcd`、`audioadsprpcd` 都能稳定运行
2. 真实 vendor/odm 运行时嫁接成功
3. 内核音频模块链完整加载，`/dev/aud_pasthru_adsp` 出现
4. 经过 LPI pinctrl 补加载后，`sound` 子设备已枚举出来
5. SWR/SoundWire 总线打通，`wcd939x-slave` 出现
6. `msm-stub-codec` 驱动已补齐绑定
7. `rx/tx/va macro` 全部绑定 driver

**最后未打通的一层**：
- `soc:spf_core_platform:sound` 设备仍 deferred，未被 `sun-asoc-snd` 接管
- `/dev/snd` 只有 `timer`，`/proc/asound/cards` 仍空
- ASoC debugfs 中无 Q6/AFE/CPU DAI 实体
- 正常系统对照中唯一显著差异是 `sound → sun-asoc-snd` 绑定状态

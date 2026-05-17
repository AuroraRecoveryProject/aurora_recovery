# infiniti Recovery WiFi 手动启动全流程（设备 OEM wpa_supplicant 路线）

**设备：** infiniti (OP60FFL1)，TWRP recovery 模式
**平台：** Snapdragon 8 Elite (pineapple)，WiFi 芯片 QCA PCIe
**目标：** 使用设备自身的 WiFi 驱动、OEM `wpa_supplicant`、OEM `wpa_supplicant.conf` 跑通扫描、关联、DHCP、外网连通
**TWRP 设备树：** <https://github.com/koaaN/twrp_device_oplus_infiniti>
**实测结果：** `wpa_cli ping`、`scan`、`scan_results`、`wpa_state=COMPLETED`、DHCP、`ping 223.5.5.5` 全部成功

---

## qrtr_ns 在默认的 TWRP 中已经运行，不知道是哪儿拉起来的

> 高通 IPC（QRTR）体系里的“服务注册与发现中心”，负责把 QMI 服务从“找不到”变成“可动态定位”。

```bash
adb shell ps -A | grep -E "qrtr|wpa_supplicant|cnss"

➜  ~ adb shell ps -A | grep -E "qrtr|wpa_supplicant|cnss"
root           245     2          0      0 kthread_worker_fn   0 S [qrtr_ns]
root           422     2          0      0 kthread_worker_fn   0 S [qrtr_rx]
```

**自编译好像不需要qrtr-ns这些东西，注意这个是qrtr_ns，下文是qrtr-ns**

## 这份流程和自编译路线的区别

这份文档**不是**自编译 `wpa_supplicant` 的流程，而是使用设备 OEM `wpa_supplicant` 的流程。

和自编译路线相比，额外要处理 4 类问题：

1. OEM `wpa_supplicant` 依赖 AIDL / keystore / keymint 相关 so
2. `servicemanager` 必须在 `/vendor` 卸载后重新扫描 VINTF
3. `odm/etc/vintf/manifest/network_manifest.xml` 的坏链需要绕过
4. 运行时库顺序要避免旧版 `vendor/libbinder.so` 抢先被加载
5. 将相关文件复制到临时的 oem 文件夹，以验证最小启动依赖

---

## 整体流程概览

```text
挂载分区
→ 复制 WCNSS_qcom_cfg.ini
→ insmod CNSS 基础模块
→ 触发固件下载 (写 fs_ready 1)
→ insmod 无线驱动（需要等待 fs_ready）
→ 确认 wlan0 出现
→ 暂存 OEM wpa_supplicant / conf / so / VINTF
→ （可选）启动 qrtr-ns / cnss-daemon
→ umount /vendor
→ 替换 odm manifest 目录并恢复 vendor supplicant VINTF
→ 重启 servicemanager
→ 以 OEM 二进制启动 wpa_supplicant
→ 扫描/连接 AP（wpa_cli scan / scan_results / connect）
→ dhcpcd 获取 IP
→ ping 验证
```

---

## 前提说明

本流程中，以下内容使用设备自身文件：

1. `/vendor/bin/hw/wpa_supplicant`
2. `/vendor/etc/wifi/wpa_supplicant.conf`
3. `/vendor/lib64/` 下 WiFi / keystore 相关 so
4. `/vendor/etc/vintf/manifest/android.hardware.wifi.supplicant.xml`
5. `/odm/etc/vintf/manifest/oplus_aidl_wifi_service_device_manifest.xml`
6. 所有 `.ko` 和 `WCNSS_qcom_cfg.ini`

本流程里仍可能临时补 2 类工具文件：

1. `wpa_cli`：如果当前 recovery 没带命令，可临时 push 一个匹配设备版本的提取副本
2. `dhcpcd`：如果当前 recovery 没带命令，可临时 push 一个可用副本

---

## Step 0：确认设备连接

```bash
# adb devices
List of devices attached
70a91f89    recovery
export ANDROID_SERIAL=70a91f89
```

> 确认设备处于 recovery 模式且 adb 可用。recovery 启动后 `/tmp` 是空的（tmpfs，重启清空），
> 各分区默认只挂载了 `/`、`/system`、`/data`，WiFi 相关的 vendor 分区尚未挂载。

## Step 1：挂载必要分区

Recovery 启动后大部分 vendor 分区未挂载，而 WiFi 内核模块（`.ko` 文件）分散在
`vendor_dlkm`、`system_dlkm`、`vendor`、`odm` 四个分区中，必须先全部挂载。

```bash
# 挂载四个分区（odm 通常已挂载，报 busy 属正常）
adb shell "mount /vendor_dlkm && mount /system_dlkm"
adb shell "mount /vendor && mount /odm"

# 检查已挂载状态
adb shell "mount | grep -E 'vendor_dlkm|system_dlkm'"
```

> - **`vendor_dlkm`**：存放大部分 WiFi 相关 `.ko`（cnss2、cfg80211、qca_cld3_peach_v2 等）
> - **`system_dlkm`**：存放 `rfkill.ko`（Linux 无线电源管理框架）
> - **`vendor`**：存放 WiFi 固件文件（`amss.bin` 等）及备用 WCNSS 配置
> - **`odm`**：存放设备专用的 `WCNSS_qcom_cfg.ini`（odm 优先级高于 vendor）

---

## Step 2：找到并复制 WCNSS 配置文件

`WCNSS_qcom_cfg.ini` 是 QCA WiFi 芯片的射频/校准配置文件，`cnss2` 驱动加载后必须能从
`/data/vendor/firmware/update/wlan/` 读取到该文件，否则固件下载会失败。

```bash
# 查找所有位置（同一设备可能有多个平台配置并存）
adb shell "find /vendor /odm -name 'WCNSS_qcom_cfg.ini' 2>/dev/null"
```

实际输出（ossi 上有 4 处）：

```bash
# Oplus Pad2 Pro
/vendor/etc/wifi/kiwi_v2/WCNSS_qcom_cfg.ini    # kiwi_v2 平台（不适用）
/vendor/etc/wifi/peach/WCNSS_qcom_cfg.ini      # peach 平台通用版
/vendor/etc/wifi/peach_v2/WCNSS_qcom_cfg.ini   # peach_v2 平台通用版
/odm/vendor/etc/wifi/WCNSS_qcom_cfg.ini        # odm 设备定制版（优先使用）

# Oplus 15(Infiniti)
/vendor/etc/wifi/kiwi_v2/WCNSS_qcom_cfg.ini
/vendor/etc/wifi/peach_v2/WCNSS_qcom_cfg.ini
/vendor/etc/wifi/wcn7750/WCNSS_qcom_cfg.ini
/odm/vendor/etc/wifi/WCNSS_qcom_cfg.ini
```

选择 odm 版本（设备特定校准数据最准确）并复制到固件目录：

> 实际上 twrp_device_oplus_sm86xx/twrp_device_xiaomi_sm8750_thales 用的都是 /vendor/etc/wifi/peach_v2/WCNSS_qcom_cfg.ini

```bash
adb shell "mkdir -p /data/vendor/firmware/update/wlan && \
    cp /odm/vendor/etc/wifi/WCNSS_qcom_cfg.ini /data/vendor/firmware/update/wlan/"
```

> **为什么是 odm 优先？** odm 分区存放厂商（一加）对本机型的定制配置，包含该批次硬件的
> 实测射频校准参数，比 vendor 中的平台通用版更精确。

---

## Step 3：加载 CNSS 基础内核模块

这些模块是 Qualcomm CNSS（Connectivity Sub-System）框架的基础层，必须按依赖顺序加载，
cnss2 主驱动最后加载。

```bash
# smem-mailbox：共享内存邮箱，用于 AP ↔ modem/WiFi 核间通信（来自 /tmp，recovery ramdisk 内）
# cnss_prealloc：提前为 WiFi 固件预分配大块连续内存，避免运行时分配失败
# cnss_utils：CNSS 工具函数库，提供 wlan_utils API（被 cnss2 依赖）
# cnss_plat_ipc_qmi_svc：CNSS 平台 IPC QMI 服务，用于内核与用户空间（cnss-daemon）的 QMI 通信
# cnss_nl：CNSS Netlink 接口，用于内核向用户空间广播 WiFi 事件
# wlan_firmware_service：处理固件下载请求，从 /vendor/firmware/ 读取 amss.bin 等固件文件
# cnss2：CNSS 主驱动，管理 PCIe 上的 QCA WiFi 芯片（枚举设备、上下电、固件加载流程控制）
smem_mailbox=/tmp/vendor/lib/modules/smem-mailbox.ko
cnss_prealloc=/vendor_dlkm/lib/modules/cnss_prealloc.ko
cnss_utils=/vendor_dlkm/lib/modules/cnss_utils.ko
cnss_plat_ipc_qmi_svc=/vendor_dlkm/lib/modules/cnss_plat_ipc_qmi_svc.ko
cnss_nl=/vendor_dlkm/lib/modules/cnss_nl.ko
wlan_firmware_service=/vendor_dlkm/lib/modules/wlan_firmware_service.ko
cnss2=/vendor_dlkm/lib/modules/cnss2.ko
# rfkill：Linux 无线电源管理框架，管理 WiFi/BT 的软件 kill 开关（来自 system_dlkm）
# cfg80211：Linux 802.11 配置框架，是所有无线驱动与 nl80211/wpa_supplicant 之间的标准接口层
# gsim：QCA Generic Simulation 模块（依赖项，被 qca_cld3 引用）
# rmnet_mem：RmNet 数据路径内存池（移动数据用，WiFi 场景下作为依赖项被加载）
# ipam：IP Address Management 模块（QCA 自定义 IP 管理，被 qca_cld3 依赖）
# qca_cld3_peach_v2：QCA WiFi 主驱动（CLD3 = CNSS Linux Driver v3），peach_v2 为 ossi 对应变体
# 加载后创建 wlan0 网络接口
rfkill=/system_dlkm/lib/modules/rfkill.ko
cfg80211=/vendor_dlkm/lib/modules/cfg80211.ko
gsim=/vendor_dlkm/lib/modules/gsim.ko
rmnet_mem=/vendor_dlkm/lib/modules/rmnet_mem.ko
ipam=/vendor_dlkm/lib/modules/ipam.ko
qca_cld3=/vendor_dlkm/lib/modules/qca_cld3_peach_v2.ko

mods=(
    "$smem_mailbox"
    "$cnss_prealloc"
    "$cnss_utils"
    "$cnss_plat_ipc_qmi_svc"
    "$cnss_nl"
    "$wlan_firmware_service"
    "$cnss2"
    "$rfkill"
    "$cfg80211"
    "$gsim"
    "$rmnet_mem"
    "$ipam"
)

# adb shell "ls /sys/bus/platform/drivers/cnss2/"
for m in "${mods[@]}"; do
    adb shell "insmod $m && echo $(basename $m) OK"
done
adb shell "ls /sys/bus/platform/drivers/cnss2/"

# adb shell "insmod $qca_cld3 && echo $(basename $qca_cld3) OK"
```

[How to enable WLAN in recovery? dhcpcd binary missing in Android 14+ builds](https://github.com/TWRP-Test/android_bootable_recovery/issues/14) 中提到的两个设备树

- [twrp_device_oplus_sm86xx/recovery/root/init.recovery.wifi.rc](https://github.com/adontoo/twrp_device_oplus_sm86xx/blob/81061909b76fc6dac1a1ae5c3ddb04b1d4a3e027/recovery/root/init.recovery.wifi.rc#L114)
- [twrp_device_xiaomi_sm8750_thales/recovery/root/init.recovery.wifi.rc](https://github.com/adontoo/twrp_device_xiaomi_sm8750_thales/blob/115f3a5b8e55dc09c44e097043ee135252d6ed7e/recovery/root/init.recovery.wifi.rc#L172)

都是先写 fs_ready 1 触发固件下载，再 insmod qca_cld3_peach_v2.ko

但在实际测试一加15的时候，可以先加载完所有的驱动模块（包括 qca_cld3_peach_v2.ko），等到最后再写 fs_ready 1 触发固件下载，wlan0 仍然能正常出现。

> **依赖关系：**
> smem-mailbox → cnss_prealloc → cnss_utils → cnss_plat_ipc_qmi_svc → cnss_nl → wlan_firmware_service → cnss2
> 顺序不能颠倒，否则 insmod 报符号未定义错误。

---

## Step 4：等待 fs_ready sysfs 节点并触发固件下载

cnss2 加载后会枚举 PCIe 设备，在 sysfs 中注册平台设备节点。`fs_ready` 是一个"握手"机制：
cnss2 等待用户空间写入 `1`，表示文件系统已就绪（固件文件可访问），然后才开始从磁盘加载固件到芯片。

### 确认 sysfs 节点已出现（cnss2 注册成功的标志）

```bash
adb shell "ls /sys/bus/platform/drivers/cnss2/"
```

```bash
# 期望输出（包含设备节点名 `b0000000.qcom,cnss-peach`）：

# Oplus Pad2 Pro
b0000000.qcom,cnss-peach
bind
cnss_debug
device_id
firmware_ready
module
uevent
unbind

# Oplus 15(Infiniti)
b0000000.qcom,cnss-peach
bind
cnss_debug
device_id
firmware_ready
module
soc:qcom,cnss-direct-link
uevent
unbind
```

### 触发固件下载

```bash
# chmod 222：赋予写权限（fs_ready 默认无写权限）
# echo 1：通知 cnss2"文件系统已就绪，请开始加载固件"
adb shell "chmod 222 /sys/bus/platform/drivers/cnss2/b0000000.qcom,cnss-peach/fs_ready && echo OK"
adb shell "echo 1 > /sys/bus/platform/drivers/cnss2/b0000000.qcom,cnss-peach/fs_ready && echo OK"
```

> **为什么需要这个步骤？**
> Recovery 环境中 cnss2 不能假设固件文件一定可读（分区可能未挂载）。
> `fs_ready` 令 cnss2 等待外部确认后再触发 `request_firmware()`，避免在文件系统就绪前就去读
> `amss.bin` 失败。固件下载完成后 `firmware_ready` 节点会变为 `1`。

---

## Step 5：加载无线驱动模块

固件开始上传后（cnss2 已初始化），加载 Linux 无线子系统和 QCA 驱动：

验证过这个驱动加载后，`adb shell "ifconfig wlan0"` 才能看到 `wlan0` 设备出现

```bash
# qca_cld3_peach_v2：QCA WiFi 主驱动（CLD3 = CNSS Linux Driver v3），peach_v2 为 ossi 对应变体
qca_cld3=/vendor_dlkm/lib/modules/qca_cld3_peach_v2.ko
adb shell "insmod $qca_cld3 && echo $(basename $qca_cld3) OK"
```

> `qca_cld3_peach_v2.ko` 是实际的 WiFi 驱动，加载后内核会：
>
> 1. 通过 cnss2 确认固件已上传到芯片
> 2. 初始化 PCIe DMA 通道
> 3. 向 cfg80211 注册 `wlan0` 网络设备

---

## Step 6：确认 wlan0 接口出现

> 这一步需要等待一会

```bash
adb shell "ifconfig wlan0"
```

期望输出：

```bash
# Oplus Pad2 Pro/Oplus 15 都类似
wlan0     Link encap:Ethernet  HWaddr 00:03:7f:12:23:86  Driver cnss_pci
          BROADCAST MULTICAST  MTU:1500  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0 
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0 
          collisions:0 txqueuelen:3000 
          RX bytes:0 TX bytes:0
          
```

> `HWaddr 00:03:7f:12:a3:9e` 是从芯片 NVS（Non-Volatile Storage）读取的固定 MAC 地址。
> 此时接口处于 `BROADCAST MULTICAST` 状态（未 UP），需要 wpa_supplicant 将其 UP 并关联 AP。

---

## Step 7：暂存 OEM 用户态文件

这一步的目的，是为了后面 `umount /vendor` 后，OEM `wpa_supplicant`、依赖 so 和 VINTF XML 仍然可用。

### 7.1 复制 OEM 二进制和配置和 `wpa_supplicant` 依赖 so

`adb shell readelf -d /vendor/bin/hw/wpa_supplicant` 输出：

```bash
0x0000000000000001 (NEEDED)             Shared library: [vendor.qti.hardware.wifi.supplicant-V1-ndk.so]
0x0000000000000001 (NEEDED)             Shared library: [libc.so]
0x0000000000000001 (NEEDED)             Shared library: [libcrypto.so]
0x0000000000000001 (NEEDED)             Shared library: [libcutils.so]
0x0000000000000001 (NEEDED)             Shared library: [libkeystore-engine-wifi-hidl.so]
0x0000000000000001 (NEEDED)             Shared library: [liblog.so]
0x0000000000000001 (NEEDED)             Shared library: [libnl.so]
0x0000000000000001 (NEEDED)             Shared library: [libssl.so]
0x0000000000000001 (NEEDED)             Shared library: [libcert_parse.wpa_s.so]
0x0000000000000001 (NEEDED)             Shared library: [vendor.oplus.hardware.wifi.supplicant-V5-ndk.so]
0x0000000000000001 (NEEDED)             Shared library: [android.hardware.wifi.supplicant-V4-ndk.so]
0x0000000000000001 (NEEDED)             Shared library: [android.system.keystore2-V1-ndk.so]
0x0000000000000001 (NEEDED)             Shared library: [libbase.so]
0x0000000000000001 (NEEDED)             Shared library: [libbinder_ndk.so]
0x0000000000000001 (NEEDED)             Shared library: [libutils.so]
0x0000000000000001 (NEEDED)             Shared library: [libc++.so]
0x0000000000000001 (NEEDED)             Shared library: [libm.so]
0x0000000000000001 (NEEDED)             Shared library: [libdl.so]
```

```bash
adb shell "mkdir -p /tmp/oem/bin /tmp/oem/lib64 /tmp/oem/vintf /tmp/odm_manifest"
adb shell cp /vendor/bin/hw/wpa_supplicant /tmp/oem/bin/
adb shell cp /vendor/bin/wpa_cli /tmp/oem/bin/
adb shell cp /vendor/etc/wifi/wpa_supplicant.conf /tmp/oem/
adb shell cp /vendor/etc/vintf/manifest/android.hardware.wifi.supplicant.xml /tmp/oem/vintf/
adb shell cp /odm/etc/vintf/manifest/oplus_aidl_wifi_service_device_manifest.xml /tmp/odm_manifest/
# 复制 so 库
adb shell "cp /vendor/lib64/vendor.qti.hardware.wifi.supplicant-V1-ndk.so /tmp/oem/lib64/"
adb shell "cp /vendor/lib64/libkeystore-engine-wifi-hidl.so /tmp/oem/lib64/"
adb shell "cp /vendor/lib64/vendor.oplus.hardware.wifi.supplicant-V5-ndk.so /tmp/oem/lib64/"
adb shell "cp /vendor/lib64/libcert_parse.wpa_s.so /tmp/oem/lib64/"
adb shell "cp /vendor/lib64/android.hardware.wifi.supplicant-V4-ndk.so /tmp/oem/lib64/"
# android.hardware.security.keymint-V1-ndk.so <- android.system.keystore2-V1-ndk.so
adb shell "cp /vendor/lib64/android.hardware.security.keymint-V1-ndk.so /tmp/oem/lib64/"
# android.hardware.security.secureclock-V1-ndk.so <- android.system.keystore2-V1-ndk.so
adb shell "cp /vendor/lib64/android.hardware.security.secureclock-V1-ndk.so /tmp/oem/lib64/"
adb shell "cp /vendor/lib64/android.system.keystore2-V1-ndk.so /tmp/oem/lib64/"
# android.hardware.wifi.common-V2-ndk.so <- android.hardware.wifi.supplicant-V4-ndk.so
adb shell "cp /vendor/lib64/android.hardware.wifi.common-V2-ndk.so /tmp/oem/lib64/"
```

## Step 8：启动 qrtr-ns / cnss-daemon（当前实测可选）

当前阶段结论：

1. 在本次 `infinti` recovery 手工 OEM 路线实测中，**不启动** `qrtr-ns` 和 `cnss-daemon`，`wlan0` 仍可正常出现
2. 在同一轮对照测试中，**不启动**这两个进程，OEM `wpa_supplicant` 仍可成功启动
3. `wpa_cli ping`、`scan`、`scan_results` 在**不启动**这两个进程的前提下仍然成功
4. 因此，至少在“拉起 OEM `wpa_supplicant` 并完成扫描”这一阶段，它们**不是当前实测必需项**

但这里暂时只下到“当前实测可选”的结论，不写成绝对规则，原因是：

1. 这轮对照主要验证到了 `wpa_supplicant` 启动和扫描阶段
2. 若后续发现某些设备、固件版本或更深的连接场景依赖它们，再单独修正文档

```bash
adb shell '/vendor/bin/qrtr-ns -f >/tmp/qrtr.log 2>&1 &'
adb shell '/vendor/bin/cnss-daemon -n -l >/tmp/cnss.log 2>&1 &'
adb shell "ps -A | grep -E 'qrtr-ns|cnss-daemon'"
```

如果你只想验证 OEM `wpa_supplicant` 能否起来、`wpa_cli ping` 是否成功、以及扫描是否工作，这一步可以先跳过。

---

## Step 9：修复 VINTF 视图

```bash
# 生成最小 `network_manifest.xml`
adb shell 'printf "<manifest version=\"1.0\" type=\"device\"></manifest>\n" > /tmp/odm_manifest/network_manifest.xml'
# 卸载真实 `/vendor`，来验证目前已经可以脱离 vendor 使用 WLAN 了
adb shell umount -l /vendor
# 用干净目录替换 `odm` manifest 目录
adb shell mount -o bind /tmp/odm_manifest /odm/etc/vintf/manifest
# 在当前 ramdisk `/vendor` 视图中恢复 supplicant VINTF
adb shell mkdir -p /vendor/etc/vintf/manifest
adb shell cp /tmp/oem/vintf/android.hardware.wifi.supplicant.xml /vendor/etc/vintf/manifest/
```

### 9.1 重启 `servicemanager`（**必须**）

```bash
# stop servicemanager 后，wpa_supplicant 进程能常驻，但是 /tmp/recovery/sockets 下无节点
adb shell stop servicemanager
# start 后，/tmp/recovery/sockets 下节点出来
adb shell start servicemanager
adb shell logcat -c
adb shell logcat -d | grep -i 'servicemanager\|supplicant\|vintf'
adb shell dmesg -C
adb shell dmesg | grep -i 'servicemanager\|supplicant\|vintf'
```

输出

```bash
05-17 06:31:18.401  1184  1184 I servicemanager: type=1400 audit(0.0:8763): avc:  denied  { read } for  name="network_manifest.xml" dev="tmpfs" ino=476 scontext=u:r:recovery:s0 tcontext=u:object_r:appdomain_tmpfs:s0 tclass=file permissive=1
05-17 06:31:18.401  1184  1184 I servicemanager: type=1400 audit(0.0:8764): avc:  denied  { open } for  path="/odm/etc/vintf/manifest/network_manifest.xml" dev="tmpfs" ino=476 scontext=u:r:recovery:s0 tcontext=u:object_r:appdomain_tmpfs:s0 tclass=file permissive=1
05-17 06:31:18.401  1184  1184 I servicemanager: type=1400 audit(0.0:8765): avc:  denied  { getattr } for  path="/odm/etc/vintf/manifest/network_manifest.xml" dev="tmpfs" ino=476 scontext=u:r:recovery:s0 tcontext=u:object_r:appdomain_tmpfs:s0 tclass=file permissive=1
```

---

## Step 10: 启动 OEM wpa_supplicant

### 10.1 为什么 `LD_LIBRARY_PATH` 要让 `/system/lib64` 在前

如果让 `/vendor/lib64` 抢先，有概率先加载旧版 `libbinder.so`，出现类似错误：

```bash
CANNOT LINK EXECUTABLE ... referenced by /system/lib64/libbinder_ndk.so
```

所以这里使用：

```bash
LD_LIBRARY_PATH=/system/lib64:/tmp/oem/lib64
```

### 10.2 启动命令

```bash
adb shell 'mkdir -p /tmp/recovery/sockets'
adb shell "rm -f  /tmp/oem_wpa.log"
adb shell 'LD_LIBRARY_PATH=/system/lib64:/tmp/oem/lib64 /tmp/oem/bin/wpa_supplicant -iwlan0 -Dnl80211 -c/tmp/oem/wpa_supplicant.conf -O/tmp/recovery/sockets -dd >/tmp/oem_wpa.log 2>&1 &'
adb shell "ps -A | grep wpa_supplicant"
adb shell "ls -l /tmp/recovery/sockets"
# 这个下也有节点，但是经过测试是无法使用的
adb shell "ls -l /data/misc/wifi/wpa_supplicant"
```

期望出现：

1. `wpa_supplicant` 进程驻留
2. `/tmp/recovery/sockets/wlan0` socket 出现

---

## Step 11：用 wpa_cli 验证控制面

### 11.1 最小探活

```bash
adb shell /tmp/oem/bin/wpa_cli -p /tmp/recovery/sockets -i wlan0 ping
# 期望输出：
PONG
```

### 11.2 扫描可用 WiFi

```bash
WPA_CLI="/tmp/oem/bin/wpa_cli"
CRL_SOCKETS="/tmp/recovery/sockets"
# CRL_SOCKETS=/data/misc/wifi/wpa_supplicant 
adb shell "$WPA_CLI -p $CRL_SOCKETS -i wlan0 scan"
adb shell "$WPA_CLI -p $CRL_SOCKETS -i wlan0 scan_results"
adb shell "$WPA_CLI -p $CRL_SOCKETS -i wlan0 scan_results" \
| while read -r bssid freq sig flags ssid; do
    printf "%s\t%s\t%s\t%s\t%b\n" "$bssid" "$freq" "$sig" "$flags" "$ssid"
done
```

扫描结果格式：`bssid / frequency / signal level / flags / ssid`

```bash
bssid / frequency / signal level / flags / ssid
a4:a9:30:83:b4:d2 5200 -24 [WPA2-PSK-CCMP][WPS][ESS] \xe4\xb8\x8d\xe5\x81\x9a\xe5\x99\xa9\xe6\xa2\xa6\xe7\x9a\x84\xe6\xa2\xa6\xe9\xad\x87\xe5\x85\xbd_5G
a4:a9:30:83:b4:d1 2462 -34 [WPA2-PSK-CCMP][WPS][ESS] \xe4\xb8\x8d\xe5\x81\x9a\xe5\x99\xa9\xe6\xa2\xa6\xe7\x9a\x84\xe6\xa2\xa6\xe9\xad\x87\xe5\x85\xbd
a4:a9:30:83:b4:d2 5200 -26 [WPA2-PSK-CCMP][WPS][ESS] Laurie Lin 5G

bssid / frequency / signal level / flags / ssid
a4:a9:30:83:b4:d2 5200 -24 [WPA2-PSK-CCMP][WPS][ESS] 不做噩梦的梦魇兽_5G
a4:a9:30:83:b4:d1 2462 -34 [WPA2-PSK-CCMP][WPS][ESS] 不做噩梦的梦魇兽
a4:a9:30:83:b4:d2 5200 -26 [WPA2-PSK-CCMP][WPS][ESS] Laurie Lin 5G
```

---

## Step 12：连接到目标 AP

### 12.1 默认 `add_network` 后的参数太宽，建议手工收窄

实测中，OEM 路线直接 `add_network` 后，`key_mgmt`、`proto`、`pairwise` 会带上过宽的默认集合，甚至包含 `WAPI`。这会让网络选择过程不稳定。

建议连接前显式收窄：

1. `key_mgmt WPA-PSK`
2. `proto RSN`
3. `pairwise CCMP`
4. 锁定目标 BSSID

### 12.2 示例：连接 `Laurie Lin 5G`

```bash
WPA="/tmp/oem/bin/wpa_cli  -p /tmp/recovery/sockets -i wlan0"
# 返回新网络的 ID（整数）
ID=$(adb shell $WPA add_network | tail -1)
adb shell $WPA set_network $ID ssid '\"Laurie Lin 5G\"'
adb shell $WPA set_network $ID psk '\"906262255\"'
# 下面四行和自编译 wpa_cli/wpa_supplicant 不一样，但是没有是连接不上的
adb shell $WPA set_network $ID key_mgmt WPA-PSK
adb shell $WPA set_network $ID proto RSN
adb shell $WPA set_network $ID pairwise CCMP
# a4:a9:30:83:b4:d2 是 5G AP 的 BSSID
adb shell $WPA set_network $ID bssid a4:a9:30:83:b4:d2
# 允许该网络被关联
adb shell $WPA enable_network $ID
# 强制切换到该网络
adb shell $WPA select_network $ID
# 需要等待一会
sleep 3
adb shell $WPA status
```

关联成功后 `status` 输出：

```bash
bssid=a4:a9:30:83:b4:d2
freq=5200
ssid=Laurie Lin 5G
id=0
mode=station
wifi_generation=7
pairwise_cipher=CCMP
group_cipher=CCMP
key_mgmt=WPA2-PSK
wpa_state=COMPLETED
p2p_device_address=00:03:7f:12:bd:c7
address=00:03:7f:12:bd:c7
uuid=685a9182-55a3-56a2-b757-657d6e457d0e
ieee80211ac=1
```

> `wpa_state=COMPLETED` 表示已完成：认证（Authentication）→ 关联（Association）→
> WPA2 四次握手（4-way Handshake）→ PTK/GTK 安装，链路层加密已就绪。
> `wifi_generation=7` 说明该 AP 支持 802.11be (WiFi 7)，ossi 硬件也支持。

---

## Step 13：DHCP 获取 IP 地址

### 13.1 DHCP

未 DHCP, `adb shell ifconfig wlan0` 输出：

```bash
wlan0     Link encap:Ethernet  HWaddr 00:03:7f:12:bd:c7  Driver cnss_pci
          inet6 addr: 240e:39d:20:31b1:203:7fff:fe12:bdc7/64 Scope: Global
          inet6 addr: fe80::203:7fff:fe12:bdc7/64 Scope: Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:12 errors:0 dropped:0 overruns:0 frame:0 
          TX packets:9 errors:0 dropped:0 overruns:0 carrier:0 
          collisions:0 txqueuelen:3000 
          RX bytes:2512 TX bytes:850
```

```bash
# 将 dhcpcd 推送到设备（来自 sm86xx device tree 的 6.8.2 和自编译版本 10.3.1）
adb push prebuilts/dhcpcd_6.8.2 /system/bin/dhcpcd6
adb push prebuilts/dhcpcd_10.3.1 /system/bin/dhcpcd10
adb shell "rm -f /data/misc/dhcp/*"
# 下面四行已经用 dhcpcd10 参数代替
# adb shell "mkdir -p /system/etc/dhcpcd"
# adb shell "echo '# minimal config for recovery' > /system/etc/dhcpcd/dhcpcd.conf"
# adb shell 'echo "#!/sbin/sh" > /system/etc/dhcpcd/dhcpcd-run-hooks'
# adb shell "chmod 755 /system/etc/dhcpcd/dhcpcd-run-hooks"
# 
adb shell killall dhcpcd10 dhcpcd6
# -c /system/bin/sh 解决警告 script_runreason: /system/etc/dhcpcd/dhcpcd-run-hooks: WEXITSTATUS 127
# -f /dev/null 避免读取默认配置文件（recovery 环境下不适用）
# -d 输出调试日志，观察 DHCP 流程
# adb shell "/system/bin/dhcpcd10 -f /dev/null -c /system/bin/sh wlan0"
# dhcpcd6 -c /system/bin/sh 会卡住不知道为啥
adb shell "/system/bin/dhcpcd6 wlan0"

```

输出及说明：

```bash
# dhcpcd 6.8.2 输出第一次：
# 以非 root 权限运行（正常）
dhcpcd is running with reduced privileges
# 尝试续约上次 lease（/data/misc/dhcp/dhcpcd-wlan0.lease 留存）
wlan0: rebinding lease of 192.168.31.150
wlan0: sending REQUEST (xid 0x5caab8d3), next in 4.6 seconds
# 路由器拒绝：该地址已被另一客户端占用
wlan0: received NAK with xid 0x5caab8d3
wlan0: message: address in use
wlan0: NAK (deferred): from 192.168.31.1
wlan0: Handling deferred NAK

# 发起 DISCOVER
wlan0: soliciting a DHCP lease
wlan0: sending DISCOVER (xid 0xb9de3f3a), next in 3.6 seconds

# 正常 DORA 流程：DISCOVER → OFFER → REQUEST → ACK
wlan0: received OFFER with xid 0xb9de3f3a
wlan0: offered 192.168.31.150 from 192.168.31.1
wlan0: requesting lease of 192.168.31.150
wlan0: sending REQUEST (xid 0xb9de3f3a), next in 3.3 seconds
wlan0: received ACK with xid 0xb9de3f3a
wlan0: acknowledged 192.168.31.150 from 192.168.31.1

# ARP 探测：确认 IP 未被同网段其他主机占用（免费 ARP）
wlan0: ARP probing 192.168.31.150 (1 of 3), next in 1.4 seconds
wlan0: ARP probing 192.168.31.150 (2 of 3), next in 1.5 seconds
wlan0: ARP probing 192.168.31.150 (3 of 3), next in 2.0 seconds

# IP 配置完成，自动添加路由
wlan0: leased 192.168.31.150 for 43200 seconds # 租约 12 小时
wlan0: adding route to 192.168.31.0/24 # 子网路由
wlan0: adding default route via 192.168.31.1 # 默认网关
forked to background, child pid 1262 # dhcpcd 后台运行，持续守护租约

# adb shell killall dhcpcd10 dhcpcd6 后再次启动：
# adb shell "/system/bin/dhcpcd6 wlan0" 
dhcpcd is running with reduced privileges
wlan0: rebinding lease of 192.168.31.150
wlan0: sending REQUEST (xid 0x358fcc2a), next in 3.4 seconds
wlan0: received ACK with xid 0x358fcc2a
wlan0: acknowledged 192.168.31.150 from 192.168.31.1
wlan0: ARP probing 192.168.31.150 (1 of 3), next in 1.2 seconds
wlan0: ARP probing 192.168.31.150 (2 of 3), next in 2.0 seconds
wlan0: ARP probing 192.168.31.150 (3 of 3), next in 2.0 seconds
wlan0: leased 192.168.31.150 for 43200 seconds
wlan0: adding route to 192.168.31.0/24
wlan0: adding default route via 192.168.31.1
forked to background, child pid 1352

# char pssid[PROFILE_LEN];  // PROFILE_LEN = 64

# r = print_string(pssid, sizeof(pssid), OT_ESCSTRING,
#     ifp->ssid, ifp->ssid_len);
# if (r == -1) {
#     logerr(__func__);  // <-- No buffer space available 报错，不影响(应该)

# dhcpcd 10.3.1 输出第一次：# adb shell "/system/bin/dhcpcd10 -f /dev/null -c /system/bin/sh wlan0"

dhcpcd_selectprofile: No buffer space available
wlan0: connected to Access Point: Laurie Lin 5G
DUID 00:01:00:01:31:9c:6c:c4:00:03:7f:12:5b:d9
wlan0: IAID 7f:12:1a:92
wlan0: soliciting an IPv6 router
wlan0: Router Advertisement from fe80::a6a9:30ff:fe83:b4cf
wlan0: adding address 240e:39d:20:8070:203:7fff:fe12:1a92/64
wlan0: adding route to 240e:39d:20:8070::/64
wlan0: adding default route via fe80::a6a9:30ff:fe83:b4c

# 很奇怪，上面输出没有 ipv4

# 但是 ifconfig wlan0 已经有 ipv4 地址了
# ➜ adb shell ifconfig wlan0
# wlan0     Link encap:Ethernet  HWaddr 00:03:7f:12:1a:92  Driver cnss_pci
#           inet addr:192.168.31.147  Bcast:192.168.31.255  Mask:255.255.255.0 
#           inet6 addr: 240e:39d:20:8070:203:7fff:fe12:1a92/64 Scope: Global
#           inet6 addr: 240e:39d:20:8070::db9/128 Scope: Global
#           inet6 addr: fe80::203:7fff:fe12:1a92/64 Scope: Link
#           UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
#           RX packets:43 errors:0 dropped:0 overruns:0 frame:0 
#           TX packets:31 errors:0 dropped:0 overruns:0 carrier:0 
#           collisions:0 txqueuelen:3000 
#           RX bytes:13455 TX bytes:3563

# adb shell killall dhcpcd10 dhcpcd6 后再次启动：
# adb shell "/system/bin/dhcpcd10 -f /dev/null -c /system/bin/sh wlan0"

DUID 00:01:00:01:31:9c:6c:c4:00:03:7f:12:5b:d9
wlan0: connected to Access Point: Laurie Lin 5G
wlan0: IAID 7f:12:5b:d9
wlan0: soliciting an IPv6 router
wlan0: Router Advertisement from fe80::a6a9:30ff:fe83:b4cf
wlan0: adding address 240e:39d:20:31b1:203:7fff:fe12:5bd9/64
wlan0: adding route to 240e:39d:20:31b1::/64
wlan0: adding default route via fe80::a6a9:30ff:fe83:b4cf
wlan0: confirming prior DHCPv6 lease
wlan0: rebinding lease of 192.168.31.153
wlan0: probing address 192.168.31.153/24
wlan0: REPLY6 received from fe80::a6a9:30ff:fe83:b4cf
# adding address/renew/rebinding/probing 打印顺序不是固定的
wlan0: adding address 240e:39d:20:31b1::f80/128
wlan0: renew in 21552, rebind in 34512, expire in 43152 seconds


# adb shell killall dhcpcd10 && adb shell "rm -f /data/misc/dhcp/*" 后再次启动：
wlan0: connected to Access Point: Laurie Lin 5G
DUID 00:01:00:01:31:9c:6d:64:00:03:7f:12:5b:d9
wlan0: IAID 7f:12:5b:d9
wlan0: soliciting a DHCP lease
wlan0: offered 192.168.31.153 from 192.168.31.1
wlan0: probing address 192.168.31.153/24
wlan0: soliciting an IPv6 router
wlan0: Router Advertisement from fe80::a6a9:30ff:fe83:b4cf
wlan0: adding address 240e:39d:20:31b1:203:7fff:fe12:5bd9/64
wlan0: adding route to 240e:39d:20:31b1::/64
wlan0: adding default route via fe80::a6a9:30ff:fe83:b4cf
wlan0: soliciting a DHCPv6 lease
wlan0: ADV 240e:39d:20:31b1::3df/128 from fe80::a6a9:30ff:fe83:b4cf (0)

```

`adb shell ifconfig wlan0` 输出：

```bash
wlan0     Link encap:Ethernet  HWaddr 00:03:7f:12:5b:d9  Driver cnss_pci
          inet addr:192.168.31.150  Bcast:192.168.31.255  Mask:255.255.255.0 
          inet6 addr: fe80::203:7fff:fe12:5bd9/64 Scope: Link
          inet6 addr: 240e:39d:20:31b1:203:7fff:fe12:5bd9/64 Scope: Global
          inet6 addr: 240e:39d:20:31b1::3df/128 Scope: Global
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:88 errors:0 dropped:0 overruns:0 frame:0 
          TX packets:111 errors:0 dropped:0 overruns:0 carrier:0 
          collisions:0 txqueuelen:3000 
          RX bytes:32386 TX bytes:12348
```

### Step 14: 验证网络连通性

```bash
# 解除 ping 权限限制（recovery 中 ping_group_range 默认为 1 1，普通进程无权发 ICMP）
# 0 → 2147483647（2^31 - 1）范围更大
# adb shell "echo '0 2147483647' > /proc/sys/net/ipv4/ping_group_range"
adb shell "echo '0 99999999' > /proc/sys/net/ipv4/ping_group_range"

# ping 阿里公共 DNS（223.5.5.5）验证 IPv4 互联网连通
adb shell "toybox ping -c 4 223.5.5.5"
```

输出：

```bash
Ping 223.5.5.5 (223.5.5.5): 56(84) bytes.
64 bytes from 223.5.5.5: icmp_seq=1 ttl=50 time=30 ms
64 bytes from 223.5.5.5: icmp_seq=2 ttl=50 time=24 ms
64 bytes from 223.5.5.5: icmp_seq=3 ttl=50 time=26 ms
64 bytes from 223.5.5.5: icmp_seq=4 ttl=50 time=14 ms

--- 223.5.5.5 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss
round-trip min/avg/max = 14/23/30 ms
```

> TTL=50（从 64 减少 14 跳），RTT 14~30 ms，0% 丢包。IPv4 互联网完全连通。✅

## 这条 OEM 路线的最小成功条件

本次实机跑通后，可以把必要条件收敛成下面几项：

1. `wlan0` 必须先通过手工模块链拉起来
2. 设备 OEM `wpa_supplicant`、OEM `wpa_supplicant.conf`、WiFi AIDL so、keystore so、keymint so 必须在 `/vendor` 卸载后仍可见
3. `servicemanager` 必须在修复 VINTF 视图后重启一次
4. 运行时库顺序必须使用 `LD_LIBRARY_PATH=/system/lib64:/tmp/oem/lib64`
5. `wpa_cli ping` 成功后，再做 `scan` / `connect` / `dhcpcd`
6. 关联阶段建议把 `key_mgmt` / `proto` / `pairwise` / `bssid` 收窄，不要直接依赖 OEM 默认模板
7. 按当前 `infinti` 实测，`qrtr-ns` 和 `cnss-daemon` 对“`wpa_supplicant` 启动 + 扫描成功”不是必需前提

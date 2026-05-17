# infiniti Recovery WiFi 手动启动全流程

**设备：** infiniti (OP60FFL1)，TWRP recovery 模式
**平台：** Snapdragon 8 Elite (pineapple)，WiFi 芯片 QCA PCIe
**目标：** 使用自编译 wpa_cli/wpa_supplicant，配合设备自身的 WiFi 驱动和固件，在 recovery 环境下手动完成 WiFi 启动、扫描、关联、DHCP 获取 IP、验证外网连通的全流程。
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

## 整体流程概览

```text
挂载分区
→ 复制 WCNSS_qcom_cfg.ini
→ insmod CNSS 基础模块
→ 触发固件下载 (写 fs_ready 1)
→ insmod 无线驱动（需要等待 fs_ready）
→ 确认 wlan0 出现
→ 启动 wpa_supplicant
→ 扫描/连接 AP（wpa_cli scan / scan_results / connect）
→ dhcpcd 获取 IP
→ ping 验证
```

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

## Step 7：启动 wpa_supplicant

wpa_supplicant 是用户空间的 WiFi 管理守护进程，负责：

- 将 wlan0 接口 UP（`SIOCSIFFLAGS`）
- 与 cfg80211/nl80211 通信，控制扫描、认证、关联、4-way handshake
- 通过 Unix Domain Socket 向 wpa_cli 暴露控制接口
- 不知道为什么这里使用的是 -O/data/misc/wifi/wpa_supplicant，后来统一又改成了 -O/tmp/recovery/sockets

```bash
adb push prebuilts/wpa_supplicant /system/bin/wpa_supplicant

# 最小配置文件：声明控制接口路径，允许运行时添加网络
adb shell "printf 'ctrl_interface=/data/misc/wifi/wpa_supplicant\nupdate_config=1\n' > /tmp/wpa_min.conf"

# wpa_supplicant 需要 socket 目录属于 wifi 组且可写
# 如果缺失这一步
# adb shell "wpa_cli -p /data/misc/wifi/wpa_supplicant -i wlan0 scan" 输出
# Failed to connect to non-global ctrl_ifname: wlan0  error: Permission denied
adb shell "chown root:wifi /tmp && chmod 775 /tmp"

# -i wlan0        : 管理 wlan0 接口
# -D nl80211      : 使用 nl80211 驱动（现代内核标准接口）
# -c /tmp/wpa_min.conf : 使用最小配置文件
# -O /data/misc/wifi/wpa_supplicant : Socket 文件存放目录（-O 与 ctrl_interface 须一致）
# -B              : 后台运行（daemon 模式）
# 忘记了这里为什么没用 -O/tmp/recovery/sockets 了，后来又改回来了
adb shell "wpa_supplicant -iwlan0 -Dnl80211 -c/tmp/wpa_min.conf -O/data/misc/wifi/wpa_supplicant -B && echo wpa_supplicant OK"

adb shell "ps -A | grep wpa_supplicant"
adb shell "ls -l /data/misc/wifi/wpa_supplicant"
```

> Recovery 中 `/system/bin/wpa_supplicant` 链接了
> `libcrypto.so` 等完整系统库，在 recovery 受限环境中缺少依赖会立即崩溃。这里用的是
> 专门为 recovery 静态编译（或用 EVP_PKEY stub）的版本，位于 recovery ramdisk 中。

---

## Step 8：扫描可用 WiFi

```bash
adb push prebuilts/wpa_cli /system/bin/wpa_cli
WPA_CLI="wpa_cli"
CRL_SOCKETS="/data/misc/wifi/wpa_supplicant"
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
...
```

```bash
#printf '%b\n' '\xe4\xb8\x8d\xe5\x81\x9a\xe5\x99\xa9\xe6\xa2\xa6\xe7\x9a\x84\xe6\xa2\xa6\xe9\xad\x87\xe5\x85\xbd_5G' 
不做噩梦的梦魇兽_5G
```

所以可以用命令

```bash
adb shell "wpa_cli -p /data/misc/wifi/wpa_supplicant -i wlan0 scan_results" \
| while read -r bssid freq sig flags ssid; do
    printf "%s\t%s\t%s\t%s\t%b\n" "$bssid" "$freq" "$sig" "$flags" "$ssid"
done
```

```bash
bssid / frequency / signal level / flags / ssid
a4:a9:30:83:b4:d2 5200 -23 [WPA2-PSK-CCMP][WPS][ESS] 不做噩梦的梦魇兽_5G
...
```

信道计算
5200 MHz
→ (5200 - 5000) / 5
→ 200 / 5
→ 40

> 信号强度 -23 dBm 接近满格（-30 dBm 以上为极强），5200 MHz 为 5GHz 信道 40。

---

## Step 9：连接到目标 AP

通过 wpa_cli 命令序列添加并激活网络：

```bash
WPA="wpa_cli -p /data/misc/wifi/wpa_supplicant -i wlan0"
# 返回新网络的 ID（整数）
ID=$(adb shell $WPA add_network | tail -1)
adb shell $WPA add_network
adb shell $WPA set_network $ID ssid '\"Laurie Lin 5G\"'
adb shell $WPA set_network $ID psk '\"906262255\"'
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

## Step 10：DHCP 获取 IP 地址

未 DHCP, `adb shell ifconfig wlan0` 输出：

```bash
wlan0     Link encap:Ethernet  HWaddr 00:03:7f:12:5b:56  Driver cnss_pci
          inet6 addr: fe80::203:7fff:fe12:5b56/64 Scope: Link
          inet6 addr: 240e:39d:20:8070:203:7fff:fe12:5b56/64 Scope: Global
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:11 errors:0 dropped:0 overruns:0 frame:0 
          TX packets:9 errors:0 dropped:0 overruns:0 carrier:0 
          collisions:0 txqueuelen:3000 
          RX bytes:3684 TX bytes:850
```

此时 wlan0 有 L2 连接但无 IP。使用 dhcpcd（v6.8.2/v）获取 IP：

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
wlan0: ARP probing 192.168.31.150 (1 of 3), next in 1.9 seconds
wlan0: ARP probing 192.168.31.150 (2 of 3), next in 1.9 seconds
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

# dhcpcd 10.3.1 输出第一次：
# adb shell "/system/bin/dhcpcd10 -f /dev/null -c /system/bin/sh wlan0"
DUID 00:01:00:01:31:9c:6f:c6:00:03:7f:12:e7:68
dhcpcd_selectprofile: No buffer space available
wlan0: connected to Access Point: Laurie Lin 5G
wlan0: IAID 7f:12:e7:68
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

DUID 00:01:00:01:31:9c:6f:c6:00:03:7f:12:e7:68
wlan0: connected to Access Point: Laurie Lin 5G
wlan0: IAID 7f:12:e7:68
wlan0: adding address fe80::203:7fff:fe12:e768
wlan0: rebinding lease of 192.168.31.150
wlan0: probing address 192.168.31.150/24
wlan0: soliciting an IPv6 router
wlan0: Router Advertisement from fe80::a6a9:30ff:fe83:b4cf
wlan0: adding address 240e:39d:20:31b1:203:7fff:fe12:e768/64
wlan0: adding route to 240e:39d:20:31b1::/64
wlan0: adding default route via fe80::a6a9:30ff:fe83:b4cf
wlan0: confirming prior DHCPv6 lease
wlan0: REPLY6 received from fe80::a6a9:30ff:fe83:b4cf
wlan0: adding address 240e:39d:20:31b1::c48/128
wlan0: renew in 21335, rebind in 34295, expire in 42935 seconds


# adb shell killall dhcpcd10 && adb shell "rm -f /data/misc/dhcp/*" 后再次启动：
wlan0: connected to Access Point: Laurie Lin 5G
DUID 00:01:00:01:31:9c:70:ed:00:03:7f:12:e7:68
wlan0: IAID 7f:12:e7:68
wlan0: adding address fe80::203:7fff:fe12:e768
wlan0: soliciting a DHCP lease
wlan0: offered 192.168.31.150 from 192.168.31.1
wlan0: probing address 192.168.31.150/24
wlan0: soliciting an IPv6 router
wlan0: Router Advertisement from fe80::a6a9:30ff:fe83:b4cf
wlan0: adding address 240e:39d:20:31b1:203:7fff:fe12:e768/64
wlan0: adding route to 240e:39d:20:31b1::/64
wlan0: adding default route via fe80::a6a9:30ff:fe83:b4cf
wlan0: soliciting a DHCPv6 lease
wlan0: ADV 240e:39d:20:31b1::ddf/128 from fe80::a6a9:30ff:fe83:b4cf (0)

```

`adb shell ifconfig wlan0` 输出：

```bash
wlan0     Link encap:Ethernet  HWaddr 00:03:7f:12:e7:68  Driver cnss_pci
          inet addr:192.168.31.150  Bcast:192.168.31.255  Mask:255.255.255.0 
          inet6 addr: 240e:39d:20:31b1:203:7fff:fe12:e768/64 Scope: Global
          inet6 addr: 240e:39d:20:31b1::aa6/128 Scope: Global
          inet6 addr: fe80::203:7fff:fe12:e768/64 Scope: Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:139 errors:0 dropped:0 overruns:0 frame:0 
          TX packets:142 errors:0 dropped:0 overruns:0 carrier:0 
          collisions:0 txqueuelen:3000 
          RX bytes:51157 TX bytes:16873
```

使用 `adb shell toybox dhcp -i wlan0` 也可以获取 ip，但后续还依赖 ip 命令手动添加路由，体验不如 dhcpcd 流畅，并且 ip 命令不是 recovery 原生的，需要从 system 提取

```bash
# adb shell toybox dhcp -i wlan0
dhcp started
dhcp started
Sending discover...
Sending select for 192.168.31.150...
Lease of 192.168.31.150 obtained, lease time 43200 from server 192.168.31.1

# adb shell ls -l /dev/block/mapper/ 找 system 分区的 block 设备
# lrwxrwxrwx 1 root root  15 1969-12-31 18:02 system_b -> /dev/block/dm-0
# 或者直接去 TWRP 挂载
# ip 在 /system_root/system/bin/ip

# /system_root/system/lib64
export LD_LIBRARY_PATH=/system_root/system/lib64
export PATH=/system_root/system/bin:$PATH
ip link set wlan0 up
ip addr flush dev wlan0
ip addr add 192.168.31.150/24 dev wlan0
ip route add default via 192.168.31.1 dev wlan0
ip route
# default via 192.168.31.1 dev wlan0 
# 192.168.31.0/24 dev wlan0 proto kernel scope link src 192.168.31.150
```

> **NAK 原因：** recovery 重启后 `/data` 保留，`dhcpcd-wlan0.lease` 仍记录上次的 IP
> `192.168.31.44`。但路由器 ARP 缓存中该 IP 已关联到其他 MAC，所以回 NAK。
> dhcpcd 自动处理 NAK 并重新 DISCOVER，无需人工干预。

---

## Step 11：验证网络连通性

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
64 bytes from 223.5.5.5: icmp_seq=1 ttl=50 time=37 ms
64 bytes from 223.5.5.5: icmp_seq=2 ttl=50 time=34 ms
64 bytes from 223.5.5.5: icmp_seq=3 ttl=50 time=33 ms
64 bytes from 223.5.5.5: icmp_seq=4 ttl=50 time=29 ms

--- 223.5.5.5 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss
round-trip min/avg/max = 29/33/37 ms
```

> TTL=50（从 64 减少 14 跳），RTT 29~37 ms，0% 丢包。IPv4 互联网完全连通。✅

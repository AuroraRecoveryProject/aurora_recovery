# ossi (OP615EL1) Recovery WiFi 手动启动全流程

**设备：** ossi (OP615EL1)，序列号 `70a91f89`，TWRP recovery 模式  
**平台：** Snapdragon 8 Gen 3 (peach/sun SoC)，WiFi 芯片 QCA PCIe  
**驱动模块：** `qca_cld3_peach_v2`  
**验证结果：** WiFi 7 连接，dhcpcd DHCP，ping 223.5.5.5 成功

---

## qrtr-ns 在默认的 TWRP 中已经运行，不知道是哪儿拉起来的

> 高通 IPC（QRTR）体系里的“服务注册与发现中心”，负责把 QMI 服务从“找不到”变成“可动态定位”。

```bash
adb shell ps -A | grep -E "qrtr|wpa_supplicant|cnss"

➜  ~ adb shell ps -A | grep -E "qrtr|wpa_supplicant|cnss"
root           245     2          0      0 kthread_worker_fn   0 S [qrtr_ns]
root           422     2          0      0 kthread_worker_fn   0 S [qrtr_rx]
```

**自编译好像不需要qrtr-ns这些东西**

## 整体流程概览

```text
挂载分区
→ 复制 WCNSS 配置
→ insmod CNSS 基础模块
→ insmod cnss2
→ 触发固件下载 (fs_ready)
→ insmod 无线驱动
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

---

## Step 1：挂载必要分区

Recovery 启动后大部分 vendor 分区未挂载，而 WiFi 内核模块（`.ko` 文件）分散在
`vendor_dlkm`、`system_dlkm`、`vendor`、`odm` 四个分区中，必须先全部挂载。

```bash
# 检查已挂载状态
adb shell "mount | grep -E 'vendor_dlkm|system_dlkm'"

# 挂载四个分区（odm 通常已挂载，报 busy 属正常）
adb shell "mount /vendor_dlkm && mount /system_dlkm"
adb shell "mount /vendor"
adb shell "mount /odm"
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

# Oplus 15
/vendor/etc/wifi/kiwi_v2/WCNSS_qcom_cfg.ini
/vendor/etc/wifi/peach_v2/WCNSS_qcom_cfg.ini
/vendor/etc/wifi/wcn7750/WCNSS_qcom_cfg.ini
/odm/vendor/etc/wifi/WCNSS_qcom_cfg.ini
```

选择 odm 版本（设备特定校准数据最准确）并复制到固件目录：

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
adb shell "insmod /tmp/vendor/lib/modules/smem-mailbox.ko && echo OK"

# cnss_prealloc：提前为 WiFi 固件预分配大块连续内存，避免运行时分配失败
adb shell "insmod /vendor_dlkm/lib/modules/cnss_prealloc.ko && echo cnss_prealloc OK"

# cnss_utils：CNSS 工具函数库，提供 wlan_utils API（被 cnss2 依赖）
adb shell "insmod /vendor_dlkm/lib/modules/cnss_utils.ko && echo cnss_utils OK"

# cnss_plat_ipc_qmi_svc：CNSS 平台 IPC QMI 服务，用于内核与用户空间（cnss-daemon）的 QMI 通信
adb shell "insmod /vendor_dlkm/lib/modules/cnss_plat_ipc_qmi_svc.ko && echo cnss_plat OK"

# cnss_nl：CNSS Netlink 接口，用于内核向用户空间广播 WiFi 事件
adb shell "insmod /vendor_dlkm/lib/modules/cnss_nl.ko && echo cnss_nl OK"

# wlan_firmware_service：处理固件下载请求，从 /vendor/firmware/ 读取 amss.bin 等固件文件
adb shell "insmod /vendor_dlkm/lib/modules/wlan_firmware_service.ko && echo wlan_firmware_service OK"

# cnss2：CNSS 主驱动，管理 PCIe 上的 QCA WiFi 芯片（枚举设备、上下电、固件加载流程控制）
adb shell "insmod /vendor_dlkm/lib/modules/cnss2.ko && echo cnss2 OK"
```

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

# Oplus 15
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

```bash
# rfkill：Linux 无线电源管理框架，管理 WiFi/BT 的软件 kill 开关（来自 system_dlkm）
adb shell "insmod /system_dlkm/lib/modules/rfkill.ko && echo rfkill OK"

# cfg80211：Linux 802.11 配置框架，是所有无线驱动与 nl80211/wpa_supplicant 之间的标准接口层
adb shell "insmod /vendor_dlkm/lib/modules/cfg80211.ko && echo cfg80211 OK"

# gsim：QCA Generic Simulation 模块（依赖项，被 qca_cld3 引用）
adb shell "insmod /vendor_dlkm/lib/modules/gsim.ko && echo gsim OK"

# rmnet_mem：RmNet 数据路径内存池（移动数据用，WiFi 场景下作为依赖项被加载）
adb shell "insmod /vendor_dlkm/lib/modules/rmnet_mem.ko && echo rmnet_mem OK"

# ipam：IP Address Management 模块（QCA 自定义 IP 管理，被 qca_cld3 依赖）
adb shell "insmod /vendor_dlkm/lib/modules/ipam.ko && echo ipam OK"

# qca_cld3_peach_v2：QCA WiFi 主驱动（CLD3 = CNSS Linux Driver v3），peach_v2 为 ossi 对应变体
# 加载后创建 wlan0 网络接口
adb shell "insmod /vendor_dlkm/lib/modules/qca_cld3_peach_v2.ko && echo qca_cld3 OK"
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
wlan0     Link encap:Ethernet  HWaddr 00:03:7f:12:a3:9e  Driver cnss_pci
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
adb shell "wpa_supplicant -iwlan0 -Dnl80211 -c/tmp/wpa_min.conf -O/data/misc/wifi/wpa_supplicant -B && echo wpa_supplicant OK"

# adb shell ps -A | grep -E "qrtr|wpa_supplicant|cnss"
# root           245     2          0      0 kthread_worker_fn   0 S [qrtr_ns]
# root           422     2          0      0 kthread_worker_fn   0 S [qrtr_rx]
# root          1049     2          0      0 kthread_worker_fn   0 S [qrtr_rx]
# wifi          1153     1   10928988   2436 do_select           0 S wpa_supplicant
```

> Recovery 中 `/system/bin/wpa_supplicant` 链接了
> `libcrypto.so` 等完整系统库，在 recovery 受限环境中缺少依赖会立即崩溃。这里用的是
> 专门为 recovery 静态编译（或用 EVP_PKEY stub）的版本，位于 recovery ramdisk 中。

---

## Step 8：扫描可用 WiFi

```bash
adb push prebuilts/wpa_cli /system/bin/wpa_cli
adb push prebuilts/dhcpcd /system/bin/dhcpcd

# 触发主动扫描
adb shell "wpa_cli -p /data/misc/wifi/wpa_supplicant -i wlan0 scan"

# 等待扫描完成（约 3~5 秒）后读取结果
adb shell "wpa_cli -p /data/misc/wifi/wpa_supplicant -i wlan0 scan_results"
```

扫描结果格式：`bssid / frequency / signal level / flags / ssid`

```bash
bssid / frequency / signal level / flags / ssid
a4:a9:30:83:b4:d2 5200 -23 [WPA2-PSK-CCMP][WPS][ESS] \xe4\xb8\x8d\xe5\x81\x9a\xe5\x99\xa9\xe6\xa2\xa6\xe7\x9a\x84\xe6\xa2\xa6\xe9\xad\x87\xe5\x85\xbd_5G
2c:43:be:e6:30:3d 5180 -51 [WPA2-PSK-CCMP+TKIP][WPS][ESS] XiaoGe-5G
2c:43:be:e6:30:3e 5180 -53 [WPA2-PSK-CCMP+TKIP][WPS][ESS] 
e0:f7:78:c9:50:b4 5765 -50 [WPA2-PSK-CCMP+TKIP][WPS][ESS] ChinaNet-4110-5G
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
2c:43:be:e6:30:3d 5180 -51 [WPA2-PSK-CCMP+TKIP][WPS][ESS] XiaoGe-5G
2c:43:be:e6:30:3e 5180 -53 [WPA2-PSK-CCMP+TKIP][WPS][ESS] 
e0:f7:78:c9:50:b4 5765 -50 [WPA2-PSK-CCMP+TKIP][WPS][ESS] ChinaNet-4110-5G
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
# 在设备上执行的连接脚本（避免 shell 引号嵌套问题）
printf '#!/system/bin/sh
WPA="wpa_cli -p /data/misc/wifi/wpa_supplicant -i wlan0"
ID=$($WPA add_network | tail -1)   # 返回新网络的 ID（整数）
$WPA set_network $ID ssid "\"不做噩梦的梦魇兽_5G\""
$WPA set_network $ID psk "\"906262255\""
$WPA enable_network $ID            # 允许该网络被关联
$WPA select_network $ID            # 强制切换到该网络
sleep 8                            # 等待 4-way handshake 完成
$WPA status
' > wpa_connect.sh

adb push wpa_connect.sh /tmp/wpa_connect.sh
adb shell "sh /tmp/wpa_connect.sh"
```

关联成功后 `status` 输出：

```bash
bssid=a4:a9:30:83:b4:d2
freq=5200
ssid=\xe4\xb8\x8d\xe5\x81\x9a\xe5\x99\xa9\xe6\xa2\xa6\xe7\x9a\x84\xe6\xa2\xa6\xe9\xad\x87\xe5\x85\xbd_5G
id=0
mode=station
wifi_generation=7
pairwise_cipher=CCMP
group_cipher=CCMP
key_mgmt=WPA2-PSK
wpa_state=COMPLETED
p2p_device_address=00:03:7f:12:9d:f2
address=00:03:7f:12:9d:f2
uuid=c76ccbb2-d8a0-541c-91e4-56873987d89b
ieee80211ac=
```

> `wpa_state=COMPLETED` 表示已完成：认证（Authentication）→ 关联（Association）→
> WPA2 四次握手（4-way Handshake）→ PTK/GTK 安装，链路层加密已就绪。
> `wifi_generation=7` 说明该 AP 支持 802.11be (WiFi 7)，ossi 硬件也支持。

---

## Step 10：DHCP 获取 IP 地址

此时 wlan0 有 L2 连接但无 IP。使用 dhcpcd（v6.8.2）获取 IP：

```bash
# 将 dhcpcd 推送到设备（来自 sm86xx device tree，recovery 适配版本）
adb push prebuilts/dhcpcd /system/bin/dhcpcd

adb shell "/system/bin/dhcpcd wlan0"
```

典型输出及说明：

```bash
# dhcpcd 无法执行 hook 脚本（如设置 DNS），但 IP 配置仍然正常完成
# 无害警告：recovery 中没有 /system/etc/dhcpcd/dhcpcd-run-hooks
script_runreason: /system/etc/dhcpcd/dhcpcd-run-hooks: WEXITSTATUS 127
script_runreason: /system/etc/dhcpcd/dhcpcd-run-hooks: WEXITSTATUS 127
script_runreason: /system/etc/dhcpcd/dhcpcd-run-hooks: WEXITSTATUS 127
# 以非 root 权限运行（正常）
dhcpcd is running with reduced privileges
# 发起 DISCOVER
wlan0: soliciting a DHCP lease
wlan0: sending DISCOVER (xid 0x53a8d1dc), next in 4.3 seconds
# 正常 DORA 流程：DISCOVER → OFFER → REQUEST → ACK
wlan0: received OFFER with xid 0x53a8d1dc
wlan0: offered 192.168.31.212 from 192.168.31.1
wlan0: requesting lease of 192.168.31.212
wlan0: sending REQUEST (xid 0x53a8d1dc), next in 4.6 seconds
wlan0: received ACK with xid 0x53a8d1dc
wlan0: acknowledged 192.168.31.212 from 192.168.31.1
# ARP 探测：确认 IP 未被同网段其他主机占用（免费 ARP）
wlan0: ARP probing 192.168.31.212 (1 of 3), next in 1.9 seconds
wlan0: ARP probing 192.168.31.212 (2 of 3), next in 1.9 seconds
wlan0: ARP probing 192.168.31.212 (3 of 3), next in 2.0 seconds
# IP 配置完成，自动添加路由
wlan0: leased 192.168.31.212 for 43200 seconds # 租约 12 小时
wlan0: adding route to 192.168.31.0/24 # 子网路由
wlan0: adding default route via 192.168.31.1 # 默认网关
forked to background, child pid 24354 # dhcpcd 后台运行，持续守护租约
```

其他输出行

```bash
# 尝试续约上次 lease（/data/misc/dhcp/dhcpcd-wlan0.lease 留存）
wlan0: rebinding lease of 192.168.31.44
# 路由器拒绝：该地址已被另一客户端占用
wlan0: received NAK with xid 0x344e9726
wlan0: Handling deferred NAK
```

使用 `adb shell toybox dhcp -i wlan0` 也可以获取 ip，但后续还依赖 ip 命令手动添加路由，体验不如 dhcpcd 流畅，并且 ip 命令不是 recovery 原生的，需要从 system 提取

```bash
toybox dhcp -i wlan0
dhcp started
Sending discover...
Sending discover...
Sending select for 192.168.31.42...
Lease of 192.168.31.42 obtained, lease time 43200 from server 192.168.31.1

# ls -l /dev/block/mapper/ 找 system 分区的 block 设备
# lrwxrwxrwx 1 root root  15 1969-12-31 18:02 system_b -> /dev/block/dm-0
# 或者直接去 TWRP 挂载
# ip 在 /system_root/system/bin/ip

# /system_root/system/lib64
export LD_LIBRARY_PATH=/system_root/system/lib64
export PATH=/system_root/system/bin:$PATH
ip link set wlan0 up
ip addr flush dev wlan0
ip addr add 192.168.31.42/24 dev wlan0
ip route add default via 192.168.31.1 dev wlan0
ip route
# default via 192.168.31.1 dev wlan0 
# 192.168.31.0/24 dev wlan0 proto kernel scope link src 192.168.31.42
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

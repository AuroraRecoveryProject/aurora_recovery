# TWRP Recovery WiFi 设备树集成指南

**参考设备**：OnePlus Pad2Pro（OP615EL1），代号 `ossi`
**平台**：Snapdragon 8 Elite（`peach`），WiFi 芯片 QCA PCIe `0x110e`，驱动 `qca_cld3_peach_v2`，WiFi 6  
**ADB 序列号**：`70a91f89`  
**适用平台**：高通（Qualcomm），基于 ossi（sun/peach）与 sm86xx（pineapple）移植经验

---

- [TWRP Recovery WiFi 设备树集成指南](#twrp-recovery-wifi-设备树集成指南)
  - [一、背景](#一背景)
  - [二、改动总览](#二改动总览)
  - [三、整体启动流程](#三整体启动流程)
  - [四、获取 wpa\_supplicant 与 wpa\_cli](#四获取-wpa_supplicant-与-wpa_cli)
    - [4.1 方案对比](#41-方案对比)
    - [4.2 方案 A：从设备提取预编译二进制](#42-方案-a从设备提取预编译二进制)
      - [分析出依赖库](#分析出依赖库)
    - [4.4 方案 B：编译 wpa\_supplicant\_recovery（适用于 pure 方案）](#44-方案-b编译-wpa_supplicant_recovery适用于-pure-方案)
      - [第一步：拉取 wpa\_supplicant\_8 源码](#第一步拉取-wpa_supplicant_8-源码)
    - [4.6 现行方案说明：为什么 `wpa_supplicant_recovery` 必须定义在上游 Android.bp](#46-现行方案说明为什么-wpa_supplicant_recovery-必须定义在上游-androidbp)
    - [4.8 现行方案说明：为什么需要 `EVP_PKEY_from_keystore` stub](#48-现行方案说明为什么需要-evp_pkey_from_keystore-stub)
  - [五、文件清单](#五文件清单)
    - [5.1 方案 A 新增文件（需在设备树中创建），以一加 `ossi` 方案为例](#51-方案-a-新增文件需在设备树中创建以一加-ossi-方案为例)
    - [5.2 从本设备提取（必须设备特定，不可跨设备复用）](#52-从本设备提取必须设备特定不可跨设备复用)
    - [5.3 提取命令（在设备连接状态下执行）](#53-提取命令在设备连接状态下执行)
  - [六、设备适配参数（移植到新设备必须核对）](#六设备适配参数移植到新设备必须核对)
    - [6.1 平台代号（决定 fs\_ready 路径）](#61-平台代号决定-fs_ready-路径)
    - [6.2 WiFi 驱动模块名](#62-wifi-驱动模块名)
    - [6.3 smem-mailbox.ko 是否存在于 vendor\_boot tmpfs](#63-smem-mailboxko-是否存在于-vendor_boot-tmpfs)
    - [6.4 各模块分布位置](#64-各模块分布位置)
      - [6.4.1. 用 modules.dep 确定硬依赖](#641-用-modulesdep-确定硬依赖)
      - [6.4.2. 把每个中间模块的依赖也展开](#642-把每个中间模块的依赖也展开)
      - [6.4.3. 对精简后的模块集合做拓扑排序](#643-对精简后的模块集合做拓扑排序)
  - [七、配置文件模板](#七配置文件模板)
    - [7.1 init.recovery.wifi.rc 模板](#71-initrecoverywifirc-模板)
      - [7.1.1 公共骨架](#711-公共骨架)
    - [7.2 cp-wifi-ko.sh 模板](#72-cp-wifi-kosh-模板)
    - [7.3 init.recovery.qcom.rc 修改](#73-initrecoveryqcomrc-修改)
  - [八、内核模块加载链](#八内核模块加载链)
    - [8.1 模块分布](#81-模块分布)
    - [8.2 完整加载顺序](#82-完整加载顺序)
    - [8.3 坑：fs\_ready 路径与权限](#83-坑fs_ready-路径与权限)
  - [九、wpa\_supplicant 权限问题](#九wpa_supplicant-权限问题)
    - [9.1 根本原因：Android 强制降权](#91-根本原因android-强制降权)
    - [9.2 当前稳定方案：统一使用 `/tmp/recovery/sockets`](#92-当前稳定方案统一使用-tmprecoverysockets)
    - [9.3 关键权限点：自编译版需要让 `/tmp` 对 `wifi` 可写](#93-关键权限点自编译版需要让-tmp-对-wifi-可写)
  - [十、WiFi 连接与 DHCP](#十wifi-连接与-dhcp)
    - [10.1 WiFi 扫描与连接](#101-wifi-扫描与连接)
    - [10.2 DHCP 方案对比](#102-dhcp-方案对比)
    - [10.3 方案 A：toybox dhcp + ip route](#103-方案-atoybox-dhcp--ip-route)
    - [10.4 方案 B：dhcpcd](#104-方案-bdhcpcd)
    - [10.5 ping 权限问题](#105-ping-权限问题)
  - [十一、关键背景知识](#十一关键背景知识)
    - [11.1 AIDL HAL 版本（V3 从哪里看出来的）](#111-aidl-hal-版本v3-从哪里看出来的)
    - [11.2 VINTF manifest 目录规则](#112-vintf-manifest-目录规则)
    - [11.3 servicemanager VINTF 时序问题与循环符号链接](#113-servicemanager-vintf-时序问题与循环符号链接)
  - [十二、调试手段](#十二调试手段)
    - [查看 WiFi 启动日志](#查看-wifi-启动日志)
    - [验证模块是否加载](#验证模块是否加载)
    - [验证 wpa\_supplicant 是否运行](#验证-wpa_supplicant-是否运行)
    - [手动触发 WiFi 初始化（调试用）](#手动触发-wifi-初始化调试用)
    - [确认 servicemanager 能否找到 VINTF 声明的 HAL](#确认-servicemanager-能否找到-vintf-声明的-hal)
    - [排查 TWRP 卡第一屏（进不去主界面）](#排查-twrp-卡第一屏进不去主界面)
  - [十三、排查案例](#十三排查案例)
    - [13.1 TWRP GUI 无法扫描 WiFi（ossi，2026-03-07）](#131-twrp-gui-无法扫描-wifiossi2026-03-07)
      - [症状](#症状)
      - [第一步：确认哪个进程崩溃](#第一步确认哪个进程崩溃)
      - [第二步：搞清楚缺哪些库](#第二步搞清楚缺哪些库)
      - [第三步：库补齐后 wpa\_supplicant 能启动，但 AIDL 注册失败](#第三步库补齐后-wpa_supplicant-能启动但-aidl-注册失败)
      - [第四步：确认 VINTF manifest 版本](#第四步确认-vintf-manifest-版本)
      - [第五步：manifest 加进去了，仍然报找不到](#第五步manifest-加进去了仍然报找不到)
      - [修复汇总](#修复汇总)
    - [13.2 TWRP 卡第一屏（ossi\_pure，keymint 缺库）](#132-twrp-卡第一屏ossi_purekeymint-缺库)
      - [症状](#症状-1)
      - [根因链](#根因链)
      - [排查过程](#排查过程)
      - [修复](#修复)
  - [十四、wpa\_cli /tmp 权限问题（自编译版专有）](#十四wpa_cli-tmp-权限问题自编译版专有)
    - [14.1 背景](#141-背景)
    - [14.2 现象](#142-现象)
    - [14.3 根因分析](#143-根因分析)
    - [14.4 两种修复方案](#144-两种修复方案)
    - [14.5 影响范围](#145-影响范围)
  - [附录：移植到其他设备](#附录移植到其他设备)


## 一、背景

标准 TWRP recovery 没有 WiFi，原因：

1. Recovery 的 `init` 只挂载基本分区，不加载 WiFi 内核模块
2. Android 系统的 `wpa_supplicant` 由 `init.rc` + `wificond` 配合启动，recovery 里这套机制不存在
3. 没有 `cfg80211`、没有 WiFi 驱动，内核不会创建 `wlan0` 接口

---

## 二、改动总览

| 层面 | 文件 | 内容 |
| --- | --- |--- |
| 编译 | `vendor/twrp/wifi/Android.bp` | `wpa_cli_recovery` 模块定义 |
| 编译 | `external/wpa_supplicant_8/wpa_supplicant/Android.bp` | 追加 `wpa_supplicant_recovery` block |
| 编译 | `external/wpa_supplicant_8/.../src/crypto/evp_pkey_stub_recovery.c` | `EVP_PKEY_from_keystore` 存根（见四.8） |
| 打包 | `vendor/twrp/config/packages.mk` | 将 `wpa_cli_recovery`、`wpa_supplicant_recovery` 打包进 recovery |
| 运行时 | `recovery/root/init.recovery.wifi.rc` | 所有 WiFi 服务、属性链定义 |
| 运行时 | `recovery/root/system/bin/cp-wifi-ko.sh` | 从各分区复制 .ko 的脚本 |

---

## 三、整体启动流程

```bash
挂载 /vendor_dlkm、/system_dlkm（cp-wifi-ko.sh）
  ↓
从各分区搜索并复制 .ko 到 /odm/wifi/modules/
  ↓
按序 insmod（13 个，严格顺序：cnss_prealloc→cnss_utils→cnss2→...→qca_cld3_*）
  ↓
写 fs_ready=1（触发内核 request_firmware，芯片下载固件）
  ↓
（内核自动）amss.bin 从 /firmware/image/peach/ 加载到 WiFi 芯片
  ↓
# 这里有问题，经过测试，这些驱动可以在 fs_ready=1 之前加载
rfkill / cfg80211 / qca_cld3_peach_v2 加载 → wlan0 出现
  ↓
umount /vendor（由 init.recovery.qcom.rc 触发）← 循环符号链断开
  ↓
重启 servicemanager（仅 OEM 版本需要，重扫 VINTF，此时循环链已消除）
  ↓
启动 wpa_supplicant（原生 OEM 版 或 自编译 recovery 版）
  ↓
wpa_cli 扫描 / 连接 → dhcpcd 获取 IP + 路由
```

---

## 四、获取 wpa_supplicant 与 wpa_cli

### 4.1 方案对比

| 方案 | 优点 | 缺点 |
| --- | --- | --- |
| A. 从设备提取预编译二进制 | 与设备完全匹配，`ossi` 已验证可正常联网 | 需同时补齐 AIDL HAL so、VINTF manifest，并处理 servicemanager/VINTF 时序 |
| B. 编译 `wpa_supplicant_recovery` | 无 AIDL 依赖，适合 `pure` 方案和跨设备移植 | 需 AOSP 源码树，编译耗时 |

---

### 4.2 方案 A：从设备提取预编译二进制

```bash
DEVICE_TREE="twrp_device_oplus_ossi"
# wpa_supplicant（含 Oplus AIDL V5，可用于 recovery，但必须同时补齐其 AIDL / HAL / VINTF 依赖）
adb pull /vendor/bin/hw/wpa_supplicant $DEVICE_TREE/recovery/root/vendor/bin/hw/

# wpa_cli（无 AIDL，可直接作为控制客户端）
adb pull /vendor/bin/wpa_cli $DEVICE_TREE/recovery/root/system/bin/
```

#### 分析出依赖库

wpa_cli 依赖比较干净

```bash
# adb shell readelf -d /vendor/bin/wpa_cli           

Dynamic section at offset 0x264e8 contains 27 entries:
  Tag                Type                 Name/Value
 0x0000000000000001 (NEEDED)             Shared library: [libcutils.so]
 0x0000000000000001 (NEEDED)             Shared library: [liblog.so]
 0x0000000000000001 (NEEDED)             Shared library: [libc++.so]
 0x0000000000000001 (NEEDED)             Shared library: [libc.so]
 0x0000000000000001 (NEEDED)             Shared library: [libm.so]
 0x0000000000000001 (NEEDED)             Shared library: [libdl.so]
 ...
```


```bash
# adb shell readelf -d /vendor/bin/hw/wpa_supplicant

Dynamic section at offset 0x3b1b38 contains 42 entries:
  Tag                Type                 Name/Value
 0x0000000000000001 (NEEDED)             Shared library: [libcutils.so]
 0x0000000000000001 (NEEDED)             Shared library: [liblog.so]
 0x0000000000000001 (NEEDED)             Shared library: [libcrypto.so]
 0x0000000000000001 (NEEDED)             Shared library: [libssl.so]
 0x0000000000000001 (NEEDED)             Shared library: [libkeystore-engine-wifi-hidl.so]
 0x0000000000000001 (NEEDED)             Shared library: [libkeystore-wifi-hidl.so]
 0x0000000000000001 (NEEDED)             Shared library: [libnl.so]
 0x0000000000000001 (NEEDED)             Shared library: [libcert_parse.wpa_s.so]
 0x0000000000000001 (NEEDED)             Shared library: [android.hardware.wifi.supplicant-V3-ndk.so]
 0x0000000000000001 (NEEDED)             Shared library: [android.system.keystore2-V1-ndk.so]
 0x0000000000000001 (NEEDED)             Shared library: [libutils.so]
 0x0000000000000001 (NEEDED)             Shared library: [libbase.so]
 0x0000000000000001 (NEEDED)             Shared library: [libbinder_ndk.so]
 0x0000000000000001 (NEEDED)             Shared library: [vendor.qti.hardware.wifi.supplicant-V1-ndk.so]
 0x0000000000000001 (NEEDED)             Shared library: [vendor.oplus.hardware.wifi.supplicant-V5-ndk.so]
 0x0000000000000001 (NEEDED)             Shared library: [libc++.so]
 0x0000000000000001 (NEEDED)             Shared library: [libc.so]
 0x0000000000000001 (NEEDED)             Shared library: [libm.so]
 0x0000000000000001 (NEEDED)             Shared library: [libdl.so]
```

初步提取动态库

```bash
VENDOR_LIBS=(
    libkeystore-engine-wifi-hidl.so
    libkeystore-wifi-hidl.so
    libcert_parse.wpa_s.so
    android.hardware.wifi.supplicant-V3-ndk.so
    android.system.keystore2-V1-ndk.so
    vendor.qti.hardware.wifi.supplicant-V1-ndk.so
    vendor.oplus.hardware.wifi.supplicant-V5-ndk.so
)

for lib in "${VENDOR_LIBS[@]}"; do
    adb pull "/vendor/lib64/$lib" "$DEVICE_TREE/recovery/root/vendor/lib64/"
done
```

需要先测试一下，将二进制和依赖库放到设备 /tmp/wifi 下

```bash
adb shell mkdir -p /tmp/wifi
adb shell cp /vendor/bin/wpa_cli /tmp/wifi/
adb shell cp /vendor/bin/hw/wpa_supplicant /tmp/wifi/
for lib in "${VENDOR_LIBS[@]}"; do
    adb shell cp "/vendor/lib64/$lib" "/tmp/wifi/"
done

# unmount vendor

adb shell umount /vendor

adb shell /tmp/wifi/wpa_cli -h
adb shell "export LD_LIBRARY_PATH=/tmp/wifi && /tmp/wifi/wpa_supplicant -h"
```

wpa_cli 没问题，输出比较长就不贴了，wpa_supplicant 意料之中输出如下：

```bash
# adb shell "export LD_LIBRARY_PATH=/tmp/wifi && /tmp/wifi/wpa_supplicant -h"

CANNOT LINK EXECUTABLE "/tmp/wifi/wpa_supplicant": library "android.hardware.wifi.common-V1-ndk.so" not found: needed by /tmp/wifi/android.hardware.wifi.supplicant-V3-ndk.so in namespace (default)
```

这里就不挨个试错了，直接再次挂载 vendor 看符号

```bash
adb shell mount /vendor
for lib in "${VENDOR_LIBS[@]}"; do
    echo "Checking $lib dependencies..."
    adb shell "readelf -d /tmp/wifi/$lib | grep 'NEEDED'"
done
```

输出

```bash
Checking libkeystore-engine-wifi-hidl.so dependencies...
 0x0000000000000001 (NEEDED)             Shared library: [android.system.keystore2-V1-ndk.so]
 0x0000000000000001 (NEEDED)             Shared library: [libbase.so]
 0x0000000000000001 (NEEDED)             Shared library: [libbinder_ndk.so]
 0x0000000000000001 (NEEDED)             Shared library: [libcrypto.so]
 0x0000000000000001 (NEEDED)             Shared library: [liblog.so]
 0x0000000000000001 (NEEDED)             Shared library: [libcutils.so]
 0x0000000000000001 (NEEDED)             Shared library: [libutils.so]
 0x0000000000000001 (NEEDED)             Shared library: [libc++.so]
 0x0000000000000001 (NEEDED)             Shared library: [libc.so]
 0x0000000000000001 (NEEDED)             Shared library: [libm.so]
 0x0000000000000001 (NEEDED)             Shared library: [libdl.so]
Checking libkeystore-wifi-hidl.so dependencies...
 0x0000000000000001 (NEEDED)             Shared library: [android.system.wifi.keystore@1.0.so]
 0x0000000000000001 (NEEDED)             Shared library: [libbase.so]
 0x0000000000000001 (NEEDED)             Shared library: [libhidlbase.so]
 0x0000000000000001 (NEEDED)             Shared library: [liblog.so]
 0x0000000000000001 (NEEDED)             Shared library: [libutils.so]
 0x0000000000000001 (NEEDED)             Shared library: [libc++.so]
 0x0000000000000001 (NEEDED)             Shared library: [libc.so]
 0x0000000000000001 (NEEDED)             Shared library: [libm.so]
 0x0000000000000001 (NEEDED)             Shared library: [libdl.so]
Checking libcert_parse.wpa_s.so dependencies...
 0x0000000000000001 (NEEDED)             Shared library: [liblog.so]
 0x0000000000000001 (NEEDED)             Shared library: [libc++.so]
 0x0000000000000001 (NEEDED)             Shared library: [libc.so]
 0x0000000000000001 (NEEDED)             Shared library: [libm.so]
 0x0000000000000001 (NEEDED)             Shared library: [libdl.so]
Checking android.hardware.wifi.supplicant-V3-ndk.so dependencies...
 0x0000000000000001 (NEEDED)             Shared library: [libbinder_ndk.so]
 0x0000000000000001 (NEEDED)             Shared library: [android.hardware.wifi.common-V1-ndk.so]
 0x0000000000000001 (NEEDED)             Shared library: [libcutils.so]
 0x0000000000000001 (NEEDED)             Shared library: [libc++.so]
 0x0000000000000001 (NEEDED)             Shared library: [libc.so]
 0x0000000000000001 (NEEDED)             Shared library: [libm.so]
 0x0000000000000001 (NEEDED)             Shared library: [libdl.so]
Checking android.system.keystore2-V1-ndk.so dependencies...
 0x0000000000000001 (NEEDED)             Shared library: [libbinder_ndk.so]
 0x0000000000000001 (NEEDED)             Shared library: [android.hardware.security.keymint-V1-ndk.so]
 0x0000000000000001 (NEEDED)             Shared library: [libc++.so]
 0x0000000000000001 (NEEDED)             Shared library: [libc.so]
 0x0000000000000001 (NEEDED)             Shared library: [libm.so]
 0x0000000000000001 (NEEDED)             Shared library: [libdl.so]
Checking vendor.qti.hardware.wifi.supplicant-V1-ndk.so dependencies...
 0x0000000000000001 (NEEDED)             Shared library: [libbinder_ndk.so]
 0x0000000000000001 (NEEDED)             Shared library: [libc++.so]
 0x0000000000000001 (NEEDED)             Shared library: [libc.so]
 0x0000000000000001 (NEEDED)             Shared library: [libm.so]
 0x0000000000000001 (NEEDED)             Shared library: [libdl.so]
Checking vendor.oplus.hardware.wifi.supplicant-V5-ndk.so dependencies...
 0x0000000000000001 (NEEDED)             Shared library: [libbinder_ndk.so]
 0x0000000000000001 (NEEDED)             Shared library: [libc++.so]
 0x0000000000000001 (NEEDED)             Shared library: [libc.so]
 0x0000000000000001 (NEEDED)             Shared library: [libm.so]
 0x0000000000000001 (NEEDED)             Shared library: [libdl.so]
```

缺失依赖库如下，再拷贝到 /tmp/wifi 进行测试

```bash

MISSING_LIBS=(
    # libkeystore-wifi-hidl.so
    android.system.wifi.keystore@1.0.so
    # android.hardware.wifi.supplicant-V3-ndk.so
    android.hardware.wifi.common-V1-ndk.so
    # android.system.keystore2-V1-ndk.so
    android.hardware.security.keymint-V1-ndk.so
)
for lib in "${MISSING_LIBS[@]}"; do
    adb shell cp "/vendor/lib64/$lib" "/tmp/wifi/"
done
# umount vendor 后测试 wpa_supplicant
adb shell umount /vendor
adb shell "export LD_LIBRARY_PATH=/tmp/wifi && /tmp/wifi/wpa_supplicant -h"
```

但实际测试不要 `android.system.wifi.keystore@1.0.so` 也没问题，输出如下

```bash
➜  TWRP adb shell "export LD_LIBRARY_PATH=/tmp/wifi && /tmp/wifi/wpa_supplicant -h"
wpa_supplicant v2.11-devel-15
Copyright (c) 2003-2022, Jouni Malinen <j@w1.fi> and contributors

This software may be distributed under the terms of the BSD license.
See README for more details.

This product includes software developed by the OpenSSL Project
for use in the OpenSSL Toolkit (http://www.openssl.org/)

usage:
  wpa_supplicant [-BddhKLqqtvW] [-P<pid file>] [-g<global ctrl>] \
        [-G<group>] \
        -i<ifname> -c<config file> [-C<ctrl>] [-D<driver>] [-p<driver_param>] \
        [-b<br_ifname>] [-e<entropy file>] \
        [-o<override driver>] [-O<override ctrl>] \
        [-N -i<ifname> -c<conf> [-C<ctrl>] [-D<driver>] \
        [-m<P2P Device config file>] \
        [-p<driver_param>] [-b<br_ifname>] [-I<config file>] ...]
...
example:
  wpa_supplicant -Dnl80211 -iwlan0 -c/etc/wpa_supplicant.conf
```

---

### 4.4 方案 B：编译 wpa_supplicant_recovery（适用于 pure 方案）

#### 第一步：拉取 wpa_supplicant_8 源码

在 AOSP 源码树根目录创建 local manifest，单独同步该仓库：

```bash
mkdir -p .repo/local_manifests
cat > .repo/local_manifests/wpa_supplicant_8.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <project path="external/wpa_supplicant_8"
           name="platform/external/wpa_supplicant_8"
           remote="aosp"
           revision="refs/tags/android-16.0.0_r1" />
</manifest>
EOF
repo sync external/wpa_supplicant_8 -c --no-tags
# sync 后在 external/wpa_supplicant_8
```

> `refs/tags/android-16.0.0_r1`：Android 16 首个正式标签，与 TWRP A16 编译环境匹配。

---

### 4.6 现行方案说明：为什么 `wpa_supplicant_recovery` 必须定义在上游 Android.bp

```bash
module wpa_supplicant_recovery missing dependencies:
  module source path "vendor/twrp/wifi/src/drivers/driver_nl80211.c" does not exist
  ...（共 25 个）
```

**根本原因**：Soong 的相对路径规则——`defaults` 里的 `srcs` 和 `local_include_dirs` 相对路径，是相对**引用该 default 的 Android.bp 所在目录**解析的，而非 default 定义所在目录。

| Default 名称 | 内容 | 跨目录可用 |
|---|---|---|
| `wpa_supplicant_cflags_defaults` | 纯 `-DCONFIG_*` cflags | ✅ 是 |
| `wpa_supplicant_no_aidl_cflags_default` | 纯 cflags | ✅ 是 |
| `wpa_supplicant_driver_srcs_default` | `srcs: ["src/drivers/..."]` 相对路径 | ❌ 否 |
| `wpa_supplicant_includes_default` | `local_include_dirs: ["src", ...]` 相对路径 | ❌ 否 |

**解决**：将 `wpa_supplicant_recovery` 模块定义追加到 `external/wpa_supplicant_8/wpa_supplicant/Android.bp` 末尾，而不是放在 `vendor/twrp/wifi/Android.bp`。

追加内容如下

```bp
// TWRP recovery wpa_supplicant: no AIDL/binder, plain Unix socket ctrl_interface.
cc_binary {
    name: "wpa_supplicant_recovery",
    stem: "wpa_supplicant",
    recovery: true,
    defaults: [
        "wpa_supplicant_srcs_default",
        "wpa_supplicant_no_aidl_cflags_default",
        "wpa_supplicant_includes_default",
    ],
    srcs: ["src/crypto/evp_pkey_stub_recovery.c"],
    shared_libs: [
        "libcrypto",
        "libssl",
        "libcutils",
        "liblog",
        "libnl",
        "libutils",
        "libbase",
        "libc++",
    ],
}
```

---

### 4.8 现行方案说明：为什么需要 `EVP_PKEY_from_keystore` stub

```bash
ld.lld: error: undefined symbol: EVP_PKEY_from_keystore
>>> referenced by tls_openssl.c:1464
```

`tls_openssl.c` 调用了此 Android keystore 专属接口（WPA-EAP 企业级证书认证路径），不在 BoringSSL 里。去掉 `libkeystore-engine-wifi-hidl` 后直接编译会有未定义符号。`-DANDROID_LIB_STUB` 无效（此版本代码未用该宏保护）。

**最终解决**：创建 stub 文件，提供空实现满足链接器：

```c
// external/wpa_supplicant_8/wpa_supplicant/src/crypto/evp_pkey_stub_recovery.c
#include <openssl/evp.h>

EVP_PKEY *EVP_PKEY_from_keystore(const char *key_id)
{
    (void)key_id;
    return NULL;  // recovery 环境不需要 keystore（WPA-EAP 企业证书场景）
}
```

```bp
// external/wpa_supplicant_8/wpa_supplicant/Android.bp

// TWRP recovery wpa_supplicant: no AIDL/binder, plain Unix socket ctrl_interface.
cc_binary {
    name: "wpa_supplicant_recovery",
    stem: "wpa_supplicant",
    recovery: true,
    defaults: [
        "wpa_supplicant_srcs_default",
        "wpa_supplicant_no_aidl_cflags_default",
        "wpa_supplicant_includes_default",
    ],
    // add line
    srcs: ["src/crypto/evp_pkey_stub_recovery.c"],
    shared_libs: [
        "libcrypto",
        "libssl",
        "libcutils",
        "liblog",
        "libnl",
        "libutils",
        "libbase",
        "libc++",
    ],
}
```

然后需要将 `external/wpa_supplicant_8/wpa_supplicant/Android.bp` 中所有包含 "libkeystore-engine-wifi-hidl" 的依赖删掉

详细代码在 [wpa_supplicant_8](https://github.com/AuroraRecoveryProject)，但我我特么忘了这个库从哪儿 clone 下来的了，应该是从安卓某个分支



编译成功，产出 `wpa_supplicant_recovery`，`recovery: true` + `stem: "wpa_supplicant"` 使其打包到 recovery ramdisk 的 `/system/bin/wpa_supplicant`。

**设计合理性**：recovery 只需要 WPA2-Personal，根本用不到 keystore engine，空实现让链接通过，唯一"丢失"的是企业证书认证路径，recovery 场景本来就不需要。

---

## 五、文件清单

### 5.1 方案 A 新增文件（需在设备树中创建），以一加 `ossi` 方案为例

```bash
recovery/root/
├── init.recovery.wifi.rc          ← 所有 WiFi 服务、属性链定义
└── system/bin/
    ├── cp-wifi-ko.sh              ← 从各分区复制 .ko 的脚本
    ├── busybox                    ← 通用工具（可复用其他设备树的）
    ├── dhcpcd                     ← DHCP 客户端（可复用）
    └── wpa_cli                    ← 从本设备 /system/bin/wpa_cli 提取
```

### 5.2 从本设备提取（必须设备特定，不可跨设备复用）

当前提取文件的 wpa_cli/wpa_supplicant 和相关 so 库仅是 OEM 方案需要的

```bash
recovery/root/
├── system/bin/
│   ├── wpa_cli (OEM 方案)
├── vendor/bin/
│   ├── hw/wpa_supplicant (OEM 方案)
│   ├── cnss-daemon (OEM 方案)
│   └── qrtr-ns (OEM 方案)
├── vendor/lib64/
│   ├── libkeystore-engine-wifi-hidl.so (OEM 方案)
│   ├── libkeystore-wifi-hidl.so (OEM 方案)
│   ├── libcert_parse.wpa_s.so (OEM 方案)
│   ├── android.hardware.wifi.supplicant-V3-ndk.so (OEM 方案)
│   ├── android.system.keystore2-V1-ndk.so (OEM 方案)
│   ├── vendor.qti.hardware.wifi.supplicant-V1-ndk.so (OEM 方案)
│   └── vendor.oplus.hardware.wifi.supplicant-V5-ndk.so (OEM 方案)
│   └── android.hardware.wifi.common-V1-ndk.so (OEM 方案)
│   └── android.hardware.security.keymint-V1-ndk.so (OEM 方案)
└── vendor/etc/vintf/manifest/
    └── android.hardware.wifi.supplicant.xml  ← HAL 版本声明
```

但是 [twrp_device_oplus_sm86xx](https://github.com/adontoo/twrp_device_oplus_sm86xx) 和 [twrp_device_xiaomi_sm8750_thales](https://github.com/adontoo/twrp_device_xiaomi_sm8750_thales) 还用到了 rmt_storage，但在我 ossi 中没有这个，就不管了

### 5.3 提取命令（在设备连接状态下执行）

```bash
OSSI_ROOT=twrp_device_oplus_ossi/recovery/root

# 二进制
adb pull /vendor/bin/hw/wpa_supplicant  $OSSI_ROOT/vendor/bin/hw/
adb pull /vendor/bin/cnss-daemon         $OSSI_ROOT/vendor/bin/
adb pull /vendor/bin/qrtr-ns             $OSSI_ROOT/vendor/bin/
adb pull /vendor/bin/wpa_cli             $OSSI_ROOT/system/bin/

VENDOR_LIBS=(
    libkeystore-engine-wifi-hidl.so
    libkeystore-wifi-hidl.so
    libcert_parse.wpa_s.so
    android.hardware.wifi.supplicant-V3-ndk.so
    android.system.keystore2-V1-ndk.so
    vendor.qti.hardware.wifi.supplicant-V1-ndk.so
    vendor.oplus.hardware.wifi.supplicant-V5-ndk.so
    # libkeystore-wifi-hidl.so
    android.system.wifi.keystore@1.0.so
    # android.hardware.wifi.supplicant-V3-ndk.so
    android.hardware.wifi.common-V1-ndk.so
    # android.system.keystore2-V1-ndk.so
    android.hardware.security.keymint-V1-ndk.so
)

for lib in "${VENDOR_LIBS[@]}"; do
    adb pull "/vendor/lib64/$lib" "$OSSI_ROOT/vendor/lib64/"
done

# VINTF manifest
mkdir -p $OSSI_ROOT/vendor/etc/vintf/manifest/
adb pull /vendor/etc/vintf/manifest/android.hardware.wifi.supplicant.xml \
    $OSSI_ROOT/vendor/etc/vintf/manifest/
```

---

## 六、设备适配参数（移植到新设备必须核对）

在创建 `init.recovery.wifi.rc` 和 `cp-wifi-ko.sh` 之前，先在设备上确认以下四个关键参数：

### 6.1 平台代号（决定 fs_ready 路径）

```bash
# 需要手动 bring-ip wifi 模块
# 见 https://github.com/AuroraRecoveryProject/aurora_recovery/blob/main/docs/WIFI/TWRP%20QCOM%20WIFI%20%E6%89%8B%E5%8A%A8%E5%90%AF%E5%8A%A8%E5%85%A8%E6%B5%81%E7%A8%8B.md

# adb shell ls /sys/bus/platform/drivers/cnss2/

b0000000.qcom,cnss-peach
bind
cnss_debug
device_id
firmware_ready
module
uevent
unbind
```

得到 fs_ready 完整路径：

```bash
/sys/devices/platform/soc/b0000000.qcom,cnss-peach/firmware_ready
```

| 平台 | 代号 | fs_ready 路径末段 |
| --- | --- | --- |
| Snapdragon 8 Gen 3（sun） | sun | `b0000000.qcom,cnss-sun` |
| Snapdragon 8 Gen 3（pineapple） | kiwi | `b0000000.qcom,cnss-kiwi` |
| Snapdragon 8 Elite（canoe/peach） | peach | `b0000000.qcom,cnss-peach` |

**TODO: 测一下一加15是什么代号**

### 6.2 WiFi 驱动模块名

**TODO: prepare_gpu.sh 中的 msm_kgsl.ko 是不是也在这**

```bash
# adb shell find /vendor_dlkm /tmp/vendor/lib/modules -name "qca_cld3_*.ko" 2>/dev/null

/vendor_dlkm/lib/modules/qca_cld3_kiwi_v2.ko
/vendor_dlkm/lib/modules/qca_cld3_peach.ko
/vendor_dlkm/lib/modules/qca_cld3_peach_v2.ko
/tmp/vendor/lib/modules/qca_cld3_peach_v2.ko
/tmp/vendor/lib/modules/qca_cld3_peach.ko
/tmp/vendor/lib/modules/qca_cld3_kiwi_v2.ko
```

### 6.3 smem-mailbox.ko 是否存在于 vendor_boot tmpfs

我忘了 /tmp/vendor/lib/modules/ 里面是啥了

```bash
adb shell ls /tmp/vendor/lib/modules/smem-mailbox.ko 2>/dev/null
```

存在则在 `init.recovery.wifi.rc` 的 `on property:twrp.cpko=true` 第一行加：

```bash
insmod /tmp/vendor/lib/modules/smem-mailbox.ko
```

### 6.4 各模块分布位置

```bash
# adb shell find /vendor_dlkm /system_dlkm -name "*.ko" 2>/dev/null | grep -E "cnss|rfkill|cfg80211|qca_cld3|gsim|rmnet|ipam|wlan_firmware_service"

/vendor_dlkm/lib/modules/cfg80211.ko
/vendor_dlkm/lib/modules/cnss2.ko
/vendor_dlkm/lib/modules/cnss_nl.ko
/vendor_dlkm/lib/modules/cnss_plat_ipc_qmi_svc.ko
/vendor_dlkm/lib/modules/cnss_prealloc.ko
/vendor_dlkm/lib/modules/cnss_utils.ko
/vendor_dlkm/lib/modules/gsim.ko
/vendor_dlkm/lib/modules/icnss2.ko
/vendor_dlkm/lib/modules/ipam.ko
/vendor_dlkm/lib/modules/qca_cld3_kiwi_v2.ko
/vendor_dlkm/lib/modules/qca_cld3_peach.ko
/vendor_dlkm/lib/modules/qca_cld3_peach_v2.ko
/vendor_dlkm/lib/modules/rmnet_aps.ko
/vendor_dlkm/lib/modules/rmnet_core.ko
/vendor_dlkm/lib/modules/rmnet_ctl.ko
/vendor_dlkm/lib/modules/rmnet_mem.ko
/vendor_dlkm/lib/modules/rmnet_offload.ko
/vendor_dlkm/lib/modules/rmnet_perf.ko
/vendor_dlkm/lib/modules/rmnet_perf_tether.ko
/vendor_dlkm/lib/modules/rmnet_sch.ko
/vendor_dlkm/lib/modules/rmnet_shs.ko
/vendor_dlkm/lib/modules/rmnet_wlan.ko
/vendor_dlkm/lib/modules/wlan_firmware_service.ko
/system_dlkm/lib/modules/rfkill.ko
```

分析依赖关系核心原则，**拓扑排序**

modules.dep 给出了每个模块依赖哪些模块，但不直接给出线性顺序。需要把 DAG 展开，保证被依赖的模块先加载。

具体步骤

#### 6.4.1. 用 modules.dep 确定硬依赖

```bash
qca_cld3_peach_v2 依赖 → cnss2, wlan_firmware_service, cnss_prealloc, cnss_utils, 
                         cfg80211, rfkill, gsim, rmnet_mem, ipam, smem-mailbox, ...
```

#### 6.4.2. 把每个中间模块的依赖也展开

比如 cfg80211 依赖 rfkill（从 modules.dep 里能看到 cfg80211.ko: rfkill.ko），所以 rfkill 一定在 cfg80211 前。

#### 6.4.3. 对精简后的模块集合做拓扑排序

从 modules.dep 那 40 个里剔除不需要的（oplus_chg_v2、dwc3-msm 等与 WiFi 无关的），对剩余的 12 个模块排序：

```bash
smem-mailbox          ← 最底层 IPC，无依赖
  ↓
cnss_prealloc         ← 只依赖 smem-mailbox（wcnss_prealloc_get/put 符号）
cnss_utils            ← 依赖 smem-mailbox
cnss_plat_ipc_qmi_svc ← 依赖 qmi_helpers, smem 等底层
cnss_nl               ← netlink 通道
  ↓
wlan_firmware_service ← 依赖上面几个 + QMI 栈
  ↓
cnss2                 ← 依赖 wlan_firmware_service（wlfw 符号）
  ↓
rfkill → cfg80211     ← cfg80211 依赖 rfkill
gsim, rmnet_mem, ipam ← 被 qca_cld3 引用，彼此独立
  ↓
qca_cld3_peach_v2     ← 最后加载
4. 同一层内顺序不一定影响加载
```

cnss_utils / cnss_plat_ipc_qmi_svc / cnss_nl 之间、gsim / rmnet_mem / ipam 之间没有相互依赖，顺序可以调换。验证方式：

- 查 A 是否依赖 B: grep "^模块A:" /vendor_dlkm/lib/modules/modules.dep | grep -o "模块B"，没输出 = 无依赖
- 用 readelf -s | grep UND 确认每个模块的未定义符号由前面哪个模块提供。如果加载顺序不对，insmod 直接报 Unknown symbol：

cnss2 在 wlan_firmware_service 之前加载就会报：

```bash
cnss2: Unknown symbol wlfw_respond_get_info_ind_msg_v01_ei
```

这就是顺序的最终验证——insmod 不报错，按这顺序全通过，就证明顺序正确。

还有个简单方法，抄别人的，相近 CPU 的设备树

---

## 七、配置文件模板

### 7.1 init.recovery.wifi.rc 模板

下面先给出 OEM 与 pure 方案共用的骨架，再给出各自需要替换的差异块。

#### 7.1.1 公共骨架

```rc
on property:twrp.modules.loaded=true
    write /dev/kmsg "[wifi] Starting module copy..."
    write /proc/sys/kernel/firmware_config/force_sysfs_fallback 1
    start cp-wifi-ko

on property:twrp.cpko=true
    # 若设备有 smem-mailbox.ko 则取消下行注释
    # insmod /tmp/vendor/lib/modules/smem-mailbox.ko
    wait /odm/wifi/modules/cnss_prealloc.ko
    insmod /odm/wifi/modules/cnss_prealloc.ko
    wait /odm/wifi/modules/cnss_nl.ko
    insmod /odm/wifi/modules/cnss_nl.ko
    wait /odm/wifi/modules/wlan_firmware_service.ko
    insmod /odm/wifi/modules/wlan_firmware_service.ko
    wait /odm/wifi/modules/cnss_plat_ipc_qmi_svc.ko
    insmod /odm/wifi/modules/cnss_plat_ipc_qmi_svc.ko
    wait /odm/wifi/modules/cnss_utils.ko
    insmod /odm/wifi/modules/cnss_utils.ko
    wait /odm/wifi/modules/cnss2.ko
    insmod /odm/wifi/modules/cnss2.ko
    wait /odm/wifi/modules/gsim.ko
    insmod /odm/wifi/modules/gsim.ko
    wait /odm/wifi/modules/rmnet_mem.ko
    insmod /odm/wifi/modules/rmnet_mem.ko
    wait /odm/wifi/modules/ipam.ko
    insmod /odm/wifi/modules/ipam.ko
    wait /odm/wifi/modules/rfkill.ko
    insmod /odm/wifi/modules/rfkill.ko
    wait /odm/wifi/modules/cfg80211.ko
    insmod /odm/wifi/modules/cfg80211.ko
    setprop twrp.insmodko 1

on init
    ######## WiFi prepare directories
    write /dev/kmsg "[jasonwifi][prepare-files] WiFi prepare started"
    # wpa_cli (drops to uid=wifi) needs to bind a temp socket in /tmp
    # 自编译 wpa_cli_recovery 必须加，原生 OEM wpa_cli 不影响但加了也无害
    chown root wifi /tmp
    chmod 0775 /tmp
    mkdir /data/misc 0777 root shell
    mkdir /data/misc/wifi 0777 root shell
    mkdir /data/vendor 0777 root root
    mkdir /data/vendor/firmware 0777 root root
    mkdir /data/vendor/firmware/update 0777 root root
    mkdir /data/vendor/firmware/update/wlan 0777 root root
    copy /vendor/etc/wifi/wlan/WCNSS_qcom_cfg.ini /data/vendor/firmware/update/wlan/WCNSS_qcom_cfg.ini
    write /dev/kmsg "[jasonwifi][prepare-files] WiFi prepare done"

on boot
    ######## WiFi boot env
    write /sys/kernel/cnss/recovery 3
    chown radio wakelock /sys/power/wake_lock
    chown radio wakelock /sys/power/wake_unlock
    chmod 0660 /sys/power/wake_lock
    chmod 0660 /sys/power/wake_unlock

# 测试 Oplus15/OplusPad2Pro 不要这个也没问题
service vendor.qrtr-ns /vendor/bin/qrtr-ns -f
    disabled
    user root
    group root
    capabilities NET_BIND_SERVICE
    seclabel u:r:recovery:s0

# 测试 Oplus15/OplusPad2Pro 不要这个也没问题
service cnss-daemon /vendor/bin/cnss-daemon -n -l
    disabled
    user root
    group root system inet net_admin wifi
    capabilities NET_ADMIN
    seclabel u:r:recovery:s0

# 核心进程，负责创建 ctrl_interface socket，接收 wpa_cli 命令
service wpa_supplicant /system/bin/wpa_supplicant -Dnl80211 -iwlan0 -dd -O/tmp/recovery/sockets -c/vendor/etc/wifi/wpa_supplicant.conf
    disabled
    seclabel u:r:recovery:s0

# 方便获取 DHCP 分配的 IP 地址，实际是直接调用的命令行
service dhcpcd /system/bin/dhcpcd wlan0 -B
    disabled
    oneshot
    seclabel u:r:recovery:s0

# 拷贝驱动文件
# TODO: 试试直接先拷贝到设备树呢？不然还得依赖正常的 vendor_dlkm, system_dlkm
service cp-wifi-ko /system/bin/cp-wifi-ko.sh
    disabled
    oneshot
    seclabel u:r:recovery:s0

on property:twrp.insmodko=1
    start vendor.qrtr-ns
    setprop qcomwlan.driver.load true

on property:qcomwlan.driver.load=true
    # 将 cnss-peach 替换为实际平台代号（见六.1）
    write /sys/devices/platform/soc/b0000000.qcom,cnss-peach/fs_ready 1
    # 将 qca_cld3_peach_v2.ko 替换为实际驱动名（见六.2）
    wait /odm/wifi/modules/qca_cld3_peach_v2.ko
    insmod /odm/wifi/modules/qca_cld3_peach_v2.ko
    wait /sys/class/net/wlan0 10
    setprop jasonwifi.driver.ready true

on property:twrp.insmodko=1
    setprop survival.start.service true
    setprop qcomwlan.driver.load true

on property:jasonwifi.driver.ready=true
    mkdir /tmp/recovery 0777 root root
    mkdir /tmp/recovery/sockets 0777 root root
    start wpa_supplicant

on property:supplicant.status=running
    start wpa_supplicant

on property:supplicant.status=stopped
    stop wpa_supplicant
```

---

### 7.2 cp-wifi-ko.sh 模板

将以下内容另存为 `recovery/root/system/bin/cp-wifi-ko.sh`

```sh
#!/system/bin/sh

# Do not copy in fastbootd mode
FASTBOOTD_PROP=$(getprop ro.twrp.fastbootd)
if [ "$FASTBOOTD_PROP" = "1" ]; then
    echo "I:cp-wifi-ko.sh: Detected fastbootd (ro.twrp.fastbootd=1), exit script." >> /tmp/recovery.log
    exit 0
fi

mount /vendor_dlkm
mount /system_dlkm

LOG_TAG="I:cp-wifi-ko.sh"
TARGET_DIR="/odm/wifi/modules"
SEARCH_DIRS="/tmp/vendor/lib/modules /vendor_dlkm /system_dlkm"
KO_FILES="cnss_prealloc.ko cnss_nl.ko wlan_firmware_service.ko cnss_plat_ipc_qmi_svc.ko cnss_utils.ko cnss2.ko gsim.ko rmnet_mem.ko ipam.ko rfkill.ko cfg80211.ko qca_cld3_peach_v2.ko"

log_print() {
    echo "$LOG_TAG: $1" >> /tmp/recovery.log
}

if [ ! -d "$TARGET_DIR" ]; then
    log_print "Creating target dir: $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
    if [ $? -ne 0 ]; then
        log_print "Error: unable to create $TARGET_DIR"
        exit 1
    fi
fi

chmod 0755 "$TARGET_DIR"

log_print "Search and copy wifi ko files..."

found_count=0
copied_count=0

for ko_file in $KO_FILES; do
    file_found=0
    for search_dir in $SEARCH_DIRS; do
        if [ -d "$search_dir" ]; then
            file_path=$(find "$search_dir" -type f -name "$ko_file" 2>/dev/null | head -1)
            if [ -n "$file_path" ] && [ -f "$file_path" ]; then
                file_found=1
                target_file="$TARGET_DIR/$ko_file"
                if [ ! -f "$target_file" ]; then
                    log_print "Copy: $file_path -> $target_file"
                    cp "$file_path" "$target_file"
                    if [ $? -eq 0 ]; then
                        chmod 0644 "$target_file"
                        copied_count=$((copied_count + 1))
                        log_print "Copy successfully: $ko_file"
                    else
                        log_print "Error: Copy failed:  $ko_file"
                    fi
                else
                    log_print "Skip existing file: $ko_file"
                fi
                break
            fi
        else
            log_print "Warning: The search directory does not exist: $search_dir"
        fi
    done
    
    if [ $file_found -eq 1 ]; then
        found_count=$((found_count + 1))
    else
        log_print "Unable to found: $ko_file"
    fi
done

log_print "Copy done: $found_count files found, $copied_count files copied."
log_print "Target dir files:"
ls -la "$TARGET_DIR" 2>/dev/null | while read line; do
    log_print "$line"
done

resetprop twrp.cpko "true"

exit 0
```

---

### 7.3 init.recovery.qcom.rc 修改

在 license 注释之后、第一个 `on` 节之前，添加 import：

```rc
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

import /init.recovery.wifi.rc    ← 添加这一行

on early-fs
    ...
```

---

## 八、内核模块加载链

### 8.1 模块分布

| 路径 | 内容 | 说明 |
| --- | --- | --- |
| `/vendor_dlkm/lib/modules/` | `cnss2.ko`、`cfg80211.ko`、`gsim.ko`、`rmnet_mem.ko`、`ipam.ko`、`qca_cld3_peach_v2.ko` | 需要先 `mount /vendor_dlkm` |
| `/system_dlkm/lib/modules/` | `rfkill.ko` | 需要先 `mount /system_dlkm` |

`smem-mailbox.ko` 文件名有连字符：`/proc/modules` 里显示 `smem_mailbox`（下划线），但文件名是 `smem-mailbox.ko`（连字符），`insmod` 必须用正确文件名。

### 8.2 完整加载顺序

```bash
① smem-mailbox          ← /tmp/vendor/lib/modules/（连字符！）
② cnss_prealloc         ← /vendor_dlkm/lib/modules/
③ cnss_utils            ← 依赖 smem_mailbox_* 符号
④ cnss_plat_ipc_qmi_svc
⑤ cnss_nl
⑥ wlan_firmware_service ← cnss2 强依赖此模块的符号（wlfw QMI / IMS）
⑦ cnss2                 ← 加载后等待 sysfs fs_ready 节点出现
       ↓
   echo 1 > fs_ready  → 内核 request_firmware("peach/amss.bin") → 芯片固件下载
       ↓
⑧ rfkill               ← /system_dlkm/lib/modules/
⑨ cfg80211             ← /vendor_dlkm/lib/modules/
⑩ gsim
⑪ rmnet_mem
⑫ ipam
⑬ qca_cld3_peach_v2    ← 加载后 ~10s，wlan0 出现
```

若跳过 ⑥（`wlan_firmware_service`），cnss2 加载时会报：

```bash
cnss2: Unknown symbol wlfw_respond_get_info_ind_msg_v01_ei (err -2)
```

### 8.3 坑：fs_ready 路径与权限

`cnss2` 加载后在 sysfs 创建一个节点，等待用户空间写 `1` 后才触发固件下载：

```bash
/sys/bus/platform/drivers/cnss2/b0000000.qcom,cnss-peach/fs_ready
```

**坑 1**：`find /sys -name fs_ready` 无法可靠找到它。sysfs 不是真实文件系统，`find` 无法遍历部分动态目录。

**坑 2**：该文件权限 `--w------- root:root`，某些 shell context 下即使是 root 也写入失败。需先 `chmod 222`。

## 九、wpa_supplicant 权限问题

只在自编译 wpa_* 方案出现

### 9.1 根本原因：Android 强制降权

`wpa_supplicant` 源码 `os_program_init()`（`os_unix.c`）在启动时：

```c
setuid(AID_WIFI);  // uid=1010
setgid(AID_WIFI);  // gid=1010
```

即使通过 root shell 启动也会降权，这是 Android 安全设计。`AID_WIFI = 1010`，`id wifi = uid=1010(wifi)`（设备实测）。

### 9.2 当前稳定方案：统一使用 `/tmp/recovery/sockets`

当前 `ossi` 与 `ossi_pure` 的稳定配置，都是让 `wpa_supplicant` 使用：

```sh
-O/tmp/recovery/sockets
```

对应地，`wpa_cli` 也统一使用：

```sh
wpa_cli -p /tmp/recovery/sockets -i wlan0 ping
```

实测 `/data/misc/wifi/wpa_supplicant` 路线同样可用，但当前设备树 RC 统一采用 `/tmp/recovery/sockets`，文档以 RC 实际配置为准。

### 9.3 关键权限点：自编译版需要让 `/tmp` 对 `wifi` 可写

`wpa_cli` 同样会降权到 `wifi`。对自编译版来说，它创建本地临时应答 socket 时会实际写入 `/tmp`，因此必须先给 `/tmp` 补 `wifi` 组写权限：

```sh
chown root:wifi /tmp
chmod g+w /tmp   # 775 → 允许 wifi 组写入
```

OEM 与自编译版为什么表现不同、`-p` 参数为什么不决定本地临时 socket 的 `bind()` 目录、以及 `strace` 是如何确认这一点的，见[十四、wpa_cli /tmp 权限问题（自编译版专有）](#十四wpa_cli-tmp-权限问题自编译版专有)，这里不再重复。

---

## 十、WiFi 连接与 DHCP

### 10.1 WiFi 扫描与连接

```sh
WPA="wpa_cli -p /tmp/recovery/sockets -i wlan0"

# 扫描
$WPA scan && sleep 5 && $WPA scan_results

# 添加网络并连接
ID=$($WPA add_network | tail -1)
$WPA set_network $ID ssid '"SSID名称"'
$WPA set_network $ID psk '"WiFi密码"'
$WPA enable_network $ID
$WPA select_network $ID

# 确认连接（约 4s 后）
$WPA status
# wpa_state=COMPLETED, wifi_generation=6 → WiFi 6 连接成功
```

### 10.2 DHCP 方案对比

| 方案 | 需额外二进制 | 自动设置默认路由 | 备注 |
|---|---|---|---|
| A. toybox dhcp + ip route | 需要 iproute2（含 `ip` 命令） | ❌ 需手动执行 | recovery 内置 toybox dhcp，无需 push |
| B. dhcpcd | 需要 push 或打包 dhcpcd 二进制 | ✅ 全自动 | **推荐**，一条命令搞定 |

### 10.3 方案 A：toybox dhcp + ip route

```sh
# 1. 获取 DHCP 租约（只输出租约信息，不配置接口）
# adb shell toybox dhcp -i wlan0
dhcp started
dhcp started
Sending discover...
Sending select for 192.168.31.150...
Lease of 192.168.31.150 obtained, lease time 43200 from server 192.168.31.1

# 2. 手动配置 IP 和路由
# 启用网卡
ip link set wlan0 up
# 查看当前状态
ip addr show wlan0
ip addr flush dev wlan0
# 手动添加 IP 和路由
ip addr add 192.168.31.150/24 dev wlan0
ip route add default via 192.168.31.1 dev wlan0
ip route
```

获取 `ip` 命令：`packages.mk` 加 `PRODUCT_PACKAGES += iproute2`，或临时推送静态编译版。

### 10.4 方案 B：dhcpcd

```sh
dhcpcd wlan0
```

实测输出：

```bash
DUID 00:01:00:01:31:9c:6f:c6:00:03:7f:12:e7:68
dhcpcd_selectprofile: No buffer space available
wlan0: connected to Access Point: Laurie Lin 5G
wlan0: IAID 7f:12:e7:68
wlan0: soliciting an IPv6 router
wlan0: Router Advertisement from fe80::a6a9:30ff:fe83:b4cf
wlan0: adding address 240e:39d:20:8070:203:7fff:fe12:1a92/64
wlan0: adding route to 240e:39d:20:8070::/64
wlan0: adding default route via fe80::a6a9:30ff:fe83:b4c
```

获取 dhcpcd 二进制：从同架构类似设备（如 sm86xx）设备树直接复制，版本 6.8.2 实测可用。

### 10.5 ping 权限问题

Recovery 环境 ICMP socket 权限受限，测试连通前需放开：

```sh
echo '0 2147483647' > /proc/sys/net/ipv4/ping_group_range
toybox ping -c 3 223.5.5.5
```

---

## 十一、关键背景知识

### 11.1 AIDL HAL 版本（V3 从哪里看出来的）

1. **so 文件名**：`android.hardware.wifi.supplicant-V3-ndk.so`，`-V3-` 即版本号
2. **VINTF manifest**：`/vendor/etc/vintf/manifest/android.hardware.wifi.supplicant.xml` 中的 `<version>3</version>`

### 11.2 VINTF manifest 目录规则

servicemanager 在注册/查找 AIDL HAL 时，会检查 VINTF manifest 确认该 HAL 已声明：

- **device manifest**（放设备 HAL 声明）：`vendor/etc/vintf/manifest/` ← **必须放这里**
- **framework manifest**（放系统服务声明）：`system/etc/vintf/manifest/` ← 放设备 HAL 会报错 `Cannot add a device manifest to a framework manifest`

对应 ramdisk 路径：
```
recovery/root/vendor/etc/vintf/manifest/android.hardware.wifi.supplicant.xml
```

### 11.3 servicemanager VINTF 时序问题与循环符号链接

**问题链**：

1. servicemanager 在 recovery 启动早期启动，此时扫描 VINTF 并缓存结果；若此时存在符号链接异常，结果为空
2. ossi 的 `/odm/etc` → `/vendor/odm/etc`（`/vendor/odm` symlink 指向 `/odm`）形成**循环符号链接**，servicemanager 扫描 device VINTF 时触发 `ELOOP`，整个 device manifest 解析返回 NULL
3. 即使 VINTF manifest 文件已放入 `recovery/root/vendor/etc/vintf/manifest/`，也因 ELOOP 被跳过，导致 `Could not find ISupplicant/default in the VINTF manifest`

**根因**：

```bash
/odm/etc  →（symlink）→  /vendor/odm/etc
/vendor/odm  →（symlink）→  /odm        ← 循环！
```

**解决方案**：`init.recovery.qcom.rc` 在 `twrp.modules.loaded=true` 时会 `umount /vendor`，此后 `/vendor/odm` 消失，循环链自动断开。在 WiFi 驱动加载完成后（`jasonwifi.driver.ready=true`，此时 `/vendor` 已 umount），重启 servicemanager，则：

- 循环链不存在 → ELOOP 消失
- ramdisk 中的 `vendor/etc/vintf/manifest/` 仍然可见
- servicemanager 成功读取 manifest → `ISupplicant/default` 可正常注册

---

## 十二、调试手段

### 查看 WiFi 启动日志

```bash
adb shell dmesg | grep jasonwifi
adb shell cat /tmp/recovery.log | grep cp-wifi
```

### 验证模块是否加载

```bash
adb shell lsmod | grep -E "cnss|cfg80211|qca_cld3|rfkill"
```

### 验证 wpa_supplicant 是否运行

```bash
adb shell ps -A | grep wpa_supplicant
adb shell ls /tmp/recovery/sockets/
```

### 手动触发 WiFi 初始化（调试用）

```bash
adb shell setprop twrp.modules.loaded true
```

### 确认 servicemanager 能否找到 VINTF 声明的 HAL

```bash
adb shell logcat -d | grep -i "servicemanager\|supplicant\|vintf"

# 检查 ELOOP 循环链接
adb shell readlink /odm           # 若输出含 /vendor/odm，与下面形成循环
adb shell readlink /vendor/odm    # 若输出 /odm，则形成 /odm→/vendor/odm→/odm 循环
```

### 排查 TWRP 卡第一屏（进不去主界面）

**第一步：确认 recovery 进程是否在跑**

```bash
adb shell ps -A | grep recovery
# 若进程存在但卡住，说明主线程阻塞
```

**第二步：找阻塞点**

```bash
adb shell logcat -d | grep -i "Waiting for service"
# 典型输出：Waiting for service 'android.hardware.security.keymint.IKeyMintDevice/default'
```

**第三步：找 HAL 未启动的原因**

```bash
adb shell logcat -d | grep "CANNOT LINK"
# 典型输出：CANNOT LINK EXECUTABLE ".../keymint-service-qti": library "libqtikeymint.so" not found

adb shell mount | grep vendor
# 若只有 vendor_dlkm 而无 /vendor，说明 /vendor 已被 umount
```

**第四步：对比设备树的 vendor/lib64 差异**

```bash
diff <(ls device_tree/twrp_device_oplus_ossi/recovery/root/vendor/lib64/ | sort) \
     <(ls device_tree/twrp_device_oplus_ossi_pure/recovery/root/vendor/lib64/ | sort)
```

---

## 十三、排查案例

### 13.1 TWRP GUI 无法扫描 WiFi（ossi，2026-03-07）

本节完整记录从「WiFi GUI 不工作」到「根因定位 + 修复」的排查过程。

#### 症状

设备树构建并刷入 recovery 后，进入 TWRP，点击 WiFi → Scan，列表为空，无任何 AP 出现。

#### 第一步：确认哪个进程崩溃

```bash
adb shell logcat -d | grep -E "CANNOT LINK|wpa_supplicant|Failed"
```

```
Cannot link executable /vendor/bin/hw/wpa_supplicant: library "android.hardware.wifi.supplicant-V3-ndk.so" not found
```

**结论**：linker 找不到 AIDL HAL 接口库，进程直接退出。

#### 第二步：搞清楚缺哪些库

通过 `readelf` 列出 wpa_supplicant 的完整 NEEDED 列表（19 个），再解包 recovery 镜像对比，发现只有以下 4 个缺失：

- `android.hardware.wifi.supplicant-V3-ndk.so`
- `android.system.keystore2-V1-ndk.so`
- `vendor.qti.hardware.wifi.supplicant-V1-ndk.so`
- `vendor.oplus.hardware.wifi.supplicant-V5-ndk.so`

从设备 `/vendor/lib64/` pull 这 4 个文件到设备树 `vendor/lib64/`。

> 最初误将 `libbinder.so` 和 `libbinder_ndk.so` 也加进设备树，实测发现反而导致符号冲突（recovery 自带版本更新）。

#### 第三步：库补齐后 wpa_supplicant 能启动，但 AIDL 注册失败

```
wpa_supplicant: Failed to initialize wpa_supplicant
servicemanager: Could not find android.hardware.wifi.supplicant.ISupplicant/default in the VINTF manifest
```

wpa_supplicant 链接成功，但 servicemanager 的 VINTF 缓存里没有 `ISupplicant/default` 条目。

#### 第四步：确认 VINTF manifest 版本

1. **so 文件名**：`android.hardware.wifi.supplicant-V3-ndk.so`，`-V3-` 即版本号
2. **设备上的 manifest XML**：`<version>3</version>`

manifest 必须放进 `vendor/etc/vintf/manifest/`（device manifest，**不是** `system/etc/vintf/manifest/`）：

```bash
mkdir -p $OSSI/vendor/etc/vintf/manifest/
adb pull /vendor/etc/vintf/manifest/android.hardware.wifi.supplicant.xml \
    $OSSI/vendor/etc/vintf/manifest/
```

#### 第五步：manifest 加进去了，仍然报找不到

logcat 里发现：

```bash
servicemanager: Failed to parse device manifest: ELOOP (Too many levels of symbolic links)
```

**根因**：ramdisk 中存在循环符号链接 `/odm → /vendor/odm → /odm`，servicemanager 启动时递归扫描 VINTF 触发 ELOOP，整个 device manifest 解析返回 NULL。

```bash
adb shell readlink /odm          # 输出含 /vendor/odm
adb shell readlink /vendor/odm   # 输出 /odm ← 形成循环
```


servicemanager 重启后循环链不存在，VINTF 成功读取，wpa_supplicant 正常初始化。

#### 修复汇总

| 问题 | 根因 | 操作 |
| --- | --- | --- |
| `CANNOT LINK: V3-ndk.so not found` | 4 个 AIDL HAL so 未放入 ramdisk | 从设备 pull → 设备树 `vendor/lib64/` |
| `ISupplicant/default not in VINTF manifest` | VINTF manifest 未放入 ramdisk | 从设备 pull XML → 设备树 `vendor/etc/vintf/manifest/` |
| manifest 放了仍报找不到 | `/odm→/vendor/odm→/odm` 循环链导致 ELOOP | 在 `jasonwifi.driver.ready=true` 重启 servicemanager |

---

### 13.2 TWRP 卡第一屏（ossi_pure，keymint 缺库）

#### 症状

刷入 recovery 后，TWRP 卡在第一屏，进不去主界面。

#### 根因链

```
/vendor umount
  → keymint-service-qti 需要 libqtikeymint.so
  → /vendor 已挂走，找不到
  → 反复崩溃
  → keystore2 永久等待 IKeyMintDevice/default
  → recovery 主线程阻塞
  → 卡第一屏
```

#### 排查过程

```bash
# 步骤 1：确认进程存在但阻塞
adb shell ps -A | grep recovery

# 步骤 2：找阻塞点
adb shell logcat -d | grep "Waiting for service"
# 输出：Waiting for service 'android.hardware.security.keymint.IKeyMintDevice/default'

# 步骤 3：找缺失库
adb shell logcat -d | grep "CANNOT LINK"
# 输出：keymint-service-qti: library "libqtikeymint.so" not found

# 步骤 4：确认 /vendor 已 umount
adb shell mount | grep vendor
# 只有 vendor_dlkm，无 /vendor → umount 后库在设备树 vendor/lib64/ 里找
```

#### 修复

从 ossi 设备树复制两个缺失文件到 ossi_pure 设备树：

```bash
cp ossi/recovery/root/vendor/lib64/libqtikeymint.so \
   ossi_pure/recovery/root/vendor/lib64/

cp ossi/recovery/root/vendor/lib64/android.hardware.security.keymint-V1-ndk.so \
   ossi_pure/recovery/root/vendor/lib64/
```

**根源**：派生 ossi_pure 时只关注删除 WiFi AIDL so，忽略了保留 keymint 相关库。从已有设备树派生时，`vendor/lib64/` 不能随意删除，需逐一确认每个库的用途。

---

## 十四、wpa_cli /tmp 权限问题（自编译版专有）

### 14.1 背景

`ossi_pure`、`infiniti` 等设备树使用自编译的 `wpa_supplicant_recovery`（`recovery: true`，无 AIDL），配套 `wpa_cli` 也是自编译版（`wpa_cli_recovery`）。

### 14.2 现象

TWRP GUI 点 Scan，列表为空。手动执行：

```bash
wpa_cli -p /tmp/recovery/sockets -i wlan0 ping
# Permission denied
```

### 14.3 根因分析

两个版本的 wpa_cli 都会降权（strace 实测验证）：

```
setgid(1010) = 0   # wifi gid
setuid(1010) = 0   # wifi uid
```

**关键差异在于临时应答 socket 的 bind 路径：**

| 版本 | bind 路径 | 来源 |
|---|---|---|
| 设备原生 wpa_cli（OEM） | `/data/vendor/wifi/wpa/sockets/wpa_ctrl_<pid>-1` | 硬编码，不受 `-p` 参数影响 |
| 自编译 wpa_cli_recovery | `/tmp/wpa_ctrl_<pid>-1` | 上游默认 fallback 路径 |

这里容易误解的一点是：`-p` 参数只决定 wpa_cli 去连接哪个 `wpa_supplicant` 控制 socket，并不决定 wpa_cli 自己本地临时应答 socket 的 `bind()` 目录。也就是说，OEM 版即使传了 `-p /tmp/recovery/sockets`，它本地创建的 `wpa_ctrl_<pid>-1` 仍然会落在编译进二进制的 `/data/vendor/wifi/wpa/sockets/`；只有自编译版才会走上游默认的 `/tmp/wpa_ctrl_<pid>-1`。

这个结论不是推断，是用 `strace` 实测确认的：先用 `strace -e setuid,setgid ...` 确认两个版本都会降到 `wifi(1010)`；再用 `strace -e bind ...` 观察它们实际创建本地 socket 时的 `sun_path`。实测结果是，原生 OEM 版显示 `bind(... "/data/vendor/wifi/wpa/sockets/wpa_ctrl_<pid>-1" ...)`，而自编译版显示 `bind(... "/tmp/wpa_ctrl_<pid>-1" ...)`，由此确认两者差异不在降权逻辑，而在二进制内部选择的本地 socket 目录。

`/tmp` 在 recovery 中权限为 `root:shell 775`，wifi(1010) 是 other，只有 `r-x`，无写权限。自编译版降权后无法在 `/tmp` 创建文件，bind 返回 `EACCES`。

原生 OEM 版 bind 到 `/data/vendor/wifi/wpa/sockets/`，该目录权限满足 wifi uid，所以没有问题。

### 14.4 两种修复方案

**方案一（已采用）：chown /tmp**

在 RC 的 `on init` 中把 `/tmp` 的 group 改为 wifi（见七.1 模板中的 `on init` 块）：

```rc
on init
    # wpa_cli (drops to uid=wifi) needs to bind a temp socket in /tmp
    chown root wifi /tmp
    chmod 0775 /tmp
```

**方案二：用 `-s` 参数指定 wpa_cli 临时 socket 目录**

`wpa_cli` 有 `-s<path>` 参数可以指定自己的临时 socket 目录：

```bash
wpa_cli -p /tmp/recovery/sockets -s/data/vendor/wifi/wpa/sockets -i wlan0 ping
# bind 到 /data/vendor/wifi/wpa/sockets/wpa_ctrl_xxx，绕开 /tmp 权限问题
```

但 TWRP GUI 调用 wpa_cli 的代码不传 `-s` 参数，需要改 TWRP 源码，成本更高。

> **注意**：`WPA_CTRL_DIR` 环境变量对自编译版无效（实测），不能用此方式绕开。

### 14.5 影响范围

- **自编译 wpa_supplicant_recovery**（ossi_pure、infiniti 等 pure 方案）：**必须加** chown /tmp
- **设备原生 wpa_supplicant**（ossi、sm86xx 等）：原生 wpa_cli bind 路径硬编码，**不受影响**，加了也无害

---


## 附录：移植到其他设备

| 步骤 | 操作 |
|---|---|
| 1 | `adb shell getprop ro.board.platform` 确认平台代号（替换 `peach`） |
| 2 | `cat /vendor_dlkm/lib/modules/modules.dep \| grep wlan` 找模块依赖链 |
| 3 | `ls /sys/bus/platform/drivers/cnss2/` 找 fs_ready 路径中的设备名 |
| 4 | `find /vendor/etc/wifi -name '*.ini'` 找 WCNSS_qcom_cfg.ini 子目录名 |
| 5 | 按新驱动名修改 `cp-wifi-ko.sh` 中的 `KO_FILES` 和 `fs_ready` 路径 |
| 6 | `wpa_supplicant_recovery` 编译方式通用，无需修改 |
| 非高通平台 | MediaTek 等无 cnss2/fs_ready 机制，需从头分析驱动初始化流程 |

---
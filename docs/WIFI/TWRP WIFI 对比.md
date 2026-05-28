# 四个 TWRP 设备树 WiFi 实现对比分析

## 核心结论：wpa_supplicant 路线

| | infiniti | ossi | sm86xx | thales |
| --- | --- | --- | --- | --- |
| 路线 | 自编译 | 主线无WiFi / 分支有 | OEM 二进制 | OEM 二进制 |
| 证据 | rc 第17行明确写"自编译的 wpa_cli/wpa_supplicant" | 主线无 init.recovery.wifi.rc | /vendor/bin/hw/wpa_supplicant | /vendor/bin/wpa_supplicant |

infiniti 证据链条：

- init.recovery.wifi.rc 第17行注释：# 我当前的方案是自编译的 wpa_cli/wpa_supplicant
- 二进制路径：/system/bin/wpa_supplicant（不是 /vendor/bin/hw/）
- 零个 AIDL WiFi .so 文件（无 android.hardware.wifi.supplicant-*.so、无 vendor.*.wifi.supplicant-*.so）
- 零个 VINTF WiFi supplicant manifest XML
- manifest.xml 中只有 android.system.wifi.keystore（HIDL keystore，用于 EAP-TLS 证书，与 wpa_supplicant AIDL 无关）

sm86xx 证据链条：

- 二进制路径：/vendor/bin/hw/wpa_supplicant（OEM 硬件服务目录）
- 预置 AIDL .so：android.hardware.wifi.supplicant-V2-ndk.so、vendor.oplus.hardware.wifi.supplicant-V5-ndk.so、vendor.qti.hardware.wifi.supplicant-V1-ndk.so
- 预置 keystore HIDL .so：libkeystore-engine-wifi-hidl.so、libkeystore-wifi-hidl.so
- VINTF manifest：android.hardware.wifi.supplicant.xml（AIDL v2）+ vendor.oplus.hardware.wifi.supplicant.xml（AIDL v5）

thales 证据链条：

- 二进制路径：/vendor/bin/wpa_supplicant（vendor OEM 预编译）
- 预置 AIDL .so：android.hardware.wifi.supplicant-V3-ndk.so、vendor.qti.hardware.wifi.supplicant-V1-ndk.so、vendor.xiaomi.hardware.wifi.supplicant-V1-ndk.so
- VINTF manifest：android.hardware.wifi.supplicant.xml（AIDL v3 + QTI vendor）

---

## 一、平台与硬件差异

| 维度 | infiniti | ossi | sm86xx | thales |
| --- | --- | --- | --- | --- |
| 设备 | OnePlus 15 | OnePlus Pad2 Pro | OPlus 通用（多机型） | Xiaomi（thales） |
| SoC | sm88xx (8 Elite) | sm87xx (8 Elite) | sm86xx (8 Gen 3) | sm8750 (8 Elite) |
| WiFi 芯片 | QCA peach_v2 | QCA6490 peach_v2 | QCA kiwi_v2 | QCA peach_v2 + kiwi |
| 驱动模块 | qca_cld3_peach_v2.ko | qca_cld3_peach_v2.ko | qca_cld3_kiwi_v2.ko | qca_cld3_peach_v2.ko |
| fs_ready sysfs | cnss-peach | cnss-peach | cnss-kiwi | cnss-peach + cnss-kiwi |

---

## 二、wpa_supplicant 实现路线（最核心差异）

| 自编译路线 | OEM 二进制路线 |
| - | - |
| infiniti | sm86xx |
| ossi(wlan-source-built 分支) | thales |
| ossi(wlan-pulled-binaries 分支) | |

### 自编译路线

- 无 AIDL HAL 依赖
- 无 VINTF supplicant manifest
- 无 keystore-wifi HIDL .so
- 不需要 servicemanager 重启
- /tmp 需 chown root:wifi

### OEM 二进制路线

- 需要 AIDL HAL .so（2-4个）
- 需要 VINTF manifest XML
- 需要 keystore-wifi HIDL .so
- 可能需要 servicemanager 处理
- 连接参数需手工收紧

ossi 主线（twrp-16.0）目前完全没有 WiFi 支持。WiFi 实现在两个独立分支上：

- twrp-16.0-wlan-source-built → 自编译
- twrp-16.0-wlan-pulled-binaries → OEM

---

## 三、AIDL / VINTF 依赖对比

| | infiniti | ossi (主线) | sm86xx | thales |
| --- | --- | --- | --- | --- |
| wifi supplicant HAL .so | 无 | 无 | V2-ndk + V5-ndk + V1-ndk | V3-ndk + V1-ndk + V1-ndk |
| wifi keystore HIDL .so | 无 | 无 | libkeystore-engine-wifi-hidl.so + libkeystore-wifi-hidl.so | libkeystore-engine-wifi-hidl.so + libkeystore-wifi-hidl.so |
| VINTF supplicant XML | 无 | 无 | AOSP v2 + Oplus v5 | AOSP v3 + QTI |
| 厂商特有 HAL | 无 | 无 | vendor.oplus.hardware.wifi.supplicant | vendor.xiaomi.hardware.wifi.supplicant |

---
四、内核模块加载机制

| | infiniti | ossi (wlan分支) | sm86xx | thales |
| --- | --- | --- | --- | --- |
| TW_LOAD_VENDOR_MODULES | 不含WiFi模块 | 不含WiFi模块 | 含11个WiFi模块 | 无此变量 |
| cp-wifi-ko.sh 特殊逻辑 | wait_for_system_dlkm() 20s重试 | 简单版 | 简单版 | 重试+mount检查+MAC地址复制 |
| 模块数量（init rc） | 12 + smem-mailbox独立 | 12 + smem-mailbox独立 | 11（smem-mailbox注释掉） | 12 + smem-mailbox列入搜索 |
| 搜索目录 | 4个（含/tmp/vendor/lib/modules） | 3个 | 2个 | 2个（不含tmpfs） |

关键差异：

- sm86xx 是唯一走双重加载路径的：TWRP 原生层（TW_LOAD_VENDOR_MODULES）+ init rc insmod，两套机制同时存在
- infiniti 的 wait_for_system_dlkm() 是唯一的时序容错机制——轮询 20 次等待 rfkill.ko 出现，说明它遇到了最严重的挂载时序问题
- thales 的 cp-wifi-ko.sh 最复杂：额外处理 MAC 地址从 persist 分区复制、重试时检查 mount 状态

---

五、启动服务对比

| 服务 | infiniti | ossi | sm86xx | thales |
| --- | --- | --- | --- | --- |
| qrtr-ns | ✓（注释质疑必要性） | ✓ | ✓ | ✓ |
| cnss-daemon | ✓（注释质疑必要性） | ✓ | ✓ | ✓ |
| rmt_storage | ✗ | ✗ | ✓ | ✓ |
| tftp_server | ✗ | ✗ | ✗ | ✓ |
| per_mgr | ✗ | ✗ | ✗ | ✓ |
| pd_mapper | ✗ | ✗ | ✗ | ✓ |
| per_proxy | ✗ | ✗ | ✗ | ✓ |
| wpa_supplicant | ✓ (/system/bin/) | ✓ | ✓ (/vendor/bin/hw/) | ✓ (/vendor/bin/) |
| dhcpcd | ✓ | ✓ | ✓ | ✓ |

thales 启动 7 个 Qualcomm 专有服务，是最重度的实现。infiniti 最精简，而且作者在注释中质疑了 qrtr-ns 和 cnss-daemon 对自编译路线的必要性。

---
六、WiFi 固件和配置

| | infiniti | ossi | sm86xx | thales |
| --- | --- | --- | --- | --- |
| 固件目录 | 无预置固件（从分区加载） | 无预置固件 | kiwi/（bdwlan.b0c/elf + regdb.bin） | peach/（66个固件文件） |
| WCNSS_qcom_cfg.ini | 484行 Oplus定制 | 484行 Oplus定制 | 106行（精简版） | 352行 vivo定制 |
| wpa_supplicant.conf | 14行（含 sae_pwe/oce） | 14行 | 6行（最简） | 6行（最简） |
| socket 路径 | /tmp/recovery/sockets | /tmp/recovery/sockets | /tmp/recovery/sockets（conf写/cache/不一致） | /tmp/recovery/sockets |
| SAR 配置 | 无 | 无 | 有（wifisar.cfg + sar-vendor-cmd.xml） | 无 |
| CNSS 诊断配置 | 无 | 无 | 有（cnss_diag.conf x2） | 无 |

---
七、特殊功能与已知问题

| | infiniti | ossi | sm86xx | thales |
| --- | --- | --- | --- | --- |
| service user字段 | 显示指定 user root | 无 | 无 | 无 |
| wpa_cli 预置 | 无（自编译） | 无（自编译） | 无 | 有预编译 wpa_cli |
| MAC 地址处理 | 无 | 无 | 无 | 从 persist 复制 wlan_mac.bin |
| 设备变体 | infiniti 单一 | ossi 单一 | 多机型共用（sm86xx平台） | 7个变体（dada/haotian/nezha/pandora/popsicle/pudding/xuanyuan） |
| early-boot 触发器 | 无 | 无 | 无 | 有（icnss wlan_en_delay + wpss_boot） |
| 固件符号链接 | 无 | 无 | 无 | 有（WCNSS + wlan_mac 的复杂 symlink） |
| 已知问题文档 | TWRP_WIFI_问题记录.md | 无 | 无 | 无 |
| WiFi 功能状态 | 活跃调试中 | 主线未集成 | 已确认工作 | 未知 |

infiniti 揭示了 4 个活跃问题：

1. 高 API level 下 init rc 解析器拒绝无 user 字段的 service → 已修复（显式加 user root）
2. rfkill.ko 运行时找不到 → 添加了 wait_for_system_dlkm() 重试，但根因未解
3. umount /firmware 导致 cnss-daemon 崩溃 → 已修复（注释掉 umount）
4. 竞态条件（cnss-daemon vs 固件挂载 vs 驱动加载）

---
八、演化关系推断（修正）

```text
sm86xx (最早, kiwi 平台, 8 Gen 3)
│
│ OEM 路线, 双重加载, 完整 VINTF + SAR
│
├── ossi (8 Elite, peach_v2)
│     │
│     ├── 主线: 无 WiFi
│     ├── wlan-source-built 分支: 自编译路线
│     └── wlan-pulled-binaries 分支: OEM 路线
│
├── infiniti (8 Elite, peach_v2)
│     │
│     │ 自编译路线
│     │ 继承 ossi 的架构但更激进精简
│     │ 解决了更多的时序问题（wait_for_system_dlkm）
│     │ 活跃调试中
│     │
│     └── 与 ossi 最大区别：ossi 分支策略（两个方案各一个分支）
│                          infiniti 只保留了自编译路线
│
└── thales (8 Elite, peach+kiwi, Xiaomi)
        │
        │ OEM 路线, 独立发展
        │ 最重量级, 深度 Xiaomi 定制
        │ 双 cnss 路径, 7 个 QCOM 服务, 7 个设备变体
```

---
九、总结

| | infiniti | ossi | sm86xx | thales |
| --- | --- | --- | --- | --- |
| wpa_supplicant | 自编译 | 主线无 | OEM hw/ | OEM vendor/bin |
| 复杂度 | 中 | 低（分支） | 中高 | 最高 |
| AIDL 依赖 | 零 | 零（自编译分支） | 3 HAL + keystore | 3 HAL + keystore |
| 成熟度 | 调试中 | 分支已验证 | 已验证 | 未知 |
| 可移植性 | 高（零依赖） | 高（自编译分支） | 低（OEM 绑定） | 最低（Xiaomi 深度绑定） |

infiniti 和 ossi 的自编译路线本质上是同一方案——都是编译 AOSP external/wpa_supplicant_8，无需 AIDL、无需 VINTF、无需 keystore。infiniti 在此基础上的改进是：处理了
system_dlkm 挂载时序问题、修复了高 API level 的 service user 字段要求。两者真正的区别在于 ossi 把两种路线分别放到了不同分支，而 infiniti 只保留了自编译路线

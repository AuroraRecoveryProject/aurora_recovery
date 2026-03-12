# TWRP 代码仓库分支演化与硬分叉成因分析

## 基础数据

| 仓库目录 | 远程地址 | 当前分支 | 总提交数 |
|---|---|---|---|
| `andrdoi_bootable_recovery_team_win` | `TeamWin/android_bootable_recovery` | android-12.1 | 12058 |
| （同上，另一分支） | 同上 | android-14.1 | 13743 |
| `android_bootable_recovery_twrp_test` | `TWRP-Test/android_bootable_recovery` | twrp-16.0 | 14496 |

所有分支共享同一 git 历史根节点：`23580ca2 Initial Contribution`（AOSP cupcake 时代，约 2009 年）。

---

## 零、TWRP 与 omnirom 的关系：谁 fork 了谁？

一个常见的误解是"TWRP fork 自 omnirom"。git 历史给出了不同的答案。

### 实际关系

```
AOSP (Google)
    └──> omnirom/android_bootable_recovery  （几乎纯 AOSP 自动同步镜像）
                    │
                    │  注册为 upstream remote，定期 merge AOSP 更新
                    ↓
         TeamWin/android_bootable_recovery  （真正的 TWRP 代码，2012 年起独立开发）
```

omnirom 在这里充当**转运站**：TeamWin 将其注册为名为 `upstream` 的 remote，定期从中 merge 来跟踪 AOSP 版本更新，而无需直接与 Google 的上游仓库对接。omnirom 本身几乎不贡献任何 recovery 功能代码。

### 证据

**omnirom 基本是 AOSP 自动同步镜像：**
- `omnirom/android-11` 的全部提交均为 `Snap for XXXXXXX ... to rvc-d1-b-release` 格式的 AOSP 自动化 snapshot，最后停在 **2020-08-03**
- `omnirom/android-14.0` 分叉点后 132 个提交中，只有 **1 个**来自 omnirom 自身：`recovery: remove most of the loopXXXX.png files to reduce ramdisk size`，其余均为 AOSP 自动 snap

**TeamWin 的 TWRP 代码早于 omnirom 8 年独立存在：**

omnirom 与 TeamWin 的共同祖先之后，TeamWin 最早的独有提交时间均在 **2012 年 8—9 月**：

```
2012-08-31  Add readme
2012-09-04  Initial stub of partitions.hpp
2012-09-05  TWRP-ify AOSP code
2012-09-05  Hax to make it boot
2012-09-07  Add processing of fstab, mounting, and decrypt
```

这些 TWRP 核心代码比 omnirom 任何实质性修改早了整整 8 年。**TWRP 不可能来自 omnirom，两者都直接源自 AOSP。**

### 各分支提交规模对比

| 分支 | 分叉点后独有提交数 | 说明 |
|---|---|---|
| TeamWin/android-12.1 | 3289 个 | 大量 TWRP 功能代码 |
| omnirom/android-11   | 0 个 | 最新提交即分叉点，已停更 |
| TeamWin/android-14.1 | 2509 个 | 大量 TWRP 功能代码 |
| omnirom/android-14.0 | 132 个 | 均为 AOSP 自动 snap |

---

## 一、android-12.1 与 android-14.1 的代码区别

### 分叉点

两个分支共享同一分叉点：

```
c7930f12  Added Sinhala Translations to extra-languages
          Author: Captain Throwback
          Date:   Wed Sep 13 16:04:42 2023
```

### 分叉后提交规模

| 分支 | 独有提交数（分叉点后） |
|---|---|
| android-12.1 | 43 个 |
| android-14.1 | 1728 个 |

android-14.1 涉及 **105 个文件变化（+1255 / -1328 行）**，是真正的大版本跨越，而非增量 bugfix。

### android-14.1 主要升级内容

- **HAL 层版本大幅升级**：Health AIDL → V4、Keymint → V4-ndk、Boot Control Client（`libboot_control_client` 替换旧的直接调用）
- **新增库依赖**：
  - `libsnapshot_cow` + lz4 + zstd（Virtual A/B COW 格式 snapshot 支持）
  - `libhealthshim`（健康 HAL shim 层）
  - binder AIDL 库
- **构建结构调整**：sepolicy 从自包含目录迁移至 `system/sepolicy`；`task_profiles` 改用 system 版本的 logcat
- **twrpRepacker 重写**（160 行改动）：更新对 Android 14 vendor_boot / recovery_ab 格式的支持
- **MinADB 变更**：deprecate `tMsg` 协议
- **AOSP recovery 底层代码**跟随 Android 14.1 更新（`update_verifier`、`otautil`、`install/` 等）

### 结论

android-14.1 是将整个 AOSP recovery 底层升级到 Android 14.1 API 水平后重新移植 TWRP 功能，属于大版本跨越，不是 android-12.1 的增量维护分支。

---

## 二、为什么 android_bootable_recovery(TWRP-Test) 是"硬分叉"而不是"fork"

### GitHub 关系层面

`TWRP-Test/android_bootable_recovery` **不是**通过 GitHub "Fork" 按钮从 `TeamWin/android_bootable_recovery` 派生的，两者是在 GitHub 上完全独立的仓库（无 "forked from" 标记）。这意味着：

- GitHub 无法追踪 PR 来源
- 无法通过 GitHub UI 对比差异
- 不存在官方意义上的上下游关系

### Git 历史层面

两仓库实际上**共享完整 git 历史**，最早的根提交相同，并共同演进到同一分叉点 `c7930f12`（2023 年 9 月）。TWRP-Test 组织将 TeamWin 的 git 历史 `push` 到了一个新的独立仓库，然后开始独立开发。

### TeamWin 的停更与 TWRP-Test 的诞生

TeamWin 的两个主力分支均已停止更新：

| 分支 | 最后一次提交 | 最后提交内容 |
|---|---|---|
| android-12.1 | **2024-05-10** | Support excluding zip from TWRP builds |
| android-14.1 | **2024-05-10** | Support excluding zip from TWRP builds |

而 TWRP-Test 的独立功能开发从 **2025 年 11 月**才开始活跃（WLAN UI、ttyd 等），距 TeamWin 停更已过去约 **18 个月**。

这段真空期是 TWRP-Test 诞生的直接动因之一：官方主线长期无人维护，社区开发者选择另起炉灶，以硬分叉的方式继续推进 TWRP 适配 Android 新版本的工作。

### TWRP 使用 Gerrit，而不是 GitHub PR

TWRP 项目的代码贡献走的是 [gerrit.twrp.me](https://gerrit.twrp.me)，而不是 GitHub Pull Request。这是理解"硬分叉"与"无法贡献"之间关系的关键：

- **GitHub fork** 是 GitHub 平台层面的概念，决定了 PR 的路由和仓库归属
- **Gerrit** 是独立于 GitHub 的代码审查平台，任何人只需有对应账号即可提交 patch，**不依赖 GitHub fork 关系**

因此，TWRP-Test 的开发者完全可以把自己的代码通过 Gerrit 提交给 TeamWin 审核合并，两者的 GitHub 仓库是否存在 fork 关系对此毫无影响。TWRP-Test 选择另建独立仓库，是**主动的独立开发决策**，而非技术限制所迫。

### "硬分叉"的本质

综合以上因素，TWRP-Test 的硬分叉成因可归纳为：

1. TeamWin 主线 **18 个月无实质更新**，社区失去等待的耐心
2. **主动绕过 Gerrit 审核流程**，直接以独立仓库推进自有功能，迭代更自由
3. GitHub 上彻底断开 fork 关系，使两者在平台层面完全独立

关系在 GitHub 上已断开，代码上也刻意大幅偏离 TeamWin 主线（792 个独有提交）。两者虽然共享 git 历史基础，但已经**无法无缝合并回去**——这就是"硬分叉"与普通 fork 的本质区别。

---

## 三、twrp-16.0 与 team_win 的代码关联

### 分叉拓扑图

所有三个分支均在 **同一分叉点** `c7930f12` 处分道扬镳：

```
(AOSP 早期 ~2009) ──────── c7930f12 (2023-09-13) ─┬─ android-12.1  (+43 commits)
                                                    ├─ android-14.1  (+1728 commits)
                                                    └─ twrp-16.0     (+2481 commits)
```

### 提交覆盖情况（通过 commit message 匹配）

android-12.1 分叉后共 43 个提交，twrp-16.0 中包含其中 **39 个**（约 90%）。

缺失的 4 个均为设备特定的 prebuilt 库和 sepolicy 修复：
- `twrpinstall: Fix for installing custom themes`
- `sepolicy: fix avc denials for loop mount`
- `prebuilt: Include android.hardware.vibrator-V2-ndk`
- `prebuilt: include vibrator libs for AIDL haptics`

### 为什么选 android-12.1 而不是 merge android-14.1？

直觉上，既然 android-14.1 更新，TWRP-Test 理应直接 merge 它。但 android-14.1 的提交构成揭示了原因：

| 提交类别 | 数量 | 占比 |
|---|---|---|
| AOSP 噪音（翻译导入、automerger、AOSP snap）| 1463 个 | **84.7%** |
| 真正的 TWRP 功能性提交 | 265 个 | 15.3% |
| **总计** | **1728 个** | 100% |

android-14.1 超过八成的提交是 TeamWin 跟随 AOSP 从 Android 12 升级到 Android 14 过程中产生的历史记录，对 TWRP-Test 毫无意义，merge 进来只会污染提交历史。

更关键的是，两者的 **AOSP 底层升级方向不同**：android-14.1 代表 TeamWin 的升级路线（Android 12 → 14），而 twrp-16.0 直接升到了 **Android 16**。如果 merge android-14.1，再升级到 Android 16 时反而会产生大量冲突。

相比之下，android-12.1 分叉后的 43 个提交**全部是干净的 TWRP 功能/bugfix**，没有任何 AOSP 升级噪音。对 TWRP-Test 来说，这些就是 TeamWin 主线上有价值的全部内容。

```
android-14.1 的 1728 个独有提交
    ├── 1463 个 AOSP 噪音        ← 污染历史，且与 TWRP-Test 自身升级路径冲突
    └──  265 个功能性提交         ← TWRP-Test 已通过自己的升级路径重新实现

android-12.1 的 43 个独有提交
    └──  43 个全是功能修复         ← 直接 cherry-pick，干净无副作用
```

### 与 android-14.1 的对比

twrp-16.0 比 android-14.1 多出 **792 个**独有提交——这些就是 TWRP-Test 的自有扩展功能。

### 结论

twrp-16.0 **并非完整包含** team_win 的提交，而是只 cherry-pick 了 android-12.1 上干净的功能性修复，丢弃了 android-14.1 的升级历史噪音，同时用自己的方式独立完成了从 AOSP 底层到 Android 16 的升级。

---

## 四、twrp-16.0 多出来的代码功能分析

### 1. WLAN UI（最重要的新功能）

提交：`5d1f8d79 Network: Add WLAN UI`  
涉及文件：`gui/wlanlist.cpp`、`gui/action.cpp`、`gui/theme/common/portrait.xml` 等，共 **1520 行新增**

#### 技术方案

不自己实现 WiFi 协议栈，而是通过 `popen()` 调用系统工具：

```
TWRP GUI ──popen()──> wpa_cli ──socket──> wpa_supplicant (daemon)
                   dhcpcd ──> wlan0 获取 IP
```

#### 用户操作流程

```
主界面 → wlan 页 → [扫描] → wlan_scan_results（GUIWlanList 滚动列表）
                           → 选中网络
                               ├─ 开放网络 → 直接 wlanconnect
                               └─ 加密网络 → wlan_password 页（输入密码）
                                               → wlan_password_confirm → wlanconnect
```

#### wlanscan 内部执行

```bash
wpa_cli -iwlan0 -p/tmp/recovery/sockets scan
wpa_cli -iwlan0 -p/tmp/recovery/sockets scan_results
```

解析输出中的 flags 字段判断加密类型：
- 含 `WPA3` → WPA3
- 含 `WPA2` → WPA2  
- 含 `WPA-PSK` → WPA
- 无 → 开放网络

扫描结果以 `SSID (信号强度)` 格式显示在 `GUIWlanList` 滚动列表中（线程安全，mutex 保护）。

#### wlanconnect 内部执行

```bash
wpa_cli add_network                              # 创建 network_id=0
wpa_cli set_network 0 ssid <hex_encoded_ssid>    # SSID 转十六进制编码
wpa_cli set_network 0 key_mgmt WPA-PSK           # 加密类型
wpa_cli set_network 0 psk <hex_psk>              # 密码
wpa_cli enable_network 0
wpa_cli select_network 0                         # 发起连接
# 等待握手完成...
dhcpcd wlan0                                     # DHCP 获取 IP
sleep 5
```

全程通过 `GUIBorderedLogBox` 在屏幕上实时显示 `[INFO]` / `[ERROR]` 日志。

#### 关键限制

- 需要 recovery 镜像中已有 **wpa_supplicant** 和 **wpa_cli**（TWRP 通常自带）
- 固定使用 `wlan0` 接口名
- WPA3 连接由 `9e1e0913 Fix key_mgmt with WPA3` 单独修复

---

### 2. ttyd — 浏览器 root shell

提交：`299c86da Add static ttyd binaries`  
作者：adontoo（2025-12-11）

#### 是什么

[ttyd](https://github.com/tsl0922/ttyd) 是开源工具，将 shell 暴露为 **WebSocket 终端**，通过浏览器即可操作设备，效果等同于 SSH terminal（但只用 HTTP）。此处使用**预编译静态链接二进制**，不依赖任何 `.so` 文件，可直接放进 recovery 镜像运行。

#### 文件部署

```
prebuilt/ttyd        → /system/bin/ttyd
etc/init/ttyd.rc     → /system/etc/init/ttyd.rc
```

#### ttyd.rc 内容

```rc
on property:servicemanager.ready=true
    start ttyd

service ttyd /system/bin/ttyd -p 7681 --writable /sbin/sh
    class hal
    user root
    group root
    disabled
    seclabel u:r:recovery:s0
```

关键参数说明：
| 参数 | 说明 |
|---|---|
| `servicemanager.ready=true` | servicemanager 初始化完成后自动触发，无需手动 |
| `-p 7681` | 监听 **7681 端口** |
| `--writable /sbin/sh` | 暴露可交互的 root shell |
| `disabled` | 不随 boot 启动，由 init 条件触发 |

#### 使用方式

当 WLAN 连接成功获取 IP 后，在**同一局域网任何浏览器**访问：

```
http://<设备IP>:7681
```

即可获得设备的 root shell，可执行任意命令（挂载分区、查看日志、操作文件等）。

---

### 3. microhttpd — HTTP 文件服务器

提交：`ae0c78d0 recovery: Add libmicrohttpd`

来自 `external/libmicrohttpd`，是 TWRP 的 **HTTP sideload** 功能，允许通过 WiFi 直接推送 OTA 包，无需 USB 数据线。

#### 三组件协作关系

| 组件 | 端口 | 功能 |
|---|---|---|
| `microhttpd` | 80/8080 | HTTP 文件上传，无线 ADB sideload |
| `ttyd` | 7681 | WebSocket 终端，浏览器 root shell |
| WLAN UI | — | 在 TWRP 界面内连接 WiFi，使上述两个服务可被局域网访问 |

#### 统一构建开关

整套网络功能由一个标志控制，不需要时可完全裁掉：

```makefile
TW_NO_NETWORK := true   # 所有网络相关模块均不编译
```

---

### 4. AVB 2.0 禁用支持

提交：`e42e3e3d recovery: Add disable AVB2.0 in advanced options`

- 在高级菜单中增加"禁用 AVB 验证"入口
- 支持 `TW_AVB_VBMETA_FLAGS_ALL_DISABLED` 编译选项
- 允许直接清空 vbmeta flags，绕过镜像签名验证，方便刷机调试

---

### 5. dmctl 工具集成

提交：`ec81f0f8 Build dmctl from source`

将 Android 的 Device Mapper 控制工具 `dmctl` 编译进 TWRP，可在 recovery 中直接操作 dm 设备（如 super 分区的 device mapper virtual device），配合 `dmuserd` 守护进程使用。

---

### 6. 工具链扩充

| 提交 | 功能 |
|---|---|
| `Add 7za` | 内置 7-Zip 命令行工具，支持更多压缩格式 |
| `recovery: Add flag TW_INCLUDE_ZSTD` | 支持 zstd 格式的 zip 包安装 |
| `recovery: Add se_omapi` | 安全元素 / NFC 相关操作支持（`TW_INCLUDE_OMAPI`） |

---

### 7. AOSP 底层升级至 Android 16

提交：`37f8efe7 TWRP a16`

将 AOSP recovery 底层升级到 **Android 16**，配套适配：
- `android.hardware.health-V4`
- `android.hardware.security.keymint-V4-ndk`
- `android.hardware.security.keymint-V5-ndk`
- `libaconfig_storage_read_api_cc.so`
- `libperfetto_c.so`
- `server_configurable_flags.so`

这是 team_win 的 android-12.1 / android-14.1 分支都不具备的。

---

### 8. 其他功能改进

| 提交 | 功能 |
|---|---|
| `Support ro.twrp.*_offset` | 通过 sysprop 控制分区偏移，无需重编内核 |
| `Supprot ro.twrp.device_version` | 通过 prop 覆盖设备版本号 |
| `Do not try decrypting all other users` | 多用户设备解密逻辑修复，避免误解密其他用户数据 |
| `Provide workaround for backup/restore issues` | 备份还原稳定性修复（koaaN 贡献） |
| `Cater for Meizu touch mapping` | 魅族触控坐标映射支持（`TW_MEIZU_TOUCH_MAPPING`） |
| `fonts: Use NotoSansCJKsc` | 更换为 Noto Sans CJK SC 字体，改善中文显示 |
| `recovery: Automatically patch security patch date` | 刷机后自动修补安全补丁日期 |
| `recovery: Combined install zip/img at install page` | 安装页面合并 zip 和 img 入口为一个界面 |
| `Use /persist/TWRP/.twrp_settings` | TWRP 配置持久化路径从 `/data` 改为 `/persist`，格式化 data 后也不丢失设置 |

---

## 总结

| 问题 | 结论 |
|---|---|
| **12.1 vs 14.1 区别** | 底层 AOSP API 大版本升级（HAL、库、构建结构），14.1 领先 1685 个提交 |
| **为何是硬分叉** | GitHub 上无 fork 链接关系；代码虽共享历史，但已深度分歧，无法无缝合并 |
| **twrp-16.0 与 team_win 的关系** | 包含 team_win 约 90% 的提交（cherry-pick），在 android-14.1 基础上再追加 792 个独有提交 |
| **多出来的代码做什么** | 核心：**WLAN 远程管理 + ttyd 浏览器终端**；其次：AVB 禁用、dmctl、7za、AOSP Android 16 底层升级 |

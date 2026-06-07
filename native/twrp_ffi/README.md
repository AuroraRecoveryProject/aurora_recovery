# TWRP FFI 模块概览

bootable/recovery/twrp_ffi/ 是一个独立于 TWRP GUI 的共享库 (libtwrp_core_ffi.so)，将 TWRP 核心功能封装为稳定的 C ABI，供 flutter 调用。

编译产物是动态库而非可执行文件，这意味着它不代替 TWRP，而是一个可被其他进程加载的功能库。

---
架构总览

```text
┌──────────────────────────────────────────────┐
│      External Callers (Flutter)               │
│                     │                        │
│               extern "C" FFI                 │
├──────────────────────────────────────────────┤
│  tw_install_ffi    tw_settings_ffi           │
│  tw_display_ffi    tw_power_ffi              │
│         │               │                    │
│         └─── tw_ffi_internal ───┐            │
│                    │            │            │
│          tw_install_core     Settings        │
│          (C++ namespace)   Persistence       │
│                    │       (/persist)        │
│         updater-binary fork/exec             │
└──────────────────────────────────────────────┘
```

---
各模块详解

1. tw_settings_ffi — 设置管理

| API | 功能 |
| - | - |
| `tw_settings_init()` | 从 `/persist/TWRP/.twrp_settings` 加载设置 |
| `tw_settings_get(key, ...)` | 读取单个设置项 |
| `tw_settings_get_all(...)` | 批量读取所有设置（`key=value` 格式） |
| `tw_settings_set(key, value)` | 修改设置（仅内存） |
| `tw_settings_flush()` | 将内存中的设置持久化到磁盘 |
| `tw_settings_reset_defaults()` | 恢复出厂默认值 |
| `tw_settings_subscribe(cb, ...)` | 订阅设置变更事件（`init` / `set` / `reset`） |

设置文件格式（tw_ffi_internal.cpp:107-159）:

- 二进制格式，文件头 4 字节版本号 (0x00010010)
- 每条记录: key_len(2B) + key + value_len(2B) + value
- 默认设置包含振动强度、时区、屏幕超时、亮度等 ~25 个键

---
1. tw_ffi_internal — 内部工具层

提供所有模块共享的基础设施:

- 全局状态: g_tw_settings（内存中的设置 map）、g_tw_settings_subscribers（订阅者列表）、全局 g_tw_ffi_mutex 互斥锁
- 亮度文件探测: 自动扫描 /sys/class/backlight/ 和 /sys/class/leds/lcd-backlight/ 找到 brightness 节点，读取 max_brightness，完成百分比 ↔ 原始值转换
- 设置持久化: TwLoadSettingsLocked() / TwSaveSettingsLocked() 读/写 /persist/TWRP/.twrp_settings
- 发布-订阅通知: TwNotifySubscribersLocked() 在 init/set/reset 时回调所有订阅者

---
3. tw_display_ffi — 亮度控制

tw_display_set_brightness_percent(80)
→ TwPercentToRawValue(80, &raw)     // 百分比→原始值（查 max_brightness）
→ TwWriteLine(brightness_node, raw)  // 写入 /sys/.../brightness
→ 更新 g_tw_settings["tw_brightness_pct"]
→ TwNotifySubscribersLocked()        // 通知订阅者

无需 GUI，直接操作 sysfs。

---
4. tw_power_ffi — 电池信息

tw_power_get_battery_info(&info)
→ GetBatteryInfo()                    // 调用 AOSP Health HAL
→ 返回 capacity (0-100) + charging (0/1)

封装了 AOSP recovery_utils/battery_utils.h 的 GetBatteryInfo()。

---
5. tw_install_core — ZIP 刷入引擎（核心）

这是最复杂的模块，将 TWRP 的 ZIP 安装逻辑重写为异步状态机:

状态模型 (tw_install_ffi.h)

IDLE(0) → RUNNING(1) → SUCCESS(2)
                    → FAILED(3)

安装流程 (InstallWorker, tw_install_core.cpp:631)

1. ResetSessionLocked(path)         // 清空日志、错误、进度
2. CheckDigest(package_path)        // 可选: SHA256/MD5 校验
    扫描 .sha2 / .sha256 / .md5 / .md5sum 文件
3. RunInstall(package_path)
    ├─ CreateMemoryPackage(path)     // mmap ZIP 文件
    ├─ verify_file()                 // 验签 (OTA certs)
    ├─ verify_package_compatibility() // 兼容性检查
    ├─ pipe() + fork()
    ├─ [子进程] unshare(CLONE_NEWNS) // ★ Mount namespace 隔离
    │           mount("/", MS_SLAVE)  //   防止 Magisk umount 影响父进程
    │           execv(updater-binary) //   执行 META-INF updater
    └─ [父进程] 解析管道输出:
        progress <portion> <fraction>  → 更新进度 %
        set_progress <fraction>        → 设置段内进度
        ui_print <message>             → 追加日志
        wipe_cache                      → 标记需清除 cache
        retry_update                    → 重试
        log <message>                   → 日志输出
4. WriteInstallResultFile()          // 写入 /tmp/last_install

Mount Namespace 隔离 (tw_install_core.cpp:541-544)

if (access("/tmp/tw_ffi_no_unshare", F_OK) != 0) {
    if (unshare(CLONE_NEWNS) == 0) {
        mount("none", "/", nullptr, MS_REC | MS_SLAVE, nullptr);
    }
}

这是一个重要的兼容性设计：子进程创建独立的 mount namespace 并将根设为 slave，防止 Magisk 在刷入脚本中执行的 umount 操作反过来影响父进程（宿主 TWRP）。可通过 touch /tmp/tw_ffi_no_unshare
关闭此隔离用于调试。

关键 API

| API | 功能 |
|------|------|
| `tw_install_init()` | 初始化路径（`/tmp/recovery.log` 等）、写入构建标记 |
| `tw_install_start_zip(path, check_digest)` | 异步启动刷入（detach 线程） |
| `tw_install_get_state()` | 查询状态：`IDLE` / `RUNNING` / `SUCCESS` / `FAILED` |
| `tw_install_get_progress()` | 查询进度（0-100） |
| `tw_install_read_log(offset, ...)` | 增量读取日志（支持断点续读） |
| `tw_install_get_last_error()` | 获取最后一次错误信息 |
| `tw_install_get_last_result()` | 获取结果码 |
| `tw_install_reset_session()` | 重置会话 |
| `tw_install_get_wipe_cache()` | 查询 updater 是否请求了 cache wipe |

关键的与主 TWRP 的差异: 这是异步非阻塞的——调用 StartZip 后立即返回，调用者循环轮询 GetState() 和 GetProgress()。传统 TWRP 的安装是同步阻塞的，会卡住整个 UI 线程。

---
模块间依赖

```text
Android.mk → libtwrp_core_ffi.so
│
├── 源码: tw_ffi_internal + tw_settings_ffi + tw_display_ffi
│         + tw_power_ffi + tw_install_ffi + tw_install_core
│
├── 依赖共享库: libbase, libcutils, libcrypto, libziparchive,
│               libaosprecovery, libhidlbase, health HAL (2.0/2.1/V3)
│
└── 依赖静态库: libtwrpinstall, librecovery_utils, libhealthhalutils
```

---
总结

twrp_ffi 是一个剥离了所有 GUI 依赖的 TWRP 功能子集，提供了:

1. 设置管理 — 持久化在 persist 分区，不与 /data 耦合
2. 亮度控制 — 直接操作 sysfs
3. 电池查询 — 封装 Health HAL
4. ZIP 安装引擎 — 完整的签名验证 + fork/exec updater + 进度/日志流式回调 + mount namespace 隔离

设计目标是为外部程序（如 TWRP 配套的管理 APP）提供一个稳定、可预测的 C ABI，同时保留 mount namespace 隔离等 Magisk 兼容性修复。它可与主 TWRP 进程并行运行，通过互斥锁和原子变量保证线程安全。
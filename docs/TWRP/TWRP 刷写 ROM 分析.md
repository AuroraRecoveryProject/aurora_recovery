# TWRP 刷写 ROM 流程分析

本文基于源码：[android_bootable_recovery](https://github.com/TWRP-Test/android_bootable_recovery)

重点分析普通 GUI 刷 ZIP、ADB sideload、OpenRecoveryScript，以及当前 Flutter/FFI 刷入路径和原版 TWRP 的关键差异。

## 结论

当前这份 TWRP 的 GUI 刷入主链路是：

```text
twrp.cpp::main()
  -> gui_start()
    -> GUIAction::flash()
      -> GUIAction::flash_zip()
        -> TWinstall_zip()
          -> Prepare_Update_Binary()
          -> Run_Update_Binary()
            -> fork()
              -> child: execve(update-binary/update_engine_sideload, args, environ)
              -> parent: 读 pipe 更新进度/日志/wipe_cache
```

这条链路里有几个关键事实：

- TWRP 在启动早期会 `signal(SIGPIPE, SIG_IGN)`，这对长期运行的 recovery 进程很重要。
- GUI 刷 ZIP 最终会走 `TWinstall_zip()`。
- 非 A/B ZIP 通过 `META-INF/com/google/android/update-binary` 执行。
- A/B OTA 通过 `payload_properties.txt` / `payload.bin` 走 `update_engine_sideload`。
- updater 和 recovery 父进程之间通过 pipe 协议通信，常见命令包括 `progress`、`set_progress`、`ui_print`、`wipe_cache`、`log`。
- TWRP 会在执行安装前卸载 Android root/system 挂载点，并重新创建 `/system` 目录。
- 非 A/B ZIP 会提取 `file_contexts` 到 `/file_contexts`。
- 这份 TWRP 的传统路径使用 `execve(..., environ)`，而不是只用 `execv()`。

需要特别注意的边界：

- `gui_start()` 返回后 `twrp.cpp` 确实会调用 `reboot()`，但正常刷 ZIP 后 GUI 仍继续运行；只有用户选择 reboot、ORS 脚本执行 reboot、或 GUI 主循环退出时才会重启。
- Flutter/FFI 刷 Magisk 时的崩溃关键不是 mmap 失效，也不是 recovery 直接失去 `/system` 依赖；更准确地说，是 Flutter 后台 helper 持续 `fork+exec` 路径解析，遇到 mount 传播后的瞬态失败，再经 SIGPIPE 链杀死进程。原版 TWRP 刷入期间基本是 `fork + waitpid` 阻塞，不会触发这条链。

## 启动到 GUI

入口在 `bootable/recovery/twrp.cpp`：

```text
main()
  -> umask(0)
  -> freopen(/tmp/recovery.log)
  -> signal(SIGPIPE, SIG_IGN)
  -> DataManager::SetDefaultValues()
  -> startup.parse()
  -> PartitionManager.Process_Fstab("/etc/twrp.fstab" 或 "/etc/recovery.fstab")
  -> gui_init()
  -> PartitionManager.Setup_Fstab_Partitions(true)
  -> gui_loadResources()
  -> DataManager::ReadSettingsFile()
  -> process_recovery_mode()
  -> gui_start()
```

对应源码位置：

- `twrp.cpp:344-356`：初始化日志、umask、SIGPIPE。
- `twrp.cpp:384-399`：默认值、启动参数、fstab 解析。
- `twrp.cpp:416-424`：GUI 初始化、加载资源、读取设置。
- `twrp.cpp:496-505`：进入 recovery 模式并启动 GUI 主循环。

`gui_start()` 是主交互循环。用户刷 ZIP、sideload、重启都发生在这个 GUI 期间。`twrp.cpp:508` 的 `reboot()` 是 GUI 主循环结束后的兜底收尾，不是每个 ZIP 刷完立刻执行。

## GUI 刷 ZIP

普通 Install 页面最终进入 `GUIAction::flash()`：

```text
GUIAction::flash()
  -> 遍历 zip_queue
  -> ozip 解密（如果扩展名是 ozip）
  -> SetPerformanceMode(true)
  -> flash_zip(zip_path, &wipe_cache)
  -> SetPerformanceMode(false)
  -> 如果 wipe_cache，Wipe_By_Path("/cache")
  -> reinject_after_flash()
  -> PartitionManager.Update_System_Details()
```

对应源码：

- `gui/action.cpp:1080-1110`：遍历队列并调用 `flash_zip()`。
- `gui/action.cpp:1119-1126`：处理 `wipe_cache`、reinject、刷新分区信息。

`flash_zip()` 本身做几件事：

```text
flash_zip(filename)
  -> 确保 zip 路径存在，必要时挂载对应路径
  -> 如果 apex flattened，先 umount("/apex")
  -> TWinstall_zip(filename, &wipe_cache, check_digest)
  -> PartitionManager.Unlock_Block_Partitions()
  -> 如果 /system/bin/installTwrp 存在，执行 installTwrp reinstall
```

对应源码：

- `gui/action.cpp:396-428`：路径检查、apex、调用 `TWinstall_zip()`。
- `gui/action.cpp:429-441`：解锁 block 分区、可选重新配置 TWRP。

## TWinstall_zip 核心流程

核心实现位于 `bootable/recovery/twrpinstall/twinstall.cpp`。

整体流程：

```text
TWinstall_zip(path, wipe_cache, check_for_digest)
  -> 可选 digest 校验
  -> 读取 TW_UNMOUNT_SYSTEM / TW_SIGNED_ZIP_VERIFY_VAR
  -> Package::CreateMemoryPackage(path)
  -> 可选签名验证：/system/etc/security/otacerts.zip + verify_file()
  -> 读取 ZipArchiveHandle
  -> 判断是否 update package
  -> 如果 TW_UNMOUNT_SYSTEM=1：
       UnMount_By_Path(PartitionManager.Get_Android_Root_Path())
       unlink("/system")
       mkdir("/system", 0755)
  -> 判断 zip 类型：
       update-binary zip
       A/B OTA zip
       TWRP theme zip
  -> 成功刷入 update package 后，可选 Disable_AVB2
```

对应源码：

- `twrpinstall/twinstall.cpp:254-269`：digest 校验。
- `twrpinstall/twinstall.cpp:271-304`：读取配置、mmap ZIP、签名验证。
- `twrpinstall/twinstall.cpp:311-321`：安装前卸载 Android root/system 并重建 `/system`。
- `twrpinstall/twinstall.cpp:326-380`：按 ZIP 类型分流。
- `twrpinstall/twinstall.cpp:392-394`：update package 成功后可选 Disable AVB2。

注意这里卸载的不是硬编码 `/system`，而是：

```cpp
PartitionManager.UnMount_By_Path(PartitionManager.Get_Android_Root_Path(), true)
```

在 system-as-root 设备上，这通常会映射到 `/system_root`。随后 `unlink("/system")` + `mkdir("/system", 0755)` 是为了把 `/system` 恢复成普通空目录，避免 updater 对 `/system` 的操作被旧挂载状态影响。

## 非 A/B update-binary ZIP

当 ZIP 内存在 `META-INF/com/google/android/update-binary` 时，TWRP 走传统 updater 路径。

准备阶段：

```text
Prepare_Update_Binary()
  -> 查找 update-binary，必要时尝试 update-binary-<abi>
  -> 提取到 TMP_UPDATER_BINARY_PATH
  -> chmod/open mode 0755
  -> 如果 ZIP 根目录有 file_contexts，提取到 /file_contexts
```

对应源码：

- `twrpinstall/twinstall.cpp:100-128`：查找并提取 updater binary。
- `twrpinstall/twinstall.cpp:134-151`：提取 SELinux `file_contexts`。

执行阶段：

```text
Run_Update_Binary(path, wipe_cache, UPDATE_BINARY_ZIP_TYPE)
  -> update_binary_command(path, retry, status_fd, &args)
  -> pipe()
  -> fork()
       child:
         close(pipe_read)
         execve(args[0], args, environ)
       parent:
         close(pipe_write)
         fdopen(pipe_read)
         循环解析 updater 输出
         Wait_For_Child(pid)
```

对应源码：

- `twrpinstall/twinstall.cpp:156-176`：生成 updater 命令。
- `twrpinstall/twinstall.cpp:183-188`：fork 子进程并 `execve(..., environ)`。
- `twrpinstall/twinstall.cpp:190-238`：父进程读取 pipe、等待子进程结束。

pipe 协议保留下来的关键命令：

| 命令 | TWRP 处理 |
|---|---|
| `progress <frac> <secs>` | `DataManager::ShowProgress()` |
| `set_progress <frac>` | `DataManager::_SetProgress()` |
| `ui_print <text>` | 输出到 GUI/log |
| `wipe_cache` | 设置 `*wipe_cache = 1`，由外层成功后清 cache |
| `clear_display` | TWRP 不处理 |
| `log <text>` | 写日志 |

## A/B OTA ZIP

当 ZIP 内没有 update-binary，但存在 `payload_properties.txt` 时，TWRP 认为它是 A/B OTA。

流程：

```text
TWinstall_zip()
  -> 识别 payload_properties.txt
  -> 标记刷入 inactive slot
  -> 为 backuptool 临时挂载 Android root/system 和 vendor
  -> copy /system/bin/sh -> /tmp/sh
  -> bind mount /tmp/sh 到 /system/bin/sh
  -> Run_Update_Binary(path, wipe_cache, AB_OTA_ZIP_TYPE)
       -> abupdate_binary_command()
       -> /system/bin/update_engine_sideload
  -> 解除 bind mount，恢复 vendor/system 原挂载状态
  -> virtual A/B 时 Unlock_Block_Partitions + Prepare_All_Super_Volumes
  -> 提醒需要 reboot recovery 才适合继续刷其它 ZIP
```

对应源码：

- `twrpinstall/twinstall.cpp:340-353`：识别 A/B OTA，挂载 system/vendor，bind `/system/bin/sh`，调用 `Run_Update_Binary()`。
- `twrpinstall/twinstall.cpp:354-365`：清理挂载状态，virtual A/B 后准备 super volumes，并提示重启 recovery。
- `twrpinstall/twinstall.cpp:241-267`：A/B command 使用 `payload.bin` offset、`payload_properties.txt` headers 和 `update_engine_sideload`。

这里的重点是：A/B OTA 会临时挂载 system/vendor 供 backuptool 使用，bind mount `/system/bin/sh`，安装完成后再恢复挂载状态并提示 slot/recovery 重启边界。

## ADB sideload 与 ORS

ADB sideload 不是另一套安装器，最终也会回到 `TWinstall_zip()`：

```text
GUIAction::adbsideload()
  -> Toggle_MTP(false)
  -> twrp_sideload("/")
  -> minadbd/FUSE 提供 /sideload/package.zip
  -> TWinstall_zip("/sideload/package.zip", &dummy)
  -> 恢复 MTP
  -> reinject_after_flash()
```

对应源码：

- `gui/action.cpp:1578-1609`：GUI sideload 外层。
- `twrpinstall/adb_install.cpp:98-122`：FUSE 文件出现后调用 `TWinstall_zip(FUSE_SIDELOAD_HOST_PATHNAME, &dummy)`。

OpenRecoveryScript 里的 `install` 命令同样调用 `TWinstall_zip()`：

- `openrecoveryscript.cpp:531-536`：定位 ZIP 后 `TWinstall_zip(Zip.c_str(), &wipe_cache)`，成功后按需清 cache。

ORS 的 `reboot` 命令会直接调用 `TWFunc::tw_reboot()`，这和“刷完 ZIP 自动重启”是两回事：

- `openrecoveryscript.cpp:356-368`：脚本显式 `reboot` 才进入重启。

## 重启边界

TWRP 的重启函数在 `twrp-functions.cpp`：

```text
TWFunc::tw_reboot(command)
  -> DataManager::Flush()
  -> Update_Log_File()
  -> sync()
  -> 如果 /data 已挂载，先卸载 /data
  -> 根据 command 设置 intent / 运行可选脚本
  -> property_set("sys.powerctl", ...)
```

对应源码：

- `twrp-functions.cpp:620-675`：重启主逻辑。
- `twrp-functions.cpp:677-686`：执行 `/system/bin/reboot*.sh` 这类可选脚本。

所以正确理解是：

- 单次 GUI flash 成功后，TWRP 返回完成页，用户可以继续刷 ZIP 或手动 reboot。
- `gui_start()` 返回后的 `reboot()` 是整个 GUI 退出后的收尾。
- A/B OTA 成功后 TWRP 只是提示“请 reboot recovery 后再刷其它 ZIP”，不是强制立即重启。

## 和 AOSP InstallPackage 的差异

源码里还有 AOSP 风格的 `bootable/recovery/install/install.cpp`。它的 `InstallPackage()` 会先调用：

```text
setup_install_mounts()
```

`setup_install_mounts()` 的行为是：

```text
遍历 fstab：
  /tmp 和 /cache -> ensure_path_mounted()
  其它挂载点 -> ensure_path_unmounted()
```

对应源码：

- `recovery_utils/roots.cpp:432-455`：`setup_install_mounts()`。
- `install/install.cpp:649-655`：AOSP `InstallPackage()` 调用该逻辑。

但当前 GUI 实际走的是 `twrpinstall/install.cpp` / `twrpinstall/twinstall.cpp`，其中 `twrpinstall/install.cpp:656-664` 的 `setup_install_mounts()` 已被注释掉；真正生效的是 `TWinstall_zip()` 自己的 `TW_UNMOUNT_SYSTEM` 分支。

这就是文档里需要区分的两层：

- AOSP 标准 `InstallPackage()`：按 fstab 广泛整理挂载状态。
- 当前 TWRP GUI `TWinstall_zip()`：重点卸载 Android root/system，并由 updater 自己处理后续分区 mount/format/extract。

## 和 Flutter/FFI 刷入路径的差异

当前仓库的 FFI 路径在：

```text
native/twrp_ffi/tw_install_core.cpp
```

关键流程：

```text
RunInstall(package_path)
  -> Package::CreateMemoryPackage(package_path)
  -> LoadKeysFromZipfile("/system/etc/security/otacerts.zip")
  -> verify_file()
  -> verify_package_compatibility()
  -> pipe()
  -> 判断 A/B 或非 A/B，准备 args
  -> fork()
       child:
         unshare(CLONE_NEWNS)
         mount("none", "/", MS_REC | MS_SLAVE)
         umask(022)
         execv(args[0], args)
       parent:
         读 pipe，更新 FFI 状态/日志/进度
```

对应源码：

- `native/twrp_ffi/tw_install_core.cpp:462-495`：mmap、验签、兼容性检查。
- `native/twrp_ffi/tw_install_core.cpp:497-518`：创建 pipe、准备命令、fork 前生成 argv。
- `native/twrp_ffi/tw_install_core.cpp:529-545`：子进程 mount namespace 隔离并 `execv()`。
- `native/twrp_ffi/tw_install_core.cpp:556-625`：父进程解析 pipe、等待 updater 结束。

差异表：

| 项目 | 原版 TWRP GUI | Flutter/FFI |
|---|---|---|
| 入口 | `gui_start()` 里的同步操作 | Dart 调 FFI，异步 worker |
| SIGPIPE | `twrp.cpp` 启动时 `signal(SIGPIPE, SIG_IGN)` | 需要 embedder/runner 侧兜底 |
| 安装前卸载 system | `TWinstall_zip()` 按 `TW_UNMOUNT_SYSTEM` 卸载 Android root/system | 当前 FFI 不走 `TW_UNMOUNT_SYSTEM` 这段 |
| 非 A/B updater | `Prepare_Update_Binary()` + `Run_Update_Binary()` | `SetUpNonAbUpdateCommands()` |
| exec | `execve(args[0], args, environ)` | `execv(args[0], args)` |
| file_contexts | 会从 ZIP 根目录提取到 `/file_contexts` | 当前 FFI 路径未做这步 |
| mount 传播隔离 | 原版没有额外 `unshare`，但进程模型简单 | 子进程 `unshare(CLONE_NEWNS)` + `/` 设为 slave |
| UI 行为 | 父进程阻塞等待 updater，GUI action 完成后返回页面 | Flutter UI 继续活着，轮询状态/日志 |

FFI 里最重要的兼容性修复是：

```cpp
if (access("/tmp/tw_ffi_no_unshare", F_OK) != 0) {
    if (unshare(CLONE_NEWNS) == 0) {
        mount("none", "/", nullptr, MS_REC | MS_SLAVE, nullptr);
    }
}
```

它不是为了模拟原版 TWRP，而是为了适配 Flutter 进程模型：Magisk 这类 updater 会改 `/system` 挂载，若 mount 事件传播回 Flutter 父进程，Dart/Flutter 后台 helper 的路径解析和 `fork+exec` 可能受到影响。把 updater 子进程隔离到独立 mount namespace 后，updater 仍能在自己的 namespace 里 mount/umount，父进程看到的挂载拓扑不被反噬。

## Magisk 崩溃问题的准确归因

容易误判的因果链是：

```text
FFI 没有先卸载 /system
  -> Magisk umount -l /system 生效
  -> recovery/Flutter 失去 /system 依赖
  -> 崩溃
```

准确的因果链是：

```text
Flutter/FFI 父进程和 updater 子进程共享 mount peer group
  -> Magisk 在 updater 子进程中改 /system 挂载
  -> mount 事件传播回 Flutter 父进程
  -> Flutter/Dart 后台 helper 仍在周期性 fork+exec 读 /proc/stat
  -> 某次 helper 的 /system/bin/cat 路径解析/exec 失败
  -> helper 错误经 pipe 回传，引发 EPIPE/SIGPIPE 链
  -> 没忽略 SIGPIPE 时，整个 Flutter 进程被杀
```

为什么原版 TWRP 不容易崩：

- 原版 TWRP 启动早期已经 `signal(SIGPIPE, SIG_IGN)`。
- 原版刷入时主要是 fork updater 后父进程读 pipe / waitpid，不会像 Flutter/Dart 那样持续启动 helper 进程做 path-based 操作。
- Linux 的 mount over / umount 本身不会让已 mmap 的库直接失效；问题触发点是后续路径解析和 SIGPIPE 链。

因此最终修复方向是：

- updater 子进程做 mount namespace 隔离，阻断 mount 传播。
- Flutter runner 入口忽略 SIGPIPE，作为兜底。
- FFI 如需更贴近 TWRP 行为，可补齐 `file_contexts` 提取、`execve(..., environ)`、以及必要时的 Android root/system 安装前挂载整理，但不要把“先卸载 /system”误认为 Magisk 崩溃的唯一根因。

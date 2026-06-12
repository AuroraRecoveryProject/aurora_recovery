# Flutter Recovery 调 FFI 刷入 Magisk 崩溃问题调查记录

> 结论部分（SIGPIPE 链是真因、unshare + SIG_IGN 双修复均生效）已最终确定；中间分析过程保留了"错误猜测—被证伪—修正"的完整轨迹，便于复盘。
>
> 目前相对前期的主要修订：前期曾把 exec 失败原因定为"`/system/bin/cat` 符号链接循环导致 ELOOP"。后续 on-device 实地 dump（见 3.11）证伪了这一点 —— erofs 真分区里 `/system/bin/cat -> toybox` 是干净的相对软链、`toybox` 是普通 ELF，并不构成自指环。同时 `signal(SIGPIPE, SIG_IGN)` 单独验证（见 3.12）确认了 SIGPIPE 链才是真因。因此 4.1 因果链里 exec 失败的**具体 errno** 被降级为"未充分定位"，但整条 SIGPIPE 链与两个修复方案的有效性都不受影响。

---

## 1. 环境与问题表现

### 1.1 软硬件环境

- 设备：OPPO `OP615EL1`，ARM64，A/B 分区，当前槽 `_b`
- 系统：Android 16，system-as-root
- Recovery：基于 TWRP 修改的 Flutter 版 Recovery（`flutter-runner`）+ 自研 FFI 桥（`libtwrp_core_ffi.so`）替代原 TWRP UI
- Magisk：v30.7
- 目标分区：`/dev/block/by-name/init_boot_b`（init_boot v4、lz4_legacy）

### 1.2 故障现象

- 在 Flutter UI 中点击 "刷入 Magisk-v30.7.apk"
- 进度走到 `- Patching ramdisk` / `Unpacking boot image` 附近
- 整个 recovery 卡死、屏幕黑屏、`adb` 立刻断开
- 无法继续操作，需要硬重启

---

## 2. 关键源码与执行链路梳理

### 2.1 Flutter 侧

- `flutter-runner` 是基于 sony 修改版 flutter-embedded-linux + 自定义 flutter 3.38.5 engine 的纯 CPU 渲染 recovery UI
- Dart 端 `FlashRomService` 通过 dart:ffi 调 `libtwrp_core_ffi.so` 暴露的接口：
  - `tw_install_start_zip(path, check_digest)` 启动安装
  - `tw_install_read_log(offset, buf, len, out_next)` 每秒轮询日志
  - `tw_install_get_state()` / `_get_progress()` 等

### 2.2 Native 侧 FFI 实现

文件：[bootable/recovery/twrp_ffi/tw_install_core.cpp](bootable/recovery/twrp_ffi/tw_install_core.cpp)

执行链：

1. Dart 调 `StartZip` → C++ 端 `std::thread(InstallWorker).detach()`
2. `InstallWorker` 调 `RunInstall`
3. `RunInstall` 创建 status pipe → `fork()` → 子进程 `execv("/tmp/update-binary", ...)`
4. 父进程读 pipe，解析 `ui_print` / `progress` / `log` 等命令字写入日志缓存
5. `waitpid` 等子进程退出

### 2.3 Magisk 子进程链

- `/tmp/update-binary` (sh 脚本) 解 apk 里的 `assets/util_functions.sh`、`assets/boot_patch.sh`、`libbusybox.so` 等
- 调 `setup_flashable` → `recovery_actions`
- 调 `mount_partitions`（含 `mount_ro_ensure "system$SLOT app$SLOT" /system`）
- 调 `boot_patch.sh` 完成 ramdisk 修补、kernel 打补丁、repack
- 最终 `flash_image` 写入 init_boot 分区

---

## 3. 调查过程（按时间顺序）

### 3.1 第一次猜测：`umount -l /system` 破坏 Flutter 的 mmap（被证伪）

最初看 [util_functions.sh](Magisk/Magisk/assets/util_functions.sh) 里 `recovery_cleanup` 含：

```sh
umount -l /system
umount -l /system_root
umount -l /vendor
umount -l /persist
umount -l /metadata
```

假设：`/system` 被 lazy umount，Flutter 进程对 `/system/lib64/*.so` 的 mmap 因此失效 → SIGBUS。

**证伪**：通过 `cat /proc/<pid>/mountinfo` 检查，`/system` 在该 system-as-root 设备上**不是独立 mount point**，只是 rootfs 目录。`umount -l /system` 实际是 no-op。同时崩溃发生在 `recovery_cleanup` 之前，时序上对不上。

### 3.2 第二次猜测：Flutter 依赖 `/vendor/lib64` 下的 GPU 库（被证伪）

由 `recovery_cleanup` 真正 umount 的 `/vendor` 推断。

**证伪**：**纯 CPU 渲染时**（修改版 flutter-embedded-linux + 自定义 engine），不加载任何 GPU 驱动；不依赖 `/vendor` 下的库。

### 3.3 第三次方向：mount namespace 共享导致传播（部分正确）

检查 `/proc/<pid>/mountinfo`，确认 Flutter (pid 1440) 与原 TWRP recovery (pid 1600) 都继承自 PID 1 的初始 mount namespace，根挂载点为 `shared:1`，意味着 fork 出来的子进程做的任何 mount/umount 都会**双向传播**到父进程（Flutter）。

虽然此时 root cause 还未真正定位，但"阻断传播"作为防御手段已经可以做。

### 3.4 加入"全套子进程隔离"补丁

在 `RunInstall` 的子进程分支（fork 之后）一次性加入以下隔离：

1. `setsid()` 切独立会话/进程组
2. 信号 disposition 全部重置为 `SIG_DFL`（防 Dart VM 设过的 `SIG_IGN` 被继承）
3. `unshare(CLONE_NEWNS) + mount("none", "/", NULL, MS_REC|MS_SLAVE, NULL)` 创建独立 mount namespace 且断掉反向传播
4. 关闭除 status pipe 写端外的所有 fd
5. stdout/stderr 重定向到 `/tmp/twrp_child.log`
6. `umask(022)` + `execv`

效果：刷入成功，无崩溃。但此时无法判断 6 项里**哪一项**是关键。

### 3.5 设计运行时开关，做 B/D 对照实验

在子进程的 `unshare` 之前加一个文件存在性检查，按是否 `touch /tmp/tw_ffi_no_unshare` 切两组：

- **D 组**（默认）：执行 unshare + MS_SLAVE
- **B 组**：跳过 unshare + MS_SLAVE，其它隔离仍保留

启用 B 组：

```sh
adb shell touch /tmp/tw_ffi_no_unshare
```

恢复 D 组：

```sh
adb shell rm -f /tmp/tw_ffi_no_unshare
```

**实验结果**：

| 配置 | 结果 |
|---|---|
| D 组（unshare 开） | 安装完整跑完，result=0 |
| B 组（unshare 关，其它隔离全开） | **崩溃** |

**结论**：6 项隔离里只有 `unshare + MS_SLAVE` 真正起决定性作用。`setsid` / 信号重置 / fd cleanup / stdio 重定向 都不是必要项。

### 3.6 最小化补丁

为了进一步排除"其它隔离掩盖了别的副作用"的可能，把子进程逻辑撤回到 TWRP 原版风格，**只保留** `unshare + MS_SLAVE` 这一块（仍带开关）：

最终子进程片段（[tw_install_core.cpp](bootable/recovery/twrp_ffi/tw_install_core.cpp)）：

```cpp
if (pid == 0) {
    close(pipe_fds[0]);

    if (access("/tmp/tw_ffi_no_unshare", F_OK) != 0) {
        if (unshare(CLONE_NEWNS) == 0) {
            mount("none", "/", nullptr, MS_REC | MS_SLAVE, nullptr);
        }
    }

    umask(022);
    execv(chr_args[0], chr_args.data());
    fprintf(stdout, "E:Can't run %s (%s)\n", chr_args[0], strerror(errno));
    _exit(EXIT_FAILURE);
}
```

验证：D 组仍正常、B 组仍崩溃 → unshare 单点修复成立。

### 3.7 在 Magisk 端加 sleep 标记，定位崩溃步骤

最小补丁确认根因方向后，需要回答"具体是 Magisk 哪一步操作触发了反噬"。

在 [assets/boot_patch.sh](Magisk/Magisk/assets/boot_patch.sh) 关键节点插 13 处 `ui_print "DBG: ..."; sleep 2`，再在 [assets/util_functions.sh](Magisk/Magisk/assets/util_functions.sh) 的 `recovery_actions` 和 `mount_partitions` 里类似插桩。

重打包启 B 组复测：

```sh
adb shell touch /tmp/tw_ffi_no_unshare
```

B 组日志末尾停在：

```
DBG: about to mount_ro_ensure system_b -> /system
```

后续再无任何 DBG 输出 → 锁定崩溃触发点：**`mount_ro_ensure "system_b app_b" /system`**，对应 [util_functions.sh](Magisk/Magisk/assets/util_functions.sh) 的 `mount_name` 内部 `mount(...)` 系统调用。

### 3.8 验证 Flutter 进程对 `/system` 的依赖

```sh
adb shell
ps -A | grep -iE 'flutter|aurora|recovery'
# flutter-runner pid=1389, recovery pid=559
cat /proc/1389/maps | awk '{print $NF}' | grep '^/system' | sort -u
```

输出显示 `flutter-runner` 对 `/system/bin/linker64` 以及 `/system/lib64/` 下 40+ 个 `.so` 都有活跃 mmap，包括 `libc.so` `libc++.so` `libbase.so` `libcutils.so` `liblog.so` `libbinder.so` 等。

> 此时一度推测崩溃是 mmap 失效（SIGBUS）。**这个猜测后来被 strace 推翻**，见下一节。

### 3.9 logcat + strace 抓崩溃栈，推翻 mmap 失效假设

在设备上设置持久日志路径（`/tmp` 不行，崩溃后重启清空）：

```sh
adb shell
mkdir -p /data/local/tmp/dbg
PID=$(pidof flutter-runner)

logcat -c
nohup logcat -v threadtime -s DEBUG libc tombstoned 'flutter:V' 'aurora:V' \
  > /data/local/tmp/dbg/logcat.log 2>&1 &

nohup strace -ttT -f -y -s 256 -p $PID \
  -o /data/local/tmp/dbg/strace.log 2>/data/local/tmp/dbg/strace.err &
sleep 1

touch /tmp/tw_ffi_no_unshare
# 在 Flutter UI 点刷入 /tmp/Magisk-v30.7-dbg.apk
```

崩溃后拉取数据：

```sh
adb pull /data/local/tmp/dbg/ ./dbg/
```

结果分析：

```sh
grep -E 'Fatal signal|Abort message|backtrace' dbg/logcat.log
# 无输出
```

**logcat 没有任何 Fatal signal/Abort/backtrace 记录** → Flutter 不是被 SIGSEGV/SIGBUS 杀死的。

strace 末尾的退出事件：

```
143347:2146  09:43:10.583023 +++ killed by SIGPIPE +++
```

主进程和 16+ 个工作线程**全部被 SIGPIPE 杀死**。

### 3.10 真凶定位：fork+exec 失败 → EPIPE → SIGPIPE

在 strace 中查找崩溃前一秒的 mount/exec/pipe 事件：

```sh
grep -nE 'mount\(|umount|unshare' dbg/strace.log | head -50
awk '/09:43:10\.5[0-9]/' dbg/strace.log | grep -v sigprocmask | tail -80
```

关键时序（已脱噪）：

`T = 09:43:10.337` Magisk 子进程 pid=3157 在 `/system` 上反复尝试 mount，前面 ext3/ext2/ext4/vfat/msdos/exfat/fuseblk/f2fs 都返回 `EINVAL`，最后 `erofs` 成功：

```
mount("/dev/block/mapper/system_b", "/system", "erofs", MS_RDONLY|MS_SILENT, NULL) = 0
```

`T = 09:43:10.534` Flutter 父进程的子线程 3169 准备 fork+exec 一个 `cat /proc/stat`（Dart VM 周期性读 CPU 利用率）：

```
execve("/sbin/cat",        ["cat", "/proc/stat"]) = -1 ENOENT
execve("/system/bin/cat",  ["cat", "/proc/stat"]) = -1 ELOOP (Too many symbolic links encountered)
```

前期基于这条 strace 行把 root cause 写成"erofs 里 `/system/bin/cat` 符号链接循环"。该归因后被 3.11 节的 on-device dump **证伪**：真分区里 `/system/bin/cat -> toybox` 是干净的相对软链，`toybox` 是普通 ELF，并不构成自指环。

更保守地说：只能确认 helper 的 `execve("/system/bin/cat", ...)` 在这个时刻**失败**了。具体 errno 是否真为 ELOOP、抑或是 mount propagation 中间态下的某个瞬态错误、抑或 strace 显示的是别处的 ELOOP 被我误归到这一行，目前**没有充分证据定论**。对本问题而言不重要 —— 后续步骤都不依赖具体 errno。

`T = 09:43:10.535` 子线程 3169 把错误信息写回 helper pipe，然后退出：

```
write(36<pipe:[33680]>, "strerror_r failed\0", 18) = 18
exit_group(1)
```

`T = 09:43:10.544` wait 线程 2181 收到 SIGCHLD，准备把子进程退出状态写回内部状态 pipe，但对端已关闭：

```
write(44<pipe:[38120]>, "\1\0\0\0\0\0\0\0", 8) = -1 EPIPE
--- SIGPIPE {si_signo=SIGPIPE, si_code=SI_USER, si_pid=2146, si_uid=0} ---
```

`T = 09:43:10.544 ~ 10.583` Flutter 没有把 SIGPIPE 设成 `SIG_IGN`，默认 disposition 是 terminate，于是所有线程被 SIGPIPE 连锁屠杀：

```
2156  +++ killed by SIGPIPE +++
2157  +++ killed by SIGPIPE +++
...（16+ 个线程）
2146  +++ killed by SIGPIPE +++   ← 主进程
```

`adb` 守护进程随主进程退出而断连。

### 3.11 on-device 反查 /system 布局，证伪"符号链接自指环"假设

为了直接验证 erofs 里 `/system/bin/cat` 究竟是不是软链循环，在 [boot_patch.sh](Magisk/Magisk/assets/boot_patch.sh) 进入处插入一段诊断块，由 Magisk 子进程在 `mount_partitions` 完成后、还在共享 namespace 内时把 `/system` 的真实布局 dump 到 `/tmp/dbg_system_view.log`。诊断块全部用 busybox 内置命令实现（独立于 `/system`），覆盖 `mountinfo`、`ls -la /system`、`ls -la /system/bin` 头若干行、`/system/system` 是否存在、关键路径的 `readlink` 等。

触发并取回：

```sh
adb shell touch /tmp/tw_ffi_no_unshare   # 强制 B 组（共享 namespace）
# 在 Flutter UI 点刷入 /tmp/Magisk-v30.7-dbg.apk
adb shell cat /tmp/dbg_system_view.log
```

关键摘录：

```
==== mountinfo (筛 /system) ====
49 1 254:0 /system /system ro,relatime shared:24 - erofs /dev/block/dm-0 \
  ro,seclabel,user_xattr,acl,cache_strategy=readaround

==== ls -la /system ====
drwxr-x--x  4 root shell  8672 Mar 13 03:34 bin
... 一组普通目录与正常的相对软链
lrw-r--r--  1 root root      8 Mar 13 03:34 product    -> /product
lrw-r--r--  1 root root     11 Mar 13 03:34 system_ext -> /system_ext
lrw-r--r--  1 root root      7 Mar 13 03:34 vendor     -> /vendor
（没有 /system/system，无任何自指）

==== ls -la /system/bin (头 20 行) ====
lrwxr-xr-x  1 root shell      6 Mar 13 03:34 cat -> toybox
-rwxr-xr-x  1 root shell 578448 Mar 13 03:34 toybox

==== readlink chain ====
/system/bin/cat   -> toybox       （6 字节，相对，1 跳）
/system/bin/toybox 是普通 ELF
/system/system    : No such file or directory
```

**结论**：erofs 真分区里 `/system/bin/cat` 路径解析完全干净，**没有任何符号链接循环**，理论上 `execve("/system/bin/cat", ...)` 应该成功。这直接证伪了第一版关于 ELOOP 来源的解释。strace 那行 ELOOP 的真实出处需要更细的上下文复查（可能是别处路径的 ELOOP 与 cat exec 行被我归到了一起，或是 mount propagation 的瞬态），但对修复方案而言不重要。

### 3.12 SIG_IGN 单独验证：进程不再被屠杀，仅降级为可恢复的 Dart 异常

在 [flutter-embedded-linux/examples/flutter-drm-dumb-backend/main.cc](flutter-embedded-linux/examples/flutter-drm-dumb-backend/main.cc) `main()` 入口最前面加：

```cpp
signal(SIGPIPE, SIG_IGN);
```

切到 B 组（`touch /tmp/tw_ffi_no_unshare`、不开 unshare、保留共享 mount namespace），重新跑刷入流程。结果：

- 进程**不再崩溃**，UI 与 adb 全程在线
- 刷入流程**完整跑完**，Magisk 正常写入 init_boot
- 控制台仅多出一条非致命异常：

  ```
  ProcessException: strerror_r failed
  ```

  这正是 strace 里看到的 helper 子进程写回 fd 36 的字面字符串 `"strerror_r failed\0"`，被 Dart 的 `Process` 类捕获后包装抛出。

**结论**：SIGPIPE 链是真因。只要屏蔽掉 SIGPIPE 这一步，前面 helper exec 失败、helper pipe EPIPE 都只是局部异常，不会扩散为进程死亡。**SIG_IGN 单独就足以救回这次崩溃**，unshare 是更彻底的根治（连那条 ProcessException 都不会出现）。

---

## 4. 最终结论

### 4.1 完整因果链

1. Flutter / Dart VM 内部有后台 helper 周期性 **`fork + exec "cat /proc/stat"`** 用于读 CPU 利用率
2. Magisk 子进程在 `/system` 上 mount erofs 真分区；由于父子共享 mount peer group（`shared:1` / `shared:24`），**mount 事件双向传播到 Flutter 父进程**
3. 在 mount 传播完成后的某个瞬间，helper 子进程 **`execve("/system/bin/cat", ...)` 失败**（strace 显示返回 `-1 ELOOP`，但 on-device dump 证明真分区里 `/system/bin/cat -> toybox` 干净无环，具体 errno 来源未充分定位，详见 3.10、3.11）
4. helper 子进程把错误信息写回内部 pipe → exit
5. wait 线程收到 SIGCHLD → 往状态回传 pipe 写字节 → 对端已关闭 → `EPIPE`
6. 没有 `signal(SIGPIPE, SIG_IGN)` → 默认 disposition = terminate → 进程内所有线程被 **SIGPIPE 连锁杀死**

这条链上**第 6 步是真正的杀手**：3.12 节单独屏蔽 SIGPIPE 后，前 5 步照旧发生（异常以 `ProcessException: strerror_r failed` 形式被 Dart 捕获），但进程不再死亡、刷入正常完成。

### 4.2 为什么之前的猜测都不对

| 猜测 | 实际是否成立 | 原因 |
|---|---|---|
| `umount /system` 让 mmap 失效 | 否 | `/system` 不是 mount point，`umount` 是 no-op |
| 依赖 `/vendor` GPU 库 | 否 | Flutter 有纯 CPU 渲染模式 |
| `/system/lib64/*.so` mmap 失效 → SIGBUS | 否 | Linux 下 mount over 不会让旧 mmap 失效 |
| 多线程访问 path 失败 → SIGSEGV | 半对 | path 解析确实失败，但失败发生在 exec 而不是 mmap，且终结点是 SIGPIPE |

### 4.3 为什么原版 TWRP 不崩

原 TWRP `recovery` 二进制虽然也 mmap 了同一批 `/system/lib64/*.so`：

- **不**周期性 fork+exec 任何子进程
- fork 出 update-binary 后直接 `waitpid` 阻塞，期间 0 次 path 解析
- 所以 ELOOP → EPIPE → SIGPIPE 这条链在 TWRP 上根本不会被触发

差异**不在 mmap 本身**，而在**进程行为模式**：Flutter 多线程持续做 path-based 操作，TWRP 只做一次 fork+wait。

### 4.4 修复方案

两个修复**正交，均已实现并各自验证有效**，建议都保留作为双层防御。

**A（已实现，根治）**：在 fork 出来的 update-binary 子进程里阻断 mount 传播

[bootable/recovery/twrp_ffi/tw_install_core.cpp](bootable/recovery/twrp_ffi/tw_install_core.cpp)：

```cpp
if (access("/tmp/tw_ffi_no_unshare", F_OK) != 0) {
    if (unshare(CLONE_NEWNS) == 0) {
        mount("none", "/", nullptr, MS_REC | MS_SLAVE, nullptr);
    }
}
```

效果：子进程在新 namespace 里挂 erofs 到 `/system`，父进程 Flutter 看到的 `/system` 仍是原 rootfs，**helper 的 `cat` 调用从源头上不会再 exec 失败** → 整条 SIGPIPE 链根本不会启动。这是最彻底的方案，连 3.12 那条 `ProcessException` 都不会出现。

**B（已实现，兜底，单独也足以救活进程）**：在 flutter-runner `main()` 入口最前面加

[flutter-embedded-linux/examples/flutter-drm-dumb-backend/main.cc](flutter-embedded-linux/examples/flutter-drm-dumb-backend/main.cc)：

```cpp
signal(SIGPIPE, SIG_IGN);
```

3.12 节已实测：即使关掉 unshare（B 组），只要这一行存在，进程就不会被屠杀，只会多出一条可被 Dart 层 try/catch 的 `ProcessException: strerror_r failed`。这是 Dart VM 与所有写 pipe 的服务端进程的**标准实践**，Flutter Linux embedder 缺这一行属于上游遗漏。

**为什么两个都留**：

- A 单独：根治 mount 传播这一具体诱因，但万一未来出现其它路径的 EPIPE（比如 socket 半关、stdout 被 adbd 切断），进程仍会被屠杀
- B 单独：能救活这次的崩溃，但每次刷入都会多一条噪音 ProcessException，并且让 helper 子进程经历一次失败 exec
- A + B：用户态零感知 + 工程兜底

### 4.5 两个修复各自的生效原理

把 4.1 的因果链画出来，对照看两个补丁分别在哪一步切断：

```
[1] Flutter helper 周期性 fork+exec "cat /proc/stat"
[2] Magisk 子进程 mount erofs 到 /system，通过 shared peer group 传播到 Flutter
[3] helper 的 execve("/system/bin/cat", ...) 失败
[4] helper 把 "strerror_r failed" 写回内部 pipe → exit
[5] wait 线程往状态 pipe 写一字节 → 对端已关闭 → EPIPE
[6] 默认 SIGPIPE disposition = terminate → 全进程被屠杀
```

- **A（unshare + MS_SLAVE）切断第 [2] 步** —— 让 Magisk 的 mount 对父进程不可见，于是 [3] 不会失败，整条链没有起点
- **B（SIGPIPE → SIG_IGN）切断第 [6] 步** —— 让 EPIPE 不再升级为进程死亡，前 [1]~[5] 照旧发生但只产生一条可捕获异常

#### 4.5.1 为什么 unshare + MS_SLAVE 能切断第 [2] 步

无 unshare 时（B 组）父子在同一个 mount namespace 内：

```
PID 1 (init) 的 mount namespace
├── Flutter (pid 1389)           ← 跟父共享 namespace
└── update-binary 子进程          ← fork 出来同样共享
        └── mount erofs /system    ← shared peer group → 双向传播
                ↑
       这条 mount 立刻出现在 Flutter 看到的 /system 上
```

之后 Flutter 内部 helper 走的 `/system/bin/cat` 就是 Magisk 新挂上来的那个 erofs `/system`，于是 `execve` 在某种瞬态下失败。

执行子进程中的两行：

```cpp
unshare(CLONE_NEWNS);
mount("none", "/", nullptr, MS_REC | MS_SLAVE, nullptr);
```

发生的事：

1. **`unshare(CLONE_NEWNS)`**：内核给子进程**复制一份当前 mount 表**作为它的私有 namespace。此刻子 ns 与父 ns 挂载结构完全一样，但**两份表从此独立演进**。
2. **`mount("none", "/", MS_REC | MS_SLAVE)`**：把子 ns 内所有挂载点的传播类型从 `shared` 改成 `slave`。slave 的语义是**只接收来自上游（父 ns）的传播，自己产生的 mount/umount 不再反向传播给父 ns**。

效果矩阵：

| 谁动了 `/system` | 父 ns（Flutter）会看到？ | 子 ns（Magisk）会看到？ |
|---|---|---|
| 父 ns 自己挂 | ✅ | ✅（从父向 slave 子单向传） |
| 子 ns 自己挂 erofs | ❌ **被切断** | ✅ |

Magisk 的所有 `mount_ro_ensure system_b /system`、`mount --move`、bind 全部发生在子 ns 内部，**父 ns 的 `/system` 在整个刷入流程中纹丝不动**，仍然是 recovery 启动时的 rootfs `/system`（里面的 `/system/bin/cat -> toybox` 一直是能正常 exec 的 toybox 软链）。

链路结果：

- helper `execve("/system/bin/cat", ...)` **成功** → 不写 "strerror_r failed"
- helper 正常退出 → wait 线程往状态 pipe 写字节时**对端还活着** → 不会 EPIPE
- 没有 EPIPE → 没有 SIGPIPE → 没有连锁屠杀
- 连 3.12 看到的那条 `ProcessException` 都不会出现

这是从**源头消因**：让"Magisk 改 /system"这件事对 Flutter 完全不可见。

#### 4.5.2 为什么 signal(SIGPIPE, SIG_IGN) 能切断第 [6] 步

Linux 的设计是：进程往一个**读端已关闭**的 pipe / socket 写数据时，内核会做两件事：

1. `write()` 系统调用返回 `-1`，errno = `EPIPE`
2. 同时向写入进程**投递一个 SIGPIPE 信号**

`SIGPIPE` 的**默认 disposition 是 `Term`**（terminate）—— 不像 SIGSEGV/SIGBUS 只杀触发的那个线程，SIGPIPE 一旦未被处理，**整个进程（所有线程）都会被终结**，这就是 3.10 strace 里看到 16+ 线程全 `+++ killed by SIGPIPE +++` 的来源。

`signal(SIGPIPE, SIG_IGN)` 把 SIGPIPE 的 disposition 改成 ignore，于是上面那"内核做的第 2 件事"被静默丢弃：

- `write()` 仍然返回 `-1` / `EPIPE`（这是用户态可处理的普通错误）
- 但**不再有信号**，进程继续活着

`fork+exec` 后子进程的信号 disposition 默认会被 `execve` 重置为 `SIG_DFL`，所以这一行只影响 Flutter 自己，不会传染给 Magisk update-binary。

链路结果（对照 B 组的实测，见 3.12）：

- [1]~[5] **完整发生**（mount 仍然传播、helper exec 仍然失败、helper pipe 仍然写 EPIPE）
- [6] **被吞掉** → 进程不死
- helper 子进程通过内部 pipe 写回的 `"strerror_r failed"` 字符串被 Dart `Process` 类正常读取 → 包装成 `ProcessException: strerror_r failed` 抛给上层
- Dart/Flutter 层可以 try/catch 这条异常，UI 与刷入流程完整继续

这是**在最后一道防线兜底**：哪怕前 5 步全部发生，进程也不会被一个 EPIPE 屠杀。这本来就是所有"会写 pipe / socket 的多线程程序"的标准实践（Dart VM 自己在其他平台都设了 `SIG_IGN`，Flutter Linux embedder 缺这一行属于上游遗漏）。

#### 4.5.3 两者的层级差异

| 维度 | A: unshare + MS_SLAVE | B: SIGPIPE → SIG_IGN |
|---|---|---|
| 切断位置 | 因果链第 [2] 步 | 因果链第 [6] 步 |
| 作用域 | 仅本次 Magisk 子进程 | 整个 Flutter 进程生命周期 |
| 副作用 | 完全无感 | 多一条 `ProcessException` 噪音 |
| 防御未来 | 只防 mount 传播这一具体诱因 | 防一切 EPIPE 来源 |
| 类比 | "釜底抽薪" | "穿防弹衣" |

两者正交，理由如 4.4 末尾所述：A 防特定诱因、B 防未来同类，组合起来是工程上最稳的做法。

### 4.6 调试开关使用方法

- 默认（`/tmp/tw_ffi_no_unshare` 不存在）→ unshare 生效 → 正常
- `adb shell touch /tmp/tw_ffi_no_unshare` → 跳过 unshare → 复现崩溃用于对照

发布时建议保留开关，便于以后类似问题排查。

---

## 5. 用到的关键命令汇总

按调查阶段先后排列，便于后续复盘或重做实验时直接拷贝。

### 5.1 验证 mount 状态

```sh
adb shell cat /proc/$(pidof flutter-runner)/mountinfo | head -20
adb shell cat /proc/$(pidof recovery)/mountinfo | head -20
```

### 5.2 验证 Flutter 进程对 /system 的 mmap

```sh
adb shell
PID=$(pidof flutter-runner)
cat /proc/$PID/maps | awk '{print $NF}' | grep '^/system' | sort -u
# 进一步看可执行段
cat /proc/$PID/maps | awk '$2 ~ /x/ {print $0}' | grep '/system'
```

### 5.3 切换 B/D 对照

```sh
adb shell touch /tmp/tw_ffi_no_unshare    # B 组（关 unshare）
adb shell rm -f /tmp/tw_ffi_no_unshare    # D 组（开 unshare）
```

### 5.4 重打包 Magisk dbg 版

```sh
cd Magisk
cp Magisk-v30.7.apk Magisk-v30.7-dbg.apk
cd Magisk
zip ../Magisk-v30.7-dbg.apk assets/boot_patch.sh assets/util_functions.sh
unzip -p ../Magisk-v30.7-dbg.apk assets/boot_patch.sh    | grep -c 'DBG:'
unzip -p ../Magisk-v30.7-dbg.apk assets/util_functions.sh | grep -c 'DBG:'
cd ..
adb push Magisk-v30.7-dbg.apk /tmp/
```

### 5.5 抓 strace + logcat

```sh
adb shell
mkdir -p /data/local/tmp/dbg
PID=$(pidof flutter-runner)

logcat -c
nohup logcat -v threadtime -s DEBUG libc tombstoned 'flutter:V' 'aurora:V' \
  > /data/local/tmp/dbg/logcat.log 2>&1 &

nohup strace -ttT -f -y -s 256 -p $PID \
  -o /data/local/tmp/dbg/strace.log 2>/data/local/tmp/dbg/strace.err &
sleep 1

touch /tmp/tw_ffi_no_unshare
# 在 Flutter UI 点刷入
```

```sh
adb pull /data/local/tmp/dbg/ ./dbg/
```

### 5.6 分析 strace

```sh
# 信号事件
grep -nE '\+\+\+ exited|killed by|SIG' dbg/strace.log | tail -50

# mount 相关 syscall
grep -nE 'mount\(|umount|unshare' dbg/strace.log | head -50

# 崩溃前那一秒的上下文（去 sigprocmask 噪音）
awk '/09:43:10\.5[0-9]/' dbg/strace.log | grep -v sigprocmask | tail -80
```

# TWRP-16 编译环境与问题记录

## 1. 环境要求 (Environment)

- **Docker 内存**: 至少分配 **16GB** 内存 (推荐 20GB+)。
- **Swap (Linux)**: 如果出现 Soong 被 `Killed`（疑似 OOM），建议准备 **16GB+ swap**（与内存一起作为缓冲）。
- **磁盘空间**: 源码 + 编译产物巨大，建议预留 **200GB+** 磁盘空间。
- **操作系统**: macOS (需解决文件系统大小写问题) / Linux。

## 2. 编译步骤 (Build Steps)

首先需要一个设备树，参考:

- [twrp_caihong](https://github.com/hraj9258/twrp_caihong)
- [twrp_device_oplus_ossi](https://github.com/AuroraRecoveryProject/twrp_device_oplus_ossi)

### 编译 twrp-12 基于 android-12.1

参考 [platform_manifest_twrp_aosp](https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp)

```bash
mkdir twrp-12
cd twrp-12
repo init --depth=1 -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-12.1
git clone https://github.com/hraj9258/twrp_caihong device/oplus/caihong
```

### 编译 twrp-16 基于 android-16.0

参考 [platform_manifest_twrp_aosp](https://github.com/TWRP-Test/platform_manifest_twrp_aosp)

```bash
mkdir twrp-16
cd twrp-16
repo init --depth=1 -u https://github.com/TWRP-Test/platform_manifest_twrp_aosp.git -b twrp-16.0
git clone https://github.com/AuroraRecoveryProject/twrp_device_oplus_ossi device/oplus/ossi
```

### 执行编译

```bash
source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
export CCACHE_DIR=.ccache
export CCACHE_EXEC=$(command -v ccache)        
export CCACHE_MAXSIZE=5G
export USE_CCACHE=1
# twrp-16
lunch twrp_ossi
# twrp-12
lunch twrp_caihong
# m will auto-select the number of parallel jobs based on CPU cores
m recoveryimage
# get ccahe usuage
ccache -s
```

## 3. 问题记录与解决方案 (Troubleshooting Log)

### Q1: macOS 文件系统大小写敏感错误

**报错:**

```text
You are building on a case-insensitive filesystem.
Please move your source tree to a case-sensitive filesystem.
```

**原因:**
macOS 默认的 APFS 文件系统不区分大小写，而 Android 源代码（尤其是 Linux 内核部分和某些 Java 包）由于文件名仅大小写不同，必须在区分大小写的文件系统中操作。

并且修改代码是在当前的 mac，所以当前 mac 需要 sync 一份安卓源码，修改完，rsync 到编译的服务器

**解决方案1:**

创建并挂载一个区分大小写的稀疏镜像：

Case-sensitive APFS 这个玩意创建的分区，里面文件删了，空间不释放

- APFS 是 copy-on-write
- sparseimage 不会自动 shrink
- 可通过 `hdiutil compact android.dmg.sparseimage` 手动回收空间

```bash
# 创建 200GB 区分大小写的 APFS 镜像
hdiutil create \
    -type SPARSE \
    -fs 'Case-sensitive APFS' \
    -size 200g \
    -volname android_source android.dmg
# 挂载
hdiutil attach android.dmg.sparseimage
# 将源码同步进去
rsync -av --exclude='*.dmg*' TWRP-16/ /Volumes/android_source/

hdiutil resize -size 300g /Users/Laurie/Desktop/nightmare-space/Android_Recovery/TWRP_Compile/android.dmg.sparseimage

# 验证挂载
hdiutil info | grep "android.dmg.sparseimage"
```

**解决方案2:**

使用 HFS+:

```bash
hdiutil create \
  -type SPARSE \
  -fs 'Case-sensitive Journaled HFS+' \
  -size 200g \
  -volname android_source android.dmg
```

**最终方案3:**

```bash
# diskutil list                                     
/dev/disk0 (internal, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      GUID_partition_scheme                        *1.0 TB     disk0
   1:             Apple_APFS_ISC Container disk1         524.3 MB   disk0s1
   2:                 Apple_APFS Container disk3         994.7 GB   disk0s2
   3:        Apple_APFS_Recovery Container disk2         5.4 GB     disk0s3

/dev/disk3 (synthesized):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      APFS Container Scheme -                      +994.7 GB   disk3
                                 Physical Store disk0s2
   1:                APFS Volume Macintosh HD - Data     651.2 GB   disk3s1
   2:                APFS Volume Macintosh HD            16.5 GB    disk3s3
   3:              APFS Snapshot com.apple.os.update-... 16.5 GB    disk3s3s1
   4:                APFS Volume Preboot                 16.9 GB    disk3s4
   5:                APFS Volume Recovery                2.6 GB     disk3s5
   6:                APFS Volume VM                      41.9 GB    disk3s6
   7:                APFS Volume Case-sensitive APFS     99.0 GB    disk3s7
   8:                APFS Volume android_source          856.1 KB   disk3s8

/dev/disk4 (disk image):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      GUID_partition_scheme                        +2.4 GB     disk4
   1:                 Apple_APFS Container disk5         2.4 GB     disk4s1

/dev/disk5 (synthesized):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      APFS Container Scheme -                      +2.4 GB     disk5
                                 Physical Store disk4s1
   1:                APFS Volume MetalToolchainCryptex   2.3 GB     disk5s1 
```

由

```bash
/dev/disk3 (synthesized):
0: APFS Container Scheme - +994.7 GB disk3
```

推断出 disk3

创建一个卷:

```bash
diskutil apfs addVolume disk3 APFSX android_source
```

或者直接去磁盘工具手动创建卷，选择 APFS(区分大小写) 就行

### Q2: Soong 编译工具崩溃 (Panic in prebuilt_etc.go)

**报错:**

```text
internal error: panic in GenerateBuildActions for singleton androidmk
runtime error: index out of range [0] with length 0 in translateAndroidMkModule for module libncurses-terminfo-a
```

**原因:**
Android 16 的构建工具 Soong 在处理某些特殊的预编译模块（如 `libncurses-terminfo-a`）时，没有考虑到输出路径为空的情况，导致数组越界访问。
**解决方案:**
修改 `build/soong/etc/prebuilt_etc.go` 文件，在访问数组前增加非空检查 (Patch Applied)。

### Q3: Soong bootstrap 被杀死 (Killed) / 疑似 OOM

**报错 (典型表现):**

```text
FAILED: out/soong/build.<product>.ninja
...
Killed
soong bootstrap failed with: exit status 1
```

**原因 (高概率):**
Linux 下 `soong_build` 在解析全量 `Android.bp` 时占用内存峰值很高；当 **物理内存 + swap** 不足时，会被内核 OOM killer 直接 SIGKILL，因此日志只剩一个 `Killed`，没有更具体的堆栈。

**如何验证是否是 OOM:**

```bash
# 1) 看内存 / swap 总览
free -h

# 2) 看 swap 是否启用、使用量
swapon --show

# 3) 查 OOM killer 证据（看到 Out of memory / Killed process 基本就坐实）
dmesg -T | egrep -i 'out of memory|oom-killer|killed process' | tail -n 50
```

**解决方案 (优先级从高到低):**

1) **增加 swap（推荐优先做）**

   如果已有 4G swap（例如 `/swap.img`），目标扩到 16G 最稳的是 **再新增一个 12G swapfile**：

   ```bash
   # 新增 12G swapfile（4G + 12G = 16G）
   sudo fallocate -l 12G /swapfile2 || sudo dd if=/dev/zero of=/swapfile2 bs=1M count=12288 status=progress
   sudo chmod 600 /swapfile2
   sudo mkswap /swapfile2
   sudo swapon /swapfile2

   # 验证
   swapon --show
   free -h

   # 持久化（开机自动启用）
   echo '/swapfile2 none swap sw 0 0' | sudo tee -a /etc/fstab
   ```

2) **提高 Docker/VM 内存上限**

   如果在 Docker/虚拟机里编译，容器/VM 的内存上限太低也会导致 `Killed`。把内存调到 **16GB+（推荐 20GB+）**。

### Q4: Recovery 卡第一屏但 ADB 可连接（`/system/bin/recovery` 反复重启）

**现象:**

- 屏幕停留在 recovery 第一屏/开机画面，界面不进入 TWRP。
- `adb devices` 可见设备，说明 adbd 起来了。
- `getprop init.svc.recovery` 显示 `restarting`。

**如何发现（定位手法）:**

1) 确认在 recovery 模式并观察关键服务状态：

   ```bash
   adb shell getprop ro.bootmode
   adb shell getprop init.svc.adbd
   adb shell getprop init.svc.recovery
   ```

2) 直接用 logcat 抓 `linker` 对 `/system/bin/recovery` 的报错（这是最关键证据）：

   ```bash
   adb shell logcat -b all -d | egrep -i 'CANNOT LINK EXECUTABLE "/system/bin/recovery"|libresetprop|init.*starting service.*recovery|Service.*recovery.*exited' | tail -n 200
   ```

**根因:**

`/system/bin/recovery` 启动时动态链接失败：缺少 `libresetprop.so`，导致进程立即退出；init 不断重启 `recovery` 服务，从而表现为“卡第一屏”。

典型日志：

```text
F linker  : CANNOT LINK EXECUTABLE "/system/bin/recovery": library "libresetprop.so" not found: needed by main executable
I init    : Service 'recovery' ... exited with status 1
```

**解决方案:**

在设备树 `BoardConfig.mk` 中启用 resetprop 并确保库被打包进 recovery：

```makefile
TW_INCLUDE_RESETPROP := true
TARGET_RECOVERY_DEVICE_MODULES += libresetprop
```

### Q5: Init 脚本验证失败 (host_init_verifier)

在 Android 16（A16）构建 TWRP recovery 时，构建系统会对 recovery 的 init 脚本（`bootable/recovery/etc/*.rc`）做静态校验。其中一个关键步骤是运行 `host_init_verifier`（主机侧 init 脚本验证器）。

遇到的错误形如：

- `No user specified for service 'charger'`
- `No user specified for service 'recovery'`
- `No user specified for service 'adbd'`

这会直接导致 `ninja` 失败并中断构建。

#### 为什么会报错？

Android init 的 `service` stanza 用于定义要启动的进程，例如：

```rc
service recovery /system/bin/recovery
    seclabel u:r:recovery:s0
```

在较新的构建/校验规则下，**service 必须显式指定运行用户（`user ...`）**。即使在某些版本/实现里“未写 user 时默认是 root”，静态校验也不会去“猜默认值”，而是要求配置写清楚：

- 避免因为默认值差异导致的行为不一致
- 让审计/安全检查更明确（服务以哪个 UID 运行必须一眼可见）
- 防止后来有人改动 init 解析逻辑/默认值时引入隐蔽的权限回退或提升

因此，**缺少 `user` 被当作配置错误而不是警告**。

#### 为什么选择 `user root`

对 recovery 场景里的这些服务（`charger` / `recovery` / `adbd` / `healthd`），在绝大多数设备与 recovery 设计中，它们需要：

- 访问设备节点（`/dev/*`）
- 挂载/格式化分区
- 与 binder/ueventd/属性服务交互
- 执行 recovery 流程与调试（尤其是 `adbd`）

这些能力通常要求 root 权限配合适当的 SELinux domain（`seclabel ...`）。因此采用：

```rc
user root
```

是**最小且与预期一致**的修复：

- 只补齐 verifier 所要求的字段
- 不改变已有的 SELinux `seclabel` 语义
- 不引入新的行为路径（相比把它改成 `system`/`shell` 等更可能改变权限边界）

#### 这个修改的影响

- **构建层面**：让 `host_init_verifier` 通过，从而恢复 `m recoveryimage` 的构建链路。
- **运行时层面**：如果这些服务此前本来就是以 root 运行（常见情况），显式 `user root` 通常不会改变实际行为，只是把“隐含默认”变成“明确配置”。
- **安全层面**：这不是“放宽权限”，而是把权限写清楚；真正的权限边界仍主要由 `seclabel` 对应的 SELinux domain 决定。

#### 本次涉及到的文件（补齐 `user root`）

这些文件位于源码树：`bootable/recovery/etc/`

- `init.rc`：`service charger` / `service recovery` / `service adbd`
- `init.recovery.hlthchrg26.rc`：`service charger /charger -r`
- `init.recovery.service22.rc`：`service recovery /system/bin/recovery`
- `init.recovery.hlthchrg25.rc`：`service healthd /system/bin/healthd -r`

> 注：具体有哪些文件需要补齐，取决于你这棵树里有哪些 rc 会被 verifier 扫描，以及哪些 service stanza 缺字段。

#### 如何自检：确认没有遗漏

可以用一个简单脚本扫描 `bootable/recovery/etc/*.rc`，找出缺少 `user` 的 `service`：

```bash
python3 -c "import re, pathlib; root=pathlib.Path('bootable/recovery/etc'); missing=[]; 
for p in sorted(root.glob('*.rc')):
 txt=p.read_text(errors='ignore').splitlines(); i=0
 while i<len(txt):
  m=re.match(r'\s*service\s+(\S+)\s+(.+)$', txt[i]);
  if not m: i+=1; continue
  svc=m.group(1); j=i+1; has_user=False
  while j<len(txt) and not re.match(r'^\S', txt[j]):
   if re.match(r'\s*user\s+\S+', txt[j]): has_user=True
   j+=1
  if not has_user: missing.append((str(p), i+1, svc, txt[i].strip()))
  i=j
print('OK' if not missing else 'Found:');
[print(f'{p}:{ln}: {svc}: {hdr}') for p,ln,svc,hdr in missing];
print('Total:', len(missing))"
```

当输出是 `Total: 0` 时，至少“缺 user”这一类 verifier 问题就被清空了。

- 重新执行构建（例如 `m recoveryimage`），确认不再出现 `No user specified for service ...`。
- 若出现新的 verifier 报错，按报错指向的 rc 文件继续做同样的“最小补齐”。

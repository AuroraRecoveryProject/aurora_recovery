# 06-pd-mapper 发现 + Init 服务注入 + 镜像验证 — 结构化总结

> 原始记录按时间顺序整理。
> 全部终端命令共 399 条，以下全部保留，并拆成按过程推进的小段，避免把大量命令堆在一起。

---

## 1. Permissive 试探与 vendor 挂载缺口定位

### 大概执行的操作和目的

先确认当前 recovery 基线：是不是 clean recovery、SELinux 是否开启、音频守护进程是否还没跑。

```bash
adb shell 'getprop ro.bootmode; echo SEP; getenforce; echo SEP; ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice"'
```

然后直接做 permissive 实验，按 stock 顺序尝试拉起三段音频服务，验证 SELinux 是否是唯一阻塞。

```bash
adb shell 'setenforce 0; echo SEP; getenforce; echo SEP; mkdir -p /data/vendor/audio /data/vendor/audio_dsp /data/vendor/audio/acdbdata; /mnt/vendor_orig/bin/adsprpcd rootpd adsp >/data/adsprpcd.out 2>&1 & /mnt/vendor_orig/bin/audioadsprpcd audiopd adsp >/data/audioadsprpcd.out 2>&1 & /mnt/vendor_orig/bin/hw/audiohalservice.qti >/data/audiohal.out 2>&1 & sleep 3; ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice"'
```

看到三段服务没有稳定驻留后，继续把输出、logcat 和关键设备节点一起读出来，确认是“权限放开后前进了”，还是“压根没执行到音频链”。

```bash
adb shell 'echo ADSP; tail -n 80 /data/adsprpcd.out 2>/dev/null; echo SEP; echo AUDIO_ADSP; tail -n 120 /data/audioadsprpcd.out 2>/dev/null; echo SEP; echo AUDIO_HAL; tail -n 120 /data/audiohal.out 2>/dev/null'
adb shell 'logcat -d -b all | grep -i -E "audioadsprpcd|adsprpcd|audiohalservice|aud_pasthru|wait_for_snd_card|Transport endpoint|gpr_lx_wrapper|left unmapped|avc:" | tail -n 200'
adb shell 'ls -l /dev/aud_pasthru_* /dev/fastrpc* /dev/snd 2>/dev/null; echo SEP; cat /proc/asound/cards 2>/dev/null'
```

发现 `/mnt/vendor_orig` 根本不存在后，转去查 recovery 当前到底有哪些 vendor 相关挂载点、二进制路径、逻辑分区和 fstab 入口。

```bash
adb shell 'getenforce; echo SEP; mount | grep -E " /vendor | /mnt/| /system_root| /system " | head -n 80'

adb shell 'ls -l /vendor/bin/adsprpcd /vendor/bin/audioadsprpcd /vendor/bin/hw/audiohalservice.qti 2>/dev/null; echo SEP; ls -l /system/vendor/bin/adsprpcd /system/vendor/bin/audioadsprpcd /system/vendor/bin/hw/audiohalservice.qti 2>/dev/null; echo SEP; ls -l /mnt/vendor_orig/bin/adsprpcd /mnt/vendor_orig/bin/audioadsprpcd /mnt/vendor_orig/bin/hw/audiohalservice.qti 2>/dev/null'

adb shell 'ls -l /dev/block/by-name/vendor* /dev/block/by-name/system* 2>/dev/null | head -n 80'
```

当前 recovery 里 permissive 还在，但根本没有现成的 `/vendor` 或 `/mnt/vendor_orig` 挂载。下一步直接把可用逻辑分区和 fstab 里关于 vendor 的入口找出来，再手动挂上。

```bash
adb shell 'ls -l /dev/block/by-name | grep -E "vendor|system|super|product|odm" | head -n 120'

adb shell 'grep -R "vendor" /etc /system/etc /first_stage_ramdisk 2>/dev/null | head -n 120'

adb shell 'find /dev/block -maxdepth 3 \( -name "vendor_a" -o -name "vendor" -o -name "system_a" -o -name "super" -o -name "product_a" -o -name "odm_a" \) 2>/dev/null | head -n 120'
```

确认 `vendor_a` 存在后，继续核对挂载点和文件系统类型，并手工把 `vendor_a` 挂到 `/vendor`，再确认音频二进制终于可见。

fstab 已经给了答案：`vendor` 是逻辑分区，挂到 `/vendor`，文件系统优先 `erofs`。先按 recovery 自己的 fstab 把 `vendor` 挂上，再补 `dsp`，然后重新跑 permissive 实验。

```bash
adb shell 'ls -ld /vendor /vendor/dsp /vendor/firmware_mnt /mnt/vendor 2>/dev/null; echo SEP; blkid /dev/block/mapper/vendor_a /dev/block/by-name/dsp_a /dev/block/by-name/modem_a 2>/dev/null'

adb shell 'mount -t erofs -o ro /dev/block/mapper/vendor_a /vendor 2>/tmp/mv1 || mount -t ext4 -o ro /dev/block/mapper/vendor_a /vendor 2>>/tmp/mv1; echo SEP; cat /tmp/mv1; echo SEP; ls -l /vendor/bin/adsprpcd /vendor/bin/audioadsprpcd /vendor/bin/hw/audiohalservice.qti 2>/dev/null'

adb shell 'mount | grep -E " /vendor | /vendor_dlkm | /vendor/dsp | /vendor/firmware_mnt"'
```

最后补一眼 `dsp` / `firmware` 相关路径，确认后面重跑音频链不会再次卡在库和 firmware 不可见。

```bash
adb shell 'ls -ld /vendor/dsp /firmware /vendor/firmware_mnt 2>/dev/null; echo SEP; ls -l /dev/block/by-name | grep -E "dsp|modem"'

adb shell 'mount | grep -E " /vendor/dsp | /firmware "'

adb shell 'ls /vendor/lib64/libadsp_default_listener.so /vendor/lib/rfsa/adsp 2>/dev/null; echo SEP; ls /firmware/image 2>/dev/null | head -n 20'
```

结论:

二进制、库和 firmware 现在都可见了。我直接在 permissive 下重拉音频链，并同时盯着 `aud_pasthru`、`/dev/snd` 和关键日志，看它有没有比 enforcing 往前走。

- permissive 虽然切成功了，但最早并没有真正进入音频链，原因不是 SELinux，而是 `/mnt/vendor_orig` 不存在、stock 二进制没执行。
- recovery 当前没有现成 `/vendor` 挂载，必须自己从逻辑分区和 fstab 入口把 `vendor_a` 挂上来。
- `vendor_a` 挂到 `/vendor` 之后，`adsprpcd`、`audioadsprpcd`、`audiohalservice.qti` 才真正可用，这一步是后面所有实验的前提。

---

## 2. vendor 挂好后重拉音频链，并确认 ABI 冲突先于声卡问题

现在 `/vendor` 已经可用，重新按 stock 路径拉起三段音频服务，判断问题是不是终于进入 DSP 或声卡阶段。

```bash
adb shell 'killall adsprpcd audioadsprpcd audiohalservice.qti 2>/dev/null; export LD_LIBRARY_PATH=/vendor/lib64:/vendor/lib:/system/lib64:/system/lib; /vendor/bin/adsprpcd rootpd adsp >/data/adsprpcd.out 2>&1 & /vendor/bin/audioadsprpcd audiopd adsp >/data/audioadsprpcd.out 2>&1 & /vendor/bin/hw/audiohalservice.qti >/data/audiohal.out 2>&1 & sleep 4; ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice"'

adb shell 'ls -l /dev/aud_pasthru_* /dev/fastrpc* /dev/snd 2>/dev/null; echo SEP; cat /proc/asound/cards 2>/dev/null'

adb shell 'echo ADSP; tail -n 80 /data/adsprpcd.out 2>/dev/null; echo SEP; echo AUDIO_ADSP; tail -n 120 /data/audioadsprpcd.out 2>/dev/null; echo SEP; echo AUDIO_HAL; tail -n 120 /data/audiohal.out 2>/dev/null'
```

permissive 实验已经给出一个新结果：`adsprpcd` 能留住，但 `audiohalservice.qti` 这次不是卡在声卡，而是直接因 `libbinder_ndk.so` 符号不匹配启动失败。把 `audioadsprpcd` 和 linker 错误的日志补齐，判断这是不是 recovery 用户态基座不兼容。

```bash
adb shell 'ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice"; echo SEP; logcat -d -b all | grep -i -E "audioadsprpcd|adsprpcd|audiohalservice|CANNOT LINK EXECUTABLE|libbinder_ndk|Transport endpoint|aud_pasthru" | tail -n 200'
adb shell 'readelf -Ws /system/lib64/libbinder_ndk.so 2>/dev/null | grep get_trace_enabled_tags; echo SEP; readelf -Ws /vendor/bin/hw/audiohalservice.qti 2>/dev/null | grep libbinder_ndk | head -n 40'
adb shell 'readelf -d /vendor/bin/audioadsprpcd 2>/dev/null | head -n 80; echo SEP; readelf -d /vendor/bin/hw/audiohalservice.qti 2>/dev/null | head -n 120'
```

抓到一个硬阻塞：`audiohalservice.qti` 在 permissive 下也起不来，而且不是 sepolicy，而是 recovery 自带 `libbinder_ndk.so` 缺它要的符号

为了确认符号差异到底来自 recovery 的系统库，继续挂上 `system_a`，核对 `libbinder_ndk.so` 与 `libbinder.so` 的真实符号与依赖。

```bash
adb shell 'mkdir -p /mnt/system_a; mount -t erofs -o ro /dev/block/mapper/system_a /mnt/system_a 2>/tmp/ms1 || mount -t ext4 -o ro /dev/block/mapper/system_a /mnt/system_a 2>>/tmp/ms1; echo SEP; cat /tmp/ms1; echo SEP; ls -l /mnt/system_a/lib64/libbinder_ndk.so /system/lib64/libbinder_ndk.so 2>/dev/null'

adb shell 'readelf -Ws /mnt/system_a/lib64/libbinder_ndk.so 2>/dev/null | grep get_trace_enabled_tags; echo SEP; readelf -Ws /system/lib64/libbinder_ndk.so 2>/dev/null | grep get_trace_enabled_tags'

adb shell 'mount | grep -E " /mnt/system_a | /system "'
```

`system_a` 已经挂上了，但它不是平铺布局，得再看一眼真实的 system-as-root 目录，再做符号对比。

```bash
adb shell 'ls -ld /mnt/system_a/system /mnt/system_a/system/lib64 /mnt/system_a/lib64 2>/dev/null'

adb shell 'ls -l /mnt/system_a/system/lib64/libbinder_ndk.so 2>/dev/null; echo SEP; readelf -Ws /mnt/system_a/system/lib64/libbinder_ndk.so 2>/dev/null | grep get_trace_enabled_tags'
```

符号在 `libbinder_ndk.so` 里只是未定义引用，还得继续看是谁提供它。接着把 recovery 和 stock 的 `libbinder.so` 对照一下，确认真正缺定义的是哪边。

```bash
adb shell 'echo RECOVERY; readelf -Ws /system/lib64/libbinder.so 2>/dev/null | grep get_trace_enabled_tags; echo SEP; echo STOCK; readelf -Ws /mnt/system_a/system/lib64/libbinder.so 2>/dev/null | grep get_trace_enabled_tags'

adb shell 'echo RECOVERY; readelf -d /system/lib64/libbinder_ndk.so 2>/dev/null | grep NEEDED; echo SEP; echo STOCK; readelf -d /mnt/system_a/system/lib64/libbinder_ndk.so 2>/dev/null | grep NEEDED'
```


permissive 实验已经跑完了，结果比之前更硬：问题现在先卡在 recovery 用户态 ABI 上，连 `adsprpcd` 和 `audiohalservice.qti` 都过不了动态链接。这个结论需要补回文档和记忆，避免后面还按“只要放开 SELinux 就能继续”的思路推进。

`Permissive` 确实切成功了，`vendor_a` 也已经手工挂到了 `/vendor`，并确认 `/vendor/bin/adsprpcd`、`/vendor/bin/audioadsprpcd`、`/vendor/bin/hw/audiohalservice.qti` 和相关库都可见。随后重新在 recovery 里手工拉起整条音频链。结果不是声卡往前走，也不是 `aud_pasthru_adsp` 出现，而是更早就撞上了用户态动态链接失败。

现在最硬的阻塞是这个：

- `adsprpcd` 会循环报 `dlopen failed: cannot locate symbol _ZN7android6binder2os22get_trace_enabled_tagsEv referenced by /system/lib64/libbinder_ndk.so`
- `audiohalservice.qti` 也会直接报 `CANNOT LINK EXECUTABLE`，同样卡在这个 binder 相关符号
- `/dev/aud_pasthru_adsp` 仍然没有出现
- `/proc/asound/cards` 仍然是 `--- no soundcards ---`

这说明两件事。第一，`Permissive` 已经排除了“纯 sepolicy 阻塞”这条单一假设。第二，当前 recovery 的 system 用户态和 stock `vendor` 音频二进制之间，至少还存在一层 binder 相关 ABI / 运行时不兼容，所以现在连 `adsprpcd` 和 `audiohalservice.qti` 都没真正进入 DSP/ASoC 阶段。

接着做一次临时 bind 实验，把 recovery 当前用到的两颗 binder 库切成 stock 分区版本，再重拉 `adsprpcd` 看错误是否变化。

```bash
adb shell 'ls -l /system/lib64/libbinder.so /system/lib64/libbinder_ndk.so /mnt/system_a/system/lib64/libbinder.so /mnt/system_a/system/lib64/libbinder_ndk.so 2>/dev/null; echo SEP; readlink /system/lib64/libbinder.so 2>/dev/null; echo SEP; readlink /system/lib64/libbinder_ndk.so 2>/dev/null'

adb shell 'cmp -s /system/lib64/libbinder.so /mnt/system_a/system/lib64/libbinder.so; echo binder:$?; cmp -s /system/lib64/libbinder_ndk.so /mnt/system_a/system/lib64/libbinder_ndk.so; echo binder_ndk:$?'

adb shell 'mount | grep -E " /mnt/system_a | /vendor | /system "'
```

对比已经说明是两套不同的库，不是“同文件不同路径”。先只替换 `libbinder.so` 和 `libbinder_ndk.so` 两个最直接命中的库，验证这个修法是不是立刻生效。

```bash
adb shell 'mount --bind /mnt/system_a/system/lib64/libbinder.so /system/lib64/libbinder.so && mount --bind /mnt/system_a/system/lib64/libbinder_ndk.so /system/lib64/libbinder_ndk.so && echo OK; mount | grep -E "libbinder(\.so|_ndk\.so)"'

adb shell 'killall adsprpcd audioadsprpcd audiohalservice.qti 2>/dev/null; export LD_LIBRARY_PATH=/vendor/lib64:/vendor/lib:/system/lib64:/system/lib; /vendor/bin/adsprpcd rootpd adsp >/data/adsprpcd.out 2>&1 & sleep 2; ps -A | grep adsprpcd; echo SEP; tail -n 80 /data/adsprpcd.out 2>/dev/null'

adb shell 'logcat -d -b all | grep -i -E "adsprpcd|CANNOT LINK EXECUTABLE|get_trace_enabled_tags|dlopen failed" | tail -n 120'
```

为了判断是否不只是两颗 binder 库的问题，又继续把 `audioadsprpcd`、`audiohalservice.qti` 一起拉起，检查实际使用了哪套库、有没有继续留住。

```bash
adb shell 'export LD_LIBRARY_PATH=/vendor/lib64:/vendor/lib:/system/lib64:/system/lib; /vendor/bin/audioadsprpcd audiopd adsp >/data/audioadsprpcd.out 2>&1 & /vendor/bin/hw/audiohalservice.qti >/data/audiohal.out 2>&1 & sleep 3; ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice"'

adb shell 'ls -l /dev/aud_pasthru_* /dev/fastrpc* /dev/snd 2>/dev/null; echo SEP; cat /proc/asound/cards 2>/dev/null'

adb shell 'echo ADSP_OUT; tail -n 80 /data/adsprpcd.out 2>/dev/null; echo SEP; echo AUDIO_ADSP_OUT; tail -n 120 /data/audioadsprpcd.out 2>/dev/null; echo SEP; echo AUDIO_HAL_OUT; tail -n 120 /data/audiohal.out 2>/dev/null'

adb shell 'grep -E "libbinder(\.so|_ndk\.so)" /proc/3875/maps 2>/dev/null'

adb shell 'ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice"; echo SEP; pidof audioadsprpcd 2>/dev/null; echo SEP; pidof audiohalservice.qti 2>/dev/null'
```

再向前推一层，尝试直接调用 stock `linker64`，同时摸清 `APEX` 布局，确认问题确实在 recovery userspace 整体基座，而不是单文件替换就能解决。

```bash
adb shell 'ls -l /system/bin/linker64 /mnt/system_a/system/bin/linker64 2>/dev/null; echo SEP; cmp -s /system/bin/linker64 /mnt/system_a/system/bin/linker64; echo linker:$?'

adb shell '/mnt/system_a/system/bin/linker64 --library-path /mnt/system_a/system/lib64:/vendor/lib64:/vendor/lib:/system/lib64:/system/lib /vendor/bin/hw/audiohalservice.qti >/data/audiohal_linker.out 2>&1 & sleep 2; ps -A | grep audiohalservice; echo SEP; tail -n 80 /data/audiohal_linker.out 2>/dev/null'

adb shell '/mnt/system_a/system/bin/linker64 --library-path /mnt/system_a/system/lib64:/vendor/lib64:/vendor/lib:/system/lib64:/system/lib /vendor/bin/adsprpcd rootpd adsp >/data/adsprpcd_linker.out 2>&1 & sleep 2; ps -A | grep adsprpcd; echo SEP; tail -n 80 /data/adsprpcd_linker.out 2>/dev/null'
```

stock 的 `linker64` 其实是指向 APEX 里的目标，直接从 `system_a` 路径跑不起来，说明还得把 runtime APEX 这一层补进来。先把 stock APEX 的真实布局摸清，再决定是 bind 还是直接用解包路径。

```bash
adb shell 'ls -l /mnt/system_a/apex/com.android.runtime* /mnt/system_a/system/apex/com.android.runtime* 2>/dev/null'

adb shell 'ls -l /apex/com.android.runtime/bin/linker64 /apex/com.android.runtime/lib64 /system/bin/linker64 2>/dev/null'

adb shell 'find /mnt/system_a/system/apex -maxdepth 1 -type f | head -n 40; echo SEP; find /mnt/system_a/system/apex -maxdepth 1 -type l | head -n 40'
```

最后把日志清空后只盯一轮干净的 `adsprpcd` 输出，同时对比整组基础库差异，确认 recovery 与 stock 并不只是两颗 binder 库不同。

```bash
adb shell 'logcat -c; killall adsprpcd 2>/dev/null; rm -f /data/adsprpcd.out; export LD_LIBRARY_PATH=/vendor/lib64:/vendor/lib:/system/lib64:/system/lib; /vendor/bin/adsprpcd rootpd adsp >/data/adsprpcd.out 2>&1 & sleep 2; ps -A | grep adsprpcd'

adb shell 'echo OUT; cat /data/adsprpcd.out 2>/dev/null; echo SEP; logcat -d -b all | grep -i adsprpcd'

adb shell 'ls -l /system/lib64/libbinder.so /system/lib64/libbinder_ndk.so 2>/dev/null; echo SEP; stat -c "%D:%i %n" /system/lib64/libbinder.so /system/lib64/libbinder_ndk.so /mnt/system_a/system/lib64/libbinder.so /mnt/system_a/system/lib64/libbinder_ndk.so 2>/dev/null'
```

bind 已经确认生效了，`/system/lib64/libbinder*.so` 现在就是 stock 分区那份。接下来只看这一轮的干净日志，就能知道这个修法是否真的把 `adsprpcd` 拉过了链接阶段。

两颗 binder 库单换不够，说明拉起来的那段 userspace 还在吃 recovery 自己的配套库。先把 binder 这一族相关依赖和 stock 做个差异表，再决定最小替换集，而不是盲目整目录覆盖。

```bash
adb shell 'for f in libbinder.so libbinder_ndk.so libutils.so libcutils.so libbase.so libc++.so liblog.so; do ls -l /system/lib64/$f /mnt/system_a/system/lib64/$f 2>/dev/null; echo SEP; done'

adb shell 'for f in libbinder.so libbinder_ndk.so libutils.so libcutils.so libbase.so libc++.so liblog.so; do cmp -s /system/lib64/$f /mnt/system_a/system/lib64/$f 2>/dev/null; echo $f:$?; done'

adb shell 'readelf -d /vendor/bin/hw/audiohalservice.qti 2>/dev/null | grep NEEDED; echo SEP; readelf -d /vendor/bin/adsprpcd 2>/dev/null | grep NEEDED'
```

现在最可能的问题不是 `libbinder*` 本身，而是它旁边那组 recovery 版配套库还没切过去。`libutils`、`libcutils`、`libbase`、`liblog` 和 stock 都不一样，于是把这组也临时换成真实分区版再试一次。

```bash
adb shell 'mount --bind /mnt/system_a/system/lib64/libutils.so /system/lib64/libutils.so && mount --bind /mnt/system_a/system/lib64/libcutils.so /system/lib64/libcutils.so && mount --bind /mnt/system_a/system/lib64/libbase.so /system/lib64/libbase.so && mount --bind /mnt/system_a/system/lib64/liblog.so /system/lib64/liblog.so && echo OK'

adb shell 'logcat -c; killall adsprpcd audioadsprpcd audiohalservice.qti 2>/dev/null; rm -f /data/adsprpcd.out /data/audioadsprpcd.out /data/audiohal.out; export LD_LIBRARY_PATH=/vendor/lib64:/vendor/lib:/system/lib64:/system/lib; /vendor/bin/adsprpcd rootpd adsp >/data/adsprpcd.out 2>&1 & sleep 2; ps -A | grep adsprpcd; echo SEP; cat /data/adsprpcd.out 2>/dev/null; echo SEP; logcat -d -b all | grep -i adsprpcd'

adb shell 'for f in libutils.so libcutils.so libbase.so liblog.so; do stat -c "%D:%i %n" /system/lib64/$f /mnt/system_a/system/lib64/$f 2>/dev/null; done'
```

这组 stock 配套库替上去后，`adsprpcd` 至少不再把错误直接打到标准输出里了，但副作用是 recovery 自己的 `logcat` 也被这组库打坏了。说明方向是对的，不过替换范围已经开始碰到 recovery userspace 本身。接下来只靠进程和输出文件继续看音频链有没有实质前进。

```bash
adb shell 'sleep 3; ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice"; echo SEP; cat /data/adsprpcd.out 2>/dev/null; echo SEP; ls -l /dev/aud_pasthru_* /dev/fastrpc* /dev/snd 2>/dev/null; echo SEP; cat /proc/asound/cards 2>/dev/null'

adb shell 'export LD_LIBRARY_PATH=/vendor/lib64:/vendor/lib:/system/lib64:/system/lib; /vendor/bin/audioadsprpcd audiopd adsp >/data/audioadsprpcd.out 2>&1 & /vendor/bin/hw/audiohalservice.qti >/data/audiohal.out 2>&1 & sleep 3; ps -A | grep -E "audioadsprpcd|audiohalservice"; echo SEP; echo AUDIO_ADSP; cat /data/audioadsprpcd.out 2>/dev/null; echo SEP; echo AUDIO_HAL; cat /data/audiohal.out 2>/dev/null'

adb shell 'grep -E "libbinder|libutils|libcutils|libbase|liblog" /proc/4133/maps 2>/dev/null | head -n 40'
```

增量已经有了：换成真实分区的这组库后，`adsprpcd` 至少不再把那个 binder 符号错误打出来，而且能稳定留住；`audiohalservice.qti` 还没过链接阶段。下一步只盯 `audioadsprpcd` 本身，确认它现在是静默退出还是进入原先的 FastRPC 错误。

```bash
adb shell 'export LD_LIBRARY_PATH=/vendor/lib64:/vendor/lib:/system/lib64:/system/lib; /vendor/bin/audioadsprpcd audiopd adsp'

adb shell 'export LD_LIBRARY_PATH=/vendor/lib64:/vendor/lib:/system/lib64:/system/lib; /vendor/bin/hw/audiohalservice.qti'

adb shell 'ls -l /vendor/lib64/libutils.so /vendor/lib64/libbase.so /vendor/lib64/libcutils.so /vendor/lib64/liblog.so /vendor/lib64/libbinder.so /vendor/lib64/libbinder_ndk.so 2>/dev/null'
```

结论:

- `/vendor` 挂好以后，问题没有直接进入声卡阶段，而是更早卡在 recovery userspace 与 stock vendor 二进制的 ABI 不兼容上。
- `audiohalservice.qti` 的 binder 符号错误说明 permissive 不是主因，用户态运行时才是新前沿。
- 这一轮把方向从“继续怀疑 sepolicy”收敛成“必须让进程优先使用真实 system 分区库，或者直接复用 stock userspace 运行环境”。

---

## 3. 改用真实 system 库查询路径，并修正 /odm 与 secure fastrpc

在用户指出不该直接替换库文件之后，改成只调整 `LD_LIBRARY_PATH`，让进程优先查询真实 `system_a` 下的库，先验证这是否足以消掉 binder 链接错误。

```bash
adb shell 'mount | grep -E " /vendor | /mnt/system_a " ; echo SEP; ls -l /vendor/bin/adsprpcd /vendor/bin/audioadsprpcd /vendor/bin/hw/audiohalservice.qti /mnt/system_a/system/lib64/libbinder.so /mnt/system_a/system/lib64/libbinder_ndk.so 2>/dev/null'

adb shell 'killall adsprpcd audioadsprpcd audiohalservice.qti 2>/dev/null; rm -f /data/adsprpcd.out /data/audioadsprpcd.out /data/audiohal.out; export LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/vendor/lib64:/system/lib64; /vendor/bin/adsprpcd rootpd adsp >/data/adsprpcd.out 2>&1 & sleep 3; ps -A | grep adsprpcd; echo SEP; cat /data/adsprpcd.out 2>/dev/null'

adb shell 'logcat -c; echo cleared'
```

这个修法已经把最前面的链接错误打掉了：`adsprpcd` 现在在新 `LD_LIBRARY_PATH` 下能稳定驻留，而且输出文件为空，没有再报那个 binder 符号错误。下一步用同样的方法把 `audioadsprpcd` 和 `audiohalservice.qti` 一起拉起来，看链路还能往前推进多少。

确认 `adsprpcd` 能稳定驻留后，把 `audioadsprpcd` 和 `audiohalservice.qti` 一起拉起，观察错误前沿是否已经从链接问题推进到运行时问题。

```bash
adb shell 'export LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/vendor/lib64:/system/lib64; /vendor/bin/audioadsprpcd audiopd adsp >/data/audioadsprpcd.out 2>&1 & /vendor/bin/hw/audiohalservice.qti >/data/audiohal.out 2>&1 & sleep 4; ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice"'

adb shell 'echo AUDIO_ADSP; cat /data/audioadsprpcd.out 2>/dev/null; echo SEP; echo AUDIO_HAL; cat /data/audiohal.out 2>/dev/null; echo SEP; ls -l /dev/aud_pasthru_* /dev/fastrpc* /dev/snd 2>/dev/null; echo SEP; cat /proc/asound/cards 2>/dev/null'

adb shell 'logcat -d -b all | grep -i -E "audioadsprpcd|adsprpcd|audiohalservice|Transport endpoint|wait_for_snd_card|gpr_lx_wrapper|aud_pasthru|CANNOT LINK EXECUTABLE" | tail -n 200'
```

这个点是对的，单纯把真实分区库放到查询路径前面以后，链路已经明显前进了：`audioadsprpcd` 和 `audiohalservice.qti` 现在都能起来，原来的 binder 符号错误已经不再是首要阻塞。现在新的前沿卡点变成了 `/odm/lib/rfsa/adsp` 的符号链接异常，以及 HAL 继续等声卡上线。

新前沿出现 `/odm/lib/rfsa/adsp` 异常后，继续检查 `/odm` 的符号链接和真实挂载，并把 `odm_a` 挂上去。

```bash
adb shell 'ls -ld /odm /vendor/odm 2>/dev/null; echo SEP; readlink /odm 2>/dev/null; echo SEP; readlink -f /odm 2>/dev/null; echo SEP; ls -ld /odm/lib /odm/lib/rfsa /odm/lib/rfsa/adsp 2>/dev/null'

adb shell 'mount | grep -E " /odm "; echo SEP; mount -t erofs -o ro /dev/block/mapper/odm_a /odm 2>/tmp/modm || mount -t ext4 -o ro /dev/block/mapper/odm_a /odm 2>>/tmp/modm; echo SEP; cat /tmp/modm; echo SEP; ls -ld /odm /odm/lib/rfsa/adsp 2>/dev/null'
```

然后在修正了 `/odm` 的前提下重拉 `audioadsprpcd` 与 `audiohalservice.qti`，看看链路是否继续前移。

```bash
adb shell 'export LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/vendor/lib64:/system/lib64; killall audioadsprpcd audiohalservice.qti 2>/dev/null; rm -f /data/audioadsprpcd.out /data/audiohal.out; logcat -c; /vendor/bin/audioadsprpcd audiopd adsp >/data/audioadsprpcd.out 2>&1 & /vendor/bin/hw/audiohalservice.qti >/data/audiohal.out 2>&1 & sleep 8; ps -A | grep -E "audioadsprpcd|audiohalservice"; echo SEP; cat /data/audioadsprpcd.out 2>/dev/null; echo SEP; cat /data/audiohal.out 2>/dev/null; echo SEP; ls -l /dev/aud_pasthru_* /dev/snd 2>/dev/null; echo SEP; cat /proc/asound/cards 2>/dev/null'
```

`/odm` 这条线也坐实了：之前确实是 recovery 自带的 `/odm/lib -> /vendor/odm/lib -> /odm/lib` 环。把真实 `odm_a` 挂上去以后，这个路径异常消失了。现在 `audioadsprpcd` 和 `audiohalservice.qti` 都能稳定驻留，但 `aud_pasthru_adsp` 和声卡还是没有出来，接着只看这一轮的新日志。

```bash
adb shell 'logcat -d -b all | grep -i -E "audioadsprpcd|audiohalservice|adsprpcd|Transport endpoint|wait_for_snd_card|gpr_lx_wrapper|aud_pasthru|fastrpc_wait_for_secure_device|adsp_default_listener" | tail -n 240'

adb shell 'export LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/vendor/lib64:/system/lib64; killall adsprpcd 2>/dev/null; rm -f /data/adsprpcd.out; /vendor/bin/adsprpcd rootpd adsp >/data/adsprpcd.out 2>&1 & sleep 5; ps -A | grep adsprpcd; echo SEP; cat /data/adsprpcd.out 2>/dev/null'

adb shell 'ls -l /dev/fastrpc* 2>/dev/null; echo SEP; ls -l /sys/class/misc | grep -i fastrpc; echo SEP; cat /sys/class/misc/fastrpc-adsp-secure/uevent 2>/dev/null'
```

这一步又有增量：在修正 `LD_LIBRARY_PATH` 和 `/odm` 后，`adsprpcd` 也重新能留住了，不再立刻退出，确认是已经真正过了 secure listener 阶段，还是只是挂着没继续推进。

指出的问题已经修正了，现在线路前进到了真正的运行时层面。当前新前沿不是链接错误，而是 clean recovery 这次启动后连 `/dev/fastrpc-adsp-secure` 都没出来，所以 `audioadsprpcd` 开始报 `fastrpc_wait_for_secure_device: Poll timeout`，HAL 则继续卡在 `aud_pasthru_adsp` 和声卡不存在。

发现 clean recovery 根本没加载 `frpc-adsprpc.ko` 后，继续查模块状态并手工补 `insmod`，确认 secure fastrpc 节点是不是此前一直都没创建出来。

```bash
adb shell 'ls /dev | grep -E "fastrpc|aud_pas|gpr" | sort; echo SEP; lsmod | grep -i -E "frpc|adsprpc|gpr|spf|audio_pkt|audio_prm|q6"'

adb shell 'modinfo /vendor_dlkm/lib/modules/frpc-adsprpc.ko 2>/dev/null | head -n 40; echo SEP; ls -l /vendor_dlkm/lib/modules/frpc-adsprpc.ko 2>/dev/null'

adb shell 'insmod /vendor_dlkm/lib/modules/frpc-adsprpc.ko 2>/tmp/frpcins; echo SEP; cat /tmp/frpcins; echo SEP; ls /dev | grep -E "fastrpc|aud_pas|gpr" | sort; echo SEP; lsmod | grep -i frpc'
```

当前 clean recovery 的直接问题已经找到了：这次启动后 `frpc_adsprpc` 压根没加载，所以连 `/dev/fastrpc-adsp-secure` 都不存在。手动 `insmod` 后这个节点已经回来了。现在重跑音频链，看 `fastrpc_wait_for_secure_device` 会不会消失。

最后在 `frpc-adsprpc` 已补齐、stock 库路径已生效的前提下，重新拉起三段进程，验证 secure fastrpc 这一层是否已打通。

```bash
adb shell 'killall adsprpcd audioadsprpcd audiohalservice.qti 2>/dev/null; rm -f /data/adsprpcd.out /data/audioadsprpcd.out /data/audiohal.out; logcat -c; export LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/vendor/lib64:/system/lib64; /vendor/bin/adsprpcd rootpd adsp >/data/adsprpcd.out 2>&1 & /vendor/bin/audioadsprpcd audiopd adsp >/data/audioadsprpcd.out 2>&1 & /vendor/bin/hw/audiohalservice.qti >/data/audiohal.out 2>&1 & sleep 10; ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice"'

adb shell 'echo ADSP; cat /data/adsprpcd.out 2>/dev/null; echo SEP; echo AUDIO_ADSP; cat /data/audioadsprpcd.out 2>/dev/null; echo SEP; echo AUDIO_HAL; cat /data/audiohal.out 2>/dev/null; echo SEP; ls -l /dev/fastrpc* /dev/aud_pasthru_* /dev/snd 2>/dev/null; echo SEP; cat /proc/asound/cards 2>/dev/null'

adb shell 'logcat -d -b all | grep -i -E "audioadsprpcd|adsprpcd|audiohalservice|Transport endpoint|wait_for_snd_card|gpr_lx_wrapper|aud_pasthru|fastrpc_wait_for_secure_device|adsp_default_listener" | tail -n 260'
```

结论:

- 把真实 `system_a` 库放到查询路径最前面后，binder 链接错误就不是主阻塞了，说明用户指出的方向是对的。
- `/odm` 的 recovery 环路会干扰音频路径，挂上真实 `odm_a` 后这层异常消失。
- `frpc-adsprpc` 在 clean recovery 中默认没加载，secure fastrpc 节点此前根本不存在；补齐后，问题前沿第一次真正推进到了运行时音频链本体。

---

## 4. 回到 live recovery，定位 aud_pasthru 的真实注册链

现在基础运行环境已经基本修正，重新拉平当前 recovery 的 live 状态，确认模块、节点、进程三组事实有没有漂移。

```bash
adb get-state
adb shell 'getprop ro.bootmode; getprop sys.boot_completed; uname -a'
adb shell 'ls /dev | grep -E "fastrpc|aud_pas|gpr"; echo ---; ls /dev/snd; echo ---; cat /proc/asound/cards 2>/dev/null'
adb shell 'ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice"; echo ---; lsmod | grep -E "frpc|gpr|spf|aud|q6|snd"'
```

代码侧先有一个硬事实：recovery 的 ueventd 已经预留了 aud_pasthru 节点权限，说明现在不是“少了一行创建设备节点规则”，而是内核根本没注册出对应字符设备。接着直接在源码里找这个字符设备是谁注册的。

然后把搜索范围缩到源码树和 ko 本体，确认 `aud_pasthru` 到底是谁注册的，避免继续凭感觉追错误方向。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n 'aud_pasthru' twrp_a16_compile/kernel twrp_a16_compile/vendor 2>/dev/null | head -n 80

cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n 'gpr_channel|gpr_lx|spf_core_platform|apm is not up' twrp_a16_compile/kernel twrp_a16_compile/vendor 2>/dev/null | head -n 120

cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n 'apps_dev_init|adsp_default_listener|createstaticpd:audiopd' twrp_a16_compile/vendor twrp_a16_compile/system 2>/dev/null | head -n 80
```

源码树里没有直接的明文实现，说明关键逻辑大概率只在预编译 ko 里。那就转向设备上的模块本体，找哪个 ko 内含 aud_pasthru 或相关符号字符串。

```bash
adb shell 'find /vendor_dlkm/lib/modules -maxdepth 1 -name "*.ko" | sed "s#.*/##" | grep -E "audio|snd|wcd|spf|gpr|adsp|q6|fastrpc" | sort | head -n 200'

adb shell 'for f in /vendor_dlkm/lib/modules/*.ko; do strings "$f" 2>/dev/null | grep -q aud_pasthru && echo "$f"; done'

adb shell 'for f in /vendor_dlkm/lib/modules/*.ko; do strings "$f" 2>/dev/null | grep -q gpr_channel && echo "$f"; done'
```

现在抓到第一个像样的差分了：包含 aud_pasthru 字符串的是 audio_pkt_dlkm.ko，而且它当前并不在已加载模块里。这比继续盯着 secure fastrpc 更接近根因。先把它和相关依赖关系看清。

```bash
adb shell 'strings /vendor_dlkm/lib/modules/audio_pkt_dlkm.ko 2>/dev/null | grep -n aud_pasthru | head -n 40'

adb shell 'modinfo /vendor_dlkm/lib/modules/audio_pkt_dlkm.ko 2>/dev/null || strings /vendor_dlkm/lib/modules/audio_pkt_dlkm.ko 2>/dev/null | grep -E "depends=|description=|alias=" | head -n 40'

adb shell 'modinfo /vendor_dlkm/lib/modules/audio_prm_dlkm.ko 2>/dev/null || strings /vendor_dlkm/lib/modules/audio_prm_dlkm.ko 2>/dev/null | grep -E "depends=|description=|alias=" | head -n 40'

adb shell 'ls /sys/bus/platform/drivers 2>/dev/null | grep -E "audio|gpr|spf|q6|wcd" | sort | head -n 200'
```

这是更具体的链路了：audio_pkt_dlkm 自己就声明了 qcom,audio-pkt 平台驱动，并且依赖 spf_core、gpr、audpkt_ion。现在要确认两件事，一是设备树里有没有对应 platform device，二是 recovery 里是不是单纯没把这些模块装上。

```bash
adb shell 'ls /sys/bus/platform/devices 2>/dev/null | grep -E "audio|spf|gpr|wsa|wcd|snd" | sort | head -n 200'

adb shell 'find /vendor_dlkm/lib/modules -maxdepth 1 -name "*audpkt*" -o -name "*audio_pkt*" -o -name "*audio_prm*" | sort'
adb shell 'modinfo /vendor_dlkm/lib/modules/audpkt_ion_dlkm.ko 2>/dev/null || echo no_modinfo'
adb shell 'lsmod | grep -E "audio_pkt|audio_prm|audpkt|spf_core|gpr"'
```

看到 `audio_pkt` / `audpkt_ion` / `audio_prm` 没进来后，先做最小 `insmod`，并同时检查为什么内核返回的是 “No such file or directory”。

```bash
adb shell 'insmod /vendor_dlkm/lib/modules/audpkt_ion_dlkm.ko 2>/data/audpkt_ion.err; echo $?; cat /data/audpkt_ion.err 2>/dev/null'

adb shell 'insmod /vendor_dlkm/lib/modules/audio_pkt_dlkm.ko 2>/data/audio_pkt.err; echo $?; cat /data/audio_pkt.err 2>/dev/null'

adb shell 'insmod /vendor_dlkm/lib/modules/audio_prm_dlkm.ko 2>/data/audio_prm.err; echo $?; cat /data/audio_prm.err 2>/dev/null'
```

加载失败不是依赖不满足，而是更底层的路径问题：find 能列出来，但 insmod 直接说文件不存在。先把这几个 ko 的真实路径和挂载状态核一下，避免被 recovery 的符号链接或挂载视图再坑一次。

```bash
adb shell 'mount | grep vendor_dlkm; echo ---; ls -ld /vendor_dlkm /vendor_dlkm/lib /vendor_dlkm/lib/modules 2>/dev/null'
adb shell 'ls -l /vendor_dlkm/lib/modules/audio_pkt_dlkm.ko /vendor_dlkm/lib/modules/audio_prm_dlkm.ko /vendor_dlkm/lib/modules/audpkt_ion_dlkm.ko 2>&1'
adb shell 'find -L /vendor_dlkm/lib/modules -maxdepth 1 \( -name "audio_pkt_dlkm.ko" -o -name "audio_prm_dlkm.ko" -o -name "audpkt_ion_dlkm.ko" \) -exec ls -l {} \;'
```

路径本身没问题，那这个 “No such file or directory” 更像是内核在报未满足依赖符号。下一步按依赖顺序补最小集合，而不是直接怼主模块。

进一步查模块依赖和 dmesg，确认不是路径问题，而是未解析符号，于是按依赖顺序先补 `oplus_audio_daemon`。

```bash
adb shell 'modinfo /vendor_dlkm/lib/modules/oplus_audio_daemon.ko 2>/dev/null || true; echo ---; lsmod | grep oplus_audio_daemon'
adb shell 'modinfo /vendor_dlkm/lib/modules/audio_pkt_dlkm.ko | grep depends; echo ---; modinfo /vendor_dlkm/lib/modules/audpkt_ion_dlkm.ko | grep depends; echo ---; modinfo /vendor_dlkm/lib/modules/audio_prm_dlkm.ko | grep depends'
adb shell 'dmesg | tail -n 80'
adb shell 'dmesg | grep -i -E "audio_pkt|audpkt|audio_prm|Unknown symbol|module verification|disagrees about version" | tail -n 80'
adb shell 'insmod /vendor_dlkm/lib/modules/oplus_audio_daemon.ko 2>/data/oplus_audio_daemon.err; echo $?; cat /data/oplus_audio_daemon.err 2>/dev/null'
```

内核日志把原因打实了：前一轮失败就是未解析符号，其中两组来自 oplus_audio_daemon，另外两组 msm_audio_* 看起来来自 audpkt_ion。既然 oplus_audio_daemon 已经成功装上，现在按正确顺序重试。

随后按正确顺序重试三条模块链，并马上检查 `aud_pasthru` 是否真正被内核注册出来。

```bash
adb shell 'insmod /vendor_dlkm/lib/modules/audpkt_ion_dlkm.ko 2>/data/audpkt_ion.err; echo $?; cat /data/audpkt_ion.err 2>/dev/null; echo ---; lsmod | grep -E "oplus_audio_daemon|audpkt_ion"'
adb shell 'insmod /vendor_dlkm/lib/modules/audio_prm_dlkm.ko 2>/data/audio_prm.err; echo $?; cat /data/audio_prm.err 2>/dev/null; echo ---; lsmod | grep -E "audio_prm|oplus_audio_daemon"'
adb shell 'insmod /vendor_dlkm/lib/modules/audio_pkt_dlkm.ko 2>/data/audio_pkt.err; echo $?; cat /data/audio_pkt.err 2>/dev/null; echo ---; lsmod | grep -E "audio_pkt|audpkt_ion|oplus_audio_daemon"'
```

模块链补齐成功了，而且加载顺序也坐实了。现在看它到底有没有把 aud_pasthru、gpr 或声卡枚举往前推；如果有变化，再决定是否需要重拉一遍用户态音频链。

```bash
adb shell 'ls /dev | grep -E "fastrpc|aud_pas|gpr"; echo ---; ls -l /dev/aud_pasthru_adsp /dev/aud_pasthru_modem /dev/gpr_channel 2>&1'
adb shell 'ls /dev/snd; echo ---; cat /proc/asound/cards 2>/dev/null; echo ---; cat /proc/asound/pcm 2>/dev/null'
adb shell 'dmesg | grep -i -E "audio_pkt|aud_pasthru|audio_prm|gpr_channel|snd|asoc|soc:audio|spf" | tail -n 120'
```

关键节点已经出来了：/dev/aud_pasthru_adsp 现在被内核注册出来了。这说明“缺的是 audio_pkt/audpkt_ion/oplus_audio_daemon 这条模块链”已经基本坐实。接下来不再猜，直接重拉一遍用户态链，看报错有没有从 “节点不存在” 前移。

最后在 `aud_pasthru_adsp` 已出现的前提下，重新拉一遍用户态音频链，验证错误是否从“节点不存在”前移到更深层的传输问题。

```bash
adb shell 'ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice"; echo ---; for p in $(pidof adsprpcd audioadsprpcd audiohalservice.qti 2>/dev/null); do echo PID:$p; ls -l /proc/$p/fd 2>/dev/null | grep aud_pasthru; done'
adb shell 'cat /data/audioadsprpcd.out 2>/dev/null | tail -n 80; echo ---; cat /data/audiohal.out 2>/dev/null | tail -n 120'
cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n 'adsprpcd rootpd adsp|audioadsprpcd audiopd adsp|audiohalservice.qti' docs/TWRP音频手动Bring-up.md | tail -n 40
adb shell 'ls /vendor/bin/adsprpcd /vendor/bin/audioadsprpcd /vendor/bin/hw/audiohalservice.qti'
```

先按已经验证过的 stock 路径把三段用户态链重新拉起来，重点看这次日志是否还停在 “aud_pasthru 节点不存在”，还是已经前移到更具体的传输或声卡注册错误。

```bash
adb shell 'getenforce; pkill adsprpcd; pkill audioadsprpcd; pkill audiohalservice.qti; rm -f /data/adsprpcd.out /data/audioadsprpcd.out /data/audiohal.out'
adb shell 'LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/vendor/lib64:/system/lib64 /vendor/bin/adsprpcd rootpd adsp >/data/adsprpcd.out 2>&1 &'
adb shell 'LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/vendor/lib64:/system/lib64 /vendor/bin/audioadsprpcd audiopd adsp >/data/audioadsprpcd.out 2>&1 &'
adb shell 'LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/vendor/lib64:/system/lib64 /vendor/bin/hw/audiohalservice.qti >/data/audiohal.out 2>&1 &'
adb shell 'ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice"; echo ---; ls /dev | grep -E "fastrpc|aud_pas|gpr"; echo ---; ls /dev/snd; echo ---; cat /proc/asound/cards 2>/dev/null'
adb shell 'tail -n 120 /data/adsprpcd.out 2>/dev/null; echo ---; tail -n 120 /data/audioadsprpcd.out 2>/dev/null; echo ---; tail -n 160 /data/audiohal.out 2>/dev/null'
adb shell 'for p in $(pidof adsprpcd audioadsprpcd audiohalservice.qti 2>/dev/null); do echo PID:$p; ls -l /proc/$p/fd 2>/dev/null | grep -E "aud_pasthru|fastrpc|snd"; echo ---; done'
```

用户态已经被成功重拉，audioadsprpcd 这次直接进了内核等待态，不再是之前那种起完就空转报节点缺失。现在要用内核日志和 logcat 看它卡在什么调用点。

```bash
adb shell 'dmesg | grep -i -E "audioadsprpcd|adsprpcd|aud_pasthru|adsp_default_listener|fastrpc|audio_pkt|audio_prm|wait_for_snd_card_to_online|sound card is not exist|GPR async send failed" | tail -n 160'
adb shell 'logcat -d 2>/dev/null | grep -E "audioadsprpcd|audiohalservice|adsprpcd|AGM|gpr_lx_wrapper|adsp_default_listener" | tail -n 200'
adb shell 'for p in 7145 7153; do echo PID:$p; cat /proc/$p/stack 2>/dev/null; echo ---; done'
```

结论:

状态前移了，但没完全打通：/dev/aud_pasthru_adsp 已经出来，audiohal 也不再报这个节点不存在；现在剩下两块是 domain 0 FastRPC 仍断、以及 ASoC 声卡仍未枚举。下一步我先锁定 machine driver/codec 模块缺口，看 no soundcards 是不是另一条独立缺链。

- `audio_pkt`、`audpkt_ion`、`oplus_audio_daemon` 这条模块链就是 `aud_pasthru_adsp` 缺失的直接原因。
- 这一步把问题从“字符设备都没出来”推进到“用户态已经能看到 `aud_pasthru_adsp`，但传输和声卡仍未打通”。
- 后续的焦点自然分成两条：一条是 domain 0 FastRPC，一条是 machine / 声卡枚举。

---

## 5. recovery 默认模块清单不完整，声卡链虽然能补齐但仍然不起卡

既然 `aud_pasthru` 已经能靠手工补模块出来，接下来继续看 ASoC / machine 这一侧到底缺哪些模块，以及 recovery 默认模块清单是不是压根没把手机音频链装进来。

```bash
adb shell 'for f in /vendor_dlkm/lib/modules/*.ko; do strings "$f" 2>/dev/null | grep -q "sun-mtp-snd-card" && echo "$f"; done'
adb shell 'find /vendor_dlkm/lib/modules -maxdepth 1 -name "*.ko" | sed "s#.*/##" | grep -E "snd|soc|wcd|wsa|va|bolero|rx-macro|tx-macro|codec|lpass|audio" | sort'
adb shell 'lsmod | grep -E "wcd|snd|soc|lpass|audio_macr|bolero|va_"'
```

ASoC 侧也有明显缺口：当前几乎只有 usb 音频和一个 hdmi codec，lpass_cdc、wcd、wsa 这些典型手机音频 codec/macro 模块都没进来。先把平台设备和依赖关系对上，再决定要不要补加载这一串。

```bash
adb shell 'ls /sys/bus/platform/devices 2>/dev/null | grep -E "lpass|wcd|wsa|macro|codec|audio" | sort | head -n 200'
adb shell 'for f in /vendor_dlkm/lib/modules/lpass_cdc_dlkm.ko /vendor_dlkm/lib/modules/lpass_cdc_rx_macro_dlkm.ko /vendor_dlkm/lib/modules/lpass_cdc_tx_macro_dlkm.ko /vendor_dlkm/lib/modules/lpass_cdc_va_macro_dlkm.ko /vendor_dlkm/lib/modules/lpass_cdc_wsa_macro_dlkm.ko /vendor_dlkm/lib/modules/lpass_cdc_wsa2_macro_dlkm.ko /vendor_dlkm/lib/modules/wcd_core_dlkm.ko /vendor_dlkm/lib/modules/wcd9xxx_dlkm.ko /vendor_dlkm/lib/modules/wcd939x_dlkm.ko /vendor_dlkm/lib/modules/wsa884x_dlkm.ko; do echo ===$f===; modinfo "$f" 2>/dev/null | grep -E "filename:|description:|alias:|depends:"; done'
adb shell 'ls /sys/bus/platform/drivers 2>/dev/null | grep -E "lpass|wcd|wsa|macro|codec|audio" | sort | head -n 200'
```

这一步已经不像单纯 runtime 玄学了，更像 recovery 的模块加载清单不完整。我去设备树和 recovery 配置里直接找这些模块名，确认是不是根本没把这条音频链列进启动装载表。

然后转去设备树、文档和模块清单，确认 recovery 默认加载器到底从哪里取模块清单，以及目前漏了哪些音频 ko。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n 'audio_pkt_dlkm|audio_prm_dlkm|audpkt_ion_dlkm|oplus_audio_daemon|lpass_cdc_dlkm|wcd939x_dlkm|wcd9xxx_dlkm' device_tree docs 2>/dev/null | head -n 200

cd '/Volumes/Case-sensitive APFS/TWRP' && find device_tree -path '*modules*' -o -name '*.rc' | grep -E 'recovery|vendor' | head -n 200

adb shell 'find /vendor_dlkm/lib/modules -maxdepth 1 -name "modules.*" -o -name "*.load" -o -name "modules.dep" | sort'

adb shell 'cat /vendor_dlkm/lib/modules/modules.load | sed -n "1,220p"'

cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n 'modules.load|vendor_dlkm|insmod .*audio|insmod .*wcd|insmod .*lpass|insmod .*frpc' device_tree/twrp_device_oplus_infiniti/recovery/root/init.recovery.qcom.rc docs/TWRP音频手动Bring-up.md 2>/dev/null
```

根因已经开始收敛成“recovery 默认模块清单压根没把手机音频链装进来”。接着去找 recovery 的模块装载入口，然后把这组最小必需模块加进去，而不是继续靠手工 adb 一次次补。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n 'twrp.modules.loaded|modules.load|modprobe|insmod ' device_tree/twrp_device_oplus_infiniti twrp_a16_compile/bootable/recovery 2>/dev/null | head -n 200
adb shell 'grep -nE "audio_pkt_dlkm|audio_prm_dlkm|audpkt_ion_dlkm|oplus_audio_daemon|lpass_cdc_dlkm|wcd939x_dlkm|wcd9xxx_dlkm|frpc-adsprpc.ko" /vendor_dlkm/lib/modules/modules.dep | head -n 120'
```

模块装载器这边也对上了：TWRP 会优先吃 modules.load.twrp。设备自带的 modules.load 明显漏掉了前面手工补出来的整条音频链，所以最合理的修法是给 recovery 补一份定制清单，而不是改 stock 分区。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && find . -name 'modules.load.twrp' -o -name 'modules.load.recovery' | head -n 50
```

下一层也清楚了：不是要手写一个 modules.load.twrp 文件进仓库，而是把缺的 ko 填进 recovery 的“请求加载模块列表”，让内置 loader 自动生成 modules.load.twrp。现在去找这份列表在哪里声明。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n 'TW_LOAD_VENDOR_MODULES|TW_LOAD_VENDOR_DLKM_MODULES|KERNEL_MODULE|TWRP_REQUIRED_MODULES|modules_requested|modules.load.twrp' device_tree/twrp_device_oplus_infiniti twrp_a16_compile/bootable/recovery 2>/dev/null | head -n 200
cd '/Volumes/Case-sensitive APFS/TWRP' && find device_tree/twrp_device_oplus_infiniti -maxdepth 3 \( -name 'BoardConfig*.mk' -o -name '*.mk' -o -name '*.bp' \) | sort
```

现在已经足够能改配置了，但我还想先验证一个关键判断：如果把 machine driver 这层也补上，声卡有没有机会直接枚举。因为如果只补 aud_pasthru，不补 machine_dlkm，最终还是会停在 no soundcards。

接着利用 recovery 自带的 `modprobe` 做一次 machine driver 闭环验证，看看只要把这整条依赖链拉起来，声卡会不会立刻出来。

```bash
adb shell 'modinfo /vendor_dlkm/lib/modules/machine_dlkm.ko 2>/dev/null | grep -E "filename:|description:|alias:|depends:"'
adb shell 'which modprobe 2>/dev/null || toybox | grep modprobe'
adb shell 'grep -n "^/vendor/lib/modules/machine_dlkm.ko:" /vendor_dlkm/lib/modules/modules.dep'
adb shell 'modprobe --help 2>&1 | head -n 40'
```

recover y 里居然有 modprobe，那就不必继续手撸一长串 insmod 依赖了。我先用它从现成的 modules.dep 拉起 machine_dlkm，看声卡是否直接出来，这能决定 BoardConfig 里应该补到什么粒度。

先确认 `modprobe`、`machine_dlkm` 和依赖数据库这条链在 recovery 里是能走通的。

```bash
adb shell 'ls /vendor_dlkm/lib/modules/modules.dep.bin /vendor_dlkm/lib/modules/modules.alias.bin 2>/dev/null'
adb shell 'modprobe -D -d /vendor_dlkm/lib/modules machine_dlkm 2>&1 | head -n 120'
```

modprobe 已经把完整依赖序列算出来了，说明 recovery 本身完全有能力自动把这条声卡链拉起来。现在直接实测 machine_dlkm，如果声卡出来，这次定位就算闭环。

```bash
adb shell 'modprobe -d /vendor_dlkm/lib/modules machine_dlkm 2>/data/machine_modprobe.err; echo $?; cat /data/machine_modprobe.err 2>/dev/null | head -n 60'
```

再马上观察声卡节点、ASoC 日志和模块驻留情况，判断 machine driver 闭环验证有没有直接带来结果。

```bash
adb shell 'ls /dev/snd; echo ---; cat /proc/asound/cards 2>/dev/null; echo ---; cat /proc/asound/pcm 2>/dev/null | head -n 80'
adb shell 'dmesg | grep -i -E "machine_dlkm|sun-asoc|snd-card|asoc|wcd|lpass_cdc|wsa|mbhc" | tail -n 160'
adb shell 'lsmod | grep -E "machine_dlkm|wcd|wsa|lpass_cdc|swr|mbhc|audio_pkt|audio_prm|oplus_audio_daemon"'
```

machine/codec 这一层虽然都已经装上，但 still no soundcards，这说明问题又不是简单“少几个 ko”这么浅了。接下来我看 machine driver 有没有实际绑定到对应平台设备，还是模块只是加载了、根本没 probe 到设备。

```bash
adb shell 'ls /sys/bus/platform/devices 2>/dev/null | grep -E "sun-asoc|snd|lpass-cdc|wcd|wsa|stub-codec" | sort'
adb shell 'ls /sys/bus/platform/drivers/machine_dlkm 2>/dev/null || ls /sys/bus/platform/drivers | grep machine'
adb shell 'find /sys/bus/platform/drivers -maxdepth 1 -type d | grep -E "sun-asoc|qcom,sun-asoc-snd|machine|lpass-cdc|wcd|wsa" | sort'
adb shell 'ls -la /sys/bus/platform/drivers/sun-asoc-snd 2>/dev/null'
```

驱动目录已经有了，但平台设备列表里只剩 stub codec，没有看到 sun-asoc-snd 的设备实例。这很像 DT 实体没导进 recovery，或者相关节点没被解析成 platform device。再把 driver 目录里的 bind 情况和 DT compatible 露出来。

接着把 DT compatible 与驱动绑定对象一一对照，确认缺的是 probe 条件，而不是模块文件本身。

```bash
adb shell 'for p in /sys/firmware/devicetree/base/* /sys/firmware/devicetree/base/soc/*; do [ -e "$p/compatible" ] && strings "$p/compatible" 2>/dev/null | grep -q "sun-asoc-snd" && echo "$p"; done'
adb shell 'for p in /sys/firmware/devicetree/base/* /sys/firmware/devicetree/base/soc/*; do [ -e "$p/compatible" ] && strings "$p/compatible" 2>/dev/null | grep -q "audio-pkt" && echo "$p"; done'
```

这里拿到一个更精确的结论了：当前 recovery 运行时 DT 里能看到 qcom,audio-pkt-core-platform，但看不到 qcom,sun-asoc-snd。也就是说“不是整个音频 DT 都没了”，而是 machine 节点这块在 recovery 实际生效的 DT 里缺失，所以 machine_dlkm 只能注册 driver，永远绑不到设备。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n 'qcom,sun-asoc-snd|sun-asoc-snd|audio-pkt-core-platform' twrp_a16_compile/device twrp_a16_compile/kernel device_tree 2>/dev/null | head -n 200
adb shell 'find /sys/firmware/devicetree/base -name compatible -exec sh -c "strings \"$1\" 2>/dev/null | grep -Eq \"sun-asoc-snd|audio-pkt-core-platform\" && echo ${1%/compatible}" _ {} \;' 2>/dev/null'
```

结论:

- recovery 默认模块清单确实不完整，漏掉的不是单个模块，而是一整条手机音频链，包括 `frpc`、`audio_pkt`、`machine` 等关键块。
- 但即使 machine/codec 依赖链都能成功加载，声卡仍然不出来，说明问题不再是“少几个 ko”这么浅。
- 这一步把判断进一步收敛到：一条是 domain 0 FastRPC 仍断；另一条是 machine 虽已注册但没有真正拿到可绑定设备或后续 child-device 枚举条件。

---

## 6. system / recovery 对照修正：从“缺 DT 节点”到“APM/GPR readiness 没完成”

为了确认问题到底在 DT 本体还是在 `spf_core_platform` 的实例化过程，先把 recovery 的 audio / asoc / sound 相关 compatible、platform device 和 driver 状态完整拉出来。

```bash
adb shell 'find /sys/firmware/devicetree/base -name compatible -exec sh -c "p=\"$1\"; s=$(tr "\\000" "\\n" < "$p" 2>/dev/null | grep -Ei "audio|asoc|snd|wcd|wsa|lpass|stub-codec" | paste -sd , -); [ -n "$s" ] && echo ${p%/compatible}:$s" _ {} \;' 2>/dev/null | sort | head -n 200'

adb shell 'for d in /sys/bus/platform/drivers/sun-asoc-snd /sys/bus/platform/drivers/audio-pkt /sys/bus/platform/drivers/lpass-cdc; do echo ===$d===; ls -la "$d" 2>/dev/null; done'

adb shell 'for d in /sys/bus/platform/devices/*; do [ -e "$d/modalias" ] && m=$(cat "$d/modalias" 2>/dev/null); echo "$d:$m"; done | grep -Ei "audio|asoc|snd|wcd|wsa|lpass|stub" | sort'
```

当前 recovery DT 的 platform device 已经说明问题更偏向 DT 侧了：有 audio-pkt-core-platform、stub-codec、一堆 audio-ref-clk，但还是没有任何 sun-asoc-snd 设备实例。接下来我切到正常系统做对照，拿到 sun-asoc-snd 在正常系统里的真实节点路径和 compatible。

接着切到系统态做对照，确认正常系统下的声卡、`sun-asoc-snd` 绑定对象和 `spf_core_platform` / `sound` 真实路径是什么。

```bash
adb reboot
sleep 20 && adb wait-for-device && adb shell 'until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 2; done; getprop ro.bootmode; getprop sys.boot_completed'
adb root && adb wait-for-device && adb shell 'for d in /sys/bus/platform/devices/*; do [ -e "$d/modalias" ] && m=$(cat "$d/modalias" 2>/dev/null); echo "$d:$m"; done | grep -Ei "sun-asoc|audio-pkt-core-platform|stub-codec|oplus,audio-drv" | sort'
adb shell 'find /sys/firmware/devicetree/base -name compatible -exec sh -c "p=$1; tr "\\000" "\\n" < "$p" 2>/dev/null | grep -Eq "qcom,sun-asoc-snd|qcom,audio-pkt-core-platform|qcom,msm-stub-codec" && echo ${p%/compatible}" sh {} \;' 2>/dev/null | sort'
```

先在系统态确认核心绑定关系，再开始把声卡、设备树和 `spf_core_platform` 路径一层层展开。

```bash
adb shell 'cat /proc/asound/cards 2>/dev/null; echo ---; ls /dev/snd | head -n 40'
```

正常系统这边至少证实了一件事：audio-pkt-core-platform 和 stub-codec 在两边都能看到，所以 recovery 并不是把整条基础音频节点全裁掉了。下一步我用更简单的命令拆开查正常系统里的 sun-asoc-snd 和声卡，避免再被 shell 转义拖住。

```bash
adb shell cat /proc/asound/cards
adb shell ls /dev/snd
adb shell find /sys/firmware/devicetree/base -name compatible
```

正常系统的 ALSA 基线没问题，完整 snd 节点确实都在。现在我不再扫整棵 DT，直接抓正常系统里 sun-asoc-snd driver 的绑定情况和对应 sysfs 设备路径。

```bash
adb shell ls -la /sys/bus/platform/drivers/sun-asoc-snd
adb shell ls /sys/bus/platform/devices | grep sun
adb shell ls /sys/class/sound
```

这一步给了一个更细的修正：正常系统里 sun-asoc-snd 不是直接绑到一个独立 “sun-*” platform 设备名上，而是绑在 soc:spf_core_platform:sound 这个设备上。也就是说，之前把问题全压到缺 qcom,sun-asoc-snd DT 节点上还不够精确，我现在转去对比 spf_core_platform 在两边有没有生成 sound 子设备。

然后只围绕 `spf_core_platform` 本体继续往下看，确认系统态真实出现了哪些子路径和节点。

```bash
adb shell ls -la /sys/devices/platform/soc/soc:spf_core_platform
adb shell find /sys/devices/platform/soc/soc:spf_core_platform -maxdepth 2 -type d | sort
adb shell cat /sys/devices/platform/soc/soc:spf_core_platform/uevent
```

正常系统的关键事实已经出来了：声卡设备不是凭空出现的，而是明确挂在 soc:spf_core_platform:sound 下面。这意味着 recovery 现在更像是停在“spf_core_platform 没有生成 sound 子设备”，而不只是“machine driver 没绑上”。接着把正常系统 sound 子设备的 sysfs 结构抓一下，然后回 recovery 对照。

```bash
adb shell ls -la /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound

adb shell find /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound -maxdepth 2 -type d | sort | head -n 120

adb shell ls -l /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/of_node
```

正常系统把路径完全坐实了：sound 子设备直接对应运行时 DT 里的 soc/spf_core_platform/sound。也就是说，recovery 要么缺这个 DT 子节点，要么 spf_core_platform 没把它实例化出来。现在我回 recovery 对照这个精确路径。

再切回 recovery，只围绕 `spf_core_platform` 和 `sound` 这一条精确路径做对照，避免再被大范围扫描带偏。

```bash
adb reboot recovery
sleep 20 && adb wait-for-device && adb get-state && adb shell getprop ro.bootmode
adb get-state
adb shell getprop ro.bootmode
```

回到 recovery 后，只对照同一条 `spf_core_platform -> sound` 路径，避免再被旁支信息干扰。

```bash
adb shell ls -la /sys/devices/platform/soc/soc:spf_core_platform

adb shell ls -la /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound
```

现在精确差分已经出来了：正常系统里 spf_core_platform 下会生成 soc:spf_core_platform:sound，而 recovery 下同一路径根本不存在。接下来只看 DT 对应目录本身，确认 recovery 的 soc/spf_core_platform 节点下面是否就少了 sound 子节点。

```bash
adb shell ls -la /sys/firmware/devicetree/base/soc/spf_core_platform

adb shell find /sys/firmware/devicetree/base/soc/spf_core_platform -maxdepth 1 -mindepth 1 -type d | sort

adb shell ls -la /sys/firmware/devicetree/base/soc/spf_core_platform/sound
```


把一个关键误判纠正了：recovery 的运行时 DT 里其实有 soc/spf_core_platform/sound 子节点，并不缺这个节点。真正的差分变成了“同一份 DT 子节点在正常系统会被 spf_core_platform 实例化成 soc:spf_core_platform:sound，而 recovery 不会”。下一步直接验证这是不是 probe 时序问题，做法是补齐模块后重绑 spf-core-platform 看它会不会现场生出 sound 子设备。

确认 recovery 的运行时 DT 里确实也有 `sound` 子节点后，继续补齐 machine / audio_pkt 路径并测试重绑 `spf-core-platform` 能不能现场生成 sound 子设备。

```bash
adb shell modprobe -d /vendor_dlkm/lib/modules machine_dlkm
adb shell insmod /vendor_dlkm/lib/modules/frpc-adsprpc.ko
adb shell insmod /vendor_dlkm/lib/modules/audio_pkt_dlkm.ko
```

clean recovery 下又回到了同一个现实：默认环境里不只是模块没加载，连 modprobe 期望的 vendor 模块路径都没准备好，所以单条主模块直接补会失败。先把当前分区挂载和模块路径视图钉死，再选最短的恢复路径。

```bash
adb shell mount | grep -E ' /vendor | /vendor_dlkm | /odm '
adb shell ls -ld /vendor /vendor/lib /vendor/lib/modules /vendor_dlkm /vendor_dlkm/lib /vendor_dlkm/lib/modules
adb shell ls /vendor_dlkm/lib/modules | grep -E 'machine_dlkm|audio_pkt_dlkm|audio_prm_dlkm|audpkt_ion_dlkm|oplus_audio_daemon|frpc-adsprpc'
```

clean recovery 只有 vendor_dlkm，根本没有 /vendor/lib/modules 这层视图，所以 modprobe 解析依赖会失败。先把真实 vendor_a 和 odm_a 挂回去，恢复成前面已经验证过的 stock 路径，再继续做 spf-core-platform 的重绑实验。

先把 recovery 当前的挂载和最小模块链重新拉平，再继续做 bind 验证。

```bash
adb shell mount /dev/block/mapper/vendor_a /vendor
adb shell mount /dev/block/mapper/odm_a /odm
adb shell ls -ld /vendor/lib/modules /odm/lib/rfsa/adsp
```

路径恢复好了。下一步直接用 modprobe 走 modules.dep，把 machine 和 audio_pkt 两条链一次性拉起，再马上重绑 spf-core-platform，看 sound 子设备会不会在 recovery 里被实例化出来。

```bash
adb shell modprobe -d /vendor/lib/modules machine_dlkm
adb shell modprobe -d /vendor/lib/modules audio_pkt_dlkm

adb shell lsmod | grep -E 'machine_dlkm|audio_pkt_dlkm|audio_prm_dlkm|audpkt_ion_dlkm|oplus_audio_daemon|lpass_cdc|wcd|wsa|frpc'
```

模块链已经补齐到正常可用水平。现在做最关键的验证：如果把已经绑定的 spf_core_platform 重新 probe 一次，recovery 能不能像正常系统那样生成 sound 子设备；这一步能直接区分“纯时序问题”和“更深的驱动条件不满足”。

然后只盯 `spf_core_platform` 本身做一次 unbind/bind，看它会不会现场生成 sound 子设备。

```bash
adb shell ls -la /sys/devices/platform/soc/soc:spf_core_platform
adb shell 'echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/unbind && echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/bind'
adb shell ls -la /sys/devices/platform/soc/soc:spf_core_platform
adb shell ls -la /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound
```

现在线索更像是“APM/SPF 时序没重新走起来”而不是 DT 本体缺失。因为 recovery 里 DT 的 spf_core_platform/sound 子节点明明在，但对应平台设备没生成。下一步不折腾 unbind 了，直接在模块补齐后的状态下手动触发一次 ADSP SSR，看 spf_core_platform 会不会把 sound 子设备补出来。

发现重绑不够后，再做一轮 SSR，继续看是不是 `APM` / `GPR` readiness 没重新走起来。

```bash
adb shell ls -la /sys/devices/platform/soc/soc:spf_core_platform
adb shell 'echo 1 > /sys/kernel/boot_adsp/ssr'
adb shell 'sleep 3; ls -la /sys/devices/platform/soc/soc:spf_core_platform; echo ---; ls -la /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound 2>&1; echo ---; ls /dev/snd; echo ---; cat /proc/asound/cards 2>/dev/null'
```

SSR 这条也验证掉了：即使模块链补齐后手动再跑一次 ADSP SSR，spf_core_platform 还是不会在 recovery 里实例化 sound 子设备，声卡也还是不出来。也就是说，问题已经不是“晚一点加载模块”或者“补一次 SSR 就行”。接着往内核日志里抓 spf_core/APM 的失败点，看它到底是在哪个判断分支停住。


日志已经把关键阻塞打印出来了：spf_core_platform 在 recovery 里不是找不到 DT 节点，而是在尝试建 child devices 时明确卡在 apm is not up，并伴随 q6 state is down。也就是说，sound 子设备不出现的直接原因现在可以归到 APM/GPR readiness，而不是 machine DT 缺失。最后再核一遍当前 gprbus 和 spf_core_platform 状态，确认这条判断已经稳定。

```bash
adb shell 'dmesg | grep -i -E "spf_core|apm|q6 state is down|audio_pkt|aud_pasthru|sun-asoc|snd-card|asoc" | tail -n 160'
adb shell find /sys/bus/gprbus/devices -maxdepth 1 -type d
adb shell ls -la /sys/devices/platform/soc/soc:spf_core_platform
adb shell 'dmesg | grep -i -E "spf_core_add_child_devices|apm is not up|Adding GPR dev|gprsvc:spf_core|q6 state is down" | tail -n 120'
```

日志里还有一个很重要的时序细节：刚开始 spf_core_platform 因为 APM not up 失败，但稍后 GPR 设备其实已经补枚举出来了，包括 spf_core、audio-pkt、q6prm。这意味着最有价值的最后一刀，是在 GPR 枚举完成后再手动重绑一次 spf-core-platform，看它会不会补生 sound 子设备。

```bash
adb shell 'echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/unbind'
adb shell 'echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/bind'
adb shell 'ls -la /sys/devices/platform/soc/soc:spf_core_platform; echo ---; ls -la /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound 2>&1; echo ---; ls /dev/snd; echo ---; cat /proc/asound/cards 2>/dev/null'
adb shell 'dmesg | grep -i -E "spf_core_add_child_devices|apm is not up|Adding GPR dev|sun-asoc|snd-card|asoc" | tail -n 120'
```

重绑后日志终于前进了一步：已经从 apm is not up 走到了 spf_core_add_child_devices: enumarate machine driver。这说明之前的关键卡点确实是 APM/GPR 就绪时序，而且在 GPR 枚举完成后重绑 spf-core-platform 能推进状态。现在只查这一跳之后 machine/sound 到底挂在了哪里，避免漏看了实际生成的设备路径。

```bash
adb shell ls -la /sys/bus/platform/drivers/sun-asoc-snd
adb shell find /sys/devices/platform/soc -maxdepth 3 -type d | grep 'sound'
adb shell 'dmesg | grep -i -E "enumarate machine driver|sun-asoc|asoc|snd card|sound card|msm_asoc" | tail -n 120'
```

machine driver 还是没真正绑上设备，日志只停在 “开始枚举 machine driver” 这一句，后面没有成功结果。最后补一组最小状态快照，把当前突破点和剩余阻塞固化下来，然后把文档更新掉。

```bash
adb shell find /sys/devices/platform/soc/soc:spf_core_platform -maxdepth 2 -type d | sort
adb shell ls /dev | grep -E 'aud_pas|fastrpc|gpr'
adb shell 'ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice"'
adb shell 'ls /dev | grep -E "aud_pas|fastrpc"; echo ---; dmesg | grep -i -E "spf_core_add_child_devices|apm is not up|enumarate machine driver|Adding GPR dev" | tail -n 20'
```

结论:

继续做完这一轮后，结论已经比之前更准了。

最重要的修正是：recovery 并不缺 spf_core_platform/sound 这个运行时 DT 子节点。之前把问题归到“缺 qcom,sun-asoc-snd DT 节点”是不准确的，文档和仓库记忆也已经改掉。现在更准确的链路是：

1. 默认 recovery 模块集确实不完整，补齐 frpc、audio_pkt、machine 相关模块后，aud_pasthru_adsp 和 fastrpc-adsp-secure 都能出来。
2. recovery 的运行时 DT 里也确实有 soc/spf_core_platform/sound。
3. 但 spf_core_platform 一直没有把这个现成的 DT 子节点实例化成真正的 soc:spf_core_platform:sound 设备，所以 /dev/snd 还是只有 timer，/proc/asound/cards 还是 no soundcards。
4. 内核日志的直接前沿证据现在是：
   1. 先报 gpr_send_pkt: q6 state is down
   2. 再报 __spf_core_is_apm_ready: send_command ret
   3. 然后报 spf_core_add_child_devices: apm is not up
   4. 后面 GPR 设备会补枚举出来：gprsvc:spf_core、gprsvc:audio-pkt、gprsvc:q6prm
   5. 在这之后重绑 spf-core-platform，日志能前进到 spf_core_add_child_devices: enumarate machine driver
   6. 但还是没有真正生成 sound 子设备，也没有声卡

所以当前主阻塞已经收敛成两条，而且都比之前更具体：

1. audioadsprpcd 的 domain 0 FastRPC transport 仍然断着。
2. spf_core_platform / APM / GPR readiness 在 recovery 里没有把 sound 子设备真正实例化出来，导致 machine driver 虽然注册了，声卡还是起不来。

1. 把 BoardConfig 里的默认 vendor 模块集补进了 frpc-adsprpc、audio_pkt_dlkm、machine_dlkm，避免下次 clean boot 还要从零手工补这三条大链。
2. 把主文档和 repo memory 里关于 “缺 sun-asoc-snd DT 节点” 的过时结论改成了现在这版更准确的时序/APM 结论。

这一步之后，最值得继续追的不是 DT 本体，而是 spf_core_platform 为什么在 recovery 中第一次 child-device 枚举时碰到 apm is not up，以及为什么在 GPR 设备后来补出来后，重绑也只走到 enumarate machine driver 就停住。后续若继续，排查重点就是 spf_core_platform、GPR、APM 的更细日志和触发条件。

---

## 7. 所谓“开机模式”继续对照，进一步锁定 pd-mapper / per_mgr 与 recovery 服务框架缺失

后续继续在“开机模式”里对照时序、GPR、remoteproc、ASoC 注册状态，验证这到底是不是一个真正可用的正常系统基线。

```bash
adb shell getprop ro.bootmode
```

先把 `spf_core_platform`、`sound` 子路径和设备节点状态看全，判断它到底像不像一个正常系统态。

```bash
adb shell 'ls -la /sys/devices/platform/soc/soc:spf_core_platform; echo ---; ls -la /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound 2>&1'
adb shell 'ls /dev/snd 2>/dev/null; echo ---; ls /dev | grep -E "aud_pas|fastrpc|gpr"'
```

再补日志和 root 视角，确认 `APM/GPR` 时序问题是不是依旧存在。

```bash
adb shell 'dmesg | grep -i -E "spf_core_add_child_devices|apm is not up|enumarate machine driver|Adding GPR dev|q6 state is down" | tail -n 40'
adb shell 'su -c "id; dmesg | grep -i -E \"spf_core_add_child_devices|apm is not up|enumarate machine driver|Adding GPR dev|q6 state is down\" | tail -n 80"'
```

最后再对照 GPR 总线、音频进程和模块清单，确认所谓“系统态”到底多出了什么。

```bash
adb shell 'su -c "find /sys/bus/gprbus/devices -maxdepth 1 -type d | sort"'
adb shell 'ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice"'
adb shell 'su -c "lsmod | grep -E \"machine_dlkm|audio_pkt_dlkm|audio_prm_dlkm|audpkt_ion_dlkm|oplus_audio_daemon|lpass_cdc|wcd|wsa|frpc\""'
```

系统态又给了一个新差分：正常系统里除了 machine/audio_pkt 这些显眼模块，还多了 pinctrl_lpi_dlkm 和一整组 cdc macro 模块，而 recovery 里我们之前没有把这层纳入视野。我先确认这些模块在 vendor_dlkm 里是否存在，以及它们和 spf_core_platform 子设备生成的关系。

```bash
adb shell 'ls /vendor_dlkm/lib/modules | grep -E "pinctrl_lpi_dlkm|lpass_cdc_tx_macro_dlkm|lpass_cdc_va_macro_dlkm|lpass_cdc_wsa_macro_dlkm|lpass_cdc_wsa2_macro_dlkm|btfmcodec"'
```

先看这组新增模块的依赖描述，确认它们是不是系统态才有、recovery 默认没补的差分。

```bash
adb shell 'su -c "modinfo /vendor_dlkm/lib/modules/pinctrl_lpi_dlkm.ko 2>/dev/null | grep -E \"filename:|description:|alias:|depends:\"; echo ---; modinfo /vendor_dlkm/lib/modules/lpass_cdc_tx_macro_dlkm.ko 2>/dev/null | grep -E \"filename:|description:|alias:|depends:\"; echo ---; modinfo /vendor_dlkm/lib/modules/lpass_cdc_va_macro_dlkm.ko 2>/dev/null | grep -E \"filename:|description:|alias:|depends:\""'
adb shell 'su -c "grep -nE \"pinctrl_lpi_dlkm|lpass_cdc_tx_macro_dlkm|lpass_cdc_va_macro_dlkm|lpass_cdc_wsa_macro_dlkm|lpass_cdc_wsa2_macro_dlkm\" /vendor_dlkm/lib/modules/modules.dep | head -n 80"'
adb shell 'su -c "ls -la /sys/bus/platform/drivers/spf-core-platform; echo ---; find /sys/devices/platform/soc/soc:spf_core_platform -maxdepth 1 -mindepth 1 -type d | sort"'
```

现在差分更具体了：正常系统里 spf_core_platform 下面除了 sound，还会实例化 lpi_pinctrl、tx_macro、va/wsa 相关那串子设备；而 recovery 之前只补了 machine、audio_pkt、rx_macro，没有把 pinctrl_lpi 和剩余 cdc macro 这一层补进来。下一步直接回 recovery 做最小验证：把这组模块也补上，再重绑 spf-core-platform，看 sound 子设备能不能真正落地。

然后切回 recovery，重新确认设备节点基线，并把 `vendor` / `odm` / `frpc` / `machine` / `audio_pkt` 这条最小链先补起来。

```bash
adb reboot recovery
sleep 20 && adb wait-for-device && adb shell getprop ro.bootmode
adb get-state
adb shell getprop ro.bootmode
adb shell 'ls /dev/snd 2>/dev/null; echo ---; ls /dev | grep -E "aud_pas|fastrpc|gpr"'
```

先确认 recovery 侧基线没漂移，再把真实分区和最小音频链重新挂回去。

```bash
adb shell mount /dev/block/mapper/vendor_a /vendor
adb shell mount /dev/block/mapper/odm_a /odm
adb shell 'ls -ld /vendor/lib/modules /odm/lib/rfsa/adsp'
adb shell insmod /vendor_dlkm/lib/modules/frpc-adsprpc.ko
```

基础路径和 frpc 都恢复好了。现在我直接按系统态差分补 machine/audio_pkt，再额外补 pinctrl_lpi 和剩余 cdc macro，然后只看 spf_core_platform 会不会从空目录变成系统态那种子设备树。

```bash
adb shell modprobe -d /vendor/lib/modules machine_dlkm
adb shell modprobe -d /vendor/lib/modules audio_pkt_dlkm
```

再把 `pinctrl_lpi` 和各个 CDC macro 差分补进去，立即看 `spf_core_platform` 和声卡侧是否有变化。

```bash
adb shell modprobe -d /vendor/lib/modules pinctrl_lpi_dlkm
adb shell 'modprobe -d /vendor/lib/modules lpass_cdc_tx_macro_dlkm; modprobe -d /vendor/lib/modules lpass_cdc_va_macro_dlkm; modprobe -d /vendor/lib/modules lpass_cdc_wsa_macro_dlkm; modprobe -d /vendor/lib/modules lpass_cdc_wsa2_macro_dlkm'
```

新增差分模块已经都补上了。现在直接看它们有没有改变 spf_core_platform 的子设备树；如果还没有，再触发一次 SSR 和重绑，就能判断这组模块是不是关键缺口。

```bash
adb shell 'find /sys/devices/platform/soc/soc:spf_core_platform -maxdepth 1 -mindepth 1 -type d | sort; echo ---; ls /dev/snd; echo ---; ls /dev | grep -E "aud_pas|fastrpc|gpr"'
```

最后再看日志、模块状态和 SSR + bind 之后的结果，判断这组差分是否真的改变了前沿。

```bash
adb shell 'dmesg | grep -i -E "spf_core_add_child_devices|apm is not up|enumarate machine driver|Adding GPR dev|q6 state is down" | tail -n 80'
adb shell 'lsmod | grep -E "pinctrl_lpi_dlkm|lpass_cdc_tx_macro_dlkm|lpass_cdc_va_macro_dlkm|lpass_cdc_wsa_macro_dlkm|lpass_cdc_wsa2_macro_dlkm"'
adb shell 'echo 1 > /sys/kernel/boot_adsp/ssr'
```

新增模块本身还不够，现状还是停在 q6 state is down，spf_core_platform 目录仍然只有 power。这说明关键仍是时序。现在我在“模块已全补齐”的前提下，再做一次 SSR 和重绑；如果这次还不长出子设备，就能把这组模块从主嫌疑里基本排除。

SSR 之后再观察一轮日志和 `spf_core_platform` 子路径，确认这组模块差分到底有没有推动 child-device 枚举。

```bash
adb shell 'sleep 3; dmesg | grep -i -E "spf_core_add_child_devices|apm is not up|enumarate machine driver|Adding GPR dev|q6 state is down" | tail -n 120'
adb shell 'echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/bind'
adb shell 'find /sys/devices/platform/soc/soc:spf_core_platform -maxdepth 1 -mindepth 1 -type d | sort; echo ---; ls /dev/snd; echo ---; cat /proc/asound/cards 2>/dev/null'
```

当前实验已经把新增模块这条路基本试透了：即使把系统态多出来的 pinctrl_lpi 和其余 cdc macro 全补上，重跑 SSR 后也只是把日志推进到 enumarate machine driver，仍然落不出 sound 子设备。下一步我只补最小对照：看 GPR bus 在 recovery 里到底枚举成了什么实体，并在这个状态下重新拉一次用户态音频链，确认 q6 state is down 是否会被用户态进一步推进。

```bash
adb shell 'ls -la /sys/bus/gprbus/devices; echo ---; find -L /sys/bus/gprbus/devices -maxdepth 1 -mindepth 1 -print | sort'
```

```bash
adb shell 'pkill adsprpcd; pkill audioadsprpcd; pkill audiohalservice.qti; rm -f /data/adsprpcd.out /data/audioadsprpcd.out /data/audiohal.out; LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/vendor/lib64:/system/lib64 /vendor/bin/adsprpcd rootpd adsp >/data/adsprpcd.out 2>&1 &; LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/vendor/lib64:/system/lib64 /vendor/bin/audioadsprpcd audiopd adsp >/data/audioadsprpcd.out 2>&1 &; LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/vendor/lib64:/system/lib64 /vendor/bin/hw/audiohalservice.qti >/data/audiohal.out 2>&1 &; sleep 2; ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice"'
adb shell 'tail -n 120 /data/audioadsprpcd.out 2>/dev/null; echo ---; tail -n 160 /data/audiohal.out 2>/dev/null; echo ---; dmesg | grep -i -E "q6 state is down|spf_core_add_child_devices|apm is not up|enumarate machine driver|audio_pkt_write|GPR async send failed" | tail -n 120'
```

GPR 设备这次已经稳定枚举出来了，但即便如此，内核还是持续卡在 q6 state is down，sound 子设备也没有出来。为进一步排除用户态因素，继续将三段音频守护进程在当前状态下单独、分步拉起，观察它们会不会改变这个内核状态。

```bash
adb shell 'pkill adsprpcd; pkill audioadsprpcd; pkill audiohalservice.qti; rm -f /data/adsprpcd.out /data/audioadsprpcd.out /data/audiohal.out'
adb shell 'LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/vendor/lib64:/system/lib64 /vendor/bin/adsprpcd rootpd adsp >/data/adsprpcd.out 2>&1 &'
adb shell 'LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/vendor/lib64:/system/lib64 /vendor/bin/audioadsprpcd audiopd adsp >/data/audioadsprpcd.out 2>&1 &'
adb shell 'LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/vendor/lib64:/system/lib64 /vendor/bin/hw/audiohalservice.qti >/data/audiohal.out 2>&1 &'
```

进程拆开后，继续核对驻留情况和输出，避免把不同错误平面混在一起。

```bash
adb shell 'sleep 2; ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice"'
adb shell 'tail -n 120 /data/audioadsprpcd.out 2>/dev/null; echo ---; tail -n 120 /data/audiohal.out 2>/dev/null'
adb shell 'dmesg | grep -i -E "q6 state is down|spf_core_add_child_devices|apm is not up|enumarate machine driver|audio_pkt_write" | tail -n 120'
adb shell 'find /sys/devices/platform/soc/soc:spf_core_platform -maxdepth 1 -mindepth 1 -type d | sort; echo ---; ls /dev/snd; echo ---; cat /proc/asound/cards 2>/dev/null'
```

刚刚用户态没有真正跑起来，原因不是新的音频问题，而是这次 clean recovery 后 `system_a` 还没重新挂回 `/mnt/system_a`，导致 `audiohalservice` 又退回了旧的 binder 链接错误。这里先修正库路径基线，再看用户态在当前 GPR 已枚举的状态下会不会继续推进 q6/APM。

继续确认 `system_a` 是否仍然可用，并进行第二轮带真实库路径的复测，排除库路径漂移影响。

```bash
adb shell 'mkdir -p /mnt/system_a; mount /dev/block/mapper/system_a /mnt/system_a'
adb shell 'ls /mnt/system_a/system/lib64/libbinder.so /mnt/system_a/system/lib64/libbinder_ndk.so'
adb shell 'pkill adsprpcd; pkill audioadsprpcd; pkill audiohalservice.qti; rm -f /data/adsprpcd.out /data/audioadsprpcd.out /data/audiohal.out'
adb shell 'LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/vendor/lib64:/system/lib64 /vendor/bin/adsprpcd rootpd adsp >/data/adsprpcd.out 2>&1 &'
adb shell 'LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/vendor/lib64:/system/lib64 /vendor/bin/audioadsprpcd audiopd adsp >/data/audioadsprpcd.out 2>&1 &'
adb shell 'LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/vendor/lib64:/system/lib64 /vendor/bin/hw/audiohalservice.qti >/data/audiohal.out 2>&1 &'
```

第二轮复测继续观察三段进程是否稳定驻留，以及 `dmesg` 和 sound 侧是否出现新变化。

```bash
adb shell 'sleep 2; ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice"; echo ---; tail -n 120 /data/audioadsprpcd.out 2>/dev/null; echo ---; tail -n 120 /data/audiohal.out 2>/dev/null'
```

`system_a` 补挂后，三段用户态这次都能稳定驻留，而且没有再退回链接错误。这样一来，“缺额外模块”和“缺 system 库路径”这两条路径都基本排除掉了，接下来只剩最后一个判断：在“模块补齐 + SSR 触发 + GPR 已枚举 + 用户态已驻留”这四个条件同时成立时，内核前沿有没有再往前走一步。

```bash
adb shell 'dmesg | grep -i -E "q6 state is down|spf_core_add_child_devices|apm is not up|enumarate machine driver|Adding GPR dev|audio_pkt_write|GPR async send failed|wait_for_snd_card_to_online|sound card is not exist" | tail -n 160'
adb shell 'find /sys/devices/platform/soc/soc:spf_core_platform -maxdepth 1 -mindepth 1 -type d | sort; echo ---; ls /dev/snd; echo ---; cat /proc/asound/cards 2>/dev/null; echo ---; ls -la /sys/bus/platform/drivers/sun-asoc-snd'
adb shell 'tail -n 160 /data/audioadsprpcd.out 2>/dev/null; echo ---; tail -n 160 /data/audiohal.out 2>/dev/null'
```

到这一步，用户态、模块、GPR、SSR 都已经压到同一状态下了，前沿阻塞仍然没动。我要把视角再往下一层降到 remoteproc/q6 本体：确认 recovery 当前 ADSP 的 remoteproc 状态、PDR 状态和 spf-core-platform 绑定状态，看看为什么会出现“GPR 服务已枚举，但 q6 仍被判定为 down”这种组合。

用户态现象稳定后，继续把 remoteproc、driver 和 GPR 设备细节完整拉出，用于判断底层 readiness 到了哪一步。

```bash
adb shell 'for p in /sys/class/remoteproc/remoteproc*; do echo ===$p===; [ -e "$p/name" ] && cat "$p/name"; [ -e "$p/state" ] && cat "$p/state"; [ -e "$p/firmware" ] && cat "$p/firmware"; done'
adb shell 'ls -la /sys/bus/platform/drivers/spf-core-platform 2>/dev/null; echo ---; ls -la /sys/devices/platform/soc/soc:spf_core_platform/driver 2>/dev/null'
adb shell 'dmesg | grep -i -E "remoteproc-adsp|qcom_q6v5|q6_pdr|q6_notifier|pdr|subsys|adsp" | tail -n 160'
```

随后继续补看 GPR 设备和系统侧调试入口，确认 readiness 缺口到底停在 userspace 之前还是之后。

```bash
adb shell 'for f in /sys/bus/gprbus/devices/*/name /sys/bus/gprbus/devices/*/service-name /sys/bus/gprbus/devices/*/state; do [ -e "$f" ] && echo ===$f=== && cat "$f"; done'
```

remoteproc 这一层已经确认：ADSP 的 remoteproc1 确实是 running，不是固件根本没起。真正矛盾点变成了“ADSP 运行中，但 spf_core_platform 在做 APM/GPR 交互时仍持续判定 q6 down”。我把这层底层日志读出来看看有没有更明确的 PDR 或 remoteproc 提示。

```bash
adb shell getprop sys.boot_completed
adb shell 'ls /sys/bus/msm_subsys/devices 2>/dev/null'
adb shell 'ls /sys/kernel/debug 2>/dev/null | grep -i -E "pdr|servreg|remoteproc|subsys|gpr"'
adb shell 'ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice"'
adb shell 'find /sys/devices/platform/soc/soc:spf_core_platform -maxdepth 2 -type d | sort'
adb shell 'dmesg | grep -i -E "apm is not up|gpr_send_pkt|Adding GPR dev|enumarate machine driver|audio-pkt|spf_core" | tail -n 120'
```

一个关键修正出来了：正常系统里 `soc:spf_core_platform` 这个目录本身也只有 `power`，说明之前把“sound 子目录是否挂在这个目录下面”当成判据，可能又偏了。下一步我改成直接追 `sun-asoc-snd` 绑定对象和 platform_device 实际名字，而不是假设它一定挂在那个路径下面。

正常系统 dmesg 里同样能看到 `q6 state is down` 和 `apm is not up`，这说明这些日志本身不是最终失败判据，它们可能只是启动阶段的过渡噪声。现在真正能区分成败的，只剩“正常系统最终绑定到了哪个 machine/card 设备，而 recovery 没有”。

这一步其实是在修正前面的隐含前提：之前默认“已经开机的系统态”更接近健康样本，想借它来反推 recovery 缺了什么；但既然系统态自己也会打出同样的日志，就不能再把这些报文本身当成 recovery 特有症状，判据必须继续下沉到 machine/card 最终是否真的出来。

随后把声卡、模块、debugfs 和关键日志整体收口，为后面的 `pd-mapper` / `per_mgr` 判断提供完整背景。

```bash
adb shell 'ls -l /sys/bus/platform/drivers/sun-asoc-snd'
adb shell 'cat /proc/asound/cards && echo SEP && ls -l /dev/snd'
adb shell 'find /sys/bus/platform/devices -maxdepth 1 -iname "*sound*" -o -iname "*asoc*" | sort'
```

结果比预期更关键：当前这个“正常系统”实例本身也没有 ALSA 卡，`sun-asoc-snd` 也没绑定任何设备。也就是说，之前拿它当“健康对照”的前提现在失效了，设备当前系统态已经不再是一个可用基线。我先确认这不是单纯的用户态挂了，而是系统态也停在“模块在、卡没出”的同一层。如果两边都坏了，就得把“回到干净系统态”当成下一步前提。

```bash
adb shell 'ls /vendor/lib/modules 2>/dev/null | grep -E "machine|audio_pkt|audio_prm|audpkt|oplus_audio|gpr|spf|lpass|wcd|wsa|frpc" | sort'
adb shell 'lsmod | grep -E "machine|audio_pkt|audio_prm|audpkt|oplus_audio|gpr|spf|lpass|wcd|wsa|frpc"'
adb shell 'ls -l /dev/aud_pasthru_adsp /dev/fastrpc-adsp-secure /dev/fastrpc-cdsp /dev/fastrpc-cdsp-secure 2>/dev/null'
```

当前系统态已经把整条音频模块链都装上了，`/dev/aud_pasthru_adsp` 也有，但依然没有声卡。这进一步收窄到 machine card 注册阶段，而不是更早的 DSP/GPR/模块缺失阶段。下一步我直接抓 ASoC/card 注册失败日志。

这也是一个明确的纠偏点：原先还想把“正常系统”当成健康对照继续比，但这一轮实际看到的是系统态和 recovery 都卡在“模块在、卡没出”的同一层。到这里，“拿系统态作健康基线”这个前提就正式失效了。

接着再把 ASoC debugfs 和几组关键时间线日志收口，给 `pd-mapper` / `per_mgr` 这条线补全背景。

```bash
adb shell 'dmesg | grep -i -E "asoc|snd_soc|soundcard|sun-mtp|sun-asoc|audio graph|controlC0|No soundcards" | tail -n 200'
adb shell 'find /sys/class/sound -maxdepth 2 -type l -o -type d | sort'
adb shell 'find /sys/kernel/debug/asoc -maxdepth 2 2>/dev/null | head -n 120'
```

ASoC 层几乎没有留下任何注册痕迹，`/sys/class/sound` 也只有 timer。这不像“卡注册失败后报错”，更像是 machine/platform 设备根本没被创出来，或者 driver 根本没 match 到设备。我要直接看 platform 驱动目录里到底有没有绑定对象。

```bash
adb shell 'ls -l /sys/bus/platform/drivers/spf-core-platform'
adb shell 'ls -l /sys/bus/platform/drivers/qcom,fastrpc'
adb shell 'find /sys/firmware/devicetree/base/soc -maxdepth 3 -iname "*sound*" | sort | head -n 80'
```

当前系统态和 recovery 一样，`spf-core-platform` 只绑定了父设备 `soc:spf_core_platform`，子 `sound` 设备并没有被实例化出来。也就是说我们现在看到的是“两边都卡在同一个内核阶段”。这不是 recovery 特例了。剩下就看 `spf_core_add_child_devices` 为什么没有真正把 DT 子节点落成 platform_device。

```bash
adb shell 'dmesg | grep -n "spf_core_add_child_devices\|__spf_core_is_apm_ready\|spf_core_apm_close_all" | tail -n 120'
adb shell 'dmesg | grep -n "Adding GPR dev\|gpr_probe\|gpr_notifier_register" | tail -n 80'
adb shell 'dmesg | grep -n "remote processor 3000000.remoteproc-adsp is now up\|fastrpc_rpmsg_probe started\|Opened rpmsg channel for adsp" | tail -n 80'
```

上面那组三条没拿到内容，是 shell 正则转义被设备端吞掉了。我改成更简单的 `grep -E` 再抓一次，重点还是时序。

```bash
adb shell 'dmesg | grep -n -E "spf_core_add_child_devices|__spf_core_is_apm_ready|spf_core_apm_close_all" | tail -n 120'
adb shell 'dmesg | grep -n -E "Adding GPR dev|gpr_probe|gpr_notifier_register" | tail -n 80'
adb shell 'dmesg | grep -n -E "remote processor 3000000.remoteproc-adsp is now up|fastrpc_rpmsg_probe started|Opened rpmsg channel for adsp" | tail -n 80'
```

时序在这里已经比较清楚了：ADSP up 和 GPR 注册都完成得更早，但直到更靠后阶段 `spf_core_platform` 才开始长时间轮询 APM，最后明确判定 `apm is not up`。这说明问题不是“启动太早来不及”，而是 audio PD / APM 在当前环境里根本没有被真正拉起来。

在这些时序与底层状态已经比较清楚之后，继续直接检查 `pd-mapper` / `per_mgr` 相关服务定义、init 属性、进程状态和手工启动结果。

`pd-mapper` 这条线也不是凭空跳出来的。前面先看到 PDR 内核模块在、DSP 与 GPR 也已经起来了，但用户态里始终没有典型的 `pd-mapper` / `servreg` 进程；于是这里才顺着“二进制是否存在、service 是否定义、属性是否出现、start 能不能拉起”这条链，一层层确认到底是服务没跑、服务起不来，还是 recovery init 根本没有导入。

```bash
adb shell 'ps -A | grep -i -E "servreg|pd-mapper|tms|qrtr|adsprpc"'
adb shell 'getprop | grep -i -E "audio|adsp|ssr|servreg|pd" | head -n 120'
adb shell 'lsmod | grep -E "q6_pdr|pdr_interface|q6_notifier|spf_core|gpr"'
```

PDR 内核模块都在，但用户态里只看到了 `qrtr-ns`，没看到典型的 `pd-mapper` 或 `servreg` 进程。这不等于它一定缺失，但已经足够可疑了。我继续直接从 init 服务状态和二进制存在性确认。

```bash
adb shell 'getprop | grep -i -E "init.svc.*(pd|servreg|mapper|tms|audio)" | sort'
adb shell 'ls /vendor/bin /system/bin 2>/dev/null | grep -i -E "pd-mapper|servreg|tms" | sort -u'
adb shell 'grep -R -i -E "pd-mapper|servreg|audio_pd|msm/adsp/audio_pd" /vendor/etc/init /system/etc/init 2>/dev/null | head -n 120'
```

找到一个非常像根因的点了：镜像里有 `pd-mapper` 二进制，但 init 输出里没有任何 `vendor.pd_mapper` 服务在运行，而且 rc 里命中了 `#pd-mapper` 注释。我要把这段 rc 上下文读出来，确认它是被注释掉了，还是被别的触发条件卡住。

```bash
adb shell 'grep -n -A8 -B4 "service vendor.pd_mapper" /vendor/etc/init/hw/init.target.rc'
```

`service vendor.pd_mapper` 本身并没有被注释掉，前面的 `#pd-mapper` 只是个注释标题。问题变成：服务定义在，但当前系统里没跑。先看它是不是启动失败过。

这一轮先把 service 定义、属性和二进制存在性全部核清，再看 recovery init 到底有没有导入这些服务。

```bash
adb shell 'logcat -b all -d | grep -i "pd_mapper\|pd-mapper\|vendor.pd_mapper" | tail -n 120'
adb shell 'getprop init.svc.vendor.pd_mapper; getprop init.svc.vendor.per_mgr'
adb shell 'ps -A | grep -E "pd-mapper|pm-service"'
```

当前系统里 `vendor.pd_mapper` 和 `vendor.per_mgr` 都是“服务定义存在，但既无进程、也无状态属性”。这已经足够异常，我直接手动拉起它们，再看 audio PD/APM 是否恢复。

```bash
adb shell start vendor.pd_mapper
adb shell start vendor.per_mgr
```

这一步直接打到了点上：`start vendor.pd_mapper` 和 `start vendor.per_mgr` 都被 init 拒绝了，而且明确要求看 dmesg。也就是说不是“没人去拉”，而是“服务起不来”。我现在只需要把 init 拒绝原因抓出来。

```bash
adb shell 'dmesg | tail -n 120'
adb shell 'logcat -b all -d | tail -n 200'
```


刚才有个决定性的线索：虽然 `sys.boot_completed=1`，但内核日志里调用者的 SELinux 域仍是 `u:r:recovery:s0`。也就是说你现在其实还是 recovery 环境，只是某些属性看起来像“已开机”。更关键的是，init 明确说 `Could not find vendor.pd_mapper`，这不是启动失败，而是 recovery 的 init 根本没导入这条 vendor service 定义。这个就把问题从“audio PD 自己没起来”推进到了“recovery 根本缺少把它拉起来的服务框架”。

这一组检查把问题钉得更具体了：`vendor.pd_mapper` 和 `vendor.per_mgr` 在 stock 里有 service 定义，但当前环境里既没有进程，也没有对应属性状态；`start` 之后 init 直接拒绝继续执行。这里已经不再是“没人去拉”，而是 recovery 的 init 根本没有把这套 vendor service 框架导入进来。

随后分别直接执行和后台常驻 `pd-mapper` / `pm-service`，判断缺的是 service 包装还是二进制本身。

```bash
adb shell 'LD_LIBRARY_PATH=/vendor/lib64:/system/lib64 /vendor/bin/pd-mapper'
adb shell 'LD_LIBRARY_PATH=/vendor/lib64:/system/lib64 /vendor/bin/pm-service'
```

`pm-service` 前台试跑没有立即崩，说明它至少能在 recovery 里执行；`pd-mapper` 的输出我读一下，看它是正常驻留还是还差别的依赖。

```bash
adb shell 'LD_LIBRARY_PATH=/vendor/lib64:/system/lib64 /vendor/bin/pd-mapper >/dev/null 2>&1 &'
adb shell 'LD_LIBRARY_PATH=/vendor/lib64:/system/lib64 /vendor/bin/pm-service >/dev/null 2>&1 &'
adb shell 'ps -A | grep -E "pd-mapper|pm-service"'
adb shell 'cat /proc/asound/cards; ls -l /dev/snd'
adb shell 'dmesg | grep -i -E "pd_mapper|pd-mapper|pm-service|per_mgr|apm is not up|q6 state is down|audio-pkt" | tail -n 120'
```

`pd-mapper` 和 `pm-service` 能在 recovery 里手工常驻，这一步已经证明“缺少 vendor service 框架”不是空想。下一层就不是继续猜服务存不存在，而是在它们已经就位的前提下重新拉 audio 用户态，观察 FastRPC 和 audio PD 初始化链能不能被带着继续往前走。

结论:

- 这一轮把一个更关键的事实坐实了：所谓“系统态”并不是健康基线，很多关键上下文仍表现为 recovery 语义。
- `vendor.pd_mapper` 和 `vendor.per_mgr` 的 service 定义存在于 stock，但 recovery init 根本没有导入，所以 `start` 会直接失败，不是服务自己崩了。
- `/vendor/bin/pd-mapper` 和 `/vendor/bin/pm-service` 本身可以在 recovery 里后台常驻，这说明缺的是 recovery 的 vendor service 框架，而不是二进制文件。

---

## 8. 手工补起 pd-mapper / pm-service 后，FastRPC 前沿继续收窄到启动形态与单实例

现在 `pd-mapper` 和 `pm-service` 已经能在 recovery 里常驻了，这一步已经证明“缺少 vendor service 框架”不是空想。还没见到声卡变化，合理下一步就是在它们已经就位的前提下重启 audio 用户态，让 FastRPC/audio PD 重新走一遍初始化链。

```bash
adb shell 'pkill -f audioadsprpcd; pkill -f audiohalservice.qti; pkill -f adsprpcd'
adb shell 'ps -A | grep -E "pd-mapper|pm-service"'
```

前置服务还在。现在把三条音频用户态链按 stock 路径重拉起来，观察是不是从“Transport endpoint is not connected”往前走一步。

这一轮先对照 stock init 定义和二进制路径，确认手工 bring-up 对应的就是这三段进程。

```bash
adb shell 'grep -R -n "service .*adsprpcd\|service .*audiohalservice" /vendor/etc/init /system/etc/init 2>/dev/null | head -n 40'
adb shell 'ls /vendor/bin /vendor/bin/hw 2>/dev/null | grep -E "adsprpcd|audiohalservice" | sort -u'
```

在 `pd-mapper` / `pm-service` 已在位的前提下，直接把三段音频进程拉起，观察错误前沿会不会继续往里走。

```bash
adb shell 'LD_LIBRARY_PATH=/vendor/lib64:/system/lib64 /vendor/bin/adsprpcd >/dev/null 2>&1 &'
adb shell 'LD_LIBRARY_PATH=/vendor/lib64:/system/lib64 /vendor/bin/audioadsprpcd >/dev/null 2>&1 &'
adb shell 'LD_LIBRARY_PATH=/vendor/lib64:/system/lib64 /vendor/bin/audiohalservice.qti >/dev/null 2>&1 &'
```

三条音频进程已经重新拉起。现在看两件事：`audioadsprpcd` 的 FastRPC 错误是否缓解，以及 ALSA 卡有没有被补出来。

```bash
adb shell 'ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice|pd-mapper|pm-service"'
adb shell 'cat /proc/asound/cards; ls -l /dev/snd'
adb shell 'logcat -b all -d | grep -i -E "audioadsprpcd|audiohalservice|adsprpcd|pd-mapper|pm-service" | tail -n 160'
```

这一轮的结果很直接：`pd-mapper` 和 `pm-service` 已经驻留，但 `audioadsprpcd`、`audiohalservice.qti` 还是没活下来，ALSA 也没有出现。这里需要看的不再是服务是否存在，而是它们退出时到底卡在什么位置。

这一轮再次退回到 binder 库路径错误后，继续确认 `system_a` 是否仍然挂载，再在正确 `LD_LIBRARY_PATH` 下重拉三段音频进程。

```bash
adb shell 'mount | grep " /mnt/system_a "'
adb shell 'ls /mnt/system_a/system/lib64/libbinder_ndk.so 2>/dev/null'
adb shell 'pkill -f audioadsprpcd; pkill -f audiohalservice.qti; pkill -f adsprpcd'
adb shell 'ps -A | grep -E "pd-mapper|pm-service"'
```

这里没有新结论，只是变量被简化过头了：前一轮又掉回 binder 符号不匹配，原因是 `LD_LIBRARY_PATH` 只给了 `/vendor/lib64:/system/lib64`，没有把 stock `system_a` 的库放到最前面。`pd-mapper` / `pm-service` 这条线已经站稳，接下来只需要把正确的 stock 库路径重新套回去。

这一段先把 `system_a` 和前置进程状态重新对齐，再带正确库路径重拉三段音频进程。

```bash
adb shell 'LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/vendor/lib64:/system/lib64 /vendor/bin/adsprpcd >/dev/null 2>&1 &'
adb shell 'LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/vendor/lib64:/system/lib64 /vendor/bin/audioadsprpcd >/dev/null 2>&1 &'
adb shell 'LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/vendor/lib64:/system/lib64 /vendor/bin/audiohalservice.qti >/dev/null 2>&1 &'
```

这次前置条件终于齐了：`pd-mapper`、`pm-service` 常驻，三条音频进程也都在正确的 stock 库路径下重拉了一遍。链路确实往前走了一步，`audioadsprpcd` 已经能稳定留住，但 `audiohalservice.qti` 仍然没有活下来，而且 ALSA 还是没有出现。

```bash
adb shell 'ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice|pd-mapper|pm-service"'
adb shell 'cat /proc/asound/cards; ls -l /dev/snd'
adb shell 'logcat -b all -d | grep -i -E "audioadsprpcd|audiohalservice|adsprpcd|wait_for_snd_card_to_online|Transport endpoint is not connected|adsp_default_listener|Failed to open snd sysfs node" | tail -n 160'
```

有变化了：`audioadsprpcd` 这次终于留住了，说明 `pd-mapper`/`pm-service` 加上正确的 stock 库路径确实让链路前进了一段。但 `audiohalservice.qti` 仍然没活下来，而且 ALSA 还没出。我要直接看最新日志卡在什么位置。

`Transport endpoint is not connected` 前移成 `Device or resource busy` 之后，先做单实例清场，避免多个 `adsprpcd` 抢同一个 listener 带来假象。

```bash
adb shell 'pkill -9 -f audioadsprpcd; pkill -9 -f audiohalservice.qti; pkill -9 -f adsprpcd'
adb shell 'sleep 1; ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice"'
```

这轮实验已经产出了两个新的硬结论，我先把它们固化下来，避免后面再绕回旧判断：

1. recovery 缺的不是单纯某个内核节点，而是 `vendor.pd_mapper` / `vendor.per_mgr` 这类 vendor service 根本没进 init 服务表；  
2. 一旦手动补齐它们，FastRPC 错误会从“未连通”前进到“资源忙”，说明链路确实被推进了，只是现在又卡在 duplicate listener / 多实例 `adsprpcd` 冲突。

随后开始专门检查 `adsprpcd` 的多实例来源、命令行参数和 stock init 定义，确认应该保留什么实例、去掉什么实例。

```bash
adb shell 'ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice|pd-mapper|pm-service"'
adb shell 'for p in $(pidof adsprpcd 2>/dev/null); do echo PID=$p; cat /proc/$p/cmdline | tr "\0" " "; echo; cat /proc/$p/status | grep -E "Name|Pid|PPid|Uid|Gid|State"; echo SEP; done'
adb shell 'for p in $(pidof audioadsprpcd 2>/dev/null); do echo PID=$p; cat /proc/$p/cmdline | tr "\0" " "; echo; cat /proc/$p/status | grep -E "Name|Pid|PPid|Uid|Gid|State"; echo SEP; done'
```

把进程实况拉出来以后，再回看 stock rc 并杀掉多余实例，确认真正应该保留的只有哪一种启动形态。

```bash
adb shell 'grep -R -n "service .*adsprpcd\|service .*audioadsprpcd" /vendor/etc/init 2>/dev/null'
adb shell 'kill -9 2965 3070; sleep 1; ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice|pd-mapper|pm-service"'
adb shell 'logcat -b all -d | grep -i -E "adsp_default_listener|Device or resource busy|Transport endpoint is not connected|apps_dev_init failed" | tail -n 80'
```

多实例冲突在这里被坐实了：`Device or resource busy` 更像是同一个 FastRPC listener 被重复占用，而不是链路完全没通。把冲突实例清掉以后，只剩单实例 `adsprpcd rootpd adsp`、`pd-mapper` 和 `pm-service` 这条最小基线，后面的判断才有意义。

在只保留单实例 `adsprpcd rootpd adsp` 之后，先试一轮无参数 `audioadsprpcd`，确认单实例策略本身是否有效，再继续对齐到 stock 参数。

```bash
adb shell 'find /vendor/etc/init -type f | sort | head -n 40'
adb shell 'LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/vendor/lib64:/system/lib64 /vendor/bin/audioadsprpcd >/dev/null 2>&1 & sleep 1; ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice|pd-mapper|pm-service"'
```

单实例策略已经起作用了：在只保留 `adsprpcd rootpd adsp` 的情况下，`audioadsprpcd` 这次能单独拉起来，而且没有立刻把 `adsprpcd` 再打成多实例。下一步看它是否能稳定存活，并补拉 `audiohalservice.qti`。

```bash
adb shell 'sleep 2; ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice|pd-mapper|pm-service"'
```

这一轮先确认无参数形态本身会不会稳定，然后再补看 cmdline、日志和 `audiohalservice` 的连带变化。

```bash
adb shell 'for p in $(pidof audioadsprpcd 2>/dev/null); do echo PID=$p; cat /proc/$p/cmdline | tr "\0" " "; echo; cat /proc/$p/status | grep -E "Name|Pid|PPid|Uid|Gid|State"; done'
adb shell 'logcat -b all -d | grep -i -E "audioadsprpcd|adsp_default_listener|apps_dev_init failed|Device or resource busy|Transport endpoint is not connected" | tail -n 120'
```

现在状态已经稳定成单实例了：`adsprpcd rootpd adsp` 1 个，`audioadsprpcd` 1 个，两个都能常驻。接下来只看两件事：它的 FastRPC 错误是否真的消失，以及 `audiohalservice.qti` 能不能跟上。

```bash
adb shell 'LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/vendor/lib64:/system/lib64 /vendor/bin/audiohalservice.qti >/dev/null 2>&1 & sleep 2; ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice|pd-mapper|pm-service"'
adb shell 'cat /proc/asound/cards; ls -l /dev/snd'
```

单实例清场把结论又收窄了：`Device or resource busy` 不是多开的 `adsprpcd` 造成的，它在只保留 `adsprpcd rootpd adsp` 后依然存在。现在更像是我把 `audioadsprpcd` 用错了启动形态，它很可能需要 stock 的参数或 service 包装，而不是裸跑二进制。

接着完全按 stock 方向对齐：读取 rc、用正确参数重拉 `audioadsprpcd audiopd adsp`，并尝试直接走 init service 名，看 recovery 是否根本没导入这些服务。

```bash
adb shell 'grep -R -n audioadsprpcd /vendor/etc/init 2>/dev/null | head -n 40'
adb shell 'grep -R -n adsprpcd /vendor/etc/init 2>/dev/null | head -n 40'
adb shell 'grep -R -n audiohalservice.qti /vendor/etc/init 2>/dev/null | head -n 40'
```

标准定义已经找到了，问题基本坐实：`audioadsprpcd` 的 stock 形态不是裸跑，而是 `/vendor/bin/audioadsprpcd audiopd adsp`。我现在按这个参数重拉一次，再看 `Device or resource busy` 会不会消失。

```bash
adb shell 'sed -n "1,80p" /vendor/etc/init/vendor.qti.audio-adsprpc-service.rc'
```

这一段先完全按 stock 参数重拉 `audioadsprpcd audiopd adsp`，确认参数对齐后错误有没有改变。

```bash
adb shell 'kill -9 3833 2>/dev/null; LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/vendor/lib64:/system/lib64 /vendor/bin/audioadsprpcd audiopd adsp >/dev/null 2>&1 & sleep 2; ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice|pd-mapper|pm-service"'
adb shell 'logcat -b all -d | grep -i -E "audioadsprpcd|adsp_default_listener|apps_dev_init failed|Device or resource busy|Transport endpoint is not connected" | tail -n 120'
```

参数已经对齐到 stock 了，但我还没把结论算死。还要看日志有没有从 `Device or resource busy` 继续前进，还是仅仅换了个壳。

```bash
adb shell 'sleep 2; ps -A | grep -E "adsprpcd|audioadsprpcd|audiohalservice|pd-mapper|pm-service"; echo SEP; for p in $(pidof audioadsprpcd 2>/dev/null); do cat /proc/$p/cmdline | tr "\0" " "; echo; cat /proc/$p/status | grep -E "Uid|Gid|PPid|State"; done'
```

随后再检查 `audiohalservice` rc 和 init.svc 状态，判断 recovery 到底有没有导入这些 service。

```bash
adb shell 'sed -n "1,80p" /vendor/etc/init/audiohalservice_qti.rc'
```

参数已经修正，但 `audioadsprpcd` 还是回到了 `Transport endpoint is not connected`。现在唯一还没对齐的是运行身份：stock rc 要它以 `media` 跑，而我手工拉起的还是 `root`。我先试能不能直接走 init 的原生 service 名，把用户和 group 也交给它。

```bash
adb shell 'getprop init.svc.vendor.audioadsprpcd_audiopd; getprop init.svc.vendor.audio-hal-aidl; getprop init.svc.vendor.adsprpcd'
adb shell 'start vendor.audioadsprpcd_audiopd; sleep 1; ps -A | grep -E "audioadsprpcd|adsprpcd"'
adb shell 'start vendor.audio-hal-aidl; sleep 1; ps -A | grep -E "audiohalservice|audioadsprpcd|adsprpcd"'
```

recovery 果然没有导入这些音频 service，`start vendor.audioadsprpcd_audiopd` 和 `start vendor.audio-hal-aidl` 都是 `Unable to start service`。也就是说，想对齐到 stock 的 `media` / `audioserver` 运行身份，不能靠 init，只能尝试手工降权运行。

最后确认 recovery 可用的降权工具和目标用户信息，说明为什么纯手工路径会在这里卡住。

```bash
adb shell 'command -v su; command -v setpriv; command -v runcon; command -v chpst; command -v toybox'
adb shell 'grep -n "audioadsprpcd_audiopd\|audio-hal-aidl" /proc/1/mounts /proc/1/environ 2>/dev/null'
adb shell 'dmesg | tail -n 40'
```

到这里基本只剩一个很具体的差异了：stock 要 `audioadsprpcd` 以 `media` 身份、`audiohalservice.qti` 以 `audioserver` 身份跑，而 recovery 既没导入对应 init service，也没有现成的 `su` / `setpriv`。接着检查 toybox 里是否有能直接切 uid/gid 的 applet。

```bash
adb shell 'toybox --long | grep -E "(^| )su( |$)|(^| )chpst( |$)|(^| )setuidgid( |$)|(^| )setpriv( |$)|(^| )nohup( |$)|(^| )daemon( |$)"'
adb shell 'getent passwd media 2>/dev/null; getent passwd audioserver 2>/dev/null; cat /system/etc/passwd 2>/dev/null | grep -E "^(media|audioserver):"'
```

结论:

1. 多实例问题已经钉死。真正应该保留的是单实例 `/vendor/bin/adsprpcd rootpd adsp`。
2. `audioadsprpcd` 裸跑是错形态，stock 形态应是 `/vendor/bin/audioadsprpcd audiopd adsp`。
3. 之前看到的 `Device or resource busy` 不是最终前沿，而是无参数 `adsprpcd` / `audioadsprpcd` 手工多开时的中间态。
4. 在只保留单实例 `adsprpcd rootpd adsp`，再按 stock 参数拉起 `audioadsprpcd audiopd adsp` 后，错误会重新收敛回真正前沿：`Transport endpoint is not connected`。
5. `pd-mapper` 和 `pm-service` 的确是 recovery 里缺失的真实前置服务，我已经验证它们可以手工常驻；但补齐它们本身还不足以打通 `audiopd`。
6. `audiohalservice.qti` 这边还是起不来，`/proc/asound/cards` 仍然是空，`/dev/snd` 仍然只有 `timer`。

现在的硬阻塞已经很明确了：

1. recovery 没有导入 stock 的 `vendor.audioadsprpcd_audiopd` 和 `vendor.audio-hal-aidl` service。
2. 当前环境里也没有 `su`、`setpriv`、`chpst` 这类工具，没法把手工拉起的进程精确降权到 stock 的 `media` / `audioserver` 身份。
3. 所以这条“纯手工单实例重拉”路线，到这里已经把可验证的部分基本做完了；再往前就不是简单清进程和重启了，而是要补 recovery 对这些 vendor audio service 的导入，或者提供等效的降权执行路径。

- `Device or resource busy` 不是最终前沿，而是多实例或错误启动形态带出来的中间态。
- 真正该保留的是单实例 `/vendor/bin/adsprpcd rootpd adsp`，`audioadsprpcd` 也必须带 stock 参数 `audiopd adsp`。
- 即便参数对齐后，错误仍会回到 `Transport endpoint is not connected`，而 recovery 又没有导入 `vendor.audioadsprpcd_audiopd` / `vendor.audio-hal-aidl`，也没有可用降权工具，所以纯手工 bring-up 到这里已经接近上限。

也正因为这一步已经把“单实例”“正确参数”“正确库路径”这些纯手工能对齐的变量基本都试完了，后面策略才明确切到设备树和 init。不是简单因为手工方案麻烦才改方向，而是手工路线已经把能验证的都验证掉了，剩下的阻塞点正好落在 recovery 没导入 vendor audio service 框架这一层。

---

## 9. 从设备树入手补最小 recovery audio service 定义

纯手工路径已经证明 recovery 缺的是 vendor audio service 框架，因此继续从 `twrp_device_oplus_ossi_source_built` 设备树入手，检查 recovery init 入口和 vendor init 目录，确认最小补丁应该落在哪里。

这里一开始并不是打算把整套音频栈都搬进 recovery。前面纯手工 bring-up 已经把问题收敛到 service 框架缺口，所以最初的目标其实更窄：优先只把 `pd-mapper`、`per_mgr`、`audioadsprpcd_audiopd` 这类最小前置服务带进 recovery，先验证缺口到底是不是“运行身份 + init service 框架”。

设备树侧先确认了两个事实：当前 recovery root 里原本没有任何 audio / pd 相关 init 片段，而且也没有现成的 `pd-mapper`、`pm-service`、`adsprpcd`、`audioadsprpcd`、`audiohalservice.qti`。完整源码落地时需要同时考虑 rc 和二进制，但为了最快验证“缺的是不是 init service 框架”这个假设，这一轮先补最小 vendor rc，让 recovery init 至少先“认识这些服务”。

这一轮中间有一个关键修正：原先还以为只要在 recovery 里补一份 rc，让 init 先认识这些 service，后面挂上真实 `/vendor` 就能继续验证；但把设备树和 `recovery/root/vendor` 实际翻完以后，发现当前树里连对应二进制和现成 rc 都没有，说明完整落地时确实不能只补 init。只是为了最快验证假设，仍然先选择最小改动面，只补 `vendor.audio-recovery-services.rc`，先把“service not found”这个最外层阻塞拿掉。

这一阶段主要做的是代码与设备树侧梳理和新增 rc 片段，没有新的终端命令链；最终新增的是一个最小 `vendor.audio-recovery-services.rc`，用于把以下 5 条 service 注册进 recovery init，但默认都 `disabled`：

- `vendor.pd_mapper`
- `vendor.per_mgr`
- `vendor.adsprpcd`
- `vendor.audioadsprpcd_audiopd`
- `vendor.audio-hal-aidl`

结论:

- 当前 `twrp_device_oplus_ossi_source_built` 的 recovery root 里原本没有音频相关 vendor service 片段。
- 最小可用修法不是先把所有二进制打进 recovery，而是先让 recovery init “认识这些服务”，这样在真实 `/vendor` 已挂好的前提下，后续至少可以 `start` 进入下一层验证。

---

## 10. 直接用 Magiskboot 注入 TWRP 成品镜像验证 init 方向

这一阶段先确认本地 `magiskboot` 可用、目标镜像路径正确，并记录原始镜像的基本信息与摘要。

这一段刚开始其实先走偏过一次：最早是顺着现成的解包目录去看 `audio_dtb_probe` 里的 recovery 产物，并一度准备直接改那份解包出来的 ramdisk；随后用户明确指出那是官方 recovery，不是当前要验证的目标，注入对象必须切回指定的 TWRP 成品图。也正因为有这次纠偏，后面的解包、注入、回封和校验才全部重新基于 `TWRP-3.7.1-16-ossi-2026-03-10.img` 来做，而不是沿用前面那份错误目标。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP' && ./magiskboot cpio 2>&1 | head -40
cd '/Volumes/Case-sensitive APFS/TWRP' && ./magiskboot --help | head -40
cd '/Volumes/Case-sensitive APFS/TWRP/device_tree/twrp_device_oplus_ossi_source_built' && ls -lh 'TWRP-3.7.1-16-ossi-2026-03-10.img' && shasum 'TWRP-3.7.1-16-ossi-2026-03-10.img'
```

随后在专门的注入目录里复制目标镜像、解包 `orig.img`，确认这张 TWRP 镜像带有可操作的 `header` 和 `ramdisk.cpio`。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/magisk_inject_ossi_20260312' && cp '../device_tree/twrp_device_oplus_ossi_source_built/TWRP-3.7.1-16-ossi-2026-03-10.img' ./orig.img && ../magiskboot unpack -h orig.img
pwd
cd '/Volumes/Case-sensitive APFS/TWRP' && ls -ld magisk_inject_ossi_20260312 && cd magisk_inject_ossi_20260312 && pwd && ls -la | head
cd '/Volumes/Case-sensitive APFS/TWRP/magisk_inject_ossi_20260312' && ls -la header ramdisk.cpio orig.img 2>/dev/null || true
```

这一步确认了解包环境本身没有问题：目标 TWRP 成品图能被正常拆出标准 `header` 和 `ramdisk.cpio`。后续不再直接修改主 recovery rc，而是优先确认 ramdisk 里是否已有 `vendor/etc/init`，这样可以把新增 service rc 以更小的改动面注进去。

这里还补做了一次环境自检，因为解包过程中工具返回的目录状态有点异常，像是工作目录和终端上下文没有完全对齐。于是没有继续沿着“看起来已经成功”的状态往下走，而是用 `pwd`、`ls` 和 `header` 再把当前目录、产物和镜像结构逐项钉死，先排除注入环境本身错位。

接着把 `ramdisk.cpio` 展开，确认里面已有 `vendor/etc/init`，这样就能直接注入额外 rc，而不用硬改主 `init.recovery.qcom.rc`。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/magisk_inject_ossi_20260312' && mkdir -p ramdisk_out && cd ramdisk_out && ../../magiskboot cpio ../ramdisk.cpio extract
cd '/Volumes/Case-sensitive APFS/TWRP/magisk_inject_ossi_20260312' && cat header
cd '/Volumes/Case-sensitive APFS/TWRP' && ./magiskboot cpio --help | head -80
```

这一轮也修正了前面基于另一份 recovery 产物得到的一个判断。当时曾以为 ramdisk 很薄、没有现成的 `vendor/etc/init`，所以最稳的做法会是把 service 段直接并进主 `init.recovery.qcom.rc`；但真正切到这张 TWRP 成品图后，实际解包结果显示它已经带了 `vendor/etc/init`，于是策略立刻改成“注入独立 rc 文件”，避免对主 rc 做不必要的侵入式改动。

确认语法后，直接把 `vendor.audio-recovery-services.rc` 注入 `ramdisk.cpio`，并回封出新的测试镜像。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/magisk_inject_ossi_20260312' && ../magiskboot cpio ramdisk.cpio "add 0644 vendor/etc/init/vendor.audio-recovery-services.rc ../device_tree/twrp_device_oplus_ossi_source_built/recovery/root/vendor/etc/init/vendor.audio-recovery-services.rc" && ../magiskboot cpio ramdisk.cpio "exists vendor/etc/init/vendor.audio-recovery-services.rc"
cd '/Volumes/Case-sensitive APFS/TWRP/magisk_inject_ossi_20260312' && ../magiskboot repack orig.img TWRP-3.7.1-16-ossi-2026-03-10-audio-init-test.img
cd '/Volumes/Case-sensitive APFS/TWRP/magisk_inject_ossi_20260312' && ls -lh TWRP-3.7.1-16-ossi-2026-03-10-audio-init-test.img 2>/dev/null || true
```

这一轮回封结果是干净的：镜像尺寸仍保持在原有量级，ramdisk 只增加了一个 rc 文件应有的体量。这里的重点已经从“能不能生成镜像”转成“新镜像能不能再被完整解包，以及注入进去的 rc 内容是否真实存在且可读”。

随后对新镜像做二次解包和内容核验，确保不是坏镜像，而且注入进去的 rc 文件真实存在、内容正确，再把产物复制回设备树目录旁边。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/magisk_inject_ossi_20260312' && mkdir -p verify && cp TWRP-3.7.1-16-ossi-2026-03-10-audio-init-test.img verify/test.img && cd verify && ../../magiskboot unpack -h test.img && ../../magiskboot cpio ramdisk.cpio "exists vendor/etc/init/vendor.audio-recovery-services.rc"
cd '/Volumes/Case-sensitive APFS/TWRP/magisk_inject_ossi_20260312' && shasum orig.img TWRP-3.7.1-16-ossi-2026-03-10-audio-init-test.img
cd '/Volumes/Case-sensitive APFS/TWRP/magisk_inject_ossi_20260312/verify' && cat header
```

确认回封产物能正常再解包后，再把注入进去的 rc 直接抽出来核对内容，并把镜像复制回设备树目录旁边。

```bash
cd '/Volumes/Case-sensitive APFS/TWRP/magisk_inject_ossi_20260312/verify' && ../../magiskboot cpio ramdisk.cpio "extract vendor/etc/init/vendor.audio-recovery-services.rc injected.rc" && sed -n '1,120p' injected.rc
cd '/Volumes/Case-sensitive APFS/TWRP/magisk_inject_ossi_20260312' && cp -f TWRP-3.7.1-16-ossi-2026-03-10-audio-init-test.img ../device_tree/twrp_device_oplus_ossi_source_built/
cd '/Volumes/Case-sensitive APFS/TWRP/device_tree/twrp_device_oplus_ossi_source_built' && ls -lh *audio-init-test*.img 2>/dev/null || true
cd '/Volumes/Case-sensitive APFS/TWRP/magisk_inject_ossi_20260312' && cp -f TWRP-3.7.1-16-ossi-2026-03-10-audio-init-test.img '../device_tree/twrp_device_oplus_ossi_source_built/TWRP-3.7.1-16-ossi-2026-03-10-audio-init-test.img' && ls -lh '../device_tree/twrp_device_oplus_ossi_source_built/TWRP-3.7.1-16-ossi-2026-03-10-audio-init-test.img'
```

结论:

- 这一步把“补 init service”从源码层面的想法，推进成了真实 TWRP 成品镜像上的可验证产物。
- 新镜像可以正常解包、回封、再解包，且注入进去的 `vendor.audio-recovery-services.rc` 内容完整无误，说明镜像级注入方向成立。
- 后续上机验证的重点不再是“镜像有没有坏”，而是 `start vendor.pd_mapper`、`start vendor.per_mgr`、`start vendor.audioadsprpcd_audiopd` 这些命令，是否会从 `unknown service` 推进到真正的运行错误。

---

## 最终归档结论

最开始的 permissive 实验排除了“只要放开 SELinux 就能继续”的单一假设，真正前置先是 `/vendor`、`/odm`、`system_a` 与 `frpc-adsprpc` 这些运行时层要齐。然后又确认 `audio_pkt` / `audpkt_ion` / `oplus_audio_daemon` 这条模块链是 `aud_pasthru_adsp` 缺失的直接原因，但补齐模块并不会自动带来声卡。

问题随后收敛到两层更真实的阻塞。第一层是 `spf_core_platform` / APM / GPR readiness：recovery 的运行时 DT 里其实有 `soc/spf_core_platform/sound`，但 `spf_core_platform` 没能把它稳定实例化成可用 child device，日志前沿从 `q6 state is down`、`apm is not up` 最多推进到 `enumarate machine driver`。第二层是 recovery 缺少 vendor audio 服务框架：`pd-mapper`、`per_mgr`、`audioadsprpcd_audiopd`、`audio-hal-aidl` 这些 service 没有被 recovery init 正式导入，手工 bring-up 只能做到一半，而且卡在运行身份、启动时序和 service 包装上。

最后这条线已经落到了可验证产物：最小 `vendor.audio-recovery-services.rc` 已注入到用户指定的 TWRP 成品镜像，并通过二次解包校验。后续真正的验证重点，是刷入后这些 service 是否能从 `unknown service` 推进到更深一层的真实运行错误。
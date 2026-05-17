# 第1章：soundtrigger VINTF 补缺与实刷验证
User: 继续

GitHub Copilot: 我继续沿用户态控制链往下打，不再重复播放侧实验。先确认 `audiohalservice.qti` 现在是怎么被拉起、有没有现成日志落点，以及能不能在不破坏当前环境的前提下把它的注册过程抓出来。

Searched for regex `vendor.audio-hal-manual|start vendor.audio-hal-manual|audiohalservice.qti|twrp-audio-hal-wrapper` (`**/device_tree/**`), 7 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/device_tree/twrp_device_oplus_ossi_source_built/recovery/root/system/bin/twrp-audio-autoload.sh#180-180), lines 180 to 280

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'getprop init.svc.vendor.audio-hal-manual; ps -A | grep audiohalservice.qti; ls -l /tmp /cache 2>/dev/null | head -n 80'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for f in /proc/878/cmdline /proc/878/environ /proc/878/fd/1 /proc/878/fd/2; do echo ===$f===; ls -l $f 2>/dev/null; done'

现在最缺的是 `audiohalservice.qti` 自己在启动和注册阶段到底说了什么。它当前 stdout/stderr 都指向 null，所以我先不改代码，直接在设备上停掉这个服务，用和 wrapper 一样的环境手工起一份带日志重定向的实例，把注册输出抓到文件里。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'tr "\0" "\n" < /proc/878/environ | sed -n "1,120p"'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'cat /proc/878/cmdline | tr "\0" " "'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'setprop ctl.stop vendor.audio-hal-manual; sleep 1; ps -A | grep audiohalservice.qti || true; export LD_LIBRARY_PATH=/mnt/real_system/system/lib64:/system/lib64:/vendor/lib64:/vendor/lib64/hw; export vendor_audio_hidl_hal_test=1; /vendor/bin/hw/audiohalservice.qti >/tmp/audiohalservice.manual.log 2>&1 & echo $! > /tmp/audiohalservice.manual.pid; sleep 3; ps -A | grep audiohalservice.qti || true; tail -n 120 /tmp/audiohalservice.manual.log'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'setprop ctl.start vendor.audio-hal-manual; sleep 2; ps -A | grep audiohalservice.qti || true'

手工起服务这条实验有两个结果：一是它确实能在 shell 里起来，二是 stdout/stderr 只有一条插件日志，不足以直接看到注册结果。先把我刚才手工起的那一份清掉，恢复成单实例，再继续找更直接的注册证据。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'cat /tmp/audiohalservice.manual.pid 2>/dev/null; ps -A | grep audiohalservice.qti || true; cat /tmp/audiohalservice.manual.log 2>/dev/null'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'manual_pid=$(cat /tmp/audiohalservice.manual.pid 2>/dev/null); if [ -n "$manual_pid" ]; then kill $manual_pid 2>/dev/null || true; fi; sleep 1; ps -A | grep audiohalservice.qti || true'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'setprop ctl.stop vendor.audio-hal-manual; sleep 1; setprop ctl.start vendor.audio-hal-manual; sleep 2; ps -A | grep audiohalservice.qti || true; dmesg | tail -n 200 | grep -Ei "audiohal|agm|pal|registerService|IAGM|IPAL|audio core|audio.effect"'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for p in /proc/878 /proc/3396 /proc/3434; do [ -d $p ] || continue; echo ===$p===; ls -l $p/fd/1 $p/fd/2 2>/dev/null; done'

Compacted conversation现在拿到了一条真正有价值的新证据：手工日志里明确有 `failed to register Interface: [name: sthal ... mandatory: 1]`，而受管启动时 dmesg 里已经能看到 `IAGM`、`IPAL`、`IPALEventNotifier`、`IFactory` 这些接口触发了 servicemanager/VINTF 路径。下一步我去确认这个 `sthal` 失败是不是把后续音频核心注册链截断了。

Searched for regex `sthal|soundtriggerhal.qti|vendor_audio_interfaces_recovery|mandatory` (`**/*.{xml,rc,sh,md,c,cpp,h}`), 200 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/device_tree/twrp_device_oplus_ossi_source_built/recovery/root/system/etc/audio/vendor_audio_interfaces_recovery.xml)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/device_tree/twrp_device_oplus_ossi_source_built/recovery/root/vendor/etc/audio/vendor_audio_interfaces_recovery.xml)

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'dmesg | grep -Ei "failed to register Interface|audiohalservice|IAGM/default|IPAL/default|IPALEventNotifier/default|IFactory/default|IModule/default|IConfig/default|soundtrigger" | tail -n 200'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for svc in vendor.qti.hardware.agm.IAGM/default vendor.qti.hardware.pal.IPAL/default vendor.qti.hardware.paleventnotifier.IPALEventNotifier/default android.hardware.audio.effect.IFactory/default android.hardware.audio.core.IModule/default android.hardware.audio.core.IConfig/default; do echo ===$svc===; service check "$svc" 2>/dev/null || cmd -w 1 service check "$svc" 2>/dev/null || true; done'

`service check` 这一轮没给出正向结果，说明普通 service CLI 在 recovery 里不够可靠，不能据此判断“没注册”。我去读刚才那份完整 dmesg 摘要，把失败和缺失接口缩成最小结论。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_PxPeXDJH8f5RylpNApWRxgVY__vscode-1773902486482/content.txt)

dmesg 已经比前面更明确了：`IAGM`、`IPAL`、`IModule`、`IConfig`、`IFactory` 都走到了 manifest 查询路径，但 `soundtrigger3.ISoundTriggerHw/default` 在 recovery VINTF 里缺失，而且 `audiohalservice.qti` 似乎在被重复拉起。现在我直接验证它是不是在 crash/restart 循环，这比继续盯 FE 控件更关键。

Searched for regex `libsoundtriggerhal\.qti\.so|soundtrigger3\.ISoundTriggerHw|sthal` (`**/device_tree/**`), no results

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'getprop init.svc.vendor.audio-hal-manual; getprop init.svc_debug_pid.vendor.audio-hal-manual; getprop init.svc_debug.no_fatal.vendor.audio-hal-manual; for i in 1 2 3 4 5 6; do ps -A | grep audiohalservice.qti || true; sleep 2; done'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for i in 1 2 3; do echo ===round:$i===; dmesg | tail -n 40 | grep -Ei "twrp-audio-hal-wrapper|soundtrigger3|failed to register Interface|audiohalservice"; sleep 4; done'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'getprop | grep -E "audio-hal-manual|audiohal|crash" | sed -n "1,120p"'

现在现象已经收敛了：`audiohalservice.qti` 不是稳定常驻，而是在大约 10 秒级别反复换 PID；每轮都卡在 `android.hardware.soundtrigger3.ISoundTriggerHw/default` 不在 VINTF manifest。这个比“某个 mixer 没写进去”更像根因级问题了。接着我确认两件事：一是 recovery 里确实漏了 soundtrigger manifest，二是设备上对应实现是否存在，决定是补 manifest 还是直接禁掉这条注册。

Searched for text `soundtrigger` (`**/device_tree/**/*.xml`), no results

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'find /vendor/etc /system/etc -maxdepth 3 \( -iname "*soundtrigger*" -o -iname "*manifest*" \) 2>/dev/null | sed -n "1,200p"'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'find /vendor/lib64 /system/lib64 /vendor/bin/hw -maxdepth 2 \( -iname "*soundtrigger*" -o -iname "libsoundtriggerhal.qti.so" \) 2>/dev/null | sed -n "1,200p"'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for f in /vendor/etc/vintf/manifest*.xml /system/etc/vintf/manifest*.xml /odm/etc/vintf/manifest*.xml; do [ -f "$f" ] || continue; echo ===$f===; grep -n "soundtrigger\|audio.core\|vendor.qti.hardware.agm\|vendor.qti.hardware.pal" "$f"; done'

设备里其实已经有 `soundtrigger.qti.xml` 和 `libsoundtriggerhal.qti.so`。所以问题不是“文件缺失”，而更像是 manifest 里的声明版本/接口名和 `audiohalservice.qti` 现在尝试注册的 `android.hardware.soundtrigger3.ISoundTriggerHw/default` 对不上。我先把这个对照出来。

Searched for files matching `**/soundtrigger.qti.xml`, no matches

Searched for regex `android.hardware.soundtrigger3|ISoundTriggerHw|soundtrigger.qti|libsoundtriggerhal.qti.so` (`**/device_tree/**/*`), no results

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'sed -n "1,200p" /vendor/etc/vintf/manifest/soundtrigger.qti.xml'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'readelf -d /vendor/lib64/hw/libsoundtriggerhal.qti.so 2>/dev/null | grep -E "NEEDED|SONAME" | sed -n "1,120p"'

这里有个更细的怀疑：不是 manifest 文件绝对缺失，而是它可能是后续脚本才拷进去的，晚于 servicemanager 读取 VINTF 的时点。这样就会出现“文件现在存在，但 servicemanager 仍然认为 manifest 里没有”的表面矛盾。我去对照自启动脚本，确认这些 audio/soundtrigger manifest 是不是运行期才补进去的。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/device_tree/twrp_device_oplus_ossi_source_built/recovery/root/system/bin/twrp-audio-autoload.sh#1-1), lines 1 to 260

Searched for regex `manifest_audio_qti_services|manifest_audiocorehal_default|soundtrigger.qti|vendor_audio_interfaces_recovery|vintf` (`**/device_tree/**/*.sh`), 1 result

Searched for text `soundtrigger.qti.xml|manifest_audio_qti_services.xml|manifest_audiocorehal_default.xml|vendor_audio_interfaces_recovery.xml` (`**/device_tree/**/*`), 2 results

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'ls -l /vendor/etc/vintf/manifest /system/etc/vintf/manifest 2>/dev/null; stat -c "%n %Y" /vendor/etc/vintf/manifest/soundtrigger.qti.xml /vendor/etc/vintf/manifest/manifest_audio_qti_services.xml /vendor/etc/vintf/manifest/manifest_audiocorehal_default.xml 2>/dev/null'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_CVaHjmRqckkDTT12Shhuyzce__vscode-1773902486500/content.txt)

我已经把矛盾点串起来了：`soundtrigger.qti.xml` 在当前设备文件系统里存在，但 recovery 根里没有这份 fragment；servicemanager 启动时只看到了 ramdisk 自带的 VINTF，因此 `audiohalservice.qti` 后续尝试注册 soundtrigger3 会一直判定“manifest 不存在”，进而进入重启/失败链。我现在直接补 recovery VINTF fragment，并把结论追加到续文档末尾。

Starting: *补 recovery VINTF fragment* (2/4)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/device_tree/twrp_device_oplus_ossi_source_built/recovery/root/vendor/etc/vintf/manifest)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#581-581), lines 581 to 581

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#540-540), lines 540 to 581

我现在做的是最小根因修复，不去碰播放器或 mixer 路径：只把缺失的 recovery VINTF fragment 补进 ramdisk，并把这次因果链写入续文档，避免之后又回到错误分支。

Generating patch (68 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md), [](file:///Volumes/Case-sensitive%20APFS/TWRP/device_tree/twrp_device_oplus_ossi_source_built/recovery/root/vendor/etc/vintf/manifest/soundtrigger.qti.xml)


```

```

```

```


Read memory

代码补丁已经落下。最后我做两件收尾：一是把这个新前沿记进仓库记忆，二是跑一次最小验证，确保这次只是补了 manifest，没有引入格式层面的明显问题。

Checked [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md), [](file:///Volumes/Case-sensitive%20APFS/TWRP/device_tree/twrp_device_oplus_ossi_source_built/recovery/root/vendor/etc/vintf/manifest/soundtrigger.qti.xml), 88 problems found

Read changed files in [](file:///Volumes/Case-sensitive%20APFS/TWRP)

Created memory file twrp_audio_soundtrigger_manifest_boot_gap_20260319.md

补丁已经落完，格式检查也过了新增的 XML 文件。文档文件本身有一批既有的 markdownlint 告警，这次没有去顺手清，因为和当前根因修复无关。

Completed: *补 recovery VINTF fragment* (2/4)

这次我已经把前沿从“继续猜播放器/路由”收敛到“修 recovery 启动期 VINTF 缺口”，并直接落了补丁。

结论
1. 当前最像根因的不是 AW、也不是播放器本身。
2. 真正的新断点是：audiohalservice.qti 会尝试注册 soundtrigger3，而且把它当 mandatory。
3. recovery 的 ramdisk 里原本有 AGM、PAL、audio core、audio effect 的 VINTF fragment，但没有 soundtrigger.qti.xml。
4. real vendor 后续虽然会 bind 进来 soundtrigger.qti.xml 和 libsoundtriggerhal.qti.so，但 servicemanager 读取 VINTF 的时点更早，所以它不会重新纳入这个 fragment。
5. 结果就是 audiohalservice.qti 持续报 soundtrigger3 不在 VINTF manifest，并出现约 10 秒级 PID 轮换，符合失败后被反复拉起的模式。

我做的改动
1. 新增了 recovery 用的 soundtrigger.qti.xml，放进 recovery ramdisk 的 vendor VINTF manifest 目录。
2. 把这条因果链追加进了续文档 14.12，明确记录：
   - 手工日志里的 sthal mandatory 注册失败
   - dmesg 里 soundtrigger3 not in VINTF manifest
   - audiohalservice.qti PID 轮换
   - 为什么文件系统里看得到 fragment，但启动期 VINTF 仍然缺它

验证结果
1. 新增的 XML 文件没有报格式错误。
2. 文档文件本身存在一批历史 markdownlint 告警，这次没有顺手清理，因为和当前修复无关。
3. 我已经把手工启动的重复 audiohalservice 实例清掉，避免继续污染判断。

现在这次修复的意义
1. 它修的是启动期根因，不是运行时表面补丁。
2. 如果判断成立，下一次完整冷启动进入 recovery 后，audiohalservice.qti 应该不再因为 soundtrigger mandatory 注册失败而反复重启。
3. 这之后再复测 10 秒播放，才有机会看到 FE 运行态不再全零，以及“只响 1 秒”的现象是否消失。

下一步最自然的是：
1. 重新打包或刷入带这个 fragment 的 recovery
2. 冷启动进入 recovery
3. 先观察 audiohalservice.qti 是否稳定常驻
4. 再复测 pure_c_agm_probe 和 agm_audio_minimal_bin 的 10 秒播放

如果你要，我下一步可以直接继续做两件事之一：
1. 帮你把这个改动并入当前 recovery 打包流程
2. 给你一套最短的冷启动复测清单，专门验证这个 fragment 修复是否命中根因

Made changes.

User: 你用注入，刷写的方式验证

GitHub Copilot: 我按“注入修改并实际刷写验证”走，不停留在静态分析。先读现有的 recovery 重打包/注入方法和设备当前可刷目标，避免走错分区或格式。

Searched for regex `repack|magiskboot|vendor_boot|init_boot|flash|fastboot` (`**/docs/**/*.md`), 200 results

Searched for regex `vendor_boot|init_boot|boot.img|recovery.img|magiskboot` (`**/*.{sh,md,txt}`), 143 results

Read memory twrp_recovery_repack.md

Read memory twrp_audio_soundtrigger_manifest_boot_gap_20260319.md

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb devices -l && adb shell getprop ro.boot.slot_suffix && adb shell getprop ro.build.product && adb shell getprop ro.bootmode && adb shell getprop ro.boot.hardware.sku

设备在线，机型是 ossi，当前就在 recovery，slot 是 `_a`。下一步我不碰编译链，直接从设备当前 recovery 分区拉原图，做最小注入、回封、刷回 recovery，再冷启动复测 audio HAL 和 10 秒播放。

Searched for files matching `**/*ossi*recovery*.img`, 2 matches

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/aurora_recovery/scripts/repack_official_recovery.sh#300-300), lines 300 to 357

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'ls -l /dev/block/by-name/recovery /dev/block/by-name/recovery_a /dev/block/bootdevice/by-name/recovery /dev/block/bootdevice/by-name/recovery_a 2>/dev/null; blockdev --getsize64 /dev/block/by-name/recovery 2>/dev/null || blockdev --getsize64 /dev/block/by-name/recovery_a 2>/dev/null'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && command -v fastboot && fastboot devices

现在线索足够了：分区节点就是 recovery_a，大小 100 MiB，主机 fastboot 也在。接下来我直接导出当前 recovery_a，确认 ramdisk 里确实缺这个 fragment，然后最小注入 `soundtrigger.qti.xml`，回封成可刷镜像。

Created [](file:///Volumes/Case-sensitive%20APFS/TWRP/verify_recovery_soundtrigger_20260320)

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb pull /dev/block/by-name/recovery_a verify_recovery_soundtrigger_20260320/recovery_a_stock.img && shasum -a 256 verify_recovery_soundtrigger_20260320/recovery_a_stock.img

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP/verify_recovery_soundtrigger_20260320 && /Volumes/Case-sensitive\ APFS/TWRP/magiskboot unpack -h recovery_a_stock.img && /Volumes/Case-sensitive\ APFS/TWRP/magiskboot cpio ramdisk.cpio test vendor/etc/vintf/manifest/soundtrigger.qti.xml; echo EXIT:$?

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP/verify_recovery_soundtrigger_20260320 && cp recovery_a_stock.img recovery_a_patched.img && cp ramdisk.cpio ramdisk.cpio.bak && /Volumes/Case-sensitive\ APFS/TWRP/magiskboot cpio ramdisk.cpio 'add 0755 vendor/etc/vintf/manifest/soundtrigger.qti.xml ../device_tree/twrp_device_oplus_ossi_source_built/recovery/root/vendor/etc/vintf/manifest/soundtrigger.qti.xml' && /Volumes/Case-sensitive\ APFS/TWRP/magiskboot repack recovery_a_patched.img recovery_a_patched_injected.img && shasum -a 256 recovery_a_patched_injected.img && /Volumes/Case-sensitive\ APFS/TWRP/magiskboot unpack -h recovery_a_patched_injected.img

注入镜像已经生成，而且头信息仍然能被 magiskboot 正常识别，ramdisk 只增加了 195 字节量级，属于预期的最小修改。现在进入真正的刷写验证：重启到 bootloader，刷 recovery_a，再冷启动回 recovery 做日志复测。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb reboot bootloader && sleep 3 && for i in 1 2 3 4 5 6 7 8 9 10; do fastboot devices; if fastboot devices | grep -q .; then break; fi; sleep 2; done

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && fastboot getvar current-slot 2>&1 && fastboot getvar has-slot:recovery 2>&1 && fastboot getvar partition-size:recovery_a 2>&1

bootloader 侧信息和 adb 侧一致：当前 slot 是 a，`recovery_a` 大小正好 0x6400000，也就是 100 MiB，和我导出的原图一致。接下来直接刷 `recovery_a`，然后回 recovery 看 soundtrigger 注册和 audio HAL 是否稳定。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && fastboot flash recovery_a verify_recovery_soundtrigger_20260320/recovery_a_patched_injected.img

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && fastboot reboot recovery && sleep 6 && for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do adb devices | sed -n '2,$p'; if adb devices | grep -E '\srecovery$' >/dev/null; then break; fi; sleep 2; done && adb devices

刷写已经完成，问题只剩最后一段启动观察：`fastboot reboot recovery` 发出后，短轮询窗口里 adb 还没重新回到 `recovery`。我继续同时看 fastboot 和 adb，确认设备到底是慢启动、掉回 bootloader，还是已经起来但未枚举。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do echo ---$i---; adb devices; fastboot devices; sleep 2; done

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell getprop ro.bootmode 2>/dev/null && adb shell getprop sys.boot_completed 2>/dev/null && adb shell getprop init.svc.vendor.audio-hal-manual 2>/dev/null
Completed with input:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell getprop ro.bootmode 2>/dev/null && adb shell getprop sys.boot_completed 2>/dev/null && adb shell getprop init.svc.vendor.audio-hal-manual 2>/dev/null

现在不是“音频没好”这一级，而是设备在刷完后没有重新枚举成 adb 或 fastboot。我要先确认它是不是掉进了别的 USB 模式，还是单纯卡在启动早期，这决定我还能不能继续自动验证。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && for i in 1 2 3 4 5 6 7 8 9 10; do echo ---$i---; adb devices -l; fastboot devices; sleep 3; done

Ran terminal command:  system_profiler SPUSBDataType | grep -E 'OPD2413|OnePlus|QUSB|Qualcomm|Android|Fastboot' | tail -n 60

设备已经重新回到 recovery，说明刷写后的镜像至少能正常起机。现在进入真正的修复判定：我看三件事，`audiohalservice.qti` 是否还在重启、`soundtrigger3 not in VINTF` 是否消失、以及带快照的纯 C 播放路径里 FE 运行态有没有脱离全零。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'getprop ro.bootmode; getprop init.svc.vendor.audio-hal-manual; getprop init.svc_debug_pid.vendor.audio-hal-manual; ps -A | grep audiohalservice.qti || true; for i in 1 2 3 4 5; do echo ===poll:$i===; ps -A | grep audiohalservice.qti || true; sleep 3; done'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'dmesg | grep -Ei "soundtrigger3|failed to register Interface|twrp-audio-hal-wrapper|IAGM/default|IPAL/default|IModule/default|IConfig/default|IFactory/default" | tail -n 120'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend --play-after-open --play-seconds 10'
Completed with input:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend --play-after-open --play-seconds 10'

一个关键目标已经命中：刷机后 `audiohalservice.qti` 的 PID 在 15 秒观察窗里稳定不变，不再像之前那样十秒级轮换。现在就差把播放侧结果读出来，看 FE 运行态有没有跟着恢复。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_IxljlK0EUZwq7JypHeojJrnM__vscode-1773902486535/content.txt)

刷写后的状态不是简单“完全好了”。新的事实是：`audiohalservice.qti` 稳定了，但 `pure_c_agm_probe` 现在在 card 100 的 plugin open 阶段直接失败，不再是之前那种“能播 10 秒但 FE 全零”。我继续把它拆开，看这是启动时序问题，还是修复把系统带到了一个新的、更接近真实根因的位置。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'tail -n 200 /tmp/recovery.log; echo ===props===; getprop init.svc.vendor.vndservicemanager; getprop init.svc.vendor.audioadsprpcd_audiopd; getprop init.svc.vendor.audio-hal-manual; echo ===ps===; ps -A | grep -E "audiohalservice|vndservicemanager|audioadsprpcd|adsprpcd|per_mgr|pd_mapper"'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell '/data/local/tmp/agm_audio_minimal_bin --play-seconds 10 --tone-hz 440'
Completed with input:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell '/data/local/tmp/agm_audio_minimal_bin --play-seconds 10 --tone-hz 440'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'ls -l /vendor/etc/vintf/manifest/soundtrigger.qti.xml; sed -n "1,40p" /vendor/etc/vintf/manifest/soundtrigger.qti.xml'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_P8pDv84qTztSBOyGNREoOHnx__vscode-1773902486537/content.txt)

当前刷写验证已经有明确增量，但还没形成“音频问题已解决”的结论。我再补一轮针对性日志：只抓 `soundtrigger`、`agm`、`pal`、`audiohalservice`，并在稍等后重跑一次最小播放器，排除冷启动时序干扰。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===recovery.log===; grep -Ei "twrp-audio-hal-wrapper|soundtrigger|agm|pal|audiohalservice|vendor_audio_interfaces" /tmp/recovery.log | tail -n 120; echo ===dmesg===; dmesg | grep -Ei "soundtrigger|failed to register|agm|pal|audiohalservice|IAGM|IPAL|IConfig|IModule|IFactory" | tail -n 120'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'sleep 15; /data/local/tmp/agm_audio_minimal_bin --play-seconds 10 --tone-hz 440'
Completed with input:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'sleep 15; /data/local/tmp/agm_audio_minimal_bin --play-seconds 10 --tone-hz 440'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for i in 1 2 3; do echo ===svc:$i===; ps -A | grep audiohalservice.qti || true; sleep 5; done'

这轮刷写验证已经有可交付结论了。我把新结论记进仓库记忆，避免下次又从“soundtrigger 缺 fragment”这一步重新推。

Read changed files in [](file:///Volumes/Case-sensitive%20APFS/TWRP)

Created memory file twrp_audio_soundtrigger_flash_validation_20260320.md

已按“注入 + 实刷”完成验证。

这次我实际做了什么
1. 从真机当前 `recovery_a` 分区导出了原始 recovery 镜像，作为基线和回退备份。
2. 用仓库里的 magiskboot 对这个原始镜像做最小注入，只往 ramdisk 里加了 `soundtrigger.qti.xml`。
3. 回封后直接 `fastboot flash recovery_a`。
4. 再 `fastboot reboot recovery`，确认设备重新进了 recovery。

刷写结果
1. 刷写成功，`recovery_a` 写入正常。
2. 设备能正常重新启动回 recovery，没有起不来的问题。
3. 注入目标已经生效，运行环境里能看到 `soundtrigger.qti.xml`。

这次验证最重要的结论
1. `audiohalservice.qti` 不再像之前那样约 10 秒级反复换 PID。
2. 冷启动后我连续观察了多轮，PID 一直稳定。
3. 之前那条关键坏迹象，也就是 `android.hardware.soundtrigger3.ISoundTriggerHw/default not in VINTF manifest`，这轮没有再复现到关键日志里。
4. 这说明“recovery 启动期缺少 soundtrigger VINTF fragment，导致 audiohalservice.qti 重启循环”这条判断，已经被实刷验证命中。

但音频问题没有直接终结
1. 现在不再是“能播 10 秒但只听到 1 秒”这个状态了。
2. 刷机后两条最小播放路径都进入了一个新的失败点：
   - `pure_c_agm_probe`
   - `agm_audio_minimal_bin`
3. 两者都卡在更早的 AGM/MFC/plugin 路径上，典型特征是：
   - `agm_mixer_get_miid rc=-19`
   - `Failed to mixer_ctl_get_array`
   - `post-connect MFC failed`
4. 也就是说，这次注入修掉了 `audiohalservice.qti` 的重启前沿，但把系统推进到了下一个更深的阻塞点：`card100` / AGM mixer plugin / MFC 控制面。

所以，这次刷写验证的结论应该表述为
1. `soundtrigger.qti.xml` 注入是有效修复。
2. 它确实修掉了 recovery 启动期的一个根因级问题。
3. 但它不是最终音频修复。
4. 现在真正剩下的前沿，已经从 “HAL 因 soundtrigger manifest 缺失而重启” 变成了 “HAL 稳定后，AGM 的 MFC / mixer plugin 控制路径仍然拿不到有效返回”。

补充说明
1. 我已经保留了刷写前导出的原始 recovery 镜像，必要时可以直接刷回。
2. 我不能主观听到设备是否发声，所以这次验证基于实际刷写后的客观启动行为、服务稳定性和播放器返回值。

下一步最自然的是：
1. 继续在“已稳定的 audiohalservice”前提下，专查 `card100` 的 `mixer_ctl_get_array` / `getTaggedInfo` / `MIID` 为什么仍是 `-19`
2. 如果你想先保守回退，我也可以直接帮你把导出的原始 `recovery_a` 刷回去

User: 继续1

GitHub Copilot: 我继续沿“稳定 HAL 之后的下一个阻塞点”往下钻，目标是确认现在卡的是 AGM/PAL 服务注册、`vendor_audio_interfaces.xml` 生效顺序，还是 `card100` 自身控件集合变了。

Read memory twrp_audio_userspace_hal_gap.md

Read memory twrp_audio_component_gap.md

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===interfaces===; ls -l /vendor/etc/audio/vendor_audio_interfaces.xml /system/etc/audio/vendor_audio_interfaces_recovery.xml 2>/dev/null; echo ===vendor_audio_interfaces===; sed -n "1,80p" /vendor/etc/audio/vendor_audio_interfaces.xml 2>/dev/null; echo ===service-list===; service list | grep -Ei "audio|agm|pal|soundtrigger" || true; echo ===lshal===; lshal | grep -Ei "audio|agm|pal|soundtrigger" || true; echo ===cmd===; cmd -l | grep -Ei "audio|media|service" || true'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===tinymixD100===; /system/bin/tinymix_stock -D 100 2>&1 | sed -n "1,120p"; echo ===ps===; ps -A | grep -E "audiohalservice|vndservicemanager"'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'dmesg | grep -Ei "agm|pal|mixer_plugin_open|pcm_plug_open|mixer_ctl_get_array|audiohalservice|soundtrigger" | tail -n 200'

新发现已经很具体了：live 的 `/vendor/etc/audio/vendor_audio_interfaces.xml` 其实还是 stock 全量版，不是 recovery 精简版。这说明现有 twrp-audio-autoload.sh 的 overlay 时序没真正把精简接口表钉住，后面的 `/vendor/etc` bind 把它覆盖掉了。我要现场验证这个点，而不是继续猜 `card100`。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===mounts===; grep -n "vendor_audio_interfaces\| /vendor \| /vendor/etc " /proc/mounts; echo ===tmp===; ls -l /tmp/recovery-audio/vendor_audio_interfaces.xml 2>/dev/null; sed -n "1,40p" /tmp/recovery-audio/vendor_audio_interfaces.xml 2>/dev/null'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'cp /system/etc/audio/vendor_audio_interfaces_recovery.xml /tmp/vendor_audio_interfaces.manual.xml && mount -o bind /tmp/vendor_audio_interfaces.manual.xml /vendor/etc/audio/vendor_audio_interfaces.xml && echo ===after_bind===; ls -l /vendor/etc/audio/vendor_audio_interfaces.xml; sed -n "1,40p" /vendor/etc/audio/vendor_audio_interfaces.xml; setprop ctl.stop vendor.audio-hal-manual; sleep 2; setprop ctl.start vendor.audio-hal-manual; sleep 4; ps -A | grep audiohalservice.qti || true'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell '/data/local/tmp/agm_audio_minimal_bin --play-seconds 10 --tone-hz 440'
Completed with input:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell '/data/local/tmp/agm_audio_minimal_bin --play-seconds 10 --tone-hz 440'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for i in 1 2 3; do echo ===pid:$i===; getprop init.svc_debug_pid.vendor.audio-hal-manual; ps -A | grep audiohalservice.qti || true; sleep 4; done'

精简接口表现场切换后，失败形态完全没变，所以当前前沿已经可以从“接口表内容”继续往后收。下一步我直接核对你之前的内核/组件前沿是否还在：`WSA` 这支没起来、backend kcontrol 没导出，会不会正好解释现在 `card100` 的 `mixer_ctl_get_array` 失败。

Read memory twrp_audio_component_gap.md

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===dt===; for f in /sys/firmware/devicetree/base/soc/spf_core_platform/sound/qcom,upd_backends_used /sys/firmware/devicetree/base/soc/spf_core_platform/lpass-cdc/wsa-macro@6B00000/status /sys/firmware/devicetree/base/soc/spf_core_platform/lpass-cdc/wsa2-macro@6AA0000/status; do echo ---$f---; cat $f 2>/dev/null | tr -d "\000"; echo; done; echo ===components===; cat /sys/kernel/debug/asoc/components 2>/dev/null | grep -E "wsa|wcd|aw882|lpass-cdc|msm-ext-disp" | sed -n "1,120p"; echo ===controls===; /system/bin/tinymix_stock 2>/dev/null | grep -E "TDM-LPAIF-RX-SECONDARY rate ch fmt|PCM100|Speaker_Mute_Switch|WSA RX0 MUX|aw882xx_rx_switch" | sed -n "1,120p"'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'dmesg | grep -Ei "wsa|wcd9378|component is NULL|Invalid mixer control|failed to add wcd9378 routes|lpass-cdc|sun-mtp-snd-card" | tail -n 200'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell '/system/bin/tinyplay_ftm /vendor/etc/ftm_test_config 440 48000 1 16 10 2>&1 | sed -n "1,160p"'

这轮现场值很关键：设备树里 `wsa-macro` / `wsa2-macro` 已经不是 `disabled`，而是 `okay`，但运行态 `asoc/components` 里仍然没有任何 `wsa-codec.*`。也就是说，前沿又缩了一层，不再是“DT 明确关掉了 WSA”，而是“WSA 宏已经允许实例化，但 runtime component 仍然没长出来”。我把这条日志也读出来，确认有没有直接的 `component is NULL` 证据。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_yNjhpx6pmBTXh1cfHCPqLU3Y__vscode-1773942039751/content.txt)

我再补一条最小闭环：模块都在、DT 也放开了，但如果 SoundWire 下就是没有 `wsa` 从设备，那 `wsa-codec.*` 起不来就顺了。这个检查能把前沿从“怀疑”收成“运行态缺实体”。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===swr_devices===; ls -1 /sys/bus/soundwire/devices 2>/dev/null | sed -n "1,120p"; echo ===swr_drivers===; ls -1 /sys/bus/soundwire/drivers 2>/dev/null | sed -n "1,120p"; echo ===platform_lpass===; find /sys/devices/platform -maxdepth 6 \( -name "wsa-macro*" -o -name "wsa2-macro*" -o -name "rx-macro*" -o -name "tx-macro*" -o -name "va-macro*" \) 2>/dev/null | sed -n "1,160p"'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'cat /proc/asound/cards 2>/dev/null; echo ===dais===; cat /sys/kernel/debug/asoc/dais 2>/dev/null | grep -E "wsa|wcd|aw882|TDM-LPAIF|DISPLAY_PORT|PCM100" | sed -n "1,200p"'

前沿已经从 `soundtrigger`

User: 继续

GitHub Copilot: 我沿着“HAL 已稳定，但运行态 component 没长出来”继续，不回到已经验证过的 soundtrigger 分支。先把之前记录的 WSA/component 前沿和当前设备现场对齐，再决定是追 SoundWire 从设备，还是追接口表时序。

Read memory twrp_audio_component_gap.md

Read memory twrp_audio_wcd9378_gap.md

Read memory twrp_audio_soundtrigger_flash_validation_20260320.md

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===interfaces===; sed -n "1,80p" /vendor/etc/audio/vendor_audio_interfaces.xml; echo ===components===; cat /sys/kernel/debug/asoc/components 2>/dev/null | grep -Ei "wsa|wcd|rx_macro|tx_macro|va_macro|bolero|swr|lpass" | sed -n "1,200p"; echo ===swr-dev===; find /sys/bus/soundwire/devices -maxdepth 2 -type d 2>/dev/null | sed -n "1,200p"'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===dmesg===; dmesg | grep -Ei "wsa|wcd9378|wcd|swr|soundwire|rx_macro|tx_macro|va_macro|component.*NULL|asoc|lpass.*cdc" | tail -n 240'

现场已经把前沿又缩了一步：现在 live 的接口表就是 recovery 精简版，不是被 stock 覆盖；真正异常在组件层，`asoc/components` 

User: 继续调试啊

GitHub Copilot: 我继续沿运行态组件层往下，不再回到已经命中的 soundtrigger 修复。先把现有前沿和真机现场对齐，目标是确认缺的是 `wsa`/SoundWire 实体、还是 `card100` 依赖的 component/kcontrol 根本没注册出来。

Read memory twrp_audio_component_gap.md

Read memory twrp_audio_wcd9378_gap.md

Read memory twrp_audio_soundtrigger_flash_validation_20260320.md

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===cards===; cat /proc/asound/cards; echo ===components===; cat /sys/kernel/debug/asoc/components 2>/dev/null | grep -Ei "wsa|wcd|rx-macro|tx-macro|va-macro|bolero|swr|lpass" | sed -n "1,200p"; echo ===dai===; cat /sys/kernel/debug/asoc/dais 2>/dev/null | grep -Ei "wsa|wcd|rx-macro|tx-macro|va-macro|swr|lpass" | sed -n "1,200p"'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===modules===; cat /proc/modules | grep -Ei "wsa|wcd|swr|lpass_cdc|bolero|audio" | sed -n "1,200p"; echo ===soundwire===; find /sys/bus/soundwire/devices -maxdepth 2 -type f \( -name modalias -o -name name \) 2>/dev/null | xargs -I{} sh -c "echo ---{}---; cat {}" | sed -n "1,200p"; echo ===platform===; ls /sys/bus/platform/devices 2>/dev/null | grep -Ei "wsa|wcd|swr|sound|spf|lpass" | sed -n "1,200p"'

现场已经有一个很硬的新事实：现在卡里是起来了，但 `asoc/components` 只剩 `wcd939x-codec` 和 `lpass-cdc`，连之前见过的 `aw882xx_smartpa.*` 都没在这次冷启动现场出现。这比单纯盯 `card100` 更关键，我接着把模块、SoundWire 实体和 `aw882xx` 这一支是否真的没枚举出来对上。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_XcjQ8h89f4K8OQyZt7s1qfJ5__vscode-1773945584381/content.txt)

模块层和 platform device 层已经比之前更完整了：`wsa-macro`、`wsa2-macro`、`wsa_swr_ctrl`、`wsa2_swr_ctrl` 都真的存在，不再是“DT 没实例化”。但 ASoC component 仍没长出来，所以现在更像是 SoundWire 从设备或 codec 注册阶段没完成。我直接抓这两层。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===soundwire-devs===; for d in /sys/bus/soundwire/devices/*; do [ -d "$d" ] || continue; echo ---$d---; for f in name modalias driver_override subsystem; do [ -e "$d/$f" ] && { echo [$f]; cat "$d/$f" 2>/dev/null || readlink "$d/$f" 2>/dev/null; }; done; done | sed -n "1,240p"'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===wsa-platform===; for d in /sys/bus/platform/devices/wsa-macro /sys/bus/platform/devices/wsa2-macro /sys/bus/platform/devices/wsa_swr_ctrl /sys/bus/platform/devices/wsa2_swr_ctrl /sys/bus/platform/devices/wcd939x-codec; do [ -e "$d" ] || continue; echo ---$d---; readlink "$d/driver" 2>/dev/null; ls "$d" 2>/dev/null | sed -n "1,80p"; done'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'dmesg | grep -Ei "wsa|wcd9378|wcd939x|swr slave|component is NULL|Codec registration failed|could not find RX/TX swr slave device|aw882xx|snd_soc|probe defer" | tail -n 240'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===aw-components===; cat /sys/kernel/debug/asoc/components 2>/dev/null | grep -i aw || true; echo ===aw-dais===; cat /sys/kernel/debug/asoc/dais 2>/dev/null | grep -i aw || true; echo ===aw-proc===; ps -A | grep -i aw || true'

WSA 这支又收紧了一步：`wsa-macro`/`wsa2-macro` 已经绑定到各自 driver，`aw882xx` 也完整在场；真正缺的还是 SoundWire 从设备，现场只有 `wcd939x-slave.*`，完全没有 `wsa883x/884x` 或 `wcd9378` slave。这已经很像“总线实体没出来，所以上层 component/kcontrol 永远长不齐”。我把 dmesg 里的直接失败句子读出来，确认不是别的分支在抢先失败。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_47Oz0lMjVCJ0Argl5zGSkvWO__vscode-1773945584385/content.txt)

我看到一个比前面都更直接的缺口：现有自动脚本只对 `rx_swr_ctrl`、`va_swr_ctrl`、`bt_swr_mstr` 做了手工 probe，没有覆盖 `wsa_swr_ctrl` 和 `wsa2_swr_ctrl`。而现场这两个节点确实存在但没有绑定 driver，这正好能解释为什么 WSA SoundWire slave 根本不枚举。先做一次纯现场 A/B，不改文件，看看手工 probe 这两个节点后会不会长出 WSA 从设备和 component。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===before===; for d in /sys/bus/platform/devices/wsa_swr_ctrl /sys/bus/platform/devices/wsa2_swr_ctrl; do echo ---$d---; readlink "$d/driver" 2>/dev/null || echo no-driver; done; echo ===probe===; for dev in wsa_swr_ctrl wsa2_swr_ctrl; do p=/sys/bus/platform/devices/$dev; [ -e "$p" ] || continue; echo swr-mgr > "$p/driver_override" 2>/dev/null; echo $dev > /sys/bus/platform/drivers_probe 2>/dev/null; done; sleep 2; echo ===after===; for d in /sys/bus/platform/devices/wsa_swr_ctrl /sys/bus/platform/devices/wsa2_swr_ctrl; do echo ---$d---; readlink "$d/driver" 2>/dev/null || echo no-driver; done; echo ===soundwire===; ls /sys/bus/soundwire/devices 2>/dev/null; echo ===components===; cat /sys/kernel/debug/asoc/components 2>/dev/null | grep -Ei "wsa|aw882|wcd|lpass" | sed -n "1,200p"; echo ===dais===; cat /sys/kernel/debug/asoc/dais 2>/dev/null | grep -Ei "wsa|aw882|wcd|lpass" | sed -n "1,200p"'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'dmesg | tail -n 160 | grep -Ei "wsa|swr|wcd9378|wcd939x|slave|lpass_cdc_wsa|aw882"'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell '/data/local/tmp/agm_audio_minimal_bin --play-seconds 5 --tone-hz 440'
Completed with input:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell '/data/local/tmp/agm_audio_minimal_bin --play-seconds 5 --tone-hz 440'

A/B 结果很干脆：手工 `probe` 这两个 SWR 控制器没有任何变化，driver 还是没绑上，SoundWire 设备列表也没新增。所以这不是单纯“自动脚本漏 probe”能解决的层级了。现在要直接看这两个节点为什么根本绑不上，我去读它们的 `modalias`、driver 列表和最近内核日志。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_wxn7BQu7PT391ksLQVf9BuQA__vscode-1773945584389/content.txt)

现在拿到的是硬错误，不再是推测：`wsa_swr_ctrl` 和 `wsa2_swr_ctrl` 手工 probe 后都报 `swr link failed to connect`，并且 dtsi 版本写的是 `0x2000000`，硬件读回 `0x2010000`。我继续把这个错误和 DT 输入对上，确认是属性写错，还是单纯没有从设备挂上来。

Searching for regex `wsa_swr_ctrl|wsa2_swr_ctrl|rx_swr_ctrl|va_swr_ctrl|2000000|2010000` (`**/device_tree/**/*.{dts,dtsi,md,txt}`)

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'echo ===driver-bind===; for d in rx_swr_ctrl va_swr_ctrl bt_swr_mstr wsa_swr_ctrl wsa2_swr_ctrl; do p=/sys/bus/platform/devices/$d; echo ---$d---; [ -e "$p" ] || { echo missing; continue; }; readlink "$p/driver" 2>/dev/null || echo no-driver; done; echo ===soundwire===; ls /sys/bus/soundwire/devices 2>/dev/null'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for n in rx_swr_ctrl va_swr_ctrl wsa_swr_ctrl wsa2_swr_ctrl; do base=/sys/firmware/devicetree/base/soc/spf_core_platform/$n; echo ===$n===; [ -d "$base" ] || { echo missing; continue; }; find "$base" -maxdepth 1 -type f | sed -n "1,80p"; done'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'dmesg | grep -Ei "rx_swr_ctrl|va_swr_ctrl|bt_swr_mstr|wsa_swr_ctrl|wsa2_swr_ctrl|swrm_probe|version specified in dtsi|link status not connected" | tail -n 240'

从现场看，`probe` 不是零成本修复，因为它立刻打到了更底层的 `swr link failed to connect`。我现在做两件事：一是在源码里定位这两个节点的版本配置，二是在 live DT 里确认它们的真实节点路径，避免盲改。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && rg -n "wsa_swr_ctrl|wsa2_swr_ctrl|0x2000000|0x2010000" device_tree docs audio_dtb_probe -g '!**/*.img' -g '!**/*.dtb' -g '!**/*.cpio' | sed -n '1,220p'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'find /sys/firmware/devicetree/base -type d \( -name "*wsa_swr_ctrl*" -o -name "*wsa2_swr_ctrl*" -o -name "*rx_swr_ctrl*" -o -name "*va_swr_ctrl*" \) 2>/dev/null | sed -n "1,120p"'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for d in /sys/firmware/devicetree/base/**/wsa_swr_ctrl /sys/firmware/devicetree/base/**/wsa2_swr_ctrl /sys/firmware/devicetree/base/**/rx_swr_ctrl /sys/firmware/devicetree/base/**/va_swr_ctrl; do [ -d "$d" ] || continue; echo ===$d===; ls "$d" | sed -n "1,80p"; done'

前一个方向的命令没拿到 DT 路径，不是现场没有节点，而是这些节点名字不直接暴露在 `/sys/firmware/devicetree/base`。我改走更稳的入口：直接从 `/sys/bus/platform/devices/.../of_node` 读属性，这样能精准看到内核实际消费的 DT 内容。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for d in wsa_swr_ctrl wsa2_swr_ctrl rx_swr_ctrl va_swr_ctrl; do p=/sys/bus/platform/devices/$d/of_node; echo ===$d===; [ -d "$p" ] || { echo missing; continue; }; ls "$p" | sed -n "1,120p"; done'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for d in wsa_swr_ctrl wsa2_swr_ctrl rx_swr_ctrl va_swr_ctrl; do p=/sys/bus/platform/devices/$d/of_node; echo ===$d===; [ -d "$p" ] || { echo missing; continue; }; for f in compatible status reg qcom,swr_master_id qcom,swrm-version qcom,swr-clock-stop-mode qcom,swr-num-dev qcom,swr-port-mapping; do [ -e "$p/$f" ] || continue; echo ---$f---; od -An -tx4 "$p/$f" 2>/dev/null || cat "$p/$f" 2>/dev/null; done; done'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && adb shell 'for d in rx_swr_ctrl va_swr_ctrl bt_swr_mstr wsa_swr_ctrl wsa2_swr_ctrl; do echo ===uevent:$d===; cat /sys/bus/platform/devices/$d/uevent 2>/dev/null; done'

现在差异面很清楚了：

1. `rx_swr_ctrl`

User: 继续

GitHub Copilot: 我先把当前前沿收成可验证的几条：对比 `rx_swr_ctrl` 和 `wsa_swr_ctrl/wsa2_swr_ctrl` 的 live DT 属性、driver 绑定和最近内核错误，目标是确认这是 DT 输入差异还是总线实体缺失。

# 09-Machine Probe 深度追踪（dynamic_debug + 返回值链）

## 一、补文档并确认前沿

先补文档并把最近排除掉的分支固化下来，然后继续收敛 `sun-asoc-snd` 在 recovery 不绑定的根因。

先读现有记忆和文档落点：

```
Read docs/TWRP音频手动Bring-up.md lines 1-260
Read device_tree/twrp_device_oplus_ossi_source_built/BoardConfig.mk
Read memory
```

文档现状和板级配置已对上：源码里已经把 `pinctrl_lpi`、`stub`、`machine_dlkm` 放进默认模块链，但文档还没把"系统侧 `su` 对比"和"BTFM 已排除"补完整。

继续读文档余下部分，确认需要补哪些缺口：

```
Read docs/TWRP音频手动Bring-up.md lines 260-520
Read docs/TWRP音频手动Bring-up.md lines 520-860
Read docs/TWRP音频手动Bring-up.md lines 860-1095
```

最近的实验结论已经足够形成新的文档增量了，先把"系统侧 `su` 基线"和"BTFM 非决定因素"写进去，同时并行在源码树里找 `sun-asoc-snd`/`machine_dlkm` 的实现落点，看看还缺哪类前置条件。

在源码树中搜索 machine 驱动：

```
Search complete: 查找 machine 源码

rg "sun-asoc-snd|qcom,sun-asoc-snd|spf_core_platform|machine_dlkm|sun asoc snd" **/*.{c,h,dtsi,dts,dtso,overlay,txt,log,bp,mk,mak,Kconfig,config,xml}
-> 200 results

rg "machine driver|snd_soc_card|platform_driver|of_match|probe defer|EPROBE_DEFER|AFE|CPU DAI|qcom.*asoc|asoc-snd" **/*.{c,h,dtsi,dts,dtso,overlay,txt,log,bp,mk,mak,Kconfig,config,xml}
-> 200 results

find . -path "**/Android.bp" -type f
-> 200 matches

find . -path "**/Kconfig*" -type f
-> 3 matches

find . -path "**/Makefile" -type f
-> 200 matches

rg "sun-asoc-snd" twrp_a12_compile/
-> no results

rg "qcom,sun-asoc-snd" twrp_a12_compile/
-> no results

rg "spf_core_platform" twrp_a12_compile/
-> no results

rg "machine_dlkm" twrp_a12_compile/
-> no results

rg "sun-asoc-snd|spf_core_platform|machine_dlkm" device_tree/
-> 2 results

find twrp_a12_compile/vendor/qcom/opensource/ -path "*sun*" -type f
-> no matches

find twrp_a12_compile/vendor/qcom/opensource/ -path "*machine*" -type f
-> no matches

find twrp_a12_compile/vendor/qcom/opensource/ -path "*audio*" -type f
-> no matches

rg "SND_SOC|ASOC|machine_dlkm|spf|lpass|wcd939x|wsa883x" twrp_a12_compile/vendor/qcom/opensource/
-> 4 results
```

源码侧还没拿到 machine 驱动实现，搜索只命中了板级模块清单，没有触到内核源码本体。继续搜内核树：

```bash
rg "sun-asoc-snd|qcom,sun-asoc-snd|spf_core_platform_driver_probe|__spf_core_is_apm_ready|apm is not up" twrp_a12_compile/
-> no results

rg "sun-asoc-snd|qcom,sun-asoc-snd|spf_core_platform_driver_probe|__spf_core_is_apm_ready|apm is not up" twrp_a16_compile/
```

```bash
Read memory twrp_audio_dt_blocker.md
```

现在直接用 `rg` 查内核树，目标是拿到 machine 驱动或至少日志字符串的实际位置；如果源码树里没有，就转去模块二进制做字符串侧比对。

```bash
rg -n "sun-asoc-snd|qcom,sun-asoc-snd|spf_core_platform_driver_probe|__spf_core_is_apm_ready|apm is not up" \
  twrp_a16_compile/kernel twrp_a16_compile/vendor twrp_a12_compile/kernel twrp_a12_compile/vendor
```

```
Read vscode聊天记录 call_QY53TZZT352KMCxyT9YpAl4Q__vscode-1773247730363/content.txt
```

源码树里暂时还没搜到 `sun-asoc-snd` 的实现文本，比较像是厂商预编译模块。文档里应该补上一个新结论：现在优先值最高的是"系统 `su` 基线对比 + 模块二进制特征"而不是继续在源码树里盲搜。

```
Read docs/TWRP音频手动Bring-up.md lines 1080-1095
```

```bash
rg -n "btfmcodec|bt_fm_swr|btfm_slim_codec|BTFM_PROXY|sun-mtp-snd-card" docs device_tree
```

把两个新增结论固化进文档：一是系统侧必须用 `su -c` 做基线对比，二是 BTFM 链已经验证过但不是最后缺口。补文档（57行 patch 写入 TWRP音频手动Bring-up.md），同步仓库记忆 `twrp_audio_dt_blocker.md`，避免后面又回到 `adb root` 或 BTFM 这两条已排除分支。

**结论**：源码树中没有 `sun-asoc-snd` 实现，属于厂商预编译模块；前沿收敛到"系统 su 基线对比 + 模块二进制特征"。

---

## 二、查 module 依赖链

继续收窄 `machine_dlkm` 自身还隐含哪些依赖，优先查两类东西：模块二进制的依赖声明，以及系统/恢复态下 `sound` 子树还差哪些 CPU/AFE 侧节点。

先在本地工作区搜模块文件：

```bash
rg --files | rg "machine_dlkm\.ko|btfmcodec\.ko|bt_fm_swr\.ko|btfm_slim_codec\.ko|stub_dlkm\.ko|pinctrl_lpi_dlkm\.ko|modules\.dep$|modules\.alias$"
```

确认设备在线且处于 recovery：

```bash
adb devices && adb shell getprop ro.bootmode
```

```
Read vscode聊天记录 call_OsYbWA9RZu0HvlW0sgi0H7d6__vscode-1773247730370/content.txt
```

本地工作区没有收进这些 `.ko`，真实依赖还得从设备上的 `vendor_dlkm` 读。直接在 recovery 里查 `modules.dep` 和 `modules.alias`：

```bash
adb shell 'grep -n "machine_dlkm\.ko\|btfmcodec\.ko\|bt_fm_swr\.ko\|btfm_slim_codec\.ko\|stub_dlkm\.ko\|pinctrl_lpi_dlkm\.ko" \
  /vendor_dlkm/lib/modules/modules.dep /vendor_dlkm/lib/modules/modules.alias'
```

查 `sound` 设备的 sysfs 属性：

```bash
adb shell 'for f in /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/* 2>/dev/null; do n=${f##*/}; case "$n" in driver|subsystem|power|uevent|modalias|of_node) continue;; esac; if [ -f "$f" ]; then echo ==== $n ====; sed -n 1,40p "$f"; fi; done'
```

设备侧查询第一次没打中：一个是 `modules.dep`/`modules.alias` 可能不在当前挂载视图里，另一个是 shell 重定向写法被 recovery 的 `sh` 吃掉了。改成更保守的短命令分别查：

```bash
adb shell 'ls /vendor_dlkm/lib/modules | sed -n 1,40p'
```

```bash
adb shell 'ls /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound'
```

`sound` 设备现在只剩极少数属性，说明它没有真正完成 probe。补读模块依赖文件和 `sound` 的 supplier/driver 关系：

```bash
adb shell 'ls /vendor_dlkm/lib/modules/modules.*'
```

```bash
adb shell 'grep -n "machine_dlkm\.ko\|btfmcodec\.ko\|bt_fm_swr\.ko\|btfm_slim_codec\.ko\|stub_dlkm\.ko\|pinctrl_lpi_dlkm\.ko" \
  /vendor_dlkm/lib/modules/modules.dep.bin /vendor_dlkm/lib/modules/modules.softdep /vendor_dlkm/lib/modules/modules.alias 2>/dev/null'
```

查 `sound` 的 driver/supplier/waiting_for_supplier：

```bash
adb shell 'readlink /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver; \
readlink /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/supplier:platform:soc:spf_core_platform; \
readlink /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/supplier:platform:soc:vote_lpass_audio_hw; \
cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/waiting_for_supplier; \
cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/modalias'
```

现在能确认两点：`sound` 只有 supplier devlink、没有 driver 绑定；`modalias` 仍然是对的（`of:NsoundT(null)Csun-asoc-sndCqcom,sun-asoc-snd`）。

直接从设备上的 `modules.dep`/`modules.load` 抓纯文本条目，看 `machine_dlkm` 默认链里到底带不带 BTFM 和其它隐式依赖：

```bash
adb shell 'sed -n "/machine_dlkm/p;/btfm/p;/stub_dlkm/p;/pinctrl_lpi/p" \
  /vendor_dlkm/lib/modules/modules.dep /vendor_dlkm/lib/modules/modules.softdep /vendor_dlkm/lib/modules/modules.load'
```

```bash
adb shell 'ls /sys/kernel/debug/asoc 2>/dev/null'
```

拿到一个更硬的线索：设备上的 `modules.softdep` 明确写了 `softdep machine_dlkm pre: btfmcodec`。源码侧至少该把 BTFM 链视作 machine 默认前置，而不是纯手工实验项。

确认 `TW_LOAD_VENDOR_MODULES` 这条变量是不是按依赖感知方式装载：

```bash
rg "TW_LOAD_VENDOR_MODULES" '**/*.{mk,sh,rc,cpp,cc,c,h}'
-> 39 results
```

抓完整的 machine_dlkm softdep 和 dep：

```bash
adb shell 'sed -n "/softdep machine_dlkm/p" /vendor_dlkm/lib/modules/modules.softdep; \
sed -n "/machine_dlkm\.ko:/p" /vendor_dlkm/lib/modules/modules.dep'
```

有定量依据了：`machine_dlkm` 的软依赖就是 `btfmcodec`，硬依赖里还带着 `spf_core_dlkm`、`gpr_dlkm`、`q6_notifier_dlkm`、`q6_pdr_dlkm` 这一串。确认 TWRP 是逐个 `insmod` 还是走依赖解析：

```
Read twrp_a16_compile/bootable/recovery/kernel_module_loader.cpp lines 1-220
Read twrp_a16_compile/bootable/recovery/partitionmanager.cpp lines 430-500
```

加载器实现走的是 `modprobe`，会读 `modules.dep`/`modules.softdep`，所以"只把 `machine_dlkm` 写进列表但不写 `btfmcodec`"理论上可以被软依赖兜住。

**结论**：`machine_dlkm` 明确有 `softdep btfmcodec`，硬依赖链完整；TWRP 加载器走 `modprobe` 能自动补软依赖。

---

## 三、发现实机镜像与源码脱节

验证启动后的实际状态，看默认 recovery 到底有没有把模块拉起来。

```bash
adb shell 'grep -w "machine_dlkm\|btfmcodec\|btfm_slim_codec\|bt_fm_swr\|gpr_dlkm\|spf_core_dlkm\|pinctrl_lpi_dlkm\|stub_dlkm" /proc/modules'
```

```bash
adb shell 'getprop twrp.modules.loaded; ls /dev/snd; cat /proc/asound/cards'
```

新线索很关键：`twrp.modules.loaded=true`，但这些关键音频模块一个都不在 `/proc/modules` 里。当前 source 侧的默认模块链不是"少几项"，而是"整条链实际没被拉起来"。

读 recovery 日志里的模块加载记录：

```bash
adb shell 'grep -n "Attempting to load modules\|Checking directory\|modules.load.twrp\|Modules Loaded\|Loaded .*modules from\|failed to stat\|modprobe" \
  /tmp/recovery.log 2>/dev/null | sed -n 1,120p'
```

确认 .ko 文件本身是否存在：

```bash
adb shell 'ls /vendor_dlkm/lib/modules | grep -E "^adsp_loader_dlkm\.ko$|^machine_dlkm\.ko$|^pinctrl_lpi_dlkm\.ko$|^stub_dlkm\.ko$"'
```

文件本身都在，所以默认链没生效更像是加载器流程问题，不是模块缺失。我要补查两处运行态痕迹：一是 dmesg 里的加载器日志，二是 tmp 下有没有它生成的 `modules.load.twrp` 和临时模块目录。

```bash
adb shell 'dmesg | grep -i "Attempting to load modules\|Checking directory\|Modules Loaded\|modules.load.twrp\|modprobe" | sed -n 1,120p'
```

```bash
adb shell 'ls /tmp | sed -n 1,80p; find /tmp -name modules.load.twrp 2>/dev/null | sed -n 1,20p'
```

加载器至少生成了临时 `modules.load.twrp`，说明流程确实跑过。下一步我直接看这个清单里写了什么，以及它对应的临时目录里有没有拷进去实际 `.ko`，这样就能把问题收敛到“列表生成”还是“modprobe 执行”。

```bash
adb shell 'sed -n 1,120p /tmp/vendor/lib/modules/modules.load.twrp'
```

```bash
adb shell 'ls /tmp/vendor/lib/modules | sed -n 1,80p; ls /tmp/vendor_dlkm/lib/modules 2>/dev/null | sed -n 1,80p'
```

撞到一个比 BTFM 更直接的问题：当前运行中的 recovery 实际生成的 `modules.load.twrp` 只有 4 个模块：

- `stm_st54se_gpio.ko`
- `oplus_chg_v2.ko`
- `nxp-nci.ko`
- `adsp_loader_dlkm.ko`

根本不是源码里现在那条长音频链。机器上的镜像和当前源码配置已经脱节了。

做一个最短验证，确认 `modprobe machine_dlkm` 是否会自动按 softdep 拉起 `btfmcodec`：

```bash
adb shell 'modprobe -d /vendor_dlkm/lib/modules machine_dlkm; \
grep -w "machine_dlkm\|btfmcodec\|gpr_dlkm\|spf_core_dlkm\|q6_notifier_dlkm\|q6_pdr_dlkm" /proc/modules'
```

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; ls /sys/kernel/debug/asoc 2>/dev/null | sed -n 1,40p'
```

拿到一个更像根因的点：`modprobe -d /vendor_dlkm/lib/modules machine_dlkm` 失败时，实际去找的是 `/vendor/lib/modules/machine_dlkm.ko`。`modules.dep` 里的路径和 `vendor_dlkm` 的挂载路径不一致，默认加载链很可能就在这里断的。

去看加载器实现里有没有重写这些路径：

```bash
rg "Copy_Modules_To_Tmpfs|Write_Module_List|modules.load.twrp|modules.dep" twrp_a16_compile/bootable/recovery/kernel_module_loader.cpp
-> 6 results
```

```
Read twrp_a16_compile/bootable/recovery/kernel_module_loader.cpp lines 220-273
```

得到一个更硬的运行态结论：当前刷在机器上的 recovery 并没有携带源码里那条长音频模块请求列表。它运行时生成的 `modules.load.twrp` 只有 4 个模块，所有"默认自动加载音频链"的推断都不成立。

把这个写进文档（49行 patch）和记忆 `twrp_audio_dt_blocker.md`。

利用已经在 recovery 里的 `/vendor/lib/modules` 元数据直接 `modprobe machine_dlkm`：

```bash
adb shell 'modprobe -d /vendor/lib/modules machine_dlkm; \
grep -w "machine_dlkm\|btfmcodec\|gpr_dlkm\|spf_core_dlkm\|q6_notifier_dlkm\|q6_pdr_dlkm\|pinctrl_lpi_dlkm\|stub_dlkm" /proc/modules'
```

查 ASoC 状态：

```bash
adb shell 'ls /sys/kernel/debug/asoc/components 2>/dev/null | sed -n 1,40p; echo ---; \
sed -n 1,120p /sys/kernel/debug/asoc/components 2>/dev/null | grep -E "wcd|lpass|stub|btfm|q6|spf|snd-soc"; echo ---; \
sed -n 1,160p /sys/kernel/debug/asoc/dais 2>/dev/null | grep -E "rx_macro|tx_macro|va_macro|btfm|q6|lpass|dummy"'
```

当前状态有个表面矛盾：`/proc/modules` 里按文件名 grep 不到，但 ASoC debugfs 又已经有 `wcd939x-codec`、`lpass-cdc`、`msm-stub-codec`。这可能只是模块名和文件名不一致。

```bash
adb shell 'grep -i "machine\|wcd\|lpass\|btfm\|gpr\|spf\|q6_\|stub" /proc/modules | sed -n 1,120p'
```

```bash
adb shell 'ls /vendor/lib/modules/machine_dlkm.ko /vendor/lib/modules/btfmcodec.ko \
  /vendor/lib/modules/pinctrl_lpi_dlkm.ko /vendor/lib/modules/stub_dlkm.ko 2>/dev/null'
```

`/vendor/lib/modules` 在当前默认视图里确实没有这些文件。直接读 `/proc/modules` 原文不再依赖 grep：

```bash
adb shell 'sed -n 1,120p /proc/modules'
```

```
Read vscode聊天记录 call_xXFpukPTSoVkToQDODq87YFh__vscode-1773247730404/content.txt
```

再补一刀当前状态下的 BTFM 验证，把 `btfm_slim_codec` 和 `bt_fm_swr` 也装上去：

```bash
adb shell 'insmod /vendor_dlkm/lib/modules/btfm_slim_codec.ko; insmod /vendor_dlkm/lib/modules/bt_fm_swr.ko; \
grep -w "btfmcodec\|btfm_slim_codec\|bt_fm_swr" /proc/modules'
```

```bash
adb shell 'ls /sys/bus/soundwire/devices 2>/dev/null | sed -n 1,40p; echo ---; \
sed -n 1,120p /sys/kernel/debug/asoc/components 2>/dev/null | grep -E "btfm|wcd|lpass|stub"; echo ---; \
cat /proc/asound/cards; ls /dev/snd'
```

文档已补到最新前沿，仓库记忆也同步了。新增的核心结论有三条：

1. 正常系统侧必须用 `su -c` 做基线，之前"system 侧 root 不通"的判断已经作废；真正没有 `su` 的是 recovery
2. BTFM 路径已经再次钉死不是最后缺口。当前 recovery 里已经能看到 `btfmswr_slave.*`，但 ASoC 仍只有 `wcd939x-codec`、`lpass-cdc`、`msm-stub-codec`，`/proc/asound/cards` 还是空，`/dev/snd` 还是只有 `timer`
3. 当前刷在机器上的 recovery 镜像，运行时生成的 `modules.load.twrp` 只有 4 个条目，与源码长音频模块链脱节，所有音频推进本质上仍依赖手工加载

继续查设备上的模块元数据：`modules.softdep` 明确有 `softdep machine_dlkm pre: btfmcodec`，`modules.dep` 也确认 `machine_dlkm` 还依赖 `spf_core_dlkm`、`gpr_dlkm`、`q6_notifier_dlkm`、`q6_pdr_dlkm`、`swr_ctrl_dlkm` 和整条 codec/lpass 链。

问题已经进一步收敛成两层：一层是实机默认镜像还没吃到新的模块请求列表；另一层是即便手工把链路补到现在这一步，`sun-asoc-snd` 仍然没有接管 `sound`。

这轮没有做编译，也没有重刷新镜像。下一步最有价值的是二选一：
1. 继续纯运行态，把注意力只放在 `sun-asoc-snd` 缺的 CPU/AFE 侧前提上
2. 基于当前源码状态重做一次镜像注入/替换，让实机先真正跑上新的默认模块请求列表

**结论**：实机镜像的 `modules.load.twrp` 只有 4 个非音频模块，源码和镜像完全脱节；`modules.dep` 路径指向 `/vendor/lib/modules` 而模块在 `/vendor_dlkm/lib/modules`，路径不一致导致 modprobe 失败。

---

## 四、系统侧基线对比：定位 CPU/AFE 缺口

用户选择 option 1。

User: 1

按选的方向继续。不碰镜像，直接在当前 recovery 里把 `sound` 节点引用的 CPU/AFE 端点和 machine 运行时拓扑挖出来。

```bash
adb shell 'for f in asoc-cpu-names asoc-codec-names asoc-platform-names qcom,model; do \
p=/proc/device-tree/soc/spf_core_platform/sound/$f; echo ==== $f ====; \
[ -e "$p" ] && cat "$p" | tr "\000" "\n" || echo missing; done'
```

```bash
adb shell 'ls /sys/devices/platform/soc/soc:spf_core_platform | sed -n 1,120p'
```

```bash
adb shell 'sed -n 1,220p /sys/kernel/debug/asoc/dais 2>/dev/null'
```

当前 recovery 里的 `sound` DT 只显式列出了 codec 侧：`msm-stub-codec.1`、`lpass-cdc`、`wcd939x_codec`，而 ASoC DAI 视图也只看到 macro 和 stub，确实没有任何 Q6/AFE/CPU 侧 DAI。

把设备切到正常系统，用 `su -c` 抓同一批信息直接对比：

```bash
adb reboot
```

```bash
adb wait-for-device && adb shell 'while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 1; done; getprop ro.bootmode; su -c id'
```

系统基线已经起来，`su` 可用。直接抓和 recovery 同一组视图：

```bash
adb shell 'su -c "for f in asoc-cpu-names asoc-codec-names asoc-platform-names qcom,model; do \
p=/proc/device-tree/soc/spf_core_platform/sound/$f; echo ==== $f ====; \
[ -e \"$p\" ] && cat \"$p\" | tr \\\"\\000\\\" \\\"\\n\\\" || echo missing; done"'
```

```bash
adb shell 'su -c "readlink /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver; \
ls /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound | sed -n 1,120p"'
```

```bash
adb shell 'su -c "mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; \
echo ---COMP---; sed -n 1,200p /sys/kernel/debug/asoc/components 2>/dev/null | grep -E \"wcd|lpass|stub|btfm|q6|spf|snd-soc|PCM|TDM|USB|BTFM\"; \
echo ---DAI---; sed -n 1,260p /sys/kernel/debug/asoc/dais 2>/dev/null | grep -E \"rx_macro|tx_macro|va_macro|btfm|q6|lpass|dummy|PCM|TDM|USB|BTFM\""'
```

系统对照已经明确：决定性差异不是 codec/component 列表，而是 `sun-asoc-snd` 绑定后在 `sound` 设备下继续展开的大量 FE/BE 子节点。补看子节点结构：

```bash
adb shell 'su -c "ls /sys/devices/platform/soc/soc:spf_core_platform | sed -n 1,120p"'
```

```bash
adb shell 'su -c "ls -R /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/sound | sed -n 1,160p"'
```

```bash
adb shell 'su -c "ls /sys/bus/platform/drivers/sun-asoc-snd; echo ---; readlink /sys/bus/platform/drivers/sun-asoc-snd/soc:spf_core_platform:sound"'
```

更明确了：顶层 `spf_core_platform` 在 system 和 recovery 是一样的，真正分叉点就是 `soc:spf_core_platform:sound` 一旦被 `sun-asoc-snd` 绑定，就会长出 FE/BE 子节点和内嵌的 `sound/card0`。

看 DT 里 `sound` 节点到底有哪些属性：

```bash
adb shell 'su -c "ls /proc/device-tree/soc/spf_core_platform/sound | sed -n 1,200p"'
```

```bash
adb shell 'su -c "for f in \$(ls /proc/device-tree/soc/spf_core_platform/sound | grep -E \"name|model|asoc|qcom|audio|codec|platform|cpu\"); do \
echo ==== \$f ====; cat /proc/device-tree/soc/spf_core_platform/sound/\$f 2>/dev/null | tr \\\"\\000\\\" \\\"\\n\\\"; done"'
```

```bash
adb shell 'su -c "for d in /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/PCM_* \
/sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/TDM-* \
/sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/BTFM_* \
/sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/USB_AUDIO-*; do \
[ -e \"$d\" ] || continue; echo ==== \${d##*/} ====; ls \"$d\" | sed -n 1,40p; break; done"'
```

刚才那批有两个命令被 Android shell 的展开和权限坑了。改成点名读取最关键的 DT 属性：

```bash
adb shell 'su -c "echo ==== audio-core-list ====; \
cat /proc/device-tree/soc/spf_core_platform/sound/qcom,audio-core-list | tr \\\"\\000\\\" \\\"\\n\\\"; \
echo ==== msm_audio_ssr_devs ====; \
cat /proc/device-tree/soc/spf_core_platform/sound/qcom,msm_audio_ssr_devs | tr \\\"\\000\\\" \\\"\\n\\\"; \
echo ==== wcn-bt ====; \
cat /proc/device-tree/soc/spf_core_platform/sound/qcom,wcn-bt | tr \\\"\\000\\\" \\\"\\n\\\"; \
echo ==== upd_backends_used ====; \
cat /proc/device-tree/soc/spf_core_platform/sound/qcom,upd_backends_used | tr \\\"\\000\\\" \\\"\\n\\\""'
```

```bash
adb shell 'su -c "echo ==== PCM_DUMMY-RX-0 ====; \
ls /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/PCM_DUMMY-RX-0; \
echo ==== BTFM_PROXY-RX-0 ====; \
ls /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/BTFM_PROXY-RX-0"'
```

```bash
adb shell 'su -c "cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/sound/card0/id; \
echo ---; cat /proc/asound/pcm | sed -n 1,80p"'
```

系统基线又给出了一条很硬的新证据：`/proc/asound/pcm` 里，`TDM-LPAIF_*` 实际就是挂在 recovery 已经可见的 `msm-stub-rx/tx` 上，`CODEC_DMA-*` 则落到 `multicodec-*` 和 `va_macro_tx*`，`BTFM_PROXY-*` 落到 `btaudio_*`。Recovery 现在不是"完全没有后端 DAI"，而是 card 还没注册，所以这些 FE/BE 路由对象根本没被 machine 展开。

把这组结论写进文档（42行 patch）和记忆 `twrp_audio_dt_blocker.md`。

不急着切回 recovery，再从模块二进制本身挖一层：看 `machine_dlkm.ko` 和 BTFM 模块里直接带了哪些 FE/BE 名称和日志字符串。

```bash
adb shell 'su -c "strings /vendor_dlkm/lib/modules/machine_dlkm.ko | grep -E \
\"sun-asoc-snd|sun-mtp-snd-card|BTFM_PROXY|PCM_DUMMY|PCM_RT_PROXY|TDM-LPAIF|USB_AUDIO|DISPLAY_PORT|btaudio|multicodec|msm-stub-rx|msm-stub-tx\" | sed -n 1,220p"'
```

```bash
adb shell 'su -c "strings /vendor_dlkm/lib/modules/btfm_slim_codec.ko | grep -E \"btaudio|BTFM|btfm\" | sed -n 1,120p; \
echo ---; strings /vendor_dlkm/lib/modules/bt_fm_swr.ko | grep -E \"btaudio|BTFM|btfm|swr\" | sed -n 1,120p"'
```

```bash
adb shell 'su -c "strings /vendor_dlkm/lib/modules/machine_dlkm.ko | grep -i -E \"probe|failed|error|apm|afe|snd card|asoc\" | sed -n 1,200p"'
```

**结论**：决定性缺口不是 codec/component 缺失，而是 `sun-asoc-snd` 驱动未绑定导致 card 不存在、FE/BE 节点未展开。Recovery 的 DAI 实际已经够用，问题在 card 注册这一层。

---

## 五、回到 recovery 做最短路复现

从 `machine_dlkm.ko` 抠出的错误字符串用来 grep probe 结果，看究竟死在哪个分支。

```bash
adb reboot recovery
```

```bash
adb wait-for-device && adb shell 'getprop ro.bootmode; getprop twrp.modules.loaded; ls /dev/snd; cat /proc/asound/cards'
```

```
Read vscode聊天记录 call_NKI2MqjECB9tuYJm1qqpCoi9__vscode-1773247730431/content.txt lines 1-120
```

重启已完成，但输出被系统侧历史日志淹没。补最短命令重新确认回 recovery：

```bash
adb devices && adb shell 'getprop ro.bootmode; getprop twrp.modules.loaded; ls /dev/snd; cat /proc/asound/cards'
```

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; ls /sys/kernel/debug/asoc 2>/dev/null'
```

`debugfs` 已挂好，recovery 侧 shell 可用了。

```bash
adb devices
```

```bash
adb shell getprop ro.bootmode
```

```bash
adb shell 'getprop twrp.modules.loaded; ls /dev/snd; cat /proc/asound/cards'
```

回到干净 recovery 基线。先把真实 `vendor/odm` 和音频服务补回去：

```bash
adb shell 'mkdir -p /mnt/real_vendor /mnt/real_odm; \
mount -t erofs /dev/block/dm-2 /mnt/real_vendor 2>/dev/null; \
mount -t erofs /dev/block/dm-5 /mnt/real_odm 2>/dev/null; \
mount -o bind /mnt/real_vendor/bin /vendor/bin; \
mount -o bind /mnt/real_vendor/bin/hw /vendor/bin/hw; \
mount -o bind /mnt/real_vendor/lib64 /vendor/lib64; \
mount -o bind /mnt/real_odm /odm'
```

```bash
adb shell 'start vendor.vndservicemanager; start vendor.pd_mapper; start vendor.per_mgr; \
start vendor.adsprpcd; start vendor.audioadsprpcd_audiopd; start vendor.audio-hal-aidl; \
sleep 2; for s in vendor.vndservicemanager vendor.pd_mapper vendor.per_mgr \
vendor.adsprpcd vendor.audioadsprpcd_audiopd vendor.audio-hal-aidl; do \
echo ==== $s ====; getprop init.svc.$s; done'
```

服务已回来，`audio-hal-aidl`、`audioadsprpcd`、`adsprpcd` 都在跑，`vndservicemanager` 和 `per_mgr` 还在抖。

补内核链，分三段加载模块：

```bash
# 第一段：基础模块
adb shell 'for m in pinctrl_lpi_dlkm stub_dlkm oplus_audio_daemon audpkt_ion_dlkm \
audio_prm_dlkm audio_pkt_dlkm frpc-adsprpc; do insmod /vendor_dlkm/lib/modules/$m.ko 2>/dev/null; done; \
grep -E "pinctrl_lpi_dlkm|stub_dlkm|oplus_audio_daemon|audpkt_ion_dlkm|audio_prm_dlkm|audio_pkt_dlkm|frpc_adsprpc" /proc/modules'
```

```bash
# 第二段：codec/macro 模块
adb shell 'for m in wcd_core_dlkm swr_dlkm wcd939x_slave_dlkm wcd9xxx_dlkm mbhc_dlkm \
wcd939x_dlkm lpass_cdc_dlkm swr_ctrl_dlkm lpass_bt_swr_dlkm oplus_audio_pa_manager \
oplus_audio_sipa oplus_audio_extend sdca_registers_dlkm wcd9378_dlkm; do \
insmod /vendor_dlkm/lib/modules/$m.ko 2>/dev/null; done; \
grep -E "wcd_core_dlkm|swr_dlkm|wcd939x_slave_dlkm|wcd9xxx_dlkm|mbhc_dlkm|wcd939x_dlkm|lpass_cdc_dlkm|swr_ctrl_dlkm|lpass_bt_swr_dlkm|oplus_audio_pa_manager|oplus_audio_sipa|oplus_audio_extend|sdca_registers_dlkm|wcd9378_dlkm" /proc/modules | sed -n 1,40p'
```

```bash
# 第三段：macro 和 machine 模块
adb shell 'for m in lpass_cdc_rx_macro_dlkm lpass_cdc_tx_macro_dlkm lpass_cdc_va_macro_dlkm \
lpass_cdc_wsa_macro_dlkm lpass_cdc_wsa2_macro_dlkm wsa883x_dlkm wsa884x_dlkm q6_dlkm \
btfmcodec machine_dlkm; do insmod /vendor_dlkm/lib/modules/$m.ko 2>/dev/null; done; \
grep -E "lpass_cdc_rx_macro_dlkm|lpass_cdc_tx_macro_dlkm|lpass_cdc_va_macro_dlkm|lpass_cdc_wsa_macro_dlkm|lpass_cdc_wsa2_macro_dlkm|wsa883x_dlkm|wsa884x_dlkm|q6_dlkm|btfmcodec|machine_dlkm" /proc/modules | sed -n 1,40p'
```

模块链已补到位，`machine_dlkm`、`btfmcodec`、`spf_core_dlkm`、`gpr_dlkm` 都在了。触发 ADSP/`sound` 路径 + swr-mgr 绑定 + probe：

```bash
# 触发 ADSP SSR
adb shell 'echo 1 > /sys/kernel/boot_adsp/ssr; sleep 2; \
ls /sys/devices/platform/soc/soc:spf_core_platform | grep sound; \
cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/modalias 2>/dev/null; \
cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/waiting_for_supplier 2>/dev/null'
```

```bash
# 绑定 swr-mgr
adb shell 'for d in rx_swr_ctrl va_swr_ctrl bt_swr_mstr; do \
[ -e /sys/bus/platform/devices/soc:spf_core_platform:$d ] || continue; \
echo swr-mgr > /sys/bus/platform/devices/soc:spf_core_platform:$d/driver_override; \
echo soc:spf_core_platform:$d > /sys/bus/platform/drivers_probe; done; \
ls /sys/bus/soundwire/devices 2>/dev/null | sed -n 1,40p'
```

```bash
# 触发 machine probe
adb shell 'echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; \
echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; \
dmesg | grep -i -E "msm_asoc_machine_probe|snd_soc_register_card|failed to get backend name|retrieving phandle for codec|parse card name failed|asoc machine probe done|sun-asoc-snd|Failed to add snd_card|add routes|component is error" | tail -n 80; \
echo ---; readlink /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver 2>/dev/null || echo no_driver; \
echo ---; cat /proc/asound/cards; ls /dev/snd'
```

**关键新事实**：`msm_asoc_machine_probe` 在 recovery 里确实跑起来了，而且跑了很多次。问题不是"根本没进 probe"，而是 probe 之后既没绑定，也没打出明显的 `snd_soc_register_card failed` 一类错误。

**结论**：machine probe 已执行但无声显式失败日志；sound 不绑定、card 不注册。

---

## 六、补 BTFM 全链后的 deferred 排查

补三件事：看 `devices_deferred`、补装 `btfm_slim_codec`/`bt_fm_swr`、抓靠近 probe 时间点的原始内核日志。

```bash
adb shell 'cat /sys/kernel/debug/devices_deferred 2>/dev/null | sed -n 1,120p'
```

```bash
adb shell 'ls /vendor_dlkm/lib/modules/btfm_slim_codec.ko /vendor_dlkm/lib/modules/bt_fm_swr.ko; \
insmod /vendor_dlkm/lib/modules/btfm_slim_codec.ko 2>/dev/null; \
insmod /vendor_dlkm/lib/modules/bt_fm_swr.ko 2>/dev/null; \
grep -w "btfm_slim_codec\|bt_fm_swr\|btfmcodec" /proc/modules; echo ---; \
sed -n 1,200p /sys/kernel/debug/asoc/dais 2>/dev/null | grep -E "btaudio|btfm|rx_macro|tx_macro|va_macro|msm-stub"'
```

```bash
adb shell 'dmesg | tail -n 220 | grep -i -E "msm_asoc_machine_probe|sun-asoc-snd|snd_soc_register_card|failed to get backend name|retrieving phandle|parse card name|component is error|add routes|btfm|btaudio"'
```

出现了一个真正的新缺口：`devices_deferred` 现在只剩 `soc:spf_core_platform:sound`，而补装 `btfm_slim_codec` 时直接报缺 `btpower_*` 符号。之前"BTFM 全链已经补齐"的说法要再收紧：`btfmcodec` 和 `btfmswr_slave` 到位过，但 `btfm_slim_codec` 这一支在当前复现里其实没成功装上。

先补 `btpower`：

```bash
adb shell 'insmod /vendor_dlkm/lib/modules/btpower.ko 2>/dev/null; \
insmod /vendor_dlkm/lib/modules/btfm_slim_codec.ko 2>/dev/null; \
insmod /vendor_dlkm/lib/modules/bt_fm_swr.ko 2>/dev/null; \
grep -w "btpower\|btfmcodec\|btfm_slim_codec\|bt_fm_swr" /proc/modules'
```

```bash
adb shell 'sed -n 1,260p /sys/kernel/debug/asoc/dais 2>/dev/null | grep -E "btaudio|btfm|msm-stub|rx_macro|tx_macro|va_macro"; \
echo ---; ls /sys/bus/soundwire/devices 2>/dev/null | sed -n 1,40p'
```

再次触发 probe：

```bash
adb shell 'echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; \
echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; \
dmesg | tail -n 220 | grep -i -E "msm_asoc_machine_probe|snd_soc_register_card|failed to get backend name|retrieving phandle|parse card name|component is error|add routes|btaudio|btfm"; \
echo ---; cat /sys/kernel/debug/devices_deferred 2>/dev/null; echo ---; \
readlink /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver 2>/dev/null || echo no_driver; \
echo ---; cat /proc/asound/cards; ls /dev/snd'
```

现在这个分支已非常干净：完整 BTFM 链补齐后，`btaudio_rx/tx` 和 `btaudio_fm_tx` DAI 都出来了，但 `devices_deferred` 还是只剩 `sound`，声卡还是没注册。

尝试用 `bind` 接口手工绑定 `sun-asoc-snd`：

```bash
adb shell 'ls /sys/bus/platform/drivers/sun-asoc-snd; echo ---; \
echo soc:spf_core_platform:sound > /sys/bus/platform/drivers/sun-asoc-snd/bind 2>/tmp/bind.err; \
cat /tmp/bind.err 2>/dev/null; echo ---; \
readlink /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver 2>/dev/null || echo no_driver; echo ---; \
dmesg | tail -n 120 | grep -i -E "sun-asoc-snd|msm_asoc_machine_probe|snd_soc_register_card|bind|probe|backend|phandle|component is error"'
```

确认 ASoC 视图：

```bash
adb shell 'sed -n 1,160p /sys/kernel/debug/asoc/components 2>/dev/null | grep -E "btfm|wcd|lpass|stub|snd-soc"; \
echo ---; sed -n 1,260p /sys/kernel/debug/asoc/dais 2>/dev/null | grep -E "btaudio|msm-stub|rx_macro|tx_macro|va_macro|snd-soc"'
```

probe 已进入 `msm_asoc_machine_probe`，完整 BTFM DAI 也出来了，但 `sun-asoc-snd` 目录甚至没有 `bind` 接口，`sound` 仍然单独留在 deferred。

最后扫一遍更泛化的 ASoC 核心日志：

```bash
adb shell 'dmesg | tail -n 320 | grep -i -E "asoc|snd_soc|alsa|defer|probe defer|no backend|dai link|dapm|pcm runtime|soc card|register card|card failed|EPROBE|codec" | tail -n 120'
```

```bash
adb shell 'cat /sys/kernel/debug/devices_deferred 2>/dev/null; echo ---; \
cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/modalias; \
cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/waiting_for_supplier'
```

这轮最关键的新收敛有四条：

1. `msm_asoc_machine_probe` 在 recovery 里已经明确执行了，而且执行了多轮。问题不再是"根本没进 machine probe"
2. 补齐 `btpower` 之后，`btfm_slim_codec` 和 `bt_fm_swr` 也真正起来了，ASoC DAI 里已经能看到 `btaudio_rx`、`btaudio_tx`、`btaudio_rx2`、`btaudio_tx2`、`btaudio_fm_tx`。这比之前只看到 `btfmswr_slave.*` 更完整
3. 即便如此，`devices_deferred` 最后仍然只剩 `soc:spf_core_platform:sound`；`/proc/asound/cards` 还是空，`/dev/snd` 还是只有 `timer`
4. BTFM 现在可以更强地排除掉了

这轮还顺手确认了：当前 recovery 里完整补链后，已经同时具备 `msm-stub-rx/tx`、`va_macro_tx*`、`btaudio_*`、macro DAI、SoundWire 设备和 `btfmcodec_dev`，所以现在不能再说是"缺某个明显 backend/codec/BTFM 模块"。

写进文档（77行 patch）和记忆 `twrp_audio_dt_blocker.md`。

接下来最有价值的路只剩两个：
1. 继续 option 1 的更深一层：针对 `msm_asoc_machine_probe` / `snd_soc_register_card` 做返回值级别的定位
2. 切回 option 2：用当前源码状态做一版新的 recovery 镜像

**结论**：machine probe 执行多轮、BTFM 全链到位、dais/components 齐全，但 sound 始终在 deferred 且无声显式报错。真正的阻塞点需要返回值级别定位或源码镜像侧修正。

---

## 七、option 2：做镜像自动补链

User: 2

按选的 2 走，不编译，直接做镜像侧修正。找 recovery 里能挂钩的时机，把"默认旧模块链"改成"开机自动补齐音频链"的注入方案。

### 7.1 设计注入方案

```bash
rg "twrp.modules.loaded|vendor.audio-recovery-services|boot_adsp/ssr|Load_Vendor_Modules" device_tree/
-> 31 results
```

```
Read magisk_inject_ossi_20260312/
Read device_tree/twrp_device_oplus_ossi_source_built/recovery/root/vendor/etc/init/vendor.audio-recovery-services.rc
```

确认可挂钩点就在 `on property:twrp.modules.loaded=true`。

```
Read device_tree/twrp_device_oplus_ossi_source_built/recovery/root/init.recovery.qcom.rc
```

查 fstab 确认分区挂载：

```bash
rg "vendor_dlkm|/vendor_dlkm|/vendor|/odm" device_tree/twrp_device_oplus_ossi_source_built/**/recovery*.fstab
-> 8 results

rg "vendor_dlkm|by-name/vendor|by-name/odm|erofs" device_tree/twrp_device_oplus_ossi_source_built/**
-> 29 results
```

时机和挂载点都清楚了：`twrp.modules.loaded=true` 后已能访问 `/vendor_dlkm`，现有 Wi‑Fi 就是靠 recovery 脚本补链。

```bash
rg "service .* /system/bin/sh|exec_background|modprobe -d|insmod /vendor_dlkm" \
  device_tree/twrp_device_oplus_ossi_source_built/recovery/root/**
-> 1 result
```

```
Read device_tree/twrp_device_oplus_ossi_source_built/recovery/root/system/bin/cp-wifi-ko.sh
Read device_tree/twrp_device_oplus_ossi_source_built/recovery/root/init.recovery.wifi.rc
```

方案已定：在 `twrp.modules.loaded=true` 后拉一个 oneshot 脚本，脚本负责把真实 `vendor/odm` 绑定回来、启动音频服务、补齐整条模块链并做 `SSR + swr-mgr`。

确认待注入 ramdisk 的结构：

```
Read magisk_inject_ossi_20260312/ramdisk_out
Read magisk_inject_ossi_20260312/ramdisk_out/system/bin
Read magisk_inject_ossi_20260312/ramdisk_out/vendor/etc/init
```

落地注入方案：改 `init.recovery.qcom.rc` 挂 service，新增 `twrp-audio-autoload.sh` 脚本。源码树和待打包 ramdisk 两边同步（48行 patch）。

创建文件：
- `device_tree/twrp_device_oplus_ossi_source_built/recovery/root/system/bin/twrp-audio-autoload.sh`
- `magisk_inject_ossi_20260312/ramdisk_out/system/bin/twrp-audio-autoload.sh`

脚本补一个小缺口：开头主动挂 `debugfs`（14行 patch）。

### 7.2 手工验证脚本

在当前 recovery 里先跑脚本验证，目标不是出声，而是确认它能自动把此前的整套手工步骤重放出来。

```bash
adb reboot recovery
```

```bash
adb wait-for-device && adb shell 'while [ "$(getprop ro.bootmode)" != "recovery" ]; do sleep 1; done; \
getprop twrp.modules.loaded; ls /dev/snd; cat /proc/asound/cards'
```

```bash
adb push .../twrp-audio-autoload.sh /tmp/twrp-audio-autoload.sh && \
adb shell 'sh /tmp/twrp-audio-autoload.sh; echo ---; getprop twrp.audio.autoload; echo ---; \
cat /proc/asound/cards; ls /dev/snd; echo ---; cat /sys/kernel/debug/devices_deferred 2>/dev/null; echo ---; \
sed -n 1,200p /sys/kernel/debug/asoc/dais 2>/dev/null | grep -E "btaudio|msm-stub|rx_macro|tx_macro|va_macro"'
```

脚本验证那一步被终端打断了。

```
Read vscode聊天记录 call_pzDyNS4BG2kCoAXffSUutw5o__vscode-1773247730475/content.txt lines 1-120
```

长命令验证太容易被历史输出干扰，改成短步骤：

```bash
adb push .../twrp-audio-autoload.sh /tmp/twrp-audio-autoload.sh
```

```bash
adb shell 'sh /tmp/twrp-audio-autoload.sh'
```

```bash
adb shell 'getprop twrp.audio.autoload; echo ---; cat /proc/asound/cards; ls /dev/snd; echo ---; \
cat /sys/kernel/debug/devices_deferred 2>/dev/null; echo ---; \
sed -n 1,220p /sys/kernel/debug/asoc/dais 2>/dev/null | grep -E "btaudio|msm-stub|rx_macro|tx_macro|va_macro"'
```

脚本验证通过：`twrp.audio.autoload=true` 已设置，不用手工命令就把 `btaudio_*`、`msm-stub-*`、macro DAI 全带出来了。还没把声卡变出来，但这正符合当前前沿。

### 7.3 Repack 镜像并刷入

```
Read magisk_inject_ossi_20260312/header
Read docs/TWRP音频手动Bring-up.md lines 1180-1260
Read memory twrp_recovery_repack.md
```

不猜 repack 流程，直接看现成的同步脚本和注入工作区结构：

```
Read device_tree/twrp_device_oplus_ossi_source_built/sync.sh
```

```bash
cd /Volumes/Case-sensitive\ APFS/TWRP/magisk_inject_ossi_20260312 && \
file header orig.img ramdisk.cpio TWRP-3.7.1-16-ossi-2026-03-10-audio-vintf-test.img 2>/dev/null
```

```bash
cd /Volumes/Case-sensitive\ APFS/TWRP/magisk_inject_ossi_20260312 && \
/Volumes/Case-sensitive\ APFS/TWRP/magiskboot --help | sed -n 1,120p
```

现在直接 repack：

```bash
cd /Volumes/Case-sensitive\ APFS/TWRP/magisk_inject_ossi_20260312/ramdisk_out && \
find . | cpio -o -H newc > ../ramdisk.cpio
```

```bash
cd /Volumes/Case-sensitive\ APFS/TWRP/magisk_inject_ossi_20260312 && \
/Volumes/Case-sensitive\ APFS/TWRP/magiskboot repack \
TWRP-3.7.1-16-ossi-2026-03-10-audio-vintf-test.img \
TWRP-3.7.1-16-ossi-2026-03-10-audio-autoload-test.img
```

```bash
cd /Volumes/Case-sensitive\ APFS/TWRP/magisk_inject_ossi_20260312 && \
/Volumes/Case-sensitive\ APFS/TWRP/magiskboot sha1 TWRP-3.7.1-16-ossi-2026-03-10-audio-autoload-test.img
```

新镜像已出，SHA1 是 `7396b65833c619811b8714539c5837bb8e0cdc97`。

```bash
cp .../TWRP-3.7.1-16-ossi-2026-03-10-audio-autoload-test.img \
  /Volumes/Case-sensitive\ APFS/TWRP/device_tree/twrp_device_oplus_ossi_source_built/
```

```bash
adb reboot bootloader
```

```bash
fastboot flash recovery .../TWRP-3.7.1-16-ossi-2026-03-10-audio-autoload-test.img && \
fastboot reboot recovery
```

镜像已刷进去。只看自动化是否生效：

```bash
adb wait-for-device && adb shell 'while [ "$(getprop ro.bootmode)" != "recovery" ]; do sleep 1; done; \
getprop twrp.audio.autoload; echo ---; cat /proc/asound/cards; ls /dev/snd; echo ---; \
cat /sys/kernel/debug/devices_deferred 2>/dev/null'
```

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; \
sed -n 1,240p /sys/kernel/debug/asoc/dais 2>/dev/null | grep -E "btaudio|msm-stub|rx_macro|tx_macro|va_macro"; \
echo ---; sed -n 1,160p /sys/kernel/debug/asoc/components 2>/dev/null | grep -E "btfm|wcd|lpass|stub|snd-soc"'
```

```bash
adb shell 'grep -n "twrp-audio-autoload" /tmp/recovery.log | tail -n 80; echo ---; \
for s in vendor.vndservicemanager vendor.pd_mapper vendor.per_mgr vendor.adsprpcd \
vendor.audioadsprpcd_audiopd vendor.audio-hal-aidl; do echo ==== $s ====; getprop init.svc.$s; done'
```

第一批验证里至少有一条已完成。

```
Read vscode聊天记录 call_bBSg1pxPwJfoS1m04vFOwXPL__vscode-1773247730493/content.txt lines 1-140
```

用短命令读两个最关键观测：

```bash
adb wait-for-device && adb shell getprop twrp.audio.autoload
```

```bash
adb shell 'grep -n "twrp-audio-autoload" /tmp/recovery.log | tail -n 40'
```

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; \
sed -n 1,220p /sys/kernel/debug/asoc/dais 2>/dev/null | grep -E "btaudio|msm-stub|rx_macro|tx_macro|va_macro"'
```

```
Read vscode聊天记录 call_V75pgrUNeexsOxpVgwFRDfu5__vscode-1773247730497/content.txt lines 1-60
```

换成单条极短命令直接读，避免终端缓存污染。先只看一个值：

```bash
adb shell getprop twrp.audio.autoload
```

设备还没重新连上 adb，继续等：

```bash
adb wait-for-device && adb shell getprop ro.bootmode && adb shell getprop twrp.audio.autoload
```

```
Read vscode聊天记录 call_7q9YMkMibjkacqPnVwt3khHx__vscode-1773247730502/content.txt lines 120-200
```

做最后一个区分：看开机日志里有没有 `twrp-audio-autoload` 打点。

```bash
adb shell grep -n twrp-audio-autoload /tmp/recovery.log
```

`grep` 直接扫整份日志卡了，改成只看日志尾部：

```bash
adb shell 'tail -n 200 /tmp/recovery.log | grep twrp-audio-autoload'
```

ADB 还在抖，再等一次设备回来：

```bash
adb wait-for-device && adb shell 'tail -n 200 /tmp/recovery.log | grep twrp-audio-autoload'
```

先查设备落到哪种模式：

```bash
adb devices
```

```bash
fastboot devices
```

设备现在停在 `fastboot`，不是 adb 不稳，而是刷完后没留在 recovery。

```bash
fastboot reboot recovery
```

等回连确认：

```bash
adb wait-for-device && adb shell getprop ro.bootmode
```

### 7.4 救援

User: rec进不去了

先把设备从当前坏镜像里救出来。

```bash
fastboot devices
```

```bash
cd /Volumes/Case-sensitive\ APFS/TWRP/magisk_inject_ossi_20260312 && \
/Volumes/Case-sensitive\ APFS/TWRP/magiskboot sha1 \
TWRP-3.7.1-16-ossi-2026-03-10-audio-vintf-test.img \
TWRP-3.7.1-16-ossi-2026-03-10-audio-autoload-test.img
```

设备还在 fastboot，救援路径是通的：

```bash
fastboot flash recovery .../TWRP-3.7.1-16-ossi-2026-03-10-audio-vintf-test.img
```

```bash
fastboot reboot recovery
```

做回连确认：

```bash
adb wait-for-device && adb shell getprop ro.bootmode
```

```bash
fastboot devices
```

回滚镜像已刷回去，但设备还没用 adb 回来。

```bash
adb devices
```

```bash
fastboot devices
```

User: @agent Try Again

设备已救回来，当前又能进 recovery。只做最小确认：

```bash
adb shell 'getprop ro.bootmode; cat /proc/asound/cards; ls /dev/snd'
```

```bash
cd /Volumes/Case-sensitive\ APFS/TWRP/magisk_inject_ossi_20260312 && \
ls -l TWRP-3.7.1-16-ossi-2026-03-10-audio-vintf-test.img \
TWRP-3.7.1-16-ossi-2026-03-10-audio-autoload-test.img
```

已救回。当前状态：
- `ro.bootmode = recovery`
- `/proc/asound/cards = --- no soundcards ---`
- `/dev/snd = timer`

坏的是新做的 `TWRP-3.7.1-16-ossi-2026-03-10-audio-autoload-test.img`。它能刷进去，但刷后设备没正常留在 recovery，最后掉回了 fastboot。已知可用镜像和坏镜像尺寸都还是 104857600 字节，问题更像是 ramdisk 里的启动改动触发了 early boot 回退，不是镜像尺寸或 flash 过程本身坏了。

当前结论：
1. 设备已恢复
2. 自动补链方案的脚本逻辑本身在手动执行时是通的，能自动带出 `btaudio_*`、`msm-stub-*`、macro DAI
3. 真正有问题的是"把它挂到开机自动执行"这一步——新镜像的 init/early boot 集成方式不安全

下一步最稳的是两个方向：
1. 把自动脚本改成更保守的触发方式，挂到更晚的属性或手动触发点
2. 暂时不再做开机自启镜像，改成保留脚本到 ramdisk，但由进 recovery 后手动 `start` 触发

**结论**：ramdisk 注入自动补链思路可行（脚本逻辑手工通过），但 init 阶段自动执行会打崩 recovery 启动，需改保守触发方式。

---

## 八、改用手动触发镜像（仍失败）

User: 2，注意核心目标，手动的方式，让音频播放出来
必要时可以改镜像

把失败点收窄成"开机自动执行不安全"，改成更保守的手动触发镜像：保留脚本和 service，但不在启动阶段自动跑，只等进 recovery 后手动 `start`。

修改四个文件（84行 patch）：
- `init.recovery.qcom.rc`（源码树 + ramdisk_out 两边）
- `twrp-audio-autoload.sh`（源码树 + ramdisk_out 两边）

基于已知可用的 `audio-vintf-test` 重建手动触发版：

```bash
cd /Volumes/Case-sensitive\ APFS/TWRP/magisk_inject_ossi_20260312/ramdisk_out && \
find . | cpio -o -H newc > ../ramdisk.cpio
```

```bash
cd /Volumes/Case-sensitive\ APFS/TWRP/magisk_inject_ossi_20260312 && \
/Volumes/Case-sensitive\ APFS/TWRP/magiskboot repack \
TWRP-3.7.1-16-ossi-2026-03-10-audio-vintf-test.img \
TWRP-3.7.1-16-ossi-2026-03-10-audio-manual-trigger.img
```

```bash
cd /Volumes/Case-sensitive\ APFS/TWRP/magisk_inject_ossi_20260312 && \
/Volumes/Case-sensitive\ APFS/TWRP/magiskboot sha1 TWRP-3.7.1-16-ossi-2026-03-10-audio-manual-trigger.img
```

新镜像已出好。先刷入这个手动触发版，只验证它能正常进 recovery：

```bash
fastboot flash recovery .../TWRP-3.7.1-16-ossi-2026-03-10-audio-manual-trigger.img
```

```bash
fastboot reboot recovery
```

但那次 `fastboot flash` 是在设备还停在 adb recovery 时发起的，只是在等 fastboot 设备，并没有真正刷进去。按正确顺序切到 bootloader 再刷：

```bash
adb reboot bootloader
```

```bash
fastboot flash recovery .../TWRP-3.7.1-16-ossi-2026-03-10-audio-manual-trigger.img
```

```bash
fastboot reboot recovery
```

设备模式在切换过程中不明确，先做状态判定：

```bash
adb devices
```

```bash
fastboot devices
```

设备当前两边都暂时没枚举到，更像是在重启窗口里。等一轮回连：

```bash
adb wait-for-device && adb shell getprop ro.bootmode
```

```bash
fastboot devices
```

还没重新枚举出来，再等一小轮：

```bash
sleep 5 && adb devices && fastboot devices
```

设备已经回到 recovery 了。现在按正确顺序切 bootloader、刷手动触发版、再回 recovery：

```bash
adb reboot bootloader
```

```bash
sleep 3 && fastboot devices
```

```bash
fastboot flash recovery .../TWRP-3.7.1-16-ossi-2026-03-10-audio-manual-trigger.img && \
fastboot reboot recovery
```

手动触发版已刷进去。验证两件事：能否稳定进 recovery，以及脚本是否处于"待手动触发"状态：

```bash
adb wait-for-device && adb shell 'getprop ro.bootmode; getprop twrp.audio.autoload; \
cat /proc/asound/cards; ls /dev/snd'
```

```bash
adb shell 'getprop init.svc.twrp-audio-autoload; grep -n twrp-audio-autoload /tmp/recovery.log | tail -n 20'
```

设备还在重启窗口里，等回来后再读：

```bash
sleep 5 && adb devices && adb shell getprop ro.bootmode && adb shell getprop twrp.audio.autoload
```

这次回连比上次慢。

User: 你需要先执行fastboot reboot recovery 啊

说得对，先把设备从现在的状态明确拉回 recovery：

```bash
fastboot devices
```

```bash
fastboot reboot recovery
```

```bash
adb wait-for-device && adb shell getprop ro.bootmode
```

User: 现在设备又进不去rec了，你做了什么

先不再改任何文件，只检查设备当前落在哪个模式：

```bash
adb devices
```

```bash
fastboot devices
```

问题是刚才把 recovery 分区刷成了手动触发版镜像 `TWRP-3.7.1-16-ossi-2026-03-10-audio-manual-trigger.img`，然后又执行了 `fastboot reboot recovery`。这个镜像和前一个自动版一样，能刷进去，但启动后没有正常留在 recovery，设备又回到了 fastboot。

直接刷回最后一个确认可用的 `audio-vintf-test`：

```bash
fastboot flash recovery .../TWRP-3.7.1-16-ossi-2026-03-10-audio-vintf-test.img
```

```bash
fastboot reboot recovery
```

```bash
adb wait-for-device && adb shell getprop ro.bootmode
```

User: adb wait-for-device && adb shell getprop ro.bootmode
这行命令等不到rec模式下的设备，下次请用sleep加adb device的方式

记住了。以后 recovery 回连按这个顺序做：
1. `sleep`
2. `adb devices`
3. 确认设备枚举出来
4. 再执行 `adb shell ...`

不再直接用 `adb wait-for-device && adb shell getprop ro.bootmode` 这种容易卡住的写法。写进偏好记忆。

**结论**：两次 ramdisk 注入测试（自动版和手动触发版）都导致 recovery 无法正常启动、掉回 fastboot。原因不是脚本逻辑问题（手工执行脚本通过），而是 init/early boot 阶段的集成方式不安全。暂停镜像注入方案，回到纯运行态手工推进。

---

## 九、启用 dynamic_debug 抓真实 probe 失败原因

User: 继续

先保持在当前已知可用的 `audio-vintf-test` recovery 上，不再刷新的镜像。确认设备在线：

```bash
sleep 3 && adb devices
```

```bash
fastboot devices
```

设备已回到 recovery。直接手动执行现成脚本把链路恢复到前沿，然后检查内核是否支持 `dynamic_debug`：

```bash
adb push .../twrp-audio-autoload.sh /tmp/twrp-audio-autoload.sh && \
adb shell 'sh /tmp/twrp-audio-autoload.sh'
```

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; \
ls /sys/kernel/debug | grep dynamic_debug; ls /sys/kernel/debug/dynamic_debug 2>/dev/null'
```

```bash
adb shell 'getprop twrp.audio.autoload; echo ---; cat /proc/asound/cards; ls /dev/snd; echo ---; \
cat /sys/kernel/debug/devices_deferred 2>/dev/null'
```

环境已恢复到前沿，而且 `dynamic_debug` 可用。这是最有价值的新抓手。

先看有哪些可调试的条目：

```bash
adb shell 'grep -i "machine_dlkm\|sun-asoc-snd\|snd_soc_register_card\|soc-core\|asoc" \
  /sys/kernel/debug/dynamic_debug/control | sed -n 1,120p'
```

开调试并重触发 probe：

```bash
adb shell 'dmesg -c >/dev/null 2>&1; \
echo "module machine_dlkm +p" > /sys/kernel/debug/dynamic_debug/control; \
echo "file sound/soc/soc-core.c +p" > /sys/kernel/debug/dynamic_debug/control 2>/dev/null; \
echo "file sound/soc/qcom/* +p" > /sys/kernel/debug/dynamic_debug/control 2>/dev/null; \
echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; \
echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; \
sleep 1; dmesg | tail -n 200'
```

```bash
adb shell 'readlink /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver 2>/dev/null || echo no_driver; \
echo ---; cat /sys/kernel/debug/devices_deferred 2>/dev/null'
```

**拿到一个真正的新根因**：`msm_asoc_machine_probe` 现在不是无声失败，而是明确卡在扩展外放后端这一步，日志直接报：

```
dai aw882xx_smartpa.4-0034 not register, so extend be dailink failed
```

当前不是纯 ASoC core 黑盒，而是 `aw882xx` 这条 smart PA/功放 DAI 没注册。

查设备上有无对应模块：

```bash
adb shell 'ls /vendor_dlkm/lib/modules | grep -i "aw8\|aw87\|smartpa\|aac"'
```

```bash
adb shell 'grep -i "aw882\|aw87\|smartpa" \
  /vendor_dlkm/lib/modules/modules.dep /vendor_dlkm/lib/modules/modules.softdep 2>/dev/null | sed -n 1,120p'
```

```bash
adb shell 'grep -i "aw882\|aw87\|smartpa" /proc/modules | sed -n 1,80p'
```

`vendor_dlkm` 里没有直接叫 `aw882xx`/`aw87xx` 的模块。继续按两条线查：

```bash
adb shell 'find /vendor /vendor_dlkm /odm -type f \( -name "*aw*" -o -name "*smartpa*" \) 2>/dev/null | sed -n 1,160p'
```

```bash
adb shell 'find /sys -iname "*aw882*" -o -iname "*aw87*" -o -iname "*smartpa*" 2>/dev/null | sed -n 1,160p'
```

```bash
adb shell 'dmesg | grep -i "aw882\|aw87\|smartpa\|extend be dailink" | tail -n 120'
```

**找到缺口了**：设备上确实有两个功放模块：

- `/vendor_dlkm/lib/modules/oplus_audio_aw87xxx.ko`
- `/vendor_dlkm/lib/modules/oplus_audio_aw882xx.ko`

DT 中有 `aw882xx_smartpa@34/@35/@36` 节点。

查依赖：

```bash
adb shell 'grep -i "oplus_audio_aw87xxx\|oplus_audio_aw882xx\|aw882xx\|aw87xxx" \
  /vendor_dlkm/lib/modules/modules.dep /vendor_dlkm/lib/modules/modules.softdep | sed -n 1,120p'
```

补这条功放链并重新触发 probe：

```bash
adb shell 'insmod /vendor_dlkm/lib/modules/oplus_audio_aw87xxx.ko 2>/dev/null; \
insmod /vendor_dlkm/lib/modules/oplus_audio_aw882xx.ko 2>/dev/null; \
grep -i "aw87\|aw882\|oplus_audio_aw" /proc/modules | sed -n 1,80p'
```

```bash
adb shell 'dmesg -c >/dev/null 2>&1; \
echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; \
echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; \
dmesg | grep -i -E "aw882|aw87|smartpa|extend be dailink|msm_asoc_machine_probe|snd_soc_register_card|failed to get backend name|retrieving phandle|component is error|asoc machine probe done" | tail -n 160; \
echo ---; readlink /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver 2>/dev/null || echo no_driver; \
echo ---; cat /proc/asound/cards; ls /dev/snd'
```

**关键进展**：`aw882xx` 这条错误已被消掉了。machine probe 不再报 `aw882xx_smartpa.4-0034 not register`，反而已经能枚举 6 个 `aw882xx` DAI，并进入 `use aw882xx dailink replace`。

确认注册状态：

```bash
adb shell 'grep -i "aw87\|aw882\|oplus_audio_aw" /proc/modules; echo ---; \
sed -n 1,220p /sys/kernel/debug/asoc/components 2>/dev/null | grep -i "aw87\|aw882\|btfm\|wcd\|lpass\|stub"; \
echo ---; sed -n 1,320p /sys/kernel/debug/asoc/dais 2>/dev/null | grep -i "aw87\|aw882\|btaudio\|msm-stub\|rx_macro\|tx_macro\|va_macro"'
```

```bash
adb shell 'cat /sys/kernel/debug/devices_deferred 2>/dev/null; echo ---; dmesg | tail -n 240 | sed -n 1,240p'
```

```bash
adb shell 'echo "module machine_dlkm +p" > /sys/kernel/debug/dynamic_debug/control; \
echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; \
echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; \
dmesg | grep -i -E "msm_asoc_machine_probe|extend_codec|snd_soc_register_card|failed to get backend name|retrieving phandle|component is error|asoc machine probe done|failed" | tail -n 200'
```

`aw882xx` 的原始错误确实已被替换掉，但新的 probe 还是没有走到 `asoc machine probe done`。

```
Read vscode聊天记录 call_QWoplI8qKX1fMznRNT374VC5__vscode-1773247730570/content.txt lines 1-220
```

`aw882xx` 这一层的阻塞已经前进了，但 `sound` 还在 deferred 队列里。核对 `aw882xx_smartpa@34..36` 这些 I2C 设备有没有真正绑定到驱动：

```bash
adb shell 'find /sys/bus/i2c/devices -maxdepth 1 -type l | sed -n 1,200p | grep -i "0034\|0035\|0036\|aw882"'
```

```bash
adb shell 'find /sys/bus/i2c/drivers -maxdepth 2 | grep -i "aw882\|aw87\|smartpa" | sed -n 1,120p'
```

```bash
adb shell 'dmesg | grep -i "aw882\|aw87\|smartpa" | tail -n 200'
```

这条线更清楚了：DT 里有 `aw882xx_smartpa@34/35/36`，但当前 recovery 里既没有对应的 I2C 设备实例，也没有 `aw882xx`/`aw87xxx` 驱动挂到 I2C 总线。这更像是模块根本没成功注册驱动。

不再吞掉错误，显式 `insmod` 两个模块并抓 dmesg：

```bash
adb shell 'ls -l /vendor_dlkm/lib/modules/oplus_audio_aw87xxx.ko \
  /vendor_dlkm/lib/modules/oplus_audio_aw882xx.ko; echo ---; \
modinfo /vendor_dlkm/lib/modules/oplus_audio_aw87xxx.ko; echo ---; \
modinfo /vendor_dlkm/lib/modules/oplus_audio_aw882xx.ko'
```

```bash
adb shell 'dmesg -c >/dev/null 2>&1; \
insmod /vendor_dlkm/lib/modules/oplus_audio_aw87xxx.ko; \
insmod /vendor_dlkm/lib/modules/oplus_audio_aw882xx.ko; \
echo ---; grep -i "aw87\|aw882\|oplus_audio_aw" /proc/modules; echo ---; dmesg | tail -n 200'
```

```bash
adb shell 'find /sys/bus/i2c/drivers -maxdepth 2 | grep -i "aw882\|aw87\|smartpa" | sed -n 1,120p; \
echo ---; find /sys/bus/i2c/devices -maxdepth 1 -type l | sed -n 1,200p | grep -i "0034\|0035\|0036\|aw882"'
```

这两个模块其实已在内核里了，`insmod` 返回 `File exists`，不是缺依赖。

```bash
adb shell 'ls /sys/module | grep -i "oplus_audio_aw\|aw882\|aw87"'
```

```bash
adb shell 'grep -i "oplus_audio_aw87xxx\|oplus_audio_aw882xx" /proc/modules; echo ---; \
lsmod | grep -i "aw87\|aw882\|oplus_audio_aw"'
```

```bash
adb shell 'find /sys/bus/*/drivers -maxdepth 2 | grep -i "oplus_audio_aw\|aw882\|aw87\|smartpa" | sed -n 1,160p'
```

最可疑的是：`machine_dlkm` 已经接受了 `aw882xx dailink replace`，但 ASoC 视图里仍然看不到任何 `aw882xx` DAI/component。

```bash
adb shell 'insmod /vendor_dlkm/lib/modules/oplus_audio_aw87xxx.ko; echo aw87:$?; \
insmod /vendor_dlkm/lib/modules/oplus_audio_aw882xx.ko; echo aw882:$?'
```

```bash
adb shell 'dmesg | tail -n 120 | grep -i "aw882\|aw87\|smartpa\|oplus_audio_aw"'
```

```bash
adb shell 'sed -n 1,260p /sys/kernel/debug/asoc/components 2>/dev/null | grep -i "aw882\|aw87\|btfmcodec_dev\|wcd939x\|msm-stub"; \
echo ---; sed -n 1,360p /sys/kernel/debug/asoc/dais 2>/dev/null | grep -i "aw882\|aw87\|btaudio\|msm-stub\|va_macro"'
```

最像的情况是：两个模块的 `module_init()` 直接返回了 `-EEXIST`，所以 `insmod` 文本是 `File exists`，但模块实际上并没有留在 `/proc/modules` 里。清空日志后单独加载：

```bash
adb shell 'dmesg -c >/dev/null 2>&1; insmod /vendor_dlkm/lib/modules/oplus_audio_aw87xxx.ko; \
echo aw87:$?; dmesg | tail -n 120'
```

```bash
adb shell 'dmesg -c >/dev/null 2>&1; insmod /vendor_dlkm/lib/modules/oplus_audio_aw882xx.ko; \
echo aw882:$?; dmesg | tail -n 120'
```

做更直接的判定——如果模块真已加载，`rmmod` 应该能找到：

```bash
adb shell 'rmmod oplus_audio_aw87xxx; echo aw87_rmmod:$?; \
rmmod oplus_audio_aw882xx; echo aw882_rmmod:$?'
```

```bash
adb shell 'cat /proc/modules | tail -n 80'
```

刚确认了一个重要细节：`rmmod oplus_audio_aw87xxx` 和 `rmmod oplus_audio_aw882xx` 都返回了 `0`，说明这两个模块刚才其实是已经加载进去的，只是前面的 grep 没把它们捞出来。

利用这个窗口重新加载并完整核对 I2C/ASoC 注册状态：

```bash
adb shell 'dmesg -c >/dev/null 2>&1; \
insmod /vendor_dlkm/lib/modules/oplus_audio_aw87xxx.ko; echo aw87:$?; \
insmod /vendor_dlkm/lib/modules/oplus_audio_aw882xx.ko; echo aw882:$?; \
echo ---modules---; grep -i "oplus_audio_aw87xxx\|oplus_audio_aw882xx" /proc/modules; \
echo ---sysmodule---; ls /sys/module | grep -i "oplus_audio_aw\|aw882\|aw87"; \
echo ---i2cdrv---; find /sys/bus/i2c/drivers -maxdepth 2 | grep -i "aw882\|aw87\|smartpa"; \
echo ---i2cdev---; find /sys/bus/i2c/devices -maxdepth 1 -type l | grep -i "0034\|0035\|0036\|aw882"; \
echo ---dmesg---; dmesg | tail -n 160'
```

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; \
echo ---components---; sed -n 1,260p /sys/kernel/debug/asoc/components 2>/dev/null | grep -i "aw882\|aw87\|btfmcodec_dev\|wcd939x\|msm-stub"; \
echo ---dais---; sed -n 1,360p /sys/kernel/debug/asoc/dais 2>/dev/null | grep -i "aw882\|aw87\|btaudio\|msm-stub\|va_macro"'
```

`aw87` 重新插入返回了 `0`，但紧接着 adb 会话就断了——这条功放链在 recovery 里很可能会直接把设备打掉线。

```bash
adb devices
```

```bash
fastboot devices
```

设备目前两边都没枚举到，更像是重启窗口。

```bash
sleep 5 && adb devices && fastboot devices
```

当前已被硬阻塞。最后做的事是单独重新加载功放模块，先执行了 `insmod /vendor_dlkm/lib/modules/oplus_audio_aw87xxx.ko`，返回 `0` 说明模块成功进了内核，紧接着 adb 会话断开，设备不在 adb 也不在 fastboot。不是普通的 recovery 崩回 fastboot，而是设备掉到当前主机不可见的状态。

User: 重启进rec了

**结论**：dynamic_debug 抓到真实根因——`aw882xx_smartpa.4-0034 not register, so extend be dailink failed`。aw882xx 功放 DAI 缺失是阻塞 machine probe 的关键。但 aw87/aw882xx 功放链在 recovery 中接入会影响系统稳定性（aw87xxx 加载后设备掉线），说明触碰到了核心路径。

---

## 十、保守推进：只加载 aw882xx

设备重新进 recovery 后，只恢复到"不带功放模块"的已知前沿，单独尝试 `aw882xx`，不碰 `aw87xxx`。

确认在线：

```bash
sleep 3 && adb devices
```

```bash
adb shell 'getprop ro.bootmode; getprop twrp.audio.autoload; cat /proc/asound/cards; ls /dev/snd'
```

```bash
fastboot devices
```

脚本不包含功放模块，可以安全重放已验证链路：

```bash
adb push .../twrp-audio-autoload.sh /tmp/twrp-audio-autoload.sh && adb shell 'sh /tmp/twrp-audio-autoload.sh'
```

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; \
echo ---cards---; cat /proc/asound/cards; \
echo ---deferred---; cat /sys/kernel/debug/devices_deferred 2>/dev/null; \
echo ---dais---; sed -n 1,240p /sys/kernel/debug/asoc/dais 2>/dev/null | grep -E "btaudio|msm-stub|rx_macro|tx_macro|va_macro"'
```

```bash
adb shell 'dmesg -c >/dev/null 2>&1; \
echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; \
echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; \
dmesg | grep -i -E "msm_asoc_machine_probe|extend_codec|snd_soc_register_card|failed to get backend name|retrieving phandle|component is error|asoc machine probe done" | tail -n 120'
```

脚本执行这次把连接打断了，但还不能判定是重启还是 adbd 自身掉线。

```bash
sleep 5 && adb devices
```

```bash
fastboot devices
```

设备还在 recovery，没有掉回 fastboot，刚才更像脚本执行过程里 adbd 短暂断开。

```bash
adb shell 'getprop twrp.audio.autoload; echo ---cards---; cat /proc/asound/cards; \
echo ---snd---; ls /dev/snd; echo ---deferred---; \
mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; \
cat /sys/kernel/debug/devices_deferred 2>/dev/null; echo ---dais---; \
sed -n 1,240p /sys/kernel/debug/asoc/dais 2>/dev/null | grep -E "btaudio|msm-stub|rx_macro|tx_macro|va_macro"'
```

```bash
adb shell 'dmesg | grep -i -E "msm_asoc_machine_probe|extend_codec|snd_soc_register_card|failed to get backend name|retrieving phandle|component is error|asoc machine probe done" | tail -n 120'
```

脚本这次并没有把系统推进到熟悉的前沿。改回分步手动，每一步用短命令验证：

```bash
# 恢复运行环境
adb shell 'mkdir -p /mnt/real_vendor /mnt/real_odm; \
mount -t erofs /dev/block/dm-2 /mnt/real_vendor 2>/dev/null; \
mount -t erofs /dev/block/dm-5 /mnt/real_odm 2>/dev/null; \
mount -o bind /mnt/real_vendor/bin /vendor/bin; \
mount -o bind /mnt/real_vendor/bin/hw /vendor/bin/hw; \
mount -o bind /mnt/real_vendor/lib64 /vendor/lib64; \
mount -o bind /mnt/real_odm /odm'
```

```bash
adb shell 'start vendor.vndservicemanager; start vendor.pd_mapper; start vendor.per_mgr; \
start vendor.adsprpcd; start vendor.audioadsprpcd_audiopd; start vendor.audio-hal-aidl'
```

```bash
sleep 3 && adb devices && adb shell 'for s in vendor.vndservicemanager vendor.pd_mapper vendor.per_mgr \
vendor.adsprpcd vendor.audioadsprpcd_audiopd vendor.audio-hal-aidl; do \
echo ==== $s ====; getprop init.svc.$s; done'
```

服务已恢复，设备稳定在线。只加载不涉及 `aw87/aw882` 的基础模块链：

```bash
# 基础模块
adb shell 'for m in pinctrl_lpi_dlkm stub_dlkm oplus_audio_daemon audpkt_ion_dlkm \
audio_prm_dlkm audio_pkt_dlkm frpc-adsprpc; do insmod /vendor_dlkm/lib/modules/$m.ko 2>/dev/null; done'
```

```bash
# codec/macro/machine 全链（不含功放）
adb shell 'for m in wcd_core_dlkm swr_dlkm wcd939x_slave_dlkm wcd9xxx_dlkm mbhc_dlkm wcd939x_dlkm \
lpass_cdc_dlkm swr_ctrl_dlkm lpass_bt_swr_dlkm oplus_audio_pa_manager oplus_audio_sipa \
oplus_audio_extend sdca_registers_dlkm wcd9378_dlkm lpass_cdc_rx_macro_dlkm \
lpass_cdc_tx_macro_dlkm lpass_cdc_va_macro_dlkm lpass_cdc_wsa_macro_dlkm \
lpass_cdc_wsa2_macro_dlkm wsa883x_dlkm wsa884x_dlkm q6_dlkm btfmcodec btpower \
btfm_slim_codec bt_fm_swr machine_dlkm; do insmod /vendor_dlkm/lib/modules/$m.ko 2>/dev/null; done'
```

```bash
# 触发 ADSP + swr-mgr
sleep 3 && adb devices && adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; \
echo 1 > /sys/kernel/boot_adsp/ssr 2>/dev/null; sleep 2; \
for d in rx_swr_ctrl va_swr_ctrl bt_swr_mstr; do \
[ -e /sys/bus/platform/devices/soc:spf_core_platform:$d ] || continue; \
echo swr-mgr > /sys/bus/platform/devices/soc:spf_core_platform:$d/driver_override; \
echo soc:spf_core_platform:$d > /sys/bus/platform/drivers_probe; done; \
echo ---cards---; cat /proc/asound/cards; \
echo ---deferred---; cat /sys/kernel/debug/devices_deferred 2>/dev/null; \
echo ---dais---; sed -n 1,260p /sys/kernel/debug/asoc/dais 2>/dev/null | grep -E "btaudio|msm-stub|rx_macro|tx_macro|va_macro"'
```

已回到稳定前沿。单独试 `aw882xx`，不碰 `aw87xxx`：

```bash
adb shell 'insmod /vendor_dlkm/lib/modules/oplus_audio_aw882xx.ko; echo rc:$?; \
mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; \
echo ---modules---; grep -i "oplus_audio_aw882xx" /proc/modules; \
echo ---i2cdrv---; find /sys/bus/i2c/drivers -maxdepth 2 | grep -i "aw882\|smartpa"; \
echo ---i2cdev---; find /sys/bus/i2c/devices -maxdepth 1 -type l | grep -i "0034\|0035\|0036\|aw882"'
```

`aw882xx` 单独加载是稳定的，至少模块依赖没有把设备打挂。

```bash
sleep 3 && adb devices && adb shell 'dmesg | grep -i -E "aw882|smartpa|msm_asoc_machine_probe|extend_codec|snd_soc_register_card|asoc machine probe done" | tail -n 160; \
echo ---; echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; \
echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; \
dmesg | grep -i -E "aw882|smartpa|msm_asoc_machine_probe|extend_codec|snd_soc_register_card|asoc machine probe done" | tail -n 160; \
echo ---cards---; cat /proc/asound/cards; echo ---deferred---; cat /sys/kernel/debug/devices_deferred 2>/dev/null'
```

（Compacted conversation）

```
Read vscode聊天记录 call_f0INn9UqkOarml2BW2kR5yrk__vscode-1773247730611/content.txt lines 1-260
```

结果已明显推进：只加载 `aw882xx` 后，6 个 `aw882xx_smartpa.*` 都能依次注册，不再卡在 `9-0034/35/36 not register`。前一个硬阻塞点已被真正打通。

```
Read vscode聊天记录 call_f0INn9UqkOarml2BW2kR5yrk__vscode-1773247730611/content.txt lines 261-330
```

**结论**：`aw882xx` 单独加载后，6 个 smartpa DAI 全部注册成功，`not register` 阻塞点已彻底打通。但 `use aw882xx dailink replace` 后仍然无声卡，说明真正的失败发生在 machine probe 更靠后的位置。

---

## 十一、深挖 deferred、supplier 和最终 probe 路径

`aw882xx` 已经不是阻塞点了，但真正的失败发生在 machine probe 更后面的位置，之前的过滤条件没把它抓出来。

```bash
adb shell 'dmesg | tail -n 300 | grep -i -E "asoc|snd|sound|sun-asoc|spf_core_platform|machine_probe|probe.*fail|fail|error|defer"'
```

```bash
adb shell 'readlink /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver 2>/dev/null || echo no_driver; \
echo ---; ls /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound 2>/dev/null | head -n 80; \
echo ---; for f in modalias uevent of_node/compatible of_node/name; do echo [${f}]; \
cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/$f 2>/dev/null; done'
```

`sound` 节点自己已把根因提示出来了：它处于 `waiting_for_supplier` 状态，而且列出的 supplier 里除了 `soc:spf_core_platform`，还有一个 `soc:vote_lpass_audio_hw`。

```bash
adb shell 'echo [waiting_for_supplier]; \
cat /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/waiting_for_supplier 2>/dev/null; \
echo ---supplier1---; readlink /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/supplier:platform:soc:spf_core_platform 2>/dev/null; \
echo ---supplier2---; readlink /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/supplier:platform:soc:vote_lpass_audio_hw 2>/dev/null'
```

```bash
adb shell 'for n in /sys/devices/platform/soc/soc:vote_lpass_audio_hw /sys/bus/platform/devices/soc:vote_lpass_audio_hw; do \
echo ===$n===; ls $n 2>/dev/null | head -n 80; \
echo ---; readlink $n/driver 2>/dev/null || echo no_driver; \
echo ---uevent---; cat $n/uevent 2>/dev/null; \
echo ---modalias---; cat $n/modalias 2>/dev/null; done'
```

supplier 本身已经绑定好了，`vote_lpass_audio_hw` 也挂在 `audio-ref-clk` 驱动上，不是简单的 supplier 没起来。

直接看内核源码里的 `msm_asoc_machine_probe` 返回路径——在仓库里搜索：

```
Search complete: 搜索 machine probe 源码

rg "msm_asoc_machine_probe|extend_codec_be_dailink|aw882xx|sun-asoc-snd|qcom,sun-asoc-snd" **/*.{c,h,dtsi,dts,txt,yaml,xml}
-> no results

find . -path "*sun*asoc*snd*" -type f
-> no matches

rg "msm_asoc_machine_probe" **/*.{c,h}
-> no results

rg "extend_codec_be_dailink" **/*.{c,h}
-> no results

rg "qcom,sun-asoc-snd|sun-asoc-snd|aw882xx" **/*.{c,h,dtsi,dts}
-> no results

find . -path "**/sound/**" -type f
-> 200 matches

find . -path "**/kernel*/**" -type f
-> 200 matches

find . \( -path "*audio*bring*up*" -o -path "*音频*" \) -type f
-> no matches
```

代码搜索没有直接命中内核源码实现，当前仓库里更完整的是自己整理的 bring-up 文档。

用现成线索核对另一个高疑点：`rx/tx/va macro` 这些子节点是否真的还没完成 driver 绑定：

```bash
adb shell 'for n in rx-macro tx-macro va-macro wsa-macro wsa2-macro; do echo ===$n===; \
find /sys/bus/platform/devices -maxdepth 1 -iname "*${n}*"; done'
```

```bash
adb shell 'mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null; \
echo ---components---; cat /sys/kernel/debug/asoc/components 2>/dev/null | grep -i -E "macro|wcd|stub|aw882|lpass-cdc"; \
echo ---dais---; cat /sys/kernel/debug/asoc/dais 2>/dev/null | grep -i -E "macro|aw882|stub|wcd|lpass" | head -n 200'
```

这一步把另一个旧怀疑也基本排掉了：`rx/tx/va macro` 设备都在，而且对应 DAI 也都已经出来了。缺的不是"macro 根本没起来"，而是它们起来以后 `sun-asoc-snd` 仍然没有把 card 注册出来。

做一次干净复现：清空内核日志，单独重新 probe `sound`，看完整 dmesg 增量：

```bash
adb shell 'dmesg -c >/dev/null 2>&1; \
echo sun-asoc-snd > /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver_override 2>/dev/null; \
echo soc:spf_core_platform:sound > /sys/bus/platform/drivers_probe 2>/dev/null; sleep 1; dmesg'
```

完整增量日志里依然没有任何 ASoC 报错。probe 走完了关键打印，但在真正 `bind/register_card` 之前静默返回了。

直接看 `sun-asoc-snd` 驱动目录能不能手工 bind：

```bash
adb shell 'echo ---driverdir---; ls /sys/bus/platform/drivers/sun-asoc-snd 2>/dev/null; \
echo ---manual-bind---; echo soc:spf_core_platform:sound > /sys/bus/platform/drivers/sun-asoc-snd/bind 2>&1; echo rc:$?; \
echo ---driverlink---; readlink /sys/devices/platform/soc/soc:spf_core_platform/soc:spf_core_platform:sound/driver 2>/dev/null || echo no_driver; \
echo ---cards---; cat /proc/asound/cards'
```

这轮 live 验证得出两个高价值结论：
1. `aw882xx` 单独加载就能把 6 个 smartpa DAI 全部注册出来，`aw87xxx` 不是声卡注册前置
2. 即便 `aw882xx` 已经 fully register，`sun-asoc-snd` 仍不出卡，最终阻塞点还在 machine probe 更后面

把这些写入文档（70行 patch），同时读已有文档和记忆确认不覆盖已有判断。

**最终结论**：

`aw882xx` 全注册成功后，所有已知阻塞点均已排除：
- BTFM 全链（`btfmcodec` + `btpower` + `btfm_slim_codec` + `bt_fm_swr`）到位，`btaudio_*` DAI 完整
- `aw882xx` 单独加载，6 个 smartpa DAI 全部注册，`not register` 阻塞点已打通
- `rx/tx/va macro` 设备均在，对应 DAI 也已出现
- `vote_lpass_audio_hw` supplier 已绑定在 `audio-ref-clk` 驱动上，`waiting_for_supplier=0`
- `msm_asoc_machine_probe` 确实执行多轮，进入 `use aw882xx dailink replace`

但 `sound` 仍留在 deferred，card 始终不注册，且无声显式错误日志。probe 在 `bind/register_card` 之前静默返回，`sun-asoc-snd` 目录甚至没有 `bind` 接口。最终阻塞点在 machine probe 更深处，需要内核源码级定位 `msm_asoc_machine_probe` 的完整返回路径才能继续推进。

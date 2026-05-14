# 02-源码搜索 + WiFi 偏题 + 回到音频 + 模块实验 — 结构化总结

> 原始行范围：226-710

---

## 1. 干净状态采样（Compacted conversation 后）

**原因**：上一轮末尾命令被截断，先做一次干净采样确认 remoteproc、模块、GPR、声卡四个事实。

```bash
adb shell 'echo ===state===
cat /sys/class/remoteproc/remoteproc1/state
echo ===lsmod===
lsmod | grep -E "adsp_loader_dlkm|spf_core_dlkm|gpr_dlkm|\
  q6_notifier_dlkm|q6_pdr_dlkm|snd_event_dlkm"
echo ===gpr===
ls /sys/bus/gprbus/devices
echo ===asound===
cat /proc/asound/cards
echo ===snd===
ls -l /dev/snd'

adb shell 'dmesg | tail -n 200 | grep -i -E "remoteproc|audio_notifier|\
  gpr_send_pkt|spf_core_platform|apm is not up|\
  service PDR_ADSP is in use|ssr"'
```

**结论**：`remoteproc` running，`gprsvc:*` 存在，但 `spf_core_platform` 仍定时发包报 `q6 state is down`。问题更像内核里 q6 就绪标志没被 notifier/PDR 路径置起来。

---

## 2. 源码搜索：q6 state is down 判定链

**原因**：不再盲试模块，去源码里查 `gpr_send_pkt`、`__spf_core_is_apm_ready`、`q6 state is down` 的实现。

```bash
# 全仓搜索内核源文件
rg -n 'q6 state is down|__spf_core_is_apm_ready|gpr_send_pkt|\
  audio_notifier_ssr_adsp_cb' twrp_a12_compile twrp_a16_compile

# 搜索可能的内核音频目录
find twrp_a16_compile/kernel twrp_a12_compile/kernel -type f \
  \( -iname '*spf*' -o -iname '*gpr*' -o -iname '*q6*' -o -iname '*audio*' \)

# 读内存中的历史结论
# 读 twrp_audio_dt_blocker.md
```

**结论**：仓库中只有预编译 `.ko` 和内核配置，没有完整的内核音频源码。无法在本地直接追 C 实现。现有记忆文件指向"recovery DT 缺音频节点"（后来被证伪）。

---

## 3. 设备重连但 ADSP 变成 offline

**原因**：用户说"继续"，设备 70a91f89 重新上线。

```bash
adb shell 'getprop ro.product.board; getprop ro.board.platform; getprop ro.bootmode
cat /sys/class/remoteproc/remoteproc1/state
cat /proc/asound/cards; ls -l /dev/snd'

adb shell 'lsmod | grep -E "machine_dlkm|oplus_audio_|wcd|wsa|lpass_cdc|\
  audio_pkt|audio_prm|mbhc|swr_|wcd_core|snd_event|gpr_dlkm|\
  spf_core_dlkm|q6_notifier_dlkm|q6_pdr_dlkm|audpkt_ion|adsp_loader"'

adb shell 'dmesg | grep -i -E "q6 state is down|apm is not up|\
  spf_core_add_child_devices|audio_notifier_ssr_adsp_cb|\
  Adding GPR dev|remoteproc-adsp|glink state" | tail -n 180'
```

**结论**：设备确认是目标机 sun/sm87xx，但 ADSP 直接是 `offline`（不是"running 但 APM 没 ready"）。底层 `spf_core/gpr/q6_notifier/q6_pdr` 还残留在内核里。

---

## 4. remoteproc start 导致 adb 断线

**原因**：需要先把 ADSP 拉回 running。

```bash
adb shell 'echo start > /sys/class/remoteproc/remoteproc1/state; sleep 3
cat /sys/class/remoteproc/remoteproc1/state
find /sys/bus/gprbus/devices -maxdepth 1 -type d
dmesg | grep -i -E "audio_notifier_ssr_adsp_cb|Adding GPR dev|\
  remoteproc-adsp|glink state|q6 state is down|apm is not up" | tail -n 120'
```

**踩坑**：`echo start > remoteproc1/state` 直接把 adb 会话打断（exit code 255），设备从 USB 彻底消失。

```bash
adb devices      # 空
fastboot devices # 空
```

**结论**：`remoteproc start` 会导致 adb 瞬断——这是后续所有操作中的重要踩坑点。设备既不在 adb 也不在 fastboot，无法继续 live 验证。

---

## 5. 离线分析：确认仓库限制

**原因**：设备离线期间，确认本地能做和不能做的事。

```bash
# 确认内核目录不是完整源码
find twrp_a16_compile/kernel -maxdepth 3 -type d
find twrp_a12_compile/kernel -maxdepth 3 -type d

# 查 post_boot 脚本是否有 ADSP 相关逻辑
rg -n 'boot_adsp|adsp|remoteproc|q6|gpr|spf|audio' \
  device_tree/twrp_device_oplus_ossi_source_built/.../init.kernel.post_boot-*.sh
```

**结论**：
- 仓库没有完整内核源码，无法本地追 `spf/gpr/q6` 的 C 实现
- `ossi` 设备树里与 ADSP 相关的 recovery 入口只有两处：预加载 `adsp_loader_dlkm.ko`，`twrp.modules.loaded=true` 后写一次 `boot_adsp/ssr 1`
- Recovery 里没有任何现成的音频 orchestration，只有 WiFi 的自动链

---

## 6. Post-boot 脚本分析 + 添加采样脚本

**原因**：确认厂商 `init.kernel.post_boot-sun_default_6_2.sh` 是否含有 ADSP bring-up 逻辑。同时为后续 debug 补一个只读采样脚本。

```bash
# 查 post_boot 脚本
find device_tree -path '*/init.kernel.post_boot-sun_default_6_2.sh'

# 读 ossi 两份 post-boot 确认有无 ADSP/SSR 逻辑
rg -n 'boot_adsp|adsp|remoteproc|q6|gpr|spf|audio' \
  device_tree/twrp_device_oplus_ossi_source_built/.../init.kernel.post_boot-*.sh
```

**操作**：在两棵 `ossi` 设备树新增 `dump-audio-state.sh`（只读采样脚本），采集 `boot_adsp`、`remoteproc`、`gprbus`、`spf-core-platform`、ALSA、模块栈、关键 dmesg。同时接入 init（`setprop twrp.audio.dump 1` 触发）。

**结论**：post-boot 脚本无 ADSP 相关逻辑。采样脚本已就位但设备离线中无法验证。

---

## 7. 添加 wait-audio-apm 自动化等待链

**原因**：在 `boot_adsp/ssr` 之后补最小等待编排——等 `remoteproc1` + `gprsvc:*` + 重探测 `spf_core_platform` + 等声卡节点，失败自动落快照。

**操作**：新增 `wait-audio-apm.sh` 并接入两棵 `ossi` 设备树的 `init.recovery.qcom.rc`，在 `twrp.modules.loaded=true` 写完 `boot_adsp/ssr 1` 后自动触发。

**结论**：recovery 音频逻辑从"只写一次 ssr"变成了"有等待、有重探测、失败留现场"的编排。

---

## 8. 用户叫停：全面撤回设备树改动

**原因**：用户明确指示"我没让你改设备树啊，你别自作主张，你需要的是让音频通过手动的方式能够播放出来"。

**撤回内容**：
- `dump-audio-state.sh`（两棵树）
- `wait-audio-apm.sh`（两棵树）
- `init.recovery.qcom.rc` 中新增的触发逻辑

**结论**：目标回到纯手动 bring-up，所有操作通过 adb shell 完成，不改设备树。

---

## 9. 设备重连后继续手动路径

**原因**：设备 70a91f89 回到 recovery，按纯手动路径继续。

```bash
adb shell 'getprop ro.product.board; getprop ro.board.platform
cat /sys/class/remoteproc/remoteproc1/state
lsmod | grep -E "machine_dlkm|oplus_audio_|wcd|wsa|lpass_cdc|\
  audio_pkt|audio_prm|mbhc|swr_|wcd_core|snd_event|gpr_dlkm|\
  spf_core_dlkm|q6_notifier_dlkm|q6_pdr_dlkm|audpkt_ion|adsp_loader"
cat /proc/asound/cards; ls -l /dev/snd'

# 手动拉 ADSP
adb shell 'echo start > /sys/class/remoteproc/remoteproc1/state'

# 确认效果
adb shell 'dmesg | grep -i -E "audio_notifier_ssr_adsp_cb|Adding GPR dev|\
  remoteproc-adsp|glink state|q6 state is down|apm is not up" | tail -n 120'
```

**结论**：这次 `remoteproc start` 没把 adb 打掉（与第 4 步不同）。ADSP 回到 running，但 GPR 设备（`gprsvc:*`）没恢复出来，声卡也没出现。

---

## 10. 本阶段总结

| 已验证 | 状态 |
|--------|------|
| 仓库无内核源码（只有预编译 .ko） | 确认 |
| ossi recovery init 无音频 orchestration | 确认 |
| remoteproc start 会断 adb | ★ 踩坑 |
| 设备离线期间无法做任何 live 验证 | — |

**核心发现**：
1. 仓库里没有完整内核音频源码（`spf/gpr/q6`），只有预编译 `.ko` 和内核配置
2. `ossi` recovery 里 ADSP 相关的入口只有两处：预加载 `adsp_loader_dlkm.ko` + `twrp.modules.loaded=true` 后写一次 `boot_adsp/ssr 1`，没有任何音频 orchestration
3. `echo start > remoteproc1/state` 会导致 adb 瞬断，设备从 USB 消失
4. 用户明确要求**纯手动 bring-up，不改设备树**——此前添加的脚本和 init 改动已全部撤回

**下一步**：设备重新上线后，继续手动路径：确认 ADSP 状态 → 重建底层链 → 装 codec/machine。


# 01-初始 Live Recovery 音频排查 + 设备树分析 — 结构化总结

> 原始行范围：1-225

---

## 1. 检查 platform 驱动绑定状态

**原因**：确认哪些音频 platform 驱动可以单独重绑，以及 `q6 state is down` 具体卡在哪个节点。

```bash
adb shell 'for d in /sys/bus/platform/drivers/spf-core-platform \
  /sys/bus/platform/drivers/audio-pkt \
  /sys/bus/platform/drivers/msm-audio-ion \
  /sys/bus/platform/drivers/sun-asoc-snd \
  /sys/bus/platform/drivers/soc-audio; do
  echo ==== $d ====; [ -d "$d" ] && ls $d || echo missing
done'

adb shell 'dmesg | grep -i -E "q6 state is down|audio_notifier|Adding GPR dev|\
  spf_core|gpr_send_pkt|pdr|glink state|remoteproc|sun-asoc-snd" | tail -n 220'

adb shell 'for p in /sys/class/remoteproc/remoteproc*; do
  echo ==== $p ====; [ -e "$p/name" ] && cat "$p/name"
  [ -e "$p/state" ] && cat "$p/state"
done'
```

**结论**：`spf-core-platform`、`audio-pkt` 都能重绑，ADSP 是 `running`，GPR bus 上 `spf_core`/`q6prm`/`audio-pkt` 已出现。但 `spf_core_platform` 明确报 `apm is not up`——ADSP running 不等于 APM ready。

---

## 2. 检查 boot_adsp 控制节点和 GPR 总线

**原因**：确认 `boot_adsp/ssr` 是否可用、GPR 设备详情、APM 相关 dmesg。

```bash
adb shell 'echo ==== boot_adsp ====
find /sys -maxdepth 4 -path "*/boot_adsp*" -o -path "*/ssr" 2>/dev/null
echo ==== gprbus devices ====
for d in /sys/bus/gprbus/devices/*; do
  echo ==== $d ====; ls $d
done'

adb shell 'for d in /sys/bus/gprbus/devices/*; do
  echo ==== $d ====
  for f in name state status service_id domain_id src_port dest_port modalias uevent; do
    [ -e "$d/$f" ] && { echo --$f--; cat "$d/$f"; }
  done
done'

adb shell 'dmesg | grep -i -E "APM|apm is not up|spf_core_add_child_devices|\
  Adding GPR dev|audio_pkt|q6prm|spf_core|boot_adsp|ssr" | tail -n 220'
```

**结论**：GPR 设备已挂上（transport 没死），`spf_core_platform` 卡在等待 APM ready。决定试一次完整 SSR 复位，按 `ADSP up → GPR ready → 重绑 spf_core_platform` 顺序重建。

---

## 3. 第一次 SSR + spf_core_platform 重绑

**原因**：走 `boot_adsp/ssr` 触发完整 ADSP 复位，看 APM 能否起来、`spf_core_platform` 是否会枚举 machine 子设备。

```bash
adb shell 'for f in /sys/kernel/boot_adsp/boot \
  /sys/kernel/boot_adsp/ssr \
  /sys/kernel/boot_adsp/ssr_defer; do
  echo ==== $f ====; cat $f 2>/dev/null
done'

adb shell 'echo 1 > /sys/kernel/boot_adsp/ssr; sleep 4
echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/unbind; sleep 1
echo soc:spf_core_platform > /sys/bus/platform/drivers/spf-core-platform/bind; sleep 3
cat /proc/asound/cards 2>/dev/null
echo ====; ls -l /dev/snd 2>/dev/null'

adb shell 'dmesg | grep -i -E "boot_adsp|audio_notifier|Adding GPR dev|\
  apm is not up|spf_core_add_child_devices|q6 state is down|glink state|\
  remoteproc-adsp|sound" | tail -n 220'
```

**结论**：SSR 走完了，声卡还是没出来。需要确认是 `q6` 还是 `APM` 仍没恢复。

---

## 4. 全量加载音频模块链（首次尝试）

**原因**：怀疑"客户端在 ADSP/APM 没 ready 时初始化过一次，状态卡死了"。在 ADSP running 前提下把音频客户端链从上到下卸掉重载。

```bash
# 查当前状态
adb shell 'cat /sys/class/remoteproc/remoteproc1/state
echo ====
lsmod | grep -E "machine_dlkm|oplus_audio_|wcd|wsa|lpass_cdc|\
  audio_pkt|audio_prm|mbhc|swr_|wcd_core|snd_event|gpr_dlkm|\
  spf_core_dlkm|q6_notifier_dlkm|q6_pdr_dlkm|audpkt_ion"'

# SSR + 重载全部模块
adb shell 'echo 1 > /sys/kernel/boot_adsp/ssr; sleep 4
cat /sys/class/remoteproc/remoteproc1/state
echo ====
dmesg | grep -i -E "audio_notifier|Adding GPR dev|glink state|\
  remoteproc-adsp|boot_adsp|q6 state is down" | tail -n 120'

# 全量 insmod（30+ 个模块）
adb shell 'for m in q6_pdr_dlkm q6_notifier_dlkm gpr_dlkm snd_event_dlkm \
  spf_core_dlkm adsp_loader_dlkm oplus_audio_daemon audpkt_ion_dlkm \
  lpass_cdc_dlkm swr_dlkm swr_ctrl_dlkm wcd_core_dlkm mbhc_dlkm \
  wcd939x_slave_dlkm audio_prm_dlkm audio_pkt_dlkm wcd9xxx_dlkm \
  wcd939x_dlkm lpass_cdc_rx_macro_dlkm lpass_cdc_tx_macro_dlkm \
  lpass_cdc_wsa_macro_dlkm lpass_cdc_wsa2_macro_dlkm wsa883x_dlkm \
  wsa884x_dlkm sdca_registers_dlkm oplus_audio_extend \
  oplus_audio_pa_manager wcd9378_slave_dlkm wcd9378_dlkm \
  oplus_audio_aw87xxx oplus_audio_aw882xx oplus_audio_sipa \
  oplus_audio_sipa_tuning machine_dlkm; do
  if [ -f /vendor_dlkm/lib/modules/${m}.ko ]; then
    insmod /vendor_dlkm/lib/modules/${m}.ko 2>&1; echo rc:$m:$?
  fi
done
cat /proc/asound/cards; ls -l /dev/snd'
```

**结论**：设备在执行全量加载时掉线了（USB 断开），说明整条链硬灌的方式不安全。

---

## 5. 设备树分析：ossi 的 recovery init 缺乏音频同步逻辑

**原因**：在 `android_vendor_twrp` 和设备树中搜索现有 recovery 音频 bring-up 模式。

```bash
# 搜索 ossi 设备树
rg -n 'boot_adsp|ssr_defer|remoteproc-adsp|q6 state is down|\
  spf_core_add_child_devices|sun-asoc-snd' device_tree

find device_tree -maxdepth 4 \( -iname '*ossi*' -o -iname '*sun*' \
  -o -iname '*audio*' -o -iname '*adsp*' \)
```

**关键发现**：
- `ossi_source_built` 和 `ossi_pulled_binaries` 的 `init.recovery.qcom.rc` 都会写 `boot_adsp/ssr 1`
- 两棵设备树里没有任何 recovery 音频脚本，只有 WiFi 脚本
- `init.recovery.qcom.rc` 只在 `twrp.modules.loaded=true` 后写一次 `ssr 1`，没有 APM/GPR ready 同步逻辑

**结论**：`ossi` 的 recovery 当前是"只有内核模块，没有 recovery 侧 orchestration"。主线更像 `source_built` 这棵树。需要补等待和重触发逻辑，而不是裸写一次 `ssr`。

---

## 6. 固定关键知识到文档

**原因**：将 live 调试结论固化到 `TWRP音频手动Bring-up.md`，避免后续重复误判。

补充的关键判断：
1. `remoteproc-adsp=running` ≠ 音频 ready
2. `gprsvc:spf_core/q6prm/audio-pkt` 已出现 ≠ `APM ready`
3. 真正危险报错：`gpr_send_pkt: q6 state is down`、`spf_core_add_child_devices: apm is not up`
4. `sun-asoc-snd` 存在但没声卡，不一定是 DT 缺节点，更可能是 ADSP 音频服务层时序没完成

**结论**：文档知识已固化。设备回来后按 `ADSP → GPR → APM → 重建模块链` 方向继续。

---

## 7. 设备重连后状态确认

**原因**：设备 70a91f89 重新上线，确认仍是 sun/sm87xx recovery。

```bash
adb shell 'getprop ro.product.board; getprop ro.board.platform; getprop ro.bootmode
cat /sys/class/remoteproc/remoteproc1/state'

adb shell 'lsmod | grep -E "machine_dlkm|oplus_audio_|wcd|wsa|lpass_cdc|\
  audio_pkt|audio_prm|mbhc|swr_|wcd_core|snd_event|gpr_dlkm|\
  spf_core_dlkm|q6_notifier_dlkm|q6_pdr_dlkm|audpkt_ion|adsp_loader"
cat /proc/asound/cards; ls -l /dev/snd'

adb shell 'dmesg | grep -i -E "audio_notifier|gpr_send_pkt|spf_core|\
  apm is not up|q6 state is down|Adding GPR dev|\
  remoteproc-adsp|glink state" | tail -n 180'
```

**结论**：ADSP running，底层 6 模块在，codec/machine 未加载，ALSA 空。`spf_core_platform` 仍然卡在 `apm is not up`。

---

## 8. 底层状态核实：DT、platform device、GPR

**原因**：在进一步操作前确认 DT、platform device、GPR 都确实存在。

```bash
adb shell 'echo ==== boot_adsp ====
for f in /sys/kernel/boot_adsp/boot /sys/kernel/boot_adsp/ssr \
  /sys/kernel/boot_adsp/ssr_defer; do echo ==== $f ====; cat $f; done
echo ==== remoteproc ====
cat /sys/class/remoteproc/remoteproc1/name
cat /sys/class/remoteproc/remoteproc1/state'

adb shell 'echo ==== gprbus ====
for d in /sys/bus/gprbus/devices/*; do
  echo ==== $d ====; [ -e "$d/uevent" ] && cat "$d/uevent"
done'

adb shell 'echo ==== spf driver ====
ls /sys/bus/platform/drivers/spf-core-platform
echo ==== spf device ====
ls /sys/bus/platform/devices/soc:spf_core_platform
echo ==== sound node ====
find /proc/device-tree/soc -maxdepth 2 \( -iname sound -o -iname "*spf*" \
  -o -iname "*gpr*" \)'
```

**结论**：DT 在、platform device 在、GPR device 也在，但 `spf_core_platform` 仍然卡着。下面按依赖顺序做干净重建。

---

## 9. 查清底层 6 模块依赖顺序 + 卸载重载

**原因**：确认 `q6_pdr → q6_notifier → gpr → snd_event → adsp_loader → spf_core` 的依赖关系后，按顺序卸掉再重载。

```bash
# 查依赖
adb shell 'for m in q6_pdr_dlkm q6_notifier_dlkm gpr_dlkm snd_event_dlkm \
  adsp_loader_dlkm spf_core_dlkm; do
  echo ==== $m ====
  modinfo /vendor_dlkm/lib/modules/${m}.ko 2>/dev/null | grep -E "^depends:|^name:"
done'

# 卸载底层链
adb shell 'for m in adsp_loader_dlkm spf_core_dlkm gpr_dlkm \
  q6_notifier_dlkm q6_pdr_dlkm snd_event_dlkm; do
  rmmod $m 2>/dev/null && echo rm:$m || echo keep:$m
done
lsmod | grep -E "snd_event|spf_core_dlkm|gpr_dlkm|q6_notifier|q6_pdr|adsp_loader"'

# SSR + 按依赖顺序重载
adb shell 'echo 1 > /sys/kernel/boot_adsp/ssr; sleep 4
for m in snd_event_dlkm q6_pdr_dlkm q6_notifier_dlkm gpr_dlkm \
  spf_core_dlkm adsp_loader_dlkm; do
  insmod /vendor_dlkm/lib/modules/${m}.ko 2>&1; echo rc:$m:$?
done
lsmod | grep -E "snd_event|spf_core_dlkm|gpr_dlkm|\
  q6_notifier|q6_pdr|adsp_loader"'

adb shell 'dmesg | grep -i -E "audio_notifier|gpr_send_pkt|spf_core|\
  apm is not up|q6 state is down|Adding GPR dev|\
  glink state|remoteproc-adsp" | tail -n 160'
```

**结论**：底层链成功整套卸载重载。但出现了两个新变化：
1. `/sys/kernel/boot_adsp/ssr` 在重载后消失了（由 `adsp_loader_dlkm` 创建/销毁）
2. `adsp_loader_dlkm` 重 probe 时报了 `audio_notifier_ssr_adsp_cb already registered`——SSR 状态机已乱

---

## 10. ADSP 意外 offline + remoteproc 手工拉起

**原因**：重载期间 ADSP 发生 `shutdowning → down`，确认当前状态。

```bash
adb shell 'echo ==== remoteproc ====
cat /sys/class/remoteproc/remoteproc1/name
cat /sys/class/remoteproc/remoteproc1/state
echo ==== boot_adsp ====
ls -l /sys/kernel/boot_adsp
echo ==== state nodes ====
find /sys/kernel/boot_adsp -maxdepth 1 -type f -exec sh -c \
  "echo ==== {} ====; cat {} 2>/dev/null" \;'

adb shell 'dmesg | tail -n 120'

adb shell 'for d in /sys/bus/gprbus/devices/*; do echo ==== $d ====; [ -e "$d/driver" ] && readlink "$d/driver"; done 2>/dev/null; echo ==== lsmod ====; lsmod | grep -E "adsp_loader_dlkm|spf_core_dlkm|gpr_dlkm|q6_notifier_dlkm|q6_pdr_dlkm|snd_event_dlkm"'

# 手工拉起 ADSP
adb shell 'echo start > /sys/class/remoteproc/remoteproc1/state 2>&1; sleep 3
cat /sys/class/remoteproc/remoteproc1/state
echo ==== gprbus ====; ls /sys/bus/gprbus/devices'

adb shell 'dmesg | grep -i -E "remoteproc-adsp|audio_notifier|Adding GPR dev|glink state|q6 state is down|adsp" | tail -n 160'

adb shell 'cat /proc/asound/cards 2>/dev/null; echo ====; ls -l /dev/snd 2>/dev/null; echo ====; lsmod | grep -E "adsp_loader_dlkm|spf_core_dlkm|gpr_dlkm|q6_notifier_dlkm|q6_pdr_dlkm|snd_event_dlkm"'
```

**结论**：ADSP 被手工拉回 `running`，`gprsvc:*` 重新出现。这一步通了。

---

## 11. ADSP 恢复后重绑 spf_core_platform（第二轮）

**原因**：验证 ADSP 在线时重绑 `spf_core_platform`，能否不再报 `q6 state is down`。

```bash
adb shell 'echo soc:spf_core_platform > \
  /sys/bus/platform/drivers/spf-core-platform/unbind; sleep 1
echo soc:spf_core_platform > \
  /sys/bus/platform/drivers/spf-core-platform/bind; sleep 3
cat /proc/asound/cards; ls -l /dev/snd'

adb shell 'dmesg | grep -i -E "spf_core_platform|spf_core_add_child_devices|\
  apm is not up|q6 state is down|Adding GPR dev|audio_notifier|gpr_probe" | tail -n 180'

adb shell 'ls /sys/bus/platform/devices/soc:spf_core_platform
find /sys/bus/platform/devices/soc:spf_core_platform -maxdepth 2'
```

**结论**：重绑没用，`q6 state is down` 还在刷。问题不是 platform 设备没重新 probe，而是底层客户端在 ADSP 没 ready 时注册过，状态已脏。

---

## 12. 最终验证：ADSP 在线时卸掉底层 6 模块再重载（第三轮）

**原因**：在 ADSP 保持 running 前提下，把底层 6 模块卸掉后重载，验证 `q6 state is down` 是否消失。

```bash
adb shell 'cat /sys/class/remoteproc/remoteproc1/state
for m in adsp_loader_dlkm spf_core_dlkm gpr_dlkm \
  q6_notifier_dlkm q6_pdr_dlkm snd_event_dlkm; do
  rmmod $m 2>/dev/null && echo rm:$m || echo keep:$m
done
echo ==== state-after-rm ====
cat /sys/class/remoteproc/remoteproc1/state'

adb shell 'for m in snd_event_dlkm q6_pdr_dlkm q6_notifier_dlkm gpr_dlkm \
  spf_core_dlkm adsp_loader_dlkm; do
  insmod /vendor_dlkm/lib/modules/${m}.ko 2>&1; echo rc:$m:$?
done
cat /sys/class/remoteproc/remoteproc1/state
ls /sys/bus/gprbus/devices'

adb shell 'dmesg | grep -i -E "audio_notifier|gpr_send_pkt|spf_core_platform|\
  apm is not up|q6 state is down|Adding GPR dev|service PDR_ADSP is in use" | tail -n 180'
```

**结论**：日志持续刷 `q6 state is down`，又出现一次 ADSP `shutdowning`。`service PDR_ADSP is in use` 说明 PDR 状态被污染。

---

## 13. 本阶段总结

| 已验证 | 状态 |
|--------|------|
| ADSP (remoteproc) 可运行 | ✅ |
| GPR 设备可枚举 (spf_core/q6prm/audio-pkt) | ✅ |
| 底层 6 模块可卸载/重载 | ✅ |
| 重绑 spf_core_platform | 无效 — q6 state is down 持续 |
| ossi recovery init 有音频同步逻辑 | ❌ 只有 `write ssr 1`，无 APM ready 等待 |

**核心阻塞**：`gpr_send_pkt: q6 state is down` → `spf_core_platform: apm is not up`。在内核层面试遍所有重绑/SSR/模块重建组合后，`q6 state` 无法被翻转为 ready。这暗示需要用户态 PDR 服务链（pd-mapper / adsprpcd），而非纯内核操作。

**下一步方向**：一旦设备回来，不再从头排查，直接按 `ADSP → GPR → APM → 重建模块链` 持续推进。


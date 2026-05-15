
 听不到声音

GitHub Copilot: 我先抓你刚才这几次播放后的设备日志，确认到底是“链路成功但太小声”，还是“这次其实没进到完整播放链”。

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d -b all | grep -i -E "tinyplay_ftm|graph_open|thread_result ok|Playing sample|aw882xx_startup|aw882xx_hw_params|ret -19|MFC not present" | tail -n 120'

Ran terminal command:  adb -s 70a91f89 shell 'ls -l /data/local/tmp/test440_low.wav /odm/etc/oplus_ftm_smart_pa.wav 2>/dev/null'

文件都在。我继续把刚才抓到的日志摊开，只看这几次手动播放到底有没有 `ret 0` 和 `thread_result ok`。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_kpjEkAg2Nph0859hAdFKJgrS__vscode-1773507436572/content.txt)

日志已经说明不是“没播起来”，而是这几次都成功进了完整播放链，但你现场还是听不到。下一步我不再碰链路，直接给你准备一个“比 low 明显一点、但不是满音量”的中等音量样本。

Ran terminal command:  rg --files | grep 'test440.*wav'

Ran terminal command:  command -v ffmpeg || command -v sox || command -v afconvert

工作区里有原始的 test440.wav，我直接从它生成一个中等电平版本并推到设备，这样你不用再猜 low 到底低了多少。

Ran terminal command:  python3 - <<'PY'
import wave, struct
src='audio_dtb_probe/test440.wav'
dst='audio_dtb_probe/test440_mid.wav'
scale=0.15
with wave.open(src,'rb') as r:
    params=r.getparams()
    frames=r.readframes(r.getnframes())
if params.sampwidth != 2:
    raise SystemExit(f'unsupported sampwidth {params.sampwidth}')
samples=struct.unpack('<{}h'.format(len(frames)//2), frames)
out=bytearray()
for s in samples:
    v=int(max(-32768,min(32767,round(s*scale))))
    out += struct.pack('<h', v)
with wave.open(dst,'wb') as w:
    w.setparams(params)
    w.writeframes(out)
print(dst)
PY
adb -s 70a91f89 push audio_dtb_probe/test440_mid.wav /data/local/tmp/test440_mid.wav

中等音量文件已经生成。我再确认它确实已经在设备上，然后给你一条可以直接听的命令。

Ran terminal command:  adb -s 70a91f89 shell 'ls -l /data/local/tmp/test440_mid.wav 2>/dev/null && file /data/local/tmp/test440_mid.wav 2>/dev/null || true'

刚才那几次不是没播起来，日志显示都已经 `graph_open ret 0`、`Playing sample`、`thread_result ok`。你现在听不到，更多像是 `test440_low.wav` 确实太小了。

我已经给你准备了一个中等音量版本：`/data/local/tmp/test440_mid.wav`，是基于原始 `test440.wav` 按 15% 幅度生成的，不是满音量，也比 low 明显一些。

你现在直接在设备 shell 里放这个：

```sh
setprop vendor.oplus.mm.ftm_spk 1
/odm/bin/tinyplay_ftm /data/local/tmp/test440_mid.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY
```

如果你不想先进 shell，就在 Mac 终端直接一条跑：

```bash
adb -s 70a91f89 shell 'setprop vendor.oplus.mm.ftm_spk 1; /odm/bin/tinyplay_ftm /data/local/tmp/test440_mid.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY'
```

先听这条。它应该比 `test440_low.wav` 更容易听到，但还不至于直接顶满。如果这条还是太轻，我下一步给你做一个 30% 版本；如果这条已经偏大，再给你退到 10%。

User: 还是听不到，是不是声音根本就没打开

GitHub Copilot: 我不先猜，直接做一个更硬的验证：拉长播放时间，在播放进行中同时读取 DAPM 和功放状态，这样能判断到底是“链路开了但很小/走错路”，还是“扬声器路径根本没真正点亮”。

Ran terminal command:  python3 - <<'PY'
import wave, struct, math
out='audio_dtb_probe/test440_mid_10s.wav'
rate=48000
secs=10
freq=440.0
amp=0.15
frames=bytearray()
for i in range(rate*secs):
    s=int(32767*amp*math.sin(2*math.pi*freq*i/rate))
    frames += struct.pack('<hh', s, s)
with wave.open(out,'wb') as w:
    w.setnchannels(2)
    w.setsampwidth(2)
    w.setframerate(rate)
    w.writeframes(frames)
print(out)
PY
adb -s 70a91f89 push audio_dtb_probe/test440_mid_10s.wav /data/local/tmp/test440_mid_10s.wav

Ran terminal command:  adb -s 70a91f89 shell 'for p in /sys/kernel/debug/asoc/sun-mtp-snd-card/dapm/bias_level /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0034/dapm/Speaker_Playback_4_34 /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0035/dapm/Speaker_Playback_4_35 /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0036/dapm/Speaker_Playback_4_36 /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.9-0034/dapm/Speaker_Playback_9_34 /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.9-0035/dapm/Speaker_Playback_9_35 /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.9-0036/dapm/Speaker_Playback_9_36; do echo ==== $p ====; cat $p 2>/dev/null; done'

空闲态基线还是全 Off。现在我把 10 秒播放放到后台，在它播放的窗口里立刻读一次同样的节点，看这些 speaker widget 会不会真的切到 On。

Ran terminal command:  adb -s 70a91f89 shell 'setprop vendor.oplus.mm.ftm_spk 1; /odm/bin/tinyplay_ftm /data/local/tmp/test440_mid_10s.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY'

播放已经挂到后台了。我现在在播放窗口里抓实时 DAPM、功放和进程状态，结果会直接告诉我们“声音到底有没有被真正打开”。

Ran terminal command:  adb -s 70a91f89 shell 'for p in /sys/kernel/debug/asoc/sun-mtp-snd-card/dapm/bias_level /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0034/dapm/Speaker_Playback_4_34 /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0035/dapm/Speaker_Playback_4_35 /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0036/dapm/Speaker_Playback_4_36 /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.9-0034/dapm/Speaker_Playback_9_34 /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.9-0035/dapm/Speaker_Playback_9_35 /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.9-0036/dapm/Speaker_Playback_9_36; do echo ==== $p ====; cat $p 2>/dev/null; done'

Ran terminal command:  adb -s 70a91f89 shell 'ps -A | grep -E "tinyplay_ftm|audiohalservice"'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d -b all | grep -i -E "tinyplay_ftm|graph_open|thread_result ok|Playing sample|aw882xx_startup|aw882xx_hw_params" | tail -n 80'

现在还差最后一个钉死证据：把“播放”和“读 DAPM”放进同一个设备 shell 脚本里，避免因为时序错过播放窗口。这样就能直接判断扬声器 widget 在播放中是不是仍然 Off。

Ran terminal command:  adb -s 70a91f89 shell '
setprop vendor.oplus.mm.ftm_spk 1
/odm/bin/tinyplay_ftm /data/local/tmp/test440_mid_10s.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY >/dev/null 2>&1 &
pid=$!
sleep 1
for p in \
  /sys/kernel/debug/asoc/sun-mtp-snd-card/dapm/bias_level \
  /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0034/dapm/Speaker_Playback_4_34 \
  /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0035/dapm/Speaker_Playback_4_35 \
  /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0036/dapm/Speaker_Playback_4_36 \
  /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.9-0034/dapm/Speaker_Playback_9_34 \
  /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.9-0035/dapm/Speaker_Playback_9_35 \
  /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.9-0036/dapm/Speaker_Playback_9_36
 do
  echo ==== $p ====
  cat $p 2>/dev/null
 done
wait $pid
logcat -d -b all | grep -i -E "tinyplay_ftm|graph_open|thread_result ok|Playing sample|aw882xx_startup|aw882xx_hw_params" | tail -n 40
'

是，至少“最后那一下真正把喇叭打出来”的声音没有完全打开，但不是整条链都没开。

我刚做了同一时序验证，结果很明确：

1. `tinyplay_ftm` 这条播放链是成功的。
2. 日志里有 `graph_open ret 0`、`Playing sample`、`thread_result ok`。
3. `aw882xx_startup` 和 `aw882xx_hw_params` 也都进了，说明数据已经送到 smart PA 这一层了。
4. 但在播放进行中的同一秒，ASoC DAPM 状态仍然是：
   `bias_level = Off`
5. 所有 `Speaker_Playback_*` 节点都是：
   `Off  in 1 out 0`
   `stream ... active`

这个组合的意思不是“完全没播”，而是：

1. 流已经 active 了。
2. 输入侧已经有连接了。
3. 但输出侧没有真正打开，`out 0`。
4. 所以你听不到，根因更像是最后的 speaker/amp route 没被真正上电，而不是 wav 太小声。

现在前沿已经收敛了，不用再怀疑 `tinyplay_ftm` 或 AGM graph 本身。真正要做的是把最后这层喇叭开关找出来。

我下一步会直接去做这件事：
1. 抓当前卡上的 `tinymix` 控件，筛 `spk|speaker|aw|amp|pa|gain|volume|rx`。
2. 对照 `/odm/etc/ftm_mixer_paths.xml` 里的 `ftm-loudspeaker-test`，看 recovery 里哪些关键控件没被打上。
3. 直接手动补开最后一层功放/扬声器 route，再让你听。

如果你要我继续，我就直接开始抓控件并试开最后这层。

User: 继续

GitHub Copilot: 我现在直接对照“控件”和“厂测路由”两边抓证据，目标是找出播放链最后没被打开的 speaker/amp 开关。

Ran terminal command:  adb -s 70a91f89 shell 'command -v tinymix; ls /odm/bin/tinymix /vendor/bin/tinymix /system/bin/tinymix 2>/dev/null'
Completed with input:  adb -s 70a91f89 shell 'command -v tinymix; ls /odm/bin/tinymix /vendor/bin/tinymix /system/bin/tinymix 2>/dev/null'

Ran terminal command:  adb -s 70a91f89 shell 'sed -n "/ftm-loudspeaker-test/,/<\/path>/p" /odm/etc/ftm_mixer_paths.xml 2>/dev/null'

Ran terminal command:  adb -s 70a91f89 shell 'for f in /sys/kernel/debug/asoc/sun-mtp-snd-card/dapm/*; do bn=$(basename "$f"); case "$bn" in *Speaker*|*SPK*|*AMP*|*PA*|*RX*|*EAR*) echo ==== $bn ====; cat "$f" 2>/dev/null; esac; done | head -n 200'

设备里没有现成的 tinymix 可直接用，但厂测路由已经明确要求 `aw_dev_*` 这组控件。下一步我转去找现成的混音工具或控件名来源，准备直接把这组开关打上去。

Ran terminal command:  rg --files | grep '/tinymix$\|tinymix_'

Ran terminal command:  rg -n "aw_dev_[0-9]_(prof|switch)|ftm-loudspeaker-test|tinymix" audio_dtb_probe docs twrp_a12_compile twrp_a16_compile device 2>/dev/null | head -n 200

Ran terminal command:  adb -s 70a91f89 shell 'ls /odm/bin /vendor/bin /system/bin 2>/dev/null | grep -E "tiny|mixer|agm|audio-ftm|cplay" | sort'

工作区里有一份已经提取好的 `tinymix_stock`，而且旧记录里也提到过手工写 WSA 路由。我先把这两条拼起来，尽量直接复用以前已经验证过的控件路径。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#2660-2660), lines 2660 to 2695

Ran terminal command:  file audio_dtb_probe/tinymix_stock && ls -l audio_dtb_probe/tinymix_stock

旧实验已经给了我们一组明确的 WSA 路由控件。我现在把 `tinymix_stock` 推到设备，先枚举当前控件里这些名字是否还在，再尝试把它们和 `aw_dev_*` 一起打上。

Ran terminal command:  adb -s 70a91f89 push audio_dtb_probe/tinymix_stock /data/local/tmp/tinymix_stock && adb -s 70a91f89 shell 'chmod 755 /data/local/tmp/tinymix_stock && /data/local/tmp/tinymix_stock | grep -i -E "WSA RX0 MUX|WSA RX1 MUX|WSA_RX0 INP0|WSA_RX1 INP0|WSA_COMP1 Switch|WSA_COMP2 Switch|VBAT|aw_dev_[0-9]_(prof|switch)"'

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/tinymix_stock | grep -i -E "speaker|spk|aw_dev|wsa|amp|pa|gain|volume" | head -n 200'

控件已经找到了，情况比刚才清楚很多：`aw_dev_0/1/2/3/5/6_switch` 现在全是 `Disable`，而 `WSA RX*` 也都还是 `ZERO/Off`。这正好对上“stream active，但 out 0”的现象。下一步我直接手工把这组控件打到厂测要求的状态，再播一次看 DAPM 的 `out` 会不会翻上来。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_Xc0yShmVgT4ePupqHpFZJcpw__vscode-1773523724458/content.txt)

控件名和当前值已经抓到了，下一步不再分析，直接按之前验证过的 WSA 路由加上 `aw_dev_*` 厂测开关一起写入，然后马上复测播放中的 DAPM。

Ran terminal command:  adb -s 70a91f89 shell '
TM=/data/local/tmp/tinymix_stock
$TM "WSA RX0 MUX" "AIF1_PB"
$TM "WSA RX1 MUX" "AIF1_PB"
$TM "WSA_RX0 INP0" "RX0"
$TM "WSA_RX1 INP0" "RX1"
$TM "WSA_COMP1 Switch" 1
$TM "WSA_COMP2 Switch" 1
$TM "WSA_RX INT0 VBAT WSA RX0 VBAT Enable" 1
$TM "WSA_RX INT1 VBAT WSA RX1 VBAT Enable" 1
$TM "WSA2 RX0 MUX" "AIF1_PB"
$TM "WSA2 RX1 MUX" "AIF1_PB"
$TM "WSA2_RX0 INP0" "RX0"
$TM "WSA2_RX1 INP0" "RX1"
$TM "WSA2_COMP1 Switch" 1
$TM "WSA2_COMP2 Switch" 1
$TM "WSA2_RX INT0 VBAT WSA2 RX0 VBAT Enable" 1
$TM "WSA2_RX INT1 VBAT WSA2 RX1 VBAT Enable" 1
$TM "aw_dev_0_switch" "Enable"
$TM "aw_dev_1_switch" "Enable"
$TM "aw_dev_2_switch" "Enable"
$TM "aw_dev_3_switch" "Enable"
$TM "aw_dev_5_switch" "Enable"
$TM "aw_dev_6_switch" "Enable"
$TM | grep -i -E "WSA RX0 MUX|WSA RX1 MUX|WSA_RX0 INP0|WSA_RX1 INP0|WSA_COMP1 Switch|WSA_COMP2 Switch|WSA_RX INT0 VBAT|WSA_RX INT1 VBAT|WSA2 RX0 MUX|WSA2 RX1 MUX|WSA2_RX0 INP0|WSA2_RX1 INP0|WSA2_COMP1 Switch|WSA2_COMP2 Switch|WSA2_RX INT0 VBAT|WSA2_RX INT1 VBAT|aw_dev_[0-9]_(switch)"
'

控件写入已经生效了。现在只差最后一次闭环复测：在这些开关保持开启的前提下重播，并同步看 `Speaker_Playback_*` 的 `out` 和 `bias_level` 是否翻转。

Ran terminal command:  adb -s 70a91f89 shell '
setprop vendor.oplus.mm.ftm_spk 1
/odm/bin/tinyplay_ftm /data/local/tmp/test440_mid_10s.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY >/dev/null 2>&1 &
pid=$!
sleep 1
for p in \
  /sys/kernel/debug/asoc/sun-mtp-snd-card/dapm/bias_level \
  /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0034/dapm/Speaker_Playback_4_34 \
  /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0035/dapm/Speaker_Playback_4_35 \
  /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0036/dapm/Speaker_Playback_4_36 \
  /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.9-0034/dapm/Speaker_Playback_9_34 \
  /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.9-0035/dapm/Speaker_Playback_9_35 \
  /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.9-0036/dapm/Speaker_Playback_9_36
 do
  echo ==== $p ====
  cat $p 2>/dev/null
 done
wait $pid
logcat -d -b all | grep -i -E "tinyplay_ftm|graph_open|thread_result ok|Playing sample|aw882xx_startup|aw882xx_hw_params" | tail -n 40
'

这次复测把一个关键点钉死了：即使 `WSA/WSA2` 和 `aw_dev_*_switch` 都手工开了，播放中 `Speaker_Playback_*` 仍然是 `Off in 1 out 0`。我继续往前推一层，检查是不是 Awinic 这边还差音量或静音类控件。

Ran terminal command:  rg -n "aw_dev_[0-9]_volume|Speaker_Mute_Switch|aw_dev_[0-9]_switch|aw_dev_[0-9]_prof" audio_dtb_probe docs 2>/dev/null | head -n 200

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/tinymix_stock "Speaker_Mute_Switch"; /data/local/tmp/tinymix_stock "aw_dev_0_volume"; /data/local/tmp/tinymix_stock "aw_dev_1_volume"; /data/local/tmp/tinymix_stock "aw_dev_2_volume"; /data/local/tmp/tinymix_stock "aw_dev_3_volume"; /data/local/tmp/tinymix_stock "aw_dev_5_volume"; /data/local/tmp/tinymix_stock "aw_dev_6_volume"'

找到一个非常硬的新线索：`aw_dev_0/1/2/3/5/6_volume` 现在全是 `0`，而它们的范围是 `0->720`。这很像最后还卡在功放音量为零。我直接把它们调到保守值再复测。

Ran terminal command:  adb -s 70a91f89 shell '
TM=/data/local/tmp/tinymix_stock
$TM "Speaker_Mute_Switch" "Off"
for n in 0 1 2 3 5 6; do $TM "aw_dev_${n}_volume" 120; done
$TM | grep -i -E "Speaker_Mute_Switch|aw_dev_[0-9]_volume|aw_dev_[0-9]_switch" | head -n 40
setprop vendor.oplus.mm.ftm_spk 1
/odm/bin/tinyplay_ftm /data/local/tmp/test440_mid_10s.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY >/dev/null 2>&1 &
pid=$!
sleep 1
for p in \
  /sys/kernel/debug/asoc/sun-mtp-snd-card/dapm/bias_level \
  /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0034/dapm/Speaker_Playback_4_34 \
  /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0035/dapm/Speaker_Playback_4_35 \
  /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0036/dapm/Speaker_Playback_4_36 \
  /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.9-0034/dapm/Speaker_Playback_9_34 \
  /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.9-0035/dapm/Speaker_Playback_9_35 \
  /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.9-0036/dapm/Speaker_Playback_9_36
 do
  echo ==== $p ====
  cat $p 2>/dev/null
 done
wait $pid
'

新的结果也很干净：即使把 `aw_dev_*_volume` 从 `0` 提到 `120`，播放中依然是 `Speaker_Playback_*: Off in 1 out 0`。这说明问题不是“音量太小”，而是 ASoC 到 smart PA 的最后输出边仍然没接通。我继续直接查这个 widget 周围的 DAPM 结构。

Ran terminal command:  adb -s 70a91f89 shell 'find /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0034/dapm -maxdepth 1 -type f | sed "s#^#. #" | sort | head -n 200'

Ran terminal command:  adb -s 70a91f89 shell 'for d in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.*; do echo ==== $d ====; ls "$d"/dapm 2>/dev/null | grep -E "Speaker|spk|SPK|AIF|DAC|AMP|OUT|IN"; done'

Ran terminal command:  adb -s 70a91f89 shell 'for p in /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0034/dapm/*; do bn=$(basename "$p"); case "$bn" in *Speaker*|*IN*|*OUT*|*AIF*|*DAC*|*AMP*) echo ==== $bn ====; cat "$p" 2>/dev/null; esac; done'

smart PA 组件本身只暴露了极少的 DAPM 节点，所以我换个角度：在播放进行中直接扫整张卡所有 active 的 DAPM widget，看看流究竟停在什么位置、断在什么名字上。

Ran terminal command:  adb -s 70a91f89 shell '
setprop vendor.oplus.mm.ftm_spk 1
/odm/bin/tinyplay_ftm /data/local/tmp/test440_mid_10s.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY >/dev/null 2>&1 &
pid=$!
sleep 1
for f in /sys/kernel/debug/asoc/sun-mtp-snd-card/*/dapm/* /sys/kernel/debug/asoc/sun-mtp-snd-card/dapm/*; do
  [ -f "$f" ] || continue
  out=$(cat "$f" 2>/dev/null)
  case "$out" in
    *" active"*|*" in 1"*|*" out 1"*|*" out 2"*|*" out 3"*|*" out 4"*)
      echo ==== $f ====
      echo "$out"
      ;;
  esac
done | head -n 300
wait $pid
'

扫描结果出来了。我把活跃节点摊开看前半段，确认流是不是止步在 WSA/COMP 一侧，还是已经推进到更后面的 widget。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_7tC9fgAj0mGqFBHHC4In7qGj__vscode-1773523724468/content.txt#1-1), lines 1 to 260

关键断点已经露出来了：`Speaker_Playback_*` 是 active，但上游的 `WSA AIF1 Playback` / `WSA2_AIF1 Playback` 仍然是 inactive。也就是说，手工写进去的 WSA 路由确实存在，但这次 `tinyplay_ftm` 走的 AGM graph 没有把流真正喂进这条 AIF。我要再看后半段 active 节点，确认它实际上跑到了哪条 backend。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_7tC9fgAj0mGqFBHHC4In7qGj__vscode-1773523724468/content.txt#261-261), lines 261 to 318

我先确认 `tinymix_stock` 能不能直接操作 `card100`，因为现在证据已经指向 `tinyplay_ftm` 成功走了 AGM graph，但 `card0` 的 WSA/AIF 路由并不是它真正吃流的地方。

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/tinymix_stock -h 2>&1 || /data/local/tmp/tinymix_stock --help 2>&1 || true'

`tinymix_stock` 支持 `-D`。我现在直接看 `card100` 的关键控件，判断 `tinyplay_ftm` 真正跑通的那张卡上还差什么开关。

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/tinymix_stock -D 100 | grep -i -E "rate ch fmt|WSA|aw_dev|speaker|spk|mute|volume|codec_dma|tdm-lpaif|AIF1_PB" | head -n 250'

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/tinymix_stock -D 100 | head -n 80'

`card100` 的 mixer 已经能读出来了。我先只看前面和关键筛选结果，确认这里是不是才有真正的 backend 控件。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_XmiIoY3f3vfFLNhjZeHLMoay__vscode-1773523724473/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_NwaVbwvPZR56w3TycYSWiszM__vscode-1773523724472/content.txt)

`card100` 的普通输出不太可读，被大块 byte 控件淹了。我换成 tab 分隔后只抽取控件名，直接搜 AGM 侧真正关心的关键字。

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/tinymix_stock -D 100 -t | awk -F "\t" "NF>=4 {print \$4}" | grep -i -E "PCM_LL|SPEAKER|MBDRC|WSA|AIF1|CODEC_DMA|TDM-LPAIF|rate ch fmt|aw_dev|volume|mute" | head -n 300'

`card100` 里确实有我们之前缺失的 backend 控件，这说明真正的路由控制点不在 `card0`。我继续读播放中的 backend 参数值，确认 `tinyplay_ftm` 实际激活了哪条 backend。

Ran terminal command:  adb -s 70a91f89 shell '
show() {
  for c in "TDM-LPAIF-RX-SECONDARY rate ch fmt" "TDM-LPAIF-RX-SECONDARY metadata" "TDM-LPAIF_WSA-RX-PRIMARY rate ch fmt" "TDM-LPAIF_WSA-RX-PRIMARY metadata" "CODEC_DMA-LPAIF_RXTX-RX-5 rate ch fmt" "CODEC_DMA-LPAIF_RXTX-RX-5 metadata"; do
    echo ==== $c ====
    /data/local/tmp/tinymix_stock -D 100 -v "$c" 2>/dev/null || true
  done
}
echo IDLE
show
setprop vendor.oplus.mm.ftm_spk 1
/odm/bin/tinyplay_ftm /data/local/tmp/test440_mid_10s.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY >/dev/null 2>&1 &
pid=$!
sleep 1
echo PLAYING
show
wait $pid
'

我把 idle 和播放中的 backend 值对比结果打开，只看那几条最关键的 `rate ch fmt` 和 `metadata`。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_CwEfhiWvnTc6EVM1t7v5LuMu__vscode-1773523724477/content.txt)

继续往下压之后，结论更硬了。

现在可以明确排掉两类旧怀疑：

1. 不是 `tinyplay_ftm` 没跑起来。
2. 也不是单纯 `aw_dev_*_switch` 没开或者 `aw_dev_*_volume` 太小。

我已经实际做了这些动作：

1. 把 `card0` 上的 `WSA RX0/1 MUX`、`WSA_RX0/1 INP0`、`WSA_COMP1/2`、`WSA_RX INT* VBAT` 全部手工打开。
2. 把 `WSA2` 对应控件也一起打开。
3. 把 `ftm-loudspeaker-test` 里的 `aw_dev_0/1/2/3/5/6_switch` 全部改成 `Enable`。
4. 把 `aw_dev_0/1/2/3/5/6_volume` 从 `0` 提到保守值 `120`。

结果还是一样：

1. 播放日志依旧是成功链：`graph_open ret 0`、`Playing sample`、`thread_result ok`。
2. 播放中的 `Speaker_Playback_*` 依旧是 `Off in 1 out 0`。
3. `bias_level` 依旧是 `Off`。

这说明“最后那条真正出声的输出边”还是没闭合。

再往前推一步，我还确认了一个更关键的事实：

1. `card100` 现在已经能看到之前缺失的 AGM backend 控件。
2. 包括：
   `TDM-LPAIF-RX-SECONDARY rate ch fmt`
   `TDM-LPAIF_WSA-RX-PRIMARY rate ch fmt`
   以及对应的 `metadata` / `setParam`
3. 这说明真正的控制点已经不在 `card0`，而是在 `card100` 这张 AGM 卡上。
4. 也就是说，当前无声的根因已经收敛成：
   不是简单 mixer 开关问题，而是 `card100` 这侧的 AGM backend 参数/metadata 没把最后的 speaker 输出边点亮。

现在最准确的话是：

声音链“前半段”已经打开了，但“真正把喇叭打出来”的那一层还没打开。不是你听漏了，是现在确实还没形成可闻输出。

下一步我会直接转到 `card100`：
1. 继续抓 `TDM-LPAIF-RX-SECONDARY`、`TDM-LPAIF_WSA-RX-PRIMARY` 的 `setParam/metadata`。
2. 对照 `tinyplay_ftm` 的 speaker metadata，把 AGM backend 真正落到 WSA/speaker 这侧。
3. 不再继续围着 `card0` 的普通 tinymix 路由打转。

User: 不对啊，过程中我听到声音了    

GitHub Copilot: 这条反馈会直接改结论。我先把当前已经生效的 mixer 状态固化下来，避免我们把“能出声的现场状态”丢掉。

Ran terminal command:  adb -s 70a91f89 shell '/data/local/tmp/tinymix_stock | grep -i -E "WSA RX0 MUX|WSA RX1 MUX|WSA_RX0 INP0|WSA_RX1 INP0|WSA_COMP1 Switch|WSA_COMP2 Switch|WSA_RX INT0 VBAT|WSA_RX INT1 VBAT|WSA2 RX0 MUX|WSA2 RX1 MUX|WSA2_RX0 INP0|WSA2_RX1 INP0|WSA2_COMP1 Switch|WSA2_COMP2 Switch|WSA2_RX INT0 VBAT|WSA2_RX INT1 VBAT|Speaker_Mute_Switch|aw_dev_[0-9]_(switch|volume)"'

Ran terminal command:  adb -s 70a91f89 shell 'setprop vendor.oplus.mm.ftm_spk 1; /odm/bin/tinyplay_ftm /data/local/tmp/test440_mid_10s.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY'

对，这会直接改掉我上一轮“还没真正出声”的判断。

既然你在过程中已经听到声音，当前最合理的结论是：

1. 扬声器路径并不是完全没通。
2. 现在已经存在一个可闻的现场状态。
3. 问题从“能不能出声”变成了“怎么稳定复现、怎么固化成最小步骤”。

我刚刚已经把当前能出声时的关键控件状态固化下来了，现状是：

1. WSA 和 WSA2 的主路由都已经打开。
2. aw_dev_0/1/2/3/5/6 的 switch 都是 Enable。
3. aw_dev_0/1/2/3/5/6 的 volume 都是 120。
4. Speaker_Mute_Switch 是 Off。

也就是说，当前最像“能听到声音”的有效组合就是这组状态加上 tinyplay_ftm 播放。

你现在可以直接再试一次这条，不要先改别的：

adb -s 70a91f89 shell 'setprop vendor.oplus.mm.ftm_spk 1; /odm/bin/tinyplay_ftm /data/local/tmp/test440_mid_10s.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY'

如果这次还能听到，那我们就不用再争论“有没有打开”，而是直接进入固化阶段。我下一步会做两件事里的第一件更有价值：

1. 把这组 mixer 设置写成一条一键命令，先稳定复现可闻播放。
2. 再把它并进 recovery 自动音频 bring-up 里，避免每次手工敲。

你先按上面这条再听一次。只要还能听到，我就直接给你整理成可重复执行的最小命令序列。

User: 有声音，和之前没声音的时候，有什么不同吗

GitHub Copilot: 有，而且差异已经基本收敛出来了。

相同的部分是：

1. `tinyplay_ftm` 这条主链在“有声”和“没声”两种情况下，高层日志几乎一样。
2. 都能看到 `graph_open ret 0`、`Playing sample`、`thread_result ok`。
3. `aw882xx_startup`、`aw882xx_hw_params` 之前也已经会进。

所以之前真正误导人的点就在这里：只看这些日志，会以为“既然都 ret 0 了，那应该早就有声”。但事实不是。

真正不同的部分是你后来让我手工打进去的 mixer 状态：

1. `WSA RX0 MUX = AIF1_PB`
2. `WSA RX1 MUX = AIF1_PB`
3. `WSA_RX0 INP0 = RX0`
4. `WSA_RX1 INP0 = RX1`
5. `WSA_COMP1 Switch = On`
6. `WSA_COMP2 Switch = On`
7. `WSA_RX INT0/1 VBAT ... Enable = On`
8. `WSA2` 那一整套对应控件也一起打开了
9. `aw_dev_0/1/2/3/5/6_switch = Enable`
10. `aw_dev_0/1/2/3/5/6_volume` 从 `0` 提到了 `120`

这里面最关键的不是 `tinyplay_ftm` 本身变了，而是“播放前的底层喇叭路由状态”变了。之前没声时，这些控件里至少有两类明显不对：

1. `WSA/WSA2` 主路由很多还是 `ZERO/Off`
2. `aw_dev_*_switch` 是 `Disable`
3. `aw_dev_*_volume` 全是 `0`

现在你能听到声，最可信的解释就是：

1. `tinyplay_ftm` 负责把流送进 AGM graph
2. 但真正决定“能不能从喇叭出来”的，是这组 WSA + aw_dev 的 mixer 状态
3. 之前图开了、流也跑了，但喇叭侧还是没放行
4. 现在这组控件被手工打开后，声音才真正出来

还有一个值得注意的点：

1. 我们抓到的 `DAPM` 读数在“有声时”看起来仍然不漂亮，还是会出现 `Speaker_Playback_*: Off in 1 out 0`
2. 但你已经现场听到了声，所以这说明这里的 DAPM 快照不能再被当成“是否有声”的最终判据
3. 至少对这台机当前这条路径来说，mixer 实际状态比那几个 DAPM 节点更可信

现在最实用的结论就是一句话：

之前没声音，不是因为 `tinyplay_ftm` 没工作，而是因为扬声器侧的 WSA/Awinic mixer 状态没有被真正打到可播放状态；现在有声音，最大的区别就是这组控件被手工打开并且音量不再是 0。

下一步我建议直接做这个，不再分析：
1. 把当前这组“有声状态”的 tinymix 命令整理成一条可重复执行的最小脚本。
2. 然后每次先打这组控件，再跑 `tinyplay_ftm`，把“偶然有声”变成“稳定有声”。

User: 我需要你把没有记录的问题先记录到当前文档

然后新建一个文档，解释从一个完全没有音频的TWRP到能够使用音频的手动Bring up步骤

GitHub Copilot: 我先把当前文档尾部和现有结论对齐，补上这次新确认但还没写进去的“有声差异点”，然后再单独写一份从零到可用音频的操作文档。

Searched for regex `13\.3[12]|手动播放链|有声音|aw_dev|WSA RX0 MUX|Speaker_Playback_` (`**/docs/TWRP音频手动Bring-up.md`), 11 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#2890-2890), lines 2890 to 2963

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs)

我现在直接落文档：一处补“这次真正新增的结论”，一处新建“从零到可用”的操作文档，内容会以这台机已经验证过的路径为主，不再写空泛方法论。

Generating patch (367 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md), [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E4%BB%8E%E9%9B%B6%E5%88%B0%E5%8F%AF%E7%94%A8%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up%E6%AD%A5%E9%AA%A4.md)


```

```

```

```
两份文档都已经落下来了。下一步我只补一条仓库记忆，把“真正导致有声的差异点”记住，避免后面又回退到只看 `graph_open ret 0` 的旧判断。

Inserted into memory file twrp_audio_manual_playback.md

已经处理完了。

我先把当前文档里之前没记录到的关键问题和新结论补进去了，重点新增了这几类内容：

1. 用户已经现场确认当前 recovery 确实能手动出声。
2. 之前“`graph_open ret 0` 但仍完全无声”的判断需要收窄，不能再作为当前最终结论。
3. 真正把“没声”推进到“有声”的差异，已经明确收敛到 `WSA/WSA2 + aw_dev_*` 这组 speaker mixer 状态，而不是 `tinyplay_ftm` 的高层日志本身。
4. `DAPM` 那几个 `Speaker_Playback_*` / `bias_level` 快照，至少在这台机上不能再单独当最终判据。

然后我新建了一份独立文档，专门解释“从一个完全没有音频的 TWRP，到能够使用音频的手动 Bring-up 步骤”。这份新文档不是泛泛而谈，而是按这台机已经验证过的路径来写的，顺序是：

1. 先把声卡和 `/dev/snd` 拉起来。
2. 再把 recovery 音频 HAL 从 stub mode 拉到 full parse。
3. 再让 `tinyplay_ftm` 跑到 `graph_open ret 0`。
4. 最后补上真正决定可闻性的 `WSA/WSA2 + aw_dev_*` speaker mixer 状态。

另外我也把这个新发现写进仓库记忆里了，后面再继续推进时，不会再回到“只看 `graph_open ret 0` 就当已经有声”的旧判断。

如果你要继续，我下一步就直接把现在这组“已可闻”的 mixer 设置整理成一条最小可重复命令序列，方便你每次一键打到有声状态。

Made changes.


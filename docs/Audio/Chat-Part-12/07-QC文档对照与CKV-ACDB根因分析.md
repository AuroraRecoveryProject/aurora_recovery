GitHub Copilot: Compacted conversation

```
adb -s 70a91f89 shell '/data/local/tmp/pure_c_play /data/local/tmp/test440_mid_10s.wav --seconds 10 --aw-vol 120 --trace'
```

User: 1s加末尾噪音

GitHub Copilot: 

还是只有 1s 加末尾噪音。说明 4 项对齐没解决问题。我需要更仔细对比 `audible-baseline` 路径与当前 `pure_c_play` 的差异。 

Created 4 todos

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#1-1), lines 1 to 120

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#1-1), lines 1 to 120

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#120-120), lines 120 to 350

Searched for regex `audible.*baseline|audible_baseline` (`**/pure_c_agm_probe.c`), 5 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#3415-3415), lines 3415 to 3520

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#350-350), lines 350 to 600

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#600-600), lines 600 to 663

Now let me trace the exact audible-baseline execution path in pure_c_agm_probe.c:  

Searched for regex `metadata_mode\s*==\s*3|metadata_mode == 3` (`**/pure_c_agm_probe.c`), 2 results

Searched for regex `skip_initial_control|direct_tagged_info|skip_helper_prep` (`**/pure_c_agm_probe.c`), 18 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2750-2750), lines 2750 to 3100

让我看 audible-baseline 的 metadata 函数具体做了什么： 

Searched for regex `prime_pcm100_metadata_6a54_min|prime_pcm100_metadata_689c_full_kv` (`**/pure_c_agm_probe.c`), 6 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#1983-1983), lines 1983 to 2090

Searched for regex `metadata_route_tag|metadata_route_value_full|metadata_route_value_split|metadata_stream_kv` (`**/pure_c_agm_probe.c`), 30 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2085-2085), lines 2085 to 2200

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2195-2195), lines 2195 to 2280

Searched for regex `ensure_recovery_audio_route` (`**/pure_c_agm_probe.c`), 10 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2716-2716), lines 2716 to 2745

Searched for regex `static.*direct_get_tagged_info` (`**/pure_c_agm_probe.c`), 1 result

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#1499-1499), lines 1499 to 1580

Searched for regex `static.*probe_agm_tagged_miid` (`**/pure_c_agm_probe.c`), 1 result

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#1918-1918), lines 1918 to 1985

关键发现！我来对比 card0 路线设置的差异。audible-baseline 的 `setup_recovery_audio_route()` 比 pure_c_play 的 `setup_speaker_route()` 多了几个重要控件。 

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2230-2230), lines 2230 to 2350

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2380-2380), lines 2380 to 2460

Searched for regex `no_route_reinforce|reinforce_route` (`**/pure_c_agm_probe.c`), 13 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2345-2345), lines 2345 to 2365

找到关键差异了。audible-baseline 比 pure_c_play 多了：

1. **`aw882xx_copp_switch = Enable`** — COPP 路由开关
2. **`WCD_SSR_SWITCH = Enable`** — WCD SSR 开关
3. **WSA VBAT 使能** — 4 个 VBAT 控件 
4. **`aw_dev_*_monitor = 1`** — 监控使能
5. **每秒路由重建** — `reinforce_route` 每秒重新设置整个 card0 路由

尤其第 5 点：audible-baseline 播放时**每约 1 秒**重建一次 card0 speaker 路由。这正好对应 pure_c_play "1s 后静音"的现象。 

Starting: *补齐 card0 控件+路由重建* (2/4)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#285-285), lines 285 to 345

Now I'll add the missing card0 controls and the route reinforcement during playback: 

Replacing 30 lines with 38 lines in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c)


```

```
Now add route reinforcement in the playback loop. Let me find the right spot: 

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#400-400), lines 400 to 425

Now I need to add route reinforcement during the playback loop. Let me add a reinforce function and integrate it: 

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#535-535), lines 535 to 575

Replacing 18 lines with 28 lines in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c)


```

```
Now add the route reinforcement in the write loop, after pcm_write and snap handling:  

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#600-600), lines 600 to 640

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#640-640), lines 640 to 681

Replacing 2 lines with 11 lines in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c)


```

```


Starting: *编译推送测试* (3/4)

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP/video_player && bash build_pure_c_play.sh

Ran terminal command:  adb -s 70a91f89 push /Volumes/Case-sensitive\ APFS/TWRP/video_player/pure_c_play /data/local/tmp/pure_c_play

编译推送完成。命令：

```
adb -s 70a91f89 shell '/data/local/tmp/pure_c_play /data/local/tmp/test440_mid_10s.wav --seconds 10 --aw-vol 120 --trace'
```

改动点：
1. 补齐 `aw882xx_copp_switch=Enable`、`WCD_SSR_SWITCH=Enable`、4 个 VBAT 使能、6 个 `aw_dev_*_monitor=1`
2. pcm_start 后立即重建一次 card0 路由
3. 播放循环中每 ~1 秒重建一次 card0 路由（与 audible-baseline 一致）

Made changes.

User: 为什么要这样做呢，现在听到声音断断续续，且末尾仍然有噪音

GitHub Copilot: 

路由重建（每秒 `mixer_open/close card0`）会瞬间中断 DAPM 路径，导致断续。这是错误方向。

回退路由重建，仅保留补齐的 card0 控件（VBAT/copp/WCD_SSR/monitor）。同时先排除 WAV 上采样问题——不传 wav 直接用内置正弦波测试。  

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#536-536), lines 536 to 560

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c#633-633), lines 633 to 650

Replacing 33 lines with 14 lines in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_play.c)


```

```


Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP/video_player && bash build_pure_c_play.sh

Ran terminal command:  adb -s 70a91f89 push /Volumes/Case-sensitive\ APFS/TWRP/video_player/pure_c_play /data/local/tmp/pure_c_play

已去掉路由重建，仅保留补齐控件（VBAT/copp/WCD_SSR/monitor）。

先用纯正弦波（不传 WAV）排除上采样问题：

```
adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --seconds 10 --aw-vol 120 --trace'
```

如果还是 1s，再试加 WAV 的：

```
adb -s 70a91f89 shell '/data/local/tmp/pure_c_play /data/local/tmp/test440_mid_10s.wav --seconds 10 --aw-vol 120 --trace'
```

两个都试一下，对比结果。

Made changes.

User: audible-baseline 能产生 8s+ 的声音这个结论是什么时候的

  TWRP adb -s 70a91f89 shell '/data/local/tmp/pure_c_play --seconds 10 --aw-vol 120 --trace'
[PureCPlay] dlopen tinyalsa 成功: /vendor/lib64/libtinyalsa.so
[PureCPlay] libagmmixer 加载: connect=0x78e8f11540 get_miid=0x78e8f114f0 mfc=0x78e8f11580
[PureCPlay] card0 speaker route 已设置 (aw_vol=120)
[PureCPlay] mixer_open(100) 成功
[PureCPlay] PCM100 control=ZERO rc=0
[PureCPlay] PCM100 metadata(6a54) rc=0
[PureCPlay] PCM100 control=TDM-LPAIF-RX-SECONDARY rc=0
[PureCPlay] PCM100 metadata(689c/devicepp) rc=0
[PureCPlay] helper_connect=TDM-LPAIF-RX-SECONDARY rc=0
[PureCPlay] agm_get_miid(MFC) rc=0 miid=16584
[PureCPlay] configure_mfc rc=0 miid=16584 48k/8ch/32bit
[PureCPlay] pcm_config: 8 ch, 48000 hz, format=1 (backend)
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
[PureCPlay] pcm_open 成功
[PureCPlay] pcm_prepare rc=0
[PureCPlay] pcm_start rc=0
[PureCPlay] 开始播放 10s (480000 frames, buf=32768 bytes)
[PureCPlay] trace: written=52224/480000 frames, elapsed=1000ms, expected=1088.0ms, drift=-88.0ms, last_write=21ms
[PureCPlay] trace: written=100352/480000 frames, elapsed=2003ms, expected=2090.7ms, drift=-87.7ms, last_write=22ms
[PureCPlay] trace: written=148480/480000 frames, elapsed=3005ms, expected=3093.3ms, drift=-88.3ms, last_write=21ms
[PureCPlay] trace: written=196608/480000 frames, elapsed=4008ms, expected=4096.0ms, drift=-88.0ms, last_write=21ms
[PureCPlay] trace: written=244736/480000 frames, elapsed=5011ms, expected=5098.7ms, drift=-87.7ms, last_write=22ms
[PureCPlay] trace: written=292864/480000 frames, elapsed=6013ms, expected=6101.3ms, drift=-88.3ms, last_write=21ms
[PureCPlay] trace: written=340992/480000 frames, elapsed=7016ms, expected=7104.0ms, drift=-88.0ms, last_write=21ms
[PureCPlay] trace: written=389120/480000 frames, elapsed=8019ms, expected=8106.7ms, drift=-87.7ms, last_write=22ms
[PureCPlay] trace: written=437248/480000 frames, elapsed=9021ms, expected=9109.3ms, drift=-88.3ms, last_write=21ms
[PureCPlay] trace: written=480000/480000 frames, elapsed=9917ms, expected=10000.0ms, drift=-83.0ms, last_write=21ms
[PureCPlay] 播放结束: written=480000/480000 frames
mixer_plugin_open - agm_mixer_plugin_open
mixer_plugin_open: card = 100
mixer_plug_get_card_info: card = 100
pcm_plug_open - agm_pcm_plugin_open
➜  TWRP adb -s 70a91f89 shell '/data/local/tmp/pure_c_play /data/local/tmp/test440_mid_10s.wav --seconds 10 --aw-vol 120 --trace'
[PureCPlay] dlopen tinyalsa 成功: /vendor/lib64/libtinyalsa.so
[PureCPlay] libagmmixer 加载: connect=0x7b2e1ad540 get_miid=0x7b2e1ad4f0 mfc=0x7b2e1ad580
[PureCPlay] card0 speaker route 已设置 (aw_vol=120)
[PureCPlay] mixer_open(100) 成功
[PureCPlay] WAV: 2 ch, 48000 hz, 16 bit, data=1920000 bytes
[PureCPlay] PCM100 control=ZERO rc=0
[PureCPlay] PCM100 metadata(6a54) rc=0
[PureCPlay] PCM100 control=TDM-LPAIF-RX-SECONDARY rc=0
[PureCPlay] PCM100 metadata(689c/devicepp) rc=0
[PureCPlay] helper_connect=TDM-LPAIF-RX-SECONDARY rc=0
[PureCPlay] agm_get_miid(MFC) rc=0 miid=16584
[PureCPlay] configure_mfc rc=0 miid=16584 48k/8ch/32bit
[PureCPlay] pcm_config: 8 ch, 48000 hz, format=1 (backend)
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
[PureCPlay] pcm_open 成功
[PureCPlay] pcm_prepare rc=0
[PureCPlay] pcm_start rc=0
[PureCPlay] 开始播放 10s (480000 frames, buf=32768 bytes)
[PureCPlay] trace: written=52224/480000 frames, elapsed=1000ms, expected=1088.0ms, drift=-88.0ms, last_write=21ms
[PureCPlay] trace: written=100352/480000 frames, elapsed=2003ms, expected=2090.7ms, drift=-87.7ms, last_write=22ms
[PureCPlay] trace: written=148480/480000 frames, elapsed=3005ms, expected=3093.3ms, drift=-88.3ms, last_write=21ms
[PureCPlay] trace: written=196608/480000 frames, elapsed=4008ms, expected=4096.0ms, drift=-88.0ms, last_write=21ms
[PureCPlay] trace: written=244736/480000 frames, elapsed=5011ms, expected=5098.7ms, drift=-87.7ms, last_write=22ms
[PureCPlay] trace: written=292864/480000 frames, elapsed=6013ms, expected=6101.3ms, drift=-88.3ms, last_write=21ms
[PureCPlay] trace: written=340992/480000 frames, elapsed=7016ms, expected=7104.0ms, drift=-88.0ms, last_write=21ms
[PureCPlay] trace: written=389120/480000 frames, elapsed=8019ms, expected=8106.7ms, drift=-87.7ms, last_write=22ms
[PureCPlay] trace: written=437248/480000 frames, elapsed=9021ms, expected=9109.3ms, drift=-88.3ms, last_write=21ms
[PureCPlay] trace: written=480000/480000 frames, elapsed=9917ms, expected=10000.0ms, drift=-83.0ms, last_write=21ms
[PureCPlay] 播放结束: written=480000/480000 frames
mixer_plugin_open - agm_mixer_plugin_open
mixer_plugin_open: card = 100
mixer_plug_get_card_info: card = 100
pcm_plug_open - agm_pcm_plugin_open

都是1s且末尾噪音

https://docs.qualcomm.com/doc/80-70020-16SC/topic/tinyalsa.html这个文档你看下

GitHub Copilot: 

  

Read memory twrp_audio_pure_c_audible_baseline_flag_20260326.md

Read memory twrp_audio_stock_and_helper_1s_frontier_20260325.md

Read memory twrp_audio_pure_c_current_silent_but_historically_1s_20260325.md

Read memory twrp_audio_agmplay_minimal_success.md

关键问题确认了。让我查证 audible-baseline 的实际测试： 

Searched for regex `audible.*baseline|8s\+|8秒|8s` (`**/docs/TWRP音频排查日志-20260326.md`), 5 results

Searched for regex `audible.*baseline.*8|8s.*audible|play_seconds.*8|chunks.*375` (`**/docs/**/*.md`), 6 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/History_Chat2.md#33880-33880), lines 33880 to 33930

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#5220-5220), lines 5220 to 5250

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#5250-5250), lines 5250 to 5290

好，找到了关键信息。

**"audible-baseline 能产生 8s+ 声音"这个结论来自 3 月 25 日的实机测试**（记录在 TWRP音频手动Bring-up.md 最末部分），当时用户肉耳确认了"听到了声音"，并且 `chunks=375`（8 秒）全部写完无报错。

但这里有一个严重的问题——**那次记录只说"听到了"，并没有明确说是持续听到了 8 秒**。结合当前 stock `agmplay` 和当前 `pure_c_play` 的表现都是"只有 ~1s 可闻"，很可能**那次也是 ~1s 可闻，只是当时认为"出声=成功"**。

现在让我看 Qualcomm 文档的内容。既然是外部 URL 不能直接访问，让我搜一下你提到的 tinyalsa 文档在工作区是否有相关内容： 

Searched for regex `80-70020-16SC|qualcomm.*tinyalsa|agm_pcm_open|session_obj_open|agm_session_open`, 20 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#5190-5190), lines 5190 to 5250

Added 1 todo

回溯完毕。关键结论：

**"audible-baseline 能产生 8s+ 声音"这个说法有误导性。**

回溯原始记录（TWRP音频手动Bring-up.md 5230 行附近），当时的原文是：

1. 用户肉耳确认"**听到了**" — 但没有明确说听了多久
2. `chunks=375`（8 秒写完、无 pcm_write 错误）— 这只证明**数据写了 8 秒**，不代表出了 8 秒声音  
3. 当时的突破点是从 `pcm_write -131` 推进到全部写完、从无声推进到有声

所以真实结论应该是：**audible-baseline 当时"能出声"，但很可能也只有 ~1s 可闻**，跟 stock `agmplay` 和当前 `pure_c_play` 表现一致。

这意味着——**~1s 边界根本不是 pure_c_play 的代码缺陷，而是当前 recovery 环境下所有工具共有的上界**（`agmplay` / `tinyplay_ftm` / `pure_c_play` / `pure_c_agm_probe` 全部都是 ~1s）。

先实测确认一下 audible-baseline 当前到底也是 1s：

```
adb -s 70a91f89 shell '/data/local/tmp/pure_c_agm_probe --audible-baseline'
```

请实听，确认 audible-baseline 是否也只有 ~1s。如果确认也是 1s，那问题就不在代码路径差异上，而是 recovery 环境本身的问题（CKV/ACDB 校准、或者 DSP 内部 gain/mute 模块在 ~1s 后切到静音）。

User:  adb -s 70a91f89 shell '/data/local/tmp/pure_c_agm_probe --audible-baseline没任何声音

GitHub Copilot: 

 

Updated memory file twrp_audio_pure_c_audible_baseline_flag_20260326.md

Starting: *分析 Qualcomm tinyalsa 文档* (5/5)

确认了：**audible-baseline 当前完全无声**。现状整理：

| 工具 | 声音 |
|------|------|
| `agmplay` (stock vendor) | ~1s |
| `pure_c_play` (我们的) | ~1s |  
| `pure_c_agm_probe --audible-baseline` | 无声 |

所以 **pure_c_play 已经是当前最好的路径**，~1s 边界是所有工具共有的环境上界。

你提到了 Qualcomm 文档 `80-70020-16SC/topic/tinyalsa.html`，我无法直接访问该 URL。你能把里面你觉得关键的内容贴出来吗？或者告诉我你在里面看到了什么可能跟 ~1s 边界有关的信息？

目前 ~1s 后静音的可能原因：
1. **CKV/ACDB 校准缺失** — logcat 显示 "No calibration found" ×3 subgraphs，DSP 可能在 ~1s 后因缺少校准而将 gain 归零
2. **DSP 内部 soft volume/limiter 模块** — 开场有默认增益，之后被某个 timer 或 ramp 模块静音
3. **ADSP 端保护逻辑** — 缺少 CKV 时 SPF 可能在播放一小段后 mute 输出

需要你把文档关键部分发过来，我来对照分析。

User: 你现在可以访问了

https://docs.qualcomm.com/doc/80-70020-16SC/topic/tinyalsa.html

GitHub Copilot: 

 

Fetch Qualcomm tinyalsa docs

Ran terminal command:  curl -sL 'https://docs.qualcomm.com/doc/80-70020-16SC/topic/tinyalsa.html' | head -c 200000

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/6ee534f1-c0c9-4d23-abb4-6743296a8d5a/toolu_bdrk_012QH5NNJesXSPSJ3hCQRqxe__vscode-1774492048448/content.txt)

Ran terminal command:  which w3m lynx links 2>/dev/null; python3 -c "import requests; print('requests ok')" 2>/dev/null
Completed with input:  which w3m lynx links 2>/dev/null; python3 -c "import requests; print('requests ok')" 2>/dev/null

Ran terminal command: import urllib.request; print('ok')" 2>/dev/null && echo "urllib ok" || echo "no python3

Ran terminal command:  curl -sL 'https://docs.qualcomm.com/doc/80-70020-16SC/topic/tinyalsa.html' | grep -oE '"[^"]*\.json[^"]*"' | head -20

Ran terminal command:  curl -sL 'https://docs.qualcomm.com/bundle/80-70020-16SC/resource/80-70020-16SC.json' -o /dev/null -w '%{http_code}' 2>/dev/null; echo; curl -sL 'https://docs.qualcomm.com/bundle/80-70020-16SC/resource/tinyalsa.html' -o /dev/null -w '%{http_code}' 2>/dev/null; echo; curl -sL 'https://docs.qualcomm.com/bundle/80-70020-16SC/topic/tinyalsa.html' -o /dev/null -w '%{http_code}' 2>/dev/null; echo

Ran terminal command:  curl -sL 'https://docs.qualcomm.com/bundle/80-70020-16SC/resource/tinyalsa.html' | head -c 2000

Ran terminal command:  curl -sL 'https://docs.qualcomm.com/bundle/80-70020-16SC/topic/tinyalsa.html' | head -c 2000

Ran terminal command:  curl -sL 'https://docs.qualcomm.com/bundle/80-70020-16SC/resource/80-70020-16SC.json' | head -c 3000

Ran terminal command:  curl -sL 'https://web.archive.org/web/2024/https://docs.qualcomm.com/doc/80-70020-16SC/topic/tinyalsa.html' -o /dev/null -w '%{http_code}\n' 2>/dev/null
Completed with input:  curl -sL 'https://web.archive.org/web/2024/https://docs.qualcomm.com/doc/80-70020-16SC/topic/tinyalsa.html' -o /dev/null -w '%{http_code}\n' 2>/dev/null

Ran terminal command:  curl -sL 'https://webcache.googleusercontent.com/search?q=cache:docs.qualcomm.com/doc/80-70020-16SC/topic/tinyalsa.html' -o /dev/null -w '%{http_code}\n' 2>/dev/null

Ran terminal command:  curl -sL -A 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)' 'https://webcache.googleusercontent.com/search?q=cache:docs.qualcomm.com/doc/80-70020-16SC/topic/tinyalsa.html' 2>/dev/null | python3 -c "
import sys, html, re
raw = sys.stdin.read()
# strip tags
text = re.sub(r'<style[^>]*>.*?</style>', '', raw, flags=re.S)
text = re.sub(r'<script[^>]*>.*?</script>', '', text, flags=re.S)
text = re.sub(r'<[^>]+>', ' ', text)
text = html.unescape(text)
# collapse whitespace
text = re.sub(r'[ \t]+', ' ', text)
text = re.sub(r'\n\s*\n', '\n\n', text)
print(text.strip()[:50000])
" 2>/dev/null | head -c 50000

Ran terminal command:  curl -sL 'https://docs.qualcomm.com/doc/80-70020-16SC/' -o /dev/null -w '%{http_code}\n%{redirect_url}\n' 2>/dev/null

Ran terminal command:  curl -sL -A 'Mozilla/5.0' 'https://docs.qualcomm.com/api/doc/80-70020-16SC/tinyalsa' -o /dev/null -w '%{http_code}\n' 2>/dev/null; curl -sL -A 'Mozilla/5.0' 'https://docs.qualcomm.com/api/bundle/80-70020-16SC/resource/tinyalsa.html' -o /dev/null -w '%{http_code}\n' 2>/dev/null; curl -sL -A 'Mozilla/5.0' 'https://docs.qualcomm.com/api/bundle/80-70020-16SC' -o /dev/null -w '%{http_code}\n' 2>/dev/null

Ran terminal command:  curl -sL -A 'Mozilla/5.0' 'https://docs.qualcomm.com/api/bundle/80-70020-16SC' | head -c 3000

页面需要 Qualcomm SSO 登录，我无法直接访问。你能把页面内容复制粘贴给我吗？或者截图/把关键段落贴到对话里。

同时，基于目前已知信息，我来把 **真正的问题** 理清——现在所有工具（`agmplay`、`pure_c_play`、`pure_c_agm_probe`）都有同一个 ~1s 边界，这说明问题不在我们的代码里，而是 recovery 环境本身。你觉得文档里哪部分跟这个边界可能相关？

User: 

Products

Applications

Developer

Support

Company



Developer Workspace


Loading...
Bring your ideas to life by saving your favorite products, comparing specifications and sharing with your team to work collaboratively.

0 Projects

Sort


Newest
NewestOldestRecently updatedLeast recently updated

Create a Project
You do not have any projects yet. Start building your Workspace.

Qualcomm Linux 音频指南
Legal notice

定制音频用例
启用基于 TinyALSA 的应用程序
启用基于 TinyALSA 的应用程序
简体中文 (Simplified Chinese)
Updated: Jul 23, 2025 80-70020-16SC Rev: AA
On this page
TinyALSA API
pcm_open
pcm_is_ready
pcm_prepare
pcm_start
pcm_write
pcm_read
pcm_stop
pcm_close
配置 TinyALSA
TinyALSA 是一个将 ALSA 内核接口包装到客户端可以调用的 API 中的库。它还提供了一个插件接口来模拟 ALSA API。

TinyALSA 源代码位于：

build-qcom-wayland/workspace/sources/tinyalsa 和

build-qcom-wayland/workspace/sources/tinycompress.

下图显示了 TinyALSA 插件架构。

TinyALSA
微压缩
客户端
ALSA/ASoC 内核框架
压缩插件
PCM 插件
混音器插件
PCM
Libaudioroute
混音器
压缩
ASoC 驱动程序
开源/框架
图例
TinyALSA 插件架构

内核中的 ALSA 框架公开了用于 PCM、Compress 和混音器的卡和设备节点。

PCM、混音器和 Compress 插件属于 TinyALSA 插件，它们是将所有 PCM、混音器和 Compress 调用从应用程序路由到特定插件的实现。

这些插件创建具有 PCM、Compress 和混音器节点的虚拟声卡。虚拟节点映射到设备上的 .so 文件（可动态加载的共享对象）。

虚拟声卡配置位于 card-defs.xml 文件中。此文件位于设备上的 /etc/ 文件夹中。

TinyALSA API
以下是常见的 TinyALSA API。关于所有 API 的完整描述，可参见开源 TinyALSA 文档。

pcm_open
用于打开 PCM 音频设备进行输入和输出操作。初始化 PCM 设备以进行通信，允许对音频数据进行读/写操作。

struct pcm *pcm_open(
     unsigned int card,
     unsigned int device,
     unsigned int flags,
     struct pcm_config *config)
参数

card

卡号。

device

所选卡中的设备号。

flags

用于配置 PCM 设备的标志。

config

指定音频流参数的结构变量。

返回值

pcm* handle

pcm_is_ready
检查 PCM 设备是否已准备好进行输入和输出操作。

int pcm_is_ready(struct pcm *pcm)
参数

pcm

指向打开的 PCM 设备的指针。

返回值

成功时为 0

失败时为错误代码

pcm_prepare
准备音频设备输入和输出操作。

int pcm_prepare(
     struct pcm *pcm)
参数

pcm

指向打开的 PCM 设备的指针。

返回值

成功时为 0

失败时为错误代码

pcm_start
用于启动 PCM 音频设备进行输入和输出操作。

int pcm_start(
     struct pcm *pcm)
参数

pcm

指向打开的 PCM 设备的指针。

返回值

成功时为 0

失败时为错误代码

pcm_write
将音频数据写入音频 PCM 设备。将音频数据作为输入，并将其发送到 PCM 设备进行播放或处理。

int pcm_write(
     struct pcm *pcm,
     const void *data,
     unsigned int count)
参数

pcm

指向打开的 PCM 设备的指针。

data

要写入的音频数据。

count

要写入的音频帧数。

返回值

成功时为 0

失败时为错误代码

pcm_read
从 PCM 设备接收音频数据，允许应用程序从麦克风采集音频数据。

int pcm_read(
     struct pcm *pcm,
     void *data,
     unsigned int count)
参数

pcm

指向打开的 PCM 设备的指针。

data

要读取的音频数据。

count

要读取的音频帧数。

返回值

成功时为 0

失败时为错误代码

pcm_stop
用于停止 PCM 音频设备进行进一步的输入和输出操作。

int pcm_stop(
     struct pcm *pcm)
参数

pcm

指向打开的 PCM 设备的指针。

返回值

成功时为 0

失败时为错误代码

pcm_close
关闭 PCM 音频设备。这将释放与 PCM 设备相关的资源并释放内存。

int pcm_close(
     struct pcm *pcm)
参数

pcm

指向打开的 PCM 设备的指针。

返回值

成功时为 0

失败时为错误代码

配置 TinyALSA
对于来自 TinyALSA 的音频用例，配置虚拟混音器控件。

这些控件由混音器插件创建，用于搭建音频用例图和模块。大多数是基于字节数组的，并使用 mixer_ctl_set_array API 进行配置。元数据（称为”PCM100 metadata”）使用键值 (KV) 对进行设置。如需了解更多实施详情，请参阅 build-qcom-wayland/workspace/sources/qcom-agm/opensource/agm/plugins/tinyalsa/test/agmmixer.c 中的 set_agm_audio_intf_metadata API。

/**
            * Key Vector pair
            */
            struct agm_key_value {
            uint32_t key; /**< key */
            uint32_t value; /**< value */
            };
            /*Sample allocation for the key value pair*/
            gkv = calloc(num_gkv, sizeof(struct agm_key_value));
            ckv = calloc(num_ckv, sizeof(struct agm_key_value));
基于 TinyALSA 的 agmplay 和 agmcap 工具的示例代码可以在以下位置找到：

build-qcom-wayland/workspace/sources/qcom-agm/opensource/agm/plugins/tinyalsa/test.

要从 TinyALSA 启用和执行音频用例：

设置音频接口（后端）设备配置，包括采样率、通道、格式和数据格式。

'CODEC_DMA-LPAIF_WSA-RX-0 rate ch fmt' 48000 2 2(PCM_16)
设置元数据，包括图键、设备的 cal 键和 DevicePP。

'CODEC_DMA-LPAIF_WSA-RX-0 metadata' bytes
设置控件，以表明后续混音器配置将设置 Stream 和 StreamPP 子图的元数据。零表示后续命令用于流。

'PCM100 control' Zero
                    'PCM100 metadata' bytes
设置控件以指示后续混频器配置将设置 DevicePP 和流设备子图的元数据。Codec_DMC-LPAIF_WSA-RX-0 表示后续命令用于流设备。CODEC_DMA-LPAIF_WSA-RX-0 是 ALSA ASOC 框架注册的音频接口之一。所有音频接口的列表可以在 /proc/asound/pcm 中找到。/proc/asound/pcm

'PCM100 control' CODEC_DMA-LPAIF_WSA-RX-0
                    'PCM100 metadata' bytes
获取与流和音频接口之间的给定会话关联的所有标签、模块 ID 和实例 ID。

'PCM100 getTaggedInfo' bytes
设置控件，以表明后续混音器配置将设置Stream 子图上模块的参数。

'PCM100 control' Zero
                    'PCM100 setParam' bytes
设置控件，以表明后续混音器配置将设置 StreamDevice 和 DevicePP 子图上模块的参数。

'PCM100 control' CODEC_DMA-LPAIF_WSA-RX-0
                    'PCM100 setParam' bytes
将前端（流）与后端（codec/音频接口）连接起来。

'PCM100 connect'CODEC_DMA-LPAIF_WSA-RX-0
打开 PCM 设备。

pcm_open
准备用于输入和输出操作的音频设备。

pcm_prepare
用于启动 PCM 音频设备进行输入和输出操作。

pcm_start
从音频 PCM 设备写入和读取音频数据。

pcm_write/pcm_read
停止 PCM 设备。

pcm_stop
关闭 PCM 音频设备。

pcm_close
可以使用以下方法获取虚拟设备的所有混频器控件：

ssh root@ip-addr
systemctl stop pulseaudio
tinymix set -D 100
Previous

在 PAL 级别定制

Next

定制音频图

May contain U.S. and international export controlled information
Light
Dark
Auto
Qualcomm relentlessly innovates to deliver intelligent computing everywhere, helping the world tackle some of its most important challenges. Our leading-edge AI, high performance, low-power computing, and unrivaled connectivity deliver proven solutions that transform major industries. At Qualcomm, we are engineering human progress.
Quick links
Products
Support
Partners
Contact us
Developer
Company info
About us
Careers
Investors
News & media
Our businesses
Email Subscriptions
Stay connected
Get the latest Qualcomm and industry information delivered to your inbox.

Subscribe
Manage your subscription
Terms of Use
Privacy
Cookie Policy
Accessibility Statement
Responsible AI Policy
Cookie Settings
Language: English (US)
Languages
English ( United States )
简体中文 ( China )
© Qualcomm Technologies, Inc. and/or its affiliated companies.

Snapdragon and Qualcomm branded products are products of Qualcomm Technologies, Inc. and/or its subsidiaries. Qualcomm patented technologies are licensed by Qualcomm Incorporated.

Note: Certain services and materials may require you to accept additional terms and conditions before accessing or using those items.

References to "Qualcomm" may mean Qualcomm Incorporated, or subsidiaries or business units within the Qualcomm corporate structure, as applicable.

Qualcomm Incorporated includes our licensing business, QTL, and the vast majority of our patent portfolio. Qualcomm Technologies, Inc., a subsidiary of Qualcomm Incorporated, operates, along with its subsidiaries, substantially all of our engineering, research and development functions, and substantially all of our products and services businesses, including our QCT semiconductor business.

Materials that are as of a specific date, including but not limited to press releases, presentations, blog posts and webcasts, may have been superseded by subsequent events or disclosures.

Nothing in these materials is an offer to sell or license any of the services or materials referenced herein.


Provide Feedback
关闭


GitHub Copilot: 

 

Updated todo list

文档内容非常有价值。我来对比文档标准序列 vs 我们的 `pure_c_play` vs `agmplay`：

## 文档规定的标准序列

| 步骤 | 操作 | pure_c_play | agmplay |
|------|------|-------------|---------|
| 1 | **后端 rate ch fmt** `'TDM-...-RX-SECONDARY rate ch fmt'` | ❌ 缺（可选flag） | ✅ |
| 2 | **后端 metadata** `'TDM-...-RX-SECONDARY metadata'` (GKV + CKV + DevicePP) | ❌ **缺** | ✅ |
| 3 | `PCM100 control` = ZERO → `PCM100 metadata` (Stream) | ✅ | ✅ |
| 4 | `PCM100 control` = backend → `PCM100 metadata` (StreamDevice/DevicePP) | ✅ | ✅ |
| 5 | `PCM100 getTaggedInfo` | ❌ 缺 | ✅ |
| 6 | `PCM100 control` = ZERO → `PCM100 setParam` (Stream 模块参数) | ❌ **缺** | ✅ |
| 7 | `PCM100 control` = backend → `PCM100 setParam` (DevicePP 模块参数) | ❌ **缺** | ✅ |
| 8 | `PCM100 connect` | ✅ | ✅ |
| 9 | pcm_open/prepare/start/write | ✅ | ✅ |

**但关键问题是：`agmplay` 做了全部步骤，也只有 ~1s。** 所以缺步骤不是 ~1s 边界的原因。

文档提到的关键线索：**第 2 步后端 metadata 包含 "cal 键 (CKV)"**。logcat 显示 "No calibration found" ×3 subgraphs — 这说明 DSP 图找不到校准数据。

校准数据来源于 ACDB 文件，在 recovery 模式下可能不完整或未加载。需要检查： 

Ran terminal command:  adb -s 70a91f89 shell 'find /vendor/etc/acdbdata /odm/etc/acdbdata /etc/acdbdata 2>/dev/null -name "*.acdb" | head -20'

Ran terminal command:  adb -s 70a91f89 shell 'ls -la /odm/etc/acdbdata/*.acdb /odm/etc/acdbdata/FTM/*.acdb /vendor/etc/acdbdata/sun_mtp/*.acdb 2>/dev/null'

Ran terminal command:  adb -s 70a91f89 shell 'getprop | grep -i acdb; getprop | grep -i cal; getprop persist.vendor.audio'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -iE "acdb|calibration|ckv|No cal" | tail -30'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -iE "ACDB.*init|ACDB.*load|acdb_file|AcdbInit|ats_init" | head -20'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -i "gsl\|ACDB\|acdb" | head -30'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d -b all | grep -iE "gsl|ACDB|acdb" | head -40'

Ran terminal command:  adb -s 70a91f89 shell 'cat /vendor/etc/card-defs.xml 2>/dev/null | head -60'

Completed: *分析 Qualcomm tinyalsa 文档* (5/5)

## 文档 + logcat 分析结论

文档和 logcat 合在一起给出了 ~1s 边界的**根因方向**：

### CKV 不匹配是核心问题

```
CKVs mismatched. ACDB CKVs count 2 CKVs sent from HAL count 4
ckv don't have key 0xef000000
can't find ckv's key: 0xa5000000(rate), 0xa6000000(bits), 0xd2000000(?)
No calibration found ×4 subgraphs
```

**HAL 发给 ACDB 4 个 CKV keys，但 ACDB 文件里只认识 2 个**。多出来的 3 个 key（`0xa5000000`=采样率、`0xa6000000`=位深、`0xd2000000`=未知）在 ACDB 里不存在，加上缺少 `0xef000000`，导致 4 个子图全部找不到校准数据。

### 为什么 ~1s 有声之后就静了

DSP graph 开没问题（`graph_open ret 0`, `graph_start ret 0`），PA 也启动了（`aw882xx_start_pa: start success`）。但因为**没有校准数据**，DSP 内部的 volume/limiter/gain 模块使用默认参数——可能是放一小段后 ramp down 到 0，或者保护模块在无校准时 ~1s 超时后 mute。

### 这跟文档的关系

文档说步骤 2 需要设置**后端 metadata 包含 cal key (CKV)**。`agmplay` 确实做了，但它传的 CKV 跟 ACDB 文件里的不匹配——这是 **ODM/OEM 层面的校准文件与 HAL 配置不一致** 的问题，不是播放器代码能解决的。

### 可能的突破方向

1. **用 FTM 的 ACDB 文件替换** — 设备上有 `/odm/etc/acdbdata/FTM/acdb_cal.acdb`（3.7MB），而默认用的是 `/odm/etc/acdbdata/acdb_cal.acdb`（4.1MB）或 vendor 的 MTP 版（3.2MB）。FTM（工厂测试模式）可能 CKV 更宽松  
2. **只发 2 个 CKV 而不是 4 个** — 匹配 ACDB 文件实际有的数量  
3. **跳过 CKV 直接发空 CKV** — 看 DSP 是否 fallback 到无校准直通模式  
4. **检查 `agmplay` 的 CKV 是从哪读的** — 可能是 `usecaseKvManager.xml`

你想先试哪个方向？我倾向先查 `usecaseKvManager.xml` 看 CKV 定义，再尝试发 2 个 CKV 或空 CKV。

User: 你直接执行你觉得收益高的方向


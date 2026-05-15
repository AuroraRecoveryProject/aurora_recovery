User: swscaler @ 0xb400007b96324170] No accelerated colorspace conversion found from yuv420p to rgba.
[VideoPlayer] 音频提取完成: /tmp/flutter/vp_audio_2250059568.wav bytes=14123608 ready=1
flutter: [VideoPlayer] 打开成功: 1280x720, 时长: 73560ms, 帧率: 30.0fps
[VideoPlayer] start_audio_playback: wav=/tmp/flutter/vp_audio_2250059568.wav start_ms=0
[VideoPlayer] 音频线程启动 path=/tmp/flutter/vp_audio_2250059568.wav
[VideoPlayer] wav 信息: rate=48000 ch=2 bits=16 data=14123608
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=before open_output_pcm setprop rc=0
[VideoPlayer] 音频路由预热: phase=before open_output_pcm mixer rc=0
[VideoPlayer] 先尝试最小 AGM 直开: card=100 device=100 intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] AGM plugin open 失败: mode=-1 card=100 device=100 rc=-32 plugin=0x0
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] 最小 AGM PCM open 失败: cfg=source err=cannot open device 100 for card 100: Unknown error -32
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] 最小 AGM PCM open 失败: cfg=backend err=cannot open device 100 for card 100: Unknown error -32
mixer_plugin_open: failed to open plugin, err: -12
[VideoPlayer] 打开 AGM mixer 失败: card=100
mixer_plugin_open: failed to open plugin, err: -12
[VideoPlayer] 打开 AGM mixer 失败: card=100
[VideoPlayer] AGM plugin 打开全部失败，回退普通 PCM
[VideoPlayer] 打开 PCM 失败: card=0 device=16 cfg=backend err=cannot set hw params: Invalid argument
[VideoPlayer] 打开 PCM 成功: card=0 device=16 cfg=source rate=48000 ch=2 bits=16
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=after open_output_pcm setprop rc=0
[VideoPlayer] 音频路由预热: phase=after open_output_pcm mixer rc=0
[VideoPlayer] 音频线程进入播放循环 backend=1
[VideoPlayer] pcm_write 首次失败，重补 speaker mixer 后重试: backend=1 rc=-1
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=pcm_write retry setprop rc=0
[VideoPlayer] 音频路由预热: phase=pcm_write retry mixer rc=0
[VideoPlayer] pcm_write 失败: cannot write initial data: Invalid argument
[VideoPlayer] 音频线程退出: 写流失败 backend=1
[VideoPlayer] 音频线程退出 stop_requested=0
Application finished.



GitHub Copilot: 这轮日志把根因又收窄了一层：不是最小 AGM 直开思路错了，而是当前进程里 `libtinyalsa` / `libagmmixer` / `libagm_pcm_plugin` 的装载形态很可能让 card100 的 plugin 依赖解析失败。我直接把这三者从 `RTLD_LOCAL` 改成 `RTLD_GLOBAL`，并让最小 AGM 直开先确保 `libagmmixer.so` 已加载，再编译部署。

Generating patch (28 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
这次改动非常集中，目标就是修进程内 plugin 依赖解析。现在继续按同一流程，只编译 `.so` 并复制到 `native`，不运行。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c), 28 problems found

Ran terminal command:  cd /Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player && ./build_so.sh

Ran terminal command:  cp /Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/libvideo_player.so /Volumes/Case-sensitive\ APFS/TWRP/aurora_recovery/native/libvideo_player.so && shasum -a 256 /Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/libvideo_player.so /Volumes/Case-sensitive\ APFS/TWRP/aurora_recovery/native/libvideo_player.so

继续推进了，而且这次改动是对准你最新日志里的新前沿。

从这轮日志看，最小 AGM 直开已经真的走到了，但失败形态变成了：
1. `AGM plugin open 失败: mode=-1 card=100 device=100 rc=-32`
2. `最小 AGM PCM open 失败 ... Unknown error -32`
3. 然后 `mixer_plugin_open: failed to open plugin, err: -12`

这说明当前最靠前的阻塞已经不再是我们自己那套 metadata/helper 序列，而是进程内加载出来的 `tinyalsa/agmmixer/agm plugin` 这组三方依赖在当前 app 里没有按外部厂测二进制的方式彼此可见。

所以我这次改了两点：
1. 把 `libtinyalsa.so`、`libagm_pcm_plugin.so`、`libagmmixer.so` 的 `dlopen` 从 `RTLD_LOCAL` 改成了 `RTLD_GLOBAL`。
2. 在最小 AGM 直开之前，先显式预加载 `libagmmixer.so`，减少 plugin 在 card100 上做二次解析时拿不到依赖符号的概率。

然后按你要求只做了：
1. 编译新的 `libvideo_player.so`
2. 复制到 libvideo_player.so

当前部署件哈希：
`e9e76c002eb1257706b810769d3bf9640367c27528f247ed259a3199dbce1df3`

编辑器里的那批 FFmpeg/tinyalsa 报错还是老的索引环境问题，实际 shell 编译已经成功。

你下一轮最值得看的日志点现在变成：
1. `mode=-1 card=100 device=100` 这条最小 AGM plugin open 的返回码，是否还停在 `-32`
2. `mixer_plugin_open: failed to open plugin, err: -12` 是否还出现
3. 如果这两个码有任何变化，说明这次全局装载已经碰到了真正的依赖问题边界

如果你继续贴下一轮日志，我会直接沿着 `-32/-12` 这组错误继续收窄，不再回去折腾普通 PCM。

Made changes.

User: swscaler @ 0xb400007b96324170] No accelerated colorspace conversion found from yuv420p to rgba.
[VideoPlayer] 音频提取完成: /tmp/flutter/vp_audio_2250059568.wav bytes=14123608 ready=1
flutter: [VideoPlayer] 打开成功: 1280x720, 时长: 73560ms, 帧率: 30.0fps
[VideoPlayer] start_audio_playback: wav=/tmp/flutter/vp_audio_2250059568.wav start_ms=0
[VideoPlayer] 音频线程启动 path=/tmp/flutter/vp_audio_2250059568.wav
[VideoPlayer] wav 信息: rate=48000 ch=2 bits=16 data=14123608
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=before open_output_pcm setprop rc=0
[VideoPlayer] 音频路由预热: phase=before open_output_pcm mixer rc=0
[VideoPlayer] 先尝试最小 AGM 直开: card=100 device=100 intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] AGM plugin open 失败: mode=-1 card=100 device=100 rc=-32 plugin=0x0
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] 最小 AGM PCM open 失败: cfg=source err=cannot open device 100 for card 100: Unknown error -32
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] 最小 AGM PCM open 失败: cfg=backend err=cannot open device 100 for card 100: Unknown error -32
mixer_plugin_open: failed to open plugin, err: -12
[VideoPlayer] 打开 AGM mixer 失败: card=100
mixer_plugin_open: failed to open plugin, err: -12
[VideoPlayer] 打开 AGM mixer 失败: card=100
[VideoPlayer] AGM plugin 打开全部失败，回退普通 PCM
[VideoPlayer] 打开 PCM 失败: card=0 device=16 cfg=backend err=cannot set hw params: Invalid argument
[VideoPlayer] 打开 PCM 成功: card=0 device=16 cfg=source rate=48000 ch=2 bits=16
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=after open_output_pcm setprop rc=0
[VideoPlayer] 音频路由预热: phase=after open_output_pcm mixer rc=0
[VideoPlayer] 音频线程进入播放循环 backend=1
[VideoPlayer] pcm_write 首次失败，重补 speaker mixer 后重试: backend=1 rc=-1
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=pcm_write retry setprop rc=0
[VideoPlayer] 音频路由预热: phase=pcm_write retry mixer rc=0
[VideoPlayer] pcm_write 失败: cannot write initial data: Invalid argument
[VideoPlayer] 音频线程退出: 写流失败 backend=1
[VideoPlayer] 音频线程退出 stop_requested=0
Application finished.



GitHub Copilot: 现在前沿没再变，说明不是加载可见性的小问题，而是进程内的 AGM plugin/mixer 依赖链本身还缺一环。我先把 `libtinyalsa` 相关插件链和 card100 打开的真实依赖摸清楚，再补代码，不会回到普通 PCM。

Ran terminal command:  strings /vendor/lib64/libtinyalsa.so 2>/dev/null | rg 'agm|plugin|mixer_plugin|pcm_plug|libagm'
Completed with input:  strings /vendor/lib64/libtinyalsa.so 2>/dev/null | rg 'agm|plugin|mixer_plugin|pcm_plug|libagm'

Ran terminal command:  strings /Volumes/Case-sensitive\ APFS/TWRP/audio_dtb_probe/libtinyalsa.so 2>/dev/null | rg 'agm|plugin|mixer_plugin|pcm_plug|libagm'

Ran terminal command:  nm -D /vendor/lib64/libagm_pcm_plugin.so 2>/dev/null | head -80

Ran terminal command:  nm -D /vendor/lib64/libagmmixer.so 2>/dev/null | head -120

我把 tinyalsa 二进制里的插件名字和本机可用库名直接挖出来，先确认是不是还漏了 `libagm_mixer_plugin.so` 这一类没有显式预加载的依赖。

Ran terminal command:  strings /Volumes/Case-sensitive\ APFS/TWRP/audio_dtb_probe/libtinyalsa.so | rg 'lib.*plugin.*so|agm.*plugin|mixer_plugin|pcm_plug'

Ran terminal command:  adb shell 'ls /vendor/lib64 | grep -E "agm|plugin|tinyalsa"'

Ran terminal command:  adb shell 'for f in /vendor/lib64/libtinyalsa.so /vendor/lib64/libagm_pcm_plugin.so /vendor/lib64/libagmmixer.so /vendor/lib64/libagm_mixer_plugin.so; do echo === $f ===; [ -f "$f" ] && toybox readelf -d "$f" 2>/dev/null | head -80; done'

设备上确实还有 `libagm_mixer_plugin.so`，这和你日志里的 `mixer_plugin_open` 失败正好对上。我先把依赖链读出来，再决定是只补预加载，还是也要直接接 mixer plugin 入口。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_ryEXOBuO9qOiwpc2llAvcf0n__vscode-1773690937184/content.txt)

依赖链已经看清了：`libagm_pcm_plugin.so` 和 `libagm_mixer_plugin.so` 都还依赖 `libsndcardparser.so`、`libagmclient.so`、`libaudio_log_utils.so`、`libutils.so`、`libcutils.so` 这串库。外部厂测二进制大概率天然把这些依赖带进了进程，但我们当前 app 进程没有。我现在直接补一层 AGM 运行时依赖预加载。

Generating patch (88 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
这次补的是进程级依赖，不是参数层逻辑。继续按同样流程，只编译和复制 `.so`。

Ran terminal command:  ./build_so.sh

Ran terminal command:  cp /Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/libvideo_player.so /Volumes/Case-sensitive\ APFS/TWRP/aurora_recovery/native/libvideo_player.so && shasum -a 256 /Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/libvideo_player.so /Volumes/Case-sensitive\ APFS/TWRP/aurora_recovery/native/libvideo_player.so

Starting: *实机验证日志前沿* (5/5)

继续推进了，这次补的是你最新日志里真正暴露出来的那层：AGM 运行时依赖链。

从你那轮日志看，当前最前沿已经不是 speaker mixer，也不是 helper 顺序，而是：
1. 最小 AGM 直开一开始就 `plugin open rc=-32`
2. 后面 `mixer_plugin_open ... err: -12`
3. 说明 app 进程里虽然能 `dlopen` 主库，但 AGM/tinyalsa 插件真正需要的那串运行时依赖没有像外部厂测二进制那样完整进入进程

所以我这次做了两件事：
1. 新增 `load_agm_runtime_deps()`，显式预加载这串依赖：
   `libc++.so`
   `libutils.so`
   `libcutils.so`
   `liblog.so`
   `libaudio_log_utils.so`
   `libsndcardparser.so`
   `libagm.so`
   `libagmclient.so`
   `libagmmixer.so`
   `libagm_pcm_plugin.so`
   `libagm_mixer_plugin.so`
   `vendor.qti.hardware.agm-V1-ndk.so`
2. 在加载 `libtinyalsa.so`、`libagmmixer.so`、`libagm_pcm_plugin.so` 之前，先确保这套依赖已经被全局预加载进当前进程。

然后按你的要求只做了：
1. 编译新的 `libvideo_player.so`
2. 复制到 libvideo_player.so

当前部署件哈希：
`456f7663757e60f21e9abffc999495ff86810ec54280ccbef16534d4057ca5fa`

下一轮你如果继续贴日志，最关键看这三处：
1. `AGM 运行时依赖预加载:` 是否开始打印
2. `AGM plugin open 失败: mode=-1 card=100 device=100 rc=...` 的 `rc` 有没有从 `-32` 变化
3. `mixer_plugin_open: failed to open plugin, err: -12` 这条还在不在

如果这两组错误码开始变化，我就能继续把问题从“进程依赖链”再往下压到具体的 plugin 初始化步骤。

Made changes.

User: [DRM-DUMB] PresentBuffer: src_fmt=RGBA dst='XB24'(875709016) layout=1 pitch=13568/13568 dim=3392x2400/3392x2400 px0=255,255,255,255
[DRM-DUMB] gr_flip(direct): 11.663 ms
[swscaler @ 0xb400006fbd2ed110] No accelerated colorspace conversion found from yuv420p to rgba.
flutter: [VideoPlayer] 打开成功: 1280x720, 时长: 73560ms, 帧率: 30.0fps
[VideoPlayer] 音频提取完成: /tmp/flutter/vp_audio_3978382032.wav bytes=14123608 ready=1
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libc++.so handle=0x2a7173237d1131ad
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libutils.so handle=0xc17f4ce7b79deb
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libcutils.so handle=0x71e306662cc13f19
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/liblog.so handle=0x0
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libaudio_log_utils.so handle=0x4461a9bb650f227b
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libsndcardparser.so handle=0xc7a95be9b430645
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm.so handle=0xcd1313ac0f280e91
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagmclient.so handle=0x55b00be7158cd93
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagmmixer.so handle=0x27fd30397b540d23
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm_pcm_plugin.so handle=0x54f412a949e6d81
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm_mixer_plugin.so handle=0x381050cfb4ee6401
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/vendor.qti.hardware.agm-V1-ndk.so handle=0xd0e66494f5a41abd
[VideoPlayer] start_audio_playback: wav=/tmp/flutter/vp_audio_3978382032.wav start_ms=0
[VideoPlayer] 音频线程启动 path=/tmp/flutter/vp_audio_3978382032.wav
[VideoPlayer] wav 信息: rate=48000 ch=2 bits=16 data=14123608
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=before open_output_pcm setprop rc=0
[VideoPlayer] 音频路由预热: phase=before open_output_pcm mixer rc=0
[VideoPlayer] 先尝试最小 AGM 直开: card=100 device=100 intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] AGM plugin open 失败: mode=-1 card=100 device=100 rc=-32 plugin=0x0
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] 最小 AGM PCM open 失败: cfg=source err=cannot open device 100 for card 100: Unknown error -32
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] 最小 AGM PCM open 失败: cfg=backend err=cannot open device 100 for card 100: Unknown error -32
mixer_plugin_open: failed to open plugin, err: -12
[VideoPlayer] 打开 AGM mixer 失败: card=100
mixer_plugin_open: failed to open plugin, err: -12
[VideoPlayer] 打开 AGM mixer 失败: card=100
[VideoPlayer] AGM plugin 打开全部失败，回退普通 PCM
[VideoPlayer] 打开 PCM 失败: card=0 device=16 cfg=backend err=cannot set hw params: Invalid argument
[VideoPlayer] 打开 PCM 成功: card=0 device=16 cfg=source rate=48000 ch=2 bits=16
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=after open_output_pcm setprop rc=0
[VideoPlayer] 音频路由预热: phase=after open_output_pcm mixer rc=0
[VideoPlayer] 音频线程进入播放循环 backend=1
[VideoPlayer] pcm_write 首次失败，重补 speaker mixer 后重试: backend=1 rc=-1
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=pcm_write retry setprop rc=0
[VideoPlayer] 音频路由预热: phase=pcm_write retry mixer rc=0
[VideoPlayer] pcm_write 失败: cannot write initial data: Invalid argument
[VideoPlayer] 音频线程退出: 写流失败 backend=1
[VideoPlayer] 音频线程退出 stop_requested=0


GitHub Copilot: 这轮日志把“依赖没加载”排掉了，新的前沿更具体了：依赖链都进进程了，但 `agm plugin/mixer plugin` 仍然返回 `-32/-12`。我先查这两个错误在当前仓库里有没有现成结论，再直接补最可能的运行时条件。

Searched for regex `-32|-12|mixer_plugin_open|failed to open plugin|libsndcardparser|sndcardparser|audio_io|backend_conf|usecaseKvManager` (`**/docs/**/*.md`), 128 results

Read memory twrp_audio_runtime_defer.md

Read memory twrp_audio_manual_playback.md

Compacted conversation现在看起来像 tinyalsa 插件层本身还能 `dlopen` 到 `libagm_pcm_plugin.so`，但插件内部初始化条件不满足。我去翻之前手记里围绕 `pcm_plug_open` 和 `backend_conf/usecaseKvManager` 的定位，看看有没有被忽略的初始化前置。Optimizing tool selection...

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3150-3150), lines 3150 to 3215

Searching for regex `agm_init|pal_init|usecaseKvManager|snd_card_def|backend_conf.xml|mixer_xml|plugin open|pcm_plug_open|mixer_plugin_open` (`**/*.{c,h,cpp,cc,md,txt,xml,sh}`)

Searched for regex `setenv\(|putenv\(|LD_LIBRARY_PATH|ANDROID_ROOT|ANDROID_DATA|vendor/etc|odm/etc|backend_conf.xml|usecaseKvManager.xml` (`**/video_player/**`), 2 results

上一轮直接开 card100/device100 的试验，和 `agmplay` 的关键差异之一是：`agmplay` 虽然命令行没显式传 `-ikv`，但它并不是“没有 instance_kv”，而是会从默认配置里补出来。我要对照当前实现，把这块补成“默认实例非零”而不是让插件吃到 0。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#200-200), lines 200 to 520

Searched for regex `instance_kv|AGM_INSTANCE|set_agm_stream_metadata|open_agm_direct_output|pcm_plug_open|backend_conf` (`**/video_player/video_player_ffi.c`), 18 results

Searched for regex `13.35|13.36|13.37|instance_kv|pcm_plug_open: failed to open plugin|MFC not present for this graph` (`**/docs/TWRP音频手动Bring-up.md`), 16 results

文档里已经有一条硬结论可以直接拿来落代码了：`instance_kv=0` 会把 graph 直接打回 `pcm_plug_open failed`。我现在对照最小直开路径，把它从“完全裸开”改成“先补默认 instance，再直开”。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#520-520), lines 520 to 760

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1240-1240), lines 1240 to 1415

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3290-3290), lines 3290 to 3365

我还缺一块关键信息：`-32/-12` 到底是插件内部哪一步吐出来的。先从本地拉下来的 AGM 相关 so 里抓错误字符串和配置路径，尽量把修改从“猜”变成“对位修”。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings audio_dtb_probe/libagm_pcm_plugin.so | rg 'failed|backend_conf|usecase|sndcard|plugin|XML|xml|odm/etc|vendor/etc|instance|card'
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings audio_dtb_probe/libagm_pcm_plugin.so | rg 'failed|backend_conf|usecase|sndcard|plugin|XML|xml|odm/etc|vendor/etc|instance|card'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings audio_dtb_probe/libagm_mixer_plugin.so | rg 'failed|backend_conf|usecase|sndcard|plugin|XML|xml|odm/etc|vendor/etc|instance|card'
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings audio_dtb_probe/libagm_mixer_plugin.so | rg 'failed|backend_conf|usecase|sndcard|plugin|XML|xml|odm/etc|vendor/etc|instance|card'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings audio_dtb_probe/libsndcardparser.so | rg 'backend_conf|usecase|snd_card|audio_platform_info|mixer_paths|odm/etc|vendor/etc|XML|xml|card'
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings audio_dtb_probe/libsndcardparser.so | rg 'backend_conf|usecase|snd_card|audio_platform_info|mixer_paths|odm/etc|vendor/etc|XML|xml|card'

本地 so 路径和我记的目录不一致，我先把实际文件位置找出来，再继续对错误字符串下钻。现在线索没变，还是在插件内部初始化条件。

Searched for files matching `**/libagm_pcm_plugin.so`, no matches

Searched for files matching `**/libagm_mixer_plugin.so`, no matches

Searched for files matching `**/libsndcardparser.so`, no matches

仓库里没有这些本地拷贝，那我改查现有源码和脚本里有没有已经记录过的“配置文件路径/默认实例”假设，再直接补实现。重点还是缩小 `agmplay` 和库内最小直开的运行时差异。

Searched for regex `AGM_BACKEND_CONF_PATH|AGM_PRIMARY_INTF|AGM_INSTANCE_KV|instance_kv << 16|set_agm_stream_metadata\(|set_agm_streamdevice_metadata\(|connect_agm_audio_intf_to_stream\(` (`**/video_player/video_player_ffi.c`), 29 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/build_so.sh)

Searched for regex `backend_conf.xml|usecaseKvManager.xml|agmplay|tinyplay_ftm|instance_kv` (`**/docs/**/*.md`), 80 results

现在差的不是“有没有 helper”，而是最小直开前完全没给插件喂任何 graph 上下文。下一步我会把直开改成“极简预编排”：只补 `instance/stream/device/devicepp` 和 connect，不走之前那套重 payload 的分支。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1120-1120), lines 1120 to 1295

Searched for regex `devicepp_kv|set_agm_streamdevice_metadata|get_device_media_config|set_agm_device_media_config|configure_mfc|agm_mixer_get_miid` (`**/video_player/video_player_ffi.c`), 30 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#2946-2946), lines 2946 to 2960

我准备再补一层“运行时环境对齐”，因为现在最像的是插件能装进来，但找不到它习惯的配置上下文。先确认仓库里有没有 `agmplay` 的本地二进制或已记录的环境变量线索；如果没有，我就直接在库里补一组保守的 env/bootstrap。

Searched for files matching `**/agmplay`, 1 match

Searched for files matching `**/*usecaseKvManager*.xml`, 2 matches

Searched for regex `LD_LIBRARY_PATH|ANDROID_ROOT|ANDROID_DATA|usecaseKvManager|backend_conf.xml|setenv\(|putenv\(` (`**/docs/**/*.md`), 35 results

有直接命中的旧结论了：之前前台手动起 vendor 二进制时，`LD_LIBRARY_PATH` 顺序不对会把整条链打坏；修成“真实 system 核心库优先，vendor 其次”后链路才继续前进。这个和现在“插件能加载，但初始化失败”是同一类症状，我先把这组环境在进程内补起来。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#730-730), lines 730 to 780

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#2790-2790), lines 2790 to 2880

Searched for regex `getenv\(|setenv\(|putenv\(` (`**/video_player/video_player_ffi.c`), no results

旧记录已经把一类坑钉死了：动态库搜索路径顺序会直接改变 AGM/PAL 是否能正常起来。接下来我会同时补两件事：进程内固定 `LD_LIBRARY_PATH`，以及最小直开前先灌默认 `instance_kv` 的极简 metadata。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1-1), lines 1 to 140

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#900-900), lines 900 to 1175

我已经定位到一个具体改法：当前最小直开只是在空白上下文里碰 plugin/pcm，和 `tinyplay_ftm` 差得太远。我要把它改成“先做极简 graph bootstrap，再直开”，同时固定进程内的库搜索顺序。

Searched for regex `close_output_stream\(|agm_connected|agm_mixer` (`**/video_player/video_player_ffi.c`), 50 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1415-1415), lines 1415 to 1515

我已经确认过清理逻辑没问题，所以可以安全地给最小直开挂一个临时 mixer 上下文。下面直接落代码、编译、复制到 native。

Generating patch (256 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
改动已经落下去了，当前有两个新增点：一是进程内固定 `LD_LIBRARY_PATH + backend/usecase` 环境，二是最小 AGM 直开前先做极简 graph bootstrap。接下来直接编译并把新的 so 复制到 native。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c), 28 problems found

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_so.sh
Completed with input:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_so.sh

编译卡在声明顺序，不是逻辑问题。我补一组前置声明就能继续构建。

Generating patch (18 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
声明顺序问题已经补好，现在重新构建并部署。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c), 28 problems found

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_so.sh

构建已经过了，编辑器里的报错仍然只是老的索引假阳性。现在把新 so 覆盖到 native，并核对哈希。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && cp '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/libvideo_player.so' aurora_recovery/native/libvideo_player.so && shasum -a 256 '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/libvideo_player.so' aurora_recovery/native/libvideo_player.so

我已经继续改了音频库，并重新编译、复制到 native 目录。

这次改动不是再去碰普通 PCM，而是直接补当前最可疑的两块运行时差异：
1. 进程内固定 AGM 运行时环境。现在会先设置 system 优先的动态库搜索顺序，并尝试把 backend_conf 和 usecaseKvManager 的路径灌进环境变量，避免插件在 Flutter 进程里找错核心库或配置上下文。
2. 最小 AGM 直开不再是裸开。现在在尝试 plugin 和 PCM 直开前，会先做一遍极简 graph bootstrap：device media config、audio intf metadata、stream metadata、device_kv、devicepp_kv、connect，以及默认 instance_kv=1 的路径对齐。

新的 so 已部署完成，源文件和 native 目录里的哈希一致：
3ff28b8d74c7898a202c5b7706615af574842be38ff691dc23b90cc9fb7f4e79

你下一次跑的时候，重点看几条新日志：
1. AGM 运行时环境: LD_LIBRARY_PATH=...
2. AGM 运行时环境: USECASE_KV_MANAGER_... 或 BACKEND_CONF_...
3. 最小 AGM bootstrap 完成: ...
4. after minimal direct bootstrap
5. 之后 AGM plugin open / mixer open 的返回码有没有从 -32 / -12 变化

我这边按你的要求没有去运行应用。你直接再跑一次，把新日志贴上来，我继续顺着这轮前沿往下收。

Made changes.

User: 
[VideoPlayer] 音频提取完成: /tmp/flutter/vp_audio_48355376.wav bytes=14123608 ready=1
flutter: [VideoPlayer] 打开成功: 1280x720, 时长: 73560ms, 帧率: 30.0fps
[VideoPlayer] AGM 运行时环境: LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/system/lib64:/vendor/lib64:/vendor/lib64/hw
[VideoPlayer] AGM 运行时环境: AGM_BACKEND_CONF_FILE=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: AGM_BACKEND_CONF_PATH=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: BACKEND_CONF_FILE=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: BACKEND_CONF_PATH=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: USECASE_KV_MANAGER_FILE=/odm/etc/usecaseKvManager.xml
[VideoPlayer] AGM 运行时环境: USECASE_KV_MANAGER_PATH=/odm/etc/usecaseKvManager.xml
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libc++.so handle=0x37711f8c5c9995cf
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libutils.so handle=0x75dcdab3a4504d0b
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libcutils.so handle=0xa33b7e8aeaa95125
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/liblog.so handle=0x0
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libaudio_log_utils.so handle=0xfa56491cebbb18b7
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libsndcardparser.so handle=0x79704a05aab42199
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm.so handle=0xace85303f886c33f
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagmclient.so handle=0x95a9a4a6049d3d05
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagmmixer.so handle=0x4e7cc497fa64e50b
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm_pcm_plugin.so handle=0xc2f06b6f5775f613
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm_mixer_plugin.so handle=0x8b0f9f69f8b4e8b
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/vendor.qti.hardware.agm-V1-ndk.so handle=0xadc08ede28446391
[VideoPlayer] start_audio_playback: wav=/tmp/flutter/vp_audio_48355376.wav start_ms=0
[VideoPlayer] 音频线程启动 path=/tmp/flutter/vp_audio_48355376.wav
[VideoPlayer] wav 信息: rate=48000 ch=2 bits=16 data=14123608
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=before open_output_pcm setprop rc=0
[VideoPlayer] 音频路由预热: phase=before open_output_pcm mixer rc=0
[VideoPlayer] PCM100 set enum: PCM100 control=TDM-LPAIF-RX-SECONDARY rc=0
[VideoPlayer] PCM100 set enum: PCM100 connect=TDM-LPAIF-RX-SECONDARY rc=0
[VideoPlayer] PCM100 控件快照: after minimal direct bootstrap
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] 最小 AGM bootstrap 完成: intf=TDM-LPAIF-RX-SECONDARY rate=48000 bits=32 instance_kv=65536
[VideoPlayer] 先尝试最小 AGM 直开: card=100 device=100 intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] AGM plugin open 失败: mode=-1 card=100 device=100 rc=-19 plugin=0x0
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] 最小 AGM PCM open 失败: cfg=source err=cannot open device 100 for card 100: Unknown error -19
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] 最小 AGM PCM open 失败: cfg=backend err=cannot open device 100 for card 100: Unknown error -19
[VideoPlayer] PCM100 控件快照: after device media config
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=0/21 name=ZERO
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-22 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] PCM100 控件快照: after audio intf metadata
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=0/21 name=ZERO
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-22 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] PCM100 控件快照: after stream metadata
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=0/21 name=ZERO
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-22 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] set_agm_streamdevice_metadata 成功: mode=1 variant=0 kv=2717908993
[VideoPlayer] PCM100 控件快照: after streamdevice metadata[0]
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] set_agm_streamdevice_metadata 成功: mode=1 variant=1 kv=2885681154
[VideoPlayer] PCM100 控件快照: after streamdevice metadata[1]
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] PCM100 控件快照: after payload agm_mixer_get_miid
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] payload agm_mixer_get_miid 失败: mode=1 rc=-19 miid=0 tag=3221225476
[VideoPlayer] PCM100 控件快照: after helper connect
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] PCM100 set enum: PCM100 control=TDM-LPAIF-RX-SECONDARY rc=0
[VideoPlayer] PCM100 set enum: PCM100 connect=TDM-LPAIF-RX-SECONDARY rc=0
[VideoPlayer] PCM100 控件快照: after force connect
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] PCM100 控件快照: after agm_mixer_get_miid
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] agm_mixer_get_miid 失败: mode=1 rc=-19 miid=0，继续尝试无 MFC 直开 PCM
[VideoPlayer] AGM mixer 路径准备完成: mode=1 device=100 intf=TDM-LPAIF-RX-SECONDARY backend=48000/8/32 device_kv=2717908993 miid=0 have_miid=0
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] AGM PCM open 失败: mode=1 cfg=source err=cannot open device 100 for card 100: Unknown error -19
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] AGM PCM open 失败: mode=1 cfg=backend err=cannot open device 100 for card 100: Unknown error -19
[VideoPlayer] AGM plugin open 失败: mode=1 card=100 device=100 rc=-19 plugin=0x0
[VideoPlayer] AGM plugin open 失败: mode=1 card=100 device=101 rc=-32 plugin=0x0
[VideoPlayer] AGM plugin open 失败: mode=1 card=100 device=102 rc=-32 plugin=0x0
[VideoPlayer] AGM plugin open 失败: mode=1 card=100 device=103 rc=-32 plugin=0x0
[VideoPlayer] AGM plugin open 失败: mode=1 card=100 device=0 rc=-22 plugin=0x0
[VideoPlayer] AGM plugin open 失败: mode=1 card=100 device=1 rc=-22 plugin=0x0
[VideoPlayer] AGM plugin open 失败: mode=1 card=100 device=2 rc=-22 plugin=0x0
[VideoPlayer] AGM plugin open 失败: mode=1 card=100 device=3 rc=-22 plugin=0x0
mixer_plugin_open: failed to open plugin, err: -12
[VideoPlayer] 打开 AGM mixer 失败: card=100
[VideoPlayer] AGM plugin 打开全部失败，回退普通 PCM
[VideoPlayer] 打开 PCM 失败: card=0 device=16 cfg=backend err=cannot set hw params: Invalid argument
[VideoPlayer] 打开 PCM 成功: card=0 device=16 cfg=source rate=48000 ch=2 bits=16
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=after open_output_pcm setprop rc=0
[VideoPlayer] 音频路由预热: phase=after open_output_pcm mixer rc=0
[VideoPlayer] 音频线程进入播放循环 backend=1
[VideoPlayer] pcm_write 首次失败，重补 speaker mixer 后重试: backend=1 rc=-1
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=pcm_write retry setprop rc=0
[VideoPlayer] 音频路由预热: phase=pcm_write retry mixer rc=0
[VideoPlayer] pcm_write 失败: cannot write initial data: Invalid argument
[VideoPlayer] 音频线程退出: 写流失败 backend=1
[VideoPlayer] 音频线程退出 stop_requested=0
Application finished.

Exited.


GitHub Copilot: 这轮日志有实质推进：`device100` 的最小直开已经从 `-32` 变成 `-19`，说明环境和最小 graph 上下文开始生效了。剩下没动的硬阻塞也更清楚了：`PCM100 metadata/setParam/setParamTag` 仍全零，所以我现在直接转去补原始 payload 路径，不再围着 plugin/env 打转。

Searched for regex `setParam|setParamTag|payload|PCM100 metadata|getTaggedInfo|raw payload|configure_mfc|device custom payload` (`**/docs/**/*.md`), 120 results

Searched for regex `mixer_ctl_set_array\(|setParamTag|PCM100 setParam|PCM100 metadata|getTaggedInfo` (`**/video_player/video_player_ffi.c`), 6 results

Searched for files matching `**/agmplay`, 1 match

现在线索很统一了：helper 能把 `control` 推到目标 backend，但真正触发 graph 后续的原始 BYTE payload 一直没写进去。我去翻文档里这段附近的结论，再从本地 agmplay 二进制里抓和 `setParamTag/getTaggedInfo` 相关的字符串，看看能不能直接做一个最小 payload 注入。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3278-3278), lines 3278 to 3368

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings audio_dtb_probe/agmplay | rg 'setParam|setParamTag|getTaggedInfo|metadata|payload|instance_kv|devicepp|stream_kv|TDM-LPAIF-RX-SECONDARY'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings audio_dtb_probe/agmplay | rg 'usecase|backend_conf|kv|devicepp|streamdevice|custom payload|get_miid|configure_mfc'

agmplay 的字符串把下一步也钉得更死了：在它那条成功链里，确实存在 `get_agm_usb_audio_config_payload` 和 `set_agm_device_custom_payload`，而我们现在完全没走这段。所以我先去翻已有笔记里对这两个 helper 的签名/参数形态有没有更细的记录；如果有，我就直接把它们接进当前路径做一次保守尝试。

Searched for regex `get_agm_usb_audio_config_payload|set_agm_device_custom_payload|custom payload|usb_audio_config_payload|payload builder` (`**/docs/**/*.md`), 6 results

Searching for regex `get_agm_usb_audio_config_payload|set_agm_device_custom_payload|usb_audio_config_payload|custom payload` (`**/*.{c,h,cpp,cc,txt,md}`)

Read memory twrp_audio_devicepp_kv_frontier.md

仓库里没有现成的 helper 签名记录，我先在源码树里搜这些 AGM 符号名和相关头文件。如果能找到 Qualcomm 头或同名实现，就能少猜一步，直接按真实签名接上 custom payload。

Searching for regex `get_agm_usb_audio_config_payload|set_agm_device_custom_payload|set_agm_streamdevice_metadata|agm_mixer_get_miid|configure_mfc` (`**/twrp_a16_compile/**/*.h`)

Searched for regex `get_agm_usb_audio_config_payload|set_agm_device_custom_payload|set_agm_streamdevice_metadata|agm_mixer_get_miid|configure_mfc` (`**/twrp_a16_compile/**/*.c`), no results

Searched for regex `get_agm_usb_audio_config_payload|set_agm_device_custom_payload|set_agm_streamdevice_metadata|agm_mixer_get_miid|configure_mfc` (`**/twrp_a12_compile/**/*.{h,c,cpp,cc}`), no results

源码树里没直接给出 Qualcomm 头，那我转成更保守的做法：先查现有手记里有没有 tag/payload 的字节级线索；如果仍然没有，我就给当前路径补一个最小的 `setParamTag/getTaggedInfo` 预热分支，至少验证 BYTE 控件是否可由我们直接驱动。

Searched for regex `c0000004|c0000019|setParamTag|getTaggedInfo|PCM100 array|w0=|metadata total=1024|setParam total=1048576` (`**/docs/TWRP音频手动Bring-up.md`), 12 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#760-760), lines 760 to 940

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings audio_dtb_probe/agmplay | rg 'Failed to set pcm metadata|Failed to set device metadata|set_agm_device_custom_payload failed|Valid format from backend_conf'

这轮我不再加新的高层 helper 了，直接把 `PCM100 metadata/setParamTag/setParam` 这组 BYTE 控件接成可写，并在 `get_miid(tag=0xC0000004)` 前做一次最小原始预热。目标很明确：先证明这些控件到底能不能被库内直接驱动，以及这一步会不会把 `-19` 再往前推。

Using "Apply Patch"

补丁没对上当前文件上下文，我先读取精确片段后重打一版，不改方向。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#760-760), lines 760 to 840

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#470-470), lines 470 to 620

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1070-1070), lines 1070 to 1095

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1030-1030), lines 1030 to 1110

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1110-1110), lines 1110 to 1215

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1215-1215), lines 1215 to 1295

我已经拿到精确上下文了，直接补最小 raw payload 预热，不再改其他逻辑。

Using "Apply Patch"

补丁工具对大块插入还是卡，我拆成两个小块来打：先加 helper，再在两个调用点插入。

Generating patch (114 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```


Generating patch (53 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
raw payload 预热已经接进去了。现在重新编译并覆盖部署，看这次日志会不会第一次出现 `PCM100 setParam/setParamTag` 非零。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c), 28 problems found

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_so.sh
Completed with input:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_so.sh

只是前置声明遗漏，补一下就能过。

Generating patch (20 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
前置声明补好了，重新构建并部署。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c), 28 problems found

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_so.sh && cp libvideo_player.so '/Volumes/Case-sensitive APFS/TWRP/aurora_recovery/native/libvideo_player.so' && shasum -a 256 libvideo_player.so '/Volumes/Case-sensitive APFS/TWRP/aurora_recovery/native/libvideo_player.so'

新一版已经编译并部署好了。

这次改动只做了一件事：把 `PCM100 metadata / setParamTag / setParam` 这组 BYTE 控件接成可写，并在两条关键路径上加了最小 raw payload 预热：
1. 最小 AGM 直开前
2. `mode=1` 的 `payload agm_mixer_get_miid(tag=0xC0000004)` 前

新的 so 已复制到 native，哈希一致：
`0722d202196d9f8a5a2a398eeecf9570dada8d224ec1e8e837f5c81fd8ab6b08`

你下一轮跑的时候，我只看这几个变化：
1. 有没有出现 `PCM100 set_array: PCM100 metadata ...`
2. 有没有出现 `PCM100 set_array: PCM100 setParamTag ...`
3. 有没有出现 `PCM100 set_array: PCM100 setParam ...`
4. `after raw payload prime` 里 `w0/w1/...` 是否第一次变成非零
5. `payload agm_mixer_get_miid` 的返回是否从 `-19` 再往前推进
6. `AGM plugin open ... device=100` 是否继续是 `-19`，还是跟着变化

编辑器里的报错还是老的索引假阳性，实际构建已经通过。你直接再跑一次，把新日志贴上来，我继续往下压这条 payload 路径。

Made changes.

User: 
[swscaler @ 0xb40000790fa63190] No accelerated colorspace conversion found from yuv420p to rgba.
flutter: [VideoPlayer] 打开成功: 1280x720, 时长: 73560ms, 帧率: 30.0fps
[VideoPlayer] 音频提取完成: /tmp/flutter/vp_audio_3213941456.wav bytes=14123608 ready=1
[VideoPlayer] AGM 运行时环境: LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/system/lib64:/vendor/lib64:/vendor/lib64/hw
[VideoPlayer] AGM 运行时环境: AGM_BACKEND_CONF_FILE=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: AGM_BACKEND_CONF_PATH=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: BACKEND_CONF_FILE=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: BACKEND_CONF_PATH=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: USECASE_KV_MANAGER_FILE=/odm/etc/usecaseKvManager.xml
[VideoPlayer] AGM 运行时环境: USECASE_KV_MANAGER_PATH=/odm/etc/usecaseKvManager.xml
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libc++.so handle=0x24a88a9b8f77fb89
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libutils.so handle=0x4dd4a9dcd34ccc33
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libcutils.so handle=0x501eade5714edf6d
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/liblog.so handle=0x0
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libaudio_log_utils.so handle=0x458a7f8a680e26c5
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libsndcardparser.so handle=0xf64966057fc856d5
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm.so handle=0x3c6ca053e0718b3d
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagmclient.so handle=0xbc991eaaf0b4a759
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagmmixer.so handle=0x1d2082147420ea57
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm_pcm_plugin.so handle=0xc25898c4172181b3
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm_mixer_plugin.so handle=0x7b482d676efbfe85
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/vendor.qti.hardware.agm-V1-ndk.so handle=0x4f7f90c85f007c3b
[VideoPlayer] start_audio_playback: wav=/tmp/flutter/vp_audio_3213941456.wav start_ms=0
[VideoPlayer] 音频线程启动 path=/tmp/flutter/vp_audio_3213941456.wav
[VideoPlayer] wav 信息: rate=48000 ch=2 bits=16 data=14123608
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=before open_output_pcm setprop rc=0
[VideoPlayer] 音频路由预热: phase=before open_output_pcm mixer rc=0
[VideoPlayer] PCM100 set_array: PCM100 metadata rc=-22 bytes=16/1024
[VideoPlayer] PCM100 set_array: PCM100 setParamTag rc=-22 bytes=16/262144
[VideoPlayer] PCM100 set_array: PCM100 setParam rc=0 bytes=32/1048576
[VideoPlayer] PCM100 控件快照: after raw payload prime
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] PCM100 set enum: PCM100 control=TDM-LPAIF-RX-SECONDARY rc=0
[VideoPlayer] PCM100 set enum: PCM100 connect=TDM-LPAIF-RX-SECONDARY rc=0
[VideoPlayer] PCM100 控件快照: after minimal direct bootstrap
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] 最小 AGM bootstrap 完成: intf=TDM-LPAIF-RX-SECONDARY rate=48000 bits=32 instance_kv=65536
[VideoPlayer] 先尝试最小 AGM 直开: card=100 device=100 intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] AGM plugin open 失败: mode=-1 card=100 device=100 rc=-19 plugin=0x0
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] 最小 AGM PCM open 失败: cfg=source err=cannot open device 100 for card 100: Unknown error -19
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] 最小 AGM PCM open 失败: cfg=backend err=cannot open device 100 for card 100: Unknown error -19
[VideoPlayer] PCM100 控件快照: after device media config
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=0/21 name=ZERO
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-22 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] PCM100 控件快照: after audio intf metadata
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=0/21 name=ZERO
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-22 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] PCM100 控件快照: after stream metadata
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=0/21 name=ZERO
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-22 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] set_agm_streamdevice_metadata 成功: mode=1 variant=0 kv=2717908993
[VideoPlayer] PCM100 控件快照: after streamdevice metadata[0]
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] set_agm_streamdevice_metadata 成功: mode=1 variant=1 kv=2885681154
[VideoPlayer] PCM100 控件快照: after streamdevice metadata[1]
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] PCM100 set_array: PCM100 metadata rc=-22 bytes=16/1024
[VideoPlayer] PCM100 set_array: PCM100 setParamTag rc=-22 bytes=16/262144
[VideoPlayer] PCM100 set_array: PCM100 setParam rc=0 bytes=32/1048576
[VideoPlayer] PCM100 控件快照: after raw payload prime
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] PCM100 控件快照: after payload agm_mixer_get_miid
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] payload agm_mixer_get_miid 失败: mode=1 rc=-19 miid=0 tag=3221225476
[VideoPlayer] PCM100 控件快照: after helper connect
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] PCM100 set enum: PCM100 control=TDM-LPAIF-RX-SECONDARY rc=0
[VideoPlayer] PCM100 set enum: PCM100 connect=TDM-LPAIF-RX-SECONDARY rc=0
[VideoPlayer] PCM100 控件快照: after force connect
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] PCM100 控件快照: after agm_mixer_get_miid
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] agm_mixer_get_miid 失败: mode=1 rc=-19 miid=0，继续尝试无 MFC 直开 PCM
[VideoPlayer] AGM mixer 路径准备完成: mode=1 device=100 intf=TDM-LPAIF-RX-SECONDARY backend=48000/8/32 device_kv=2717908993 miid=0 have_miid=0
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] AGM PCM open 失败: mode=1 cfg=source err=cannot open device 100 for card 100: Unknown error -19
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] AGM PCM open 失败: mode=1 cfg=backend err=cannot open device 100 for card 100: Unknown error -19
[VideoPlayer] AGM plugin open 失败: mode=1 card=100 device=100 rc=-19 plugin=0x0
[VideoPlayer] AGM plugin open 失败: mode=1 card=100 device=101 rc=-32 plugin=0x0
[VideoPlayer] AGM plugin open 失败: mode=1 card=100 device=102 rc=-32 plugin=0x0
[VideoPlayer] AGM plugin open 失败: mode=1 card=100 device=103 rc=-32 plugin=0x0
[VideoPlayer] AGM plugin open 失败: mode=1 card=100 device=0 rc=-22 plugin=0x0
[VideoPlayer] AGM plugin open 失败: mode=1 card=100 device=1 rc=-22 plugin=0x0
[VideoPlayer] AGM plugin open 失败: mode=1 card=100 device=2 rc=-22 plugin=0x0
[VideoPlayer] AGM plugin open 失败: mode=1 card=100 device=3 rc=-22 plugin=0x0
mixer_plugin_open: failed to open plugin, err: -12
[VideoPlayer] 打开 AGM mixer 失败: card=100
[VideoPlayer] AGM plugin 打开全部失败，回退普通 PCM
[VideoPlayer] 打开 PCM 失败: card=0 device=16 cfg=backend err=cannot set hw params: Invalid argument
[VideoPlayer] 打开 PCM 成功: card=0 device=16 cfg=source rate=48000 ch=2 bits=16
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=after open_output_pcm setprop rc=0
[VideoPlayer] 音频路由预热: phase=after open_output_pcm mixer rc=0
[VideoPlayer] 音频线程进入播放循环 backend=1
[VideoPlayer] pcm_write 首次失败，重补 speaker mixer 后重试: backend=1 rc=-1
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=pcm_write retry setprop rc=0
[VideoPlayer] 音频路由预热: phase=pcm_write retry mixer rc=0
[VideoPlayer] pcm_write 失败: cannot write initial data: Invalid argument
[VideoPlayer] 音频线程退出: 写流失败 backend=1


GitHub Copilot: 这轮结果把一个边界钉死了：`PCM100 metadata` 和 `setParamTag` 不是“随便写几个字”就能接受的普通 BYTE 控件，当前 16 字节写入直接 `-22`。我先从本地 agmplay 的导入符号和字符串把 `custom payload` 那段再压实，目标是下一步不要再盲写。

Searched for text `PCM100 set_array: PCM100 metadata rc=-22|setParamTag rc=-22|setParam rc=0|payload agm_mixer_get_miid 失败` (`**/docs/**/*.md`), no results

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && file audio_dtb_probe/agmplay && xcrun llvm-readelf -Ws audio_dtb_probe/agmplay | rg 'agm_|mixer_ctl_set_array|pcm_'
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && file audio_dtb_probe/agmplay && xcrun llvm-readelf -Ws audio_dtb_probe/agmplay | rg 'agm_|mixer_ctl_set_array|pcm_'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && xcrun llvm-objdump -d --no-show-raw-insn audio_dtb_probe/agmplay | rg -n 'get_agm_usb_audio_config_payload|set_agm_device_custom_payload|set_agm_stream_metadata|set_agm_streamdevice_metadata|agm_mixer_get_miid|configure_mfc'

反汇编已经给出一个更强信号：agmplay 主路径里确实走到了 `get_agm_usb_audio_config_payload -> set_agm_device_custom_payload`，而且就在第一次 `get_miid(tag=0xC0000004)` 之后、第二次 `get_miid(tag=0xC0000019)` 之前。下一步我直接抠这段调用周围的寄存器准备，尽量把签名和最小参数形态还原出来。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#90-90), lines 90 to 190

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && xcrun llvm-objdump -d --no-show-raw-insn --start-address=0x6640 --stop-address=0x6868 audio_dtb_probe/agmplay

这轮最直接可改的点已经出来了：`metadata` 和 `setParamTag` 的 `-22` 很像“长度不对”，不是“内容不对”。我先把 BYTE 写入从“只写前缀”改成“按控件全长零填充后整块提交”，看能不能先把 `-22` 压成 `0`。

Generating patch (34 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
长度策略已经改了，现在重新编译并部署这一版。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c), 28 problems found

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_so.sh && cp libvideo_player.so '/Volumes/Case-sensitive APFS/TWRP/aurora_recovery/native/libvideo_player.so' && shasum -a 256 libvideo_player.so '/Volumes/Case-sensitive APFS/TWRP/aurora_recovery/native/libvideo_player.so'

这版已经部署完了，新的实验点是“按控件全长提交 BYTE 数据”，不再只写前 16/32 字节。我要顺手把这个新前沿记进仓库记忆，避免后面重复回到短写假设。

Inserted into memory file twrp_audio_devicepp_kv_frontier.md

我已经继续改了，并重新编译、复制到 native 目录。

这次不是换逻辑分支，而是只验证一个更具体的假设：`PCM100 metadata` 和 `setParamTag` 的 `-22` 很可能是写入长度不对。所以我把 BYTE 控件写入改成了“按控件全长分配、前缀填数据、剩余补零、整块提交”，不再只发前 16/32 字节。

新的 so 已部署完成，当前哈希是：
`1c53f0a759b70dd3802d12810dfc9b3822152194b6d0b27f58df1d4e09859f06`

你下一轮跑的时候，我只看这几条：
1. `PCM100 set_array: PCM100 metadata rc=... payload=16 total=1024`
2. `PCM100 set_array: PCM100 setParamTag rc=... payload=16 total=262144`
3. `PCM100 set_array: PCM100 setParam rc=... payload=32 total=1048576`
4. `after raw payload prime` 里 `metadata/setParam/setParamTag` 的 `w0-w3` 有没有第一次变成非零
5. `payload agm_mixer_get_miid` 是否还停在 `rc=-19 miid=0`

这轮日志已经说明一个很重要的事实：短写 `metadata/setParamTag` 会直接 `-22`，所以之前那条假设可以先收掉了。现在就看全长提交能不能把这一步真正推过去。

Made changes.

User: [INFO][HandleMinuitwrpEvents(701)] MINUITWRP -> OnTouchUp
[swscaler @ 0xb40000721ea211e0] No accelerated colorspace conversion found from yuv420p to rgba.
[VideoPlayer] 音频提取完成: /tmp/flutter/vp_audio_2122883232.wav bytes=14123608 ready=1
flutter: [VideoPlayer] 打开成功: 1280x720, 时长: 73560ms, 帧率: 30.0fps
[VideoPlayer] AGM 运行时环境: LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/system/lib64:/vendor/lib64:/vendor/lib64/hw
[VideoPlayer] AGM 运行时环境: AGM_BACKEND_CONF_FILE=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: AGM_BACKEND_CONF_PATH=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: BACKEND_CONF_FILE=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: BACKEND_CONF_PATH=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: USECASE_KV_MANAGER_FILE=/odm/etc/usecaseKvManager.xml
[VideoPlayer] AGM 运行时环境: USECASE_KV_MANAGER_PATH=/odm/etc/usecaseKvManager.xml
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libc++.so handle=0xe74b407364ab78dd
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libutils.so handle=0xbe406cee5d3ef8df
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libcutils.so handle=0x1a6baaa5a2a42b3
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/liblog.so handle=0x0
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libaudio_log_utils.so handle=0x9eb97baca43966f9
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libsndcardparser.so handle=0x2c066bfb23265669
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm.so handle=0xff829b0cf5b28e37
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagmclient.so handle=0xb813f06e3eb5aa81
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagmmixer.so handle=0xc95bf9dfab603773
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm_pcm_plugin.so handle=0x93b1863b00883107
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm_mixer_plugin.so handle=0xc9a037a2c162cd4d
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/vendor.qti.hardware.agm-V1-ndk.so handle=0x9a570fb16e0e2fa5
[VideoPlayer] start_audio_playback: wav=/tmp/flutter/vp_audio_2122883232.wav start_ms=0
[VideoPlayer] 音频线程启动 path=/tmp/flutter/vp_audio_2122883232.wav
[VideoPlayer] wav 信息: rate=48000 ch=2 bits=16 data=14123608
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=before open_output_pcm setprop rc=0
[VideoPlayer] 音频路由预热: phase=before open_output_pcm mixer rc=0
[VideoPlayer] PCM100 set_array: PCM100 metadata rc=-22 payload=16 total=1024
[VideoPlayer] PCM100 set_array: PCM100 setParamTag rc=-22 payload=16 total=262144
[VideoPlayer] PCM100 set_array: PCM100 setParam rc=0 payload=32 total=1048576
[VideoPlayer] PCM100 控件快照: after raw payload prime
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] PCM100 set enum: PCM100 control=TDM-LPAIF-RX-SECONDARY rc=0
[VideoPlayer] PCM100 set enum: PCM100 connect=TDM-LPAIF-RX-SECONDARY rc=0
[VideoPlayer] PCM100 控件快照: after minimal direct bootstrap
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] 最小 AGM bootstrap 完成: intf=TDM-LPAIF-RX-SECONDARY rate=48000 bits=32 instance_kv=65536
[VideoPlayer] 先尝试最小 AGM 直开: card=100 device=100 intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] AGM plugin open 失败: mode=-1 card=100 device=100 rc=-19 plugin=0x0
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] 最小 AGM PCM open 失败: cfg=source err=cannot open device 100 for card 100: Unknown error -19
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] 最小 AGM PCM open 失败: cfg=backend err=cannot open device 100 for card 100: Unknown error -19
[VideoPlayer] PCM100 控件快照: after device media config
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=0/21 name=ZERO
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-22 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] PCM100 控件快照: after audio intf metadata
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=0/21 name=ZERO
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-22 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] PCM100 控件快照: after stream metadata
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=0/21 name=ZERO
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-22 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] set_agm_streamdevice_metadata 成功: mode=1 variant=0 kv=2717908993
[VideoPlayer] PCM100 控件快照: after streamdevice metadata[0]
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] set_agm_streamdevice_metadata 成功: mode=1 variant=1 kv=2885681154
[VideoPlayer] PCM100 控件快照: after streamdevice metadata[1]
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] PCM100 set_array: PCM100 metadata rc=-22 payload=16 total=1024
[VideoPlayer] PCM100 set_array: PCM100 setParamTag rc=-22 payload=16 total=262144
[VideoPlayer] PCM100 set_array: PCM100 setParam rc=0 payload=32 total=1048576
[VideoPlayer] PCM100 控件快照: after raw payload prime
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] PCM100 控件快照: after payload agm_mixer_get_miid
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] payload agm_mixer_get_miid 失败: mode=1 rc=-19 miid=0 tag=3221225476
[VideoPlayer] PCM100 控件快照: after helper connect
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] PCM100 set enum: PCM100 control=TDM-LPAIF-RX-SECONDARY rc=0
[VideoPlayer] PCM100 set enum: PCM100 connect=TDM-LPAIF-RX-SECONDARY rc=0
[VideoPlayer] PCM100 控件快照: after force connect
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] PCM100 控件快照: after agm_mixer_get_miid
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] agm_mixer_get_miid 失败: mode=1 rc=-19 miid=0，继续尝试无 MFC 直开 PCM
[VideoPlayer] AGM mixer 路径准备完成: mode=1 device=100 intf=TDM-LPAIF-RX-SECONDARY backend=48000/8/32 device_kv=2717908993 miid=0 have_miid=0
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] AGM PCM open 失败: mode=1 cfg=source err=cannot open device 100 for card 100: Unknown error -19
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] AGM PCM open 失败: mode=1 cfg=backend err=cannot open device 100 for card 100: Unknown error -19
[VideoPlayer] AGM plugin open 失败: mode=1 card=100 device=100 rc=-19 plugin=0x0
[VideoPlayer] AGM plugin open 失败: mode=1 card=100 device=101 rc=-32 plugin=0x0
[VideoPlayer] AGM plugin open 失败: mode=1 card=100 device=102 rc=-32 plugin=0x0
[VideoPlayer] AGM plugin open 失败: mode=1 card=100 device=103 rc=-32 plugin=0x0
[VideoPlayer] AGM plugin open 失败: mode=1 card=100 device=0 rc=-22 plugin=0x0
[VideoPlayer] AGM plugin open 失败: mode=1 card=100 device=1 rc=-22 plugin=0x0
[VideoPlayer] AGM plugin open 失败: mode=1 card=100 device=2 rc=-22 plugin=0x0
[VideoPlayer] AGM plugin open 失败: mode=1 card=100 device=3 rc=-22 plugin=0x0
mixer_plugin_open: failed to open plugin, err: -12
[VideoPlayer] 打开 AGM mixer 失败: card=100
[VideoPlayer] AGM plugin 打开全部失败，回退普通 PCM
[VideoPlayer] 打开 PCM 失败: card=0 device=16 cfg=backend err=cannot set hw params: Invalid argument
[VideoPlayer] 打开 PCM 成功: card=0 device=16 cfg=source rate=48000 ch=2 bits=16
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=after open_output_pcm setprop rc=0
[VideoPlayer] 音频路由预热: phase=after open_output_pcm mixer rc=0
[VideoPlayer] 音频线程进入播放循环 backend=1
[VideoPlayer] pcm_write 首次失败，重补 speaker mixer 后重试: backend=1 rc=-1
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=pcm_write retry setprop rc=0
Application finished.

Exited.


GitHub Copilot: 我先把刚拿到的反汇编线索继续压实，因为这轮日志说明“全长写 BYTE 控件”也不是根因。现在最高价值的信息已经不在运行态试错，而在 agmplay 实际怎么准备 `custom payload` 和那两次 `set_agm_stream_metadata`。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && xcrun llvm-objdump -d --no-show-raw-insn --start-address=0x65c0 --stop-address=0x6710 audio_dtb_probe/agmplay

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && xcrun llvm-objdump -d --no-show-raw-insn --start-address=0x6770 --stop-address=0x67d0 audio_dtb_probe/agmplay

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings audio_dtb_probe/agmplay | rg 'usb.*device|usb_d|sample rate|bit width|channel count|payload'

现在我有两条新结论了：一是 agmplay 实际上确实有两次 `set_agm_stream_metadata`；二是 `custom payload` 这段调用签名已经缩得比较小了。我再做一步小的静态取证，确认那个 `strcmp` 比较的接口名常量到底是不是我们这条 `TDM-LPAIF-RX-SECONDARY`。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings -t x audio_dtb_probe/agmplay | rg 'TDM-LPAIF-RX-SECONDARY|USB|usb|MIID|payload|CODEC_DMA|LPAIF'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && xcrun llvm-objdump -s --start-address=0x2960 --stop-address=0x2990 audio_dtb_probe/agmplay

比较常量已经出来了：`custom payload` 这一段只在接口名等于 `USB_AUDIO-RX` 时才进。也就是说，这条 helper 不能直接搬到我们现在的 `TDM-LPAIF-RX-SECONDARY` 路线上。我要把这条死路正式收掉，然后把重点切回一个更小的改动：把我们刚确认错误的“第二次 stream metadata”形态修回跟 agmplay 一致。

Searched for regex `set_agm_stream_metadata\(mixer,\s*AGM_PCM_DEVICE|set_agm_stream_metadata\(mixer,\s*AGM_STREAM_KV_PCM_LL_PLAYBACK|instance_kv = AGM_INSTANCE_KV << 16` (`**/video_player/video_player_ffi.c`), 2 results

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_2gnajXfmawzJGsa2FgZTP0N7__vscode-1773701472068/content.txt#1-1), lines 1 to 40

Inserted into memory file twrp_audio_devicepp_kv_frontier.md

我准备先做一轮离线逆向梳理，而不是继续拍脑袋改代码。目标是把 agmplay 这段调用的真实参数关系整理清楚，特别是那两次 `set_agm_stream_metadata` 和 USB 守卫之外还有没有 speaker 路线分支。

分析 agmplay 调用序

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#1-1), lines 1 to 100

Read memory [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/memory-tool/memories/ZTg2MmQ5YzgtYzAzMS00M2RiLWEwZTYtZTI3NTZlMTVkZjUy)

Read memory twrp_audio_agmmixer_helper_semantics.md

Read memory twrp_audio_pcm_route_frontier.md

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#1-1), lines 1 to 500

Read memory [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/memory-tool/memories/ZTg2MmQ5YzgtYzAzMS00M2RiLWEwZTYtZTI3NTZlMTVkZjUy/agm_mode0_not_enough.md)

Read memory twrp_audio_agmplay_minimal_success.md

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#100-100), lines 100 to 200

Search complete: 找出 agmplay 中 AGM 主路径的 helper 调用顺序

Searched for files matching `**/*agmplay*`, 1 match

Searching for regex `set_agm_stream_metadata|get_agm_usb_audio_config_payload|set_agm_device_custom_payload`

Searching for text `agmplay`

Searching for text `set_agm_stream_metadata`

Searching for text `get_agm_usb_audio_config_payload`

Searching for text `set_agm_device_custom_payload`

Searched for files matching `**/audio_dtb_probe/**`, 200 matches

Read memory twrp_audio_devicepp_kv_frontier.md

Read memory twrp_audio_userspace_hal_gap.md

Read memory twrp_audio_component_gap.md

Searched codebase for "agmplay main speaker playback helper call sequence connect graph metadata instance", 12 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1-1), lines 1 to 100

Searching for text `set_agm_stream_metadata configure_mfc get_agm_usb_audio_config_payload set_agm_device_custom_payload`

Searched for regex `tag=0xC0000004|tag=0xC0000019|get_agm_miid|graph_open` (`**/docs/**`), 20 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#100-100), lines 100 to 400

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#400-400), lines 400 to 800

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#800-800), lines 800 to 1200

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1200-1200), lines 1200 to 1600

Updated memory file twrp_audio_agmmixer_helper_semantics.md

Inserted into memory file twrp_audio_agmmixer_helper_semantics.md

Updated memory file twrp_audio_agmmixer_helper_semantics.md

Read memory twrp_audio_agmmixer_helper_semantics.md

Updated memory file twrp_audio_agmmixer_helper_semantics.md

反汇编这边给出了一个足够硬的新边界：`custom payload` 那段前面有 `strcmp(intf_name, "USB_AUDIO-RX")` 守卫，所以我们现在对 `TDM-LPAIF-RX-SECONDARY` 强行走 `payload prime + tag=0xC0000004`，大概率本身就是错路。下面我直接把这段改成“仅 USB 路径启用”。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#470-470), lines 470 to 640

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1180-1180), lines 1180 to 1275

我要做的改动很小：只加一个接口判断，把 `raw payload prime` 和前置 `tag=0xC0000004` 查询都限定到 `USB_AUDIO-RX`，避免继续把 USB 专用段硬塞进 speaker 路线。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1275-1275), lines 1275 to 1355

Searched for regex `payload_miid|AGM_DEVICE_CUSTOM_PAYLOAD_TAG|prime_pcm100_payload_controls` (`**/video_player/video_player_ffi.c`), 15 results

Generating patch (116 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
这次改动已经落下去了：speaker 路线不再走 USB 专用 `custom payload` 和前置 `tag=0xC0000004`。现在直接重建并部署，让下一轮日志只反映非 USB 主路径。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c), 28 problems found

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_so.sh && cp libvideo_player.so '/Volumes/Case-sensitive APFS/TWRP/aurora_recovery/native/libvideo_player.so' && shasum -a 256 libvideo_player.so '/Volumes/Case-sensitive APFS/TWRP/aurora_recovery/native/libvideo_player.so'

新一版已经编译并部署了。

这次改动只做一件事：把 `custom payload` 相关逻辑限制到 `USB_AUDIO-RX`。原因已经被反汇编钉死了，agmplay 在 `get_agm_usb_audio_config_payload -> set_agm_device_custom_payload` 前有明确的 `strcmp(intf_name, "USB_AUDIO-RX")` 守卫，所以那段不是当前 `TDM-LPAIF-RX-SECONDARY` speaker 路线该走的分支。

新的 so 已覆盖到 native，哈希一致：
`27dc4b7b7ada6535af4ff706544da64d7795238df36bdffa3533be20f5b0004e`

你下一轮跑的时候，我只看这几个点：
1. 是否出现 `跳过 USB custom payload 路径: intf=TDM-LPAIF-RX-SECONDARY mode=1`
2. 日志里不应再出现 `PCM100 set_array: PCM100 metadata ...` 和 `PCM100 set_array: PCM100 setParamTag ...`
3. `AGM plugin open ... device=100` 是否还停在 `rc=-19`
4. `connect` 后的 `agm_mixer_get_miid(tag=0xC0000019)` 有没有变化

这轮的意义是把一条已经证伪的 USB 专用支路从 speaker 主路径里拿掉，避免继续被 `-22/-19` 噪声干扰。你直接再跑一次，把新日志贴上来，我继续往下收敛。

Made changes.

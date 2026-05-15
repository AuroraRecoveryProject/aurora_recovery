
Exited.


GitHub Copilot: 我现在不靠现象猜了，直接从 blob 里查谁会真正用到 `setParamTag` 这条控件；如果库里根本没有 helper，我就自己补一条最小原始写入。

Ran terminal command:  objdump -d "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/libagmmixer.so" | rg -n "#0x956|#0xa7c|#0x879|setParamTag|getTaggedInfo|agm_mixer_set_param@plt|mixer_ctl_set_array@plt"

Ran terminal command:  objdump -d "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/agmplay" | rg -n "agm_mixer_set_param|setParamTag|getTaggedInfo|configure_mfc|agm_mixer_get_miid"

我已经确认 `agmplay` 自己也没有直接调 `setParamTag` 导出 helper，所以关键很可能在 `libagmmixer.so` 内部另外一条写 payload 路径；我把这几处 `set_array` 近邻读出来，找它到底往哪个控件写。

Ran terminal command:  objdump -d --start-address=0xa6f0 --stop-address=0xa7e8 "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/libagmmixer.so"

Ran terminal command:  objdump -d --start-address=0xac80 --stop-address=0xadd0 "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/libagmmixer.so"

Ran terminal command:  objdump -d --start-address=0xc0d0 --stop-address=0xc190 "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/libagmmixer.so"

AGM 这条线已经把关键状态逼出来了，但还是没跨过 `graph_open`；我同时检查普通 PCM 回退路径，看看是不是直接把它切到 `8ch/32bit` 后就能先把声音打出来。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1240-1240), lines 1240 to 1495

Read memory twrp_audio_manual_playback.md

Read memory twrp_audio_standard_path_priority.md

AGM 这条线还卡在图没成型，但普通 PCM 回退已经给出一个更直接的根因信号了：`card0/device16` 能 open、却在首包写入时报 `Invalid argument`，这很像驱动实际要的是 backend 格式而不是源 WAV 格式；我先把回退路径改成优先尝试 `48k/8ch/32bit`，并在普通 PCM 写入时也做 `2ch16 -> 8ch32` 转换。

Generating patch (139 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
改动已经完成，我现在直接重建并覆盖 `native` 目录；如果这条回退路径可用，你下一轮应该先看到 `打开 PCM 成功: ... cfg=backend`，再看是否还会在首包写入时报错。

Ran terminal command:  ./build_so.sh

Ran terminal command:  cp "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/libvideo_player.so" "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/aurora_recovery/native/libvideo_player.so"

Ran terminal command:  strings "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/aurora_recovery/native/libvideo_player.so" | rg -n "cfg=backend|cfg=source|打开 PCM 成功: card=0 device=%u cfg=%s"
Completed with input:  strings "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/aurora_recovery/native/libvideo_player.so" | rg -n "cfg=backend|cfg=source|打开 PCM 成功: card=0 device=%u cfg=%s"

新的 so 已经重新编译并拷贝到 `native` 目录。

这次改的是普通 PCM 回退路径，不是 AGM 日志：
1. `card0/device16` 和 `device14` 现在会先尝试 `backend` 配置，也就是 `48k/8ch/32bit`。
2. 如果普通 PCM 走的是 backend 配置，写入前会自动把 `2ch/16bit` WAV 转成 `8ch/32bit`，不再直接把源格式裸写进去。
3. 保留了原来的 `source` 配置兜底，所以现在会按 `backend -> source` 顺序试。

你下一次跑时，先只看这几行：
1. `打开 PCM 成功: card=0 device=... cfg=backend ...`
2. 如果没成，再看 `打开 PCM 失败: ... cfg=backend ...`
3. 最后看还有没有 `pcm_write 失败: cannot write initial data: Invalid argument`

这一步的目的很直接：先验证是不是普通 PCM 只是格式写错了。如果这次 backend 格式能写通，后面 AGM 可以慢慢收；如果还是不行，我下一步就回到 `setParamTag` 原始 payload。

Made changes.

User: [INFO][HandleMinuitwrpEvents(701)] MINUITWRP -> OnTouchUp
[INFO][HandleMinuitwrpEvents(701)] MINUITWRP -> OnTouchUp
[INFO][HandleMinuitwrpEvents(701)] MINUITWRP -> OnTouchUp
[INFO][HandleMinuitwrpEvents(701)] MINUITWRP -> OnTouchUp
[swscaler @ 0xb400007be3238080] No accelerated colorspace conversion found from yuv420p to rgba.
flutter: [VideoPlayer] 打开成功: 1280x720, 时长: 73560ms, 帧率: 30.0fps
[VideoPlayer] 音频提取完成: /tmp/flutter/vp_audio_3810553792.wav bytes=14123608 ready=1
[VideoPlayer] start_audio_playback: wav=/tmp/flutter/vp_audio_3810553792.wav start_ms=0
[VideoPlayer] 音频线程启动 path=/tmp/flutter/vp_audio_3810553792.wav
[VideoPlayer] wav 信息: rate=48000 ch=2 bits=16 data=14123608
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
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
[VideoPlayer] PCM100 控件快照: after stream metadata kv
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
[VideoPlayer] PCM100 控件快照: after stream metadata instance
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
[VideoPlayer] PCM100 控件快照: after helper connect
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
[VideoPlayer] agm_mixer_get_miid 失败: mode=0 rc=-19 miid=0，继续尝试无 MFC 直开 PCM
[VideoPlayer] AGM mixer 路径准备完成: mode=0 device=100 intf=TDM-LPAIF-RX-SECONDARY backend=48000/8/32 device_kv=0 miid=0 have_miid=0
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] AGM PCM open 失败: mode=0 cfg=source err=cannot open device 100 for card 100: Unknown error -19
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] AGM PCM open 失败: mode=0 cfg=backend err=cannot open device 100 for card 100: Unknown error -19
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
[VideoPlayer] PCM100 控件快照: after stream metadata kv
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
[VideoPlayer] PCM100 控件快照: after stream metadata instance
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
[VideoPlayer] set_agm_streamdevice_metadata 成功: mode=1 variant=0 device_kv=2717908993
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
[VideoPlayer] set_agm_streamdevice_metadata 成功: mode=1 variant=1 device_kv=2717908993
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
[VideoPlayer] AGM plugin open 失败: card=100 device=100 rc=-32 plugin=0x0
[VideoPlayer] AGM plugin open 失败: card=100 device=101 rc=-32 plugin=0x0
[VideoPlayer] AGM plugin open 失败: card=100 device=102 rc=-32 plugin=0x0
[VideoPlayer] AGM plugin open 失败: card=100 device=103 rc=-32 plugin=0x0
[VideoPlayer] AGM plugin open 失败: card=100 device=0 rc=-22 plugin=0x0
[VideoPlayer] AGM plugin open 失败: card=100 device=1 rc=-22 plugin=0x0
[VideoPlayer] AGM plugin open 失败: card=100 device=2 rc=-22 plugin=0x0
[VideoPlayer] AGM plugin open 失败: card=100 device=3 rc=-22 plugin=0x0
[VideoPlayer] AGM plugin 打开全部失败，回退普通 PCM
[VideoPlayer] 打开 PCM 失败: card=0 device=16 cfg=backend err=cannot set hw params: Invalid argument
[VideoPlayer] 打开 PCM 成功: card=0 device=16 cfg=source rate=48000 ch=2 bits=16
[VideoPlayer] 音频线程进入播放循环 backend=1
[VideoPlayer] pcm_write 失败: cannot write initial data: Invalid argument
[VideoPlayer] 音频线程退出: 写流失败 backend=1
[VideoPlayer] 音频线程退出 stop_requested=0


GitHub Copilot: 当前增量结论已经很清楚：`AGM` 仍然没把任何 payload 写进 `PCM100`，而普通 PCM 的 `device16` 只能按 `2ch/16bit` 打开却首包写入失败；我先查现有仓库记录里对 `device16` 和 `pcm_write Invalid argument` 的已验证结论，避免重复试错。

Searched for regex `device=16|pcm_write 失败|Invalid argument|打开 PCM 成功|tinyplay|pcm_open` (`**/docs/**/*.md`), 105 results

Searched for regex `device=16|pcm_write 失败|Invalid argument|打开 PCM 成功|tinyplay|pcm_open` (`**/video_player/video_player_ffi.c`), 11 results

Read memory twrp_audio_true_tinyplay_probe.md

Read memory twrp_audio_pcm_route_frontier.md

这轮真正有价值的增量出来了：`streamdevice metadata[0]/[1]` 两次调用都会把 `control` 推到 `TDM-LPAIF-RX-SECONDARY`，但我之前把两次都喂了同一个 `speaker device_kv`；而你仓库里的已验证 `tinyplay_ftm` 基线明确还带了 `devicepp_kv=0xAC000002`，所以第二次变体现在明显传错了。

Generating patch (67 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
我现在把这个修正编进去并覆盖到 `native`；如果这条判断对，下一轮最值得看的就是 `variant=1 kv=2885681154` 之后 `getTaggedInfo` 或 `connect` 有没有继续前进。

Ran terminal command:  ./build_so.sh

Ran terminal command:  cp "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/libvideo_player.so" "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/aurora_recovery/native/libvideo_player.so"

Ran terminal command:  strings "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/aurora_recovery/native/libvideo_player.so" | rg -n "variant=%u kv=%u|AC000002|DEVICEPP"

新的 so 已经重新编译并拷贝到 `native` 目录。

这次改的是 `streamdevice metadata` 第二个变体的 `kv`：
1. `variant=0` 继续用 `speaker device_kv = 0xA2000001`
2. `variant=1` 现在改成用已验证基线里的 `devicepp_kv = 0xAC000002`

之前这两次调用我都错误地传了同一个 `speaker device_kv`，这会把 `DevicePP` 段直接漏掉。你现有日志里最强的线索就是：
1. 只有走到 `streamdevice metadata` 后，`PCM100 control` 才从 `ZERO` 变成 `TDM-LPAIF-RX-SECONDARY`
2. 但 `getTaggedInfo` 只从 `-22` 变成 `-19`，说明图只推进了一半
3. 而你仓库里已经验证过的 `tinyplay_ftm` 基线明确包含 `devicepp_kv=0xAC000002`

所以下一轮不用贴全量日志，只看这几行就够：
1. `set_agm_streamdevice_metadata 成功`
2. `after streamdevice metadata[0]`
3. `after streamdevice metadata[1]`
4. `after helper connect`
5. `after force connect`
6. `agm_mixer_get_miid`

重点看 `variant=1 kv=...` 之后，`getTaggedInfo` 还会不会继续是 `-19`，以及 `connect` 有没有变化。

Made changes.


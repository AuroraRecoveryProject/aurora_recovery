GitHub Copilot: 这轮日志已经把一个很硬的事实打出来了：`PCM100 control` 在 mode=1 最终能被切到 `TDM-LPAIF-RX-SECONDARY`，但 `PCM100 connect` 一直卡在 `ZERO`。我先把这层直接补成手工枚举切换，不再只信 helper。

Generating patch (50 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
我把 `PCM100 connect` 的手工枚举切换补进去了。现在直接编译覆盖，这一轮最关键是看 `PCM100 connect current` 会不会从 `ZERO` 变成 `TDM-LPAIF-RX-SECONDARY`。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c), 28 problems found

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery' && ./video_player/build_so.sh && cp video_player/libvideo_player.so aurora_recovery/native/libvideo_player.so && shasum -a 256 video_player/libvideo_player.so aurora_recovery/native/libvideo_player.so

我已经把这一步补上并重新部署了。

这次做的不是再猜 `miid`，而是直接强制把：

- `PCM100 control`
- `PCM100 connect`

都设成 `TDM-LPAIF-RX-SECONDARY`

因为你上一轮日志已经证明了一个关键点：

- `PCM100 control` 在 mode=1 最终能到 `TDM-LPAIF-RX-SECONDARY`
- 但 `PCM100 connect` 一直停在 `ZERO`

这说明 helper 至少没有把真正的 connect 枚举状态落下去，所以我这次直接手动补了。

新的 so 已经覆盖到部署目录，当前 SHA-256 是：

`3babf3de7aa8b46e76b5da226a73a7475baf49a9541cb95d7d0586bb7e13a97d`

下一轮你只需要重点看这几行有没有变化：

1. `PCM100 set enum: PCM100 control=TDM-LPAIF-RX-SECONDARY rc=...`
2. `PCM100 set enum: PCM100 connect=TDM-LPAIF-RX-SECONDARY rc=...`
3. 后面重新打印的：
   - `PCM100 enum: PCM100 control current=...`
   - `PCM100 enum: PCM100 connect current=...`
4. `agm_mixer_get_miid` 还会不会继续是 `-19`
5. `AGM PCM open` 是否还会是 `-19`

这轮非常关键，因为如果 `PCM100 connect` 终于不再是 `ZERO`，但 `pcm_open` 仍然 `-19`，那我下一步就会把注意力从 FE/BE connect 转到 `getTaggedInfo` / payload 本身，而不再在 connect 这层打转。

Made changes.

User: [INFO][HandleMinuitwrpEvents(701)] MINUITWRP -> OnTouchUp
[INFO][HandleMinuitwrpEvents(701)] MINUITWRP -> OnTouchUp
[swscaler @ 0xb4000074d5964150] No accelerated colorspace conversion found from yuv420p to rgba.
[VideoPlayer] 音频提取完成: /tmp/flutter/vp_audio_1166381216.wav bytes=14123608 ready=1
flutter: [VideoPlayer] 打开成功: 1280x720, 时长: 73560ms, 帧率: 30.0fps
[VideoPlayer] start_audio_playback: wav=/tmp/flutter/vp_audio_1166381216.wav start_ms=0
[VideoPlayer] 音频线程启动 path=/tmp/flutter/vp_audio_1166381216.wav
[VideoPlayer] wav 信息: rate=48000 ch=2 bits=16 data=14123608
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] PCM100 控件: PCM100 control type=ENUM values=1
[VideoPlayer] PCM100 enum: PCM100 control current=0 name=ZERO
[VideoPlayer] PCM100 enum option: PCM100 control[0]=ZERO
[VideoPlayer] PCM100 enum option: PCM100 control[1]=CODEC_DMA-LPAIF_RXTX-RX-0
[VideoPlayer] PCM100 enum option: PCM100 control[2]=CODEC_DMA-LPAIF_RXTX-RX-1
[VideoPlayer] PCM100 enum option: PCM100 control[3]=CODEC_DMA-LPAIF_RXTX-RX-2
[VideoPlayer] PCM100 enum option: PCM100 control[4]=CODEC_DMA-LPAIF_RXTX-RX-3
[VideoPlayer] PCM100 enum option: PCM100 control[5]=CODEC_DMA-LPAIF_RXTX-RX-5
[VideoPlayer] PCM100 enum option: PCM100 control[6]=PCM_RT_PROXY-RX-1
[VideoPlayer] PCM100 enum option: PCM100 control[7]=USB_AUDIO-RX
[VideoPlayer] PCM100 enum option: PCM100 control[8]=PCM_RT_PROXY-RX-2
[VideoPlayer] PCM100 enum option: PCM100 control[9]=PCM_DUMMY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 control[10]=TDM-LPAIF-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 control[11]=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 control[12]=TDM-LPAIF_AUD-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 control[13]=TDM-LPAIF_RXTX-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 control[14]=TDM-LPAIF_VA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 control[15]=TDM-LPAIF_WSA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 control[16]=TDM-LPAIF_AUD-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 control[17]=DISPLAY_PORT-RX-0
[VideoPlayer] PCM100 enum option: PCM100 control[18]=DISPLAY_PORT-RX-1
[VideoPlayer] PCM100 enum option: PCM100 control[19]=BTFM_PROXY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 control[20]=BTFM_PROXY-RX-1
[VideoPlayer] PCM100 控件: PCM100 metadata type=BYTE values=1024
[VideoPlayer] PCM100 get_array: PCM100 metadata rc=0 first=00 00 00 00
[VideoPlayer] PCM100 控件: PCM100 getTaggedInfo type=BYTE values=1024
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo rc=-22 first=00 00 00 00
[VideoPlayer] PCM100 控件: PCM100 connect type=ENUM values=1
[VideoPlayer] PCM100 enum: PCM100 connect current=0 name=ZERO
[VideoPlayer] PCM100 enum option: PCM100 connect[0]=ZERO
[VideoPlayer] PCM100 enum option: PCM100 connect[1]=CODEC_DMA-LPAIF_RXTX-RX-0
[VideoPlayer] PCM100 enum option: PCM100 connect[2]=CODEC_DMA-LPAIF_RXTX-RX-1
[VideoPlayer] PCM100 enum option: PCM100 connect[3]=CODEC_DMA-LPAIF_RXTX-RX-2
[VideoPlayer] PCM100 enum option: PCM100 connect[4]=CODEC_DMA-LPAIF_RXTX-RX-3
[VideoPlayer] PCM100 enum option: PCM100 connect[5]=CODEC_DMA-LPAIF_RXTX-RX-5
[VideoPlayer] PCM100 enum option: PCM100 connect[6]=PCM_RT_PROXY-RX-1
[VideoPlayer] PCM100 enum option: PCM100 connect[7]=USB_AUDIO-RX
[VideoPlayer] PCM100 enum option: PCM100 connect[8]=PCM_RT_PROXY-RX-2
[VideoPlayer] PCM100 enum option: PCM100 connect[9]=PCM_DUMMY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 connect[10]=TDM-LPAIF-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 connect[11]=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 connect[12]=TDM-LPAIF_AUD-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 connect[13]=TDM-LPAIF_RXTX-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 connect[14]=TDM-LPAIF_VA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 connect[15]=TDM-LPAIF_WSA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 connect[16]=TDM-LPAIF_AUD-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 connect[17]=DISPLAY_PORT-RX-0
[VideoPlayer] PCM100 enum option: PCM100 connect[18]=DISPLAY_PORT-RX-1
[VideoPlayer] PCM100 enum option: PCM100 connect[19]=BTFM_PROXY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 connect[20]=BTFM_PROXY-RX-1
[VideoPlayer] PCM100 set enum: PCM100 control=TDM-LPAIF-RX-SECONDARY rc=0
[VideoPlayer] PCM100 set enum: PCM100 connect=TDM-LPAIF-RX-SECONDARY rc=0
[VideoPlayer] PCM100 控件: PCM100 control type=ENUM values=1
[VideoPlayer] PCM100 enum: PCM100 control current=11 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 control[0]=ZERO
[VideoPlayer] PCM100 enum option: PCM100 control[1]=CODEC_DMA-LPAIF_RXTX-RX-0
[VideoPlayer] PCM100 enum option: PCM100 control[2]=CODEC_DMA-LPAIF_RXTX-RX-1
[VideoPlayer] PCM100 enum option: PCM100 control[3]=CODEC_DMA-LPAIF_RXTX-RX-2
[VideoPlayer] PCM100 enum option: PCM100 control[4]=CODEC_DMA-LPAIF_RXTX-RX-3
[VideoPlayer] PCM100 enum option: PCM100 control[5]=CODEC_DMA-LPAIF_RXTX-RX-5
[VideoPlayer] PCM100 enum option: PCM100 control[6]=PCM_RT_PROXY-RX-1
[VideoPlayer] PCM100 enum option: PCM100 control[7]=USB_AUDIO-RX
[VideoPlayer] PCM100 enum option: PCM100 control[8]=PCM_RT_PROXY-RX-2
[VideoPlayer] PCM100 enum option: PCM100 control[9]=PCM_DUMMY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 control[10]=TDM-LPAIF-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 control[11]=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 control[12]=TDM-LPAIF_AUD-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 control[13]=TDM-LPAIF_RXTX-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 control[14]=TDM-LPAIF_VA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 control[15]=TDM-LPAIF_WSA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 control[16]=TDM-LPAIF_AUD-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 control[17]=DISPLAY_PORT-RX-0
[VideoPlayer] PCM100 enum option: PCM100 control[18]=DISPLAY_PORT-RX-1
[VideoPlayer] PCM100 enum option: PCM100 control[19]=BTFM_PROXY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 control[20]=BTFM_PROXY-RX-1
[VideoPlayer] PCM100 控件: PCM100 metadata type=BYTE values=1024
[VideoPlayer] PCM100 get_array: PCM100 metadata rc=0 first=00 00 00 00
[VideoPlayer] PCM100 控件: PCM100 getTaggedInfo type=BYTE values=1024
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo rc=-19 first=00 00 00 00
[VideoPlayer] PCM100 控件: PCM100 connect type=ENUM values=1
[VideoPlayer] PCM100 enum: PCM100 connect current=0 name=ZERO
[VideoPlayer] PCM100 enum option: PCM100 connect[0]=ZERO
[VideoPlayer] PCM100 enum option: PCM100 connect[1]=CODEC_DMA-LPAIF_RXTX-RX-0
[VideoPlayer] PCM100 enum option: PCM100 connect[2]=CODEC_DMA-LPAIF_RXTX-RX-1
[VideoPlayer] PCM100 enum option: PCM100 connect[3]=CODEC_DMA-LPAIF_RXTX-RX-2
[VideoPlayer] PCM100 enum option: PCM100 connect[4]=CODEC_DMA-LPAIF_RXTX-RX-3
[VideoPlayer] PCM100 enum option: PCM100 connect[5]=CODEC_DMA-LPAIF_RXTX-RX-5
[VideoPlayer] PCM100 enum option: PCM100 connect[6]=PCM_RT_PROXY-RX-1
[VideoPlayer] PCM100 enum option: PCM100 connect[7]=USB_AUDIO-RX
[VideoPlayer] PCM100 enum option: PCM100 connect[8]=PCM_RT_PROXY-RX-2
[VideoPlayer] PCM100 enum option: PCM100 connect[9]=PCM_DUMMY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 connect[10]=TDM-LPAIF-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 connect[11]=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 connect[12]=TDM-LPAIF_AUD-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 connect[13]=TDM-LPAIF_RXTX-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 connect[14]=TDM-LPAIF_VA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 connect[15]=TDM-LPAIF_WSA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 connect[16]=TDM-LPAIF_AUD-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 connect[17]=DISPLAY_PORT-RX-0
[VideoPlayer] PCM100 enum option: PCM100 connect[18]=DISPLAY_PORT-RX-1
[VideoPlayer] PCM100 enum option: PCM100 connect[19]=BTFM_PROXY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 connect[20]=BTFM_PROXY-RX-1
[VideoPlayer] agm_mixer_get_miid 失败: mode=0 rc=-19 miid=0，继续尝试无 MFC 直开 PCM
[VideoPlayer] AGM mixer 路径准备完成: mode=0 device=100 intf=TDM-LPAIF-RX-SECONDARY backend=48000/8/32 device_kv=0 miid=0 have_miid=0
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] AGM PCM open 失败: mode=0 cfg=source err=cannot open device 100 for card 100: Unknown error -19
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] AGM PCM open 失败: mode=0 cfg=backend err=cannot open device 100 for card 100: Unknown error -19
[VideoPlayer] PCM100 控件: PCM100 control type=ENUM values=1
[VideoPlayer] PCM100 enum: PCM100 control current=0 name=ZERO
[VideoPlayer] PCM100 enum option: PCM100 control[0]=ZERO
[VideoPlayer] PCM100 enum option: PCM100 control[1]=CODEC_DMA-LPAIF_RXTX-RX-0
[VideoPlayer] PCM100 enum option: PCM100 control[2]=CODEC_DMA-LPAIF_RXTX-RX-1
[VideoPlayer] PCM100 enum option: PCM100 control[3]=CODEC_DMA-LPAIF_RXTX-RX-2
[VideoPlayer] PCM100 enum option: PCM100 control[4]=CODEC_DMA-LPAIF_RXTX-RX-3
[VideoPlayer] PCM100 enum option: PCM100 control[5]=CODEC_DMA-LPAIF_RXTX-RX-5
[VideoPlayer] PCM100 enum option: PCM100 control[6]=PCM_RT_PROXY-RX-1
[VideoPlayer] PCM100 enum option: PCM100 control[7]=USB_AUDIO-RX
[VideoPlayer] PCM100 enum option: PCM100 control[8]=PCM_RT_PROXY-RX-2
[VideoPlayer] PCM100 enum option: PCM100 control[9]=PCM_DUMMY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 control[10]=TDM-LPAIF-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 control[11]=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 control[12]=TDM-LPAIF_AUD-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 control[13]=TDM-LPAIF_RXTX-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 control[14]=TDM-LPAIF_VA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 control[15]=TDM-LPAIF_WSA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 control[16]=TDM-LPAIF_AUD-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 control[17]=DISPLAY_PORT-RX-0
[VideoPlayer] PCM100 enum option: PCM100 control[18]=DISPLAY_PORT-RX-1
[VideoPlayer] PCM100 enum option: PCM100 control[19]=BTFM_PROXY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 control[20]=BTFM_PROXY-RX-1
[VideoPlayer] PCM100 控件: PCM100 metadata type=BYTE values=1024
[VideoPlayer] PCM100 get_array: PCM100 metadata rc=0 first=00 00 00 00
[VideoPlayer] PCM100 控件: PCM100 getTaggedInfo type=BYTE values=1024
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo rc=-22 first=00 00 00 00
[VideoPlayer] PCM100 控件: PCM100 connect type=ENUM values=1
[VideoPlayer] PCM100 enum: PCM100 connect current=0 name=ZERO
[VideoPlayer] PCM100 enum option: PCM100 connect[0]=ZERO
[VideoPlayer] PCM100 enum option: PCM100 connect[1]=CODEC_DMA-LPAIF_RXTX-RX-0
[VideoPlayer] PCM100 enum option: PCM100 connect[2]=CODEC_DMA-LPAIF_RXTX-RX-1
[VideoPlayer] PCM100 enum option: PCM100 connect[3]=CODEC_DMA-LPAIF_RXTX-RX-2
[VideoPlayer] PCM100 enum option: PCM100 connect[4]=CODEC_DMA-LPAIF_RXTX-RX-3
[VideoPlayer] PCM100 enum option: PCM100 connect[5]=CODEC_DMA-LPAIF_RXTX-RX-5
[VideoPlayer] PCM100 enum option: PCM100 connect[6]=PCM_RT_PROXY-RX-1
[VideoPlayer] PCM100 enum option: PCM100 connect[7]=USB_AUDIO-RX
[VideoPlayer] PCM100 enum option: PCM100 connect[8]=PCM_RT_PROXY-RX-2
[VideoPlayer] PCM100 enum option: PCM100 connect[9]=PCM_DUMMY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 connect[10]=TDM-LPAIF-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 connect[11]=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 connect[12]=TDM-LPAIF_AUD-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 connect[13]=TDM-LPAIF_RXTX-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 connect[14]=TDM-LPAIF_VA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 connect[15]=TDM-LPAIF_WSA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 connect[16]=TDM-LPAIF_AUD-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 connect[17]=DISPLAY_PORT-RX-0
[VideoPlayer] PCM100 enum option: PCM100 connect[18]=DISPLAY_PORT-RX-1
[VideoPlayer] PCM100 enum option: PCM100 connect[19]=BTFM_PROXY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 connect[20]=BTFM_PROXY-RX-1
[VideoPlayer] PCM100 set enum: PCM100 control=TDM-LPAIF-RX-SECONDARY rc=0
[VideoPlayer] PCM100 set enum: PCM100 connect=TDM-LPAIF-RX-SECONDARY rc=0
[VideoPlayer] PCM100 控件: PCM100 control type=ENUM values=1
[VideoPlayer] PCM100 enum: PCM100 control current=11 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 control[0]=ZERO
[VideoPlayer] PCM100 enum option: PCM100 control[1]=CODEC_DMA-LPAIF_RXTX-RX-0
[VideoPlayer] PCM100 enum option: PCM100 control[2]=CODEC_DMA-LPAIF_RXTX-RX-1
[VideoPlayer] PCM100 enum option: PCM100 control[3]=CODEC_DMA-LPAIF_RXTX-RX-2
[VideoPlayer] PCM100 enum option: PCM100 control[4]=CODEC_DMA-LPAIF_RXTX-RX-3
[VideoPlayer] PCM100 enum option: PCM100 control[5]=CODEC_DMA-LPAIF_RXTX-RX-5
[VideoPlayer] PCM100 enum option: PCM100 control[6]=PCM_RT_PROXY-RX-1
[VideoPlayer] PCM100 enum option: PCM100 control[7]=USB_AUDIO-RX
[VideoPlayer] PCM100 enum option: PCM100 control[8]=PCM_RT_PROXY-RX-2
[VideoPlayer] PCM100 enum option: PCM100 control[9]=PCM_DUMMY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 control[10]=TDM-LPAIF-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 control[11]=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 control[12]=TDM-LPAIF_AUD-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 control[13]=TDM-LPAIF_RXTX-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 control[14]=TDM-LPAIF_VA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 control[15]=TDM-LPAIF_WSA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 control[16]=TDM-LPAIF_AUD-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 control[17]=DISPLAY_PORT-RX-0
[VideoPlayer] PCM100 enum option: PCM100 control[18]=DISPLAY_PORT-RX-1
[VideoPlayer] PCM100 enum option: PCM100 control[19]=BTFM_PROXY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 control[20]=BTFM_PROXY-RX-1
[VideoPlayer] PCM100 控件: PCM100 metadata type=BYTE values=1024
[VideoPlayer] PCM100 get_array: PCM100 metadata rc=0 first=00 00 00 00
[VideoPlayer] PCM100 控件: PCM100 getTaggedInfo type=BYTE values=1024
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo rc=-19 first=00 00 00 00
[VideoPlayer] PCM100 控件: PCM100 connect type=ENUM values=1
[VideoPlayer] PCM100 enum: PCM100 connect current=0 name=ZERO
[VideoPlayer] PCM100 enum option: PCM100 connect[0]=ZERO
[VideoPlayer] PCM100 enum option: PCM100 connect[1]=CODEC_DMA-LPAIF_RXTX-RX-0
[VideoPlayer] PCM100 enum option: PCM100 connect[2]=CODEC_DMA-LPAIF_RXTX-RX-1
[VideoPlayer] PCM100 enum option: PCM100 connect[3]=CODEC_DMA-LPAIF_RXTX-RX-2
[VideoPlayer] PCM100 enum option: PCM100 connect[4]=CODEC_DMA-LPAIF_RXTX-RX-3
[VideoPlayer] PCM100 enum option: PCM100 connect[5]=CODEC_DMA-LPAIF_RXTX-RX-5
[VideoPlayer] PCM100 enum option: PCM100 connect[6]=PCM_RT_PROXY-RX-1
[VideoPlayer] PCM100 enum option: PCM100 connect[7]=USB_AUDIO-RX
[VideoPlayer] PCM100 enum option: PCM100 connect[8]=PCM_RT_PROXY-RX-2
[VideoPlayer] PCM100 enum option: PCM100 connect[9]=PCM_DUMMY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 connect[10]=TDM-LPAIF-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 connect[11]=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 connect[12]=TDM-LPAIF_AUD-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 connect[13]=TDM-LPAIF_RXTX-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 connect[14]=TDM-LPAIF_VA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 connect[15]=TDM-LPAIF_WSA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 connect[16]=TDM-LPAIF_AUD-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 connect[17]=DISPLAY_PORT-RX-0
[VideoPlayer] PCM100 enum option: PCM100 connect[18]=DISPLAY_PORT-RX-1
[VideoPlayer] PCM100 enum option: PCM100 connect[19]=BTFM_PROXY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 connect[20]=BTFM_PROXY-RX-1
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
[VideoPlayer] 打开 PCM 成功: card=0 device=16 rate=48000 ch=2 bits=16
[VideoPlayer] 音频线程进入播放循环 backend=1
[VideoPlayer] pcm_write 失败: cannot write initial data: Invalid argument
[VideoPlayer] 音频线程退出: 写流失败 backend=1
[VideoPlayer] 音频线程退出 stop_requested=0
Application finished.

Exited.


GitHub Copilot: 我继续把 `PCM100 connect` 这层做硬一点，不再只看 `rc=0`。下一版会在设枚举后立刻 `update + 回读`，并且把手工 `control/connect` 前移到 helper `connect` 之前再补一次，确认它不是被时序吃掉了。

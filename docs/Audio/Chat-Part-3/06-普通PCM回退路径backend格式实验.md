

GitHub Copilot: 这份日志本身已经给出结论了：你跑到的不是我刚插桩后的 so，因为新增的 `after audio intf metadata`、`after helper connect`、`PCM100 setParam`、`COMPRESS100 *` 一条都没有出现；我先核对源码和当前二进制里的字符串，确认是哪一层没更新。

Searched for regex `after audio intf metadata|after helper connect|PCM100 setParam|COMPRESS100 control` (`**/video_player/video_player_ffi.c`), 5 results

Ran terminal command:  strings "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/aurora_recovery/native/libvideo_player.so" | rg -n "after audio intf metadata|after helper connect|PCM100 setParam|COMPRESS100 control"

Ran terminal command:  strings "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/libvideo_player.so" | rg -n "after audio intf metadata|after helper connect|PCM100 setParam|COMPRESS100 control"

Ran terminal command:  ls -l "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/libvideo_player.so" "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/aurora_recovery/native/libvideo_player.so"

源码已经比二进制新了，两个 so 里都只有旧字符串，说明你这次运行的确实是旧构建；我现在直接查这个小库的构建入口，目标是只重建 `libvideo_player.so` 并覆盖到固定部署路径。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player)

Searched for regex `libvideo_player.so|clang|gcc|ffmpeg|tinyalsa|video_player_ffi.c` (`**/video_player/*`), 110 results

User: 你需要把编译后的so拷贝到native文件夹

GitHub Copilot: 先把小库按现有脚本重建，再把产物覆盖到 native，这样你下一次运行拿到的就是带新插桩的 so。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/build_so.sh)

Ran terminal command:  cd "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player" && ./build_so.sh

编译已经完成，接下来只做一件事：把新产物覆盖到你指定的 `native` 目录，并顺手核对新字符串已经进了 so。

Ran terminal command:  cp "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/libvideo_player.so" "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/aurora_recovery/native/libvideo_player.so"

Ran terminal command:  shasum -a 256 "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/libvideo_player.so" "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/aurora_recovery/native/libvideo_player.so"

Ran terminal command:  strings "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/aurora_recovery/native/libvideo_player.so" | rg -n "after audio intf metadata|after helper connect|PCM100 setParam|COMPRESS100 control"

新的 so 已经编译并拷贝到 native 了。

校验结果也已经确认：
- 两个文件 SHA-256 一致，都是 `4bd553143ff0d55fd8c04c39ee75f177650bd332db422e783410f798d4015e81`
- `native` 目录里的 so 已经包含最新插桩字符串：
  - `after audio intf metadata`
  - `after helper connect`
  - `PCM100 setParam`
  - `COMPRESS100 control`

你现在直接再跑一次播放器即可，这次日志里应该会出现这几段新标记。

User: 日志太多


[INFO][HandleMinuitwrpEvents(701)] MINUITWRP -> OnTouchUp
[swscaler @ 0xb400006e5794c130] No accelerated colorspace conversion found from yuv420p to rgba.
flutter: [VideoPlayer] 打开成功: 1280x720, 时长: 73560ms, 帧率: 30.0fps
[VideoPlayer] 音频提取完成: /tmp/flutter/vp_audio_3347499056.wav bytes=14123608 ready=1
[VideoPlayer] start_audio_playback: wav=/tmp/flutter/vp_audio_3347499056.wav start_ms=0
[VideoPlayer] 音频线程启动 path=/tmp/flutter/vp_audio_3347499056.wav
[VideoPlayer] wav 信息: rate=48000 ch=2 bits=16 data=14123608
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] PCM100 控件快照: after device media config
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
[VideoPlayer] PCM100 get_array: PCM100 metadata rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata bytes=1024 preview=32 hex=00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
[VideoPlayer] PCM100 words: PCM100 metadata w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件: PCM100 setParam type=BYTE values=1048576
[VideoPlayer] PCM100 get_array: PCM100 setParam rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam bytes=1048576 preview=32 hex=00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
[VideoPlayer] PCM100 words: PCM100 setParam w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件: PCM100 setParamTag type=BYTE values=262144
[VideoPlayer] PCM100 get_array: PCM100 setParamTag rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag bytes=262144 preview=32 hex=00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
[VideoPlayer] PCM100 words: PCM100 setParamTag w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件: PCM100 getTaggedInfo type=BYTE values=1024
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo rc=-22 bytes=256/1024 first=00 00 00 00
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
[VideoPlayer] PCM100 控件: PCM100 disconnect type=ENUM values=1
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0 name=ZERO
[VideoPlayer] PCM100 enum option: PCM100 disconnect[0]=ZERO
[VideoPlayer] PCM100 enum option: PCM100 disconnect[1]=CODEC_DMA-LPAIF_RXTX-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[2]=CODEC_DMA-LPAIF_RXTX-RX-1
[VideoPlayer] PCM100 enum option: PCM100 disconnect[3]=CODEC_DMA-LPAIF_RXTX-RX-2
[VideoPlayer] PCM100 enum option: PCM100 disconnect[4]=CODEC_DMA-LPAIF_RXTX-RX-3
[VideoPlayer] PCM100 enum option: PCM100 disconnect[5]=CODEC_DMA-LPAIF_RXTX-RX-5
[VideoPlayer] PCM100 enum option: PCM100 disconnect[6]=PCM_RT_PROXY-RX-1
[VideoPlayer] PCM100 enum option: PCM100 disconnect[7]=USB_AUDIO-RX
[VideoPlayer] PCM100 enum option: PCM100 disconnect[8]=PCM_RT_PROXY-RX-2
[VideoPlayer] PCM100 enum option: PCM100 disconnect[9]=PCM_DUMMY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[10]=TDM-LPAIF-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[11]=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[12]=TDM-LPAIF_AUD-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[13]=TDM-LPAIF_RXTX-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[14]=TDM-LPAIF_VA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[15]=TDM-LPAIF_WSA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[16]=TDM-LPAIF_AUD-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[17]=DISPLAY_PORT-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[18]=DISPLAY_PORT-RX-1
[VideoPlayer] PCM100 enum option: PCM100 disconnect[19]=BTFM_PROXY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[20]=BTFM_PROXY-RX-1
[VideoPlayer] PCM100 控件不存在: COMPRESS100 control
[VideoPlayer] PCM100 控件不存在: COMPRESS100 metadata
[VideoPlayer] PCM100 控件不存在: COMPRESS100 setParam
[VideoPlayer] PCM100 控件不存在: COMPRESS100 setParamTag
[VideoPlayer] PCM100 控件不存在: COMPRESS100 getTaggedInfo
[VideoPlayer] PCM100 控件不存在: COMPRESS100 connect
[VideoPlayer] PCM100 控件不存在: COMPRESS100 disconnect
[VideoPlayer] PCM100 控件快照: after audio intf metadata
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
[VideoPlayer] PCM100 get_array: PCM100 metadata rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata bytes=1024 preview=32 hex=00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
[VideoPlayer] PCM100 words: PCM100 metadata w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件: PCM100 setParam type=BYTE values=1048576
[VideoPlayer] PCM100 get_array: PCM100 setParam rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam bytes=1048576 preview=32 hex=00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
[VideoPlayer] PCM100 words: PCM100 setParam w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件: PCM100 setParamTag type=BYTE values=262144
[VideoPlayer] PCM100 get_array: PCM100 setParamTag rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag bytes=262144 preview=32 hex=00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
[VideoPlayer] PCM100 words: PCM100 setParamTag w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件: PCM100 getTaggedInfo type=BYTE values=1024
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo rc=-22 bytes=256/1024 first=00 00 00 00
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
[VideoPlayer] PCM100 控件: PCM100 disconnect type=ENUM values=1
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0 name=ZERO
[VideoPlayer] PCM100 enum option: PCM100 disconnect[0]=ZERO
[VideoPlayer] PCM100 enum option: PCM100 disconnect[1]=CODEC_DMA-LPAIF_RXTX-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[2]=CODEC_DMA-LPAIF_RXTX-RX-1
[VideoPlayer] PCM100 enum option: PCM100 disconnect[3]=CODEC_DMA-LPAIF_RXTX-RX-2
[VideoPlayer] PCM100 enum option: PCM100 disconnect[4]=CODEC_DMA-LPAIF_RXTX-RX-3
[VideoPlayer] PCM100 enum option: PCM100 disconnect[5]=CODEC_DMA-LPAIF_RXTX-RX-5
[VideoPlayer] PCM100 enum option: PCM100 disconnect[6]=PCM_RT_PROXY-RX-1
[VideoPlayer] PCM100 enum option: PCM100 disconnect[7]=USB_AUDIO-RX
[VideoPlayer] PCM100 enum option: PCM100 disconnect[8]=PCM_RT_PROXY-RX-2
[VideoPlayer] PCM100 enum option: PCM100 disconnect[9]=PCM_DUMMY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[10]=TDM-LPAIF-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[11]=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[12]=TDM-LPAIF_AUD-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[13]=TDM-LPAIF_RXTX-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[14]=TDM-LPAIF_VA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[15]=TDM-LPAIF_WSA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[16]=TDM-LPAIF_AUD-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[17]=DISPLAY_PORT-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[18]=DISPLAY_PORT-RX-1
[VideoPlayer] PCM100 enum option: PCM100 disconnect[19]=BTFM_PROXY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[20]=BTFM_PROXY-RX-1
[VideoPlayer] PCM100 控件不存在: COMPRESS100 control
[VideoPlayer] PCM100 控件不存在: COMPRESS100 metadata
[VideoPlayer] PCM100 控件不存在: COMPRESS100 setParam
[VideoPlayer] PCM100 控件不存在: COMPRESS100 setParamTag
[VideoPlayer] PCM100 控件不存在: COMPRESS100 getTaggedInfo
[VideoPlayer] PCM100 控件不存在: COMPRESS100 connect
[VideoPlayer] PCM100 控件不存在: COMPRESS100 disconnect
[VideoPlayer] PCM100 控件快照: after stream metadata kv
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
[VideoPlayer] PCM100 get_array: PCM100 metadata rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata bytes=1024 preview=32 hex=00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
[VideoPlayer] PCM100 words: PCM100 metadata w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件: PCM100 setParam type=BYTE values=1048576
[VideoPlayer] PCM100 get_array: PCM100 setParam rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam bytes=1048576 preview=32 hex=00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
[VideoPlayer] PCM100 words: PCM100 setParam w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件: PCM100 setParamTag type=BYTE values=262144
[VideoPlayer] PCM100 get_array: PCM100 setParamTag rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag bytes=262144 preview=32 hex=00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
[VideoPlayer] PCM100 words: PCM100 setParamTag w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件: PCM100 getTaggedInfo type=BYTE values=1024
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo rc=-22 bytes=256/1024 first=00 00 00 00
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
[VideoPlayer] PCM100 控件: PCM100 disconnect type=ENUM values=1
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0 name=ZERO
[VideoPlayer] PCM100 enum option: PCM100 disconnect[0]=ZERO
[VideoPlayer] PCM100 enum option: PCM100 disconnect[1]=CODEC_DMA-LPAIF_RXTX-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[2]=CODEC_DMA-LPAIF_RXTX-RX-1
[VideoPlayer] PCM100 enum option: PCM100 disconnect[3]=CODEC_DMA-LPAIF_RXTX-RX-2
[VideoPlayer] PCM100 enum option: PCM100 disconnect[4]=CODEC_DMA-LPAIF_RXTX-RX-3
[VideoPlayer] PCM100 enum option: PCM100 disconnect[5]=CODEC_DMA-LPAIF_RXTX-RX-5
[VideoPlayer] PCM100 enum option: PCM100 disconnect[6]=PCM_RT_PROXY-RX-1
[VideoPlayer] PCM100 enum option: PCM100 disconnect[7]=USB_AUDIO-RX
[VideoPlayer] PCM100 enum option: PCM100 disconnect[8]=PCM_RT_PROXY-RX-2
[VideoPlayer] PCM100 enum option: PCM100 disconnect[9]=PCM_DUMMY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[10]=TDM-LPAIF-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[11]=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[12]=TDM-LPAIF_AUD-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[13]=TDM-LPAIF_RXTX-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[14]=TDM-LPAIF_VA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[15]=TDM-LPAIF_WSA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[16]=TDM-LPAIF_AUD-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[17]=DISPLAY_PORT-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[18]=DISPLAY_PORT-RX-1
[VideoPlayer] PCM100 enum option: PCM100 disconnect[19]=BTFM_PROXY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[20]=BTFM_PROXY-RX-1
[VideoPlayer] PCM100 控件不存在: COMPRESS100 control
[VideoPlayer] PCM100 控件不存在: COMPRESS100 metadata
[VideoPlayer] PCM100 控件不存在: COMPRESS100 setParam
[VideoPlayer] PCM100 控件不存在: COMPRESS100 setParamTag
[VideoPlayer] PCM100 控件不存在: COMPRESS100 getTaggedInfo
[VideoPlayer] PCM100 控件不存在: COMPRESS100 connect
[VideoPlayer] PCM100 控件不存在: COMPRESS100 disconnect
[VideoPlayer] PCM100 控件快照: after stream metadata instance
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
[VideoPlayer] PCM100 get_array: PCM100 metadata rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata bytes=1024 preview=32 hex=00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
[VideoPlayer] PCM100 words: PCM100 metadata w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件: PCM100 setParam type=BYTE values=1048576
[VideoPlayer] PCM100 get_array: PCM100 setParam rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam bytes=1048576 preview=32 hex=00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
[VideoPlayer] PCM100 words: PCM100 setParam w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件: PCM100 setParamTag type=BYTE values=262144
[VideoPlayer] PCM100 get_array: PCM100 setParamTag rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag bytes=262144 preview=32 hex=00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
[VideoPlayer] PCM100 words: PCM100 setParamTag w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件: PCM100 getTaggedInfo type=BYTE values=1024
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo rc=-22 bytes=256/1024 first=00 00 00 00
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
[VideoPlayer] PCM100 控件: PCM100 disconnect type=ENUM values=1
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0 name=ZERO
[VideoPlayer] PCM100 enum option: PCM100 disconnect[0]=ZERO
[VideoPlayer] PCM100 enum option: PCM100 disconnect[1]=CODEC_DMA-LPAIF_RXTX-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[2]=CODEC_DMA-LPAIF_RXTX-RX-1
[VideoPlayer] PCM100 enum option: PCM100 disconnect[3]=CODEC_DMA-LPAIF_RXTX-RX-2
[VideoPlayer] PCM100 enum option: PCM100 disconnect[4]=CODEC_DMA-LPAIF_RXTX-RX-3
[VideoPlayer] PCM100 enum option: PCM100 disconnect[5]=CODEC_DMA-LPAIF_RXTX-RX-5
[VideoPlayer] PCM100 enum option: PCM100 disconnect[6]=PCM_RT_PROXY-RX-1
[VideoPlayer] PCM100 enum option: PCM100 disconnect[7]=USB_AUDIO-RX
[VideoPlayer] PCM100 enum option: PCM100 disconnect[8]=PCM_RT_PROXY-RX-2
[VideoPlayer] PCM100 enum option: PCM100 disconnect[9]=PCM_DUMMY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[10]=TDM-LPAIF-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[11]=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[12]=TDM-LPAIF_AUD-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[13]=TDM-LPAIF_RXTX-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[14]=TDM-LPAIF_VA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[15]=TDM-LPAIF_WSA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[16]=TDM-LPAIF_AUD-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[17]=DISPLAY_PORT-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[18]=DISPLAY_PORT-RX-1
[VideoPlayer] PCM100 enum option: PCM100 disconnect[19]=BTFM_PROXY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[20]=BTFM_PROXY-RX-1
[VideoPlayer] PCM100 控件不存在: COMPRESS100 control
[VideoPlayer] PCM100 控件不存在: COMPRESS100 metadata
[VideoPlayer] PCM100 控件不存在: COMPRESS100 setParam
[VideoPlayer] PCM100 控件不存在: COMPRESS100 setParamTag
[VideoPlayer] PCM100 控件不存在: COMPRESS100 getTaggedInfo
[VideoPlayer] PCM100 控件不存在: COMPRESS100 connect
[VideoPlayer] PCM100 控件不存在: COMPRESS100 disconnect
[VideoPlayer] PCM100 控件快照: after helper connect
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
[VideoPlayer] PCM100 get_array: PCM100 metadata rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata bytes=1024 preview=32 hex=00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
[VideoPlayer] PCM100 words: PCM100 metadata w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件: PCM100 setParam type=BYTE values=1048576
[VideoPlayer] PCM100 get_array: PCM100 setParam rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam bytes=1048576 preview=32 hex=00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
[VideoPlayer] PCM100 words: PCM100 setParam w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件: PCM100 setParamTag type=BYTE values=262144
[VideoPlayer] PCM100 get_array: PCM100 setParamTag rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag bytes=262144 preview=32 hex=00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
[VideoPlayer] PCM100 words: PCM100 setParamTag w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件: PCM100 getTaggedInfo type=BYTE values=1024
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo rc=-22 bytes=256/1024 first=00 00 00 00
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
[VideoPlayer] PCM100 控件: PCM100 disconnect type=ENUM values=1
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0 name=ZERO
[VideoPlayer] PCM100 enum option: PCM100 disconnect[0]=ZERO
[VideoPlayer] PCM100 enum option: PCM100 disconnect[1]=CODEC_DMA-LPAIF_RXTX-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[2]=CODEC_DMA-LPAIF_RXTX-RX-1
[VideoPlayer] PCM100 enum option: PCM100 disconnect[3]=CODEC_DMA-LPAIF_RXTX-RX-2
[VideoPlayer] PCM100 enum option: PCM100 disconnect[4]=CODEC_DMA-LPAIF_RXTX-RX-3
[VideoPlayer] PCM100 enum option: PCM100 disconnect[5]=CODEC_DMA-LPAIF_RXTX-RX-5
[VideoPlayer] PCM100 enum option: PCM100 disconnect[6]=PCM_RT_PROXY-RX-1
[VideoPlayer] PCM100 enum option: PCM100 disconnect[7]=USB_AUDIO-RX
[VideoPlayer] PCM100 enum option: PCM100 disconnect[8]=PCM_RT_PROXY-RX-2
[VideoPlayer] PCM100 enum option: PCM100 disconnect[9]=PCM_DUMMY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[10]=TDM-LPAIF-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[11]=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[12]=TDM-LPAIF_AUD-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[13]=TDM-LPAIF_RXTX-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[14]=TDM-LPAIF_VA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[15]=TDM-LPAIF_WSA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[16]=TDM-LPAIF_AUD-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[17]=DISPLAY_PORT-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[18]=DISPLAY_PORT-RX-1
[VideoPlayer] PCM100 enum option: PCM100 disconnect[19]=BTFM_PROXY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[20]=BTFM_PROXY-RX-1
[VideoPlayer] PCM100 控件不存在: COMPRESS100 control
[VideoPlayer] PCM100 控件不存在: COMPRESS100 metadata
[VideoPlayer] PCM100 控件不存在: COMPRESS100 setParam
[VideoPlayer] PCM100 控件不存在: COMPRESS100 setParamTag
[VideoPlayer] PCM100 控件不存在: COMPRESS100 getTaggedInfo
[VideoPlayer] PCM100 控件不存在: COMPRESS100 connect
[VideoPlayer] PCM100 控件不存在: COMPRESS100 disconnect
[VideoPlayer] PCM100 set enum: PCM100 control=TDM-LPAIF-RX-SECONDARY rc=0
[VideoPlayer] PCM100 set enum: PCM100 connect=TDM-LPAIF-RX-SECONDARY rc=0
[VideoPlayer] PCM100 控件快照: after force connect
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
[VideoPlayer] PCM100 get_array: PCM100 metadata rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata bytes=1024 preview=32 hex=00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
[VideoPlayer] PCM100 words: PCM100 metadata w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件: PCM100 setParam type=BYTE values=1048576
[VideoPlayer] PCM100 get_array: PCM100 setParam rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam bytes=1048576 preview=32 hex=00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
[VideoPlayer] PCM100 words: PCM100 setParam w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件: PCM100 setParamTag type=BYTE values=262144
[VideoPlayer] PCM100 get_array: PCM100 setParamTag rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag bytes=262144 preview=32 hex=00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
[VideoPlayer] PCM100 words: PCM100 setParamTag w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件: PCM100 getTaggedInfo type=BYTE values=1024
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo rc=-19 bytes=256/1024 first=00 00 00 00
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
[VideoPlayer] PCM100 控件: PCM100 disconnect type=ENUM values=1
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0 name=ZERO
[VideoPlayer] PCM100 enum option: PCM100 disconnect[0]=ZERO
[VideoPlayer] PCM100 enum option: PCM100 disconnect[1]=CODEC_DMA-LPAIF_RXTX-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[2]=CODEC_DMA-LPAIF_RXTX-RX-1
[VideoPlayer] PCM100 enum option: PCM100 disconnect[3]=CODEC_DMA-LPAIF_RXTX-RX-2
[VideoPlayer] PCM100 enum option: PCM100 disconnect[4]=CODEC_DMA-LPAIF_RXTX-RX-3
[VideoPlayer] PCM100 enum option: PCM100 disconnect[5]=CODEC_DMA-LPAIF_RXTX-RX-5
[VideoPlayer] PCM100 enum option: PCM100 disconnect[6]=PCM_RT_PROXY-RX-1
[VideoPlayer] PCM100 enum option: PCM100 disconnect[7]=USB_AUDIO-RX
[VideoPlayer] PCM100 enum option: PCM100 disconnect[8]=PCM_RT_PROXY-RX-2
[VideoPlayer] PCM100 enum option: PCM100 disconnect[9]=PCM_DUMMY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[10]=TDM-LPAIF-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[11]=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[12]=TDM-LPAIF_AUD-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[13]=TDM-LPAIF_RXTX-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[14]=TDM-LPAIF_VA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[15]=TDM-LPAIF_WSA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[16]=TDM-LPAIF_AUD-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[17]=DISPLAY_PORT-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[18]=DISPLAY_PORT-RX-1
[VideoPlayer] PCM100 enum option: PCM100 disconnect[19]=BTFM_PROXY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[20]=BTFM_PROXY-RX-1
[VideoPlayer] PCM100 控件不存在: COMPRESS100 control
[VideoPlayer] PCM100 控件不存在: COMPRESS100 metadata
[VideoPlayer] PCM100 控件不存在: COMPRESS100 setParam
[VideoPlayer] PCM100 控件不存在: COMPRESS100 setParamTag
[VideoPlayer] PCM100 控件不存在: COMPRESS100 getTaggedInfo
[VideoPlayer] PCM100 控件不存在: COMPRESS100 connect
[VideoPlayer] PCM100 控件不存在: COMPRESS100 disconnect
[VideoPlayer] PCM100 控件快照: after agm_mixer_get_miid
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
[VideoPlayer] PCM100 get_array: PCM100 metadata rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata bytes=1024 preview=32 hex=00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
[VideoPlayer] PCM100 words: PCM100 metadata w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件: PCM100 setParam type=BYTE values=1048576
[VideoPlayer] PCM100 get_array: PCM100 setParam rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam bytes=1048576 preview=32 hex=00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
[VideoPlayer] PCM100 words: PCM100 setParam w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件: PCM100 setParamTag type=BYTE values=262144
[VideoPlayer] PCM100 get_array: PCM100 setParamTag rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag bytes=262144 preview=32 hex=00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
[VideoPlayer] PCM100 words: PCM100 setParamTag w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件: PCM100 getTaggedInfo type=BYTE values=1024
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo rc=-19 bytes=256/1024 first=00 00 00 00
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
[VideoPlayer] PCM100 控件: PCM100 disconnect type=ENUM values=1
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0 name=ZERO
[VideoPlayer] PCM100 enum option: PCM100 disconnect[0]=ZERO
[VideoPlayer] PCM100 enum option: PCM100 disconnect[1]=CODEC_DMA-LPAIF_RXTX-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[2]=CODEC_DMA-LPAIF_RXTX-RX-1
[VideoPlayer] PCM100 enum option: PCM100 disconnect[3]=CODEC_DMA-LPAIF_RXTX-RX-2
[VideoPlayer] PCM100 enum option: PCM100 disconnect[4]=CODEC_DMA-LPAIF_RXTX-RX-3
[VideoPlayer] PCM100 enum option: PCM100 disconnect[5]=CODEC_DMA-LPAIF_RXTX-RX-5
[VideoPlayer] PCM100 enum option: PCM100 disconnect[6]=PCM_RT_PROXY-RX-1
[VideoPlayer] PCM100 enum option: PCM100 disconnect[7]=USB_AUDIO-RX
[VideoPlayer] PCM100 enum option: PCM100 disconnect[8]=PCM_RT_PROXY-RX-2
[VideoPlayer] PCM100 enum option: PCM100 disconnect[9]=PCM_DUMMY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[10]=TDM-LPAIF-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[11]=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[12]=TDM-LPAIF_AUD-RX-SECONDARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[13]=TDM-LPAIF_RXTX-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[14]=TDM-LPAIF_VA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[15]=TDM-LPAIF_WSA-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[16]=TDM-LPAIF_AUD-RX-PRIMARY
[VideoPlayer] PCM100 enum option: PCM100 disconnect[17]=DISPLAY_PORT-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[18]=DISPLAY_PORT-RX-1
[VideoPlayer] PCM100 enum option: PCM100 disconnect[19]=BTFM_PROXY-RX-0
[VideoPlayer] PCM100 enum option: PCM100 disconnect[20]=BTFM_PROXY-RX-1
[VideoPlayer] PCM100 控件不存在: COMPRESS100 control
[VideoPlayer] PCM100 控件不存在: COMPRESS100 metadata
[VideoPlayer] PCM100 控件不存在: COMPRESS100 setParam
[VideoPlayer] PCM100 控件不存在: COMPRESS100 setParamTag
[VideoPlayer] PCM100 控件不存在: COMPRESS100 getTaggedInfo
[VideoPlayer] PCM100 控件不存在: COMPRESS100 connect
[VideoPlayer] PCM100 控件不存在: COMPRESS100 disconnect
[VideoPlayer] agm_mixer_get_miid 失败: mode=0 rc=-19 miid=0，继续尝试无 MFC 直开 PCM
[VideoPlayer] AGM mixer 路径准备完成: mode=0 device=100 intf=TDM-LPAIF-RX-SECONDARY backend=48000/8/32 device_kv=0 miid=0 have_miid=0
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] AGM PCM open 失败: mode=0 cfg=source err=cannot open device 100 for card 100: Unknown error -19
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] AGM PCM open 失败: mode=0 cfg=backend err=cannot open device 100 for card 100: Unknown error -19
[VideoPlayer] PCM100 控件快照: after device media config
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
[VideoPlayer] PCM100 get_array: PCM100 metadata rc=0 bytes=256/1024 fir

GitHub Copilot: 我先把日志压缩到可用级别，只保留当前值、关键返回码和少量摘要，这样下次你贴一屏就够看出问题点。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#585-585), lines 585 to 705

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#905-905), lines 905 to 1005

我直接收敛日志噪音：去掉每个枚举选项的全量打印，把 BYTE 控件压成单行摘要，并把 `COMPRESS100` 缺失合并成一条。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#533-533), lines 533 to 585

Generating patch (139 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)

日志压缩已经改完，我先把 so 重新编出来并再次覆盖到 `native`，这样你下次拿到的就是精简版输出。

Ran terminal command:  ./build_so.sh

Ran terminal command:  cp "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/libvideo_player.so" "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/aurora_recovery/native/libvideo_player.so"

Ran terminal command:  strings "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/aurora_recovery/native/libvideo_player.so" | rg -n "COMPRESS100 controls absent|current=%d/%u|array: %s total="

我已经把日志压缩版 so 重新编译并覆盖到 native 目录了。

这次改动后的输出会明显短很多：
1. 不再打印每个枚举控件的全部选项。
2. BYTE 控件只保留一行摘要，包含 `rc`、`nonzero` 和前四个字。
3. `COMPRESS100` 不存在时只打一条摘要，不再重复刷屏。

从你这轮长日志里，结论其实已经很稳定了：
1. `PCM100 metadata`、`setParam`、`setParamTag` 在所有阶段都还是全零。
2. `COMPRESS100` 这组控件根本不存在，可以先排除。
3. helper 版 `connect` 后，`PCM100 connect` 仍然是 `ZERO`；只有手动强写 `control` 能变成 `TDM-LPAIF-RX-SECONDARY`。
4. `getTaggedInfo` 从 `-22` 变成 `-19`，说明状态前进了一点，但图还是没真正组起来。

你现在再跑一次，用新 so 的短日志把这些关键词贴出来就够了：
1. `after audio intf metadata`
2. `after stream metadata kv`
3. `after stream metadata instance`
4. `after helper connect`
5. `after force connect`
6. `after agm_mixer_get_miid`

我拿到精简日志后，下一步就可以直接判断要不要跳过现有 helper，改成手写 `setParam` / `setParamTag` 的原始 payload。

User: [INFO][HandleMinuitwrpEvents(701)] MINUITWRP -> OnTouchUp
[INFO][HandleMinuitwrpEvents(701)] MINUITWRP -> OnTouchUp
[swscaler @ 0xb40000702362f150] No accelerated colorspace conversion found from yuv420p to rgba.
flutter: [VideoPlayer] 打开成功: 1280x720, 时长: 73560ms, 帧率: 30.0fps
[VideoPlayer] 音频提取完成: /tmp/flutter/vp_audio_3008652464.wav bytes=14123608 ready=1
[VideoPlayer] start_audio_playback: wav=/tmp/flutter/vp_audio_3008652464.wav start_ms=0
[VideoPlayer] 音频线程启动 path=/tmp/flutter/vp_audio_3008652464.wav
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
[VideoPlayer] PCM100 控件快照: after streamdevice metadata
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
[VideoPlayer] 打开 PCM 成功: card=0 device=16 rate=48000 ch=2 bits=16
[VideoPlayer] 音频线程进入播放循环 backend=1
[VideoPlayer] pcm_write 失败: cannot write initial data: Invalid argument
[VideoPlayer] 音频线程退出: 写流失败 backend=1
[VideoPlayer] 音频线程退出 stop_requested=0


GitHub Copilot: 现在日志已经足够短，而且信息很明确了：`COMPRESS100` 可以排除，`connect` 读值不可信或根本不持久，真正没建立起来的是图和 tag；我去查本地代码/文档里对 `MFC tag` 和 `agm_mixer_get_miid` 的真实用法，优先修正最可能传错的 tag 或查询路径。

Searched for regex `C0000019|configure_mfc|agm_mixer_get_miid|set_agm_stream_metadata_type|agm_mixer_set_param|setParamTag` (`**/*.{c,cc,cpp,h,hpp,md,txt,sh}`), 12 results

Ran terminal command:  strings "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/agmplay" | rg -n "MFC|miid|tag|0x|configure_mfc|setParamTag|getTaggedInfo"

Read memory twrp_audio_agmmixer_helper_semantics.md

现在线索指向 `set_agm_streamdevice_metadata`：只有走它之后，`PCM100 control` 才从 `ZERO` 变成 `TDM-LPAIF-RX-SECONDARY`，所以它的参数顺序比别的 helper 更关键；我直接拆这一个 helper，确认我们是不是把 `stream_kv` 和 `device_kv` 传反了。

Ran terminal command:  objdump -d --start-address=0xb9c8 --stop-address=0xbb90 "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/libagmmixer.so"

Ran terminal command:  strings "/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/agmplay" | rg -n "Failed to set device metadata|device metadata|streamdevice|speaker|TDM-LPAIF-RX-SECONDARY"

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_52m8CVl5ZiL0QGSbbrUG7cJT__vscode-1773648131364/content.txt)

下一步我不再扩日志，而是补一条更接近 Qualcomm 图模型的尝试：在 `mode=1` 下把 `streamdevice metadata` 连续写两次，分别走两个 metadata 变体，补齐 `StreamDevice` 和可能缺失的 `DevicePP` 段，看看能不能把 `connect`/`graph_open` 推过去。

Generating patch (66 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
改动已经落下，我现在把新 so 重建并覆盖到 `native`，让你下一轮直接验证这两个 `streamdevice metadata` 变体有没有推进图状态。

Ran terminal command:  ./build_so.sh

Ran terminal command:  cp "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/libvideo_player.so" "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/aurora_recovery/native/libvideo_player.so"

Ran terminal command:  strings "/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/aurora_recovery/native/libvideo_player.so" | rg -n "streamdevice metadata\[0\]|streamdevice metadata\[1\]|variant=%u"

新的 so 已经重新编译并拷贝到 `native` 目录了，这次包含了 `streamdevice metadata[0]` 和 `streamdevice metadata[1]` 两个变体尝试。

我这边已经确认 `native` 里的 so 带有新标记：
1. `after streamdevice metadata[0]`
2. `after streamdevice metadata[1]`
3. `set_agm_streamdevice_metadata 成功: mode=%d variant=%u device_kv=%u`

你现在直接再跑一次，下一轮只需要贴这几类短日志就够：
1. `after streamdevice metadata[0]`
2. `after streamdevice metadata[1]`
3. `after helper connect`
4. `after force connect`
5. `agm_mixer_get_miid`
6. `AGM PCM open 失败`

如果这一步能把 `connect` 或 `getTaggedInfo` 再往前推，我就继续沿这条线收敛；如果还是完全不动，下一步我就不再走 helper 组合，直接下手 `setParam` / `setParamTag` 原始 payload。

Made changes.

User: [INFO][HandleMinuitwrpEvents(701)] MINUITWRP -> OnTouchUp
[swscaler @ 0xb400007ac314b190] No accelerated colorspace conversion found from yuv420p to rgba.
[VideoPlayer] 音频提取完成: /tmp/flutter/vp_audio_318541616.wav bytes=14123608 ready=1
flutter: [VideoPlayer] 打开成功: 1280x720, 时长: 73560ms, 帧率: 30.0fps
[VideoPlayer] start_audio_playback: wav=/tmp/flutter/vp_audio_318541616.wav start_ms=0
[VideoPlayer] 音频线程启动 path=/tmp/flutter/vp_audio_318541616.wav
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
[VideoPlayer] 打开 PCM 成功: card=0 device=16 rate=48000 ch=2 bits=16
[VideoPlayer] 音频线程进入播放循环 backend=1
[VideoPlayer] pcm_write 失败: cannot write initial data: Invalid argument
[VideoPlayer] 音频线程退出: 写流失败 backend=1
[VideoPlayer] 音频线程退出 stop_requested=0
Application finished.

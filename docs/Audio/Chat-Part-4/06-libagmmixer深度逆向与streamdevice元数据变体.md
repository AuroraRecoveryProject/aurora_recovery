
User: 
[swscaler @ 0xb40000751c4b0100] No accelerated colorspace conversion found from yuv420p to rgba.
flutter: [VideoPlayer] 打开成功: 1280x720, 时长: 73560ms, 帧率: 30.0fps
[VideoPlayer] 音频提取完成: /tmp/flutter/vp_audio_3695140800.wav bytes=14123608 ready=1
[VideoPlayer] AGM 运行时环境: LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/system/lib64:/vendor/lib64:/vendor/lib64/hw
[VideoPlayer] AGM 运行时环境: AGM_BACKEND_CONF_FILE=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: AGM_BACKEND_CONF_PATH=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: BACKEND_CONF_FILE=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: BACKEND_CONF_PATH=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: USECASE_KV_MANAGER_FILE=/odm/etc/usecaseKvManager.xml
[VideoPlayer] AGM 运行时环境: USECASE_KV_MANAGER_PATH=/odm/etc/usecaseKvManager.xml
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libc++.so handle=0x1e767b26f1430053
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libutils.so handle=0x8b2c13d67b54de1
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libcutils.so handle=0xcb4df4f13e7f045d
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/liblog.so handle=0x0
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libaudio_log_utils.so handle=0x587f1eba41f4b423
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libsndcardparser.so handle=0x6f25522ed860c727
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm.so handle=0x86fdc5766a3c5f27
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagmclient.so handle=0xe3dfbd1109d7abd7
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagmmixer.so handle=0xd68c9f2e80163005
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm_pcm_plugin.so handle=0xbcf62dc779f5661d
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm_mixer_plugin.so handle=0xfb6f8eb1c47954e3
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/vendor.qti.hardware.agm-V1-ndk.so handle=0x68cfad90c0c79185
[VideoPlayer] start_audio_playback: wav=/tmp/flutter/vp_audio_3695140800.wav start_ms=0
[VideoPlayer] 音频线程启动 path=/tmp/flutter/vp_audio_3695140800.wav
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
[VideoPlayer] 跳过 USB custom payload 路径: intf=TDM-LPAIF-RX-SECONDARY mode=1
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

GitHub Copilot: 这轮日志把 USB 支路排干净了，但主问题没动：speaker 路线跳过 USB custom payload 后，`device=100` 仍稳定卡在 `-19`。我先把 agmplay 那两次 `set_agm_stream_metadata` 的参数关系再钉死，确认我们现在是不是少了一次真实的 metadata 提交。

Searched for regex `set_agm_stream_metadata\(|AGM_STREAM_KV_PCM_LL_PLAYBACK|AGM_INSTANCE_KV << 16|double|第二次` (`**/docs/**/*.md`), 80 results

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && xcrun llvm-objdump -d --no-show-raw-insn --start-address=0x6520 --stop-address=0x666c audio_dtb_probe/agmplay

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings -t x audio_dtb_probe/agmplay | rg 'Failed to set pcm metadata|Failed to set device metadata|Assign 0 if no instance kv|Assign 0 if no device pp'

我拿到一条比前几轮都更硬的新证据了：从反汇编看，`set_agm_streamdevice_metadata` 在 agmplay 里大概率只吃 `devicepp_kv`，而不是我们现在这样先打一遍 `device_kv` 再打一遍 `devicepp_kv`。我先把这块改成更贴近 agmplay 的单调用形态。

Using "Apply Patch"

补丁上下文又漂了，我先读精确片段再拆成小块改，不换方向。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#500-500), lines 500 to 620

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1265-1265), lines 1265 to 1415

我已经看到精确上下文了，直接把双变体那段收成单次 `devicepp_kv`。

Generating patch (25 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```


Generating patch (92 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
双变体逻辑已经收掉了，我再顺手把那几个废掉的局部变量删掉，然后编译部署。

Generating patch (8 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
现在重新构建并部署，看这次日志里 `streamdevice metadata` 后的状态会不会和之前分叉。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c), 28 problems found

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_so.sh && cp libvideo_player.so '/Volumes/Case-sensitive APFS/TWRP/aurora_recovery/native/libvideo_player.so' && shasum -a 256 libvideo_player.so '/Volumes/Case-sensitive APFS/TWRP/aurora_recovery/native/libvideo_player.so'

新一版已经编译并部署好了。

这次改动把 `set_agm_streamdevice_metadata` 从“先打 `device_kv` 再打 `devicepp_kv`”改成了更贴近 agmplay 反汇编的单次调用，只传 `devicepp_kv`。原因是从调用点看，这个 helper 更像是在补 `device pp in graph`，而普通 `device_kv` 已经由前面的 `set_agm_audio_intf_metadata` 负责。

新的 so 已覆盖到 native，哈希一致：
`c5213db8f05d2e12c3e51b71eb92ac88d399d3537eba03f4aee11b3a8144e893`

你下一轮跑的时候，我只看这些变化：
1. `set_agm_streamdevice_metadata 成功:` 现在应该只出现一次
2. `after streamdevice metadata` 后 `PCM100 control` 和 `getTaggedInfo` 有没有变化
3. `AGM plugin open ... device=100` 是否还停在 `rc=-19`
4. `agm_mixer_get_miid(tag=0xC0000019)` 是否第一次变成非零 MIID

编辑器里的那批报错还是旧的索引假阳性，实际构建已经通过。你直接再跑一次，把新日志贴上来，我继续压这条主路径。

Made changes.

User: 
[VideoPlayer] 音频提取完成: /tmp/flutter/vp_audio_153677536.wav bytes=14123608 ready=1
flutter: [VideoPlayer] 打开成功: 1280x720, 时长: 73560ms, 帧率: 30.0fps
[VideoPlayer] AGM 运行时环境: LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/system/lib64:/vendor/lib64:/vendor/lib64/hw
[VideoPlayer] AGM 运行时环境: AGM_BACKEND_CONF_FILE=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: AGM_BACKEND_CONF_PATH=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: BACKEND_CONF_FILE=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: BACKEND_CONF_PATH=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: USECASE_KV_MANAGER_FILE=/odm/etc/usecaseKvManager.xml
[VideoPlayer] AGM 运行时环境: USECASE_KV_MANAGER_PATH=/odm/etc/usecaseKvManager.xml
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libc++.so handle=0x387c614e5ddea2c7
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libutils.so handle=0xbeeb2decd8eece0b
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libcutils.so handle=0xe432ca44d2b4fedb
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/liblog.so handle=0x0
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libaudio_log_utils.so handle=0x45d0dcce3d748519
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libsndcardparser.so handle=0x3534b09ed586c7cf
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm.so handle=0x70ad63da20225227
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagmclient.so handle=0xdcb577d1dd269529
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagmmixer.so handle=0xdc7b971a1e7461a5
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm_pcm_plugin.so handle=0x724077d5988962c5
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm_mixer_plugin.so handle=0x91989fc2cd3e2003
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/vendor.qti.hardware.agm-V1-ndk.so handle=0x42c0458d37168841
[VideoPlayer] start_audio_playback: wav=/tmp/flutter/vp_audio_153677536.wav start_ms=0
[VideoPlayer] 音频线程启动 path=/tmp/flutter/vp_audio_153677536.wav
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
[VideoPlayer] set_agm_streamdevice_metadata 成功: mode=1 kv=2885681154
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
[VideoPlayer] 跳过 USB custom payload 路径: intf=TDM-LPAIF-RX-SECONDARY mode=1
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
mixer_plugin_open - agm_mixer_plugin_open
mixer_plugin_open: card = 100
mixer_plug_get_card_info: card = 100
Instance key is added
2
pcm_plug_open - agm_pcm_plugin_open
mixer_plugin_open - agm_mixer_plugin_open
mixer_plugin_open: card = 100
mixer_plug_get_card_info: card = 100
Instance key is added
Failed to mixer_ctl_get_array
2
pcm_plug_open - agm_pcm_plugin_open
mixer_plugin_open - agm_mixer_plugin_open
[INFO][HandleMinuitwrpEvents(701)] MINUITWRP -> OnTouchUp
[VideoPlayer] 音频路由预热: phase=pcm_write retry mixer rc=0
[VideoPlayer] pcm_write 失败: cannot write initial data: Invalid argument
[VideoPlayer] 音频线程退出: 写流失败 backend=1
[VideoPlayer] 音频线程退出 stop_requested=1


GitHub Copilot: 这轮日志第一次给了插件内部自带的关键信号：`Instance key is added` 之后紧跟 `Failed to mixer_ctl_get_array`。我先不猜，直接把这个精确字符串在设备侧 AGM 插件里对上，看看它具体卡在哪个控件读数组。

Searched for text `Failed to mixer_ctl_get_array|Instance key is added|agm_mixer_plugin_open|mixer_plug_get_card_info` (`**/docs/**/*.md`), no results

Ran terminal command:  adb shell strings /vendor/lib64/libagm_mixer_plugin.so | rg 'Failed to mixer_ctl_get_array|Instance key is added|mixer_plug_get_card_info|agm_mixer_plugin_open'

Ran terminal command:  adb shell strings /vendor/lib64/libagm_pcm_plugin.so | rg 'Failed to mixer_ctl_get_array|Instance key is added|pcm_plug_open|agm_pcm_plugin_open'

设备侧直接 `strings` 不够，我改成把 AGM 插件拉到工作区做离线取证。目标是把 `Failed to mixer_ctl_get_array` 这个报错附近的其他字符串一起抓出来，推断它在读哪个控件。

Searched for files matching `**/runtime_pull/**`, 2 matches

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_dtb_probe)

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb pull /vendor/lib64/libagm_mixer_plugin.so audio_dtb_probe/libagm_mixer_plugin.so && adb pull /vendor/lib64/libagm_pcm_plugin.so audio_dtb_probe/libagm_pcm_plugin.so

插件已经拉到本地了。现在离线抓报错字符串附近的内容，看看是不是有紧挨着的 mixer control 名。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings -t x audio_dtb_probe/libagm_mixer_plugin.so | rg 'Failed to mixer_ctl_get_array|Instance key is added|mixer_plug_get_card_info|card = |metadata|setParam|getTaggedInfo|connect|disconnect'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings -t x audio_dtb_probe/libagm_pcm_plugin.so | rg 'Failed to mixer_ctl_get_array|Instance key is added|pcm_plug_open|metadata|setParam|getTaggedInfo|connect|disconnect'
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings -t x audio_dtb_probe/libagm_pcm_plugin.so | rg 'Failed to mixer_ctl_get_array|Instance key is added|pcm_plug_open|metadata|setParam|getTaggedInfo|connect|disconnect'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings -t x audio_dtb_probe/libagm_mixer_plugin.so | rg 'card info|snd_card|backend_conf|usecase|stream|device|instance|kv|PCM|COMPRESS'

我不想在 `device_kv/devicepp_kv` 这块靠猜继续来回摆。先让子代理专门把 agmplay 里 `set_agm_streamdevice_metadata` 那个循环的参数来源抠清楚，再决定要不要保留这次单调用改动。

分析 streamdevice 参数

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_dtb_probe)

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1-1), lines 1 to 150

Read memory [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/memory-tool/memories/ZTg2MmQ5YzgtYzAzMS00M2RiLWEwZTYtZTI3NTZlMTVkZjUy)

Searched for files matching `**/*agmplay*`, 1 match

Read memory [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/memory-tool/memories/ZTg2MmQ5YzgtYzAzMS00M2RiLWEwZTYtZTI3NTZlMTVkZjUy/agm_mode0_not_enough.md)

Searched for regex `672c|6754|set_agm_streamdevice_metadata`, 20 results

Searching for regex `devicepp_kv|device_kv|set_agm_streamdevice`

Search complete: 查找agmplay反汇编资料

Searching for regex `agmplay|0x672c|set_agm_streamdevice_metadata`

Searching for files matching `**/*agmplay*`

Searching for files matching `**/*disasm*`

Searching for files matching `**/*metadata*`

Searching for text `agmplay`

Searching for text `0x672c`

Searching for text `set_agm_streamdevice_metadata`

Searched for files matching `**/*.asm`, 200 matches

Searched for files matching `**/*.idapro`, no matches

Searched for files matching `**/*.txt`, 200 matches

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#570-570), lines 570 to 620

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1320-1320), lines 1320 to 1360

Searched for text `set_agm_streamdevice_metadata` (`**/video_player_ffi.c`), 6 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3290-3290), lines 3290 to 3310

Read memory repo

Read memory twrp_audio_agmplay_minimal_success.md

Read memory twrp_audio_devicepp_kv_frontier.md

Read memory twrp_audio_manual_playback.md

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1300-1300), lines 1300 to 1360

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#550-550), lines 550 to 620

Searching for text `ldr w6`

Searched for text `0x672c`, 20 results

我先把 mixer 插件里跟 `metadata_get/put` 和 `connect_get/put` 这组内部 helper 相关的字符串再摊开一点，尽量推断它在读 FE 还是 BE 控件。这个比继续猜参数值更值钱。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings -t x audio_dtb_probe/libagm_mixer_plugin.so | sed -n '60,140p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings -t x audio_dtb_probe/libagm_mixer_plugin.so | sed -n '140,220p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings -t x audio_dtb_probe/libagm_mixer_plugin.so | rg 'index not found|set_session_metadata|set_aif_ses_metadata|amp_be_metadata|get_card_info|Instance key'

我需要把 card100 真实导出的控件名再看一遍，确认 AGM 插件是不是在找我们没注意到的 `rate ch fmt` / `metadata index` 相关控件。先用现成的 `tinymix_stock` 从设备上直接把 card100 列出来。

Ran terminal command:  adb shell 'ls /data/local/tmp/tinymix_stock /odm/bin/tinymix_stock 2>/dev/null'
Completed with input:  adb shell 'ls /data/local/tmp/tinymix_stock /odm/bin/tinymix_stock 2>/dev/null'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb push audio_dtb_probe/tinymix_stock /data/local/tmp/tinymix_stock >/dev/null && adb shell chmod 755 /data/local/tmp/tinymix_stock

Ran terminal command:  adb shell '/data/local/tmp/tinymix_stock -D 100 | rg "metadata|setParam|getTaggedInfo|connect|disconnect|rate ch fmt|control|PCM100|COMPRESS100"'
Completed with input:  adb shell '/data/local/tmp/tinymix_stock -D 100 | rg "metadata|setParam|getTaggedInfo|connect|disconnect|rate ch fmt|control|PCM100|COMPRESS100"'

设备里没有 `rg`，我改成本机过滤输出，不变更方向。

Ran terminal command:  adb shell /data/local/tmp/tinymix_stock -D 100 | rg 'metadata|setParam|getTaggedInfo|connect|disconnect|rate ch fmt|control|PCM100|COMPRESS100'

输出写到临时结果文件里了，我现在只读命中的那部分，不展开整份列表。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_deIVrgDELCmpkaI6qBXADtAC__vscode-1773705133967/content.txt)

刚才那份控件列表过滤得太宽了，我改成只抓控件标题行，不再把整段数组数据带出来。目标是确认 card100 到底有没有插件可能在找的 `rate ch fmt` 或别的 BE metadata 控件。

Ran terminal command:  adb shell /data/local/tmp/tinymix_stock -D 100 | rg '^[[:space:]]*[0-9]+.*(PCM100|COMPRESS100|rate ch fmt|metadata|setParam|getTaggedInfo|connect|disconnect)'
Completed with input:  adb shell /data/local/tmp/tinymix_stock -D 100 | rg '^[[:space:]]*[0-9]+.*(PCM100|COMPRESS100|rate ch fmt|metadata|setParam|getTaggedInfo|connect|disconnect)'

Ran terminal command:  adb shell /data/local/tmp/tinymix_stock -D 100 | rg 'rate ch fmt|Buffer size|bufTimestamp|getBufInfo|setACDBTunnel|getACDBTunnel|sidetone|echoReference|loopback|grp config|datapathParams'
Completed with input:  adb shell /data/local/tmp/tinymix_stock -D 100 | rg 'rate ch fmt|Buffer size|bufTimestamp|getBufInfo|setACDBTunnel|getACDBTunnel|sidetone|echoReference|loopback|grp config|datapathParams'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_2aihDbsjo0PSMzeUUumbgSG5__vscode-1773705133969/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_Bhn9GFKQB8VCNimJA6657Qw6__vscode-1773705133970/content.txt)

这轮最有价值的新发现出来了：card100 上真正成组导出的控件并不只是一套 `PCM100`，还有 backend 名字直接命名的 `rate ch fmt / metadata / setParam`。我现在把这些 backend 控件名精确抓出来，确认插件到底在用哪一组。

Ran terminal command:  adb shell /data/local/tmp/tinymix_stock -D 100 | grep -E 'CODEC_DMA|TDM-LPAIF|PCM100|COMPRESS100|rate ch fmt|metadata|setParam|getTaggedInfo|connect|disconnect' | head -n 80

Ran terminal command:  adb shell /data/local/tmp/tinymix_stock -D 100 | grep -E 'TDM-LPAIF-RX-SECONDARY|CODEC_DMA-LPAIF_RXTX-RX-0|CODEC_DMA-LPAIF_WSA-RX-0' | head -n 80

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_BgWatAg9UFlLpR8kscpmO76B__vscode-1773705133973/content.txt#1-1), lines 1 to 120

Compacting conversation...

User: 继续

GitHub Copilot: 我继续往插件内部失败点下钻，先把本地 AGM 插件副本和 card100 的实际控件名对齐，目标是确定 `Failed to mixer_ctl_get_array` 到底在读哪一组 mixer 控件。

Searched for files matching `**/libagm_mixer_plugin.so`, 1 match

Searched for files matching `**/libagm_pcm_plugin.so`, 1 match

Searched for files matching `**/tinymix_stock`, 1 match

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb devices

本地插件副本和设备都在，下一步直接同时抓两件事：插件里 `mixer_ctl_get_array` 报错附近的字符串，以及设备上 card100 里跟 backend/metadata 相关的控件名。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings audio_dtb_probe/libagm_mixer_plugin.so | rg -n 'mixer_ctl_get_array|Failed to mixer_ctl_get_array|metadata|setParam|rate ch fmt|connect|disconnect|backend'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell '/data/local/tmp/tinymix_stock -D 100' | grep -E 'rate ch fmt|metadata|setParam|connect|disconnect|TDM|PCM100|COMPRESS100' | head -n 200

插件字符串已经出现关键函数族了：它不只碰 `PCM100 metadata`，还会走 `amp_be_metadata_get/put`、`amp_pcm_metadata_get/put` 和 `amp_pcm_aif_connect_get/put`。我先把设备上 card100 命中的控件名读出来，确认 backend 那组控件是否真的存在。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_m2Su3AGGAkDYd9bbfAiVWXzx__vscode-1773706017553/content.txt)

上一次设备侧控件列表被数组内容淹没了，我这次只读 card100 的表头和命中的控件名，目标是确认插件字符串里那组 `amp_be_metadata_get/put` 对应的 backend 控件是否真的导出了。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell '/data/local/tmp/tinymix_stock -D 100' | head -n 80
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell '/data/local/tmp/tinymix_stock -D 100' | head -n 80

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings audio_dtb_probe/libagm_mixer_plugin.so | rg -n 'amp_be_metadata_get|amp_be_metadata_put|amp_pcm_metadata_get|amp_pcm_metadata_put|amp_pcm_aif_connect_get|amp_pcm_aif_connect_put|metadata index not found'
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings audio_dtb_probe/libagm_mixer_plugin.so | rg -n 'amp_be_metadata_get|amp_be_metadata_put|amp_pcm_metadata_get|amp_pcm_metadata_put|amp_pcm_aif_connect_get|amp_pcm_aif_connect_put|metadata index not found'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_u4ekfLjqTZq7bTBP4Slxf3gV__vscode-1773706017555/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_aljbOY92omH0UAGhxkVBCUQf__vscode-1773706017556/content.txt)

现在已经确认 card100 不只导出 `PCM100`，而且确实有 backend 名字直接命名的 `metadata/setParam/rate ch fmt` 控件。下一步我把这些控件名干净地列出来，确认 `TDM-LPAIF-RX-SECONDARY` 那组是否齐全。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell '/data/local/tmp/tinymix_stock -D 100' | awk 'NF && $1 ~ /^[0-9]+$/ {print}' | grep -E 'TDM-LPAIF|CODEC_DMA|metadata|setParam|connect|disconnect|rate ch fmt' | head -n 200

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings audio_dtb_probe/libagm_mixer_plugin.so | rg -n 'amp_be_metadata_get|amp_be_metadata_put|amp_pcm_metadata_get|amp_pcm_metadata_put|amp_pcm_aif_connect_get|amp_pcm_aif_connect_put|rate ch fmt|metadata index not found' | head -n 80
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings audio_dtb_probe/libagm_mixer_plugin.so | rg -n 'amp_be_metadata_get|amp_be_metadata_put|amp_pcm_metadata_get|amp_pcm_metadata_put|amp_pcm_aif_connect_get|amp_pcm_aif_connect_put|rate ch fmt|metadata index not found' | head -n 80

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_YdfkbeBDnUP0YvGEHupo8lIG__vscode-1773706017559/content.txt#1-1), lines 1 to 160

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_ujo9DiadHoRnVsPJj93W4Uqu__vscode-1773706017560/content.txt)

Compacting conversation...

User: 继续

GitHub Copilot: 我先把两条线并起来：一条找工作区里已经拉回来的 AGM 插件副本，另一条直接从设备上只取 card100 的控件名。目标是把 `Failed to mixer_ctl_get_array` 对应到具体控件。

Searched for files matching `**/libagm_mixer_plugin*.so`, 1 match

Searched for files matching `**/libagm_pcm_plugin*.so`, 1 match

Ran terminal command:  adb shell '/data/local/tmp/tinymix_stock -D 100' | grep -E '^[[:space:]]*[0-9]+' | grep -E 'TDM-LPAIF-RX-SECONDARY|PCM100|metadata|setParam|rate ch fmt|connect|disconnect' | head -n 200

本地插件副本有了，设备侧控件过滤结果也拿到了。我先读那份过滤输出，再直接在本地插件里抓 `mixer_ctl_get_array` 附近的字符串，做一次一一对位。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_rhZ2pUDpIyOMh9N5xQioOIKh__vscode-1773706724787/content.txt)

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings audio_dtb_probe/libagm_mixer_plugin.so | grep -E 'mixer_ctl_get_array|metadata_get|metadata_put|connect_get|connect_put|rate ch fmt|setParam|PCM100|TDM-LPAIF-RX-SECONDARY|Failed to mixer_ctl_get_array'
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings audio_dtb_probe/libagm_mixer_plugin.so | grep -E 'mixer_ctl_get_array|metadata_get|metadata_put|connect_get|connect_put|rate ch fmt|setParam|PCM100|TDM-LPAIF-RX-SECONDARY|Failed to mixer_ctl_get_array'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings audio_dtb_probe/libagm_pcm_plugin.so | grep -E 'mixer_ctl_get_array|metadata_get|metadata_put|connect_get|connect_put|rate ch fmt|setParam|PCM100|TDM-LPAIF-RX-SECONDARY|Failed to mixer_ctl_get_array'
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings audio_dtb_probe/libagm_pcm_plugin.so | grep -E 'mixer_ctl_get_array|metadata_get|metadata_put|connect_get|connect_put|rate ch fmt|setParam|PCM100|TDM-LPAIF-RX-SECONDARY|Failed to mixer_ctl_get_array'

上一轮设备控件过滤还带出了大段 BYTE 内容，不够干净。我现在只抓“控件标题行”和插件里的关键字符串，目标是把 `Failed to mixer_ctl_get_array` 和 card100 的具体控件名精确对上。

Ran terminal command:  adb shell '/data/local/tmp/tinymix_stock -D 100' | grep -E '^[[:space:]]*[0-9]+.*(TDM-LPAIF-RX-SECONDARY|PCM100|metadata|setParam|rate ch fmt|connect|disconnect)' | head -n 200

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings -a audio_dtb_probe/libagm_mixer_plugin.so | grep -n -E 'Failed to mixer_ctl_get_array|amp_.*metadata|amp_.*connect|metadata_get|metadata_put|connect_get|connect_put|rate ch fmt|mixer_ctl_get_array' | head -n 200
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings -a audio_dtb_probe/libagm_mixer_plugin.so | grep -n -E 'Failed to mixer_ctl_get_array|amp_.*metadata|amp_.*connect|metadata_get|metadata_put|connect_get|connect_put|rate ch fmt|mixer_ctl_get_array' | head -n 200

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings -a audio_dtb_probe/libagm_mixer_plugin.so | grep -n -E 'TDM-LPAIF-RX-SECONDARY|PCM100|metadata|setParam|connect|disconnect|rate ch fmt' | head -n 200

现在有明确插件 helper 名了：`amp_be_metadata_get/put`、`amp_pcm_metadata_get/put`、`amp_pcm_aif_connect_get/put`、以及 `metadata index not found for pcm_idx`。我先把设备侧控件标题和这批 helper 放一起看，判断它到底在找 backend 组还是 PCM100 组。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_bkd1UgkdylmsmyJlQhkc7Grd__vscode-1773706724791/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_GKcvsWYEenTIRL8a1V5IpJTR__vscode-1773706724792/content.txt)

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings -a audio_dtb_probe/libagm_mixer_plugin.so | grep -n -E 'metadata index not found|Failed to mixer_ctl_get_array|write_with_metadata failed|set_metadata failed|set_session_metadata failed|set_aif_ses_metadata failed'

Compacted conversation前一次 card100 控件查询被 BYTE 内容淹没了。我改成只抓控件标题行，再对照源码里现有 metadata/connect 调用点，看看是不是压根没碰到 plugin 想要的 backend 组。Optimizing tool selection...

Searched for regex `set_agm_stream_metadata|set_agm_streamdevice_metadata|connect_.*audio_intf|get_miid|set_agm_device_custom_payload|set_agm_audio_intf_metadata` (`**/video_player_ffi.c`), 35 results

Ran terminal command:  adb shell "/data/local/tmp/tinymix_stock -D 100 | sed -n '1,220p'" | grep -E '^[[:space:]]*[0-9]+ ' | grep -E 'TDM-LPAIF-RX-SECONDARY|PCM100|metadata|setParam|rate ch fmt|connect|disconnect' | head -n 200

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings -a audio_dtb_probe/libagm_mixer_plugin.so | grep -n -E 'amp_pcm_metadata_get|amp_pcm_metadata_put|amp_be_metadata_get|amp_be_metadata_put|amp_pcm_aif_connect_get|amp_pcm_aif_connect_put|rate ch fmt|metadata index not found for pcm_idx'

设备侧 `tinymix -D 100` 本身就在刷 `Failed to mixer_ctl_get_array`，这更像插件在遍历某类 BYTE 控件时就已经踩空，而不是我们单独某次 `open()` 才触发。我接着看 vendor helper 里有没有拼控件名的格式串，直接反推它在找什么名字。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1260-1260), lines 1260 to 1435

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings -a audio_dtb_probe/libagm_mixer_plugin.so | grep -n -E 'PCM%|metadata|connect|setParam|BE|AIF|pcm_idx|backend|rate ch fmt' | head -n 260

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings -a audio_dtb_probe/libagmmixer.so | grep -n -E 'set_agm_streamdevice_metadata|set_agm_stream_metadata|set_agm_audio_intf_metadata|connect_agm_audio_intf_to_stream|metadata index|rate ch fmt|PCM%|setParam|connect|disconnect' | head -n 260

`libagmmixer.so` 只暴露了通用 helper 名，没有直接给控件名模板；反而 libagm_mixer_plugin.so 明确区分了 `amp_pcm_*` 和 `amp_be_*`。这说明现在最值得做的不是再换 KV，而是让我们自己的路径把 backend metadata 那组也补齐。

Searched for regex `find_control|mixer_get_ctl_by_name|mixer_ctl_set_array|mixer_ctl_get_array|rate ch fmt|setParamTag|metadata|connect|disconnect` (`**/video_player_ffi.c`), 85 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#430-430), lines 430 to 620

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n 'rate ch fmt|setParamTag|metadata|connect|disconnect' docs audio_dtb_probe -g '!**/*.so'

源码里现在只显式操纵了 `PCM100` / `COMPRESS100` 族；没有任何 backend 命名控件写入逻辑。结合插件里的 `amp_be_metadata_get/put`，这基本说明当前路径少了一整组 backend metadata 编程。

Searched for regex `TDM-LPAIF-RX-SECONDARY|PCM100 metadata|rate ch fmt|setParamTagACDB|metadata index not found` (`**/docs/**`), 39 results

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_UR4ejQsBgjvt7JSPaIglZjpt__vscode-1773706724805/content.txt#1-1), lines 1 to 220

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n 'PCM100 control|PCM100 metadata|TDM-LPAIF-RX-SECONDARY|setParamTagACDB|rate ch fmt|metadata index' audio_dtb_probe -g '!**/*.so' -g '!**/*.a'

文档里早就有一条被验证过的结论：早期失败曾经就是 `Invalid mixer control: <backend> rate ch fmt`，后来不再卡在这一步。现在插件新增 `amp_be_metadata_get/put` 线索后，最合理的补丁就是主动把 backend 侧控件按接口名去探测并编程，而不是继续只盯着 `PCM100`。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#740-740), lines 740 to 1085

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3228-3228), lines 3228 to 3368

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings -a audio_dtb_probe/libagm_mixer_plugin.so | grep -n -E 'control|ctl|pcm_idx|be_idx|rate ch fmt|setParamTagACDB|metadata index|connect failed' | head -n 260

插件里又多了两个关键符号：`amp_pcm_mtd_control_get/put`。这说明它确实在按 `pcm_idx` 先找 metadata control index，再读写具体 control；而我们现在连 backend 同名控件是否存在都没有探测。下一步我会把这层探测和补写直接加进代码里。

Searched for regex `mixer_get_num_ctls|mixer_get_ctl\(|mixer_ctl_get_name|typedef struct TinyAlsaApi|mixer_ctl_get_type_string` (`**/video_player_ffi.c`), 9 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1-1), lines 1 to 140

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings -a audio_dtb_probe/libagm_mixer_plugin.so | grep -n -E 'amp_pcm_mtd_control_get|amp_pcm_mtd_control_put|amp_pcm_get_control_value|total_ctl_cnt|metadata index not found'

我要开始改代码了：一是加 card100 上按接口名枚举实际 backend 控件，避免再被 `tinymix` 自己的 plugin 输出干扰；二是补一条“接口名 backend 控件编程”分支，至少把 `rate ch fmt`、`metadata`、`connect` 这组补上，并把结果都打进播放器日志里。

Searched for regex `libvideo_player.so|video_player_ffi.c|clang|gcc|CMake|Makefile`, 120 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#540-540), lines 540 to 625

Using "Apply Patch"

补丁第一次没套上，我在按实际上下文重新分段应用。先把 helper 层加进去，再接两处调用点，避免大块 patch 漂移。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#800-800), lines 800 to 930

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#548-548), lines 548 to 625

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1280-1280), lines 1280 to 1410

Generating patch (193 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```


Generating patch (47 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```


Generating patch (51 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
helper 和调用点已经加上了。接下来先做静态校验；如果没有编译错误，再用现成脚本编译 `.so` 并覆盖到 `native` 目录。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c), 28 problems found

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/build_so.sh)

编辑层面没有新的语法诊断，但 VS Code 的静态检查缺少 FFmpeg/NDK 头，不能代表真实构建结果。我直接走项目自带脚本编译，再把产物复制到 native。

Searched for files matching `**/aurora_recovery/native/libvideo_player.so`, 1 match

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_so.sh
Completed with input:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_so.sh

编译卡在 C 的前向声明，不是逻辑错误。补两条 prototype 就够了，然后我重新编译并覆盖部署。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#180-180), lines 180 to 260

Searched for regex `static int bootstrap_agm_direct_route|static int prepare_agm_pcm_route|static void force_agm_pcm100_connect` (`**/video_player_ffi.c`), 4 results

Generating patch (23 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```


Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c), 28 problems found

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_so.sh

真实构建已经过了；Problems 里的报错还是老样子，只是编辑器没带 FFmpeg/NDK include path。现在我把新 `.so` 复制到 `native` 目录，并给你留一个 hash 方便核对。

Ran terminal command:  cp '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/libvideo_player.so' '/Volumes/Case-sensitive APFS/TWRP/aurora_recovery/native/libvideo_player.so'

Ran terminal command:  shasum -a 256 '/Volumes/Case-sensitive APFS/TWRP/aurora_recovery/native/libvideo_player.so'

Read memory

Read memory /memories/repo/

Read memory twrp_audio_devicepp_kv_frontier.md

Read memory twrp_audio_devicepp_kv_frontier.md

Inserted into memory file twrp_audio_devicepp_kv_frontier.md

这轮已经继续推进完了，代码、编译、部署都做了。

改动点集中在播放器 native 音频路径上：
1. 新增了按接口名模糊探测 AGM mixer 控件的逻辑，不再只盯着 PCM100 这一组。
2. 新增了 backend 控件补写路径，会针对当前接口尝试写入 rate ch fmt、rate ch bit fmt、metadata、setParam，并在 connect 后再补一次 backend connect。
3. 新增了一次性的接口控件清单日志，方便直接从播放器日志里看到 card100 上到底暴露了哪些带 TDM-LPAIF-RX-SECONDARY 的控件。

新的 so 已经编译成功并复制到 native 目录，当前部署 hash 是 5bfc14fdaffb7604861d27004fe2bdcd36cd722bd57d9a3ce851c745b145e0eb。

编辑器 Problems 里那些 FFmpeg/NDK 头文件报错仍然存在，但那是本地索引环境没带编译脚本的 include path；真实构建已经通过。

下一步你直接跑一遍播放器，把新日志贴我，重点看这几类输出：
1. AGM interface 控件清单开始/结束
2. 找不到匹配控件 或 set_array 的 rc
3. connect 后 device100 还是不是 -19
4. 有没有新的 metadata index not found 或 mixer_ctl_get_array 相关变化

有了这轮新日志，就能判断插件实际缺的是 backend 命名控件本身，还是控件存在但 payload 结构还不对。

Made changes.

User: 
flutter: [VideoPlayer] 打开成功: 1280x720, 时长: 73560ms, 帧率: 30.0fps
[VideoPlayer] 音频提取完成: /tmp/flutter/vp_audio_2770535152.wav bytes=14123608 ready=1
[VideoPlayer] AGM 运行时环境: LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/system/lib64:/vendor/lib64:/vendor/lib64/hw
[VideoPlayer] AGM 运行时环境: AGM_BACKEND_CONF_FILE=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: AGM_BACKEND_CONF_PATH=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: BACKEND_CONF_FILE=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: BACKEND_CONF_PATH=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: USECASE_KV_MANAGER_FILE=/odm/etc/usecaseKvManager.xml
[VideoPlayer] AGM 运行时环境: USECASE_KV_MANAGER_PATH=/odm/etc/usecaseKvManager.xml
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libc++.so handle=0xfdd8dcb8b3f38ab7
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libutils.so handle=0x68aa0735a319ea1b
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libcutils.so handle=0x848f849081baf8ab
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/liblog.so handle=0x0
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libaudio_log_utils.so handle=0x6d47f1f5b33b47
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libsndcardparser.so handle=0xb1092a08cec8f405
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm.so handle=0x76fdc3968432167b
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagmclient.so handle=0x9e7e9082a839c307
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagmmixer.so handle=0x5549e478a7dd2657
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm_pcm_plugin.so handle=0xd2821f5e1b1fa347
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm_mixer_plugin.so handle=0xb6ca07bee29cd3ff
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/vendor.qti.hardware.agm-V1-ndk.so handle=0x67219480957c6153
[VideoPlayer] start_audio_playback: wav=/tmp/flutter/vp_audio_2770535152.wav start_ms=0
[VideoPlayer] 音频线程启动 path=/tmp/flutter/vp_audio_2770535152.wav
[VideoPlayer] wav 信息: rate=48000 ch=2 bits=16 data=14123608
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=before open_output_pcm setprop rc=0
[VideoPlayer] 音频路由预热: phase=before open_output_pcm mixer rc=0
[VideoPlayer] AGM interface 控件清单开始: intf=TDM-LPAIF-RX-SECONDARY total=569
[VideoPlayer] AGM interface 控件: [30] TDM-LPAIF-RX-SECONDARY rate ch fmt type=INT
[VideoPlayer] AGM interface 控件: [31] TDM-LPAIF-RX-SECONDARY metadata type=BYTE
[VideoPlayer] AGM interface 控件: [32] TDM-LPAIF-RX-SECONDARY setParam type=BYTE
[VideoPlayer] AGM interface 控件清单结束: intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 set_array: TDM-LPAIF-RX-SECONDARY rate ch fmt rc=0 payload=4 total=4
[VideoPlayer] 找不到匹配控件: token0=TDM-LPAIF-RX-SECONDARY token1=rate ch bit fmt
[VideoPlayer] PCM100 set_array: TDM-LPAIF-RX-SECONDARY metadata rc=-22 payload=16 total=1024
[VideoPlayer] PCM100 set_array: TDM-LPAIF-RX-SECONDARY setParam rc=0 payload=32 total=65536
[VideoPlayer] PCM100 set_array: TDM-LPAIF-RX-SECONDARY rate ch fmt rc=0 payload=4 total=4
[VideoPlayer] 找不到匹配控件: token0=TDM-LPAIF-RX-SECONDARY token1=rate ch bit fmt
[VideoPlayer] PCM100 set_array: TDM-LPAIF-RX-SECONDARY metadata rc=-22 payload=16 total=1024
[VideoPlayer] PCM100 set_array: TDM-LPAIF-RX-SECONDARY setParam rc=0 payload=32 total=65536
[VideoPlayer] PCM100 set enum: PCM100 control=TDM-LPAIF-RX-SECONDARY rc=0
[VideoPlayer] PCM100 set enum: PCM100 connect=TDM-LPAIF-RX-SECONDARY rc=0
[VideoPlayer] 找不到匹配枚举控件: token0=TDM-LPAIF-RX-SECONDARY token1=connect
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
[VideoPlayer] AGM plugin open 失败: mode=-1 card=100 device=100 rc=-5 plugin=0x0
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] 最小 AGM PCM open 失败: cfg=source err=cannot open device 100 for card 100: Unknown error -5
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] 最小 AGM PCM open 失败: cfg=backend err=cannot open device 100 for card 100: Unknown error -5
[VideoPlayer] PCM100 set_array: TDM-LPAIF-RX-SECONDARY rate ch fmt rc=0 payload=4 total=4
[VideoPlayer] 找不到匹配控件: token0=TDM-LPAIF-RX-SECONDARY token1=rate ch bit fmt
[VideoPlayer] PCM100 set_array: TDM-LPAIF-RX-SECONDARY metadata rc=-22 payload=16 total=1024
[VideoPlayer] PCM100 set_array: TDM-LPAIF-RX-SECONDARY setParam rc=0 payload=32 total=65536
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
[VideoPlayer] set_agm_streamdevice_metadata 成功: mode=1 kv=2885681154
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
[VideoPlayer] PCM100 set_array: TDM-LPAIF-RX-SECONDARY rate ch fmt rc=0 payload=4 total=4
[VideoPlayer] 找不到匹配控件: token0=TDM-LPAIF-RX-SECONDARY token1=rate ch bit fmt
[VideoPlayer] PCM100 set_array: TDM-LPAIF-RX-SECONDARY metadata rc=-22 payload=16 total=1024
[VideoPlayer] PCM100 set_array: TDM-LPAIF-RX-SECONDARY setParam rc=0 payload=32 total=65536
[VideoPlayer] 跳过 USB custom payload 路径: intf=TDM-LPAIF-RX-SECONDARY mode=1
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
[VideoPlayer] 找不到匹配枚举控件: token0=TDM-LPAIF-RX-SECONDARY token1=connect
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
[VideoPlayer] AGM PCM open 失败: mode=1 cfg=source err=cannot open device 100 for card 100: Unknown error -5
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] AGM PCM open 失败: mode=1 cfg=backend err=cannot open device 100 for card 100: Unknown error -5
[VideoPlayer] AGM plugin open 失败: mode=1 card=100 device=100 rc=-5 plugin=0x0
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


GitHub Copilot: 这批日志把边界压得更清楚了：backend 侧确实只暴露了 3 个以接口名命名的控件，`rate ch fmt`、`metadata`、`setParam`，而且真正卡住的是 `metadata rc=-22` 和 plugin/open 的 `-5`，不是“控件不存在”。我先把 backend 控件写法修正成按类型编程，并补更多控件枚举/快照，缩小到到底缺 `setParamTagACDB` 还是 metadata 载荷格式。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#760-760), lines 760 to 1095

Searched for regex `setParamTagACDB|rate ch fmt|metadata rc=-22|amp_be_metadata|amp_pcm_mtd_control` (`**/docs/**`), 6 results

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && strings -a audio_dtb_probe/libagm_mixer_plugin.so | grep -n -E 'setParamTagACDB|metadata index|amp_be_metadata|amp_pcm_mtd_control|rate ch fmt|connect failed err'

从这批日志里能确认两件事：第一，`rate ch fmt` 现在被我们用错 API 了，它是 `INT` 不是 `BYTE`；第二，plugin 字符串里还有 `setParamTagACDB`，但当前运行时根本没把这类控件列出来。下一轮补丁我会同时修这两个问题：按控件类型写值，并把所有 `setParamTag` 相关控件一次性枚举出来。

Searched for regex `find_mixer_control_like\(|write_mixer_words_like\(|trace_agm_interface_controls\(|prime_agm_named_backend_controls\(` (`**/video_player_ffi.c`), 16 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#860-860), lines 860 to 1075

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#220-220), lines 220 to 270

我要把 backend 写入层改成“按控件类型分派”：`INT` 走逐项 `set_value`，`BYTE` 才走整块 `set_array`。顺手再把所有带 `setParamTag` 的控件一次性打出来，这样下一轮日志就能直接看到是不是还藏着 `setParamTagACDB`。

Generating patch (169 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
补丁已经落下去了，现在直接编译验证；如果过了就继续覆盖 `native` 里的 so。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c), 28 problems found

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_so.sh

真实构建还是通过了，说明改动没有引入新编译问题。现在我把新 so 覆盖过去并给出新的 hash，你就可以直接再跑一轮拿日志。

Ran terminal command:  cp '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/libvideo_player.so' '/Volumes/Case-sensitive APFS/TWRP/aurora_recovery/native/libvideo_player.so'

Ran terminal command:  shasum -a 256 '/Volumes/Case-sensitive APFS/TWRP/aurora_recovery/native/libvideo_player.so'

这轮我已经继续改完并部署了。

核心修正有两点。第一，把 backend 控件的写入从“无脑按 BYTE set_array”改成了“按实际控件类型分派”：
`TDM-LPAIF-RX-SECONDARY rate ch fmt` 现在会走 `INT` 多值写入，不再像上一版那样只塞 4 个字节。
第二，增加了 `setParamTag` 相关控件的全局枚举和可选写入，专门盯 `setParamTagACDB` 这条线，因为从你这次日志看，plugin 明显还留着这条语义，但运行时还没看到对应控件被我们触到。

新的 so 已经编译并复制到 native 目录，当前 hash 是：
0ac8378688ac4f95dfa55772a18560eb5f5747329badeac5401a3e9d57306b06

你下一轮直接跑播放器，把新增日志贴我，重点看这几类：
1. `AGM interface 控件` 现在的 `values=` 明细，特别是 `rate ch fmt`
2. `AGM 关键字控件: ... setParamTag ...`
3. `PCM100 set_int:` 是否成功写了 `TDM-LPAIF-RX-SECONDARY rate ch fmt`
4. `setParamTagACDB` 有没有被找到，以及写入 rc
5. `agm_mixer_get_miid` 和 `plugin open` 的返回值有没有从 `-19/-5` 继续前进

从你上一轮日志看，方向已经很明确了：不是接口名 backend 控件不存在，而是 backend metadata/tag 这层格式或缺项还没对上。下一轮只要看到 `setParamTag` 家族的实际暴露情况，基本就能决定是继续补 ACDB tag，还是回头改 `metadata` 的 payload 结构。

Made changes.

User: 
Connecting to VM Service at ws://127.0.0.1:58093/zi9hqJByBoo=/ws
Connected to the VM Service.
[DRM-DUMB] PresentBuffer: src_fmt=RGBA dst='XB24'(875709016) layout=1 pitch=13568/13568 dim=3392x2400/3392x2400 px0=255,255,255,255
[DRM-DUMB] gr_flip(direct): 13.813 ms
[DRM-DUMB] PresentBuffer: src_fmt=RGBA dst='XB24'(875709016) layout=1 pitch=13568/13568 dim=3392x2400/3392x2400 px0=255,255,255,255
[DRM-DUMB] gr_flip(direct): 10.324 ms
2
[INFO][HandleMinuitwrpEvents(701)] MINUITWRP -> OnTouchUp
[swscaler @ 0xb40000725dc16010] No accelerated colorspace conversion found from yuv420p to rgba.
[VideoPlayer] 音频提取完成: /tmp/flutter/vp_audio_2915302320.wav bytes=14123608 ready=1
flutter: [VideoPlayer] 打开成功: 1280x720, 时长: 73560ms, 帧率: 30.0fps
[VideoPlayer] AGM 运行时环境: LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/system/lib64:/vendor/lib64:/vendor/lib64/hw
[VideoPlayer] AGM 运行时环境: AGM_BACKEND_CONF_FILE=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: AGM_BACKEND_CONF_PATH=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: BACKEND_CONF_FILE=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: BACKEND_CONF_PATH=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: USECASE_KV_MANAGER_FILE=/odm/etc/usecaseKvManager.xml
[VideoPlayer] AGM 运行时环境: USECASE_KV_MANAGER_PATH=/odm/etc/usecaseKvManager.xml
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libc++.so handle=0x83bfffca036e861b
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libutils.so handle=0xa7d8e8c8f32ece8d
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libcutils.so handle=0x3d35e36549e2ed31
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/liblog.so handle=0x0
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libaudio_log_utils.so handle=0x39e65c3740b9e943
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libsndcardparser.so handle=0xca9ca003925470cb
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm.so handle=0xaa1e34b82e4d4923
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagmclient.so handle=0xce1207bc147b0deb
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagmmixer.so handle=0x4f4eb567156a55e7
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm_pcm_plugin.so handle=0x37766132f875aaa9
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm_mixer_plugin.so handle=0xfa7ac72e9394b107
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/vendor.qti.hardware.agm-V1-ndk.so handle=0xa632f42b1ca0dc4d
[VideoPlayer] start_audio_playback: wav=/tmp/flutter/vp_audio_2915302320.wav start_ms=0
[VideoPlayer] 音频线程启动 path=/tmp/flutter/vp_audio_2915302320.wav
[VideoPlayer] wav 信息: rate=48000 ch=2 bits=16 data=14123608
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=before open_output_pcm setprop rc=0
[VideoPlayer] 音频路由预热: phase=before open_output_pcm mixer rc=0
[VideoPlayer] AGM interface 控件清单开始: intf=TDM-LPAIF-RX-SECONDARY total=569
[VideoPlayer] AGM interface 控件: [30] TDM-LPAIF-RX-SECONDARY rate ch fmt type=INT values=4
[VideoPlayer] AGM interface 控件: [31] TDM-LPAIF-RX-SECONDARY metadata type=BYTE values=1024
[VideoPlayer] AGM interface 控件: [32] TDM-LPAIF-RX-SECONDARY setParam type=BYTE values=65536
[VideoPlayer] AGM interface 控件清单结束: intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] AGM 关键字控件开始: keyword=setParamTag total=569
[VideoPlayer] AGM 关键字控件: [122] PCM100 setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [123] PCM100 setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [134] PCM102 setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [135] PCM102 setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [146] PCM103 setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [147] PCM103 setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [158] VOICEMMODE1p setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [159] VOICEMMODE1p setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [170] VOICEMMODE2p setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [171] VOICEMMODE2p setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [182] PCM110 setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [183] PCM110 setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [194] PCM114 setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [195] PCM114 setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [206] PCM117 setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [207] PCM117 setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [218] PCM123 setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [219] PCM123 setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [230] PCM126 setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [231] PCM126 setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [242] PCM128 setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [243] PCM128 setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [254] COMPRESS105 setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [255] COMPRESS105 setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [302] PCM101 setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [303] PCM101 setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [314] PCM104 setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [315] PCM104 setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [326] VOICEMMODE1c setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [327] VOICEMMODE1c setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [338] VOICEMMODE2c setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [339] VOICEMMODE2c setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [350] PCM111 setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [351] PCM111 setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [362] PCM112 setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [363] PCM112 setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [374] PCM113 setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [375] PCM113 setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [386] PCM115 setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [387] PCM115 setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [398] PCM116 setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [399] PCM116 setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [410] PCM118 setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [411] PCM118 setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [422] PCM119 setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [423] PCM119 setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [434] PCM120 setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [435] PCM120 setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [446] PCM121 setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [447] PCM121 setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [458] ExtEC122 setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [459] ExtEC122 setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [470] PCM125 setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [471] PCM125 setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [482] PCM127 setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [483] PCM127 setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [494] PCM129 setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [495] PCM129 setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [506] COMPRESS124 setParamTag type=BYTE values=262144
[VideoPlayer] AGM 关键字控件: [507] COMPRESS124 setParamTagACDB type=BYTE values=262144
[VideoPlayer] AGM 关键字控件结束: keyword=setParamTag
[VideoPlayer] PCM100 set_int: TDM-LPAIF-RX-SECONDARY rate ch fmt rc=0 count=4 total=4 v0=48000 v1=8 v2=32 v3=4294967295
[VideoPlayer] 找不到匹配控件: token0=TDM-LPAIF-RX-SECONDARY token1=rate ch bit fmt
[VideoPlayer] PCM100 set_array: TDM-LPAIF-RX-SECONDARY metadata rc=-22 payload=16 total=1024
[VideoPlayer] PCM100 set_array: TDM-LPAIF-RX-SECONDARY setParam rc=0 payload=32 total=65536
[VideoPlayer] 找不到匹配控件: token0=TDM-LPAIF-RX-SECONDARY token1=setParamTag
[VideoPlayer] PCM100 set_array: PCM100 setParamTagACDB rc=-12 payload=16 total=262144
[VideoPlayer] PCM100 set_int: TDM-LPAIF-RX-SECONDARY rate ch fmt rc=0 count=4 total=4 v0=48000 v1=8 v2=32 v3=4294967295
[VideoPlayer] 找不到匹配控件: token0=TDM-LPAIF-RX-SECONDARY token1=rate ch bit fmt
[VideoPlayer] PCM100 set_array: TDM-LPAIF-RX-SECONDARY metadata rc=-22 payload=16 total=1024
[VideoPlayer] PCM100 set_array: TDM-LPAIF-RX-SECONDARY setParam rc=0 payload=32 total=65536
[VideoPlayer] 找不到匹配控件: token0=TDM-LPAIF-RX-SECONDARY token1=setParamTag
[VideoPlayer] PCM100 set_array: PCM100 setParamTagACDB rc=-32 payload=16 total=262144
[VideoPlayer] PCM100 set enum: PCM100 control=TDM-LPAIF-RX-SECONDARY rc=0
[VideoPlayer] PCM100 set enum: PCM100 connect=TDM-LPAIF-RX-SECONDARY rc=0
[VideoPlayer] 找不到匹配枚举控件: token0=TDM-LPAIF-RX-SECONDARY token1=connect
[VideoPlayer] PCM100 控件快照: after minimal direct bootstrap
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=256/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=256/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 preview=32 nonzero=0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-22 bytes=256/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] 最小 AGM bootstrap 完成: intf=TDM-LPAIF-RX-SECONDARY rate=48000 bits=32 instance_kv=65536
[VideoPlayer] 先尝试最小 AGM 直开: card=100 device=100 intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] AGM plugin open 失败: mode=-1 card=100 device=100 rc=-5 plugin=0x0
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] 最小 AGM PCM open 失败: cfg=source err=cannot open device 100 for card 100: Unknown error -5
pcm_plug_open: dlopen successful for libagm_pcm_plugin.so
pcm_plug_open: failed to open plugin
[VideoPlayer] 最小 AGM PCM open 失败: cfg=backend err=cannot open device 100 for card 100: Unknown error -5
[VideoPlayer] PCM100 set_int: TDM-LPAIF-RX-SECONDARY rate ch fmt rc=0 count=4 total=4 v0=48000 v1=8 v2=32 v3=4294967295
[VideoPlayer] 找不到匹配控件: token0=TDM-LPAIF-RX-SECONDARY token1=rate ch bit fmt
[VideoPlayer] PCM100 set_array: TDM-LPAIF-RX-SECONDARY metadata rc=-22 payload=16 total=1024
[VideoPlayer] PCM100 set_array: TDM-LPAIF-RX-SECONDARY setParam rc=0 payload=32 total=65536
[VideoPlayer] 找不到匹配控件: token0=TDM-LPAIF-RX-SECONDARY token1=setParamTag
[VideoPlayer] PCM100 set_array: PCM100 setParamTagACDB rc=-12 payload=16 total=262144
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
[VideoPlayer] set_agm_streamdevice_metadata 成功: mode=1 kv=2885681154
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
[VideoPlayer] PCM100 set_int: TDM-LPAIF-RX-SECONDARY rate ch fmt rc=0 count=4 total=4 v0=48000 v1=8 v2=32 v3=4294967295
[VideoPlayer] 找不到匹配控件: token0=TDM-LPAIF-RX-SECONDARY token1=rate ch bit fmt
[VideoPlayer] PCM100 set_array: TDM-LPAIF-RX-SECONDARY metadata rc=-22 payload=16 total=1024
[VideoPlayer] PCM100 set_array: TDM-LPAIF-RX-SECONDARY setParam rc=0 payload=32 total=65536
[VideoPlayer] 找不到匹配控件: token0=TDM-LPAIF-RX-SECONDARY token1=setParamTag
[VideoPlayer] PCM100 set_array: PCM100 setParamTagACDB rc=-32 payload=16 total=262144
[VideoPlayer] 跳过 USB custom payload 路径: intf=TDM-LPAIF-RX-SECONDARY mode=1
Application finished.

GitHub Copilot: 这次日志的新增信息很关键：`rate ch fmt` 已经写对了，`setParamTag` 家族也完全暴露出来了，但真正没推进的是两件事，`TDM-LPAIF-RX-SECONDARY metadata rc=-22` 以及 `PCM100 setParamTag/ACDB` 的 payload 根本不对。我先回看现有笔记和源码里 `setParamTag` 相关实验，再直接把 speaker 路径补成真正去写 `PCM100 setParamTag`，不再误写成 ACDB 元数据。

Searched for regex `setParamTag|setParamTagACDB|PCM100 setParamTag|metadata rc=-22|getTaggedInfo` (`**/docs/**`), 7 results

Searched for regex `prime_pcm100_payload_controls|setParamTagACDB|PCM100 setParamTag|AGM_DEVICE_CUSTOM_PAYLOAD_TAG|metadata_words|tag_words` (`**/video_player_ffi.c`), 31 results

Read memory twrp_audio_pcm100_setparamtag.md

现在最值得做的不是再碰 `setParamTagACDB`，因为日志已经证明那是在全局 PCM 控件上乱打，返回 `-12/-32` 只是噪音。我要把它撤掉，改成 speaker 路径真正去补 `PCM100 setParamTag`，让 `TDM-LPAIF-RX-SECONDARY` 的 helper 链后面至少有一轮针对 `PCM100` 本体的 tag 编程。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1168-1168), lines 1168 to 1235

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1650-1650), lines 1650 to 1755

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1538-1538), lines 1538 to 1615

我现在把“错误的 ACDB 全局写入”撤掉，并把 raw `PCM100 setParamTag` 正式接到 speaker 路径里。目标是让下一轮日志能回答一个更硬的问题：`PCM100 setParamTag` 真写进去之后，`getTaggedInfo` 还会不会继续卡在 `-19`。

Generating patch (17 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```


Generating patch (26 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```


Generating patch (30 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
raw `PCM100 setParamTag` 已经正式接回 speaker 路径了，且不再去误写 `setParamTagACDB`。我先编译并部署，你拿下一轮日志时就能直接看这条改动有没有把 `PCM100 setParamTag` 从全零状态拉起来。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c), 28 problems found

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_so.sh

编译是成功的，编辑器里的 include 报错还是老问题，不影响这次产物。我把新 so 覆盖到 `native` 并给出新的 hash。

Ran terminal command:  cp '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/libvideo_player.so' '/Volumes/Case-sensitive APFS/TWRP/aurora_recovery/native/libvideo_player.so'

Ran terminal command:  shasum -a 256 '/Volumes/Case-sensitive APFS/TWRP/aurora_recovery/native/libvideo_player.so'

状态更新：这轮不是“又试了个 KV”，而是把错误的 `setParamTagACDB` 旁路掉，转成真正对 `PCM100 setParamTag` 做 speaker 原始 payload 补写。下一轮日志最关键的观察点已经变成两条：`PCM100 setParamTag` 还会不会持续全零，以及 `getTaggedInfo` 会不会从 `-19` 再往前走。从你这次日志里，结论已经更硬了。

现在可以确认：
1. `TDM-LPAIF-RX-SECONDARY rate ch fmt` 已经写对了，且必须按 `INT` 写，不是之前那种 `BYTE`。
2. backend 接口名控件只有 3 个：`rate ch fmt`、`metadata`、`setParam`。这里面真正异常的是 `metadata rc=-22`。
3. `setParamTag` 家族并不挂在 backend 接口名下面，而是挂在 `PCM100/PCM102/...` 这类全局 PCM 控件下面。
4. 我们上一轮去写 `PCM100 setParamTagACDB` 基本可以判定是错方向，因为它只产生了 `-12/-32` 噪音，没推进任何状态。

所以我已经继续改了代码，把这条误写撤掉，并把 speaker 路径改成真正去补 `PCM100 setParamTag` 的 raw payload。新的 so 已经编译、复制完成，当前 hash 是：
4fd55000b022746c3e7701c1684034ee0042da707d0a6cb383888a8608ecd303

你下一轮直接跑这版，然后只盯下面这些日志：
1. 有没有新的 `PCM100 set_array: PCM100 setParamTag ...`
2. `PCM100 setParamTag` 读回是不是还全零
3. `PCM100 getTaggedInfo` 还是否停在 `-19`
4. `agm_mixer_get_miid` / `plugin open` 的返回值有没有变化

如果这轮 `PCM100 setParamTag` 仍然写了也完全不生效，那下一步就不是再加控件，而是要回头改 `PCM100 metadata` 和 `PCM100 setParamTag` 的 payload 结构本身。现在 frontier 已经从“缺哪个控件”收敛到“payload 格式不对”。

Made changes.


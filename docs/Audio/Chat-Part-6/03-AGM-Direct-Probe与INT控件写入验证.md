# 第3章：AGM Direct Probe与INT控件写入验证


User: [INFO][HandleMinuitwrpEvents(701)] MINUITWRP -> OnTouchUp
[INFO][HandleMinuitwrpEvents(701)] MINUITWRP -> OnTouchUp
[INFO][HandleMinuitwrpEvents(701)] MINUITWRP -> OnTouchUp
[swscaler @ 0xb4000079bb6b00b0] No accelerated colorspace conversion found from yuv420p to rgba.
flutter: [VideoPlayer] 打开成功: 1280x720, 时长: 73560ms, 帧率: 30.0fps
[VideoPlayer] 音频提取完成: /tmp/flutter/vp_audio_2338560496.wav bytes=14123608 ready=1
[VideoPlayer] AGM 构建标记: agm-20260318-direct-probe-v3
[VideoPlayer] AGM 运行时环境: LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/system/lib64:/vendor/lib64:/vendor/lib64/hw
[VideoPlayer] AGM 运行时环境: AGM_BACKEND_CONF_FILE=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: AGM_BACKEND_CONF_PATH=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: BACKEND_CONF_FILE=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: BACKEND_CONF_PATH=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: USECASE_KV_MANAGER_FILE=/odm/etc/usecaseKvManager.xml
[VideoPlayer] AGM 运行时环境: USECASE_KV_MANAGER_PATH=/odm/etc/usecaseKvManager.xml
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libc++.so handle=0x70a356c2948d9d51
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libutils.so handle=0x6fc9ad430ff54ae1
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libcutils.so handle=0x9b28a2e33390e98d
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/liblog.so handle=0x0
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libaudio_log_utils.so handle=0xcc1227f4b67a2de9
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libsndcardparser.so handle=0x9a8b1ea475c79f4f
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm.so handle=0x5849b7f111ef8a99
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagmclient.so handle=0x4c2abaa8460344ef
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagmmixer.so handle=0xd18a9db46e1818d1
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm_pcm_plugin.so handle=0x5b0ffd091f6b1b2f
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm_mixer_plugin.so handle=0x28e5e11f17b9d725
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/vendor.qti.hardware.agm-V1-ndk.so handle=0xe04909b23d415e5f
[VideoPlayer] VideoPlayer FFI build=agm-20260318-direct-probe-v3
[VideoPlayer] start_audio_playback: wav=/tmp/flutter/vp_audio_2338560496.wav start_ms=0
[VideoPlayer] 音频线程启动 path=/tmp/flutter/vp_audio_2338560496.wav
[VideoPlayer] wav 信息: rate=48000 ch=2 bits=16 data=14123608
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=before open_output_pcm setprop rc=0
[VideoPlayer] 音频路由预热: phase=before open_output_pcm mixer rc=0
[VideoPlayer] 临时跳过最小 AGM 直开分支: 当前该分支在 plugin 失败路径会触发 abort，先保留主 AGM 路径调试稳定性
[VideoPlayer] AGM: 归一化 media_config rate=48000 ch=8 bits=32 fmt=0xffffffff
[VideoPlayer] AGM backend 观测: intf=TDM-LPAIF-RX-SECONDARY stream_kv=2701131790 device_kv=2717908993 devicepp_kv=2885681154 instance_kv=65536 rate=48000 ch=8 bits=32
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
[VideoPlayer] AGM direct probe: after device media config before v0=0 v1=0 v2=0 v3=0
[VideoPlayer] PCM100 set_int: TDM-LPAIF-RX-SECONDARY rate ch fmt rc=0 count=4 total=4 v0=48000 v1=8 v2=32 v3=4294967295
[VideoPlayer] AGM direct probe: after device media config write rc=0 rate=48000 ch=8 bits=32 fmt=0xffffffff
[VideoPlayer] AGM direct probe: after device media config after v0=0 v1=0 v2=0 v3=0
[VideoPlayer] AGM interface 运行态快照: after device media config intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 int: TDM-LPAIF-RX-SECONDARY rate ch fmt values=4 v0=0 v1=0 v2=0 v3=0
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY setParam type=BYTE rc=0 bytes=4096/65536 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY setParam total=65536 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件快照: after device media config
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=0/21 name=ZERO
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=4096/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=4096/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-22 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] PCM100 控件快照: after audio intf metadata
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=0/21 name=ZERO
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=4096/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=4096/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-22 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] AGM interface 运行态快照: after audio intf metadata intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 int: TDM-LPAIF-RX-SECONDARY rate ch fmt values=4 v0=0 v1=0 v2=0 v3=0
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY setParam type=BYTE rc=0 bytes=4096/65536 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY setParam total=65536 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件快照: after stream metadata
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=0/21 name=ZERO
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=4096/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=4096/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-22 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] AGM interface 运行态快照: after stream metadata intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 int: TDM-LPAIF-RX-SECONDARY rate ch fmt values=4 v0=0 v1=0 v2=0 v3=0
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY setParam type=BYTE rc=0 bytes=4096/65536 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY setParam total=65536 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] set_agm_streamdevice_metadata 成功: mode=1 单次调用 kv=2717908993
[VideoPlayer] PCM100 控件快照: after streamdevice metadata
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=4096/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=4096/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] AGM interface 运行态快照: after streamdevice metadata intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 int: TDM-LPAIF-RX-SECONDARY rate ch fmt values=4 v0=0 v1=0 v2=0 v3=0
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY setParam type=BYTE rc=0 bytes=4096/65536 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY setParam total=65536 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] 跳过 speaker raw payload prime: 当前 PCM100 metadata/setParamTag/setParam 原始结构未对齐 agmmixer helper
[VideoPlayer] AGM backend 观测: intf=TDM-LPAIF-RX-SECONDARY stream_kv=2701131790 device_kv=2717908993 devicepp_kv=2885681154 instance_kv=65536 rate=48000 ch=8 bits=32
[VideoPlayer] PCM100 控件快照: after pre-connect agm_mixer_get_miid
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=4096/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=4096/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] agm_mixer_get_miid 失败: phase=after pre-connect agm_mixer_get_miid mode=1 rc=-19 miid=0 tag=3221225476
[VideoPlayer] 跳过 USB custom payload 下发: intf=TDM-LPAIF-RX-SECONDARY mode=1 preconnect_miid=0
[VideoPlayer] PCM100 控件快照: after helper connect
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=4096/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=4096/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] AGM interface 运行态快照: after helper connect intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 int: TDM-LPAIF-RX-SECONDARY rate ch fmt values=4 v0=0 v1=0 v2=0 v3=0
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY setParam type=BYTE rc=0 bytes=4096/65536 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY setParam total=65536 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件快照: after connect settle
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=4096/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=4096/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] AGM interface 运行态快照: after connect settle intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 int: TDM-LPAIF-RX-SECONDARY rate ch fmt values=4 v0=0 v1=0 v2=0 v3=0
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY setParam type=BYTE rc=0 bytes=4096/65536 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY setParam total=65536 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件快照: after agm_mixer_get_miid
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=4096/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=4096/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] agm_mixer_get_miid 失败: phase=after agm_mixer_get_miid mode=1 rc=-19 miid=0 tag=3221225497
[VideoPlayer] AGM interface 运行态快照: after agm_mixer_get_miid intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 int: TDM-LPAIF-RX-SECONDARY rate ch fmt values=4 v0=0 v1=0 v2=0 v3=0
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY setParam type=BYTE rc=0 bytes=4096/65536 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY setParam total=65536 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] MFC tag 尚未解析出 MIID: mode=1，继续尝试无 MFC 直开 PCM
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
[VideoPlayer] AGM: 归一化 media_config rate=48000 ch=8 bits=32 fmt=0xffffffff
mixer_plugin_open: failed to open plugin, err: -12
[VideoPlayer] 打开 AGM mixer 失败: card=100
[VideoPlayer] AGM plugin 打开全部失败，回退普通 PCM
[VideoPlayer] 打开 PCM 失败: card=0 device=16 cfg=backend err=cannot set hw params: Invalid argument
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=pcm probe after open setprop rc=0
[VideoPlayer] 音频路由预热: phase=pcm probe after open mixer rc=0
[VideoPlayer] PCM probe write: phase=source rc=-1 bytes=4096
[VideoPlayer] 打开 PCM 后探测写失败: card=0 device=16 cfg=source err=cannot write initial data: Invalid argument
[VideoPlayer] 打开 PCM 失败: card=0 device=14 cfg=backend err=cannot set hw params: Invalid argument
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=pcm probe after open setprop rc=0
[VideoPlayer] 音频路由预热: phase=pcm probe after open mixer rc=0
[VideoPlayer] PCM probe write: phase=source rc=-1 bytes=4096
[VideoPlayer] 打开 PCM 后探测写失败: card=0 device=14 cfg=source err=cannot write initial data: Invalid argument
[VideoPlayer] 普通 PCM 打开全部失败
[VideoPlayer] 音频线程退出: 输出打开失败


GitHub Copilot: 我先只查一个点：`<intf> rate ch fmt` 写入明明 `rc=0` 却读回全零，先确认我们是不是用错了 tinyalsa 的写法，这个点比继续猜 payload 更前。

Searched for regex `set_mixer_int_words|PCM100 set_int:|mixer_ctl_set_value\(|mixer_ctl_set_array\(` (`**/video_player_ffi.c`), 7 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#940-940), lines 940 to 1045

Read memory twrp_audio_qualcomm_tinyalsa_doc_mapping.md

下一步我直接把 `INT` 控件写法补成更接近 tinyalsa 真实语义的版本：先确认 `mixer_ctl_set_array` 的参数约定，再让 `rate ch fmt` 这种 4-word 控件同时走 array 路径。

查 tinyalsa array 语义

Searched for regex `mixer_ctl_set_array\(|int mixer_ctl_set_array|size_t count` (`**/*asoundlib*.h`), 40 results

Searching for regex `mixer_ctl_set_array\(` (`**/*.{c,h,cpp,cc}`)

Search complete: 找 mixer_ctl_set_array 定义

Searched for files matching `**/asoundlib.h`, 54 matches

Searching for text `mixer_ctl_set_array`

Searched for regex `mixer_ctl_set_array` (`**/external/tinyalsa/include/tinyalsa/asoundlib.h`), 48 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/twrp_a12_compile/prebuilts/vndk/v30/x86_64/include/external/tinyalsa/include/tinyalsa/asoundlib.h#300-300), lines 300 to 320

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/twrp_a12_compile/prebuilts/vndk/v31/x86_64/include/external/tinyalsa/include/tinyalsa/asoundlib.h#325-325), lines 325 to 345

Search complete: 找 mixer_ctl_set_array 实现

Searching for text `mixer_ctl_set_array`

Searched for files matching `**/mixer*.c`, no matches

Searched for files matching `**/mixer*.h`, 42 matches

Searched codebase for "mixer_ctl_set_array INT ENUM BYTE type handling", 24 results

Searched for files matching `**/external/tinyalsa/**/*.c`, no matches

Searched for files matching `**/*.c`, 200 matches

Searched for regex `ctl_set_array|mixer_ctl_set`, 200 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#99-99), lines 99 to 110

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#895-895), lines 895 to 960

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/twrp_a16_compile/hardware/libhardware/modules/usbaudio/audio_hal.c#780-780), lines 780 to 795

Search complete: 找 video_player_ffi.c

Searched for files matching `**/video_player_ffi.c`, no matches

Searching for text `mixer_ctl_set_value`

Searching for regex `mixer_ctl_set_value|video_player_ffi`

Searched for regex `rate.*ch.*fmt|mixer_ctl_set_value.*rate|mixer_ctl_set_value.*0,`, 20 results

Searched for files matching `**/video_player_ffi.c`, no matches

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1228-1228), lines 1228 to 1290

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#895-895), lines 895 to 970

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/twrp_a12_compile/prebuilts/vndk/v30/x86_64/include/external/tinyalsa/include/tinyalsa/asoundlib.h#300-300), lines 300 to 326

Searched for text `set_mixer_int_words` (`**//Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c`), 3 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#986-986), lines 986 to 1030

Searching for text `mixer_ctl_set_array mixer_ctl_set_value implementation`

我继续往前压，不停在分析：这次直接修 `INT` 控件写法，让 `rate ch fmt` 这类 4-word 控件优先走单次 array 写入，并且写完立刻读回校验。

Generating patch (106 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
我先把这次改动编译成新的 `.so`，保证你能直接继续跑。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c), 28 problems found

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_so.sh

结果：

1. 我继续往前调了，不是停在分析。
2. 这次已经生成新的 `libvideo_player.so`。
3. 新产物哈希是：

```text
bffdc357d15ab5c38777b0c82e26e39ac2b564f52577f55373eb6916407c9dbe
```

这次改的核心只有一个：

1. 把 `TDM-LPAIF-RX-SECONDARY rate ch fmt` 这种 `INT values=4` 控件的写法，从“逐项 `set_value`”改成了：
   - 先走一次 `mixer_ctl_set_array`
   - 立刻读回校验
   - 如果 array 写不落，再退回逐项写
   - 如果两种写法都 `rc=0` 但值还是没落下，直接报验证失败

为什么要改这个

你刚贴的日志已经把一个前置问题钉死了：

1. `PCM100 set_int: TDM-LPAIF-RX-SECONDARY rate ch fmt rc=0`
2. 但紧接着读回还是 `v0=0 v1=0 v2=0 v3=0`

也就是说，之前代码存在明显假阳性：

1. 写接口返回成功
2. 但状态根本没进控件
3. 后面继续跑 AGM helper 其实是建立在一个假的前提上

所以这轮不是去碰更后面的 `payload`，而是先把最前面的 `rate ch fmt` 写入语义压实。

你下一轮跑完后，我最关心的不是“有没有声”这一个结果，而是日志里这两类新信息：

1. 有没有出现：
   - `PCM100 set_int array: ...`
2. 有没有出现：
   - `PCM100 set_int verify failed: ...`

如果还失败，那就说明：

1. 当前不是“写法不对”
2. 而是这条 `<intf> rate ch fmt` 控件本身在当前时序/前置条件下就是不吃写入
3. 这样主线会进一步前推到：
   - 先补足某个更早的 graph/session 前置动作
   - 再尝试写 FE/interface 控件

补充一个已经从你这轮日志里确认的结果：

1. 我上轮修的普通 PCM fallback 已经生效了
2. 现在不会再把 `device16/source` 这种“能 open 但首写就炸”的节点误判成成功
3. 你日志里已经明确变成：
   - `PCM probe write: phase=source rc=-1`
   - `打开 PCM 后探测写失败`
   - `普通 PCM 打开全部失败`

这部分已经不是前沿了，当前真正前沿仍然是 AGM FE/interface 控件不落状态。

你现在直接用这个新 `.so` 跑就行。跑完把新日志贴回来，我继续往下压。

Made changes.

User: [INFO][HandleMinuitwrpEvents(701)] MINUITWRP -> OnTouchUp
[INFO][HandleMinuitwrpEvents(701)] MINUITWRP -> OnTouchUp
[swscaler @ 0xb400007d3f1df170] No accelerated colorspace conversion found from yuv420p to rgba.
flutter: [VideoPlayer] 打开成功: 1280x720, 时长: 73560ms, 帧率: 30.0fps
[VideoPlayer] 音频提取完成: /tmp/flutter/vp_audio_2668489792.wav bytes=14123608 ready=1
[VideoPlayer] AGM 构建标记: agm-20260318-direct-probe-v3
[VideoPlayer] AGM 运行时环境: LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/system/lib64:/vendor/lib64:/vendor/lib64/hw
[VideoPlayer] AGM 运行时环境: AGM_BACKEND_CONF_FILE=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: AGM_BACKEND_CONF_PATH=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: BACKEND_CONF_FILE=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: BACKEND_CONF_PATH=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: USECASE_KV_MANAGER_FILE=/odm/etc/usecaseKvManager.xml
[VideoPlayer] AGM 运行时环境: USECASE_KV_MANAGER_PATH=/odm/etc/usecaseKvManager.xml
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libc++.so handle=0x98a24d4d0b48e9ef
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libutils.so handle=0x26f9aced8eefb567
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libcutils.so handle=0xc339f701008105e1
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/liblog.so handle=0x0
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libaudio_log_utils.so handle=0x9a7629470f9372d1
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libsndcardparser.so handle=0x73cd040da3297c2d
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm.so handle=0xbd66da2ecfd650dd
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagmclient.so handle=0xb9df19404f92a0ed
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagmmixer.so handle=0x58233e83f9c2b36f
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm_pcm_plugin.so handle=0x64742de47cd66223
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm_mixer_plugin.so handle=0xd9d06b888a7905a7
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/vendor.qti.hardware.agm-V1-ndk.so handle=0x7d2a6d4be49fa5bb
[VideoPlayer] VideoPlayer FFI build=agm-20260318-direct-probe-v3
[VideoPlayer] start_audio_playback: wav=/tmp/flutter/vp_audio_2668489792.wav start_ms=0
[VideoPlayer] 音频线程启动 path=/tmp/flutter/vp_audio_2668489792.wav
[VideoPlayer] wav 信息: rate=48000 ch=2 bits=16 data=14123608
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=before open_output_pcm setprop rc=0
[VideoPlayer] 音频路由预热: phase=before open_output_pcm mixer rc=0
[VideoPlayer] 临时跳过最小 AGM 直开分支: 当前该分支在 plugin 失败路径会触发 abort，先保留主 AGM 路径调试稳定性
[VideoPlayer] AGM: 归一化 media_config rate=48000 ch=8 bits=32 fmt=0xffffffff
[VideoPlayer] AGM backend 观测: intf=TDM-LPAIF-RX-SECONDARY stream_kv=2701131790 device_kv=2717908993 devicepp_kv=2885681154 instance_kv=65536 rate=48000 ch=8 bits=32
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
[VideoPlayer] AGM direct probe: after device media config before v0=0 v1=0 v2=0 v3=0
[VideoPlayer] PCM100 set_int array: TDM-LPAIF-RX-SECONDARY rate ch fmt rc=0 count=4 total=4
[VideoPlayer] PCM100 set_int verify failed: TDM-LPAIF-RX-SECONDARY rate ch fmt count=4 total=4 rb0=0 rb1=0 rb2=0 rb3=0
[VideoPlayer] AGM direct probe: after device media config write rc=-1 rate=48000 ch=8 bits=32 fmt=0xffffffff
[VideoPlayer] AGM direct probe: after device media config after v0=0 v1=0 v2=0 v3=0
[VideoPlayer] AGM interface 运行态快照: after device media config intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 int: TDM-LPAIF-RX-SECONDARY rate ch fmt values=4 v0=0 v1=0 v2=0 v3=0
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY setParam type=BYTE rc=0 bytes=4096/65536 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY setParam total=65536 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件快照: after device media config
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=0/21 name=ZERO
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=4096/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=4096/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-22 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] PCM100 控件快照: after audio intf metadata
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=0/21 name=ZERO
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=4096/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=4096/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-22 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] AGM interface 运行态快照: after audio intf metadata intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 int: TDM-LPAIF-RX-SECONDARY rate ch fmt values=4 v0=0 v1=0 v2=0 v3=0
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY setParam type=BYTE rc=0 bytes=4096/65536 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY setParam total=65536 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件快照: after stream metadata
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=0/21 name=ZERO
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=4096/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=4096/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-22 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] AGM interface 运行态快照: after stream metadata intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 int: TDM-LPAIF-RX-SECONDARY rate ch fmt values=4 v0=0 v1=0 v2=0 v3=0
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY setParam type=BYTE rc=0 bytes=4096/65536 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY setParam total=65536 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] set_agm_streamdevice_metadata 成功: mode=1 单次调用 kv=2717908993
[VideoPlayer] PCM100 控件快照: after streamdevice metadata
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=4096/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=4096/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] AGM interface 运行态快照: after streamdevice metadata intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 int: TDM-LPAIF-RX-SECONDARY rate ch fmt values=4 v0=0 v1=0 v2=0 v3=0
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY setParam type=BYTE rc=0 bytes=4096/65536 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY setParam total=65536 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] 跳过 speaker raw payload prime: 当前 PCM100 metadata/setParamTag/setParam 原始结构未对齐 agmmixer helper
[VideoPlayer] AGM backend 观测: intf=TDM-LPAIF-RX-SECONDARY stream_kv=2701131790 device_kv=2717908993 devicepp_kv=2885681154 instance_kv=65536 rate=48000 ch=8 bits=32
[VideoPlayer] PCM100 控件快照: after pre-connect agm_mixer_get_miid
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=4096/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=4096/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] agm_mixer_get_miid 失败: phase=after pre-connect agm_mixer_get_miid mode=1 rc=-19 miid=0 tag=3221225476
[VideoPlayer] 跳过 USB custom payload 下发: intf=TDM-LPAIF-RX-SECONDARY mode=1 preconnect_miid=0
[VideoPlayer] PCM100 控件快照: after helper connect
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=4096/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=4096/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] AGM interface 运行态快照: after helper connect intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 int: TDM-LPAIF-RX-SECONDARY rate ch fmt values=4 v0=0 v1=0 v2=0 v3=0
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY setParam type=BYTE rc=0 bytes=4096/65536 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY setParam total=65536 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件快照: after connect settle
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=4096/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=4096/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] AGM interface 运行态快照: after connect settle intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 int: TDM-LPAIF-RX-SECONDARY rate ch fmt values=4 v0=0 v1=0 v2=0 v3=0
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY setParam type=BYTE rc=0 bytes=4096/65536 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY setParam total=65536 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件快照: after agm_mixer_get_miid
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=4096/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=4096/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] agm_mixer_get_miid 失败: phase=after agm_mixer_get_miid mode=1 rc=-19 miid=0 tag=3221225497
[VideoPlayer] AGM interface 运行态快照: after agm_mixer_get_miid intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 int: TDM-LPAIF-RX-SECONDARY rate ch fmt values=4 v0=0 v1=0 v2=0 v3=0
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY setParam type=BYTE rc=0 bytes=4096/65536 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY setParam total=65536 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] MFC tag 尚未解析出 MIID: mode=1，继续尝试无 MFC 直开 PCM
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
[VideoPlayer] AGM: 归一化 media_config rate=48000 ch=8 bits=32 fmt=0xffffffff
mixer_plugin_open: failed to open plugin, err: -12
[VideoPlayer] 打开 AGM mixer 失败: card=100
[VideoPlayer] AGM plugin 打开全部失败，回退普通 PCM
[VideoPlayer] 打开 PCM 失败: card=0 device=16 cfg=backend err=cannot set hw params: Invalid argument
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=pcm probe after open setprop rc=0
[VideoPlayer] 音频路由预热: phase=pcm probe after open mixer rc=0
[VideoPlayer] PCM probe write: phase=source rc=-1 bytes=4096
[VideoPlayer] 打开 PCM 后探测写失败: card=0 device=16 cfg=source err=cannot write initial data: Invalid argument
[VideoPlayer] 打开 PCM 失败: card=0 device=14 cfg=backend err=cannot set hw params: Invalid argument
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=pcm probe after open setprop rc=0
[VideoPlayer] 音频路由预热: phase=pcm probe after open mixer rc=0
[VideoPlayer] PCM probe write: phase=source rc=-1 bytes=4096
[VideoPlayer] 打开 PCM 后探测写失败: card=0 device=14 cfg=source err=cannot write initial data: Invalid argument
[VideoPlayer] 普通 PCM 打开全部失败
[VideoPlayer] 音频线程退出: 输出打开失败
记得持续更新文档

GitHub Copilot: 我先把这轮日志的新结论补进文档尾部，重点记录三件事：`rate ch fmt` 现在已经证明确实写不进去、AGM 前沿从 `-19` 推到了 `-5`、普通 PCM 假成功已经被挡住。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3720-3720), lines 3720 to 3774

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3774-3774), lines 3774 to 3774

文档尾部就是上一轮“allow power”结论，我现在直接接一节，把这轮播放器日志的新边界和已验证有效的代码修正一并补上。

Generating patch (74 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```
文档已经持续更新了，这轮我补进去了。

这次新增的核心结论是：

1. `rate ch fmt` 这条 FE/interface 控件现在已经证明不是“写法问题”
2. 我已经把它改成：
   - 先 `mixer_ctl_set_array`
   - 再立刻读回校验
   - 不行再退回逐项 `set_value`
3. 结果日志明确变成：
   - `set_int array rc=0`
   - 但紧接着 `verify failed`
   - 读回仍然是 `0 0 0 0`

这说明前沿又往前推了一层：

1. 当前不是 `payload` 太后面的问题
2. 也不是 `set_value`/`set_array` 这种写法细节
3. 而是 `set_agm_device_media_config(...)` 之前，播放器还缺某个更早的 graph/session/init 前置动作
4. 连 FE/interface 这一层都没有被真正写起来

另外两点也已经在文档里同步了：

1. `card100/device100` 的失败码这轮从之前常见的 `-19` 推到了 `-5`
   - 说明状态不是完全没动
   - 但仍然没跨过真正可播放的 graph-ready 边界
2. 普通 PCM fallback 现在已经不会再制造假成功
   - 会先做 `probe write`
   - 失败就直接淘汰
   - 这条噪音链现在已经基本清掉了

所以当前主线已经更明确：

1. 不再继续试 `rate ch fmt` 写法
2. 回到 `set_agm_device_media_config(...)` 之前
3. 找 `tinyplay_ftm/agmplay` 还有哪个更早的初始化步骤没被播放器补上

你继续跑新日志给我，我会继续往文档里追着补，不会断。

Made changes.

User: [INFO][HandleMinuitwrpEvents(701)] MINUITWRP -> OnTouchUp
[INFO][HandleMinuitwrpEvents(701)] MINUITWRP -> OnTouchUp
[swscaler @ 0xb400007566b4d120] No accelerated colorspace conversion found from yuv420p to rgba.
flutter: [VideoPlayer] 打开成功: 1280x720, 时长: 73560ms, 帧率: 30.0fps
[VideoPlayer] 音频提取完成: /tmp/flutter/vp_audio_111665312.wav bytes=14123608 ready=1
[VideoPlayer] AGM 构建标记: agm-20260318-direct-probe-v3
[VideoPlayer] AGM 运行时环境: LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/system/lib64:/vendor/lib64:/vendor/lib64/hw
[VideoPlayer] AGM 运行时环境: AGM_BACKEND_CONF_FILE=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: AGM_BACKEND_CONF_PATH=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: BACKEND_CONF_FILE=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: BACKEND_CONF_PATH=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: USECASE_KV_MANAGER_FILE=/odm/etc/usecaseKvManager.xml
[VideoPlayer] AGM 运行时环境: USECASE_KV_MANAGER_PATH=/odm/etc/usecaseKvManager.xml
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libc++.so handle=0x54f57964ffedbc9d
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libutils.so handle=0xc6e3cc916954fb55
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libcutils.so handle=0x8e7ca1efd5d66a1b
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/liblog.so handle=0x0
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libaudio_log_utils.so handle=0x256a9ab770000d07
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libsndcardparser.so handle=0x2081a9ecb6c439b
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm.so handle=0x49a0573a603a13d1
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagmclient.so handle=0xd77491409a80a77b
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagmmixer.so handle=0x9486b72331416d25
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm_pcm_plugin.so handle=0x6e43bcf207db97a7
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm_mixer_plugin.so handle=0xf0f6a79daf7bc2b5
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/vendor.qti.hardware.agm-V1-ndk.so handle=0x707ea80318bb492b
[VideoPlayer] VideoPlayer FFI build=agm-20260318-direct-probe-v3
[VideoPlayer] start_audio_playback: wav=/tmp/flutter/vp_audio_111665312.wav start_ms=0
[VideoPlayer] 音频线程启动 path=/tmp/flutter/vp_audio_111665312.wav
[VideoPlayer] wav 信息: rate=48000 ch=2 bits=16 data=14123608
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=before open_output_pcm setprop rc=0
[VideoPlayer] 音频路由预热: phase=before open_output_pcm mixer rc=0
[VideoPlayer] 临时跳过最小 AGM 直开分支: 当前该分支在 plugin 失败路径会触发 abort，先保留主 AGM 路径调试稳定性
[VideoPlayer] AGM: 归一化 media_config rate=48000 ch=8 bits=32 fmt=0xffffffff
[VideoPlayer] AGM backend 观测: intf=TDM-LPAIF-RX-SECONDARY stream_kv=2701131790 device_kv=2717908993 devicepp_kv=2885681154 instance_kv=65536 rate=48000 ch=8 bits=32
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
[VideoPlayer] AGM direct probe: after device media config before v0=0 v1=0 v2=0 v3=0
[VideoPlayer] PCM100 set_int array: TDM-LPAIF-RX-SECONDARY rate ch fmt rc=0 count=4 total=4
[VideoPlayer] PCM100 set_int verify failed: TDM-LPAIF-RX-SECONDARY rate ch fmt count=4 total=4 rb0=0 rb1=0 rb2=0 rb3=0
[VideoPlayer] AGM direct probe: after device media config write rc=-1 rate=48000 ch=8 bits=32 fmt=0xffffffff
[VideoPlayer] AGM direct probe: after device media config after v0=0 v1=0 v2=0 v3=0
[VideoPlayer] AGM interface 运行态快照: after device media config intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 int: TDM-LPAIF-RX-SECONDARY rate ch fmt values=4 v0=0 v1=0 v2=0 v3=0
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY setParam type=BYTE rc=0 bytes=4096/65536 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY setParam total=65536 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件快照: after device media config
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=0/21 name=ZERO
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=4096/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=4096/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-22 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] PCM100 控件快照: after audio intf metadata
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=0/21 name=ZERO
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=4096/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=4096/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-22 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] AGM interface 运行态快照: after audio intf metadata intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 int: TDM-LPAIF-RX-SECONDARY rate ch fmt values=4 v0=0 v1=0 v2=0 v3=0
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY setParam type=BYTE rc=0 bytes=4096/65536 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY setParam total=65536 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件快照: after stream metadata
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=0/21 name=ZERO
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=4096/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=4096/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-22 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] AGM interface 运行态快照: after stream metadata intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 int: TDM-LPAIF-RX-SECONDARY rate ch fmt values=4 v0=0 v1=0 v2=0 v3=0
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY setParam type=BYTE rc=0 bytes=4096/65536 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY setParam total=65536 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] set_agm_streamdevice_metadata 成功: mode=1 单次调用 kv=2717908993
[VideoPlayer] PCM100 控件快照: after streamdevice metadata
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=4096/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=4096/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] AGM interface 运行态快照: after streamdevice metadata intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 int: TDM-LPAIF-RX-SECONDARY rate ch fmt values=4 v0=0 v1=0 v2=0 v3=0
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY setParam type=BYTE rc=0 bytes=4096/65536 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY setParam total=65536 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] 跳过 speaker raw payload prime: 当前 PCM100 metadata/setParamTag/setParam 原始结构未对齐 agmmixer helper
[VideoPlayer] AGM backend 观测: intf=TDM-LPAIF-RX-SECONDARY stream_kv=2701131790 device_kv=2717908993 devicepp_kv=2885681154 instance_kv=65536 rate=48000 ch=8 bits=32
[VideoPlayer] PCM100 控件快照: after pre-connect agm_mixer_get_miid
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=4096/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=4096/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] agm_mixer_get_miid 失败: phase=after pre-connect agm_mixer_get_miid mode=1 rc=-19 miid=0 tag=3221225476
[VideoPlayer] 跳过 USB custom payload 下发: intf=TDM-LPAIF-RX-SECONDARY mode=1 preconnect_miid=0
[VideoPlayer] PCM100 控件快照: after helper connect
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=4096/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=4096/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] AGM interface 运行态快照: after helper connect intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 int: TDM-LPAIF-RX-SECONDARY rate ch fmt values=4 v0=0 v1=0 v2=0 v3=0
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY setParam type=BYTE rc=0 bytes=4096/65536 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY setParam total=65536 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件快照: after connect settle
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=4096/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=4096/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] AGM interface 运行态快照: after connect settle intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 int: TDM-LPAIF-RX-SECONDARY rate ch fmt values=4 v0=0 v1=0 v2=0 v3=0
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY setParam type=BYTE rc=0 bytes=4096/65536 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY setParam total=65536 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 控件快照: after agm_mixer_get_miid
[VideoPlayer] PCM100 控件摘要: COMPRESS100 controls absent
[VideoPlayer] PCM100 enum: PCM100 control current=11/21 name=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 get_array: PCM100 metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParam type=BYTE rc=0 bytes=4096/1048576 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParam total=1048576 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 setParamTag type=BYTE rc=0 bytes=4096/262144 first=00 00 00 00
[VideoPlayer] PCM100 array: PCM100 setParamTag total=262144 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: PCM100 getTaggedInfo type=BYTE rc=-19 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 enum: PCM100 connect current=0/21 name=ZERO
[VideoPlayer] PCM100 enum: PCM100 disconnect current=0/21 name=ZERO
[VideoPlayer] agm_mixer_get_miid 失败: phase=after agm_mixer_get_miid mode=1 rc=-19 miid=0 tag=3221225497
[VideoPlayer] AGM interface 运行态快照: after agm_mixer_get_miid intf=TDM-LPAIF-RX-SECONDARY
[VideoPlayer] PCM100 int: TDM-LPAIF-RX-SECONDARY rate ch fmt values=4 v0=0 v1=0 v2=0 v3=0
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY metadata type=BYTE rc=0 bytes=1024/1024 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY metadata total=1024 scanned=1024 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] PCM100 get_array: TDM-LPAIF-RX-SECONDARY setParam type=BYTE rc=0 bytes=4096/65536 first=00 00 00 00
[VideoPlayer] PCM100 array: TDM-LPAIF-RX-SECONDARY setParam total=65536 scanned=4096 nonzero=0 first_nonzero=none/0 w0=00000000 w1=00000000 w2=00000000 w3=00000000
[VideoPlayer] MFC tag 尚未解析出 MIID: mode=1，继续尝试无 MFC 直开 PCM
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
[VideoPlayer] AGM: 归一化 media_config rate=48000 ch=8 bits=32 fmt=0xffffffff
mixer_plugin_open: failed to open plugin, err: -12
[VideoPlayer] 打开 AGM mixer 失败: card=100
[VideoPlayer] AGM plugin 打开全部失败，回退普通 PCM
[VideoPlayer] 打开 PCM 失败: card=0 device=16 cfg=backend err=cannot set hw params: Invalid argument
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=pcm probe after open setprop rc=0
[VideoPlayer] 音频路由预热: phase=pcm probe after open mixer rc=0
[VideoPlayer] PCM probe write: phase=source rc=-1 bytes=4096
[VideoPlayer] 打开 PCM 后探测写失败: card=0 device=16 cfg=source err=cannot write initial data: Invalid argument
[VideoPlayer] 打开 PCM 失败: card=0 device=14 cfg=backend err=cannot set hw params: Invalid argument
[VideoPlayer] property vendor.oplus.mm.ftm_spk=1 rc=0
[VideoPlayer] 音频路由预热: phase=pcm probe after open setprop rc=0
[VideoPlayer] 音频路由预热: phase=pcm probe after open mixer rc=0
[VideoPlayer] PCM probe write: phase=source rc=-1 bytes=4096
[VideoPlayer] 打开 PCM 后探测写失败: card=0 device=14 cfg=source err=cannot write initial data: Invalid argument
[VideoPlayer] 普通 PCM 打开全部失败
[VideoPlayer] 音频线程退出: 输出打开失败


GitHub Copilot: 我不在原地复述日志，直接往前推进：先确认 `tinyplay_ftm` 成功链到底是走 `agmservice/libagm` 还是 `agmmixer/controlC100`，如果前者成立，当前代码主线就该切掉一整条错误方向。

Ran terminal command:  adb -s 70a91f89 shell 'strings /odm/bin/tinyplay_ftm | grep -E "agm_session|graph_open|graph_start|set_agm_|device_media_config|streamdevice|connect_agm|get_miid|configure_mfc" | head -n 120'

Ran terminal command:  adb -s 70a91f89 shell 'for so in /vendor/lib64/libagm.so /vendor/lib64/libagmclient.so /vendor/lib64/libagmmixer.so; do echo === $so ===; nm -D $so 2>/dev/null | grep -E " graph_|agm_|session|stream|metadata|connect|miid|mfc" | head -n 120; done'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -i -E "agm_session_aif_connect|graph_open|graph_start|IAGM|AgmIpc|agmservice|palservice|tinyplay_ftm" | tail -n 120'

日志抽取结果比较长，我只读关键片段，看 `tinyplay_ftm` 成功链是否带有 session/connect 级证据。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_58i1XcHLwl2D8rQtDJRbe8zN__vscode-1773775025609/content.txt)

这轮日志给了一个真正有价值的新证据：`tinyplay_ftm` 成功链里已经明确出现了 `AgmIpc::Client` 和 `agm_session_aif_connect`。我现在直接沿这条线查可调用符号，准备把主线从 `agmmixer` 控件编排切到 `libagm`/service 编排。

Ran terminal command:  adb -s 70a91f89 shell 'for so in /vendor/lib64/libagm.so /vendor/lib64/libagmclient.so; do echo === $so ===; readelf -Ws $so 2>/dev/null | grep -E "agm_session|session_aif|graph_open|graph_start|agm_init|agm_open|agm_audio_intf|set_agm|metadata|device_config" | head -n 200; done'

Ran terminal command:  adb -s 70a91f89 shell 'for so in /vendor/lib64/libagm.so /vendor/lib64/libagmclient.so; do echo === $so ===; strings $so | grep -E "agm_session_|graph_open|graph_start|aif_connect|device_config|usecase|session_open|session_prepare|session_start|set_params" | head -n 200; done'

Ran terminal command:  adb -s 70a91f89 shell 'strings /odm/bin/tinyplay_ftm | grep -E "agm_session_|graph_open|graph_start|aif_connect|device_media_config|set_agm_group_device_config|session_prepare|session_start|set_params" | head -n 200'

现在主线已经很明确了：`tinyplay_ftm` 成功链不是靠 `agmmixer + controlC100`，而是走 `AgmIpc/libagm` 的 session API。我先把工作区里的 AGM 头文件/结构体找出来，准备直接切代码路径。

Searching for regex `agm_session_open|agm_session_aif_connect|agm_session_set_config|agm_session_prepare|agm_session_start|agm_session_write` (`**/*.{h,c,cpp,cc,md}`)

Searched for files matching `**/*agm*.h`, 120 matches

Read memory twrp_audio_agmplay_minimal_success.md

工作区检索太大，我改用 `rg` 直接扫源树里的 AGM 头文件和结构体，目标是把 `libagmclient` 这条 session API 真正接进播放器。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && rg --files | rg '/agm.*\.h$|/.*agm.*\.h$|/pal.*\.h$' | head -n 200

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && rg -n "agm_session_open|agm_session_aif_connect|agm_session_set_config|agm_session_prepare|agm_session_start|agm_session_write" twrp_a16_compile aurora_recovery/twrp_a16_compile 2>/dev/null | head -n 200

我只读最前面的命中，先拿到 AGM 头文件和关键 API 声明位置。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_RyNACNrhJg4o8CGDcK7oU3wR__vscode-1773775025617/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_NczHkwmQaO8DY0PZevMu0pou__vscode-1773775025618/content.txt#1-1), lines 1 to 220

Compacted conversation工作面已经收敛了：仓库里没现成 AGM 头，下一步直接去外部源码和本地构建目录里找 `agm_session_*` 的声明与调用样例。Optimizing tool selection...

Ran terminal command:  cd /Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery && rg -n "agm_session_open|agm_session_aif_connect|agm_session_set_config|agm_session_prepare|agm_session_start|agm_session_write|agm_session_config" .
Completed with input:  cd /Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery && rg -n "agm_session_open|agm_session_aif_connect|agm_session_set_config|agm_session_prepare|agm_session_start|agm_session_write|agm_session_config" .

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP && rg -n "struct agm_session_config|typedef struct agm_session_config|agm_session_open\(|agm_session_aif_connect\(" twrp_a16_compile device_tree android_vendor_twrp aurora_recovery
Completed with input:  cd /Volumes/Case-sensitive\ APFS/TWRP && rg -n "struct agm_session_config|typedef struct agm_session_config|agm_session_open\(|agm_session_aif_connect\(" twrp_a16_compile device_tree android_vendor_twrp aurora_recovery

源码树里没有现成声明，意味着要么手写最小原型并走 `dlopen/dlsym`，要么从设备库反推出结构。先检查现有播放器里对 AGM 动态加载的封装，再决定最小改动路径。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1-1), lines 1 to 320

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/build_so.sh)

现有代码已经是动态装载风格，这样可以直接接 AGM session API，不需要等头文件。接下来我读 AGM 装载和输出打开路径，按最小侵入补一条 session 路径。

Searched for regex `load_agm_mixer|load_tinyalsa|open_output_pcm|open_agm_output|write_output_stream|dlopen|dlsym` (`**/video_player/video_player_ffi.c`), 51 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#320-320), lines 320 to 980

我先把 AGM 打开、写入、关闭三段读全，确认能否无缝插入 session backend，而不影响现在的 PCM fallback。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#2360-2360), lines 2360 to 2735

Searched for regex `close_output_stream|OUTPUT_BACKEND_AGM_PLUGIN|OUTPUT_BACKEND_AGM_PCM|OUTPUT_BACKEND_PCM` (`**/video_player/video_player_ffi.c`), 19 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1828-1828), lines 1828 to 1878

如果能拿到公开 AGM 头，session 路径就能少走很多试错。我先直接抓 Qualcomm 开源 AGM 头和示例，不再盲猜结构体布局。





Fetched 3 resources

Fetched 2 resources

我补读仓库记忆，确认之前有没有已经验证过的 AGM 前置条件，避免重复踩已经排除的坑。

Read memory twrp_audio_helper_timing_delta_20260317.md

Read memory twrp_audio_manual_playback.md

Read memory twrp_audio_standard_path_priority.md

Read memory twrp_audio_userspace_hal_gap.md

目前两条路里，低风险的是先把 session API 原型查准，而不是直接瞎写结构体。我要去公开镜像和本机缓存里找 `agm_api.h`，只要拿到声明就可以安全落地。

Ran terminal command:  find ~/Library -name agm_api.h 2>/dev/null | head -n 20

Ran terminal command:  curl -L --max-time 15 https://raw.githubusercontent.com/search?q=agm_session_open+agm_session_aif_connect&type=code | head

我先从设备日志把 `tinyplay_ftm` 的 AGM API 调用序列抽出来，至少拿到顺序、`session id`、`aif id` 和有没有 `set_config/prepare/start/write`。这个比继续猜更划算。

Ran terminal command:  adb -s 70a91f89 logcat -d | rg "agm_session_|AgmIpc::|tinyplay_ftm|graph_open|graph_start" | tail -n 300

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_x9rewj2iLvYXZf0K26oCJV9R__vscode-1773775025638/content.txt)

历史日志太脏了，我直接清空 logcat 跑一次基线命令，只抓这一轮的 AGM 调用链。

Ran terminal command:  adb -s 70a91f89 logcat -c && adb -s 70a91f89 shell 'setprop vendor.oplus.mm.ftm_spk 1; /odm/bin/tinyplay_ftm /data/local/tmp/test440_mid_10s.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY >/dev/null 2>&1' && adb -s 70a91f89 logcat -d | rg "agm_session_|AgmIpc::|tinyplay_ftm|graph_open|graph_start|aif_connect|session id|aifid"

日志给了一个更小的切入点：成功路径里最确定的调用就是 `agm_session_aif_connect(session=100, aif=16, connect=1)`，而我们现在走的是 `agmmixer connect_agm_audio_intf_to_stream`。我准备先补一条极小改动的 `libagmclient` connect 路径，验证是不是“控制面 API 用错了”。

Searched for regex `prepare_agm_pcm_route|connect_agm_audio_intf_to_stream|agm_mixer_get_miid|set_agm_streamdevice_metadata` (`**/video_player/video_player_ffi.c`), 28 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1880-1880), lines 1880 to 2365

我要做的改动很小：新增 `libagmclient.so` 动态装载，只接一颗 `agm_session_aif_connect`，并在现有 AGM 准备流程里优先用它做 connect/disconnect，失败再回退原来的 `agmmixer` helper。这样能直接验证“是不是 connect API 层用错了”。

Generating patch (178 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
改动已经落下，我现在直接编译新的 `.so`，先看这条最小 session-connect 试探能不能稳定过编译。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c), 28 problems found

Ran terminal command:  cd /Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player && ./build_so.sh

`.so` 已经编好。我补一段文档，记录这次 pivot 不是“大改 AGM”，而是先把 connect 控制面从 `agmmixer` 切到 `libagmclient` 试探。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#1-1), lines 1 to 260

Ran terminal command:  shasum -a 256 libvideo_player.so

Ran terminal command:  tail -n 80 '/Volumes/Case-sensitive APFS/TWRP/docs/TWRP音频手动Bring-up.md'

Generating patch (46 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)

文档补丁第一次没对上上下文，我先读精确尾部行号后再追加，避免误伤现有记录。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#520-520), lines 520 to 620

Ran terminal command:  wc -l '/Volumes/Case-sensitive APFS/TWRP/docs/TWRP音频手动Bring-up.md'

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3760-3760), lines 3760 to 3841

Generating patch (46 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```
结果：

1. 已把播放器 AGM 控制面的 connect/disconnect 先切到 `libagmclient.so` 试探。
2. 具体行为是：
   - 优先调用 `agm_session_aif_connect(session=100, aif=16, connect=1)`
   - 关闭时优先调用 `agm_session_aif_connect(..., connect=0)`
   - 如果 session API 失败，再回退原来的 `agmmixer` helper
3. 这次没有去瞎猜 `agm_session_config`，所以改动风险可控，目标是单独验证“是不是 connect 这一层 API 用错了”。

产物：
1. 新 `libvideo_player.so` 已编译完成
2. SHA256: `787350f56aef052a1b014a71e8879de76f1335916d51d930ddcacb3817aae62f`

文档：
1. 已追加本轮结论和新哈希

当前结论：
1. vendor 成功链里已确认存在 `agm_session_aif_connect(session id=100, aifid=16)`
2. 播放器现在也开始对齐这一层
3. 还没有新的设备实跑日志，所以暂时不能证明已经出声，也不能证明 FE/interface 已开始落状态

下一步只需要你跑新库，然后把这一轮播放器日志里这几类结果给我：
1. `agm_session_aif_connect rc=`
2. connect 之后的 `<interface> rate ch fmt / metadata / setParam`
3. `PCM100` / `MIID` / `tagged-info` 是否有变化

Made changes.


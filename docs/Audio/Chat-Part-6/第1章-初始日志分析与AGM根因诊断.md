# 第1章：初始日志分析与AGM根因诊断

User: [INFO][HandleMinuitwrpEvents(701)] MINUITWRP -> OnTouchUp
[INFO][HandleMinuitwrpEvents(701)] MINUITWRP -> OnTouchUp
[swscaler @ 0xb400007dea930110] No accelerated colorspace conversion found from yuv420p to rgba.
[VideoPlayer] 音频提取完成: /tmp/flutter/vp_audio_2055549536.wav bytes=14123608 ready=1
flutter: [VideoPlayer] 打开成功: 1280x720, 时长: 73560ms, 帧率: 30.0fps
[VideoPlayer] AGM 构建标记: agm-20260317-media-config-v2
[VideoPlayer] AGM 运行时环境: LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/system/lib64:/vendor/lib64:/vendor/lib64/hw
[VideoPlayer] AGM 运行时环境: AGM_BACKEND_CONF_FILE=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: AGM_BACKEND_CONF_PATH=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: BACKEND_CONF_FILE=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: BACKEND_CONF_PATH=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: USECASE_KV_MANAGER_FILE=/odm/etc/usecaseKvManager.xml
[VideoPlayer] AGM 运行时环境: USECASE_KV_MANAGER_PATH=/odm/etc/usecaseKvManager.xml
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libc++.so handle=0x53f66d9f202916c9
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libutils.so handle=0xf9defa3a84a5bfa7
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libcutils.so handle=0x54100a5ee05ad22f
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/liblog.so handle=0x0
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libaudio_log_utils.so handle=0x491b3673bd99387
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libsndcardparser.so handle=0x144f084944831f6b
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm.so handle=0x254b40609359b975
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagmclient.so handle=0xa1f4a2dcad44aebd
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagmmixer.so handle=0xbe43821c36f0e2cb
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm_pcm_plugin.so handle=0xee0ad30fb32bbf8d
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm_mixer_plugin.so handle=0xecba111bf8a250b7
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/vendor.qti.hardware.agm-V1-ndk.so handle=0x93926518ebd3ee47
[VideoPlayer] VideoPlayer FFI build=agm-20260317-media-config-v2
[VideoPlayer] start_audio_playback: wav=/tmp/flutter/vp_audio_2055549536.wav start_ms=0
[VideoPlayer] 音频线程启动 path=/tmp/flutter/vp_audio_2055549536.wav
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
[VideoPlayer] AGM: 归一化 media_config rate=48000 ch=8 bits=32 fmt=0xffffffff
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


GitHub Copilot: 我先把这段日志按阶段拆开，对照仓库里现有 AGM/TinyALSA 代码和已记录结论，确认失败点到底是在元数据、MIID、plugin 打开，还是后备 PCM 参数不匹配。

Read memory twrp_audio_agmmixer_helper_semantics.md

Read memory twrp_audio_pcm100_setparamtag.md

Read memory twrp_audio_standard_path_priority.md

Search complete: 定位 AGM 播放代码

Searched codebase for "VideoPlayer AGM audio playback start_audio_playback open_output_pcm agm_mixer_get_miid pcm_write retry fallback normal PCM card device config", 14 results

Searched for regex `start_audio_playback|open_output_pcm|agm_mixer_get_miid|pcm_write|retry|AGM|VideoPlayer` (`**/*.{c,cc,cpp,h,hpp,java,kt,mk,xml,txt,log}`), 200 results

Searched for regex `static int open_output_pcm|open_output_pcm\(|start_audio_playback\(|pcm_write\(|retry|回退|fallback|普通 PCM|tinyalsa|backend =|OUTPUT_BACKEND_` (`**/video_player_ffi.c`), 191 results

Searched for regex `AGM plugin|plugin 失败|plugin失败|agm_pcm_plugin_open|open_output_pcm|pcm_open|pcm_is_ready|pcm_get_error|卡|device|card=|device=` (`**/video_player_ffi.c`), 200 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#230-230), lines 230 to 320

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1800-1800), lines 1800 to 2435

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#2460-2460), lines 2460 to 2710

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#2945-2945), lines 2945 to 2995

我已经拿到控制流了。下一步直接核对仓库内实现与这份日志是否一致，并判断这次失败更像是 AGM graph 没真正建成，还是 fallback PCM 的硬件参数和设备 16 不匹配。

Searched for files matching `**/video_player_ffi.c`, no matches

Searching for regex `AGM plugin 打开全部失败|pcm_write 首次失败|set_agm_streamdevice_metadata 成功|agm_mixer_get_miid 失败` (`**/*.{c,cc,cpp,h,md}`)

Read memory twrp_audio_agmplay_minimal_success.md

Read memory twrp_audio_manual_playback.md

外部检索到的实现路径不在当前工作区，所以我不做代码修改假设。再补一轮工作区内搜索，确认这里是否有同名实现或文档记录，然后给出可执行的根因判断。

Searched for text `start_audio_playback` (`**/*.{c,cc,cpp,h,md,txt}`), 9 results

Searched for text `VideoPlayer` (`**/*.{c,cc,cpp,h,md,txt,dart}`), 50 results

Read memory twrp_audio_helper_timing_delta_20260317.md

Read memory twrp_audio_userspace_hal_gap.md

控制流已经对上日志了。现在只读关键段，确认 fallback 的设备号、参数组合和重试逻辑是不是正好解释你看到的 Invalid argument。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#2315-2315), lines 2315 to 2565

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1800-1800), lines 1800 to 2108

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#2636-2636), lines 2636 to 2705

结论已经比较清楚了：这不是“最后一层扬声器 mixer 没补够”，而是 AGM graph 根本没立起来，后面的普通 PCM 只是误打误撞打开了一个能 `open` 不能 `write` 的节点。我再补一条仓库经验，看它和这次现象是否完全一致。

Read memory twrp_audio_component_gap.md

Read memory twrp_audio_runtime_defer.md

Read memory twrp_audio_reprobe.md

结论

这次失败分成两层，而且主因已经很明确：

1. AGM 主路径没有真正把 graph/session 建起来。
2. 回退到普通 PCM 后，又停在了一个“能 open 但不能 write”的假成功节点上。

关键判断

1. 视频侧是正常的
- 音频提取完成
- 视频打开成功
- swscaler 那条 yuv420p -> rgba 警告和出声失败无关

2. AGM 运行环境不是当前问题
- `LD_LIBRARY_PATH`、`backend_conf.xml`、`usecaseKvManager.xml` 都已经设了
- `libagm.so`、`libagmclient.so`、`libagmmixer.so`、`libagm_pcm_plugin.so` 都能 `dlopen`
- 所以这不是“库没加载起来”的级别

3. AGM helper 虽然返回成功，但状态没有真正下沉
从你这段日志里，最关键的不是 `set_agm_streamdevice_metadata 成功`，而是成功之后所有观测面基本都还是空的：

- `<interface> rate ch fmt` 读回全 0
- `<interface> metadata` 全 0
- `<interface> setParam` 全 0
- `PCM100 metadata` 全 0
- `PCM100 setParam` 全 0
- `PCM100 setParamTag` 全 0

这说明当前播放器代码里那套 helper 调用序列，至少在这台 recovery 环境里，没有把 FE/interface 和 PCM100 的运行态真正立起来。返回码是 0，不代表 graph 已经可用。

4. `agm_mixer_get_miid` 两次失败，说明 graph 根本没开出来
你这里有两次关键失败：

- pre-connect 查 `tag=0xC0000004`，返回 `rc=-19`
- post-connect 查 `tag=0xC0000019`，还是 `rc=-19`

这比 “MFC 没配好” 更早。因为连 connect 前后的 tagged MIID 都拿不到，说明 session / graph 并没有进入 agmplay 那种可工作状态。

已知仓库里的经验也和这个完全一致：
- 真正能成功的 `agmplay` 最小命令是 `-D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY`
- 一旦 instance/graph 落点不对，就会退化成 `graph_open ret -19`

你现在这条播放器路径，本质上也正卡在这个层级。

5. AGM plugin 失败是结果，不是根因
后面这些失败是一串连锁反应：

- `AGM PCM open ... Unknown error -19`
- `agm_pcm_plugin_open ... rc=-19/-32/-22`
- `mixer_plugin_open ... err: -12`

它们都指向同一个事实：card 100 / device 100 这条 AGM 图没有被准备成可写状态。

如果 graph 没起来，plugin open 失败是自然结果，不是另一个独立根因。

6. 普通 PCM fallback 也有实现问题
回退后日志是：

- `card=0 device=16 cfg=backend` 打不开，`Invalid argument`
- `card=0 device=16 cfg=source` 能打开，`48000/2/16`
- 但第一次 `pcm_write` 就失败
- 补 speaker mixer 后重试，还是 `Invalid argument`

这说明：
- `device 16 + 2ch/16bit source config` 这个节点不是真正稳定可写的输出路径
- 现在的 fallback 逻辑把“open 成功”当成“输出可用”，这个判断太早了

按当前实现，它在普通 PCM 路径里是先枚举设备 `16, 14`，每个设备先试 `backend(8ch/32)`，再试 `source(2ch/16)`。一旦 `open` 成功就直接返回，不会做首包可写性验证。于是它卡在了 `device 16 source` 这个假阳性上，根本没机会继续尝试别的设备或配置。

所以这层问题也是真实存在的，但它是次因。

归因排序

按优先级排，当前问题应该这样看：

1. AGM 控制面/graph 建立失败
- 这是主因
- 证据是 helper 后状态仍全零，MIID 查不到，AGM open/plugin 全挂

2. 普通 PCM fallback 过早认定成功
- 这是次因
- 证据是 `open` 成功但首个 `pcm_write` 立即 `EINVAL`

3. 扬声器 mixer 不是当前前沿
- 你已经在 `before open_output_pcm`、`after open_output_pcm`、`pcm_write retry` 都做了 speaker 路由预热
- 如果只是功放开关没补够，前面 AGM 通常不会表现成“所有 metadata / setParam / MIID 都空”
- 所以这次不是“再补几条 tinymix 就能通”的阶段

我建议的下一步

1. 先修 fallback 判定
- 不要把 `pcm_open + pcm_is_ready` 当成成功
- 普通 PCM 路径里应在返回前做一次小块探测写入
- 如果首写失败，就关闭当前 pcm，继续试下一个 device/config
- 按你这次日志，至少不能停在 `card0/device16/source(48k/2ch/16)` 这个节点上

这一步能解决“假成功导致后续不再探测”的问题，属于应该立刻修的实现缺陷。

2. AGM 路径不要再把“helper 返回 0”当成图已建成
建议把 AGM 成功条件收紧成至少满足下面之一：
- `agm_mixer_get_miid` 能拿到非零 MIID
- AGM plugin/open 真正成功
- 某个关键运行态控件出现非零变化

否则就应明确判定为 AGM graph 未建立，直接走后续策略，不要继续把这条路径当作已准备完成。

3. 接下来要对比的不是 PCM 参数，而是 agmplay 的建图语义
从仓库已有记录看，`agmplay` 最小成功路径已经存在，而且它能稳定 `graph_open ret 0`、`graph_start ret 0`。所以现在最该比对的是：

- instance_kv 的最终落点
- helper 调用顺序是否真的和 `agmplay` 一致
- 是否缺少某个 graph/session 打开前置动作
- 是否存在 recovery 下必须依赖的服务链时序差异

不是继续在 `48k/8ch/32`、`2ch/16` 这种 PCM 参数上反复试。

一句话收口

这份日志不是“快通了，只差 speaker mixer 一脚”，而是：
- AGM 图没起来
- fallback 又被一个假阳性 PCM 节点截住了

如果你要，我下一步可以直接帮你整理成两个最小代码改动点：
1. 普通 PCM fallback 改成“首包写成功后才算成功”
2. AGM 路径改成“拿不到 MIID/关键状态不变就判失败，不再把 helper rc=0 当成功”

User: 你并没有更新文档

GitHub Copilot: 我先读取当前文档内容，定位应该补进哪一段，然后直接把这次日志结论整理进去。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#1-1), lines 1 to 260

Searched for regex `VideoPlayer|AGM|pcm_write|fallback|回退普通 PCM|MIID` (`**/docs/TWRP音频手动Bring-up.md`), 50 results

我已经定位到文档后半段的 AGM/播放器分析区，现在读取尾部相关段落，把这次新结论接在合适位置，避免重复覆盖旧结论。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#2660-2660), lines 2660 to 2855

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs)

我已经找到 AGM 分析章节，准备直接补一个新小节，专门记录这次 VideoPlayer FFI 日志把问题进一步收敛到哪一层，以及为什么普通 PCM fallback 现在会误判成功。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#2856-2856), lines 2856 to 2955

Searched for regex `13\.29|VideoPlayer FFI|普通 PCM fallback|假成功|card=0 device=16` (`**/docs/TWRP音频手动Bring-up.md`), 3 results

我再看一下文档尾部，确保新段落接在最新进展之后，不把后面的内容盖掉。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#2956-2956), lines 2956 to 3065

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3066-3066), lines 3066 to 3145

文档后面还有后续小节，我直接把新结论追加到最新位置后面，保持编号连续，不去打乱现有结构。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3146-3146), lines 3146 to 3260

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3261-3261), lines 3261 to 3385

我只再读最后一小段，用文件尾部作为补丁锚点，然后直接追加。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3386-3386), lines 3386 to 3455

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3456-3456), lines 3456 to 3525

补丁位置已经够明确了，我再读到文件末尾，避免把新段落插到半截。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3526-3526), lines 3526 to 3605

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3606-3606), lines 3606 to 3647

我现在直接把这轮 VideoPlayer FFI 的新结论补到文档尾部，重点写三件事：新库已真正部署、AGM graph 仍未建成、普通 PCM fallback 存在假成功。

Generating patch (75 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```
已经补进文档了。

这次新增的是 13.48，内容集中记录了三点：

1. 新版 VideoPlayer FFI 库这次已经真正部署到设备上
2. AGM 主路径仍然没把 graph 和 MIID 建起来，plugin 和 card100 打开失败只是后果
3. 普通 PCM fallback 现在存在“能 open 但首个 pcm_write 就失败”的假成功问题

如果你要，我下一步可以继续把文档里的“后续动作”再细化成可执行 checklist，把代码侧该改的两点单独列出来。

Made changes.

User: 你是不是可以用strace抓一下tinyplay_ftm agmplay调用的api

GitHub Copilot: 我先确认当前设备连接状态，以及 recovery 里有没有 `strace` / `toybox strace` 这类可直接用的跟踪工具，再判断这条路能不能落地。

Ran terminal command:  adb devices

Ran terminal command:  command -v adb

设备已经在 recovery，下一步直接看 `strace` 是否存在，以及能不能附着到 `tinyplay_ftm` 这类进程。

Ran terminal command:  adb shell 'command -v strace; toybox --list 2>/dev/null | grep -x strace || true; busybox 2>/dev/null | grep -i strace || true'

Ran terminal command:  adb shell 'id; getenforce 2>/dev/null || true'

可以，但先把边界说清楚：`strace` 抓的是 syscall，不是 `libagmmixer.so` / `libagm.so` 这种用户态 API 调用栈；它更适合看 `openat`、`ioctl`、`mmap`、`binder`、`read/write`，能帮我们侧面还原它们碰了哪些设备、配置文件和驱动节点。

Ran terminal command:  adb shell 'ls /odm/bin/tinyplay_ftm /vendor/bin/agmplay /data/local/tmp/test440_low.wav 2>/dev/null'

Ran terminal command:  adb shell 'strace -V 2>&1 | head -n 1'

我直接跑一轮轻量 strace，把 `agmplay` 和 `tinyplay_ftm` 的 syscall 级行为落到设备文件里，然后抽关键行看它们实际碰了哪些配置、设备节点和服务接口。

Ran terminal command:  adb shell 'rm -f /data/local/tmp/agmplay.strace /data/local/tmp/agmplay.out && strace -f -tt -s 120 -o /data/local/tmp/agmplay.strace /vendor/bin/agmplay /data/local/tmp/test440_low.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY >/data/local/tmp/agmplay.out 2>&1'

Ran terminal command:  adb shell 'rm -f /data/local/tmp/tinyplay_ftm.strace /data/local/tmp/tinyplay_ftm.out && setprop vendor.oplus.mm.ftm_spk 1 && strace -f -tt -s 120 -o /data/local/tmp/tinyplay_ftm.strace /odm/bin/tinyplay_ftm /data/local/tmp/test440_low.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY >/data/local/tmp/tinyplay_ftm.out 2>&1'

两份 trace 已经生成。我现在不去整份生搬，而是只筛最有价值的几类调用：配置文件、共享库、`/dev/snd`、以及可能暴露 graph/服务交互的 `ioctl`/binder 入口。

Ran terminal command:  adb shell 'tail -n 20 /data/local/tmp/agmplay.out; tail -n 20 /data/local/tmp/tinyplay_ftm.out'

Ran terminal command:  adb shell 'grep -E "backend_conf|usecaseKvManager|agm|pal|/dev/snd|binder|pcmC|controlC|libagm|libagmmixer|libtinyalsa" /data/local/tmp/agmplay.strace | head -n 120'

Ran terminal command:  adb shell 'grep -E "backend_conf|usecaseKvManager|agm|pal|/dev/snd|binder|pcmC|controlC|libagm|libagmmixer|libtinyalsa" /data/local/tmp/tinyplay_ftm.strace | head -n 160'

筛出来的结果比较多，我只读关键片段，重点看 `openat/access/ioctl` 触到的库、XML 和 `card100` 设备节点。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_4LRAuOJ0Xa1UN7sC5YTYgOVG__vscode-1773769667893/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_KmaD2UyiFgolPVK7wT4Ab0mJ__vscode-1773769667894/content.txt)

现在已经能回答“能不能抓”了，而且还有初步结果。我再补一刀，把 `controlC100` 这类最关键节点的返回值单独拎出来，避免被 `unfinished ...` 干扰。

Ran terminal command:  adb shell 'grep -n "controlC100\|pcmC100\|pcmC0D16p\|pcmC0D14p" /data/local/tmp/agmplay.strace | head -n 80'

Ran terminal command:  adb shell 'grep -n "controlC100\|pcmC100\|pcmC0D16p\|pcmC0D14p" /data/local/tmp/tinyplay_ftm.strace | head -n 80'

正则转义在设备 shell 里有点脏，我换成最简单的单关键字抽取，拿到明确返回值就够了。

Ran terminal command:  adb shell 'grep controlC100 /data/local/tmp/agmplay.strace | head -n 20'

Ran terminal command:  adb shell 'grep controlC100 /data/local/tmp/tinyplay_ftm.strace | head -n 20'

我再把 `tinyplay_ftm` 那条 `unfinished` 补成完整返回值；这个点很关键，因为它能直接区分“card100 根本不存在”和“card100 已经真的开起来”。

Ran terminal command:  adb shell 'grep -n controlC100 /data/local/tmp/tinyplay_ftm.strace | head -n 1'

Ran terminal command:  adb shell 'grep -n controlC100 /data/local/tmp/agmplay.strace | head -n 1'

行号拿到了。我直接读 `tinyplay_ftm` 附近几行，把 `openat` 的恢复结果补全，然后就能给你一个可操作结论。

Ran terminal command:  adb shell 'sed -n 748,756p /data/local/tmp/tinyplay_ftm.strace'

可以，而且我刚刚已经实际抓了一轮。

先说边界：

1. `strace` 抓的是 syscall，不是 `libagmmixer.so`、`libagm.so` 里的 C API 调用。
2. 所以它能回答“它碰了哪些设备、XML、binder、plugin、ioctl”，但不能直接告诉你“这里调用了 `set_agm_streamdevice_metadata()`”。

这轮实抓到的结论很有用：

1. recovery 里自带 `strace`，版本是 `4.25`，设备当前是 root，能直接用。
2. `agmplay` 和 `tinyplay_ftm` 都不是纯本地 tinyalsa 直推。
3. 两者都会加载：
   - `libtinyalsa.so`
   - `libagmmixer.so` 或相关 mixer plugin
   - `libagmclient.so`
   - `libagm_pcm_plugin.so`
   - `vendor.qti.hardware.agm-V1-ndk.so`
   - `libbinder_ndk.so`
   - `libbinder.so`
4. 两者都会打开 `/dev/binder`，说明它们确实走了 AGM AIDL/binder 侧链路。
5. 两者都会读 `/odm/etc/backend_conf.xml`。
6. 更关键的是，两者访问 `/dev/snd/controlC100` 都直接失败，返回都是 `ENOENT`。

这个点很重要，因为它说明：

1. 它们并不是靠直接打开本地 `card100` 控制节点完成整条链路。
2. 当前这条 AGM/FTM 路更多是：
   - 用户态二进制
   - AGM client / plugin
   - binder 到 AGM service
   - 再由服务或 plugin 往下编排
3. 所以单看 `strace`，已经能证明它们的关键差异不在“直接 open 某个 `/dev/snd/controlC100` 成功没有”，而在更上层的 binder + plugin + graph 编排。

你关心的“抓 API”这件事，结论要分开说：

1. 如果你的目标是“确认它到底碰了哪些库、配置、设备、binder”，`strace` 很合适，刚才这轮已经证明了。
2. 如果你的目标是“确认它按什么顺序调用了 agmmixer helper”，`strace` 不够。
3. 这个层级更适合用：
   - `ltrace`，如果设备上有
   - `frida-trace`
   - `perf probe` / `uprobe`
   - 或者直接看 `libagmmixer.so` / `libagmclient.so` 的符号和日志

所以现在最实用的判断是：

1. `strace` 值得继续用
2. 但它应该用来抓：
   - 哪些 XML 被读
   - 哪些 `.so` 被加载
   - binder 是否建立
   - 哪些 `ioctl` 打到了 ALSA 节点
3. 不应该指望它直接还原 `set_agm_stream_metadata` 这类 API 名称级调用图

如果你要继续往下压，我建议下一步做这两种之一：

1. 做一轮“聚焦版 strace”
   - 只抓 `openat, ioctl, read, write, sendmsg, recvmsg`
   - 这样更容易看清 AGM service、plugin、ALSA 节点交互
2. 做一轮“uprobe/符号级跟踪”
   - 直接盯 `libagmmixer.so` 的导出函数
   - 这样才能真正看到 helper 顺序

如果你要，我下一步可以直接继续做：
1. 给 `agmplay` 和 `tinyplay_ftm` 各抓一版精简 `strace` 摘要
2. 或者开始尝试在设备上找能不能用 `perf probe` / `uprobe` 盯 `libagmmixer.so` 导出符号

User: 我并没有听到声音

GitHub Copilot: 我先按“当前确实无声”重验一次播放现场，把 `tinyplay_ftm` 运行时的日志和关键 mixer 状态一起抓出来，先确认现在退回到了哪一层。

Ran terminal command:  adb shell 'ls /odm/bin/tinyplay_ftm /vendor/bin/agmplay /odm/bin/tinymix_stock /data/local/tmp/tinymix_stock 2>/dev/null'
Completed with input:  adb shell 'ls /odm/bin/tinyplay_ftm /vendor/bin/agmplay /odm/bin/tinymix_stock /data/local/tmp/tinymix_stock 2>/dev/null'

Ran terminal command:  adb shell 'cat /proc/asound/cards; echo ---; cat /proc/asound/pcm'

Ran terminal command:  adb shell 'logcat -d | grep -i -E "aw882xx|graph_open|graph_start|MFC not present|allow power|tinyplay_ftm|agmplay" | tail -n 120'

声卡和 `TDM-LPAIF-RX-SECONDARY` 还在，所以下一步直接现场重放一次 `tinyplay_ftm`，同时抓“功放有没有进入 allow power / start success”以及当前 speaker mixer 是不是又掉回默认值。

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /odm/bin/tinyplay_ftm /data/local/tmp/test440_low.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY'

Ran terminal command:  adb shell 'logcat -d | grep -i -E "aw882xx_start_pa|allow power|graph_open|graph_start|thread_result|Playing sample|tinyplay_ftm" | tail -n 160'

Ran terminal command:  adb shell '/data/local/tmp/tinymix_stock 0 | grep -i -E "WSA RX0 MUX|WSA RX1 MUX|WSA2 RX0 MUX|WSA2 RX1 MUX|WSA_COMP1 Switch|WSA_COMP2 Switch|WSA2_COMP1 Switch|WSA2_COMP2 Switch|Speaker_Mute_Switch|aw_dev_[0-9]+_switch|aw_dev_[0-9]+_volume" | head -n 80'

这次 `tinyplay_ftm` 明显没有走到之前那种 `Playing sample` / `thread_result ok`，先把对应日志读出来，再单独用更稳的方式回读 mixer。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_oRkvWklLKzdYUzopsRGEocmQ__vscode-1773769667908/content.txt)

Ran terminal command:  adb shell '/data/local/tmp/tinymix_stock 0 > /data/local/tmp/tinymix0.txt && grep -i "WSA RX0 MUX\|WSA RX1 MUX\|WSA2 RX0 MUX\|WSA2 RX1 MUX\|WSA_COMP1 Switch\|WSA_COMP2 Switch\|WSA2_COMP1 Switch\|WSA2_COMP2 Switch\|Speaker_Mute_Switch\|aw_dev_0_switch\|aw_dev_1_switch\|aw_dev_2_switch\|aw_dev_3_switch\|aw_dev_5_switch\|aw_dev_6_switch\|aw_dev_0_volume\|aw_dev_1_volume\|aw_dev_2_volume\|aw_dev_3_volume\|aw_dev_5_volume\|aw_dev_6_volume" /data/local/tmp/tinymix0.txt'
Completed with input:  adb shell '/data/local/tmp/tinymix_stock 0 > /data/local/tmp/tinymix0.txt && grep -i "WSA RX0 MUX\|WSA RX1 MUX\|WSA2 RX0 MUX\|WSA2 RX1 MUX\|WSA_COMP1 Switch\|WSA_COMP2 Switch\|WSA2_COMP1 Switch\|WSA2_COMP2 Switch\|Speaker_Mute_Switch\|aw_dev_0_switch\|aw_dev_1_switch\|aw_dev_2_switch\|aw_dev_3_switch\|aw_dev_5_switch\|aw_dev_6_switch\|aw_dev_0_volume\|aw_dev_1_volume\|aw_dev_2_volume\|aw_dev_3_volume\|aw_dev_5_volume\|aw_dev_6_volume" /data/local/tmp/tinymix0.txt'

结论已经很清楚一半了：`graph_open/start` 仍然成功，`tinyplay_ftm` 也跑到了 `thread_result ok`，但 6 路 `aw882xx_start_pa` 全都卡在 `dev can not allow power`。现在只差把当前 mixer 默认值读出来，确认是不是末端 speaker 路由又掉回去了。

Ran terminal command:  adb shell 'grep -i "WSA RX0 MUX\|WSA RX1 MUX\|WSA2 RX0 MUX\|WSA2 RX1 MUX\|WSA_COMP\|WSA2_COMP\|Speaker_Mute_Switch" /data/local/tmp/tinymix0.txt | head -n 80'

Ran terminal command:  adb shell 'grep -i "aw_dev_" /data/local/tmp/tinymix0.txt | head -n 80'

Ran terminal command:  adb shell 'grep -i "VBAT" /data/local/tmp/tinymix0.txt | head -n 40'

我先检查 `tinymix0.txt` 本身有没有内容，避免继续在空文件上 grep。

Ran terminal command:  adb shell 'wc -l /data/local/tmp/tinymix0.txt; sed -n 1,20p /data/local/tmp/tinymix0.txt'

Ran terminal command:  adb shell '/data/local/tmp/tinymix_stock 0 2>/data/local/tmp/tinymix0.err >/data/local/tmp/tinymix0.out; wc -l /data/local/tmp/tinymix0.out /data/local/tmp/tinymix0.err; sed -n 1,12p /data/local/tmp/tinymix0.out; sed -n 1,12p /data/local/tmp/tinymix0.err'

`tinymix_stock 0` 只是在读单个控件 0，不是列全表。我改成无参数导出完整控件列表，再筛我们关心的 WSA 和 `aw_dev_*`。

Ran terminal command:  adb shell '/data/local/tmp/tinymix_stock >/data/local/tmp/tinymix_all.txt; wc -l /data/local/tmp/tinymix_all.txt; sed -n 1,8p /data/local/tmp/tinymix_all.txt'

Ran terminal command:  adb shell 'grep -i "WSA RX0 MUX\|WSA RX1 MUX\|WSA2 RX0 MUX\|WSA2 RX1 MUX\|WSA_COMP1 Switch\|WSA_COMP2 Switch\|WSA2_COMP1 Switch\|WSA2_COMP2 Switch\|Speaker_Mute_Switch" /data/local/tmp/tinymix_all.txt | head -n 80'

Ran terminal command:  adb shell 'grep -i "aw_dev_" /data/local/tmp/tinymix_all.txt | head -n 80'

`aw_dev_*_volume` 还在 120，但所有 `aw_dev_*_switch` 都是 `Disable`，这已经足够解释 `allow power` 失败的一半了。我再把 WSA/WSA2 那组控件也用更宽松的关键字拉出来，确认是不是同样退回了默认路由。

Ran terminal command:  adb shell 'grep -i "wsa" /data/local/tmp/tinymix_all.txt | head -n 160'

Ran terminal command:  adb shell 'grep -i "Speaker_Mute_Switch\|Mute" /data/local/tmp/tinymix_all.txt | head -n 80'

我已经把“没听到声音”重验了一次，结果和你的反馈一致，而且失败点比之前更清楚了：不是 graph 没开，而是功放上电条件没满足。我现在把这个修正结论补进文档，避免后面再把 `graph_open ret 0` 误写成“已可闻”。

Generating patch (70 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```
对，按刚才这轮重验，当前结论应该改成“确实没声”。

我已经现场复核过一次，结果和你的反馈一致：

1. `tinyplay_ftm` 仍然能跑到 `Playing sample` 和 `thread_result ok`
2. `AGM graph_open`、`graph_start` 也都是 `ret 0`
3. 但 6 路 Awinic 都卡在：
   - `aw882xx_start_pa: dev can not allow power`

这说明现在不是：
1. 声卡没起来
2. AGM graph 没打开
3. 样本根本没送进去

而是更后面的末端功放没有满足上电条件，所以仍然无声。

我还把当前 mixer 状态重新读了一次，关键点是：

1. `WSA/WSA2` 主路由其实还在
2. `VBAT` 相关开关也还是 `On`
3. 但 `aw_dev_0/1/2/3/5/6_volume` 虽然还是 `120`
4. `aw_dev_0/1/2/3/5/6_switch` 全都回到了 `Disable`

这和 `allow power` 失败是对得上的。当前最像直接根因的，就是这组 `aw_dev_*_switch` 没打开。

我已经把这个修正结论补进文档了，避免后面再把 `graph_open ret 0` 误写成“已可闻”。

下一步最值的是：

1. 先把全部 `aw_dev_*_switch` 切回 `Enable`
2. 立刻重跑一次 `tinyplay_ftm`
3. 如果还不响，再继续补查还有哪组 PA 条件没满足

如果你要，我下一步就直接帮你把这组 `tinymix_stock` 命令补齐并现场复测。

Made changes.

User: 我还是没有听到声音，现在如何听到声音

GitHub Copilot: 我先直接把当前最可疑的 Awinic 开关补到“有声态”，然后立刻重跑 `tinyplay_ftm` 验证是不是已经能出声。

Ran terminal command:  adb shell 'grep -i "Speaker_Mute_Switch\|aw_dev_[0-9]_switch\|aw_dev_[0-9]_volume" /data/local/tmp/tinymix_all.txt | head -n 120'

Ran terminal command:  adb shell '/data/local/tmp/tinymix_stock "aw_dev_0_switch" "Enable"; /data/local/tmp/tinymix_stock "aw_dev_1_switch" "Enable"; /data/local/tmp/tinymix_stock "aw_dev_2_switch" "Enable"; /data/local/tmp/tinymix_stock "aw_dev_3_switch" "Enable"; /data/local/tmp/tinymix_stock "aw_dev_5_switch" "Enable"; /data/local/tmp/tinymix_stock "aw_dev_6_switch" "Enable"; /data/local/tmp/tinymix_stock "aw_dev_0_volume" 120; /data/local/tmp/tinymix_stock "aw_dev_1_volume" 120; /data/local/tmp/tinymix_stock "aw_dev_2_volume" 120; /data/local/tmp/tinymix_stock "aw_dev_3_volume" 120; /data/local/tmp/tinymix_stock "aw_dev_5_volume" 120; /data/local/tmp/tinymix_stock "aw_dev_6_volume" 120'

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /odm/bin/tinyplay_ftm /data/local/tmp/test440_low.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY'

我已经把 `aw_dev_*_switch` 重新打到 `Enable` 并重跑了一次播放；现在直接看这次播放后的功放日志和控件回读，判断是否还卡在 `allow power`。

Ran terminal command:  adb shell 'logcat -d | grep -i -E "aw882xx_start_pa|allow power|start success|graph_open|graph_start|thread_result|Playing sample|tinyplay_ftm" | tail -n 120'

Ran terminal command:  adb shell '/data/local/tmp/tinymix_stock >/data/local/tmp/tinymix_all2.txt; grep -i "aw_dev_0_switch\|aw_dev_1_switch\|aw_dev_2_switch\|aw_dev_3_switch\|aw_dev_5_switch\|aw_dev_6_switch\|aw_dev_0_volume\|aw_dev_1_volume\|aw_dev_2_volume\|aw_dev_3_volume\|aw_dev_5_volume\|aw_dev_6_volume" /data/local/tmp/tinymix_all2.txt'
Completed with input:  adb shell '/data/local/tmp/tinymix_stock >/data/local/tmp/tinymix_all2.txt; grep -i "aw_dev_0_switch\|aw_dev_1_switch\|aw_dev_2_switch\|aw_dev_3_switch\|aw_dev_5_switch\|aw_dev_6_switch\|aw_dev_0_volume\|aw_dev_1_volume\|aw_dev_2_volume\|aw_dev_3_volume\|aw_dev_5_volume\|aw_dev_6_volume" /data/local/tmp/tinymix_all2.txt'

Ran terminal command:  adb shell 'grep -i "WSA RX0 MUX\|WSA RX1 MUX\|WSA2 RX0 MUX\|WSA2 RX1 MUX\|WSA_COMP1 Switch\|WSA_COMP2 Switch\|WSA2_COMP1 Switch\|WSA2_COMP2 Switch\|WSA_RX INT0 VBAT\|WSA_RX INT1 VBAT\|WSA2_RX INT0 VBAT\|WSA2_RX INT1 VBAT" /data/local/tmp/tinymix_all2.txt | head -n 80'

日志已经出来了；我先读这次播放后的关键片段，再直接按已知行号去抽 `aw_dev_*` 和 `WSA` 控件，绕开前面 `grep` 的输出兼容问题。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_8BewarCFdhsU0umy6LrQNi1e__vscode-1773769667926/content.txt)

Ran terminal command:  adb shell 'sed -n 325,382p /data/local/tmp/tinymix_all2.txt'

Ran terminal command:  adb shell 'sed -n 173,206p /data/local/tmp/tinymix_all2.txt; echo ---; sed -n 248,281p /data/local/tmp/tinymix_all2.txt'

我已经把最关键的功放开关补上了，而且最新一次重放时 6 路 Awinic 都从 `allow power` 失败推进到了 `start success`，我现在再触发一遍播放，让你直接在设备上听。

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /odm/bin/tinyplay_ftm /data/local/tmp/test440_low.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY'

现在最直接的做法已经不是再分析，而是按这组命令把功放状态拉到可播态后立刻重放。

我刚才已经实际做了两件事：

1. 把这几路 Awinic 功放开关重新补到了 `Enable`
2. 再次触发了 `tinyplay_ftm` 播放

关键变化是，最新一轮内核日志已经从之前的：

```text
aw882xx_start_pa: dev can not allow power
```

变成了：

```text
aw882xx_start_pa: start success
```

而且 6 路实例都进入了 `start success`。这说明现在已经从“功放不上电”推进到“功放启动成功”。

你现在要听声，直接用这条命令重放就行：

```bash
adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /odm/bin/tinyplay_ftm /data/local/tmp/test440_low.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY'
```

如果你还没听到，按这个顺序再做一遍最稳：

```bash
adb shell '/data/local/tmp/tinymix_stock "aw_dev_0_switch" "Enable"'
adb shell '/data/local/tmp/tinymix_stock "aw_dev_1_switch" "Enable"'
adb shell '/data/local/tmp/tinymix_stock "aw_dev_2_switch" "Enable"'
adb shell '/data/local/tmp/tinymix_stock "aw_dev_3_switch" "Enable"'
adb shell '/data/local/tmp/tinymix_stock "aw_dev_5_switch" "Enable"'
adb shell '/data/local/tmp/tinymix_stock "aw_dev_6_switch" "Enable"'
adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /odm/bin/tinyplay_ftm /data/local/tmp/test440_low.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY'
```

当前判断很明确：

1. 声卡还在
2. AGM graph 也能 `graph_open ret 0` / `graph_start ret 0`
3. 最新关键突破是 `aw882xx_start_pa: start success`
4. 所以现在这条路径已经具备“应该能出声”的条件

如果你此刻仍然听不到，我下一步建议直接做这两件事中的一个：

1. 我继续把 `aw_dev_*_switch=Enable`、`Speaker_Mute_Switch=Off`、WSA/WSA2 路由写成一条完整恢复命令，方便你每次重启后一键恢复
2. 我改用更长、音量感知更明显的测试样本再重放一遍，排除当前 `test440_low.wav` 听感太弱

User: 有声音了，主线还能继续调试吗，不依赖二进制，播放出视频的声音，为什么二进制能播放声音，而你的代码不能

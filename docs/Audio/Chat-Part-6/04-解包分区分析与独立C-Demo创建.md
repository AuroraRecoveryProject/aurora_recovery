# 第4章：解包分区分析与独立C Demo创建

User: ➜  rom_extract git:(main) ✗ ls '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/aurora_recovery/rom_extract/extracted_20260318_034751'  
abl.img             init_boot.img       pdp_cdb.img         uefi.img
aop.img             keymaster.img       product.img         uefisecapp.img
aop_config.img      modem.img           pvmfw.img           vbmeta.img
bluetooth.img       my_bigball.img      qupfw.img           vbmeta_system.img
boot.img            my_carrier.img      recovery.img        vbmeta_vendor.img
cpucp.img           my_engineering.img  shrm.img            vendor.img
cpucp_dtb.img       my_heytap.img       soccp_dcd.img       vendor_boot.img
devcfg.img          my_manifest.img     soccp_debug.img     vendor_dlkm.img
dsp.img             my_product.img      splash.img          xbl.img
dtbo.img            my_region.img       spuservice.img      xbl_config.img
engineering_cdt.img my_stock.img        system.img          xbl_ramdump.img
featenabler.img     odm.img             system_dlkm.img
hyp.img             oplus_sec.img       system_ext.img
imagefv.img         pdp.img             tz.img
➜  rom_extract git:(main) ✗ 

有没有别的分区是能用的


这是这次的日志

[INFO][HandleMinuitwrpEvents(701)] MINUITWRP -> OnTouchUp
[INFO][HandleMinuitwrpEvents(701)] MINUITWRP -> OnTouchUp
[INFO][HandleMinuitwrpEvents(701)] MINUITWRP -> OnTouchUp
[swscaler @ 0xb4000076425e8130] No accelerated colorspace conversion found from yuv420p to rgba.
[VideoPlayer] 音频提取完成: /tmp/flutter/vp_audio_575575296.wav bytes=14123608 ready=1
flutter: [VideoPlayer] 打开成功: 1280x720, 时长: 73560ms, 帧率: 30.0fps
[VideoPlayer] AGM 构建标记: agm-20260318-direct-probe-v3
[VideoPlayer] AGM 运行时环境: LD_LIBRARY_PATH=/mnt/system_a/system/lib64:/system/lib64:/vendor/lib64:/vendor/lib64/hw
[VideoPlayer] AGM 运行时环境: AGM_BACKEND_CONF_FILE=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: AGM_BACKEND_CONF_PATH=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: BACKEND_CONF_FILE=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: BACKEND_CONF_PATH=/odm/etc/backend_conf.xml
[VideoPlayer] AGM 运行时环境: USECASE_KV_MANAGER_FILE=/odm/etc/usecaseKvManager.xml
[VideoPlayer] AGM 运行时环境: USECASE_KV_MANAGER_PATH=/odm/etc/usecaseKvManager.xml
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libc++.so handle=0xea87b4a7befef2cd
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libutils.so handle=0xdb6b0b57529d27b
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libcutils.so handle=0x96f7485fde39b7a1
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/liblog.so handle=0x0
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libaudio_log_utils.so handle=0x7f3fbe3730160f63
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libsndcardparser.so handle=0xc738f847a9a19dfb
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm.so handle=0x67d4403dce3e255d
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagmclient.so handle=0xe94c2c52c1b77e15
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagmmixer.so handle=0xc6f8b099a06061eb
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm_pcm_plugin.so handle=0x7d855d1935cd62a9
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/libagm_mixer_plugin.so handle=0x87963548fc4a3dbb
[VideoPlayer] AGM 运行时依赖预加载: /vendor/lib64/vendor.qti.hardware.agm-V1-ndk.so handle=0xe97f5d2650137c5d
[VideoPlayer] VideoPlayer FFI build=agm-20260318-direct-probe-v3
[VideoPlayer] start_audio_playback: wav=/tmp/flutter/vp_audio_575575296.wav start_ms=0
[VideoPlayer] 音频线程启动 path=/tmp/flutter/vp_audio_575575296.wav
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
[VideoPlayer] agm_session_aif_connect rc=0 session=100 aif=16 connect=1
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



GitHub Copilot: 我先把这轮日志收口成结论，并顺手把文档补上；同时给你一个“哪些分区现在还有价值”的精确名单。

Generating patch (44 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```
这轮日志已经把一个关键分支排除了：`agm_session_aif_connect` 不是缺口本体，缺口在更早的 session 生命周期。下面我把“哪些分区还有用”按优先级给你收紧。

Completed: *记录结果与限制* (4/4)

有，而且现在能用的分区其实已经很明确了。基于你这次日志，优先级要重新排，不要再平均用力。

先说这次日志的结论：

1. `agm_session_aif_connect rc=0 session=100 aif=16 connect=1` 已经命中了。
2. 但命中之后，`TDM-LPAIF-RX-SECONDARY rate ch fmt` 还是 `0,0,0,0`。
3. `metadata`、`setParam` 还是全零。
4. `PCM100 connect/disconnect` 还是 `ZERO`。
5. `agm_mixer_get_miid` 还是拿不到，`getTaggedInfo` 还是 `-19`。
6. 最后 `card100/device100` 还是 `Unknown error -5`。

这说明一件事：

1. 现在已经不是 connect helper 用错的问题了。
2. 也不是普通 PCM fallback 误判。
3. 真正缺的是更早的 session 生命周期，至少是 `session_open / set_config / prepare / start` 这一层，或者它们之前的 graph/session 前置初始化。

所以，分区有没有用，要按“能不能补这条前置链”来分。

现在最有用的分区

1. `vendor.img`
   - 这是第一优先级。
   - 里面有 `libagm.so`、`libagmclient.so`、`libagmmixer.so`、`audiohalservice.qti` 相关库、AIDL manifest、vendor 音频配置。
   - 如果你要继续补播放器的 `session_open/set_config/...`，最该从这里找符号、依赖链、服务声明、库版本耦合。
   - 当前主战场就是它。

2. `odm.img`
   - 也是第一梯队。
   - 你现在已经在吃它的 `/odm/etc/backend_conf.xml` 和 `usecaseKvManager.xml`。
   - 还应该继续看里面的 `ftm_mixer_paths.xml`、厂测配置、`tinyplay_ftm` 依赖的 XML。
   - 当前 `streamdevice metadata` 能把 `PCM100 control` 推到 `TDM-LPAIF-RX-SECONDARY`，但推不进下一层，这时 `odm` 里的 usecase / kv / mixer path 仍然很关键。

3. `vendor_boot.img`
   - 非常有用。
   - 这不是为了音频数据面，而是为了 recovery/vendor ramdisk 的启动链。
   - 你现在的问题越来越像“播放器进程没补齐 tinyplay_ftm 启动前就已经具备的 session 环境”，这种前置环境经常就在 vendor ramdisk 的 init、挂载、属性、service 启动顺序里。
   - 尤其要看：
     - audio 相关 init rc
     - vendor AIDL service 启动
     - vendor ramdisk 里的 manifest / vintf / sepolicy / 属性导出
     - recovery 模式和正常模式的差异

4. `boot.img` 和 `init_boot.img`
   - 有用，但优先级低于 `vendor_boot`。
   - 主要看 init、属性、zygote 前的基础环境、是否有影响 vendor service 行为的 early-init 配置。
   - 如果 `vendor_boot` 里已经把 recovery 侧的前置链解释清楚了，这两个可以少看。
   - 如果 `vendor_boot` 解释不清，才继续顺着它们补。

5. `dtbo.img`
   - 有用，但现在不是第一优先。
   - 你这次日志已经证明 AGM service/control 面能起来一些，`streamdevice metadata` 也能推进一点，所以当前不太像“完全 DT 缺音频节点”。
   - 但如果后面发现 `session_open/set_config` 也补了，还是始终不进 graph-ready，再回头查它。
   - 主要价值是核对音频后端节点、宏节点状态、speaker/codec 相关 overlay。

6. `recovery.img`
   - 有用。
   - 不是拿来找音频配置本身，而是用来对比你当前 recovery 里到底少了什么：
     - ramdisk
     - init 脚本
     - manifest
     - 启动顺序
     - 挂载点
   - 如果这是 stock recovery，还很有参考价值。

中等价值的分区

1. `system.img`
   - 中等价值。
   - 主要看和 vendor 音频服务耦合的 `system/lib64` 依赖，尤其 binder、AIDL、base 库版本。
   - 你现在的播放器进程在 recovery 里走 vendor 音频用户态，`system.img` 有时决定它能不能完整拉起那条链。
   - 但它通常不是第一手真相来源。

2. `system_ext.img`
   - 中等价值。
   - 某些音频 AIDL / 权限 / framework 侧配置会放这里。
   - 对 recovery 来说，不如 `vendor` / `odm` / `vendor_boot` 直接，但仍可能解释某些 service 依赖。

3. `vendor_dlkm.img`、`system_dlkm.img`
   - 只有在你怀疑当前 recovery 模块集不完整时才值得深挖。
   - 但你这轮日志已经不是单纯内核没起卡的问题，所以它们不是当前主线。

低价值或当前基本不用看的分区

1. `product.img`
2. `my_product.img`
3. `my_region.img`
4. `my_stock.img`
5. `my_heytap.img`
6. `my_carrier.img`
7. `my_engineering.img`
8. `my_bigball.img`

这些更多是资源、应用、定制内容、区域配置。对你现在这个 AGM session 生命周期问题，基本不提供核心答案。

当前基本可以先不看的分区

1. `abl.img`
2. `xbl.img`
3. `xbl_config.img`
4. `xbl_ramdump.img`
5. `modem.img`
6. `aop.img`
7. `aop_config.img`
8. `qupfw.img`
9. `pvmfw.img`
10. `tz.img`
11. `hyp.img`
12. `uefi.img`
13. `uefisecapp.img`
14. `cpucp.img`
15. `cpucp_dtb.img`
16. `dsp.img`

这些更偏 bootloader、固件、底层处理器镜像。你当前问题已经不在那一层。尤其 `dsp.img` 虽然看起来像音频相关，但如果 `tinyplay_ftm` 能走到 `agm_session_aif_connect`、`graph_open` 这类阶段，它就不是当前第一瓶颈。

可以直接给你一个实用排序：

1. 先挖 `vendor.img`
2. 再挖 `odm.img`
3. 再挖 `vendor_boot.img`
4. 然后 `recovery.img`
5. 不够再看 `boot.img` / `init_boot.img`
6. 最后才是 `dtbo.img`

这次日志对调试方向的实际意义

1. 你让我补的 `libagmclient` connect 试探已经验证完了。
2. 结果是：connect 能成，但图还是不进入可写态。
3. 所以下一步不该继续折腾 `connect`，也不该继续折腾 `rate ch fmt` 写法。
4. 下一步应该直接转向：
   - 从 `vendor.img` 里的 `libagm.so/libagmclient.so` 继续补 `session_open`
   - 找 `session_set_config`
   - 找 `prepare/start/write`
   - 对照 `tinyplay_ftm` 真正最小调用链

如果你要我继续，我下一轮就直接做两件事：

1. 从你这些分区里给出“只需要解包哪些镜像”的最小名单
2. 继续改播放器，把 `agm_session_open/set_config/prepare/start` 这条最小 session 路径补进去

Made changes.

User: recovery.img分区没用，官方的rec啥也没有，我给你解包出来，你等我指令

GitHub Copilot: 我先把这个约束记成仓库事实，后续不再把 `recovery.img` 放进主线优先级；下一步就等你解包结果或新指令。

Read memory /memories/repo/

这个信息足够关键，我补一条仓库记忆，避免后面再把官方 `recovery.img` 当成高价值输入。

Created memory file twrp_official_recovery_empty_20260318.md

记住了。

后续调整：
1. 不再把官方 `recovery.img` 当主线输入。
2. 分区优先级里直接去掉它。
3. 等你把需要的内容解出来，或者你下一个明确指令，我再继续往下做。

当前最合理的等待点就是：
1. 你给解包结果
2. 或者直接让我转去 `vendor` / `odm` / `vendor_boot` 继续做 session 生命周期那条线

User: ➜  extracted_20260318_034751 git:(main) ✗ ls '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/aurora_recovery/rom_extract/extracted_20260318_034751'
boot.img            keymaster.img       soccp_debug.img     vbmeta_vendor.img
devcfg.img          odm.img             splash.img          vendor
dsp.img             oplus_sec.img       spuservice.img      vendor.img
dtbo.img            pdp.img             system.img          vendor_boot.img
engineering_cdt.img pdp_cdb.img         system_dlkm.img     vendor_dlkm.img
featenabler.img     recovery.img        system_ext.img
imagefv.img         shrm.img            vbmeta.img
init_boot.img       soccp_dcd.img       vbmeta_system.img

继续告诉我没用的镜像，我好删除

GitHub Copilot: 按你现在这条主线，下面这些镜像可以先删，基本不提供当前 AGM/session/recovery 音频问题的有效信息。

可以先删
1. `keymaster.img`
2. `devcfg.img`
3. `dsp.img`
4. `oplus_sec.img`
5. `pdp.img`
6. `pdp_cdb.img`
7. `shrm.img`
8. `soccp_dcd.img`
9. `soccp_debug.img`
10. `spuservice.img`
11. `engineering_cdt.img`
12. `featenabler.img`
13. `imagefv.img`
14. `splash.img`
15. `vbmeta.img`
16. `vbmeta_system.img`
17. `vbmeta_vendor.img`
18. `recovery.img`

这些东西要么是签名/校验，要么是基带/安全/固件侧碎片，要么是显示资源。对你现在要找的：
1. AGM session 生命周期
2. vendor 音频服务链
3. recovery 下的用户态前置条件
4. 音频配置和 usecase

基本没直接价值。

建议保留
1. `vendor.img`
2. `vendor`
3. `odm.img`
4. `vendor_boot.img`
5. `boot.img`
6. `init_boot.img`
7. `dtbo.img`
8. `system.img`
9. `system_ext.img`

这几个是当前最该留的。

有条件再决定删不删
1. `vendor_dlkm.img`
2. `system_dlkm.img`

这两个对你当前“用户态 AGM session 没补齐”不是主线，但如果后面怀疑模块集、声卡节点、音频内核组件不完整，它们还可能回头用到。磁盘不紧张就先留。

一句话收口：
1. 真正别动的是 `vendor.img`、`odm.img`、`vendor_boot.img`
2. 次级保留是 `boot.img`、`init_boot.img`、`dtbo.img`、`system.img`、`system_ext.img`
3. 其余你这次列出来的大部分都可以删

如果你要，我下一条可以直接给你一份“最小保留名单”，你照着只留 8 到 10 个镜像就行。

User: dsp.img分区是啥

GitHub Copilot: `dsp.img` 一般就是 DSP 固件分区，放的是给各类数字信号处理器跑的固件镜像，不是 Android 用户态那种普通文件系统分区。

放的通常是什么
1. Qualcomm 平台上，常见是 ADSP/CDSP/SLPI 一类子系统要加载的固件
2. 音频算法、语音处理、部分传感器/低功耗协处理相关固件也经常在这里
3. 里面常见会有 `.mbn`、`.elf`、`.jsn`、`bdwlan` 风格的固件或描述文件

它在音频链里的角色
1. 不是播放器配置
2. 不是 mixer path
3. 不是 AGM XML
4. 它更像“底层 DSP 能不能跑起来”的固件来源

对你现在这个问题的意义
1. 它当然和音频有关，因为 Qualcomm 很多音频能力最终都跑在 ADSP 上
2. 但它不是你当前最该优先挖的分区
3. 你现在的日志已经说明：
   - AGM 库能加载
   - session connect 能打到
   - graph/control 至少部分在动
4. 这说明问题不像是“DSP 固件根本没起来”这种最底层故障

什么时候 `dsp.img` 才值得重点看
1. `remoteproc-adsp` 根本起不来
2. 日志里大量出现 DSP firmware load fail
3. `q6 state is down`
4. `adsprpcd`、`audioadsprpcd`、AGM/PAL 服务一启动就因为 DSP 侧不可用直接挂掉
5. 不同 ROM/不同版本之间怀疑 DSP 固件和 vendor 用户态严重不匹配

一句话说清
1. `dsp.img` 是“DSP 固件仓库”
2. 解决的是“DSP 能不能工作”
3. 你现在更像是“DSP 大体活着，但播放器没补齐 vendor 成功链里的完整 session 生命周期”
4. 所以当前优先级还是低于 `vendor.img`、`odm.img`、`vendor_boot.img`

如果你要，我下一条可以顺手把：
1. `boot.img`
2. `init_boot.img`
3. `vendor_boot.img`
4. `vendor.img`
5. `odm.img`
分别是干什么，按“对当前问题的价值”给你列成一张短表。

User: /Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751

解压了一部分，你继续分析，核心主线，不依赖二进制播放出声音

我觉得你不应该死磕ffi，你应该写一个纯C/CPP的demo，你自主完成测试

然后随时更新文档

GitHub Copilot: 我先把新解包目录里的音频相关资产和现有源码入口对齐，目标是转主线到一个独立的纯 C/C++ 最小 demo，而不是继续把验证绑死在 FFI 上。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/extracted_20260318_034751)

Searched for text `libagm.so|libagmclient.so|libagmmixer.so|tinyplay_ftm|agmplay|backend_conf.xml|usecaseKvManager.xml|audiohalservice.qti` (`**/extracted_20260318_034751/**`), 48 results

Searched for regex `agm_session_open|agm_session_set_config|agm_session_prepare|agm_session_start|agm_session_write|agm_session_aif_connect` (`**/extracted_20260318_034751/**`), no results

解包目录已经够用了：用户态库、init rc、XML 都在。下一步我把 service 启动面和 `libagmclient/libagm` 可用 API 摊平，然后直接起一个独立 demo。

Searched for regex `IAGM|IPAL|audiohalservice|audioeffecthal|audio core|agmservice|palservice` (`**/extracted_20260318_034751/vendor/**`), 56 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/extracted_20260318_034751/vendor/vendor/etc/init/audiohalservice_qti.rc)

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP/extracted_20260318_034751 && strings vendor/vendor/lib64/libagmclient.so | rg "agm_session_(open|set_config|prepare|start|write|close|aif_connect)|agm_aif_set_params|agm_session_set_metadata|agm_set_params_with_tag"

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP/extracted_20260318_034751 && strings vendor/vendor/lib64/libagm.so | rg "agm_session_(open|set_config|prepare|start|write|close|aif_connect)|agm_aif_set_params|agm_session_set_metadata|agm_set_params_with_tag"

现在已经确认两件事：一是解包目录提供了完整用户态音频服务链，二是 `libagmclient.so` 符号足够做独立 demo。下一步我直接反推出最小 API 原型和调用顺序，然后落一个可编译、可上机测试的纯 C 程序。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP/extracted_20260318_034751 && llvm-nm -D vendor/vendor/lib64/libagmclient.so | rg "agm_session_(open|set_config|prepare|start|write|close|aif_connect)|agm_aif_set_params|agm_session_set_metadata|agm_set_params_with_tag"

Ran terminal command:  adb -s 70a91f89 shell 'strings /odm/bin/tinyplay_ftm | rg "session id|stream_kv|device_kv|instance_kv|Backend|aifid|Playing sample|num_intf"'
Completed with input:  adb -s 70a91f89 shell 'strings /odm/bin/tinyplay_ftm | rg "session id|stream_kv|device_kv|instance_kv|Backend|aifid|Playing sample|num_intf"'

Ran terminal command:  adb -s 70a91f89 shell 'readelf -Ws /vendor/lib64/libagmclient.so | rg "agm_session_(open|set_config|prepare|start|write|close|aif_connect)"'
Completed with input:  adb -s 70a91f89 shell 'readelf -Ws /vendor/lib64/libagmclient.so | rg "agm_session_(open|set_config|prepare|start|write|close|aif_connect)"'

我要把结构体线索从库里挖出来，重点不是完整头文件，而是足够支撑一个“能 open/set_config/connect/prepare/start”的最小原型。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP/extracted_20260318_034751 && strings vendor/vendor/lib64/libagmclient.so | grep -E "AgmSessionConfig|agm_session_config|agm_media_format|BufferConfig|SessionConfig|AidlToLegacy|LegacyToAidl" | head -n 200

Ran terminal command:  adb -s 70a91f89 shell 'strings /odm/bin/tinyplay_ftm | grep -E "stream_kv|device_kv|instance_kv|Backend|Playing sample|num_intf|rate ch bit|session id|aifid" | head -n 200'

Ran terminal command:  adb -s 70a91f89 shell 'readelf -Ws /vendor/lib64/libagmclient.so | grep -E "agm_session_(open|set_config|prepare|start|write|close|aif_connect)"'

我再往前一步，不猜 API，而是直接从 `tinyplay_ftm` 反推出它调用 `agm_session_open/set_config/...` 时准备了哪些参数寄存器和顺序。

Ran terminal command:  adb -s 70a91f89 shell 'objdump -d /odm/bin/tinyplay_ftm 2>/dev/null | grep -n "agm_session_open@plt\|agm_session_set_config@plt\|agm_session_prepare@plt\|agm_session_start@plt\|agm_session_write@plt\|agm_session_aif_connect@plt" | head -n 80'

Ran terminal command:  adb -s 70a91f89 shell 'readelf -Ws /odm/bin/tinyplay_ftm | grep -E "agm_session_(open|set_config|prepare|start|write|aif_connect)"'
Completed with input:  adb -s 70a91f89 shell 'readelf -Ws /odm/bin/tinyplay_ftm | grep -E "agm_session_(open|set_config|prepare|start|write|aif_connect)"'

Ran terminal command:  adb -s 70a91f89 shell 'readelf -d /odm/bin/tinyplay_ftm | grep NEEDED'

`tinyplay_ftm` 不是直接链接 `libagmclient`，更像是运行时装载，所以我直接看 `libagmclient` 自己的 wrapper 反汇编，借它把参数个数和形状反出来。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP/extracted_20260318_034751 && llvm-objdump -d --symbolize-operands --demangle --start-address=0x1aa00 --stop-address=0x1ab80 vendor/vendor/lib64/libagmclient.so

Ran terminal command:  adb -s 70a91f89 shell 'logcat -c && setprop vendor.oplus.mm.ftm_spk 1 && /odm/bin/tinyplay_ftm /data/local/tmp/test440_mid_10s.wav -num_intf 1 -i TDM-LPAIF-RX-SECONDARY >/dev/null 2>&1 && logcat -d | grep -E "agm_session_(open|set_config|prepare|start|write|aif_connect|close)"'

wrapper 反汇编已经拿到了，我先读关键几段，目标是把 `open/set_config/write` 的参数个数定下来，然后就开工写 demo。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_GRxo3g5d9z92vGamPgO7xuyD__vscode-1773775025674/content.txt)

库本体没给出头文件，我改走公开代码搜索接口，直接抓 `agm_session_open` 和 `agm_session_config` 的源码定义。

Ran terminal command:  curl -s 'https://grep.app/api/search?q=agm_session_open' | head -c 12000

Ran terminal command:  curl -s 'https://grep.app/api/search?q=agm_session_config' | head -c 12000

主线判断已经定了：继续追求“能独立复现并上机试”的价值比继续堆 FFI 大，所以我现在切到一个独立 CLI demo，并让它直接跑你当前这条 AGM 路径。

Created 5 todos

在开新文件前，我先扫一遍现有仓库有没有已经成形的纯 C 音频小工具，能复用就不重复造轮子。

Searched for regex `int main\(|tinyalsa|agm_session_aif_connect|pcm_open\(|tinyplay_ftm` (`**/*.{c,cc,cpp,h,sh}`), 200 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual)

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player)

我先确认一下现有 FFI 头里有没有能直接复用的纯音频入口；如果没有，就直接落独立源码，不再绕。

Searched for regex `EXPORT|video_player_|audio_play|play_wav|start_audio|stop_audio` (`**/video_player/video_player_ffi.c`), 28 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.h)

头文件里没有现成入口，所以我走折中但高效的路线：把当前已验证的音频核心抽成一个可直接从 `main()` 调的 C 接口，再编一个独立可执行 demo，和 Flutter 运行时彻底解耦。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#2828-2828), lines 2828 to 2928

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#3144-3144), lines 3144 to 3198

我要做的代码改动很集中：给现有音频核心加一个可直接调用的 WAV 播放入口，再补一个独立 `main()` 和构建脚本，这样我们就能脱离 Flutter 上机跑。

Generating patch (156 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.h), [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c), [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/audio_demo_main.c), [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/build_agm_demo.sh)


```

```

```

```

```

```

```

```
独立入口已经落下，下一步直接编译这个可执行 demo，确认它能脱离 Flutter 成功出产物。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c), [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.h), [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/audio_demo_main.c), 29 problems found

Ran terminal command:  cd /Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player && chmod +x build_agm_demo.sh && ./build_agm_demo.sh
Completed with input:  cd /Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player && chmod +x build_agm_demo.sh && ./build_agm_demo.sh

编译只卡在一个实际问题：Android NDK 不需要单独链 `-lpthread`。我先修脚本，再继续产出并上机。

Generating patch (10 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/build_agm_demo.sh)


```

```
脚本已修正。我现在重新编译，并且如果产物出来就直接推到设备跑一轮，验证这个独立 demo 能否完整复现当前 AGM 路径。

Ran terminal command:  ./build_agm_demo.sh

Ran terminal command:  adb -s 70a91f89 shell 'test -f /data/local/tmp/test440_mid_10s.wav && echo ok || echo missing'

独立可执行已经出产物了，哈希是 `0727a57ef185f0dc94f80d4efcb87caaecfe4e3d3e95d11acd39c49149abc9af`。下一步我直接把它推到设备并跑，拿第一轮“脱离 Flutter 后”的真实日志。

Ran terminal command:  adb -s 70a91f89 push agm_audio_demo /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo

Ran terminal command:  adb -s 70a91f89 shell 'logcat -c && /data/local/tmp/agm_audio_demo /data/local/tmp/test440_mid_10s.wav >/data/local/tmp/agm_audio_demo.out 2>&1; echo EXIT:$?; tail -n 200 /data/local/tmp/agm_audio_demo.out'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -E "VideoPlayer|AGM: API: agm_session_|AgmIpc::|graph_open|graph_start|aw882xx|pcm_plug_open|mixer_plugin_open" | tail -n 300'

设备侧已经跑完，接下来我只读两份结果文件的关键段，判断这个纯 C demo 有没有把问题压缩到比 FFI 更干净的位置。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_4jf1UM4queeUf39nxoJPnklW__vscode-1773775025694/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_6jjKHhDqjFSEK2ZOKM3cvI5Z__vscode-1773775025695/content.txt)

现在已经拿到一个比 FFI 更硬的证据链：独立 demo 复现了同样的失败。接下来我把这轮结果写进文档，把“Flutter/FFI 不是主因”正式钉住。

Generating patch (54 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)

文档上下文刚才没对上，我先读尾部精确位置再追加，不动前面内容。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3840-3840), lines 3840 to 3911

Ran terminal command:  wc -l '/Volumes/Case-sensitive APFS/TWRP/docs/TWRP音频手动Bring-up.md'

Generating patch (56 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```
文档已经补上。我再记一条仓库事实：独立 demo 已经复现同样故障，后续不必再怀疑 Flutter 容器层。

Created memory file twrp_audio_standalone_demo_20260318.md

独立 demo 已经把“不是 FFI 容器问题”钉住了。下一步我继续往前推进一层，直接在同一个 demo 里加一个 `libagmclient` session 探针，先验证 `session_open/prepare/start/close` 这条链最起码能不能跑起来。

Using "Apply Patch"

补丁格式刚才撞到了同一文件的重复段，我拆成一次性单段更新后继续。

Generating patch (172 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.h), [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/audio_demo_main.c), [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```

```

```

```

```
session 探针入口已经进去了。我现在直接重编独立 demo 并上机跑 `--probe-session`，看 `agm_session_open/set_config/prepare/start/close` 在真实设备上到底能走到哪一步。

Ran terminal command:  ./build_agm_demo.sh

Ran terminal command:  adb -s 70a91f89 push agm_audio_demo /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell 'logcat -c && /data/local/tmp/agm_audio_demo --probe-session >/data/local/tmp/agm_probe.out 2>&1; echo EXIT:$?; tail -n 200 /data/local/tmp/agm_probe.out'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -E "debug probe session|AGM: API: agm_session_(open|set_config|prepare|start|close|aif_connect)|AgmIpc::|graph_open|graph_start" | tail -n 300'

我不再盲试参数了，直接把 veneer 跳转目标解出来。只要拿到 `agm_session_open` 真正的函数体，就能从寄存器使用反推出原型。

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP/extracted_20260318_034751 && llvm-nm vendor/vendor/lib64/libagmclient.so | grep '__ubsan_handle_cfi_check_fail_minimal_abort'
Completed with input:  cd /Volumes/Case-sensitive\ APFS/TWRP/extracted_20260318_034751 && llvm-nm vendor/vendor/lib64/libagmclient.so | grep '__ubsan_handle_cfi_check_fail_minimal_abort'

Ran terminal command:  cd /Volumes/Case-sensitive\ APFS/TWRP/extracted_20260318_034751 && llvm-objdump -d --symbolize-operands --demangle vendor/vendor/lib64/libagmclient.so | grep -n '<agm_session_open>\|<agm_session_set_config>\|<agm_session_aif_connect>\|<agm_session_prepare>\|<agm_session_start>\|<agm_session_close>'

还有一个低成本试探值得做：把 `agm_session_open` 的第二个参数从 `0` 改成一个非空 dummy 指针。如果这次不再当场崩，说明第二个参数很可能根本不是 session mode，而是一个必须可解引用的结构体指针。

Generating patch (28 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)


```

```
我继续用同一个探针快速回归，目标不是成功播放，而是把 `agm_session_open` 的参数形状再缩小一层。

Ran terminal command:  cd /Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player && ./build_agm_demo.sh

Ran terminal command:  adb -s 70a91f89 push agm_audio_demo /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell chmod 755 /data/local/tmp/agm_audio_demo && adb -s 70a91f89 shell 'logcat -c && /data/local/tmp/agm_audio_demo --probe-session >/data/local/tmp/agm_probe.out 2>&1; echo EXIT:$?; tail -n 120 /data/local/tmp/agm_probe.out'

Ran terminal command:  adb -s 70a91f89 shell 'logcat -d | grep -E "debug probe session|AGM: API: agm_session_(open|set_config|prepare|start|close|aif_connect)|AgmIpc::|graph_open|graph_start" | tail -n 200'

这轮又压出一个硬结论：`agm_session_open` 不能靠“多塞几个 0”盲调，当前原型猜测完全不够。我要把这个探针结果记进文档，主线前沿就正式移到“先拿准 open 原型”。

Generating patch (45 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```
文档已更新，当前 delta 很清楚：独立 demo 和 session 探针都已经跑过，瓶颈正式收敛到 `agm_session_open` 真实 ABI。

Completed: *实现独立 C 音频 demo* (3/5)

主线已经切出去了，而且结果比之前更硬。

这轮我实际完成了这些事：

1. 做了一个独立纯 C 可执行 demo，彻底脱离 Flutter/FFI 容器。
2. 编译并上机跑了这个 demo，直接播放设备上的 WAV。
3. 又在同一个 demo 里加了 `--probe-session`，直接探 `libagmclient` 的 session 生命周期。
4. 文档已经持续更新到最新结论。

这轮最重要的结论

1. 独立 demo 完整复现了 FFI 版的失败轨迹。
2. 这基本把“是不是 Flutter/FFI 容器层导致无声”排除了。
3. `agm_session_aif_connect rc=0` 仍然命中，但 connect 前后：
   - `rate ch fmt` 还是 `0,0,0,0`
   - `metadata` / `setParam` 还是全零
   - `agm_mixer_get_miid` 还是失败
   - `card100/device100` 还是 `-5`
4. 所以当前问题不在 FFI，不在普通 PCM fallback，也不只是 connect helper。

独立 demo 新增带来的额外信息

1. Awinic 侧已经能看到更完整的 `startup -> hw_params -> mute=0 -> start_pa` 尝试序列。
2. 但多颗功放还是持续 `aw882xx_start_pa: start failed, cnt=...`。
3. AGM service 在运行中还出现过一次 `serviceDied`，随后被重新拉起。

这说明现在至少有两条并行前沿：

1. AGM/PAL/session 生命周期本身还没补完整。
2. AGM service / plugin 稳定性也有问题。

更关键的新收敛

我又做了两轮 `agm_session_open` 探针：

1. 第一轮把它当成“`session_id + mode + 一堆 0`”去调。
2. 第二轮把第二个参数改成非空 dummy 指针再试。

两轮结果都一样：

1. 能先走到 `AgmIpc::Client: getAgm`
2. 能 `linked to death`
3. 然后立刻 `Segmentation fault`
4. 甚至来不及返回 `agm_session_open rc=...`

这意味着：

1. `agm_session_open` 的真实 ABI 绝对不是现在这种简单猜法。
2. 继续靠盲猜参数顺序和结构体大小去撞，收益很低。
3. 当前真正卡住主线的，已经收敛成：`agm_session_open` 以及它前后相关结构体/ABI 还没拿准。

本轮新产物

1. 独立 demo 首个可执行哈希：`0727a57ef185f0dc94f80d4efcb87caaecfe4e3d3e95d11acd39c49149abc9af`
2. 加入 session 探针后的新版哈希：`de39256bfcf378d511abfdc6579fca0296025b909583e843fe9a4df54ab9bfb3`
3. 第二轮 open 参数试探版哈希：`676ef8d9e405bcd12bbac6a21863540ff4b117940cb6f7e1f8a1744a78423703`

当前主线结论

1. 不依赖 vendor 播放二进制的方向是对的。
2. 不该再把时间花在 FFI 容器层。
3. 也不该继续只围绕 `agm_session_aif_connect` 打转。
4. 下一阶段必须先拿准 `agm_session_open` 的真实原型，再谈 `set_config / prepare / start / write`。

下一步我会继续做的，就是这一件事：

1. 反推出 `agm_session_open` 的真实 ABI/结构体形状，然后把独立 demo 从“connect 探针”推进到“真正的 session_open/set_config/prepare/start/write”链路。

Made changes.


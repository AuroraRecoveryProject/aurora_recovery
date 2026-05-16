# 第3章：Session API ABI验证与Metadata Wire Format突破

User: 继续

GitHub Copilot: 我直接转到 libagm.so 的 session 导出入口，目标是先把 agm_session_open 和 agm_session_set_config 的 wrapper 形态看出来，确认它们是不是简单跳板到更深层实现。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -h libagm.so | sed -n '1,40p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0x37340 --stop-address=0x37820 libagm.so

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && strings -a -t x libagm.so | grep -i 'session_open\|set_config\|prepare\|start\|metadata\|params_with_tag' | sed -n '1,120p'

导出入口都在 .text 里，不是 PLT 跳板，这很好。下一步我直接读 wrapper 反汇编结果，看 agm_session_open/set_config 是不是简单转到 session_obj_* / graph_*，还是还包了一层参数整理。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_vI6QCF3TXNQSpee1eJ8ZWUav__vscode-1773795047803/content.txt#1-1), lines 1 to 260

Compacted conversationwrapper 基本全是无条件跳转，真实逻辑在 0x1b5cc、0x1b618、0x1a138 这批实现里。现在我读这几个实现本体，先把 agm_session_open / set_config / aif_set_metadata 的参数流和下层调用关系钉死。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0x1b5cc --stop-address=0x1b760 libagm.so | sed -n '1,220p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0x1a138 --stop-address=0x1a6f0 libagm.so | sed -n '1,260p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0x2123c --stop-address=0x21620 libagm.so | sed -n '1,260p'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_5alMz64BaDoaqGFK6HnkNxvQ__vscode-1773795047807/content.txt#1-1), lines 1 to 260

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_yMNYpmlBmDONnVPsyHSa6HaX__vscode-1773795047808/content.txt)

现在能确定一层重要事实：`graph_set_config` 的 ABI 不是 `(graph, tag, ptr, size)`，而是 `(graph, payload_ptr, size)`，并且它会先从 payload 首 8 字节取一个 `w2` 作为 config id，再把余下数据传给 `gsl_set_config`。这和我们之前对 tagged payload 的某些猜测有偏差。继续把 session_open/set_config 后半段读完。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_5alMz64BaDoaqGFK6HnkNxvQ__vscode-1773795047807/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_5alMz64BaDoaqGFK6HnkNxvQ__vscode-1773795047807/content.txt#60-60), lines 60 to 220

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0x1b5cc --stop-address=0x1b860 libagm.so | head -n 220

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0x1a4d0 --stop-address=0x1a6c0 libagm.so | head -n 220

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_yokQw6gSwO7lQaaaC0eqrlmk__vscode-1773795047813/content.txt)

`agm_session_open` 的 ABI 已经出来了：它不是 opaque builder，而是直接 `(session_obj*, session_config*, media_config*, buffer_config*)`。其中 `x2/x3` 不能为空，否则直接 `-22`；`x1` 可以为空，而且只有 `sess_mode == 2` 时才会把 `x1` 这块 16B 额外拷进对象。接下来我去仓库和反编译里找这些结构体定义，确认各字段的实际布局。

Searched for regex `struct agm_session_config|agm_session_config|agm_media_config|agm_buffer_config` (`**/*.{h,hpp,c,cc,cpp,txt,md}`), 7 results

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && strings -a libagm.so | rg 'session_open_|session_obj_set_config|graph_set_config failed|Unable to prepare device|Unable to start device|session_obj_prepare|session_obj_start'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0x1b7ac --stop-address=0x1b940 libagm.so | head -n 220

Searched for regex `agm_session_open|agm_session_set_config|agm_session_prepare|agm_session_start|session_open` (`**/pure_c_agm_probe.c`), no results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1-1), lines 1 to 240

Searched for regex `typedef struct \{|run_probe\(|prime_agm_helper_prep|helper_only|skip_initial_control|metadata_mode` (`**/pure_c_agm_probe.c`), 23 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#960-960), lines 960 to 1400

Searched codebase for "AGM session_config media_config buffer_config struct definition Qualcomm AGM", 15 results

Searched for regex `agm_session_config|agm_media_config|agm_buffer_config|session_config` (`**/*.{h,hpp,c,cc,cpp}`), 200 results

仓库里其实已经埋过一次更低层 session 尝试，video_player_ffi.c 里可能有我们之前猜出来的结构布局。我要把那段拿出来对照反汇编，不重复走已经验证过的错路。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#3670-3670), lines 3670 to 3805

Searched for regex `agm_session_open\(|agm_session_set_config\(|agm_session_prepare\(|agm_session_start\(` (`**/*.{c,cc,cpp,h,hpp,txt}`), no results

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n 'agm_session_open|agm_session_set_config|agm_session_prepare|agm_session_start' audio_manual extracted_20260318_034751 'audio_dtb_probe' docs /Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player | head -n 200

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && nm -D libagmclient.so | rg 'agm_session_open|agm_session_set_config|agm_session_prepare|agm_session_start|agm_session_close|agm_init'

`libagmclient.so` 也导出同名 `agm_session_*`，而此前盲探针就是从这里拿到符号的。既然它是更薄的一层客户端封装，直接拆它通常比先拆 `libagm.so` 更快拿到真实 ABI。 我现在把 `libagmclient.so` 的 `agm_session_open/set_config` 反汇编出来。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0x1a9d0 --stop-address=0x1ac20 libagmclient.so | head -n 260

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && strings -a libagmclient.so | rg 'agm_session_open|session_open|set_config|prepare|start|close|AIF'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -h libagmclient.so | head -n 40

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_VbGm07Pwe6oUszLOpM1jTxbO__vscode-1773795047830/content.txt#1-1), lines 1 to 220

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0xe4f8 --stop-address=0xe680 libagmclient.so | head -n 220

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0xf9d4 --stop-address=0xfb20 libagmclient.so | head -n 220

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0xee14 --stop-address=0xf040 libagmclient.so | head -n 260

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_q68cuCYmXvs5P7NiVFRYJC5a__vscode-1773795047835/content.txt)

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#150-150), lines 150 to 220

Searched for regex `agm_.*session|AGM_SESSION|agm_media_format|agm_buffer_config|agm_session_mode|agm_session_config|agm_tag_config` (`**/*.{h,hpp}`), 1 result

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n 'agm_session_config|agm_media_config|agm_buffer_config|agm_media_format|AGM_SESSION|SESSION_MODE|agm_tag_config' extracted_20260318_034751 audio_manual twrp_a16_compile /Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player | head -n 260

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/extracted_20260318_034751/vendor/vendor/etc/card-defs.xml#330-330), lines 330 to 390

Searched for regex `<id>100</id>|<session_mode>` (`**/extracted_20260318_034751/vendor/vendor/etc/card-defs.xml`), 40 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/extracted_20260318_034751/vendor/vendor/etc/card-defs.xml#30-30), lines 30 to 55

现在能把 `agm_session_open` 的误区清掉一半了：对 `libagmclient.so` 来说，它确实就是 `(session_id, session_mode, handle_out)`，而 `PCM100` 的 `session_mode` 从 card-defs 里能直接确认是 `0`。真正还没钉死的是 `agm_session_set_config` 要的三块 legacy 结构。 我继续顺着 `convertAgmSessionConfigToAidl(...)` 这条线把结构体字段抠出来。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && nm -C libagmclient.so | rg 'convertAgmSessionConfigToAidl|convertAgmBuffer|convertAgmMedia|AgmSessionConfig|AgmMedia'
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && nm -C libagmclient.so | rg 'convertAgmSessionConfigToAidl|convertAgmBuffer|convertAgmMedia|AgmSessionConfig|AgmMedia'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --demangle --start-address=0x1b0e0 --stop-address=0x1b1c0 libagmclient.so | head -n 220

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --demangle --start-address=0x1af40 --stop-address=0x1b0a0 libagmclient.so | head -n 240

Searched for regex `load_agm_client\(|agm_session_aif_connect` (`**/pure_c_agm_probe.c`), 10 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#280-280), lines 280 to 410

我准备做一次最小、低风险的代码改动：不给主路径塞新的 session data plane，只加一个独立的 `session_open -> close` 探针，直接用我们刚刚确认过的 `libagmclient` ABI 和 `PCM100 session_mode=0`。这样能先验证“当前这个更稳的纯 C 运行时里，session 打开本身到底会不会成功”，避免再盲猜 set_config 结构。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1520-1520), lines 1520 to 1642

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/build_pure_c_agm_probe.sh)

Generating patch (112 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
代码已经加上了单独的 `session_open/close` 探针入口，不碰原有播放主路径。接下来我先编译校验，再在设备上分别跑 `--probe-session-open` 和 `--probe-session-open-init`，看看 open 本身是不是终于能稳定返回。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c), 24 problems found

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh
Completed with input:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh

编译只报了一个真实问题：新探针比 `ensure_recovery_audio_route` 的定义更早出现，导致隐式声明。补一个前向声明就行，不涉及逻辑改动。

Generating patch (14 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```


Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c), 24 problems found

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh

编译已经过了，问题面转到设备实测。先用当前恢复环境把新二进制推上去，然后各跑一次 open-only 探针和 init+open 探针，观察是否能拿到非零 handle，或者至少把失败点从“崩溃”变成可见返回码。

Ran terminal command:  adb devices

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && adb -s 70a91f89 push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe

Ran terminal command:  adb -s 70a91f89 shell chmod 755 /data/local/tmp/pure_c_agm_probe && adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --probe-session-open
Completed with input:  adb -s 70a91f89 shell chmod 755 /data/local/tmp/pure_c_agm_probe && adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --probe-session-open

Ran terminal command:  adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --probe-session-open-init
Completed with input:  adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --probe-session-open-init

探针已经给出第一个硬结论：在当前更稳的纯 C 运行时里，`libagmclient.agm_session_open(session=100, mode=0)` 不再崩溃，而是稳定返回 `-32`，`agm_init` 也不改变结果。 这说明 ABI 至少拿对了，阻塞点已经从“调用形态错误”前移到“服务端拒绝 open”。我现在去抓设备侧日志，看 `-32` 在 AGM service 那边对应哪条失败路径。

Ran terminal command:  adb -s 70a91f89 logcat -c && adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --probe-session-open-init
Completed with input:  adb -s 70a91f89 logcat -c && adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --probe-session-open-init

Ran terminal command:  adb -s 70a91f89 logcat -d | rg 'agm_session_open|session_open|Unable to open a session|graph_open|AGM|vendor.audio-hal-aidl|session id=100|Error:' | tail -n 120

设备日志把 `-32` 的含义钉死了：`session_open_with_first_device` 直接报 `No Audio interface(Backend) set on session(Frontend):100`。也就是说，当前 open 失败不是 mode 或 handle 问题，而是 session 在 open 前根本没挂上 backend。 下一步最值钱的实验就是在 open 前显式做一次 `agm_session_aif_connect(session=100, aif=16, 1)`，验证它是否正是 service 口里说的“first device”。

Generating patch (73 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```


Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c), 24 problems found

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && adb -s 70a91f89 push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe

Ran terminal command:  adb -s 70a91f89 logcat -c && adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect-init
Completed with input:  adb -s 70a91f89 logcat -c && adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect-init

Ran terminal command:  adb -s 70a91f89 logcat -d | rg 'agm_session_open|session_open|Unable to open a session|No Audio interface|connecting aifid|agm_session_aif_connect|session id=100|AGM:' | tail -n 120

现在服务日志已经把缺口从“没有 backend”进一步压到“backend 16 打开时参数仍是 rate/ch/fmt/period 全零”。这几乎直接指向 `agm_aif_set_media_config` 或同层 AIF/session 元数据在 open 前没建立。 我先拆 `libagmclient.agm_aif_set_media_config`，如果 ABI 够简单，就能直接做下一轮 AIF 参数注入实验，而不用继续猜整套 session_config。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0xe370 --stop-address=0xe4f8 libagmclient.so | head -n 240

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0xe6d0 --stop-address=0xe8bc libagmclient.so | head -n 260

`agm_aif_set_media_config` 的 ABI 很干净，`libagmclient` 这层只接收 `aif_id + 16 字节配置块`，而且它正好就是一整个 `q0` 原样拷过去。结合我们已经知道的 FE control 形态，这 16 字节高度像 `[rate, channels, alsa_format, data_format]`。我直接补一条“AIF media + preconnect + open”探针，把 backend 16 的 `48000/8ch/S32/-1` 先塞进去。

Generating patch (99 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```


Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && adb -s 70a91f89 push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe

Ran terminal command:  adb -s 70a91f89 logcat -c && adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-media-preconnect-init
Completed with input:  adb -s 70a91f89 logcat -c && adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-media-preconnect-init

Ran terminal command:  adb -s 70a91f89 logcat -d | rg 'agm_session_open|session_open|Unable to open a session|No Audio interface|opening device object|Unable to open PCM device|agm_session_aif_connect|AGM:' | tail -n 120

现在 service 侧的 frontier 也出来了：只补 backend media config 以后，`device_open` 已经不再因为 `rate/ch/fmt=0` 死掉，但 `graph_open` 立刻报 `Metadata GKV size:0 / CKV count:0`，然后 `get_tags_with_module_info -> -22`。 所以下一个真正缺的层已经不是 media config，而是 graph/session metadata 本身。我要把 `agm_aif_set_metadata` 和 `agm_session_set_metadata` 的客户端 ABI 继续拆出来，看能不能再做一轮最小 metadata 注入。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0xe6d0 --stop-address=0xe8c0 libagmclient.so | sed -n '1,220p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0xe8bc --stop-address=0xeab8 libagmclient.so | sed -n '1,240p'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_fFg7qs1JLA7n3aSf0po2K1G4__vscode-1773795047875/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_fFg7qs1JLA7n3aSf0po2K1G4__vscode-1773795047875/content.txt#120-120), lines 120 to 132

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0xe8bc --stop-address=0xea20 libagmclient.so | head -n 220

这轮已经形成了三段连续的 service-side 证据链，我先把它落进文档和 repo memory，避免后面再重复试同一层。然后本轮就可以把下一跳明确成：不是继续猜 open，而是最小化复刻 `*_set_metadata`。

Searched for regex `### 13\.80|### 13\.79` (`**/docs/TWRP音频手动Bring-up.md`), 2 results

Read memory twrp_audio_helper_timing_delta_20260317.md

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#1600-1600), lines 1600 to 1665

Using "Apply Patch"

文档补丁里 repo memory 路径不能用 `apply_patch`，我分开处理。先把主文档写进去，再用 memory 工具追加 repo 记忆。

Generating patch (67 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```


Inserted into memory file twrp_audio_helper_timing_delta_20260317.md

本轮已经把 `libagmclient` 这条 session 路压到了新的硬边界，并且把探针代码补进了纯 C 二进制里。

结论

1. `agm_session_open` 的客户端 ABI 已经拿准了
   使用 `libagmclient.agm_session_open(session_id, session_mode, handle_out)`，对 `PCM100` 用 `session_id=100`、`session_mode=0`。
2. 之前“open 一调就崩”的结论已经过时
   在当前这份更稳的纯 C 运行时里，open 不再崩，而是稳定返回明确错误码。
3. 失败链已经被压成三层
   - 只做 `session_open` 或 `agm_init + session_open`：`rc=-32`
   - 先做 `agm_session_aif_connect(100, 16, 1)` 再 open：`rc=-5`
   - 再补 `agm_aif_set_media_config(16, {48000, 8, S32_LE, -1})` 后再 connect/open：`rc=-22`

设备侧日志对应关系

1. open-only / init+open
   service 明确报：
   `No Audio interface(Backend) set on session(Frontend):100`
   这说明第一层缺口不是 mode，也不是 handle，而是 session 在 open 前根本没 backend。

2. pre-connect 之后
   service 不再报“无 backend”，改成：
   `Unable to open PCM device 16 ... rate 48000 ch 0 fmt 0`
   `Period Size 0`
   这说明 `agm_session_aif_connect` 确实把缺口从“没 backend”推进到了“backend 16 参数还是空”。

3. 再补 `agm_aif_set_media_config`
   service 已经能真正进 `graph_open`，但马上报：
   `Metadata GKV size:0`
   `CKV count:0`
   `get_tags_with_module_info ... -22`
   `graph_open ... ret -22`
   这说明 media config 这一层也已经不再是当前最前面的阻塞，新的硬边界变成 metadata 为空。

我做的改动

1. 给纯 C 探针新增了这些独立入口
   - `--probe-session-open`
   - `--probe-session-open-init`
   - `--probe-session-open-preconnect-init`
   - `--probe-session-open-aif-media-preconnect-init`

2. 扩展了 `libagmclient` 动态装载
   现在会额外解析：
   - `agm_init`
   - `agm_session_open`
   - `agm_session_close`
   - `agm_aif_set_media_config`

3. 把本轮实测结果补进了 bring-up 文档和 repo memory，避免后面重复回踩同一层。

当前主线判断

1. `libagmclient` 路径的第一缺口已经不是 `session_open` ABI
2. 第二缺口也不再是 backend media config
3. 下一跳最值得做的是继续最小化复刻：
   - `agm_aif_set_metadata`
   - `agm_session_set_metadata`
   - `agm_session_aif_set_metadata`

也就是继续补 graph/session metadata，而不是再重试 open/init/mode 组合。

如果你要我继续，我建议下一轮直接做这两个动作之一：

1. 继续逆 `libagmclient` 的 `*_set_metadata` ABI，并在纯 C 探针里加最小 metadata 注入实验
2. 先只做 `agm_aif_set_metadata` 一条，因为它最贴近刚刚已经打通的 `aif_set_media_config -> connect -> graph_open` 链路

Made changes.

User: 继续

GitHub Copilot: 已经把 open 链路压到 metadata 缺口了。下一步我直接拆 `libagmclient` 的 `agm_session_set_metadata / agm_session_aif_set_metadata`，把参数形态拿准，再决定先补哪一条最小注入。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0xe8bc --stop-address=0xec00 libagmclient.so | sed -n '1,260p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && strings -a libagmclient.so | rg 'set_metadata|metadata|get tags info|GKV|CKV|session_set_metadata|aif_set_metadata'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0x1a138 --stop-address=0x1a6c0 libagm.so | sed -n '1,240p'

metadata 这层的 wrapper 结构已经抓到了，我先读实现本体，重点看它们到底是 `(id, size, buf)` 还是带额外 tag/aif 的多参版本。读完我就能加下一轮最小 metadata 探针，不再靠猜。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_CSl45HpA609KeCaRFuD8QbWf__vscode-1773795047886/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_ZsK6FFoX1zueyCj5aES5AMBW__vscode-1773795047888/content.txt)

新信息有两点。第一，`libagmclient` 这层三个 metadata API 的形态已经能确定：`agm_aif_set_metadata(id,size,buf)`、`agm_session_set_metadata(session,size,buf)`、`agm_session_aif_set_metadata(session,aif,size,buf)`。第二，我先不急着硬猜 metadata payload，而是先做一轮更便宜的高价值验证：把现有 `helper_prep` 接到 `session_open` 探针前面，看它写出来的 agmmixer metadata 是否会被 session/graph 路实际看见。

Generating patch (123 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
新探针已经接上 `helper_prep -> aif_media -> preconnect -> session_open` 这条链。现在直接编译、推送、清 log 复跑，目标很明确：看 graph 侧的 `GKV/CKV` 是否还保持 0。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh
Completed with input:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && adb -s 70a91f89 push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe

Ran terminal command:  adb -s 70a91f89 logcat -c && adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --probe-session-open-helper-prep-aif-media-preconnect-init
Completed with input:  adb -s 70a91f89 logcat -c && adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --probe-session-open-helper-prep-aif-media-preconnect-init

这轮没有拿到新结果，原因很具体：新探针比 `load_agm_mixer` 的定义更早出现，导致编译失败，所以设备上跑到的还是上一版二进制。补一个前向声明就够，不是逻辑问题。

Generating patch (10 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
前向声明已经补好。现在重新编译、推送并复跑同一个探针，这次结果才有意义。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && adb -s 70a91f89 push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe

Ran terminal command:  adb -s 70a91f89 logcat -c && adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --probe-session-open-helper-prep-aif-media-preconnect-init
Completed with input:  adb -s 70a91f89 logcat -c && adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --probe-session-open-helper-prep-aif-media-preconnect-init

探针这次已经真跑起来了，输出比较长，我先把关键几段读出来。重点看两处：`helper_prep` 后 `session_open` 返回码，以及设备侧 `graph_open` 里的 `GKV/CKV` 是否还为 0。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_pOD1YRJ8lccPc54XymSG6j4Y__vscode-1773795047898/content.txt)

Ran terminal command:  adb -s 70a91f89 logcat -d | rg 'graph_open|Metadata GKV|CKV count|get tags info|session_open_with_first_device|agm_session_aif_connect|Unable to open a session|AGM:' | tail -n 140

结果已经有价值了。`helper_prep` 并没有把 session 路推进到更深，反而把 `aif_media + preconnect + open` 从 `-22` 拉回了 `-19`。我再把服务侧日志读出来确认是不是又退回到了更早的 backend/device 阶段，还是 metadata 路径换了失败点。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_DrLmXDaRPQ18EOHu4Jg1N1Cf__vscode-1773795047900/content.txt)

有一个更高价值、信息密度更高的对照还没拿：成功的 `agmplay` 在 `graph_open` 时到底打印了什么 metadata。比起现在盲猜 `*_set_metadata` payload，先抓成功样本的 `GKV/CKV/property` 形态更稳。

Ran terminal command:  adb -s 70a91f89 shell ls /data/local/tmp/test440_mid_10s.wav

Ran terminal command:  adb -s 70a91f89 logcat -c && adb -s 70a91f89 shell /vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY -dkv 0xA2000001 -ikv 1 -skv 0xA100000E -dppkv 0xAC000002

Ran terminal command:  adb -s 70a91f89 logcat -d | rg 'graph_open|Metadata GKV|CKV count|property count|key:|Property ID:|Property Values:|graph_prepare|graph_start|AGM:' | tail -n 200

`agmplay` 这次没有真正成功，最后还是 `Error playing sample`，但它已经走过了 plugin 打开和 `Instance key is added`。我先读设备侧 logcat，看它在 `graph_open` 打到了哪一步；哪怕失败，也能作为比当前 probe 更接近成功路径的 metadata 样本。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_XCrmiKWSzwi0bom7HyzfqqK9__vscode-1773795047904/content.txt)

现在有了第一份真正可用的成功样本。`agmplay` 的 `graph_open` metadata 不是空的，而是明确长这样：

- GKV：
  - `0xa1000000 -> 0xa100000e`
  - `0xa2000000 -> 0xa2000001`
- CKV：
  - `0xa4000000 -> 0`
  - `0xa5000000 -> 48000`
  - `0xa6000000 -> 32`
  - `0xd2000000 -> 0`

下一步我直接把这份“成功形态”做成一个 `agm_session_aif_set_metadata` 的最小探针，验证当前 session 路能不能靠这块 metadata 从 `-22/-19` 再往前推。

Generating patch (133 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
成功样本 metadata 已经硬编码成一轮最小 `session_aif_set_metadata` 探针。现在直接编译、推送、清 log 复跑，看它是否能让 `graph_open` 打出跟 agmplay 一样的 GKV/CKV，或者至少把 `session_open` 从当前边界再往前推。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && adb -s 70a91f89 push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe

Ran terminal command:  adb -s 70a91f89 logcat -c && adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --probe-session-open-success-metadata-aif-media-preconnect-init
Completed with input:  adb -s 70a91f89 logcat -c && adb -s 70a91f89 shell /data/local/tmp/pure_c_agm_probe --probe-session-open-success-metadata-aif-media-preconnect-init

直接把 agmplay 那份 64B metadata 喂给 `agm_session_aif_set_metadata` 还不行，client API 本身就返回了 `-22`。我去看 service 侧是“payload 形态错了”还是“调用时序/归属对象不对”。

Ran terminal command:  adb -s 70a91f89 logcat -d | rg 'session_obj_set_sess_aif_metadata|agm_session_aif_set_metadata|graph_open|Metadata GKV|CKV count|Error:-22|session id=100|aif_id=16|AGM:' | tail -n 160

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_th7ycKh6iBqfOJ53A3kJHkzl__vscode-1773795047910/content.txt)

新的关键事实已经出来了：`agm_session_aif_set_metadata` 接受的不是我们直接照抄 `graph_open` 打印结果的那份整体 metadata blob。service 明确报的是 `metadata_copy: Num CKVs 48000 more than expected: 48`，说明它在按另一种内部结构解释这块 buffer。 下一步该转成静态逆 `metadata_copy` 本体，而不是继续盲试 payload。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && strings -a libagm.so | rg -n 'Num CKVs|Num GKVs|metadata_copy|more than expected|Property ID|Property Values'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -s --section=.rodata libagm.so | rg -n 'Num CKVs|Property ID|Metadata Done|more than expected'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d libagm.so | rg -n 'metadata_copy|Num CKVs|more than expected|Metadata Done|Property ID'

Made changes.

User: @agent Try Again

GitHub Copilot: 静态搜索已经证明 `metadata_copy` 的格式串都在 `libagm.so` 里，只是还没直接拿到函数地址。下一步我会改用字符串虚拟地址回推引用点，把 `metadata_copy` 本体拆出来，这样就能知道 session metadata 的真实头布局。本轮继续推进后，边界又被压实了一层，而且方向已经很明确。

新增硬结论

1. `libagmclient` 的 metadata API 形态已经拿准
   - `agm_aif_set_metadata(id, size, buf)`
   - `agm_session_set_metadata(session, size, buf)`
   - `agm_session_aif_set_metadata(session, aif, size, buf)`

2. `helper_prep` 的 metadata 确实会对 session 路产生影响，但不是成功推进
   我新增了一个探针链：
   `helper_prep -> aif_set_media_config -> agm_session_aif_connect -> agm_session_open`
   结果：
   - 之前 `aif_media + preconnect + open` 是 `-22`
   - 加上 `helper_prep` 后退回 `-19`

3. 这次退回 `-19` 不是坏消息，反而给了第一份“部分命中 graph metadata”的证据
   设备侧日志显示：
   - `graph_open: entry`
   - `GKV size:4`
   - `key:0xa1000000, value:0xa100000e`
   - `property count:0`
   - `get_tags_with_module_info ... -19`

   这说明：
   - session 路已经不再是完全空 metadata
   - `helper_prep` 至少把 `stream_kv` 这一条 GKV 喂进了 graph
   - 但仍然缺其他关键 metadata，尤其 device / CKV 那部分

4. 已拿到一份成功样本的 graph metadata
   这次重跑 `agmplay` 虽然最终用户态显示 `Error playing sample`，但 service 侧 `graph_open` 是成功的，metadata 明确打印出：

   GKV:
   - `0xa1000000 -> 0xa100000e`
   - `0xa2000000 -> 0xa2000001`

   CKV:
   - `0xa4000000 -> 0`
   - `0xa5000000 -> 48000`
   - `0xa6000000 -> 32`
   - `0xd2000000 -> 0`

   然后继续：
   - `graph_open ... ret 0`
   - `graph_set_config ... ret 0`
   - `graph_prepare ... ret 0`
   - `graph_start ... ret 0`

5. 直接把这份成功样本 metadata 原样喂给 `agm_session_aif_set_metadata` 不行
   我做了新探针：
   `session_aif_set_metadata(成功样本) -> aif_media -> preconnect -> open`

   结果：
   - client API 自己直接返回 `-22`
   - service 侧报：
     `metadata_copy: Num CKVs 48000 more than expected: 48`

   这个报错非常关键，说明：
   - `agm_session_aif_set_metadata` 接受的不是 `graph_open` 打印出来的那种“平铺后的最终 metadata blob”
   - 它前面还有一层更高阶的 legacy metadata 结构
   - 当前真正该逆的是 `libagm.so` 里的 `metadata_copy`，而不是继续盲试 payload

本轮代码改动

我在 pure_c_agm_probe.c 里补了这些探针能力：

1. session open-only
2. init + session open
3. preconnect + session open
4. aif media + preconnect + session open
5. helper_prep + aif media + preconnect + session open
6. success-sample metadata + aif media + preconnect + session open

当前最重要的主线判断

1. 现在已经可以排除：
   - `agm_session_open` ABI 错
   - `session_mode` 错
   - 仅仅缺 backend connect
   - 仅仅缺 backend media config

2. 当前真正卡住的是：
   - session/graph metadata 的真实输入结构还没拿准
   - `helper_prep` 只能喂进部分 GKV
   - `agmplay` 成功样本里还需要 device GKV 和完整 CKV 集合
   - `agm_session_aif_set_metadata` 要的并不是 `graph_open` 最终打印格式

3. 下一步最值钱的事已经收敛成一个明确目标：
   直接逆 `libagm.so` 的 `metadata_copy`，拿到 session metadata 的真实头布局和计数字段顺序

我接下来会继续做这个：
1. 用 `libagm.so` 的字符串引用回推出 `metadata_copy` 实现地址
2. 拆出它如何解析 `num_gkvs / num_ckvs / num_props`
3. 再把正确结构喂回 `agm_session_aif_set_metadata` 探针

如果继续，我就直接做这一步，不再重复试错 payload。

User: 继续

GitHub Copilot: 现在目标很单一：把 `metadata_copy` 的字符串地址和代码引用对上，拿到它的真实解析逻辑。先抓 rodata 偏移和 `.rodata` 基址，再反查引用点。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && strings -a -t x libagm.so | rg 'metadata_copy|Num CKVs|Num GKVs|Property ID|Property Values|Metadata Done'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -h libagm.so | head -n 25

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && nm -D libagm.so | rg 'metadata|graph_open|session_obj_set_sess_aif_metadata'

符号直接露出来了，省掉了字符串回推。下一步我直接拆 `metadata_copy` 和 `session_obj_set_sess_aif_metadata`，目标是拿清楚 metadata 头部字段顺序和 size 单位。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0x379f0 --stop-address=0x37b00 libagm.so | sed -n '1,260p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0x3880 --stop-address=0x39a0 libagm.so | sed -n '1,260p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0x1f34c --stop-address=0x1f8a0 libagm.so | sed -n '1,260p'

User: @agent Try Again

GitHub Copilot: 

User: @agent Try Again

GitHub Copilot: 上次错在地址少写了一位，`0x3880` 实际应是 `0x37880`。这次我直接读 `metadata_copy`、`session_obj_set_sess_metadata`、`session_obj_set_sess_aif_metadata` 的真实实现区间，把头布局钉死。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0x37760 --stop-address=0x37820 libagm.so | sed -n '1,240p'
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0x37760 --stop-address=0x37820 libagm.so | sed -n '1,240p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0x37820 --stop-address=0x37920 libagm.so | sed -n '1,260p'
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0x37820 --stop-address=0x37920 libagm.so | sed -n '1,260p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64' && llvm-objdump -d --start-address=0x37920 --stop-address=0x37a00 libagm.so | sed -n '1,240p'

路径问题只是终端对带空格绝对路径处理不稳，不是仓库缺文件。我改用工作区相对路径重读同一段反汇编。

Ran terminal command:  cd extracted_20260318_034751/vendor/vendor/lib64 && llvm-objdump -d --start-address=0x37760 --stop-address=0x37820 libagm.so | sed -n '1,240p'
Completed with input:  cd extracted_20260318_034751/vendor/vendor/lib64 && llvm-objdump -d --start-address=0x37760 --stop-address=0x37820 libagm.so | sed -n '1,240p'

Ran terminal command:  cd extracted_20260318_034751/vendor/vendor/lib64 && llvm-objdump -d --start-address=0x37820 --stop-address=0x37920 libagm.so | sed -n '1,260p'
Completed with input:  cd extracted_20260318_034751/vendor/vendor/lib64 && llvm-objdump -d --start-address=0x37820 --stop-address=0x37920 libagm.so | sed -n '1,260p'

Ran terminal command:  cd extracted_20260318_034751/vendor/vendor/lib64 && llvm-objdump -d --start-address=0x37920 --stop-address=0x37a00 libagm.so | sed -n '1,240p'
Completed with input:  cd extracted_20260318_034751/vendor/vendor/lib64 && llvm-objdump -d --start-address=0x37920 --stop-address=0x37a00 libagm.so | sed -n '1,240p'

当前只是终端 cwd 和实际目录没对齐。我先用文件搜索拿到 `libagm.so` 的确切路径，然后按那个路径读，不再猜。

Searched for files matching `**/libagm.so`, 1 match

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP)

Ran terminal command:  pwd

路径已经确认两份都在工作区里；终端 cwd 也正常。下一步我直接用 `list_dir` 进到提取目录确认库文件名，然后按绝对路径读反汇编。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/extracted_20260318_034751)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/extracted_20260318_034751/vendor)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/extracted_20260318_034751/vendor/vendor/lib64)

提取目录的绝对路径解析有点异常，但 libagm.so 是现成副本，足够用于 ABI 反汇编。现在直接对这份库读 `metadata_copy` 和 `session_obj_set_sess_aif_metadata`。

Ran terminal command:  llvm-objdump -d --start-address=0x37760 --stop-address=0x37820 '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/libagm.so' | sed -n '1,240p'

Ran terminal command:  llvm-objdump -d --start-address=0x37820 --stop-address=0x37920 '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/libagm.so' | sed -n '1,260p'

Ran terminal command:  llvm-objdump -d --start-address=0x37920 --stop-address=0x37a00 '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/libagm.so' | sed -n '1,240p'

Compacted conversation导出符号本身只是跳板，真正实现都在 `.text` 内部目标地址。下一步改看 `0x27864`、`0x287e0`、`0x29850` 这些落点，恢复真实结构字段。Optimizing tool selection...

Ran terminal command:  llvm-objdump -d --start-address=0x27840 --stop-address=0x27b20 '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/libagm.so' | sed -n '1,320p'

Ran terminal command:  llvm-objdump -d --start-address=0x287c0 --stop-address=0x28940 '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/libagm.so' | sed -n '1,320p'

Ran terminal command:  llvm-objdump -d --start-address=0x29820 --stop-address=0x29ab0 '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/libagm.so' | sed -n '1,420p'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_xjJdOMAMe0DHF51mh2Q0X0If__vscode-1773803651154/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_CuVuzP4SFblMxIV98rqtcOmM__vscode-1773803651156/content.txt)

已经能看到关键形状：`metadata_copy(dst, size, src)` 先读首个 `u32` 作为 GKV 数量，再顺序读 CKV 数量，最后很可能还有 property 段。继续补全后半段，就能确定精确线性布局。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_xjJdOMAMe0DHF51mh2Q0X0If__vscode-1773803651154/content.txt#120-120), lines 120 to 192

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_CuVuzP4SFblMxIV98rqtcOmM__vscode-1773803651156/content.txt#110-110), lines 110 to 172

Ran terminal command:  strings -t x '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/libagm.so' | rg 'Num CKVs|Num GKVs|Property ID|Property Values|Metadata Done|metadata is null|Invalid params|failed to get aif obj|Session ID|AIF ID'

Ran terminal command:  llvm-objdump -d --start-address=0x27b1c --stop-address=0x27ca8 '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/libagm.so' | sed -n '1,260p'

Ran terminal command:  llvm-objdump -d --start-address=0x29aa0 --stop-address=0x29c20 '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/libagm.so' | sed -n '1,320p'

Ran terminal command:  strings -t x '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/libagm.so' | rg 'Unable to copy metadata|Unable to allocate memory|Num GKVs|Num CKVs|Num Props|Metadata Done|Property ID|Property Values'

`metadata_copy` 现在基本清楚了：输入不是扁平化 GKV/CKV 对，而是一个计数前缀的线性 blob。接下来先找当前工作区里真正的 pure_c_agm_probe.c，然后把这个布局编码进去做实机验证。

Searched for files matching `**/pure_c_agm_probe.c`, no matches

Searched for regex `probe-session-open-success-metadata-aif-media-preconnect-init|agm_session_aif_set_metadata|pure_c_agm_probe` (`**/*.{c,cc,cpp,h,sh,md}`), 16 results

Ran terminal command:  llvm-objdump -d --start-address=0x26e74 --stop-address=0x27110 '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe/libagm.so' | sed -n '1,320p'

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#400-400), lines 400 to 520

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1780-1780), lines 1780 to 1865

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_z6LmH6MCJpOND6YSehG4MPuH__vscode-1773803651167/content.txt)

布局已经够用了，可以直接编码新 blob 了。当前 `success_metadata_words` 只是把最终打印出来的 GKV/CKV 平铺回去，难怪 `metadata_copy` 把第二个词当成 `Num CKVs`。现在改成真正的线性格式再上机验证。

Searched for regex `success_metadata_words|aif_media_cfg|probe_agm_session_open_close\(` (`**//Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c`), 12 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#330-330), lines 330 to 430

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/build_pure_c_agm_probe.sh)

准备改 pure_c_agm_probe.c：只做最小修正，把 `success_metadata_words` 从“打印后的扁平结果”改成 `metadata_copy` 真正吃的线性 wire format，不动其他路径。

Generating patch (12 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```


Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c), 24 problems found

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh

本地构建已过，语言服务报的是宿主机缺 Android 头文件，不影响 NDK 脚本实际产物。现在直接把新二进制推到设备，复测 `session_aif_set_metadata` 这一支。

Ran terminal command:  command -v adb && adb devices

Ran terminal command:  adb -s 70a91f89 shell getprop ro.bootmode 2>/dev/null || true

Ran terminal command:  adb -s 70a91f89 logcat -c

Ran terminal command:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe' /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe

Ran terminal command:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --probe-session-open-success-metadata-aif-media-preconnect-init'
Completed with input:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --probe-session-open-success-metadata-aif-media-preconnect-init'

Ran terminal command:  adb -s 70a91f89 logcat -d | rg 'AGM|pure_c_agm_probe|audiosphere|graph_open|get_tags_with_module_info|metadata_copy|session_open|No Audio interface|Metadata GKV|Metadata CKV|Session ID|AIF ID'

结果已经前进了一步：`agm_session_aif_set_metadata` 从 `-22` 变成 `rc=0`，说明 wire format 命中了 `metadata_copy`。现在只剩 `session_open=-19`，需要从服务日志看还缺哪一块 tag/module info。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_ivP58pve6X97gEf1H7k7FkvB__vscode-1773803651182/content.txt)

Ran terminal command:  adb -s 70a91f89 logcat -d | rg -n 'get_tags_with_module_info|graph_open|Metadata GKV|Metadata CKV|aif_set_metadata|session_aif_set_metadata|No Audio interface|Unable to get tags|Session ID|AIF ID|Devicepp|GKV size|CKV count|PCM100|TDM-LPAIF-RX-SECONDARY'

服务端已经给了最关键的确认：`session_obj_set_sess_aif_metadata: Exit`，而且 `graph_open` 确实看到了非空 metadata。还要补一眼完整 `metadata_print`，确认 CKV 和第二个 GKV 是否都进入了 graph。

Ran terminal command:  adb -s 70a91f89 logcat -d | sed -n '920,932p'

Ran terminal command:  adb -s 70a91f89 logcat -d | rg 'metadata_print: 83 key:|metadata_print: 95 key:|metadata_print: 89 CKV count:|metadata_print: 102 Property ID:|metadata_print: 103 property count:'

下一步不该再猜 helper 顺序了，应该直接做更窄的 A/B：把 stream metadata 和 backend metadata 分开喂。按 AGM 语义，`session_set_metadata` 更像前端 stream，`session_aif_set_metadata` 更像后端 device。现在加一个 split-metadata 探针验证这个分工。

Generating patch (75 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```


Generating patch (51 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```


Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c), 24 problems found

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh

Ran terminal command:  adb -s 70a91f89 logcat -c

Ran terminal command:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe' /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe

Ran terminal command:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --probe-session-open-split-metadata-aif-media-preconnect-init'
Completed with input:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --probe-session-open-split-metadata-aif-media-preconnect-init'

Ran terminal command:  adb -s 70a91f89 logcat -d | sed -n '1,260p'

split 试验没有直接突破 `-19`，但两个 metadata API 都返回了 `0`。现在看服务日志里的 `metadata_print`，确认 merge 后到底保留了哪些字段。

Ran terminal command:  adb -s 70a91f89 logcat -d | rg 'session_obj_set_sess_metadata|session_obj_set_sess_aif_metadata|graph_open: 615|metadata_print: 80|metadata_print: 83|metadata_print: 89|metadata_print: 95|metadata_print: 102|metadata_print: 103|get_tags_with_module_info|AcdbGetUsecaseSubgraphList|AcdbCmdGetTagsFromGkv|graph_open: 850|session_obj_open'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_4kiKq2hCvGPZ2W2D4ImX2N9T__vscode-1773803651194/content.txt#1-1), lines 1 to 260

这轮已经拿到一个硬结论：`metadata_copy` 的 wire format 和 split 语义都确认了，而且 graph 现在完整看到了 `stream GKV + device GKV + 4 CKV`。剩下的 `-19` 已经不再是 metadata 传输问题，而是这组 key vector 本身在 ACDB 里找不到匹配 graph。先把这个结论写进文档和 repo memory，避免后面重复踩坑。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#1700-1700), lines 1700 to 1775

Read memory twrp_audio_helper_timing_delta_20260317.md

Read memory twrp_audio_helper_timing_delta_20260317.md

Generating patch (18 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)

文档尾部有空行和旧段落混排，补丁上下文没命中。我先读末尾精确内容，再把新结论直接接到末尾，避免误改。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#1726-1726), lines 1726 to 1750

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#1750-1750), lines 1750 to 1825

Generating patch (72 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```


Inserted into memory file twrp_audio_helper_timing_delta_20260317.md

Searched for text `13.82 session metadata 真实 wire format 已命中` (`**/docs/TWRP音频手动Bring-up.md`), 1 result

Searched for regex `probe-session-open-split-metadata-aif-media-preconnect-init|unsigned int session_metadata_words\[]|unsigned int aif_metadata_words\[]` (`**/pure_c_agm_probe.c`), no results

结果已经推进到下一层了。

这次不是停在 metadata 头格式，而是把它真正打通了：

1. session_aif_set_metadata 现在已经能稳定返回 0
2. split metadata 之后，graph 侧已经完整看到了目标 metadata
3. session_open 仍然是 -19，但含义已经收敛成 ACDB 找不到这组 graph key vector，而不是 metadata 没进去

我实际做了两步修改和两轮上机验证。

第一步是修正纯 C probe 里的 metadata wire format。
之前那份 success metadata 直接复用了 graph_open 打印出来的扁平 GKV/CKV 列表，这对 metadata_copy 来说是错的。现在按 libagm.so 里的真实格式改成了：

1. num_gkv
2. gkv 数组
3. num_ckv
4. ckv 数组
5. property_id
6. num_prop_values
7. property_values

修完后重新编译，新的二进制哈希是 3f8d4fbc188716ddb766a7ca6b1dacda3ad0f7b1c469379b279a65e0aab493c7。

第一轮设备验证结果：

1. aif_set_media_config rc=0
2. session_aif_set_metadata rc=0
3. pre-connect rc=0
4. session_open 从之前的 -22 前进到了 -19

这一步已经证明 metadata API 的 ABI 和头布局命中了。

第二步是新增 split metadata 探针。
我把 stream metadata 和 backend metadata 分开下发：

1. session_set_metadata 负责 stream GKV 和 4 个 CKV
2. session_aif_set_metadata 负责 device GKV

第二轮设备验证结果：

1. session_set_metadata rc=0
2. split session_aif_set_metadata rc=0
3. session_open 仍然是 -19

但这轮服务端日志给了最关键的新结论。graph_open 看到的 metadata 已经是完整的：

1. GKV size: 2
2. 0xA1000000 -> 0xA100000E
3. 0xA2000000 -> 0xA2000001
4. CKV count: 4
5. 0xA4000000 -> 0
6. 0xA5000000 -> 48000
7. 0xA6000000 -> 32
8. 0xD2000000 -> 0

随后失败点变成了：

1. AcdbGetUsecaseSubgraphList Error[19]: Unable to find the graph key vector
2. AcdbCmdGetTagsFromGkv Error[19]
3. gsl_graph_get_tags_with_module_info failed with 19
4. graph_open ret -19

所以当前边界可以明确改写成：

1. 不是 session_open ABI 问题
2. 不是 backend attach 问题
3. 不是 AIF media config 问题
4. 不是 metadata wire format 问题
5. 也不是 session/aif metadata split 语义问题
6. 现在剩下的是这组 stream GKV + device GKV + CKV 本身在当前 recovery 的 ACDB 里找不到匹配 graph

我已经把这轮结论写进文档：
TWRP音频手动Bring-up.md

补充说明：

1. VS Code Problems 里仍会看到宿主机缺 Android 头文件的报错
2. 这不影响 NDK 脚本实际构建，二进制已经成功生成并上机运行验证

下一步最有价值的是这两条：

1. 继续做 graph key vector A/B，优先试 stream kv 是否必须不是 A100000E，或者 device 侧是否还需要换成别的 kv 组合
2. 继续往下追 metadata_merge 和 gsl_get_tags_with_module_info，确认最终送进 ACDB 的 key vector 顺序、来源和去重规则

如果你要我继续，我建议直接从第 1 条开始做最小 A/B。

Made changes.


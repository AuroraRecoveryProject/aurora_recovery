# 第5章：Recovery重启、环境重建与Devicepp KV实验
User: 现在rec重启了，需要先拉起环境，继续回归主线，不用二进制，播放出声音，不要用ffi，用纯c的demo

GitHub Copilot: 我先把当前主线需要的两件事对齐：一是按已验证过的 recovery 环境顺序把音频链重新拉起，二是确认纯 C demo 的当前位置，避免又回到 FFI 或外部二进制路径。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#2815-2815), lines 2815 to 3095

Read memory twrp_audio_manual_playback.md

Read memory twrp_audio_helper_timing_delta_20260317.md

Ran terminal command:  adb devices

Compacted conversation设备已经回到 recovery 的 adb，可直接拉环境。下一步我会先核对当前 recovery 里的音频服务状态和纯 C demo 源码位置，然后按已验证过的基线把服务链与 speaker mixer 重新拉起。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n "pure_c_agm_probe|agm_session_open|PCM100 control" -S

Ran terminal command:  adb shell 'getprop init.svc.vendor.audio-hal-manual; getprop init.svc.vendor.audio-hal-aidl; getprop init.svc.vendor.audio-hal; getprop init.svc.vendor.pd-mapper; getprop init.svc.vendor.pm-service; ps -A | grep -E "audiohalservice|agmserver|palserver|audioadsprpcd|adsprpcd|pd-mapper|pm-service|vndservicemanager"'

Ran terminal command:  adb shell 'ls /system/bin/twrp-audio-autoload.sh /system/bin/twrp-audio-hal-wrapper.sh /vendor/etc/init/vendor.audio-recovery-services.rc 2>/dev/null; cat /proc/asound/cards; echo ---; cat /proc/asound/pcm'

当前 recovery 已经把基础依赖链带起来了：audiohalservice、pd-mapper、pm-service、adsp 侧进程都在，声卡和 TDM-LPAIF-RX-SECONDARY 也已经出来。现在差的不是服务链，而是把 speaker mixer 和纯 C demo 这两段重新接上。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#4658-4658), lines 4658 to 5075

Ran terminal command:  find /Users/Laurie/Desktop/nightmare-space -name 'pure_c_agm_probe.c' -o -name 'build_pure_c_agm_probe.sh'

Ran terminal command:  adb shell 'ls /odm/bin/tinyplay_ftm /data/local/tmp/test440_low.wav /data/local/tmp/test440_mid_10s.wav 2>/dev/null; /system/bin/tinymix 0 2>/dev/null | head -n 5; getprop vendor.oplus.mm.ftm_spk'

纯 C demo 源码和构建脚本都还在外部工程目录，测试音频样本和 tinyplay_ftm 也都在设备上。接下来我先读纯 C probe 的当前实现，再按文档里已经证实可闻的那组 mixer 状态把 speaker 路由恢复出来。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1-1), lines 1 to 420

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/build_pure_c_agm_probe.sh)

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n "WSA RX0 MUX|Speaker_Mute_Switch|aw_dev_[0-9]+_volume|aw_dev_[0-9]+_switch|WSA_COMP1 Switch" docs/TWRP音频手动Bring-up.md
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n "WSA RX0 MUX|Speaker_Mute_Switch|aw_dev_[0-9]+_volume|aw_dev_[0-9]+_switch|WSA_COMP1 Switch" docs/TWRP音频手动Bring-up.md

我已经拿到纯 C probe 的当前实现和编译入口。下一步分成两段执行：先从文档抽出可闻基线的确切 mixer 控件，再直接在设备上复原这组 speaker 路由，然后编译并下发纯 C demo 做回归。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_KpcoDTiFs0CVDbeqrtrMUg8e__vscode-1773803651286/content.txt#1-1), lines 1 to 260

Ran terminal command:  adb shell 'command -v tinymix; ls /odm/bin/tinymix_stock /vendor/bin/tinymix /system/bin/tinymix 2>/dev/null'
Completed with input:  adb shell 'command -v tinymix; ls /odm/bin/tinymix_stock /vendor/bin/tinymix /system/bin/tinymix 2>/dev/null'

Ran terminal command:  adb shell 'ps -A | grep tinyplay_ftm; logcat -d -b all | grep -E "AHAL_Service_QTI|AgmIpc::Service|PalIpc::Service|aw882xx_start_pa|graph_open" | tail -n 80'

设备上现在看不到现成的 tinymix 可执行文件，所以不能走手工 shell 调 mixer 的老路径。我改用纯 C probe 自己内置的 route 预热逻辑，这样更符合“不要用外部二进制，只用纯 C demo”的要求。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#420-420), lines 420 to 920

Ran terminal command:  grep -n "ensure_recovery_audio_route\|MixerEnumRoute\|MixerIntRoute\|aw_dev_\|Speaker_Mute_Switch\|WSA RX0 MUX" '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c'

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1416-1416), lines 1416 to 1548

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1548-1548), lines 1548 to 1935

Ran terminal command:  grep -n "pcm_write\|writei\|write(\|sample\|wav\|/data/local/tmp/test440" '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c'

主线现在很明确了：现有纯 C probe 只做到 open/close，还不会真正写入 PCM，所以它不可能自己放音。我先不猜，先把当前源码编译下发跑一遍拿到基线，然后直接把“写数据发声”能力补进这个纯 C 程序。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb shell 'chmod 755 /data/local/tmp/pure_c_agm_probe && /data/local/tmp/pure_c_agm_probe'
Completed with input:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb shell 'chmod 755 /data/local/tmp/pure_c_agm_probe && /data/local/tmp/pure_c_agm_probe'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_ytx8E9y5ELs9kZ1fI1LfuCRb__vscode-1773803651295/content.txt)

基线已经对上了：recovery 拉起后，当前纯 C probe 还是老边界，speaker 路由预热能成功，但 card100 插件仍停在 pcm_open -5。要继续推进到“纯 C 真的放音”，现在不能只给它 open/close，我会直接把程序补成可写数据，并同时加一条纯 C 的 card0 直放对照路径，用来判断是 AGM 插件卡住，还是末端 speaker 仍有缺口。

Read memory twrp_audio_standard_path_priority.md

Read memory twrp_audio_true_tinyplay_probe.md

Ran terminal command:  grep -n "pcm_write\|pcm_read\|PCM_IN\|PCM_OUT" '/Volumes/Case-sensitive APFS/TWRP/twrp_a16_compile/prebuilts/vndk/v34/arm64/include/external/tinyalsa/include/tinyalsa/asoundlib.h'

我要对纯 C demo 做两类最小改动：一是加真正的 PCM 写入能力，二是加一条独立的纯 C 标准 PCM 对照模式，这样可以在不依赖 FFI 和现成播放二进制的前提下，直接验证“AGM 插件卡住”还是“末端 speaker 仍未打通”。

Generating patch (244 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
我已经把纯 C demo 补成可真正写 PCM 数据，并且加了一个不经过 card100 插件的 card0:16 纯 C 对照模式。现在直接编译、下发、先跑这条标准 PCM 对照，判断它能不能在当前 recovery 里先把声音放出来。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb shell 'chmod 755 /data/local/tmp/pure_c_agm_probe && /data/local/tmp/pure_c_agm_probe --standard-card0-16 --play-seconds 3'
Completed with input:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb shell 'chmod 755 /data/local/tmp/pure_c_agm_probe && /data/local/tmp/pure_c_agm_probe --standard-card0-16 --play-seconds 3'

纯 C 对照已经把一个旧结论重新坐实了：card0:16 这条“普通 PCM”路径在当前 recovery 里确实是能 open 但首包 write 立刻 EINVAL 的假成功，没法当成可闻闭环。接下来不再在它上面空转，我回到主线，直接查 AGM session 头文件和现成原型，补纯 C 的 session-write 路。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n "agm_session_prepare|agm_session_start|agm_session_write|agm_session_set_config|agm_session_open\(" -S twrp_a16_compile | head -n 120

Ran terminal command:  adb shell 'logcat -d -b all | grep -E "aw882xx|pcm|agm|graph_open|audio_hw_primary|start_pa" | tail -n 120'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_1ocIjf1CVqIABk10slFzX9lP__vscode-1773803651303/content.txt)

普通 PCM 这条路的失败层级也重新落地了：不是没进驱动，而是已经打到 AW startup/hw_params/start_pa，随后整组功放 start failed，首包 write 才回 EINVAL。所以现在确实该回到 AGM session 低层，不该再碰 card0 这条假成功支线。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && find . -name 'libagmclient.so' -o -name 'libagm.so' -o -name 'libagmclient*.h' -o -name 'agm*.h' | head -n 120

Ran terminal command:  adb shell 'for f in /vendor/lib64/libagmclient.so /vendor/lib64/libagm.so; do echo === $f ===; toybox readelf -Ws $f | grep agm_session_ | head -n 80; done'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_5knNNwBgi6gNrslVYF9SdFF4__vscode-1773803651306/content.txt)

设备库上的 session 符号面已经拿到了，能继续往下压，不用再盲猜“有没有这些 API”。我接下来查 workspace 里是否已有 AGM 结构体定义；如果没有，就直接围绕现成已知成功点补 session 配置和 write 探针。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n "agm_session_config|struct agm_session|agm_buffer|agm_media_config|AgmSessionConfig" -S . | head -n 200

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && strings libagmclient.so | grep -E "AgmSessionConfig|session_config|buffer_config|AgmBuff|AgmMediaConfig" | head -n 120

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n "interface IAGM|parcelable AgmSessionConfig|AgmBufferConfig|AgmBuff|AgmMediaConfig" -S twrp_a16_compile device_tree android_vendor_twrp 2>/dev/null | head -n 200

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3828-3828), lines 3828 to 3905

我继续往下压，但这一步要换方法：不是再猜参数，而是直接从本地保存的 libagmclient.so 反汇编 wrapper，看看 agm_session_set_config 和 agm_session_write 的真实调用形态。这样才能决定纯 C demo 下一个该补哪个结构体。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d --demangle libagmclient.so | sed -n '/<agm_session_set_config>:/,/^$/p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d --demangle libagmclient.so | sed -n '/<agm_session_write>:/,/^$/p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d --demangle libagmclient.so | sed -n '/<agm_session_prepare>:/,/^$/p'

wrapper 本身只是一个跳板，真实逻辑在跳转目标里。我继续直接看目标地址周围的反汇编，这样能读出寄存器参数和 AIDL 转换调用。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d --demangle --start-address=0xe4f8 --stop-address=0xe650 libagmclient.so

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d --demangle --start-address=0xfed4 --stop-address=0x10040 libagmclient.so

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d --demangle --start-address=0xee14 --stop-address=0xef20 libagmclient.so

我现在已经把两个关键原型掰出来一半了：`agm_session_set_config` 不是两参，明显至少带 `session_id + session_config + media_config + buffer_config` 四段信息；`agm_session_write` 也不是 opaque handle，而是更像 `session + buffer + size_inout`。下一步我直接看 libagm_pcm_plugin 的调用点，而不是继续在 wrapper 层猜结构。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d --demangle libagm_pcm_plugin.so | grep -n "agm_session_set_config@plt\|agm_session_prepare@plt\|agm_session_start@plt\|agm_session_write@plt" | head -n 80

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d --demangle libagm_pcm_plugin.so | grep -n "agm_session_open@plt" | head -n 40

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d --demangle --start-address=0x5da0 --stop-address=0x66a0 libagm_pcm_plugin.so

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_KtKHlMWeOy5ZCzGHcUKN8jXw__vscode-1773803651320/content.txt#1-1), lines 1 to 260

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_KtKHlMWeOy5ZCzGHcUKN8jXw__vscode-1773803651320/content.txt#260-260), lines 260 to 520

我已经把“重启后先拉环境”这段做完，也把纯 C demo 提升到真正能写 PCM 数据。现在可以明确分层：普通 PCM 仍是假成功，主线 blocker 还在 AGM 图状态，不在 FFI、外部二进制或 speaker mixer 基线。剩下要不要继续往 session_set_config 结构体和 session_write 直通链里压，就是下一步最值钱的工作。

Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c), 24 problems found

Read memory /memories/repo/

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-aif-media-preconnect-init'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-aif-media-preconnect-init'

当前 recovery 上，纯 C session 主线和文档里记录的一样，没有因为重启而漂移：`aif_set_media_config + split metadata + pre-connect` 都是 `rc=0`，但 `agm_session_open` 仍稳定卡在 `-19`。这说明环境已经恢复到正确前沿了，接下来如果继续推进，只剩 graph key/vector 这一层值得改。

Read memory twrp_audio_standalone_demo_20260318.md

Ran terminal command:  adb shell 'logcat -d -b all | grep -E "Metadata GKV size|CKV count|graph key vector|Unable to find the graph key vector|get_tags_with_module_info|graph_open" | tail -n 80'

我把这轮重启后的两个关键事实都压实了：一是纯 C 标准 PCM 支线仍然是假成功，二是纯 C session 主线已经恢复到正确的 `graph key vector` 前沿。这个状态适合直接作为后续 session/config 逆向的起点，不需要再重新拉环境。

Created memory file twrp_audio_reboot_rebaseline_20260318.md

现在可以确定一件事：继续啃 `session_set_config` 不会立刻解决这次 `-19`，因为 `agm_session_open` 自己就已经在 graph_open 之前死在 graph key vector 了。真正有价值的是回看成功路径里 GKV/CKV 到底该是什么组合，而不是先补 prepare/start/write。

Read memory twrp_audio_devicepp_kv_frontier.md

Read memory twrp_audio_agmplay_minimal_success.md

Read memory twrp_audio_qualcomm_tinyalsa_doc_mapping.md

我不再在 blind ABI 上耗时间了，直接做一组最有价值的 metadata A/B：把 session AIF metadata 从“只有 device_kv”扩成“device_kv + devicepp_kv”。如果 `agm_session_open` 能从 `-19` 松动，就说明这轮重启后的真正缺口就是 graph key vector 少了一段 GKV，而不是环境或 session 生命周期。

Generating patch (108 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
我加了一组最关键的 session metadata A/B，目标很单纯：验证 graph key vector 里是不是少了 `devicepp_kv` 这一段。现在直接编译实跑看 `agm_session_open` 会不会从 `-19` 松动。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb shell 'chmod 755 /data/local/tmp/pure_c_agm_probe && /data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-devicepp-aif-media-preconnect-init'
Completed with input:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb shell 'chmod 755 /data/local/tmp/pure_c_agm_probe && /data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-devicepp-aif-media-preconnect-init'

这组最有希望的 A/B 也已经收口了：把 `devicepp_kv` 加进 AIF metadata 不会动 `agm_session_open -19`。我再补抓一次 service 侧图日志，看 GKV/CKV 计数有没有变化；如果连计数都不变，就可以把“缺 devicepp GKV”这条支线正式降级。

Ran terminal command:  adb shell 'logcat -d -b all | grep -E "Metadata GKV size|CKV count|graph_open: 615 entry|graph_open: 850 exit|Unable to find the graph key vector" | tail -n 120'

Ran terminal command:  adb shell 'logcat -d -b all | grep -n "05:38:01.828" | tail -n 20'

Ran terminal command:  adb shell 'logcat -d -b all | sed -n "29648,29666p"'

这条 A/B 终于动了，不是白跑：`devicepp_kv` 加进去以后，服务端 metadata 已经从 `GKV size:2` 变成了 `GKV size:3`，明确看到了 `0xAC000002`。但失败点没有变成成功，而是前移成了 `session_open_with_first_device ... Connect failed error:-19`。也就是说，`devicepp_kv` 不是噪音，它确实进图了，只是还没补齐到可开会话。

Ran terminal command:  adb shell 'logcat -d -b all | sed -n "29666,29690p"'

这次 devicepp 不是完全没价值，它把服务端状态推到了新的地方：metadata 已经变成 `GKV size:3`，但会话仍在 open 期失败，而且日志里已经出现了 AW `hw_params`。这意味着下一跳很值得试一个最小 pre-open `agm_session_set_config`，把 frontend 媒体/缓冲参数先补齐，看能不能把这次 `sample size:16` 的默认值改掉。

Generating patch (170 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
我补了一个最小 `pre-open agm_session_set_config` 变体，目的就是验证“GKV 已经进图，但 open 还在默认 16bit 路径上失败”是不是因为 session/frontend 配置没补齐。现在直接跑这一条。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb shell 'chmod 755 /data/local/tmp/pure_c_agm_probe && /data/local/tmp/pure_c_agm_probe --probe-session-open-preconfig-split-metadata-devicepp-aif-media-preconnect-init'
Completed with input:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb shell 'chmod 755 /data/local/tmp/pure_c_agm_probe && /data/local/tmp/pure_c_agm_probe --probe-session-open-preconfig-split-metadata-devicepp-aif-media-preconnect-init'

这次不是结论问题，是探针组合少带了一项：`pre-open set_config` 已经命中了，而且直接返回 `-22`，但我刚才没有把 `split metadata + devicepp` 一起叠上去。现在补跑组合版，确认 `set_config` 在完整 GKV 条件下是仍然 `-22`，还是会改变 open 行为。

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconfig-split-metadata-devicepp-aif-media-preconnect-init --probe-session-open-split-metadata-devicepp-aif-media-preconnect-init'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconfig-split-metadata-devicepp-aif-media-preconnect-init --probe-session-open-split-metadata-devicepp-aif-media-preconnect-init'

这轮已经把主线再收窄了一层：`devicepp_kv` 确实是有效 GKV，不是噪音；而 `pre-open agm_session_set_config` 目前直接 `-22`，至少以这组最小结构体猜法还不是通路。这个结论值得记到仓库记忆里，后面就不用再重复踩。

Created memory file twrp_audio_session_devicepp_gkv_20260318.md

已经把环境重新拉起来，并把纯 C 主线继续往前推了一段。

这轮实际完成的事：

1. recovery 音频环境已恢复
- `vendor.audio-hal-manual`、`pd-mapper`、`pm-service`、`adsprpcd`、`audioadsprpcd`、`audiohalservice.qti` 都在
- 声卡和 `TDM-LPAIF-RX-SECONDARY` 也已经恢复出来
- 说明现在不是“环境没拉起”，而是已经回到正确调试前沿

2. 纯 C demo 已经补成“真的会写 PCM”
- 我给纯 C demo 加了真正的 `pcm_write`
- 加了测试音写入逻辑
- 加了一个纯 C 的标准 PCM 对照模式：`--standard-card0-16`
- 这一步不依赖 FFI，也不依赖现成播放二进制

3. 纯 C 标准 PCM 支线重新验证过了，还是假成功
- 跑 `--standard-card0-16 --play-seconds 3`
- 结果是：`card0:16` 可以 open，但首包 `pcm_write` 立刻 `EINVAL`
- 同时内核日志能看到 `aw882xx_startup`、`aw882xx_hw_params`、`aw882xx_start_pa`
- 但随后整组 `start failed`
- 这条路仍然不能作为“纯 C 可闻播放”闭环

4. 纯 C session 主线也重新回到了正确前沿
- 跑 split-metadata 的 session-open 纯 C 探针后：
  - `agm_init rc=0`
  - `agm_aif_set_media_config rc=0`
  - metadata 写入 `rc=0`
  - `agm_session_aif_connect rc=0`
- 但 `agm_session_open` 仍然稳定 `rc=-19`
- 设备侧日志仍然指向 graph key vector / graph open 失败

5. 这轮最有价值的新结论
- 我新增了一个 `devicepp_kv` A/B，把 AIF metadata 从只带 `device_kv` 扩成 `device_kv + devicepp_kv`
- 结果 service 侧 metadata 已经从 `GKV size:2` 变成了 `GKV size:3`
- 明确能看到 `0xAC000002` 已经进图
- 这说明 `devicepp_kv` 不是噪音，它确实是有效 GKV 组成部分

6. 但还没到能出声
- 即便 `devicepp_kv` 已经进了 GKV，`agm_session_open` 还是 `-19`
- 失败点前移成了 `session_open_with_first_device ... Connect failed error:-19`
- 我还补了一个最小 `pre-open agm_session_set_config` 试探
- 目前这个调用直接 `rc=-22`
- 叠加 `devicepp_kv` 也没有把 open 推过去

当前结论很明确：

- 环境已经拉起
- FFI 不是问题
- 普通 PCM 不是通路
- `devicepp_kv` 确实是正确方向
- 但纯 C demo 现在还没有做到“可闻播放”
- 当前真正 blocker 还是 AGM graph/session key 这层，不是 recovery 重启后的环境问题

补充一点：
- 编辑器里对这份纯 C 源码还有 Android 头文件相关的静态报错
- 但实际用 NDK 构建是通过的，二进制也已经成功下发并运行
- 所以这属于本机索引环境和真实 Android 交叉编译环境不一致，不是这次改动把程序编坏了

下一步最值钱的方向只有两个：

1. 继续围绕 session metadata 做 A/B
- 重点不是再试普通 PCM
- 而是继续对齐 `stream_kv / device_kv / devicepp_kv / instance` 的真实组合，找出还缺的那一段 graph key

2. 直接回到 `tinyplay_ftm` 成功路径的用户态准备逻辑
- 现在已经知道只补 helper 和 session API 还不够
- 下一步最该抠的是它在 `mixer_ctl_set_array` 之前那段本地准备函数，到底还补了什么 graph 前置状态

如果你要我继续，我建议直接走第 2 条。它比继续盲猜 `set_config` 结构体更值。

Made changes.

User: 你之前不是说没有写PCM吗

GitHub Copilot: 对，之前那句说的是“改之前的那个版本”。

当时我先读了现有的 pure C demo，结论是：

1. 它只做了 pcm_open / pcm_is_ready / pcm_close
2. 没有解析 pcm_write 符号
3. 也没有任何生成音频样本并写入设备的代码

所以那一刻我说“它没有写 PCM”，这个判断是对旧代码状态的描述，不是对现在代码状态的描述。

后面我已经把它改了，新增了两块：

1. 给 tinyalsa 动态表补了 pcm_write
2. 加了测试音生成和写入逻辑

所以现在的状态变成了：

1. 之前：不会写 PCM，只能 open/close
2. 现在：已经会真正调用 pcm_write

而且我已经实际跑过了，所以不是只改代码没验证：

1. 标准 PCM 对照路径能 open
2. 第一包 pcm_write 立刻返回 Invalid argument
3. 内核侧同时能看到 aw882xx_startup、hw_params、start_pa，然后 start failed

这也正是为什么我说主线已经往前推进了：
不是“还没写 PCM”，而是“现在已经写了，但普通 PCM 这条路还是假成功，真正 blocker 还在 AGM graph/session 那层”。

所以两句话并不矛盾，区别只在时间点：

1. 之前那句，描述的是旧版本
2. 现在这个版本，已经补上了 PCM 写入能力

如果你要，我下一步就不再解释这个分层，直接继续往 tinyplay_ftm 成功链前面的本地准备逻辑抠。

User: 你之前说tinyplay_ftm和agmplay并没有写PCM

GitHub Copilot: 那句如果按字面理解，是我表述不严谨，应该纠正。

更准确地说是：

1. `tinyplay_ftm` 不是“只做裸 `pcm_write` 的简单播放器”
2. `agmplay` 也不是“只做裸 `pcm_write` 的简单播放器”
3. 它们前面都会先做一大段用户态准备：`backend/media config`、`metadata`、`connect`、`graph/session`、各种 `mixer_ctl_set_array/set_enum`
4. 之后才进入真正的数据面

所以要分两层看：

1. “它们最终会不会写 PCM 数据”
- 会
- `tinyplay_ftm` 在成功路径里肯定会写，不然不会出现 `Playing sample`、`thread_result ok`
- `agmplay` 如果 `graph_open/graph_start` 成功，也一定会进入数据写入阶段

2. “它们的成功是不是因为单纯调用了 `pcm_write`”
- 不是
- 真正决定成败的关键在 `pcm_write` 之前那段准备链
- 这也是我这轮一直在强调的点

所以我之前那句话如果是说“它们根本不写 PCM”，那是错的。
正确说法应该是：

1. `tinyplay_ftm/agmplay` 不是“不写 PCM”
2. 而是“不是靠裸 PCM 写入就能成功”
3. 它们真正有价值的是写 PCM 之前那套准备逻辑

再细一点分：

1. `tinyplay_ftm`
- 在当前 recovery 的成功链里，已经走到了真正播放
- 所以它不仅准备了 graph，后面也确实写了 PCM

2. `agmplay`
- 在你现在这条失败链里，很多时候卡在 `graph_open -19`
- 这种失败实例里，它还没来得及走到真正的数据写入
- 但这不等于它这个程序“不会写 PCM”
- 只是这次失败没走到那一步

所以结论就一句：

我之前真正想表达的是“它们不是裸 PCM 工具，关键差异在写 PCM 前的准备链”，不是“它们根本不写 PCM”。

如果你要，我下一步就直接继续抠 `tinyplay_ftm` 在 `mixer_ctl_set_array` 之前那段本地准备逻辑，不再在这个表述上打转。

User: 你之前的结论，他们没写PCM，是依赖的库写的

GitHub Copilot: 对，这样说才准确。

我之前如果把结论压成一句，正确表述应该是：

1. `tinyplay_ftm` 和 `agmplay` 不是自己在可执行文件里手搓底层 PCM 写逻辑
2. 它们是通过依赖库去完成真正的数据面写入
3. 但从行为语义上，仍然应算“它们在写 PCM”

也就是要分清两层：

1. 实现层
- 可执行文件本体主要负责参数解析、XML/metadata/graph/session 准备、调用控制链
- 真正的 `pcm_open / pcm_write`、plugin 调度、session I/O，多数是在依赖库里完成
- 例如 `libtinyalsa`、`libagm_pcm_plugin`、`libagmclient` 这类库

2. 行为层
- 只要这个进程最终调用到了这些库去把数据送进 PCM/AGM，会话上就应算它“在播放/在写 PCM”
- 不能因为写动作落在库里，就说这个程序“没写 PCM”

所以我之前更严谨的说法应该是：

1. `tinyplay_ftm/agmplay` 的关键差异不在“有没有写 PCM”
2. 而在“它们在写 PCM 之前，通过依赖库和控制链补了大量 graph/session/metadata 准备”
3. 当前纯 C demo 缺的也不是“学会调用一个 `pcm_write` 函数”
4. 缺的是写之前那套能把图真正立起来的准备状态

一句话收口：

- 说“它们没写 PCM”不准确
- 说“它们自己不直接实现底层写入，而是依赖库完成真正的数据面写入”才准确

这也是为什么我后面把主线从“补 `pcm_write`”转回了“补 graph/session 前置状态”。因为单把写函数接上，确实不够。

User: 继续调试。不要给我二选一，你要做就都做

GitHub Copilot: 我继续并行压两条线：一条直接抠 `tinyplay_ftm` 成功路径在写 PCM 前到底补了什么，另一条把 `libagm_pcm_plugin` 里的 `session_set_config` 结构布局继续掰实，避免再靠猜。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && find . \( -name 'tinyplay_ftm*' -o -name 'agmplay*' -o -name 'libagm_pcm_plugin.so' -o -name 'libagmclient.so' \) | head -n 120

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && grep -n "probe_agm_session_open_close(" pure_c_agm_probe.c

Ran terminal command:  adb shell 'ls /odm/bin/tinyplay_ftm /vendor/bin/agmplay 2>/dev/null'

工作区里已经有 `tinyplay_ftm` 的本地样本和 objdump 文本，不用再从设备拉。下一步我直接读现成反汇编，把成功路径里 `mixer_ctl_set_array` 前的准备链抠出来，同时校正纯 C 探针的参数组合。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#2140-2140), lines 2140 to 2198

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#1-1), lines 1 to 320

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_manual' && grep -n "mixer_ctl_set_array\|mixer_ctl_set_enum_by_string\|XML_ParseBuffer\|XML_ParserCreate\|backend_conf\|usecaseKvManager\|graph_open\|thread_result" tinyplay_ftm_objdump_20260318.txt | head -n 200

我已经把 `tinyplay_ftm` 成功链上的关键调用点定位出来了。下一步直接读这些调用附近的反汇编，目标是把“XML 解析后到底写了哪些控件、顺序是什么、哪些是 enum 哪些是 array”具体抠成可复刻步骤。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#1400-1400), lines 1400 to 2025

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2180-2180), lines 2180 to 2725

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2830-2830), lines 2830 to 2895

我已经把 `tinyplay_ftm` 里的几个关键 helper 形状抠出来了：`rate ch fmt`、两个 metadata helper、一个 48B `setParam` helper、以及变长大 payload helper。下一步我直接找这些 helper 在主流程里的调用顺序，然后把同样顺序塞回纯 C demo 做对照。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_manual' && grep -n "bl\s\+0x5c40\|bl\s\+0x63d8\|bl\s\+0x6628\|bl\s\+0x689c\|bl\s\+0x6a54\|bl\s\+0x5f28\|bl\s\+0x5e1c" tinyplay_ftm_objdump_20260318.txt | head -n 200

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d --demangle libagm_pcm_plugin.so | sed -n '230,340p'

我已经拿到 `tinyplay_ftm` 主流程里这些 helper 的真实顺序了。现在直接读主流程这段代码，把每个调用前后的参数来源也抠出来，再决定哪些可以原样塞回纯 C probe。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#500-500), lines 500 to 860

`tinyplay_ftm` 的主链顺序已经清楚了：每个接口先做 `0x60f4 -> 0x63d8`，随后全局打一层 `0x6a54`，再对每个接口按 `0x689c -> connect -> getTaggedInfo(0xC0000019) -> 0x6628` 走一遍，然后才 `pcm_open`。我接着把中间那个 `connect` helper 和 `0x6628` 需要的参数关系再抠清楚，准备直接复刻进纯 C probe。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2060-2060), lines 2060 to 2185

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2588-2588), lines 2588 to 2698

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_manual' && strings tinyplay_ftm_bin_20260318 | grep -E "USB_AUDIO-RX|TDM-LPAIF|setParam|getTaggedInfo|connect|disconnect|metadata|rate ch fmt" | head -n 120

我先补一个不会破坏主线的观测点：直接按 `tinyplay_ftm` 的方式读取 `<intf> getTaggedInfo`，绕过 `agm_mixer_get_miid`。这样可以立刻判断现在卡的是“helper 没拿到值”，还是控件里根本就没有值。

Generating patch (168 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
我先不动更多 payload，只加了直接读 `getTaggedInfo` 的观测点。现在跑一组最接近 `tinyplay_ftm` 顺序的组合，看控件里到底有没有 `0xC0000019` 的条目。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb shell 'chmod 755 /data/local/tmp/pure_c_agm_probe && /data/local/tmp/pure_c_agm_probe --rate-ch-fmt-1 --pre-setparam-63d8 --metadata-6a54-plus-689c --direct-tagged-info --with-mfc'
Completed with input:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb shell 'chmod 755 /data/local/tmp/pure_c_agm_probe && /data/local/tmp/pure_c_agm_probe --rate-ch-fmt-1 --pre-setparam-63d8 --metadata-6a54-plus-689c --direct-tagged-info --with-mfc'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_K9tj5jD4hifxVam2aKhuEIhn__vscode-1773803651358/content.txt)

新信息已经出来了：`tinyplay_ftm` 这段查询并不是走 `<intf> getTaggedInfo`，因为设备上根本没有这个控件名。下一步我把 direct probe 改成优先读 `PCM100 getTaggedInfo`，按 `tinyplay_ftm` 的解析格式直接拆，确认它是不是已经有条目但被我们之前的 helper 漏掉了。

Generating patch (34 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
我把 direct 读取改成了先试接口控件、找不到就回退 `PCM100 getTaggedInfo`。现在再跑同一组组合，看 `PCM100 getTaggedInfo` 里到底有没有 `0xC0000019` 的条目。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb shell 'chmod 755 /data/local/tmp/pure_c_agm_probe && /data/local/tmp/pure_c_agm_probe --rate-ch-fmt-1 --pre-setparam-63d8 --metadata-6a54-plus-689c --direct-tagged-info --with-mfc'
Completed with input:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb shell 'chmod 755 /data/local/tmp/pure_c_agm_probe && /data/local/tmp/pure_c_agm_probe --rate-ch-fmt-1 --pre-setparam-63d8 --metadata-6a54-plus-689c --direct-tagged-info --with-mfc'

Ran terminal command:  grep -n "direct getTaggedInfo\|direct_get_tagged_info\|PCM100 getTaggedInfo\|agm_mixer_get_miid" '/Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_5fNjHHspBMx2jV7vPQ91mKDA__vscode-1773803651361/content.txt'

我继续把两条线都往前压一格：一条验证“去掉 helper-prep 后，纯手搓 tinyplay 顺序还能不能立起 tagged-info”，另一条验证“更贴近 0x60f4 原样 rate 写法时会不会改变当前边界”。

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --rate-ch-fmt-1 --pre-setparam-63d8 --metadata-6a54-plus-689c --direct-tagged-info --with-mfc'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --rate-ch-fmt-1 --pre-setparam-63d8 --metadata-6a54-plus-689c --direct-tagged-info --with-mfc'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --rate-60f4-words --pre-setparam-63d8 --metadata-6a54-plus-689c --direct-tagged-info --with-mfc'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --rate-60f4-words --pre-setparam-63d8 --metadata-6a54-plus-689c --direct-tagged-info --with-mfc'

两组新 A/B 已经跑完。现在我只抽关键结论，不再把整段日志倒给你：看 `direct_get_tagged_info`、`pcm_open` 和最终错误码有没有变化。

Ran terminal command:  grep -n "direct_get_tagged_info\|pcm_open\|打开失败\|post_connect_mfc\|setParam-63d8\|rate write" '/Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_CFnblKO1cQ2MB2tZln70yqyD__vscode-1773803651363/content.txt'

Ran terminal command:  grep -n "direct_get_tagged_info\|pcm_open\|打开失败\|post_connect_mfc\|setParam-63d8\|60f4\|rate write" '/Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_q79IJHB1mrqhuPB3x183Mczc__vscode-1773803651364/content.txt'

我不在原地复读日志，直接做下一组有信息增益的 A/B：既然 `devicepp_kv` 已经确认能进 GKV，那下一步就试把实例相关的已知候选键也塞进 session GKV，看 `agm_session_open -19` 会不会松动。

Generating patch (133 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
我把 session GKV 的两个实例候选键都接进探针了。现在先跑 `A3000004`，看 `agm_session_open` 和 service 侧 graph 日志有没有任何松动；如果有，再跑 `A3000006`。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb shell 'chmod 755 /data/local/tmp/pure_c_agm_probe && /data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-devicepp-a3004-aif-media-preconnect-init'
Completed with input:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb push pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb shell 'chmod 755 /data/local/tmp/pure_c_agm_probe && /data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-devicepp-a3004-aif-media-preconnect-init'

`A3000004` 已经命中并进入 metadata，但 `agm_session_open` 还是 `-19`。我紧接着跑 `A3000006`，确认这两个已知实例候选键都不是下一跳。

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-devicepp-a3006-aif-media-preconnect-init'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-devicepp-a3006-aif-media-preconnect-init'

这两条实例候选键都命中了用户态写入，但 `agm_session_open` 仍是 `-19`。我再补抓一次 service 侧 metadata 打印，确认它们确实已经进 GKV，而不是客户端写了、服务端没收。

Ran terminal command:  adb shell 'logcat -d -b all | grep -E "GKV size|key:0xa3000000|key:0xac000000|graph_open: 615 entry|graph_open: 850 exit|session_open_with_first_device" | tail -n 120'

我把这轮最关键的新收敛写进仓库记忆：`devicepp` 和两个 `A300` 实例候选键都已经确认能进服务端 GKV，但还不足以把 session open 推过去。后面就不用再重复这三组。

Created memory file twrp_audio_session_gkv_a300_candidates_20260318.md

我继续往前，不停在“这三组没用”这个结论上。下一步直接从本地 `agmplay` 二进制里搜实例和 GKV 相关常量，看看成功路径里除了 `devicepp` 和 `A3000004/6` 之外还写了哪些候选键。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d agmplay | grep -n "a3000004\|a3000006\|a2000001\|ac000002\|a100000e\|d2000000\|a4000000\|a5000000\|a6000000" | head -n 200

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && strings agmplay | grep -E "devicepp|instance|stream_kv|device_kv|getTaggedInfo|setParam|metadata|rate ch fmt|graph_open" | head -n 200

字符串证实了 `agmplay` 本身就把 `deviceppkv` 和 `instance_kv` 当一等参数。下一步我直接从反汇编里搜装载这些常量的指令模式，不靠明文十六进制文本。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d agmplay | grep -n "movk.*#0xa300\|movk.*#0xa200\|movk.*#0xac00\|movk.*#0xa100\|movk.*#0xd200\|movk.*#0xa400\|movk.*#0xa500\|movk.*#0xa600" | head -n 240

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d agmplay | grep -n "set_agm_stream_metadata@plt\|set_agm_streamdevice_metadata@plt\|set_agm_audio_intf_metadata@plt\|connect_agm_audio_intf_to_stream@plt\|agm_mixer_get_miid@plt\|configure_mfc@plt" | head -n 120

`agmplay` 的 helper 顺序也定位到了，而且和 `tinyplay_ftm` 不完全一样。现在我直接读这一段主流程，目的是把两条成功链的共同部分和差异部分分开，避免后面继续把无关动作塞进纯 C probe。我不能直接读二进制本体，所以改成把这段 `agmplay` 反汇编导出来再读。结果会更干净，也能精确看到 helper 前后的参数来源。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d agmplay | sed -n '2528,2692p'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_ZQHLi7CLhnXwAroudL25hW9R__vscode-1773803651377/content.txt)

Compacted conversation正在把 agmplay 主流程和 tinyplay_ftm 做逐调用对齐，先确认它们在 pcm_open 之前共享哪些准备步骤，再把共性顺序塞回纯 C probe。下一步我会补读 agmplay 邻近反汇编，并同时检查现有 pure C 代码里对应步骤是否缺序或参数错位。Optimizing tool selection...

Created 5 todos

我已经看到 agmplay 在每个接口上先做 device media config 和 audio intf metadata，然后统一下发 stream metadata，之后再进入 per-device metadata、connect、MIID、MFC 这一段。现在补前后文，确认它和 tinyplay_ftm 的差别到底是在顺序、payload，还是条件分支。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d agmplay | sed -n '2488,2528p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d agmplay | sed -n '2692,2748p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d agmplay | sed -n '2748,2816p'

agmplay 的关键差异已经露出来了：它在 pcm_open 前做的是 device media config 和 audio intf metadata 的按接口循环，然后统一下发 stream metadata，再做 streamdevice metadata、connect、MIID、MFC；pcm_open 之后还有一轮 group mux/group device 配置。这意味着我们现有 probe 不只是少几个 key，更可能是少了 post-open 的 group 配置链。

Searched for regex `set_agm_device_media_config|set_agm_audio_intf_metadata|set_agm_stream_metadata|set_agm_streamdevice_metadata|connect_agm_audio_intf_to_stream|agm_mixer_get_miid|configure_mfc|group` (`**/pure_c_agm_probe.c`), 26 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1-1), lines 1 to 260

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1460-1460), lines 1460 to 1645

Searched for regex `standard-card0-16|probe-session-open|direct-tagged-info|metadata-6a54|rate-60f4|skip-helper-prep` (`**/pure_c_agm_probe.c`), 39 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1645-1645), lines 1645 to 2215

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#2215-2215), lines 2215 to 2365

我在对参数位序了。现在最可疑的不再只是“少一步”，而是我们某些 helper 的函数签名本身就可能猜错了，尤其是 stream metadata 这一类。如果参数位序错了，前面很多 rc=0 也可能只是写进了不对的位置。

Searched for regex `set_agm_stream_metadata\(|set_agm_streamdevice_metadata\(|set_agm_audio_intf_metadata\(|connect_agm_audio_intf_to_stream\(|configure_mfc\(` (`**/*.{h,c,cpp,cc}`), 5 results

Searched for regex `get_group_device_info|set_agm_group_device_config|set_agm_group_mux_config` (`**/*.{h,c,cpp,cc}`), no results

Searched for files matching `**/*agm*.h`, 102 matches

Searched for files matching `**/*agmmixer*`, 3 matches

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n "set_agm_stream_metadata|set_agm_group_device_config|set_agm_group_mux_config|agm_mixer_get_miid" twrp_a16_compile twrp_a12_compile audio_manual device_tree -g '*.[ch]' -g '*.hpp' -g '*.cpp' | head -n 120

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && readelf -Ws libagmmixer.so | rg 'set_agm_group_device_config|set_agm_group_mux_config|get_group_device_info'
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && readelf -Ws libagmmixer.so | rg 'set_agm_group_device_config|set_agm_group_mux_config|get_group_device_info'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-readelf -Ws libagmmixer.so | rg 'set_agm_group_device_config|set_agm_group_mux_config|get_group_device_info'
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-readelf -Ws libagmmixer.so | rg 'set_agm_group_device_config|set_agm_group_mux_config|get_group_device_info'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && nm -gU libagmmixer.so | rg 'set_agm_group_device_config|set_agm_group_mux_config|get_group_device_info|set_agm_stream_metadata|configure_mfc'
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && nm -gU libagmmixer.so | rg 'set_agm_group_device_config|set_agm_group_mux_config|get_group_device_info|set_agm_stream_metadata|configure_mfc'

group helper 这条线我也在确认可操作性：如果 libagmmixer 没导出对应符号，纯 C probe 就算知道顺序也无法直接调用，只能退回控制面直写或 session 路径。现在先查导出表，再决定是补 helper 还是继续从 mixer control payload 入手。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && objdump -T libagmmixer.so | rg 'set_agm_group_device_config|set_agm_group_mux_config|get_group_device_info|set_agm_stream_metadata|configure_mfc'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && strings libagmmixer.so | rg 'set_agm_group_device_config|set_agm_group_mux_config|get_group_device_info|set_agm_stream_metadata|configure_mfc'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && strings -t x agmplay | rg '96f|98e|92c|9b2|8ee|509|911|8b2|9db'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d agmplay | sed -n '2448,2488p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d agmplay | rg 'set_agm_stream_metadata_type@plt|set_agm_stream_metadata@plt'

我先不盲改代码，先拿现有 probe 验证一个更贴近 agmplay 的“纯 helper 链”组合，确认到底是不是我们前面那些 PCM100 直写把状态弄脏了。如果 helper-only 也还是卡在同一处，再去补新 helper。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh

Ran terminal command:  adb devices

Ran terminal command:  adb push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe' /data/local/tmp/pure_c_agm_probe && adb shell chmod 755 /data/local/tmp/pure_c_agm_probe && adb logcat -c && adb shell '/data/local/tmp/pure_c_agm_probe --helper-connect --skip-initial-control --skip-rate-write --skip-split-metadata --with-mfc --pcm-backend --play-after-open --play-seconds 3'
Completed with input:  adb push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe' /data/local/tmp/pure_c_agm_probe && adb shell chmod 755 /data/local/tmp/pure_c_agm_probe && adb logcat -c && adb shell '/data/local/tmp/pure_c_agm_probe --helper-connect --skip-initial-control --skip-rate-write --skip-split-metadata --with-mfc --pcm-backend --play-after-open --play-seconds 3'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_AeQhE1R4Xn5ZbwkKSXqAoPk2__vscode-1773803651404/content.txt)

Ran terminal command:  adb logcat -d | rg 'PureCAgmProbe|agm|graph_open|getTaggedInfo|mixer_ctl_get_array|Failed to mixer_ctl_get_array|Connect failed|PCM100|audio_hw_primary|aw882xx'

helper-only 结果已经出来了，结论很硬：把所有 PCM100 直写都去掉以后，前沿完全没动，还是 `getTaggedInfo -19`，最终 plugin open 还是 `-19`。这说明问题不在我们“写脏了控件”，而在 helper 链本身仍缺状态，或者缺的状态根本不在这些现有 helper 里。

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1180-1180), lines 1180 to 1465

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_manual' && rg -n "0x60f4|0x63d8|0x689c|0x6a54|getTaggedInfo|setParam" tinyplay_ftm_objdump_20260318.txt | head -n 120

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#532-532), lines 532 to 584

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#730-730), lines 730 to 770

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#770-770), lines 770 to 805

我现在把矛头重新收束到 60f4/63d8/689c/6a54 这几段了。因为 helper-only 路径已经证伪，而 agmplay/tinyplay_ftm 的共性正好都落在这些额外 payload helper 上，它们才是最可能缺失的真实状态。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#1885-1885), lines 1885 to 1985

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2035-2035), lines 2035 to 2145

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2165-2165), lines 2165 to 2245

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2260-2260), lines 2260 to 2355

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2355-2355), lines 2355 to 2445

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2520-2520), lines 2520 to 2625

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2450-2450), lines 2450 to 2520

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2625-2625), lines 2625 to 2725

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2725-2725), lines 2725 to 2815

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2815-2815), lines 2815 to 2895

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_manual' && strings -t x tinyplay_ftm_bin_20260318 | rg '3ee|a5b|2a5|3f7|82e|7e5'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_manual' && strings -t x tinyplay_ftm_bin_20260318 | rg 'a5b|5bd|561|59c|16b|536|240|886|487|27f'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_manual' && strings -t x tinyplay_ftm_bin_20260318 | rg '1a5b|1a65|19dc|1af8|1ae0|1a27|1536|1886'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_manual' && strings tinyplay_ftm_bin_20260318 | rg '^PCM$|PCM100|COMPRESS|connect|disconnect|rate ch fmt|metadata|getTaggedInfo|setParam$'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_manual' && strings -t x tinyplay_ftm_bin_20260318 | rg '1a70|1a5f|1a65|13ee|17e5|182e|13f7|12a5'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_manual' && strings -t x tinyplay_ftm_bin_20260318 | rg '1a5.'

我要改两处核心行为。第一，把我们自以为的 63d8 “setParam” 纠正成实际的 metadata 写入目标；第二，把 6a54/689c 前后的 control 切换补成更接近 tinyplay_ftm 的顺序，也就是先 ZERO 再 metadata，再切回接口名再 metadata。

Generating patch (58 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```


Checked [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c), 24 problems found

我已经把 63d8 从错误的 setParam 目标改回 metadata，并补上了 6a54/689c 的 control 切换。接下来直接编译上机，看 tagged-info 和 plugin open 是否发生位移。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh
Completed with input:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh

Ran terminal command:  adb push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe' /data/local/tmp/pure_c_agm_probe && adb shell chmod 755 /data/local/tmp/pure_c_agm_probe

编译挡住的是一个前置声明问题，不是逻辑问题。我补一个原型声明就继续上机验证。

Generating patch (13 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```


Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh

Ran terminal command:  adb devices

现在跑的是最接近 tinyplay_ftm 主链的一组：`60f4 -> 63d8 -> 6a54 -> 689c -> connect -> getTaggedInfo/MFC`。这次的目标很具体，只看 `getTaggedInfo` 和最终 plugin open 有没有从 `-19` 挪动。

Ran terminal command:  adb push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe' /data/local/tmp/pure_c_agm_probe && adb shell chmod 755 /data/local/tmp/pure_c_agm_probe && adb logcat -c && adb shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --rate-60f4-words --pre-setparam-63d8 --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend'
Completed with input:  adb push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe' /data/local/tmp/pure_c_agm_probe && adb shell chmod 755 /data/local/tmp/pure_c_agm_probe && adb logcat -c && adb shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --rate-60f4-words --pre-setparam-63d8 --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_U4tYx8sShitfCKDRvfbel0ID__vscode-1773803651435/content.txt)

Ran terminal command:  adb logcat -d | rg 'PureCAgmProbe|agm|graph_open|getTaggedInfo|mixer_ctl_get_array|Failed to mixer_ctl_get_array|Connect failed|PCM100|audio_hw_primary'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_pKvfLBrcWyMUGGKZ8m2NC10R__vscode-1773803651437/content.txt)

前沿确实动了，不是噪声。原来这条链是 `Connect failed -19`，现在已经变成 `Connect failed -5`，而且 plugin 侧只剩一次 `Failed to mixer_ctl_get_array`。这说明 63d8 目标和 control 切换方向是对的，接下来该扫的是 63d8 里的 pair 选择和 6628 之后那段。

Ran terminal command:  adb logcat -c && adb shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --rate-60f4-words --pre-setparam-63d8-a3004 --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend' | rg 'preopen|direct_get_tagged_info|post_connect_mfc|打开失败|helper_connect|metadata-6a54|metadata-689c|metadata-63d8'
Completed with input:  adb logcat -c && adb shell '/data/local/tmp/pure_c_agm_probe --skip-helper-prep --skip-initial-control --rate-60f4-words --pre-setparam-63d8-a3004 --metadata-6a54-plus-689c --helper-connect --direct-tagged-info --with-mfc --pcm-backend' | rg 'preopen|direct_get_tagged_info|post_connect_mfc|打开失败|helper_connect|metadata-6a54|metadata-689c|metadata-63d8'

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_w9S3ckNvZ1fXWAk3nWg3O7kf__vscode-1773803651439/content.txt)

Ran terminal command:  adb logcat -d | rg 'Connect failed error|agm_session_aif_get_tag_module_info|Failed to mixer_ctl_get_array|graph_open|record open session_id'

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2145-2145), lines 2145 to 2205

Made changes.


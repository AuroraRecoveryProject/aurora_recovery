# 第8章：Tag面对照与pre-connect源码溯源收口

User: 继续

GitHub Copilot: 我直接沿着“helper 比 agmplay 少了哪一步”往下做静态对照，先找仓库里现成的 `agmplay` 行为证据和任何 `graph_open/graph_start` 相关记录，目标是把缺失动作压到具体调用级别。

Ran terminal command:  rg -n "agmplay|graph_open|graph_start|set_agm_|tagged info|module info|audioreach|strace.*agmplay|agm_mixer_plugin|graph_" docs audio_manual video_player

Ran terminal command:  find audio_manual -maxdepth 2 \( -iname '*agmplay*' -o -iname '*strace*' -o -iname '*agm*' \) | sed -n '1,120p'

我已经拿到一份总索引和两份现成 strace 线索。下一步只读最相关片段：一份看 `agmplay/graph_*` 的文档记录，一份看 `demo_minimal` 的实际调用序列，目标是找出 helper 当前缺的那类调用。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3228-3228), lines 3228 to 3268

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_diHBlRYNMh3VUuhFutFEeGN8__vscode-1774362628714/content.txt#1-1), lines 1 to 260

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/strace_demo_minimal_20260318.txt#2680-2680), lines 2680 to 2825

现在线索已经指向旧文档里那几处“还没补上的 agmplay 步骤”，我把相关段落补读出来，目标是从历史分析里直接提取最像缺口的调用，而不是重新从零猜。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3323-3323), lines 3323 to 3352

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3498-3498), lines 3498 to 3524

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#4938-4938), lines 4938 to 4998

旧结论已经给了一个非常具体的实验方向：当前 helper 可能还缺那条“手工 `<intf> rate ch fmt`”写入。我先确认这段能力在现有最小播放器里有没有；如果没有，就直接补一个最小实验开关去实机验证。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#950-950), lines 950 to 1120

Ran terminal command:  rg -n "rate ch fmt|setParamTag|setParam|write_u32_at\(media_config|media_config.*0x50|media_config.*0x54|media_config.*0x58|PCM100 metadata|helper-prep|skip-rate-write" video_player/agm_audio_minimal.c video_player/agm_audio_minimal_main.c video_player/pure_c_agm_probe.c

旧材料已经把两个最像缺口的点缩到很小了：
1. `connect` 前的 `get_miid(tag=0xC0000004)`
2. 以及那条手工 `<intf> rate ch fmt` 写入

我先把 probe 里现成的“直写 rate ch fmt”实现读出来，准备最小复用到 helper CLI 里做一次 A/B 实机验证。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#1588-1588), lines 1588 to 1728

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2548-2548), lines 2548 to 2634

probe 里现成的 4-word 直写已经足够做实验了。我先确认最小播放器里是否已经有可复用的底层 `set_array/word-write` helper；如果有，我就直接接一个窄开关，不扩散到主路径。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#540-540), lines 540 to 640

Ran terminal command:  rg -n "set_mixer_array|write_pcm100_words|set_mixer_int\(|set_mixer_enum\(|write_u32_at|pcm_format_to_alsa_format|sample_format_to_pcm_format" video_player/agm_audio_minimal.c

底层写入工具已经齐了，我只需要给最小播放器加一个窄实验开关和一段最小直写逻辑，不碰默认路径。先把配置结构读出来，确定最小改动面。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.h)

Ran terminal command:  rg -n "typedef struct AgmAudioPlayerConfig|AgmAudioPlayerConfig|agm_audio_player_config_init" video_player/agm_audio_minimal.h video_player/agm_audio_minimal.c

配置结构很小，适合直接加一个实验字段。我先读初始化和 open 入口周边，避免碰到和 WAV 路径的隐性耦合。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#1056-1056), lines 1056 to 1180

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#1330-1330), lines 1330 to 1410

我刚确认到一个更硬的点：当前 `agm_audio_player_open` 里根本没走 `prime_agm_helper_prep`，只打了 `PCM100 metadata + helper_connect + post-connect MFC`。我先把这件事确认成代码事实，再决定是补 `helper_prep` 还是补直写实验。

Ran terminal command:  rg -n "prime_agm_helper_prep\(" video_player/agm_audio_minimal.c

这已经不是猜测了：`prime_agm_helper_prep` 实现存在，但当前 `agm_audio_player_open` 完全没调用。按照前面的 `agmplay` 时序，这一步本来就应该属于 pre-open 主链。我先把这处缺口补上，再直接编译做 1 秒寄存器对照。

Generating patch (25 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c)


```

```
我已经补上最明显的时序缺口。接下来直接编译、推送、跑同一个 WAV，再用同样的 1 秒 AW 寄存器采样看它是不是终于能离开 idle 图谱。

Checked [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c), 22 problems found

Ran terminal command:  bash ./video_player/build_agm_audio_minimal.sh

构建已经成功，编辑器里的这些报错还是本机头文件缺失导致的旧问题，不影响刚才的交叉编译产物。现在直接把新二进制推到设备并做同一套 1 秒寄存器对照。

Ran terminal command:  adb push video_player/agm_audio_minimal_bin /data/local/tmp/agm_audio_minimal_bin

Ran terminal command:  adb shell chmod 755 /data/local/tmp/agm_audio_minimal_bin

部署完成。下一步就是唯一关键验证：新 helper 播放同一个 `test440_mid_10s.wav` 时，`1.2s` 的 6 颗 AW 寄存器位有没有从 idle 图谱跳到 `agmplay` 那组工作态。

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --wav /data/local/tmp/test440_mid_10s.wav'

Ran terminal command:  sleep 1.2 && adb shell 'for d in 4-0034 4-0035 4-0036 9-0034 9-0035 9-0036; do echo ==== $d; cat /sys/bus/i2c/devices/$d/reg 2>/dev/null | grep -E "^reg:0x(04|08|20|23|24|25|26|28|2b)="; done'

Ran terminal command:  sleep 1.2 && adb shell 'for p in /sys/kernel/debug/asoc/sun-mtp-snd-card/dapm/bias_level /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0034/dapm/Speaker_Playback_4_34; do echo ==== $p; cat $p 2>/dev/null; done'

补入 `helper_prep` 后，1 秒 AW 寄存器还是完全 idle，没有任何改善。我把这轮收尾对上播放日志，确认这次不是 `helper_prep` 提前失败，而是真正“调用了也没推进”。

Awaited terminal completion

Ran terminal command:  adb shell 'dmesg | grep -E "aw882xx_(startup|hw_params|start_pa|shutdown|mute)" | tail -n 80'

`helper_prep` 单独补上没有任何推进，说明它不是唯一缺口。下一步我直接把已知最可疑的那条“手工 `<intf> rate ch fmt` 直写”做成一个窄实验开关，避免继续靠文档推理空转。

Generating patch (12 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.h)


```

```
我把实验开关接到实现里，只做最小 4-word 直写，不改默认路径。这样可以直接回答“这一步是否就是 helper 缺口”。

Generating patch (71 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c)


```

```
最后把 CLI 接出来，默认仍关闭；只有显式带开关时才走这条实验路径。

Generating patch (16 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal_main.c)


```

```
代码已经改完。我先重新编译，确认这个窄实验开关不影响构建，再直接用同一个 WAV 做 1 秒 AW 寄存器 A/B。

Checked [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c), [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.h), [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal_main.c), 23 problems found

Ran terminal command:  bash ./video_player/build_agm_audio_minimal.sh

构建没问题，编辑器报错还是同一类本机头文件缺失噪声。我直接推新二进制并跑 `--force-rate-write --wav ...`，看 1 秒 AW 寄存器是否终于跳出 idle。

Ran terminal command:  adb push video_player/agm_audio_minimal_bin /data/local/tmp/agm_audio_minimal_bin

Ran terminal command:  adb shell chmod 755 /data/local/tmp/agm_audio_minimal_bin

现在只差最后一个关键 A/B：同一个 WAV、同一个 helper，但显式加上 `--force-rate-write` 后，1 秒时 6 颗 AW 寄存器有没有从 idle 图谱跳到工作态。

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --force-rate-write --wav /data/local/tmp/test440_mid_10s.wav'

Ran terminal command:  sleep 1.2 && adb shell 'for d in 4-0034 4-0035 4-0036 9-0034 9-0035 9-0036; do echo ==== $d; cat /sys/bus/i2c/devices/$d/reg 2>/dev/null | grep -E "^reg:0x(04|08|20|23|24|25|26|28|2b)="; done'

Ran terminal command:  sleep 1.2 && adb shell 'for p in /sys/kernel/debug/asoc/sun-mtp-snd-card/dapm/bias_level /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0034/dapm/Speaker_Playback_4_34; do echo ==== $p; cat $p 2>/dev/null; done'

`--force-rate-write` 也没把 1 秒寄存器推离 idle。我把这轮日志收尾对上，重点看直写本身的返回值，确认这一步到底是“调用成功但没效果”还是“根本没写进去”。

Awaited terminal completion

我发现这轮 `--force-rate-write` 其实没生效到 WAV 路径上：CLI 带了配置，但 `--wav` 分支直接调了不带配置的 `agm_audio_player_play_wav_file`，把实验开关丢了。这不是环境问题，是代码路径本身的真 bug。我先把它修掉，再重跑实验。

Generating patch (10 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.h)


```

```
我把 WAV 路径的配置透传补到库里，保留旧 API 不动，只新增一个带配置的入口，避免影响现有调用方。

Using "Apply Patch"

补丁上下文没对上，我直接读 WAV 播放函数完整段落后重打一次，避免误改。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#1330-1330), lines 1330 to 1515

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#1515-1515), lines 1515 to 1559

现在上下文够了，我只做兼容式补丁：抽一个内部实现，旧 API 继续保留，新 API 才带配置。然后 main 的 `--wav` 分支改用新入口。

Generating patch (28 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c)


```

```
我再把 main 的 WAV 分支接到新入口上，保证 `--force-rate-write` 这类实验参数不会再在 `--wav` 路径上丢失。

Generating patch (23 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal_main.c)


```

```
我重新编译并直接复跑同一组 `--force-rate-write --wav` 验证，目标很明确：这次日志里必须能看到直写返回值，1 秒寄存器也要么跳变、要么证明这一步即使真实生效也仍然不够。

Ran terminal command:  bash ./video_player/build_agm_audio_minimal.sh

Ran terminal command:  adb push video_player/agm_audio_minimal_bin /data/local/tmp/agm_audio_minimal_bin && adb shell chmod 755 /data/local/tmp/agm_audio_minimal_bin

部署完成。我直接重跑最终实验版本的 `--force-rate-write --wav`，这次重点同时看两件事：
1. 终端日志里有没有 `direct rate ch fmt write rc=...`
2. 1 秒时 6 颗 AW 寄存器是否从 idle 图谱跳变。

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --force-rate-write --wav /data/local/tmp/test440_mid_10s.wav'

Ran terminal command:  sleep 1.2 && adb shell 'for d in 4-0034 4-0035 4-0036 9-0034 9-0035 9-0036; do echo ==== $d; cat /sys/bus/i2c/devices/$d/reg 2>/dev/null | grep -E "^reg:0x(04|08|20|23|24|25|26|28|2b)="; done'

Ran terminal command:  sleep 1.2 && adb shell 'for p in /sys/kernel/debug/asoc/sun-mtp-snd-card/dapm/bias_level /sys/kernel/debug/asoc/sun-mtp-snd-card/aw882xx_smartpa.4-0034/dapm/Speaker_Playback_4_34; do echo ==== $p; cat $p 2>/dev/null; done'

这次实验终于给了一个新的硬结果：`--force-rate-write` 会把 `pcm_open` 直接从原来的 `-19` 推到 `-5`。我把完整日志收尾读出来，确认直写本身确实成功，这样就能把“缺口至少包括 `<intf> rate ch fmt`”这件事写死。

Awaited terminal completion

我再补一刀纯观测，不改行为：把 `connect` 前的 `agm_mixer_get_miid(tag=0xC0000004)` 日志接到 helper 里。这样能直接回答“helper 现在连 agmplay 那个 pre-connect module info 都拿不到，还是拿到了但后续仍少别的动作”。

Generating patch (37 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c)


```

```
我编译后只跑一轮最关键的 `--force-rate-write --wav`，目标不是再看寄存器，而是看 pre-connect `tag=0xC0000004` 的 MIID 到底能不能拿到。

Ran terminal command:  bash ./video_player/build_agm_audio_minimal.sh && adb push video_player/agm_audio_minimal_bin /data/local/tmp/agm_audio_minimal_bin && adb shell chmod 755 /data/local/tmp/agm_audio_minimal_bin

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --force-rate-write --wav /data/local/tmp/test440_mid_10s.wav'
Completed with input:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --force-rate-write --wav /data/local/tmp/test440_mid_10s.wav'

Compacted conversation结果已经把范围再收窄一层了：helper 在 connect 前就能拿到 `tag=0xC0000004` 的 MIID，说明缺口不在“完全没有 pre-connect module 发现”。我接着回查现有文档和代码里 `0xC0000004/16505` 的历史语义，看它后面在 `agmplay` 里是否还伴随额外 setParam 或另一段 payload。Optimizing tool selection...

Ran terminal command:  rg -n "0xC0000004|C0000004|16505|get_miid|setParam|configure_mfc|PCM100" docs video_player /memories/repo
Completed with input:  rg -n "0xC0000004|C0000004|16505|get_miid|setParam|configure_mfc|PCM100" docs video_player /memories/repo

Read memory twrp_audio_aw882xx_frontier.md

Read memory twrp_audio_pcm100_setparamtag.md

我先不扩散实验面。现在最有价值的是把历史里 `tag4` 周边的 helper 动作串起来，确认 `agmplay` 在“拿到 tag4 MIID”之后、`pcm_open` 之前还做没做别的。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_UDB6QRJyMD13agjzYudVM102__vscode-1774362628769/content.txt#1-1), lines 1 to 240

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#3323-3323), lines 3323 to 3348

现在有一个比刚才更明确的差异候选了：历史结论里 `agmplay` 是单次 `set_agm_stream_metadata(instance_kv<<16)`，如果当前 helper 还是双调用，那就不是“小噪音差异”，而是顺序和 payload 形态都没对齐。我要直接查现码。

Searched for text `set_agm_stream_metadata` (`**/video_player/agm_audio_minimal.c`), 4 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#920-920), lines 920 to 960

Searched for text `instance_kv` (`**/video_player/agm_audio_minimal.c`), 6 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#900-900), lines 900 to 915

Searched for regex `custom_payload|get_agm_usb_audio_config_payload|set_agm_device_custom_payload` (`**/video_player/agm_audio_minimal.c`), no results

Searched for regex `set_agm_device_custom_payload|get_agm_usb_audio_config_payload|custom payload|custom_payload` (`**/docs/**`), 7 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#4938-4938), lines 4938 to 4995

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#700-700), lines 700 to 740

我准备做一个最小观测补丁，不改行为，只把 pre-connect 的 `tag4` 从两层都打出来：`direct_get_tagged_info` 和 `agm_mixer_get_miid`。如果这两层都成立，而 AW 仍不进工作态，就可以更有把握地把主缺口从“tag4 不存在”排除掉。

Created 4 todos

Generating patch (42 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c)


```

```
补丁已经下去。下一轮我只验证两件事：`after helper_connect` 之后 `tag4` 还在不在，以及它是否和 `tag19` 一样形成稳定骨架。

Checked [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c), 22 problems found

Ran terminal command:  bash ./video_player/build_agm_audio_minimal.sh && adb push video_player/agm_audio_minimal_bin /data/local/tmp/agm_audio_minimal_bin && adb shell chmod 755 /data/local/tmp/agm_audio_minimal_bin

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --force-rate-write --wav /data/local/tmp/test440_mid_10s.wav'
Completed with input:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --force-rate-write --wav /data/local/tmp/test440_mid_10s.wav'

运行结果已经出来了。我先抽取关键几行，不重新铺大日志，只看 `tag4/tag19` 在不同 phase 的骨架有没有变化。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_mZ37wPPEEghauBOVNGQdseX0__vscode-1774362628786/content.txt)

结论已经足够硬了：`tag4` 不但在 connect 前能拿到，而且在 connect 后、post-connect MFC 后都稳定保留成 `value=1 / miid=16505`。这意味着当前最像根因的，不再是“helper 没建出 pre-connect custom module”，而是 `pcm_open` 侧还期待另一段 graph/plugin 输入。

Searched for regex `pcm_plug_open: failed to open plugin|Failed to mixer_ctl_get_array|Instance key is added` (`**/docs/**`), 35 results

Searched for regex `16505|0xc0000004|pre-connect agm_mixer_get_miid` (`**/docs/**`), 10 results

Read memory /memories/repo/

我把这次新收敛记进仓库记忆，后面就不用再反复回溯“tag4 曾经是不是没立起来”这个分支了。

Created memory file twrp_audio_tag4_stable_but_pcmopen_still_minus5_20260324.md

下一步不应该再去猜 `setParamTag`。既然 `tag4/tag19` 两套 MIID 都已经稳定，我更倾向于先把 `PCM100 getTaggedInfo` 的 16 个 entry 全量打出来，看 helper 现在到底少哪一个 tag，而不是继续盲补 helper。

Searched for regex `entries=16|getTaggedInfo|dump.*tag|dump.*entry|tagged info` (`**/video_player/agm_audio_minimal.c`), 2 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#780-780), lines 780 to 860

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#860-860), lines 860 to 915

Searched for regex `key = read_u32_at\(buffer, offset\)|entry_count = read_u32_at\(buffer, 0\)|PCM100 array` (`**/video_player/pure_c_agm_probe.c`), 3 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#1418-1418), lines 1418 to 1460

我再做一个只增日志的小补丁，把 `PCM100 getTaggedInfo` 的 entry 全量展开。现在不是缺“再多一个 helper”，而是缺“看到 plugin 眼里的完整 tag 面”。

Generating patch (26 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c)


```

```


Starting: *重编译并复测 helper* (3/4)

Checked [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c), 22 problems found

Ran terminal command:  bash ./video_player/build_agm_audio_minimal.sh && adb push video_player/agm_audio_minimal_bin /data/local/tmp/agm_audio_minimal_bin && adb shell chmod 755 /data/local/tmp/agm_audio_minimal_bin

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --force-rate-write --wav /data/local/tmp/test440_mid_10s.wav'
Completed with input:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --force-rate-write --wav /data/local/tmp/test440_mid_10s.wav'

我现在只提取 `entry[...]` 那些行。看完整 tag 集合比再看一次 `pcm_open -5` 更有信息量。

Searched for regex `direct_get_tagged_info entry\[|runtime direct_get_tagged_info|runtime agm_mixer_get_miid|pre-connect agm_mixer_get_miid|pcm_open failed` (`**//Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_ylvMOr436B1OV6ZrBn4Z4oZJ__vscode-1774362628801/content.txt`), no results

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_ylvMOr436B1OV6ZrBn4Z4oZJ__vscode-1774362628801/content.txt#40-40), lines 40 to 116

现在已经不是只有 `tag4/tag19` 两个点，而是 helper 实际已经立起一串 tag：`0xc0000004/6/7/d/e/10/11/13/19`。这更像是“图里的 tagged-info 面已经出来了，但 plugin 还要另一类输入”，而不是少某个单独 tag。

Searched for regex `0xc0000006|0xc0000007|0xc000000d|0xc000000e|0xc0000010|0xc0000011|0xc0000013|0xc0000019` (`**/docs/**`), 58 results

Searched for regex `0xc0000006|0xc0000007|0xc000000d|0xc000000e|0xc0000010|0xc0000011|0xc0000013` (`**/video_player/**`), no results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#1668-1668), lines 1668 to 1680

我准备把比较对象从“helper 自己”切到“agmplay 正在播放时的同一组 tagged-info entry”。如果两边 tag 集合一样，那主缺口就在 plugin/pcm open 之后；如果不一样，就能直接锁定少了哪一项。

Searched for regex `snapshot|inspect|dump.*runtime|open-close-cycles|play-cycles|wav|tone` (`**/video_player/agm_audio_minimal_main.c`), 20 results

Searched for regex `agm_audio_player_open|agm_audio_player_close|agm_audio_player_` (`**/video_player/agm_audio_minimal.h`), 7 results

我打算加一个纯观测入口，不走 `pcm_open`，只开 mixer 并打印当前 `PCM100 getTaggedInfo` 快照。这样就能在 `agmplay` 背景播放时，直接用同一套日志代码对照它的 tag 面。

Searched for regex `load_runtime|ensure_.*loaded|mixer_open\(|load_.*symbols|initialize|dlopen` (`**/video_player/agm_audio_minimal.c`), 9 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#1028-1028), lines 1028 to 1088

Searched for regex `static int load_tinyalsa|static int load_agm_mixer|load_agm_mixer\(` (`**/video_player/agm_audio_minimal.c`), 3 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#1128-1128), lines 1128 to 1168

Searched for regex `agmplay .*test440_mid_10s.wav|/vendor/bin/agmplay| agmplay ` (`**/docs/**`), 21 results

我加一个 `--snapshot-only`，不触发 helper，不碰 `pcm_open`，只做只读快照。这样可以直接在 `agmplay` 背景播放时拿到它的 `PCM100 getTaggedInfo` 面。

Using "Apply Patch"

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.h)

Generating patch (13 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.h)


```

```


Searched for regex `int agm_audio_player_play_tone|int agm_audio_player_play_wav_file_with_config|int agm_audio_player_play_wav_file\(` (`**/video_player/agm_audio_minimal.c`), 3 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#1308-1308), lines 1308 to 1620

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal_main.c)

Generating patch (32 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c)


```

```


Generating patch (35 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal_main.c)


```

```
补丁很小，目标也单一：让同一份观测代码能在 `agmplay` 运行时旁路读取 mixer。接下来我只做一次 background `agmplay` 加一次 `--snapshot-only` 对照。

Checked [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c), [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.h), [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal_main.c), 23 problems found

Ran terminal command:  bash ./video_player/build_agm_audio_minimal.sh && adb push video_player/agm_audio_minimal_bin /data/local/tmp/agm_audio_minimal_bin && adb shell chmod 755 /data/local/tmp/agm_audio_minimal_bin

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY -dkv 0xA2000001 -ikv 1 -skv 0xA100000E -dppkv 0xAC000002'

Ran terminal command:  sleep 1 && adb shell '/data/local/tmp/agm_audio_minimal_bin --snapshot-only'

这个对照结果有实质差异了。我再把后台 `agmplay` 的收尾拿一下，确认这轮快照确实是在成功播放窗口里采到的，不是踩到启动前后边界。

Awaited terminal completion

我再补一拍 `3s` 快照，只确认这组差异是不是瞬态。如果 `agmplay` 在 1s 和 3s 都保持同一组 `13 entry + miid=16472`，这个分叉就很可信了。

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY -dkv 0xA2000001 -ikv 1 -skv 0xA100000E -dppkv 0xAC000002'

Ran terminal command:  sleep 3 && adb shell '/data/local/tmp/agm_audio_minimal_bin --snapshot-only'

Awaited terminal completion

Completed: *重编译并复测 helper* (3/4)

Created memory file twrp_audio_agmplay_snapshot_tag_surface_20260324.md

我继续把问题从“helper 自己看自己”推进到了“对照 agmplay 成功播放时的真实 tag 面”。

这轮实际做了三件事

1. 在 helper 路径里补全了 tag4 的运行态观测
2. 把 getTaggedInfo 的 entry 全量展开日志加进去了
3. 新增了一个纯只读的 snapshot-only 入口，不走 helper，不走 pcm_open，只开 mixer 读当前 AGM 运行态

这轮最重要的新结论

1. helper 现在已经可以稳定建出 tag4，不存在“pre-connect custom module 根本没起来”这个问题
   - connect 前就能拿到 tag4，miid 是 16505
   - after helper_connect 仍然能读到 tag4，value 是 1，miid 还是 16505
   - after post-connect mfc 之后 tag4 也还在

2. helper 的 tag19 也同样稳定
   - value 是 1
   - miid 是 16584
   - configure_mfc 仍然成功
   - 但 pcm_open 还是失败在 -5

3. 这说明当前主缺口不能再归因到“没有 tag4”或者“没有 tag19”
   - 这两个都已经存在了
   - 问题更像是 plugin 或 graph 后续依赖的另一段状态没有对上

然后我把同一套观测代码拿去旁路读 agmplay 的成功播放窗口，分别在 1 秒和 3 秒抓了一次，结果稳定一致

1. agmplay 成功播放时，PCM100 control 仍然是 ZERO
2. agmplay 成功播放时，PCM100 connect 仍然是 ZERO
3. agm_mixer_get_miid 对 tag4 仍然成功，miid 还是 16505
4. 但 direct_get_tagged_info 对 tag4 返回的是 -22
5. tag19 仍然存在，value 是 1
6. agmplay 成功播放窗口里的 tag19 miid 是 16472，不是 helper 里的 16584

这个差异很关键

1. 现在 helper 和 agmplay 的分叉，不再是“有没有 tag4/tag19”
2. 真正的分叉是“最终落到哪个 module instance 映射”
3. helper 现在稳定走到的是 16584
4. agmplay 成功播放时走到的是 16472

也就是说，后面不该再泛化地补 helper、补 setParamTag、补随机 payload 了。最值得继续压的主线已经变成：

1. 追清楚 agmplay 是怎么把 tag19 最终映射到 16472 的
2. 再看 helper 为什么稳定落到 16584
3. 这两个 miid 背后的模块链路差异，才更像当前真正的根因

补充说明

1. 设备侧对照已经实际跑过，agmplay 后台播放成功退出，快照不是踩在无效窗口
2. 编辑器里那些 android 头文件缺失报错还是老的宿主环境问题，这轮交叉编译本身是成功的

如果你要我继续，我下一步会直接围绕 16472 和 16584 这组分叉做定向追踪，不再扩散到新的通用 helper 猜测。

Made changes.

User: 当前有偏离主线吗，这条路收益大吗

GitHub Copilot: 没有明显偏离主线，而且这一段目前是高收益路径。

判断依据

1. 主线问题已经从“为什么只听到约 1 秒”收敛成“helper 和 agmplay 到底差在哪个真实状态面上”。
2. 这轮做的事虽然看起来是“加日志、加 snapshot-only”，但本质上是在直接回答这个核心问题，不是旁支。
3. 收益点已经出来了，不是空转排查：
   - 已经排除了“tag4 不存在”这条怀疑
   - 已经排除了“只有 tag19 不稳定”这条怀疑
   - 直接抓到了 helper 和 agmplay 的实质分叉：同样有 tag，但最终 module instance 映射不同，helper 是 16584，agmplay 成功窗里是 16472
   - 这比之前泛泛地猜 `setParamTag`、猜 DAPM、猜 AW sysfs 要硬得多

所以结论是

1. 没偏主线
2. 这条路当前收益很大
3. 而且已经比之前的大多数分支更接近根因

为什么我认为这条路值得继续压

1. 它把“现象差异”变成了“可重复的结构差异”
   - 不再只是 helper 无声、agmplay 有声
   - 而是能稳定复现到具体 `miid` 分叉
2. 这个分叉发生在足够靠前、又足够贴近真实播放链的位置
   - 比 AW 寄存器更接近用户态 AGM 图构建
   - 比单纯 `pcm_open -5` 更有可操作性
3. 它给了明确下一步，而不是继续盲试
   - 现在该追的是 helper 为什么落到 16584
   - agmplay 为什么落到 16472
   - 这两条映射链谁多了什么、谁少了什么

什么才算偏离主线

如果接下来去做这些，就开始偏了：

1. 再回去大面积试 `setParamTag` payload 猜值
2. 再围着 DAPM、bias、`PCM100 connect=ZERO` 打转
3. 再做大量新的 tone/wav/循环稳定性实验
4. 再从 AW 寄存器现象层反推用户态，而不继续盯 AGM 映射差异

这些现在都不如继续追 `16472 vs 16584` 有价值。

我对当前路线的评估

1. 短期收益：高
2. 与主线一致性：高
3. 继续投入价值：高
4. 风险：中等
   - 风险不在于方向错
   - 风险在于后面可能需要更深地对 `agmplay` 调用链或 plugin 行为做定向比对，工作会更细

如果继续，我建议只守一条线：
先把 `16584 -> 为什么不是 16472` 查清，再决定要不要补新的 helper 或 payload。这样不会散。

User: 继续

GitHub Copilot: 我继续沿着 `16472 vs 16584` 这条线压，不再扩散到别的 helper 猜测；先把当前 entry 日志补成“全量不提前返回”，这样才能真比出 helper 和 agmplay 的完整 tag 面差异。

Searched for regex `16472|16584|16505|0xc0000011|0xc0000010|0xc0000013` (`**/docs/**`), 39 results

Searched for regex `16472|16584|16505|0xc0000011|0xc0000010|0xc0000013` (`**/video_player/**`), 17 results

Read memory twrp_audio_agmplay_minimal_success.md

Read memory twrp_audio_helper_timing_delta_20260317.md

搜索结果把一个旧边界重新激活了：`-ikv 0` 会把 agmplay 打回失败，说明“正确的 instance 落点”本来就是硬门槛；我现在把 entry 日志改成全量输出，直接看 helper 和 agmplay 到底在哪几个 tag 上真正分叉。

Generating patch (34 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c)


```

```
补丁已经下去。接下来我会各跑一拍 helper 和 agmplay，只看完整 entry 集合差异，不再重复抓无关日志。

Checked [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c), 22 problems found

Ran terminal command:  bash ./video_player/build_agm_audio_minimal.sh && adb push video_player/agm_audio_minimal_bin /data/local/tmp/agm_audio_minimal_bin && adb shell chmod 755 /data/local/tmp/agm_audio_minimal_bin

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --force-rate-write --wav /data/local/tmp/test440_mid_10s.wav'
Completed with input:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --force-rate-write --wav /data/local/tmp/test440_mid_10s.wav'

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /vendor/bin/agmplay /data/local/tmp/test440_mid_10s.wav -D 100 -d 100 -num_intf 1 -i TDM-LPAIF-RX-SECONDARY -dkv 0xA2000001 -ikv 1 -skv 0xA100000E -dppkv 0xAC000002'

Ran terminal command:  sleep 1 && adb shell '/data/local/tmp/agm_audio_minimal_bin --snapshot-only'

对照窗已经有新信息了：agmplay 的完整 entry 比之前又多露出两个尾部 tag，先把 helper 那边完整集合读出来，再做真正的集合差异。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_5OdB25LYckZQ7BUgB4bRHSWL__vscode-1774367488563/content.txt#35-35), lines 35 to 152

完整集合已经出来了，差异比上一轮更清楚：helper 侧多了三枚 agmplay 成功窗里没有的 tag，反而 agmplay 没显示出 helper 的那些尾部项。我先把后台 agmplay 收尾确认掉，然后把这组差异固化成下一跳结论。

Awaited terminal completion

Created memory file twrp_audio_helper_vs_agmplay_tag_surface_diff_20260324.md

下一跳我不去猜这些 tag 的语义，先把“它们是在哪一步冒出来的”钉住。最省成本的办法是在 helper 里加一个 pre-connect 全量快照，看 `0xc0000011/0039/0041` 是 connect 前就有，还是 connect 后才被建出来。

Generating patch (18 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c)


```

```
补丁只加了一个观测点，不改行为。现在重编译后跑一轮 helper，就能知道额外 tag 是 pre-connect 还是 post-connect 才出现。

Checked [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c), 25 problems found

Ran terminal command:  bash ./video_player/build_agm_audio_minimal.sh && adb push video_player/agm_audio_minimal_bin /data/local/tmp/agm_audio_minimal_bin && adb shell chmod 755 /data/local/tmp/agm_audio_minimal_bin
Completed with input:  bash ./video_player/build_agm_audio_minimal.sh && adb push video_player/agm_audio_minimal_bin /data/local/tmp/agm_audio_minimal_bin && adb shell chmod 755 /data/local/tmp/agm_audio_minimal_bin

我插错位置了，编译器已经把问题点指出来了。修这个很直接：把快照放到 `agm_mixer_get_miid(...)` 调用之前，而不是调用参数中间。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#1198-1198), lines 1198 to 1224

Generating patch (26 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c)


```

```
位置已经修正。我重新编译并只跑一轮 helper，目标是看 `0011/0039/0041` 在 connect 前是不是就已经存在。

Checked [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c), 22 problems found

Ran terminal command:  bash ./video_player/build_agm_audio_minimal.sh && adb push video_player/agm_audio_minimal_bin /data/local/tmp/agm_audio_minimal_bin && adb shell chmod 755 /data/local/tmp/agm_audio_minimal_bin

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --force-rate-write --wav /data/local/tmp/test440_mid_10s.wav'
Completed with input:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --force-rate-write --wav /data/local/tmp/test440_mid_10s.wav'

我现在只读 `before helper_connect` 那一段，目的很单一：确认多出来的 tag 是不是 connect 前就已经被 helper-preset 铺出来。

Searched for regex `before helper_connect|after helper_connect|entry\[|runtime agm_mixer_get_miid: phase=before helper_connect|runtime direct_get_tagged_info: phase=before helper_connect` (`**//Users/Laurie/Library/Application Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_te9ttQwfZTN8x2G6HSeSHbfY__vscode-1774367488576/content.txt`), no results

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_te9ttQwfZTN8x2G6HSeSHbfY__vscode-1774367488576/content.txt#1-1), lines 1 to 120

新的边界已经钉住了：helper 多出来的那几枚 tag 不是 connect 造成的，before-helper-connect 就已经完整存在。也就是说，分叉点已经前移到 `helper_prep + 直写 rate + metadata` 这段，而不是 connect 之后。

Created memory file twrp_audio_extra_tags_exist_before_connect_20260324.md

我继续往前压了一步，结论比上一轮更收敛。

这轮新增的硬结论

1. helper 比 agmplay 多出来的 tag，不是 `helper_connect` 才产生的
2. 在 `before helper_connect` 阶段，helper 就已经完整带着这组额外 tag
3. 具体说，helper 在 connect 前就已经有：
   - `0xc0000011`
   - `0xc0000039`
   - `0xc0000041`
4. 而且 connect 前就已经有：
   - `tag=0xc0000019 value=0x1`
   - `agm_mixer_get_miid(tag=0xc0000019)=16584`

这意味着什么

1. 分叉点已经前移了
2. 现在不能再把问题归到 `helper_connect` 或 post-connect MFC
3. 当前真正可疑的阶段是 pre-connect 建图这段：
   - `prime_agm_helper_prep(...)`
   - 手工 32 位四槽 `rate ch fmt` 直写
   - `PCM100 metadata` 两段写入

和 agmplay 的对照关系现在是这样的

1. helper
   - pre-connect 就已经长成 `16 entry`
   - 多出 `0xc0000011/0039/0041`
   - `tag19 -> miid=16584`
2. agmplay 成功播放窗口
   - 旁路只读快照稳定是 `13 entry`
   - 没看到 `0xc0000011/0039/0041`
   - `tag19 -> miid=16472`

所以当前最合理的解释已经不是“helper 少了什么”，而更像：

1. helper 在 pre-connect 阶段建出了一个和 agmplay 不同的图分支
2. 这个分支把 `tag19` 映射到了 `16584`
3. 而成功路径 agmplay 落到的是 `16472`

这条线仍然没有偏主线，而且收益还在上升，因为现在已经能把问题压到具体阶段了：

1. 不是 AW 末端问题
2. 不是 connect 时序问题
3. 不是 tag4/tag19 不存在
4. 而是 pre-connect 建图面已经和 agmplay 分叉

我建议下一步只做一类动作，不扩散：

1. 逐项隔离 pre-connect 动作
   - 分别去掉 `prime_agm_helper_prep`
   - 去掉手工 `rate ch fmt`
   - 去掉两段 `PCM100 metadata`
2. 看是哪一步第一次引入 `0xc0000011/0039/0041`
3. 同时观察 `tag19` 的 `miid` 什么时候从 agmplay 风格偏到 `16584`

如果你继续让我往下做，我下一轮就直接做这个“pre-connect 三段拆分”，不再加新的泛化探针。

Made changes.

User: 继续

GitHub Copilot: 我继续按上一轮的收敛点做 pre-connect 三段拆分，目标是找出哪一步首次引入 `0xc0000011/0039/0041` 和 `16584` 这组偏移。

Searched for regex `force_rate_ch_fmt_write|AgmAudioPlayerConfig|prime_agm_helper_prep|prime_pcm100_metadata_6a54_min|prime_pcm100_metadata_689c_full_kv` (`**/video_player/agm_audio_minimal.*`), 23 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#1140-1140), lines 1140 to 1235

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal_main.c)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.h)

分叉点已经前移到 pre-connect，我现在直接把三段拆成可控开关：跳过 helper_prep、跳过 6a54 metadata、跳过 689c metadata。这样一轮就能看出是哪一步第一次把图带偏。

Generating patch (15 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.h)


```

```


Using "Apply Patch"

我先对齐当前源码段落后再补丁，避免把旧上下文套到新位置上。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#1380-1380), lines 1380 to 1495

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#1495-1495), lines 1495 to 1545

上下文已经对齐了，我现在把三段开关补进去，然后直接跑拆分实验。

Generating patch (74 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c)


```

```


Generating patch (21 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal_main.c)


```

```
开关已经补齐。下一轮我不全矩阵暴力跑，只做三拍最有信息量的对照：各自单独跳过一段，看 `before helper_connect` 的 tag 集合和 `tag19 miid` 谁先变。

Checked [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.h), [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c), [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal_main.c), 23 problems found

Ran terminal command:  bash ./video_player/build_agm_audio_minimal.sh && adb push video_player/agm_audio_minimal_bin /data/local/tmp/agm_audio_minimal_bin && adb shell chmod 755 /data/local/tmp/agm_audio_minimal_bin

我现在跑三拍最小拆分，对比的唯一目标是 `before helper_connect` 的 tag 集合和 `tag19 miid`，不关心后面的 `pcm_open` 是否失败。

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --force-rate-write --skip-helper-prep --wav /data/local/tmp/test440_mid_10s.wav'
Completed with input:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --force-rate-write --skip-helper-prep --wav /data/local/tmp/test440_mid_10s.wav'

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --force-rate-write --skip-metadata-6a54 --wav /data/local/tmp/test440_mid_10s.wav'
Completed with input:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --force-rate-write --skip-metadata-6a54 --wav /data/local/tmp/test440_mid_10s.wav'

Ran terminal command:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --force-rate-write --skip-metadata-689c --wav /data/local/tmp/test440_mid_10s.wav'
Completed with input:  adb shell 'setprop vendor.oplus.mm.ftm_spk 1; /data/local/tmp/agm_audio_minimal_bin --force-rate-write --skip-metadata-689c --wav /data/local/tmp/test440_mid_10s.wav'

三拍都跑完了，接下来只抽 `before helper_connect` 和紧邻的 `miid` 行做对比，看看是哪一段真正决定了偏到 `16584`。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_v6nrVHC4EXrXFcCrL3RMpt4V__vscode-1774435149333/content.txt#1-1), lines 1 to 160

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_Ktrcz1XC5OJnF4yeT4R1G5rt__vscode-1774435149334/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_t3caSIbJGtektXgUkwr2fbFZ__vscode-1774435149335/content.txt)

结果已经足够收敛，不需要再铺更多矩阵了：`helper_prep` 不是主分叉源，真正把图推到 `16584 + 额外 tag` 的是两段 PCM100 metadata 组合。这个结论我先记到仓库记忆里。

Created memory file twrp_audio_pcm100_metadata_pair_is_preconnect_split_source_20260325.md

继续压下去之后，主线又收了一层。

这轮实测结论

1. `helper_prep` 不是当前主分叉源
2. 两段 PCM100 metadata 才是当前 pre-connect 分叉的关键组合

我做了三拍拆分

1. 跳过 `helper_prep`
   - 仍然能在 `before helper_connect` 看到完整 `16 entry`
   - 额外 tag 还在：
     - `0xc0000011`
     - `0xc0000039`
     - `0xc0000041`
   - `tag19` 仍然直接落到 `miid=16584`
   - 说明这组偏移不是 `helper_prep` 造成的

2. 跳过 `PCM100 metadata 6a54`
   - `before helper_connect` 直接退回
   - `tag4/tag19` 都拿不到
   - `miid=0`
   - post-connect MFC 直接失败

3. 跳过 `PCM100 metadata 689c`
   - 结果同样直接退回
   - `tag4/tag19` 也拿不到
   - `miid=0`
   - post-connect MFC 同样失败

这说明什么

1. 当前 helper 路径里，把图推进到
   - `16 entry`
   - 额外 tag
   - `tag19 -> 16584`
   这组状态的，不是 `helper_prep`

2. 真正关键的是两段 PCM100 metadata 的组合
   - `6a54` 单独缺失，不行
   - `689c` 单独缺失，也不行
   - 也就是这两段至少是共同必要条件

3. 这把主分叉点又往前钉死了
   - 不是 `helper_connect`
   - 不是 post-connect MFC
   - 不是 `helper_prep`
   - 而是 pre-connect 的 PCM100 metadata 组合本身

当前最像事实的描述

1. helper 不是“缺少某个 metadata”
2. 相反，更像是“当前这组 metadata 组合把图推到了错误但稳定的一支”
3. 那一支的特征就是：
   - 多出 `0xc0000011/0039/0041`
   - `tag19` 落到 `16584`
4. 而 agmplay 成功窗对应的是另一支：
   - 没有这几个额外 tag
   - `tag19` 落到 `16472`

所以现在下一步已经很明确了

不是继续猜 helper，也不是继续猜 connect，而是只盯 metadata 组合：

1. 改 `6a54` 内容，保持 `689c` 不动
2. 改 `689c` 内容，保持 `6a54` 不动
3. 看哪一个字段会让
   - 额外 tag 消失
   - `16584` 向 `16472` 靠拢

我建议下一轮直接做这个最小 A/B：
先保留两段 metadata 的框架不变，只改其中一段的关键字段，而不是整段跳过。这样最容易找到把图带偏的具体词。

Made changes.

User: 继续，我仍然搞不懂，之前纯C都能播放1s，你改了一通，完全没声音了

GitHub Copilot: 我先把两条线重新对齐：用户感知的“之前纯 C 能响 1 秒”很可能不是我最近一直在改的这条 helper/agm_audio_minimal 路径，所以我先核对当前源码和现有实验入口，避免把两条链再混在一起。

Read changed files in [](file:///Volumes/Case-sensitive%20APFS/TWRP)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#1380-1380), lines 1380 to 1515

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal_main.c)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.h)

Searched for regex `pure_c_agm_probe|agm_audio_minimal_bin|1 秒|1s|纯 C` (`**/docs/**`), 80 results

我先把“为什么会从 1 秒退到完全无声”用现有回退记录对齐，然后直接复跑那条历史纯 C 可闻命令，确认是不是只有 helper 路径退了。

Searched for files matching `**/build_pure_c_agm_probe.sh`, 1 match

Searched for files matching `**/pure_c_agm_probe.c`, 1 match

Searched for text `pure_c_agm_probe --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --play-after-open --play-seconds 5` (`**/docs/**`), 1 result

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91Bring-up-%E5%9B%9E%E9%80%80%E6%8E%92%E6%9F%A5-20260325.md#1-1), lines 1 to 220

回退排查文档已经把你的疑惑说透了：退化点锁定在 `agm_audio_minimal_bin`，不是纯 C 总体坏了。我现在直接把纯 C 的“正确调用”和当前 minimal 的差别补成实机结论，不再靠推测。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91Bring-up-%E5%9B%9E%E9%80%80%E6%8E%92%E6%9F%A5-20260325.md#220-220), lines 220 to 360

Ran terminal command:  bash ./video_player/build_pure_c_agm_probe.sh && adb push video_player/pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb shell chmod 755 /data/local/tmp/pure_c_agm_probe

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --skip-initial-control --skip-rate-write --metadata-6a54-plus-689c --play-after-open --play-seconds 5'

我已经把“是不是我把纯 C 也改坏了”这件事重新验了一遍。现在要点不是代码又崩了，而是当前纯 C 正确调用虽然还能完整跑播放链，但用户听感上也已经不是之前那条“1 秒可闻基线”了。

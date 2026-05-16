# 第1章：0x63d8/0x60f4参数消除——setParam分支降级与32位槽位收敛
User: 继续

GitHub Copilot: 我先核对纯 C probe 里 0x63d8 风格 setParam 分支现在到底落到哪一步，避免按口头进度继续往前跑偏。

Searched for regex `setParam|0x63d8|A3000004|A3000006|A2000000|D2000000|pre-open` (`**/pure_c_agm_probe.c`), 27 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1-1), lines 1 to 420

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#421-421), lines 421 to 1300

我先把 A3000004 和 A3000006 两条 0x63d8 分支在同一基线上实跑完，结果会直接告诉我们这条 pre-open setParam 线值不值得再追。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh

Ran terminal command:  adb -s 70a91f89 shell true

代码和设备状态都正常。接着我会在同一基线上分别跑 A3000004 和 A3000006，只抓 `setParam rc`、`getTaggedInfo/MFC tag` 和最终 `pcm_open` 这几个关键结果。

Ran terminal command:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe' /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe && adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-session --with-mfc --skip-split-metadata --pre-setparam-63d8-a3004' | grep -E 'preopen setParam|preopen_setparam_63d8|getTaggedInfo|agm_mixer_get_miid|post_connect_mfc|pcm_config|打开失败|打开成功|Instance key|Failed to mixer_ctl_get_array'

Ran terminal command:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-session --with-mfc --skip-split-metadata --pre-setparam-63d8-a3006' | grep -E 'preopen setParam|preopen_setparam_63d8|getTaggedInfo|agm_mixer_get_miid|post_connect_mfc|pcm_config|打开失败|打开成功|Instance key|Failed to mixer_ctl_get_array'

两条 A300 分支都跑完了。我现在只读关键摘录，确认它们有没有任何一条把 `MFC tag` 或 `pcm_open` 往前推。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_fzIvaQ9R7R7qWBOaFXpj8bMj__vscode-1773794280726/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_NmxcxHroEQ3F63yBtUgOsASW__vscode-1773794280727/content.txt)

A3000004 和 A3000006 都排掉了：两条分支都是 `PCM100 setParam rc=0 payload=48`，但 `getTaggedInfo/MFC tag` 仍然空，`pcm_open` 仍停在 `-5`。下一步不再扩 setParam 值表，我直接回反汇编确认 0x63d8 相对 connect 的真实顺序。

Searched for regex `60f4|63d8|629c|connect|setParam|rate ch fmt` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), 7 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#1880-1880), lines 1880 to 2060

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2061-2061), lines 2061 to 2225

反汇编把一个关键事实钉死了：0x63d8 确实在 0x60f4 之后、0x629c 之前，也就是 rate helper 后、connect 前。但 0x63d8 的三条已知分支都没推动边界，所以接下来要确认的是它所在调用点还有没有别的前置条件。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#520-520), lines 520 to 580

我把 0x63d8 的调用点也对上了。下一步只剩一件事：把它的第 3、4、6 个参数具体语义抠出来，看我们现在是不是把一个本该随循环变化的值写死了。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2301-2301), lines 2301 to 2425

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/tinyplay_ftm_objdump_20260318.txt#2426-2426), lines 2426 to 2488

0x63d8 的语义比当前实现细一点：它不是单纯按 `pair_tag/pair_value` 直写，而是先根据第 4 个参数选三条分支，再由第 3、6 个参数决定第二个 KV。最可疑的剩余空白是 `w3 == 3` 那条 rodata 分支，我们还没试过。

Searched for regex `1ae0|1af8|1148|1120|a100000e|a2000001|a3000004|a3000006|b1000003` (`**/audio_manual/tinyplay_ftm_objdump_20260318.txt`), 4 results

Searched for regex `A100000E|A2000001|A3000004|A3000006|B1000003` (`**/*.{txt,md,c,xml}`), 200 results

我现在补最后一块缺口：把 0x63d8 那条还没试过的 rodata 分支常量直接从二进制里抠出来，避免继续靠猜。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_manual' && xxd -g 4 -s 0x1148 -l 16 tinyplay_ftm_bin_20260318 && xxd -g 4 -s 0x1af8 -l 40 tinyplay_ftm_bin_20260318

rodata 读出来了：`w3 == 3` 那条分支不是 speaker，而是固定写 `0xA2000000 / 0xA2000009`。我把这条真正没试过的分支补进纯 C probe，然后上机看它会不会改变当前 `-5` 边界。

Generating patch (35 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
A2000009 分支已经补上。接着直接实跑，不再做额外分析；结果只看它是不是能让 `getTaggedInfo/MFC tag` 或 `pcm_open` 产生任何变化。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb -s 70a91f89 push './pure_c_agm_probe' /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe && adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-session --with-mfc --skip-split-metadata --pre-setparam-63d8-a2009' | grep -E 'preopen setParam|preopen_setparam_63d8|getTaggedInfo|agm_mixer_get_miid|post_connect_mfc|pcm_config|打开失败|打开成功|Instance key|Failed to mixer_ctl_get_array'

这次如果还不动，就能把 0x63d8 三条主分支整体降级，不再当成当前主缺口。先读关键摘录。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_fOVUIW0zJH6tagxcdflGcxiK__vscode-1773794280740/content.txt)

0x63d8 现在可以整体降级了：A2000001、A3000004、A3000006、A2000009 四条都只是“可写不推进”。我接下来转回 0x60f4，本质问题很可能是我们现在的 rate 写入形状仍然和 vendor helper 不一致。

Searched for regex `mixer_ctl_set_array\s*\(` (`**/*.{c,h,cpp}`), 50 results

Search complete: Find tinyalsa semantics

Searching for text `mixer_ctl_set_array` (`**/*.{c,cc,cpp,h,hpp,mk,txt,md,sh,py}`)

Searched for files matching `**/*tinyalsa*`, 181 matches

Searched for regex `tinyalsa|mixer_ctl_set_bytes|SNDRV_CTL_ELEM_TYPE_BYTES|SNDRV_CTL_ELEM_TYPE_INTEGER` (`**/*.{c,cc,cpp,h,hpp,mk,txt,md,sh,py}`), 200 results

Searched for files matching `**/external/tinyalsa/**`, 122 matches

Searched for text `libtinyalsa.so external/tinyalsa external/tinyalsa` (`**/module_paths.txt`), 8 results

Searched for text `mixer_ctl_set_array` (`**/external/tinyalsa/**`), 48 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/twrp_a16_compile/prebuilts/vndk/v34/x86_64/include/external/tinyalsa/include/tinyalsa/asoundlib.h#300-300), lines 300 to 352

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/twrp_a12_compile/prebuilts/vndk/v31/x86_64/include/external/tinyalsa/include/tinyalsa/asoundlib.h#300-300), lines 300 to 352

我不再追 setParam 了，改验证 0x60f4 本身。当前最值得试的是把 rate helper 按反汇编的“内存布局”去写一版，看是不是我们现在写成了错误的 4 个 32 位值。

Searching for regex `int mixer_ctl_set_array\s*\(struct mixer_ctl` (`**/*.{c,cpp,h}`)

Searched for regex `MIXER_CTL_TYPE_INT|MIXER_CTL_TYPE_BYTE|mixer_ctl_get_type_string` (`**/*.{c,cpp,h}`), 50 results

头文件只能确认这个控件不是 INT64；还差实现。我要在源码树里把 `mixer_ctl_set_array` 本体找出来，确认它对 INT 控件到底按 32 位还是按原始字节拷贝。

Searched for files matching `**/tinyalsa/**/*.c`, no matches

Searched for files matching `**/mixer.c`, no matches

Search complete: Locate tinyalsa source

Searching for text `mixer_ctl_set_array` (`**/*.{c,cc,cpp,h,hpp}`)

Searching for files matching `**/tinyalsa/**`

Searching for files matching `**/mixer.c`

Searching for files matching `**/external/**/mixer.c`

Searching for text `mixer_ctl_set_array` (`**/external/**`)

Searching for files matching `**/tinyalsa*/**`

Searched codebase for "mixer_ctl_set_array implementation tinyalsa mixer.c INT controls input buffer count sizeof(int)", 5 results

我准备把 0x60f4 按反汇编原样做一版：四个 64 位槽位的 raw layout，不再把它当普通 4 个 32 位数去写。这个实验能直接验证我们现在的 rate 写入是不是形状就错了。

Generating patch (151 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
0x60f4 layout 模式已经加进去了。现在直接跑最小链路，不带 helper-prep、不带 split metadata，只看这个更贴近反汇编的 rate 形状会把边界推到哪里。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb -s 70a91f89 push './pure_c_agm_probe' /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe && adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --skip-helper-prep --skip-split-metadata --rate-60f4-layout' | grep -E '60f4 probe|set_int u64|getTaggedInfo|pcm_config|打开失败|打开成功|Instance key|Failed to mixer_ctl_get_array'
Completed with input:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb -s 70a91f89 push './pure_c_agm_probe' /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe && adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --skip-helper-prep --skip-split-metadata --rate-60f4-layout' | grep -E '60f4 probe|set_int u64|getTaggedInfo|pcm_config|打开失败|打开成功|Instance key|Failed to mixer_ctl_get_array'

这刀很有价值：更贴近 0x60f4 的 u64 layout 没把状态推进，反而把最小链路从 `-5` 打回了 `-22`。说明当前 recovery 环境里，真正有用的不是“像 0x60f4 一样写”，而是我们那种非精确但能刺激 graph 前移的 32 位 rate 写法。再补一组 helper-prep 对照，把这个结论钉死。

Ran terminal command:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-session --with-mfc --skip-split-metadata --rate-60f4-layout' | grep -E '60f4 probe|set_int u64|getTaggedInfo|agm_mixer_get_miid|post_connect_mfc|pcm_config|打开失败|打开成功|Instance key|Failed to mixer_ctl_get_array'

我只读关键摘录。这个结果能决定后面是继续追 0x60f4 真实形状，还是把注意力彻底转回“为什么错误的 32 位 rate 写法反而有效”。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_IL8Ed2CyIhSca6kb7nwdqtT3__vscode-1773794280766/content.txt)

这次把问题又压了一层：`0x60f4` 的精确 u64 layout 在最小链路下退到 `-22`，在 helper-prep 基线上也只到 `-19`。所以当前真正有推进作用的，既不是 0x63d8，也不是 0x60f4 的原样布局，而是某种“32 位错位写法”。我再补最后一个直接对照：把 0x60f4 的值语义保留，但改成 32 位四槽 `[rate, ch, fmt, 1]`。

Generating patch (79 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
我先跑最小链路这一版 `[rate, ch, fmt, 1]`。如果它还能保持 `-5`，说明“有效的是 32 位槽位 + 60f4 数值语义”；如果它退回去，说明真正有效的还是更怪的 `[rate, ch, bits, -1]`。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb -s 70a91f89 push './pure_c_agm_probe' /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe && adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --skip-helper-prep --skip-split-metadata --rate-60f4-words' | grep -E 'AGM direct probe|getTaggedInfo|pcm_config|打开失败|打开成功|Instance key|Failed to mixer_ctl_get_array'
Completed with input:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb -s 70a91f89 push './pure_c_agm_probe' /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe && adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --skip-helper-prep --skip-split-metadata --rate-60f4-words' | grep -E 'AGM direct probe|getTaggedInfo|pcm_config|打开失败|打开成功|Instance key|Failed to mixer_ctl_get_array'

这次结果比上一个更关键：只要还是 32 位四槽，`[rate, ch, fmt=10, tail=1]` 也能稳定到 `-5`。也就是说，决定性因素不是旧版里的 `bits=32 / -1` 这两个具体值，而更像是“这个控件必须被以 32 位四槽方式写一次”。我再用 helper-prep 基线确认一遍，然后就可以把默认 baseline 改成更接近 vendor 语义的 `fmt=10 / tail=1`。

Ran terminal command:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --with-session --with-mfc --skip-split-metadata --rate-60f4-words' | grep -E 'AGM direct probe|getTaggedInfo|agm_mixer_get_miid|post_connect_mfc|pcm_config|打开失败|打开成功|Instance key|Failed to mixer_ctl_get_array'

这条如果也还是 `-5`，当前 baseline 就可以升级成更接近 0x60f4 语义的 32 位写法，不必继续沿用明显脏的 `bits/-1` 组合。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_10bVqBC0IRaorZVm719Zkn4Z__vscode-1773794280770/content.txt)

这轮已经把“rate 写法到底哪部分在起作用”压得很清楚了。我先把文档、repo memory 和任务状态补齐，然后再决定是否继续穷举 32 位槽位里的更细排列。

Generating patch (38 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```


Inserted into memory file twrp_audio_helper_timing_delta_20260317.md

Inserted into memory file twrp_audio_pcm100_setparamtag.md

Completed: *定位纯C最小依赖* (1/5)

继续推进后的新增结论：

1. `0x63d8` 这条 pre-open `setParam` 线现在可以整体降级了。
2. 已实跑的四条分支：
   1. `A2000001`
   2. `A3000004`
   3. `A3000006`
   4. `A2000009`
3. 它们全部都是 `PCM100 setParam rc=0 payload=48`，但都没有让 `getTaggedInfo` 或 `MFC tag` 立起来，`pcm_open` 也还是 `-5`。

更关键的是 `rate ch fmt` 这条线被继续压缩了：

1. 我把 `0x60f4` 的原样 helper layout 复刻成了 `u64` 四槽写法。
2. 结果它反而会把边界打回去：
   1. 最小链路下从 `-5` 退到 `-22`
   2. helper-prep 基线上从 `-5` 退到 `-19`
3. 这说明当前 recovery 里，真正有推进作用的不是 `0x60f4` 的精确 vendor 内存布局。

然后我又做了一个更重要的对照：

1. 保留 `0x60f4` 的值语义，但改成普通 32 位四槽写法：
   1. `[rate, ch, fmt=10, 1]`
2. 结果无论最小链路还是 helper-prep 基线，都仍然稳定得到 `pcm_open -5`。

到这一步，当前最硬的结论是：

1. `0x63d8` 不是主缺口。
2. `0x60f4` 的原样 `u64` layout 不是当前 recovery 里的有效推进方式。
3. 真正有推进作用的是：
   1. `PCM100 control`
   2. 一次 `32 位四槽` 的 `rate ch fmt` 写入
   3. `PCM100 connect`
4. 对这个 32 位四槽写入来说，具体值并不需要维持原来那组明显脏的 `[rate, ch, bits, -1]`；更接近 vendor 语义的 `[rate, ch, fmt=10, 1]` 也同样能把边界推进到 `-5`。

我已经同步做了这些更新：

1. 纯 C probe 新增了：
   1. `--pre-setparam-63d8-a2009`
   2. `--rate-60f4-layout`
   3. `--rate-60f4-words`
2. 文档和 repo memory 已补到最新结论。
3. 当前任务列表也已经收口完成。

下一步最值得做的只剩两条，不建议再回头扩 `setParam`：

1. 继续在 `32 位四槽 rate 写入 + connect` 这条最小主链里穷举槽位顺序
   1. 例如 `[rate, ch, fmt, 1]`
   2. `[rate, fmt, ch, 1]`
   3. `[rate, ch, 1, fmt]`
2. 继续对齐 `connect` 前后顺序
   1. `control -> rate -> connect`
   2. `control -> connect -> rate`
   3. 必要时补一次重复 `control`

如果你不打断，我下一轮就直接把这组 32 位四槽排列和 `connect` 时序一次性跑完。

Made changes.

User: 继续

GitHub Copilot: 我继续沿最小主链收变量，下一轮只测两类变化：32 位四槽的槽位排列，以及 rate/connect 的先后顺序，目标是判断 `-5` 是否绑定在某个更窄的写法上。

Searched for regex `rate_mode ==|skip_connect|force_agm_pcm100_connect|probe_agm_rate_ch_fmt_60f4_words|run_probe` (`**/pure_c_agm_probe.c`), 16 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#520-520), lines 520 to 860

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c#1080-1080), lines 1080 to 1325

我准备一次性把三种 32 位槽位排列和一个 `connect-before-rate` 顺序开关加进 probe，这样一轮上机就能把当前主缺口再收窄。

Generating patch (155 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
新开关已经加好。接下来我会在最小链路里只跑四组最有信息量的组合：三个 32 位排列，加一个 `connect-before-rate`，用一次上机把有效排列和有效顺序筛出来。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh

Ran terminal command:  adb -s 70a91f89 push '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe' /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe

构建和部署已完成。现在开始批量跑四个最小链路对照，只抓排列标签、关键控件快照和最终错误码。

Ran terminal command:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --skip-helper-prep --skip-split-metadata --rate-ch-fmt-1' | grep -E 'AGM custom probe|AGM direct probe|getTaggedInfo|pcm_config|打开失败|打开成功|Instance key|Failed to mixer_ctl_get_array'
Completed with input:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --skip-helper-prep --skip-split-metadata --rate-ch-fmt-1' | grep -E 'AGM custom probe|AGM direct probe|getTaggedInfo|pcm_config|打开失败|打开成功|Instance key|Failed to mixer_ctl_get_array'

Ran terminal command:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --skip-helper-prep --skip-split-metadata --rate-ch-1-fmt' | grep -E 'AGM custom probe|AGM direct probe|getTaggedInfo|pcm_config|打开失败|打开成功|Instance key|Failed to mixer_ctl_get_array'

Ran terminal command:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --skip-helper-prep --skip-split-metadata --rate-fmt-ch-1' | grep -E 'AGM custom probe|AGM direct probe|getTaggedInfo|pcm_config|打开失败|打开成功|Instance key|Failed to mixer_ctl_get_array'
Completed with input:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --skip-helper-prep --skip-split-metadata --rate-fmt-ch-1' | grep -E 'AGM custom probe|AGM direct probe|getTaggedInfo|pcm_config|打开失败|打开成功|Instance key|Failed to mixer_ctl_get_array'

Ran terminal command:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --skip-helper-prep --skip-split-metadata --rate-ch-fmt-1 --connect-before-rate' | grep -E 'AGM custom probe|AGM direct probe|getTaggedInfo|pcm_config|打开失败|打开成功|Instance key|Failed to mixer_ctl_get_array|before-rate'
Completed with input:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --skip-helper-prep --skip-split-metadata --rate-ch-fmt-1 --connect-before-rate' | grep -E 'AGM custom probe|AGM direct probe|getTaggedInfo|pcm_config|打开失败|打开成功|Instance key|Failed to mixer_ctl_get_array|before-rate'

已经有两个有效信号出来了：`rate-ch-fmt-1` 保持 `-5`，`connect-before-rate + rate-ch-fmt-1` 也还是 `-5`。还差两条排列我会补跑干净，把 `fmt` 和 `tail` 的可交换性一次钉死。

Ran terminal command:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --skip-helper-prep --skip-split-metadata --rate-ch-1-fmt'
Completed with input:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --skip-helper-prep --skip-split-metadata --rate-ch-1-fmt'

Ran terminal command:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --skip-helper-prep --skip-split-metadata --rate-fmt-ch-1'
Completed with input:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --skip-helper-prep --skip-split-metadata --rate-fmt-ch-1'

四组最小链路对照已经闭环了：`fmt` 和 `tail` 两个槽位互换都不影响前沿，`connect-before-rate` 也不影响前沿。也就是说，当前 `-5` 基本只要求“有一次 32 位四槽写入”和“最终发生 connect”，但不严格绑定这几个槽位的内部顺序。

Generating patch (42 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```


Inserted into memory file twrp_audio_helper_timing_delta_20260317.md

Inserted into memory file twrp_audio_pcm100_setparamtag.md

我继续往 `connect` 之后挖，不停在分析上。下一刀只测两种更大的状态变化：重复 `control` 和 `connect -> disconnect -> connect`，看 `-5` 会不会终于动。

Generating patch (77 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/pure_c_agm_probe.c)


```

```
新开关已经落进去。我直接编译并跑两组最小链路：`double-control` 和 `reconnect-cycle`，目标是看更大的 connect 状态转换能不能把 `-5` 撬开。

Ran terminal command:  cd '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player' && ./build_pure_c_agm_probe.sh && adb -s 70a91f89 push './pure_c_agm_probe' /tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /tmp/pure_c_agm_probe

Ran terminal command:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --skip-helper-prep --skip-split-metadata --rate-ch-fmt-1 --double-control' | grep -E '重|connect-disconnect-connect|AGM custom probe|getTaggedInfo|pcm_config|打开失败|打开成功|Instance key|Failed to mixer_ctl_get_array'
Completed with input:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --skip-helper-prep --skip-split-metadata --rate-ch-fmt-1 --double-control' | grep -E '重|connect-disconnect-connect|AGM custom probe|getTaggedInfo|pcm_config|打开失败|打开成功|Instance key|Failed to mixer_ctl_get_array'

Ran terminal command:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --skip-helper-prep --skip-split-metadata --rate-ch-fmt-1 --reconnect-cycle' | grep -E '重|connect-disconnect-connect|AGM custom probe|getTaggedInfo|pcm_config|打开失败|打开成功|Instance key|Failed to mixer_ctl_get_array'
Completed with input:  adb -s 70a91f89 shell '/tmp/pure_c_agm_probe --skip-helper-prep --skip-split-metadata --rate-ch-fmt-1 --reconnect-cycle' | grep -E '重|connect-disconnect-connect|AGM custom probe|getTaggedInfo|pcm_config|打开失败|打开成功|Instance key|Failed to mixer_ctl_get_array'

这两刀也排掉了：重复 `control` 和 `connect-disconnect-connect` 都不会改变前沿，还是 `-5`。到现在为止，`connect` 相关的小循环基本都不是缺口。

Generating patch (38 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)

Inserted into memory file twrp_audio_helper_timing_delta_20260317.md

Inserted into memory file twrp_audio_pcm100_setparamtag.md

文档补丁刚才命中了错误上下文，我现在只读最后相关段落并把 13.77 精确补进去，不改别的。

Searched for regex `13.76|13.75|当前前沿|不严格绑定` (`**/docs/TWRP音频手动Bring-up.md`), 17 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md#1438-1438), lines 1438 to 1495

我已经拿到准确插入点了，现在只把 13.77 追加进去，不碰前面的收敛结论。

Generating patch (33 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up.md)


```

```
我再补一层证据链，不在猜测上收尾。下一步去看 `strace_tinyplay_open` 里真实的 mixer 控件访问序列，目标是确认 tinyplay 在 `pcm_open` 前是不是还摸了我们没补到的其它控件。

Searched for text `PCM100 control|PCM100 connect|PCM100 disconnect|rate ch fmt|getTaggedInfo|setParam|metadata` (`**/audio_manual/strace_tinyplay_open_20260318.txt`), no results

Searched for text `mixer_ctl_set_array|mixer_ctl_set_enum_by_string|mixer_get_ctl_by_name|pcm_open|agm_pcm_plugin_open|Failed to mixer_ctl_get_array` (`**/audio_manual/strace_tinyplay_open_20260318.txt`), no results

搜索被忽略规则挡住了，我改成包含被忽略文件再查一次，只为了拿到 `strace` 里的真实系统调用顺序。

Searched for regex `PCM100 control|PCM100 connect|PCM100 disconnect|rate ch fmt|getTaggedInfo|setParam|metadata` (`**/audio_manual/strace_tinyplay_open_20260318.txt`), no results

Searched for regex `mixer_ctl_set_array|mixer_ctl_set_enum_by_string|mixer_get_ctl_by_name|pcm_open|agm_pcm_plugin_open|Failed to mixer_ctl_get_array` (`**/audio_manual/strace_tinyplay_open_20260318.txt`), no results

`strace` 里没有符号名，只有原始调用和日志写出。我直接读 tinyplay_open 的关键日志段，看看 vendor 自己在 `pcm_open` 前打印了哪些状态。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_manual/strace_tinyplay_open_20260318.txt#1660-1660), lines 1660 to 1725

我把 tinyplay 的 `strace` 关键段也补上了。它在 `pcm_open` 前能确认的新增信息很有限，最硬的一条仍然是 `Instance key is added`，然后很快就进入 plugin 打开阶段，没有暴露出新的明显 mixer 控件序列。继续后的新增结果：

1. `32 位四槽 rate 写入` 这条线我已经继续压完了。
2. 最小链路下这几种排列都稳定还是 `pcm_open -5`：
   1. `[rate, ch, fmt, 1]`
   2. `[rate, ch, 1, fmt]`
   3. `[rate, fmt, ch, 1]`
3. `connect-before-rate` 也还是 `-5`。
4. 这说明当前前沿不严格依赖：
   1. `fmt` 和 `tail=1` 的内部槽位顺序
   2. `connect` 放在 rate 写入之前还是之后

我又继续排了两类 `connect` 侧小循环：

1. `--double-control`
   1. 多补一次 `PCM100 control`
   2. 结果还是 `-5`
2. `--reconnect-cycle`
   1. 做一次 `connect -> disconnect -> connect`
   2. 结果还是 `-5`

所以到现在，当前最小有效条件已经非常明确：

1. 流程里要发生一次 `32 位四槽` 的 `rate ch fmt` 写入
2. 最终要发生一次 `connect`
3. 但不要求：
   1. 特定的 `fmt/tail` 槽位顺序
   2. `connect` 的前后顺序
   3. 重复一次 `control`
   4. 做一次 `disconnect/reconnect` 小循环

这轮还补了一层 `strace_tinyplay_open` 的证据：

1. `tinyplay_ftm` 在 `pcm_open` 前明确打出了：
   1. `stream_kv: a100000e device_kv[0]: a2000001 instance_kv: 1 ...`
   2. `Instance key is added`
2. 然后很快进入 plugin 打开阶段。
3. 从现有 `strace` 关键段里，没有直接露出新的明显 mixer 控件名字或新的可补动作。

当前判断
1. `0x63d8` 不是主缺口。
2. `0x60f4` 的原样 `u64` layout 不是有效路径。
3. `connect` 侧的小排列和小循环也不是缺口。
4. 现在最像根因的，已经不再是“还差某个小写入顺序”，而是：
   1. `pcm_open` 前 plugin/driver 侧还缺一个更高阶的建图条件
   2. 或者 card100/plugin 对我们当前 recovery 导出的控件集还有隐藏前置依赖

我已经更新了：
1. TWRP音频手动Bring-up.md
2. repo memory 里的两条音频结论记录

如果继续，我下一轮会优先做这两件事之一：
1. 直接围绕 `pcm_plug_open / agm_pcm_plugin_open / Failed to mixer_ctl_get_array` 追 plugin 侧缺的到底是哪类 ctl
2. 反过来从 card100 的全部 mixer ctl 快照里筛“tinyplay 成功路径前后出现、而我们纯 C 路径始终没动过”的控件

现在更值得走的是第 1 条。

Made changes.

User: 继续


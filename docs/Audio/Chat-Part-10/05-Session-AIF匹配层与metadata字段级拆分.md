# 第5章：Session-AIF匹配层与metadata字段级拆分
User: 继续

GitHub Copilot: 我下一步不扩 probe 矩阵，而是只验证一个更窄的问题：当前 `-19` 依赖的是“任意 live connected state”，还是“同一个 session/aif 的 live connected state”。这能决定后面该追 session 侧还是全局图侧。

Searched for regex `AGM_SESSION_ID|AGM_AIF_ID_SECONDARY_RX|probe_agm_session_open_close\(` (`**/video_player/pure_c_agm_probe.c`), 41 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#1-1), lines 1 to 80

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#436-436), lines 436 to 520

我只再加一个维度：把 `pre-connect` 的 session 从 `100` 切到 `101`，而 `open` 仍然开 `100`。如果这样就从 `-19` 退回 `-32`，说明当前切换至少要求“同一 session 的 live connected state”，不是任意连接都行。

Generating patch (95 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
开关已经加好，只改了 connect/disconnect 用的 session，不动 `open(100)` 本身。现在编译并跑两条最小对照，看 `session101 connect + session100 open` 会不会把错误面打回 `-32`。

Checked [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c), 24 problems found

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_pure_c_agm_probe.sh

构建已过，编辑器诊断仍是旧的 Android 头文件噪声。现在直接推设备并跑 `preconnect`/`preconnect-init` 的错 session 对照。

Ran terminal command:  adb push '/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_agm_probe' /data/local/tmp/pure_c_agm_probe && adb shell chmod 755 /data/local/tmp/pure_c_agm_probe

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect --probe-session-open-preconnect-session101' | grep -E 'session-open probe: (pre-connect rc|agm_init rc|agm_session_open rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect --probe-session-open-preconnect-session101' | grep -E 'session-open probe: (pre-connect rc|agm_init rc|agm_session_open rc|fail-disconnect rc|post-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect-init --probe-session-open-preconnect-session101' | grep -E 'session-open probe: (pre-connect rc|agm_init rc|agm_session_open rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect-init --probe-session-open-preconnect-session101' | grep -E 'session-open probe: (pre-connect rc|agm_init rc|agm_session_open rc|fail-disconnect rc|post-disconnect rc)'

这一步已经把范围再缩小了：不是“任意连接都行”，而是必须是和 `open(100)` 对应的同一个 session 处于 live connected state。下一步我只把这条新边界落文档和 memory，不再加新实验分支。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#5580-5580), lines 5580 to 5645

Read memory twrp_audio_session_open_two_error_planes_20260324.md

我先把尾部读完整，确认 14.87 的段落边界，再只在文档末尾追加 14.88，不碰中段。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#5646-5646), lines 5646 to 5669

Ran terminal command:  wc -l '/Volumes/Case-sensitive APFS/TWRP/docs/TWRP音频手动Bring-up-续.md'

尾部边界已经确认，当前 EOF 在 5668 行。我现在把“错 session 会退回 `-32`”这条新边界追加到文档和 memory，作为下一轮只追 session 侧的起点。

Generating patch (43 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```
文档已经落了 14.88。接着我把同一条结论压进 repo memory，后面就能直接以“必须是同一 session 的 live connected state”为新起点往下拆。

Updated memory file twrp_audio_session_open_two_error_planes_20260324.md

我继续顺着这条线收，不停在文档更新上。下一刀就测“同一 session 但错 AIF”是否也会把 `-19` 打回 `-32`，这样就能把条件从“同一 session”进一步缩到“同一 session + 同一 AIF”。

Generating patch (91 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
我把 connect 维度再细到 AIF 了，但仍然不动 `open(100,mode)`。现在编译并直接跑 `session100 + aif17` 的两条对照，看条件能不能继续缩到“同 session + 同 AIF”。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_pure_c_agm_probe.sh && adb push '/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_agm_probe' /data/local/tmp/pure_c_agm_probe && adb shell chmod 755 /data/local/tmp/pure_c_agm_probe

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect --probe-session-open-preconnect-aif17' | grep -E 'session-open probe: (pre-connect rc|agm_init rc|agm_session_open rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect --probe-session-open-preconnect-aif17' | grep -E 'session-open probe: (pre-connect rc|agm_init rc|agm_session_open rc|fail-disconnect rc|post-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect-init --probe-session-open-preconnect-aif17' | grep -E 'session-open probe: (pre-connect rc|agm_init rc|agm_session_open rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect-init --probe-session-open-preconnect-aif17' | grep -E 'session-open probe: (pre-connect rc|agm_init rc|agm_session_open rc|fail-disconnect rc|post-disconnect rc)'

结果比预期更值钱：同 session 但错 AIF 不是回到 `-32`，而是稳定落到第三个错误面 `-5`。这说明当前 `session_open` 前置条件已经不是二元分界，而是至少有三层：无连接 `-32`、同 session 错 AIF `-5`、同 session 正 AIF `-19`。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#5660-5660), lines 5660 to 5706

Read memory twrp_audio_session_open_two_error_planes_20260324.md

我把这条第三错误面正式追加进去。这样下一轮就不该再说“两层错误面”了，而是要按“无连接 `-32` / 同 session 错 AIF `-5` / 同 session 正 AIF `-19`”这三层往下拆。

Generating patch (50 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```
我再把 repo memory 从“两层”更新成“三层”，避免下一轮继续沿用已经过时的二层模型。

Updated memory file twrp_audio_session_open_two_error_planes_20260324.md

继续推进了一步，这一轮把当前 `session_open` 主线从“两层错误面”收紧成了“至少三层错误面”。

新实验只做了一刀：

1. 保持 `open` 仍然打开 `session100`
2. `pre-connect` 仍然使用 `session100`
3. 但把 AIF 从 `16` 改到 `17`

结果很硬：

1. `pre-connect rc=0 session=100 aif=17`
2. 不带 init 时，`agm_session_open rc=-5`
3. 带 init 时，仍然是 `agm_session_open rc=-5`
4. `fail-disconnect rc=0`

这条结果很关键，因为它说明当前错误面已经不是简单的：

1. 无连接 `-32`
2. 有正确连接 `-19`

而是至少三层：

1. 没有相关 live connected state：`-32`
2. 同一个 session，但 AIF 错配：`-5`
3. 同一个 session，且 AIF 也对上：`-19`

结合上一轮已经确认的两条边界：

1. 把 `pre-connect` 改到 `session101`，而 `open` 仍开 `session100`，会回到 `-32`
2. 在 `open` 前先断开，会从 `-19` 回落到 `-32`

现在可以把当前主线压成更具体的一句话：

1. `agm_session_open(100)` 要从最裸 `-32` 进入更深失败面，至少要求同一个 `session100` 处于 live connected state
2. 仅有同 session 还不够，AIF 也会继续分层：错 AIF 是 `-5`，对 AIF 才到 `-19`
3. 所以当前 `-19` 更像是“session 与 AIF 两层都已经满足，但仍缺更深的一层前置条件”

这一轮我已经同步做了三件事：

1. 新增了错 AIF 的最小 probe 开关
2. 重新编译并推送设备验证
3. 把结论追加进续记和 repo memory

下一步最值钱的方向已经更清楚了：

1. 不再讨论“有没有连接”这种粗粒度问题
2. 直接围绕“`session100 + aif16` 都已经满足时，为什么还是 `-19`”做最小 A/B

如果继续，我下一轮就只拆这一个层次。

Made changes.

User: 继续

GitHub Copilot: 我先不再改代码，直接用现有开关测一组“错 AIF 下再补齐正确 AIF 侧配置”的对照。目标是判断 `-5` 只是纯 AIF mismatch，还是还能被 `aif/media/metadata` 进一步推进。

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-media-preconnect-init --probe-session-open-preconnect-aif17' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|fail-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-media-preconnect-init --probe-session-open-preconnect-aif17' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|fail-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-success-metadata-aif-media-preconnect-init --probe-session-open-preconnect-aif17' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|fail-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-success-metadata-aif-media-preconnect-init --probe-session-open-preconnect-aif17' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|fail-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-devicepp-aif-media-preconnect-init --probe-session-open-preconnect-aif17' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|session_set_metadata rc|split\+devicepp session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|fail-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-devicepp-aif-media-preconnect-init --probe-session-open-preconnect-aif17' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|session_set_metadata rc|split\+devicepp session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|fail-disconnect rc)'

这组三连把 `-5` 的语义也钉住了：即使把 open 侧 AIF16 的 media 和 metadata 全补齐，只要 live connected state 仍然挂在错的 AIF17，上限就停在 `-5`。我把这条新边界直接追加到续记和 memory。

Generating patch (51 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```
我再把 memory 一并更新成“`-5` 也已经被 media/metadata A/B 钉死”，后面就能只追 `-19` 那一层。

Inserted into memory file twrp_audio_session_open_two_error_planes_20260324.md

继续推进了，这一轮没有再扩代码矩阵，只用现有开关把 `-5` 这一层也钉死了。

本轮做的 3 条关键对照：

1. `--probe-session-open-aif-media-preconnect-init --probe-session-open-preconnect-aif17`
2. `--probe-session-open-success-metadata-aif-media-preconnect-init --probe-session-open-preconnect-aif17`
3. `--probe-session-open-split-metadata-devicepp-aif-media-preconnect-init --probe-session-open-preconnect-aif17`

共同结论：

1. `pre-connect` 仍然是 `session=100 aif=17`
2. `open` 仍然固定开 `session100`
3. 同时把 open 侧 `aif16` 的 `media`、`success metadata`、`split metadata + devicepp` 都补齐
4. 结果 `agm_session_open` 还是稳定 `rc=-5`

这说明：

1. `-5` 不是“只差给 open 侧 AIF16 再补一点 media 或 metadata”
2. 它更像是在明确表达：session 已经对了，但 live connected AIF 仍然不对
3. 所以当前三层模型已经更稳了：

   1. 无相关 live connected state：`-32`
   2. 同 session 但 live connected AIF 错：`-5`
   3. 同 session 且 live connected AIF 也对：`-19`

我已经把这条结论追加进续记和 repo memory。

现在主线已经明显收缩成只剩最后一层值得追：

1. 为什么在 `session100 + aif16` 都已经满足以后，`agm_session_open` 仍然停在 `-19`

下一轮最值钱的方向，就是只围绕这个 `-19` 面继续拆，不再回头怀疑 `-5` 是否只是 media/metadata 没补齐。

Made changes.

User: 继续

GitHub Copilot: 我继续只做最小 A/B，不改主线假设。下一刀测“同 session 同时连对 AIF16 和错 AIF17”时，`agm_session_open` 会落在哪个错误面，这能判断 `-19` 是“只要存在正确 AIF 就够”还是会被错 AIF 污染。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#436-436), lines 436 to 860

Searched for text `probe_session_open_preconnect_aif17|connect_aif_id|pre-connect rc` (`**/video_player/pure_c_agm_probe.c`), 13 results

我继续只加一个最小维度：在同一个 session 上同时连两个 AIF。这样能直接判定当前 `-19` 是“只要存在正确 AIF16 就够”，还是会被额外的错 AIF17 污染。

Generating patch (133 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
我现在直接编译并跑两个判定性对照：`16+17` 和 `17+16`。这两条就能回答“正确 AIF 的存在是否足够”，还是“错 AIF 会压过正确 AIF”。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_pure_c_agm_probe.sh && adb push '/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_agm_probe' /data/local/tmp/pure_c_agm_probe && adb shell chmod 755 /data/local/tmp/pure_c_agm_probe

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect --probe-session-open-extra-preconnect-aif17' | grep -E 'session-open probe: (pre-connect rc|extra-pre-connect rc|agm_session_open rc|fail-extra-disconnect rc|fail-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect --probe-session-open-extra-preconnect-aif17' | grep -E 'session-open probe: (pre-connect rc|extra-pre-connect rc|agm_session_open rc|fail-extra-disconnect rc|fail-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect --probe-session-open-preconnect-aif17 --probe-session-open-extra-preconnect-aif16' | grep -E 'session-open probe: (pre-connect rc|extra-pre-connect rc|agm_session_open rc|fail-extra-disconnect rc|fail-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect --probe-session-open-preconnect-aif17 --probe-session-open-extra-preconnect-aif16' | grep -E 'session-open probe: (pre-connect rc|extra-pre-connect rc|agm_session_open rc|fail-extra-disconnect rc|fail-disconnect rc)'

我先把这条“正确 AIF 只要存在就足以主导错误面”落下来，不再让主线停留在 `-5` 上。之后如果继续拆，就只该盯 `-19` 那一层。

Generating patch (46 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```
我把 repo memory 也同步成“正确 AIF 的存在主导错误面，错 AIF 不会压过它”。这样下一轮就能直接从 `-19` 开始，不用再回头跑 AIF 组合。

Inserted into memory file twrp_audio_session_open_two_error_planes_20260324.md

继续推进了，这一轮把 `-5` 和 `-19` 的边界又压实了一层。

这次做的是双 AIF 最小对照：

1. 同一 session，先连正确的 `aif16`，再额外连错的 `aif17`
2. 同一 session，先连错的 `aif17`，再额外连正确的 `aif16`

结果两条都一样：

1. 两次 connect 都是 `rc=0`
2. 最后 `agm_session_open` 都回到 `rc=-19`
3. 两个 AIF 的失败后 disconnect 也都分别是 `rc=0`

这说明当前语义已经更清楚了：

1. 错 AIF 本身不会污染同一 session 上已经存在的正确 AIF
2. 只要当前 session 上存在 live 的正确 `aif16`，错误面就会回到 `-19`
3. `-5` 更准确的含义已经不是“有错 AIF 就一定 `-5`”
4. 而是“当前 session 上缺少任何 live 的正确 `aif16`，只剩错 AIF 活着”

所以现在这条主线已经可以整理成：

1. 没有相关 live connected state：`-32`
2. 同 session 上没有 live 的正确 `aif16`，只存在错 AIF：`-5`
3. 同 session 上只要存在 live 的正确 `aif16`，不论是否同时挂着别的错 AIF，都会回到 `-19`

我已经把这条结果同步追加到续记和 repo memory。

现在可以明确的是，主线已经基本可以退出 session/AIF 匹配层了。后面真正值得拆的只剩一层：

1. 在正确 session
2. 正确 AIF 也已经 live
3. 为什么 `agm_session_open` 还是停在 `-19`

如果继续，下一轮我会只围绕这个 `-19` 面做最小 A/B，不再回头跑 AIF 组合。

Made changes.

User: 继续

GitHub Copilot: 我先不碰 metadata，直接试一个更值钱的问题：当前 `-19` 是不是 `session100` 这条 ID 自身的状态被污染了，还是“任意同 session + 正确 AIF”的最小 open 都会停在 `-19`。如果后者成立，session 号本身这层也能出局。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2788-2788), lines 2788 to 2915

Searched for regex `AGM_SESSION_ID|agm_session_open\(|agm_session_set_metadata\(|agm_session_aif_set_metadata\(` (`**/video_player/pure_c_agm_probe.c`), 20 results

我加一个最小“open session 切到 101”的开关，让 `session101 + aif16` 这条最小链自己跑一遍。这样能直接判断当前 `-19` 是不是 `session100` 特有污染，还是任意正确 session/AIF 组合都会落在同一层。

Generating patch (111 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
我先直接编译并跑 `session101 + aif16` 的最小链，不加其他变量。结果如果还是 `-19`，session 号这层就可以基本出局。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_pure_c_agm_probe.sh && adb push '/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_agm_probe' /data/local/tmp/pure_c_agm_probe && adb shell chmod 755 /data/local/tmp/pure_c_agm_probe

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (pre-connect rc|agm_session_open rc|fail-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (pre-connect rc|agm_session_open rc|fail-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (agm_init rc|pre-connect rc|agm_session_open rc|fail-disconnect rc)'

这一步出了一个真正新的分叉：`session101 + aif16` 的最小链已经不是 `-19`，而是直接 `agm_session_open rc=0`。也就是说，当前卡在 `-19` 的很可能不是“任意正确 session/AIF 组合”的通病，而是 `session100` 这条 ID 自身的语境。现在我要立刻把带 init 的同组对照补完整。

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (agm_init rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (agm_init rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-success-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-success-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

这一轮结果已经改写主线了：`session101 + aif16` 的最小链能直接成功，但一旦叠加 `session_aif_set_metadata`，又会掉回 `-19`。我再补两条现成的 split-metadata 变体，确认是不是“任何 metadata 家族”都会把 `session101` 从成功面打回 `-19`。

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|session_set_metadata rc|split session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|session_set_metadata rc|split session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-devicepp-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|session_set_metadata rc|split\+devicepp session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-devicepp-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|session_set_metadata rc|split\+devicepp session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

我先把这轮真正的新边界落下来：`session101 + aif16` 最小链能成功，而把 `session_aif_set_metadata` 叠回去就会掉回 `-19`。这意味着主线已经从“连接条件不对”转到“metadata 是否把 fresh session 拉回失败面”。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#5790-5790), lines 5790 to 5834

Ran terminal command:  wc -l '/Volumes/Case-sensitive APFS/TWRP/docs/TWRP音频手动Bring-up-续.md'

Read memory twrp_audio_session_open_two_error_planes_20260324.md

EOF 已经确认。我现在只做末尾追加和 memory 更新，不改中段：把“fresh session101 最小链成功、metadata 又把它压回 -19”写成当前最硬的新前沿。

Generating patch (64 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```
我再把 repo memory 从“错误面分层”补充成“fresh session101 的最小成功面”和“metadata 重新拉回 -19”的结论，后面就能直接围绕 metadata 继续拆。

Inserted into memory file twrp_audio_session_open_two_error_planes_20260324.md

我不在这里停，因为当前最值钱的问题已经变成“到底是哪一层 metadata 把 fresh session101 拉回 -19”。我先加一个最小的 `aif_metadata_only` 入口，只打最小 AIF metadata，不带 split 的 session metadata，这能直接判断最小嫌疑是不是 `session_aif_set_metadata` 本身。

Generating patch (75 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
新入口只做一件事：在 `aif media` 之上单独补最小 `aif_metadata_words`。我直接编译并对 `session101` 跑一条最小验证，如果它也掉回 `-19`，就能把嫌疑进一步缩到 `session_aif_set_metadata` 本身，而不是 success/split payload 的某个大组合。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_pure_c_agm_probe.sh && adb push '/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_agm_probe' /data/local/tmp/pure_c_agm_probe && adb shell chmod 755 /data/local/tmp/pure_c_agm_probe

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|aif-only session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|aif-only session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

命令输出被截到临时结果文件了，我直接把那份结果读出来，不再重跑。目标只看一件事：`aif-only metadata` 会不会已经把 `session101` 从 `rc=0` 拉回 `-19`。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_PEYOmXDs5KCGIlL2IDR4FRst__vscode-1774298644204/content.txt)

新入口刚跑偏了，实际掉进了普通 `pure-c probe` 分支，没有走 `session-open` 分支。这不是设备现象，是 dispatch 漏接。我先把这个接线修好，再重跑同一条命令。

Searched for text `probe_session_open_aif_only_metadata_aif_media_preconnect_init` (`**/video_player/pure_c_agm_probe.c`), 5 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2870-2870), lines 2870 to 2965

dispatch 的确漏了最外层判定，只差一处。我补上它，然后直接重跑同一条 `session101 + aif-only metadata` 命令。

Generating patch (12 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
我直接重编、重推、重跑同一条命令，不再做别的分支。目标就是把 `aif-only metadata` 的结果钉清。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_pure_c_agm_probe.sh && adb push '/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_agm_probe' /data/local/tmp/pure_c_agm_probe && adb shell chmod 755 /data/local/tmp/pure_c_agm_probe

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|aif-only session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|aif-only session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

又发现一个接线漏项：这次新入口已经走进 `session-open` 分支了，但没有带上 `pre-connect`，所以结果掉成了最裸 `-32`。我把它接到 `pre_connect` 条件里，再重跑同一条命令。

Generating patch (13 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
我不再加别的实验，直接重编重跑同一条 `session101 + aif-only metadata`。这一次如果回到 `-19`，就能把最小嫌疑定到 `session_aif_set_metadata` 本身。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_pure_c_agm_probe.sh && adb push '/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_agm_probe' /data/local/tmp/pure_c_agm_probe && adb shell chmod 755 /data/local/tmp/pure_c_agm_probe

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|aif-only session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|aif-only session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

最小结论已经钉住了：对 fresh `session101`，只要在 `aif media` 之上单独补最小 `session_aif_set_metadata(aif_metadata_words)`，就足以把 `open` 从 `rc=0` 拉回 `-19`。我把这条作为新的最硬前沿落到续记和 memory。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#5830-5830), lines 5830 to 5892

Ran terminal command:  wc -l '/Volumes/Case-sensitive APFS/TWRP/docs/TWRP音频手动Bring-up-续.md'

EOF 现在在 5891 行。我只追加一个新小节，不动前文：把“最小 `aif-only metadata` 已足以把 fresh session101 拉回 `-19`”固定成新的最小嫌疑。

Generating patch (43 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```
我把 repo memory 也同步成“最小 aif-only metadata 已足够触发 -19”。这样后面如果继续，就可以直接拆 `aif_metadata_words` 的字段，不必再回头跑 success/split 大组合。

Inserted into memory file twrp_audio_session_open_two_error_planes_20260324.md

继续推进了，这一轮把 `-19` 的最小新增条件又压缩了一层。

新得到的最关键结论：

1. `session101 + aif16` 的 fresh 最小链，`pre-connect + aif media` 可以直接 `agm_session_open rc=0`
2. 只要在这之上再单独补一次最小的 `session_aif_set_metadata(aif_metadata_words)`
3. `agm_session_open` 就会立刻从 `rc=0` 回落到 `rc=-19`

也就是说，当前已经不需要再拿 `success-metadata` 或 `split-metadata` 那种大 payload 来解释 `-19` 了。

现在已经钉住的层次是：

1. `session101 + aif16 + pre-connect`：`rc=0`
2. 再加 `aif_set_media_config`：仍然 `rc=0`
3. 再加最小 `aif-only session_aif_set_metadata`：直接变 `rc=-19`

这把主线从“metadata 家族可疑”继续收紧成了：

1. fresh session 从成功面掉回 `-19` 的最小新增条件
2. 已经收缩到 `session_aif_set_metadata(aif_metadata_words)` 本身

这也让 `session100` 现在长期停在 `-19` 的解释更具体了：

1. 不再像是单纯 connect/open 还不对
2. 更像是它已经处在与这层最小 AIF metadata 等价的语境里

我已经把这条结果追加进续记和 repo memory。

下一步真正值钱的工作已经很清楚：

1. 不再拆 success/split 大组合
2. 直接去拆这份最小 `aif_metadata_words` 的字段
3. 找出到底是哪个字段把 fresh session 从 `rc=0` 拉回 `-19`

如果继续，我下一轮就只围绕这个最小 AIF metadata 做字段级 A/B。

Made changes.

User: 继续

GitHub Copilot: 我继续沿最小 `aif-only metadata` 这条线往下拆，只做字段级 A/B，不再碰 success/split 大组合。目标是判断到底是“任何非空 AIF metadata 调用”都会触发 `-19`，还是已经能缩到具体 tag/value。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#500-500), lines 500 to 590

Searched for text `aif_metadata_words|aif-only session_aif_set_metadata|probe_session_open_aif_only_metadata_aif_media_preconnect_init` (`**/video_player/pure_c_agm_probe.c`), 19 results

我现在加三个字段级变体，不加更多：`count=0`、`tag=0`、`value=0`。这三条足够区分“任何非空调用都会触发 `-19`”和“已经缩到具体 tag/value 对”。

Generating patch (126 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
我现在只跑三条字段级对照，全部固定在 fresh `session101 + aif16 + aif media` 上。跑完就能知道是“任何非空 metadata 调用”还是已经缩到 tag/value 某一侧。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_pure_c_agm_probe.sh && adb push '/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_agm_probe' /data/local/tmp/pure_c_agm_probe && adb shell chmod 755 /data/local/tmp/pure_c_agm_probe

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-zero-count-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|aif-only-zero-count session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-zero-count-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|aif-only-zero-count session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-zero-tag-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|aif-only-zero-tag session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-zero-tag-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|aif-only-zero-tag session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-zero-value-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|aif-only-zero-value session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-zero-value-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|aif-only-zero-value session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

这一轮字段级 A/B 已经有足够信息，不再继续加新分支。我先把三条结果固定下来：`zero-tag` 和 `zero-value` 都仍是 `-19`，而 `zero-count` 虽然调用本身返回 `-22`，后续 `open` 也同样掉到 `-19`。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#5890-5890), lines 5890 to 5929

Ran terminal command:  wc -l '/Volumes/Case-sensitive APFS/TWRP/docs/TWRP音频手动Bring-up-续.md'

Read memory twrp_audio_session_open_two_error_planes_20260324.md

我现在只追加一个新小节，不再动 probe。它要固定两件事：`zero-tag` 和 `zero-value` 都还能触发 `-19`，而 `zero-count` 虽然调用本身返回 `-22`，后续 `open` 也同样回到 `-19`。

Generating patch (52 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```
我把 repo memory 也收口成“当前最小嫌疑更像 API 调用层本身，而不是具体 tag/value”。之后如果继续，就该直接测“无效 payload / size / 空调用”这类 API 层语境，而不是继续枚举 KV。

Inserted into memory file twrp_audio_session_open_two_error_planes_20260324.md

继续推进了，这一轮把 `-19` 的最小嫌疑从“最小 AIF metadata payload”进一步压到了“`session_aif_set_metadata` 这一调用层本身”。

这次只做了 3 条字段级对照，全部固定在：

1. fresh `session101 + aif16`
2. `aif_set_media_config` 已经成功
3. `pre-connect` 已经成功

分别测试：

1. `zero-count`
2. `zero-tag`
3. `zero-value`

结果很清楚：

1. `zero-tag`：`session_aif_set_metadata rc=0`，后续 `agm_session_open rc=-19`
2. `zero-value`：`session_aif_set_metadata rc=0`，后续 `agm_session_open rc=-19`
3. `zero-count`：`session_aif_set_metadata rc=-22`，但后续 `agm_session_open` 仍然是 `rc=-19`

这意味着两件事：

1. 当前已经不能简单收口成“就是某个特定 `tag -> value` 对把 fresh session 拉回了 `-19`”
2. 因为 tag 清零、value 清零之后，错误面都没有变
3. 更重要的是，连 `count=0` 这种本身已经报错的 metadata 调用，后续 `open` 也还是掉到 `-19`

所以当前最小嫌疑已经从：

1. 某个具体 metadata 字段值

收紧成：

1. `session_aif_set_metadata` 这层调用本身
2. 或者它在调用过程中立起的某类 session/AIF 语境

我已经把这条结果追加到续记和 repo memory。

现在主线下一步也已经很明确了：

1. 不再继续枚举 tag/value
2. 直接验证“是否只要调用过 `session_aif_set_metadata`，无论 payload 是否有效，fresh session 都会从 `rc=0` 掉到 `-19`”

如果继续，我下一轮会直接做 API 层语境验证，而不是再拆 KV。

Made changes.

User: 现在阶段是什么，在排查什么问题

GitHub Copilot: 当前阶段已经不是在排查“连没连上”这种粗层问题了，而是在排查：

1. 为什么 `agm_session_open` 在“连接条件已经满足”的情况下，仍然会被某类 metadata 语境拉回失败面
2. 更具体地说，是哪一层 `session_aif_set_metadata` 相关语境，把 fresh session 从 `rc=0` 拉回 `rc=-19`

当前已经排到的边界是：

1. `session` 和 `AIF` 的基本匹配层，已经基本压平了
2. fresh 的 `session101 + aif16` 最小链，在 `pre-connect` 下可以直接 `agm_session_open rc=0`
3. 这说明 `-19` 不是“任意正确 session/AIF 组合都会遇到”的天然天花板

已经排除或确认的点：

1. 不是单纯缺 `agm_init`
2. 不是单纯缺 route prewarm
3. 不是“任意 live connected state 都行”
4. 不是“错 AIF 一出现就一定污染结果”
5. 不是必须上 success-metadata 或 split-metadata 这种大 payload 才会掉到 `-19`

当前最关键的新结论是：

1. 对 fresh `session101` 来说
2. `pre-connect + 正确 AIF + aif media` 可以成功
3. 但只要再额外调用一次最小的 `session_aif_set_metadata`
4. 就足以把 `agm_session_open` 从 `rc=0` 拉回 `rc=-19`

而且字段级继续拆以后发现：

1. `zero-tag` 还是 `-19`
2. `zero-value` 还是 `-19`
3. `zero-count` 虽然 metadata 调用自己报 `-22`，后续 `open` 也还是 `-19`

所以当前主线已经收缩成：

1. 现在最可疑的，不再是某个具体 KV 值
2. 更像是 `session_aif_set_metadata` 这层调用本身
3. 或者它在调用过程中立起的某种 session/AIF 语境

一句话总结现在在查什么：

1. 不是在查“怎么把链路连起来”
2. 而是在查“为什么一旦进入 `session_aif_set_metadata` 这层语境，fresh session 的 open 就会从成功面掉回 `-19`”

下一步如果继续，最合理的是：

1. 不再枚举更多 metadata 内容
2. 直接验证“是否只要调用过这层 API，无论 payload 是否有效，都会把 fresh session 拉回 `-19`”

User: 主线还是在播放完整音频吗

GitHub Copilot: 不是。

当前主线已经暂时从“播放完整音频”那条链上切出来了，正在做更前置的一层排查：

1. 先把 `agm_session_open` 这一步单独打通
2. 确认在什么最小条件下它会成功，什么条件下会掉回 `-19`

原因很直接：

1. 如果连 fresh session 的 `session_open` 成败边界都没钉清
2. 那后面“为什么完整播放链只出前段、后段塌掉”
3. 很容易把 open 前置条件、metadata 语境、真正播放期问题混在一起

所以现在的阶段是：

1. 暂停直接追“完整音频为什么播不满/后段为什么没声”
2. 先把 `session_open` 的最小成功面和失败面压清
3. 目前已经压到：
   1. fresh `session101 + aif16` 最小链可以 `open rc=0`
   2. 但一旦进入 `session_aif_set_metadata` 这层语境，就会掉回 `-19`

这说明当前主线是在排“播放前的会话建链前置条件”，不是在直接排“完整音频播放时长”本身。

更准确地说：

1. 大主线目标还是完整音频
2. 但当前子主线已经下潜到它前面一层
3. 先解决“为什么会话一旦带上某类 metadata 就回落失败”
4. 解决完这层，才会回到完整播放链继续合流

如果你要一句最短版本：

1. 总目标还是完整音频
2. 但当前手上的主线分支，不是在直接查播放时长
3. 而是在查播放前的 `session_open / metadata` 前置条件为什么卡住

User: 继续

GitHub Copilot: 我继续沿 API 层语境往下压，不再碰播放链。下一刀只测一件事：如果 `session_aif_set_metadata` 连有效字节数都不给，只做一次“空调用”，fresh `session101` 会不会也从 `rc=0` 掉到 `-19`。

Generating patch (53 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
我只跑这一条 `zero-bytes`，不再扩散。它能直接回答现在最关键的问题：是不是连“空字节调用”都足以把 fresh session 拉回 `-19`。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_pure_c_agm_probe.sh && adb push '/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_agm_probe' /data/local/tmp/pure_c_agm_probe && adb shell chmod 755 /data/local/tmp/pure_c_agm_probe

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-zero-bytes-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|aif-only-zero-bytes session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-zero-bytes-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|aif-only-zero-bytes session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

结果已经够硬，不需要再加新实验：`bytes=0` 的空调用本身就足以让 fresh `session101` 从 `rc=0` 掉回 `-19`。我把这条作为当前最强结论落到续记和 memory，主线就可以正式改写成“API 调用层语境”了。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#5920-5920), lines 5920 to 5975

Ran terminal command:  wc -l '/Volumes/Case-sensitive APFS/TWRP/docs/TWRP音频手动Bring-up-续.md'

Read memory twrp_audio_session_open_two_error_planes_20260324.md

我只补一条新小节和一条 memory。这样当前阶段就明确变成：`session_aif_set_metadata` 空字节调用本身也足以把 fresh session 拉回 `-19`。

Generating patch (40 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Inserted into memory file twrp_audio_session_open_two_error_planes_20260324.md

继续推进了，这一轮把主线基本正式收口到 API 调用层了。

最新、最硬的结论是：

1. 对 fresh 的 `session101 + aif16`
2. `pre-connect + aif media` 可以 `agm_session_open rc=0`
3. 但只要再走一次 `session_aif_set_metadata`
4. 哪怕 `bytes=0`，调用本身已经返回 `-22`
5. 后续 `agm_session_open` 也还是会回落到 `rc=-19`

这说明当前最强嫌疑已经不是：

1. 某个具体的 metadata tag/value
2. 或某个成功写入的合法 payload

而更像是：

1. `session_aif_set_metadata` 这一 API 调用层本身
2. 或者它在调用过程中立起的某类 session/AIF 语境

也就是说，主线现在可以明确改写成：

1. 当前 fresh session 从成功面掉回 `-19`
2. 已经基本不依赖具体 payload 内容
3. 更像是“只要走过这层 API”，就会进入 `-19` 语境

我已经把这条结果追加进续记和 repo memory。

如果继续，下一步最合理的就不再是拆 payload 了，而是直接做 API 形态 A/B：

1. 是否调用
2. 调用几次
3. 调用顺序前后
4. 是否先连后调、先调后连

这会比继续拆 KV 更值钱。

Made changes.


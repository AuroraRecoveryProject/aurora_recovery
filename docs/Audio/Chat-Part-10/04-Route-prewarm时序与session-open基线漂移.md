# 第4章：Route prewarm时序与session-open基线漂移

如果你要，我下一步可以直接把最新二进制再推一次设备，然后继续沿“仅加载库 / open 后立刻 close”那条更窄边界往下切。

Made changes.

User: 继续

GitHub Copilot: 我继续沿当前最窄前沿推进：下一步直接拆“只是加载 tinyalsa/agmmixer 库”与“真的持有 mixer 句柄”这两层，看看裸 `session_open` 是在哪一层开始掉到 `-19`。

Searched for text `load_tinyalsa|load_agm_mixer|probe_agm_session_open_close` (`**/video_player/pure_c_agm_probe.c`), 37 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#340-340), lines 340 to 640

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2500-2500), lines 2500 to 2760

我现在补两个更窄 probe，不碰主路径：一个只 `load_tinyalsa/load_agmmixer` 不开句柄，一个 `mixer_open` 后立刻 `mixer_close`，这样就能把失败边界切成“库加载层”还是“活句柄层”。

Generating patch (104 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
代码点已经补上了。现在先本地编译，再直接上设备跑两个短 probe，马上就能知道边界是“库加载就坏”还是“必须出现过 mixer_open”。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_pure_c_agm_probe.sh

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && adb push pure_c_agm_probe /data/local/tmp/

二进制已经更新到设备。现在直接跑两个最窄 A/B：只加载 tinyalsa/agmmixer，不开句柄；以及打开 card100 mixer 后立刻关闭，再看 `session_open` 会不会仍掉到 `-19`。

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-load-mixer-libs-aif-media-preconnect-init' | grep -E 'session-open probe: (仅加载 tinyalsa/agmmixer 完成|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-load-mixer-libs-aif-media-preconnect-init' | grep -E 'session-open probe: (仅加载 tinyalsa/agmmixer 完成|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-open-close-mixer-aif-media-preconnect-init' | grep -E 'session-open probe: (仅加载 tinyalsa/agmmixer 完成|短暂打开 card|已关闭临时 mixer|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-open-close-mixer-aif-media-preconnect-init' | grep -E 'session-open probe: (仅加载 tinyalsa/agmmixer 完成|短暂打开 card|已关闭临时 mixer|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

这轮结果暴露了一个新的代码点：新 flag 的命名是 `aif-media-preconnect-init`，但实际分发里没有把它们并到 `set_aif_media/pre_connect` 那两组布尔条件里，所以跑成了一个更裸的 `session_open`，直接掉到 `-32`。我先把这两处接线补齐，再重跑，避免拿错实验面做结论。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2680-2680), lines 2680 to 2765

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2765-2765), lines 2765 to 2815

我已经确认问题就是分发漏接了两组 OR 条件，不是设备态漂移。现在只补这两处，然后重新编译、推送并重跑同样两个命令，结论就会回到正确实验面。

Generating patch (23 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
分发漏接已经补回。现在我直接重编、重推、重跑同样两个 probe，拿到真正可比较的结果。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_pure_c_agm_probe.sh

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && adb push pure_c_agm_probe /data/local/tmp/

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-load-mixer-libs-aif-media-preconnect-init' | grep -E 'session-open probe: (仅加载 tinyalsa/agmmixer 完成|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-load-mixer-libs-aif-media-preconnect-init' | grep -E 'session-open probe: (仅加载 tinyalsa/agmmixer 完成|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-open-close-mixer-aif-media-preconnect-init' | grep -E 'session-open probe: (仅加载 tinyalsa/agmmixer 完成|短暂打开 card|已关闭临时 mixer|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-open-close-mixer-aif-media-preconnect-init' | grep -E 'session-open probe: (仅加载 tinyalsa/agmmixer 完成|短暂打开 card|已关闭临时 mixer|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

新结果比上一轮更硬：连活句柄都不需要，只要同进程里先把 `tinyalsa/agmmixer` 这层加载起来，带上 `aif_media + pre-connect` 后，isolated `session_open` 就已经掉到 `-19` 了。下一刀我直接拆成“只 load tinyalsa”和“只 load agmmixer”，把触发层再向前推一层。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#780-780), lines 780 to 875

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#5120-5120), lines 5120 to 5235

我继续往前切触发层：这次不再碰 mixer 句柄，只把“只 load tinyalsa”和“只 load agmmixer”拆开。这样跑完就能知道到底是哪一个库的装载已经足够把 `session_open` 压到 `-19`。

Generating patch (108 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
新 probe 入口已经补上。现在先编译并推到设备，然后只跑两个很短的对照，直接看是哪一个库的装载先把 `session_open` 推到失败面。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_pure_c_agm_probe.sh

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && adb push pure_c_agm_probe /data/local/tmp/

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-load-tinyalsa-aif-media-preconnect-init' | grep -E 'session-open probe: (仅加载 tinyalsa 完成|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-load-tinyalsa-aif-media-preconnect-init' | grep -E 'session-open probe: (仅加载 tinyalsa 完成|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-load-agmmixer-aif-media-preconnect-init' | grep -E 'session-open probe: (仅加载 agmmixer 完成|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-load-agmmixer-aif-media-preconnect-init' | grep -E 'session-open probe: (仅加载 agmmixer 完成|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

这一轮已经把边界前推到了“库装载层”：不需要活 mixer 句柄，只要先 load `tinyalsa` 或单独 load `agmmixer`，带 `aif_media + pre-connect` 的 isolated `session_open` 就都会掉到 `-19`。我把这个新结论追加进文档和 repo memory，下一轮就可以直接去拆 `dlopen` 本身与后续符号解析/初始化的差别。

Searched for regex `14\.8[0-9]` (`**/docs/TWRP音频手动Bring-up-续.md`), 3 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#5230-5230), lines 5230 to 5298

Generating patch (82 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Created memory file twrp_audio_library_load_alone_blocks_isolated_session_open_20260324.md

这轮主线又往前推进了一层，而且边界比前面更早：

1. 不需要活着的 mixer 句柄。
2. 不需要 `mixer_open(...)` 持续保活。
3. 只要当前进程先加载了 `tinyalsa`，或者单独加载了 `agmmixer`，再走 `aif_set_media_config + pre-connect + isolated agm_session_open`，结果就已经稳定掉到 `-19`。

这次我做了这些实际动作：

1. 给 `pure_c_agm_probe` 增加了更细的 probe：
   `--probe-session-open-load-tinyalsa-aif-media-preconnect-init`
   `--probe-session-open-load-agmmixer-aif-media-preconnect-init`
   以及前一轮的 `open-close-mixer` 入口
2. 修正了我自己刚加的新 probe 分发漏接问题：
   原先新 flag 名字里带了 `aif-media-preconnect-init`，但没被并进 `set_aif_media/pre_connect` 条件，第一次跑成了错误实验面
3. 重新编译、推送并重跑了正确版本

拿到的关键结果是：

1. 仅加载 `tinyalsa`
   `aif_set_media_config rc=0`
   `pre-connect rc=0`
   `agm_session_open rc=-19`
2. 仅加载 `agmmixer`
   `aif_set_media_config rc=0`
   `pre-connect rc=0`
   `agm_session_open rc=-19`
3. 短暂 `mixer_open(card100)` 再立刻 `mixer_close`
   结果仍然是 `agm_session_open rc=-19`

所以现在最准确的结论已经变成：

1. 冲突不是 card100 专属。
2. 冲突不是活 mixer 句柄专属。
3. 冲突更像是在“mixer 侧用户态库装载层”就已经被触发。

我也已经把这个新结论追加进续记，编号补到 14.81，并记了一条新的 repo memory，后面不会再回到“必须先有活 mixer 句柄”这条死分支。

下一步最值钱的一刀已经很明确：

1. 继续拆 `dlopen` 本身和后续符号解析/初始化副作用。
2. 也就是去回答：
   是只要把库装进进程就够了，
   还是某个 `dlsym` / 首次调用路径才真正把最小 `session_open` 压到 `-19`。

如果你继续让我推，我下一刀就直接做这一层，不再回到 mixer/card/helper-prep 分支。

Made changes.

User: 继续

GitHub Copilot: 我继续沿“库加载副作用”这条前沿往下切。先核对 `load_agm_runtime_deps()` 到底提前预加载了哪些库，否则直接拆 `dlopen` / `dlsym` 可能会被隐藏的公共预加载层污染。

Searched for regex `load_agm_runtime_deps|preload_one_runtime_dep|deps\[\]` (`**/video_player/pure_c_agm_probe.c`), 7 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#280-280), lines 280 to 350

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#220-220), lines 220 to 280

我发现一个更硬的上下文约束，得先纠正方向再继续：当前 probe 一进来就会走公共预加载，而且 `ensure_recovery_audio_route(...)` 本身也可能先触达 tinyalsa/card0。也就是说，刚才那句“只加载库就足够”现在不能直接下结论，我先把这层时序关系读清，再把实验改成真正可区分的版本。

Searched for text `ensure_recovery_audio_route|setup_recovery_audio_route` (`**/video_player/pure_c_agm_probe.c`), 10 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#1825-1825), lines 1825 to 1888

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#1888-1888), lines 1888 to 1938

我刚把一个更关键的时序矛盾看出来了：`session_open` probe 开头本来就会先走一次 `ensure_recovery_audio_route(...)`，而它内部已经 `load_tinyalsa + mixer_open(0) + mixer_close(0)`。这意味着刚才“仅加载 tinyalsa”那条 probe 实际上很可能是空操作，所以我先把 `ensure_recovery_audio_route` 的一次性逻辑读清，再按真正可区分的顺序去改实验。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2150-2150), lines 2150 to 2195

我不打算继续在“已经被 prewarm 污染的实验面”上推结论了。先加一个最小开关，把 session probe 开头那次 `ensure_recovery_audio_route(...)` 可选跳过，然后马上重跑三条短命令，看“无 prewarm 基线”和“无 prewarm 后再触达 tinyalsa/agmmixer”分别落在哪个面。

Generating patch (47 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
开关已经加好。现在我直接编译、推送，并在“无 prewarm”条件下重跑三条最短命令：无触达基线、load tinyalsa、load agmmixer。这样一轮就能把刚才那层污染彻底拆开。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_pure_c_agm_probe.sh

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && adb push pure_c_agm_probe /data/local/tmp/

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-aif-media-preconnect-init' | grep -E 'session-open probe: (跳过开头 route prewarm|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-aif-media-preconnect-init' | grep -E 'session-open probe: (跳过开头 route prewarm|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-load-tinyalsa-aif-media-preconnect-init' | grep -E 'session-open probe: (跳过开头 route prewarm|仅加载 tinyalsa 完成|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-load-tinyalsa-aif-media-preconnect-init' | grep -E 'session-open probe: (跳过开头 route prewarm|仅加载 tinyalsa 完成|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-load-agmmixer-aif-media-preconnect-init' | grep -E 'session-open probe: (跳过开头 route prewarm|仅加载 agmmixer 完成|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-load-agmmixer-aif-media-preconnect-init' | grep -E 'session-open probe: (跳过开头 route prewarm|仅加载 agmmixer 完成|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

新结果把前沿改写了，而且比刚才更关键：`skip-route-prewarm` 之后，连最小 `aif_media + pre-connect` 基线自己都会掉到 `-19`。也就是说，之前能成功的那条最小 `session_open`，其实依赖开头那次 route prewarm；我下一刀直接测“把同样的 prewarm 挪到 agm_init 之后，能不能救回来”，这样就能区分是 prewarm 内容本身有效，还是必须发生在 init 之前。

Generating patch (47 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
我已经把 post-init prewarm 开关接上了。现在直接编译、推送、跑两条短 A/B：一个是“跳过前置 prewarm，但在 init 后补做一次 prewarm”，另一个是在这个条件上再额外触达 tinyalsa，看 prewarm 能不能把失败面救回来。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_pure_c_agm_probe.sh

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && adb push pure_c_agm_probe /data/local/tmp/

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-route-prewarm-after-init --probe-session-open-aif-media-preconnect-init' | grep -E '音频路由预热: phase=session-open probe\(post-init prewarm\)|session-open probe: (跳过开头 route prewarm|agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-route-prewarm-after-init --probe-session-open-aif-media-preconnect-init' | grep -E '音频路由预热: phase=session-open probe\(post-init prewarm\)|session-open probe: (跳过开头 route prewarm|agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-route-prewarm-after-init --probe-session-open-load-tinyalsa-aif-media-preconnect-init' | grep -E '音频路由预热: phase=session-open probe\(post-init prewarm\)|session-open probe: (跳过开头 route prewarm|agm_init rc|仅加载 tinyalsa 完成|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-route-prewarm-after-init --probe-session-open-load-tinyalsa-aif-media-preconnect-init' | grep -E '音频路由预热: phase=session-open probe\(post-init prewarm\)|session-open probe: (跳过开头 route prewarm|agm_init rc|仅加载 tinyalsa 完成|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

这轮已经把最关键的时序钉死了：不是“只加载库就会坏”，而是“开头那次 route prewarm 必须发生在 agm_init 之前”。我先把这个更正追加进文档，避免 14.81 那段继续误导，然后记一条 repo memory。

Generating patch (75 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Created memory file twrp_audio_route_prewarm_before_agminit_required_20260324.md

这轮把前沿纠正到更准确了，核心不是“只要多碰一次库就坏”，而是：

1. 最小 `session_open` 成功依赖开头那次 route prewarm。
2. 而且这次 prewarm 必须发生在 `agm_init` 之前。
3. 同样的 prewarm 挪到 `agm_init` 之后，再补做一次，也救不回来。

我这次实际做了这些事：

1. 在 pure_c_agm_probe.c 里加了 `--probe-session-open-skip-route-prewarm`
2. 又加了 `--probe-session-open-route-prewarm-after-init`
3. 重新编译并推送到设备
4. 跑了三条关键短 A/B：
   无 prewarm 的最小基线
   无 prewarm + load tinyalsa
   无 prewarm + load agmmixer
   然后又跑了 post-init prewarm 对照

拿到的关键结果是：

1. `skip-route-prewarm + aif_media + pre-connect`
   直接 `agm_session_open rc=-19`
2. `skip-route-prewarm + route-prewarm-after-init + aif_media + pre-connect`
   仍然是 `agm_session_open rc=-19`

这说明两件事：

1. 之前“仅加载 tinyalsa/agmmixer 会把最小 session_open 压到 -19”那句，受到了默认 prewarm 顺序的混淆，不能再直接当最终结论。
2. 当前更硬的事实是：
   route prewarm 的时序窗口本身才是决定性条件，
   它必须早于 `agm_init`。

我已经把这个更正追加进续记，编号补到 14.82，也记了一条新的 repo memory，后面不会再沿错误的“库加载本身有毒”表述继续跑偏。

下一步最值钱的方向已经很明确：

1. 继续拆开头那次 prewarm 到底立起了什么状态。
2. 更具体地说，去区分它里面的两部分谁是关键：
   `setprop vendor.oplus.mm.ftm_spk=1`
   还是 card0 的 mixer 路由写入
3. 因为现在真正要解释的是：
   为什么这组动作只要发生在 `agm_init` 之前就能让最小 `session_open` 成功，
   但一旦放到 `agm_init` 之后，同样内容就完全失效。

如果你继续让我推，下一刀我就直接把 prewarm 拆成这两部分做最小 A/B，不再绕回 tinyalsa/agmmixer 这层。

Made changes.

User: 继续

GitHub Copilot: 我继续沿 prewarm 时序主线往下切，这次不再碰库加载分叉，直接把 prewarm 拆成两半：`setprop` 和 card0 mixer 路由，看看到底是谁必须发生在 `agm_init` 之前。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2148-2148), lines 2148 to 2195

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#432-432), lines 432 to 620

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2498-2498), lines 2498 to 2775

我继续只切 prewarm 组成，不回到别的分叉。下一步直接把 prewarm 拆成两半做前置 A/B：只做 `setprop`，只做 card0 mixer 路由，看最小 `session_open` 是被哪一半在 `agm_init` 前救活。

Generating patch (85 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
我先核对一下刚才补丁落点，确认 pre-init 组件开关已经完整接到函数签名和命令行分发；如果有半截，我先补全再跑设备。

Searched for text `prewarm_setprop_before_init|prewarm_mixer_before_init|pre-init split prewarm` (`**/video_player/pure_c_agm_probe.c`), 5 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#432-432), lines 432 to 470

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2510-2510), lines 2510 to 2765

刚才补丁只落进去了一半：函数体里已经用了两个 pre-init 组件变量，但签名、局部变量和分发还没接上。我先把这半截补完整，再编译跑设备，不在半成品上浪费实验轮次。

Generating patch (45 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
现在这组 pre-init 组件开关才算接完整。我直接编译、推送，并跑两个最短 A/B：只做 `setprop-before-init`，只做 `mixer-before-init`，看谁能把最小 `session_open` 从 `-19` 拉回成功面。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_pure_c_agm_probe.sh
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_pure_c_agm_probe.sh

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && adb push pure_c_agm_probe /data/local/tmp/

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-prewarm-setprop-before-init --probe-session-open-aif-media-preconnect-init' | grep -E '音频路由预热: phase=session-open probe\(pre-init split prewarm\) setprop rc=|session-open probe: (跳过开头 route prewarm|agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-prewarm-setprop-before-init --probe-session-open-aif-media-preconnect-init' | grep -E '音频路由预热: phase=session-open probe\(pre-init split prewarm\) setprop rc=|session-open probe: (跳过开头 route prewarm|agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-prewarm-mixer-before-init --probe-session-open-aif-media-preconnect-init' | grep -E '音频路由预热: phase=session-open probe\(pre-init split prewarm\) mixer rc=|session-open probe: (跳过开头 route prewarm|agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-prewarm-mixer-before-init --probe-session-open-aif-media-preconnect-init' | grep -E '音频路由预热: phase=session-open probe\(pre-init split prewarm\) mixer rc=|session-open probe: (跳过开头 route prewarm|agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

编译报错说明刚才有一段 helper 函数插到了 `run_probe(...)` 签名里，导致整段文件语法偏移了。我要先把这个结构修正回干净状态，再继续跑 pre-init 组件 A/B。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2168-2168), lines 2168 to 2208

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2338-2338), lines 2338 to 2368

Searched for text `probe-session-open-prewarm-setprop-before-init|probe-session-open-prewarm-mixer-before-init` (`**/video_player/pure_c_agm_probe.c`), 4 results

我已经定位到两个坏点了：一个 helper 代码块被插进了 `run_probe(...)` 函数签名里，另一个 pre-init 组件调用被插进了 `run_probe` 的 rate-write 分支。先把这两个结构错位清掉，再恢复成正确落点。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#430-430), lines 430 to 448

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2328-2328), lines 2328 to 2365

Generating patch (56 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
结构错位已经清掉了。现在我先本地编译确认语法恢复，再推设备跑 `setprop-only` 和 `mixer-only` 两条真正的 pre-init 组件 A/B。

Searched for text `prewarm_recovery_audio_route_components|probe-session-open-prewarm-setprop-before-init|probe-session-open-prewarm-mixer-before-init` (`**/video_player/pure_c_agm_probe.c`), 5 results

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_pure_c_agm_probe.sh

本地已经恢复干净并编过了。现在直接推设备跑两个组件级 A/B：只做前置 `setprop`，只做前置 card0 mixer 路由，马上看哪一半才是真正的成功条件。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && adb push pure_c_agm_probe /data/local/tmp/

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-prewarm-setprop-before-init --probe-session-open-aif-media-preconnect-init' | grep -E '音频路由预热: phase=session-open probe\(pre-init split prewarm\) setprop rc=|session-open probe: (跳过开头 route prewarm|agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-prewarm-setprop-before-init --probe-session-open-aif-media-preconnect-init' | grep -E '音频路由预热: phase=session-open probe\(pre-init split prewarm\) setprop rc=|session-open probe: (跳过开头 route prewarm|agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-prewarm-mixer-before-init --probe-session-open-aif-media-preconnect-init' | grep -E '音频路由预热: phase=session-open probe\(pre-init split prewarm\) mixer rc=|session-open probe: (跳过开头 route prewarm|agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-prewarm-mixer-before-init --probe-session-open-aif-media-preconnect-init' | grep -E '音频路由预热: phase=session-open probe\(pre-init split prewarm\) mixer rc=|session-open probe: (跳过开头 route prewarm|agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

两个 probe 都还没打出 pre-init 组件日志，这不是设备态结果，而是代码分发还差最后一刀。我先核对 `probe_agm_session_open_close(...)` 调用参数顺序，确认这两个新布尔有没有真正传进去。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2790-2790), lines 2790 to 2865

Searched for text `probe_session_open_prewarm_setprop_before_init|probe_session_open_prewarm_mixer_before_init` (`**/video_player/pure_c_agm_probe.c`), 6 results

参数传递已经是通的，所以剩下就不是“没传进去”，而是代码执行位置本身得再核对一下。我直接读 `skip_route_prewarm` 那段体内逻辑，确认 pre-init 组件调用确实还在 `agm_init` 之前。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#547-547), lines 547 to 590

定位到了，最后一处漏点在这里：`skip_route_prewarm` 分支里现在只打了日志，还没真正调用 pre-init 组件 prewarm。这个补上就能得到真正的 `setprop-only` / `mixer-only` 结果。

Generating patch (14 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
现在才是完整状态。我直接重编、重推，并重跑刚才那两个组件级命令，拿最终结果。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_pure_c_agm_probe.sh
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_pure_c_agm_probe.sh

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && adb push pure_c_agm_probe /data/local/tmp/

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-prewarm-setprop-before-init --probe-session-open-aif-media-preconnect-init' | grep -E '音频路由预热: phase=session-open probe\(pre-init split prewarm\) setprop rc=|session-open probe: (跳过开头 route prewarm|agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-prewarm-setprop-before-init --probe-session-open-aif-media-preconnect-init' | grep -E '音频路由预热: phase=session-open probe\(pre-init split prewarm\) setprop rc=|session-open probe: (跳过开头 route prewarm|agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-prewarm-mixer-before-init --probe-session-open-aif-media-preconnect-init' | grep -E '音频路由预热: phase=session-open probe\(pre-init split prewarm\) mixer rc=|session-open probe: (跳过开头 route prewarm|agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-prewarm-mixer-before-init --probe-session-open-aif-media-preconnect-init' | grep -E '音频路由预热: phase=session-open probe\(pre-init split prewarm\) mixer rc=|session-open probe: (跳过开头 route prewarm|agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

这轮设备输出还不能用于结论，因为本地编译没过，设备上跑的还是上一版二进制。问题只差一个小点：`prewarm_recovery_audio_route_components(...)` 没有前置声明，导致新逻辑没进到设备。先把这个补上，再重跑同样两条命令。

Using "Apply Patch"

我要先读一下顶部声明区再补一行前置声明，避免继续在错误上下文上打补丁。

Searched for text `static int ensure_recovery_audio_route|static int log_pcm100_enum_ctl|static int prime_agm_post_connect_mfc` (`**/video_player/pure_c_agm_probe.c`), 3 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#196-196), lines 196 to 220

Generating patch (11 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
前置声明已经补上。现在这次是真正的最终重试：重编、重推，然后再跑 `setprop-only` 和 `mixer-only` 两条 pre-init 组件命令。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_pure_c_agm_probe.sh

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && adb push pure_c_agm_probe /data/local/tmp/

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-prewarm-setprop-before-init --probe-session-open-aif-media-preconnect-init' | grep -E '音频路由预热: phase=session-open probe\(pre-init split prewarm\) setprop rc=|session-open probe: (跳过开头 route prewarm|agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-prewarm-setprop-before-init --probe-session-open-aif-media-preconnect-init' | grep -E '音频路由预热: phase=session-open probe\(pre-init split prewarm\) setprop rc=|session-open probe: (跳过开头 route prewarm|agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-prewarm-mixer-before-init --probe-session-open-aif-media-preconnect-init' | grep -E '音频路由预热: phase=session-open probe\(pre-init split prewarm\) mixer rc=|session-open probe: (跳过开头 route prewarm|agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-prewarm-mixer-before-init --probe-session-open-aif-media-preconnect-init' | grep -E '音频路由预热: phase=session-open probe\(pre-init split prewarm\) mixer rc=|session-open probe: (跳过开头 route prewarm|agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

两条组件级 A/B 已经给出一个很硬的结果了：单独 `setprop` 不够，单独 card0 mixer 路由也不够，它们各自都还是 `-19`。我再补最后一个闭环对照，把这两半在 pre-init 里一起执行一次，确认“必须两者同时成立”而不是我拆分 helper 时漏了别的副作用。

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-prewarm-setprop-before-init --probe-session-open-prewarm-mixer-before-init --probe-session-open-aif-media-preconnect-init' | grep -E '音频路由预热: phase=session-open probe\(pre-init split prewarm\) (setprop|mixer) rc=|session-open probe: (跳过开头 route prewarm|agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-skip-route-prewarm --probe-session-open-prewarm-setprop-before-init --probe-session-open-prewarm-mixer-before-init --probe-session-open-aif-media-preconnect-init' | grep -E '音频路由预热: phase=session-open probe\(pre-init split prewarm\) (setprop|mixer) rc=|session-open probe: (跳过开头 route prewarm|agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

这个结果比预期更硬：就算把 `setprop` 和 card0 mixer 两半都在 pre-init 里补齐，结果仍然是 `-19`。这说明默认成功链里还有一层我们还没显式复制到。下一步我先重跑一条当前代码下的默认成功基线，确认是不是“默认 prewarm 仍成功，而 split helper 复刻失败”，还是现场状态本身已经漂了。

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-media-preconnect-init' | grep -E '音频路由预热: phase=session-open probe\(init\) (setprop|mixer) rc=|session-open probe: (agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-media-preconnect-init' | grep -E '音频路由预热: phase=session-open probe\(init\) (setprop|mixer) rc=|session-open probe: (agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

默认基线现在已经漂了，而且这比前面所有分叉都更关键：当前这版代码下，连最基础的 `--probe-session-open-aif-media-preconnect-init` 都已经是 `-19`，不再是之前那条成功链。所以我先把真正的现状钉住，确认漂移点是在 `aif_set_media_config` 这一层，还是更早。

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect-init' | grep -E 'session-open probe: (agm_init rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect-init' | grep -E 'session-open probe: (agm_init rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-media-preconnect-init' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-media-preconnect-init' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

当前最重要的新事实不是 prewarm 组件差异，而是 session-open 整条基线已经整体漂移了：连历史上能成功的 `preconnect-init` 和 `aif-media-preconnect-init` 现在都稳定变成了 `-19`。我先再钉一个历史成功锚点 `helper-prep-close-mixer`，确认这是“局部条件变了”还是“整个 session-open 分支都漂了”。

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-helper-prep-close-mixer-aif-media-preconnect-init' | grep -E 'session-open probe: (helper_prep rc|helper-prep 后已关闭 mixer|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-helper-prep-close-mixer-aif-media-preconnect-init' | grep -E 'session-open probe: (helper_prep rc|helper-prep 后已关闭 mixer|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

我把这个历史成功锚点的输出读出来。如果它也变成 `-19`，那当前任务就不是继续切 prewarm 组件，而是先把“session-open anchor 全面漂移”记录清楚，再做新的 rebaseline。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_Qkm8hPzu2kRLWAjF175LZxTT__vscode-1774278878558/content.txt)

当前已经不是细分 prewarm 组件的问题了，而是历史成功锚点整体漂到了失败面：`preconnect-init`、`aif-media-preconnect-init`、`helper-prep-close-mixer` 现在全都稳定是 `-19`。我先把这个 rebaseline 事实落文档和记忆，避免后面继续拿旧锚点当真。

Generating patch (59 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Created memory file twrp_audio_session_open_anchors_drifted_20260324.md

当前主线已经发生了一个更上游的变化，我先把它钉住了：

1. 不是只有某条 prewarm 组件实验跑偏。
2. 当前 session-open 的历史成功锚点已经整体漂移到 `-19`。
3. 所以后面不能再直接拿旧的 `rc=0` 地标去解释新的组件级 A/B。

我这轮实际确认了三件事：

1. `--probe-session-open-preconnect-init`
   现在已经是 `agm_session_open rc=-19`
2. `--probe-session-open-aif-media-preconnect-init`
   现在也稳定是 `agm_session_open rc=-19`
3. 历史成功锚点
   `--probe-session-open-helper-prep-close-mixer-aif-media-preconnect-init`
   现在同样漂到了 `agm_session_open rc=-19`

这意味着：

1. 当前不是单个条件在变。
2. 是整个 session-open 分支的成功面已经塌回失败面了。
3. 所以我刚做的 `setprop-only` / `mixer-only` / split-prewarm 这些细分实验，信息还在，但现在必须放在“新 baseline 已漂移”的前提下读，不能再直接和旧成功结论一一对照。

我已经把这个 rebaseline 事实补进续记，编号加到 14.83，也记了一条新的 repo memory，后面不会再误用旧锚点。

下一步最值钱的方向已经变了，不该继续抠 prewarm 组件，而是先回答：

1. 是什么把整个 session-open 分支从旧成功面整体拖回了当前 `-19`
2. 这个漂移是设备态变化、运行时环境变化，还是我们当前 probe 结构里某个更早的公共前置被改动了

如果你继续让我推，我下一刀会优先做“当前状态 rebaseline”而不是继续拆 prewarm：
1. 先找出当前最小还能成功的 session/open 入口，或者确认已经没有成功锚点
2. 然后再回头解释这次整体漂移的根因

Made changes.

User: 继续

GitHub Copilot: 我先不再改代码，直接把当前 `session_open` 分支重新扫一遍，找出现在还剩哪些最小入口、它们分别落在什么错误面。这样能先确认是“全面塌陷”还是“只是旧成功锚点消失”。

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-init' | grep -E 'session-open probe: (agm_init rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-init' | grep -E 'session-open probe: (agm_init rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect-init' | grep -E 'session-open probe: (agm_init rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect-init' | grep -E 'session-open probe: (agm_init rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-media-preconnect-init' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-media-preconnect-init' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|pre-connect rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-postconfig-init' | grep -E 'session-open probe: (agm_init rc|agm_session_open rc|postopen_set_config rc|postopen_set_config_small rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-postconfig-init' | grep -E 'session-open probe: (agm_init rc|agm_session_open rc|postopen_set_config rc|postopen_set_config_small rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

Compacted conversation当前最小面已经更清楚了：`init-only` 和 `postconfig-init` 现在是 `-32`，只要先 `pre-connect` 就稳定变成 `-19`。这说明分支没有“完全塌陷”，而是错误面重新分层了；下一步我直接扫源码里的剩余 `session_open` 入口，找还没重跑过的候选成功锚点。Optimizing tool selection...

Searched for text `probe-session-open-` (`**/video_player/pure_c_agm_probe.c`), 50 results

Searched for text `agm_session_open rc` (`**/video_player/pure_c_agm_probe.c`), 1 result

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#1-1), lines 1 to 260

源码里还有一组没重跑的候选：`success-metadata`、`split-metadata`、`devicepp`、`preconfig-split`。我先把这组一次性跑掉，看当前漂移是否已经扩展到“带元数据预置”的历史成功路径。

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-success-metadata-aif-media-preconnect-init' | grep -E 'session-open probe: (helper_prep rc|agm_init rc|aif_set_media_config rc|pre-connect rc|session_set_metadata rc|session_aif_set_metadata rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-success-metadata-aif-media-preconnect-init' | grep -E 'session-open probe: (helper_prep rc|agm_init rc|aif_set_media_config rc|pre-connect rc|session_set_metadata rc|session_aif_set_metadata rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-aif-media-preconnect-init' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|pre-connect rc|session_set_metadata rc|session_aif_set_metadata rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-aif-media-preconnect-init' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|pre-connect rc|session_set_metadata rc|session_aif_set_metadata rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-devicepp-aif-media-preconnect-init' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|pre-connect rc|session_set_metadata rc|session_aif_set_metadata rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-devicepp-aif-media-preconnect-init' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|pre-connect rc|session_set_metadata rc|session_aif_set_metadata rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconfig-split-metadata-devicepp-aif-media-preconnect-init' | grep -E 'session-open probe: (agm_init rc|preconfig_set_config rc|preconfig_set_config_small rc|aif_set_media_config rc|pre-connect rc|session_set_metadata rc|session_aif_set_metadata rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconfig-split-metadata-devicepp-aif-media-preconnect-init' | grep -E 'session-open probe: (agm_init rc|preconfig_set_config rc|preconfig_set_config_small rc|aif_set_media_config rc|pre-connect rc|session_set_metadata rc|session_aif_set_metadata rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

这轮结果说明得更狠：连带元数据的历史入口也全落回 `-19`，而 `preconfig` 额外暴露了一个稳定的 `preopen_set_config=-22`。我再读两段关键源码，把还剩下的 `A3004/A3006` 分支和无后缀 `--probe-session-open` 的真实行为确认掉，然后只补最有价值的两三个实验。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#650-650), lines 650 to 930

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2470-2470), lines 2470 to 2765

还剩两类信息没落地：无后缀总开关 `--probe-session-open` 走不走这套分支，以及 `A3004/A3006` 额外 GKV 变体是否能打出新的错误面。我直接定位 dispatch，再补这三条最小实验。

Searched for regex `probe_session_open_split_metadata_devicepp_a3004|probe_session_open_split_metadata_devicepp_a3006|probe_session_open_postconfig_init|probe_session_open\)` (`**/video_player/pure_c_agm_probe.c`), 21 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2766-2766), lines 2766 to 2895

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|pre-connect rc|session_set_metadata rc|session_aif_set_metadata rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|pre-connect rc|session_set_metadata rc|session_aif_set_metadata rc|agm_session_open rc|agm_session_close rc|fail-disconnect rc|post-disconnect rc)'

现在已经确认无后缀总开关只是最裸 `session_open`，对应 `-32`。我把最后两个 `A3004/A3006` 变体补完；如果它们也落在 `-19`，这一轮就可以正式收口成“当前仅剩两层错误面：裸开 `-32`，凡是 pre-connect 链统一 `-19`”。

Read [](file:///memories/)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#1-1), lines 1 to 40

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-devicepp-a3004-aif-media-preconnect-init' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|session_set_metadata.*rc|split\+devicepp session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|fail-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-devicepp-a3004-aif-media-preconnect-init' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|session_set_metadata.*rc|split\+devicepp session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|fail-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-devicepp-a3006-aif-media-preconnect-init' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|session_set_metadata.*rc|split\+devicepp session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|fail-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-split-metadata-devicepp-a3006-aif-media-preconnect-init' | grep -E 'session-open probe: (agm_init rc|aif_set_media_config rc|session_set_metadata.*rc|split\+devicepp session_aif_set_metadata rc|pre-connect rc|agm_session_open rc|fail-disconnect rc)'

A3004/A3006 也没有分叉，和其余 pre-connect 链一样统一落在 `-19`。我现在只做两件事：先核对续记文档末尾的真实 EOF 和当前最大节号，再把这一轮“错误面重新分层”的结论追加进去，同时补一条 repo memory。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#1320-1320), lines 1320 to 1420

Read memory

Read memory /memories/repo/

我已经确认 memory 名称空间里没有这条新结论的重复文件。现在只差文档尾部定位和旧 memory 对照，确认追加编号与内容边界，然后我就落盘。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#4300-4300), lines 4300 to 4405

Ran terminal command:  wc -l 'docs/TWRP音频手动Bring-up-续.md'
Completed with input:  wc -l 'docs/TWRP音频手动Bring-up-续.md'

Read memory twrp_audio_session_open_anchors_drifted_20260324.md

刚才那次 `wc` 只是因为相对路径不在当前 cwd。我要把真实总行数和最后一段拿准，然后直接做末尾追加，不会去动文档中段。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#5496-5496), lines 5496 to 5496

Ran terminal command:  wc -l '/Volumes/Case-sensitive APFS/TWRP/docs/TWRP音频手动Bring-up-续.md'

EOF 已经确认在 5495 行。我再把最后一屏读出来，核对当前最大节号和段落边界，然后就落补充结论。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#5435-5435), lines 5435 to 5495

我准备把这一轮结论追加到续记末尾：不是再补“又一个失败样本”，而是把当前 `session_open` 分支的两层错误面正式固定下来，避免后面继续拿旧成功锚点做参照。

Generating patch (71 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```
文档已经只在 EOF 追加了 14.84。接着我把同样的核心结论收成一条 repo memory，后面继续跑 `-32 -> -19` 分界时就不用再从长文里回捞。

Created memory file twrp_audio_session_open_two_error_planes_20260324.md

我再往前推半步，不改代码：直接测 `--probe-session-open-preconnect`。这条能把 `agm_init` 从方程里拿掉，判断当前 `-32 -> -19` 的切换到底是不是已经被 `agm_session_aif_connect` 单独触发。

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect' | grep -E 'session-open probe: (pre-connect rc|agm_init rc|agm_session_open rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect' | grep -E 'session-open probe: (pre-connect rc|agm_init rc|agm_session_open rc|fail-disconnect rc|post-disconnect rc)'

这一步把分界再收紧了一刀：`--probe-session-open-preconnect` 在不做 `agm_init` 的情况下，已经能把错误面直接切到 `-19`。也就是说，当前 `-32 -> -19` 的切换不需要等到 `agm_init` 才发生，我把这点追加到续记末尾。

Generating patch (41 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```
我顺手把 repo memory 也补一行，避免后面又把 `agm_init` 误当成错误面切换的最低触发点。

Updated memory file twrp_audio_session_open_two_error_planes_20260324.md

继续推进了一步，当前主线已经从“旧成功锚点漂移了”收紧到“错误面如何切换”。

本轮确认了三件事：

1. 当前 `session_open` 不是单一失败面。
2. 不做 `pre-connect` 的裸开链，稳定是 `agm_session_open rc=-32`。
3. 只要先进入 `pre-connect`，无论再叠加 `aif media config`、success metadata、split metadata、devicepp、A3004、A3006，最终都会稳定切到 `agm_session_open rc=-19`。

新增的最关键实验是：

1. 跑了 `--probe-session-open-preconnect`
2. 这条不做 `agm_init`
3. 结果仍然是 `pre-connect rc=0` 后，`agm_session_open rc=-19`

这说明当前 `-32 -> -19` 的切换，最低触发点已经收缩到 `pre-connect` 本身，不需要等到 `agm_init`。

另外也补齐了当前源码里剩余的历史变体，结果都没有跳出这个两层模型：

1. `--probe-session-open-success-metadata-aif-media-preconnect-init`
2. `--probe-session-open-split-metadata-aif-media-preconnect-init`
3. `--probe-session-open-split-metadata-devicepp-aif-media-preconnect-init`
4. `--probe-session-open-preconfig-split-metadata-devicepp-aif-media-preconnect-init`
5. `--probe-session-open-split-metadata-devicepp-a3004-aif-media-preconnect-init`
6. `--probe-session-open-split-metadata-devicepp-a3006-aif-media-preconnect-init`

文档已追加两节：

1. 14.84：当前 `session_open` 分成 `-32` 和 `-19` 两个稳定错误面
2. 14.85：`pre-connect` 单独就足以把错误面从 `-32` 推进到 `-19`

repo memory 也已经同步更新，后面不用再回头从长文里找这条结论。

下一步最值钱的方向已经很明确：

1. 继续围绕 `agm_session_aif_connect` 本身做最小拆分
2. 搞清楚它是直接改变了 open 前置条件，还是只是把某个更底层状态机推进到另一层缺口

如果你继续，我下一轮就直接围绕这个 `pre-connect` 分界做最小 A/B，不再枚举 metadata 组合。

Made changes.

User: 继续

GitHub Copilot: 我先不碰大逻辑，直接看 `probe_agm_session_open_close` 里 `pre-connect` 前后还能插什么最小动作。目标是只加一两个“能判定是否存在 latch”的 A/B，而不是再扩散 probe 矩阵。

Searched for regex `static int probe_agm_session_open_close|agm_session_aif_connect` (`**/video_player/pure_c_agm_probe.c`), 11 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#520-520), lines 520 to 760

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#760-760), lines 760 to 900

我要加一个最小修饰开关：先 `pre-connect`，再在 `open` 前立刻 `disconnect`。这能直接判定当前 `-19` 是不是要求“连接态仍然存活”，还是 `pre-connect` 已经留下了可持续的 side effect。

Generating patch (65 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
代码已经加了一个最小修饰位，不影响现有矩阵，只是在 `pre-connect` 后多一个可选的“先断再开”。我先编译确认没有把 probe 本身搞坏，再立刻跑两条 A/B。

Checked [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c), 24 problems found

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_pure_c_agm_probe.sh

本地构建已经过了，编辑器里的 clang 报警还是老的 Android 头文件缺失噪声，不是这次改动引入的编译问题。下一步直接推设备，跑 `preconnect` 和 `preconnect-init` 各自的“先连后断”对照。

Ran terminal command:  adb push '/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_agm_probe' /data/local/tmp/pure_c_agm_probe

Ran terminal command:  adb shell chmod 755 /data/local/tmp/pure_c_agm_probe

设备侧二进制已更新。现在只差两条判定性实验：`preconnect` 和 `preconnect-init` 各自加上“先连后断”，看错误面会不会回落到 `-32`。

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect --probe-session-open-disconnect-before-open' | grep -E 'session-open probe: (pre-connect rc|pre-disconnect-before-open rc|agm_init rc|agm_session_open rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect --probe-session-open-disconnect-before-open' | grep -E 'session-open probe: (pre-connect rc|pre-disconnect-before-open rc|agm_init rc|agm_session_open rc|fail-disconnect rc|post-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect-init --probe-session-open-disconnect-before-open' | grep -E 'session-open probe: (pre-connect rc|pre-disconnect-before-open rc|agm_init rc|agm_session_open rc|fail-disconnect rc|post-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect-init --probe-session-open-disconnect-before-open' | grep -E 'session-open probe: (pre-connect rc|pre-disconnect-before-open rc|agm_init rc|agm_session_open rc|fail-disconnect rc|post-disconnect rc)'

结果已经很硬了：一旦在 `open` 前把连接撤掉，错误面无论有没有 `agm_init` 都直接回落到 `-32`。这说明当前没有观察到“pre-connect 留下可持续 latch”，`-19` 依赖的是 open 当下仍处在连接态。

Generating patch (49 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```
我再把 repo memory 同步成“无 latch、依赖 live connected state”，这样下一轮可以直接沿着“连接态仍存活时还缺什么”继续缩。

Updated memory file twrp_audio_session_open_two_error_planes_20260324.md

我先不再改源码，直接把“live connected state”再和 route prewarm 解耦一次。目标是确认当前 `-32 -> -19` 的切换，是否连 route prewarm 都不再依赖。

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect --probe-session-open-skip-route-prewarm' | grep -E 'session-open probe: (跳过开头 route prewarm|pre-connect rc|agm_init rc|agm_session_open rc|fail-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect --probe-session-open-skip-route-prewarm' | grep -E 'session-open probe: (跳过开头 route prewarm|pre-connect rc|agm_init rc|agm_session_open rc|fail-disconnect rc)'

Ran terminal command:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect-init --probe-session-open-skip-route-prewarm' | grep -E 'session-open probe: (跳过开头 route prewarm|pre-connect rc|agm_init rc|agm_session_open rc|fail-disconnect rc)'
Completed with input:  adb shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect-init --probe-session-open-skip-route-prewarm' | grep -E 'session-open probe: (跳过开头 route prewarm|pre-connect rc|agm_init rc|agm_session_open rc|fail-disconnect rc)'

我把这条也落下来：当前 `-32 -> -19` 的切换连 route prewarm 都不依赖。这样下一轮就可以彻底把注意力从 prewarm 时序挪开，只盯 live connected state 下还缺的前置条件。

Generating patch (38 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Updated memory file twrp_audio_session_open_two_error_planes_20260324.md

继续推进了，当前主线又收紧了两层。

这轮做了什么：

1. 给 probe 加了一个最小修饰开关：
   `--probe-session-open-disconnect-before-open`
2. 它的行为是：
   先 `pre-connect`，再在 `agm_session_open` 前立刻 `disconnect`
3. 重新编译、推到设备，并跑了 4 组关键 A/B：
   `preconnect`
   `preconnect-init`
   `preconnect + skip-route-prewarm`
   `preconnect-init + skip-route-prewarm`

新结论：

1. 当前没有观察到 `pre-connect` 的持久 latch。
2. 只要在 `open` 前把连接撤掉，错误面无论是否做过 `agm_init`，都会从 `-19` 直接回落到 `-32`。
3. 这说明当前 `-19` 依赖的是 `agm_session_open` 发生时，AIF 仍处于 live connected state。
4. 同时，当前 `-32 -> -19` 的切换连 route prewarm 都不再依赖。
5. 在 `skip-route-prewarm` 条件下，只要 `pre-connect` 还活着，`agm_session_open` 仍然稳定是 `-19`。

现在这条主线已经可以压成一句话：

1. 把错误面从最裸 `-32` 推到 `-19` 的必要条件，已经收缩到“open 当下连接态仍存活”。
2. 它不要求 `agm_init`。
3. 它也不要求 route prewarm。
4. 它也不像是 connect 后残留了某种可脱离连接态单独存在的 side effect。

我已经把这轮结果追加进续记，并同步到 repo memory。

下一步最值钱的方向已经很明确：

1. 不再围绕 prewarm 或 metadata 组合打转
2. 直接追 live connected state 下，`agm_session_open` 还缺哪一个前置条件，才会从当前 `-19` 继续往前推进

如果你继续，我下一轮就直接围绕“连接态已满足，但 open 仍是 `-19`”做最小 A/B。

Made changes.


# 第6章：跨进程-deinit-reset与真实播放链分叉
User: 继续

GitHub Copilot: 我先把主线从“API 调用层本身”再缩一刀到“它是全局污染还是只污染目标 session”。这一步最值钱，因为能决定后面是继续查 session 本地语境，还是查更上游的全局状态机。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#680-680), lines 680 to 820

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2670-2670), lines 2670 to 2865

我继续只做一刀最值钱的 A/B：把 `session_aif_set_metadata` 发到“别的 session”，而 `open` 仍然开 fresh 的 `session101`。这样能直接判断当前 `-19` 是 session 本地污染，还是一次 metadata 调用就会全局扩散。

Generating patch (101 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
Compacting conversation...

Made changes.

User: 继续

GitHub Copilot: 我直接做“metadata 发到别的 session”这一刀，不再扩别的变量。目标是确认当前 `session_aif_set_metadata` 把 fresh session 拉回 `-19`，到底是目标 session 本地污染，还是一次调用就会跨 session 扩散。

Searched for regex `open_session_id|session_aif_set_metadata\(|probe_session_open_open_session101|probe_session_open_preconnect_session101` (`**/video_player/pure_c_agm_probe.c`), 17 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#430-430), lines 430 to 820

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2660-2660), lines 2660 to 3015

Compacted conversation上下文够了：代码里已经提前留出了 `metadata_session_id` 通路，主缺口只是把它真正接到 CLI 和实验矩阵上，然后直接做设备侧验证。下一步我会补这个开关并马上跑对照。Optimizing tool selection...

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#3015-3015), lines 3015 to 3065

代码其实已经把 `metadata_session_id` 这条线接好了，说明现在不需要再改探针，直接进入编译、下发、设备 A/B。我要先确认现成构建/推送命令，避免重复走弯路。

Searching for text `pure_c_agm_probe`

Got last terminal command

Read memory /memories/repo/

我没拿到终端历史，但仓库记忆里已经确认这条支线存在。现在改用本地 `rg` 找现成的构建/推送脚本或命令痕迹，直接复用。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n "pure_c_agm_probe|adb push .*pure_c_agm_probe|clang .*pure_c_agm_probe" -S video_player docs README.md .

Read memory twrp_audio_session_open_two_error_planes_20260324.md

我已经确认现成构建脚本在仓库里，CLI 也已有 `metadata_session102` 开关。接下来不改代码，直接用脚本构建，再用短命令确认设备串号并跑两组最小对照。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/build_pure_c_agm_probe.sh)

Read memory twrp_audio_session_open_two_error_planes_20260324.md

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb devices
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb devices

构建脚本已确认，上一条终端输出被旧搜索命令串扰了。我切回更短、更干净的单条命令：先编译，再单独确认 adb 设备，避免共享终端上下文继续污染。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/video_player' && ./build_pure_c_agm_probe.sh

Ran terminal command:  adb devices | cat

现在进入设备侧最小对照：同一条 fresh `session101+aif16`，只改 metadata 目标 session。结果会直接告诉我们这是“本地污染”还是“调用即全局扩散”。

Ran terminal command:  adb -s 70a91f89 push '/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_agm_probe' /data/local/tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /data/local/tmp/pure_c_agm_probe && adb -s 70a91f89 shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101'
Completed with input:  adb -s 70a91f89 push '/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_agm_probe' /data/local/tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /data/local/tmp/pure_c_agm_probe && adb -s 70a91f89 shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101'

Ran terminal command:  adb -s 70a91f89 push '/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_agm_probe' /data/local/tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /data/local/tmp/pure_c_agm_probe && adb -s 70a91f89 shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101 --probe-session-open-metadata-session102'
Completed with input:  adb -s 70a91f89 push '/Volumes/Case-sensitive APFS/TWRP/video_player/pure_c_agm_probe' /data/local/tmp/pure_c_agm_probe && adb -s 70a91f89 shell chmod 755 /data/local/tmp/pure_c_agm_probe && adb -s 70a91f89 shell '/data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101 --probe-session-open-metadata-session102'

对照结果已经出来了，而且比预期更硬：把 metadata 发到 `session102`，`open session101` 依然掉回 `-19`。这说明它至少不是“只污染目标 session”。我再补一刀最小分叉，把 metadata 改发到 `AIF17`，这样能区分“跨 session 但仍是同 AIF 污染”还是“调用本身全局污染”。

Using "Apply Patch"

User: @agent Try Again

GitHub Copilot: Compacted conversation继续当前主线：先把刚确认的“跨 session metadata 也把 fresh session101 拉回 -19”补进日志与仓库记忆，然后立刻做下一组最小 A/B，把问题继续压缩到“调用时序”还是“调用本身”。Optimizing tool selection...

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#1-1), lines 1 to 260

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#1-1), lines 1 to 420

Read memory twrp_audio_session_open_two_error_planes_20260324.md

现状已经确认：仓库记忆还停在“metadata 调用本身可疑”，最新的“metadata 打到 session102 仍拖垮 session101”还没落盘。下一步我先读日志尾部与当前探针分支，避免把新实验插到错误位置。

Read changed files in [](file:///Volumes/Case-sensitive%20APFS/TWRP)

Searched for regex `14\.9[0-9]|15\.` (`**/docs/TWRP音频手动Bring-up-续.md`), 19 results

Searched for regex `probe_session_open_metadata_session102|aif-only-metadata|disconnect-before-open|open-session101|preconnect-session101` (`**/video_player/pure_c_agm_probe.c`), 21 results

我已经确认工作树是干净的，可以直接补实验开关而不踩到别的改动。现在读核心函数的 session-open 路径，准备加一个只改变“metadata 与 pre-connect 顺序”的开关，这样能把“API 调用本身污染”与“live connected 状态+metadata 组合污染”拆开。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#700-700), lines 700 to 930

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2680-2680), lines 2680 to 3045

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#5968-5968), lines 5968 to 6008

可以开始动代码了。当前函数里 metadata 固定在 pre-connect 前执行，所以没法直接回答“只要调用过 metadata 就污染”还是“metadata 与 live connected state 的组合才污染”；我会加一个仅改变顺序的开关，不改其他变量。

Searched for regex `static int probe_agm_session_open_close\(|probe_agm_session_open_close\(` (`**/video_player/pure_c_agm_probe.c`), 2 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#430-430), lines 430 to 720

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#3045-3045), lines 3045 to 3084

准备修改 pure_c_agm_probe.c：只新增一个 session-open 开关，把 pre-connect 提前到 metadata 之前，其余参数和默认路径保持不变。这样跑完后就能直接比较“metadata 前无 live connected state”和“metadata 前已有 live connected state”两种形态。

Generating patch (335 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
开关已经加进去，默认行为不变，新行为只多一条可选顺序分支。接下来先编译验证，再在设备上做两组最小对照：same-session 和 cross-session，唯一变量都是这个新顺序开关。

Checked [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c), 24 problems found

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && ./video_player/build_pure_c_agm_probe.sh

本地构建通过，编辑器里的报错只是宿主机缺 Android 头，不影响交叉编译结果。现在直接在 recovery 机上跑两个新顺序实验，验证 metadata 调用时是否必须已经存在 live connected state。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb devices

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb push ./video_player/pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb shell chmod 755 /data/local/tmp/pure_c_agm_probe

二进制已推送到设备。下一组只改顺序，不改 session、AIF、payload 和 open 目标：先跑 same-session，再跑 cross-session。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101 --probe-session-open-preconnect-before-metadata
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101 --probe-session-open-preconnect-before-metadata

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101 --probe-session-open-metadata-session102 --probe-session-open-preconnect-before-metadata
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101 --probe-session-open-metadata-session102 --probe-session-open-preconnect-before-metadata

新实验结果已经足够形成一条更硬的结论：把 pre-connect 提前到 metadata 之前，same-session 和 cross-session 仍都稳落 -19。现在把这条“顺序不敏感”结论补进日志和仓库记忆，方便后面继续沿 API 语义往下压。

Generating patch (79 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Inserted into memory file twrp_audio_session_open_two_error_planes_20260324.md

关键结论已经落盘。为了给你一个可追踪的结果，我再抓一下新增开关和新日志段落的位置，然后给出这次 A/B 的结论与下一刀建议。

Read changed files in [](file:///Volumes/Case-sensitive%20APFS/TWRP)

Searched for text `preconnect-before-metadata|pre-connect-before-metadata` (`**/video_player/pure_c_agm_probe.c`), 4 results

Searched for regex `14\.96|14\.97` (`**/docs/TWRP音频手动Bring-up-续.md`), 4 results

这次我直接把顺序 A/B 做完了，结果比前一轮更硬：

1. 我在 pure_c_agm_probe.c 加了一个新开关，把 pre-connect 提前到 metadata 之前。
2. 新开关的参数解析在 pure_c_agm_probe.c，usage 也同步补了 pure_c_agm_probe.c。
3. 交叉编译成功，二进制已重新推到 recovery 设备上实测。

设备侧新 A/B 结果：

1. same-session
   命令形态是 aif-only metadata + aif media + preconnect + open session101，再加 preconnect-before-metadata。
   结果：
   pre-connect-before-metadata rc=0
   session_aif_set_metadata rc=0，session=101
   agm_session_open 仍然是 rc=-19

2. cross-session
   只把 metadata 目标切到 session102，其它保持 open/preconnect 都在 session101，再加 preconnect-before-metadata。
   结果：
   pre-connect-before-metadata rc=0
   session_aif_set_metadata rc=0，session=102
   agm_session_open 仍然是 rc=-19

这意味着当前结论又收紧了一步：

1. 问题已经不是某个特定 payload。
2. 也不是 metadata 必须打到和 open 相同的 session。
3. 现在连 metadata 与 pre-connect 的先后顺序看起来也不敏感。
4. 当前最强假设更像是：session_aif_set_metadata 这层调用会触发某种 API 级或进程级语境切换，把 fresh session101 从 rc=0 推回 rc=-19。

文档我已经补上：

1. 顺序翻转的 same-session 结论写在 TWRP音频手动Bring-up-续.md
2. cross-session + 顺序翻转的结论写在 TWRP音频手动Bring-up-续.md

如果继续往下压，下一刀最值钱的是：

1. 加一个 metadata 之后立刻 disconnect，再 open 的分支，看能不能把 rc=-19 拉回 rc=0
2. 加一个同进程内 metadata 调用次数 A/B，验证一次调用和多次调用是否等价
3. 加一个 metadata 后重新 agm_init 或新进程重启探针的 A/B，验证这种污染是不是只活在单进程生命周期里

你如果要我继续，我建议直接做第 1 个，因为它最能区分“临时 live state 污染”还是“更高层 API 状态污染”。

Made changes.

User: 继续

GitHub Copilot: 继续往下压这条主线：我先不再改代码，直接利用现有开关做“metadata 后再断开、再 open”的 A/B。这样可以把“metadata 调用本身就污染”与“open 当下仍要有 live connected state 才会落 -19”拆开。

Created 3 todos

这组实验只改 open 前是否仍保留 live connected state，预期能直接回答当前 -19 是“metadata 一次调用就足够”还是“metadata 还必须叠加 open 当下的 live state”。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb devices

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101 --probe-session-open-preconnect-before-metadata --probe-session-open-disconnect-before-open
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101 --probe-session-open-preconnect-before-metadata --probe-session-open-disconnect-before-open

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101 --probe-session-open-metadata-session102 --probe-session-open-preconnect-before-metadata --probe-session-open-disconnect-before-open
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101 --probe-session-open-metadata-session102 --probe-session-open-preconnect-before-metadata --probe-session-open-disconnect-before-open

结果已经分出来了：只要把 live connected state 在 open 前拿掉，哪怕 metadata 已经打过，同一轮 open 也会从 -19 退回 -32。现在我把这个关键分水岭补进日志和仓库记忆。

Generating patch (72 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Inserted into memory file twrp_audio_session_open_two_error_planes_20260324.md

这一步已经把“metadata 单独污染一切”否掉了。下一刀我准备加一个最小重连开关：metadata 后先断开，再在 open 前重连。这样能验证决定 -19 的到底是“metadata 发生过 + open 当下有 live state”，还是还依赖第一次 connect 的那次历史。

Generating patch (63 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
我已经把“断开后再重连”的最小开关加上了，默认路径不变。现在重编译并直接跑 same-session / cross-session 两组重连实验，验证 -19 是不是只认 open 当下的 live state。

Checked [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c), 24 problems found

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && ./video_player/build_pure_c_agm_probe.sh

编译已过，编辑器里的错误仍然只是本机缺 Android 头。接下来推送新二进制并跑“断开后再重连”的两组设备侧 A/B。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb push ./video_player/pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb shell chmod 755 /data/local/tmp/pure_c_agm_probe

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101 --probe-session-open-preconnect-before-metadata --probe-session-open-disconnect-before-open --probe-session-open-reconnect-before-open
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101 --probe-session-open-preconnect-before-metadata --probe-session-open-disconnect-before-open --probe-session-open-reconnect-before-open

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101 --probe-session-open-metadata-session102 --probe-session-open-preconnect-before-metadata --probe-session-open-disconnect-before-open --probe-session-open-reconnect-before-open
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101 --probe-session-open-metadata-session102 --probe-session-open-preconnect-before-metadata --probe-session-open-disconnect-before-open --probe-session-open-reconnect-before-open

重连实验结果很干净：metadata 后先断再重连，-19 立刻回来，而且 same-session / cross-session 都一致。也就是说，当前最稳的模型已经收敛成“metadata 改写 open-time live state 的错误面”，不是第一次 connect 本身有魔法。

Generating patch (72 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Inserted into memory file twrp_audio_session_open_two_error_planes_20260324.md

主线已经再收紧了一层，我把这一轮收尾一下：更新计划状态，然后给你一个只保留增量结论的总结。

Completed: *跑断开前开路A/B* (1/3)

这一轮已经把模型继续压实了，而且不是停在分析上，我把新的 A/B 也跑完了。

新增结论

1. 如果先 connect，再发 metadata，然后在 open 前 disconnect，那么 open 会从 -19 退回 -32。
2. 如果在上面这条路径里，再在 open 前 reconnect 一次，那么 open 会立刻回到 -19。
3. 这个结论在 same-session 和 cross-session 两组里都成立。

这说明现在最稳的模型已经变成：

1. open 当下没有 relevant live connected state，结果就是 -32。
2. fresh session101+aif16 只有 live connected state、没有 metadata 时，可以得到 0。
3. 同一进程里一旦调用过 session_aif_set_metadata，只要 open 当下 relevant live connected state 又存在，open 就会稳定掉到 -19。
4. 所以当前 -19 不像是某个特定 payload，也不像第一次 connect 的历史痕迹。
5. 更像是 session_aif_set_metadata 改写了“后续 relevant live connected state 对应的 agm_session_open 语义面”。

我这次实际做了什么

1. 先直接用现有开关跑了两组断开实验：
   same-session 和 cross-session 都从 -19 退回 -32。
2. 然后我在探针里补了一个最小开关，允许在 disconnect 之后、open 之前再 reconnect。
3. 重编译、推送到 recovery 设备后，又把 same-session 和 cross-session 两组重连实验跑完。
4. 两组都稳定回到 -19。
5. 日志和仓库记忆也已经同步追加。

当前最有价值的下一刀

1. 直接测“metadata 调用次数”是否影响结果。
2. 也就是比较一次 metadata、两次 metadata、不同 session 各一次 metadata，但保持 open 当下 live connected state 不变。
3. 这能继续判断 -19 是一个二值语境切换，还是还存在更细的计数/覆盖规则。

如果继续，我建议下一步就做这个“调用次数 / 多 session metadata 次序”A/B。

Made changes.

User: 继续

GitHub Copilot: 继续沿“API 调用形态”往下压，这一轮我直接测 metadata 调用次数与跨 session 叠加是否会改变结论。先补一个最小二次 metadata 开关，再跑双调用 A/B。

Created 3 todos

这次改动会尽量小：只给现有 aif-only metadata 路径增加“再打一遍”的能力，避免碰 success/split 分支。读完对应代码后我就直接补开关。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#700-700), lines 700 to 840

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2700-2700), lines 2700 to 2955

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#6070-6070), lines 6070 to 6165

我已经看清 metadata 分支了，改动可以很小：只在 aif-only 路径后面加一条“可选第二次 metadata”调用，不碰别的分支。补完后直接跑三组双调用实验。

Generating patch (54 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
参数已经接进主流程了，接下来只补函数里的第二次 metadata 调用本体。然后就能编译并直接跑三组双调用实验。

Generating patch (28 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
代码改完了，开始编译验证；如果过，就立刻推到设备上跑 3 组双 metadata A/B。

Checked [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c), 24 problems found

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && ./video_player/build_pure_c_agm_probe.sh

构建已过，可以直接上机。下面三组分别对应：同 session 连打两次、101 后 102、102 后 101。这样能看出调用次数和跨 session 次序是否真的还会改变面向。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb push ./video_player/pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb shell chmod 755 /data/local/tmp/pure_c_agm_probe

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-double-aif-only-metadata --probe-session-open-preconnect-session101 --probe-session-open-open-session101 --probe-session-open-preconnect-before-metadata
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-double-aif-only-metadata --probe-session-open-preconnect-session101 --probe-session-open-open-session101 --probe-session-open-preconnect-before-metadata

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-double-aif-only-metadata-other-session --probe-session-open-preconnect-session101 --probe-session-open-open-session101 --probe-session-open-preconnect-before-metadata
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-double-aif-only-metadata-other-session --probe-session-open-preconnect-session101 --probe-session-open-open-session101 --probe-session-open-preconnect-before-metadata

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-double-aif-only-metadata-other-session --probe-session-open-preconnect-session101 --probe-session-open-open-session101 --probe-session-open-metadata-session102 --probe-session-open-preconnect-before-metadata
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-double-aif-only-metadata-other-session --probe-session-open-preconnect-session101 --probe-session-open-open-session101 --probe-session-open-metadata-session102 --probe-session-open-preconnect-before-metadata

三组双 metadata 结果已经出来了，而且非常一致：调用次数和 101/102 的先后次序目前都没有把面向改出 -19。我先把这条“次数/次序也不敏感”的结论落盘，再决定是否继续压到“同进程 re-init 是否能清掉语境”。

Generating patch (67 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Inserted into memory file twrp_audio_session_open_two_error_planes_20260324.md

次数和 101/102 次序已经基本排干净了，下一刀就压到 reset 语义。最小办法是在同一进程里、open 之前再补一次 agm_init，看它能不能把 metadata 语境清掉。

Generating patch (68 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
re-init 开关已经补上，默认行为不变。现在直接重编译并跑 same-session / cross-session 两组 reinit-before-open 实验，看 agm_init 是否真有 reset 能力。

Checked [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c), 24 problems found

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && ./video_player/build_pure_c_agm_probe.sh

编译通过，直接上机跑 reinit A/B。这里唯一变量就是 open 前额外再调一次 agm_init。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb push ./video_player/pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb shell chmod 755 /data/local/tmp/pure_c_agm_probe

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101 --probe-session-open-preconnect-before-metadata --probe-session-open-reinit-before-open
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101 --probe-session-open-preconnect-before-metadata --probe-session-open-reinit-before-open

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101 --probe-session-open-metadata-session102 --probe-session-open-preconnect-before-metadata --probe-session-open-reinit-before-open
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101 --probe-session-open-metadata-session102 --probe-session-open-preconnect-before-metadata --probe-session-open-reinit-before-open

re-init 结果也出来了，而且很硬：同进程里再调一次 agm_init 并没有把 metadata 语境清掉。最后把这条追加进日志和仓库记忆，再给你一个只保留新增信息的结论。

Generating patch (57 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Inserted into memory file twrp_audio_session_open_two_error_planes_20260324.md

Completed: *加二次metadata开关* (1/3)

这一轮我没有停在“猜”，而是把两类更强 A/B 都跑完了。

新增实测结论

1. aif-only metadata 连打两次，结果不变。
2. 两次 metadata 的 101/102 次序对调，结果也不变。
3. metadata 之后、open 之前在同进程里再补一次 agm_init，结果还是不变。

具体落点

1. `101 -> 101` 双 metadata，`agm_session_open` 仍然是 `-19`
2. `101 -> 102` 双 metadata，仍然是 `-19`
3. `102 -> 101` 双 metadata，仍然是 `-19`
4. same-session metadata 后再 `agm_init` 一次，仍然是 `-19`
5. cross-session metadata 后再 `agm_init` 一次，仍然还是 `-19`

这把当前模型又收紧了一层：

1. 当前错误面至少对 metadata 调用次数不敏感。
2. 也对 101/102 的 metadata 先后顺序不敏感。
3. 还不会被同进程里额外再调一次 agm_init 清掉。
4. 所以现在更像一个进程内持续存活的 metadata 语境，而不是某次调用的瞬时边沿效果。

到现在为止，最稳的工作模型是：

1. open 当下没有 relevant live connected state，结果是 `-32`
2. fresh `session101 + aif16` 只有 live connected state、没有 metadata 时，结果可以是 `0`
3. 同进程里一旦建立过 metadata 语境，只要 open 当下 relevant live connected state 存在，结果就稳定变成 `-19`
4. 这个语境不吃次数、不吃 101/102 顺序，也不被额外一次 agm_init 清掉

我已经把结果补进长日志和仓库记忆。

如果继续往下压，现在最值钱的只剩两条：

1. 找更强的同进程 reset，确认有没有真正的 deinit / teardown 能把这个语境清掉
2. 做跨进程 A/B：一个进程只负责打 metadata，另一个全新进程只负责 open，验证 `-19` 会不会跨进程延续

下一步我建议直接做第 2 条。它最能区分“进程内库态污染”还是“驱动/系统侧全局污染”。

Made changes.

User: 继续

GitHub Copilot: 继续压到跨进程：我先加一个最小的“open 前直接退出”开关，这样第一个进程可以只负责打 metadata 并在退出前断开 live state，第二个全新进程再做 fresh preconnect/open。这样能直接区分“进程内库态污染”还是“跨进程延续”。

Created 3 todos

这次改动只影响 session-open 路径的最后一步：在所有 setup 做完后、真正 open 前允许直接返回，不触碰默认路径。补完就能直接用两次 adb shell 做跨进程实验。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#820-820), lines 820 to 940

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#2720-2720), lines 2720 to 2965

可以直接改了：我只加一个 `exit-before-open`，让第一个进程做完 metadata 和 disconnect 后提前退出，不再触发 open/清理分支。这样第二个 adb shell 就是干净的新进程。

Generating patch (61 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
开关已经加好了。下一步直接编译、推送，然后跑两段式跨进程实验：第一段只打 metadata 后退出，第二段全新进程 fresh preconnect/open，不带 metadata。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && ./video_player/build_pure_c_agm_probe.sh

Checked [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c), 24 problems found

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb push ./video_player/pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb shell chmod 755 /data/local/tmp/pure_c_agm_probe

二进制已经上机。现在开始两段式跨进程 A/B：进程 A 只做 metadata 后退出，进程 B 是全新 adb shell，只做 fresh preconnect/open，不带 metadata。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-open-session101 --probe-session-open-preconnect-session101 --probe-session-open-preconnect-before-metadata --probe-session-open-disconnect-before-open --probe-session-open-exit-before-open

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101

第一组跨进程结果不够干净，因为第二个新进程在“无 metadata 的 fresh preconnect/open”下也落到了 -19，和旧基线不一致。现在先补一条必要对照，把当前时刻的 fresh session101 baseline 重新钉死，否则跨进程结论会失真。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-media-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-preconnect-init --probe-session-open-preconnect-session101 --probe-session-open-open-session101

当前问题不是实验做不动，而是 `session101` 这条旧基线已经漂移到 fresh preconnect/open 也稳定 -19，导致跨进程结果失去判别力。我直接把 session id 参数化，切到新的 fresh session 继续跑，避免在旧 session 上打转。

Generating patch (63 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
session id 已参数化，接下来先找一个还没被历史实验污染的 fresh session。优先试 103 和 104，先钉哪个还能稳定回到 0，再拿它做跨进程。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && ./video_player/build_pure_c_agm_probe.sh

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb push ./video_player/pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb shell chmod 755 /data/local/tmp/pure_c_agm_probe

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-media-preconnect-init --probe-session-open-open-session-id 103 --probe-session-open-preconnect-session-id 103

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-media-preconnect-init --probe-session-open-open-session-id 104 --probe-session-open-preconnect-session-id 104

fresh session 已经找到了：103 和 104 现在都还能稳定回到 0。接下来用 103 做 open 目标，跑两组真正有判别力的跨进程 A/B：`103 -> 103` 和 `104 -> 103`。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-open-session-id 103 --probe-session-open-preconnect-session-id 103 --probe-session-open-preconnect-before-metadata --probe-session-open-disconnect-before-open --probe-session-open-exit-before-open

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-media-preconnect-init --probe-session-open-open-session-id 103 --probe-session-open-preconnect-session-id 103

同 session 的跨进程 A/B 已经有判别力了：进程 A 在 103 上打完 metadata 并断开退出后，进程 B 在 103 上 fresh preconnect/open 重新回到了 0。这基本已经指向“metadata 语境不跨进程”。我再补一条更强的 `104 -> 103` 对照，把这个结论钉死。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-open-session-id 103 --probe-session-open-preconnect-session-id 103 --probe-session-open-metadata-session-id 104 --probe-session-open-preconnect-before-metadata --probe-session-open-disconnect-before-open --probe-session-open-exit-before-open

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-media-preconnect-init --probe-session-open-open-session-id 103 --probe-session-open-preconnect-session-id 103

跨进程这一刀已经有结论了，我先把“session101 漂移”和“fresh session103/104 的跨进程不继承 metadata 语境”写进日志与记忆，然后再去查 libagmclient 里有没有更强 reset 入口。

Generating patch (95 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Inserted into memory file twrp_audio_session_open_two_error_planes_20260324.md

跨进程已经把问题压到“同进程用户态语境”。下一步不再猜，我先直接查设备上的 `libagmclient.so` 暴露了哪些 reset/deinit 相关符号，看看有没有比 `agm_init` 更强的 teardown 入口可测。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell strings /vendor/lib64/libagmclient.so | grep -Ei 'agm_.*(deinit|reset|destroy|teardown|close|init)' | head -n 80

设备库里已经给出一个更强入口了：`libagmclient.so` 里确实有 `agm_deinit`。我直接把它接进 probe，跑“metadata 后 deinit+reinit 再 open”的 A/B，比继续猜更快。

Searched for regex `agm_deinit|load_agm_client|LOAD_AGMCLIENT_SYM` (`**/video_player/pure_c_agm_probe.c`), 4 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#390-390), lines 390 to 470

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c#120-120), lines 120 to 180

`agm_deinit` 已经确认存在。为了不把结果和“deinit 顺手清掉 live state”混在一起，我直接做更强版本：`metadata -> deinit -> init -> 重新补 aif media + reconnect -> open`。这样如果还能 -19，就说明不是简单的轻量库态残留。

Generating patch (122 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c)


```

```
`agm_deinit` 路径已经接进 probe。现在直接在 fresh session103 上跑 same-session 和 cross-session 两组 `deinit+init+reapply+reconnect`，看它能不能把 `-19` 真正拉回 0。

Checked [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/pure_c_agm_probe.c), 24 problems found

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && ./video_player/build_pure_c_agm_probe.sh

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb push ./video_player/pure_c_agm_probe /data/local/tmp/pure_c_agm_probe && adb shell chmod 755 /data/local/tmp/pure_c_agm_probe

二进制已推上去。现在直接在 fresh session103 上跑两组 `deinit+init+reapply+reconnect`，只看它能不能把 same-process metadata 语境从 -19 拉回 0。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-open-session-id 103 --probe-session-open-preconnect-session-id 103 --probe-session-open-preconnect-before-metadata --probe-session-open-deinit-reinit-before-open

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/pure_c_agm_probe --probe-session-open-aif-only-metadata-aif-media-preconnect-init --probe-session-open-open-session-id 103 --probe-session-open-preconnect-session-id 103 --probe-session-open-metadata-session-id 104 --probe-session-open-preconnect-before-metadata --probe-session-open-deinit-reinit-before-open

这条线已经打到一个很关键的可操作结论了：`agm_deinit+agm_init` 真的能在同进程里把 metadata 语境清掉。我先把它落盘，然后给出下一步最直接的利用方式。

Generating patch (76 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Inserted into memory file twrp_audio_session_open_two_error_planes_20260324.md

Completed: *加跨进程退出开关* (1/3)

这一轮已经把这条支线打到一个可直接利用的结论了。

新增硬结论

1. `session101` 旧基线又漂了，fresh `preconnect/open` 现在自己都会掉到 `-19`，所以我切到了新的 fresh `session103/104`。
2. `session103` 和 `session104` 目前都还能稳定得到 `open=0`。
3. metadata 语境不会跨 adb shell 进程延续。
4. 同进程里，单独再调一次 `agm_init` 清不掉这层语境。
5. 但 `agm_deinit + agm_init`，再补回 `aif_set_media_config + session_aif_connect`，可以把 `-19` 重新拉回 `0`。

我实际验证了什么

1. fresh `session103`:
   `aif-media-preconnect-init + open`
   结果回到 `rc=0`

2. 跨进程 same-session:
   进程 A 在 `session103` 上打 metadata，disconnect，`exit-before-open`
   进程 B 全新进程对 `session103` fresh `preconnect/open`
   结果重新是 `rc=0`

3. 跨进程 cross-session:
   进程 A 把 metadata 打到 `session104`，但 connect/disconnect 用 `session103`
   进程 B 全新进程对 `session103` fresh `preconnect/open`
   结果还是 `rc=0`

4. 同进程强 reset:
   在 fresh `session103` 上先打 metadata
   然后执行 `agm_deinit`
   再执行 `agm_init`
   再重新补 `aif_set_media_config` 和 `session_aif_connect`
   最后 `open`
   same-session 和 `104 -> 103` cross-session 两组都重新回到了 `rc=0`

这把当前模型收紧成：

1. 当前 `-19` 不是驱动侧的全局永久污染。
2. 它也不会跨进程带进下一次 fresh probe。
3. 它更像是 `libagmclient / AGM` 用户态栈内部的一层可重置语境。
4. 这层语境不会被单独一次 `agm_init` 清掉。
5. 但会被 `agm_deinit + agm_init + reapply media/connect` 清掉。

这次代码侧新增了几类调试能力

1. 显式 session id 参数
2. `exit-before-open`
3. `agm_deinit + agm_init` 的 reset 路径

文档和仓库记忆已经同步补上。

现在最直接的下一步，不是继续枚举 metadata，而是二选一：

1. 把这套 `deinit/init + reapply` 思路搬到真实播放路径前，验证它能不能让真实 playback 链从更干净的 AGM 用户态语境起步
2. 继续留在 probe 里，检查 `agm_deinit` 之后是否还有别的状态必须补回，比如 session config / buffer config / 额外 metadata

如果继续，我建议直接做第 1 条。现在已经不是“有没有 reset”的问题，而是“真实播放器能不能借这个 reset 避开被 metadata 污染过的 open 语义面”。

Made changes.

User: 继续

GitHub Copilot: 继续往真实播放路径靠：我先定位仓库里谁在走 AGM metadata/open 主线，优先找最小可改入口，把刚验证过的 `agm_deinit + agm_init + reapply` 思路接到真实播放前。

Added 1 todo

这一步只做代码定位，目标是找出最接近真实播放、又最容易插入 reset 的入口，避免把 probe 里的结论硬搬到错误层。

Searched for regex `agm_session_aif_set_metadata|agm_session_open|agm_deinit|agm_init|agm_session_aif_connect` (`**/*.{c,cpp,h,cc,mm}`), 67 results

Searched for files matching `**/agm_audio_minimal*.{c,h,cpp}`, 3 matches

真实播放侧入口已经定位到 `video_player/agm_audio_minimal*.c`。我先看这条链路里 AGM init/connect/open 的具体时序，确认最小接入点是在播放器里而不是 probe 里继续绕。

Searched for regex `agm_init|agm_deinit|agm_session_open|agm_session_aif_connect|agm_session_aif_set_metadata|agm_session_set_metadata|agm_aif_set_media_config|prime_agm_helper_prep` (`**/video_player/agm_audio_minimal*.{c,h}`), 1 result

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#1-1), lines 1 to 420

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal_main.c)

这个播放器链路里没有直接走 `libagmclient`，目前看更像是 tinyalsa + agmmixer helper 路径，不是我们刚刚压实的 `agm_session_open` 分支本体。我先把播放器内部的实际 bring-up 时序读完，确认是不是要改另一个更接近 session-open 的真实入口。

Searched for regex `agm_audio_player_play_tone|agm_audio_player_play_wav_file|agm_audio_player_create|prepare_and_start|prime_agm_helper_prep|connect_agm_audio_intf_to_stream|set_agm_stream_metadata|set_agm_streamdevice_metadata` (`**/video_player/agm_audio_minimal.c`), 16 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c#820-820), lines 820 to 1320

这个最小播放器本身走的是 agmmixer helper + pcm_open，不是 `libagmclient session_open` 那条线，所以它不能直接吃刚验证的 `agm_deinit` 结论。下一步我改去找真正会触发 `session_open / session_aif_set_metadata` 的播放入口，否则再往这边改只会偏题。

Searched for regex `pure_c_agm_probe|agm_audio_minimal|session_open|session_aif_set_metadata|libagmclient|agm_deinit` (`**/video_player/**/*.{c,cpp,h,cc}`), 200 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player)

真正要接近业务路径的候选现在只剩 `video_player_ffi.c` / `libvideo_player.so`。我先确认这层到底是走 `agm_audio_minimal` 还是另有 session-open 分支，再决定是把 reset 接到 FFI 入口还是继续只留在 probe。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/video_player_ffi.c#1-1), lines 1 to 420

Searched for regex `agm_audio_player_|agm_audio_minimal|pure_c_agm_probe|session_open|agm_deinit|pcm_open` (`**/video_player/video_player_ffi.c`), 12 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/video_player_ffi.h)

目前可以确认一件重要事实：`video_player_ffi -> libagm_audio_minimal` 这条真实播放链路并不直接走 `libagmclient session_open`，所以不能直接套用刚刚那套 reset。为避免继续在错误入口上做无效改动，我先全仓库确认一下除了 probe 之外，还有没有任何真实代码真的调用 `agm_session_open`。

Searched for regex `agm_session_open|agm_session_aif_set_metadata|agm_deinit` (`**/*.{c,cpp,h,cc}`), 31 results

Searched for regex `set_agm_stream_metadata|set_agm_streamdevice_metadata|connect_agm_audio_intf_to_stream` (`**/*.{c,cpp,h,cc}`), 21 results

全仓库确认过了：除了 `pure_c_agm_probe`，没有任何真实代码在直接调用 `agm_session_open / session_aif_set_metadata / agm_deinit`。也就是说，当前这套 reset 结论还不能直接落到真实播放器代码里。下一步我转去查真实播放链依赖的 `libagmmixer` 有没有同类 reset/teardown 入口。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell strings /vendor/lib64/libagmmixer.so | grep -Ei '(agm|mixer).*(deinit|reset|destroy|teardown|close|init)' | head -n 120

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell strings /vendor/lib64/libagm_mixer_plugin.so | grep -Ei '(agm|mixer).*(deinit|reset|destroy|teardown|close|init)' | head -n 120

设备上的 `strings` 没扫出可用 reset 符号，至少没有像 `agm_deinit` 这样显眼的入口。我换成本机侧读 ELF 符号表，先把真实播放链涉及的两个库拉下来再查导出符号，这样结论会更可靠。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && mkdir -p ./audio_manual/runtime_libs && adb pull /vendor/lib64/libagmmixer.so ./audio_manual/runtime_libs/libagmmixer.so && adb pull /vendor/lib64/libagm_mixer_plugin.so ./audio_manual/runtime_libs/libagm_mixer_plugin.so

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && command -v llvm-nm || command -v nm

库已经拉到本地，可以直接看导出符号。目标很简单：确认真实播放链有没有等价于 `agm_deinit` 的强 reset 入口，如果没有，就该停止尝试把这条结论硬塞进 `agm_audio_minimal`。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && /Users/Laurie/.swiftly/bin/llvm-nm -D ./audio_manual/runtime_libs/libagmmixer.so | grep -Ei '(init|deinit|reset|destroy|teardown|close)'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && /Users/Laurie/.swiftly/bin/llvm-nm -D ./audio_manual/runtime_libs/libagm_mixer_plugin.so | grep -Ei '(init|deinit|reset|destroy|teardown|close)'

导出符号层面已经很明确了：真实播放链依赖的 `libagmmixer.so` / `libagm_mixer_plugin.so` 没有暴露任何像 `agm_deinit` 这种可用的 reset/teardown API。为了避免误判，我再抓一遍这两个库的主要导出名，确认它们确实只是 metadata/connect 辅助层。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && /Users/Laurie/.swiftly/bin/llvm-nm -D --defined-only ./audio_manual/runtime_libs/libagmmixer.so | head -n 120

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && /Users/Laurie/.swiftly/bin/llvm-nm -D --defined-only ./audio_manual/runtime_libs/libagm_mixer_plugin.so | head -n 120

这条主线已经产生一个很关键的边界条件，我先把它落盘：当前 `agm_deinit` 结论只对 probe 的 `libagmclient session_open` 分支成立，不能直接迁到 `agm_audio_minimal` / `video_player_ffi`。真实播放链走的是 `libagmmixer` helper，而且库导出里没有对应 reset API。

Generating patch (50 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Inserted into memory file twrp_audio_session_open_two_error_planes_20260324.md

这一轮我把分支边界钉死了。后面如果继续，有两条真正不冲突的主线可选：一条继续做 `libagmclient session_open` 语义；另一条单独为真实播放链建立 `libagmmixer helper` 的状态模型。这次没有继续盲改真实播放代码，因为我先把一个关键边界确认清楚了。

新增结论

1. `agm_deinit + agm_init` 这条强 reset 结论，目前只对 `pure_c_agm_probe` 里直接操纵 `libagmclient` 的 `session_open` 分支成立。
2. 当前真实播放链 `video_player_ffi -> libagm_audio_minimal` 并不走这条 API。
3. 它实际走的是 `libagmmixer` helper 路径：
   `set_agm_stream_metadata`
   `set_agm_streamdevice_metadata`
   `connect_agm_audio_intf_to_stream`
   再到 `pcm_open`
4. 我把设备上的 `libagmmixer.so` 和 `libagm_mixer_plugin.so` 拉回本机查了导出符号，没看到可直接用的 `deinit/reset/teardown` 入口。
5. 所以现在不能把 probe 里验证过的 `agm_deinit` reset 方案，直接原样塞进真实播放器。

这一步的重要性

1. 它把两条主线彻底分开了，避免后面再把 `session_open` 语义问题和真实 `agm_audio_minimal` 播放问题混写成一个结论。
2. 现在可以明确：
   `libagmclient session_open` 分支已经证明了 metadata 语境可被 `agm_deinit + agm_init` 清掉
3. 但真实播放分支目前没有找到等价公开 reset API，需要独立建模

我已经把这条边界补进日志和仓库记忆。

如果继续，真正合理的后续只有两条：

1. 继续沿 `libagmclient session_open` 分支深挖，把现有 reset 结论整理成更稳定的实验基线
2. 切到真实播放链，单独分析 `agm_audio_minimal` 的 `libagmmixer helper` 路径，找它自己的状态污染点和可重建窗口

我建议现在转到第 2 条。因为 `session_open` 这条线已经压得足够深，再继续堆实验的边际收益会明显下降，而真实播放链目前还是独立黑盒。

Made changes.

User: 继续

GitHub Copilot: 继续转向真实播放链本身：我不再碰 `libagmclient`，而是先给 `agm_audio_minimal_bin` 加一个最小“同进程重复 open/close”实验入口，直接判断 `libagmmixer helper` 路径有没有自己的进程内状态污染。

Searched for regex `agm_audio_player_open\(|agm_audio_player_close\(|agm_audio_player_play_tone\(|agm_audio_player_play_wav_file\(` (`**/video_player/agm_audio_minimal*.{c,h}`), 29 results

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.h)

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/build_agm_audio_minimal.sh)

现在开始改真实播放侧的小实验入口：只在 agm_audio_minimal_main.c 里加 `--open-close-cycles N`，不改库行为。这样能直接测出 `libagmmixer helper` 路径在同一进程里多次 open/close 会不会自己漂移。

Generating patch (77 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal_main.c)


```

```
CLI 实验入口已经加好了。接下来我会重编译 `agm_audio_minimal_bin`，然后在设备上直接跑 `open-close-cycles=2/3`，看 helper 路径是否在同进程内从 `open=0` 漂到失败面。

Checked [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal.c), [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal_main.c), 21 problems found

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && ./video_player/build_agm_audio_minimal.sh
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP' && ./video_player/build_agm_audio_minimal.sh

构建脚本只是没执行位，不是代码问题。我改用 `bash` 直接跑脚本，编过后就上机做 2/3 次 open-close 循环。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && bash ./video_player/build_agm_audio_minimal.sh

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb push ./video_player/agm_audio_minimal_bin /data/local/tmp/agm_audio_minimal_bin && adb shell chmod 755 /data/local/tmp/agm_audio_minimal_bin

二进制已经上机。现在直接跑同进程 `open-close-cycles=2` 和 `3`，如果 helper 路径也有状态污染，会在第二次或第三次 open 直接暴露出来。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/agm_audio_minimal_bin --open-close-cycles 2

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/agm_audio_minimal_bin --open-close-cycles 3

结果太长，我直接读关键输出文件，提取每一轮 `open-close cycle` 和失败点，马上就能判断 helper 路径是否也有同进程漂移。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_6bShIRg6wUOEgClzaV7Sq1Nh__vscode-1774321085941/content.txt)

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_fICZqBAEgERhv1cwalGOQHy2__vscode-1774321085942/content.txt)

新结果已经出来：`libagmmixer helper` 路径在同一进程里连续 `open/close` 2 次、3 次都稳定成功，没有出现像 `libagmclient session_open` 那样的立刻漂移。下一步我把实验再推进半步，补一个同进程 `play` 循环，确认“真正写音频数据”会不会才是污染触发点。

Generating patch (75 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/video_player/agm_audio_minimal_main.c)


```

```
播放循环入口已经补上。接下来重编译并直接跑同进程 `play-cycles=2` 的短音测试，验证 helper 路径在真实写流后是否仍然保持稳定。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && bash ./video_player/build_agm_audio_minimal.sh

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb push ./video_player/agm_audio_minimal_bin /data/local/tmp/agm_audio_minimal_bin && adb shell chmod 755 /data/local/tmp/agm_audio_minimal_bin

二进制已更新。现在跑同进程两轮 1 秒纯音；如果第二轮仍然完整走通，就可以基本排除 `agm_audio_minimal` helper 路径的进程内累积污染。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && adb shell /data/local/tmp/agm_audio_minimal_bin --play-cycles 2 --play-seconds 1

输出较长，我直接抓关键日志，重点看两轮 `play cycle`、`pcm_prepare/start` 和任何 `player_open/write` 失败点。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/4158d4c3-fa87-420b-8563-937ce0cad799/call_0GzGLfaQHaxzH85mt1L5ZIHS__vscode-1774321085948/content.txt)

Compacted conversation两轮真实播放都成功了，说明 helper 播放链路目前没有复现 probe 那种同进程漂移。我接着把这个结论落到实验文档和仓库记忆里，只追加到末尾。Optimizing tool selection...

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#1-1), lines 1 to 260

Read memory twrp_audio_session_open_two_error_planes_20260324.md

我先确认文档真实末尾和当前最大节号，避免把补充插到中间。然后只在末尾追加一节，把“probe 分支”和“helper 播放分支”边界写死。

Ran terminal command:  rg -n '^### ' docs/TWRP音频手动Bring-up-续.md | tail -n 20

Ran terminal command:  wc -l docs/TWRP音频手动Bring-up-续.md

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#6430-6430), lines 6430 to 6492

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md#6493-6493), lines 6493 to 6493

我现在追加两处最小变更：
1. 文档末尾新增 15.10，记录 helper 路径的 `open/close` 与短时真实播放循环结果。
2. 仓库记忆补一条边界结论，避免后面又把 probe 的污染模型套错到真实播放器链。

Generating patch (57 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```
文档已追加。我再做一个小修正，把刚才追加段落里的一个日志名拼写改正，然后同步更新仓库记忆。

Generating patch (6 lines) in [](file:///Volumes/Case-sensitive%20APFS/TWRP/docs/TWRP%E9%9F%B3%E9%A2%91%E6%89%8B%E5%8A%A8Bring-up-%E7%BB%AD.md)


```

```


Updated memory file twrp_audio_session_open_two_error_planes_20260324.md

结论先收口：

1. 真实 helper 播放链这边，当前没有复现 probe 那种“同进程越跑越脏”的现象。
2. 两轮 `play-cycles 2 --play-seconds 1` 都成功，关键日志稳定：
   - `pcm_prepare rc=0`
   - `pcm_start rc=0`
   - `play_tone done`
   - `play cycle 1/2 rc=0`
   - `play cycle 2/2 rc=0`
3. 结合前面已经跑过的 `open-close-cycles 2` 和 `3` 全成功，可以先把“helper 播放器自身短周期复用污染”从主嫌疑里降级。

我已经做了两件落地动作：

1. 在续记文档末尾追加了 `15.10`，把这次 helper 分支的连续 `open/close` 和连续短播放结果写进去了。
2. 更新了仓库记忆，明确标注：
   - probe 的 `libagmclient` metadata 语境污染模型仍成立；
   - 但真实 `agmmixer helper` 播放分支目前没观察到对应的同进程漂移，不能混成一个结论。

这一步的实际意义是：

1. “只能听到约 1 秒” 现在不宜再优先归因到 helper 路径里连续调用后的状态污染。
2. 主线应继续回到“持续出声链本身”去查，而不是继续怀疑 helper 的短周期 `open/play` 复用。

下一步如果继续，我建议直接做这两项里的一个：

1. 播放 10 秒期间连续采样关键 mixer / 路由状态，盯住约 1 秒附近是否有后端状态回切。
2. 对比 `agm_audio_minimal` 与 `agmplay` 在播放中途的实时路由快照，找持续可闻输出缺口。

Made changes.

User: 继续

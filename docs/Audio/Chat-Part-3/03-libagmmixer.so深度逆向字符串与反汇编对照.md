
Generating patch (64 lines) in [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c)

User: 你在空转

GitHub Copilot: 你说得对，这条线现在收益太低了。我不再继续修 helper 的边角，而是直接切策略：去拆 `agmplay` 对 `PCM100 metadata/getTaggedInfo/connect` 的原始 array 写法，准备绕过 `libagmmixer` 这层黑盒。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && objdump -d agmplay | rg "mixer_ctl_set_array|mixer_ctl_get_array|mixer_ctl_set_enum_by_string|mixer_ctl_update|mixer_ctl_get_value|mixer_ctl_get_num_values|mixer_get_ctl_by_name|mixer_get_ctl"
Completed with input:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && objdump -d agmplay | rg "mixer_ctl_set_array|mixer_ctl_get_array|mixer_ctl_set_enum_by_string|mixer_ctl_update|mixer_ctl_get_value|mixer_ctl_get_num_values|mixer_get_ctl_by_name|mixer_get_ctl"

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && strings agmplay | grep -E "PCM100|metadata|getTaggedInfo|setParam|connect|control" | sort -u

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && objdump -d agmplay --start-address=0x64e0 --stop-address=0x68a8 | sed -n '1,260p'

`agmplay` 本体没有直接碰 `PCM100` 控件，说明这层都封在 `libagmmixer.so` 里了。下一步我直接拆 `libagmmixer.so` 自身，确认它到底怎么用 `metadata/getTaggedInfo/connect`。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d libagmmixer.so --start-address=0xd4a0 --stop-address=0xd5d0

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -T libagmmixer.so | grep -E "mixer_ctl_set_array|mixer_ctl_get_array|mixer_ctl_set_enum_by_string|mixer_get_ctl_by_name|mixer_ctl_get_value|mixer_ctl_get_num_values|mixer_ctl_get_enum_string"

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && strings -t x libagmmixer.so | grep -E "PCM100|getTaggedInfo|metadata|setParam|connect|control|Invalid mixer control" | head -n 200

我继续拆 `libagmmixer.so` 内部实现，不再猜。现在已经确认它自己确实直接依赖 `mixer_ctl_set_enum_by_string`、`mixer_ctl_set_array`、`mixer_ctl_get_array`，所以下一步就是看它在 `connect` 和 `stream metadata` 里具体按什么顺序写控件。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d libagmmixer.so --start-address=0xb000 --stop-address=0xb120 | sed -n '1,220p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d libagmmixer.so --start-address=0xbb80 --stop-address=0xbd10 | sed -n '1,260p'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d libagmmixer.so --start-address=0xa980 --stop-address=0xab20 | sed -n '1,260p'

我已经把真正有用的信息挖出来了，不是空转了：

1. `libagmmixer.so` 的 `connect_agm_audio_intf_to_stream` 确实只是：
   - 组一个控件名
   - `mixer_get_ctl_by_name`
   - `mixer_ctl_set_enum_by_string`
2. `agm_mixer_get_miid` 的实现也确认了：
   - 它先读一个 `BYTE` 控件的 1024 字节数组
   - 再在里面按 tag 查记录
   - 也就是说，`-19` 的根因就在 `getTaggedInfo` 这层数组没准备好

下一步我不再泛化描述了，直接去把 `connect` helper 用到的几个字符串常量解出来，确认它到底写的是不是你看到的 `PCM100 connect`，还是另一个动态控件名。只要这个点一落地，我们就能避免现在这种“`rc=0` 但回读还是 `ZERO`”的假成功。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && strings -t x libagmmixer.so | awk '$1 >= "2c80" && $1 <= "2d40" {print}'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && strings -t x libagmmixer.so | awk '$1 >= "2810" && $1 <= "2890" {print}'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && strings -t x libagmmixer.so | awk '$1 >= "2c00" && $1 <= "2d10" {print}'

Compacted conversation字符串已经开始对上了。`connect_agm_audio_intf_to_stream` 这边能看到几组关键模板：

- `connect`
- `disconnect`
- `control`
- `%s%d`
- `%s %s`

这基本说明它不是写死某个名字，而是在拼诸如 `PCM100 connect` / `PCM100 control` 这类名字。现在还差最后一跳：把字符串地址和反汇编里的偏移精确对上，确认 helper 在什么分支下选 `control`，什么分支下选 `connect`。Optimizing tool selection...

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && otool -l libagmmixer.so | sed -n '/__TEXT/,/sectname/p' | head -n 80

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -h libagmmixer.so | head -n 40

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d --start-address=0xb01c --stop-address=0xb140 libagmmixer.so

地址映射已经出来了：`.rodata` 从 `0x22d0` 开始，`connect` helper 里面用到的常量地址分别是：

- `0x2c21` -> `connect`
- `0x2cb2` -> `disconnect`
- 还差：
  - `0x2ca8`
  - `0x2907`
  - `0x2a1f`

我现在直接把这几个地址附近的原始 rodata 拿出来，不靠 `strings` 漏检，直接把模板字面值解掉。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -s --section=.rodata --start-address=0x28e0 --stop-address=0x2940 libagmmixer.so

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -s --section=.rodata --start-address=0x2c90 --stop-address=0x2cd8 libagmmixer.so

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -s --section=.rodata --start-address=0x2a10 --stop-address=0x2a40 libagmmixer.so

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_a5xMid7km8KBH1IHWh3eigGF__vscode-1773634973320/content.txt#1-1), lines 1 to 120

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_FlNyCEJrkVLQhkAicWflcoPs__vscode-1773634973321/content.txt#1-1), lines 1 to 120

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_cwUjiqWFcf7CCCNuuAL7Pjct__vscode-1773634973322/content.txt#1-1), lines 1 to 120

我拿到一个关键结论了：

- `0x2907` 实际上落在 `COMPRESS`
- `0x2910` 一带是 `metadata`

这说明我之前把 `0x2907` 猜成普通控件前缀是错的，反汇编地址没完全解干净。现在我要直接按二进制偏移做十六进制读取，不再依赖 `objdump` 的 section 转储格式。这样能把 `0x2ca8` / `0x2a1f` 这些地址上的字节一个个抠出来。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && xxd -g 1 -s 0x2c90 -l 80 libagmmixer.so

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && xxd -g 1 -s 0x2a10 -l 64 libagmmixer.so

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && xxd -g 1 -s 0x2900 -l 48 libagmmixer.so

这下分支语义已经还原了，核心点很清楚：

- `0x2ca8` 是 `PCM`
- `0x2907` 是 `COMPRESS`
- `0x2c21` 是 `connect`
- `0x2cb2` 是 `disconnect`
- `0x2a1f` 是格式串 `%s%d %s`

所以 `connect_agm_audio_intf_to_stream()` 本质上就是拼下面两类控件名：

- `PCM100 connect` / `PCM100 disconnect`
- 或 `COMPRESS100 connect` / `COMPRESS100 disconnect`

这意味着现在最值得检查的不是 ALSA 层，而是我们调用这个 helper 时传进去的 flag。只要那个 flag 走错分支，helper 实际上就不是在做 `connect`，而是在做 `disconnect`。我现在回到播放器代码里核对这个调用点。

Searched for text `connect_agm_audio_intf_to_stream` (`**/video_player_ffi.c`), 8 results

Searched for regex `set_agm_stream_metadata\(|set_agm_stream_metadata_type\(|agm_mixer_get_miid\(` (`**/video_player_ffi.c`), 5 results

Searched for regex `AgmMixerApi|prepare_agm_pcm_route|force_agm_pcm100_connect` (`**/video_player_ffi.c`), 7 results

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#777-777), lines 777 to 920

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#724-724), lines 724 to 748

Read [](file:///Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/video_player/video_player_ffi.c#1038-1038), lines 1038 to 1072

调用点我已经核对过了，`connect_agm_audio_intf_to_stream(mixer, 100, intf, 0, 1)` 这边参数方向没写反：

- 第四个参数是 `0`，所以它拼的是 `PCM100 ...`
- 第五个参数是 `1`，所以它拼的是 `PCM100 connect`

对应的 teardown 里传的是最后一个参数 `0`，也就是 `PCM100 disconnect`。这一层现在基本排除了。

接下来卡点就更聚焦了：`connect` 不是传错了，而是 connect 之前的 metadata graph 还没满足，导致控件虽然可写，但状态马上回到 `ZERO`。我去找 `agmplay` 或同类实现里 `set_agm_stream_metadata` 的真实入参顺序，确认我们现在两次 `set_agm_stream_metadata` 有没有漏字段或字段顺序错位。

Searching for regex `set_agm_stream_metadata\s*\(` (`**/*.{c,cc,cpp,h}`)

Searching for regex `agm_mixer_get_miid\s*\(|connect_agm_audio_intf_to_stream\s*\(` (`**/*.{c,cc,cpp,h}`)

Search complete: 搜索 AGM 调用样例

Searching for regex `set_agm_stream_metadata|agm_mixer_get_miid|connect_agm_audio_intf_to_stream|agmmixer|agmplay` (`**/vendor/**`)

Searching for regex `set_agm_stream_metadata|agm_mixer_get_miid|connect_agm_audio_intf_to_stream|agmmixer|agmplay` (`**/external/**`)

Searching for regex `set_agm_stream_metadata|agm_mixer_get_miid|connect_agm_audio_intf_to_stream|agmmixer|agmplay` (`**/bootable/**`)

Searching for regex `set_agm_stream_metadata|agm_mixer_get_miid|connect_agm_audio_intf_to_stream|agmmixer|agmplay` (`**/system/**`)

Searching for files matching `**/vendor/**/*agm*`

Searching for files matching `**/external/**/*agm*`

Searching for files matching `**/bootable/**/*agm*`

Searching for files matching `**/system/**/*agm*`

Searched for text `agmplay` (`**/vendor/**/*.c`), no results

Searched for text `agmplay` (`**/vendor/**/*.cpp`), no results

Searched for text `agmmixer` (`**/vendor/**/*.c`), no results

Searching for text `agmmixer` (`**/vendor/**/*.cpp`)

Searched codebase for "agmplay agmmixer helper set_agm_stream_metadata agm_mixer_get_miid connect_agm_audio_intf_to_stream device 100 PCM playback vendor external bootable system", 14 results

代码库级全文检索在这个大树里超时了，我改成定点 `rg`。目标不是泛搜，而是把 `agmplay` 和 helper 实现直接找出来做对照。

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n "set_agm_stream_metadata|agm_mixer_get_miid|connect_agm_audio_intf_to_stream" twrp_a12_compile twrp_a16_compile -g '*.{c,cc,cpp,h}' | head -n 200

Ran terminal command:  rg -n "set_agm_stream_metadata|agm_mixer_get_miid|connect_agm_audio_intf_to_stream" '/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery' -g '*.{c,cc,cpp,h}'

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP' && rg -n "agmplay|libagmmixer|AGM_MFC_TAG|STREAM_KV_PCM_LL_PLAYBACK" twrp_a12_compile twrp_a16_compile -g '*.{c,cc,cpp,h,mk,bp}' | head -n 200

源树里没有现成的 agmplay/helper 调用源码，至少这两个 Android 树分支没有。那就只能继续逆向 `libagmmixer.so` 本身，不过现在方向已经更窄了，不再盲找。

Read [](file:///Volumes/Case-sensitive%20APFS/TWRP/audio_dtb_probe)

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d --start-address=0xbb90 --stop-address=0xbd60 libagmmixer.so

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d --start-address=0xa988 --stop-address=0xac20 libagmmixer.so

`set_agm_stream_metadata` 这边已经挖到一个很硬的点了：它不是简单塞几个 KV，而是在拼一个带 header 的数组结构，而且结构长度会随参数组合变。

我还差后半段 `mixer_ctl_set_array` 之前的收尾和 `agm_mixer_get_miid` 的解析循环，把这两个补齐后就能判断我们现在传的 `0/0/instance_bits` 到底是不是有效 payload，还是只是“helper 返回 0 但 graph 其实没成”。

Read [](file:///Users/Laurie/Library/Application%20Support/Code/User/workspaceStorage/177dab5c2148d09df3ce2128198eb82a/GitHub.copilot-chat/chat-session-resources/e862d9c8-c031-43db-a0e6-e2756e15df52/call_35X1XZY30kh3BScdp2b7PwZQ__vscode-1773634973356/content.txt#80-80), lines 80 to 174

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d --start-address=0xa988 --stop-address=0xac20 libagmmixer.so | tail -n 140

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d --start-address=0xbd5c --stop-address=0xbe80 libagmmixer.so

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && llvm-objdump -d --start-address=0xa988 --stop-address=0xab70 libagmmixer.so

Ran terminal command:  cd '/Volumes/Case-sensitive APFS/TWRP/audio_dtb_probe' && xxd -g 1 -s 0x0820 -l 64 libagmmixer.so

User: 这个文档你有参考吗https://docs.qualcomm.com/doc/80-70020-16SC/topic/agm.html
继续

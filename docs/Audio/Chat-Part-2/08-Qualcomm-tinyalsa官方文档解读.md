User: https://docs.qualcomm.com/doc/80-70020-16SC/topic/tinyalsa.html

理解这个文档

GitHub Copilot: 我先把这份 Qualcomm tinyalsa 文档抓出来，重点看它对 `tinymix`、`tinyplay`、AGM/metadata 相关接口的定义和边界，这样能直接判断哪些结论能用于你现在这条 recovery 音频链。



Fetched https://docs.qualcomm.com/doc/80-70020-16SC/topic/tinyalsa.html

Compacted conversation这份文档的核心意思，可以压成一句话：

在 Qualcomm 平台上，tinyalsa 不只是一个普通的 PCM 读写库，它还能通过 plugin 把“音频图搭建、metadata 下发、模块参数配置、前后端连接”也一起做掉。

这点对你现在这条链非常关键，因为它直接解释了为什么“裸 `pcm_open/pcm_write`”和“`agmplay` 能出声”之间会有本质差异。

**文档在讲什么**

它分三层讲：

1. 基础 API 层  
   这部分是标准 tinyalsa 用法：
   - `pcm_open`
   - `pcm_is_ready`
   - `pcm_prepare`
   - `pcm_start`
   - `pcm_write` / `pcm_read`
   - `pcm_stop`
   - `pcm_close`

这层只说明“怎么打开一个 PCM 设备并写音频数据”。

2. plugin 架构层  
   文档明确说 Qualcomm 的 tinyalsa 有：
   - PCM plugin
   - mixer plugin
   - compress plugin

这些 plugin 会创建“虚拟声卡”和“虚拟 mixer controls”，并把调用路由到实际的共享库实现上。  
也就是说，应用层看到的卡、设备、控件，不一定是内核原生 ALSA 节点的直接映射，可能是厂商 plugin 暴露出来的一套抽象入口。

3. 音频图配置层  
   这是最重要的部分。文档写得很直白：

   要启用一个 tinyalsa 音频用例，不能只做 `pcm_open`，还要先通过 mixer controls 去配置：
   - backend 设备配置
   - metadata
   - stream metadata
   - stream-device / DevicePP metadata
   - 模块参数
   - FE/BE connect

然后才是：
   - `pcm_open`
   - `pcm_prepare`
   - `pcm_start`
   - `pcm_write`

也就是：

$$
\text{Qualcomm tinyalsa usecase} \neq \text{只开 PCM}
$$

而是：

$$
\text{mixer graph setup} + \text{metadata} + \text{connect} + \text{PCM write}
$$

**文档里最关键的信号**

文档专门提到这些虚拟 mixer 控件是由 mixer plugin 创建的，很多是字节数组控件，要用 `mixer_ctl_set_array` 配。  
并且明确举了 `PCM100 metadata`、`PCM100 control`、`PCM100 connect`、`PCM100 getTaggedInfo` 这类控制。

这实际上就在说：

- `PCM100` 不是普通 ALSA mixer 开关
- 它背后是 AGM / graph / metadata 这一套编排接口
- `agmplay` 之类工具，本质上就是在帮你做这些步骤

文档给出的典型顺序是：

1. 配 backend 媒体参数  
2. 配 metadata  
3. 设 stream 侧 metadata  
4. 设 stream-device / DevicePP metadata  
5. 获取 tagged info / 模块信息  
6. 下发模块参数  
7. connect 前端流和后端接口  
8. 再 `pcm_open`
9. `pcm_prepare`
10. `pcm_start`
11. `pcm_write`
12. `pcm_stop`
13. `pcm_close`

这和你前面反汇编 `agmplay` 看到的骨架是对得上的，不是巧合。

**对你当前问题的直接含义**

这份文档给出的结论，基本把你现在的判断坐实了：

1. `tinyplay_stock` 这类“普通 PCM 播放”之所以失败，不一定是采样率、位宽、声道数错了。  
   更可能是它根本没有完成 Qualcomm 平台要求的 graph / metadata / connect 流程。

2. `agmplay` 之所以有价值，不是因为它是另一个播放器，而是因为它走的是 Qualcomm 文档认可的完整路径。  
   它不是单纯 `pcm_write` 成功，而是先把 usecase 搭起来了。

3. 你播放器里现在那种“直接 `agm_pcm_plugin_open` 然后 `hw_params/sw_params/write`”的模型，很可能还是少了前置编排。  
   文档已经说明，前置 mixer/plugin 配置是正路，不是可选项。

4. 文档也解释了为什么 Qualcomm 会把很多配置放进 mixer controls，而不是公开成普通 ALSA 参数。  
   因为它们在管理的是 graph、subgraph、module、metadata，不只是 PCM endpoint。

**你可以怎么理解这份文档**

最实用的理解方式是把它分成两句话：

- tinyalsa API 负责“搬运 PCM 数据”
- tinyalsa plugin + mixer controls 负责“把 Qualcomm 音频图搭起来”

如果只做前者，不做后者，很多平台上会出现：
- `pcm_open` 成功
- 甚至 codec/PA 部分有动作
- 但整条播放链并没有真正被 graph 层正确拉起

这和你现在看到的现象高度一致。

**跟你当前路线最相关的结论**

这篇文档本身已经足够支持你当前的方向切换：

- 不应该再把重点放在“继续试裸 PCM 参数组合”
- 应该把重点放在“复刻 Qualcomm 文档里的 usecase 配置顺序”
- 也就是：先 plugin/mixer metadata/connect，再 PCM 打流

如果你要，我下一步可以继续做两件事里的一个：

1. 把这篇文档的流程映射成你播放器里需要补的最小调用序列  
2. 直接继续改你那边的 video_player_ffi.c，把 `agmplay` 等价骨架接进去


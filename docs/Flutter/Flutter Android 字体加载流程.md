# Flutter 在 Android 上加载字体的流程

这份目录用于给 Android recovery 环境提供一套最小可用的系统字体资源，让 Flutter 在没有完整 Android framework 字体栈的情况下仍然能正常显示英文、数字、调试文字和中文。

当前目录包含：

- Roboto 系列字体，作为默认 sans-serif。
- DroidSansMono.ttf，作为 monospace。
- NotoSansCJKsc-Regular.ttf，作为中文 fallback。
- fonts.xml，作为 Android/Skia 字体配置入口。

## 总体流程

Flutter 在 Android 上显示文字时，核心流程不是 Flutter 自己直接解析字体文件，而是：

1. Flutter 把文本样式、字体族和 locale 传给 SkParagraph。
2. SkParagraph 通过 txt::FontCollection 向底层请求字体。
3. Android 平台默认字体管理器由 Skia 创建。
4. Skia 读取系统 fonts.xml，并根据其中的 family、lang、weight、style 信息建立字体族和 fallback 链。
5. 当首选字体不包含某个字符时，Skia 逐个 family 做 fallback，找到真正包含该字符 glyph 的字体。
6. 找到字体后，Skia/FreeType 从对应字体文件中取出 glyph，最后完成排版和绘制。

## 关键调用链

### 1. Flutter 创建 Android 默认字体管理器

Flutter 在 Android 上的默认字体管理器来自：

- engine/src/flutter/txt/src/txt/platform_android.cc

其中会调用：

- SkFontMgr_New_Android(nullptr, SkFontScanner_Make_FreeType())

这表示 Flutter 默认使用 Skia 的 Android 字体管理器，并让 FreeType 负责解析字体文件。

### 2. Flutter 把字体集合交给文本排版模块

文本排版时，Flutter 会把字体集合传给 SkParagraph：

- engine/src/flutter/txt/src/txt/font_collection.cc
- engine/src/flutter/txt/src/skia/paragraph_builder_skia.cc

这里会同时传入：

- default font manager：系统字体。
- asset font manager：应用自带字体。
- dynamic font manager：运行时动态加载字体。

如果应用字体缺字，系统字体就会参与 fallback。

### 3. locale 会被传给 Skia

Flutter 文本样式里的 locale 会继续往下传，例如：

- zh-CN
- zh-Hans
- en-US

Skia 会用这个 locale 作为字体 fallback 的语言提示，而不是 Flutter 自己在业务层显式写死“中文走哪个字体”。

## Skia 如何读取 fonts.xml

Android 字体配置解析逻辑在：

- engine/src/flutter/third_party/skia/src/ports/SkFontMgr_android_parser.cpp

Skia 会读取系统字体配置文件，例如：

- /system/etc/fonts.xml
- 老版本系统上可能还会读 /system/etc/system_fonts.xml

同时，字体文件基路径通常来自：

- $ANDROID_ROOT/fonts/

在 recovery 场景中，只要最终把本目录内容放到设备对应的系统位置，Skia 就能按 Android 默认逻辑读取它们。

## fonts.xml 中每个字段的作用

当前 fonts.xml 里最关键的是 family 配置。

示例：

```xml
<family name="sans-serif">
    <font weight="400" style="normal">Roboto-Regular.ttf</font>
</family>
```

含义：

- family name="sans-serif"：定义默认无衬线字体族。
- weight="400"：普通字重。
- style="normal"：正常样式。
- 字体文件名：最终要和设备上真实文件名完全一致。

中文 fallback 示例：

```xml
<family lang="zh-Hans">
    <font weight="400" style="normal">NotoSansCJKsc-Regular.ttf</font>
</family>
```

含义：

- lang="zh-Hans"：这组字体优先服务于简体中文场景。
- 当文本 locale 与简中匹配时，Skia 会优先考虑它。

通用 fallback 示例：

```xml
<family>
    <font weight="400" style="normal">NotoSansCJKsc-Regular.ttf</font>
</family>
```

含义：

- 不带 name，也不带 lang。
- 这是一条通用 fallback。
- 当文本没有设置 locale，或者语言匹配不明显时，它仍然可以兜底显示中文。

## 中文是如何被匹配到的

真正的中文匹配逻辑在：

- engine/src/flutter/third_party/skia/src/ports/SkFontMgr_android.cpp

Skia 会做这些事：

1. 先尝试请求的首选字体族，比如 sans-serif。
2. 如果首选字体没有对应字符，就继续查 fallback family。
3. 如果文本带有 locale，优先匹配带对应 lang 标签的 family。
4. 对每个候选字体，调用 unicharToGlyph(character) 检查它是否真的包含这个字符。
5. 找到第一个包含 glyph 的字体后停止。

所以，中文能否显示，最终取决于两件事：

1. fonts.xml 里有没有把中文字体纳入 fallback 链。
2. 对应字体文件里是否真的包含目标汉字。

## 为什么只放 Roboto 不够

Roboto 主要覆盖拉丁字符、数字和常见符号，不包含完整中文字符集。

因此：

- 只有 Roboto 时，英文和数字通常正常。
- 中文字符会因为找不到 glyph 而显示为空白、方框，或者直接不显示。

要让 Flutter 在 recovery 环境里默认显示中文，必须额外提供真正的 CJK 字体文件，例如：

- NotoSansCJKsc-Regular.ttf

## 当前目录的推荐最小方案

对 recovery 来说，最小可用方案通常是：

1. 保留 Roboto 作为默认 sans-serif。
1. 保留 DroidSansMono 作为 monospace。
1. 添加一个简体中文 fallback：

```xml
<family lang="zh-Hans">
    <font weight="400" style="normal">NotoSansCJKsc-Regular.ttf</font>
</family>
```

1. 再添加一个无 lang 的通用 fallback：

```xml
<family>
    <font weight="400" style="normal">NotoSansCJKsc-Regular.ttf</font>
</family>
```

这样可以覆盖两类场景：

- 文本明确带有简中 locale。
- 文本没有设置 locale，但仍然需要显示中文。

## 配置时最容易出错的点

### 1. 字体文件名不一致

fonts.xml 里的文件名必须和设备上的真实文件名完全一致，包括扩展名。

错误示例：

- NotoSansCJKsc-Regular

正确示例：

- NotoSansCJKsc-Regular.ttf

### 2. 只写 lang fallback，不写通用 fallback

如果只写：

```xml
<family lang="zh-Hans">
    <font weight="400" style="normal">NotoSansCJKsc-Regular.ttf</font>
</family>
```

那么在部分没有 locale 的文本场景下，中文 fallback 可能不够稳定。

### 3. 只有配置，没有字体文件

fonts.xml 只是索引，不能代替真实字体文件。

### 4. 设备路径不符合 Skia 预期

如果字体和 fonts.xml 没被放到最终系统可读取的位置，Flutter 默认流程也不会生效。

## 一句话总结

Flutter 在 Android 上显示字体的本质是：Flutter 负责把文本样式和 locale 交给 Skia，Skia 根据系统 fonts.xml 和字体文件做 family 匹配与 fallback，最后从真正包含 glyph 的字体里把字符画出来。

对 recovery 场景来说，想让 Flutter 默认显示中文，关键不是改 Flutter 文本代码，而是提供一份可被 Skia 正常读取的 fonts.xml，并确保其中的中文 fallback 指向真实存在的中文字体文件。

# Aurora Recovery Project (ARP)

一个全新的 Android Recovery，基于 Flutter 构建，我想把安卓的整个 Recovery 生态推向下一个里程碑

无论如何，我不会放弃我的每一个软件，曾经是，将来是，现在也是

## 为什么开发？

在我设备换了一加的手机和平板后，我再次接触了刷机，刷 Magisk，但因为用小米失去的这几年，我已经完全和这个生态脱节，第一步尝试了找设备的 TWRP，还是熟悉的界面，和十年前几乎一模一样，在我8年前刚接触 Flutter，我当时就想，如果这个 Recovery 能用 Flutter 开发就好了，当时也没想太多这件事的意义是什么，直到现在，我终于有了能力将这件事情实现。

## 解决什么问题？

- 开发效率提升：Flutter 的 hot reload 和 hot restart 大大缩短了开发周期，极大提升了开发效率，有开发效率，这个 Recovery 才能快速迭代，快速完善，快速适配更多设备
- Flutter 丰富的生态：Flutter 拥有丰富的第三方库和工具，可以轻松集成各种功能，例如网络请求、数据存储、动画效果等，这些都可以直接在 Recovery 中使用，而不需要重新开发
- 跨平台: 虽然是只运行在 Android Recovery 环境，但如果仅仅调试 UI，可以通过其他任意设备调试
- 十年前的 UI 风格也许不适应当下了

在尝试自己编译 TWRP 的过程中，发现整个过程其实比较复杂，TWRP 需要依赖整个 AOSP 的编译环境，占用磁盘非常大，第一次编译时间非常长

后续命中缓存编译时间会好一些，但对于 TWRP 的开发，我并不清楚是如何进行的，是不是只能盲写代码，然后 push recovery 这个二进制到设备上运行测试，还是需要完整 flash recovery 镜像，也许有一些现有的方法

例如 TWRP 的 UI 是基于 XML 编写的，可能可以实现直接预览，但无论如何，整个开发流程效率极低

于是我将 Flutter 带到了 Android Recovery 环境中，开发 Aurora Recovery，和开发普通 Flutter App 没有任何差异，借助 flutter 的 custom devices，保存后 hot reload，以及 hot restart，都和普通开发完全一样

## 实现方案

### 1.为 flutter-embedded-linux 开发一个新的 DRM-DUMB backend

基于 sony 的 [flutter-embedded-linux](https://github.com/sony/flutter-embedded-linux)，原始的代码，是强依赖 Linux 的 GPU 环境的，即使是 flutter-embedded-linux/examples/flutter-drm-gbm-backend 这个 backend，虽然是直接操作 drm 设备节点，但在 Android Recovery 模式下仍然不可用

而参考 TWRP 的代码，其中有两个渲染库，分别是 minui/minuitwrp，后者对现代的设备支持更好，有针对设置 plane 通道等操作，前者在一加15和一加 Pad2 Pro 上的 RGB demo 展示都不正确

所以 DRM-DUMB backend 的实现初步就是将 Flutter 每帧渲染的数据通单次 CPU 拷贝，再使用 minuitwrp 送显

### 2.自定义 Flutter Engine

Flutter Engine 也有大量的修改适配，来支持 Android Recovery 环境运行，并只需要一份 Engine 就能同时支持 CPU 和 GPU 两种渲染后端，去除 OpenGL ES 相关的依赖，增加 Vulkan Impeller 的支持

目前闭源，后续会提供类似 flutter-elinux 的工具，可以让大家也能开发这个 Recovery

默认编译出 Android 两个 so 的依赖如下：

```bash
$READELF -d libflutter.so 
  0x0000000000000001 (NEEDED)       Shared library: [libc.so]
  0x0000000000000001 (NEEDED)       Shared library: [libdl.so]
  0x0000000000000001 (NEEDED)       Shared library: [libm.so]
  0x0000000000000001 (NEEDED)       Shared library: [libandroid.so]
  0x0000000000000001 (NEEDED)       Shared library: [libEGL.so]
  0x0000000000000001 (NEEDED)       Shared library: [libGLESv2.so]
  0x0000000000000001 (NEEDED)       Shared library: [liblog.so]
  0x0000000000000001 (NEEDED)       Shared library: [libjnigraphics.so]
  0x000000000000000e (SONAME)       Library soname: [libflutter.so]
$READELF -d libflutter_engine.so 
  0x0000000000000001 (NEEDED)       Shared library: [libc.so]
  0x0000000000000001 (NEEDED)       Shared library: [libdl.so]
  0x0000000000000001 (NEEDED)       Shared library: [libm.so]
  0x0000000000000001 (NEEDED)       Shared library: [libandroid.so]
  0x0000000000000001 (NEEDED)       Shared library: [libEGL.so]
  0x0000000000000001 (NEEDED)       Shared library: [libGLESv2.so]
  0x0000000000000001 (NEEDED)       Shared library: [liblog.so]
  0x000000000000000e (SONAME)       Library soname: [libflutter_engine.so]
```

修改后的引擎依赖如下：

```bash
$READELF -d /Users/Laurie/Desktop/nightmare-space/AuroraRecoveryProject/arp_render/flutter-3.38.5/engine/src/out/android_debug_unopt_arm64_embedder_software/libflutter_engine.so  
Dynamic section at offset 0x20954a8 contains 28 entries:
  Tag                Type           Name/Value
  0x0000000000000001 (NEEDED)       Shared library: [libc.so]
  0x0000000000000001 (NEEDED)       Shared library: [libdl.so]
  0x0000000000000001 (NEEDED)       Shared library: [libm.so]
  0x0000000000000001 (NEEDED)       Shared library: [liblog.so]
  0x000000000000000e (SONAME)       Library soname: [libflutter_engine.so]
```

虽然不依赖 libEGL.so 和 libGLESv2.so 了，但配合自定义的 embedders，依然可以让 Flutter 使用 Vulkan Impeller 后端

经过不少的尝试

#### Vulkan：设备与显示分离

```bash
vkCreateInstance()        ← 不需要任何 display
  → vkEnumeratePhysicalDevices()
    → vkCreateDevice()    ← 只需内核驱动 (kgsl)
      → vkAllocateMemory() / vkCreateBuffer() / ...
```

Vulkan 设计上将 **核心 GPU 操作**（instance、device、memory、command buffer）与 **窗口系统集成**（WSI: surface、swapchain）完全分离。在 Android HAL 层，`hwvulkan_device_t` 直接提供 `GetInstanceProcAddr`，绕过了所有 Framework 服务。

#### OpenGL ES：EGL 是必经之路

```bash
eglGetDisplay()           ← 必须有 display（连接 SurfaceFlinger）
  → eglInitialize()       ← 枚举 GPU、加载配置（依赖 HWComposer）
    → eglCreateContext()  ← 所有 GL 调用必须在 context 内
      → glBindBuffer() / glDrawArrays() / ...
```

OpenGL/ES 的所有操作都必须在 **EGL context** 内执行，而 EGL context 需要 EGL display。Adreno 闭源 `libEGL_adreno.so` 的 `eglInitialize()` 内部通过 `libgui` 连接 SurfaceFlinger 枚举显示设备 — **这在 Recovery 中永远不可能成功**。

#### 对比总结

| | Vulkan | OpenGL ES |
| --- | -------- | ---------- |
| 需要 display 才能初始化？ | ❌ 不需要 | ✅ **必须** |
| Android HAL 直接入口？ | ✅ `hwvulkan_device_t` | ❌ 无对应 HAL |
| 依赖 SurfaceFlinger？ | ❌ | ✅ EGL 内部硬编码 |
| 离屏渲染是一等公民？ | ✅ | ❌ 需先有 context |
| Recovery 可用性 | ✅ **可用** | ❌ **不可用** |

#### 构建系统支持按条件裁剪 GL、Vulkan 和 Android SDK 依赖

**问题：**

Recovery 模式下的 engine 目标产物是 arm64 架构的 so，运行环境不提供完整的 GPU 图形栈，原始构建系统在 arm64 交叉编译时会强制链接 EGL、GLESv2 等库；这些库在 Recovery 运行时环境中不存在，so 加载时会因 undefined symbol 直接崩溃

**方案：**

将 Android 侧 BUILD.gn 改为条件编译，允许按构建开关裁剪 GL、Vulkan 以及部分 Android SDK 相关依赖

通过把 GL/Vulkan 设为可裁剪开关，消除了交叉编译阶段的强制 GPU 符号引用，也打通了 software-only engine 的独立编译与正确加载链路

#### Android 平台侧的 GL/Vulkan 路径增加编译期宏保护

**问题：**

仅修改 BUILD.gn 只能在链接层面移除依赖，无法保证源代码本身不再引用这些后端，当 GL/Vulkan 被完全裁掉时，未受保护的头文件引用、类型声明和 switch case 仍会导致编译失败


**方案：**

所以为 Android 平台代码中的 GL/Vulkan include、类型引用和分支逻辑补充编译期宏保护，增加宏保护后，纯 CPU software engine 不仅能在链接阶段裁掉 GPU 依赖，也能在源码层面完整编译通过

#### Embedder 补齐 Vulkan Impeller Surface 构造入口

**问题：**

Embedder 端虽然具备 Vulkan Impeller 的调用路径，但平台视图对象无法按预期完成构造，导致整条渲染链路无法打通，embedder.cc 中已经存在 Vulkan Impeller 的接线逻辑，但当前版本的 PlatformViewEmbedder 缺少对应构造函数重载

**方案：**

为 PlatformViewEmbedder 增加 Vulkan Impeller 对应的构造函数入口，新增构造入口后，embedder.cc 中已有的 Vulkan Impeller 逻辑可以正确落到 PlatformViewEmbedder，实现完整的 Vulkan Impeller 接入闭环

#### Vulkan 后端修复 Adreno OOM：补齐 command pool 和 descriptor pool 复位

**问题：**

Adreno 驱动对 command pool 和 descriptor pool 的持续增长更敏感，在高频分配但不复位的情况下更容易触发 OOM，反复分配 command buffer 和 descriptor set 而不复位 pool，会导致已完成帧对应的分配长期滞留，最终引发内存持续增长和 OOM，**在 Android 原生的渲染路线中不会有这个问题**

**方案：**

为 Vulkan 后端补充 command pool 和 descriptor pool 的显式复位机制，在每帧 present 完成后显式复位 command pool 和 descriptor pool，及时回收本帧已完成的临时分配，避免 Vulkan 资源池无限增长，降低 Adreno 设备在长时间运行下触发 OOM 的风险

## 功能

- 在 CPU/GPU 模式都有较高刷新率
- 响应式的 UI
- 更完整的终端

### 4.fort Cli

这个最初是由 sh 脚本实现的，后面转成了 dart，它的作用是配合 custom-devices.json，因为这种模式下的 Flutter App，需要特殊的安装方式，以及 ffi 的插件补全，推送到设备的 /tmp，还有很多额外的工作，都是 fort 内部完成，包括但不限于

- 字体库补齐
- GPU 驱动挂载
- 动态库补齐

custom-devices.json 的配置示例如下：

```json
{
  "custom-devices": [
    {
      "id": "rec",
      "label": "Android Recovery",
      "sdkNameAndVersion": "Android Recovery 1.0",
      "platform": "android-arm64",
      "enabled": true,
      "ping": [
        "adb",
        "get-state"
      ],
      "pingSuccessRegex": "recovery",
      "postBuild": null,
      "uninstall": [
        "fort",
        "uninstall",
        "--app-name",
        "${appName}"
      ],
      "install": [
        "fort",
        "install",
        "--app-name",
        "${appName}",
        "--local-path",
        "${localPath}/.."
      ],
      "runDebug": [
        "fort",
        "launch",
        "--app-name",
        "${appName}"
      ],
      "forwardPort": [
        "adb",
        "forward",
        "tcp:${hostPort}",
        "tcp:${devicePort}"
      ],
      "forwardPortSuccessRegex": ".*",
      "stopApp": [
        "adb",
        "shell",
        "killall",
        "flutter-runner"
      ],
      "screenshot": [
        "echo",
        "Installing on Android Recovery"
      ]
    }
  ]
}
```

说明：如果需要在同一个设备定义下切换渲染后端（例如 Vulkan / SwiftShader），可以通过环境变量传给 `fort` 决策（例如 `FORT_RENDERER=software|vulkan|swiftshader`），而不是再定义多个 device id。

详见 [launch.json](.vscode/launch.json)

### 5.底层库独立

- TWRP 的代码和UI是耦合在一起的的。需要将部分能力拆分成可以独立使用的库，例如 Setting，这样可以保持 ARP 和 TWRP 的设置同步
- 还有例如电量获取等，也要拆分出独立的模块，以 ffi 的方式提供给 Flutter 层
- 其他的 so 库保持不动，这样只要是基于同一个 TWRP 额的源码编译出来的版本，Flutter 都能正常使用 ffi 能力

例如：

```bash
➜  android_source $READELF -d 'libtwrp_settings_ffi.so'
Dynamic section at offset 0x81f0 contains 35 entries:
  Tag                Type              Name/Value
  0x0000000000000001 (NEEDED)          Shared library: [android.hardware.health@2.0.so]
  0x0000000000000001 (NEEDED)          Shared library: [libhidlbase.so]
  0x0000000000000001 (NEEDED)          Shared library: [libutils.so]
  0x0000000000000001 (NEEDED)          Shared library: [libbase.so]
  0x0000000000000001 (NEEDED)          Shared library: [libc++.so]
  0x0000000000000001 (NEEDED)          Shared library: [libc.so]
  0x0000000000000001 (NEEDED)          Shared library: [libm.so]
  0x0000000000000001 (NEEDED)          Shared library: [libdl.so]
  0x000000000000000e (SONAME)          Library soname: [libtwrp_core_ffi.so]
  ***
```

其中的 `android.hardware.health@2.0.so/libhidlbase.so` 等都不需要管

只需要把 libtwrp_core_ffi.so 作为 ARP(Flutter App) 的依赖即可

## 功能

- 支持多指并解决 TWRP 单指快速点击，大量事件丢失的问题
- 待补

## 架构设计

```text
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│                           Flutter On Android Recovery (Architecture)                     │
└──────────────────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────────────────────┐
│ Framework (Dart)                                                                         │
│  ┌──────────────────────┐   ┌──────────────────────┐                                     │
│  │ Material / Cupertino │   │ Widgets              │                                     │
│  └──────────────────────┘   └──────────────────────┘                                     │
│  ┌──────────────────────────────────────────────────────────────────────────┐            │
│  │ Rendering / Animation / Painting / Gestures / Foundation                 │            │
│  └──────────────────────────────────────────────────────────────────────────┘            │
│  App code (your Dart/Flutter app) → builds widget tree → produces layer tree / scene     │
└──────────────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ Flutter Engine API (embedder)
                                      v
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│ Engine (C/C++)                                                                           │
│  ┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐            │
│  │ Dart Isolate Setup   │  │ Dart Runtime Mgmt    │  │ Service Protocol     │            │
│  └──────────────────────┘  └──────────────────────┘  └──────────────────────┘            │
│  ┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐            │
│  │ Asset Resolution     │  │ Platform Channels    │  │ System Events        │            │
│  └──────────────────────┘  └──────────────────────┘  └──────────────────────┘            │
│  ┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐            │
│  │ Frame Scheduling     │  │ Frame Pipelining     │  │ Composition          │            │
│  └──────────────────────┘  └──────────────────────┘  └──────────────────────┘            │
│  Raster backend (selected by embedder):                                                  │
│    - Software: Skia CPU raster                                                           │
│    - Vulkan:   Impeller Vulkan (if enabled)                                              │
└──────────────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ Callbacks + configs provided by embedder
                                      v
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│ Embedder (platform-specific: Recovery runner)                                            │
│                                                                                          │
│  ┌──────────────────────────────┐   ┌───────────────────────────────┐                    │
│  │ Thread / TaskRunner Setup    │   │ Event Loop Interop            │                    │
│  │ (UI/Raster/IO/Platform)      │   │ (epoll path; avoid libandroid)│                    │
│  └──────────────────────────────┘   └───────────────────────────────┘                    │
│  ┌──────────────────────────────┐   ┌──────────────────────────────┐                     │
│  │ App Packaging (Bundle)       │   │ Native Plugins (optional)    │                     │
│  │ - icudtl.dat                 │   │ - MethodChannel/EventChannel │                     │
│  │ - flutter_assets/*           │   │ - minimal in Recovery        │                     │
│  │ - libapp.so (AOT only)       │   └──────────────────────────────┘                     │
│  └──────────────────────────────┘                                                        │
│  ┌──────────────────────────────────────────────────────────────────────────┐            │
│  │ Render Surface Setup (DRM-DUMB)                                          │            │
│  │  - KMS/DRM dumb buffers                                                  │            │
│  │  - PresentSoftwareBitmap/PresentBuffer                                   │            │
│  └──────────────────────────────────────────────────────────────────────────┘            │
│  ┌──────────────────────────────────────────────────────────────────────────┐            │
│  │ Input (Recovery)                                                         │            │
│  │  - minuitwrp touch API → Flutter pointer/key events                      │            │
│  └──────────────────────────────────────────────────────────────────────────┘            │
│  Vulkan mode extra (when enabled):                                                       │
│  ┌──────────────────────────────────────────────────────────────────────────┐            │
│  │ Vulkan loader/driver chain                                               │            │
│  │  libvulkan.so → /vendor/lib64/hw/vulkan.adreno.so                        │            │
│  │  (often also) libc++.so / libnativewindow.so                             │            │
│  └──────────────────────────────────────────────────────────────────────────┘            │
└──────────────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ Display scanout
                                      v
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│ Kernel / Hardware                                                                        │
│  DRM (e.g., msm_drm) + KMS → panel/display controller → screen                           │
└──────────────────────────────────────────────────────────────────────────────────────────┘
```


## 构建 Debug

```bash
forc build-app
forc install --app-name aurora_recovery --local-path build
forc launch --app-name aurora_recovery
```

```bash
forc build-app --release
forc install --app-name aurora_recovery-release --local-path build
forc launch --app-name aurora_recovery-release --release
flutter assemble -dTargetPlatform=android-arm64 \
-dBuildMode=release \
-dTargetFile=lib/main.dart \
--local-engine-src-path=$TWRP_FLUTTER_SDK/engine/src \
--local-engine=android_release_arm64_embedder_software \
--local-engine-host=host_debug_unopt_arm64 \
-o build \
android_aot_bundle_release_android-arm64
```

## 运行

```bash
device=oneplus15-rec
device=opus-pad2pro-rec 

flutter run -d $device --debug \
  -t lib/main.dart \
  --local-engine-src-path=$TWRP_FLUTTER_SDK/engine/src \
  --local-engine=android_debug_unopt_arm64_embedder_software \
  --local-engine-host=host_debug_unopt_arm64 \
  -v
```

adb shell cat /tmp/twrp_child.log > ./twrp_child.log
adb shell cat /data/local/tmp/magisk_install.log > ./magisk_install.log
adb shell dmesg -T | tail -200 > ./dmesg.log



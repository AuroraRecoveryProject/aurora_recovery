# Aurora Recovery Project (ARP)

一个全新的 Android Recovery，基于 Flutter 构建，我想把安卓的整个 Recovery 生态推向下一个里程碑

无论如何，我不会放弃我的每一个软件，曾经是，将来是，现在也是

## 为什么开发？

在我设备换了一加的手机和平板后，我再次接触了刷机，刷 Magisk，但因为用小米失去的这几年，我已经完全和这个生态脱节，第一步尝试了找设备的 TWRP，还是熟悉的界面，和十年前几乎一模一样，在我8年前刚接触 Flutter，我当时就想，如果这个 Recovery 能用 Flutter 开发就好了，当时也没想太多这件事的意义是什么，直到现在，我终于有了能力将这件事情实现。

## 解决什么问题？

在尝试自己编译 TWRP 的过程中，发现整个过程其实比较复杂，TWRP 需要依赖整个 AOSP 的编译环境，占用磁盘非常大，第一次编译时间非常长，后续命中缓存编译时间会好一些，但对于 TWRP 的开发，我并不清楚是如何进行的，是不是只能盲写代码，然后 push recovery 这个二进制到设备上运行测试，还是需要完整 flash recovery 镜像，也许有一些现有的方法，例如 TWRP 的 UI 是基于 XMl 编写的，可能可以实现直接预览，但无论如何，整个开发流程效率极低

于是我将 Flutter 带到了 Android Recovery 环境中，开发 Aurora Recovery，和开发普通 Flutter App 没有任何差异，借助 flutter 的 custom devices，保存后 hot reload，以及 hot restart，都和普通开发完全一样

总结：

- 开发效率提升：Flutter 的 hot reload 和 hot restart 大大缩短了开发周期，极大提升了开发效率，有开发效率，这个 Recovery 才能快速迭代，快速完善，快速适配更多设备
- Flutter 丰富的生态：Flutter 拥有丰富的第三方库和工具，可以轻松集成各种功能，例如网络请求、数据存储、动画效果等，这些都可以直接在 Recovery 中使用，而不需要重新开发
- 跨平台: 虽然是只运行在 Android Recovery 环境，但如果仅仅调试 UI，可以通过其他任意设备调试

## 如何实现？

### 1.为 flutter-embedded-linux 开发一个新的 DRM-DUMB backend

基于 sony 的 [flutter-embedded-linux](https://github.com/sony/flutter-embedded-linux)，原始的代码，是强依赖 Linux 的 GPU 环境的，即使是flutter-embedded-linux/examples/flutter-drm-gbm-backend 这个 backend，虽然是直接操作 drm 设备节点，但在 Android Recovery 模式下仍然不可用

而参考 TWRP 的代码，其中有两个渲染库，分别是 minui/minuitwrp，后者对现代的设备支持更好，有针对设置 plane 通道等操作，前者在一加15和一加 Pad2 Pro 上的 RGB demo 展示都不正确

所以 DRM-DUMB backend 的实现初步就是将 Flutter 每帧渲染的数据通单次 CPU 拷贝，再使用 minuitwrp 送显

### 2.自定义 Flutter Engine

#### 2.1 CPU Only

使用以下参数构建

#### 2.2 Vulkan (Impeller)

使用以下参数构建

### 3.输入事件适配

从 minuitwrp 获取输入事件，转换为 Flutter 的 PointerEvent 注入到 Engine 中

所以整个 ARP 的实现设计三个库，我目前仅想开源

### 4.fort Cli

这个最初是由 sh 脚本实现的，后面转成了 dart，它的作用是配合 custom-devices.json，因为这种模式下的 Flutter App，需要特殊的安装方式，以及 ffi 的插件补全，推送到设备的 /tmp，还有很多额外的工作，都是 fort 内部完成，包括但不限于

- 字体库补齐
- GPU 驱动挂载
- 动态库补齐

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
  0x000000000000001e (FLAGS)           BIND_NOW 
  0x000000006ffffffb (FLAGS_1)         NOW 
  0x0000000060000011 (ANDROID_RELA)    0x2138
  0x0000000060000012 (ANDROID_RELASZ)  211 (bytes)
  0x0000000000000009 (RELAENT)         24 (bytes)
  0x000000006fffe000 (ANDROID_RELR)    0x2210
  0x000000006fffe001 (ANDROID_RELRSZ)  0x10
  0x000000006fffe003 (ANDROID_RELRENT) 0x8
  0x0000000000000017 (JMPREL)          0x2220
  0x0000000000000002 (PLTRELSZ)        1680 (bytes)
  0x0000000000000003 (PLTGOT)          0x8450
  0x0000000000000014 (PLTREL)          RELA
  0x0000000070000001 (AARCH64_BTI_PLT) 0
  0x0000000000000006 (SYMTAB)          0x338
  0x000000000000000b (SYMENT)          24 (bytes)
  0x0000000000000005 (STRTAB)          0xea4
  0x000000000000000a (STRSZ)           4751 (bytes)
  0x000000006ffffef5 (GNU_HASH)        0xdc8
  0x0000000000000019 (INIT_ARRAY)      0x81e8
  0x000000000000001b (INIT_ARRAYSZ)    8 (bytes)
  0x000000000000001a (FINI_ARRAY)      0x81d8
  0x000000000000001c (FINI_ARRAYSZ)    16 (bytes)
  0x000000006ffffff0 (VERSYM)          0xcc8
  0x000000006ffffffe (VERNEED)         0xd94
  0x000000006fffffff (VERNEEDNUM)      1
  0x0000000000000000 (NULL)            0x0
```

其中的 `android.hardware.health@2.0.so/libhidlbase.so` 等都不需要管

只需要把 libtwrp_core_ffi.so 作为 ARP(Flutter App) 的依赖即可

## 功能

- 支持多指并解决 TWRP 单指快速点击，大量事件丢失的问题

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
┌──────────────────────────────────────────────────────────────────────────────────────────────┐
│ Embedder (platform-specific: Recovery runner)                                                │
│                                                                                              │
│  ┌──────────────────────────────┐   ┌───────────────────────────────┐                        │
│  │ Thread / TaskRunner Setup    │   │ Event Loop Interop            │                        │
│  │ (UI/Raster/IO/Platform)      │   │ (epoll path; avoid libandroid)│                        │
│  └──────────────────────────────┘   └───────────────────────────────┘                        │
│  ┌──────────────────────────────┐   ┌──────────────────────────────┐                         │
│  │ App Packaging (Bundle)       │   │ Native Plugins (optional)    │                         │
│  │ - icudtl.dat                 │   │ - MethodChannel/EventChannel │                         │
│  │ - flutter_assets/*           │   │ - minimal in Recovery        │                         │
│  │ - libapp.so (AOT only)       │   └──────────────────────────────┘                         │
│  └──────────────────────────────┘                                                            │
│  ┌──────────────────────────────────────────────────────────────────────────┐                │
│  │ Render Surface Setup (DRM-DUMB)                                          │                │
│  │  - KMS/DRM dumb buffers                                                  │                │
│  │  - PresentSoftwareBitmap/PresentBuffer                                   │                │
│  └──────────────────────────────────────────────────────────────────────────┘                │
│  ┌──────────────────────────────────────────────────────────────────────────┐                │
│  │ Input (Recovery)                                                         │                │
│  │  - minuitwrp touch API → Flutter pointer/key events                      │                │
│  └──────────────────────────────────────────────────────────────────────────┘                │
│  Vulkan mode extra (when enabled):                                                           │
│  ┌──────────────────────────────────────────────────────────────────────────┐                │
│  │ Vulkan loader/driver chain                                               │                │
│  │  libvulkan.so → /vendor/lib64/hw/vulkan.adreno.so                        │                │
│  │  (often also) libc++.so / libnativewindow.so                             │                │
│  └──────────────────────────────────────────────────────────────────────────┘                │
└──────────────────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ Display scanout
                                      v
┌──────────────────────────────────────────────────────────────────────────────────────────────┐
│ Kernel / Hardware                                                                            │
│  DRM (e.g., msm_drm) + KMS → panel/display controller → screen                               │
└──────────────────────────────────────────────────────────────────────────────────────────────┘
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
--local-engine-src-path=../flutter-3.29-new/engine/src \
--local-engine=android_release_arm64_embedder_software \
--local-engine-host=host_debug_unopt_arm64 \
-o build \
android_aot_bundle_release_android-arm64
```

## 运行

```bash
flutter run -d rec --debug \                     
  -t lib/main.dart \
  --local-engine-src-path=/Users/Laurie/Desktop/nightmare-space/Android_Recovery/Flutter_On_Recovery/flutter-3.29-new/engine/src \
  --local-engine=android_debug_unopt_arm64_embedder_software \
  --local-engine-host=host_debug_unopt_arm64 -v
```
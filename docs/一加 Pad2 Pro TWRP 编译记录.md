# 一加 Pad2 Pro Recovery TWRP 编译

## 起因

一加 Pad2 Pro 目前能搜到的 Rec 有两个:

- [[RECOVERY][UNOFFICIAL][TWRP-3.7.1_12] TWRP for OnePlus Pad 2](https://xdaforums.com/t/recovery-unofficial-twrp-3-7-1_12-twrp-for-oneplus-pad-2.4692182/)
- [[shared][recovery]oneplus pad 3/pad 2 pro](https://xdaforums.com/t/shared-recovery-oneplus-pad-3-pad-2-pro-twrp.4748091/)

第一个用的设备树是 [twrp_caihong](https://github.com/hraj9258/twrp_caihong)，caihong 是一加 Pad 2 的代号，一加 Pad 2Pro 的代号是 ossi

不知道为什么，编译出来的 Recovery 也能运行在 Pad 2Pro 上

但是目前很短的使用就发现了以下问题：

- 1.电量获取到的始终是100+
- 2.无法在 Recovery 模式下充电
- 3.fastbootd 模式完全无法使用

也是让我不得不尝试编译新的 TWRP 的原因，这里的 fastbootd 不是 bootloader 模式，传统的 fastboot 运行在 bootloader 模式下，fastbootd 运行在 Android 的 recovery / userspace 里，目的就是能支持动态分区的刷入

安卓10引入的动态分区，system/vendor/odm 等分区被合并到 super 分区里，所以传统的 fastboot 只能刷整个 super 镜像，刷不了单个动态分区

而系统 Rom 一般解包后就是单独的 system/vendor .img

日志如下：

```bash
# fastboot flash system system.img
ERROR: usb_write failed with status e00002ed
ERROR: usb_write failed with status e00002d8
ERROR: usb_write failed with status e00002d8
ERROR: usb_write failed with status e00002d8
ERROR: usb_write failed with status e00002d8
Warning: skip copying system image avb footer (system partition size: 0, system image size: 971853824).
ERROR: usb_write failed with status e00002d8
Sending 'system' (949076 KB)                       ERROR: usb_write failed with status e00002d8
FAILED (Write to device failed (No such file or directory))
fastboot: error: Command failed
```

并且不管刷写失败，原本的分区这么一搞彻底坏了

所以在我一次轻微变砖后，我用这个 rec 救不回来，当然，可以包装一个 super.img 刷入，但没必要，应该从根本解决问题

不过遇到这种情况，可以先刷入官方的 recovery，然后用命令 fastboot reboot fastboot 进入 fastbootd 模式，再刷入 system.img，这样就能暂时救回来

上面的第二个是只有网盘分享的 Rec，我还是比较喜欢开源，特别是 Rec，内核这种东西，遇到问题，至少有途径分析

## 思路

一加15的设备树 [twrp_device_oplus_infiniti](https://github.com/koaaN/twrp_device_oplus_infiniti) 是基于 [twrp_device_oplus_sm87xx](https://github.com/kmiit/twrp_device_oplus_sm87xx) 分叉的，而 `twrp_device_oplus_sm87xx` 支持的设备都是一加或者 Realme，全是 OPPO 的品牌，芯片大都是骁龙 8 Elite, 一加 Pad 2Pro 的芯片也是这个，所以从这个设备树上改是最佳的选择，并且这个设备树中的东西比 caihong 要多很多

twrp_caihong

```bash
.
├── AndroidProducts.mk
├── BoardConfig.mk
├── device.mk
├── recovery
│   └── root
│       ├── init.recovery.qcom.rc
│       ├── init.recovery.usb.rc
│       ├── system
│       │   ├── bin
│       │   │   ├── android.hardware.gatekeeper@1.0-service-qti
│       │   │   ├── android.hardware.security.keymint-service-qti
│       │   │   └── qseecomd
│       │   ├── etc
│       │   │   ├── event-log-tags
│       │   │   ├── recovery.fstab
│       │   │   ├── task_profiles.json
│       │   │   ├── twrp.flags
│       │   │   └── vintf
│       │   └── lib64
│       │       └── libdmabufheap.so
│       └── vendor
│           ├── etc
│           │   ├── gpfspath_oem_config.xml
│           │   ├── init
│           │   ├── ueventd.rc
│           │   └── vintf
│           └── lib64
│               ├── android.hardware.security.keymint-V3-ndk.so
│               ├── android.hardware.security.rkp-V3-ndk.so
│               ├── android.hardware.security.secureclock-V1-ndk.so
│               ├── android.hardware.security.sharedsecret-V1-ndk.so
│               ├── hw
│               ├── libGPreqcancel.so
│               ├── libGPreqcancel_svc.so
│               ├── libQSEEComAPI.so
│               ├── libboot_control_qti.so
│               ├── libdiag.so
│               ├── libdisplayconfig.qti.so
│               ├── libdrm.so
│               ├── libdrmfs.so
│               ├── libdrmtime.so
│               ├── libgpt.so
│               ├── libkeymasterdeviceutils.so
│               ├── libkeymasterutils.so
│               ├── libminkdescriptor.so
│               ├── libops.so
│               ├── libqcbor.so
│               ├── libqisl.so
│               ├── libqtikeymint.so
│               ├── librecovery_updater.so
│               ├── librpmb.so
│               ├── libspl.so
│               ├── libssd.so
│               ├── libtime_genoff.so
│               └── vendor.display.config@2.0.so
├── twrp_caihong.mk
└── vendor.prop
```

twrp_device_oplus_sm87xx

```bash
.
├── Android.bp
├── AndroidProducts.mk
├── BoardConfig.mk
├── README.md
├── device.mk
├── libinit
│   ├── Android.bp
│   └── libinit_oplus_sm87xx.cpp
├── recovery
│   └── root
│       ├── init.recovery.qcom.rc
│       ├── init.recovery.usb.rc
│       ├── system
│       │   └── etc
│       │       ├── event-log-tags
│       │       ├── task_profiles.json
│       │       ├── twrp.flags
│       │       ├── ueventd.rc
│       │       └── vintf
│       └── vendor
│           ├── bin
│           │   ├── hw
│           │   ├── init.kernel.post_boot-sun_default_6_2.sh
│           │   ├── override-spl.sh
│           │   ├── qseecomd
│           │   └── ssgtzd
│           ├── etc
│           │   ├── gpfspath_oem_config.xml
│           │   ├── init
│           │   ├── ssg
│           │   ├── ueventd.rc
│           │   └── vintf
│           ├── lib64
│           │   ├── android.hardware.common-V2-ndk.so
│           │   ├── hw
│           │   ├── libGPMTEEC_vendor.so
│           │   ├── libGPQeSE.so
│           │   ├── libGPTEE_vendor.so
│           │   ├── libGPreqcancel.so
│           │   ├── libGPreqcancel_svc.so
│           │   ├── libQSEEComAPI.so
│           │   ├── libboot_control_qti.so
│           │   ├── libconfigdb.so
│           │   ├── libdiag.so
│           │   ├── libdmabufheap.so
│           │   ├── libdrm.so
│           │   ├── libdrmfs.so
│           │   ├── libdrmtime.so
│           │   ├── libdsi_netctrl.so
│           │   ├── libdsutils.so
│           │   ├── libgatekeeper.so
│           │   ├── libgpt.so
│           │   ├── libidl.so
│           │   ├── libion.so
│           │   ├── libkeymasterdeviceutils.so
│           │   ├── libkeymasterutils.so
│           │   ├── libmdmdetect.so
│           │   ├── libminkdescriptor.so
│           │   ├── libminksocket_vendor.so
│           │   ├── libnetutils.so
│           │   ├── libnicm.so
│           │   ├── libnicm_dsi.so
│           │   ├── libnicm_utils.so
│           │   ├── libops.so
│           │   ├── libqcbor.so
│           │   ├── libqdi.so
│           │   ├── libqisl.so
│           │   ├── libqmi.so
│           │   ├── libqmi_cci.so
│           │   ├── libqmi_client_helper.so
│           │   ├── libqmi_client_qmux.so
│           │   ├── libqmi_common_so.so
│           │   ├── libqmi_csi.so
│           │   ├── libqmi_encdec.so
│           │   ├── libqmiservices.so
│           │   ├── libqrtr.so
│           │   ├── libqtikeymint.so
│           │   ├── librecovery_updater.so
│           │   ├── librpmb.so
│           │   ├── libseclog.so
│           │   ├── libsoc_helper.so
│           │   ├── libspl.so
│           │   ├── libssd.so
│           │   ├── libtaautoload.so
│           │   ├── libtime_genoff.so
│           │   ├── libvmmem.so
│           │   ├── libxml.so
│           │   └── vendor.qti.hardware.display.config-V7-ndk.so
│           └── odm
│               ├── bin
│               ├── etc
│               ├── firmware
│               └── lib64
├── recovery.fstab
├── security
│   ├── local_OTA.x509.pem
│   └── special_OTA.x509.pem
├── system.prop
└── twrp_sm87xx.mk
```

我不太懂这些设备树到底是如何生成的，包括这一系列的 so, 想学习，目前找到的大部分生成设备树的都是比较古老的 twrpdtgen，有缘的话可以学一下，请教过维护的开发者的建议是，直接看 commit 历史

后来亲自尝试给已经有的设备树，添加 WLAN 的过程中，逐渐明白了，添加一个简单的二进制，会依赖很多 so，各种配置文件，就全带进 Rec 了

目前分区表应该参考的是 vendor_boot.img 解包后的 first_stage_ramdisk/fstab.qcom

不仅设备树的构建很少有

连所有 TWRP 的构建文档都指向 [[DEV]How to compile TWRP touch recovery](https://xdaforums.com/t/dev-how-to-compile-twrp-touch-recovery.1943625/)

2012 年的文章！！！14年前！！！这样的事为什么会发生在开源社区。

## prop 补齐

```bash
adb shell 'echo "brand=$(getprop ro.product.brand) device=$(getprop ro.product.device) manufacturer=$(getprop ro.product.manufacturer) model=$(getprop ro.product.model) base_name=$(getprop ro.product.name | cut -d_ -f1) prjname=$(getprop ro.boot.prjname)"'
```

`libinit/libinit_oplus_sm87xx.cpp` 修改

```c
const std::unordered_map<int, ModelInfo> kModelInfoMap = {
    {23821, {"OnePlus", "OP5D0DL1", "OnePlus", "PJZ110",  "PJZ110",  "OnePlus_13",          "1"}}, // dodge CN
    {23893, {"OnePlus", "OP5D55L1", "OnePlus", "CPH2653", "CPH2653", "OnePlus_13",          "1"}}, // dodge GLO
    {24600, {"realme",  "RE6018L1", "realme",  "RMX5010", "RMX5010", "Realme_GT_7_Pro",     "0"}}, // RMX5010 CN
    {24620, {"realme",  "RE602CL1", "realme",  "RMX5090", "RMX5090", "Realme_GT_7_Pro_JS",  "0"}}, // RMX5090 CN
    {24670, {"realme",  "RE605FL1", "realme",  "RMX5011", "RMX5011", "Realme_GT_7_Pro",     "0"}}, // RMX5011 IN
    {24671, {"realme",  "RE605FL1", "realme",  "RMX5011", "RMX5011", "Realme_GT_7_Pro",     "0"}}, // RMX5011 EEA/RU
    {24811, {"OnePlus", "OP60EBL1", "OnePlus", "PKR110",  "PKR110",  "OnePlus_ACE_5_Pro",   "0"}}, // hummer CN
    {24816, {"OnePlus", "OP60F0L1", "OnePlus", "PLU110",  "PLU110",  "OnePlus_Turbo_6",     "0"}}, // Prado CN
    {24821, {"OnePlus", "OP60F5L1", "OnePlus", "PKX110",  "PKX110",  "OnePlus_13_T",        "1"}}, // pagani CN
    {24875, {"OnePlus", "OP612BL1", "OnePlus", "CPH2723", "CPH2723", "OnePlus_13_s",        "1"}}, // pagani IN
    {24851, {"OnePlus", "OP6113L1", "OnePlus", "PLQ110",  "PLQ110",  "OnePlus_ACE_6",       "0"}}, // ktm CN
    {25600, {"realme",  "RE6400L1", "realme",  "RMX6699", "RMX6699", "Realme_GT_8",         "0"}}, // RMX6699 CN
    {24926, {"OnePlus", "OP615EL1", "OnePlus", "OPD2413", "OPD2413", "OnePlus_Pad2Pro",     "0"}}, // ossi CN
    {0,     {"OPLUS",   "SM87XX",   "OPLUS",   "SM87XX",  "SM87XX",  "SM87XX",              "0"}}, // Default
};
```

新增行

```c
    {24926, {"OnePlus", "OP615EL1", "OnePlus", "OPD2413", "OPD2413", "OnePlus_Pad2Pro",     "0"}}, // ossi CN
```

同样这个文件，添加

```c
void vendor_load_properties() {
    std::string buf = "0";
    GetKernelCmdline("oplus_region", &buf);

    auto region = std::stoi(buf);
    auto region_suffix_iter = kRegionSuffixMap.find(region);

    // Handle unknown regions gracefully
    if (region_suffix_iter == kRegionSuffixMap.end()) {
        LOG(WARNING) << "Unknown oplus_region: " << region << ", using default";
        region_suffix_iter = kRegionSuffixMap.find(0);
    }

    auto prjname = std::stoi(GetProperty("ro.boot.prjname", "0"));
    auto model_info = kModelInfoMap.find(prjname);

    // Handle unknown device models
    if (model_info == kModelInfoMap.end()) {
        LOG(ERROR) << "Unknown prjname: " << prjname << ", using default";
        model_info = kModelInfoMap.find(0);
    }

    SetupModelProperties(model_info->second, region_suffix_iter->second);

    // Set a prop to handle rotation
    if (prjname == 24926) {
        OverrideProperty("persist.twrp.rotation", "270");
    }
    // Set a prop to handle strongbox
    switch (prjname) {
        case 24851:
            OverrideProperty("twrp.se.no_sb", "true");
            break;
        default:
            OverrideProperty("twrp.se.no_sb", "false");
    }
}
```

添加部分：

```c
    // Set a prop to handle rotation
    if (prjname == 24926) {
        OverrideProperty("persist.twrp.rotation", "270");
    }
```

详情 commit [Support OnePlus Pad 2 Pro](https://github.com/kmiit/twrp_device_oplus_sm87xx/commit/313432a2961dfcdfa497ee78ade686cfdbc6a1f5)

没错，就这个一个文件改动，已经提交 PR 合并了，不过后续支持 WLAN，改动就非常大了
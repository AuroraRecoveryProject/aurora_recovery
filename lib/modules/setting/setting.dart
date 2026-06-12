import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import 'package:responsive_framework/responsive_framework.dart';
import 'package:global_repository/global_repository.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:aurora_recovery/services/device_info_service.dart';
import 'package:aurora_recovery/services/setting_service.dart';
import 'package:aurora_recovery/modules/video_player/core/video_player_backend.dart';
import 'package:aurora_recovery/widgets/fake_safearea.dart';
import 'package:aurora_recovery/common/assets.dart';
import 'package:aurora_recovery/common/l10n.dart';
import 'package:aurora_recovery/main.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool isImpellerEnabled() {
    // This property returns true only when the Impeller engine is active
    return ui.ImageFilter.isShaderFilterSupported;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStle = TextStyle(fontSize: $(16));
    bool isDesktop = ResponsiveBreakpoints.of(context).isDesktop;
    Widget? leading;
    if (!isDesktop) {
      leading = IconButton(
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
        icon: SvgPicture.asset(
          Assets.menuIcon,
          width: $(24),
          height: $(24),
          colorFilter: ColorFilter.mode(
            Theme.of(context).colorScheme.onSurfaceVariant,
            BlendMode.srcIn,
          ),
        ),
      );
    }
    return Material(
      color: colorScheme.surface,
      child: FakeSafearea(
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.setting),
            leadingWidth: $(48 + 16),
            forceMaterialTransparency: true,
            leading: leading,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all($(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: $(8),
              children: [
                Text(l10n.current_render_mode(isImpellerEnabled() ? 'Vulkan' : 'Software'), style: textStle),
                Text(l10n.video_render_mode),
                RadioGroup<VideoPlayerBackend>(
                  groupValue: SettingInstance.videoPlayerBackend,
                  onChanged: (value) {
                    if (value == null) return;
                    SettingInstance.setVideoPlayerBackend(value);
                    setState(() {});
                    Get.forceAppUpdate();
                  },
                  child: Row(
                    children: [
                      Radio(value: VideoPlayerBackend.ffi),
                      Text('FFI'),
                      Radio(value: VideoPlayerBackend.texture),
                      Text('Texture'),
                      Radio(value: VideoPlayerBackend.yuvTexture),
                      Text('YUV Texture'),
                    ],
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular($(8)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all($(12)),
                    child: DefaultTextStyle(
                      style: textStle.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('FFI / Texture'),
                          Text('CPU 消耗最多，Recovery 下调度不理想，设备会很快发热。'),
                          SizedBox(height: $(8)),
                          Text('YUV Texture'),
                          Text('CPU 压力会好一些，但依赖 Vulkan。'),
                        ],
                      ),
                    ),
                  ),
                ),
                Text(
                  "${l10n.battery}: ${DeviceInfoInstance.batteryValue}",
                  style: textStle,
                ),
                Text(
                  "${l10n.brightness}: ${SettingInstance.brightnessPct}%",
                  style: textStle,
                ),
                SliderContainer(
                  value: SettingInstance.brightnessPct.toDouble(),
                  onChanged: (value) {
                    SettingInstance.setBrightness(value.toInt());
                    SettingInstance.settingSet('tw_brightness_pct', value.toInt().toString());
                    setState(() {});
                  },
                ),
                Row(
                  spacing: $(12),
                  children: [
                    Expanded(
                      child: Text(
                        l10n.show_performance_overlay,
                        style: textStle,
                      ),
                    ),
                    Switch(
                      value: showPerformanceOverlay,
                      onChanged: (value) {
                        showPerformanceOverlay = value;
                        setState(() {});
                        Get.forceAppUpdate();
                      },
                    ),
                  ],
                ),
                Text(
                  l10n.language,
                  style: textStle,
                ),
                RadioGroup<String>(
                  groupValue: Get.locale?.languageCode,
                  onChanged: (value) {
                    Get.updateLocale(Locale(value!));
                  },
                  child: Row(
                    children: [
                      Radio(value: 'zh'),
                      Text('中文'),
                      Radio(value: 'en'),
                      Text('English'),
                    ],
                  ),
                ),
                Row(
                  spacing: $(12),
                  children: [
                    Text(
                      l10n.reboot,
                      style: textStle,
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Process.run('reboot', []);
                      },
                      child: Text(
                        'System',
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Process.run('reboot', ['recovery']);
                      },
                      child: Text(
                        'Recovery',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SliderContainer extends StatefulWidget {
  const SliderContainer({
    super.key,
    required this.value,
    this.onChanged,
  });
  final double value;
  final ValueChanged<double>? onChanged;

  @override
  State<SliderContainer> createState() => _SliderContainerState();
}

class _SliderContainerState extends State<SliderContainer> {
  late double value = widget.value;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final double deltaValue = details.delta.dx / box.size.width * 100;
        value = (value + deltaValue).clamp(0, 100);
        setState(() {});
        widget.onChanged?.call(value);
      },
      child: SizedBox(
        height: $(48),
        width: double.infinity,
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular($(12)),
          clipBehavior: Clip.antiAlias,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value / 100,
            child: Container(
              height: $(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular($(12)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

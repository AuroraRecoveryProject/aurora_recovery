import 'dart:io';
import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
// ignore: depend_on_referenced_packages
import 'package:global_repository/global_repository.dart';
import 'package:aurora_recovery/common/l10n.dart';
import 'package:aurora_recovery/main.dart';
import 'package:aurora_recovery/services/global.dart';
import 'package:aurora_recovery/widgets/fake_safearea.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      child: FakeSafearea(
        top: ResponsiveBreakpoints.of(context).isMobile,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.setting),
            leadingWidth: $(48 + 16),
            forceMaterialTransparency: true,
            leading: IconButton(
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              icon: Icon(
                Icons.menu,
                size: $(24),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all($(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: $(8),
              children: [
                Text(
                  "${l10n.battery}: ${Global.batteryValue}",
                  style: TextStyle(
                    fontSize: $(16),
                  ),
                ),
                SizedBox(height: $(16)),
                Text(
                  "${l10n.brightness}: ${Global.brightnessPct}%",
                  style: TextStyle(
                    fontSize: $(16),
                  ),
                ),
                SliderContainer(
                  value: Global.brightnessPct.toDouble(),
                  onChanged: (value) {
                    Global.brightnessPct = value.toInt();
                    Global.ffi.tw_display_set_brightness_percent(Global.brightnessPct);
                    setState(() {});
                  },
                ),
                Row(
                  spacing: $(12),
                  children: [
                    Expanded(
                      child: Text(
                        l10n.show_performance_overlay,
                        style: TextStyle(
                          fontSize: $(16),
                        ),
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
                Row(
                  spacing: $(12),
                  children: [
                    Text(
                      '语言',
                      style: TextStyle(
                        fontSize: $(16),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Radio<String>(
                      value: 'zh',
                      groupValue: Get.locale?.languageCode,
                      onChanged: (value) {
                        Get.updateLocale(Locale(value!));
                      },
                    ),
                    Text('中文'),
                    Radio<String>(
                      value: 'en',
                      groupValue: Get.locale?.languageCode,
                      onChanged: (value) {
                        Get.updateLocale(Locale(value!));
                      },
                    ),
                  ],
                ),
                Row(
                  spacing: $(12),
                  children: [
                    Text(
                      l10n.reboot,
                      style: TextStyle(
                        fontSize: $(16),
                      ),
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

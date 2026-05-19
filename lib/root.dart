import 'dart:ui';

import 'package:aurora_recovery/demo_page.dart';
import 'package:aurora_recovery/widgets/toast.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:signale/signale.dart';

import 'drawer.dart';
import 'flash_rom/flash_rom_page.dart';
import 'setting/setting.dart';
import 'terminal/terminal_page.dart';
import 'theme.dart';
import 'video_player/video_player_page.dart';
import 'widgets/view_metric.dart';
import 'wlan/wlan_page.dart';

bool showPerformanceOverlay = false;

class AuroraRecoveryApp extends StatefulWidget {
  const AuroraRecoveryApp({super.key});

  @override
  State<AuroraRecoveryApp> createState() => _AuroraRecoveryAppState();
}

class _AuroraRecoveryAppState extends State<AuroraRecoveryApp> with WidgetsBindingObserver {
  // 监听窗口尺寸变化
  static const double _targetTouchSlop = 8.0;

  MediaQueryData _withRecoveryGestureSettings(MediaQueryData data) {
    final double? currentTouchSlop = data.gestureSettings.touchSlop;
    if (currentTouchSlop != null && currentTouchSlop <= _targetTouchSlop) {
      return data;
    }
    return data.copyWith(
      gestureSettings: const DeviceGestureSettings(touchSlop: _targetTouchSlop),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
    final size = view.physicalSize / view.devicePixelRatio;
    Log.i("Window size changed: $size");
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: showPerformanceOverlay,
      defaultTransition: Transition.cupertino,
      theme: auroraDark,
      builder: (context, child) {
        final mediaQuery = _withRecoveryGestureSettings(MediaQuery.of(context));
        return ResponsiveBreakpoints.builder(
          child: MediaQuery(
            data: mediaQuery,
            child: Builder(builder: (context) {
              FlutterView view = PlatformDispatcher.instance.views.first;
              Log.i("Current Device Pixel Ratio: ${view.devicePixelRatio}");
              Log.i("Current Screen Size: ${view.physicalSize / view.devicePixelRatio}");
              Log.i("Current touchSlop: ${MediaQuery.of(context).gestureSettings.touchSlop}");
              return ViewMetric(
                uiWidth: 414,
                screenWidth: MediaQuery.of(context).size.width,
                child: child!,
              );
            }),
          ),
          landscapePlatforms: ResponsiveTargetPlatform.values,
          breakpoints: const [
            Breakpoint(start: 0, end: 500, name: MOBILE),
            Breakpoint(start: 500, end: 800, name: TABLET),
            Breakpoint(start: 800, end: double.infinity, name: DESKTOP),
          ],
          breakpointsLandscape: [
            Breakpoint(start: 0, end: 500, name: MOBILE),
            Breakpoint(start: 500, end: 800, name: TABLET),
            Breakpoint(start: 800, end: double.infinity, name: DESKTOP),
          ],
        );
      },
      home: AuroraRecoveryRoot(),
      // shortcuts: ,
    );
  }
}

class AuroraRecoveryRoot extends StatefulWidget {
  const AuroraRecoveryRoot({super.key});

  @override
  State createState() => _AuroraRecoveryRootState();
}

class _AuroraRecoveryRootState extends State<AuroraRecoveryRoot> with SingleTickerProviderStateMixin {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pages = [
      DemoPage(),
      TerminalPage(),
      SettingPage(),
      VideoPlayerPage(),
      WlanPage(),
      FlashRomPage(),
    ];
    final spacer = SizedBox(width: $(24));
    final spacing = $(24);

    final drawerItems = [
      ArpDrawerItem(
        value: 1,
        groupValue: _selectedIndex,
        child: Row(
          spacing: spacing,
          children: [
            spacer,
            SvgPicture.asset(
              'assets/icons/terminal.svg',
              colorFilter: ColorFilter.mode(colorScheme.primary, BlendMode.srcIn),
            ),
            Text('终端'),
          ],
        ),
      ),
      ArpDrawerItem(
        value: 5,
        groupValue: _selectedIndex,
        child: Row(
          spacing: spacing,
          children: [
            spacer,
            SvgPicture.asset(
              'assets/icons/zap.svg',
              color: Theme.of(context).colorScheme.primary,
            ),
            Text('刷机'),
          ],
        ),
      ),
      ArpDrawerItem(
        value: 4,
        groupValue: _selectedIndex,
        child: Row(
          spacing: spacing,
          children: [
            spacer,
            SvgPicture.asset(
              'assets/icons/wifi-cog.svg',
              colorFilter: ColorFilter.mode(colorScheme.primary, BlendMode.srcIn),
            ),
            Text('WLAN'),
          ],
        ),
      ),
      ArpDrawerItem(
        value: 2,
        groupValue: _selectedIndex,
        child: Row(
          spacing: spacing,
          children: [
            spacer,
            SvgPicture.asset(
              'assets/icons/settings.svg',
              colorFilter: ColorFilter.mode(colorScheme.primary, BlendMode.srcIn),
            ),
            Text('设置'),
          ],
        ),
      ),
      ArpDrawerItem(
        value: 3,
        groupValue: _selectedIndex,
        child: Row(
          spacing: spacing,
          children: [
            spacer,
            SvgPicture.asset(
              'assets/icons/video.svg',
              colorFilter: ColorFilter.mode(colorScheme.primary, BlendMode.srcIn),
            ),
            Text('视频'),
          ],
        ),
      ),
      ArpDrawerItem(
        value: 0,
        groupValue: _selectedIndex,
        child: Row(
          spacing: spacing,
          children: [
            spacer,
            SvgPicture.asset(
              'assets/icons/layout-panel-left.svg',
              colorFilter: ColorFilter.mode(colorScheme.primary, BlendMode.srcIn),
            ),
            Text('Demo'),
          ],
        ),
      ),
    ];
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Builder(builder: (context) {
        final data = ResponsiveBreakpoints.of(context);
        if (data.isDesktop) {
          return Row(
            children: [
              ArpDrawer<int>(
                onItemSelected: (index) {
                  _selectedIndex = index;
                  setState(() {});
                },
                items: drawerItems,
              ),
              Expanded(
                child: pages[_selectedIndex],
              ),
            ],
          );
        }
        return Scaffold(
          drawer: SizedBox(
            width: 300,
            child: ArpDrawer<int>(
              onItemSelected: (index) {
                _selectedIndex = index;
                setState(() {});
                Get.back();
              },
              items: drawerItems,
            ),
          ),
          body: pages[_selectedIndex],
        );
      }),
    );
  }
}

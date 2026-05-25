import 'dart:async';
import 'dart:io';
import 'package:aurora_recovery/widgets/fake_safearea.dart';
import 'package:file_manager/file_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:xterm/xterm.dart';
import 'common/assets.dart';
import 'generated/app_localizations.dart';
import 'common/l10n.dart';
import 'modules/flash_rom/flash_rom_dialog.dart';
import 'services/flash_rom_service.dart';
import 'services/global.dart';
import 'setting/setting.dart';
import 'terminal/terminal_page.dart';
import 'theme.dart';
import 'video_player/video_player_page.dart';
// ignore: depend_on_referenced_packages
import 'package:global_repository/global_repository.dart';
import 'demo/demo_page.dart';
import 'drawer.dart';
import 'wifi/wifi_page.dart';

Future<void> main() async {
  int port = await FileServerService.instance.start();
  Log.i('File server started on port: $port');
  FMController controller = FMController();
  controller.setPort(port);
  controller.enterHomeDir();
  Get.put(controller);

  Config.initPackageMode();
  runApp(const AuroraRecoveryApp());
  Global.init();
}

bool showPerformanceOverlay = false;

class AuroraRecoveryApp extends StatefulWidget {
  const AuroraRecoveryApp({super.key});

  @override
  State<AuroraRecoveryApp> createState() => _AuroraRecoveryAppState();
}

class _AuroraRecoveryAppState extends State<AuroraRecoveryApp> with WidgetsBindingObserver {
  static const Duration _idleTimeout = Duration(seconds: kDebugMode ? 30 : 10);
  static const Duration _fadeDuration = Duration(milliseconds: 250);
  static const double _targetTouchSlop = 8.0;

  Timer? _idleTimer;
  bool _isDimmed = false;

  MediaQueryData _withRecoveryGestureSettings(MediaQueryData data) {
    // See: docs/ARP 触控 Slop 排查记录.md
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
    _restartIdleTimer();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _restartIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleTimeout, _dimScreen);
  }

  void _dimScreen() {
    if (!mounted || _isDimmed) {
      return;
    }
    setState(() {
      _isDimmed = true;
    });
  }

  void _handlePointerActivity(PointerEvent event) {
    if (event is! PointerDownEvent && event is! PointerMoveEvent && event is! PointerPanZoomStartEvent) {
      return;
    }
    _restartIdleTimer();
    if (!_isDimmed) {
      return;
    }
    setState(() {
      _isDimmed = false;
    });
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
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      locale: Locale('en'),
      builder: (context, child) {
        final mediaQuery = _withRecoveryGestureSettings(MediaQuery.of(context));
        return ResponsiveBreakpoints.builder(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _handlePointerActivity,
            onPointerMove: _handlePointerActivity,
            onPointerPanZoomStart: _handlePointerActivity,
            child: AbsorbPointer(
              absorbing: _isDimmed,
              child: AnimatedOpacity(
                duration: _fadeDuration,
                opacity: _isDimmed ? 0 : 1,
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
              ),
            ),
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

class _AuroraRecoveryRootState extends State<AuroraRecoveryRoot> {
  static const demo = 'demo';
  static const terminal = 'terminal';
  static const setting = 'setting';
  static const videoPlayer = 'video_player';
  static const wlan = 'wlan';
  static const fileManager = 'file_manager';
  String _selectedPage = terminal;

  final pages = {
    demo: DemoPage(),
    terminal: TerminalPage(),
    setting: SettingPage(),
    videoPlayer: VideoPlayerPage(),
    wlan: WifiPage(),
    fileManager: Builder(builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      final l10n = L10n.of(context)!;
      return FakeSafearea(
        top: ResponsiveBreakpoints.of(context).isMobile,
        child: FileManagerView(
          controller: Get.find<FMController>(),
          onFileTap: (file) {
            bool text = [
              'txt',
              'rc',
              'log',
              'ini',
              'conf',
              'cfg',
              'json',
              'xml',
              'prop',
            ].any((ext) => file.path.endsWith(ext));
            bool probeZom = ['zip', 'apk'].any((ext) => file.path.endsWith(ext));
            if (probeZom) {
              Get.dialog(
                AlertDialog(
                  title: Text('${l10n.flash} ${file.name}?'),
                  content: Text(l10n.flash_romt_tips(file.name), style: TextStyle(color: colorScheme.error)),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () {
                        Get.back();
                        Get.dialog(
                          FlashRomDialog(filePath: file.path),
                          barrierDismissible: false,
                        );
                      },
                      child: Text(l10n.flash),
                    ),
                  ],
                ),
              );
              return;
            }
            if (!text) return;
            Get.to(
              () => Container(
                color: colorScheme.surface,
                child: FakeSafearea(
                  child: Scaffold(
                    appBar: AppBar(
                      title: Text(file.path),
                      forceMaterialTransparency: true,
                    ),
                    body: FutureBuilder<String>(
                      future: File(file.path).readAsString(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Text(snapshot.data ?? ''),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    })
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final spacer = SizedBox(width: $(12));
    final spacing = $(12);
    final svgColorFilter = ColorFilter.mode(colorScheme.primary, BlendMode.srcIn);

    final drawerItems = [
      ArpDrawerItem(
        value: terminal,
        groupValue: _selectedPage,
        child: Row(
          spacing: spacing,
          children: [
            spacer,
            SvgPicture.asset(
              Assets.terminalIcon,
              colorFilter: svgColorFilter,
            ),
            Text(l10n.terminal),
          ],
        ),
      ),
      ArpDrawerItem(
        value: fileManager,
        groupValue: _selectedPage,
        child: Row(
          spacing: spacing,
          children: [
            spacer,
            SvgPicture.asset(
              Assets.folderOpenIcon,
              colorFilter: svgColorFilter,
            ),
            Text(l10n.file_manager),
          ],
        ),
      ),
      ArpDrawerItem(
        value: wlan,
        groupValue: _selectedPage,
        child: Row(
          spacing: spacing,
          children: [
            spacer,
            SvgPicture.asset(
              Assets.wifiCogIcon,
              colorFilter: svgColorFilter,
            ),
            Text(l10n.wlan),
          ],
        ),
      ),
      ArpDrawerItem(
        value: setting,
        groupValue: _selectedPage,
        child: Row(
          spacing: spacing,
          children: [
            spacer,
            SvgPicture.asset(
              Assets.settingsIcon,
              colorFilter: svgColorFilter,
            ),
            Text(l10n.setting),
          ],
        ),
      ),
      ArpDrawerItem(
        value: videoPlayer,
        groupValue: _selectedPage,
        child: Row(
          spacing: spacing,
          children: [
            spacer,
            SvgPicture.asset(
              Assets.videoIcon,
              colorFilter: svgColorFilter,
            ),
            Text(l10n.video_player),
          ],
        ),
      ),
      ArpDrawerItem(
        value: demo,
        groupValue: _selectedPage,
        child: Row(
          spacing: spacing,
          children: [
            spacer,
            SvgPicture.asset(
              Assets.layoutPanelLeftIcon,
              colorFilter: svgColorFilter,
            ),
            Text(l10n.demo),
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
              ArpDrawer<String>(
                onItemSelected: (page) {
                  _selectedPage = page;
                  setState(() {});
                },
                items: drawerItems,
              ),
              Expanded(child: pages[_selectedPage]!),
            ],
          );
        }
        return Scaffold(
          drawer: SizedBox(
            width: 300,
            child: ArpDrawer<String>(
              onItemSelected: (page) {
                _selectedPage = page;
                setState(() {});
                Get.back();
              },
              items: drawerItems,
            ),
          ),
          body: pages[_selectedPage],
        );
      }),
    );
  }
}

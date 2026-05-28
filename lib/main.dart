import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:shader_graph_example/assets.dart' as shader_graph_example;
import 'package:responsive_framework/responsive_framework.dart';
import 'package:global_repository/global_repository.dart';
import 'package:file_manager/file_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'modules/video_player/video_player_page.dart';
import 'modules/flash_rom/flash_rom_dialog.dart';
import 'modules/info_overlay/info_overlay.dart';
import 'modules/terminal/terminal_page.dart';
import 'modules/setting/setting.dart';
import 'generated/app_localizations.dart';
import 'services/services.dart';
import 'modules/demo/demo_page.dart';
import 'widgets/widgets.dart';

// import 'theme/apple_theme.dart';
// import 'theme/aurora_theme.dart';
// import 'theme/binance_theme.dart';
// import 'theme/coinbase_theme.dart';
// import 'theme/ferrari_theme.dart';
import 'theme/linear_theme.dart';
// import 'theme/notion_theme.dart';
// import 'theme/nvidia_theme.dart';
// import 'theme/sentry_theme.dart';
// import 'theme/shopify_theme.dart';
// import 'theme/spacex_theme.dart';
// import 'theme/spotify_theme.dart';
// import 'theme/stripe_theme.dart';
// import 'theme/supabase_theme.dart';
// import 'theme/tesla_theme.dart';
// import 'theme/vercel_theme.dart';
// import 'theme/warp_theme.dart';

import 'wifi/wifi_page.dart';
import 'common/assets.dart';
import 'common/l10n.dart';
import 'drawer.dart';

Future<void> main() async {
  int port = await FileServerService.instance.start();
  Log.i('File server started on port: $port');
  FMController controller = FMController();
  controller.setPort(port);
  controller.enterHomeDir();
  Get.put(controller);
  Config.initPackageMode();
  shader_graph_example.Assets.initPackages();
  runApp(const AuroraRecoveryApp());
  initArp();
}

void initArp() {
  DeviceInfoService.instance.init();
  SettingService.instance.init();
  final scripts = ['color_print', 'cmatrix', 'nettest', 'curl'];
  for (final script in scripts) {
    rootBundle.load('assets/executable/$script').then((data) {
      final bytes = data.buffer.asUint8List();
      final file = File('/tmp/$script');
      file.writeAsBytes(bytes).then((_) {
        Log.i('Copied $script to /tmp/$script');
        // set executable
        Process.run('chmod', ['+x', '/tmp/$script']).then((result) {
          Log.i('Set executable exitCode: ${result.exitCode}');
        });
      });
    });
  }
  // 'echo "nameserver 223.5.5.5" > /etc/resolv.conf'
  File('/etc/resolv.conf').writeAsString('nameserver 223.5.5.5');
}

bool showPerformanceOverlay = false;

class AuroraRecoveryApp extends StatefulWidget {
  const AuroraRecoveryApp({super.key});

  @override
  State<AuroraRecoveryApp> createState() => _AuroraRecoveryAppState();
}

class _AuroraRecoveryAppState extends State<AuroraRecoveryApp> with WidgetsBindingObserver {
  static const Duration _idleTimeout = Duration(seconds: kDebugMode ? 9999 : 10);
  static const Duration _fadeDuration = Duration(milliseconds: 250);
  static const double _targetTouchSlop = 8.0;

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
      theme: light,
      darkTheme: dark,
      // themeMode: ThemeMode.light,
      themeMode: ThemeMode.dark,
      localizationsDelegates: L10n.localizationsDelegates,
      supportedLocales: L10n.supportedLocales,
      locale: Locale('en'),
      builder: (context, child) {
        final mediaQuery = _withRecoveryGestureSettings(MediaQuery.of(context));
        return ResponsiveBreakpoints.builder(
          child: IdleDimmer(
            idleTimeout: _idleTimeout,
            fadeDuration: _fadeDuration,
            opacity: 0.2,
            onDimmedChanged: (isDimmed) {
              Log.i("Screen dimmed: $isDimmed");
              if (isDimmed) {
                SettingInstance.brightnessPct = 0;
                SettingInstance.ffi.tw_display_set_brightness_percent(SettingInstance.brightnessPct);
                setState(() {});
              } else {
                SettingInstance.brightnessPct = 100;
                SettingInstance.ffi.tw_display_set_brightness_percent(SettingInstance.brightnessPct);
                setState(() {});
              }
            },
            child: TouchIndicatorOverlay(
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
                  top: ResponsiveBreakpoints.of(context).isMobile,
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
      body: Stack(
        alignment: Alignment.center,
        children: [
          Builder(
            builder: (context) {
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
            },
          ),
          DeviceInfoOverlay(),
        ],
      ),
    );
  }
}

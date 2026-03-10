import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:xterm/xterm.dart';

import 'animation_demo/animation_demo.dart';
import 'drawer.dart';
import 'heavy_demo/heavy_ui_demo.dart';
import 'muitifinger/muitifinger.dart';
import 'setting/setting.dart';
import 'shader_demo/shader_demo.dart';
import 'terminal/terminal_page.dart';
import 'theme.dart';
import 'theme_preview/theme_preview.dart';
import 'video_player/video_player_page.dart';
import 'wlan/wlan_page.dart';

class AuroraRecoveryApp extends StatelessWidget {
  const AuroraRecoveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'xterm.dart demo',
      debugShowCheckedModeBanner: false,
      // showPerformanceOverlay: true,
      theme: lightTheme.copyWith(
        textTheme: lightTheme.textTheme.apply(
          fontFamily: 'NotoSansCJK',
        ),
      ),
      builder: (context, child) {
        return ResponsiveBreakpoints.builder(
          child: child!,
          landscapePlatforms: ResponsiveTargetPlatform.values,
          breakpoints: const [
            Breakpoint(start: 0, end: 500, name: MOBILE),
            Breakpoint(start: 500, end: 800, name: TABLET),
            Breakpoint(start: 800, end: double.infinity, name: DESKTOP),
          ],
          breakpointsLandscape: [
            const Breakpoint(start: 0, end: 450, name: MOBILE),
            const Breakpoint(start: 451, end: 800, name: TABLET),
            const Breakpoint(start: 801, end: double.infinity, name: DESKTOP),
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
  // ignore: library_private_types_in_public_api
  _AuroraRecoveryRootState createState() => _AuroraRecoveryRootState();
}

class _AuroraRecoveryRootState extends State<AuroraRecoveryRoot> {
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Builder(builder: (context) {
        final data = ResponsiveBreakpoints.of(context);
        if (data.isDesktop) {
          return Row(
            children: [
              ArpDrawer<int>(
                onItemSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                items: [
                  ArpDrawerItem(
                    value: 0,
                    groupValue: _selectedIndex,
                    child: Text('Theme'),
                  ),
                  ArpDrawerItem(
                    value: 1,
                    groupValue: _selectedIndex,
                    child: Text('着色器'),
                  ),
                  ArpDrawerItem(
                    value: 2,
                    groupValue: _selectedIndex,
                    child: Text('Heavy UI'),
                  ),
                  ArpDrawerItem(
                    value: 3,
                    groupValue: _selectedIndex,
                    child: Text('终端'),
                  ),
                  ArpDrawerItem(
                    value: 4,
                    groupValue: _selectedIndex,
                    child: Text('动画'),
                  ),
                  ArpDrawerItem(
                    value: 5,
                    groupValue: _selectedIndex,
                    child: Text('设置'),
                  ),
                  ArpDrawerItem(
                    value: 6,
                    groupValue: _selectedIndex,
                    child: Text('多点触控'),
                  ),
                  ArpDrawerItem(
                    value: 7,
                    groupValue: _selectedIndex,
                    child: Text('计数器'),
                  ),
                  ArpDrawerItem(
                    value: 8,
                    groupValue: _selectedIndex,
                    child: Text('视频'),
                  ),
                  ArpDrawerItem(
                    value: 9,
                    groupValue: _selectedIndex,
                    child: Text('WLAN'),
                  ),
                ],
              ),
              Expanded(
                child: [
                  ThemePreviewPage(),
                  ShaderDemo(),
                  HeavyUiHome(),
                  TerminalPage(),
                  AnimationDemo(),
                  SettingPage(),
                  MultiTouchPage(),
                  CounterApp(),
                  VideoPlayerPage(),
                  WlanPage(),
                ][_selectedIndex],
              ),
            ],
          );
        }
        return Scaffold(
          drawer: ArpDrawer<int>(
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: [
              ArpDrawerItem(
                value: 0,
                groupValue: _selectedIndex,
                child: Text('Theme'),
              ),
              ArpDrawerItem(
                value: 1,
                groupValue: _selectedIndex,
                child: Text('着色器'),
              ),
              ArpDrawerItem(
                value: 2,
                groupValue: _selectedIndex,
                child: Text('Heavy UI'),
              ),
              ArpDrawerItem(
                value: 3,
                groupValue: _selectedIndex,
                child: Text('终端'),
              ),
              ArpDrawerItem(
                value: 4,
                groupValue: _selectedIndex,
                child: Text('动画'),
              ),
              ArpDrawerItem(
                value: 5,
                groupValue: _selectedIndex,
                child: Text('设置'),
              ),
              ArpDrawerItem(
                value: 6,
                groupValue: _selectedIndex,
                child: Text('多点触控'),
              ),
              ArpDrawerItem(
                value: 7,
                groupValue: _selectedIndex,
                child: Text('计数器'),
              ),
              ArpDrawerItem(
                value: 8,
                groupValue: _selectedIndex,
                child: Text('视频'),
              ),
            ],
          ),
          body: [
            ThemePreviewPage(),
            ShaderDemo(),
            HeavyUiHome(),
            TerminalPage(),
            AnimationDemo(),
            SettingPage(),
            MultiTouchPage(),
            CounterApp(),
            VideoPlayerPage(),
          ][_selectedIndex],
        );
      }),
    );
  }
}

String get shell {
  if (Platform.isMacOS || Platform.isLinux) {
    return Platform.environment['SHELL'] ?? 'bash';
  }

  if (Platform.isWindows) {
    return 'cmd.exe';
  }

  return 'sh';
}

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CounterPage(),
    );
  }
}

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int _count = 0;

  void _increment() {
    setState(() {
      _count++;
    });
  }

  void _decrement() {
    setState(() {
      _count--;
    });
  }

  void _reset() {
    setState(() {
      _count = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Counter Demo"),
      ),
      body: Center(
        child: Text(
          '$_count',
          style: const TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: _increment,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            onPressed: _decrement,
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            onPressed: _reset,
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

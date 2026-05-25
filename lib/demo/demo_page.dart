import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:shader_graph_example/main.dart' as shader_demo;
import 'package:responsive_framework/responsive_framework.dart';
// ignore: depend_on_referenced_packages
import 'package:global_repository/global_repository.dart';

import 'package:aurora_recovery/demo/heavy_demo/heavy_ui_demo.dart';
import 'package:aurora_recovery/demo/muitifinger/muitifinger.dart';
import 'package:aurora_recovery/common/l10n.dart';
import 'package:aurora_recovery/widgets/fake_safearea.dart';

import 'animation_demo/animation_demo.dart';
import 'theme_preview/theme_preview.dart';

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  String _selectedTab = l10n.theme_preview;
  final tabs = [
    l10n.theme_preview,
    l10n.shader,
    l10n.heavy_ui,
    l10n.animation,
    l10n.multi_finger,
    l10n.counter,
  ];

  final pages1 = [
    ThemePreviewPage(),
    shader_demo.RootPage(),
    HeavyUiHome(),
    AnimationDemo(),
    MultiTouchPage(),
    CounterPage(),
  ];
  @override
  Widget build(BuildContext context) {
    // RootPage 不需要这个是因为内部的 CupertinoSlidingSegmentedControl 上层有 CupertinoNavigationBar
    // RootPage not need this because the CupertinoSlidingSegmentedControl inside has a CupertinoNavigationBar above it
    final segmentedLabelColor = CupertinoDynamicColor.resolve(CupertinoColors.label, context);

    return Scaffold(
      backgroundColor: CupertinoDynamicColor.resolve(CupertinoColors.systemBackground, context),
      body: FakeSafearea(
        top: ResponsiveBreakpoints.of(context).isMobile,
        child: CupertinoTheme(
          data: CupertinoThemeData(
            brightness: Theme.of(context).brightness,
            primaryColor: Theme.of(context).colorScheme.primary,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: $(12),
            children: [
              Row(
                spacing: $(8),
                children: [
                  SizedBox(width: $(8)),
                  IconButton(
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    icon: Icon(
                      Icons.menu,
                      size: $(24),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: CupertinoSlidingSegmentedControl<int>(
                          groupValue: tabs.indexOf(_selectedTab),
                          proportionalWidth: true,
                          onValueChanged: (int? value) {
                            if (value != null) {
                              _selectedTab = tabs[value];
                              setState(() {});
                            }
                          },
                          children: {
                            for (var i = 0; i < tabs.length; i++)
                              i: Text(
                                tabs[i],
                                style: TextStyle(color: segmentedLabelColor),
                              ),
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(child: pages1[tabs.indexOf(_selectedTab)]),
            ],
          ),
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          '$_count',
          style: TextStyle(
            fontSize: $(60),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: $(12),
        children: [
          FloatingActionButton(
            onPressed: () {
              _count++;
              setState(() {});
            },
            child: Icon(Icons.add, size: $(24)),
          ),
          FloatingActionButton(
            onPressed: () {
              _count--;
              setState(() {});
            },
            child: Icon(Icons.remove, size: $(24)),
          ),
          FloatingActionButton(
            onPressed: () {
              _count = 0;
              setState(() {});
            },
            child: Icon(Icons.refresh, size: $(24)),
          ),
        ],
      ),
    );
  }
}

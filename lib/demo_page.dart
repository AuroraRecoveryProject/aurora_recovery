import 'package:aurora_recovery/widgets/view_metric.dart';
import 'package:example/main.dart' as shader_demo;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'demo/animation_demo/animation_demo.dart';
import 'widgets/fake_safearea.dart';
import 'demo/heavy_demo/heavy_ui_demo.dart';
import 'demo/muitifinger/muitifinger.dart';
// import 'demo/shader_demo/shader_demo.dart';
import 'demo/theme_preview/theme_preview.dart';

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  String _selectedTab = 'Theme';
  final tabs = [
    'Theme',
    '着色器',
    'Heavy UI',
    '动画',
    '多点触控',
    '计数器',
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
    return Scaffold(
      body: FakeSafearea(
        top: ResponsiveBreakpoints.of(context).isMobile,
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
                  child: CupertinoSlidingSegmentedControl<int>(
                    groupValue: tabs.indexOf(_selectedTab),
                    onValueChanged: (int? value) {
                      if (value != null) {
                        setState(() {
                          _selectedTab = tabs[value];
                        });
                      }
                    },
                    children: {for (var i = 0; i < tabs.length; i++) i: Text(tabs[i])},
                  ),
                ),
              ],
            ),
            Expanded(child: pages1[tabs.indexOf(_selectedTab)]),
          ],
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

// ignore_for_file: must_be_immutable

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:signale/signale.dart';

class ViewMetric extends InheritedWidget {
  ViewMetric({
    super.key,
    required this.uiWidth,
    required super.child,
    required this.screenWidth,
    double longWidthScale = 1.0,
  }) {
    Log.i('ScreenQuery init -> uiWidth: $uiWidth, screenWidth: $screenWidth', 'ScreenQuery');
    if (uiWidth == 0) {
      return;
    }
    if (screenWidth > 1000) {
      // 第二显示器为 4K 的时候，
      // Android DPI: 213
      // devicePixelRatio: 1.331

      // 小米 pad 6s Pro信息:
      // PhysicalSize: Size(3048.0, 1992.0)
      // devicePixelRatio: 2.5
      // Android DPI: 400.0
      // DP Size.longestSide -> 1219.2(3048.0/2.5)
      // ignore: deprecated_member_use
      double devicePixelRatio = window.devicePixelRatio;
      double androidDPI = devicePixelRatio * 160;
      Log.i("screenWidth -> $screenWidth", 'ScreenQuery');
      Log.i("devicePixelRatio -> $devicePixelRatio", 'ScreenQuery');
      Log.i("Android DPI -> $androidDPI", 'ScreenQuery');
      // 这里其实就是不适配宽高了
      // 但是在 4K 显示器上，所有的 Size 看起来都会非常小
      // 可以参考 Windows 的缩放比例
      // 例如 1.25 1.5 1.75 2.0
      scale = longWidthScale;
      return;
    }
    scale = screenWidth / uiWidth;
    // cache 1 -> 64
    for (double i = 0; i <= 1000; i++) {
      _cache[i] = i * scale;
    }
  }

  static final Map<double, double> _cache = {};
  final double uiWidth;
  final double screenWidth;
  double scale = 1.0;

  @override
  bool updateShouldNotify(covariant ViewMetric oldWidget) {
    return oldWidget.scale != scale;
  }

  double v(num percent) {
    return screenWidth * (percent / 100.0);
  }

  double setWidth(num width) {
    // Log.i('scale -> $scale', tag: 'ScreenAdapter');
    return _cache[width.toDouble()] ?? (width.toDouble() * scale);
  }

  static ViewMetric of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType()!;
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ViewMetric(uiWidth: $uiWidth, screenWidth: $screenWidth, scale: $scale)';
  }
}

extension ViewMetricNumExt on num {
  double $(BuildContext context) => ViewMetric.of(context).setWidth(this);
}

extension ViewMetricStateExt on State {
  @Deprecated('Use w(num width) instead')
  double l(num width) => w(width);

  double w(num width) => ViewMetric.of(context).setWidth(width);

  double v(num percent) => ViewMetric.of(context).v(percent);

  double $(num width) => w(width);
}

extension ViewMetricContextExt on BuildContext {
  @Deprecated('Use w(num width) instead')
  double l(num width) => w(width);

  double w(num width) {
    return ViewMetric.of(this).setWidth(width);
  }

  double v(num percent) {
    return ViewMetric.of(this).v(percent);
  }
}

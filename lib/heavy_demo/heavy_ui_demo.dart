// =============================================================
// Heavy UI Demo — 故意制造 UI 线程负载，让 Performance Overlay 可视
// =============================================================

import 'dart:math';

import 'package:flutter/material.dart';

class HeavyUiHome extends StatefulWidget {
  const HeavyUiHome({super.key});
  @override
  State<HeavyUiHome> createState() => _HeavyUiHomeState();
}

class _HeavyUiHomeState extends State<HeavyUiHome> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _rng = Random(42);

  @override
  void initState() {
    super.initState();
    // 每帧都触发 rebuild
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // 每次 build 创建 200 个带阴影+变换+透明的卡片
  @override
  Widget build(BuildContext context) {
    final t = _ctrl.value;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1) 200 个随机定位、旋转、半透明的彩色卡片
          for (int i = 0; i < 200; i++)
            Positioned(
              left: (sin(t * 6.28 + i * 0.3) * 0.5 + 0.5) * (MediaQuery.of(context).size.width - 80),
              top: (cos(t * 6.28 + i * 0.5) * 0.5 + 0.5) * (MediaQuery.of(context).size.height - 120),
              child: Transform.rotate(
                angle: t * 6.28 + i * 0.1,
                child: Opacity(
                  opacity: 0.3 + 0.7 * ((sin(t * 12.56 + i) + 1) / 2),
                  child: Container(
                    width: 60 + (i % 40).toDouble(),
                    height: 40 + (i % 30).toDouble(),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(200, (i * 37) % 256, (i * 73 + 100) % 256, (i * 113 + 50) % 256),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: Colors.black54, blurRadius: 8 + (i % 10).toDouble(), offset: Offset(2, 2))
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$i',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10 + (i % 6).toDouble(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // 2) 叠加一个 CustomPainter 在上面
          Positioned.fill(child: CustomPaint(painter: _HeavyPainter(t))),
        ],
      ),
    );
  }
}

/// CustomPainter：每帧绘制 500 个圆 + 200 条线
class _HeavyPainter extends CustomPainter {
  final double t;
  _HeavyPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    // 500 个半透明圆
    for (int i = 0; i < 500; i++) {
      final x = (sin(t * 4 + i * 0.2) * 0.5 + 0.5) * size.width;
      final y = (cos(t * 3 + i * 0.15) * 0.5 + 0.5) * size.height;
      final r = 3.0 + (i % 15);
      paint.color = Color.fromARGB(80, (i * 47) % 256, (i * 83) % 256, (i * 131) % 256);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
    // 200 条线
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (int i = 0; i < 200; i++) {
      final x1 = (sin(t * 5 + i * 0.4) * 0.5 + 0.5) * size.width;
      final y1 = (cos(t * 7 + i * 0.3) * 0.5 + 0.5) * size.height;
      final x2 = (sin(t * 3 + i * 0.25 + 1) * 0.5 + 0.5) * size.width;
      final y2 = (cos(t * 4 + i * 0.35 + 2) * 0.5 + 0.5) * size.height;
      paint.color = Color.fromARGB(60, 255, 255, (i * 3) % 256);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeavyPainter old) => true;
}

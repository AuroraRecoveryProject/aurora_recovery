import 'package:flutter/material.dart' hide ViewMetric;
import 'package:global_repository/global_repository.dart';

class AnimationDemo extends StatelessWidget {
  const AnimationDemo({super.key});
  @override
  Widget build(BuildContext context) {
    final $ = context.$;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: $(24),
          children: [
            Text("Alyx is the best VR Game", style: TextStyle(fontSize: $(24), fontWeight: FontWeight.bold)),
            LoadingProgress(
              minRadius: $(10),
              strokeWidth: $(3),
              increaseRadius: $(4),
            ),
          ],
        ),
      ),
    );
  }
}

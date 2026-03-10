import 'package:flutter/material.dart';

class AnimationDemo extends StatelessWidget {
  const AnimationDemo({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 24,
          children: [
            Text("Flutter Animation Demo", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(width: 60, height: 60, child: CircularProgressIndicator(strokeWidth: 6)),
            SizedBox(width: 300, child: LinearProgressIndicator(minHeight: 10)),
          ],
        ),
      ),
    );
  }
}

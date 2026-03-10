import 'dart:developer';

import 'package:flutter/material.dart';

class MultiTouchPage extends StatefulWidget {
  const MultiTouchPage({super.key});

  @override
  State<MultiTouchPage> createState() => _MultiTouchPageState();
}

class _MultiTouchPageState extends State<MultiTouchPage> {
  final Map<int, Offset> _pointers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        onPointerDown: (event) {
          log("Pointer down: ID=${event.pointer}, Position=(${event.localPosition.dx}, ${event.localPosition.dy})");
          setState(() {
            _pointers[event.pointer] = event.localPosition;
          });
        },
        onPointerMove: (event) {
          // log("Pointer move: ID=${event.pointer}, Position=(${event.localPosition.dx}, ${event.localPosition.dy})");
          setState(() {
            _pointers[event.pointer] = event.localPosition;
          });
        },
        onPointerUp: (event) {
          log("Pointer up: ID=${event.pointer}, Position=(${event.localPosition.dx}, ${event.localPosition.dy})");
          setState(() {
            _pointers.remove(event.pointer);
          });
        },
        onPointerCancel: (event) {
          // log("Pointer cancel: ID=${event.pointer}, Position=(${event.localPosition.dx}, ${event.localPosition.dy})");
          setState(() {
            _pointers.remove(event.pointer);
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // 手指圆点
            ..._pointers.entries.map((entry) {
              return Positioned(
                left: entry.value.dx - 30,
                top: entry.value.dy - 30,
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      "ID: ${entry.key}\n(${entry.value.dx.toStringAsFixed(0)}, ${entry.value.dy.toStringAsFixed(0)})",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

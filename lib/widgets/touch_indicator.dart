import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class TouchIndicatorOverlay extends StatefulWidget {
  const TouchIndicatorOverlay({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<TouchIndicatorOverlay> createState() => _TouchIndicatorOverlayState();
}

class _TouchIndicatorOverlayState extends State<TouchIndicatorOverlay> {
  final Map<int, Offset> _pointers = {};

  void _update(PointerEvent event) {
    setState(() {
      if (event is PointerDownEvent || event is PointerMoveEvent || event is PointerHoverEvent) {
        _pointers[event.pointer] = event.position;
      } else if (event is PointerUpEvent || event is PointerCancelEvent || event is PointerRemovedEvent) {
        _pointers.remove(event.pointer);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _update,
      onPointerMove: _update,
      onPointerHover: _update,
      onPointerUp: _update,
      onPointerCancel: _update,
      child: Stack(
        children: [
          widget.child,
          IgnorePointer(
            child: Stack(
              children: _pointers.entries.map((entry) {
                final position = entry.value;
                return Positioned(
                  left: position.dx - 8,
                  top: position.dy - 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.withOpacity(0.5),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.6),
                        width: 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

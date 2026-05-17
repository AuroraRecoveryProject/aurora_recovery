import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'view_metric.dart';

// Copy from https://github.com/nightmare-space/global_repository

@Deprecated('Use Toast.show instead')
void showToast(
  String message, {
  Duration duration = const Duration(milliseconds: 1000),
}) {
  Toast.show(
    message,
    duration: duration,
  );
}

class ToastEntry {
  ToastEntry({required this.message});

  final String message;

  OverlayEntry build() {
    return OverlayEntry(
      builder: (context) {
        final width = MediaQuery.of(context).size.width;
        return Positioned(
          bottom: context.w(64),
          width: width,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(context.w(12)),
              child: Material(
                color: const Color(0xff303030),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(16),
                    vertical: context.w(8),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: context.w(16),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class Toast {
  static OverlayEntry? _current;

  static void show(
    String message, {
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final overlay = _rootOverlay;
      if (overlay == null) return;

      _current?.remove();

      final entry = ToastEntry(message: message).build();
      _current = entry;

      overlay.insert(entry);

      Future.delayed(duration).then((_) {
        Future.delayed(const Duration(milliseconds: 800), () {
          entry.remove();
          if (_current == entry) {
            _current = null;
          }
        });
      });
    });
  }

  static OverlayState? get _rootOverlay {
    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return null;

    OverlayState? overlay;

    void visitor(Element element) {
      if (element is StatefulElement && element.state is OverlayState) {
        overlay = element.state as OverlayState;
        return;
      }
      element.visitChildElements(visitor);
    }

    root.visitChildElements(visitor);
    return overlay;
  }
}

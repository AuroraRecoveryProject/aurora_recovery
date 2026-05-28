import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'twrp_keyboard.dart';

class VirtualKeyboard {
  static OverlayEntry? _current;

  static void show(void Function(String) onText) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final overlay = _rootOverlay;
      if (overlay == null) return;

      _current?.remove();

      final entry = OverlayEntry(builder: (context) {
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Material(
            child: TwrpKeyboard(
              mode: TwKeyboardMode.full,
              onText: (value) {
                // use utf8.encode to get the correct code units for non-ASCII characters
                final encoded = utf8.encode(value);
                onText(String.fromCharCodes(encoded));
              },
            ),
          ),
        );
      });
      _current = entry;
      overlay.insert(entry);
    });
  }

  static void hide() {
    _current?.remove();
    _current = null;
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

import 'package:flutter/services.dart';

class TwKey {
  final double units;
  final String label;
  final String? text;
  final String? longPressText;
  final LogicalKeyboardKey? logicalKey;
  final int? toLayout;

  const TwKey({
    required this.units,
    required this.label,
    this.text,
    this.longPressText,
    this.logicalKey,
    this.toLayout,
  });

  const TwKey.empty(this.units)
      : label = '',
        text = null,
        longPressText = null,
        logicalKey = null,
        toLayout = null;

  bool get isEmpty => label.isEmpty && text == null && logicalKey == null && toLayout == null;

  bool get isLayout => toLayout != null;

  bool get isText => (text ?? '').isNotEmpty;
}

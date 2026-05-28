import 'package:flutter/material.dart';

class TwKeyboardStyle {
  final Color bg;
  final Color keyAlphaBg;
  final Color keyOtherBg;
  final Color keyAlphaText;
  final Color keyOtherText;
  final Color longPressText;
  final Color highlight;
  final Color capsHighlight;
  final Color ctrlHighlight;
  final EdgeInsets keyMargin;
  final double height;

  const TwKeyboardStyle({
    this.bg = const Color(0xFF111111),
    this.keyAlphaBg = const Color(0xFF111111),
    this.keyOtherBg = const Color(0xFF111111),
    this.keyAlphaText = const Color(0xFFEEEEEE),
    this.keyOtherText = const Color(0xFF5B5B5B),
    this.longPressText = const Color(0xFF5B5B5B),
    this.highlight = const Color(0x66FFFFFF),
    this.capsHighlight = const Color(0x99FFFFFF),
    this.ctrlHighlight = const Color(0x800090CA),
    this.keyMargin = const EdgeInsets.all(4),
    this.height = 260,
  });
}

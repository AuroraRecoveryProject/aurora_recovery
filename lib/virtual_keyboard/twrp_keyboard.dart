import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'keyboard_layouts.dart';
import 'keyboard_style.dart';
import 'virtual_key.dart';

enum TwKeyboardMode { full, numeric }

class TwrpKeyboard extends StatefulWidget {
  final TwKeyboardMode mode;
  final TwKeyboardStyle style;
  final ValueChanged<String> onText;

  const TwrpKeyboard({
    super.key,
    required this.mode,
    required this.onText,
    this.style = const TwKeyboardStyle(),
  });

  @override
  State<TwrpKeyboard> createState() => TwrpKeyboardState();
}

class TwrpKeyboardState extends State<TwrpKeyboard> {
  int layout = 1;
  bool capsLockOn = false;
  bool ctrlActive = false;

  late final Future<KeyboardLayoutsModel> layoutsFuture;

  final Map<int, ({int row, int col})> pressedKeysByPointer = <int, ({int row, int col})>{};
  final Map<int, bool> longPressTriggeredByPointer = <int, bool>{};
  final Map<int, Timer> holdTimersByPointer = <int, Timer>{};
  final Map<int, Timer> repeatTimersByPointer = <int, Timer>{};

  static const longPressDelay = Duration(milliseconds: 420);
  static const repeatDelay = Duration(milliseconds: 70);

  static const ansiEsc = '\x1b';
  static final backspace = String.fromCharCode(127);

  @override
  void initState() {
    super.initState();
    layoutsFuture = KeyboardLayoutsModel.loadFromAsset();
  }

  @override
  void dispose() {
    for (final t in holdTimersByPointer.values) {
      t.cancel();
    }
    for (final t in repeatTimersByPointer.values) {
      t.cancel();
    }
    super.dispose();
  }

  void clearPressedKey(int pointer) {
    pressedKeysByPointer.remove(pointer);
    longPressTriggeredByPointer.remove(pointer);
  }

  static const Map<String, LogicalKeyboardKey> logicalKeyByName = {
    'controlLeft': LogicalKeyboardKey.controlLeft,
    'controlRight': LogicalKeyboardKey.controlRight,
    'escape': LogicalKeyboardKey.escape,
    'tab': LogicalKeyboardKey.tab,
    'arrowLeft': LogicalKeyboardKey.arrowLeft,
    'arrowDown': LogicalKeyboardKey.arrowDown,
    'arrowUp': LogicalKeyboardKey.arrowUp,
    'arrowRight': LogicalKeyboardKey.arrowRight,
    'backspace': LogicalKeyboardKey.backspace,
    'enter': LogicalKeyboardKey.enter,
    'numpadEnter': LogicalKeyboardKey.numpadEnter,
  };

  TwKey toTwKey(KeyboardKeyModel model) {
    final units = model.units;
    switch (model.type) {
      case 'empty':
        return TwKey.empty(units);
      case 'layout':
        final label = model.label;
        final to = model.to;
        if (label == null || label.isEmpty || to == null) return TwKey.empty(units);
        return TwKey(units: units, label: label, toLayout: to);
      case 'key':
        final label = model.label;
        final logicalName = model.logical;
        final logicalKey = logicalName == null ? null : logicalKeyByName[logicalName];
        if (label == null || label.isEmpty || logicalKey == null) return TwKey.empty(units);
        return TwKey(units: units, label: label, logicalKey: logicalKey);
      case 'text':
      default:
        final text = model.text;
        if (text == null || text.isEmpty) return TwKey.empty(units);
        final label = (model.label == null || model.label!.isEmpty) ? text : model.label!;
        return TwKey(units: units, label: label, text: text, longPressText: model.long);
    }
  }

  List<List<TwKey>> rows(KeyboardLayoutsModel layouts) {
    switch (widget.mode) {
      case TwKeyboardMode.numeric:
        return layouts.numeric.map((row) => row.map(toTwKey).toList(growable: false)).toList(growable: false);
      case TwKeyboardMode.full:
        final page = layouts.full['$layout'] ?? layouts.full['1'] ?? const <List<KeyboardKeyModel>>[];
        return page.map((row) => row.map(toTwKey).toList(growable: false)).toList(growable: false);
    }
  }

  void emit(String text) {
    if (text.isEmpty) return;
    widget.onText(text);
  }

  String? logicalKeyToAnsi(LogicalKeyboardKey? logicalKey) {
    if (logicalKey == null) return null;

    if (logicalKey == LogicalKeyboardKey.arrowLeft) return '$ansiEsc[D';
    if (logicalKey == LogicalKeyboardKey.arrowRight) return '$ansiEsc[C';
    if (logicalKey == LogicalKeyboardKey.arrowUp) return '$ansiEsc[A';
    if (logicalKey == LogicalKeyboardKey.arrowDown) return '$ansiEsc[B';

    return null;
  }

  int charToCtrl(int code) {
    if (code >= 65 && code <= 127 && code != 96) return code & 0x1f;
    return code;
  }

  bool canRepeat(TwKey key) {
    if (key.logicalKey == LogicalKeyboardKey.backspace) return true;
    if (logicalKeyToAnsi(key.logicalKey) != null) return true;
    return false;
  }

  void startHold(int pointer, TwKey key) {
    stopHold(pointer);
    longPressTriggeredByPointer[pointer] = false;

    holdTimersByPointer[pointer] = Timer(longPressDelay, () async {
      if (!mounted) return;

      if (key.longPressText != null && key.longPressText!.isNotEmpty) {
        longPressTriggeredByPointer[pointer] = true;
        await HapticFeedback.selectionClick();
        emit(key.longPressText!);
        return;
      }

      if (canRepeat(key)) {
        longPressTriggeredByPointer[pointer] = true;
        startRepeat(pointer, key);
      }
    });
  }

  void startRepeat(int pointer, TwKey key) {
    if (!canRepeat(key)) return;
    repeatTimersByPointer[pointer]?.cancel();
    repeatTimersByPointer[pointer] = Timer.periodic(repeatDelay, (_) {
      if (!mounted) return;
      if (key.logicalKey == LogicalKeyboardKey.backspace) {
        emit(backspace);
      }

      final seq = logicalKeyToAnsi(key.logicalKey);
      if (seq != null) emit(seq);
    });
  }

  void stopHold(int pointer) {
    holdTimersByPointer.remove(pointer)?.cancel();
    repeatTimersByPointer.remove(pointer)?.cancel();
  }

  Future<void> onTapKey(TwKey key) async {
    if (key.isEmpty) return;
    await HapticFeedback.selectionClick();

    if (isShiftKey(key) && widget.mode == TwKeyboardMode.full) {
      if (capsLockOn) {
        capsLockOn = false;
        layout = 1;
      } else if (layout == 2) {
        capsLockOn = true;
      } else {
        layout = 2;
        capsLockOn = false;
      }
      setState(() {});
      return;
    }

    if (key.isLayout && widget.mode == TwKeyboardMode.full) {
      capsLockOn = false;
      layout = key.toLayout ?? 1;
      setState(() {});
      return;
    }

    if (key.logicalKey != null) {
      final k = key.logicalKey;

      if (k == LogicalKeyboardKey.controlLeft || k == LogicalKeyboardKey.controlRight) {
        ctrlActive = !ctrlActive;
        setState(() {});
        return;
      }

      if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
        emit('\n');
        return;
      }

      if (k == LogicalKeyboardKey.backspace) {
        emit(backspace);
        return;
      }

      if (k == LogicalKeyboardKey.escape) {
        emit(String.fromCharCode(27));
        return;
      }

      if (k == LogicalKeyboardKey.tab) {
        emit('\t');
        return;
      }

      final seq = logicalKeyToAnsi(k);
      if (seq != null) {
        emit(seq);
        return;
      }
    }

    final out = key.text ?? '';
    if (out.isNotEmpty) {
      if (ctrlActive) {
        ctrlActive = false;
        final code = charToCtrl(out.codeUnitAt(0));
        emit(String.fromCharCode(code));
        setState(() {});
      } else {
        emit(out);
      }

      if (widget.mode == TwKeyboardMode.full && layout == 2 && !capsLockOn) {
        layout = 1;
        setState(() {});
      }
    }
  }

  bool isHighlighted(int row, int col) {
    for (final p in pressedKeysByPointer.values) {
      if (p.row == row && p.col == col) return true;
    }
    return false;
  }

  bool isShiftKey(TwKey key) => key.isLayout && key.label == 'Shift';

  // Shift 锁定状态：全键盘模式，当前是 Shift 页，且 Caps Lock 已经打开
  bool isShiftLatched() => widget.mode == TwKeyboardMode.full && layout == 2 && capsLockOn;

  // Shift 活跃状态：全键盘模式，且当前是 Shift 页（不管 Caps Lock 状态）
  bool isShiftActive() => widget.mode == TwKeyboardMode.full && layout == 2;

  bool isCtrlKeyActive(TwKey key) {
    return (key.logicalKey == LogicalKeyboardKey.controlLeft || key.logicalKey == LogicalKeyboardKey.controlRight) && ctrlActive;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = widget.mode == TwKeyboardMode.full ? widget.style.height + 72.0 : widget.style.height;

        return FutureBuilder<KeyboardLayoutsModel>(
          future: layoutsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Container(width: width, height: height, color: widget.style.bg);
            }
            if (!snapshot.hasData) {
              return Container(width: width, height: height, color: widget.style.bg);
            }

            final rows = this.rows(snapshot.data!);
            return Container(
              width: width,
              height: height,
              color: widget.style.bg,
              child: Column(
                children: List.generate(rows.length, (rowIndex) {
                  final row = rows[rowIndex];
                  return Expanded(
                    child: Row(
                      children: List.generate(row.length, (colIndex) {
                        final key = row[colIndex];
                        return Expanded(
                          flex: (key.units * 100).round(),
                          child: Padding(
                            padding: widget.style.keyMargin,
                            child: buildKey(key, rowIndex, colIndex),
                          ),
                        );
                      }, growable: false),
                    ),
                  );
                }, growable: false),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildKey(TwKey key, int row, int col) {
    final highlighted = isHighlighted(row, col);
    final ctrlKeyActive = isCtrlKeyActive(key);

    Color bg = key.isText ? widget.style.keyAlphaBg : widget.style.keyOtherBg;
    if (isShiftKey(key) && isShiftActive()) {
      bg = isShiftLatched() ? widget.style.capsHighlight : widget.style.highlight;
    }
    if (ctrlKeyActive) bg = widget.style.ctrlHighlight;
    if (highlighted) bg = widget.style.highlight;

    final isAlpha = key.isText && ((key.text?.codeUnitAt(0) ?? 0) >= 32);
    final textColor = isAlpha ? widget.style.keyAlphaText : widget.style.keyOtherText;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        // print('Key pressed: ${key.label}, logical: ${key.logicalKey}, text: ${key.text}');
        pressedKeysByPointer[event.pointer] = (row: row, col: col);
        setState(() {});
        startHold(event.pointer, key);
      },
      onPointerCancel: (event) {
        stopHold(event.pointer);
        clearPressedKey(event.pointer);
        setState(() {});
      },
      onPointerUp: (event) {
        stopHold(event.pointer);
        final longPressTriggered = longPressTriggeredByPointer[event.pointer] ?? false;
        if (!longPressTriggered) onTapKey(key);
        clearPressedKey(event.pointer);
        setState(() {});
      },
      child: Container(
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Stack(
          children: [
            Center(
              child: Text(
                key.label,
                style: TextStyle(
                  color: textColor,
                  fontSize: key.isText ? 20 : 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if ((key.longPressText ?? '').isNotEmpty)
              Positioned(
                right: 8,
                top: 4,
                child: Text(
                  key.longPressText!,
                  style: TextStyle(color: widget.style.longPressText, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

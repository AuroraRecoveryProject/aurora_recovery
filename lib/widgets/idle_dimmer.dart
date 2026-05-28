import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class IdleDimmer extends StatefulWidget {
  const IdleDimmer({
    super.key,
    required this.child,
    this.idleTimeout = const Duration(seconds: kDebugMode ? 30 : 10),
    this.fadeDuration = const Duration(milliseconds: 250),
    this.opacity = 0,
    this.onDimmedChanged,
  });

  final Widget child;
  final Duration idleTimeout;
  final Duration fadeDuration;
  final double opacity;
  final ValueChanged<bool>? onDimmedChanged;

  @override
  State<IdleDimmer> createState() => _IdleDimmerState();
}

class _IdleDimmerState extends State<IdleDimmer> {
  Timer? _idleTimer;
  bool _isDimmed = false;

  @override
  void initState() {
    super.initState();
    _restartIdleTimer();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  void _restartIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(widget.idleTimeout, _dimScreen);
  }

  void _dimScreen() {
    if (!mounted || _isDimmed) {
      return;
    }
    _isDimmed = true;
    setState(() {});
    widget.onDimmedChanged?.call(true);
  }

  void _handlePointerActivity(PointerEvent event) {
    if (event is! PointerDownEvent && event is! PointerMoveEvent && event is! PointerPanZoomStartEvent) {
      return;
    }

    _restartIdleTimer();

    if (!_isDimmed) {
      return;
    }

    _isDimmed = false;
    setState(() {});
    widget.onDimmedChanged?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerActivity,
      onPointerMove: _handlePointerActivity,
      onPointerPanZoomStart: _handlePointerActivity,
      child: AbsorbPointer(
        absorbing: _isDimmed,
        child: AnimatedOpacity(
          duration: widget.fadeDuration,
          opacity: _isDimmed ? widget.opacity : 1,
          child: widget.child,
        ),
      ),
    );
  }
}

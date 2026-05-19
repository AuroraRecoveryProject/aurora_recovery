# Recovery 触控 Slop 排查记录

## 背景

在 Android 正常模式下，`CupertinoSlidingSegmentedControl` 外包一层横向滚动容器时，横向拖动可以正常由外层滚动接管。

在 recovery 模式下，相同手势会被控件内部手势团队抢先拿到竞技场，表现为：

- 控件一直输出 `pressed-path`
- 外层横向滚动不接管
- 手势结束时只有 `onEnd`，没有正常模式里的 `onCancel`

这里的 `pressed-path` 不是 Flutter 官方术语，而是排查时加的调试日志标签，表示控件仍在走“内部按压高亮更新”路径，还没有被外层滚动取消。

## 排查目标

目标不是猜一个原因，而是把下面四件事确认清楚：

1. Flutter framework 收到的原始 pointer 序列是否正常
2. gesture arena 到底是谁先过阈值、谁先赢
3. 控件内部到底在走哪条更新路径
4. 正常 Android 和 recovery 的关键差异到底出现在什么层

## 日志加点位置

### 1. Flutter 原始 PointerEvent

在 `GestureBinding` 入口打印 framework 收到的原始 pointer 事件，确认 recovery 和正常 Android 的序列是否一致。

关键代码：

```dart
void _handlePointerEventImmediately(PointerEvent event) {
  assert(() {
    if (event is PointerDownEvent ||
        event is PointerMoveEvent ||
        event is PointerUpEvent ||
        event is PointerCancelEvent ||
        event is PointerAddedEvent ||
        event is PointerRemovedEvent) {
      final StringBuffer message = StringBuffer(
        'RAW_POINTER '
        'type=${event.runtimeType} '
        'pointer=${event.pointer} '
        'viewId=${event.viewId} '
        'embedderId=${event.embedderId} '
        'pos=${event.position} '
        'delta=${event.delta} '
        'buttons=${event.buttons} '
        'down=${event.down} '
        'kind=${event.kind} '
        'synth=${event.synthesized} '
        'time=${event.timeStamp.inMicroseconds}',
      );
      if (event is PointerMoveEvent) {
        message.write(' pressure=${event.pressure}');
      }
      debugPrint(message.toString());
    }
    return true;
  }());
    // Original code
}
```

### 2. Gesture Arena(arena.dart)

在 gesture arena 里打印 adding、accepting、rejecting、winner，确认最终是谁拿到竞技场。

关键代码：

```dart
bool _shouldLogMessage(String message) {
  return message.startsWith('★ Opening') ||
      message.startsWith('Adding:') ||
      message == 'Closing' ||
      message.startsWith('Accepting:') ||
      message.startsWith('Rejecting:') ||
      message.startsWith('Self-declared winner:') ||
      message.startsWith('Eager winner:') ||
      message == 'Sweeping' ||
      message.startsWith('Winner:') ||
      message.startsWith('Default winner:') ||
      message == 'Arena empty.' ||
      message == 'Holding' ||
      message == 'Releasing' ||
      message == 'Delaying sweep';
}
bool _debugLogDiagnostic(int pointer, String message, [_GestureArena? state]) {
  assert(() {
    if (debugPrintGestureArenaDiagnostics ||  _shouldLogMessage(message)) {
      final int? count = state?.members.length;
      final String s = count != 1 ? 's' : '';
      debugPrint(
        'Gesture arena ${pointer.toString().padRight(4)} ❙ $message${count != null ? " with $count member$s." : ""}${state != null ? " state=[$state]" : ""}',
      );
    }
    return true;
  }());
  return true;
}
```

实际观察时重点看这几类输出：

```text
Adding: ...
Accepting: ...
Rejecting: ...
Self-declared winner: ...
```

### 3. Drag 阈值与识别器身份

在 `monodrag.dart` 里打印每个 recognizer 的实例身份、当前累计位移、当前 slop、是否过阈值。

关键代码：

```dart
String _debugIdentity() {
  final Object? owner = debugOwner;
  return '${toStringShort()} owner=${owner ?? 'null'}';
}

double? _debugAcceptanceSlop(PointerDeviceKind kind) {
  switch (this) {
    case HorizontalDragGestureRecognizer():
    case VerticalDragGestureRecognizer():
      return computeHitSlop(kind, gestureSettings);
    case PanGestureRecognizer():
      return computePanSlop(kind, gestureSettings);
  }
}

void _debugLog(String message) {
  assert(() {
    debugPrint('MONODRAG ${_debugIdentity()}: $message');
    return true;
  }());
}
```

以及：

```dart
void _addPointer(PointerEvent event) {
  _velocityTrackers[event.pointer] = velocityTrackerBuilder(event);
  switch (_state) {
    case _DragState.ready:
      _state = _DragState.possible;
      _initialPosition = OffsetPair(global: event.position, local: event.localPosition);
      _lastPosition = _initialPosition;
      _pendingDragOffset = OffsetPair.zero;
      _globalDistanceMoved = 0.0;
      _lastPendingEventTimestamp = event.timeStamp;
      _lastTransform = event.transform;
      // add line
      _debugLog(
        'addPointer pointer=${event.pointer} pos=${event.position} '
        'buttons=${event.buttons} kind=${event.kind} '
        'onlyOnThreshold=$onlyAcceptDragOnThreshold '
        'slop=${_debugAcceptanceSlop(event.kind)?.toStringAsFixed(3)}',
      );
      _checkDown();
    case _DragState.possible:
      break;
    case _DragState.accepted:
      resolve(GestureDisposition.accepted);
  }
}


@override
void handleEvent(PointerEvent event) {
  assert(_state != _DragState.ready);
  if (!event.synthesized &&
      (event is PointerDownEvent ||
          event is PointerMoveEvent ||
          event is PointerPanZoomStartEvent ||
          event is PointerPanZoomUpdateEvent)) {
    final Offset position = switch (event) {
      PointerPanZoomStartEvent() => Offset.zero,
      PointerPanZoomUpdateEvent() => event.pan,
      _ => event.localPosition,
    };
    _velocityTrackers[event.pointer]!.addPosition(event.timeStamp, position);
  }
  if (event is PointerMoveEvent && event.buttons != _initialButtons) {
    _giveUpPointer(event.pointer);
    return;
  }
  if ((event is PointerMoveEvent || event is PointerPanZoomUpdateEvent) &&
      _shouldTrackMoveEvent(event.pointer)) {
    final Offset delta = (event is PointerMoveEvent)
        ? event.delta
        : (event as PointerPanZoomUpdateEvent).panDelta;
    final Offset localDelta = (event is PointerMoveEvent)
        ? event.localDelta
        : (event as PointerPanZoomUpdateEvent).localPanDelta;
    final Offset position = (event is PointerMoveEvent)
        ? event.position
        : (event.position + (event as PointerPanZoomUpdateEvent).pan);
    final Offset localPosition = (event is PointerMoveEvent)
        ? event.localPosition
        : (event.localPosition + (event as PointerPanZoomUpdateEvent).localPan);
    _lastPosition = OffsetPair(local: localPosition, global: position);
    final Offset resolvedDelta = _resolveLocalDeltaForMultitouch(event.pointer, localDelta);
    switch (_state) {
      case _DragState.ready || _DragState.possible:
        _pendingDragOffset += OffsetPair(local: localDelta, global: delta);
        _lastPendingEventTimestamp = event.timeStamp;
        _lastTransform = event.transform;
        final Offset movedLocally = _getDeltaForDetails(localDelta);
        final Matrix4? localToGlobalTransform = event.transform == null
            ? null
            : Matrix4.tryInvert(event.transform!);
        _globalDistanceMoved +=
            PointerEvent.transformDeltaViaPositions(
              transform: localToGlobalTransform,
              untransformedDelta: movedLocally,
              untransformedEndPosition: localPosition,
            ).distance *
            (_getPrimaryValueFromOffset(movedLocally) ?? 1).sign;
        _debugLog(
          'move pointer=${event.pointer} state=$_state globalDistance=${_globalDistanceMoved.toStringAsFixed(3)} '
          'delta=$delta localDelta=$localDelta resolvedDelta=$resolvedDelta '
          'primary=${_getPrimaryValueFromOffset(movedLocally)} kind=${event.kind} '
          'slop=${_debugAcceptanceSlop(event.kind)?.toStringAsFixed(3)}',
        );
        if (hasSufficientGlobalDistanceToAccept(event.kind, gestureSettings?.touchSlop)) {
          _hasDragThresholdBeenMet = true;
          _debugLog(
            'threshold-met pointer=${event.pointer} globalDistance=${_globalDistanceMoved.toStringAsFixed(3)} '
            'acceptedPointers=$_acceptedActivePointers activePointer=$_activePointer '
            'slop=${_debugAcceptanceSlop(event.kind)?.toStringAsFixed(3)}',
          );
          if (_acceptedActivePointers.contains(event.pointer)) {
            _debugLog('threshold-met -> _checkDrag(${event.pointer})');
            _checkDrag(event.pointer);
          } else {
            _debugLog('threshold-met -> resolve(accepted) for pointer=${event.pointer}');
            resolve(GestureDisposition.accepted);
          }
        }
      case _DragState.accepted:
        _checkUpdate(
          sourceTimeStamp: event.timeStamp,
          delta: _getDeltaForDetails(resolvedDelta),
          primaryDelta: _getPrimaryValueFromOffset(resolvedDelta),
          globalPosition: position,
          localPosition: localPosition,
          pointer: event.pointer,
        );
    }
    _recordMoveDeltaForMultitouch(event.pointer, localDelta);
  }
  if (event case PointerUpEvent() || PointerCancelEvent() || PointerPanZoomEndEvent()) {
    _giveUpPointer(event.pointer);
  }
}
@override
void acceptGesture(int pointer) {
  assert(!_acceptedActivePointers.contains(pointer));
  _acceptedActivePointers.add(pointer);
  _activePointer = pointer;
  // add line
  _debugLog(
    'acceptGesture pointer=$pointer hasThreshold=$_hasDragThresholdBeenMet '
    'acceptedPointers=$_acceptedActivePointers activePointer=$_activePointer',
  );
  if (!onlyAcceptDragOnThreshold || _hasDragThresholdBeenMet) {
    _checkDrag(pointer);
  }
}

@override
void rejectGesture(int pointer) {
  // add line
  _debugLog(
    'rejectGesture pointer=$pointer state=$_state '
    'acceptedPointers=$_acceptedActivePointers activePointer=$_activePointer',
  );
  _giveUpPointer(pointer);
}
```

### 4. Cupertino 控件内部路径

在 `CupertinoSlidingSegmentedControl` 内部打印 `onDown`、`onUpdate`、`onCancel`、`onEnd`，区分控件到底在走哪条路径。

关键代码：

```dart
void _debugLog(String message) {
  assert(() {
    debugPrint('CupertinoSlidingSegmentedControl: $message');
    return true;
  }());
}

void onTapUp(TapUpDetails details) {
  // No gesture should interfere with an ongoing thumb drag.
  if (isThumbDragging) {
    _debugLog('onTapUp ignored because thumb drag is active');
    return;
  }

  final T segment = segmentForXPosition(details.localPosition.dx);
  onPressedChangedByGesture(null);
  _debugLog(
    'onTapUp dx=${details.localPosition.dx.toStringAsFixed(1)} '
    'segment=$segment groupValue=${widget.groupValue} highlighted=$highlighted',
  );
  if (segment != widget.groupValue && !widget.disabledChildren.contains(segment)) {
    widget.onValueChanged(segment);
  }
}

void onDown(DragDownDetails details) {
  final T touchDownSegment = segmentForXPosition(details.localPosition.dx);
  _startedOnSelectedSegment = touchDownSegment == highlighted;
  _startedOnDisabledSegment = widget.disabledChildren.contains(touchDownSegment);
  _debugLog(
    'onDown dx=${details.localPosition.dx.toStringAsFixed(1)} '
    'segment=$touchDownSegment highlighted=$highlighted groupValue=${widget.groupValue} '
    'startedOnSelected=$_startedOnSelectedSegment startedOnDisabled=$_startedOnDisabledSegment',
  );
  if (widget.disabledChildren.contains(touchDownSegment)) {
    return;
  }
  onPressedChangedByGesture(touchDownSegment);

  if (isThumbDragging) {
    _playThumbScaleAnimation(isExpanding: false);
  }
}

void onUpdate(DragUpdateDetails details) {
  // If drag gesture starts on disabled segment, no update needed.
  if (_startedOnDisabledSegment) {
    _debugLog('onUpdate ignored because drag started on disabled segment');
    return;
  }

  // If drag gesture starts on enabled segment and dragging on disabled segment,
  // no update needed.
  final T touchDownSegment = segmentForXPosition(details.localPosition.dx);
  if (widget.disabledChildren.contains(touchDownSegment)) {
    _debugLog('onUpdate ignored because current segment is disabled: $touchDownSegment');
    return;
  }
  if (isThumbDragging) {
    _debugLog(
      'onUpdate thumb-drag '
      'dx=${details.localPosition.dx.toStringAsFixed(1)} segment=$touchDownSegment '
      'highlighted=$highlighted groupValue=${widget.groupValue}',
    );
    onPressedChangedByGesture(touchDownSegment);
    onHighlightChangedByGesture(touchDownSegment);
  } else {
    final T? segment = _hasDraggedTooFar(details)
        ? null
        : segmentForXPosition(details.localPosition.dx);
    _debugLog(
      'onUpdate pressed-path '
      'dx=${details.localPosition.dx.toStringAsFixed(1)} segment=$segment '
      'highlighted=$highlighted groupValue=${widget.groupValue}',
    );
    onPressedChangedByGesture(segment);
  }
}

void onEnd(DragEndDetails details) {
  final T? pressed = this.pressed;
  _debugLog(
    'onEnd isThumbDragging=$isThumbDragging pressed=$pressed '
    'highlighted=$highlighted groupValue=${widget.groupValue}',
  );
  if (isThumbDragging) {
    _playThumbScaleAnimation(isExpanding: true);
    if (highlighted != widget.groupValue) {
      widget.onValueChanged(highlighted);
    }
  } else if (pressed != null) {
    onHighlightChangedByGesture(pressed);
    assert(pressed == highlighted);
    if (highlighted != widget.groupValue) {
      widget.onValueChanged(highlighted);
    }
  }

  onPressedChangedByGesture(null);
  _startedOnSelectedSegment = null;
}

void onCancel() {
  _debugLog(
    'onCancel isThumbDragging=$isThumbDragging highlighted=$highlighted '
    'groupValue=${widget.groupValue}',
  );
  if (isThumbDragging) {
    _playThumbScaleAnimation(isExpanding: true);
  }
  onPressedChangedByGesture(null);
  _startedOnSelectedSegment = null;
}
```

### 5. App 层 workaround

为了避免一开始就重编 engine，在应用根部直接覆写 `MediaQuery.gestureSettings`，把 recovery 下的 `touchSlop` 钳到 `8.0`。

关键代码：

```dart
static const double _targetTouchSlop = 8.0;

MediaQueryData _withRecoveryGestureSettings(MediaQueryData data) {
 final double? currentTouchSlop = data.gestureSettings.touchSlop;
 if (currentTouchSlop != null && currentTouchSlop <= _targetTouchSlop) {
  return data;
 }
 return data.copyWith(
  gestureSettings: const DeviceGestureSettings(touchSlop: _targetTouchSlop),
 );
}
```

并在根部打印最终生效值：

```dart
Log.i("当前 touchSlop: ${MediaQuery.of(context).gestureSettings.touchSlop}");
```

### 6. 正常 Android 的来源

正常 Android 下外层 scroll 能拿到 `slop=8`，本质上是 Flutter 视图拿到了系统提供的 touch slop，并最终通过 `MediaQuery.gestureSettings` 下发给 drag recognizer。

这份文档不展开底层平台传递细节，只保留在 Flutter 层能观察到的结果：

```text
MONODRAG HorizontalDragGestureRecognizer#ead7c ... slop=8.000
```

## 观察结果

### 1. Flutter 原始 PointerEvent 序列是完整的

`RAW_POINTER` 日志显示 recovery 和正常 Android 都能形成完整的：

```text
PointerAddedEvent
PointerDownEvent
PointerMoveEvent ...
PointerUpEvent
PointerRemovedEvent
```

结论：

- 不是 framework 层 pointer phase 错乱
- recovery 和正常 Android 的差异不在“有没有事件”，而在“这些事件如何驱动识别器跨阈值”

### 2. 正常 Android 有两条 horizontal，而且阈值不同

正常 Android 日志里，存在两条 `HorizontalDragGestureRecognizer`：

```text
MONODRAG HorizontalDragGestureRecognizer#ce21a ... slop=18.000
MONODRAG HorizontalDragGestureRecognizer#ead7c ... slop=8.000
```

随后 `slop=8` 的那条先过阈值：

```text
MONODRAG HorizontalDragGestureRecognizer#ead7c ... threshold-met ... slop=8.000
Gesture arena 1 ❙ Accepting: HorizontalDragGestureRecognizer#ead7c
CupertinoSlidingSegmentedControl: onCancel ...
```

结论：

- 外层 scroll 的 horizontal 拿到了更小的阈值
- 它比控件内部更早赢得竞技场
- 所以控件被正常 cancel，外层滚动接管成功

### 3. Recovery 两条 horizontal 都退回成了 18

recovery 日志里，两条 `HorizontalDragGestureRecognizer` 都是：

```bash
MONODRAG HorizontalDragGestureRecognizer#53590 ... slop=18.000
MONODRAG HorizontalDragGestureRecognizer#697da ... slop=18.000
```

随后先过阈值的是控件内部那条：

```bash
MONODRAG HorizontalDragGestureRecognizer#53590 ... threshold-met ... slop=18.000
Gesture arena 1 ❙ Accepting: Instance of '_CombiningGestureArenaMember'
```

这之后控件没有 `onCancel`，而是持续输出：

```bash
CupertinoSlidingSegmentedControl: onUpdate pressed-path ...
```

结论：

- recovery 下外层 scroll 不再拥有更小阈值优势
- 控件内部 recognizer 先过阈值并代表 team 抢到 arena
- 所以外层滚动不接管，控件一直停留在内部按压高亮更新路径

### 4. App 层强制 `touchSlop=8.0` 后，行为恢复正常

应用根部覆写 `MediaQuery.gestureSettings` 后，效果与正常 Android 一致。

验证结果：

- recovery 模式行为恢复正常
- 外层横向滚动重新接管
- 效果与 Android 正常模式一致

这一步非常关键，因为它直接说明：

- 问题核心确实是 `touchSlop` 传播缺失
- 不是控件本身实现错误
- 也不是必须依赖 pressure 才能解释当前现象

## 根因结论

### Android 正常模式下

```java
private void sendViewportMetricsToFlutter() {
  if (!isAttachedToFlutterEngine()) {
    Log.w(
        TAG,
        "Tried to send viewport metrics from Android to Flutter but this "
            + "FlutterView was not attached to a FlutterEngine.");
    return;
  }

  viewportMetrics.devicePixelRatio = getResources().getDisplayMetrics().density;
  viewportMetrics.physicalTouchSlop = ViewConfiguration.get(getContext()).getScaledTouchSlop();

  flutterEngine.getRenderer().setViewportMetrics(viewportMetrics);
}
```

embedder.cc 默认是给桌面端，桌面端直接命中

```dart
/// The distance a touch has to travel for the framework to be confident that
/// the gesture is a scroll gesture, or, inversely, the maximum distance that a
/// touch can travel before the framework becomes confident that it is not a
/// tap.
///
/// A total delta less than or equal to [kTouchSlop] is not considered to be a
/// drag, whereas if the delta is greater than [kTouchSlop] it is considered to
/// be a drag.
// This value was empirically derived. We started at 8.0 and increased it to
// 18.0 after getting complaints that it was too difficult to hit targets.
const double kTouchSlop = 18.0; // Logical pixels
```

recovery 用的 engine 是基于 embedder.h

```c
typedef struct {
  /// The size of this struct. Must be sizeof(FlutterWindowMetricsEvent).
  size_t struct_size;
  /// Physical width of the window.
  size_t width;
  /// Physical height of the window.
  size_t height;
  /// Scale factor for the physical screen.
  double pixel_ratio;
  /// Horizontal physical location of the left side of the window on the screen.
  size_t left;
  /// Vertical physical location of the top of the window on the screen.
  size_t top;
  /// Top inset of window.
  double physical_view_inset_top;
  /// Right inset of window.
  double physical_view_inset_right;
  /// Bottom inset of window.
  double physical_view_inset_bottom;
  /// Left inset of window.
  double physical_view_inset_left;
  /// The identifier of the display the view is rendering on.
  FlutterEngineDisplayId display_id;
  /// The view that this event is describing.
  int64_t view_id;
  // ⚠️  没有 touch_slop
} FlutterWindowMetricsEvent;
```

embedder.c 中 MakeViewportMetricsFromWindowMetrics 就无法将设备级 touch slop 传递到 Flutter 视图，最终导致 framework 只能回退到默认值 `kTouchSlop=18`。

最终导致外层 scroll 的 horizontal drag 从正常 Android 的 `slop=8` 退回到 framework 默认 `slop=18`，最终失去先于控件内部 recognizer 赢得 gesture arena 的机会。

更具体地说：

1. 正常 Android 能把设备级 touch slop 传到 Flutter 视图
2. framework 再通过 `MediaQuery.gestureSettings` 下发给 drag recognizer
3. recovery 环境下这份设备级 touch slop 没有进入当前 Flutter 视图
4. 所以 recovery 最终回退到 framework 默认 `kTouchSlop=18`

## 当前可行方案, 保留应用层 workaround

- 在 app 根部统一覆写 `MediaQuery.gestureSettings`
- 当 `touchSlop` 为空或大于 `8.0` 时，强制设为 `8.0`

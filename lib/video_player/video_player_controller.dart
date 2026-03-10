// video_player_controller.dart — 视频播放控制器

import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import 'video_player_bindings.dart';

class VideoPlayerController extends ChangeNotifier {
  static final VideoPlayerBindings _bindings = VideoPlayerBindings();

  Pointer<Void> _player = nullptr;
  ui.Image? _currentFrame;
  Timer? _frameTimer;
  bool _disposed = false;

  int _width = 0;
  int _height = 0;
  int _durationMs = 0;
  int _positionMs = 0;
  bool _isPlaying = false;
  double _fps = 30.0;

  ui.Image? get currentFrame => _currentFrame;
  int get width => _width;
  int get height => _height;
  int get durationMs => _durationMs;
  int get positionMs => _positionMs;
  bool get isPlaying => _isPlaying;
  bool get isInitialized => _player != nullptr;

  /// 打开视频文件
  Future<bool> open(String path) async {
    final pathPtr = path.toNativeUtf8();
    _player = _bindings.vpCreate(pathPtr);
    malloc.free(pathPtr);

    if (_player == nullptr) {
      print('[VideoPlayer] 打开失败: $path');
      return false;
    }

    _width = _bindings.vpGetWidth(_player);
    _height = _bindings.vpGetHeight(_player);
    _durationMs = _bindings.vpGetDurationMs(_player);
    _fps = _bindings.vpGetFps(_player);
    if (_fps <= 0) _fps = 30.0;

    print('[VideoPlayer] 打开成功: ${_width}x$_height, 时长: ${_durationMs}ms, 帧率: ${_fps}fps');
    notifyListeners();
    return true;
  }

  void play() {
    if (_player == nullptr) return;
    _bindings.vpPlay(_player);
    _isPlaying = true;
    _startFrameLoop();
    notifyListeners();
  }

  void pause() {
    if (_player == nullptr) return;
    _bindings.vpPause(_player);
    _isPlaying = false;
    _stopFrameLoop();
    notifyListeners();
  }

  void togglePlayPause() {
    if (_isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void seek(int positionMs) {
    if (_player == nullptr) return;
    _bindings.vpSeek(_player, positionMs);
  }

  void _startFrameLoop() {
    _frameTimer?.cancel();
    final intervalMs = (1000.0 / _fps).round();
    _frameTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      _pollFrame();
    });
  }

  void _stopFrameLoop() {
    _frameTimer?.cancel();
    _frameTimer = null;
  }

  void _pollFrame() {
    if (_disposed || _player == nullptr) return;

    // 检查播放状态
    _isPlaying = _bindings.vpIsPlaying(_player) != 0;
    if (!_isPlaying) {
      _stopFrameLoop();
      notifyListeners();
      return;
    }

    // 更新位置
    _positionMs = _bindings.vpGetPositionMs(_player);

    // 检查新帧
    if (_bindings.vpHasNewFrame(_player) == 0) return;

    final framePtr = _bindings.vpGetFrame(_player);
    if (framePtr == nullptr) return;

    // RGBA 像素数据 → ui.Image
    final byteCount = _width * _height * 4;
    final pixels = framePtr.asTypedList(byteCount);

    // 复制一份，因为底层缓冲会被下一帧覆盖
    final pixelsCopy = Uint8List.fromList(pixels);

    ui.decodeImageFromPixels(
      pixelsCopy,
      _width,
      _height,
      ui.PixelFormat.rgba8888,
      (ui.Image image) {
        if (_disposed) {
          image.dispose();
          return;
        }
        _currentFrame?.dispose();
        _currentFrame = image;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _stopFrameLoop();
    _currentFrame?.dispose();
    _currentFrame = null;

    if (_player != nullptr) {
      _bindings.vpDestroy(_player);
      _player = nullptr;
    }

    super.dispose();
  }
}

// FFI implementation for the official video_player platform API.
//
// This backend stays separate from TextureVideoPlayerPlatformBase because it
// does not use MethodChannel create(mode) or Flutter Texture IDs. It opens
// libvideo_player.so directly, pulls RGBA frames with vp_get_frame(), converts
// them with decodeImageFromPixels, and paints them with CustomPaint.

import 'dart:async';
import 'dart:ffi' hide Size;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:ffi/ffi.dart';

import 'package:aurora_recovery/generated/aurora_ffi_bindings.dart';

class FfiVideoPlayerPlatform extends VideoPlayerPlatform {
  FfiVideoPlayerPlatform._();

  static final FfiVideoPlayerPlatform instance = FfiVideoPlayerPlatform._();

  static final AuroraFfiBindings _bindings = AuroraFfiBindings(DynamicLibrary.open('libvideo_player.so'));

  static int _nextPlayerId = 1;
  static final Map<int, _FfiVideoPlayer> _players = {};
  // Extra metadata that official video_player does not expose on VideoEvent.
  static final Map<String, int> _bitrateByPath = {};
  static final Map<String, double> _fpsByPath = {};

  static int bitrateForPath(String path) {
    return _bitrateByPath[path] ?? 0;
  }

  static double fpsForPath(String path) {
    return _fpsByPath[path] ?? 0;
  }

  @override
  Future<void> init() async {
    final players = List<_FfiVideoPlayer>.of(_players.values);
    _players.clear();
    _bitrateByPath.clear();
    _fpsByPath.clear();
    for (final player in players) {
      player.dispose();
    }
  }

  @override
  Future<void> dispose(int playerId) async {
    _players.remove(playerId)?.dispose();
  }

  @override
  Future<int?> create(DataSource dataSource) {
    return createWithOptions(
      VideoCreationOptions(
        dataSource: dataSource,
        viewType: VideoViewType.textureView,
      ),
    );
  }

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final path = _pathForDataSource(options.dataSource);
    if (path == null || path.isEmpty) {
      throw ArgumentError('Video player only supports file sources.');
    }

    // Open the video file through the Recovery native player and keep the
    // handle behind the official video_player platform interface.
    final player = _FfiVideoPlayer(_bindings);
    final opened = player.open(path);
    final playerId = _nextPlayerId++;
    _players[playerId] = player;
    if (opened) {
      _bitrateByPath[path] = player.bitrateBps;
      _fpsByPath[path] = player.fps;
    }

    if (!opened) {
      player.openError = PlatformException(
        code: 'video_open_failed',
        message: 'Failed to open video: $path',
      );
    }

    return playerId;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    final player = _players[playerId];
    if (player == null) {
      return Stream<VideoEvent>.error(
        StateError('No Video player for id $playerId.'),
      );
    }

    scheduleMicrotask(() {
      final openError = player.openError;
      if (openError != null) {
        player.addError(openError);
        return;
      }
      player.emitInitialized();
    });
    return player.events;
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {
    _players[playerId]?.looping = looping;
  }

  @override
  Future<void> play(int playerId) async {
    _players[playerId]?.play();
  }

  @override
  Future<void> pause(int playerId) async {
    _players[playerId]?.pause();
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {
    _players[playerId]?.setVolume(volume);
  }

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    _players[playerId]?.seek(position);
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {
    // The current FFmpeg/AGM backend does not expose rate control yet.
  }

  @override
  Future<Duration> getPosition(int playerId) async {
    return _players[playerId]?.position ?? Duration.zero;
  }

  @override
  Widget buildView(int playerId) {
    return buildViewWithOptions(VideoViewOptions(playerId: playerId));
  }

  @override
  Widget buildViewWithOptions(VideoViewOptions options) {
    final player = _players[options.playerId];
    if (player == null) {
      return const SizedBox.shrink();
    }
    return _FfiVideoView(player: player);
  }

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Future<void> setAllowBackgroundPlayback(bool allowBackgroundPlayback) async {}

  static String? _pathForDataSource(DataSource dataSource) {
    switch (dataSource.sourceType) {
      case DataSourceType.file:
        final uri = dataSource.uri;
        if (uri == null) return null;
        final parsed = Uri.tryParse(uri);
        if (parsed != null && parsed.scheme == 'file') {
          return parsed.toFilePath();
        }
        return Uri.decodeComponent(uri);
      case DataSourceType.contentUri:
      case DataSourceType.network:
      case DataSourceType.asset:
        return null;
    }
  }
}

class _FfiVideoPlayer extends ChangeNotifier {
  _FfiVideoPlayer(this._bindings);

  final AuroraFfiBindings _bindings;
  final StreamController<VideoEvent> _eventController = StreamController<VideoEvent>.broadcast();

  Pointer<VideoPlayerHandle> _handle = nullptr;
  ui.Image? _currentFrame;
  Timer? _frameTimer;
  Timer? _decodeWatchdog;
  bool _disposed = false;
  bool _decoding = false;
  bool _initializedEventSent = false;
  bool _isPlaying = false;
  bool _completed = false;
  bool looping = false;
  Object? openError;

  int _width = 0;
  int _height = 0;
  int _bitrateBps = 0;
  int _durationMs = 0;
  int _positionMs = 0;
  int _decodeGeneration = 0;
  int _decodeSerial = 0;
  int _activeDecodeSerial = 0;
  double _fps = 30.0;

  Stream<VideoEvent> get events => _eventController.stream;
  ui.Image? get currentFrame => _currentFrame;
  Duration get position => Duration(milliseconds: _positionMs);
  int get bitrateBps => _bitrateBps;
  double get fps => _fps;

  bool open(String path) {
    final pathPtr = path.toNativeUtf8();
    _handle = _bindings.vp_create(pathPtr.cast<Char>());
    malloc.free(pathPtr);

    if (_handle == nullptr) {
      return false;
    }

    _width = _bindings.vp_get_width(_handle);
    _height = _bindings.vp_get_height(_handle);
    _bitrateBps = _bindings.vp_get_bitrate_bps(_handle);
    _durationMs = _bindings.vp_get_duration_ms(_handle);
    _fps = _bindings.vp_get_fps(_handle);
    if (_fps <= 0) {
      _fps = 30.0;
    }
    setVolume(1.0);
    return true;
  }

  void emitInitialized() {
    if (_disposed || _initializedEventSent || _handle == nullptr) {
      return;
    }
    _initializedEventSent = true;
    _eventController.add(
      VideoEvent(
        eventType: VideoEventType.initialized,
        duration: Duration(milliseconds: _durationMs),
        size: ui.Size(_width.toDouble(), _height.toDouble()),
      ),
    );
  }

  void addError(Object error) {
    if (!_eventController.isClosed) {
      _eventController.addError(error);
    }
  }

  void play() {
    if (_disposed || _handle == nullptr) {
      return;
    }
    if (_completed && !looping) {
      seek(Duration.zero);
    }
    _completed = false;
    _bindings.vp_play(_handle);
    _isPlaying = true;
    _eventController.add(
      VideoEvent(
        eventType: VideoEventType.isPlayingStateUpdate,
        isPlaying: true,
      ),
    );
    _startFrameLoop();
  }

  void pause() {
    if (_disposed || _handle == nullptr) {
      return;
    }
    _bindings.vp_pause(_handle);
    _isPlaying = false;
    _stopFrameLoop();
    _eventController.add(
      VideoEvent(
        eventType: VideoEventType.isPlayingStateUpdate,
        isPlaying: false,
      ),
    );
  }

  void seek(Duration position) {
    if (_disposed || _handle == nullptr) {
      return;
    }
    final targetMs = position.inMilliseconds.clamp(0, _durationMs).toInt();
    _decodeGeneration++;
    _decodeSerial++;
    _activeDecodeSerial = _decodeSerial;
    _decodeWatchdog?.cancel();
    _decodeWatchdog = null;
    _decoding = false;
    _completed = false;
    _bindings.vp_seek(_handle, targetMs);
    _positionMs = targetMs;
    notifyListeners();
  }

  void setVolume(double volume) {
    if (_disposed || _handle == nullptr) {
      return;
    }

    // Public AW88261 Linux driver exposes speaker volume as attenuation, not gain:
    // AW88261_MUTE_VOL = 90 * 8, where 0 means 0 dB attenuation and 720 means
    // about -90 dB, effectively near mute.
    //
    // References:
    // - aw88261.h: AW88261_MUTE_VOL is defined as 90 * 8.
    //   https://codebrowser.dev/linux/linux/sound/soc/codecs/aw88261.h.html
    // - aw88261.c: aw88261_dev_set_volume() clamps to AW88261_MUTE_VOL before
    //   converting the attenuation value to the hardware register value.
    //   https://codebrowser.dev/linux/linux/sound/soc/codecs/aw88261.c.html
    final clamped = math.max(0.0, math.min(1.0, volume));

    final int aw;
    if (clamped <= 0.0) {
      aw = 720;
    } else {
      // Treat `volume` as a linear amplitude multiplier and convert it to dB:
      // attenuationDb = -20 * log10(volume).
      //
      // The AW control uses 1/8 dB units, so multiply dB attenuation by 8:
      //   volume 1.00 -> 0 dB  -> aw 0
      //   volume 0.50 -> 6 dB  -> aw 48
      //   volume 0.25 -> 12 dB -> aw 96
      final attenuationDb = -20.0 * math.log(clamped) / math.ln10;
      aw = math.max(0, math.min(720, (attenuationDb * 8.0).round()));
    }

    _bindings.vp_set_aw_volume(_handle, aw);
  }

  void _startFrameLoop() {
    _frameTimer?.cancel();
    final targetFps = _fps > 60.0 ? 60.0 : _fps;
    final safeFps = targetFps < 1.0 ? 1.0 : targetFps;
    final intervalMs = (1000.0 / safeFps).round();
    _frameTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      _pollFrame();
    });
  }

  void _stopFrameLoop() {
    _frameTimer?.cancel();
    _frameTimer = null;
  }

  void _pollFrame() {
    if (_disposed || _handle == nullptr) {
      return;
    }

    // Keep the official controller position in sync with the native clock.
    _positionMs = _bindings.vp_get_position_ms(_handle);
    final nativePlaying = _bindings.vp_is_playing(_handle) != 0;
    if (_isPlaying && !nativePlaying) {
      if (looping && _durationMs > 0 && _positionMs >= _durationMs - 250) {
        seek(Duration.zero);
        _bindings.vp_play(_handle);
        return;
      }
      _isPlaying = false;
      _completed = _durationMs > 0 && _positionMs >= _durationMs - 250;
      _stopFrameLoop();
      _eventController.add(
        VideoEvent(
          eventType: VideoEventType.isPlayingStateUpdate,
          isPlaying: false,
        ),
      );
      if (_completed) {
        _eventController.add(
          VideoEvent(eventType: VideoEventType.completed),
        );
      }
      notifyListeners();
      return;
    }

    // Skip while the previous decodeImageFromPixels callback is still pending;
    // otherwise Dart can queue stale RGBA buffers faster than Flutter can
    // convert them into ui.Image objects.
    if (_decoding || _bindings.vp_has_new_frame(_handle) == 0) {
      return;
    }

    final framePtr = _bindings.vp_get_frame(_handle);
    if (framePtr == nullptr || _width <= 0 || _height <= 0) {
      return;
    }

    // Native keeps an RGBA read buffer for the latest decoded frame. The
    // current display path is still RGBA pointer -> typed list -> ui.Image.
    final byteCount = _width * _height * 4;
    final pixels = framePtr.asTypedList(byteCount);
    _decoding = true;
    final decodeGeneration = _decodeGeneration;
    final decodeSerial = ++_decodeSerial;
    _activeDecodeSerial = decodeSerial;
    _decodeWatchdog?.cancel();
    _decodeWatchdog = Timer(const Duration(milliseconds: 800), () {
      if (_activeDecodeSerial == decodeSerial && _decodeGeneration == decodeGeneration) {
        // Do not let one stuck image decode block all future frames.
        _decoding = false;
      }
    });

    ui.decodeImageFromPixels(
      pixels,
      _width,
      _height,
      ui.PixelFormat.rgba8888,
      (ui.Image image) {
        final isActiveDecode = _activeDecodeSerial == decodeSerial && _decodeGeneration == decodeGeneration;
        if (isActiveDecode) {
          _decodeWatchdog?.cancel();
          _decodeWatchdog = null;
        }
        if (_disposed || !isActiveDecode) {
          if (isActiveDecode) {
            _decoding = false;
          }
          image.dispose();
          return;
        }
        _decoding = false;
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
    _decodeWatchdog?.cancel();
    _decodeWatchdog = null;
    _currentFrame?.dispose();
    _currentFrame = null;
    if (_handle != nullptr) {
      _bindings.vp_destroy(_handle);
      _handle = nullptr;
    }
    _eventController.close();
    super.dispose();
  }
}

class _FfiVideoView extends StatelessWidget {
  const _FfiVideoView({required this.player});

  final _FfiVideoPlayer player;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: player,
      builder: (context, _) {
        final frame = player.currentFrame;
        if (frame == null) {
          return const Center(child: SizedBox.shrink());
        }
        return CustomPaint(
          painter: _FfiFramePainter(frame),
          size: ui.Size.infinite,
        );
      },
    );
  }
}

class _FfiFramePainter extends CustomPainter {
  _FfiFramePainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final fitted = applyBoxFit(
        src.size.width / src.size.height >= size.width / size.height ? BoxFit.fitWidth : BoxFit.fitHeight,
        src.size,
        size);
    final dst = Alignment.center.inscribe(fitted.destination, Offset.zero & size);
    canvas.drawImageRect(image, src, dst, Paint());
  }

  @override
  bool shouldRepaint(_FfiFramePainter oldDelegate) {
    return image != oldDelegate.image;
  }
}

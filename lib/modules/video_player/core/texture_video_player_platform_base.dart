import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'video_player_backend.dart';

class TextureVideoPlayerPlatformBase extends VideoPlayerPlatform {
  TextureVideoPlayerPlatformBase({
    required this.createMode,
    required this.openErrorCode,
    required this.openErrorMessage,
  });

  static const MethodChannel _channel = MethodChannel('aurora_texture_video');

  final String createMode;
  final String openErrorCode;
  final String openErrorMessage;
  final Map<int, TextureVideoPlayer> _players = {};
  final Map<String, TextureVideoMetadata> _metadataByPath = {};

  VideoInfo? metadataInfoForPath(String path) {
    final metadata = _metadataByPath[path];
    if (metadata == null) {
      return null;
    }
    return VideoInfo(
      fps: metadata.fps,
      bitrateBps: metadata.bitrateBps,
      fileSizeBytes: metadata.fileSizeBytes,
      videoCodec: metadata.videoCodec,
      audioCodec: metadata.audioCodec,
    );
  }

  @override
  Future<void> init() async {
    _players.clear();
    _metadataByPath.clear();
    await _channel.invokeMethod<void>('dispose');
  }

  @override
  Future<void> dispose(int playerId) async {
    final player = _players.remove(playerId);
    if (player == null) {
      return;
    }
    await player.dispose();
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
      throw ArgumentError('Texture video only supports file sources.');
    }

    final result = await _channel.invokeMapMethod<String, Object?>(
      'create',
      {'path': path, 'mode': createMode},
    );
    if (result == null) {
      throw PlatformException(
        code: openErrorCode,
        message: 'Native player returned no result.',
      );
    }

    final textureId = (result['textureId'] as num?)?.toInt();
    if (textureId == null) {
      throw PlatformException(
        code: openErrorCode,
        message: openErrorMessage,
      );
    }

    final metadata = TextureVideoMetadata.fromMap(result);
    _metadataByPath[path] = metadata;
    _players[textureId] = TextureVideoPlayer(
      platform: this,
      textureId: textureId,
      metadata: metadata,
    );
    await _channel.invokeMethod<void>('setAwVolume', {'awVolume': 120});
    return textureId;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    final player = _players[playerId];
    if (player == null) {
      return Stream<VideoEvent>.error(
        StateError('No Texture video player for id $playerId.'),
      );
    }

    scheduleMicrotask(player.emitInitialized);
    return player.events;
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {
    _players[playerId]?.looping = looping;
  }

  @override
  Future<void> play(int playerId) async {
    final player = _players[playerId];
    if (player == null) {
      return;
    }
    if (player.completed && !player.looping) {
      await _channel.invokeMethod<void>('seek', {'positionMs': 0});
    }
    await _channel.invokeMethod<void>('play');
    player.setPlaying(true);
  }

  @override
  Future<void> pause(int playerId) async {
    final player = _players[playerId];
    if (player == null) {
      return;
    }
    await _channel.invokeMethod<void>('pause');
    player.setPlaying(false);
  }

  @override
  Future<void> setVolume(int playerId, double volume) async {
    if (!_players.containsKey(playerId)) {
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

    await _channel.invokeMethod<void>(
      'setAwVolume',
      {'awVolume': aw},
    );
  }

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    final player = _players[playerId];
    if (player == null) {
      return;
    }
    final targetMs = position.inMilliseconds.clamp(0, player.metadata.duration.inMilliseconds).toInt();
    await _channel.invokeMethod<void>(
      'seek',
      {'positionMs': targetMs},
    );
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async {
    if (!_players.containsKey(playerId)) {
      return Duration.zero;
    }
    final positionMs = await _channel.invokeMethod<int>('position');
    return Duration(milliseconds: positionMs ?? 0);
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
    return Texture(textureId: player.textureId);
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

class TextureVideoPlayer {
  TextureVideoPlayer({
    required this.platform,
    required this.textureId,
    required this.metadata,
  });

  final TextureVideoPlayerPlatformBase platform;
  final int textureId;
  final TextureVideoMetadata metadata;
  final StreamController<VideoEvent> _events = StreamController<VideoEvent>.broadcast();
  Timer? _positionTimer;
  bool _initializedEventSent = false;
  bool _disposed = false;
  bool _isPlaying = false;
  bool _completed = false;
  bool looping = false;

  Stream<VideoEvent> get events => _events.stream;
  bool get completed => _completed;

  void emitInitialized() {
    if (_disposed || _initializedEventSent) {
      return;
    }
    _initializedEventSent = true;
    _events.add(
      VideoEvent(
        eventType: VideoEventType.initialized,
        duration: metadata.duration,
        size: ui.Size(
          metadata.width.toDouble(),
          metadata.height.toDouble(),
        ),
      ),
    );
  }

  void setPlaying(bool isPlaying) {
    if (_disposed) {
      return;
    }
    _isPlaying = isPlaying;
    if (isPlaying) {
      _completed = false;
      _startPositionMonitor();
    } else {
      _stopPositionMonitor();
    }
    _events.add(
      VideoEvent(
        eventType: VideoEventType.isPlayingStateUpdate,
        isPlaying: isPlaying,
      ),
    );
  }

  void _startPositionMonitor() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _checkCompletion();
    });
  }

  void _stopPositionMonitor() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  Future<void> _checkCompletion() async {
    if (_disposed || !_isPlaying || metadata.duration <= Duration.zero) {
      return;
    }
    final positionMs = await TextureVideoPlayerPlatformBase._channel.invokeMethod<int>('position');
    if (_disposed || !_isPlaying || positionMs == null) {
      return;
    }
    final durationMs = metadata.duration.inMilliseconds;
    if (positionMs < durationMs - 250) {
      return;
    }
    if (looping) {
      await TextureVideoPlayerPlatformBase._channel.invokeMethod<void>(
        'seek',
        {'positionMs': 0},
      );
      await TextureVideoPlayerPlatformBase._channel.invokeMethod<void>('play');
      return;
    }
    _completed = true;
    _isPlaying = false;
    _stopPositionMonitor();
    _events.add(
      VideoEvent(
        eventType: VideoEventType.isPlayingStateUpdate,
        isPlaying: false,
      ),
    );
    _events.add(VideoEvent(eventType: VideoEventType.completed));
  }

  Future<void> dispose() async {
    _disposed = true;
    _stopPositionMonitor();
    await TextureVideoPlayerPlatformBase._channel.invokeMethod<void>('dispose');
    await _events.close();
  }
}

class TextureVideoMetadata {
  const TextureVideoMetadata({
    required this.width,
    required this.height,
    required this.duration,
    required this.fps,
    required this.bitrateBps,
    required this.fileSizeBytes,
    required this.videoCodec,
    required this.audioCodec,
  });

  factory TextureVideoMetadata.fromMap(Map<String, Object?> map) {
    return TextureVideoMetadata(
      width: (map['width'] as num?)?.toInt() ?? 0,
      height: (map['height'] as num?)?.toInt() ?? 0,
      duration: Duration(
        milliseconds: (map['durationMs'] as num?)?.toInt() ?? 0,
      ),
      fps: (map['fps'] as num?)?.toDouble() ?? 0,
      bitrateBps: (map['bitrateBps'] as num?)?.toInt() ?? 0,
      fileSizeBytes: (map['fileSizeBytes'] as num?)?.toInt() ?? 0,
      videoCodec: (map['videoCodec'] as String?) ?? '',
      audioCodec: (map['audioCodec'] as String?) ?? '',
    );
  }

  final int width;
  final int height;
  final Duration duration;
  final double fps;
  final int bitrateBps;
  final int fileSizeBytes;
  final String videoCodec;
  final String audioCodec;
}

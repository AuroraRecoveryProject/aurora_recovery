import 'dart:async';
import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:global_repository/global_repository.dart';
import 'package:video_player/video_player.dart' as official;

import 'core/video_player_backend.dart';

class VideoPlayerWithControls extends StatefulWidget {
  const VideoPlayerWithControls({
    super.key,
    required this.backend,
    required this.videoPath,
  });

  final VideoPlayerBackend backend;
  final String videoPath;

  @override
  State<VideoPlayerWithControls> createState() => _VideoPlayerWithControlsState();
}

class _VideoPlayerWithControlsState extends State<VideoPlayerWithControls> {
  late final official.VideoPlayerController _videoController;
  ChewieController? _chewieController;
  Object? _error;
  Subtitles _subtitles = Subtitles(const []);

  @override
  void initState() {
    super.initState();
    widget.backend.registerPlatform();
    _videoController = official.VideoPlayerController.file(
      File(widget.videoPath),
    );
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _subtitles = await _loadSidecarSubtitles(widget.videoPath);
      await _videoController.initialize();
      if (!mounted) return;

      _chewieController = _createChewieController(autoPlay: true);

      setState(() {});

      final initialVolume = widget.backend.initialVolume;
      if (initialVolume != null) {
        await _videoController.setVolume(initialVolume);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }
  }

  Future<Subtitles> _loadSidecarSubtitles(String videoPath) async {
    final subtitleFile = File(_defaultSubtitlePath(videoPath));
    if (!await subtitleFile.exists()) {
      return Subtitles(const []);
    }

    final fileContents = await subtitleFile.readAsString();
    final captionFile = official.SubRipCaptionFile(fileContents);
    final subtitles = captionFile.captions
        .map(
          (caption) => Subtitle(
            index: caption.number,
            start: caption.start,
            end: caption.end,
            text: caption.text,
          ),
        )
        .toList(growable: false);
    return Subtitles(subtitles);
  }

  String _defaultSubtitlePath(String videoPath) {
    final extensionIndex = videoPath.lastIndexOf('.');
    final slashIndex = videoPath.lastIndexOf('/');
    if (extensionIndex > slashIndex) {
      return '${videoPath.substring(0, extensionIndex)}.srt';
    }
    return '$videoPath.srt';
  }

  Widget _buildSubtitle(BuildContext context, dynamic subtitle) {
    final text = subtitle.toString();
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 28),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xB8000000),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                height: 1.25,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  ChewieController _createChewieController({required bool autoPlay}) {
    return ChewieController(
      videoPlayerController: _videoController,
      autoPlay: autoPlay,
      looping: false,
      subtitle: _subtitles,
      showSubtitles: _subtitles.isNotEmpty,
      subtitleBuilder: _buildSubtitle,
      pauseOnBackgroundTap: true,
      allowFullScreen: false,
      customControls: const CupertinoControls(
        backgroundColor: Color.fromRGBO(41, 41, 41, 0.7),
        iconColor: Color.fromARGB(255, 200, 200, 200),
      ),
      hideControlsTimer: const Duration(seconds: 3),
    );
  }

  Future<void> _openFullscreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) {
          return _FullscreenVideoPlayer(
            backend: widget.backend,
            videoPath: widget.videoPath,
            videoController: _videoController,
            createChewieController: () => _createChewieController(autoPlay: false),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) {
      return Center(
        child: Text(
          '${widget.backend.openErrorTitle}\n$error',
          textAlign: TextAlign.center,
        ),
      );
    }

    final chewieController = _chewieController;
    if (chewieController == null || !_videoController.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return _PlayerSurface(
      backend: widget.backend,
      videoPath: widget.videoPath,
      videoController: _videoController,
      chewieController: chewieController,
      fullscreenIcon: Icons.fullscreen,
      onFullscreenPressed: _openFullscreen,
    );
  }
}

class _FullscreenVideoPlayer extends StatefulWidget {
  const _FullscreenVideoPlayer({
    required this.backend,
    required this.videoPath,
    required this.videoController,
    required this.createChewieController,
  });

  final VideoPlayerBackend backend;
  final String videoPath;
  final official.VideoPlayerController videoController;
  final ChewieController Function() createChewieController;

  @override
  State<_FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<_FullscreenVideoPlayer> {
  late final ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    _chewieController = widget.createChewieController();
  }

  @override
  void dispose() {
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _PlayerSurface(
          backend: widget.backend,
          videoPath: widget.videoPath,
          videoController: widget.videoController,
          chewieController: _chewieController,
          fullscreenIcon: Icons.fullscreen_exit,
          onFullscreenPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

class _PlayerSurface extends StatefulWidget {
  const _PlayerSurface({
    required this.backend,
    required this.videoPath,
    required this.videoController,
    required this.chewieController,
    required this.fullscreenIcon,
    required this.onFullscreenPressed,
  });

  final VideoPlayerBackend backend;
  final String videoPath;
  final official.VideoPlayerController videoController;
  final ChewieController chewieController;
  final IconData fullscreenIcon;
  final VoidCallback onFullscreenPressed;

  @override
  State<_PlayerSurface> createState() => _PlayerSurfaceState();
}

class _PlayerSurfaceState extends State<_PlayerSurface> {
  Timer? _volumeOverlayTimer;
  Timer? _infoOverlayTimer;
  bool _showVolumeOverlay = false;
  bool _showInfoOverlay = false;

  @override
  void dispose() {
    _volumeOverlayTimer?.cancel();
    _infoOverlayTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleVolumeDrag(double deltaDy, double dragAreaHeight) async {
    final height = dragAreaHeight <= 0 ? 1.0 : dragAreaHeight;
    final deltaVolume = -deltaDy / height;
    final nextVolume = (widget.videoController.value.volume + deltaVolume).clamp(
      0.0,
      1.0,
    );
    await widget.videoController.setVolume(nextVolume);
    if (!mounted) return;
    setState(() => _showVolumeOverlay = true);
    _volumeOverlayTimer?.cancel();
    _volumeOverlayTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() => _showVolumeOverlay = false);
      }
    });
  }

  void _showVideoInfo() {
    if (!mounted) return;
    setState(() => _showInfoOverlay = true);
    _infoOverlayTimer?.cancel();
    _infoOverlayTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showInfoOverlay = false);
      }
    });
  }

  void _hideVolumeOverlaySoon() {
    _volumeOverlayTimer?.cancel();
    _volumeOverlayTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() => _showVolumeOverlay = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _showVideoInfo(),
      child: Stack(
        children: [
          Chewie(controller: widget.chewieController),
          Positioned.fill(
            child: Row(
              children: [
                const Spacer(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onVerticalDragStart: (_) {
                          setState(() => _showVolumeOverlay = true);
                        },
                        onVerticalDragUpdate: (details) {
                          _handleVolumeDrag(
                            details.delta.dy,
                            constraints.maxHeight,
                          );
                        },
                        onVerticalDragEnd: (_) => _hideVolumeOverlaySoon(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 24,
            child: IconButton(
              icon: Icon(widget.fullscreenIcon),
              color: Colors.white,
              onPressed: widget.onFullscreenPressed,
            ),
          ),
          if (_showInfoOverlay)
            _VideoInfoOverlay(
              backend: widget.backend,
              controller: widget.videoController,
              videoPath: widget.videoPath,
            ),
          if (_showVolumeOverlay) _VolumeOverlay(volume: widget.videoController.value.volume),
        ],
      ),
    );
  }
}

class _VideoInfoOverlay extends StatelessWidget {
  const _VideoInfoOverlay({
    required this.backend,
    required this.controller,
    required this.videoPath,
  });

  final VideoPlayerBackend backend;
  final official.VideoPlayerController controller;
  final String videoPath;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final $ = context.$;
    final info = backend.infoForPath(videoPath);

    return Positioned(
      left: $(6),
      top: $(64),
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacityExact(0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: DefaultTextStyle(
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: $(12),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    backend.infoTitle,
                    style: TextStyle(
                      fontSize: $(14),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('File: ${_fileName(videoPath)}'),
                  Text(
                    'Duration: ${_formatDuration(controller.value.duration)}',
                  ),
                  Text(
                    'Resolution: ${_formatResolution(controller.value.size)}',
                  ),
                  Text('FPS: ${_formatFps(info.fps)}'),
                  Text('Bitrate: ${_formatBitrate(info.bitrateBps)}'),
                  if (backend.showsExtendedInfo) ...[
                    Text('Size: ${_formatBytes(info.fileSizeBytes)}'),
                    Text('Video: ${_dashIfEmpty(info.videoCodec)}'),
                    Text('Audio: ${_dashIfEmpty(info.audioCodec)}'),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _fileName(String path) {
    final slashIndex = path.lastIndexOf('/');
    if (slashIndex >= 0 && slashIndex < path.length - 1) {
      return path.substring(slashIndex + 1);
    }
    return path;
  }

  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  static String _formatResolution(Size size) {
    if (size == Size.zero) {
      return '-';
    }
    return '${size.width.round()}x${size.height.round()}';
  }

  static String _formatFps(double fps) {
    if (fps <= 0) {
      return '-';
    }
    return fps.toStringAsFixed(fps == fps.roundToDouble() ? 0 : 2);
  }

  static String _formatBitrate(int bitrateBps) {
    if (bitrateBps <= 0) {
      return '-';
    }
    if (bitrateBps >= 1000 * 1000) {
      return '${(bitrateBps / (1000 * 1000)).toStringAsFixed(2)} Mbps';
    }
    return '${(bitrateBps / 1000).toStringAsFixed(0)} kbps';
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) {
      return '-';
    }
    const units = ['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    return '${value.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
  }

  static String _dashIfEmpty(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }
    return value;
  }
}

class _VolumeOverlay extends StatelessWidget {
  const _VolumeOverlay({required this.volume});

  final double volume;

  @override
  Widget build(BuildContext context) {
    final percent = (volume * 100).round().clamp(0, 100);
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      right: 28,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacityExact(0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.volume_up, color: colorScheme.onSurface, size: 22),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 8,
                    height: 150,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withOpacityExact(0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: percent / 100,
                          widthFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colorScheme.onSurface,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$percent',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

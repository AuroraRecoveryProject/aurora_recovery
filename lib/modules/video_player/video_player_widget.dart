// video_player_widget.dart — 视频播放 Widget

import 'package:flutter/material.dart';

import 'video_player_controller.dart';

/// 视频画面渲染
class VideoPlayerView extends StatelessWidget {
  final VideoPlayerController controller;
  final BoxFit fit;

  const VideoPlayerView({
    super.key,
    required this.controller,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final frame = controller.currentFrame;
        if (frame == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return CustomPaint(
          painter: _VideoPainter(frame, fit),
          size: Size.infinite,
        );
      },
    );
  }
}

class _VideoPainter extends CustomPainter {
  final dynamic image; // ui.Image
  final BoxFit fit;

  _VideoPainter(this.image, this.fit);

  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) return;

    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final dst = _applyBoxFit(fit, src.size, size);

    canvas.drawImageRect(image, src, dst, Paint());
  }

  Rect _applyBoxFit(BoxFit fit, Size srcSize, Size dstSize) {
    final FittedSizes fitted = applyBoxFit(fit, srcSize, dstSize);
    final double dx = (dstSize.width - fitted.destination.width) / 2;
    final double dy = (dstSize.height - fitted.destination.height) / 2;
    return Rect.fromLTWH(
      dx,
      dy,
      fitted.destination.width,
      fitted.destination.height,
    );
  }

  @override
  bool shouldRepaint(_VideoPainter oldDelegate) => image != oldDelegate.image;
}

/// 包含控制栏的完整视频播放器
class VideoPlayerWithControls extends StatefulWidget {
  final String videoPath;

  const VideoPlayerWithControls({
    super.key,
    required this.videoPath,
  });

  @override
  State<VideoPlayerWithControls> createState() =>
      _VideoPlayerWithControlsState();
}

class _VideoPlayerWithControlsState extends State<VideoPlayerWithControls> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  double? _dragProgress;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController();
    _init();
  }

  Future<void> _init() async {
    final ok = await _controller.open(widget.videoPath);
    if (ok && mounted) {
      setState(() => _initialized = true);
      _controller.play();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _controller.togglePlayPause,
            child: VideoPlayerView(controller: _controller),
          ),
        ),
        // 控制栏
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _controller.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: _controller.togglePlayPause,
                  ),
                  Text(
                    _formatDuration(_controller.positionMs),
                    style: const TextStyle(color: Colors.white),
                  ),
                  Expanded(
                    child: Slider(
                      value: _dragProgress ??
                          (_controller.durationMs > 0
                              ? _controller.positionMs /
                                  _controller.durationMs.toDouble()
                              : 0),
                      onChangeStart: (v) {
                        setState(() => _dragProgress = v);
                      },
                      onChanged: (v) {
                        setState(() => _dragProgress = v);
                      },
                      onChangeEnd: (v) {
                        final target = (v * _controller.durationMs).round();
                        setState(() => _dragProgress = null);
                        _controller.seek(target);
                      },
                    ),
                  ),
                  Text(
                    _formatDuration(_controller.durationMs),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.volume_up, color: Colors.white, size: 18),
                  SizedBox(
                    width: 120,
                    child: Slider(
                      value: _controller.volumePercent,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      onChanged: _controller.setVolumePercent,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

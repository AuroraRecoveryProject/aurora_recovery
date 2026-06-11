import 'package:flutter/material.dart';

import 'core/video_player_backend.dart';
import 'video_player_widget.dart';

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({
    super.key,
    required this.backend,
  });

  final VideoPlayerBackend backend;

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  String? _videoPath;
  final _pathController = TextEditingController(
    text: '/sdcard/Project.Hail.Mary.2026.IMAX.2160p.iT.WEB-DL.English.DDP5.1.Atmos.H.265.mkv',
  );

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backend = widget.backend;
    if (_videoPath != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(backend.playbackTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _videoPath = null),
          ),
        ),
        body: VideoPlayerWithControls(
          key: ValueKey('${backend.name}:$_videoPath'),
          backend: backend,
          videoPath: _videoPath!,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(backend.pickerTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '输入视频文件路径:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pathController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '/sdcard/video.mp4',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                final path = _pathController.text.trim();
                if (path.isNotEmpty) {
                  setState(() => _videoPath = path);
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('播放'),
            ),
            if (backend.pickerHint.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text(
                backend.pickerHint,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

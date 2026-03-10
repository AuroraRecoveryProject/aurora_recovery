// video_player_page.dart — 视频播放器页面

import 'dart:io';

import 'package:flutter/material.dart';

import 'video_player_widget.dart';

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({super.key});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  String? _videoPath;
  final _pathController = TextEditingController(
    text: '/tmp/flutter/test.mp4',
  );

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoPath != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('视频播放'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _videoPath = null),
          ),
        ),
        body: VideoPlayerWithControls(
          key: ValueKey(_videoPath),
          videoPath: _videoPath!,
        ),
      );
    }

    // 文件选择界面
    return Scaffold(
      appBar: AppBar(title: const Text('视频播放器')),
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
                hintText: '/tmp/flutter/test.mp4',
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
            const SizedBox(height: 32),
            const Text(
              '提示: 先用 adb push video.mp4 /tmp/flutter/ 将视频传到设备',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextureVideoDemoPage extends StatefulWidget {
  const TextureVideoDemoPage({super.key});

  @override
  State<TextureVideoDemoPage> createState() => _TextureVideoDemoPageState();
}

class _TextureVideoDemoPageState extends State<TextureVideoDemoPage> {
  static const _channel = MethodChannel('aurora_texture_demo');

  int? _textureId;
  String _status = '未创建';

  @override
  void dispose() {
    _disposeTexture();
    super.dispose();
  }

  Future<void> _createTexture() async {
    final result = await _channel.invokeMapMethod<String, Object?>('create');
    final textureId = result?['textureId'];
    if (textureId is int) {
      setState(() {
        _textureId = textureId;
        _status = 'Texture #$textureId';
      });
      await _channel.invokeMethod<void>('start');
    }
  }

  Future<void> _disposeTexture() async {
    await _channel.invokeMethod<void>('dispose');
  }

  Future<void> _stopTexture() async {
    await _channel.invokeMethod<void>('stop');
    setState(() => _status = '已停止');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Texture 视频 Demo')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _textureId == null ? _createTexture : null,
                  icon: const Icon(Icons.add),
                  label: const Text('创建'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _textureId == null ? null : _stopTexture,
                  icon: const Icon(Icons.pause),
                  label: const Text('停止'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(_status),
            const SizedBox(height: 16),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _textureId == null
                        ? const Center(child: Text('等待创建 Texture'))
                        : Texture(textureId: _textureId!),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

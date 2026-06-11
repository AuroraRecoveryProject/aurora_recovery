import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'texture_video_player_platform.dart';
import 'yuv_texture_video_player_platform.dart';
import 'ffi_video_player_platform.dart';

enum VideoPlayerBackend {
  ffi,
  texture,
  yuvTexture,
}

extension VideoPlayerBackendX on VideoPlayerBackend {
  String get playbackTitle {
    switch (this) {
      case VideoPlayerBackend.ffi:
        return '视频播放';
      case VideoPlayerBackend.texture:
        return 'Texture 视频播放';
      case VideoPlayerBackend.yuvTexture:
        return 'YUV Texture 视频播放';
    }
  }

  String get pickerTitle {
    switch (this) {
      case VideoPlayerBackend.ffi:
        return '视频播放器';
      case VideoPlayerBackend.texture:
        return 'Texture 视频播放器';
      case VideoPlayerBackend.yuvTexture:
        return 'YUV Texture 视频播放器';
    }
  }

  String get openErrorTitle {
    switch (this) {
      case VideoPlayerBackend.ffi:
        return '打开视频失败';
      case VideoPlayerBackend.texture:
        return '打开 Texture 视频失败';
      case VideoPlayerBackend.yuvTexture:
        return '打开 YUV Texture 视频失败';
    }
  }

  String get infoTitle {
    switch (this) {
      case VideoPlayerBackend.ffi:
        return 'Video Info';
      case VideoPlayerBackend.texture:
        return 'Texture Video Info';
      case VideoPlayerBackend.yuvTexture:
        return 'YUV Texture Video Info';
    }
  }

  String get pickerHint {
    switch (this) {
      case VideoPlayerBackend.ffi:
        return '提示: 先用 adb push video.mp4 /tmp/flutter/ 将视频传到设备';
      case VideoPlayerBackend.texture:
        return '提示: 这个版本走官方 video_player 接口，画面由 native Texture 提供';
      case VideoPlayerBackend.yuvTexture:
        return '';
    }
  }

  double? get initialVolume {
    switch (this) {
      case VideoPlayerBackend.ffi:
      case VideoPlayerBackend.texture:
        return null;
      case VideoPlayerBackend.yuvTexture:
        return 0.2;
    }
  }

  void registerPlatform() {
    switch (this) {
      case VideoPlayerBackend.ffi:
        VideoPlayerPlatform.instance = FfiVideoPlayerPlatform.instance;
      case VideoPlayerBackend.texture:
        VideoPlayerPlatform.instance = TextureVideoPlayerPlatform.instance;
      case VideoPlayerBackend.yuvTexture:
        VideoPlayerPlatform.instance = YuvTextureVideoPlayerPlatform.instance;
    }
  }

  VideoInfo infoForPath(String path) {
    switch (this) {
      case VideoPlayerBackend.ffi:
        return VideoInfo(
          fps: FfiVideoPlayerPlatform.fpsForPath(path),
          bitrateBps: FfiVideoPlayerPlatform.bitrateForPath(path),
        );
      case VideoPlayerBackend.texture:
        return TextureVideoPlayerPlatform.instance.metadataInfoForPath(path) ?? const VideoInfo(fps: 0, bitrateBps: 0);
      case VideoPlayerBackend.yuvTexture:
        return YuvTextureVideoPlayerPlatform.instance.metadataInfoForPath(path) ??
            const VideoInfo(fps: 0, bitrateBps: 0);
    }
  }

  bool get showsExtendedInfo {
    switch (this) {
      case VideoPlayerBackend.ffi:
        return false;
      case VideoPlayerBackend.texture:
      case VideoPlayerBackend.yuvTexture:
        return true;
    }
  }
}

class VideoInfo {
  const VideoInfo({
    required this.fps,
    required this.bitrateBps,
    this.fileSizeBytes = 0,
    this.videoCodec = '',
    this.audioCodec = '',
  });

  final double fps;
  final int bitrateBps;
  final int fileSizeBytes;
  final String videoCodec;
  final String audioCodec;
}

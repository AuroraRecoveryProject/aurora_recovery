import 'texture_video_player_platform_base.dart';

class YuvTextureVideoPlayerPlatform extends TextureVideoPlayerPlatformBase {
  YuvTextureVideoPlayerPlatform._()
      : super(
          createMode: 'yuv',
          openErrorCode: 'texture_video_open_failed',
          openErrorMessage: 'Native player returned no texture id.',
        );

  static final YuvTextureVideoPlayerPlatform instance =
      YuvTextureVideoPlayerPlatform._();
}

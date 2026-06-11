import 'texture_video_player_platform_base.dart';

class TextureVideoPlayerPlatform extends TextureVideoPlayerPlatformBase {
  TextureVideoPlayerPlatform._()
      : super(
          createMode: 'rgba',
          openErrorCode: 'texture_video_open_failed',
          openErrorMessage: 'Native player returned no texture id.',
        );

  static final TextureVideoPlayerPlatform instance =
      TextureVideoPlayerPlatform._();
}

// video_player_bindings.dart — Dart FFI 绑定
// 对应 video_player/video_player_ffi.h

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

// C 函数签名类型定义
typedef _VpCreateNative = Pointer<Void> Function(Pointer<Utf8> path);
typedef _VpCreateDart = Pointer<Void> Function(Pointer<Utf8> path);

typedef _VpDestroyNative = Void Function(Pointer<Void> p);
typedef _VpDestroyDart = void Function(Pointer<Void> p);

typedef _VpPlayNative = Int32 Function(Pointer<Void> p);
typedef _VpPlayDart = int Function(Pointer<Void> p);

typedef _VpPauseNative = Int32 Function(Pointer<Void> p);
typedef _VpPauseDart = int Function(Pointer<Void> p);

typedef _VpSeekNative = Int32 Function(Pointer<Void> p, Int64 positionMs);
typedef _VpSeekDart = int Function(Pointer<Void> p, int positionMs);

typedef _VpGetWidthNative = Int32 Function(Pointer<Void> p);
typedef _VpGetWidthDart = int Function(Pointer<Void> p);

typedef _VpGetHeightNative = Int32 Function(Pointer<Void> p);
typedef _VpGetHeightDart = int Function(Pointer<Void> p);

typedef _VpGetDurationMsNative = Int64 Function(Pointer<Void> p);
typedef _VpGetDurationMsDart = int Function(Pointer<Void> p);

typedef _VpGetPositionMsNative = Int64 Function(Pointer<Void> p);
typedef _VpGetPositionMsDart = int Function(Pointer<Void> p);

typedef _VpIsPlayingNative = Int32 Function(Pointer<Void> p);
typedef _VpIsPlayingDart = int Function(Pointer<Void> p);

typedef _VpGetFrameNative = Pointer<Uint8> Function(Pointer<Void> p);
typedef _VpGetFrameDart = Pointer<Uint8> Function(Pointer<Void> p);

typedef _VpHasNewFrameNative = Int32 Function(Pointer<Void> p);
typedef _VpHasNewFrameDart = int Function(Pointer<Void> p);

typedef _VpGetFpsNative = Double Function(Pointer<Void> p);
typedef _VpGetFpsDart = double Function(Pointer<Void> p);

class VideoPlayerBindings {
  late final DynamicLibrary _lib;

  late final _VpCreateDart vpCreate;
  late final _VpDestroyDart vpDestroy;
  late final _VpPlayDart vpPlay;
  late final _VpPauseDart vpPause;
  late final _VpSeekDart vpSeek;
  late final _VpGetWidthDart vpGetWidth;
  late final _VpGetHeightDart vpGetHeight;
  late final _VpGetDurationMsDart vpGetDurationMs;
  late final _VpGetPositionMsDart vpGetPositionMs;
  late final _VpIsPlayingDart vpIsPlaying;
  late final _VpGetFrameDart vpGetFrame;
  late final _VpHasNewFrameDart vpHasNewFrame;
  late final _VpGetFpsDart vpGetFps;

  VideoPlayerBindings() {
    _lib = DynamicLibrary.open('libvideo_player.so');

    vpCreate = _lib.lookupFunction<_VpCreateNative, _VpCreateDart>('vp_create');
    vpDestroy = _lib.lookupFunction<_VpDestroyNative, _VpDestroyDart>('vp_destroy');
    vpPlay = _lib.lookupFunction<_VpPlayNative, _VpPlayDart>('vp_play');
    vpPause = _lib.lookupFunction<_VpPauseNative, _VpPauseDart>('vp_pause');
    vpSeek = _lib.lookupFunction<_VpSeekNative, _VpSeekDart>('vp_seek');
    vpGetWidth = _lib.lookupFunction<_VpGetWidthNative, _VpGetWidthDart>('vp_get_width');
    vpGetHeight = _lib.lookupFunction<_VpGetHeightNative, _VpGetHeightDart>('vp_get_height');
    vpGetDurationMs = _lib.lookupFunction<_VpGetDurationMsNative, _VpGetDurationMsDart>('vp_get_duration_ms');
    vpGetPositionMs = _lib.lookupFunction<_VpGetPositionMsNative, _VpGetPositionMsDart>('vp_get_position_ms');
    vpIsPlaying = _lib.lookupFunction<_VpIsPlayingNative, _VpIsPlayingDart>('vp_is_playing');
    vpGetFrame = _lib.lookupFunction<_VpGetFrameNative, _VpGetFrameDart>('vp_get_frame');
    vpHasNewFrame = _lib.lookupFunction<_VpHasNewFrameNative, _VpHasNewFrameDart>('vp_has_new_frame');
    vpGetFps = _lib.lookupFunction<_VpGetFpsNative, _VpGetFpsDart>('vp_get_fps');
  }
}

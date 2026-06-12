import 'dart:ffi';
import 'package:signale/signale.dart';
import 'package:ffi/ffi.dart';

import 'package:aurora_recovery/generated/aurora_ffi_bindings.dart';
import 'package:aurora_recovery/modules/video_player/core/video_player_backend.dart';

class SettingService {
  SettingService._();

  static final SettingService instance = SettingService._();

  DynamicLibrary lib = DynamicLibrary.open("libtwrp_core_ffi.so");
  late AuroraFfiBindings ffi = AuroraFfiBindings(lib);

  int brightnessPct = 0;
  VideoPlayerBackend videoPlayerBackend = VideoPlayerBackend.ffi;
  String dumpAll = '';

  void init() {
    ffi.tw_settings_init();

    final outValuePtr = calloc<Char>(1024);
    const outLen = 1024;
    ffi.tw_settings_get_all(outValuePtr, outLen);
    dumpAll = outValuePtr.cast<Utf8>().toDartString();
    Log.i("All settings: $dumpAll");
    calloc.free(outValuePtr);
    // tw_brightness_pct
    final outBrightnessPtr = calloc<Char>(1024);
    ffi.tw_settings_get(
        'tw_brightness_pct'.toNativeUtf8().cast(), outBrightnessPtr, outLen);
    final brightnessValue = outBrightnessPtr.cast<Utf8>().toDartString();
    Log.i("Brightness: $brightnessValue");
    brightnessPct = int.parse(brightnessValue);
    // tw_display_set_brightness_percent
    ffi.tw_display_set_brightness_percent(brightnessPct);
    calloc.free(outBrightnessPtr);

    videoPlayerBackend = _readVideoPlayerBackend();
  }

  void settingSet(String key, String value) {
    ffi.tw_settings_set(key.toNativeUtf8().cast(), value.toNativeUtf8().cast());
  }

  String settingGet(String key) {
    final outValuePtr = calloc<Char>(1024);
    const outLen = 1024;
    ffi.tw_settings_get(key.toNativeUtf8().cast(), outValuePtr, outLen);
    final value = outValuePtr.cast<Utf8>().toDartString();
    calloc.free(outValuePtr);
    return value;
  }

  void setBrightness(int pct) {
    brightnessPct = pct;
    ffi.tw_display_set_brightness_percent(brightnessPct);
    settingSet('tw_brightness_pct', pct.toString());
  }

  void setVideoPlayerBackend(VideoPlayerBackend backend) {
    videoPlayerBackend = backend;
    settingSet('tw_video_player_backend', backend.name);
  }

  VideoPlayerBackend _readVideoPlayerBackend() {
    final value = settingGet('tw_video_player_backend');
    for (final backend in VideoPlayerBackend.values) {
      if (backend.name == value) {
        return backend;
      }
    }
    return VideoPlayerBackend.ffi;
  }
}

// ignore: non_constant_identifier_names
final SettingInstance = SettingService.instance;

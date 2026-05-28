import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:aurora_recovery/generated_bindings.dart';
import 'package:ffi/ffi.dart';
import 'package:signale/signale.dart';

class SettingService {
  SettingService._();

  static final SettingService instance = SettingService._();

  DynamicLibrary lib = DynamicLibrary.open("libtwrp_core_ffi.so");
  late AuroraBindings ffi = AuroraBindings(lib);

  int brightnessPct = 0;
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
    ffi.tw_settings_get('tw_brightness_pct'.toNativeUtf8().cast(), outBrightnessPtr, outLen);
    final brightnessValue = outBrightnessPtr.cast<Utf8>().toDartString();
    Log.i("Brightness: $brightnessValue");
    brightnessPct = int.parse(brightnessValue);
    // tw_display_set_brightness_percent
    ffi.tw_display_set_brightness_percent(brightnessPct);
    calloc.free(outBrightnessPtr);
  }
}

// ignore: non_constant_identifier_names
final SettingInstance = SettingService.instance;

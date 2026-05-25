// create global instance

import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:aurora_recovery/utils.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:signale/signale.dart';

import '../generated_bindings.dart';

class _Global extends GetxController {
  _Global._internal();
  DynamicLibrary lib = DynamicLibrary.open("libtwrp_core_ffi.so");
  late AuroraBindings ffi = AuroraBindings(lib);

  static final _Global instance = _Global._internal();

  Timer? infoTimer;
  double cpuUsage = 0.0;
  double gpuUsage = 0.0;
  double gpuKernelUsage = 0.0;
  String batteryValue = '';
  String dumpAll = '';
  bool _initialized = false;
  int brightnessPct = 0;

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    infoTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      final results = await Future.wait([calculateCPUUsage(), calculateGPUUsage()]);
      final cpuUsageTmp = results[0] as double;
      final gpuData = results[1] as Map<String, double>;

      cpuUsage = cpuUsageTmp;
      gpuUsage = gpuData['calc_usage']!;
      gpuKernelUsage = gpuData['kernel_usage']!;

      final batteryValuePtr = calloc<Char>(1024);
      ffi.tw_power_get_battery_string(batteryValuePtr, 1024);
      batteryValue = batteryValuePtr.cast<Utf8>().toDartString();
      calloc.free(batteryValuePtr);
      update();
    });

    _initSettings();
    _initInstallRuntime();

    _copyBundledAssets();
  }

  void _initSettings() {
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

  void _initInstallRuntime() {
    update();
  }

  void _copyBundledAssets() {
    final scripts = ['color_print', 'cmatrix', 'nettest', 'curl'];
    for (final script in scripts) {
      rootBundle.load('assets/executable/$script').then((data) {
        final bytes = data.buffer.asUint8List();
        final file = File('/tmp/$script');
        file.writeAsBytes(bytes).then((_) {
          Log.i('Copied $script to /tmp/$script');
          // set executable
          Process.run('chmod', ['+x', '/tmp/$script']).then((result) {
            Log.i('Set executable exitCode: ${result.exitCode}');
          });
        });
      });
    }
    // 'echo "nameserver 223.5.5.5" > /etc/resolv.conf'
    File('/etc/resolv.conf').writeAsString('nameserver 223.5.5.5');
  }

  @override
  void onClose() {
    infoTimer?.cancel();
    super.onClose();
  }
}

// ignore: non_constant_identifier_names
final Global = _Global.instance;

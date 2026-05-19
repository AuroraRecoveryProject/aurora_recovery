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
  Timer? installTimer;
  double cpuUsage = 0.0;
  double gpuUsage = 0.0;
  double gpuKernelUsage = 0.0;
  String batteryValue = '';
  String dumpAll = '';
  String installTargetPath = '/tmp/test.zip';
  String installStateLabel = 'idle';
  String installLog = '';
  String installError = '';
  int installProgress = 0;
  int installResult = 0;
  bool installRequestedWipeCache = false;
  bool _initialized = false;
  bool _installReady = false;
  int brightnessPct = 0;

  void init() {
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
    final initRet = ffi.tw_install_init();
    if (initRet != 0) {
      installStateLabel = 'init_failed';
      installError = 'tw_install_init failed: $initRet';
      update();
      return;
    }

    final logPath = '/tmp/recovery.log'.toNativeUtf8();
    final installFilePath = '/tmp/last_install'.toNativeUtf8();
    final updateBinaryPath = '/tmp/update-binary'.toNativeUtf8();

    final setPathRet = ffi.tw_install_set_paths(
      logPath.cast(),
      installFilePath.cast(),
      updateBinaryPath.cast(),
    );
    calloc.free(logPath);
    calloc.free(installFilePath);
    calloc.free(updateBinaryPath);

    if (setPathRet != 0) {
      installStateLabel = 'set_paths_failed';
      installError = 'tw_install_set_paths failed: $setPathRet';
      update();
      return;
    }

    _installReady = true;
    installStateLabel = 'ready';
    update();
  }

  void startInstall([String? packagePath]) {
    if (packagePath != null && packagePath.isNotEmpty) {
      installTargetPath = packagePath;
    }

    if (!_installReady) {
      _initInstallRuntime();
      if (!_installReady) {
        return;
      }
    }

    if (installTimer?.isActive ?? false) {
      return;
    }

    ffi.tw_install_reset_session();

    installStateLabel = 'starting';
    installError = '';
    installLog = '';
    installResult = 0;
    installProgress = 0;
    installRequestedWipeCache = false;
    update();

    if (!File(installTargetPath).existsSync()) {
      installStateLabel = 'package_missing';
      installError = 'Package not found: $installTargetPath';
      update();
      return;
    }

    final zipPath = installTargetPath.toNativeUtf8();
    final startRet = ffi.tw_install_start_zip(zipPath.cast(), 0);
    calloc.free(zipPath);

    if (startRet != 0) {
      installStateLabel = 'start_failed';
      installError = 'tw_install_start_zip failed: $startRet';
      update();
      return;
    }

    installStateLabel = 'running';
    installError = '';
    installResult = 0;
    installProgress = 0;
    installRequestedWipeCache = false;
    _pollInstallState();
    installTimer?.cancel();
    installTimer = Timer.periodic(Duration(milliseconds: 500), (_) {
      _pollInstallState();
    });
    update();
  }

  void _pollInstallState() {
    final state = ffi.tw_install_get_state();
    installProgress = ffi.tw_install_get_progress();
    installRequestedWipeCache = ffi.tw_install_get_wipe_cache() != 0;
    installResult = ffi.tw_install_get_last_result();

    final logBuffer = calloc<Char>(16384);
    ffi.tw_install_read_log(logBuffer, 16384);
    installLog = logBuffer.cast<Utf8>().toDartString();
    calloc.free(logBuffer);

    if (state == TW_INSTALL_STATE_IDLE) {
      if (installStateLabel != 'ready') {
        installStateLabel = 'idle';
      }
    } else if (state == TW_INSTALL_STATE_RUNNING) {
      installStateLabel = 'running';
    } else if (state == TW_INSTALL_STATE_SUCCESS) {
      installStateLabel = 'success';
      installTimer?.cancel();
    } else if (state == TW_INSTALL_STATE_FAILED) {
      installStateLabel = 'failed';
      final errorBuffer = calloc<Char>(4096);
      ffi.tw_install_get_last_error(errorBuffer, 4096);
      installError = errorBuffer.cast<Utf8>().toDartString();
      calloc.free(errorBuffer);
      installTimer?.cancel();
    } else {
      installStateLabel = 'unknown($state)';
    }

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
    installTimer?.cancel();
    super.onClose();
  }
}

// ignore: non_constant_identifier_names
final Global = _Global.instance;

import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:aurora_recovery/generated_bindings.dart';
import 'package:aurora_recovery/widgets/toast.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:signale/signale.dart';

class FlashRomService {
  FlashRomService._();
  static const tag = 'FlashRomService';

  static final FlashRomService instance = FlashRomService._();
  DynamicLibrary lib = DynamicLibrary.open("libtwrp_core_ffi.so");
  late AuroraBindings ffi = AuroraBindings(lib);
  bool _installReady = false;
  String installStateLabel = 'idle';
  int installProgress = 0;
  int installResult = 0;
  bool installRequestedWipeCache = false;
  void init() {
    final initRet = ffi.tw_install_init();
    if (initRet != 0) {
      installStateLabel = 'init_failed';
      Log.e('tw_install_init failed: $initRet', tag);
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
      Log.e('tw_install_set_paths failed: $setPathRet', tag);
      return;
    }

    _installReady = true;
    installStateLabel = 'ready';
  }

  void startInstall(String packagePath, {ValueSetter<String>? onLog}) async {
    Log.i('Starting install for package: $packagePath', tag);
    if (!_installReady) {
      init();
      if (!_installReady) {
        return;
      }
    }

    ffi.tw_install_reset_session();
    _logOffset = 0;

    installStateLabel = 'starting';
    installResult = 0;
    installProgress = 0;
    installRequestedWipeCache = false;

    if (!File(packagePath).existsSync()) {
      installStateLabel = 'package_missing';
      Log.e('Package not found: $packagePath', tag);
      Toast.show('Package not found: $packagePath');
      return;
    }

    final zipPath = packagePath.toNativeUtf8();
    final startRet = ffi.tw_install_start_zip(zipPath.cast(), 0);
    calloc.free(zipPath);

    if (startRet != 0) {
      installStateLabel = 'start_failed';
      Log.e('tw_install_start_zip failed: $startRet', tag);
      Toast.show('tw_install_start_zip failed: $startRet');
      return;
    }

    installStateLabel = 'running';
    installResult = 0;
    installProgress = 0;
    installRequestedWipeCache = false;
    while (true) {
      final state = ffi.tw_install_get_state();
      installProgress = ffi.tw_install_get_progress();
      installRequestedWipeCache = ffi.tw_install_get_wipe_cache() != 0;
      installResult = ffi.tw_install_get_last_result();

      String installLog = readInstallLogChunk();
      if (onLog != null) {
        onLog(installLog);
      }
      Log.i('Install state: $state, progress: $installProgress%, result: $installResult', tag);
      Log.e('Install log:\n$installLog', tag);
      Log.e('---', tag);
      if (state == TW_INSTALL_STATE_IDLE) {
        if (installStateLabel != 'ready') {
          installStateLabel = 'idle';
        }
      } else if (state == TW_INSTALL_STATE_RUNNING) {
        Log.i('Install is running...', tag);
      } else if (state == TW_INSTALL_STATE_SUCCESS) {
        Log.i('Install completed successfully!', tag);
        final tail = readInstallLogChunk();
        if (onLog != null && tail.isNotEmpty) onLog(tail);
        break;
      } else if (state == TW_INSTALL_STATE_FAILED) {
        final tail = readInstallLogChunk();
        if (onLog != null && tail.isNotEmpty) onLog(tail);
        final errorBuffer = calloc<Char>(4096);
        ffi.tw_install_get_last_error(errorBuffer, 4096);
        Log.e('Install error:\n${errorBuffer.cast<Utf8>().toDartString()}', tag);
        calloc.free(errorBuffer);
        break;
      } else {
        installStateLabel = 'unknown($state)';
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  String readInstallLogChunk() {
    const bufferSize = 64 * 1024;

    final buffer = calloc<Char>(bufferSize);
    final nextOffsetPtr = calloc<Uint64>();
    try {
      final ret = ffi.tw_install_read_log(
        _logOffset,
        buffer,
        bufferSize,
        nextOffsetPtr,
      );
      if (ret == 0) {
        final text = buffer.cast<Utf8>().toDartString();
        _logOffset = nextOffsetPtr.value;
        return text;
      }
      // ENOSPC (-28)：本轮 buffer 不够，下一轮自然会继续；offset 不前进。
      // 其他错误：忽略本轮，记日志即可。
      Log.w('tw_install_read_log returned $ret, skipping this poll', tag);
      return '';
    } finally {
      calloc.free(buffer);
      calloc.free(nextOffsetPtr);
    }
  }

  int _logOffset = 0;
}

// create global instance

import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:aurora_recovery/utils.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'generated_bindings.dart';

class _Global extends GetxController {
  _Global._internal();
  DynamicLibrary lib = DynamicLibrary.open("libtwrp_core_ffi.so");
  late AuroraBindings bindings = AuroraBindings(lib);

  static final _Global instance = _Global._internal();

  Timer? cpuTimer;
  double cpuUsage = 0.0;
  double gpuUsage = 0.0;
  double gpuKernelUsage = 0.0;
  String batteryValue = '';
  String dumpAll = '';

  void init() {
    cpuTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      final results = await Future.wait([calculateCPUUsage(), calculateGPUUsage()]);

      final cpuUsageTmp = results[0] as double;
      final gpuData = results[1] as Map<String, double>;

      cpuUsage = cpuUsageTmp;
      gpuUsage = gpuData['calc_usage']!;
      gpuKernelUsage = gpuData['kernel_usage']!;
      // print(
      //   'CPU Usage: ${cpuUsage.toStringAsFixed(2)}% | GPU Calc Usage: ${gpuUsage.toStringAsFixed(2)}% | GPU Kernel Usage: ${gpuKernelUsage.toStringAsFixed(2)}%',
      // );
      update();
    });
    final batteryValuePtr = calloc<Char>(1024);
    bindings.tw_power_get_battery_string(batteryValuePtr, 1024);
    // print battery value
    batteryValue = batteryValuePtr.cast<Utf8>().toDartString();
    print("Battery value: $batteryValue");
    calloc.free(batteryValuePtr);

    bindings.tw_settings_init();

    final outValuePtr = calloc<Char>(1024);
    final outLen = 1024;
    bindings.tw_settings_get_all(outValuePtr, outLen);
    dumpAll = outValuePtr.cast<Utf8>().toDartString();
    print("All settings: $dumpAll");
    calloc.free(outValuePtr);
    bindings.tw_display_set_brightness_percent(60);
    // copy asstes/arp_flash.sh to /tmp/arp_flash.sh with rootbundle
    // copy asstes/cmatrix to /tmp/cmatrix with rootbundle
    rootBundle.load('assets/arp_flash.sh').then((data) {
      final bytes = data.buffer.asUint8List();
      final file = File('/tmp/arp_flash.sh');
      file.writeAsBytes(bytes).then((_) {
        print('Copied arp_flash.sh to /tmp/arp_flash.sh');
        // set executable
        Process.run('chmod', ['+x', '/tmp/arp_flash.sh']).then((result) {
          print('Set executable: ${result.stdout}');
        });
      });
    });
    rootBundle.load('assets/cmatrix').then((data) {
      final bytes = data.buffer.asUint8List();
      final file = File('/tmp/cmatrix');
      file.writeAsBytes(bytes).then((_) {
        print('Copied cmatrix to /tmp/cmatrix');
        // set executable
        Process.run('chmod', ['+x', '/tmp/cmatrix']).then((result) {
          print('Set executable: ${result.stdout}');
        });
      });
    });
  }
}

// ignore: non_constant_identifier_names
final Global = _Global.instance;

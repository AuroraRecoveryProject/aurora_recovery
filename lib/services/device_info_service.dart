import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:signale/signale.dart';
import 'package:ffi/ffi.dart';
import 'package:get/get.dart';

import 'package:aurora_recovery/generated/aurora_ffi_bindings.dart';

class DeviceInfoService extends GetxController {
  DeviceInfoService._();

  static final DeviceInfoService instance = DeviceInfoService._();

  DynamicLibrary lib = DynamicLibrary.open("libtwrp_core_ffi.so");
  late AuroraFfiBindings ffi = AuroraFfiBindings(lib);

  Timer? infoTimer;
  double cpuUsage = 0.0;
  double gpuUsage = 0.0;
  double gpuKernelUsage = 0.0;
  String batteryValue = '';

  void init() {
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
  }

  Future<Map<String, double>> calculateGPUUsage() async {
    try {
      const String gpubusyPath = '/sys/class/kgsl/kgsl-3d0/gpubusy';
      final gpubusyFile = File(gpubusyPath);
      if (!await gpubusyFile.exists()) {
        return {'calc_usage': -1.0, 'kernel_usage': -1.0};
      }

      // 读取第一次 gpubusy
      // Read the first gpubusy
      final gpubusy1 = await gpubusyFile.readAsString();
      final parts1 = gpubusy1.trim().split(RegExp('\\s+'));
      if (parts1.length < 2) return {'calc_usage': 0.0, 'kernel_usage': 0.0};

      final int busy1 = int.parse(parts1[0]);
      final int total1 = int.parse(parts1[1]);

      await Future.delayed(Duration(seconds: 1));

      // 读取第二次 gpubusy
      // Read the second gpubusy
      final gpubusy2 = await gpubusyFile.readAsString();
      final parts2 = gpubusy2.trim().split(RegExp('\\s+'));
      if (parts2.length < 2) return {'calc_usage': 0.0, 'kernel_usage': 0.0};

      final int busy2 = int.parse(parts2[0]);
      final int total2 = int.parse(parts2[1]);

      final int busyDiff = busy2 - busy1;
      final int totalDiff = total2 - total1;

      double calcUsage = 0.0;
      if (totalDiff > 0) {
        calcUsage = (100.0 * busyDiff / totalDiff);
      }

      // 读取内核计算好的 gpu_load
      // Read the gpu_load calculated by the kernel
      double kernelUsage = 0.0;
      final gpuLoadFile = File('/sys/class/kgsl/kgsl-3d0/devfreq/gpu_load');
      if (await gpuLoadFile.exists()) {
        final gpuLoadStr = await gpuLoadFile.readAsString();
        kernelUsage = double.tryParse(gpuLoadStr.trim()) ?? 0.0;
      }

      return {'calc_usage': calcUsage.clamp(0.0, 100.0), 'kernel_usage': kernelUsage.clamp(0.0, 100.0)};
    } catch (e) {
      return {'calc_usage': 0.0, 'kernel_usage': 0.0};
    }
  }

  Future<double> calculateCPUUsage() async {
    // 读取第一次 CPU 时间
    // Read the first CPU times
    final cpuTimes1 = await getCPUTimes();
    if (cpuTimes1.length < 8) {
      return -1;
    }
    await Future.delayed(Duration(seconds: 1));
    final cpuTimes2 = await getCPUTimes();
    if (cpuTimes2.length < 8) {
      return -1;
    }

    // 显式提取第一次采样的变量
    // Explicitly extract the variables from the first sample
    final user1 = cpuTimes1[0];
    final nice1 = cpuTimes1[1];
    final system1 = cpuTimes1[2];
    final idle1 = cpuTimes1[3];
    final iowait1 = cpuTimes1[4];
    final irq1 = cpuTimes1[5];
    final softirq1 = cpuTimes1[6];
    final steal1 = cpuTimes1[7];

    // 显式提取第二次采样的变量
    // Explicitly extract the variables from the second sample
    final user2 = cpuTimes2[0];
    final nice2 = cpuTimes2[1];
    final system2 = cpuTimes2[2];
    final idle2 = cpuTimes2[3];
    final iowait2 = cpuTimes2[4];
    final irq2 = cpuTimes2[5];
    final softirq2 = cpuTimes2[6];
    final steal2 = cpuTimes2[7];

    // 计算总时间和空闲时间
    // Calculate total time and idle time
    final totalTime1 = user1 + nice1 + system1 + idle1 + iowait1 + irq1 + softirq1 + steal1;
    final totalTime2 = user2 + nice2 + system2 + idle2 + iowait2 + irq2 + softirq2 + steal2;

    final idleTime1 = idle1 + iowait1;
    final idleTime2 = idle2 + iowait2;

    final totalDelta = totalTime2 - totalTime1;
    final idleDelta = idleTime2 - idleTime1;

    if (totalDelta <= 0) {
      return 0.0;
    }

    // 计算 CPU 使用率
    // Calculate CPU usage
    final cpuUsage = 1.0 - (idleDelta / totalDelta);
    return (cpuUsage * 100).clamp(0.0, 100.0);
  }

  Future<List<int>> getCPUTimes() async {
    try {
      // ! 不能用 cat，在一些 Rom 刷写的时候，会将真实的 system 分区挂载到当前 /system
      // ! cat 是符号链接到 toybox，会直接引发所有进程的崩溃，最后甚至连 adb 都连不上，已经连接的 adb 也无法执行任何命令
      // ! 测试 A:
      // ! 仅把 cat 改成文件读取，即使 ffi 端不加 mount("none", "/", nullptr, MS_REC | MS_SLAVE, nullptr)
      // ! 刷写面具依然正常
      // ! 测试 B:
      // ! embeded main 添加 signal(SIGPIPE, SIG_IGN);
      // ! 当前代码仅报错 ProcessException: strerror_r failed，整个程序不崩，正常刷入 Magisk
      // ! 测试 C:
      // ! 上面两个修复都不要，但是把当前 cat 换成直接读取文件，正常刷入 Magisk
      // String statContent = await Process.run('cat', ['/proc/stat']).then((result) => result.stdout);
      String statContent = await File('/proc/stat').readAsString();
      final lines = statContent.split('\n');
      final cpuLine = lines.firstWhere((line) => line.startsWith('cpu '), orElse: () => '');
      if (cpuLine.isEmpty) return [];
      return cpuLine.trim().split(RegExp('\\s+')).skip(1).map(int.parse).toList();
    } catch (e) {
      Log.e('Failed to read CPU times: $e');
      return [];
    }
  }
}

// ignore: non_constant_identifier_names
final DeviceInfoInstance = DeviceInfoService.instance;

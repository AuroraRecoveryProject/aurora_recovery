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
  List<double> cpuCoreUsages = [];
  List<double> cpuCoreFrequencies = [];
  double cpuTemperature = -1.0;
  double gpuUsage = 0.0;
  double gpuKernelUsage = 0.0;
  String batteryValue = '';
  String? _loggedCpuTemperaturePath;
  // coreUsageText
  String coreUsageText = '';
  String coreFrequencyText = '';

  void init() {
    infoTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      final results = await Future.wait([
        calculateCPUUsage(),
        readCpuFrequencies(),
        calculateGPUUsage(),
        readCpuTemperature(),
      ]);
      final cpuUsageTmp = results[0] as double;
      final cpuCoreFrequenciesTmp = results[1] as List<double>;
      final gpuData = results[2] as Map<String, double>;
      final cpuTemperatureTmp = results[3] as double;

      cpuUsage = cpuUsageTmp;
      cpuCoreFrequencies = cpuCoreFrequenciesTmp;
      gpuUsage = gpuData['calc_usage']!;
      gpuKernelUsage = gpuData['kernel_usage']!;
      cpuTemperature = cpuTemperatureTmp;

      coreUsageText =
          [for (var i = 0; i < cpuCoreUsages.length; i++) 'cpu$i=${cpuCoreUsages[i].toStringAsFixed(2)}%'].join(' ');
      coreFrequencyText = [
        for (var i = 0; i < cpuCoreFrequencies.length; i++) 'cpu$i=${formatCpuFrequency(cpuCoreFrequencies[i])}'
      ].join(' ');
      // Log.i(
      //   'CPU: ${cpuUsage.toStringAsFixed(2)}% cores: $coreUsageText freq: $coreFrequencyText',
      // );

      final batteryValuePtr = calloc<Char>(1024);
      ffi.tw_power_get_battery_string(batteryValuePtr, 1024);
      batteryValue = batteryValuePtr.cast<Utf8>().toDartString();
      calloc.free(batteryValuePtr);
      update();
    });
  }

  Future<double> readCpuTemperature() async {
    try {
      final thermalDir = Directory('/sys/class/thermal');
      if (!await thermalDir.exists()) {
        return -1.0;
      }

      final zones = await thermalDir
          .list()
          .where((entry) => entry is Directory && entry.path.contains('thermal_zone'))
          .cast<Directory>()
          .toList();

      const preferredKeywords = [
        'cpu',
        'cpuss',
        'soc',
        'tsens',
        'little',
        'big',
        'gold',
        'silver',
      ];

      for (final zone in zones) {
        final typeFile = File('${zone.path}/type');
        final tempFile = File('${zone.path}/temp');
        if (!await typeFile.exists() || !await tempFile.exists()) {
          continue;
        }

        final type = (await typeFile.readAsString()).trim().toLowerCase();
        if (!preferredKeywords.any(type.contains)) {
          continue;
        }

        final raw = double.tryParse((await tempFile.readAsString()).trim());
        if (raw == null) {
          continue;
        }

        if (_loggedCpuTemperaturePath != tempFile.path) {
          _loggedCpuTemperaturePath = tempFile.path;
          Log.i(
            'CPU temperature path type=${typeFile.path} temp=${tempFile.path} zone_type=$type',
          );
        }

        return raw > 1000 ? raw / 1000.0 : raw;
      }

      return -1.0;
    } catch (e) {
      Log.e('Failed to read CPU temperature: $e');
      return -1.0;
    }
  }

  Future<Map<String, double>> calculateGPUUsage() async {
    try {
      const String gpubusyPath = '/sys/class/kgsl/kgsl-3d0/gpubusy';
      final gpubusyFile = File(gpubusyPath);
      if (!await gpubusyFile.exists()) {
        return {'calc_usage': -1.0, 'kernel_usage': -1.0};
      }

      final gpubusy = await gpubusyFile.readAsString();
      final parts = gpubusy.trim().split(RegExp('\\s+'));
      if (parts.length < 2) return {'calc_usage': 0.0, 'kernel_usage': 0.0};

      double calcUsage = 0.0;
      final int busy = int.parse(parts[0]);
      final int total = int.parse(parts[1]);
      if (total > 0) {
        // KGSL gpubusy is a current-window busy/total pair, not a monotonic
        // counter like /proc/stat. Use the ratio directly.
        calcUsage = 100.0 * busy / total;
      }

      // gpu_load is the KGSL/devfreq governor's load estimate. It is useful
      // for debugging frequency policy, but it can be smoothed, delayed, or
      // affected by governor state, so it is not as reliable for UI display as
      // the direct gpubusy busy/total ratio above.
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
    final cpuTimes1 = await getAllCPUTimes();
    final totalCpuTimes1 = cpuTimes1['cpu'];
    if (totalCpuTimes1 == null || totalCpuTimes1.length < 8) {
      return -1;
    }
    await Future.delayed(Duration(seconds: 1));
    final cpuTimes2 = await getAllCPUTimes();
    final totalCpuTimes2 = cpuTimes2['cpu'];
    if (totalCpuTimes2 == null || totalCpuTimes2.length < 8) {
      return -1;
    }

    final coreNames = cpuTimes1.keys.where((name) => RegExp(r'^cpu\d+$').hasMatch(name)).toList()
      ..sort((a, b) => int.parse(a.substring(3)).compareTo(int.parse(b.substring(3))));

    final coreUsages = <String, double>{};
    for (final name in coreNames) {
      final coreTimes2 = cpuTimes2[name];
      if (coreTimes2 == null) {
        continue;
      }
      coreUsages[name] = _calculateCPUUsageFromTimes(cpuTimes1[name]!, coreTimes2);
    }
    cpuCoreUsages = coreUsages.values.toList();

    final totalCpuUsage = _calculateCPUUsageFromTimes(totalCpuTimes1, totalCpuTimes2);

    return totalCpuUsage;
  }

  Future<List<double>> readCpuFrequencies() async {
    final frequencies = <double>[];

    try {
      for (var i = 0;; i++) {
        final cpuDir = Directory('/sys/devices/system/cpu/cpu$i');
        if (!await cpuDir.exists()) {
          break;
        }

        final frequency = await _readCpuFrequency(cpuDir.path);
        frequencies.add(frequency);
      }
    } catch (e) {
      Log.e('Failed to read CPU frequencies: $e');
    }

    return frequencies;
  }

  Future<double> _readCpuFrequency(String cpuPath) async {
    final frequencyFiles = [
      File('$cpuPath/cpufreq/scaling_cur_freq'),
      File('$cpuPath/cpufreq/cpuinfo_cur_freq'),
    ];

    for (final frequencyFile in frequencyFiles) {
      if (!await frequencyFile.exists()) {
        continue;
      }

      final raw = int.tryParse((await frequencyFile.readAsString()).trim());
      if (raw == null) {
        continue;
      }

      return raw / 1000.0;
    }

    return -1.0;
  }

  Future<List<int>> getCPUTimes() async {
    final cpuTimes = await getAllCPUTimes();
    return cpuTimes['cpu'] ?? [];
  }

  Future<Map<String, List<int>>> getAllCPUTimes() async {
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
      final cpuTimes = <String, List<int>>{};
      for (final line in lines) {
        if (!line.startsWith(RegExp(r'cpu\d* '))) {
          continue;
        }

        final parts = line.trim().split(RegExp('\\s+'));
        if (parts.length < 9) {
          continue;
        }

        cpuTimes[parts.first] = parts.skip(1).map(int.parse).toList();
      }
      return cpuTimes;
    } catch (e) {
      Log.e('Failed to read CPU times: $e');
      return {};
    }
  }

  double _calculateCPUUsageFromTimes(List<int> times1, List<int> times2) {
    if (times1.length < 8 || times2.length < 8) {
      return -1.0;
    }

    // 显式提取第一次采样的变量
    // Explicitly extract the variables from the first sample
    final user1 = times1[0];
    final nice1 = times1[1];
    final system1 = times1[2];
    final idle1 = times1[3];
    final iowait1 = times1[4];
    final irq1 = times1[5];
    final softirq1 = times1[6];
    final steal1 = times1[7];

    // 显式提取第二次采样的变量
    // Explicitly extract the variables from the second sample
    final user2 = times2[0];
    final nice2 = times2[1];
    final system2 = times2[2];
    final idle2 = times2[3];
    final iowait2 = times2[4];
    final irq2 = times2[5];
    final softirq2 = times2[6];
    final steal2 = times2[7];

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

    return ((1.0 - (idleDelta / totalDelta)) * 100).clamp(0.0, 100.0);
  }

  String formatCpuFrequency(double frequency) {
    if (frequency < 0) {
      return 'N/A';
    }

    return '${frequency.toStringAsFixed(0)}MHz';
  }
}

// ignore: non_constant_identifier_names
final DeviceInfoInstance = DeviceInfoService.instance;

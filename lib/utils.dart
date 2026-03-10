import 'dart:io';

Future<Map<String, double>> calculateGPUUsage() async {
  try {
    const String gpubusyPath = '/sys/class/kgsl/kgsl-3d0/gpubusy';
    final gpubusyFile = File(gpubusyPath);
    if (!await gpubusyFile.exists()) {
      return {'calc_usage': -1.0, 'kernel_usage': -1.0};
    }

    // 读取第一次 gpubusy
    final gpubusy1 = await gpubusyFile.readAsString();
    final parts1 = gpubusy1.trim().split(RegExp('\\s+'));
    if (parts1.length < 2) return {'calc_usage': 0.0, 'kernel_usage': 0.0};

    final int busy1 = int.parse(parts1[0]);
    final int total1 = int.parse(parts1[1]);

    await Future.delayed(Duration(seconds: 1));

    // 读取第二次 gpubusy
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
  final user1 = cpuTimes1[0];
  final nice1 = cpuTimes1[1];
  final system1 = cpuTimes1[2];
  final idle1 = cpuTimes1[3];
  final iowait1 = cpuTimes1[4];
  final irq1 = cpuTimes1[5];
  final softirq1 = cpuTimes1[6];
  final steal1 = cpuTimes1[7];

  // 显式提取第二次采样的变量
  final user2 = cpuTimes2[0];
  final nice2 = cpuTimes2[1];
  final system2 = cpuTimes2[2];
  final idle2 = cpuTimes2[3];
  final iowait2 = cpuTimes2[4];
  final irq2 = cpuTimes2[5];
  final softirq2 = cpuTimes2[6];
  final steal2 = cpuTimes2[7];

  // 计算总时间和空闲时间
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
  final cpuUsage = 1.0 - (idleDelta / totalDelta);
  return (cpuUsage * 100).clamp(0.0, 100.0);
}

Future<List<int>> getCPUTimes() async {
  try {
    String statContent = await Process.run('cat', ['/proc/stat']).then((result) => result.stdout);
    final lines = statContent.split('\n');
    final cpuLine = lines.firstWhere((line) => line.startsWith('cpu '), orElse: () => '');
    if (cpuLine.isEmpty) return [];
    return cpuLine.trim().split(RegExp('\\s+')).skip(1).map(int.parse).toList();
  } catch (e) {
    return [];
  }
}

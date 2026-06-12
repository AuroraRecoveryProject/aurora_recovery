import 'package:aurora_recovery/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:global_repository/global_repository.dart';
import 'package:aurora_recovery/services/device_info_service.dart';

class DeviceInfoOverlay extends StatefulWidget {
  const DeviceInfoOverlay({super.key});

  @override
  State<DeviceInfoOverlay> createState() => _DeviceInfoOverlayState();
}

class _DeviceInfoOverlayState extends State<DeviceInfoOverlay> {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: FakeSafearea(
        child: IgnorePointer(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacityExact(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: GetBuilder(
                init: DeviceInfoInstance,
                global: false,
                builder: (_) {
                  TextStyle infoStyle = TextStyle(
                    fontSize: $(12),
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  );
                  return Container(
                    padding: EdgeInsets.all($(8)),
                    child: Material(
                      color: Colors.transparent,
                      child: DefaultTextStyle(
                        style: infoStyle,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              spacing: $(12),
                              children: [
                                Text(
                                  'CPU: ${DeviceInfoInstance.cpuUsage.toStringAsFixed(2)}%'
                                  '    '
                                  '${_formatTemperature(DeviceInfoInstance.cpuTemperature)}',
                                ),
                                Text('GPU: ${DeviceInfoInstance.gpuUsage.toStringAsFixed(2)}%'),
                                Text('Battery: ${DeviceInfoInstance.batteryValue}'),
                              ],
                            ),
                            for (int i = 0; i < DeviceInfoInstance.cpuCoreUsages.length / 2; i++) ...[
                              Builder(builder: (context) {
                                final cpuCoreCount = DeviceInfoInstance.cpuCoreUsages.length;
                                String usuage = DeviceInfoInstance.cpuCoreUsages[i].toStringAsFixed(2);
                                // convert usuage to 6 characters, if usuage is less than 10, add a space before it
                                usuage = '$usuage%'.padLeft(6);
                                final frequencyValue = DeviceInfoInstance.cpuCoreFrequencies[i];
                                String frequency = DeviceInfoInstance.formatCpuFrequency(frequencyValue);
                                // convert frequency to 7 characters, if frequency is less than 1000 MHz, add a space before it
                                frequency = frequency.padLeft(7);
                                String usuage2 =
                                    DeviceInfoInstance.cpuCoreUsages[i + cpuCoreCount ~/ 2].toStringAsFixed(2);
                                final frequencyValue2 = DeviceInfoInstance.cpuCoreFrequencies[i + cpuCoreCount ~/ 2];
                                String frequency2 = DeviceInfoInstance.formatCpuFrequency(frequencyValue2);
                                // convert frequency2 to 7 characters, if frequency2 is less than 1000 MHz, add a space before it
                                frequency2 = frequency2.padLeft(7);
                                // convert usuage2 to 6 characters, if usuage2 is less than 10, add a space before it
                                usuage2 = '$usuage2%'.padLeft(6);
                                return Text(
                                  'Core $i: $usuage'
                                  '  '
                                  '$frequency'
                                  '  '
                                  'Core ${i + cpuCoreCount ~/ 2}: $usuage2'
                                  '  '
                                  '$frequency2',
                                  style: TextStyle(
                                    fontSize: $(10),
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'DroidSansMono',
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTemperature(double value) {
    if (value < 0) {
      return '--°C';
    }
    return '${value.toStringAsFixed(1)}°C';
  }
}

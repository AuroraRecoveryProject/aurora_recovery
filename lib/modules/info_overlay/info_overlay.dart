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
    return IgnorePointer(
      child: Padding(
        padding: EdgeInsets.all($(4)),
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
                  child: DefaultTextStyle(
                    style: infoStyle,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      spacing: $(12),
                      children: [
                        Text('CPU: ${DeviceInfoInstance.cpuUsage.toStringAsFixed(2)}%'),
                        Text('GPU: ${DeviceInfoInstance.gpuUsage.toStringAsFixed(2)}%'),
                        Text('Battery: ${DeviceInfoInstance.batteryValue}'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:aurora_recovery/widgets/fake_safearea.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'services/global.dart';
import 'widgets/view_metric.dart';

class ArpDrawer<T> extends StatefulWidget {
  const ArpDrawer({
    super.key,
    this.onItemSelected,
    required this.items,
  });
  final void Function(T value)? onItemSelected;
  final List<ArpDrawerItem<T>> items;

  @override
  State<ArpDrawer<T>> createState() => _ArpDrawerState<T>();
}

class _ArpDrawerState<T> extends State<ArpDrawer<T>> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      child: FakeSafearea(
        top: ResponsiveBreakpoints.of(context).isMobile,
        child: SizedBox(
          width: 200,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: $(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: $(8),
                children: [
                  for (var item in widget.items)
                    Builder(
                      builder: (context) {
                        bool isSelected = item.value == item.groupValue;
                        final backgroundColor = isSelected ? colorScheme.surfaceContainerHigh : Colors.transparent;
                        return Ink(
                          height: $(48),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular($(8)),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular($(8)),
                            onTap: () {
                              widget.onItemSelected?.call(item.value);
                            },
                            child: Center(child: item),
                          ),
                        );
                      },
                    ),
                  GetBuilder(
                    init: Global,
                    global: false,
                    builder: (context) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CPU:       ${Global.cpuUsage.toStringAsFixed(2)}%'),
                          Text('GPU:       ${Global.gpuKernelUsage.toStringAsFixed(2)}%'),
                          Text('Battery: ${Global.batteryValue}'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ArpDrawerItem<T> extends StatefulWidget {
  const ArpDrawerItem({
    super.key,
    required this.value,
    required this.child,
    required this.groupValue,
  });
  final T value;
  final T groupValue;
  final Widget child;

  @override
  State<ArpDrawerItem> createState() => _ArpDrawerItemState();
}

class _ArpDrawerItemState extends State<ArpDrawerItem> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: colorScheme.onSurface),
      child: widget.child,
    );
  }
}

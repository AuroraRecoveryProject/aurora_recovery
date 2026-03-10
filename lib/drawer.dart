import 'package:flutter/material.dart';
import 'package:get/get_state_manager/get_state_manager.dart';

import 'global.dart';

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
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SizedBox(
        width: 200,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
            child: Column(
              spacing: 8,
              children: [
                for (var item in widget.items)
                  Builder(
                    builder: (context) {
                      final backgroundColor = item.value == item.groupValue
                          ? Theme.of(context).colorScheme.surfaceContainerHigh
                          : Theme.of(context).colorScheme.surfaceContainerLow;
                      return Ink(
                        height: 48,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
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
                  builder: (context) {
                    return Text(
                      'CPU: ${Global.cpuUsage.toStringAsFixed(2)}%\nGPU: ${Global.gpuKernelUsage.toStringAsFixed(2)}%',
                    );
                  },
                ),
              ],
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
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).colorScheme.onSurface),
      child: widget.child,
    );
  }
}

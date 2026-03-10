import 'dart:ffi';

import 'package:aurora_recovery/global.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

import '../generated_bindings.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  double _value = 50;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Battery: ${Global.batteryValue}"),
          Text("Brightness"),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              showValueIndicator: ShowValueIndicator.always,
            ),
            child: Slider(
              value: _value,
              min: 0,
              max: 100,
              label: _value.toStringAsFixed(0),
              onChanged: (value) {
                _value = value;
                Global.bindings.tw_display_set_brightness_percent(_value.toInt());
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }
}

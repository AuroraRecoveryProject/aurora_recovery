import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:aurora_recovery/root.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:xterm/xterm.dart';

import 'global.dart';
import 'heavy_demo/heavy_ui_demo.dart';
import 'setting/setting.dart';

// TODO
// 增加 CPU 频率展示
// 增加内存占用展示
// 增加磁盘占用展示
void main() {
  runApp(const AuroraRecoveryApp());
  Global.init();
}

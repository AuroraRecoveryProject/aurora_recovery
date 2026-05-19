import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:aurora_recovery/root.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:xterm/xterm.dart';

import 'services/global.dart';
import 'demo/heavy_demo/heavy_ui_demo.dart';
import 'setting/setting.dart';

void main() {
  runApp(const AuroraRecoveryApp());
  Global.init();
}

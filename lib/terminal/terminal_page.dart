import 'dart:convert';
import 'dart:io';

import 'package:aurora_recovery/widgets/toast.dart';
import 'package:aurora_recovery/widgets/fake_safearea.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:xterm/xterm.dart';

import '../virtual_keyboard/twrp_keyboard.dart';

class TerminalPage extends StatefulWidget {
  const TerminalPage({super.key});

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  final terminal = Terminal(maxLines: 10000);
  final terminalController = TerminalController();
  late final Pty pty;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.endOfFrame.then((_) {
      if (mounted) _startPty();

      Toast.show("左侧滑动可以打开抽屉哦~");
    });
  }

  void _startPty() {
    pty = Pty.start(
      'sh',
      columns: terminal.viewWidth,
      rows: terminal.viewHeight,
      environment: {
        'TERM': 'xterm-256color',
        'PATH': '/tmp:${Platform.environment['PATH'] ?? ''}',
      },
    );

    pty.output.cast<List<int>>().transform(Utf8Decoder()).listen((data) {
      terminal.write(data);
    });

    pty.exitCode.then((code) {
      terminal.write('the process exited with exit code $code\r\n');
    });

    terminal.onOutput = (data) {
      pty.write(const Utf8Encoder().convert(data));
    };

    terminal.onResize = (w, h, pw, ph) {
      pty.resize(h, w);
    };
    terminal.write('Terminal ready.\r\n');
    terminal.write('Use color_print to display colors.\r\n');
    terminal.write('Use cmatrix to display matrix effect.\r\n');
    terminal.write('Use nettest to test network.\r\n');
    // pty.write(utf8.encode('wpa_cli -iwlan0 -p/tmp/recovery/sockets status\r\n'));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: defaultTheme.background,
      child: FakeSafearea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // return Center(child: CircularProgressIndicator());
            return Column(
              children: [
                // Padding(
                //   padding: const EdgeInsets.all(8),
                //   child: Row(
                //     children: [
                //       ElevatedButton(
                //         onPressed: _ptyReady ? _flashMagiskTest : null,
                //         child: const Text(
                //           '刷入 Magisk（测试）',
                //           style: TextStyle(color: Colors.white70),
                //         ),
                //       ),
                //       const SizedBox(width: 12),
                //       const Expanded(
                //         child: Text(
                //           '固定路径：/tmp/Magisk-v30.7.apk（仅测试链路）',
                //           style: TextStyle(color: Colors.white70),
                //           overflow: TextOverflow.ellipsis,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                Expanded(
                  child: TerminalView(
                    terminal,
                    controller: terminalController,
                    autofocus: true,
                    backgroundOpacity: 1,
                    theme: defaultTheme,
                    textStyle: TerminalStyle(fontSize: 14, fontFamily: 'DroidSansMono'),
                  ),
                ),
                TwrpKeyboard(
                  mode: TwKeyboardMode.full,
                  onText: (text) {
                    pty.write(utf8.encode(text));
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

const defaultTheme = TerminalTheme(
  cursor: Color(0XAAAEAFAD),
  selection: Color(0XAAAEAFAD),
  foreground: Color(0XFFCCCCCC),
  background: Color(0xFF000000),
  black: Color(0XFF000000),
  red: Color(0XFFCD3131),
  green: Color(0XFF0DBC79),
  yellow: Color(0XFFE5E510),
  blue: Color(0XFF2472C8),
  magenta: Color(0XFFBC3FBC),
  cyan: Color(0XFF11A8CD),
  white: Color(0XFFE5E5E5),
  brightBlack: Color(0XFF666666),
  brightRed: Color(0XFFF14C4C),
  brightGreen: Color(0XFF23D18B),
  brightYellow: Color(0XFFF5F543),
  brightBlue: Color(0XFF3B8EEA),
  brightMagenta: Color(0XFFD670D6),
  brightCyan: Color(0XFF29B8DB),
  brightWhite: Color(0XFFFFFFFF),
  searchHitBackground: Color(0XFFFFFF2B),
  searchHitBackgroundCurrent: Color(0XFF31FF26),
  searchHitForeground: Color(0XFF000000),
);

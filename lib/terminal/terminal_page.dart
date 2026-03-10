import 'dart:convert';
import 'dart:io';

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
  bool _ptyReady = false;

  static const String _magiskApkPath = '/tmp/Magisk-v30.7.apk';

  void _flashMagiskTest() async {
    pty.write(utf8.encode("source /tmp/arp_flash.sh\n"));

    // 4. Call the function
    terminal.write('[ARP] >>> Invoking arp_flash_zip...\r\n');
    pty.write(utf8.encode("arp_flash_zip '$_magiskApkPath'\n"));
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.endOfFrame.then((_) {
      if (mounted) _startPty();
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
    _ptyReady = true;

    pty.output.cast<List<int>>().transform(Utf8Decoder()).listen((data) {
      // print('pty output: $data');
      terminal.write(data);
    });

    pty.exitCode.then((code) {
      terminal.write('the process exited with exit code $code');
    });

    terminal.onOutput = (data) {
      // print('terminal output: $data');
      pty.write(const Utf8Encoder().convert(data));
    };

    terminal.onResize = (w, h, pw, ph) {
      pty.resize(h, w);
    };
    // pty.write(utf8.encode("(cat /system/bin/orsout &) ; echo -n 'install /tmp/Magisk-v30.7.apk' > /system/bin/orsin"));
    terminal.write('\r\n[ARP] Terminal ready. Press the button to run flash test.\r\n');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
                backgroundOpacity: 0.7,
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
    );
  }
}

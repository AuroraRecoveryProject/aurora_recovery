import 'package:aurora_recovery/terminal/terminal_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xterm/xterm.dart';
import 'package:aurora_recovery/common/l10n.dart';
import 'package:aurora_recovery/services/flash_rom_service.dart';

// ignore: depend_on_referenced_packages
import 'package:global_repository/global_repository.dart';

class FlashRomDialog extends StatefulWidget {
  const FlashRomDialog({super.key, required this.filePath});
  final String filePath;

  @override
  State<FlashRomDialog> createState() => _FlashRomDialogState();
}

class _FlashRomDialogState extends State<FlashRomDialog> {
  Terminal terminal = Terminal();
  @override
  void initState() {
    super.initState();
    FlashRomService.instance.startInstall(widget.filePath, onLog: (log) {
      for (final line in log.split('\n')) {
        terminal.write('${line.trim()}\r\n');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        width: $(400),
        height: $(500),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular($(8)),
        ),
        child: Material(
          elevation: $(4),
          borderRadius: BorderRadius.circular($(8)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              SizedBox(height: $(12)),
              Text('${l10n.flash} ${widget.filePath}'),
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: Padding(
                    padding: EdgeInsets.all($(12)),
                    child: TerminalView(
                      terminal,
                      theme: defaultTheme,
                      backgroundOpacity: 0,
                      textStyle: TerminalStyle.fromTextStyle(
                        TextStyle(
                          fontSize: $(12),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Get.back();
                    },
                    child: Text(l10n.close),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

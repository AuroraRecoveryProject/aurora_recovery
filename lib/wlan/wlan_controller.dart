import 'dart:convert';
import 'dart:io';

import 'package:aurora_recovery/virtual_keyboard/twrp_keyboard.dart';
import 'package:aurora_recovery/virtual_keyboard/virtual_keyboard.dart';
import 'package:aurora_recovery/widgets/toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:signale/signale.dart';

import 'wifi_result.dart';

class WlanController extends GetxController {
  List<WifiResult> networks = const <WifiResult>[];
  bool isLoading = false;
  bool isConnecting = false;
  String? error;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  String detectEncryption(String flags) {
    if (flags.contains('SAE')) return 'WPA3';
    if (flags.contains('WPA2')) return 'WPA2';
    if (flags.contains('WPA-PSK') || flags.contains('WPA')) return 'WPA';
    return 'Open';
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    update();

    try {
      // wpa_cli -iwlan0 -p/tmp/recovery/sockets scan
      // wpa_cli -iwlan0 -p/tmp/recovery/sockets scan_results
      ProcessResult result = await _runWpaCli(['scan']);

      await Future<void>.delayed(const Duration(seconds: 2));

      result = await _runWpaCli(['scan_results']);

      final networks = WifiResult.parseScanResults(result.stdout.toString());

      this.networks = networks;
    } catch (error) {
      this.error = error.toString();
      networks = const <WifiResult>[];
    } finally {
      isLoading = false;
    }
    update();
  }

  Future<void> connectToNetwork(WifiResult network) async {
    final String? password;
    if (network.requiresPassword) {
      password = await _showPasswordDialog(network);
      if (password == null) {
        return;
      }
    } else {
      password = null;
    }

    isConnecting = true;
    error = null;
    update();

    // wpa_cli -iwlan0 -p/tmp/recovery/sockets remove_network 0
    // wpa_cli -iwlan0 -p/tmp/recovery/sockets add_network
    // wpa_cli -iwlan0 -p/tmp/recovery/sockets set_network 0 ssid '"Laurie Lin 5G"'
    // wpa_cli -iwlan0 -p/tmp/recovery/sockets set_network 0 key_mgmt WPA-PSK
    // wpa_cli -iwlan0 -p/tmp/recovery/sockets set_network 0 psk '"<密码明文>"'
    // wpa_cli -iwlan0 -p/tmp/recovery/sockets enable_network 0
    // wpa_cli -iwlan0 -p/tmp/recovery/sockets status

    try {
      final addNetwork = await _runWpaCli(['add_network']);
      final networkId = addNetwork.stdout.toString().trim();
      final parsedId = int.tryParse(networkId);
      if (parsedId == null) {
        throw StateError('add_network 返回了无效的网络 ID: $networkId');
      }

      await _runWpaCli(['set_network', networkId, 'ssid', network.ssid]);

      if (network.requiresPassword) {
        await _runWpaCli(['set_network', networkId, 'key_mgmt', detectEncryption(network.flags.join(''))]);
        await _runWpaCli(['set_network', networkId, 'psk', password!]);
      } else {
        await _runWpaCli(['set_network', networkId, 'key_mgmt', 'NONE']);
      }

      await _runWpaCli(['enable_network', networkId]);
      await _runWpaCli(['select_network', networkId]);
      while (true) {
        final statusResult = await _runWpaCli(['status']);
        final status = WifiStatus.parse(statusResult.stdout.toString());
        Log.i('连接状态: $status');
        if (status.isConnected) {
          break;
        }
      }

      Toast.show('已连接到 ${network.displayName}');
      await load();
    } catch (error) {
      this.error = error.toString();
      Toast.show('连接失败: ${this.error}');
      update();
    } finally {
      isConnecting = false;
      update();
    }
  }

  Future<ProcessResult> _runWpaCli(List<String> args) async {
    final commandArgs = ['-p', '/tmp/recovery/sockets', '-iwlan0', ...args];
    final result = await Process.run('wpa_cli', commandArgs);
    if (result.exitCode == 0) {
      final stdout = result.stdout.toString().trim();
      final stderr = result.stderr.toString().trim();
      // Log.i(
      //     'socketPath: /tmp/recovery/sockets, command: wpa_cli ${commandArgs.join(' ')}, stdout: $stdout, stderr: $stderr');
      return result;
    }
    throw ProcessException('wpa_cli', commandArgs, 'wpa_cli returned non-zero exit code', result.exitCode);
  }

  final controller = TextEditingController();
  Future<String?> _showPasswordDialog(WifiResult network) async {
    bool obscureText = false;

    return showDialog<String>(
      context: Get.context!,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('连接 ${network.displayName}'),
              content: TextField(
                controller: controller,
                autofocus: true,
                obscureText: obscureText,
                onTap: () {
                  VirtualKeyboard.show((String value) {
                    if (value.codeUnits.first == 127) {
                      if (controller.text.isNotEmpty) {
                        controller.text = controller.text.substring(0, controller.text.length - 1);
                        controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
                      }
                      return;
                    }
                    controller.text = controller.text + value;
                    controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
                  });
                },
                decoration: InputDecoration(
                  labelText: '密码',
                  suffixIcon: IconButton(
                    onPressed: () {
                      obscureText = !obscureText;
                      setState(() {});
                    },
                    icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
                  ),
                ),
                onSubmitted: (String value) {
                  Navigator.of(context).pop(value);
                },
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    VirtualKeyboard.hide();
                  },
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(controller.text.trim());
                    VirtualKeyboard.hide();
                  },
                  child: const Text('连接'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

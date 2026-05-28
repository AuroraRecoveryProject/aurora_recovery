import 'dart:io';

import 'package:flutter/material.dart';
import 'package:signale/signale.dart';
import 'package:get/get.dart';

import 'package:aurora_recovery/modules/virtual_keyboard/virtual_keyboard.dart';
import 'package:aurora_recovery/widgets/toast.dart';
import 'package:aurora_recovery/common/l10n.dart';
import 'wifi_result.dart';

enum WifiConnectionState {
  idle,
  connecting,
  connected,
  dhcp,
}

class WifiController extends GetxController {
  List<WifiResult> networks = const <WifiResult>[];
  bool isLoading = false;
  WifiConnectionState connectionState = WifiConnectionState.idle;
  String? currentBssid;
  String wpaCliPrefix = 'wpa_cli -iwlan0 -p/tmp/recovery/sockets';

  @override
  void onInit() {
    super.onInit();
    load();
  }

  String detectEncryption(String flags) {
    if (flags.contains('SAE')) return 'WPA3';
    if (flags.contains('WPA2-PSK')) return 'WPA-PSK';
    if (flags.contains('WPA2')) return 'WPA2';
    if (flags.contains('WPA-PSK') || flags.contains('WPA')) return 'WPA';
    return 'Open';
  }

  Future<void> load() async {
    isLoading = true;
    update();

    try {
      await runCommand('$wpaCliPrefix scan');
      int maxRetries = 10;
      int retryCount = 0;
      String result;
      while (true) {
        await Future<void>.delayed(const Duration(seconds: 1));
        result = await runCommand('$wpaCliPrefix scan_results');
        if (result.contains('bssid / frequency / signal level / flags / ssid')) break;
        retryCount++;
        if (retryCount >= maxRetries) {
          throw StateError('Failed to get scan results after $maxRetries attempts');
        }
      }

      final networks = WifiResult.parseScanResults(result);
      Log.i('Scan results: ${networks.join('\n')}');
      final statusResult = await runCommand('$wpaCliPrefix status');
      final status = WifiStatus.parse(statusResult);

      this.networks = networks;
      _syncConnectionState(status, scannedNetworks: networks);
    } catch (error) {
      networks = const <WifiResult>[];
      connectionState = WifiConnectionState.idle;
      currentBssid = null;
    } finally {
      isLoading = false;
    }
    update();
  }

  bool isCurrentNetwork(WifiResult network) {
    return currentBssid != null && currentBssid!.isNotEmpty && currentBssid == network.bssid;
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

    connectionState = WifiConnectionState.connecting;
    currentBssid = network.bssid;
    update();

    // wpa_cli -iwlan0 -p/tmp/recovery/sockets remove_network 0
    // wpa_cli -iwlan0 -p/tmp/recovery/sockets add_network
    // wpa_cli -iwlan0 -p/tmp/recovery/sockets set_network 0 ssid '"Laurie Lin 5G"'
    // wpa_cli -iwlan0 -p/tmp/recovery/sockets set_network 0 key_mgmt WPA-PSK
    // wpa_cli -iwlan0 -p/tmp/recovery/sockets set_network 0 psk '"<password>"'
    // wpa_cli -iwlan0 -p/tmp/recovery/sockets enable_network 0
    // wpa_cli -iwlan0 -p/tmp/recovery/sockets status

    try {
      final networkId = await runCommand('$wpaCliPrefix add_network');
      final parsedId = int.tryParse(networkId);
      if (parsedId == null) {
        throw StateError('add_network returned an invalid network ID: $networkId');
      }
      await runCommand('$wpaCliPrefix set_network $networkId ssid \\"${network.ssid}\\"');

      if (network.requiresPassword) {
        await runCommand('$wpaCliPrefix set_network $networkId key_mgmt ${detectEncryption(network.flags.join(''))}');
        await runCommand('$wpaCliPrefix set_network $networkId psk \\"$password\\"');
      } else {
        await runCommand('$wpaCliPrefix set_network $networkId key_mgmt NONE');
      }

      // final enableNetwork = await _runWpaCli(['enable_network', networkId]);
      // Log.i('Enable network result: ${enableNetwork.stdout} ${enableNetwork.stderr}');
      await runCommand('$wpaCliPrefix enable_network $networkId');
      // final selectNetwork = await _runWpaCli(['select_network', networkId]);
      // Log.i('Select network result: ${selectNetwork.stdout} ${selectNetwork.stderr}');
      await runCommand('$wpaCliPrefix select_network $networkId');
      while (true) {
        final statusResult = await runCommand('$wpaCliPrefix status');
        final status = WifiStatus.parse(statusResult);
        Log.i('Connection status: $status');
        if (status.isConnected) {
          _syncConnectionState(status, fallbackNetwork: network);
          update();
          break;
        }
        await Future<void>.delayed(const Duration(seconds: 1));
      }

      connectionState = WifiConnectionState.dhcp;
      update();

      String dhcpcdResult = await runCommand('dhcpcd wlan0');
      Log.i('dhcpcd result: $dhcpcdResult');

      Toast.show('Connected to ${network.displayName}');
      await load();
    } catch (error) {
      connectionState = WifiConnectionState.idle;
      currentBssid = null;
      Toast.show('Connection failed: $error');
      update();
    } finally {
      update();
    }
  }

  Future<String> runCommand(String command) async {
    try {
      final result = await Process.run('sh', ['-c', command]);
      if (result.exitCode == 0) {
        final resultStr = result.stdout.toString().trim();
        if (resultStr.contains('FAIL')) {
          throw ProcessException('sh', ['-c', command], 'Command failed: $resultStr', result.exitCode);
        }
        return resultStr;
      } else {
        throw ProcessException('sh', ['-c', command], 'Command returned non-zero exit code', result.exitCode);
      }
    } catch (e) {
      throw ProcessException('sh', ['-c', command], 'Failed to run command', -1);
    }
  }

  void _syncConnectionState(
    WifiStatus status, {
    List<WifiResult>? scannedNetworks,
    WifiResult? fallbackNetwork,
  }) {
    if (!status.isConnected) {
      if (connectionState != WifiConnectionState.connecting) {
        connectionState = WifiConnectionState.idle;
        currentBssid = null;
      }
      return;
    }

    final matchedNetwork = _findMatchedNetwork(status, scannedNetworks) ?? fallbackNetwork;
    connectionState = WifiConnectionState.connected;
    currentBssid = matchedNetwork?.bssid ?? status.bssid;
  }

  WifiResult? _findMatchedNetwork(WifiStatus status, List<WifiResult>? scannedNetworks) {
    if (scannedNetworks == null || scannedNetworks.isEmpty) {
      return null;
    }

    if (status.bssid.isNotEmpty) {
      for (final network in scannedNetworks) {
        if (network.bssid == status.bssid) {
          return network;
        }
      }
    }

    if (status.ssid.isNotEmpty) {
      for (final network in scannedNetworks) {
        if (network.ssid == status.ssid) {
          return network;
        }
      }
    }

    return null;
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
              title: Text('${l10n.connect} ${network.displayName}'),
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
                  labelText: l10n.password,
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
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(controller.text.trim());
                    VirtualKeyboard.hide();
                  },
                  child: Text(l10n.connect),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

class WlanPage extends StatefulWidget {
  const WlanPage({super.key});

  @override
  State<WlanPage> createState() => _WlanPageState();
}

class _WlanPageState extends State<WlanPage> {
  static const List<String> _controlSocketPaths = <String>[
    '/data/misc/wifi/wpa_supplicant',
    '/tmp/recovery/sockets',
  ];

  List<WifiNetwork> _networks = const <WifiNetwork>[];
  bool _isLoading = false;
  bool _isConnecting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // wpa_cli -iwlan0 -p/tmp/recovery/sockets scan
      // wpa_cli -iwlan0 -p/tmp/recovery/sockets scan_results
      ProcessResult result = await _runWpaCli(const <String>['scan']);

      await Future<void>.delayed(const Duration(seconds: 2));

      result = await _runWpaCli(const <String>['scan_results']);

      final networks = WifiNetwork.parseScanResults(result.stdout.toString());

      if (!mounted) {
        return;
      }

      setState(() {
        _networks = networks;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
        _networks = const <WifiNetwork>[];
      });
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            '连接WIFI',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 400,
                child: Builder(
                  builder: (_) {
                    if (_isLoading) return const LinearProgressIndicator();
                    if (_networks.isEmpty && !_isLoading && _error == null) {
                      return Center(
                        child: Text('未发现 WLAN 网络'),
                      );
                    }
                    return ListView.separated(
                      itemCount: _networks.length,
                      separatorBuilder: (BuildContext context, int index) => const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        final network = _networks[index];
                        return ListTile(
                          onTap: _isConnecting ? null : () => _connectToNetwork(network),
                          leading: Icon(
                            Icons.wifi,
                            color: _signalColor(network.signalLevel),
                          ),
                          title: Text(network.displayName),
                          subtitle: Text(
                            '${network.flagsText}  ${network.frequency} MHz  ${network.bandLabel}',
                          ),
                          trailing: _isConnecting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text('${network.signalLevel} dBm'),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _signalColor(int signalLevel) {
    if (signalLevel >= -50) {
      return Colors.green;
    }
    if (signalLevel >= -67) {
      return Colors.lightGreen;
    }
    if (signalLevel >= -75) {
      return Colors.orange;
    }
    return Colors.redAccent;
  }

  Future<void> _connectToNetwork(WifiNetwork network) async {
    final String? password;
    if (network.requiresPassword) {
      password = await _showPasswordDialog(network);
      if (password == null) {
        return;
      }
    } else {
      password = null;
    }

    setState(() {
      _isConnecting = true;
      _error = null;
    });

    try {
      final addNetwork = await _runWpaCli(const <String>['add_network']);
      final networkId = _extractLastNonEmptyLine(addNetwork.stdout.toString());
      final parsedId = int.tryParse(networkId);
      if (parsedId == null) {
        throw StateError('add_network 返回了无效的网络 ID: $networkId');
      }

      await _runWpaCli(<String>['set_network', '$parsedId', 'ssid', _quoteForWpaCli(network.ssid)]);

      if (network.requiresPassword) {
        await _runWpaCli(<String>[
          'set_network',
          '$parsedId',
          'psk',
          _quoteForWpaCli(password!),
        ]);
      } else {
        await _runWpaCli(<String>['set_network', '$parsedId', 'key_mgmt', 'NONE']);
      }

      await _runWpaCli(<String>['enable_network', '$parsedId']);
      await _runWpaCli(<String>['select_network', '$parsedId']);
      await Future<void>.delayed(const Duration(seconds: 8));

      final statusResult = await _runWpaCli(const <String>['status']);
      final status = WifiStatus.parse(statusResult.stdout.toString());
      if (!status.isConnected) {
        throw StateError(status.rawStatus.isEmpty ? '连接失败，wpa_cli 未返回有效状态' : status.rawStatus);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已连接到 ${network.displayName}')),
      );
      await load();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
      });
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isConnecting = false;
      });
    }
  }

  Future<String?> _showPasswordDialog(WifiNetwork network) async {
    final controller = TextEditingController();
    bool obscureText = true;

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('连接 ${network.displayName}'),
              content: TextField(
                controller: controller,
                autofocus: true,
                obscureText: obscureText,
                decoration: InputDecoration(
                  labelText: '密码',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscureText = !obscureText;
                      });
                    },
                    icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
                  ),
                ),
                onSubmitted: (String value) {
                  Navigator.of(context).pop(value.trim());
                },
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                  child: const Text('连接'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(controller.dispose);
  }

  Future<ProcessResult> _runWpaCli(List<String> args) async {
    ProcessException? lastException;

    for (final socketPath in _controlSocketPaths) {
      final commandArgs = <String>['-p', socketPath, '-iwlan0', ...args];
      final result = await Process.run('wpa_cli', commandArgs);
      if (result.exitCode == 0) {
        final stdout = result.stdout.toString().trim();
        final stderr = result.stderr.toString().trim();
        if (stdout == 'FAIL' || stderr == 'FAIL') {
          lastException = ProcessException('wpa_cli', commandArgs, 'FAIL', result.exitCode);
          continue;
        }
        return result;
      }

      lastException = ProcessException(
        'wpa_cli',
        commandArgs,
        result.stderr.toString(),
        result.exitCode,
      );
    }

    throw lastException ?? ProcessException('wpa_cli', args, '未找到可用的 wpa_supplicant 控制 socket', -1);
  }

  String _extractLastNonEmptyLine(String output) {
    final lines = const LineSplitter()
        .convert(output)
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList(growable: false);
    if (lines.isEmpty) {
      throw StateError('wpa_cli 没有返回可用内容');
    }
    return lines.last;
  }

  String _quoteForWpaCli(String value) {
    final escaped = value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    return '"$escaped"';
  }
}

class WifiNetwork {
  const WifiNetwork({
    required this.bssid,
    required this.frequency,
    required this.signalLevel,
    required this.flags,
    required this.ssid,
  });

  final String bssid;
  final int frequency;
  final int signalLevel;
  final List<String> flags;
  final String ssid;

  String get displayName => ssid.isEmpty ? '<隐藏网络>' : ssid;

  String get flagsText => flags.isEmpty ? 'OPEN' : flags.join(' ');

  bool get requiresPassword => flags.any((String flag) {
        return flag.contains('WPA') || flag.contains('WEP') || flag.contains('SAE') || flag.contains('PSK');
      });

  String get bandLabel {
    if (frequency >= 5925) {
      return '6 GHz';
    }
    if (frequency >= 5000) {
      return '5 GHz';
    }
    return '2.4 GHz';
  }

  static List<WifiNetwork> parseScanResults(String rawOutput) {
    final networks = <WifiNetwork>[];

    for (final line in const LineSplitter().convert(rawOutput)) {
      final trimmed = line.trimRight();
      if (trimmed.isEmpty || trimmed.startsWith('bssid /')) {
        continue;
      }

      final columns = trimmed.split('\t');
      if (columns.length < 4) {
        continue;
      }

      final frequency = int.tryParse(columns[1]);
      final signalLevel = int.tryParse(columns[2]);
      if (frequency == null || signalLevel == null) {
        continue;
      }

      final ssidColumn = columns.length > 4 ? columns.sublist(4).join('\t') : '';
      networks.add(
        WifiNetwork(
          bssid: columns[0],
          frequency: frequency,
          signalLevel: signalLevel,
          flags: _parseFlags(columns[3]),
          ssid: _decodeSsid(ssidColumn),
        ),
      );
    }

    networks.sort((WifiNetwork a, WifiNetwork b) => b.signalLevel.compareTo(a.signalLevel));
    return networks;
  }

  static List<String> _parseFlags(String rawFlags) {
    final matches = RegExp(r'\[([^\]]+)\]').allMatches(rawFlags);
    return matches.map((Match match) => match.group(1)!).toList(growable: false);
  }

  static String _decodeSsid(String rawSsid) {
    if (rawSsid.isEmpty || !rawSsid.contains(r'\x')) {
      return rawSsid;
    }

    final bytes = <int>[];
    int index = 0;
    while (index < rawSsid.length) {
      final isHexEscape = index + 3 < rawSsid.length && rawSsid[index] == r'\' && rawSsid[index + 1] == 'x';

      if (isHexEscape) {
        final hex = rawSsid.substring(index + 2, index + 4);
        final value = int.tryParse(hex, radix: 16);
        if (value != null) {
          bytes.add(value);
          index += 4;
          continue;
        }
      }

      bytes.addAll(utf8.encode(rawSsid[index]));
      index += 1;
    }

    return utf8.decode(bytes, allowMalformed: true);
  }
}

class WifiStatus {
  const WifiStatus({
    required this.state,
    required this.ssid,
    required this.rawStatus,
  });

  final String state;
  final String ssid;
  final String rawStatus;

  bool get isConnected => state == 'COMPLETED';

  static WifiStatus parse(String raw) {
    final values = <String, String>{};
    for (final line in const LineSplitter().convert(raw)) {
      final separatorIndex = line.indexOf('=');
      if (separatorIndex <= 0) {
        continue;
      }
      final key = line.substring(0, separatorIndex).trim();
      final value = line.substring(separatorIndex + 1).trim();
      values[key] = value;
    }

    return WifiStatus(
      state: values['wpa_state'] ?? '',
      ssid: values['ssid'] ?? '',
      rawStatus: raw.trim(),
    );
  }
}

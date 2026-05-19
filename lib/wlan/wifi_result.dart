import 'dart:convert';

import 'wifi_signal_strength.dart';

class WifiResult {
  const WifiResult({
    required this.bssid,
    required this.frequency,
    required this.flags,
    required this.ssid,
    required this.strength,
    required this.signalLevel,
  });

  final String bssid;
  final int frequency;
  final WifiSignalStrength strength;
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

  static List<WifiResult> parseScanResults(String rawOutput) {
    final networks = <WifiResult>[];

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
        WifiResult(
          bssid: columns[0],
          frequency: frequency,
          signalLevel: signalLevel,
          strength: WifiSignalStrength.fromRssi(signalLevel),
          flags: _parseFlags(columns[3]),
          ssid: _decodeSsid(ssidColumn),
        ),
      );
    }

    networks.sort((WifiResult a, WifiResult b) => b.signalLevel.compareTo(a.signalLevel));
    return networks;
  }

  static List<String> _parseFlags(String rawFlags) {
    final matches = RegExp(r'\[([^\]]+)\]').allMatches(rawFlags);
    return matches.map((Match match) => match.group(1)!).toList(growable: false);
  }

  static String _decodeSsid(String rawSsid) {
    // 中文 SSID 可能会被 wpa_cli 输出为类似于 \xE5\x93\x88\xE5\x93\x88 的格式，这里需要进行解码
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

  @override
  String toString() => 'WifiStatus(state: $state, ssid: $ssid rawStatus: $rawStatus)';
}

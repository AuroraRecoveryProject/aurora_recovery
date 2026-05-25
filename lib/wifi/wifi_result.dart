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

  String get displayName => ssid.isEmpty ? '<Hide Network>' : ssid;

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

  // 中文 SSID 可能会被 wpa_cli 输出为类似于 \xE5\x93\x88\xE5\x93\x88 的格式，这里需要进行解码
  // Chinese SSIDs may be output by wpa_cli in a format like \xE5\x93\x88\xE5\x93\x88, which needs to be decoded here
  static String _decodeSsid(String ssid) {
    if (!ssid.contains(r'\x')) {
      return ssid;
    }

    final bytes = <int>[];

    ssid.replaceAllMapped(RegExp(r'\\x([0-9A-Fa-f]{2})|(.)'), (m) {
      if (m[1] != null) {
        bytes.add(int.parse(m[1]!, radix: 16));
      } else {
        bytes.addAll(utf8.encode(m[2]!));
      }
      return '';
    });

    return utf8.decode(bytes, allowMalformed: true);
  }

  @override
  String toString() {
    return 'WifiResult(bssid: $bssid, frequency: $frequency, signalLevel: $signalLevel, strength: $strength, flags: ${flags.join(' ')}, ssid: $ssid)';
  }
}

class WifiStatus {
  const WifiStatus({
    required this.state,
    required this.bssid,
    required this.ssid,
    required this.rawStatus,
  });

  final String state;
  final String bssid;
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
      bssid: values['bssid'] ?? '',
      ssid: WifiResult._decodeSsid(values['ssid'] ?? ''),
      rawStatus: raw.trim(),
    );
  }

  @override
  String toString() => 'WifiStatus(state: $state, bssid: $bssid, ssid: $ssid rawStatus: $rawStatus)';
}

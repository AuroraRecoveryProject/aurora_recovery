enum WifiSignalStrength {
  none,
  veryWeak,
  weak,
  medium,
  strong,
  veryStrong;

  static WifiSignalStrength fromRssi(int rssi) {
    if (rssi <= -100) {
      return WifiSignalStrength.none;
    } else if (rssi <= -85) {
      return WifiSignalStrength.veryWeak;
    } else if (rssi <= -75) {
      return WifiSignalStrength.weak;
    } else if (rssi <= -65) {
      return WifiSignalStrength.medium;
    } else if (rssi <= -55) {
      return WifiSignalStrength.strong;
    } else {
      return WifiSignalStrength.veryStrong;
    }
  }
}

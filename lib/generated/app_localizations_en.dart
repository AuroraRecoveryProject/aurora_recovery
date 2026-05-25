// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get theme_preview => 'Theme preview';

  @override
  String get shader => 'Shader';

  @override
  String get heavy_ui => 'Heavy UI';

  @override
  String get animation => 'Animation';

  @override
  String get multi_finger => 'Multi-finger recognition';

  @override
  String get counter => 'Counter';

  @override
  String get terminal => 'Terminal';

  @override
  String get terminal_tips => 'Swipe from the left to open the drawer~';

  @override
  String get file_manager => 'File Manager';

  @override
  String get wlan => 'WLAN';

  @override
  String get setting => 'Setting';

  @override
  String get video_player => 'Video Player';

  @override
  String get flash => 'Flash';

  @override
  String flash_romt_tips(Object name) {
    return 'Press confirm to flash $name, please make sure this is a valid ROM package.\nNote: This feature has not been tested extensively, please consider carefully!';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get battery => 'Battery';

  @override
  String get brightness => 'Brightness';

  @override
  String get show_performance_overlay => 'Show Flutter performance overlay';

  @override
  String get reboot => 'Reboot';

  @override
  String get demo => 'Demo';

  @override
  String get connect => 'Connect';

  @override
  String get password => 'Password';

  @override
  String get no_wifi => 'No WIFI network found';

  @override
  String get getting_ip => 'Getting IP address';

  @override
  String get connecting => 'Connecting';

  @override
  String get connected => 'Connected';

  @override
  String get close => 'Close';
}

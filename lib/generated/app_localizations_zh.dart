// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class L10nZh extends L10n {
  L10nZh([String locale = 'zh']) : super(locale);

  @override
  String get theme_preview => '主题预览';

  @override
  String get shader => '着色器';

  @override
  String get heavy_ui => '耗时UI';

  @override
  String get animation => '动画';

  @override
  String get multi_finger => '多指识别';

  @override
  String get counter => '计数器';

  @override
  String get terminal => '终端';

  @override
  String get terminal_tips => '左侧滑动可以打开抽屉哦~';

  @override
  String get file_manager => '文件管理器';

  @override
  String get wlan => 'WLAN';

  @override
  String get setting => '设置';

  @override
  String get video_player => '视频播放器';

  @override
  String get flash => '刷入';

  @override
  String flash_romt_tips(Object name) {
    return '按下确认将刷入 $name，请确保这是一个有效的刷机包。\n注意：这个功能还未大量测试，请慎重考虑！';
  }

  @override
  String get cancel => '取消';

  @override
  String get battery => '电池';

  @override
  String get brightness => '亮度';

  @override
  String get show_performance_overlay => '显示Flutter性能图层';

  @override
  String get reboot => '重启';

  @override
  String get demo => '示例';

  @override
  String get connect => '连接';

  @override
  String get password => '密码';

  @override
  String get no_wifi => '未发现 WIFI 网络';

  @override
  String get getting_ip => '获取 IP 地址中';

  @override
  String get connecting => '正在连接';

  @override
  String get connected => '已连接';

  @override
  String get close => '关闭';

  @override
  String get language => '语言';
}

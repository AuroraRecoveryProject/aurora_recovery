import 'dart:convert';
import 'dart:io';

import 'package:aurora_recovery/widgets/toast.dart';
import 'package:aurora_recovery/widgets/view_metric.dart';
import 'package:aurora_recovery/virtual_keyboard/twrp_keyboard.dart';
import 'package:aurora_recovery/widgets/fake_safearea.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:signale/signale.dart';

import 'wifi_result.dart';
import 'wifi_signal_strength.dart';
import 'wlan_controller.dart';

class WlanPage extends StatefulWidget {
  const WlanPage({super.key});

  @override
  State<WlanPage> createState() => _WlanPageState();
}

class _WlanPageState extends State<WlanPage> {
  WlanController controller = WlanController();
  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveBreakpoints.of(context).isDesktop;
    return FakeSafearea(
      top: ResponsiveBreakpoints.of(context).isMobile,
      child: Scaffold(
        appBar: AppBar(
          title: Text("WIFI设置"),
          leadingWidth: $(48 + 16),
          forceMaterialTransparency: true,
          leading: isDesktop
              ? null
              : IconButton(
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                  icon: Icon(
                    Icons.menu,
                    size: $(24),
                  ),
                ),
        ),
        body: GetBuilder(
            init: controller,
            builder: (context) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Center(
                      child: Builder(builder: (context) {
                        bool isDesktop = ResponsiveBreakpoints.of(context).isDesktop;
                        final width = isDesktop ? double.infinity : $(400 - 16);
                        return SizedBox(
                          width: width,
                          child: Builder(
                            builder: (_) {
                              if (controller.isLoading) return const LinearProgressIndicator();
                              if (controller.networks.isEmpty && !controller.isLoading && controller.error == null) {
                                return Center(
                                  child: Text('未发现 WLAN 网络'),
                                );
                              }
                              return ListView.separated(
                                itemCount: controller.networks.length,
                                separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 1),
                                itemBuilder: (BuildContext context, int index) {
                                  final network = controller.networks[index];
                                  return ListTile(
                                    onTap: controller.isConnecting ? null : () => controller.connectToNetwork(network),
                                    leading: SvgPicture.asset(
                                      getSignalSvg(network.strength),
                                      width: $(24),
                                      height: $(24),
                                      colorFilter: ColorFilter.mode(
                                        Theme.of(context).colorScheme.onSurfaceVariant,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                    title: Text(network.displayName),
                                    subtitle: Text(
                                      '${network.flagsText}  ${network.frequency} MHz  ${network.bandLabel}',
                                    ),
                                    trailing: controller.isConnecting
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
                        );
                      }),
                    ),
                  ),
                ],
              );
            }),
      ),
    );
  }

  String getSignalSvg(WifiSignalStrength strength) {
    switch (strength) {
      case WifiSignalStrength.veryStrong:
        return 'assets/icons/wifi.svg';
      case WifiSignalStrength.strong:
        return 'assets/icons/wifi-high.svg';
      default:
        return 'assets/icons/wifi-low.svg';
    }
  }
}

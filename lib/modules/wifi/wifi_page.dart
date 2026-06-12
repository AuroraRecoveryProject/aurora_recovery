import 'package:aurora_recovery/common/assets.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:global_repository/global_repository.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import 'package:aurora_recovery/widgets/fake_safearea.dart';
import 'package:aurora_recovery/common/l10n.dart';
import 'wifi_signal_strength.dart';
import 'wifi_controller.dart';
import 'wifi_result.dart';

class WifiPage extends StatefulWidget {
  const WifiPage({super.key});

  @override
  State<WifiPage> createState() => _WifiPageState();
}

class _WifiPageState extends State<WifiPage> {
  WifiController controller = WifiController();
  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveBreakpoints.of(context).isDesktop;
    Widget? leading;
    if (!isDesktop) {
      leading = IconButton(
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
        icon: SvgPicture.asset(
          Assets.menuIcon,
          width: $(24),
          height: $(24),
          colorFilter: ColorFilter.mode(
            Theme.of(context).colorScheme.onSurfaceVariant,
            BlendMode.srcIn,
          ),
        ),
      );
    }
    return FakeSafearea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("WIFI ${l10n.setting}"),
          leadingWidth: $(48 + 16),
          forceMaterialTransparency: true,
          leading: leading,
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
                            if (controller.isLoading) {
                              return LoadingProgress(
                                minRadius: $(10),
                                strokeWidth: $(3),
                                increaseRadius: $(4),
                              );
                            }
                            if (controller.networks.isEmpty && !controller.isLoading) {
                              return Center(
                                child: Text(l10n.no_wifi),
                              );
                            }
                            return ListView.separated(
                              itemCount: controller.networks.length,
                              separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 1),
                              itemBuilder: (BuildContext context, int index) {
                                final network = controller.networks[index];
                                final isCurrentNetwork = controller.isCurrentNetwork(network);
                                return ListTile(
                                  onTap: controller.connectionState == WifiConnectionState.connecting
                                      ? null
                                      : () => controller.connectToNetwork(network),
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
                                    _buildSubtitle(network, controller.connectionState, isCurrentNetwork),
                                  ),
                                  trailing: _buildTrailing(
                                    context,
                                    network,
                                    controller.connectionState,
                                    isCurrentNetwork,
                                  ),
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
          },
        ),
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

  String _buildSubtitle(WifiResult network, WifiConnectionState connectionState, bool isCurrentNetwork) {
    final details = '${network.flagsText}  ${network.frequency} MHz  ${network.bandLabel}';

    return details;
  }

  Widget _buildTrailing(
    BuildContext context,
    WifiResult network,
    WifiConnectionState connectionState,
    bool isCurrentNetwork,
  ) {
    if (!isCurrentNetwork) {
      return Text('${network.signalLevel} dBm');
    }

    switch (connectionState) {
      case WifiConnectionState.connecting:
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case WifiConnectionState.connected:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.check_circle,
              size: $(18),
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(width: $(6)),
            Text(
              l10n.connected,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        );
      case WifiConnectionState.dhcp:
        return Text(l10n.getting_ip);
      case WifiConnectionState.idle:
        return Text('${network.signalLevel} dBm');
    }
  }
}

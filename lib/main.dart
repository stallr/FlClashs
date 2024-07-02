import 'dart:async';
import 'dart:io';

import 'package:fl_clash/clash/clash.dart';
import 'package:fl_clash/plugins/app.dart';
import 'package:fl_clash/plugins/tile.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/material.dart';
import 'package:ignore_battery_optimization/ignore_battery_optimization.dart';
import 'application.dart';
import 'l10n/l10n.dart';
import 'models/models.dart';
import 'common/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await android?.init();
  await window?.init();
  await requestIgnoreBatteryOptimizations();
  final config = await preferences.getConfig() ?? Config();
  final clashConfig = await preferences.getClashConfig() ?? ClashConfig();
  final appState = AppState(
    mode: clashConfig.mode,
    isCompatible: config.isCompatible,
    selectedMap: config.currentSelectedMap,
  );
  appState.navigationItems = navigation.getItems(
    openLogs: config.openLogs,
    hasProxies: false,
  );
  await globalState.init(
    appState: appState,
    config: config,
    clashConfig: clashConfig,
  );
  runAppWithPreferences(
    const Application(),
    appState: appState,
    config: config,
    clashConfig: clashConfig,
  );
}

@pragma('vm:entry-point')
Future<void> vpnService() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await preferences.getConfig() ?? Config();
  final clashConfig = await preferences.getClashConfig() ?? ClashConfig();
  final appState = AppState(
    mode: clashConfig.mode,
    isCompatible: config.isCompatible,
    selectedMap: config.currentSelectedMap,
  );
  clashMessage.addListener(
    ClashMessageListenerWithVpn(
      onTun: (String fd) async {
        final fdInt = int.parse(fd);
        await proxyManager.setProtect(fdInt);
        clashCore.setFdMap(fdInt);
      },
    ),
  );

  await globalState.init(
    appState: appState,
    config: config,
    clashConfig: clashConfig,
  );

  globalState.applyProfile(
    appState: appState,
    config: config,
    clashConfig: clashConfig,
  );

  final appLocalizations = await AppLocalizations.load(
    other.getLocaleForString(config.locale) ??
        WidgetsBinding.instance.platformDispatcher.locale,
  );

  handleStart() async {
    await app?.tip(appLocalizations.startVpn);
    await globalState.startSystemProxy(
      appState: appState,
      config: config,
      clashConfig: clashConfig,
    );
    globalState.updateTraffic(config: config);
    globalState.updateFunctionLists = [
      () {
        globalState.updateTraffic(config: config);
      }
    ];
  }

  handleStart();

  tile?.addListener(
    TileListenerWithVpn(
      onStop: () async {
        await app?.tip(appLocalizations.stopVpn);
        await globalState.stopSystemProxy();
        clashCore.shutdown();
        exit(0);
      },
    ),
  );
}

class ClashMessageListenerWithVpn with ClashMessageListener {
  final Function(String fd) _onTun;

  ClashMessageListenerWithVpn({
    required Function(String fd) onTun,
  }) : _onTun = onTun;

  @override
  void onTun(String fd) {
    _onTun(fd);
  }
}

class TileListenerWithVpn with TileListener {
  final Function() _onStop;

  TileListenerWithVpn({
    required Function() onStop,
  }) : _onStop = onStop;

  @override
  void onStop() {
    _onStop();
  }
}

Future<void> requestIgnoreBatteryOptimizations() async {
  bool isIgnoring = await IgnoreBatteryOptimization.isIgnoringBatteryOptimizations('com.tom.cla');
  if (!isIgnoring) {
    await IgnoreBatteryOptimization.openIgnoringBatteryOptimizations('com.tom.cla');
  }
}

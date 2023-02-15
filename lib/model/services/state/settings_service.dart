import 'package:despresso/objectbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../service_locator.dart';

enum SettingKeys {
  shotStopOnWeight,
  shotAutoTare,
  vizualizerUpload,
  vizualizerUser,
  vizualizerPwd,
  sleepTimer,
  screenLockTimer,
  graphSingle,
  mqttEnabled,
  mqttServer,
  mqttPort,
  mqttUser,
  mqttPassword,
  mqttRootTopic,
  mqttSendState,
  mqttSendShot,
  mqttSendBattery,
  mqttSendWater,
  smartCharging,
  hasSteamThermometer,
  hasScale,
  useSentry,
}

class SettingsService extends ChangeNotifier {
  late SharedPreferences prefs;

  late ObjectBox objectBox;

  SettingsService() {
    init();
  }

  void init() async {
    objectBox = getIt<ObjectBox>();

    prefs = await SharedPreferences.getInstance();
    notifyListeners();
  }

  bool get shotStopOnWeight => Settings.getValue<bool>(SettingKeys.shotStopOnWeight.name) ?? true;
  bool get shotAutoTare => Settings.getValue(SettingKeys.shotAutoTare.name) ?? true;

  bool get vizualizerUpload => Settings.getValue(SettingKeys.vizualizerUpload.name) ?? false;
  String get vizualizerUser => Settings.getValue(SettingKeys.vizualizerUser.name);
  String get vizualizerPwd => Settings.getValue(SettingKeys.vizualizerPwd.name);

  double get sleepTimer => Settings.getValue<double>(SettingKeys.sleepTimer.name) ?? 120;
  double get screenLockTimer => Settings.getValue<double>(SettingKeys.screenLockTimer.name) ?? 240;

  bool get mqttEnabled => Settings.getValue<bool>(SettingKeys.mqttEnabled.name) ?? false;
  String get mqttServer => Settings.getValue<String>(SettingKeys.mqttServer.name) ?? "192.168.178.79";
  String get mqttPort => Settings.getValue<String>(SettingKeys.mqttPort.name) ?? "1883";
  String get mqttUser => Settings.getValue<String>(SettingKeys.mqttUser.name) ?? "";
  String get mqttPassword => Settings.getValue<String>(SettingKeys.mqttPassword.name) ?? "";
  String get mqttRootTopic => Settings.getValue<String>(SettingKeys.mqttRootTopic.name) ?? "0";
  bool get mqttSendState => Settings.getValue<bool>(SettingKeys.mqttSendState.name) ?? false;
  bool get mqttSendShot => Settings.getValue<bool>(SettingKeys.mqttSendShot.name) ?? false;
  bool get mqttSendBattery => Settings.getValue<bool>(SettingKeys.mqttSendBattery.name) ?? false;
  bool get mqttSendWater => Settings.getValue<bool>(SettingKeys.mqttSendWater.name) ?? false;

  bool get smartCharging => Settings.getValue<bool>(SettingKeys.smartCharging.name) ?? true;

  bool get hasSteamThermometer => Settings.getValue<bool>(SettingKeys.hasSteamThermometer.name) ?? false;
  bool get hasScale => Settings.getValue<bool>(SettingKeys.hasScale.name) ?? true;

  bool get useSentry => Settings.getValue<bool>(SettingKeys.useSentry.name) ?? true;

  void notifyDelayed() {
    Future.delayed(
      const Duration(milliseconds: 100),
      () {
        notifyListeners();
      },
    );
  }
}

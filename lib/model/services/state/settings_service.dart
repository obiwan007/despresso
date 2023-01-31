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
}

class SettingsService extends ChangeNotifier {
  // Coffee? currentCoffee;
  // List<Coffee> knownCoffees = [];
  // List<Roaster> knownRoasters = [];
  late SharedPreferences prefs;

  late ObjectBox objectBox;

  SettingsService() {
    init();
  }

  void init() async {
    objectBox = getIt<ObjectBox>();
    // coffeeBox = objectBox.store.box<Coffee>();
    // roasterBox = objectBox.store.box<Roaster>();
    // shotBox = objectBox.store.box<Shot>();

    prefs = await SharedPreferences.getInstance();
    notifyListeners();
  }

  bool get shotStopOnWeight =>
      Settings.getValue<bool>(SettingKeys.shotStopOnWeight.name) ?? true;
  bool get shotAutoTare =>
      Settings.getValue(SettingKeys.shotAutoTare.name) ?? true;

  bool get vizualizerUpload =>
      Settings.getValue(SettingKeys.vizualizerUpload.name) ?? false;
  String get vizualizerUser =>
      Settings.getValue(SettingKeys.vizualizerUser.name);
  String get vizualizerPwd => Settings.getValue(SettingKeys.vizualizerPwd.name);

  double get sleepTimer =>
      Settings.getValue<double>(SettingKeys.sleepTimer.name) ?? 120;
  double get screenLockTimer =>
      Settings.getValue<double>(SettingKeys.screenLockTimer.name) ?? 240;

  bool get graphSingle =>
      Settings.getValue<bool>(SettingKeys.graphSingle.name) ?? false;

  bool get mqttEnabled =>
      Settings.getValue<bool>(SettingKeys.mqttEnabled.name) ?? false;

  String get mqttServer => Settings.getValue(SettingKeys.mqttServer.name);

  int get mqttPort => Settings.getValue<int>(SettingKeys.mqttPort.name) ?? 1883;
}

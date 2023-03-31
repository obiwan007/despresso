import 'package:despresso/model/shot.dart';
import 'package:despresso/objectbox.dart';
import 'package:despresso/objectbox.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../service_locator.dart';

enum SettingKeys {
  shotStopOnWeight,
  shotAutoTare,
  visualizerUpload,
  visualizerUser,
  visualizerPwd,
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
  currentProfile,
  selectedRoaster,
  selectedCoffee,
  selectedRecipe,
  selectedShot,
  steamSettings,
  targetSteamTemp,
  targetSteamLength,
  targetMilkTemperature,
  targetHotWaterTemp,
  targetHotWaterVol,
  targetHotWaterWeight,
  targetHotWaterLength,
  targetEspressoVol,
  targetFlushTime,
  targetFlushTime2,
  targetGroupTemp,
  targetEspressoWeight,
  targetEspressoWeightTimeAdjust,
  webServer,
  targetTempCorrection,
  screenBrightnessTimer,
  screenBrightnessValue,
  screenTapWake,
  screenTimoutGoToRecipe,
  screenDarkTheme,
  screenThemeIndex,
  steamHeaterOff,
  startCounter,
  launchWake,
  showFlushScreen,
}

class SettingsService extends ChangeNotifier {
  final log = Logger('SettingsService');
  late SharedPreferences prefs;

  late ObjectBox objectBox;

  SettingsService() {
    init();
  }

  void init() async {
    objectBox = getIt<ObjectBox>();

    prefs = await SharedPreferences.getInstance();

    var shotBox = objectBox.store.box<Shot>();
    var shots = shotBox.count();

    if (shots > 0) {
      var lastShot = shotBox.query().order(Shot_.date, flags: Order.descending).build().findFirst();
      if (lastShot != null) selectedShot = lastShot.id;
    }
    log.info("Found $shots stored");
    notifyListeners();
  }

  bool get shotStopOnWeight => Settings.getValue<bool>(SettingKeys.shotStopOnWeight.name) ?? true;
  bool get shotAutoTare => Settings.getValue(SettingKeys.shotAutoTare.name) ?? true;

  bool get visualizerUpload => Settings.getValue(SettingKeys.visualizerUpload.name) ?? false;
  String get visualizerUser => Settings.getValue(SettingKeys.visualizerUser.name) ?? "";
  String get visualizerPwd => Settings.getValue(SettingKeys.visualizerPwd.name) ?? "";

  double get sleepTimer => Settings.getValue<double>(SettingKeys.sleepTimer.name) ?? 15;
  double get screenLockTimer => Settings.getValue<double>(SettingKeys.screenLockTimer.name) ?? 30;

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

  String get currentProfile => Settings.getValue<String>(SettingKeys.currentProfile.name) ?? "Default";
  set currentProfile(value) => Settings.setValue<String>(SettingKeys.currentProfile.name, value);

  int get selectedRoaster => Settings.getValue<int>(SettingKeys.selectedRoaster.name) ?? 0;
  set selectedRoaster(value) => Settings.setValue<int>(SettingKeys.selectedRoaster.name, value);

  int get selectedCoffee => Settings.getValue<int>(SettingKeys.selectedCoffee.name) ?? 0;
  set selectedCoffee(value) => Settings.setValue<int>(SettingKeys.selectedCoffee.name, value);

  int get selectedRecipe => Settings.getValue<int>(SettingKeys.selectedRecipe.name) ?? 0;
  set selectedRecipe(value) => Settings.setValue<int>(SettingKeys.selectedRecipe.name, value);

  int get selectedShot => Settings.getValue<int>(SettingKeys.selectedShot.name) ?? 0;
  set selectedShot(value) => Settings.setValue<int>(SettingKeys.selectedShot.name, value);

  int get steamSettings => Settings.getValue<int>(SettingKeys.steamSettings.name) ?? 0;
  set steamSettings(value) => Settings.setValue<int>(SettingKeys.steamSettings.name, value);

  int get targetSteamTemp => Settings.getValue<int>(SettingKeys.targetSteamTemp.name) ?? 120;
  set targetSteamTemp(value) => Settings.setValue<int>(SettingKeys.targetSteamTemp.name, value);

  bool get steamHeaterOff => Settings.getValue<bool>(SettingKeys.steamHeaterOff.name) ?? false;
  set steamHeaterOff(value) => Settings.setValue<bool>(SettingKeys.steamHeaterOff.name, value);

  int get targetSteamLength => Settings.getValue<int>(SettingKeys.targetSteamLength.name) ?? 90;
  set targetSteamLength(value) => Settings.setValue<int>(SettingKeys.targetSteamLength.name, value);

  int get targetMilkTemperature => Settings.getValue<int>(SettingKeys.targetMilkTemperature.name) ?? 55;
  set targetMilkTemperature(value) => Settings.setValue<int>(SettingKeys.targetMilkTemperature.name, value);

  int get targetHotWaterTemp => Settings.getValue<int>(SettingKeys.targetHotWaterTemp.name) ?? 85;
  set targetHotWaterTemp(value) => Settings.setValue<int>(SettingKeys.targetHotWaterTemp.name, value);

  int get targetHotWaterVol => Settings.getValue<int>(SettingKeys.targetHotWaterVol.name) ?? 120;
  set targetHotWaterVol(value) => Settings.setValue<int>(SettingKeys.targetHotWaterVol.name, value);

  int get targetHotWaterWeight => Settings.getValue<int>(SettingKeys.targetHotWaterWeight.name) ?? 120;
  set targetHotWaterWeight(value) => Settings.setValue<int>(SettingKeys.targetHotWaterWeight.name, value);

  int get targetHotWaterLength => Settings.getValue<int>(SettingKeys.targetHotWaterLength.name) ?? 45;
  set targetHotWaterLength(value) => Settings.setValue<int>(SettingKeys.targetHotWaterLength.name, value);

  int get targetEspressoVol => Settings.getValue<int>(SettingKeys.targetEspressoVol.name) ?? 35;
  set targetEspressoVol(value) => Settings.setValue<int>(SettingKeys.targetEspressoVol.name, value);

  double get targetEspressoWeight => Settings.getValue<double>(SettingKeys.targetEspressoWeight.name) ?? 36;
  set targetEspressoWeight(value) => Settings.setValue<double>(SettingKeys.targetEspressoWeight.name, value);

  double get targetEspressoWeightTimeAdjust =>
      Settings.getValue<double>(SettingKeys.targetEspressoWeightTimeAdjust.name) ?? 0.5;
  set targetEspressoWeightTimeAdjust(value) =>
      Settings.setValue<double>(SettingKeys.targetEspressoWeightTimeAdjust.name, value);

  double get targetFlushTime => Settings.getValue<double>(SettingKeys.targetFlushTime.name) ?? 3.0;
  set targetFlushTime(value) => Settings.setValue<double>(SettingKeys.targetFlushTime.name, value);

  double get targetFlushTime2 => Settings.getValue<double>(SettingKeys.targetFlushTime2.name) ?? 15.0;
  set targetFlushTime2(value) => Settings.setValue<double>(SettingKeys.targetFlushTime2.name, value);

  int get targetGroupTemp => Settings.getValue<int>(SettingKeys.targetGroupTemp.name) ?? 98;
  set targetGroupTemp(value) => Settings.setValue<int>(SettingKeys.targetGroupTemp.name, value);

  bool get webServer => Settings.getValue<bool>(SettingKeys.webServer.name) ?? true;
  set webServer(value) => Settings.setValue<bool>(SettingKeys.webServer.name, value);

  double get targetTempCorrection => Settings.getValue<double>(SettingKeys.targetTempCorrection.name) ?? 0;
  set targetTempCorrection(value) => Settings.setValue<double>(SettingKeys.targetTempCorrection.name, value);

  double get screenBrightnessTimer => Settings.getValue<double>(SettingKeys.screenBrightnessTimer.name) ?? 10;
  set screenBrightnessTimer(value) => Settings.setValue<double>(SettingKeys.screenBrightnessTimer.name, value);

  double get screenBrightnessValue => Settings.getValue<double>(SettingKeys.screenBrightnessValue.name) ?? 0;
  set screenBrightnessValue(value) => Settings.setValue<double>(SettingKeys.screenBrightnessValue.name, value);

  /// Wake de1 if tapped out of screensaver/dim mode
  bool get screenTapWake => Settings.getValue<bool>(SettingKeys.screenTapWake.name) ?? true;
  set screenTapWake(value) => Settings.setValue<bool>(SettingKeys.screenTapWake.name, value);

  /// Wake de1 ifapp is starting
  bool get launchWake => Settings.getValue<bool>(SettingKeys.launchWake.name) ?? true;
  set launchWake(value) => Settings.setValue<bool>(SettingKeys.launchWake.name, value);

  bool get screenTimoutGoToRecipe => Settings.getValue<bool>(SettingKeys.screenTimoutGoToRecipe.name) ?? true;
  set screenTimoutGoToRecipe(value) => Settings.setValue<bool>(SettingKeys.screenTimoutGoToRecipe.name, value);

  bool get screenDarkTheme => Settings.getValue<bool>(SettingKeys.screenDarkTheme.name) ?? true;
  set screenDarkTheme(value) => Settings.setValue<bool>(SettingKeys.screenDarkTheme.name, value);

  String get screenThemeIndex => Settings.getValue<String>(SettingKeys.screenThemeIndex.name) ?? "0";
  set screenThemeIndex(value) => Settings.setValue<String>(SettingKeys.screenThemeIndex.name, value);

  int get startCounter => Settings.getValue<int>(SettingKeys.startCounter.name) ?? 0;
  set startCounter(value) => Settings.setValue<int>(SettingKeys.startCounter.name, value);

  bool get showFlushScreen => Settings.getValue<bool>(SettingKeys.showFlushScreen.name) ?? false;
  set showFlushScreen(value) => Settings.setValue<bool>(SettingKeys.showFlushScreen.name, value);

  void notifyDelayed() {
    Future.delayed(
      const Duration(milliseconds: 100),
      () {
        notifyListeners();
      },
    );
  }
}

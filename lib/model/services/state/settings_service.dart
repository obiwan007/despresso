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
  hasRefractometer,
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
  stepLimitWeightTimeAdjust,
  targetWaterlevel,
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
  screensaverOnIfIdle,
  locale,
  profileFilter,
  useSteam,
  useWater,
  showPressureGraph,
  showWeightGraph,
  showTempGraph,
  showFlowGraph,
  chUrl,
  useCafeHub,
  useLongUUID,
  recordPrePouring,
  savePrePouring,
  screensaverShowClock,
  scaleStartTimer,
  tareOnWeight1,
  tareOnDetectedWeight,
  tareOnWeight2,
  tareOnWeight3,
  tareOnWeight4,
  scaleDisplayOffOnSleep,
  scalePrimary,
  scaleSecondary,
  targetSteamFlow,
  targetMilkTempPreset1,
  targetMilkTempPreset2,
  targetMilkTempPreset3,
  tabletSleepDuringScreensaver,
  tabletSleepDuringScreensaverTimeout,
  tabletSleepWhenMachineOff,
  visualizerUploadExtended,
  visualizerExtendedUser,
  visualizerExtendedPwd,
  visualizerExtendedUrl,
  visualizerExtendedUpload,
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
  set shotStopOnWeight(bool value) => Settings.setValue<bool>(SettingKeys.shotStopOnWeight.name, value);

  bool get shotAutoTare => Settings.getValue(SettingKeys.shotAutoTare.name) ?? true;

  bool get visualizerUpload => Settings.getValue(SettingKeys.visualizerUpload.name) ?? false;
  String get visualizerUser => Settings.getValue(SettingKeys.visualizerUser.name) ?? "";
  String get visualizerPwd => Settings.getValue(SettingKeys.visualizerPwd.name) ?? "";

  bool get visualizerExtendedUpload => Settings.getValue(SettingKeys.visualizerExtendedUpload.name) ?? false;
  String get visualizerExtendedUser => Settings.getValue(SettingKeys.visualizerExtendedUser.name) ?? "";
  String get visualizerExtendedPwd => Settings.getValue(SettingKeys.visualizerExtendedPwd.name) ?? "";
  String get visualizerExtendedUrl => Settings.getValue(SettingKeys.visualizerExtendedUrl.name) ?? "";

  double get sleepTimer => Settings.getValue<double>(SettingKeys.sleepTimer.name) ?? 15;
  bool get tabletSleepDuringScreensaver =>
      Settings.getValue<bool>(SettingKeys.tabletSleepDuringScreensaver.name) ?? false;
  double get tabletSleepDuringScreensaverTimeout =>
      Settings.getValue<double>(SettingKeys.tabletSleepDuringScreensaverTimeout.name) ?? 60;
  bool get tabletSleepWhenMachineOff => Settings.getValue<bool>(SettingKeys.tabletSleepWhenMachineOff.name) ?? false;

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
  bool get hasRefractometer => Settings.getValue<bool>(SettingKeys.hasRefractometer.name) ?? false;
  bool get hasScale => Settings.getValue<bool>(SettingKeys.hasScale.name) ?? true;

  bool get useSentry => Settings.getValue<bool>(SettingKeys.useSentry.name) ?? true;

  String get currentProfile => Settings.getValue<String>(SettingKeys.currentProfile.name) ?? "Default";
  set currentProfile(String value) => Settings.setValue<String>(SettingKeys.currentProfile.name, value);

  int get selectedRoaster => Settings.getValue<int>(SettingKeys.selectedRoaster.name) ?? 0;
  set selectedRoaster(int value) => Settings.setValue<int>(SettingKeys.selectedRoaster.name, value);

  int get selectedCoffee => Settings.getValue<int>(SettingKeys.selectedCoffee.name) ?? 0;
  set selectedCoffee(int value) => Settings.setValue<int>(SettingKeys.selectedCoffee.name, value);

  int get selectedRecipe => Settings.getValue<int>(SettingKeys.selectedRecipe.name) ?? 0;
  set selectedRecipe(int value) => Settings.setValue<int>(SettingKeys.selectedRecipe.name, value);

  int get selectedShot => Settings.getValue<int>(SettingKeys.selectedShot.name) ?? 0;
  set selectedShot(int value) => Settings.setValue<int>(SettingKeys.selectedShot.name, value);

  int get steamSettings => Settings.getValue<int>(SettingKeys.steamSettings.name) ?? 0;
  set steamSettings(int value) => Settings.setValue<int>(SettingKeys.steamSettings.name, value);

  int get targetSteamTemp => Settings.getValue<int>(SettingKeys.targetSteamTemp.name) ?? 120;
  set targetSteamTemp(int value) => Settings.setValue<int>(SettingKeys.targetSteamTemp.name, value);

  bool get steamHeaterOff => Settings.getValue<bool>(SettingKeys.steamHeaterOff.name) ?? false;
  set steamHeaterOff(bool value) => Settings.setValue<bool>(SettingKeys.steamHeaterOff.name, value);

  int get targetSteamLength => Settings.getValue<int>(SettingKeys.targetSteamLength.name) ?? 90;
  set targetSteamLength(int value) => Settings.setValue<int>(SettingKeys.targetSteamLength.name, value);

  double get targetSteamFlow => Settings.getValue<double>(SettingKeys.targetSteamFlow.name) ?? 1.4;
  set targetSteamFlow(double value) => Settings.setValue<double>(SettingKeys.targetSteamFlow.name, value);

  int get targetMilkTemperature => Settings.getValue<int>(SettingKeys.targetMilkTemperature.name) ?? 55;
  set targetMilkTemperature(int value) => Settings.setValue<int>(SettingKeys.targetMilkTemperature.name, value);

  int get targetMilkTempPreset1 => Settings.getValue<int>(SettingKeys.targetMilkTempPreset1.name) ?? 55;
  set targetMilkTempPreset1(int value) => Settings.setValue<int>(SettingKeys.targetMilkTempPreset1.name, value);

  int get targetMilkTempPreset2 => Settings.getValue<int>(SettingKeys.targetMilkTempPreset2.name) ?? 55;
  set targetMilkTempPreset2(int value) => Settings.setValue<int>(SettingKeys.targetMilkTempPreset2.name, value);

  int get targetMilkTempPreset3 => Settings.getValue<int>(SettingKeys.targetMilkTempPreset3.name) ?? 55;
  set targetMilkTempPreset3(int value) => Settings.setValue<int>(SettingKeys.targetMilkTempPreset3.name, value);

  int get targetHotWaterTemp => Settings.getValue<int>(SettingKeys.targetHotWaterTemp.name) ?? 85;
  set targetHotWaterTemp(int value) => Settings.setValue<int>(SettingKeys.targetHotWaterTemp.name, value);

  int get targetHotWaterVol => Settings.getValue<int>(SettingKeys.targetHotWaterVol.name) ?? 120;
  set targetHotWaterVol(int value) => Settings.setValue<int>(SettingKeys.targetHotWaterVol.name, value);

  int get targetHotWaterWeight => Settings.getValue<int>(SettingKeys.targetHotWaterWeight.name) ?? 120;
  set targetHotWaterWeight(int value) => Settings.setValue<int>(SettingKeys.targetHotWaterWeight.name, value);

  int get targetHotWaterLength => Settings.getValue<int>(SettingKeys.targetHotWaterLength.name) ?? 45;
  set targetHotWaterLength(int value) => Settings.setValue<int>(SettingKeys.targetHotWaterLength.name, value);

  int get targetEspressoVol => Settings.getValue<int>(SettingKeys.targetEspressoVol.name) ?? 35;
  set targetEspressoVol(int value) => Settings.setValue<int>(SettingKeys.targetEspressoVol.name, value);

  double get targetEspressoWeight => Settings.getValue<double>(SettingKeys.targetEspressoWeight.name) ?? 36;
  set targetEspressoWeight(double value) => Settings.setValue<double>(SettingKeys.targetEspressoWeight.name, value);

  double get targetEspressoWeightTimeAdjust =>
      Settings.getValue<double>(SettingKeys.targetEspressoWeightTimeAdjust.name) ?? 0.5;
  set targetEspressoWeightTimeAdjust(value) =>
      Settings.setValue<double>(SettingKeys.targetEspressoWeightTimeAdjust.name, value);

  double get stepLimitWeightTimeAdjust =>
      Settings.getValue<double>(SettingKeys.stepLimitWeightTimeAdjust.name) ?? 0.0;
  set stepLimitWeightTimeAdjust(value) =>
      Settings.setValue<double>(SettingKeys.stepLimitWeightTimeAdjust.name, value);

  double get targetFlushTime => Settings.getValue<double>(SettingKeys.targetFlushTime.name) ?? 3.0;
  set targetFlushTime(double value) => Settings.setValue<double>(SettingKeys.targetFlushTime.name, value);

  double get targetFlushTime2 => Settings.getValue<double>(SettingKeys.targetFlushTime2.name) ?? 15.0;
  set targetFlushTime2(double value) => Settings.setValue<double>(SettingKeys.targetFlushTime2.name, value);

  int get targetGroupTemp => Settings.getValue<int>(SettingKeys.targetGroupTemp.name) ?? 98;
  set targetGroupTemp(int value) => Settings.setValue<int>(SettingKeys.targetGroupTemp.name, value);

  bool get webServer => Settings.getValue<bool>(SettingKeys.webServer.name) ?? true;
  set webServer(bool value) => Settings.setValue<bool>(SettingKeys.webServer.name, value);

  double get targetTempCorrection => Settings.getValue<double>(SettingKeys.targetTempCorrection.name) ?? 0;
  set targetTempCorrection(double value) => Settings.setValue<double>(SettingKeys.targetTempCorrection.name, value);

  int get targetWaterlevel => Settings.getValue<int>(SettingKeys.targetWaterlevel.name) ?? 200;
  set targetWaterlevel(int value) => Settings.setValue<int>(SettingKeys.targetWaterlevel.name, value);

  double get screenBrightnessTimer => Settings.getValue<double>(SettingKeys.screenBrightnessTimer.name) ?? 10;
  set screenBrightnessTimer(double value) => Settings.setValue<double>(SettingKeys.screenBrightnessTimer.name, value);

  double get screenBrightnessValue => Settings.getValue<double>(SettingKeys.screenBrightnessValue.name) ?? 0;
  set screenBrightnessValue(double value) => Settings.setValue<double>(SettingKeys.screenBrightnessValue.name, value);

  /// Wake de1 if tapped out of screensaver/dim mode
  bool get screenTapWake => Settings.getValue<bool>(SettingKeys.screenTapWake.name) ?? true;
  set screenTapWake(bool value) => Settings.setValue<bool>(SettingKeys.screenTapWake.name, value);

  /// Wake de1 ifapp is starting
  bool get launchWake => Settings.getValue<bool>(SettingKeys.launchWake.name) ?? true;
  set launchWake(bool value) => Settings.setValue<bool>(SettingKeys.launchWake.name, value);

  bool get screenTimoutGoToRecipe => Settings.getValue<bool>(SettingKeys.screenTimoutGoToRecipe.name) ?? true;
  set screenTimoutGoToRecipe(bool value) => Settings.setValue<bool>(SettingKeys.screenTimoutGoToRecipe.name, value);

  bool get screenDarkTheme => Settings.getValue<bool>(SettingKeys.screenDarkTheme.name) ?? true;
  set screenDarkTheme(bool value) => Settings.setValue<bool>(SettingKeys.screenDarkTheme.name, value);

  String get screenThemeIndex => Settings.getValue<String>(SettingKeys.screenThemeIndex.name) ?? "0";
  set screenThemeIndex(String value) => Settings.setValue<String>(SettingKeys.screenThemeIndex.name, value);

  int get startCounter => Settings.getValue<int>(SettingKeys.startCounter.name) ?? 0;
  set startCounter(int value) => Settings.setValue<int>(SettingKeys.startCounter.name, value);

  bool get showFlushScreen => Settings.getValue<bool>(SettingKeys.showFlushScreen.name) ?? false;
  set showFlushScreen(bool value) => Settings.setValue<bool>(SettingKeys.showFlushScreen.name, value);

  bool get screensaverOnIfIdle => Settings.getValue<bool>(SettingKeys.screensaverOnIfIdle.name) ?? true;
  set screensaverOnIfIdle(bool value) => Settings.setValue<bool>(SettingKeys.screensaverOnIfIdle.name, value);

  bool get screensaverShowClock => Settings.getValue<bool>(SettingKeys.screensaverShowClock.name) ?? true;
  set screensaverShowClock(bool value) => Settings.setValue<bool>(SettingKeys.screensaverShowClock.name, value);

  String get locale => Settings.getValue<String>(SettingKeys.locale.name) ?? "auto";
  set locale(String value) => Settings.setValue<String>(SettingKeys.locale.name, value);

  String get profileFilter => Settings.getValue<String>(SettingKeys.profileFilter.name) ?? "Mine,Default";
  set profileFilter(String value) => Settings.setValue<String>(SettingKeys.profileFilter.name, value);

  List<String> get profileFilterList => profileFilter.split(',');
  set profileFilterList(List<String> value) => profileFilter = value.join(',');

  /// Parameter to show the steam tab or not.
  bool get useSteam => Settings.getValue<bool>(SettingKeys.useSteam.name) ?? true;
  set useSteam(bool value) => Settings.setValue<bool>(SettingKeys.useSteam.name, value);

  /// Parameter to show the water tab or not.
  bool get useWater => Settings.getValue<bool>(SettingKeys.useWater.name) ?? true;
  set useWater(bool value) => Settings.setValue<bool>(SettingKeys.useWater.name, value);

  bool get showPressureGraph => Settings.getValue<bool>(SettingKeys.showPressureGraph.name) ?? true;
  set showPressureGraph(bool value) => Settings.setValue<bool>(SettingKeys.showPressureGraph.name, value);

  bool get showFlowGraph => Settings.getValue<bool>(SettingKeys.showFlowGraph.name) ?? true;
  set showFlowGraph(bool value) => Settings.setValue<bool>(SettingKeys.showFlowGraph.name, value);

  bool get showWeightGraph => Settings.getValue<bool>(SettingKeys.showWeightGraph.name) ?? true;
  set showWeightGraph(bool value) => Settings.setValue<bool>(SettingKeys.showWeightGraph.name, value);

  bool get showTempGraph => Settings.getValue<bool>(SettingKeys.showTempGraph.name) ?? true;
  set showTempGraph(bool value) => Settings.setValue<bool>(SettingKeys.showTempGraph.name, value);

  String get chUrl => Settings.getValue<String>(SettingKeys.chUrl.name) ?? "ws://192.168.178.97:8765";
  set chUrl(String value) => Settings.setValue<String>(SettingKeys.chUrl.name, value);

  bool get useCafeHub => Settings.getValue<bool>(SettingKeys.useCafeHub.name) ?? false;
  set useCafeHub(bool value) => Settings.setValue<bool>(SettingKeys.useCafeHub.name, value);

  bool get useLongUUID => Settings.getValue<bool>(SettingKeys.useLongUUID.name) ?? true;
  set useLongUUID(bool value) => Settings.setValue<bool>(SettingKeys.useLongUUID.name, value);

  /// show the shot data in graph during espresso including pre pouring states.
  bool get recordPrePouring => Settings.getValue<bool>(SettingKeys.recordPrePouring.name) ?? true;
  set recordPrePouring(bool value) => Settings.setValue<bool>(SettingKeys.recordPrePouring.name, value);

  /// save heating phase of shots
  bool get savePrePouring => Settings.getValue<bool>(SettingKeys.savePrePouring.name) ?? false;
  set savePrePouring(bool value) => Settings.setValue<bool>(SettingKeys.savePrePouring.name, value);

  bool get scaleStartTimer => Settings.getValue<bool>(SettingKeys.scaleStartTimer.name) ?? true;
  set scaleStartTimer(bool value) => Settings.setValue<bool>(SettingKeys.scaleStartTimer.name, value);

  double get tareOnWeight1 => Settings.getValue<double>(SettingKeys.tareOnWeight1.name) ?? 0;
  set tareOnWeight1(value) => Settings.setValue<double>(SettingKeys.tareOnWeight1.name, value);

  double get tareOnWeight2 => Settings.getValue<double>(SettingKeys.tareOnWeight2.name) ?? 0;
  set tareOnWeight2(value) => Settings.setValue<double>(SettingKeys.tareOnWeight2.name, value);

  double get tareOnWeight3 => Settings.getValue<double>(SettingKeys.tareOnWeight3.name) ?? 0;
  set tareOnWeight3(value) => Settings.setValue<double>(SettingKeys.tareOnWeight3.name, value);

  double get tareOnWeight4 => Settings.getValue<double>(SettingKeys.tareOnWeight4.name) ?? 0;
  set tareOnWeight4(value) => Settings.setValue<double>(SettingKeys.tareOnWeight4.name, value);

  bool get tareOnDetectedWeight => Settings.getValue<bool>(SettingKeys.tareOnDetectedWeight.name) ?? true;
  set tareOnDetectedWeight(bool value) => Settings.setValue<bool>(SettingKeys.tareOnDetectedWeight.name, value);

  bool get scaleDisplayOffOnSleep => Settings.getValue<bool>(SettingKeys.scaleDisplayOffOnSleep.name) ?? true;
  set scaleDisplayOffOnSleep(bool value) => Settings.setValue<bool>(SettingKeys.scaleDisplayOffOnSleep.name, value);

  String get scalePrimary => Settings.getValue<String>(SettingKeys.scalePrimary.name) ?? "";
  set scalePrimary(String value) => Settings.setValue<String>(SettingKeys.scalePrimary.name, value);

  String get scaleSecondary => Settings.getValue<String>(SettingKeys.scaleSecondary.name) ?? "";
  set scaleSecondary(String value) => Settings.setValue<String>(SettingKeys.scaleSecondary.name, value);

  void notifyDelayed() {
    Future.delayed(
      const Duration(milliseconds: 100),
      () {
        notifyListeners();
      },
    );
  }
}

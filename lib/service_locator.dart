import 'package:despresso/model/services/ble/ble_service.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/ble/temperature_service.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/services/state/screen_saver.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/model/services/state/mqtt_service.dart';

import 'package:get_it/get_it.dart';

import 'model/services/state/visualizer_service.dart';
import 'model/services/state/web_server.dart';

final getIt = GetIt.instance;

void setupServices() {
  getIt.registerSingleton<SettingsService>(SettingsService(), signalsReady: false);
  getIt.registerSingleton<BLEService>(BLEService(), signalsReady: false);
  getIt.registerSingleton<ScaleService>(ScaleService(), signalsReady: false);
  getIt.registerSingleton<CoffeeService>(CoffeeService(), signalsReady: false);
  getIt.registerSingleton<ProfileService>(ProfileService(), signalsReady: false);
  getIt.registerSingleton<TempService>(TempService(), signalsReady: false);
  getIt.registerSingleton<EspressoMachineService>(EspressoMachineService(), signalsReady: false);
  getIt.registerSingleton<MqttService>(MqttService(), signalsReady: false);
  getIt.registerSingleton<VisualizerService>(VisualizerService(), signalsReady: false);
  getIt.registerSingleton<WebService>(WebService(), signalsReady: false);
  getIt.registerSingleton<ScreensaverService>(ScreensaverService(), signalsReady: false);
}

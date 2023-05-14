import 'package:despresso/service_locator.dart';

import '../model/services/state/settings_service.dart';

enum TimerMode {
  start,
  stop,
  reset,
}

enum DisplayMode {
  on,
  off,
}

enum PowerMode {
  on,
  off,
  sleep,
}

abstract class AbstractScale {
  Future<void> writeTare();
  Future<void> timer(TimerMode start);
  Future<void> display(DisplayMode start);
  Future<void> power(PowerMode start);
  Future<void> beep();
}

int getScaleIndex(String deviceId) {
  var settingsService = getIt<SettingsService>();

  if (settingsService.scalePrimary == deviceId) {
    return 0;
  } else if (settingsService.scaleSecondary == deviceId) {
    return 1;
  }
  return 0;
}

mixin ScaleBase {
  Future<void> writeTare();
  Future<void> timer(TimerMode start);
  Future<void> display(DisplayMode start);
  Future<void> power(PowerMode start);
  Future<void> beep();

  int index = 0;
  getIndex(String deviceId) {
    var settingsService = getIt<SettingsService>();

    if (settingsService.scalePrimary == deviceId) {
      index = 0;
    } else if (settingsService.scaleSecondary == deviceId) {
      index = 1;
    }
  }
}

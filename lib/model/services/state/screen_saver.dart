import 'dart:async';

import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:wakelock/wakelock.dart';

import '../../../service_locator.dart';

class ScreensaverService extends ChangeNotifier {
  final log = Logger('ScreensaverService');

  late Timer _timer;
  late SettingsService _settings;

  int _screenSaverTimer = 0;
  bool screenSaverOn = false;

  bool _paused = false;

  ScreensaverService() {
    init();
  }

  void init() async {
    _settings = getIt<SettingsService>();
    setupScreensaver();
    notifyListeners();
  }

  void notifyDelayed() {
    Future.delayed(
      const Duration(milliseconds: 100),
      () {
        notifyListeners();
      },
    );
  }

  bool allwaysWakeLock() {
    return _settings.screenLockTimer > 239;
  }

  bool useWakeLock() {
    return _settings.screenLockTimer > 0;
  }

  void setupScreensaver() {
    try {
      if (useWakeLock()) {
        Wakelock.enable();
        log.info('Enable WakeLock');
      } else {
        Wakelock.disable();
      }
    } catch (e) {
      log.severe("Could not use WakeLock $e");
    }

    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) async {
        if (_paused == true) return;
        _screenSaverTimer += 5;
        log.fine("Tick  $_screenSaverTimer ${_settings.screenBrightnessTimer * 60} on: $screenSaverOn");
        if (_settings.screenBrightnessTimer > 0 &&
            _screenSaverTimer > _settings.screenBrightnessTimer * 60 &&
            screenSaverOn == false) {
          await ScreenBrightness().setScreenBrightness(_settings.screenBrightnessValue);
          screenSaverOn = true;
          notifyListeners();
        }
        if (_screenSaverTimer > _settings.screenLockTimer * 60 && !allwaysWakeLock()) {
          try {
            if (await Wakelock.enabled) {
              log.info('Disable WakeLock');
              Wakelock.disable();
            }
          } on MissingPluginException catch (e) {
            log.severe('Failed to set wakelock: $e');
          }
        }
      },
    );
  }

  Future<void> handleTap() async {
    _screenSaverTimer = 0;
    log.info("Tap");
    if (screenSaverOn) {
      screenSaverOn = false;
      ScreenBrightness().resetScreenBrightness();

      if (_settings.screenTapWake) {
        var machine = getIt<EspressoMachineService>();
        machine.de1?.switchOn();
      }
      try {
        if ((await Wakelock.enabled) == false) {
          log.info('enable WakeLock');
          Wakelock.enable();
        } else {
          log.fine('is enabled WakeLock');
        }
      } on MissingPluginException catch (e) {
        log.severe('Failed to set wakelock enable: $e');
      }
      notifyListeners();
    }
  }

  void pause() {
    _paused = true;
  }

  void resume() {
    _paused = false;
    _screenSaverTimer = 0;
  }
}

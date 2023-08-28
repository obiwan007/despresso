import 'dart:async';

import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../service_locator.dart';

class ScreensaverService extends ChangeNotifier {
  final log = Logger('ScreensaverService');

  late Timer _timer;
  late SettingsService _settings;
  late EspressoMachineService machine;
  int _screenSaverTimer = 0;
  bool screenSaverOn = false;

  bool _paused = false;

  EspressoMachineState lastState = EspressoMachineState.disconnected;

  ScreensaverService() {
    init();
  }

  void init() async {
    _settings = getIt<SettingsService>();
    machine = getIt<EspressoMachineService>();
    setupScreensaver();
    notifyListeners();

// Prevent screensave to go online during a pour.
    machine.streamState.listen((event) async {
      if (event.state != lastState) {
        lastState = event.state;
        await setWakelock();

        switch (lastState) {
          case EspressoMachineState.idle:
            resume();
            break;
          case EspressoMachineState.sleep:
            break;
          case EspressoMachineState.water:
          case EspressoMachineState.steam:
          case EspressoMachineState.flush:
          case EspressoMachineState.espresso:
            resume();
            pause();
            break;
          case EspressoMachineState.disconnected:
            break;
          case EspressoMachineState.connecting:
            break;
          case EspressoMachineState.refill:
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  void notifyDelayed() {
    Future.delayed(
      const Duration(milliseconds: 100),
      () {
        notifyListeners();
      },
    );
  }

  bool shouldBeWakelocked() {
    if (_settings.tabletSleepDuringScreensaver && screenSaverOn) {
      if (_screenSaverTimer >= _settings.tabletSleepDuringScreensaverTimeout * 60) {
        return false;
      }
    }

    if (_settings.tabletSleepWhenMachineOff) {
      switch (lastState) {
        case EspressoMachineState.connecting:
        case EspressoMachineState.disconnected:
        case EspressoMachineState.sleep:
          return false;
        case EspressoMachineState.espresso:
        case EspressoMachineState.flush:
        case EspressoMachineState.idle:
        case EspressoMachineState.refill:
        case EspressoMachineState.steam:
        case EspressoMachineState.water:
          break;
      }
    }

    return true;
  }

  Future<void> setWakelock() async {
    var isLocked = await WakelockPlus.enabled;
    var shouldBeLocked = shouldBeWakelocked();

    try {
      if (!isLocked && shouldBeLocked) {
        WakelockPlus.enable();
      } else if (isLocked && !shouldBeLocked) {
        WakelockPlus.disable();
      }
    } catch (e) {
      log.severe("Failed to set wakelock: $e");
    }
  }

  void setupScreensaver() {
    setWakelock();

    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) async {
        await setWakelock();

        if (_paused == true) return;
        _screenSaverTimer += 5;
        // log.fine("Tick  $_screenSaverTimer ${_settings.screenBrightnessTimer * 60} on: $screenSaverOn");
        await checkAndActivateSaver();
      },
    );
  }

  Future<void> checkAndActivateSaver() async {
    if (_settings.screenBrightnessTimer > 0 &&
        _screenSaverTimer > _settings.screenBrightnessTimer * 60 &&
        screenSaverOn == false) {
      await ScreenBrightness().setScreenBrightness(_settings.screenBrightnessValue);
      screenSaverOn = true;
      notifyListeners();
    }
  }

  activateScreenSaver() {
    _screenSaverTimer = (_settings.screenBrightnessTimer * 60 + 1).toInt();
    checkAndActivateSaver();
  }

  Future<void> handleTap() async {
    log.info("resumed");
    _screenSaverTimer = 0;
    _paused = false;
    log.info("Tap");
    if (screenSaverOn) {
      screenSaverOn = false;
      ScreenBrightness().resetScreenBrightness();
      setWakelock();

      if (_settings.screenTapWake) {
        machine.de1?.switchOn();
      }
      notifyListeners();
    }
  }

  void pause() {
    _paused = true;
    log.info("Paused");
  }

  void resume() {
    handleTap();
  }
}

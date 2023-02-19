import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:despresso/devices/decent_de1.dart';
import 'package:despresso/model/services/ble/ble_service.dart';
import 'package:despresso/model/services/ble/temperature_service.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/settings_service.dart';

import 'package:despresso/model/de1shotclasses.dart';
import 'package:despresso/objectbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock/wakelock.dart';

import 'package:battery_plus/battery_plus.dart';

import '../../../service_locator.dart';
import '../../shot.dart';
import '../../shotstate.dart';
import '../state/profile_service.dart';
import 'scale_service.dart';

class WaterLevel {
  WaterLevel(this.waterLevel, this.waterLimit);

  int waterLevel = 0;
  int waterLimit = 0;

  int getLevelPercent() {
    var l = waterLevel - waterLimit;
    return l * 100 ~/ 8300;
  }

  int getLevelML() {
    var l = waterLevel - waterLimit;
    return (l / 10.0).round();
  }
}

class MachineState {
  MachineState(this.shot, this.coffeeState);
  ShotState? shot;
  De1ShotHeaderClass? shotHeader;
  De1ShotFrameClass? shotFrame;

  WaterLevel? water;
  EspressoMachineState coffeeState;
  String subState = "";
}

enum EspressoMachineState { idle, espresso, water, steam, sleep, disconnected, connecting, refill, flush }

class EspressoMachineFullState {
  EspressoMachineState state = EspressoMachineState.disconnected;
  String subState = "";
}

class EspressoMachineService extends ChangeNotifier {
  final MachineState _state = MachineState(null, EspressoMachineState.disconnected);
  final log = Logger('EspressoMachineService');

  DE1? de1;

  late SharedPreferences prefs;

  late ProfileService profileService;
  late BLEService bleService;

  bool refillAnounced = false;

  bool inShot = false;

  String lastSubstate = "";

  late ScaleService scaleService;
  late CoffeeService coffeeService;
  late SettingsService settingsService;

  ShotList shotList = ShotList([]);
  double baseTime = 0;

  DateTime baseTimeDate = DateTime.now();

  Duration timer = const Duration(seconds: 0);

  var _count = 0;

  DateTime t1 = DateTime.now();

  int idleTime = 0;
  int sleepTime = 0;

  double pourTimeStart = 0;
  bool isPouring = false;

  double lastPourTime = 0;
  late ObjectBox objectBox;

  Shot currentShot = Shot();

  late StreamController<ShotState> _controllerShotState;
  late Stream<ShotState> _streamShotState;
  late TempService tempService;

  EspressoMachineState lastState = EspressoMachineState.disconnected;

  Battery _battery = Battery();

  final List<int> _waterAverager = [];

  Stream<ShotState> get streamShotState => _streamShotState;

  late StreamController<WaterLevel> _controllerWaterLevel;
  late Stream<WaterLevel> _streamWaterLevel;
  Stream<WaterLevel> get streamWaterLevel => _streamWaterLevel;

  late StreamController<EspressoMachineFullState> _controllerEspressoMachineState;
  late Stream<EspressoMachineFullState> _streamState;
  Stream<EspressoMachineFullState> get streamState => _streamState;

  late StreamController<int> _controllerBattery;
  late Stream<int> _streamBatteryState;
  Stream<int> get streamBatteryState => _streamBatteryState;

  EspressoMachineFullState currentFullState = EspressoMachineFullState();

  EspressoMachineService() {
    _controllerShotState = StreamController<ShotState>();
    _streamShotState = _controllerShotState.stream.asBroadcastStream();

    _controllerEspressoMachineState = StreamController<EspressoMachineFullState>();
    _streamState = _controllerEspressoMachineState.stream.asBroadcastStream();

    _controllerWaterLevel = StreamController<WaterLevel>();
    _streamWaterLevel = _controllerWaterLevel.stream.asBroadcastStream();

    _controllerBattery = StreamController<int>();
    _streamBatteryState = _controllerBattery.stream.asBroadcastStream();

    init();
    _controllerEspressoMachineState.add(currentFullState);
  }
  void init() async {
    profileService = getIt<ProfileService>();
    settingsService = getIt<SettingsService>();
    bleService = getIt<BLEService>();

    objectBox = getIt<ObjectBox>();
    profileService.addListener(updateProfile);
    scaleService = getIt<ScaleService>();
    coffeeService = getIt<CoffeeService>();

    log.fine('Preferences loaded');

    notifyListeners();
    loadShotData();

    try {
      handleBattery();
    } catch (e) {
      log.severe("Error handling battery $e");
    }
    tempService = getIt<TempService>();
    handleTemperature();

    Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (state.coffeeState == EspressoMachineState.sleep) {
        try {
          log.fine("Machine is still sleeping $sleepTime ${settingsService.screenLockTimer * 60}");
          sleepTime += 10;

          if (sleepTime > settingsService.screenLockTimer * 60 && settingsService.screenLockTimer > 0.1) {
            try {
              if (await Wakelock.enabled) {
                log.info('Disable WakeLock');
                Wakelock.disable();
              }
            } on MissingPluginException catch (e) {
              log.severe('Failed to set wakelock: $e');
            }
          }
        } catch (e) {
          log.severe("Error $e");
        }
      } else {
        sleepTime = 0;
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
      }

      if (state.coffeeState == EspressoMachineState.idle) {
        try {
          log.fine("Machine is still idle $idleTime < ${settingsService.sleepTimer * 60}");
          idleTime += 10;

          if (idleTime > settingsService.sleepTimer * 60 && settingsService.sleepTimer > 0.1) {
            de1?.switchOff();
          }
        } catch (e) {
          {}
          log.severe("Error $e");
        }
      } else {
        idleTime = 0;
      }
    });
  }

  handleBattery() async {
// Access current battery level
    var state = await _battery.batteryLevel;
    log.fine("Battery: $state");

// Be informed when the state (full, charging, discharging) changes
    _battery.onBatteryStateChanged.listen((BatteryState state) async {
      // Do something with new state
      final batteryLevel = await _battery.batteryLevel;
      log.info("Battery: changed: $state $batteryLevel");
      //_controllerBattery.add(batteryLevel);
      if (de1 == null) {
        log.severe("Battery: DE1 not connected yet");
        _controllerBattery.add(batteryLevel);
        return;
      }
      if (settingsService.smartCharging) {
        if (batteryLevel < 60) {
          log.info("Battery: below 60");
          de1!.setUsbChargerMode(1);
        } else if (batteryLevel > 70) {
          log.info("Battery: above 70");
          de1!.setUsbChargerMode(0);
        } else {
          de1!.setUsbChargerMode(de1!.usbChargerMode);
        }

        Future.delayed(
          const Duration(seconds: 1),
          () {
            _controllerBattery.add(batteryLevel);
          },
        );
      } else {
        log.info("Battery: SmartCharging off");
        _controllerBattery.add(batteryLevel);
      }
    });
  }

  loadShotData() async {
    currentShot = coffeeService.getLastShot() ?? Shot();
    shotList.entries = currentShot.shotstates;
    // await shotList.load("testshot.json");
    log.fine("Lastshot loaded ${shotList.entries.length}");
    notifyListeners();
  }

  updateProfile() {}

  void setShot(ShotState shot) {
    _state.shot = shot;
    _count++;
    if (_count % 10 == 0) {
      var t = DateTime.now();
      var ms = t.difference(t1).inMilliseconds;
      var hz = 10 / ms * 1000.0;
      if (_state.coffeeState == EspressoMachineState.espresso || _count & 50 == 0) log.fine("Hz: $ms $hz");
      t1 = t;
    }
    handleShotData();
    notifyListeners();
    _controllerShotState.add(shot);
  }

  void setWaterLevel(WaterLevel water) {
    try {
      _waterAverager.add(water.waterLevel);
      if (_waterAverager.length > 10) {
        _waterAverager.removeAt(0);
      }
      var avWater = _waterAverager.average;
      water.waterLevel = avWater.toInt();
      _state.water = water;
      notifyListeners();
      _controllerWaterLevel.add(water);
    } catch (e) {
      log.severe("Waterlevel add not possible $e");
    }
  }

  void setState(EspressoMachineState state) {
    _state.coffeeState = state;

    if (lastState != state &&
        (_state.coffeeState == EspressoMachineState.espresso || _state.coffeeState == EspressoMachineState.water)) {
      if (settingsService.shotAutoTare) {
        scaleService.tare();
      }
    }
    if (state == EspressoMachineState.idle &&
        scaleService.state == ScaleState.disconnected &&
        (_state.subState == "heat_water_tank" || _state.subState == "no_state")) {
      log.info("Trying to autoconnect to scale");
      bleService.startScan();
    }

    notifyListeners();
    currentFullState.state = state;
    _controllerEspressoMachineState.add(currentFullState);
    lastState = state;
  }

  void setSubState(String state) {
    _state.subState = state;
    notifyListeners();
    currentFullState.subState = state;
    _controllerEspressoMachineState.add(currentFullState);
  }

  MachineState get state => _state;

  void setDecentInstance(DE1 de1) {
    this.de1 = de1;
  }

  void setShotHeader(De1ShotHeaderClass sh) {
    _state.shotHeader = sh;
    log.fine("Shotheader:$sh");
    notifyListeners();
  }

  void setShotFrame(De1ShotFrameClass sh) {
    _state.shotFrame = sh;
    log.fine("ShotFrame:$sh");
    notifyListeners();
  }

  Future<String> uploadProfile(De1ShotProfile profile) async {
    log.fine("Save profile $profile");
    var header = profile.shotHeader;

    try {
      log.fine("Write Header: $header");
      await de1!.writeWithResult(Endpoint.headerWrite, header.bytes);
    } catch (ex) {
      log.fine("Save profile $profile");
      return "Error writing profile header $ex";
    }

    for (var fr in profile.shotFrames) {
      try {
        log.fine("Write Frame: $fr");
        await de1!.writeWithResult(Endpoint.frameWrite, fr.bytes);
      } catch (ex) {
        return "Error writing shot frame $fr";
      }
    }

    for (var exFrame in profile.shotExframes) {
      try {
        log.fine("Write ExtFrame: $exFrame");
        await de1!.writeWithResult(Endpoint.frameWrite, exFrame.bytes);
      } catch (ex) {
        return "Error writing ex shot frame $exFrame";
      }
    }

    // stop at volume in the profile tail
    if (true) {
      var tailBytes = De1ShotHeaderClass.encodeDe1ShotTail(profile.shotFrames.length, 0);

      try {
        log.fine("Write Tail: $tailBytes");
        await de1!.writeWithResult(Endpoint.frameWrite, tailBytes);
      } catch (ex) {
        return "Error writing shot frame tail $tailBytes";
      }
    }

    // check if we need to send the new water temp
    if (settingsService.targetGroupTemp != profile.shotFrames[0].temp) {
      profile.shotHeader.targetGroupTemp = profile.shotFrames[0].temp;
      var bytes = encodeDe1OtherSetn();

      try {
        log.fine("Write Shot Settings: $bytes");
        await de1!.writeWithResult(Endpoint.shotSettings, bytes);
      } catch (ex) {
        return "Error writing shot settings $bytes";
      }
    }
    return Future.value("");
  }

  void handleShotData() {
    // checkForRefill();

    if (state.coffeeState == EspressoMachineState.sleep ||
        state.coffeeState == EspressoMachineState.disconnected ||
        state.coffeeState == EspressoMachineState.refill) {
      return;
    }
    var shot = state.shot;
    // if (machineService.state.subState.isNotEmpty) {
    //   subState = machineService.state.subState;
    // }
    if (shot == null) {
      log.fine('Shot null');
      return;
    }
    if (state.coffeeState == EspressoMachineState.idle && inShot == true) {
      baseTimeDate = DateTime.now();
      refillAnounced = false;
      inShot = false;
      if (shotList.saved == false &&
          shotList.entries.isNotEmpty &&
          shotList.saving == false &&
          shotList.saved == false) {
        shotFinished();
      }

      return;
    }
    if (!inShot && state.coffeeState == EspressoMachineState.espresso) {
      log.info('Not Idle and not in Shot');
      inShot = true;
      isPouring = false;
      shotList.clear();
      baseTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      log.info("basetime $baseTime");
      lastPourTime = 0;
    }
    if (state.coffeeState == EspressoMachineState.espresso &&
        lastSubstate != state.subState &&
        state.subState == "pour") {
      pourTimeStart = DateTime.now().millisecondsSinceEpoch / 1000.0;
      isPouring = true;
    } else if (state.coffeeState == EspressoMachineState.espresso &&
        lastSubstate != state.subState &&
        state.subState != "pour") {
      isPouring = false;
    }

    if (state.coffeeState == EspressoMachineState.water && lastSubstate != state.subState && state.subState == "pour") {
      log.info('Startet water pour');
      baseTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      baseTimeDate = DateTime.now();
      log.fine("basetime $baseTime");
    }

    if (state.coffeeState == EspressoMachineState.steam && lastSubstate != state.subState && state.subState == "pour") {
      log.info('Startet steam pour');
      tempService.resetHistory();
      baseTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      baseTimeDate = DateTime.now();
      log.fine("basetime $baseTime");
    }
    if (state.coffeeState == EspressoMachineState.flush && lastSubstate != state.subState && state.subState == "pour") {
      log.info('Startet flush pour');
      baseTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      baseTimeDate = DateTime.now();
      log.fine("basetime $baseTime");
    }

    var subState = state.subState;
    timer = DateTime.now().difference(baseTimeDate);
    if (!(shot.sampleTimeCorrected > 0)) {
      if (lastSubstate != subState && subState.isNotEmpty) {
        log.info("SubState: $subState");
        lastSubstate = state.subState;
        shot.subState = lastSubstate;
      }

      shot.weight = scaleService.weight;
      shot.flowWeight = scaleService.flow;
      shot.sampleTimeCorrected = shot.sampleTime - baseTime;
      if (isPouring) {
        shot.pourTime = shot.sampleTime - pourTimeStart;
        lastPourTime = shot.pourTime;
      }

      switch (state.coffeeState) {
        case EspressoMachineState.espresso:
          if (scaleService.state == ScaleState.connected) {
            if (profileService.currentProfile!.shotHeader.targetWeight > 1 &&
                shot.weight + 1 > profileService.currentProfile!.shotHeader.targetWeight) {
              log.info(
                  "Shot Weight reached ${shot.weight} > ${profileService.currentProfile!.shotHeader.targetWeight}");

              if (settingsService.shotStopOnWeight) {
                triggerEndOfShot();
              }
            }
          }
          break;
        case EspressoMachineState.water:
          if (scaleService.state == ScaleState.connected) {
            if (settingsService.targetHotWaterWeight > 1 &&
                scaleService.weight + 1 > settingsService.targetHotWaterWeight) {
              log.info(
                  "Water Weight reached ${shot.weight} > ${profileService.currentProfile!.shotHeader.targetWeight}");

              if (settingsService.shotStopOnWeight) {
                triggerEndOfShot();
              }
            }
          }
          if (state.subState == "pour" &&
              settingsService.targetHotWaterLength > 1 &&
              timer.inSeconds > settingsService.targetHotWaterLength) {
            log.info("Water Timer reached ${timer.inSeconds} > ${settingsService.targetHotWaterLength}");

            triggerEndOfShot();
          }

          break;
        case EspressoMachineState.steam:
          if (state.subState == "pour" &&
              settingsService.targetSteamLength > 1 &&
              timer.inSeconds > settingsService.targetSteamLength) {
            log.info("Steam Timer reached ${timer.inSeconds} > ${settingsService.targetSteamLength}");

            triggerEndOfShot();
          }

          break;
        case EspressoMachineState.flush:
          if (state.subState == "pour" &&
              settingsService.targetFlushTime > 1 &&
              timer.inSeconds > settingsService.targetFlushTime) {
            log.info("Flush Timer reached ${timer.inSeconds} > ${settingsService.targetFlushTime}");

            triggerEndOfShot();
          }

          break;
        case EspressoMachineState.idle:
          break;
        case EspressoMachineState.sleep:
          break;
        case EspressoMachineState.disconnected:
          break;
        case EspressoMachineState.connecting:
          break;
        case EspressoMachineState.refill:
          break;
      }

      //if (profileService.currentProfile.shot_header.target_weight)
      if (inShot == true) {
        shotList.add(shot);
      }
    }
  }

  void triggerEndOfShot() {
    log.info("Idle mode initiated because of weight");

    de1?.requestState(De1StateEnum.idle);
    // Future.delayed(const Duration(milliseconds: 5000), () {
    // log.info("Idle mode initiated finished", error: {DateTime.now()});
    //   stopTriggered = false;
    // });
  }

  shotFinished() async {
    log.info("Save last shot");
    try {
      currentShot = Shot();
      currentShot.coffee.targetId = coffeeService.selectedCoffee;

      currentShot.shotstates.addAll(shotList.entries);

      currentShot.pourTime = lastPourTime;
      currentShot.profileId = profileService.currentProfile?.id ?? "";
      currentShot.pourWeight = shotList.entries.last.weight;

      var id = coffeeService.shotBox.put(currentShot);

      await coffeeService.setLastShotId(id);

      shotList.saveData();
      // currentShot = Shot();
    } catch (ex) {
      log.severe("Error writing file: $ex");
    }
  }

  Future<void> updateSettings() async {
    notifyListeners();

    var bytes = encodeDe1OtherSetn();
    try {
      log.info("Write Shot Settings: $bytes");
      await de1!.writeWithResult(Endpoint.shotSettings, bytes);
    } catch (ex) {
      log.severe("Error writing shot settings $bytes");
    }
  }

  Uint8List encodeDe1OtherSetn() {
    Uint8List data = Uint8List(9);

    int index = 0;
    data[index] = settingsService.steamSettings;
    index++;
    data[index] = settingsService.targetSteamTemp;
    index++;
    data[index] = settingsService.targetSteamLength;
    index++;
    data[index] = settingsService.targetHotWaterTemp;
    index++;
    data[index] = settingsService.targetHotWaterVol;
    index++;
    data[index] = settingsService.targetHotWaterLength;
    index++;
    data[index] = settingsService.targetEspressoVol;
    index++;

    data[index] = settingsService.targetGroupTemp.toInt();
    index++;
    data[index] = ((settingsService.targetGroupTemp - settingsService.targetGroupTemp.floor()) * 256.0).toInt();
    index++;

    return data;
  }

  void handleTemperature() {
    tempService.stream.listen((event) {
      if (settingsService.hasSteamThermometer &&
          event.state == TempState.connected &&
          state.coffeeState == EspressoMachineState.steam &&
          state.subState == "pour") {
        if (event.temp1 >= settingsService.targetMilkTemperature) {
          log.info("End of shot ${event.temp1} > ${settingsService.targetMilkTemperature}");
          triggerEndOfShot();
        }
      }
    });
  }
}

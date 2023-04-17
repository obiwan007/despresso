import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:despresso/devices/abstract_decent_de1.dart';
import 'package:despresso/devices/decent_de1.dart';
import 'package:despresso/helper/linear_regress.ion.dart';
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

  IDe1? de1;

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

  bool _delayedStopActive = false;

  int flushCounter = 0;
  DateTime lastFlushTime = DateTime.now();

  double _sampleTime = 0;

  ShotState? _previousShot;
  ShotState? _newestShot;

  ShotState? _floatingShot;

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

          // if (sleepTime > settingsService.screenLockTimer * 60 && settingsService.screenLockTimer > 0.1) {
          //   try {
          //     if (await Wakelock.enabled) {
          //       log.info('Disable WakeLock');
          //       Wakelock.disable();
          //     }
          //   } on MissingPluginException catch (e) {
          //     log.severe('Failed to set wakelock: $e');
          //   }
          // }
        } catch (e) {
          log.severe("Error $e");
        }
      } else {
        sleepTime = 0;
        // try {
        //   if ((await Wakelock.enabled) == false) {
        //     log.info('enable WakeLock');
        //     Wakelock.enable();
        //   } else {
        //     log.fine('is enabled WakeLock');
        //   }
        // } on MissingPluginException catch (e) {
        //   log.severe('Failed to set wakelock enable: $e');
        // }
      }

      if (state.coffeeState == EspressoMachineState.idle) {
        isPouring = false;
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
    // var state = await _battery.batteryLevel;
    // log.fine("Battery: $state");

// Be informed when the state (full, charging, discharging) changes
    _battery.onBatteryStateChanged.listen((BatteryState state) async {
      // Do something with new state
      try {
        final batteryLevel = await _battery.batteryLevel;
        log.info("Battery: changed: $state $batteryLevel");

        //_controllerBattery.add(batteryLevel);
        if (de1 == null) {
          log.fine("Battery: DE1 not connected yet");
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
      } catch (e) {}
    });
  }

  loadShotData() async {
    currentShot = coffeeService.getLastShot() ?? Shot();
    shotList.entries = currentShot.shotstates;
    lastPourTime = currentShot.pourTime;
    // await shotList.load("testshot.json");
    log.fine("Lastshot loaded ${shotList.entries.length}");
    notifyListeners();
  }

  double getOverallTime() {
    if (shotList.entries.isNotEmpty) {
      return shotList.entries.last.sampleTimeCorrected;
    }
    return 0;
  }

  updateProfile() {}

  void setShot(ShotState shot) {
    if (shot == null) return;
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
    // notifyListeners();
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

  void setDecentInstance(IDe1 de1) {
    this.de1 = de1;
  }

  void setShotHeader(De1ShotHeaderClass sh) {
    _state.shotHeader = sh;
    log.fine("Shotheader:$sh");
    // notifyListeners();
  }

  void setShotFrame(De1ShotFrameClass sh) {
    _state.shotFrame = sh;
    log.fine("ShotFrame:$sh");
    // notifyListeners();
  }

  Future<String> uploadProfile(De1ShotProfile profileToBeUploaded) async {
    if (de1 == null) {
      return Future.error("No de1 connected");
    }
    var profile = profileToBeUploaded.clone();
    log.info("Uploading profile to machine $profile");
    var header = profile.shotHeader;

    try {
      log.info("Write Header: $header");
      await de1!.writeWithResult(Endpoint.headerWrite, header.bytes);
    } catch (ex) {
      log.severe("Error writing header $profile $ex");
      return "Error writing profile header $ex";
    }

    for (var fr in profile.shotFrames) {
      try {
        log.info("Write Frame: $fr");
        var oldTemp = fr.temp;
        fr.temp += settingsService.targetTempCorrection;
        var bytes = De1ShotFrameClass.encodeDe1ShotFrame(fr);
        await de1!.writeWithResult(Endpoint.frameWrite, bytes);
        fr.temp = oldTemp;
      } catch (ex) {
        log.severe("Error writing frame $profile $ex");
        return "Error writing shot frame $fr";
      }
    }

    for (var exFrame in profile.shotExframes) {
      try {
        log.info("Write ExtFrame: $exFrame");
        await de1!.writeWithResult(Endpoint.frameWrite, exFrame.bytes);
      } catch (ex) {
        log.severe("Error writing exframe $profile $ex");
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

      try {
        log.fine("Write Shot Settings");
        await de1!.updateSettings();
      } catch (ex) {
        return "Error writing shot settings";
      }
    }
    return Future.value("");
  }

  Future<void> handleShotData() async {
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
      currentShot = Shot();
      currentShot.targetEspressoWeight = settingsService.targetEspressoWeight;

      _delayedStopActive = false;
      isPouring = false;
      shotList.clear();
      baseTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      log.info("basetime $baseTime");
      lastPourTime = 0;
    }
    if (state.coffeeState == EspressoMachineState.espresso &&
        lastSubstate != state.subState &&
        lastSubstate == "heat_water_heater") {
      log.info('Heating phase over');
      shotList.clear();
      baseTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      log.info("new basetime $baseTime");
      lastPourTime = 0;
    }

    if (state.coffeeState == EspressoMachineState.espresso &&
        lastSubstate != state.subState &&
        state.subState == "pour") {
      pourTimeStart = DateTime.now().millisecondsSinceEpoch / 1000.0;
      isPouring = true;
      _previousShot = null;
      _newestShot = null;
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
      flushCounter++;
      // If second flush was done, reset to first flush
      if (flushCounter > 2) flushCounter = 1;
      // Reset to default flush after 30 sec.
      if (DateTime.now().difference(lastFlushTime).inSeconds > 30) flushCounter = 1;

      log.info('Startet flush pour $flushCounter ${DateTime.now().difference(lastFlushTime).inSeconds}');
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
          if (lastPourTime > 5 && scaleService.state == ScaleState.connected) {
            var weight = settingsService.targetEspressoWeight;
            if (weight < 1) {
              weight = profileService.currentProfile!.shotHeader.targetWeight;
            }

            if (isPouring && settingsService.shotStopOnWeight && weight > 1 && _delayedStopActive == false) {
              var valuesCount = calcWeightReachedEstimation();
              if (valuesCount > 0) {
                var timeToWeight = currentShot.estimatedWeightReachedTime - shot.sampleTimeCorrected;
                // var timeToWeight = (weight - shot.weight) / shot.flowWeight;
                shot.timeToWeight = timeToWeight;
                log.info("Time to weight: $timeToWeight ${shot.weight} ${shot.flowWeight}");
                if (timeToWeight > 0 &&
                    timeToWeight < 2.5 &&
                    (settingsService.targetEspressoWeight - shot.weight < 5)) {
                  _delayedStopActive = true;
                  log.info("Shot weight reached soon, starting delayed stop");
                  Future.delayed(
                    Duration(
                        milliseconds: ((timeToWeight - settingsService.targetEspressoWeightTimeAdjust) * 1000).toInt()),
                    () {
                      log.info("Shot weight reached now!, stopping ${state.shot!.weight}");
                      triggerEndOfShot();
                    },
                  );
                }
              }
              // if (weight > 1 && shot.weight + 1 > weight) {
              //   log.info("Shot Weight reached ${shot.weight} > $weight Portime: $lastPourTime");

              //   if (settingsService.shotStopOnWeight) {
              //     triggerEndOfShot();
              //   }
              // }
            }
          }
          break;
        case EspressoMachineState.water:
          if (scaleService.state == ScaleState.connected) {
            if (state.subState == "pour" &&
                settingsService.targetHotWaterWeight > 1 &&
                scaleService.weight + 1 > settingsService.targetHotWaterWeight) {
              log.info("Water Weight reached ${shot.weight} > ${settingsService.targetHotWaterWeight}");

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
          var flushTime = flushCounter == 1 ? settingsService.targetFlushTime : settingsService.targetFlushTime2;
          bool reachedGoal = state.subState == "pour" && flushTime > 1.0 && timer.inSeconds.toDouble() > flushTime;
          log.info("Flush Timer $reachedGoal ${timer.inMilliseconds / 1000.0} > $flushTime");
          if (reachedGoal) {
            log.info("Flush Timer reached ${timer.inSeconds} > $flushTime");
            lastFlushTime = DateTime.now();
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
        shot.isPouring = isPouring;
        if (isPouring) {
          var t = 50;
          // var index = shotList.entries.length - 5;
          // if (index > 0) {
          //   shotList.entries.removeAt(index);
          //   shotList.entries.removeAt(index);
          //   shotList.entries.removeAt(index);
          //   shotList.entries.removeAt(index);
          // }
          var l = shotList.entries.length;
          shot.isInterpolated = false;

          // shotList.entries.removeWhere(
          //     (element) => (element.isInterpolated == true && (_sampleTime - element.sampleTimeCorrected) > 1.3));
          // shotList.entries.removeWhere((element) => (element.isInterpolated == true));
          // var oldShot = shotList.entries.indexWhere((element) => (element.isInterpolated == true));
          var c = 5;
          var hz = 4;
          var f = 1 / hz * 1000;
          int ms = (f / (c + 1)).toInt();

          // if (oldShot == -1) {
          if (_newestShot != null) {
            // shotList.add(_newestShot!);
            // shotList.add(ShotState.fromJson(shot.toJson()));
            _previousShot = ShotState.fromJson(_newestShot!.toJson());
          }

          _newestShot = ShotState.fromJson(shot.toJson());
          ;

          if (_previousShot != null) {
            if (_floatingShot == null) {
              // _floatingShot = ShotState.fromJson(shot!.toJson());
              // shotList.add(_floatingShot!);
            }

            var linGP = LineEq.calcLinearEquation(_newestShot!.sampleTimeCorrected, _previousShot!.sampleTimeCorrected,
                _newestShot!.groupPressure, _previousShot!.groupPressure);

            var linGP_S = LineEq.calcLinearEquation(_newestShot!.sampleTimeCorrected,
                _previousShot!.sampleTimeCorrected, _newestShot!.setGroupPressure, _previousShot!.setGroupPressure);

            var linGF = LineEq.calcLinearEquation(_newestShot!.sampleTimeCorrected, _previousShot!.sampleTimeCorrected,
                _newestShot!.groupFlow, _previousShot!.groupFlow);

            var linGF_S = LineEq.calcLinearEquation(_newestShot!.sampleTimeCorrected,
                _previousShot!.sampleTimeCorrected, _newestShot!.setGroupFlow, _previousShot!.setGroupFlow);

            var linWF = LineEq.calcLinearEquation(_newestShot!.sampleTimeCorrected, _previousShot!.sampleTimeCorrected,
                _newestShot!.flowWeight, _previousShot!.flowWeight);

            // var newShot = ShotState.fromJson(_previousShot!.toJson());
            // shotList.add(newShot);
            // _floatingShot = ShotState.fromJson(_previousShot!.toJson());
            _floatingShot = ShotState.fromJson(_previousShot!.toJson());
            shotList.add(_floatingShot!);
            var base = ShotState.fromJson(_previousShot!.toJson());
            var fs = _floatingShot!;
            // fs.sampleTimeCorrected = base.sampleTimeCorrected;

            for (var t = 0; t < c; t += 1) {
              await Future.delayed(Duration(milliseconds: ms), () {
                fs.isInterpolated = t == c - 1 ? false : true;

                // if (t == 1) shotList.entries.removeWhere((element) => (element.isInterpolated == true));
                // var newShot = ShotState.fromJson(shot.toJson());
                // newShot.groupPressure = 1;
                fs.sampleTimeCorrected += (t) * ms / 1000;
                fs.groupPressure = linGP.getY(fs.sampleTimeCorrected);
                fs.setGroupPressure = linGP_S.getY(fs.sampleTimeCorrected);
                fs.groupFlow = linGF.getY(fs.sampleTimeCorrected);
                fs.setGroupFlow = linGF_S.getY(fs.sampleTimeCorrected);
                fs.flowWeight = linWF.getY(fs.sampleTimeCorrected);
                // log.info("Shot: $t ${newShot.isInterpolated} ${newShot.sampleTimeCorrected}");
                // shotList.lastTouched = (newShot.sampleTimeCorrected * 100).toInt();

                shotList.lastTouched++;
                notifyListeners();
              });
            }
            // shotList.lastTouched++;
            // shotList.entries.insert(shotList.entries.length - 3, shot);
            // // shotList.add(shot);
            // notifyListeners();
            // notifyListeners();
          } else {
            shotList.lastTouched++;
            shotList.add(shot);

            notifyListeners();
          }
        } else {
          // make a single value for the first few seconds to show some action ongoing
          shotList.lastTouched++;
          if (shotList.entries.isEmpty) {
            shotList.entries.add(shot);
          } else if (shotList.entries.length == 1) {
            shotList.entries[0] = shot;
          }
          notifyListeners();
        }
      }
    }
  }

  void triggerEndOfShot() {
    log.info("Idle mode initiated because of goal reached");

    de1?.requestState(De1StateEnum.idle);
    // Future.delayed(const Duration(milliseconds: 5000), () {
    // log.info("Idle mode initiated finished", error: {DateTime.now()});
    //   stopTriggered = false;
    // });
  }

  shotFinished() async {
    log.info("Save last shot");
    try {
      var cs = Shot();
      cs.coffee.targetId = coffeeService.selectedCoffeeId;
      cs.recipe.targetId = coffeeService.selectedRecipeId;

      cs.shotstates
          .addAll(shotList.entries.where((element) => element.isPouring == true && element.isInterpolated == false));

      cs.pourTime = lastPourTime;
      cs.profileId = profileService.currentProfile?.id ?? "";
      cs.targetEspressoWeight = settingsService.targetEspressoWeight;
      cs.targetTempCorrection = settingsService.targetTempCorrection;
      cs.doseWeight = coffeeService.currentRecipe?.grinderDoseWeight ?? 0;
      cs.pourWeight = shotList.entries.last.weight;
      cs.ratio1 = coffeeService.currentRecipe?.ratio1 ?? 1;
      cs.ratio2 = coffeeService.currentRecipe?.ratio2 ?? 1;

      cs.grinderSettings = coffeeService.currentRecipe?.grinderSettings ?? 0;
      cs.estimatedWeightReachedTime = currentShot.estimatedWeightReachedTime;
      cs.estimatedWeight_b = currentShot.estimatedWeight_b;
      cs.estimatedWeight_m = currentShot.estimatedWeight_m;
      cs.estimatedWeight_tEnd = currentShot.estimatedWeight_tEnd;
      cs.estimatedWeight_tStart = currentShot.estimatedWeight_tStart;
      await coffeeService.addNewShot(cs);

      shotList.saveData();

      currentShot = cs;
    } catch (ex) {
      log.severe("Error writing file: $ex");
    }
  }

  Future<void> updateSettings() async {
    if (de1 == null) return;

    await de1!.updateSettings();
    // var bytes = encodeDe1OtherSetn();
    // try {
    //   log.info("Write Shot Settings: $bytes");
    //   await de1?.writeWithResult(Endpoint.shotSettings, bytes);
    // } catch (ex) {
    //   log.severe("Error writing shot settings $bytes");
    // }
    notifyListeners();
  }

  Future<void> updateFlush() async {
    if (de1 == null) return;

    await de1!.setFlushTimeout(max(settingsService.targetFlushTime, settingsService.targetFlushTime2));
    // var bytes = encodeDe1OtherSetn();
    // try {
    //   log.info("Write Shot Settings: $bytes");
    //   await de1?.writeWithResult(Endpoint.shotSettings, bytes);
    // } catch (ex) {
    //   log.severe("Error writing shot settings $bytes");
    // }
    notifyListeners();
  }

  // Uint8List encodeDe1OtherSetn() {
  //   Uint8List data = Uint8List(9);

  //   int index = 0;
  //   data[index] = settingsService.steamSettings;
  //   index++;
  //   data[index] = settingsService.steamHeaterOff ? 0 : settingsService.targetSteamTemp;
  //   index++;
  //   data[index] = settingsService.targetSteamLength;
  //   index++;
  //   data[index] = settingsService.targetHotWaterTemp;
  //   index++;
  //   data[index] = settingsService.targetHotWaterVol;
  //   index++;
  //   data[index] = settingsService.targetHotWaterLength;
  //   index++;
  //   data[index] = settingsService.targetEspressoVol;
  //   index++;

  //   data[index] = settingsService.targetGroupTemp.toInt();
  //   index++;
  //   data[index] = ((settingsService.targetGroupTemp - settingsService.targetGroupTemp.floor()) * 256.0).toInt();
  //   index++;

  //   return data;
  // }

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

  int calcWeightReachedEstimation() {
    List<ShotState> raw = shotList.entries;

    if (inShot == true) {
      currentShot.estimatedWeight_tEnd = raw.last.sampleTimeCorrected;
      currentShot.estimatedWeight_tStart = currentShot.estimatedWeight_tEnd - 3;
    }

    var weightData = raw
        .where((element) =>
            element.sampleTimeCorrected > currentShot.estimatedWeight_tStart &&
            element.sampleTimeCorrected < currentShot.estimatedWeight_tEnd)
        .map(
      (e) {
        return DataPoint(e.sampleTimeCorrected, e.weight);
      },
    ).toList();
    if (weightData.isNotEmpty) {
      var regressionData = Line.limit(linearRegression(weightData));
      log.info("Regression: ${regressionData.m} ${regressionData.b}");
      currentShot.estimatedWeightReachedTime = (currentShot.targetEspressoWeight - regressionData.b) / regressionData.m;
      currentShot.estimatedWeight_m = regressionData.m;
      currentShot.estimatedWeight_b = regressionData.b;
      return weightData.length;
    } else {
      return 0;
    }
  }
}

class LineEq {
  var log = Logger("lin");
  double m;
  double b;
  double x1;
  LineEq(this.m, this.b, this.x1);

  static LineEq calcLinearEquation(double x2, double x1, double y2, double y1) {
    double dx = (x2 - x1);
    double dy = (y2 - y1);
    double m = dy / dx;
    double b = y1;
    return LineEq(m, b, x1);
  }

  getY(double x) {
    double y = (m) * (x - x1) + b;
    log.info("lin: $y = ($m * $x + $b");
    return y;
  }
}

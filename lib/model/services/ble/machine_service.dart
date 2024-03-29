import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:despresso/devices/abstract_comm.dart';
import 'package:despresso/devices/abstract_decent_de1.dart';
import 'package:despresso/devices/abstract_scale.dart';
import 'package:despresso/devices/decent_de1.dart';
import 'package:despresso/helper/linear_regress.ion.dart';
import 'package:despresso/helper/savgol.dart';
import 'package:despresso/model/services/ble/ble_service.dart';
import 'package:despresso/model/services/ble/temperature_service.dart';
import 'package:despresso/model/services/cafehub/ch_service.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/settings_service.dart';

import 'package:despresso/model/de1shotclasses.dart';
import 'package:despresso/objectbox.dart';
import 'package:flutter/material.dart';

import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:battery_plus/battery_plus.dart';

import '../../../service_locator.dart';
import '../../shot.dart';
import '../../shotstate.dart';
import '../state/profile_service.dart';
import 'scale_service.dart';

// Map to find volume from height of mm probe.
// spreadsheet to calculate this calculated from CAD, from Mark Kelly, from decent de1app
const waterMap = [
  0,
  16,
  43,
  70,
  97,
  124,
  151,
  179,
  206,
  233,
  261,
  288,
  316,
  343,
  371,
  398,
  426,
  453,
  481,
  509,
  537,
  564,
  592,
  620,
  648,
  676,
  704,
  732,
  760,
  788,
  816,
  844,
  872,
  900,
  929,
  957,
  985,
  1013,
  1042,
  1070,
  1104,
  1138,
  1172,
  1207,
  1242,
  1277,
  1312,
  1347,
  1382,
  1417,
  1453,
  1488,
  1523,
  1559,
  1594,
  1630,
  1665,
  1701,
  1736,
  1772,
  1808,
  1843,
  1879,
  1915,
  1951,
  1986,
  2022,
  2058,
];

class TimedWeightMeasurement {
  TimedWeightMeasurement(this.weight, this.time);

  WeightMeassurement weight;
  DateTime time;
}

class WaterLevel {
  WaterLevel(this.waterLevel, this.waterLimit);

  int waterLevel = 0;
  int waterLimit = 0;

  int getLevelPercent() {
    var l = waterLevel - waterLimit;
    return l * 100 ~/ 8300;
  }

  int getLevelMM() {
    var l = waterLevel;
    return (l / 256).round();
  }

  int getLevelML() {
    // Offset because probe starts above water.
    var l = getLevelMM() + 5;
    return l > 0 && l < waterMap.length ? waterMap[l] : 0;
  }

  int getLevelRefill() {
    var l = (waterLimit / 256).round();
    return l > 0 && l < waterMap.length ? waterMap[l] : 0;
  }

  static int getLevelFromHeight(int height) {
    var l = (height / 256).round();
    return l > 0 && l < waterMap.length ? waterMap[l] : 0;
  }

  static int getLevelFromVolume(int vol) {
    int i = 0;
    for (var element in waterMap) {
      if (element > vol) {
        return i - 1;
      }
      i++;
    }
    return 0;
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

enum EspressoMachineState {
  idle,
  espresso,
  water,
  steam,
  sleep,
  disconnected,
  connecting,
  refill,
  flush,
  descale,
  clean,
  airPurge
}

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
  late DeviceCommunication bleService;

  bool refillAnounced = false;

  bool inShot = false;

  String lastSubstate = "";

  late ScaleService scaleService;
  late CoffeeService coffeeService;
  late SettingsService settingsService;

  // Keeps track of events from ScaleService (cleared at start of shot).
  // Useful if you need weight samples that aren't quantized to ShotList
  // elements
  List<TimedWeightMeasurement> weightMeasurementsDuringShot = [];
  bool weightSubscriptionShouldCancel = false;
  StreamSubscription<WeightMeassurement>? weightSubscription;
  Completer<TimedWeightMeasurement> weightCompleter = Completer();
  double flowRateForecast = 0.0;
  Set<int> _weightMoveOnFrames = {};

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

  late StreamController<String> _controllerFrameName;
  late Stream<String> _streamFrameName;
  Stream<String> get streamFrameName => _streamFrameName;

  EspressoMachineState lastState = EspressoMachineState.disconnected;

  final Battery _battery = Battery();

  final List<int> _waterAverager = [];

  bool _delayedStopActive = false;

  int flushCounter = 0;
  DateTime lastFlushTime = DateTime.now();

  ShotState? _previousShot;
  ShotState? _newestShot;

  ShotState? _floatingShot;

  int _lastFrameNumber = -1;

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

  LineEq linGP = LineEq(1, 0, 0);
  LineEq lingpS = LineEq(1, 0, 0);
  LineEq linGF = LineEq(1, 0, 0);
  LineEq lingfS = LineEq(1, 0, 0);
  LineEq linWF = LineEq(1, 0, 0);

  EspressoMachineService() {
    _controllerShotState = StreamController<ShotState>();
    _streamShotState = _controllerShotState.stream.asBroadcastStream();

    _controllerEspressoMachineState = StreamController<EspressoMachineFullState>();
    _streamState = _controllerEspressoMachineState.stream.asBroadcastStream();

    _controllerWaterLevel = StreamController<WaterLevel>();
    _streamWaterLevel = _controllerWaterLevel.stream.asBroadcastStream();

    _controllerBattery = StreamController<int>();
    _streamBatteryState = _controllerBattery.stream.asBroadcastStream();

    _controllerFrameName = StreamController<String>();
    _streamFrameName = _controllerFrameName.stream.asBroadcastStream();

    init();
    _controllerEspressoMachineState.add(currentFullState);
  }

  void attachWeightListener () {
    weightSubscriptionShouldCancel = false;
    weightCompleter = Completer();
    weightSubscription = scaleService.stream0.listen(weightListener);
  }

  Future<List<TimedWeightMeasurement>> detachWeightListener ( )async {
    if (weightSubscription == null) {
      return Future.value(weightMeasurementsDuringShot);
    }

    if (weightMeasurementsDuringShot.isEmpty) {
      // we probably won't receive any more weight measurements if we didn't
      // get any during the shot, so just clean up the subscription now.
      weightSubscription?.cancel();
      weightSubscription = null;
      return Future.value(weightMeasurementsDuringShot);
    }

    // otherwise, setting this flag lets the subscription know to wait for flow
    // rate to drop off before canceling
    weightSubscriptionShouldCancel = true;

    // wait up to 2 seconds for flow rate to drop to near-zero, so our weight data
    // captures any additional weight flow after the machine goes into the idle
    // state.
    final fallback = Future.delayed(const Duration(seconds: 2));
    await Future.any([weightCompleter.future, fallback]);

    // resolve a new list holding the shot's weights
    final measurementsToResolve = [...weightMeasurementsDuringShot];
    weightMeasurementsDuringShot.clear();
    return measurementsToResolve;
  }

  void weightListener(WeightMeassurement measurement) {
    final timedMeasurement =
        TimedWeightMeasurement(measurement, DateTime.now());
    weightMeasurementsDuringShot.add(timedMeasurement);

    flowRateForecast = getFlowRateForecast(const Duration(seconds: 1));

    if (weightSubscriptionShouldCancel &&
        flowRateForecast < 0.1 &&
        !weightCompleter.isCompleted) {
      weightSubscription?.cancel();
      weightSubscription = null;
      weightCompleter.complete(timedMeasurement);
      return;
    }
  }

  void init() async {
    profileService = getIt<ProfileService>();
    settingsService = getIt<SettingsService>();

    if (settingsService.useCafeHub) {
      bleService = getIt<CHService>();
    } else {
      bleService = getIt<BLEService>();
    }

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
          log.fine("Machine is still sleeping $sleepTime");
          sleepTime += 10;
          if (sleepTime < 30 && settingsService.scaleDisplayOffOnSleep) {
            scaleService.display(DisplayMode.off);
          }
        } catch (e) {
          log.severe("Error $e");
        }
      } else {
        sleepTime = 0;
      }

      if (state.coffeeState == EspressoMachineState.idle) {
        isPouring = false;

        if (idleTime == 0 && settingsService.scaleDisplayOffOnSleep) {
          scaleService.display(DisplayMode.on);
        }

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
        // ignore: empty_catches
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

  void setShot(ShotState? shot) {
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

  Future<void> setState(EspressoMachineState state) async {
    _state.coffeeState = state;

    if (lastState != state &&
        (_state.coffeeState == EspressoMachineState.espresso || _state.coffeeState == EspressoMachineState.water)) {
      if (settingsService.shotAutoTare) {
        await scaleService.tare();
      }
      if (settingsService.scaleStartTimer) {
        await scaleService.timer(TimerMode.reset);
      }
    }
    if (state == EspressoMachineState.idle &&
        scaleService.state[0] == ScaleState.disconnected &&
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
      _controllerFrameName.add("");
      _lastFrameNumber = -1;
      if (shotList.saved == false &&
          shotList.entries.isNotEmpty &&
          shotList.saving == false &&
          shotList.saved == false) {
        final weights = await detachWeightListener();
        shotFinished(weights);
      }

      return;
    }
    if (!inShot && state.coffeeState == EspressoMachineState.espresso) {
      log.info('Not Idle and not in Shot');
      inShot = true;
      currentShot = Shot();
      currentShot.targetEspressoWeight = settingsService.targetEspressoWeight;

      _delayedStopActive = false;
      _weightMoveOnFrames = {};
      isPouring = false;
      shotList.clear();
      weightMeasurementsDuringShot.clear();
      baseTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      log.info("basetime $baseTime");
      lastPourTime = 0;
      attachWeightListener();

      Timer.periodic(const Duration(milliseconds: 50), (timer) => checkMoveOnAtWeight(timer));
    }
    if (state.coffeeState == EspressoMachineState.espresso && shot.frameNumber != _lastFrameNumber) {
      if (profileService.currentProfile != null &&
          shot.frameNumber <= profileService.currentProfile!.shotFrames.length) {
        var frame = profileService.currentProfile!.shotFrames[shot.frameNumber];
        _controllerFrameName.add(frame.name);
      }

      _lastFrameNumber = shot.frameNumber;
    }
    if (state.coffeeState == EspressoMachineState.espresso &&
        lastSubstate != state.subState &&
        lastSubstate == "heat_water_heater") {
      log.info('Heating phase over');

      baseTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      if (!settingsService.savePrePouring) {
        shotList.clear();
      } else {
        /// time correct the prePouring data. Let time be 0 with the start of the pour.
        var tAdjust = shotList.entries.last.sampleTimeCorrected;
        for (var element in shotList.entries) {
          element.sampleTimeCorrected -= tAdjust;
        }
      }
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

      if (settingsService.scaleStartTimer) {
        scaleService.timer(TimerMode.start);
      }
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

      shot.weight = scaleService.weight[0];
      shot.flowWeight = scaleService.flow[0];
      shot.sampleTimeCorrected = shot.sampleTime - baseTime;
      if (isPouring) {
        shot.pourTime = shot.sampleTime - pourTimeStart;
        lastPourTime = shot.pourTime;
      }

      switch (state.coffeeState) {
        case EspressoMachineState.espresso:
          if (lastPourTime > 5 && scaleService.state[0] == ScaleState.connected) {
            var weight = settingsService.targetEspressoWeight;
            if (weight < 1) {
              weight = profileService.currentProfile!.shotHeader.targetWeight;
            }

            if (isPouring && settingsService.shotStopOnWeight && weight > 1 && _delayedStopActive == false) {
              var valuesCount = calcWeightReachedEstimation();
              if (valuesCount > 0) {
                var timeToWeight = currentShot.estimatedWeightReachedTime - shot.sampleTimeCorrected;
                // var timeToWeight = (weight - shot.weight) / shot.flowWeight;
                shot.timeToWeight = timeToWeight > 0 && timeToWeight < 100 ? timeToWeight : 0;
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
          if (scaleService.state[0] == ScaleState.connected) {
            if (state.subState == "pour" &&
                settingsService.targetHotWaterWeight > 1 &&
                scaleService.weight[0] + 1 > settingsService.targetHotWaterWeight) {
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

            // triggerEndOfShot(); - not needed the machine automatically ends steaming after the timer ends
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
          // var t = 50;
          // var index = shotList.entries.length - 5;
          // if (index > 0) {
          //   shotList.entries.removeAt(index);
          //   shotList.entries.removeAt(index);
          //   shotList.entries.removeAt(index);
          //   shotList.entries.removeAt(index);
          // }
          // var l = shotList.entries.length;
          shot.isInterpolated = false;

          // shotList.entries.removeWhere(
          //     (element) => (element.isInterpolated == true && (_sampleTime - element.sampleTimeCorrected) > 1.3));
          // shotList.entries.removeWhere((element) => (element.isInterpolated == true));
          // var oldShot = shotList.entries.indexWhere((element) => (element.isInterpolated == true));
          var c = 5;
          var hz = 4;
          var f = 1 / hz * 1000;
          int ms = f ~/ (c + 1);

          // if (oldShot == -1) {
          if (_newestShot != null) {
            // shotList.add(_newestShot!);
            // shotList.add(ShotState.fromJson(shot.toJson()));
            _previousShot = ShotState.fromJson(_newestShot!.toJson());
          }

          _newestShot = ShotState.fromJson(shot.toJson());

          if (_previousShot != null) {
            if (_floatingShot == null) {
              // _floatingShot = ShotState.fromJson(shot!.toJson());
              // shotList.add(_floatingShot!);
            }

            if (_newestShot!.sampleTimeCorrected != _previousShot!.sampleTimeCorrected) {
              linGP = LineEq.calcLinearEquation(_newestShot!.sampleTimeCorrected, _previousShot!.sampleTimeCorrected,
                  _newestShot!.groupPressure, _previousShot!.groupPressure);

              lingpS = LineEq.calcLinearEquation(_newestShot!.sampleTimeCorrected, _previousShot!.sampleTimeCorrected,
                  _newestShot!.setGroupPressure, _previousShot!.setGroupPressure);

              linGF = LineEq.calcLinearEquation(_newestShot!.sampleTimeCorrected, _previousShot!.sampleTimeCorrected,
                  _newestShot!.groupFlow, _previousShot!.groupFlow);

              lingfS = LineEq.calcLinearEquation(_newestShot!.sampleTimeCorrected, _previousShot!.sampleTimeCorrected,
                  _newestShot!.setGroupFlow, _previousShot!.setGroupFlow);

              linWF = LineEq.calcLinearEquation(_newestShot!.sampleTimeCorrected, _previousShot!.sampleTimeCorrected,
                  _newestShot!.flowWeight, _previousShot!.flowWeight);
            } else {
              log.warning("Same Timestamp for interpolations");
              log.warning(
                  "Same Timestamp for interpolations${_newestShot!.groupPressure} ${_newestShot!.setGroupPressure} ${_newestShot!.groupFlow} ${_newestShot!.setGroupFlow} ${_newestShot!.flowWeight}");
            }
            // var newShot = ShotState.fromJson(_previousShot!.toJson());
            // shotList.add(newShot);
            // _floatingShot = ShotState.fromJson(_previousShot!.toJson());
            _floatingShot = ShotState.fromJson(_previousShot!.toJson());
            shotList.add(_floatingShot!);
            // var base = ShotState.fromJson(_previousShot!.toJson());
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
                fs.setGroupPressure = lingpS.getY(fs.sampleTimeCorrected);
                fs.groupFlow = linGF.getY(fs.sampleTimeCorrected);
                fs.setGroupFlow = lingfS.getY(fs.sampleTimeCorrected);
                fs.flowWeight = linWF.getY(fs.sampleTimeCorrected);
                fs.weight = scaleService.weight[0]; //  linW.getY(fs.sampleTimeCorrected);
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
          if (settingsService.recordPrePouring) {
            shotList.lastTouched++;
            shotList.entries.add(shot);
          } else {
            // make a single value for the first few seconds to show some action ongoing
            shotList.lastTouched++;
            if (shotList.entries.isEmpty) {
              shotList.entries.add(shot);
            } else if (shotList.entries.length == 1) {
              shotList.entries[0] = shot;
            }
          }
          notifyListeners();
        }
      }
    }
  }

  void checkMoveOnAtWeight(Timer timer) {
    if (state.coffeeState != EspressoMachineState.espresso ||
        (state.subState != "pour" && state.subState != "pre_infuse" && state.subState != "heat_water_heater")) {
      // we're no longer pulling a shot, so stop checking
      log.info("Stopping weight move-on checks");
      timer.cancel();
      return;
    }

    var shot = state.shot;

    if (shot == null) {
      return;
    }

    if (_weightMoveOnFrames.contains(shot.frameNumber)) {
      return;
    }

    var frame = profileService.currentProfile?.shotFrames[shot.frameNumber];
    var stepWeightLimit = frame?.maxWeight ?? 0.0;

    if ((isPouring || state.subState == "pre_infuse") &&
        stepWeightLimit > 0.0 &&
        flowRateForecast > 0.0 &&
        _delayedStopActive == false) {
      var currentWeight = weightMeasurementsDuringShot.last;
      var forecastWeight = currentWeight.weight.weight +
          flowRateForecast * (DateTime.now().difference(currentWeight.time)).inMilliseconds;
      var timeToWeight = (stepWeightLimit - forecastWeight) / flowRateForecast;

      if (timeToWeight <= (settingsService.stepLimitWeightTimeAdjust * 1000)) {
        _weightMoveOnFrames.add(shot.frameNumber);
        log.info("Frame weight reached now, moving on");
        moveToNextFrame();
      }
    }
  }

  void triggerEndOfShot() {
    log.info("Idle mode initiated because of goal reached");

    if (settingsService.scaleStartTimer) {
      scaleService.timer(TimerMode.stop);
    }
    de1?.requestState(De1StateEnum.idle);
    // Future.delayed(const Duration(milliseconds: 5000), () {
    // log.info("Idle mode initiated finished", error: {DateTime.now()});
    //   stopTriggered = false;
    // });
  }

  void moveToNextFrame() {
    log.info("Skipping to next frame");
    de1?.requestState(De1StateEnum.skipToNext);
  }

  // Attempt Savitzky-Golay filter to derive flow weights from given weight
  // measurements.
  // If there's not enough data, or if the Sav-Gol filter fails, returns null.
  // Otherwise returns a list of length 2.
  // The first element is a list of flow weights in g/s, the second element
  // is the time since eoch for that flow weight value.
  // TODO: check if we can upgrade to Flutter 3 and return a list of records
  Future<List<List<double>>?> calculateFlowWeightsForVisualizer(
      List<TimedWeightMeasurement> weightMeasurements) async {
    if (weightMeasurements.length < 2) {
      return null;
    }

    final weightTimes = weightMeasurements
        .map(
            (measurement) => measurement.time.millisecondsSinceEpoch.toDouble())
        .toList();

    final weightValues = weightMeasurements
        .map((measurement) => measurement.weight.weight)
        .toList();

    // First, interpolate weight measurements so they're equally spaced
    final linearTimestep =
        (weightTimes.last - weightTimes.first) / (weightTimes.length - 1);
    final linearWeightTimes = List.generate(
        weightTimes.length, (i) => weightTimes.first + (linearTimestep * i));
    final linearlyInterpolatedWeights =
        interp(linearWeightTimes, weightTimes, weightValues);

    // Savitzky-Golay filter to get the derivative (relative to index)
    final weightValuesDerivative = savgolFilter(
        values: linearlyInterpolatedWeights,
        windowLength: 17,
        polyOrder: 2,
        derivative: 1);

    if (weightValuesDerivative == null) {
      log.info("Sav-Gol filter failed");
      return null;
    }

    // Then divide by timestep to convert to flow rate
    // (and convert from g/ms to g/s)
    return [weightValuesDerivative
        .map((d) => d / linearTimestep * 1000)
        .toList(), linearWeightTimes];
  }

  shotFinished(List<TimedWeightMeasurement> weightMeasurements) async {
    log.info("Save last shot");
    try {
      var cs = Shot();

      var currentRecipe = coffeeService.currentRecipe!;
      currentRecipe.id = 0;
      currentRecipe.isShot = true;

      cs.recipe.targetId = coffeeService.addRecipeFromRecipe(currentRecipe);
      var currentCoffee = coffeeService.currentCoffee!;
      currentCoffee.id = 0;
      currentCoffee.isShot = true;
      cs.coffee.targetId = await coffeeService.addCoffee(currentCoffee);

      // sometimes shotstates get duplicated, so filter those out
      // TODO: figure out why they're being duplicated
      final Set<double> seenSampleTimes = {};
      cs.shotstates.addAll(
          shotList.entries.where((element) => element.isInterpolated == false));
      cs.shotstates.retainWhere((el) => seenSampleTimes.add(el.sampleTime));

      final sampleTimes =
          cs.shotstates.map((state) => state.sampleTime * 1000).toList();

      final weightTimes = weightMeasurements
          .map((measurement) =>
              measurement.time.millisecondsSinceEpoch.toDouble())
          .toList();

      final weightValues = weightMeasurements
          .map((measurement) => measurement.weight.weight)
          .toList();

      final interpolatedWeights =
          interp(sampleTimes, weightTimes, weightValues);

      final linearFlowWeightsAndTimes =
          await calculateFlowWeightsForVisualizer(weightMeasurements);
      final List<double>? flowWeights;
      if (linearFlowWeightsAndTimes == null) {
        flowWeights = null;
      } else {
        // interpolate back to DE1 sample times
        final linearFlowWeightValues = linearFlowWeightsAndTimes.first;
        final linearFlowWeightTimes = linearFlowWeightsAndTimes[1];
        flowWeights =
            interp(sampleTimes, linearFlowWeightTimes, linearFlowWeightValues);
      }

      // apply weights & flowWeights to 1 decimal place and 2 decimal places
      // respectively
      cs.shotstates.asMap().forEach((index, state) {
        state.weight = (interpolatedWeights[index] * 10).round() / 10;

        // if we failed to get nice smooth flow weights, don't do anything,
        // and the moving sample flowWeight property will be saved instead
        if (flowWeights != null) {
          state.flowWeight = (flowWeights[index] * 100).round() / 100;
        }
      });

      cs.pourTime = lastPourTime;
      cs.profileId = profileService.currentProfile?.id ?? "";
      cs.targetEspressoWeight = settingsService.targetEspressoWeight;
      cs.targetTempCorrection = settingsService.targetTempCorrection;
      cs.doseWeight = coffeeService.currentRecipe?.grinderDoseWeight ?? 0;
      cs.pourWeight = weightMeasurements.last.weight.weight;
      cs.ratio1 = coffeeService.currentRecipe?.ratio1 ?? 1;
      cs.ratio2 = coffeeService.currentRecipe?.ratio2 ?? 1;

      cs.grinderName = coffeeService.currentRecipe?.grinderModel ?? "";
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

  // Linear interpolation
  // xpNew: the new x-coordinates to interpolate values to
  // xp: x-coordinates of the original data
  // fp: y-coordinates of the original data
  List<double> interp(List<double> xpNew, List<double> xp, List<double> fp) {
    if (xp.length != fp.length) {
      throw ArgumentError("Input lists 'xp' and 'fp' must have the same length.");
    }

    List<double> results = [];

    for (int i = 0; i < xpNew.length; i++) {
      double x = xpNew[i];

      double x0;
      double x1;
      double f0;
      double f1;

      if (x <= xp.first) {
        x0 = xp.first;
        x1 = xp[1];
        f0 = fp.first;
        f1 = fp[1];
      } else if (x >= xp.last) {
        x0 = xp[xp.length - 2];
        x1 = xp.last;
        f0 = fp[fp.length - 2];
        f1 = fp.last;
      } else {
        int j = 0;
        while (j < xp.length - 1 && xp[j + 1] < x) {
          j++;
        }

        x0 = xp[j];
        x1 = xp[j + 1];
        f0 = fp[j];
        f1 = fp[j + 1];
      }

      double interpolatedValue = f0 + (f1 - f0) * (x - x0) / (x1 - x0);
      results.add(interpolatedValue);
    }

    return results;
  }

  // Double exponential smoothing over the given data. Data points are assumed
  // to have equal temporal spacing. Returns the values of s, b at each point.
  // TODO: check if we can upgrade to Flutter 3 and return a list of records
  List<List<double>> doubleExponentialSmoothing(
      List<double> input, double dataSmoothingFactor, double trendSmoothingFactor) {
    var s = input[0];
    var b = input[1] - input[0];

    List<List<double>> result = [
      [s, b]
    ];

    input.sublist(1).forEach((x) {
      var s_1 = s;
      var b_1 = b;
      s = x * dataSmoothingFactor + (1 - dataSmoothingFactor) * (s_1 + b_1);
      b = trendSmoothingFactor * (s - s_1) + (1 - trendSmoothingFactor) * b_1;
      result.add([s, b]);
    });

    return result;
  }

  // Get forecast flow rate using double exponential smoothing.
  double getFlowRateForecast(Duration window) {
    var sampleWindowStart = DateTime.now().subtract(window);
    var samples = weightMeasurementsDuringShot
        .where((m) => m.time.isAfter(sampleWindowStart) || m.time.isAtSameMomentAs(sampleWindowStart));

    if (samples.isEmpty) {
      return 0.0;
    }

    if (samples.length == 1) {
      return samples.first.weight.flow;
    }

    var selectedSampleWeights = samples.map((m) => m.weight.weight).toList();
    var selectedSampleTimeEpochs = samples.map((m) => m.time.millisecondsSinceEpoch.toDouble()).toList();

    // this will probably be slightly different than the requested sample window
    var actualSampleWindow = samples.last.time.difference(samples.first.time);

    // get a list of equally spaced sample times between the start and end
    // of the sample window
    // This might be a bad approach depending on the variance in the
    // scale's reporting - investigate better solutions?
    var timestep = actualSampleWindow ~/ (samples.length - 1);

    var interpolatedSampleTimeEpochs =
        List.generate(samples.length, (i) => samples.first.time.add(timestep * i).millisecondsSinceEpoch.toDouble());

    var interpolatedSampleWeights =
        interp(interpolatedSampleTimeEpochs, selectedSampleTimeEpochs, selectedSampleWeights);

    // These values for data smoothing, trend smoothing factors were found by
    // minimizing square error of forecast weights on real shot data
    var smoothed = doubleExponentialSmoothing(interpolatedSampleWeights, 0.6, 0.5);

    // double exponential forecast is given by adding b * m to the last smoothed
    // value, where "m" is a discrete number of time steps.
    // Therefore the gradient is b divided by the time step size
    // (and weight gradient == flow rate)
    var b = smoothed.last[1];
    var gradient = b / timestep.inMilliseconds;

    // multiplying by the ratio of current : previous flow rate slightly
    // improves fit IME, using b alone under-estimates increase/decreases in
    // flow rate
    var b_2 = smoothed[smoothed.length - 2][1];
    var fudgeFactor = b / b_2;
    fudgeFactor = fudgeFactor.isFinite ? fudgeFactor : 1;

    var flow = gradient * fudgeFactor;

    return flow;
  }

  void notify() {
    notifyListeners();
  }

  Future<void> startDescaling() {
    return de1!.requestState(De1StateEnum.descale);
  }

  Future<void> startCleaning() {
    return de1!.requestState(De1StateEnum.clean);
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
    // log.info("lin: $y = ($m * $x + $b");
    return y;
  }
}

import 'dart:async';

import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/cafehub/ch_service.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../../devices/abstract_scale.dart';
import '../../../service_locator.dart';
import 'ble_service.dart';

enum ScaleState {
  /// Currently establishing a connection.
  connecting,

  /// Connection is established.
  connected,

  /// Terminating the connection.
  disconnecting,

  /// Device is disconnected.
  disconnected
}

class WeightMeassurement {
  double flow;
  double weight;
  ScaleState state;
  int index;
  WeightMeassurement(this.weight, this.flow, this.state, this.index);
}

class BatteryLevel {
  int level = 0;
  int index = 0;
  BatteryLevel(this.level, this.index);
}

class ScaleService extends ChangeNotifier {
  final log = Logger('ScaleService');

  List<double> _weight = [0.0, 0.0];
  List<double> _flow = [0.0, 0.0];

  final List<int> _battery = [0, 0];
  DateTime last = DateTime.now();

  ScaleState _state = ScaleState.disconnected;

  bool tareInProgress = false;
  var _count = 0;

  DateTime t1 = DateTime.now();

  SettingsService? _settingsService;

  EspressoMachineService? _machineService;

  bool hasSecondaryScale = false;
  bool hasPrimaryScale = false;

  Stream<WeightMeassurement> get stream => _stream;
  Stream<BatteryLevel> get streamBattery => _streamBattery;

  List<double> get weight => _weight;
  List<double> get flow => _flow;
  List<int> get battery => _battery;

  ScaleState get state => _state;

  late StreamController<WeightMeassurement> _controller;
  late Stream<WeightMeassurement> _stream;

  final List<AbstractScale?> _scale = [null, null];

  late StreamController<BatteryLevel> _controllerBattery;
  late Stream<BatteryLevel> _streamBattery;

  List<List<double>> averaging = [[], []];

  ScaleService() {
    _controller = StreamController<WeightMeassurement>();
    _stream = _controller.stream.asBroadcastStream();

    _controllerBattery = StreamController<BatteryLevel>();
    _streamBattery = _controllerBattery.stream.asBroadcastStream();
  }

  Future<void> tare({int index = 0}) async {
    if (_state == ScaleState.connected) {
      setWeight(0, index);
      tareInProgress = true;
      await _scale[index]?.writeTare();
      Future.delayed(const Duration(milliseconds: 500), () {
        tareInProgress = false;
        setWeight(0, index);
      });
    }
  }

  Future<void> timer(TimerMode startMode, {int index = 0}) async {
    if (_state == ScaleState.connected) {
      try {
        await _scale[index]?.timer(startMode);
      } catch (e) {
        log.info("Timer not implemented $e");
      }
    }
  }

  Future<void> display(DisplayMode mode, {int index = 0}) async {
    if (_state == ScaleState.connected) {
      try {
        await _scale[index]?.display(mode);
      } catch (e) {
        log.info("Display not implemented $e");
      }
    }
  }

  Future<void> power(PowerMode mode, {int index = 0}) async {
    if (_state == ScaleState.connected) {
      try {
        await _scale[index]?.power(mode);
      } catch (e) {
        log.info("Power not implemented $e");
      }
    }
  }

  Future<void> beep({int index = 0}) async {
    if (_state == ScaleState.connected) {
      try {
        await _scale[index]?.beep();
      } catch (e) {
        log.info("Beep not implemented $e");
      }
    }
  }

  void setTara() {
    log.info("Tara done");
    averaging.clear();
  }

  void setWeight(double weight, index) {
    if (tareInProgress) return;

    var now = DateTime.now();
    var flow = 0.0;
    var timeDiff = (now.millisecondsSinceEpoch - last.millisecondsSinceEpoch);

    // calc flow, cap on 10g/s
    if (timeDiff == 0) return;
    var n = math.min(10.0, (weight - _weight[index]).abs() / (timeDiff / 1000));

    averaging[index].add(n);

    flow = averaging[index].average;

    if (averaging.length > 10) {
      averaging.removeAt(0);
    }
    _weight[index] = weight;
    _flow[index] = flow;
    last = now;
    _controller.add(WeightMeassurement(weight, flow, _state, index));
    notifyListeners();

    _count++;
    if (_count % 100 == 0) {
      var t = DateTime.now();
      var ms = t.difference(t1).inMilliseconds;
      var hz = 100 / ms * 1000.0;
      if (_count & 50 == 0) log.info("Weight Hz: $ms $hz");
      t1 = t;
    }

    if (_settingsService != null &&
        _machineService != null &&
        _settingsService!.tareOnDetectedWeight &&
        (_machineService?.state.coffeeState == EspressoMachineState.idle ||
            _machineService?.state.coffeeState == EspressoMachineState.sleep)) {
      var wl = [
        _settingsService?.tareOnWeight1,
        _settingsService?.tareOnWeight2,
        _settingsService?.tareOnWeight3,
        _settingsService?.tareOnWeight4
      ];
      for (var w in wl) {
        if (_weight[index] + 0.1 > w! && _weight[index] - 0.1 < w && w > 1) {
          tare();
        }
      }
    }
  }

  void setScaleInstance(AbstractScale abstractScale, int index) {
    if (_scale[index] == null) {
      _scale[index] = abstractScale;
      log.info("Set instance $index");
      if (index == 0) {
        hasPrimaryScale = true;
      }
      if (index == 1) {
        hasSecondaryScale = true;
      }
    }
    _settingsService = getIt<SettingsService>();
    _machineService = getIt<EspressoMachineService>();
  }

  void setState(ScaleState state, int index) {
    _state = state;
    if (index == -1) return;
    if (state == ScaleState.disconnected) {
      _scale[index] = null;
      if (index == 0) hasPrimaryScale = false;
      if (index == 1) hasSecondaryScale = false;
    }
    log.info('Scale State: $_state');
    _controller.add(WeightMeassurement(_weight[index], _flow[index], _state, index));
  }

  void connect() {
    var settings = getIt<SettingsService>();
    if (settings.useCafeHub) {
      var bleService = getIt<CHService>();
      bleService.startScan();
    } else {
      var bleService = getIt<BLEService>();
      bleService.startScan();
    }
  }

  void setBattery(int batteryLevel, int index) {
    if (batteryLevel == _battery[index]) return;
    _battery[index] = batteryLevel;
    _controllerBattery.add(BatteryLevel(batteryLevel, index));
  }
}

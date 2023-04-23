import 'dart:async';

import 'dart:math' as math;
import 'package:collection/collection.dart';
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
  WeightMeassurement(this.weight, this.flow, this.state);
}

class ScaleService extends ChangeNotifier {
  final log = Logger('ScaleService');

  double _weight = 0.0;
  double _flow = 0.0;
  int _battery = 0;
  DateTime last = DateTime.now();

  ScaleState _state = ScaleState.disconnected;

  bool tareInProgress = false;
  var _count = 0;

  DateTime t1 = DateTime.now();

  Stream<WeightMeassurement> get stream => _stream;
  Stream<int> get streamBattery => _streamBattery;

  double get weight => _weight;
  double get flow => _flow;
  int get battery => _battery;

  ScaleState get state => _state;

  late StreamController<WeightMeassurement> _controller;
  late Stream<WeightMeassurement> _stream;

  AbstractScale? scale;

  late StreamController<int> _controllerBattery;
  late Stream<int> _streamBattery;

  List<double> averaging = [];

  ScaleService() {
    _controller = StreamController<WeightMeassurement>();
    _stream = _controller.stream.asBroadcastStream();

    _controllerBattery = StreamController<int>();
    _streamBattery = _controllerBattery.stream.asBroadcastStream();
  }

  Future<void> tare() async {
    if (_state == ScaleState.connected) {
      setWeight(0);
      tareInProgress = true;
      await scale?.writeTare();
      Future.delayed(const Duration(milliseconds: 500), () {
        tareInProgress = false;
        setWeight(0);
      });
    }
  }

  void setTara() {
    log.info("Tara done");
    averaging.clear();
  }

  void setWeight(double weight) {
    if (tareInProgress) return;

    var now = DateTime.now();
    var flow = 0.0;
    var timeDiff = (now.millisecondsSinceEpoch - last.millisecondsSinceEpoch);

    // calc flow, cap on 10g/s
    if (timeDiff == 0) return;
    var n = math.min(10.0, (weight - _weight).abs() / (timeDiff / 1000));

    averaging.add(n);

    flow = averaging.average;

    if (averaging.length > 10) {
      averaging.removeAt(0);
    }
    _weight = weight;
    _flow = flow;
    last = now;
    _controller.add(WeightMeassurement(weight, flow, _state));
    notifyListeners();

    _count++;
    if (_count % 100 == 0) {
      var t = DateTime.now();
      var ms = t.difference(t1).inMilliseconds;
      var hz = 100 / ms * 1000.0;
      if (_count & 50 == 0) log.info("Weight Hz: $ms $hz");
      t1 = t;
    }
  }

  void setScaleInstance(AbstractScale abstractScale) {
    scale = abstractScale;
  }

  void setState(ScaleState state) {
    _state = state;
    if (state == ScaleState.disconnected) {
      // scale = null;
    }
    log.info('Scale State: $_state');
    _controller.add(WeightMeassurement(_weight, _flow, _state));
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

  void setBattery(int batteryLevel) {
    if (batteryLevel == _battery) return;
    _battery = batteryLevel;
    _controllerBattery.add(_battery);
  }
}

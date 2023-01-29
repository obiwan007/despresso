import 'dart:async';
import 'dart:developer';

import 'package:despresso/devices/acaia_scale.dart';
import 'package:flutter/material.dart';

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
  double _weight = 0.0;
  double _flow = 0.0;
  int _battery = 0;
  DateTime last = DateTime.now();

  ScaleState _state = ScaleState.disconnected;

  bool tareInProgress = false;

  double lastFlow = 1;

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

  late StreamController<int> _controllerBattery;
  late Stream<int> _streamBattery;

  AcaiaScale? scale;

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

  void setWeight(double weight) {
    const T = 1.7;
    const U = 1.5;
    if (tareInProgress) return;
    // log('Weight: ' + weight.toString());
    var now = DateTime.now();
    var flow = 0.0;
    var timeDiff = (now.millisecondsSinceEpoch - last.millisecondsSinceEpoch) / 1000;
    // log(_flow.toStringAsFixed(2));
    var n = ((weight - _weight).abs() / timeDiff);
    flow = (n - lastFlow) * (2 * T - U) / (2 * T + U) + lastFlow;
    lastFlow = flow;

    _weight = weight;
    _flow = flow;
    last = now;
    _controller.add(WeightMeassurement(weight, flow, _state));

    notifyListeners();

    _count++;
    if (_count % 10 == 0) {
      var t = DateTime.now();
      var ms = t.difference(t1).inMilliseconds;
      var hz = 10 / ms * 1000.0;
      if (_count & 50 == 0) log("Weight Hz: $ms $hz");
      t1 = t;
    }
  }

  void setScaleInstance(AcaiaScale acaiaScale) {
    scale = acaiaScale;
  }

  void setState(ScaleState state) {
    _state = state;
    log('Scale State: $_state');
    _controller.add(WeightMeassurement(_weight, _flow, _state));
  }

  void connect() {
    var bleService = getIt<BLEService>();
    bleService.startScan();
  }

  void setBattery(int batteryLevel) {
    if (batteryLevel == _battery) return;
    _battery = batteryLevel;
    _controllerBattery.add(_battery);
  }
}

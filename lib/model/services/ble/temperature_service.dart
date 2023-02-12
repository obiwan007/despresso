import 'dart:async';

import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:despresso/devices/abstract_thermometer.dart';
import 'package:despresso/devices/acaia_scale.dart';
import 'package:despresso/logger_util.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../../devices/abstract_scale.dart';
import '../../../service_locator.dart';
import 'ble_service.dart';

enum TempState {
  /// Currently establishing a connection.
  connecting,

  /// Connection is established.
  connected,

  /// Terminating the connection.
  disconnecting,

  /// Device is disconnected.
  disconnected
}

class TempMeassurement {
  double temp1;
  double temp2;
  TempState state;
  double time = 0;
  TempMeassurement(this.temp1, this.temp2, this.state);
}

class TempService extends ChangeNotifier {
  final log = Logger('TempService');

  double _temp1 = 0.0;
  double _temp2 = 0.0;
  int _battery = 0;
  DateTime last = DateTime.now();

  TempState _state = TempState.disconnected;

  bool tareInProgress = false;
  var _count = 0;

  DateTime t1 = DateTime.now();

  double _baseTime = 0;

  Stream<TempMeassurement> get stream => _stream;
  Stream<int> get streamBattery => _streamBattery;

  double get temp1 => _temp1;
  double get temp2 => _temp2;
  int get battery => _battery;

  TempState get state => _state;

  late StreamController<TempMeassurement> _controller;
  late Stream<TempMeassurement> _stream;

  AbstractThermometer? tempProbe;

  late StreamController<int> _controllerBattery;
  late Stream<int> _streamBattery;

  List<TempMeassurement> history = [];

  TempService() {
    _controller = StreamController<TempMeassurement>();
    _stream = _controller.stream.asBroadcastStream();

    _controllerBattery = StreamController<int>();
    _streamBattery = _controllerBattery.stream.asBroadcastStream();
  }

  void setTemp(double temp1, double temp2) {
    _temp1 = temp1;
    _temp2 = temp2;

    // calc flow, cap on 10g/s
    var m = TempMeassurement(temp1, temp2, _state);
    m.time = DateTime.now().millisecondsSinceEpoch / 1000.0 - _baseTime;
    history.add(m);
    if (history.length > 200) {
      history.removeAt(0);
    }
    _controller.add(m);
    notifyListeners();

    _count++;
    if (_count % 10 == 0) {
      var t = DateTime.now();
      var ms = t.difference(t1).inMilliseconds;
      var hz = 10 / ms * 1000.0;
      log.finer("Temp Hz: $ms $hz");
      t1 = t;
    }
  }

  void setState(TempState state) {
    if (state == TempState.connected) {
      _baseTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      resetHistory();
    } else if (state == TempState.disconnected) {
      resetHistory();
      setBattery(0);
    }
    _state = state;
    log.info('Scale State: $_state');
    _controller.add(TempMeassurement(_temp1, _temp2, _state));
    notifyListeners();
  }

  void connect() {
    var bleService = getIt<BLEService>();
    bleService.startScan();
  }

  void setBattery(int batteryLevel) {
    if (batteryLevel == _battery) return;
    _battery = batteryLevel;
    _controllerBattery.add(_battery);
    log.fine("Meater battery $_battery");
  }

  resetHistory() {
    history.clear();
    _baseTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
  }
}

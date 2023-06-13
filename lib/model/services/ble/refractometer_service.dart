import 'dart:async';
import 'package:despresso/devices/abstract_refractometer.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../../../service_locator.dart';
import 'ble_service.dart';

enum RefractometerState {
  /// Currently establishing a connection.
  connecting,

  /// Connection is established.
  connected,

  /// Terminating the connection.
  disconnecting,

  /// Device is disconnected.
  disconnected
}

class TdsMeassurement {
  double tds;
  double refrIndex;
  double tempPrism;
  double tempTank;
  RefractometerState state;
  TdsMeassurement(this.tds, this.refrIndex, this.tempPrism, this.tempTank, this.state);
}

class RefractometerService extends ChangeNotifier {
  final log = Logger('TRefractometerService');

  double _tds = 0.0;
  double _refrIndex = 0.0;
  double _tempPrism = 0.0;
  double _tempTank = 0.0;
  int _battery = 0;
  DateTime last = DateTime.now();

  RefractometerState _state = RefractometerState.disconnected;

  DateTime t1 = DateTime.now();

  Stream<TdsMeassurement> get stream => _stream;
  Stream<int> get streamBattery => _streamBattery;

  double get tds => _tds;
  double get refrIndex => _refrIndex;
  double get tempPrism => _tempPrism;
  double get tempTank => _tempTank;
  int get battery => _battery;

  RefractometerState get state => _state;

  late StreamController<TdsMeassurement> _controller;
  late Stream<TdsMeassurement> _stream;

  AbstractRefractometer? refractometer;

  // SettingsService? _settingsService;

  // EspressoMachineService? _machineService;
  late StreamController<int> _controllerBattery;
  late Stream<int> _streamBattery;

  RefractometerService() {
    _controller = StreamController<TdsMeassurement>();
    _stream = _controller.stream.asBroadcastStream();

    _controllerBattery = StreamController<int>();
    _streamBattery = _controllerBattery.stream.asBroadcastStream();
  }

  void setRefractometerInstance(AbstractRefractometer abstractRefractometer) {
    refractometer = abstractRefractometer;
    // _settingsService = getIt<SettingsService>();
    // _machineService = getIt<EspressoMachineService>();
  }

  setState(RefractometerState state) {
    if (state == RefractometerState.connected) {
    } else if (state == RefractometerState.disconnected) {
      setBattery(0);
    }
    _state = state;
    log.info('Refractometer State: $_state');
    _controller.add(TdsMeassurement(_tds, _refrIndex, _tempPrism, _tempTank, _state));
    notifyListeners();
  }

  void setTemp(double tempPrism, double tempTank) {
    _tempPrism = tempPrism;
    _tempTank = tempTank;

    // calc flow, cap on 10g/s
    // var m = TdsMeassurement(temp1, temp2, _state);
    // m.time = DateTime.now().millisecondsSinceEpoch / 1000.0 - _baseTime;
    // history.add(m);
    // if (history.length > 200) {
    //   history.removeAt(0);
    // }
    // _controller.add(m);
    // notifyListeners();

    //   _count++;
    //   if (_count % 10 == 0) {
    //     var t = DateTime.now();
    //     var ms = t.difference(t1).inMilliseconds;
    //     var hz = 10 / ms * 1000.0;
    //     log.finer("Temp Hz: $ms $hz");
    //     t1 = t;
    //   }
  }

  void setRefraction(double tds, double refrIndex) {
    _tds = tds;
    _refrIndex = refrIndex;
  }

  Future<void> read() async {
    if (_state == RefractometerState.connected) {
      try {
        await refractometer?.requestValue();
      } catch (e) {
        log.info("Beep not implemented $e");
      }
    }
  }

  void connect() {
    var bleService = getIt<BLEService>();
    bleService.startScan();
  }

  void setBattery(int batteryLevel) {
    if (batteryLevel == _battery) return;
    _battery = batteryLevel;
    _controllerBattery.add(_battery);
    log.fine("Refractometer battery $_battery");
  }
}

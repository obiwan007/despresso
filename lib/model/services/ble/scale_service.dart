import 'dart:async';
import 'dart:developer';

import 'package:despresso/devices/acaia_scale.dart';
import 'package:reactive_ble_platform_interface/src/model/connection_state_update.dart';

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

class ScaleService {
  double _weight = 0.0;
  double _flow = 0.0;
  DateTime last = DateTime.now();

  ScaleState _state = ScaleState.disconnected;

  Stream<WeightMeassurement> get stream => _stream;

  double get weight => _weight;
  double get flow => _flow;

  ScaleState get state => _state;

  late StreamController<WeightMeassurement> _controller;
  late Stream<WeightMeassurement> _stream;

  AcaiaScale? scale;

  ScaleService() {
    _controller = StreamController<WeightMeassurement>();
    _stream = _controller.stream.asBroadcastStream();
  }

  void tare() {
    scale?.writeTare();
  }

  void setWeight(double weight) {
    // log('Weight: ' + weight.toString());
    var now = DateTime.now();
    var flow = 0.0;
    if (last != null) {
      var timeDiff = (now.millisecondsSinceEpoch - last.millisecondsSinceEpoch) / 1000;
      // log(timeDiff.toStringAsFixed(2));
      flow = (weight - _weight) / timeDiff;
    }

    _controller.add(WeightMeassurement(weight, flow, _state));
    _weight = weight;
    _flow = flow;
    last = now;
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
}

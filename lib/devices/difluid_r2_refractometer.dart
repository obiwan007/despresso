import 'dart:async';

import 'package:despresso/devices/abstract_comm.dart';
import 'package:despresso/devices/abstract_refractometer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:logging/logging.dart' as l;

import '../model/services/ble/refractometer_service.dart';

class DifluidR2Refractometer extends ChangeNotifier implements AbstractRefractometer {
  final log = l.Logger('DifluidR2Refractometer');
  // ignore: non_constant_identifier_names
  static Uuid ServiceUUID = useLongCharacteristics() ? Uuid.parse('x') : Uuid.parse('x');
// ignore: non_constant_identifier_names
  static Uuid ReadCharacteristicUUID = useLongCharacteristics() ? Uuid.parse('x') : Uuid.parse('x');
// ignore: non_constant_identifier_names
  static Uuid WriteCharacteristicUUID = useLongCharacteristics() ? Uuid.parse('x') : Uuid.parse('x');

  late RefractometerService refractometerService;

  final DiscoveredDevice device;

  final flutterReactiveBle = FlutterReactiveBle();

  late StreamSubscription<ConnectionStateUpdate> _deviceListener;

  late StreamSubscription<List<int>> _characteristicsSubscription;

  DeviceCommunication connection;
  DifluidR2Refractometer(this.device, this.connection) {}
  @override
  Future<void> requestValue() {
    // TODO: implement requestValue
    throw UnimplementedError();
  }

  void _notificationCallback(List<int> data) {}

  void _onStateChange(DeviceConnectionState state) async {
    log.info('REFRACTOMETER State changed to $state');

    switch (state) {
      case DeviceConnectionState.connecting:
        log.info('Connecting');
        refractometerService.setState(RefractometerState.connecting);
        break;

      case DeviceConnectionState.connected:
        log.info('Connected');
        refractometerService.setState(RefractometerState.connected);

        final characteristic = QualifiedCharacteristic(
            serviceId: ServiceUUID, characteristicId: ReadCharacteristicUUID, deviceId: device.id);

        _characteristicsSubscription = flutterReactiveBle.subscribeToCharacteristic(characteristic).listen((data) {
          _notificationCallback(data);
        }, onError: (dynamic error) {
          log.severe("Subscribe to $characteristic failed: $error");
        });

        return;
      case DeviceConnectionState.disconnected:
        refractometerService.setState(RefractometerState.disconnected);
        refractometerService.setBattery(0);
        log.info('Difluid R2 Refractometer disconnected. Destroying');
        _characteristicsSubscription.cancel();

        _deviceListener.cancel();
        notifyListeners();
        return;
      default:
        return;
    }
  }
}

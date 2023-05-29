import 'dart:async';

import 'package:despresso/devices/abstract_comm.dart';
import 'package:despresso/devices/abstract_refractometer.dart';
import 'package:flutter/cupertino.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:logging/logging.dart' as l;

import '../model/services/ble/refractometer_service.dart';

class DifluidR2Refractometer extends ChangeNotifier implements AbstractRefractometer {
  final log = l.Logger('DifluidR2Refractometer');
  // ignore: non_constant_identifier_names
  static Uuid ServiceUUID =
      useLongCharacteristics() ? Uuid.parse('000000ff-0000-1000-8000-00805f9b34fb') : Uuid.parse('00ff');
// ignore: non_constant_identifier_names
  static Uuid CharacteristicUUID =
      useLongCharacteristics() ? Uuid.parse('0000aa01-0000-1000-8000-00805f9b34fb') : Uuid.parse('aa01');

  late RefractometerService refractometerService;

  final DiscoveredDevice device;

  final flutterReactiveBle = FlutterReactiveBle();

  late StreamSubscription<ConnectionStateUpdate> _deviceListener;

  late StreamSubscription<List<int>> _characteristicsSubscription;

  DeviceCommunication connection;
  DifluidR2Refractometer(this.device, this.connection) {
    refractometerService = getIt<RefractometerService>();
    refractometerService.setRefractometerInstance(this);
    _deviceListener = connection.connectToDevice(id: device.id).listen((connectionState) {
      _onStateChange(connectionState.connectionState);
    }, onError: (Object error) {
      // Handle a possible error
    });
  }
  @override
  Future<void> requestValue() {
    // TODO: implement requestValue
    throw UnimplementedError();
  }

  void _notificationCallback(List<int> data) {
    log.info(data);
  }

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

        final characteristic =
            QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: CharacteristicUUID, deviceId: device.id);

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

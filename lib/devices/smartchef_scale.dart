import 'dart:async';
import 'dart:convert';
import 'package:despresso/devices/abstract_comm.dart';
import 'dart:typed_data';

import 'package:despresso/devices/abstract_scale.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'package:logging/logging.dart' as l;

class SmartchefScale extends ChangeNotifier implements AbstractScale {
  final log = l.Logger('SmartchefScale');

  // ignore: non_constant_identifier_names
  static Uuid ServiceUUID =
      useLongCharacteristics() ? Uuid.parse('0000fff0-0000-1000-8000-00805f9b34fb') : Uuid.parse('fff0');
  // ignore: non_constant_identifier_names
  static Uuid DataUUID =
      useLongCharacteristics() ? Uuid.parse('0000fff1-0000-1000-8000-00805f9b34fb') : Uuid.parse('fff1');

  late ScaleService scaleService;

  static const int cmdTare = 0;

  final DiscoveredDevice device;

  List<int> commandBuffer = [];
  double initialWeight = 0.00; // this is a workaround for the missing taring function

  late StreamSubscription<ConnectionStateUpdate> _deviceListener;

  late StreamSubscription<List<int>> _characteristicsSubscription;
  DeviceCommunication connection;
  SmartchefScale(this.device, this.connection) {
    scaleService = getIt<ScaleService>();
    scaleService.setScaleInstance(this);
    _deviceListener = connection.connectToDevice(id: device.id).listen((connectionState) {
      _onStateChange(connectionState.connectionState);
    }, onError: (Object error) {
      // Handle a possible error
    });
  }

  void _notificationCallback(List<int> data) {
    var weight = (data[5] * 256 + data[6]) / 10;
    // weight = weight - initialWeight; -> set on shot start
    // set weight negative on condition?

    scaleService.setWeight(weight);
  }

  @override
  writeTare() {
    // return writeToSmartchef([cmdTare]);
    return Future(() => null); // the smartchef scale doesn't seem to support ble taring
  }

  Future<void> writeToSmartchef(List<int> payload) async {
    log.info("Sending to Smartchef");
    final characteristic =
        QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: DataUUID, deviceId: device.id);
    return await connection.writeCharacteristicWithResponse(characteristic, value: Uint8List.fromList(payload));
  }

  void _onStateChange(DeviceConnectionState state) async {
    log.info('SCALE State changed to $state');

    switch (state) {
      case DeviceConnectionState.connecting:
        log.info('Connecting');
        scaleService.setState(ScaleState.connecting);
        break;

      case DeviceConnectionState.connected:
        log.info('Connected');
        scaleService.setState(ScaleState.connected);
        // await device.discoverAllServicesAndCharacteristics();
        final characteristic =
            QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: DataUUID, deviceId: device.id);

        _characteristicsSubscription = connection.subscribeToCharacteristic(characteristic).listen((data) {
          _notificationCallback(data);
        }, onError: (dynamic error) {
          log.severe("Subscribe to $characteristic failed: $error");
        });

        return;
      case DeviceConnectionState.disconnected:
        scaleService.setState(ScaleState.disconnected);
        scaleService.setBattery(0);
        log.info('Smartchef Scale disconnected. Destroying');
        // await device.disconnectOrCancelConnection();
        _characteristicsSubscription.cancel();

        _deviceListener.cancel();
        notifyListeners();
        return;
      default:
        return;
    }
  }
}
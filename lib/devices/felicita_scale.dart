import 'dart:async';
import 'dart:io' show Platform;
import 'package:collection/collection.dart';
import 'package:despresso/devices/abstract_comm.dart';
import 'dart:typed_data';

import 'package:despresso/devices/abstract_scale.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'package:logging/logging.dart' as l;

class FelicitaScale extends ChangeNotifier implements AbstractScale {
  final log = l.Logger('FelicitaScale');

  // ignore: non_constant_identifier_names
  static Uuid ServiceUUID =
      useLongCharacteristics() ? Uuid.parse('0000ffe0-0000-1000-8000-00805f9b34fb') : Uuid.parse('ffe0');
  // ignore: non_constant_identifier_names
  static Uuid DataUUID =
      useLongCharacteristics() ? Uuid.parse('0000ffe1-0000-1000-8000-00805f9b34fb') : Uuid.parse('ffe1');

  late ScaleService scaleService;

  static const int minBattLevel = 129;
  static const int maxBattLevel = 158;

  static const int cmdStartTimer = 0x52;
  static const int cmdStopTimer = 0x53;
  static const int cmdResetTimer = 0x43;
  static const int cmdToggleTimer = 0x42;
  static const int cmdTogglePrecision = 0x44;
  static const int cmdTare = 0x54;
  static const int cmdToggleUnit = 0x55;

  final DiscoveredDevice device;

  List<int> commandBuffer = [];

  late StreamSubscription<ConnectionStateUpdate> _deviceListener;

  late StreamSubscription<List<int>> _characteristicsSubscription;
  DeviceCommunication connection;
  FelicitaScale(this.device, this.connection) {
    scaleService = getIt<ScaleService>();
    scaleService.setScaleInstance(this);
    _deviceListener = connection.connectToDevice(id: device.id).listen((connectionState) {
      _onStateChange(connectionState.connectionState);
    }, onError: (Object error) {
      // Handle a possible error
    });
  }

  void _notificationCallback(List<int> data) {
    if (data.length == 18) {
      var weight = int.parse(data.slice(3, 9).map((value) => value - 48).join(''));
      scaleService.setWeight(weight / 100);
      scaleService.setBattery(((data[15] - minBattLevel) / (maxBattLevel - minBattLevel) * 100).round());
    }
  }

  @override
  writeTare() {
    return writeToFelicita([cmdTare]);
  }

  Future<void> startTimer() {
    return writeToFelicita([cmdStartTimer]);
  }

  Future<void> stopTimer() {
    return writeToFelicita([cmdStopTimer]);
  }

  Future<void> resetTimer() {
    return writeToFelicita([cmdResetTimer]);
  }

  Future<void> writeToFelicita(List<int> payload) async {
    log.info("Sending to Felicita");
    final characteristic =
        QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: DataUUID, deviceId: device.id);
    return await connection.writeCharacteristicWithoutResponse(characteristic, value: Uint8List.fromList(payload));
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
        log.info('Felicita Scale disconnected. Destroying');
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

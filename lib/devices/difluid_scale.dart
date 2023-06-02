import 'dart:async';
import 'package:collection/collection.dart';
import 'package:despresso/devices/abstract_comm.dart';
import 'dart:typed_data';

import 'package:despresso/devices/abstract_scale.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/cupertino.dart';
import 'package:convert/convert.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'package:logging/logging.dart' as l;

class DifluidScale extends ChangeNotifier implements AbstractScale {
  final log = l.Logger('DifluidScale');

  // ignore: non_constant_identifier_names
  static Uuid ServiceUUID =
      useLongCharacteristics() ? Uuid.parse('000000ee-0000-1000-8000-00805f9b34fb') : Uuid.parse('00ee');
  // ignore: non_constant_identifier_names
  static Uuid DataUUID =
      useLongCharacteristics() ? Uuid.parse('0000aa01-0000-1000-8000-00805f9b34fb') : Uuid.parse('ff01');

  late ScaleService scaleService;

  final DiscoveredDevice device;

  List<int> commandBuffer = [];

  late StreamSubscription<ConnectionStateUpdate> _deviceListener;

  late StreamSubscription<List<int>> _characteristicsSubscription;
  DeviceCommunication connection;
  DifluidScale(this.device, this.connection) {
    scaleService = getIt<ScaleService>();
    scaleService.setScaleInstance(this);
    _deviceListener = connection.connectToDevice(id: device.id).listen((connectionState) {
      _onStateChange(connectionState.connectionState);
    }, onError: (Object error) {
      // Handle a possible error
    });
  }

  void _notificationCallback(List<int> data) {
    log.info(int.parse(hex.encode(data.slice(6, 9)), radix: 16) / 10);
    // log.info(int.parse(data.slice(5, 8) as String, radix: 16) / 10);
    if (data[17] != 0) {
      setScaleUnitToGram();
      log.info('change scale to grams!');
    }

    if (data[0] == 223) {
      var weight = int.parse(hex.encode(data.slice(6, 9)), radix: 16);
      if (weight > 2500) {
        weight =
            int.parse(hex.encode(data.slice(6, 9).map((element) => element.toSigned(8)).join()) as String, radix: 16);
      }
      scaleService.setWeight(weight / 10);
    } else {
      log.info('not a weight update');
    }
  }

  @override
  writeTare() {
    var payload = [0xDF, 0xDF, 0x03, 0x02, 0x01, 0x01, 0XC5];
    // payload.add(calculateChecksum(payload));
    // this is equal to a single power button click
    return writeToDifluidScale(payload);
  }

  // calculateChecksum(data) {
  //   // according to difluid example app
  //   var checksum = 0;
  //   for (var i = 0; i < data.length; i++) {
  //     checksum += int.parse(data[i] & 0xFF);
  //   }
  //   return (checksum & 0xFF).toString().toUpperCase().padLeft(2, '0');
  // }

  startWeightNotifications() {
    log.info('enabling weight notifications');
    return writeToDifluidScale([0xDF, 0xDF, 0x01, 0x00, 0x01, 0x01, 0xC1]);
  }

  setScaleUnitToGram() {
    return writeToDifluidScale([0xDF, 0xDF, 0x01, 0x04, 0x01, 0x00, 0xC4]);
  }

  Future<void> startTimer() {
    return writeToDifluidScale([0xDF, 0xDF, 0x03, 0x02, 0x01, 0x00, 0xC4]);
  }

  Future<void> stopTimer() {
    return writeToDifluidScale([0xDF, 0xDF, 0x03, 0x01, 0x01, 0x00, 0xC3]);
  }

  Future<void> resetTimer() {
    return writeToDifluidScale([0xDF, 0xDF, 0x03, 0x02, 0x01, 0x00, 0xC4]);
  }

  Future<void> writeToDifluidScale(List<int> payload) async {
    log.info("Sending to Difluid Scale");
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
        startWeightNotifications();
        setScaleUnitToGram();
        return;
      case DeviceConnectionState.disconnected:
        scaleService.setState(ScaleState.disconnected);
        scaleService.setBattery(0);
        log.info('Difluid Scale disconnected. Destroying');
        // await device.disconnectOrCancelConnection();
        _characteristicsSubscription.cancel();

        _deviceListener.cancel();
        notifyListeners();
        return;
      default:
        return;
    }
  }

  @override
  Future<void> timer(TimerMode start) async {
    try {
      switch (start) {
        case TimerMode.reset:
          await resetTimer();
          break;
        case TimerMode.start:
          await resetTimer();
          await startTimer();
          break;
        case TimerMode.stop:
          await stopTimer();
          break;
      }
    } catch (e) {
      log.severe("timer failed $e");
    }
  }

  @override
  Future<void> beep() {
    // TODO: implement beep
    throw UnimplementedError();
  }

  @override
  Future<void> display(DisplayMode start) {
    // TODO: implement display
    throw UnimplementedError();
  }

  @override
  Future<void> power(PowerMode start) {
    // TODO: implement power
    throw UnimplementedError();
  }
}

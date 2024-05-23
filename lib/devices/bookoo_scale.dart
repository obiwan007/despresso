import 'dart:async';
import 'package:collection/collection.dart';
import 'package:despresso/devices/abstract_comm.dart';
import 'dart:typed_data';

import 'package:despresso/devices/abstract_scale.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'package:logging/logging.dart' as l;

class BookooScale extends ChangeNotifier implements AbstractScale {
  final log = l.Logger('BookooScale');

  // ignore: non_constant_identifier_names
  static Uuid ServiceUUID = useLongCharacteristics() ? Uuid.parse('00000ffe-0000-1000-8000-00805f9b34fb') : Uuid.parse('0ffe');
  // ignore: non_constant_identifier_names
  static Uuid DataUUID = useLongCharacteristics() ? Uuid.parse('0000ff11-0000-1000-8000-00805f9b34fb') : Uuid.parse('ff11');
  // ignore: non_constant_identifier_names
  static Uuid CmdUUID = useLongCharacteristics() ? Uuid.parse('0000ff12-0000-1000-8000-00805f9b34fb') : Uuid.parse('ff12');

  late ScaleService scaleService;

  final DiscoveredDevice device;

  List<int> commandBuffer = [];

  late StreamSubscription<ConnectionStateUpdate> _deviceListener;

  late StreamSubscription<List<int>> _characteristicsSubscription;
  DeviceCommunication connection;

  int index = 0;
  BookooScale(this.device, this.connection) {
    scaleService = getIt<ScaleService>();
    index = getScaleIndex(device.id);
    scaleService.setScaleInstance(this, index);
    _deviceListener = connection.connectToDevice(id: device.id).listen((connectionState) {
      _onStateChange(connectionState.connectionState);
    }, onError: (Object error) {
      // Handle a possible error
    });
  }

  void _notificationCallback(List<int> data) {
    if (data.length == 20) {
      var weight = (data[7] << 16) + (data[8] << 8) + data[9];
      if (data[6] == 45) {
        weight = weight * -1;
      }
      scaleService.setWeight(weight / 100, index);
      scaleService.setBattery(data[13], index);
    }
  }

  @override
  writeTare() {
    return writeToBokooScale([0x03, 0x0A, 0x01, 0x00, 0x00, 0x08]);
  }

  Future<void> startTimer() {
    return writeToBokooScale([0x03, 0x0A, 0x04, 0x00, 0x00, 0x0A]);
  }

  Future<void> stopTimer() {
    return writeToBokooScale([0x03, 0x0A, 0x05, 0x00, 0x00, 0x0D]);
  }

  Future<void> resetTimer() {
    return writeToBokooScale([0x03, 0x0A, 0x06, 0x00, 0x00, 0x0C]);
  }

  Future<void> writeToBokooScale(List<int> payload) async {
    log.info("Sending to Bookoo Scale");
    final characteristic = QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: CmdUUID, deviceId: device.id);
    return await connection.writeCharacteristicWithoutResponse(characteristic, value: Uint8List.fromList(payload));
  }

  void _onStateChange(DeviceConnectionState state) async {
    log.info('SCALE State changed to $state');

    switch (state) {
      case DeviceConnectionState.connecting:
        log.info('Connecting');
        scaleService.setState(ScaleState.connecting, index);
        break;

      case DeviceConnectionState.connected:
        log.info('Connected');
        scaleService.setState(ScaleState.connected, index);
        // await device.discoverAllServicesAndCharacteristics();
        final characteristic = QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: DataUUID, deviceId: device.id);

        _characteristicsSubscription = connection.subscribeToCharacteristic(characteristic).listen((data) {
          _notificationCallback(data);
        }, onError: (dynamic error) {
          log.severe("Subscribe to $characteristic failed: $error");
        });

        return;
      case DeviceConnectionState.disconnected:
        scaleService.setState(ScaleState.disconnected, index);
        scaleService.setBattery(0, index);
        log.info('Bookoo Scale disconnected. Destroying');
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
    return Future(() => null);
  }

  @override
  Future<void> display(DisplayMode start) {
    return Future(() => null);
  }

  @override
  Future<void> power(PowerMode start) {
    return Future(() => null);
  }
}

import 'dart:async';
import 'dart:typed_data';

import 'package:despresso/devices/abstract_comm.dart';
import 'package:despresso/devices/abstract_scale.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'package:logging/logging.dart' as l;

class EurekaScale extends ChangeNotifier implements AbstractScale {
  final log = l.Logger('EurekaScale');

  // ignore: non_constant_identifier_names
  static Uuid ServiceUUID =
      useLongCharacteristics() ? Uuid.parse('0000fff0-0000-1000-8000-00805f9b34fb') : Uuid.parse('fff0');
  // ignore: non_constant_identifier_names
  static Uuid CharateristicUUID =
      useLongCharacteristics() ? Uuid.parse('0000fff1-0000-1000-8000-00805f9b34fb') : Uuid.parse('fff1');
  // ignore: non_constant_identifier_names
  static Uuid BatteryServiceUUID =
      useLongCharacteristics() ? Uuid.parse('0000180f-0000-1000-8000-00805f9b34fb') : Uuid.parse('180f');
  // ignore: non_constant_identifier_names
  static Uuid BatteryCharacteristicUUID =
      useLongCharacteristics() ? Uuid.parse('00002a19-0000-1000-8000-00805f9b34fb') : Uuid.parse('2a19');
  // ignore: non_constant_identifier_names
  static Uuid CommandUUID =
      useLongCharacteristics() ? Uuid.parse('0000fff2-0000-1000-8000-00805f9b34fb') : Uuid.parse('fff2');

  late ScaleService scaleService;

  static const int cmdHeader = 0xAA;
  static const int cmdBase = 0x02;
  static const int cmdStartTimer = 0x33;
  static const int cmdStopTimer = 0x34;
  static const int cmdResetTimer = 0x35;
  static const int cmdTare = 0x31;

  final DiscoveredDevice device;

  List<int> commandBuffer = [];

  late StreamSubscription<ConnectionStateUpdate> _deviceListener;

  late StreamSubscription<List<int>> _characteristicsSubscription;
  DeviceCommunication connection;

  int index = 0;
  EurekaScale(this.device, this.connection) {
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
    var isNeg = (data[6] == 0 ? false : true);
    var weight = (data[7] + (data[8] << 8));

    weight = isNeg ? weight * -1 : weight;
    scaleService.setWeight((weight / 10).toDouble(), index);
  }

  @override
  writeTare() {
    return writeToEureka([cmdHeader, cmdBase, cmdTare, cmdTare]);
  }

  Future<void> startTimer() {
    return writeToEureka([cmdHeader, cmdBase, cmdStartTimer, cmdStartTimer]);
  }

  Future<void> stopTimer() {
    return writeToEureka([cmdHeader, cmdBase, cmdStopTimer, cmdStopTimer]);
  }

  Future<void> resetTimer() {
    return writeToEureka([cmdHeader, cmdBase, cmdResetTimer, cmdResetTimer]);
  }

  Future<void> writeToEureka(List<int> payload) async {
    log.info("Sending to Eureka");
    final characteristic =
        QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: CommandUUID, deviceId: device.id);
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
        final characteristic =
            QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: CharateristicUUID, deviceId: device.id);

        _characteristicsSubscription = connection.subscribeToCharacteristic(characteristic).listen((data) {
          // code to handle incoming data
          _notificationCallback(data);
        }, onError: (dynamic error) {
          log.severe("Subscribe to $characteristic failed: $error");
        });

        final batteryCharacteristic = QualifiedCharacteristic(
            characteristicId: BatteryCharacteristicUUID, serviceId: BatteryServiceUUID, deviceId: device.id);
        final batteryLevel = await connection.readCharacteristic(batteryCharacteristic);
        scaleService.setBattery(batteryLevel[0], index);

        return;
      case DeviceConnectionState.disconnected:
        scaleService.setState(ScaleState.disconnected, index);
        log.info('Eureka Scale disconnected. Destroying');
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

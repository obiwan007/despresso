// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:typed_data';

import 'package:despresso/devices/abstract_comm.dart';
import 'package:despresso/devices/abstract_scale.dart';
import 'package:despresso/model/de1shotclasses.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'package:logging/logging.dart' as l;

class Skale2Scale extends ChangeNotifier implements AbstractScale {
  final log = l.Logger('Skale2Scale');

  static Uuid ServiceUUID =
      useLongCharacteristics() ? Uuid.parse('6e400001-b5a3-f393-e0a9-e50e24dcca9e') : Uuid.parse('ff08');
  static Uuid WeightCharacteristicUUID =
      useLongCharacteristics() ? Uuid.parse('0000EF81-0000-1000-8000-00805F9B34FB') : Uuid.parse('EF81');

  static Uuid BatteryServiceUUID =
      useLongCharacteristics() ? Uuid.parse('0000180f-0000-1000-8000-00805f9b34fb') : Uuid.parse('180f');
  // Platform.isAndroid ? Uuid.parse('0000180F-0000-1000-8000-00805f9b34fb') : Uuid.parse('180f');
  static Uuid BatteryCharacteristicUUID =
      useLongCharacteristics() ? Uuid.parse('00002a19-0000-1000-8000-00805f9b34fb') : Uuid.parse('2a19');
  static Uuid CommandUUID =
      useLongCharacteristics() ? Uuid.parse('0000EF80-0000-1000-8000-00805F9B34FB') : Uuid.parse('EF80');

  static Uuid ButtonNotifyUUID =
      useLongCharacteristics() ? Uuid.parse('0000ef82-0000-1000-8000-00805F9B34FB') : Uuid.parse('ef82');

  late ScaleService scaleService;

  static const int cmdDisplayOn = 0xed;
  static const int cmdDisplayOff = 0xee;
  static const int cmdDisplayWeight = 0xec;
  static const int cmdGramms = 0x3;
  static const int cmdPound = 0x2;
  static const int cmdTare = 0x10;
  static const int timerReset = 0xd0;
  static const int timerStart = 0xd1;
  static const int timerStop = 0xd2;

  final DiscoveredDevice device;

  List<int> commandBuffer = [];

  late StreamSubscription<ConnectionStateUpdate> _deviceListener;

  StreamSubscription<List<int>>? _characteristicsSubscription;

  StreamSubscription<List<int>>? _characteristicsButtonSubscription;
  DeviceCommunication connection;

  int index = 0;
  Skale2Scale(this.device, this.connection) {
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
    var weight = getInt(data);
    scaleService.setWeight((weight / 10 / 256).toDouble(), index);
  }

  void _notificationButtonsCallback(List<int> data) {
    var button = getInt(data);
    switch (button) {
      case 1:
        writeTare();
        break;
      case 2:
        break;
    }
    // scaleService.setWeight((weight / 10 / 256).toDouble());
  }

  int getInt(List<int> buffer) {
    ByteData bytes = ByteData(20);
    var i = 0;
    var list = bytes.buffer.asUint8List();
    for (var _ in buffer) {
      list[i] = buffer[i];
      i++;
    }
    return bytes.getInt32(0, Endian.little);
  }

  @override
  writeTare() {
    return writeToSkale([cmdTare]);
  }

  Future<void> displayOn() async {
    await writeToSkale([cmdDisplayOn]);
    return writeToSkale([cmdDisplayWeight]);
  }

  Future<void> displayOff() async {
    await writeToSkale([cmdDisplayOff]);
  }

  Future<void> setGramms() async {
    await writeToSkale([cmdGramms]);
  }

  Future<void> writeToSkale(List<int> payload) async {
    var list = Uint8List.fromList(payload);
    log.info("Sending to Skale2 ${Helper.toHex(list)}");
    final characteristic =
        QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: CommandUUID, deviceId: device.id);
    return await connection.writeCharacteristicWithoutResponse(characteristic, value: list);
  }

  void _onStateChange(DeviceConnectionState state) async {
    log.info('SCALE2 State changed to $state');

    switch (state) {
      case DeviceConnectionState.connecting:
        log.info('Connecting');
        scaleService.setState(ScaleState.connecting, index);
        break;

      case DeviceConnectionState.connected:
        log.info('Connected');
        scaleService.setState(ScaleState.connected, index);

        final characteristic = QualifiedCharacteristic(
            serviceId: ServiceUUID, characteristicId: WeightCharacteristicUUID, deviceId: device.id);

        _characteristicsSubscription = connection.subscribeToCharacteristic(characteristic).listen((data) {
          // code to handle incoming data
          _notificationCallback(data);
        }, onError: (dynamic error) {
          log.severe(("Error register weight callback $error"));
        });

        final characteristicButton =
            QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: ButtonNotifyUUID, deviceId: device.id);

        _characteristicsButtonSubscription = connection.subscribeToCharacteristic(characteristicButton).listen((data) {
          // code to handle incoming data
          _notificationButtonsCallback(data);
        }, onError: (dynamic error) {
          log.severe(("Error register weight callback $error"));
        });

        try {
          log.info("Service Id ${device.serviceUuids}");
          final batteryCharacteristic = QualifiedCharacteristic(
              characteristicId: BatteryCharacteristicUUID, serviceId: BatteryServiceUUID, deviceId: device.id);
          final batteryLevel = await connection.readCharacteristic(batteryCharacteristic);
          scaleService.setBattery(batteryLevel[0], index);

          connection.subscribeToCharacteristic(batteryCharacteristic).listen((data) {
            log.info(("Battery reported $data"));
            // code to handle incoming data
            scaleService.setBattery(data[0], index);
          }, onError: (dynamic error) {
            log.severe(("Error register battery callback $error"));
          });
        } catch (e) {
          log.severe("Error reading battery $e");
        }
        try {
          // await setGramms();
          await displayOn();
        } catch (e) {
          log.severe("Error setting scale2 gram and display $e");
        }

        return;
      case DeviceConnectionState.disconnected:
        scaleService.setState(ScaleState.disconnected, index);
        log.info('Skale2 disconnected. Destroying');
        scaleService.setBattery(0, index);
        // await device.disconnectOrCancelConnection();
        _characteristicsSubscription?.cancel();
        _characteristicsButtonSubscription?.cancel();

        _deviceListener.cancel();
        notifyListeners();
        return;
      default:
        return;
    }
  }

  @override
  Future<void> timer(TimerMode start) async {
    log.info("Timer $start");
    switch (start) {
      case TimerMode.start:
        await writeToSkale([timerStart]);
        break;
      case TimerMode.stop:
        await writeToSkale([timerStop]);
        break;
      case TimerMode.reset:
        await writeToSkale([timerReset]);
        break;
    }
  }

  @override
  Future<void> beep() {
    // TODO: implement beep
    throw UnimplementedError();
  }

  @override
  Future<void> display(DisplayMode start) async {
    log.info("Display $start");
    switch (start) {
      case DisplayMode.off:
        await displayOff();
        break;
      case DisplayMode.on:
        await displayOn();
        break;
    }
  }

  @override
  Future<void> power(PowerMode start) {
    // TODO: implement power
    throw UnimplementedError();
  }
}

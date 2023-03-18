// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:despresso/devices/abstract_scale.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'package:logging/logging.dart' as l;

class Skale2Scale extends ChangeNotifier implements AbstractScale {
  final log = l.Logger('Skale2Scale');

  static Uuid ServiceUUID =
      Platform.isAndroid ? Uuid.parse('6e400001-b5a3-f393-e0a9-e50e24dcca9e') : Uuid.parse('ff08');
  static Uuid WeightCharacteristicUUID =
      Platform.isAndroid ? Uuid.parse('0000EF81-0000-1000-8000-00805F9B34FB') : Uuid.parse('EF81');

  static Uuid BatteryServiceUUID =
      Platform.isAndroid ? Uuid.parse('0000180f-0000-1000-8000-00805f9b34fb') : Uuid.parse('180f');
  // Platform.isAndroid ? Uuid.parse('0000180F-0000-1000-8000-00805f9b34fb') : Uuid.parse('180f');
  static Uuid BatteryCharacteristicUUID =
      Platform.isAndroid ? Uuid.parse('00002a19-0000-1000-8000-00805f9b34fb') : Uuid.parse('2a19');
  static Uuid CommandUUID =
      Platform.isAndroid ? Uuid.parse('0000EF80-0000-1000-8000-00805F9B34FB') : Uuid.parse('EF80');

  static Uuid ButtonNotifyUUID =
      Platform.isAndroid ? Uuid.parse('0000ef82-0000-1000-8000-00805F9B34FB') : Uuid.parse('ef82');

  late ScaleService scaleService;

  static const int cmdDisplayOn = 0xed;
  static const int cmdDisplayOff = 0xee;
  static const int cmdDisplayWeight = 0xec;
  static const int cmdGramms = 0x3;
  static const int cmdPound = 0x2;
  static const int cmdTare = 0x10;

  final DiscoveredDevice device;

  List<int> commandBuffer = [];
  final flutterReactiveBle = FlutterReactiveBle();

  late StreamSubscription<ConnectionStateUpdate> _deviceListener;

  late StreamSubscription<List<int>> _characteristicsSubscription;

  Skale2Scale(this.device) {
    scaleService = getIt<ScaleService>();
    scaleService.setScaleInstance(this);
    _deviceListener = flutterReactiveBle.connectToDevice(id: device.id).listen((connectionState) {
      _onStateChange(connectionState.connectionState);
    }, onError: (Object error) {
      // Handle a possible error
    });
  }

  void _notificationCallback(List<int> data) {
    var weight = getInt(data);
    scaleService.setWeight((weight / 10 / 256).toDouble());
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

  Future<void> setGramms() async {
    await writeToSkale([cmdGramms]);
  }

  Future<void> writeToSkale(List<int> payload) async {
    log.info("Sending to Skale2");
    final characteristic =
        QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: CommandUUID, deviceId: device.id);
    return await flutterReactiveBle.writeCharacteristicWithoutResponse(characteristic,
        value: Uint8List.fromList(payload));
  }

  void _onStateChange(DeviceConnectionState state) async {
    log.info('SCALE2 State changed to $state');

    switch (state) {
      case DeviceConnectionState.connecting:
        log.info('Connecting');
        scaleService.setState(ScaleState.connecting);
        break;

      case DeviceConnectionState.connected:
        log.info('Connected');
        scaleService.setState(ScaleState.connected);

        final characteristic = QualifiedCharacteristic(
            serviceId: ServiceUUID, characteristicId: WeightCharacteristicUUID, deviceId: device.id);

        _characteristicsSubscription = flutterReactiveBle.subscribeToCharacteristic(characteristic).listen((data) {
          // code to handle incoming data
          _notificationCallback(data);
        }, onError: (dynamic error) {
          log.severe(("Error register weight callback $error"));
        });

        final characteristicButton =
            QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: ButtonNotifyUUID, deviceId: device.id);

        _characteristicsSubscription =
            flutterReactiveBle.subscribeToCharacteristic(characteristicButton).listen((data) {
          // code to handle incoming data
          _notificationButtonsCallback(data);
        }, onError: (dynamic error) {
          log.severe(("Error register weight callback $error"));
        });

        try {
          log.info("Service Id ${device.serviceUuids}");
          final batteryCharacteristic = QualifiedCharacteristic(
              characteristicId: BatteryCharacteristicUUID, serviceId: BatteryServiceUUID, deviceId: device.id);
          final batteryLevel = await flutterReactiveBle.readCharacteristic(batteryCharacteristic);
          scaleService.setBattery(batteryLevel[0]);
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
        scaleService.setState(ScaleState.disconnected);
        log.info('Skale2 disconnected. Destroying');
        scaleService.setBattery(0);
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

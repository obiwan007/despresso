import 'dart:async';
import 'dart:developer';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:despresso/devices/abstract_scale.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class DecentScale extends ChangeNotifier implements AbstractScale {
  // ignore: non_constant_identifier_names
  static Uuid ServiceUUID = Uuid.parse('0000fff0-0000-1000-8000-00805f9b34fb');
// ignore: non_constant_identifier_names
  static Uuid ReadCharacteristicUUID =
      Uuid.parse('0000fff4-0000-1000-8000-00805f9b34fb');
// ignore: non_constant_identifier_names
  static Uuid WriteCharacteristicUUID =
      Uuid.parse('000036f5-0000-1000-8000-00805f9b34fb');

  late ScaleService scaleService;

  final DiscoveredDevice device;

  late DeviceConnectionState _state;

  final flutterReactiveBle = FlutterReactiveBle();

  late StreamSubscription<ConnectionStateUpdate> _deviceListener;

  late StreamSubscription<List<int>> _characteristicsSubscription;

  bool weightStability = true;

  DecentScale(this.device) {
    scaleService = getIt<ScaleService>();
    log("Connect to Decent");
    scaleService.setScaleInstance(this);
    _deviceListener = flutterReactiveBle.connectToDevice(id: device.id).listen(
        (connectionState) {
      // Handle connection state updates
      log('Peripheral ${device.name} connection state is $connectionState');
      _onStateChange(connectionState.connectionState);
    }, onError: (Object error) {
      // Handle a possible error
    });
  }

  void _notificationCallback(List<int> data) {
    var weight = ((data[2] << 8) + data[3]) / 10;
    if (weight > 3200) {
      writeTare();
    } else {
      scaleService.setWeight(weight);
    }
    if (data[1] == 0xCE) {
      // scaleService.setWeightStable(true);
      log('weight stable');
      weightStability = true;
    } else {
      // scaleService.setWeightStable(false);
      log('weight changing');
      weightStability = false;
    }
  }

  int getXOR(payload) {
    return payload[0] ^
        payload[1] ^
        payload[2] ^
        payload[3] ^
        payload[4] ^
        payload[5];
  }

  writeTare() {
    List<int> payload = [0x03, 0x0F, 0xFD, 0x00, 0x00, 0x00];
    payload.add(getXOR(payload));
    return writeToDecentScale(payload);
  }

  Future<void> ledOff() {
    List<int> payload = [0x03, 0x0A, 0x00, 0x00, 0x00, 0x00];
    payload.add(getXOR(payload));
    return writeToDecentScale(payload);
  }

  Future<void> startTimer() {
    List<int> payload = [0x03, 0x0B, 0x03, 0x00, 0x00, 0x00];
    payload.add(getXOR(payload));
    return writeToDecentScale(payload);
  }

  Future<void> stopTimer() {
    List<int> payload = [0x03, 0x0B, 0x00, 0x00, 0x00, 0x00];
    payload.add(getXOR(payload));
    return writeToDecentScale(payload);
  }

  Future<void> resetTimer() {
    List<int> payload = [0x03, 0x0B, 0x02, 0x00, 0x00, 0x00];
    payload.add(getXOR(payload));
    return writeToDecentScale(payload);
  }

  Future<void> powerOff() {
    List<int> payload = [0x03, 0x0B, 0x03, 0x00, 0x00, 0x00];
    payload.add(getXOR(payload));
    return writeToDecentScale(payload);
  }

  Future<void> writeToDecentScale(List<int> payload) async {
    // Uint8List command = Uint8List.fromList(payload.add(getXOR(payload)));
    log("Sending to Decent");
    final characteristic = QualifiedCharacteristic(
        serviceId: ServiceUUID,
        characteristicId: WriteCharacteristicUUID,
        deviceId: device.id);
    return await flutterReactiveBle.writeCharacteristicWithoutResponse(
        characteristic,
        value: Uint8List.fromList(payload));
  }

  void _onStateChange(DeviceConnectionState state) async {
    log('SCALE State changed to $state');
    _state = state;

    switch (state) {
      case DeviceConnectionState.connecting:
        log('Connecting');
        scaleService.setState(ScaleState.connecting);
        break;

      case DeviceConnectionState.connected:
        log('Connected');
        scaleService.setState(ScaleState.connected);
        ledOff(); // make the scale report weight by sending an inital write cmd

        final characteristic = QualifiedCharacteristic(
            serviceId: ServiceUUID,
            characteristicId: ReadCharacteristicUUID,
            deviceId: device.id);

        _characteristicsSubscription = flutterReactiveBle
            .subscribeToCharacteristic(characteristic)
            .listen((data) {
          // code to handle incoming data
          _notificationCallback(data);
        }, onError: (dynamic error) {
          // code to handle errors
        });

        return;
      case DeviceConnectionState.disconnected:
        scaleService.setState(ScaleState.disconnected);
        log('Eureka Scale disconnected. Destroying');
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
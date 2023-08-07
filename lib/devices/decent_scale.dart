import 'dart:async';
import 'dart:typed_data';

import 'package:despresso/devices/abstract_comm.dart';
import 'package:despresso/devices/abstract_scale.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:logging/logging.dart' as l;

class DecentScale extends ChangeNotifier implements AbstractScale {
  final log = l.Logger('DecentScale');
  // ignore: non_constant_identifier_names
  static Uuid ServiceUUID =
      useLongCharacteristics() ? Uuid.parse('0000fff0-0000-1000-8000-00805f9b34fb') : Uuid.parse('fff0');
// ignore: non_constant_identifier_names
  static Uuid ReadCharacteristicUUID =
      useLongCharacteristics() ? Uuid.parse('0000fff4-0000-1000-8000-00805f9b34fb') : Uuid.parse('fff4');
// ignore: non_constant_identifier_names
  static Uuid WriteCharacteristicUUID =
      useLongCharacteristics() ? Uuid.parse('000036f5-0000-1000-8000-00805f9b34fb') : Uuid.parse('36f5');

  late ScaleService scaleService;

  final DiscoveredDevice device;

  late StreamSubscription<ConnectionStateUpdate> _deviceListener;

  late StreamSubscription<List<int>> _characteristicsSubscription;

  bool weightStability = true;
  int tareCounter = 0;
  double _weight = 0.0;
  DeviceCommunication connection;

  int index = 0;

  DecentScale(this.device, this.connection) {
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
    if (data.length < 4) return;
    var d = ByteData(2);
    d.setInt8(0, data[2]);
    d.setInt8(1, data[3]);
    _weight = d.getInt16(0) / 10;
    scaleService.setWeight(_weight, index);

    if (data[1] == 0xCE) {
      // log.info('weight stable');
      weightStability = true;
    } else {
      // log.info('weight changing');
      weightStability = false;
    }
    if (data[1] == 0xAA && data[3] == 0x01) {
      // short button presses - depends on fw and scale version if delivered
      switch (data[2]) {
        case 0x01:
          log.info('button 1 short pressed');
          break;
        case 0x02:
          log.info('button 2 short pressed, init tare');
          Future.delayed(Duration(seconds: 1), () => writeTare());
      }
    }
    if (data[1] == 0xAA && data[3] == 0x02) {
      // button long presses - depends on fw and scale version if delivered
      switch (data[2]) {
        case 01:
          log.info('button 1 long pressed');
          break;
        case 02:
          log.info('button 2 long pressed');
      }
    }
    if (data[5] == 0xFE) {
      log.info('successful cmd');
    }
  }

  int getXOR(payload) {
    return payload[0] ^ payload[1] ^ payload[2] ^ payload[3] ^ payload[4] ^ payload[5];
  }

  @override
  writeTare() async {
    // tare command
    bool exit = false;
    _weight = 100;
    for (var i = 0; i < 3; i++) {
      await sendTare();
      await Future.delayed(
        const Duration(milliseconds: 200),
        () {
          if (_weight < 0.1 && _weight > -0.1) {
            exit = true;
          }
        },
      );
      if (exit == true) {
        log.fine("Tare finished without repeat $i");
        return;
      }
      log.fine("Tare repeat $_weight");
    }
  }

  sendTare() {
    List<int> payload = [0x03, 0x0F, 0xFD, tareCounter, 0x00, 0x00];
    payload.add(getXOR(payload));
    tareCounter++;
    if (tareCounter > 255) {
      tareCounter = 0;
    }
    return writeToDecentScale(payload);
  }

  Future<void> ledOff() {
    List<int> payload = [0x03, 0x0A, 0x00, 0x00, 0x00, 0x00];
    payload.add(getXOR(payload));
    return writeToDecentScale(payload);
  }

  Future<void> ledOn() {
    List<int> payload = [0x03, 0x0A, 0x01, 0x01, 0x00, 0x00];
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
    // only works with fw 1.2+
    List<int> payload = [0x03, 0x0B, 0x03, 0x00, 0x00, 0x00];
    payload.add(getXOR(payload));
    return writeToDecentScale(payload);
  }

  Future<void> writeToDecentScale(List<int> payload) async {
    // Uint8List command = Uint8List.fromList(payload.add(getXOR(payload)));
    log.info("Sending to Decent");
    final characteristic =
        QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: WriteCharacteristicUUID, deviceId: device.id);
    return await connection.writeCharacteristicWithResponse(characteristic, value: Uint8List.fromList(payload));
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
        ledOn(); // make the scale report weight by sending an inital write cmd

        subscribeToNotifications();

        return;
      case DeviceConnectionState.disconnected:
        scaleService.setState(ScaleState.disconnected, index);
        scaleService.setBattery(0, index);
        log.info('Decent Scale disconnected. Destroying');
        _characteristicsSubscription.cancel();

        _deviceListener.cancel();
        notifyListeners();
        return;
      default:
        return;
    }
  }

  subscribeToNotifications() {
    final characteristic =
        QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: ReadCharacteristicUUID, deviceId: device.id);

    _characteristicsSubscription = connection.subscribeToCharacteristic(characteristic).listen((data) {
      _notificationCallback(data);
    }, onError: (dynamic error) {
      log.severe("Subscribe to $characteristic failed: $error");
    });
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
  Future<void> display(DisplayMode start) async {
    try {
      switch (start) {
        case DisplayMode.on:
          ledOn();
          break;
        case DisplayMode.off:
          ledOff();
          break;
      }
    } catch (e) {
      log.severe("display failed $e");
    }
  }

  @override
  Future<void> power(PowerMode start) {
    return Future(() => null);
  }
}

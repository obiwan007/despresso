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

  final flutterReactiveBle = FlutterReactiveBle();

  late StreamSubscription<ConnectionStateUpdate> _deviceListener;

  late StreamSubscription<List<int>> _characteristicsSubscription;

  bool weightStability = true;
  int tareCounter = 0;
  DeviceCommunication connection;
  DecentScale(this.device, this.connection) {
    scaleService = getIt<ScaleService>();
    scaleService.setScaleInstance(this);
    _deviceListener = flutterReactiveBle.connectToDevice(id: device.id).listen((connectionState) {
      _onStateChange(connectionState.connectionState);
    }, onError: (Object error) {
      // Handle a possible error
    });
  }

  void _notificationCallback(List<int> data) {
    if (data.length < 4) return;
    var weight = ((data[2] << 8) + data[3]) / 10;
    if (weight > 3200) {
      // This gives us also the negative weight - similar implementation as in Beanconqueror
      weight = ((data[2].toSigned(8) << 8) + data[3].toSigned(8)) / 10;
    }
    scaleService.setWeight(weight);

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
          log.info('button 2 short pressed');
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
  writeTare() {
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
    await flutterReactiveBle.writeCharacteristicWithResponse(characteristic, value: Uint8List.fromList(payload));
    return await flutterReactiveBle.writeCharacteristicWithResponse(characteristic, value: Uint8List.fromList(payload));
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
        ledOn(); // make the scale report weight by sending an inital write cmd

        final characteristic = QualifiedCharacteristic(
            serviceId: ServiceUUID, characteristicId: ReadCharacteristicUUID, deviceId: device.id);

        _characteristicsSubscription = flutterReactiveBle.subscribeToCharacteristic(characteristic).listen((data) {
          _notificationCallback(data);
        }, onError: (dynamic error) {
          log.severe("Subscribe to $characteristic failed: $error");
        });

        return;
      case DeviceConnectionState.disconnected:
        scaleService.setState(ScaleState.disconnected);
        scaleService.setBattery(0);
        log.info('Decent Scale disconnected. Destroying');
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

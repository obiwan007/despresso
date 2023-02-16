import 'dart:async';
import 'dart:io' show Platform;
import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
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
      Platform.isAndroid ? Uuid.parse('0000ffe0-0000-1000-8000-00805f9b34fb') : Uuid.parse('ffe0');
  static Uuid DataUUID = Platform.isAndroid ? Uuid.parse('0000ffe1-0000-1000-8000-00805f9b34fb') : Uuid.parse('ffe1');

  late ScaleService scaleService;

  static const int minBattLevel = 129;
  static const int maxBattLevel = 158;

  static const int cmdStartTimer = 0x52;
  static const int cmdStopTimer = 0x53;
  static const int cmdResetTimer = 0x43;
  static const int cmdToggleTimer = 0x42;
  static const int cmdTogglePrecistion = 0x44;
  static const int cmdTare = 0x54;
  static const int cmdToggleUnit = 0x55;

  final DiscoveredDevice device;

  late DeviceConnectionState _state;

  List<int> commandBuffer = [];
  final flutterReactiveBle = FlutterReactiveBle();

  late StreamSubscription<ConnectionStateUpdate> _deviceListener;

  late StreamSubscription<List<int>> _characteristicsSubscription;

  FelicitaScale(this.device) {
    scaleService = getIt<ScaleService>();
    scaleService.setScaleInstance(this);
    _deviceListener = flutterReactiveBle.connectToDevice(id: device.id).listen((connectionState) {
      _onStateChange(connectionState.connectionState);
    }, onError: (Object error) {
      // Handle a possible error
    });
  }

  void _notificationCallback(List<int> data) {
    if (data.length == 18) {
      // var isNeg = (data[6] == 0 ? false : true);
      // var weight = (data[7] + (data[8] << 8));

      // weight = isNeg ? weight * -1 : weight;
      // scaleService.setWeight((weight / 10).toDouble());
      //  data.slice(3,9).map((value) => { return value - 48 }).join('');

      // scaleService.setWeight(weight/100);
      scaleService.setBattery(((data[15] - minBattLevel) / (maxBattLevel - minBattLevel) * 100).round());
    }
  }

  @override
  writeTare() {
    return writeToEureka([cmdTare]);
  }

  Future<void> startTimer() {
    return writeToEureka([cmdStartTimer]);
  }

  Future<void> stopTimer() {
    return writeToEureka([cmdStopTimer]);
  }

  Future<void> resetTimer() {
    return writeToEureka([cmdResetTimer]);
  }

  Future<void> writeToEureka(List<int> payload) async {
    log.info("Sending to Felicita");
    final characteristic =
        QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: DataUUID, deviceId: device.id);
    return await flutterReactiveBle.writeCharacteristicWithoutResponse(characteristic,
        value: Uint8List.fromList(payload));
  }

  void _onStateChange(DeviceConnectionState state) async {
    log.info('SCALE State changed to $state');
    _state = state;

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

        _characteristicsSubscription = flutterReactiveBle.subscribeToCharacteristic(characteristic).listen((data) {
          // code to handle incoming data
          _notificationCallback(data);
        }, onError: (dynamic error) {
          // code to handle errors
        });

        return;
      case DeviceConnectionState.disconnected:
        scaleService.setState(ScaleState.disconnected);
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
}

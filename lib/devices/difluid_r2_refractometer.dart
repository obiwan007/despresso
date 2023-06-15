import 'dart:async';
import 'dart:typed_data';

import 'package:despresso/devices/abstract_comm.dart';
import 'package:despresso/devices/abstract_refractometer.dart';
import 'package:flutter/cupertino.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:logging/logging.dart' as l;

import '../model/services/ble/refractometer_service.dart';

class DifluidR2Refractometer extends ChangeNotifier implements AbstractRefractometer {
  final log = l.Logger('DifluidR2Refractometer');
  // ignore: non_constant_identifier_names
  static Uuid ServiceUUID =
      useLongCharacteristics() ? Uuid.parse('000000ff-0000-1000-8000-00805f9b34fb') : Uuid.parse('00ff');
// ignore: non_constant_identifier_names
  static Uuid CharacteristicUUID =
      useLongCharacteristics() ? Uuid.parse('0000aa01-0000-1000-8000-00805f9b34fb') : Uuid.parse('aa01');

  late RefractometerService refractometerService;

  final DiscoveredDevice device;

  final flutterReactiveBle = FlutterReactiveBle();

  late StreamSubscription<ConnectionStateUpdate> _deviceListener;

  late StreamSubscription<List<int>> _characteristicsSubscription;

  DeviceCommunication connection;

  late bool responseReceived = false;
  DifluidR2Refractometer(this.device, this.connection) {
    refractometerService = getIt<RefractometerService>();
    refractometerService.setRefractometerInstance(this);
    _deviceListener = connection.connectToDevice(id: device.id).listen((connectionState) {
      _onStateChange(connectionState.connectionState);
    }, onError: (Object error) {
      // Handle a possible error
    });
  }
  @override
  Future<void> requestValue() async {
    responseReceived = false;
    writeToDifluidRefractometer([0xDF, 0xDF, 0x03, 0x00, 0x00, 0xC1]);
    return await waitForResponse();
    // if average is wanted an average test return writeToDifluidRefractometer([0xDF, 0xDF, 0x03, 0x01, 0x01, 0x03 0xC6]);
  }

  waitForResponse() async {
    while (!responseReceived) {
      // Wait for a short duration before checking again
      await Future.delayed(Duration(milliseconds: 100));
    }
  }

  startDeviceNotifications() {
    log.info('enabling notifications');
    return writeToDifluidRefractometer([0xDF, 0xDF, 0x01, 0x00, 0x01, 0x01, 0xC1]);
  }

  setDeviceToCelsius() {
    log.info('enabling notifications');
    return writeToDifluidRefractometer([0xDF, 0xDF, 0x01, 0x00, 0x01, 0x00, 0xC0]);
  }

  Future<void> writeToDifluidRefractometer(List<int> payload) async {
    log.info("Sending to Difluid Refractometer");
    final characteristic =
        QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: CharacteristicUUID, deviceId: device.id);
    return await connection.writeCharacteristicWithResponse(characteristic, value: Uint8List.fromList(payload));
  }

  void _notificationCallback(List<int> data) {
    log.info(data);
    if (data[3] == 254) {
      log.info('no liquid');
    }
    if (data[4] == 3 && data[5] == 0) {
      if (data[6] == 11) {
        log.info('test started');
      } else if (data[6] == 0) {
        log.info('test finished');
      }
    } else if (data[4] == 6 && data[5] == 1) {
      log.info('temp result');
      var tempPrism = getInt(data.sublist(6, 8));
      var tempTank = getInt(data.sublist(9, 11));
      refractometerService.setTemp(tempPrism / 10, tempTank / 10);
    } else if (data[4] == 7 && data[5] == 2) {
      log.info('tds result');
      var tds = getInt(data.sublist(6, 8));
      var refractiveIndex = getInt(data.sublist(8, 12));
      refractometerService.setRefraction(tds / 100, refractiveIndex / 100000);
      responseReceived = true;
    }
  }

  int getInt(List<int> buffer) {
    ByteData bytes = ByteData(buffer.length);
    var i = 0;
    var list = bytes.buffer.asUint8List();
    for (var _ in buffer) {
      list[i] = buffer[i];
      i++;
    }
    if (buffer.length == 2) {
      return bytes.getInt16(0, Endian.big);
    } else {
      return bytes.getInt32(0, Endian.big);
    }
  }

  void _onStateChange(DeviceConnectionState state) async {
    log.info('REFRACTOMETER State changed to $state');

    switch (state) {
      case DeviceConnectionState.connecting:
        log.info('Connecting');
        refractometerService.setState(RefractometerState.connecting);
        break;

      case DeviceConnectionState.connected:
        log.info('Connected');
        refractometerService.setState(RefractometerState.connected);

        final characteristic =
            QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: CharacteristicUUID, deviceId: device.id);

        _characteristicsSubscription = flutterReactiveBle.subscribeToCharacteristic(characteristic).listen((data) {
          _notificationCallback(data);
        }, onError: (dynamic error) {
          log.severe("Subscribe to $characteristic failed: $error");
        });
        startDeviceNotifications();
        setDeviceToCelsius();
        return;
      case DeviceConnectionState.disconnected:
        refractometerService.setState(RefractometerState.disconnected);
        refractometerService.setBattery(0);
        log.info('Difluid R2 Refractometer disconnected. Destroying');
        _characteristicsSubscription.cancel();

        _deviceListener.cancel();
        notifyListeners();
        return;
      default:
        return;
    }
  }
}

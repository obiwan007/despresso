import 'dart:async';
import 'package:despresso/devices/abstract_comm.dart';
import 'package:despresso/model/services/ble/temperature_service.dart';

import 'package:despresso/devices/abstract_thermometer.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'package:logging/logging.dart' as l;

class IBraaiThermometer extends ChangeNotifier implements AbstractThermometer {
  final log = l.Logger('iBraaiTherm');

  // ignore: non_constant_identifier_names
  Uuid ServiceUUID = useLongCharacteristics() ? Uuid.parse('00001000-0000-1000-8000-00805f9b34fb') : Uuid.parse('1000');
  // ignore: non_constant_identifier_names
  static Uuid CharateristicUUID =
      useLongCharacteristics() ? Uuid.parse('00001002-0000-1000-8000-00805f9b34fb') : Uuid.parse('1002');

  late TempService tempService;

  final DiscoveredDevice device;

  List<int> commandBuffer = [];

  late StreamSubscription<ConnectionStateUpdate> _deviceListener;

  late StreamSubscription<List<int>> _characteristicsSubscription;
  DeviceCommunication connection;
  IBraaiThermometer(this.device, this.connection) {
    tempService = getIt<TempService>();
    log.info("Connect to iBraai ${device.serviceUuids}");
    _deviceListener = connection.connectToDevice(id: device.id).listen((connectionState) {
      _onStateChange(connectionState.connectionState);
    }, onError: (Object error) {
      // Handle a possible error
    });
  }

  bytesToInt(int byte0, int byte1) {
    return byte1 * 256 + byte0;
  }

  toCelsius(int value) {
    return ((value) + 8.0) / 16.0;
  }

  void _notificationCallback(List<int> pData) {
    var temp = (pData[0] ^ pData[2] ^ pData[8]) * 10 + (pData[0] ^ pData[2] ^ pData[9]).toDouble();
    tempService.setTemp(temp, temp);
  }

  void _onStateChange(DeviceConnectionState state) async {
    log.info('IBraai State changed to $state');

    switch (state) {
      case DeviceConnectionState.connecting:
        log.info('Connecting');
        tempService.setState(TempState.connecting);
        break;

      case DeviceConnectionState.connected:
        log.info('Connected');
        tempService.setState(TempState.connected);
        final characteristic =
            QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: CharateristicUUID, deviceId: device.id);

        _characteristicsSubscription = connection.subscribeToCharacteristic(characteristic).listen((data) {
          // code to handle incoming data
          _notificationCallback(data);
        }, onError: (dynamic error) {
          log.severe("Error subscribing to temp characteristics $error");
        });

        return;
      case DeviceConnectionState.disconnected:
        tempService.setState(TempState.disconnected);
        log.info('IBraai disconnected. Destroying');
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

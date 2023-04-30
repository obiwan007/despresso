import 'dart:async';
import 'dart:math';
import 'package:despresso/devices/abstract_comm.dart';
import 'package:despresso/model/services/ble/temperature_service.dart';

import 'package:despresso/devices/abstract_thermometer.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'package:logging/logging.dart' as l;

class MeaterThermometer extends ChangeNotifier implements AbstractThermometer {
  final log = l.Logger('MeaterTherm');

  // ignore: non_constant_identifier_names
  Uuid ServiceUUID = Uuid.parse('a75cc7fc-c956-488f-ac2a-2dbc08b63a04');
  // ignore: non_constant_identifier_names
  static Uuid CharateristicUUID = Uuid.parse('7edda774-045e-4bbf-909b-45d1991a2876');
  // ignore: non_constant_identifier_names
  static Uuid BatteryServiceUUID = Uuid.parse('a75cc7fc-c956-488f-ac2a-2dbc08b63a04');
  // ignore: non_constant_identifier_names
  static Uuid BatteryCharacteristicUUID = Uuid.parse('2adb4877-68d8-4884-bd3c-d83853bf27b8');

  late TempService tempService;

  final DiscoveredDevice device;

  List<int> commandBuffer = [];

  late StreamSubscription<ConnectionStateUpdate> _deviceListener;

  late StreamSubscription<List<int>> _characteristicsSubscription;
  DeviceCommunication connection;
  MeaterThermometer(this.device, this.connection) {
    tempService = getIt<TempService>();
    log.info("Connect to Meater ${device.serviceUuids}");
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
    int tip = bytesToInt(pData[0], pData[1]);
    int ra = bytesToInt(pData[2], pData[3]);
    int oa = bytesToInt(pData[4], pData[5]);
    double ambient2 = tip + (max(0.0, ((((ra - min(48, oa)) * 16) * 589)) / 1487));

    // int meat_raw = ((pData[1] << 8) + (pData[0]));
    // double temp_int = (meat_raw).toDouble() / 16;
    // int ambient_raw = ((pData[3] << 8) + (pData[2]));
    // int offset = ((pData[5] << 8) + (pData[4]));
    // double ambient = (meat_raw + max(0, (ambient_raw - offset)) * 6.33) / 16;
    // log.info(
    //     "Data $meat_raw, TempInt: $temp_int, Ambient Raw:$ambient_raw, $offset, Ambient:$ambient 2:${toCelsius(ambient2.toInt())} TIP:${toCelsius(tip)}");

    tempService.setTemp(toCelsius(tip), toCelsius(ambient2.toInt()));
  }

  void _onStateChange(DeviceConnectionState state) async {
    log.info('MEATER State changed to $state');

    switch (state) {
      case DeviceConnectionState.connecting:
        log.info('Connecting');
        tempService.setState(TempState.connecting);
        break;

      case DeviceConnectionState.connected:
        log.info('Connected');
        tempService.setState(TempState.connected);
        // await device.discoverAllServicesAndCharacteristics();
        final characteristic =
            QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: CharateristicUUID, deviceId: device.id);

        _characteristicsSubscription = connection.subscribeToCharacteristic(characteristic).listen((data) {
          // code to handle incoming data
          _notificationCallback(data);
        }, onError: (dynamic error) {
          log.severe("Error subscribing to temp characteristics $error");
        });

        try {
          final batteryCharacteristic = QualifiedCharacteristic(
              characteristicId: BatteryCharacteristicUUID, serviceId: BatteryServiceUUID, deviceId: device.id);

          connection.subscribeToCharacteristic(batteryCharacteristic).listen((data) {
            // code to handle incoming data
            int bat = bytesToInt(data[0], data[1]) * 10;
            tempService.setBattery(bat);
          }, onError: (dynamic error) {
            log.severe("Error subscribing to battery characteristics $error");
          });

          final batteryLevel = await connection.readCharacteristic(batteryCharacteristic);
          int bat = bytesToInt(batteryLevel[0], batteryLevel[1]) * 10;
          tempService.setBattery(bat);
        } catch (e) {
          log.severe("Error reading battery $e");
        }

        return;
      case DeviceConnectionState.disconnected:
        tempService.setState(TempState.disconnected);
        log.info('Meater disconnected. Destroying');
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

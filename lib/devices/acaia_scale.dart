import 'dart:async';
import 'dart:developer';
import 'dart:math' show pow;
import 'dart:typed_data';

import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class AcaiaScale extends ChangeNotifier {
  // ignore: non_constant_identifier_names
  static Uuid ServiceUUID = Uuid.parse('00001820-0000-1000-8000-00805f9b34fb');
  // ignore: non_constant_identifier_names
  static Uuid CharateristicUUID = Uuid.parse('00002a80-0000-1000-8000-00805f9b34fb');
  late ScaleService scaleService;

  static const _heartbeatTime = Duration(seconds: 3);
  static const List<int> _heartbeatPayload = [0x02, 0x00];
  static const List<int> _identPayload = [
    0x30,
    0x31,
    0x32,
    0x33,
    0x34,
    0x35,
    0x36,
    0x37,
    0x38,
    0x39,
    0x30,
    0x31,
    0x32,
    0x33,
    0x34
  ];
  static const List<int> _configPayload = [
    9, // length
    0, // weight
    1, // weight argument
    1, // battery
    2, // battery argument
    2, // timer
    5, // timer argument
    3, // key
    4 // setting
  ];

  static const int header1 = 0xef;
  static const int header2 = 0xdd;

  final DiscoveredDevice device;

  late DeviceConnectionState _state;

  List<int> commandBuffer = [];
  late Timer _heartBeatTimer;
  final flutterReactiveBle = FlutterReactiveBle();

  late StreamSubscription<ConnectionStateUpdate> _deviceListener;

  late StreamSubscription<List<int>> _characteristicsSubscription;

  AcaiaScale(this.device) {
    scaleService = getIt<ScaleService>();
    log("Connect to Acaia");
    scaleService.setScaleInstance(this);
    _deviceListener = flutterReactiveBle.connectToDevice(id: device.id).listen((connectionState) {
      // Handle connection state updates
      log('Peripheral ${device.name} connection state is $connectionState');
      _onStateChange(connectionState.connectionState);
    }, onError: (Object error) {
      // Handle a possible error
    });

    // device
    //     .observeConnectionState(
    //         emitCurrentValue: false, completeOnDisconnect: true)
    //     .listen((connectionState) {
    //   log('Peripheral ${device.identifier} connection state is $connectionState');
    //   _onStateChange(connectionState);
    // });
    // device.connect();
  }

  Uint8List encode(int msgType, List<int> payload) {
    var cksum1 = 0;
    var cksum2 = 0;
    var buffer = <int>[];
    buffer.add(header1);
    buffer.add(header2);
    buffer.add(msgType);

    payload.asMap().forEach((index, value) => {
          if (index % 2 == 0) {cksum1 += value} else {cksum2 += value},
          buffer.add(value)
        });

    buffer.add(cksum1 & 0xFF);
    buffer.add(cksum2 & 0xFF);

    return Uint8List.fromList(buffer);
  }

  void parsePayload(int type, List<int> payload) {
    switch (type) {
      case 12:
        var subType = payload[0];
        if (subType == 5) {
          var temp = ((payload[4] & 0xff) << 24) +
              ((payload[3] & 0xff) << 16) +
              ((payload[2] & 0xff) << 8) +
              (payload[1] & 0xff);
          var unit = payload[5] & 0xFF;

          var value = temp / pow(10, unit);
          if ((payload[6] & 0x02) != 0) {
            value *= -1.0;
          }
          scaleService.setWeight(value);

          break;
        }
        //log("Unparsed acaia event subtype: " + subType.toString());
        //log("Payload: " + payload.toString());

        break;
      // General Status including battery
      case 8:
        var batteryLevel = commandBuffer[4];
        log('Got status message, battery= $batteryLevel');
        break;
      default:
        log('Unparsed acaia response: $type');
    }
  }

  void _notificationCallback(List<int> data) {
    var notification = data;
    commandBuffer.addAll(notification);

    // remove broken half commands
    if (commandBuffer.length > 2 && (commandBuffer[0] != header1 || commandBuffer[1] != header2)) {
      commandBuffer.clear();
      return;
    }
    if (commandBuffer.length > 4) {
      var type = commandBuffer[2];
      parsePayload(type, commandBuffer.sublist(4));
      commandBuffer.clear();
    }
  }

  void _sendHeatbeat() {
    if (_state != DeviceConnectionState.connected) {
      log('Disconnected from acaia scale. Not sending heartbeat');

      scaleService.setState(ScaleState.disconnected);
      return;
    }
    final characteristic =
        QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: CharateristicUUID, deviceId: device.id);
    flutterReactiveBle.writeCharacteristicWithoutResponse(characteristic, value: encode(0x00, _heartbeatPayload));

    // device.writeCharacteristic(
    //     ServiceUUID, CharateristicUUID, encode(0x00, _heartbeatPayload), false);
  }

  void _sendIdent() {
    if (_state != DeviceConnectionState.connected) {
      log('Disconnected from acaia scale. Not sending ident');

      scaleService.setState(ScaleState.disconnected);
      return;
    }

    final characteristic =
        QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: CharateristicUUID, deviceId: device.id);
    flutterReactiveBle.writeCharacteristicWithoutResponse(characteristic, value: encode(0x0b, _identPayload));

    // device.writeCharacteristic(
    //     ServiceUUID, CharateristicUUID, encode(0x0b, _identPayload), false);
    log('Ident payload: ${encode(0x0b, _identPayload)}');
  }

  void _sendConfig() {
    if (_state != DeviceConnectionState.connected) {
      log('Disconnected from acaia scale. Not sending config');
      scaleService.setState(ScaleState.disconnected);
      return;
    }

    final characteristic =
        QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: CharateristicUUID, deviceId: device.id);
    flutterReactiveBle.writeCharacteristicWithoutResponse(characteristic, value: encode(0x0c, _configPayload));

    // device.writeCharacteristic(
    //     ServiceUUID, CharateristicUUID, encode(0x0c, _configPayload), false);
    log('Config payload: ${encode(0x0c, _configPayload)}');
  }

  Future<void> writeTare() {
    // tare command
    var list = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];

    final characteristic =
        QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: CharateristicUUID, deviceId: device.id);
    return flutterReactiveBle.writeCharacteristicWithoutResponse(characteristic, value: encode(0x04, list));
  }

  Future<void> writeToAcaia(Uint8List payload) async {
    log("Sending to Acaia");
    final characteristic =
        QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: CharateristicUUID, deviceId: device.id);
    return await flutterReactiveBle.writeCharacteristicWithResponse(characteristic, value: payload);
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
        // await device.discoverAllServicesAndCharacteristics();
        final characteristic =
            QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: CharateristicUUID, deviceId: device.id);

        // flutterReactiveBle
        //     .subscribeToCharacteristic(characteristic)
        //     .listen(_notificationCallback);
        _characteristicsSubscription = flutterReactiveBle.subscribeToCharacteristic(characteristic).listen((data) {
          // code to handle incoming data
          _notificationCallback(data);
        }, onError: (dynamic error) {
          // code to handle errors
        });
        // device
        //     .monitorCharacteristic(ServiceUUID, CharateristicUUID)
        //     .listen(_notificationCallback);

        Timer(const Duration(seconds: 1), _sendIdent);
        Timer(const Duration(seconds: 2), _sendConfig);

        _heartBeatTimer = Timer.periodic(_heartbeatTime, (Timer t) => _sendHeatbeat());
        return;
      case DeviceConnectionState.disconnected:
        scaleService.setState(ScaleState.disconnected);
        log('Acaia Scale disconnected. Destroying');
        // await device.disconnectOrCancelConnection();
        _characteristicsSubscription.cancel();
        _heartBeatTimer.cancel();
        _deviceListener.cancel();
        notifyListeners();
        return;
      default:
        return;
    }
  }
}

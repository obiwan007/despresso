import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' show pow;
import 'dart:typed_data';

import 'package:despresso/devices/abstract_scale.dart';
import 'package:despresso/model/de1shotclasses.dart';
import 'package:logging/logging.dart' as l;
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

///
///Implementation for the Acaia scale models
///Lunar 2021,
///PYXIS
///PEARLS
class AcaiaPyxisScale extends ChangeNotifier implements AbstractScale {
  final log = l.Logger('AcaiaPyxisScale');
  // ignore: non_constant_identifier_names
  static Uuid ServiceUUID = Platform.isAndroid
      ? Uuid.parse('49535343-FE7D-4AE5-8FA9-9FAFD205E455')
      : Uuid.parse('49535343-FE7D-4AE5-8FA9-9FAFD205E455');

  /// Command
  static Uuid characteristicCommandUUID = Platform.isAndroid
      ? Uuid.parse('49535343-8841-43F4-A8D4-ECBE34729BB3')
      : Uuid.parse('49535343-8841-43F4-A8D4-ECBE34729BB3');

  /// Command
  static Uuid characteristicStatusUUID = Platform.isAndroid
      ? Uuid.parse('49535343-1E4D-4BD9-BA61-23C647249616')
      : Uuid.parse('49535343-1E4D-4BD9-BA61-23C647249616');

  late ScaleService scaleService;

  static const _heartbeatTime = Duration(seconds: 3);
  static const List<int> _heartbeatPayload = [0x02, 0x00];
  static const List<int> _identPayload = [
    0x2D,
    0x2D,
    0x2D,
    0x2D,
    0x2D,
    0x2D,
    0x2D,
    0x2D,
    0x2D,
    0x2D,
    0x2D,
    0x2D,
    0x2D,
    0x2D,
    0x2D,
  ];

  static const List<int> _configPayload = [
    9, // length
    0, // weight
    2, // weight argument
    1, // battery
    3, // battery argument
    2, // timer
    1, // timer argument
    3, // key
    4, // setting
  ];

  static const int header1 = 0xef;
  static const int header2 = 0xdd;

  final DiscoveredDevice device;

  late DeviceConnectionState _state;

  List<int> commandBuffer = [];
  Timer? _heartBeatTimer;
  final flutterReactiveBle = FlutterReactiveBle();

  late StreamSubscription<ConnectionStateUpdate> _deviceListener;

  late StreamSubscription<List<int>> _characteristicsSubscription;

  AcaiaPyxisScale(this.device) {
    scaleService = getIt<ScaleService>();
    log.info("Connect to Acaia");
    scaleService.setScaleInstance(this);
    _deviceListener = flutterReactiveBle.connectToDevice(id: device.id).listen((connectionState) {
      // Handle connection state updates
      log.info('Peripheral ${device.name} connection state is $connectionState');
      _onStateChange(connectionState.connectionState);
    }, onError: (Object error) {
      // Handle a possible error
    });

    // device
    //     .observeConnectionState(
    //         emitCurrentValue: false, completeOnDisconnect: true)
    //     .listen((connectionState) {
    //   log.info('Peripheral ${device.identifier} connection state is $connectionState');
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
    var l = Uint8List.fromList(buffer);
    log.info("Sending: ${l.length} ${Helper.toHex(l)}");
    return l;
  }

  void parsePayload(int type, List<int> payload) {
    if (type != 12) log.info('Acaia: $type');
    switch (type) {
      case 12:
        var subType = payload[0];
        //log.info('Acaia: $type $subType');
        if (subType != 5) {}
        switch (subType) {
          case 12: // weight
          case 5: // weight
            double weight = decodeWeight(payload);
            scaleService.setWeight(weight);
            break;
          case 8: // Tara done
            scaleService.setTara();
            break;
          case 7:
            double time = decodeTime(payload.sublist(2));
            // log.fine("Time Response:  $time");
            break;
          case 11: // Heartbeat
            var weight = 0.0;
            var time = 0.0;

            if (payload[3] == 5) weight = decodeWeight(payload.sublist(3));
            if (payload[3] == 7) time = decodeTime(payload.sublist(3));
            // scaleService.setWeight(weight);
            scaleService.setWeight(weight);
            log.finer("Heartbeat Response: Weight: PL3: ${payload[3]} $weight Time: $time ${payload.sublist(3)}");
            break;
          default:
            log.fine('Acaia: 12 Subtype $subType');
            break;
        }

        break;
      // General Status including battery
      case 8:
        var batteryLevel = commandBuffer[4];
        log.info('Got status message, battery= $batteryLevel');
        scaleService.setBattery(batteryLevel);
        break;
      default:
        log.info('Unparsed acaia response: $type');
    }
  }

  double decodeTime(List<int> payload) {
    double value = (payload[0] & 0xff) * 60;
    value = value + (payload[1]);
    value = value + (payload[2] / 10.0);
    return value;
  }

  double decodeWeight(List<int> payload) {
    if (payload.length < 7) return 0;
    var temp =
        ((payload[4] & 0xff) << 24) + ((payload[3] & 0xff) << 16) + ((payload[2] & 0xff) << 8) + (payload[1] & 0xff);
    var unit = payload[5] & 0xFF;

    var weight = temp / pow(10, unit);
    if ((payload[6] & 0x02) != 0) {
      weight *= -1.0;
    }
    return weight;
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

  Future<void> _sendHeatbeat() async {
    if (_state != DeviceConnectionState.connected) {
      log.info('Disconnected from acaia scale. Not sending heartbeat');

      scaleService.setState(ScaleState.disconnected);
      scaleService.setBattery(0);
      return;
    }
    final characteristic = QualifiedCharacteristic(
        serviceId: ServiceUUID, characteristicId: characteristicCommandUUID, deviceId: device.id);

    try {
      await flutterReactiveBle.writeCharacteristicWithoutResponse(characteristic,
          value: encode(0x00, _heartbeatPayload));
    } catch (e) {
      log.severe("Heartbeat failure $e");
    }
  }

  Future<void> _sendIdent() async {
    if (_state != DeviceConnectionState.connected) {
      log.info('Disconnected from acaia scale. Not sending ident');

      scaleService.setState(ScaleState.disconnected);
      return;
    }

    final characteristic = QualifiedCharacteristic(
        serviceId: ServiceUUID, characteristicId: characteristicCommandUUID, deviceId: device.id);
    await flutterReactiveBle.writeCharacteristicWithoutResponse(characteristic, value: encode(0x0b, _identPayload));

    // device.writeCharacteristic(
    //     ServiceUUID, CharateristicUUID, encode(0x0b, _identPayload), false);
    log.info('Ident payload: ${encode(0x0b, _identPayload)}');
  }

  Future<void> _sendConfig() async {
    if (_state != DeviceConnectionState.connected) {
      log.info('Disconnected from acaia scale. Not sending config');
      scaleService.setState(ScaleState.disconnected);
      return;
    }

    final characteristic = QualifiedCharacteristic(
        serviceId: ServiceUUID, characteristicId: characteristicCommandUUID, deviceId: device.id);
    await flutterReactiveBle.writeCharacteristicWithoutResponse(characteristic, value: encode(0x0c, _configPayload));

    // device.writeCharacteristic(
    //     ServiceUUID, CharateristicUUID, encode(0x0c, _configPayload), false);
    log.info('Config payload: ${encode(0x0c, _configPayload)}');
  }

  @override
  writeTare() async {
    // tare command
    var list = [
      0x00,
    ];

    final characteristic = QualifiedCharacteristic(
        serviceId: ServiceUUID, characteristicId: characteristicCommandUUID, deviceId: device.id);
    try {
      await flutterReactiveBle.writeCharacteristicWithoutResponse(characteristic, value: encode(0x04, list));

      await _sendConfig();
      log.info("tara send Ok");
    } catch (e) {
      log.severe("tara failed $e");
    }
  }

  Future<void> writeToAcaia(Uint8List payload) async {
    log.info("Sending to Acaia");
    final characteristic = QualifiedCharacteristic(
        serviceId: ServiceUUID, characteristicId: characteristicCommandUUID, deviceId: device.id);
    return await flutterReactiveBle.writeCharacteristicWithResponse(characteristic, value: payload);
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

        registerForNotifications();
        await Future.delayed(
          const Duration(seconds: 1),
          () async {
            try {} catch (e) {
              log.severe("Error in config scale $e");
            }
          },
        );
        await Future.delayed(
          const Duration(milliseconds: 1000),
          () async {
            try {
              await _sendIdent();
            } catch (e) {
              log.severe("Error in config scale $e");
            }
          },
        );

        await Future.delayed(
          const Duration(seconds: 1),
          () async {
            try {
              await _sendConfig();
            } catch (e) {
              log.severe("Error in config scale $e");
            }
          },
        );
        // await Future.delayed(
        //   const Duration(seconds: 1),
        //   () async {
        //     _heartBeatTimer = Timer.periodic(_heartbeatTime, (Timer t) => _sendHeatbeat());
        //     //
        //   },
        // );
        // heartBeatTimer = Timer.periodic(_heartbeatTime, (Timer t) => _sendHeatbeat());
        // Timer(const Duration(seconds: 3), _sendIdent);
        // Timer(const Duration(seconds: 5), _sendConfig);

        return;
      case DeviceConnectionState.disconnected:
        scaleService.setState(ScaleState.disconnected);
        scaleService.setBattery(0);
        log.info('Acaia Scale disconnected. Destroying');
        _characteristicsSubscription.cancel();
        if (_heartBeatTimer != null) _heartBeatTimer!.cancel();
        _deviceListener.cancel();
        notifyListeners();
        return;
      default:
        return;
    }
  }

  void registerForNotifications() {
    final characteristic = QualifiedCharacteristic(
        serviceId: ServiceUUID, characteristicId: characteristicStatusUUID, deviceId: device.id);

    _characteristicsSubscription = flutterReactiveBle.subscribeToCharacteristic(characteristic).listen((data) {
      // code to handle incoming data
      try {
        _notificationCallback(data);
      } catch (e) {
        log.severe("Handling notification failed $e");
      }
    }, onError: (dynamic error) {
      // code to handle errors
      log.severe("Subscribe to $characteristic failed: $error");
    });
  }
}
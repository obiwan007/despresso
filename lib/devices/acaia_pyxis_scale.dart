import 'dart:async';
import 'dart:math' show pow;
import 'dart:typed_data';

import 'package:despresso/devices/abstract_comm.dart';
import 'package:despresso/devices/abstract_scale.dart';
import 'package:despresso/model/de1shotclasses.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:logging/logging.dart' as l;
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

int instances = 0;

///
///Implementation for the Acaia scale models
///Lunar 2021,
///PYXIS
///PEARLS
class AcaiaPyxisScale extends ChangeNotifier implements AbstractScale {
  var log = l.Logger('AcaiaPyxisScale');

  int _sequence = 1;
  // ignore: non_constant_identifier_names
  static Uuid ServiceUUID = useLongCharacteristics()
      ? Uuid.parse('49535343-FE7D-4AE5-8FA9-9FAFD205E455')
      : Uuid.parse('49535343-FE7D-4AE5-8FA9-9FAFD205E455');

  /// Command
  static Uuid characteristicCommandUUID = useLongCharacteristics()
      ? Uuid.parse('49535343-8841-43F4-A8D4-ECBE34729BB3')
      : Uuid.parse('49535343-8841-43F4-A8D4-ECBE34729BB3');

  /// Command
  static Uuid characteristicStatusUUID = useLongCharacteristics()
      ? Uuid.parse('49535343-1E4D-4BD9-BA61-23C647249616')
      : Uuid.parse('49535343-1E4D-4BD9-BA61-23C647249616');

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

// 0001 0102 0205 0304
  static const List<int> _configPayload = [
    9, // length
    0, // weight
    1, // weight argument
    1, // battery
    2, // battery argument
    2, // timer
    5, // timer argument
    3, // key
    4 // settingg
  ];
  // 00 01 01 02 02 01 03 04
  static const int header1 = 0xef;
  static const int header2 = 0xdd;

  final DiscoveredDevice device;

  DeviceConnectionState _state = DeviceConnectionState.disconnected;

  List<int> commandBuffer = [];
  Timer? _heartBeatTimer;

  late StreamSubscription<ConnectionStateUpdate> _deviceListener;

  StreamSubscription<List<int>>? _characteristicsSubscription;

  DateTime _lastResponse = DateTime.now();
  int instance = 0;
  DeviceCommunication connection;

  int index = 0;

  AcaiaPyxisScale(this.device, this.connection) {
    instances++;
    instance = instances;
    log = l.Logger('AcaiaPyxisScale $instance');
    scaleService = getIt<ScaleService>();

    index = getScaleIndex(device.id);

    log.info("Connect to Acaia");
    scaleService.setScaleInstance(this, index);
    init();
    // device
    //     .observeConnectionState(
    //         emitCurrentValue: false, completeOnDisconnect: true)
    //     .listen((connectionState) {
    //   log.info('Peripheral ${device.identifier} connection state is $connectionState');
    //   _onStateChange(connectionState);
    // });
    // device.connect();
  }

  init() async {
    _deviceListener = connection.connectToDevice(id: device.id).listen((connectionState) {
      // Handle connection state updates
      log.info('Peripheral ${device.name} connection state is $connectionState');
      _onStateChange(connectionState.connectionState);
    }, onError: (Object error) {
      // Handle a possible error
    });
  }

  @override
  void dispose() {
    super.dispose();
    _deviceListener.cancel();
    log.info('Disposed AcaiaPyxisScale');
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
    log.info("encode Sending: ${l.length} ${Helper.toHex(l)}");

    return l;
  }

  void parsePayload(int type, List<int> payload) {
    if (type != 12) log.info('Acaia: $type');
    switch (type) {
      case 12:
        var subType = payload[0];

        if (subType != 5) {
          // log.info('Acaia: $type Sub: $subType');
        }
        switch (subType) {
          case 12: // weight
          case 5: // weight
            double? weight = decodeWeight(payload);
            if (weight != null) scaleService.setWeight(weight, index);
            _lastResponse = DateTime.now();
            break;
          case 8: // Tara done

            scaleService.setTara();
            if (payload[0] == 0 && payload[1] == 5) {
              var weight = decodeWeight(payload.sublist(2));
              log.info("Tare received $weight ${Helper.toHex(Uint8List.fromList(payload))}");
            }

            break;
          case 7:
            double time = decodeTime(payload.sublist(2));

            log.info("time: $time");
            break;
          case 11: // Heartbeat

            if (payload[3] == 5) {
              var w = decodeWeight(payload.sublist(3));
              if (w != null) scaleService.setWeight(w, index);
            }
            // if (payload[3] == 7) time = decodeTime(payload.sublist(3));

            log.fine("Heartbeat Response: PL3: ${payload[3]} ${payload.sublist(3)}");

            break;
          default:
            log.fine('Acaia: 12 Subtype $subType');
            break;
        }

        break;
      case 7:
        log.info("Tare 7 received: ${Helper.toHex(Uint8List.fromList(payload))}");

        break;
      // General Status including battery
      case 8:
        var batteryLevel = commandBuffer[4];
        log.info('Got status message, battery= $batteryLevel');
        scaleService.setBattery(batteryLevel, index);
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

  double? decodeWeight(List<int> payload) {
    if (payload.length < 7) return null;
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
    // log.info("received: ${Helper.toHex(Uint8List.fromList(commandBuffer))}");
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

  Future<void> _heartbeat() async {
    if (_heartBeatTimer == null) return;
    if (_state != DeviceConnectionState.connected) {
      log.info('Disconnected from acaia scale. Not sending heartbeat');

      scaleService.setState(ScaleState.disconnected, index);
      scaleService.setBattery(0, index);
      return;
    }

    var now = DateTime.now().difference(_lastResponse).inMilliseconds;

    if (now > 3400) {
      log.info('Last Heartbeat $now');
      log.severe('Init disconnection');
      _onStateChange(DeviceConnectionState.disconnected);

      return;
    }

    await _sendHeartbeat();
    await _sendConfig();
  }

  Future<void> _sendHeartbeat() async {
    try {
      log.info("Send Heartbeat");
      // await _sendIdent();
      final characteristic = QualifiedCharacteristic(
          serviceId: ServiceUUID, characteristicId: characteristicCommandUUID, deviceId: device.id);
      await connection.writeCharacteristicWithResponse(characteristic, value: encode(0x00, _heartbeatPayload));
    } catch (e) {
      log.severe("Heartbeat failure $e");
    }
  }

  Future<void> _sendIdent() async {
    if (_state != DeviceConnectionState.connected) {
      log.info('Disconnected from acaia scale. Not sending ident');

      scaleService.setState(ScaleState.disconnected, index);
      return;
    }

    final characteristic = QualifiedCharacteristic(
        serviceId: ServiceUUID, characteristicId: characteristicCommandUUID, deviceId: device.id);
    await connection.writeCharacteristicWithoutResponse(characteristic, value: encode(0x0b, _identPayload));
  }

  Future<void> _sendConfig() async {
    if (_state != DeviceConnectionState.connected) {
      log.info('Disconnected from acaia scale. Not sending config');
      scaleService.setState(ScaleState.disconnected, index);
      return;
    }
    log.info('Send config');
    final characteristic = QualifiedCharacteristic(
        serviceId: ServiceUUID, characteristicId: characteristicCommandUUID, deviceId: device.id);
    await connection.writeCharacteristicWithoutResponse(characteristic, value: encode(0x0c, _configPayload));
  }

  @override
  writeTare() async {
    // tare command

    var list = [
      0x00,
      00,
      00,
      00,
      00,
      00,
      00,
      00,
      00,
      00,
      00,
      00,
      00,
      00,
      00,
    ];

    final characteristic = QualifiedCharacteristic(
        serviceId: ServiceUUID, characteristicId: characteristicCommandUUID, deviceId: device.id);
    try {
      await connection.writeCharacteristicWithoutResponse(characteristic, value: encode(0x04, list));
      await ack();
      // await _sendConfig();
      log.info("tara send Ok");
    } catch (e) {
      log.severe("tara failed $e");
    }
    // Future.delayed(Duration(milliseconds: 100), () async {
    //   await _sendIdent();
    //   return await _sendConfig();
    // });
  }

  // Future<void> writeToAcaia(Uint8List payload) async {
  //   log.info("Sending to Acaia");
  //   final characteristic = QualifiedCharacteristic(
  //       serviceId: ServiceUUID, characteristicId: characteristicCommandUUID, deviceId: device.id);
  //   return await connection.writeCharacteristicWithResponse(characteristic, value: payload);
  // }

  void _onStateChange(DeviceConnectionState state) async {
    log.info('SCALE State changed to $state');
    _state = state;

    switch (state) {
      case DeviceConnectionState.connecting:
        log.info('Connecting');
        scaleService.setState(ScaleState.connecting, index);
        break;

      case DeviceConnectionState.connected:
        log.info('Connected');
        try {
          var mtu = await connection.requestMtu(deviceId: device.id, mtu: 250);
          log.info("AcaiaPyxisScale MTU $mtu");
        } catch (e) {
          log.severe("AcaiaPyxisScale MTU $e");
        }

        scaleService.setState(ScaleState.connected, index);

        _lastResponse = DateTime.now();
        await _sendIdent();
        await _sendConfig();
        registerForNotifications();
        _lastResponse = DateTime.now();
        // Future.delayed(
        //   const Duration(milliseconds: 10),
        //   () async {
        //     try {
        //       if (_state == DeviceConnectionState.connected) {
        //         await _sendIdent();
        //       }
        //     } catch (e) {
        //       log.severe("Error in config scale $e");
        //     }
        //   },
        // );

        // Future.delayed(
        //   const Duration(milliseconds: 50),
        //   () async {
        //     try {
        //       if (_state == DeviceConnectionState.connected) await _sendConfig();
        //     } catch (e) {
        //       log.severe("Error in config scale $e");
        //     }
        //   },
        // );
        // Future.delayed(
        //   const Duration(milliseconds: 1),
        //   () async {
        //     try {
        //       registerForNotifications();
        //     } catch (e) {
        //       log.severe("Error in config scale $e");
        //     }
        //   },
        // );
        Future.delayed(
          const Duration(seconds: 3),
          () {
            log.info("Heartbeat watchdog started");
            if (_state == DeviceConnectionState.connected) {
              _lastResponse = DateTime.now();
              _heartBeatTimer = Timer.periodic(_heartbeatTime, (Timer t) => _heartbeat());
            }

            //
          },
        );
        // _heartBeatTimer = Timer.periodic(_heartbeatTime, (Timer t) => _sendHeatbeat());
        // Timer(const Duration(seconds: 3), _sendIdent);
        // Timer(const Duration(seconds: 5), _sendConfig);

        return;
      case DeviceConnectionState.disconnected:
        log.info('Acaia Scale disconnected. Destroying');
        try {
          if (_heartBeatTimer != null) {
            _heartBeatTimer!.cancel();
            log.info("Timer canceled");
          }
          _heartBeatTimer = null;
          scaleService.setState(ScaleState.disconnected, index);
          scaleService.setBattery(0, index);

          _characteristicsSubscription?.cancel();

          _deviceListener.cancel();
          Future.delayed(const Duration(seconds: 2), () => notifyListeners());
        } catch (e) {
          log.severe("Error shutting down $e");
        }

        return;
      default:
        return;
    }
  }

  Future<void> registerForNotifications() async {
    if (_characteristicsSubscription != null) {
      await _characteristicsSubscription!.cancel();
      log.info("UnRegister for notifications");
    }
    final characteristic = QualifiedCharacteristic(
        serviceId: ServiceUUID, characteristicId: characteristicStatusUUID, deviceId: device.id);

    log.info("Register for notifications");
    _characteristicsSubscription = connection.subscribeToCharacteristic(characteristic).listen((data) {
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

  Future<void> ack() async {
    // await _sendIdent();
    // await _sendHeartbeat();
    await _sendConfig();
  }

  @override
  Future<void> timer(TimerMode start) async {
    final characteristic = QualifiedCharacteristic(
        serviceId: ServiceUUID, characteristicId: characteristicCommandUUID, deviceId: device.id);
    try {
      switch (start) {
        case TimerMode.reset:
          await connection.writeCharacteristicWithoutResponse(characteristic,
              value: encode(0x0d, [(_sequence++ & 0xff), 1]));
          break;
        case TimerMode.start:
          // await connection.writeCharacteristicWithoutResponse(characteristic, value: encode(0x0d, [1]));
          await connection.writeCharacteristicWithoutResponse(characteristic,
              value: encode(0x0d, [(_sequence++ & 0xff), 1]));
          await connection.writeCharacteristicWithoutResponse(characteristic,
              value: encode(0x0d, [(_sequence++ & 0xff), 0]));
          break;
        case TimerMode.stop:
          await connection.writeCharacteristicWithoutResponse(characteristic,
              value: encode(0x0d, [(_sequence++ & 0xff), 2]));
          break;
      }
      await ack();
      log.info("timer send Ok $start");
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

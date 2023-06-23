import 'dart:async';
import 'package:despresso/devices/abstract_comm.dart';
import 'dart:typed_data';

import 'package:despresso/devices/abstract_scale.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'package:logging/logging.dart' as l;

class BlackCoffeeScale extends ChangeNotifier implements AbstractScale {
  final log = l.Logger('BlackCoffeeScale');

  // ignore: non_constant_identifier_names
  static Uuid ServiceUUID =
      useLongCharacteristics() ? Uuid.parse('0000ffb0-0000-1000-8000-00805f9b34fb') : Uuid.parse('fff0');
  // ignore: non_constant_identifier_names
  static Uuid DataUUID =
      useLongCharacteristics() ? Uuid.parse('0000ffb2-0000-1000-8000-00805f9b34fb') : Uuid.parse('fff1');

  late ScaleService scaleService;

  static const int cmdTare = 0;

  final DiscoveredDevice device;

  List<int> commandBuffer = [];
  double weightAtTare = 0.00; // this is a workaround for the missing taring function
  double weightFromScale = 0.00;

  late StreamSubscription<ConnectionStateUpdate> _deviceListener;

  late StreamSubscription<List<int>> _characteristicsSubscription;
  DeviceCommunication connection;

  int index = 0;
  BlackCoffeeScale(this.device, this.connection) {
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
    var weight = getInt(data.sublist(3, 7));
    weightFromScale = weight / 1000;
    if (data[2] >= 128) {
      weightFromScale = weightFromScale * -1;
    }
    scaleService.setWeight(weightFromScale - weightAtTare, index);
  }

  int getInt(List<int> buffer) {
    ByteData bytes = ByteData(buffer.length);
    var i = 0;
    var list = bytes.buffer.asUint8List();
    for (var _ in buffer) {
      list[i] = buffer[i];
      i++;
    }
    return bytes.getInt32(0, Endian.big);
  }

  @override
  writeTare() {
    weightAtTare = weightFromScale;
    return Future(() => null); // the black coffee scale doesn't support ble taring
  }

  Future<void> writeToBlackCoffee(List<int> payload) async {
    log.info("Sending to Smartchef");
    final characteristic =
        QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: DataUUID, deviceId: device.id);
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
        // await device.discoverAllServicesAndCharacteristics();
        final characteristic =
            QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: DataUUID, deviceId: device.id);

        _characteristicsSubscription = connection.subscribeToCharacteristic(characteristic).listen((data) {
          _notificationCallback(data);
        }, onError: (dynamic error) {
          log.severe("Subscribe to $characteristic failed: $error");
        });

        return;
      case DeviceConnectionState.disconnected:
        scaleService.setState(ScaleState.disconnected, index);
        scaleService.setBattery(0, index);
        log.info('Smartchef Scale disconnected. Destroying');
        // await device.disconnectOrCancelConnection();
        _characteristicsSubscription.cancel();

        _deviceListener.cancel();
        notifyListeners();
        return;
      default:
        return;
    }
  }

  @override
  Future<void> timer(TimerMode start) {
    // TODO: implement timer
    throw UnimplementedError();
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

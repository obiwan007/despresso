import 'dart:async';
import 'dart:typed_data';

import 'package:despresso/devices/abstract_comm.dart';
import 'package:despresso/devices/abstract_scale.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'package:logging/logging.dart' as l;

class HiroiaScale extends ChangeNotifier implements AbstractScale {
  final log = l.Logger('HiroiaScale');

  // ignore: non_constant_identifier_names
  static Uuid ServiceUUID =
      useLongCharacteristics() ? Uuid.parse('06c31822-8682-4744-9211-febc93e3bece') : Uuid.parse('1822');
  // ignore: non_constant_identifier_names
  static Uuid DataUUID =
      useLongCharacteristics() ? Uuid.parse('06c31823-8682-4744-9211-febc93e3bece') : Uuid.parse('1823');
  // ignore: non_constant_identifier_names
  static Uuid WriteUUID =
      useLongCharacteristics() ? Uuid.parse('06c31824-8682-4744-9211-febc93e3bece') : Uuid.parse('1824');

  late ScaleService scaleService;

  static const List<int> cmdTare = [0x07, 0x00];

  final DiscoveredDevice device;

  List<int> commandBuffer = [];

  late StreamSubscription<ConnectionStateUpdate> _deviceListener;

  late StreamSubscription<List<int>> _characteristicsSubscription;
  DeviceCommunication connection;

  int index = 0;
  HiroiaScale(this.device, this.connection) {
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
    final mode = data[0];
    final sign = data[6];
    final msw = data[5];
    final lsw = data[4];

    var weight = 256 * msw + lsw;

    if (sign == 255) {
      weight = (65536 - weight) * -1;
    }

    if (mode > 0x08) {
      toggleUnit();
    } else {
      scaleService.setWeight(weight / 10, index);
    }
  }

  @override
  writeTare() {
    return writeToHiroia(cmdTare);
  }

  Future<void> toggleMode() {
    const toggleMode = [0x04, 0x00];
    return writeToHiroia(toggleMode);
  }

  Future<void> toggleUnit() {
    const toggleUnit = [0x0b, 0x00];
    return writeToHiroia(toggleUnit);
  }

  Future<void> writeToHiroia(List<int> payload) async {
    log.info("Sending to Hiroia");
    final characteristic =
        QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: WriteUUID, deviceId: device.id);
    return await connection.writeCharacteristicWithoutResponse(characteristic, value: Uint8List.fromList(payload));
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

        final characteristic =
            QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: DataUUID, deviceId: device.id);

        _characteristicsSubscription = connection.subscribeToCharacteristic(characteristic).listen((data) {
          // code to handle incoming data
          _notificationCallback(data);
        }, onError: (dynamic error) {
          log.severe("Subscribe to $characteristic failed: $error");
        });

        return;
      case DeviceConnectionState.disconnected:
        scaleService.setState(ScaleState.disconnected, index);
        scaleService.setBattery(0, index);
        log.info('Hiroia Scale disconnected. Destroying');
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

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:despresso/devices/abstract_scale.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'package:logging/logging.dart' as l;

class HiroiaScale extends ChangeNotifier implements AbstractScale {
  final log = l.Logger('HiroiaScale');

  // ignore: non_constant_identifier_names
  static Uuid ServiceUUID = Platform.isAndroid ? Uuid.parse('06c31822-8682-4744-9211-febc93e3bece') : Uuid.parse('1822');
  // ignore: non_constant_identifier_names
  static Uuid DataUUID = Platform.isAndroid ? Uuid.parse('06c31823-8682-4744-9211-febc93e3bece') : Uuid.parse('1823');
  // ignore: non_constant_identifier_names
  static Uuid WriteUUID = Platform.isAndroid ? Uuid.parse('06c31824-8682-4744-9211-febc93e3bece') : Uuid.parse('1824');

  late ScaleService scaleService;

  static const List<int> cmdTare = [0x07, 0x00];

  final DiscoveredDevice device;

  late DeviceConnectionState _state;

  List<int> commandBuffer = [];
  final flutterReactiveBle = FlutterReactiveBle();

  late StreamSubscription<ConnectionStateUpdate> _deviceListener;

  late StreamSubscription<List<int>> _characteristicsSubscription;

  HiroiaScale(this.device) {
    scaleService = getIt<ScaleService>();
    scaleService.setScaleInstance(this);
    _deviceListener = flutterReactiveBle.connectToDevice(id: device.id).listen((connectionState) {
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
      scaleService.setWeight(weight / 10);
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
    final characteristic = QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: WriteUUID, deviceId: device.id);
    return await flutterReactiveBle.writeCharacteristicWithoutResponse(characteristic, value: Uint8List.fromList(payload));
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

        final characteristic = QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: DataUUID, deviceId: device.id);

        _characteristicsSubscription = flutterReactiveBle.subscribeToCharacteristic(characteristic).listen((data) {
          // code to handle incoming data
          _notificationCallback(data);
        }, onError: (dynamic error) {
          // code to handle errors
        });

        return;
      case DeviceConnectionState.disconnected:
        scaleService.setState(ScaleState.disconnected);
        log.info('Hiroia Scale disconnected. Destroying');
        _characteristicsSubscription.cancel();

        _deviceListener.cancel();
        notifyListeners();
        return;
      default:
        return;
    }
  }
}

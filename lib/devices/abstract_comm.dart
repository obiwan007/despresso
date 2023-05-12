import 'dart:io';

import 'package:despresso/service_locator.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../model/services/state/settings_service.dart';

abstract class DeviceCommunication {
  Stream<ConnectionStateUpdate> connectToDevice(
      {required String id, Map<Uuid, List<Uuid>>? servicesWithCharacteristicsToDiscover, Duration? connectionTimeout});

  Future<List<int>> readCharacteristic(QualifiedCharacteristic characteristic);
  Future<void> writeCharacteristicWithResponse(QualifiedCharacteristic characteristic, {required List<int> value});
  Future<void> writeCharacteristicWithoutResponse(QualifiedCharacteristic characteristic, {required List<int> value});
  Stream<List<int>> subscribeToCharacteristic(QualifiedCharacteristic characteristic);
  Future<int> requestMtu({required String deviceId, required int mtu});
  BleStatus get status;
  void startScan() {}
}

bool useLongCharacteristics() {
  var service = getIt<SettingsService>();
  bool ch = (service).useCafeHub;
  if (ch) {
    return service.useLongUUID;
  }
  if (Platform.isAndroid) return true;
  return false;
}

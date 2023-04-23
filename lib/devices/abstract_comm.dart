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
  BleStatus get status;
  void startScan() {}
}

bool useLongCharacteristics() {
  bool ch = (getIt<SettingsService>()).useCafeHub;
  if (ch) return true;
  if (Platform.isAndroid) return true;
  return false;
}

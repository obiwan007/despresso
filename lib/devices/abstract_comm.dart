import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

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

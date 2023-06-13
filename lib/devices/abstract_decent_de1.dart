import 'dart:typed_data';

import 'package:despresso/devices/decent_de1.dart';

abstract class IDe1 {
  int usbChargerMode = 0;
  int steamPurgeMode = 1;
  double steamFlow = 2.5;
  void switchOn();
  Future<void> setIdleState();
  Future<void> switchOff();
  Future<void> requestState(De1StateEnum state);
  Future<void> setFlushTimeout(double newTimeout);
  Future<void> setSteamFlow(double newFlow);
  Future<int> getUsbChargerMode();
  Future<void> setFanThreshhold(int t);
  Future<void> setFlowEstimation(double newFlow);
  Future<double> getFlowEstimation();
  Future<double> getSteamFlow();
  Future<int> getFanThreshhold();
  Future<int> getFirmwareBuild();
  Future<int> getSerialNumber();
  Future<int> getGhcInfo();
  Future<int> getGhcMode();
  Future<void> setUsbChargerMode(int t);
  Future<void> setWaterLevelWarning(int t);
  Future<void> setSteamPurgeMode(int t);
  Future<int> getSteamPurgeMode();
  Future<void> updateSettings();
  Future<void> writeWithResult(Endpoint e, Uint8List data);
}

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

bool checkInProgress = false;

Future<void> checkPermissions() async {
  while (checkInProgress) {
    await Future.delayed(const Duration(milliseconds: 100));
    debugPrint("Permission Check in progress");
  }
  debugPrint("Permission Check ready");
  return checkPermissionsHandler();
}

Future<void> checkPermissionsHandler() async {
  // if (Permission.location.serviceStatus.isEnabled == true){
  // var status2 = await Permission.bluetooth.request();
  // var status1 = await Permission.location.request();

// You can request multiple permissions at once.

  checkInProgress = true;
  Map<Permission, PermissionStatus> statuses = await [
    Permission.location,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.storage,
  ].request();
  checkInProgress = false;
  if (!statuses.values.any((element) => element.isDenied)) {
    return;
  }
  return Future.error(Exception('Location permission not granted. Bluetooth is not working now!'));
}

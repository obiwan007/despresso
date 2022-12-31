import 'dart:async';
import 'dart:developer';
// import 'dart:html';
// import 'dart:html';

import 'package:permission_handler/permission_handler.dart';
import 'package:despresso/devices/acaia_scale.dart';
import 'package:despresso/devices/decent_de1.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BLEService extends ChangeNotifier {
  // static BleManager bleManager = BleManager();
  final flutterReactiveBle = FlutterReactiveBle();

  final List<DiscoveredDevice> _devicesList = <DiscoveredDevice>[];

  StreamSubscription<DiscoveredDevice>? _subscription;

  BLEService() {
    init();
  }

  void init() async {
    await _checkPermissions();
    // await bleManager.createClient();

    // bleManager.observeBluetoothState().listen(btStateListener);
    // startScanning();
    startScan();
  }

  // void btStateListener(BluetoothState btState) {
  //   print(btState);
  // }

  void startScan() {
    _devicesList.clear();
    _subscription?.cancel();
    _subscription = flutterReactiveBle.scanForDevices(
        withServices: [], scanMode: ScanMode.lowLatency).listen((device) {
      //code for handling results
      // print('Scanned Peripheral ${device.name}, RSSI ${device.rssi}');
      deviceScanListener(device);
    }, onError: (err) {
      //code for handling error
      print('Scanner Error:' + err?.message?.message);
    });

    Timer(Duration(seconds: 10), () {
      _subscription?.cancel();
    });

    // var _scanSubscription =
    //     bleManager.startPeripheralScan().listen((ScanResult result) {
    //   print('Scanned Peripheral ${result.peripheral.name}, RSSI ${result.rssi}');
    // });
  }

  void deviceScanListener(DiscoveredDevice result) {
    print('Scanned Peripheral ${result..name}, RSSI ${result.rssi}');
    _addDeviceTolist(result);
  }

  List<DiscoveredDevice> get devices => _devicesList;

  void _checkdevice(DiscoveredDevice device) async {
    if (true) {
      log('Removing device');
      _devicesList.remove(device);
      // bleManager.startPeripheralScan().listen(deviceScanListener);
      startScan();
    }
  }

  void _addDeviceTolist(final DiscoveredDevice device) async {
    if (!device.name.isEmpty) {
      if (!_devicesList.map((e) => e.id).contains(device.id)) {
        log('Found Device: ' + device.name);
        if (device.name != null && device.name.startsWith('ACAIA')) {
          log('Creating Acaia Scale!');
          AcaiaScale(device).addListener(() => _checkdevice(device));
        }
        if (device.name != null && device.name.startsWith('DE1')) {
          log('Creating DE1 machine!');
          DE1(device).addListener(() => _checkdevice(device));
        }
        _devicesList.add(device);
        notifyListeners();
      } else {
        log('Ignoring existing device: ${device.name}');
      }
    }
  }

  Future<void> _checkPermissions() async {
    // if (Permission.location.serviceStatus.isEnabled == true){
    // var status2 = await Permission.bluetooth.request();
    // var status1 = await Permission.location.request();

// You can request multiple permissions at once.
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    if (!statuses.values.any((element) => element.isDenied)) {
      return;
    }
    return Future.error(Exception('Location permission not granted'));

    // }else{
    //   return Future.error(Exception('Location permission not granted'));
    // }
  }
}

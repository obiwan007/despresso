import 'dart:async';
import 'dart:developer';
// import 'dart:html';
// import 'dart:html';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:despresso/devices/acaia_scale.dart';
import 'package:despresso/devices/eureka_scale.dart';
import 'package:despresso/devices/decent_de1.dart';

// import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BLEService extends ChangeNotifier {
  // static BleManager bleManager = BleManager();
  final flutterReactiveBle = FlutterReactiveBle();

  final List<DiscoveredDevice> _devicesList = <DiscoveredDevice>[];

  StreamSubscription<DiscoveredDevice>? _subscription;

  bool isScanning = false;

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
    if (isScanning) return;
    isScanning = true;
    // _devicesList.clear();
    _subscription?.cancel();
    notifyListeners();

    _subscription = flutterReactiveBle.scanForDevices(
        withServices: [], scanMode: ScanMode.lowLatency).listen((device) {
      deviceScanListener(device);
    }, onError: (err) {
      // ignore: prefer_interpolation_to_compose_strings
      log('Scanner Error:' + err?.message?.message);
    });

    Timer(const Duration(seconds: 10), () {
      _subscription?.cancel();
      isScanning = false;
      notifyListeners();
    });

    // var _scanSubscription =
    //     bleManager.startPeripheralScan().listen((ScanResult result) {
    //   print('Scanned Peripheral ${result.peripheral.name}, RSSI ${result.rssi}');
    // });
  }

  void deviceScanListener(DiscoveredDevice result) {
    if (kDebugMode) {
      print('Scanned Peripheral ${result..name}, RSSI ${result.rssi}');
    }
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
    if (device.name.isNotEmpty) {
      if (!_devicesList.map((e) => e.id).contains(device.id)) {
        log('Found Device: ${device.name}');
        if (device.name.startsWith('ACAIA') ||
            device.name.startsWith('PROCHBT')) {
          log('Creating Acaia Scale!');
          AcaiaScale(device).addListener(() => _checkdevice(device));
          _devicesList.add(device);
        }
        if (device.name.startsWith('CFS-9002')) {
          log('eureka scale found');
          EurekaScale(device).addListener(() => _checkdevice(device));
          _devicesList.add(device);
        }
        if (device.name.startsWith('DE1')) {
          log('Creating DE1 machine!');
          DE1(device).addListener(() => _checkdevice(device));
          _devicesList.add(device);
        }

        notifyListeners();
      } else {
        if (kDebugMode) {
          print('Ignoring existing device: ${device.name}');
        }
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

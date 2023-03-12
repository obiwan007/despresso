import 'dart:async';

// import 'dart:html';
// import 'dart:html';

import 'package:despresso/devices/decent_scale.dart';
import 'package:despresso/devices/felicita_scale.dart';
import 'package:despresso/devices/meater_thermometer.dart';
import 'package:despresso/devices/skale2_scale.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:despresso/devices/acaia_scale.dart';
import 'package:despresso/devices/eureka_scale.dart';
import 'package:despresso/devices/hiroia_scale.dart';
import 'package:despresso/devices/decent_de1.dart';

// import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart' as ble;

class BLEService extends ChangeNotifier {
  final log = Logger('BLEService');

  // static BleManager bleManager = BleManager();
  final flutterReactiveBle = ble.FlutterReactiveBle();

  final List<ble.DiscoveredDevice> _devicesList = <ble.DiscoveredDevice>[];
  final List<ble.DiscoveredDevice> _devicesIgnoreList = <ble.DiscoveredDevice>[];

  StreamSubscription<ble.DiscoveredDevice>? _subscription;

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
    log.info('startScan');
    _subscription =
        flutterReactiveBle.scanForDevices(withServices: [], scanMode: ble.ScanMode.lowLatency).listen((device) {
      deviceScanListener(device);
    }, onError: (err) {
      // ignore: prefer_interpolation_to_compose_strings
      log.info('Scanner Error:' + err?.message?.message);
    });

    Timer(const Duration(seconds: 10), () {
      _subscription?.cancel();
      log.info('stoppedScan');
      isScanning = false;
      notifyListeners();
    });

    // var _scanSubscription =
    //     bleManager.startPeripheralScan().listen((ScanResult result) {
    //   print('Scanned Peripheral ${result.peripheral.name}, RSSI ${result.rssi}');
    // });
  }

  void deviceScanListener(ble.DiscoveredDevice result) {
    // if (result.name.isNotEmpty) {
    //   log.fine('Scanned Peripheral ${result.name}, ID: ${result.id} RSSI ${result.rssi} ${result.serviceUuids}');
    // }
    _addDeviceTolist(result);
  }

  List<ble.DiscoveredDevice> get devices => _devicesList;

  void _checkdevice(ble.DiscoveredDevice device) async {
    if (true) {
      log.info('Removing device');
      _devicesList.remove(device);
      // bleManager.startPeripheralScan().listen(deviceScanListener);
      startScan();
    }
  }

  void _addDeviceTolist(final ble.DiscoveredDevice device) async {
    if (device.name.isNotEmpty) {
      if (!_devicesIgnoreList.map((e) => e.id).contains(device.id) &&
          !_devicesList.map((e) => e.id).contains(device.id)) {
        log.fine(
            'Found new device: ${device.name} ID: ${device.id} UUIDs: ${device.serviceUuids} RSSI ${device.rssi} ');
        if (device.name.startsWith('ACAIA') || device.name.startsWith('PROCHBT')) {
          log.info('Creating Acaia Scale!');
          AcaiaScale(device).addListener(() => _checkdevice(device));
          _devicesList.add(device);
        } else if (device.name.startsWith('CFS-9002')) {
          log.info('eureka scale found');
          EurekaScale(device).addListener(() => _checkdevice(device));
          _devicesList.add(device);
        } else if (device.name.startsWith('Decent')) {
          log.info('decent scale found');
          DecentScale(device).addListener(() => _checkdevice(device));
          _devicesList.add(device);
        } else if (device.name.startsWith('DE1')) {
          log.info('Creating DE1 machine!');
          DE1(device).addListener(() => _checkdevice(device));
          _devicesList.add(device);
        } else if (device.name.startsWith('MEATER')) {
          log.info('Meater thermometer ');
          MeaterThermometer(device).addListener(() => _checkdevice(device));
          _devicesList.add(device);
        } else if (device.name.startsWith('Skale')) {
          log.info('Skala 2');
          Skale2Scale(device).addListener(() => _checkdevice(device));
          _devicesList.add(device);
        } else if (device.name.startsWith('FELICITA')) {
          log.info('Felicita Scale');
          FelicitaScale(device).addListener(() => _checkdevice(device));
          _devicesList.add(device);
        } else if (device.name.startsWith('HIROIA')) {
          log.info('Hiroia Scale');
          HiroiaScale(device).addListener(() => _checkdevice(device));
          _devicesList.add(device);
        } else {
          _devicesIgnoreList.add(device);
          log.info('Added unknown device');
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

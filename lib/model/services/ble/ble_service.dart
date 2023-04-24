import 'dart:async';

// import 'dart:html';
// import 'dart:html';

import 'package:despresso/devices/acaia_pyxis_scale.dart';
import 'package:despresso/devices/decent_scale.dart';
import 'package:despresso/devices/felicita_scale.dart';
import 'package:despresso/devices/meater_thermometer.dart';
import 'package:despresso/devices/skale2_scale.dart';
import 'package:despresso/helper/permissioncheck.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:despresso/devices/acaia_scale.dart';
import 'package:despresso/devices/eureka_scale.dart';
import 'package:despresso/devices/hiroia_scale.dart';
import 'package:despresso/devices/decent_de1.dart';

// import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart' as ble;

import '../../../devices/abstract_comm.dart';

class BLEService extends ChangeNotifier implements DeviceCommunication {
  final log = Logger('BLEService');

  // static BleManager bleManager = BleManager();
  final flutterReactiveBle = ble.FlutterReactiveBle();

  final List<ble.DiscoveredDevice> _devicesList = <ble.DiscoveredDevice>[];
  final List<ble.DiscoveredDevice> _devicesIgnoreList = <ble.DiscoveredDevice>[];
  late SettingsService _settings;
  StreamSubscription<ble.DiscoveredDevice>? _subscription;

  bool isScanning = false;

  String error = "";

  bool _useCafeHub = false;

  BLEService() {
    _settings = getIt<SettingsService>();
    _settings.addListener(
      () {
        if (_settings.useCafeHub != _useCafeHub) {
          _useCafeHub = _settings.useCafeHub;
          init();
        }
      },
    );
    init();
  }

  void init() async {
    if (_settings.useCafeHub) {
      log.info("BLE is deactivated");
      return;
    }
    log.info("BLE trying to connect");
    await checkPermissions();
    // await bleManager.createClient();

    // bleManager.observeBluetoothState().listen(btStateListener);
    // startScanning();
    startScan();
  }

  // void btStateListener(BluetoothState btState) {
  //   print(btState);
  // }

  @override
  void startScan() {
    if (isScanning) {
      log.info("Already scanning");
      return;
    }

    isScanning = true;
    // _devicesList.clear();
    if (_subscription != null) _subscription?.cancel();

    log.info('startScan');
    ScaleService scaleService = getIt<ScaleService>();
    if (scaleService.state != ScaleState.connected) {
      scaleService.setState(ScaleState.connecting);
    }
    _subscription =
        flutterReactiveBle.scanForDevices(withServices: [], scanMode: ble.ScanMode.lowLatency).listen((device) {
      deviceScanListener(device);
    }, onError: (err) {
      // ignore: prefer_interpolation_to_compose_strings
      log.info('Scanner Error:' + err?.message?.message);
      error = err.message?.message;
      notifyListeners();
    });

    Timer(const Duration(seconds: 30), () {
      _subscription?.cancel();
      log.info('stoppedScan');
      _subscription = null;
      isScanning = false;
      if (scaleService.state == ScaleState.connecting) {
        // scaleService.setState(ScaleState.disconnected);
      }
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
      _devicesIgnoreList.remove(device);
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
          AcaiaScale(device, this).addListener(() => _checkdevice(device));
          _devicesList.add(device);
        } else if (device.name.startsWith('PEARLS') ||
            device.name.startsWith('LUNAR') ||
            device.name.startsWith('PYXIS')) {
          log.info('Creating AcaiaPYXIS Scale!');
          AcaiaPyxisScale(device, this).addListener(() => _checkdevice(device));
          _devicesList.add(device);
        } else if (device.name.startsWith('CFS-9002')) {
          log.info('eureka scale found');
          EurekaScale(device, this).addListener(() => _checkdevice(device));
          _devicesList.add(device);
        } else if (device.name.startsWith('Decent')) {
          log.info('decent scale found');
          DecentScale(device, this).addListener(() => _checkdevice(device));
          _devicesList.add(device);
        } else if (device.name.startsWith('DE1')) {
          log.info('Creating DE1 machine!');
          DE1(device, this).addListener(() => _checkdevice(device));
          _devicesList.add(device);
        } else if (device.name.startsWith('MEATER')) {
          log.info('Meater thermometer ');
          MeaterThermometer(device, this).addListener(() => _checkdevice(device));
          _devicesList.add(device);
        } else if (device.name.startsWith('Skale')) {
          log.info('Skala 2');
          Skale2Scale(device, this).addListener(() => _checkdevice(device));
          _devicesList.add(device);
        } else if (device.name.startsWith('FELICITA')) {
          log.info('Felicita Scale');
          FelicitaScale(device, this).addListener(() => _checkdevice(device));
          _devicesList.add(device);
        } else if (device.name.startsWith('HIROIA')) {
          log.info('Hiroia Scale');
          HiroiaScale(device, this).addListener(() => _checkdevice(device));
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

  @override
  Stream<ble.ConnectionStateUpdate> connectToDevice(
      {required String id,
      Map<ble.Uuid, List<ble.Uuid>>? servicesWithCharacteristicsToDiscover,
      Duration? connectionTimeout}) {
    return flutterReactiveBle.connectToDevice(
        id: id,
        servicesWithCharacteristicsToDiscover: servicesWithCharacteristicsToDiscover,
        connectionTimeout: connectionTimeout);
  }

  @override
  Future<List<int>> readCharacteristic(ble.QualifiedCharacteristic characteristic) {
    return flutterReactiveBle.readCharacteristic(characteristic);
  }

  @override
  Stream<List<int>> subscribeToCharacteristic(ble.QualifiedCharacteristic characteristic) {
    return flutterReactiveBle.subscribeToCharacteristic(characteristic);
  }

  @override
  Future<void> writeCharacteristicWithResponse(ble.QualifiedCharacteristic characteristic, {required List<int> value}) {
    return flutterReactiveBle.writeCharacteristicWithResponse(characteristic, value: value);
  }

  @override
  Future<void> writeCharacteristicWithoutResponse(ble.QualifiedCharacteristic characteristic,
      {required List<int> value}) {
    return flutterReactiveBle.writeCharacteristicWithoutResponse(characteristic, value: value);
  }

  @override
  // TODO: implement status
  ble.BleStatus get status => flutterReactiveBle.status;
}

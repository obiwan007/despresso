import 'dart:async';

// import 'dart:html';
// import 'dart:html';

import 'package:collection/collection.dart';
import 'package:despresso/devices/acaia_pyxis_scale.dart';
import 'package:despresso/devices/decent_scale.dart';
import 'package:despresso/devices/difluid_r2_refractometer.dart';
import 'package:despresso/devices/difluid_scale.dart';
import 'package:despresso/devices/felicita_scale.dart';
import 'package:despresso/devices/ibraai_thermometer.dart';
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
import 'package:despresso/devices/blackcoffee_scale.dart';
import 'package:despresso/devices/bookoo_scale.dart';
import 'package:despresso/devices/decent_de1.dart';

// import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart' as ble;

import '../../../devices/abstract_comm.dart';
import 'package:despresso/devices/smartchef_scale.dart';

class BLEService extends ChangeNotifier implements DeviceCommunication {
  final log = Logger('BLEService');

  // static BleManager bleManager = BleManager();
  final flutterReactiveBle = ble.FlutterReactiveBle();

  final List<ble.DiscoveredDevice> _devicesList = <ble.DiscoveredDevice>[];
  final List<ble.DiscoveredDevice> _scalesList = <ble.DiscoveredDevice>[];
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
    if (scaleService.state[0] != ScaleState.connected) {
      scaleService.setState(ScaleState.connecting, 0);
    }
    if (scaleService.state[1] != ScaleState.connected) {
      scaleService.setState(ScaleState.connecting, 1);
    }
    _subscription =
        flutterReactiveBle.scanForDevices(withServices: [], scanMode: ble.ScanMode.lowLatency).listen((device) async {
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
      if (scaleService.state[0] == ScaleState.connecting) {
        scaleService.setState(ScaleState.disconnected, 0);
      }
      if (scaleService.state[1] == ScaleState.connecting) {
        scaleService.setState(ScaleState.disconnected, 1);
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

  List<ble.DiscoveredDevice> get scales => _scalesList;

  void _checkdevice(ble.DiscoveredDevice device) async {
    if (true) {
      log.info('Removing device');
      _devicesList.remove(device);
      _devicesIgnoreList.remove(device);
      // bleManager.startPeripheralScan().listen(deviceScanListener);
      startScan();
    }
  }

  bool shouldBeAdded(ble.DiscoveredDevice device) {
    var scaleService = getIt<ScaleService>();
    if (isSupportedScale(device) && _scalesList.firstWhereOrNull((element) => element.id == device.id) == null) {
      _scalesList.add(device);
    }

// Add any scale if nothing was configured.
    if (_settings.scalePrimary.isEmpty && _settings.scaleSecondary.isEmpty && scaleService.scaleInstances[0] == null) {
      return true;
    }
    if (scaleService.scaleInstances[0] == null && device.id == _settings.scalePrimary) {
      return true;
    }
    if (scaleService.scaleInstances[1] == null && device.id == _settings.scaleSecondary) {
      return true;
    }

    return false;
  }

  static isSupportedScale(ble.DiscoveredDevice device) {
    if (device.name.startsWith('ACAIA') || device.name.startsWith('PROCHBT')) {
      return true;
    } else if (device.name.startsWith('PEARLS') || device.name.startsWith('LUNAR') || device.name.startsWith('PYXIS')) {
      return true;
    } else if (device.name.startsWith('CFS-9002')) {
      return true;
    } else if (device.name.startsWith('Decent')) {
      return true;
    } else if (device.name.startsWith('Skale')) {
      return true;
    } else if (device.name.startsWith('FELICITA')) {
      return true;
    } else if (device.name.startsWith('HIROIA')) {
      return true;
    } else if (device.name.startsWith('smartchef')) {
      return true;
    } else if (device.name.startsWith('Blackcoffee')) {
      return true;
    } else if (device.name.startsWith('BOOKOO_SC')) {
      return true;
    } else if (device.name.startsWith('Microbalance')) {
      return true;
    } else {
      return false;
    }
  }

  void _addDeviceTolist(final ble.DiscoveredDevice device) async {
    if (device.name.isNotEmpty) {
      if (!_devicesIgnoreList.map((e) => e.id).contains(device.id) &&
          !_devicesList.map((e) => e.id).contains(device.id)) {
        log.fine(
            'Found new device: ${device.name} ID: ${device.id} UUIDs: ${device.serviceUuids} RSSI ${device.rssi} ');

        if (device.name.startsWith('DE1')) {
          log.info('Creating DE1 machine!');
          DE1(device, this).addListener(() => _checkdevice(device));
          _devicesList.add(device);
        } else if (device.name.startsWith('MEATER')) {
          log.info('Meater thermometer ');
          MeaterThermometer(device, this).addListener(() => _checkdevice(device));
          _devicesList.add(device);
        }

// Check for Scales only if they already added or not

        if (!shouldBeAdded(device)) return;

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
        } else if (device.name.startsWith('smartchef')) {
          log.info('Smartchef Scale');
          SmartchefScale(device, this).addListener(() => _checkdevice(device));
          _devicesList.add(device);
        } else if (device.name.startsWith('Blackcoffee.io')) {
          log.info('BlackCoffee Scale');
          BlackCoffeeScale(device, this).addListener(() => _checkdevice(device));
          _devicesList.add(device);
        } else if (device.name.startsWith('BOOKOO_SC')) {
          log.info('Bookoo Scale');
          BookooScale(device, this).addListener(() => _checkdevice(device));
          _devicesList.add(device);
        } else if (device.name.startsWith('DiFluid R2')) {
          log.info('Difluid R2');
          DifluidR2Refractometer(device, this).addListener(() => _checkdevice(device));
        } else if (device.name.startsWith('Microbalance')) {
          log.info('Difluid Scale');
          DifluidScale(device, this).addListener(() => _checkdevice(device));
          _devicesList.add(device);
        } else if (device.name.startsWith('BLE#0x')) {
          log.info('iBraai Thermometer');
          IBraaiThermometer(device, this).addListener(() => _checkdevice(device));
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
  Future<int> requestMtu({required String deviceId, required int mtu}) {
    return flutterReactiveBle.requestMtu(deviceId: deviceId, mtu: mtu);
  }

  @override
  ble.BleStatus get status => flutterReactiveBle.status;
}

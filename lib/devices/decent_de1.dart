import 'dart:async';
import 'dart:collection';
import 'dart:developer';

import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/de1shotclasses.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../model/shotstate.dart';
// import 'package:flutter_ble_lib/flutter_ble_lib.dart';

enum Endpoint {
  versions,
  requestedState,
  setTime,
  shotDirectory,
  readFromMMR,
  writeToMMR,
  shotMapRequest,
  deleteShotRange,
  fwMapRequest,
  temperatures,
  shotSettings,
  deprecatedShotDesc,
  shotSample,
  stateInfo,
  headerWrite,
  frameWrite,
  waterLevels,
  calibration
}

enum De1StateEnum {
  sleep, // 0x0  Everything is off
  goingToSleep, // 0x1
  idle, // 0x2  Heaters are controlled, tank water will be heated if required.
  busy, // 0x3  Firmware is doing something you can't interrupt (eg. cooling down water heater after a shot, calibrating sensors on startup).
  espresso, // 0x4  Making espresso
  steam, // 0x5  Making steam
  hotWater, // 0x6  Making hot water
  shortCal, // 0x7  Running a short calibration
  selfTest, // 0x8  Checking as much as possible within the firmware. Probably only used during manufacture or repair.
  longCal, // 0x9  Long and involved calibration, possibly involving user interaction. (See substates below, for cases like that).
  descale, // 0xA  Descale the whole bang-tooty
  fatalError, // 0xB  Something has gone horribly wrong
  init, // 0xC  Machine has not been run yet
  noRequest, // 0xD  State for T_RequestedState. Means nothing is specifically requested
  skipToNext, // 0xE  In Espresso, skip to next frame. Others, go to Idle if possible
  hotWaterRinse, // 0xF  Produce hot water at whatever temperature is available
  steamRinse, // 0x10 Produce a blast of steam
  refill, // 0x11 Attempting, or needs, a refill.
  clean, // 0x12 Clean group head
  inBootLoader, // 0x13 The main firmware has not run for some reason. Bootloader is active.
  airPurge, // 0x14 Air purge.
  schedIdle, // 0x15 Scheduled wake up idle state
  unknown
}

class DE1 extends ChangeNotifier {
  // ignore: non_constant_identifier_names
  static Uuid ServiceUUID = Uuid.parse('0000A000-0000-1000-8000-00805F9B34FB');

  static var cuuids = {
    '0000A001-0000-1000-8000-00805F9B34FB': Endpoint.versions,
    '0000A002-0000-1000-8000-00805F9B34FB': Endpoint.requestedState,
    '0000A003-0000-1000-8000-00805F9B34FB': Endpoint.setTime,
    '0000A004-0000-1000-8000-00805F9B34FB': Endpoint.shotDirectory,
    '0000A005-0000-1000-8000-00805F9B34FB': Endpoint.readFromMMR,
    '0000A006-0000-1000-8000-00805F9B34FB': Endpoint.writeToMMR,
    '0000A007-0000-1000-8000-00805F9B34FB': Endpoint.shotMapRequest,
    '0000A008-0000-1000-8000-00805F9B34FB': Endpoint.deleteShotRange,
    '0000A009-0000-1000-8000-00805F9B34FB': Endpoint.fwMapRequest,
    '0000A00A-0000-1000-8000-00805F9B34FB': Endpoint.temperatures,
    '0000A00B-0000-1000-8000-00805F9B34FB': Endpoint.shotSettings,
    '0000A00C-0000-1000-8000-00805F9B34FB': Endpoint.deprecatedShotDesc,
    '0000A00D-0000-1000-8000-00805F9B34FB': Endpoint.shotSample,
    '0000A00E-0000-1000-8000-00805F9B34FB': Endpoint.stateInfo,
    '0000A00F-0000-1000-8000-00805F9B34FB': Endpoint.headerWrite,
    '0000A010-0000-1000-8000-00805F9B34FB': Endpoint.frameWrite,
    '0000A011-0000-1000-8000-00805F9B34FB': Endpoint.waterLevels,
    '0000A012-0000-1000-8000-00805F9B34FB': Endpoint.calibration
  };

  static Map<Endpoint, String> cuuidLookup =
      LinkedHashMap.fromEntries(cuuids.entries.map((e) => MapEntry(e.value, e.key)));

  static Map states = {
    0x00: 'sleep', // 0 Everything is off
    0x01: 'going_to_sleep', // 1 Going to sleep
    0x02: 'idle', // 2 Heaters are controlled, tank water will be heated if required.
    0x03:
        'busy', // 3 Firmware is doing something you can't interrupt (eg. cooling down water heater after a shot, calibrating sensors on startup).
    0x04: 'espresso', // 4 Making espresso
    0x05: 'steam', // 5 Making steam
    0x06: 'hot_water', // 6 Making hot water
    0x07: 'short_cal', // 7 Running a short calibration
    0x08:
        'self_test', // 8 Checking as much as possible within the firmware. Probably only used during manufacture or repair.
    0x09:
        'long_cal', // 9 Long and involved calibration, possibly involving user interaction. (See substates below, for cases like that).
    0x0a: 'descale', // A Descale the whole bang-tooty
    0x0b: 'fatal_error', // B Something has gone horribly wrong
    0x0c: 'init', // C Machine has not been run yet
    0x0d: 'no_request', // D State for T_RequestedState. Means nothing is specifically requested
    0x0e: 'skip_to_next', // E In Espresso, skip to next frame. Others, go to Idle if possible
    0x0f: 'hot_water_rinse', // F Produce hot water at whatever temperature is available
    0x10: 'steam_rinse', // 10 Produce a blast of steam
    0x11: 'refill', // 11 Attempting, or needs, a refill.
    0x12: 'clean', // 12 Clean group head
    0x13: 'in_boot_loader', // 13 The main firmware has not run for some reason. Bootloader is active.
    0x14: 'air_purge', // 14 Air purge.
    0x15: 'sched_idle', // 15 Scheduled wake up idle state
  };

  static const Map subStates = {
    0x00: 'no_state', // 0 State is not relevant
    0x01: 'heat_water_tank', // 1 Cold water is not hot enough. Heating hot water tank.
    0x02: 'heat_water_heater', // 2 Warm up hot water heater for shot.
    0x03: 'stabilize_mix_temp', // 3 Stabilize mix temp and get entire water path up to temperature.
    0x04: 'pre_infuse', // 4 Espresso only. Hot Water and Steam will skip this state.
    0x05: 'pour', // 5 Not used in Steam
    0x06: 'flush', // 6 Espresso only, atm
    0x07: 'steaming', // 7 Steam only
    0x08: 'descale_int', // 8 Starting descale
    0x09: 'descale_fill_group', // 9 get some descaling solution into the group and let it sit
    0x0a: 'descale_return', // A descaling internals
    0x0b: 'descale_group', // B descaling group
    0x0c: 'descale_steam', // C descaling steam
    0x0d: 'clean_init', // D Starting clean
    0x0e: 'clean_fill_group', // E Fill the group
    0x0f: 'clean_soak', // F Wait for 60 seconds so we soak the group head
    0x10: 'clean_group', // 10 Flush through group
    0x11: 'paused_refill', // 11 Have we given up on a refill
    0x12: 'paused_steam', // 12 Are we paused in steam?

    200: 'error_nan', // 200 Something died with a NaN
    201: 'error_inf', // 201 Something died with an Inf
    202: 'error_generic', // 202 An error for which we have no more specific description
    203: 'error_acc', // 203 ACC not responding, unlocked, or incorrectly programmed
    204: 'error_tsensor', // 204 We are getting an error that is probably a broken temperature sensor
    205: 'error_psensor', // 205 Pressure sensor error
    206: 'error_wlevel', // 206 Water level sensor error
    207: 'error_dip', // 207 DIP switches told us to wait in the error state.
    208: 'error_assertion', // 208 Assertion failed
    209: 'error_unsafe', // 209 Unsafe value assigned to variable
    210: 'error_invalid_param', // 210 Invalid parameter passed to function
    211: 'error_flash', // 211 Error accessing external flash
    212: 'error_oom', // 212 Could not allocate memory
    213: 'error_deadline', // 213 Realtime deadline missed
  };

  final DiscoveredDevice device;

  EspressoMachineService service = getIt<EspressoMachineService>();
  final flutterReactiveBle = FlutterReactiveBle();

  bool mmrAvailable = true;

  late StreamSubscription<ConnectionStateUpdate> _connectToDeviceSubscription;

  DE1(this.device) {
    // device
    //     .observeConnectionState(
    //         emitCurrentValue: false, completeOnDisconnect: true)
    //     .listen((connectionState) {
    //   log('Peripheral ${device.identifier} connection state is $connectionState');
    //   _onStateChange(connectionState);
    // });
    // device.connect();
    service.setState(EspressoMachineState.connecting);
    _connectToDeviceSubscription = flutterReactiveBle.connectToDevice(id: device.id).listen((connectionState) {
      // Handle connection state updates
      log('DE1 Peripheral ${device.name} connection state is $connectionState');
      _onStateChange(connectionState.connectionState);
    }, onError: (Object error) {
      // Handle a possible error
    });

    service.setDecentInstance(this);
  }

  void enableNotification(Endpoint e, Function(ByteData) callback) {
    log('enabeling Notification for $e (${getCharacteristic(e)})');

    final characteristic =
        QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: getCharacteristic(e), deviceId: device.id);
    flutterReactiveBle.subscribeToCharacteristic(characteristic).listen((data) {
      // Handle connection state updates

      callback(ByteData.sublistView(Uint8List.fromList(data)));
    }, onError: (Object error) {
      // Handle a possible error
    });
    // return device.readCharacteristic(ServiceUUID, getCharacteristic(e));

    // device
    //     .monitorCharacteristic(ServiceUUID, getCharacteristic(e))
    //     .listen((event) {
    //   callback(ByteData.sublistView(event.value));
    // });
  }

  setIdleState() {
    requestState(De1StateEnum.idle);
    log('idleState Requested');
  }

  switchOn() {
    requestState(De1StateEnum.idle);
    log('SwitchOn Requested');
  }

  switchOff() {
    requestState(De1StateEnum.sleep);
    log('SwitchOff Requested');
  }

  requestState(De1StateEnum state) {
    write(Endpoint.requestedState, Uint8List.fromList([state.index]));
  }

  Future<List<int>> read(Endpoint e) {
    final characteristic =
        QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: getCharacteristic(e), deviceId: device.id);
    var data = flutterReactiveBle.readCharacteristic(characteristic);
    // return device.readCharacteristic(ServiceUUID, getCharacteristic(e));
    return data;
  }

  void write(Endpoint e, Uint8List data) {
    final characteristic =
        QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: getCharacteristic(e), deviceId: device.id);
    flutterReactiveBle.writeCharacteristicWithoutResponse(characteristic, value: data);

    // device.writeCharacteristic(ServiceUUID, getCharacteristic(e), data, false);
  }

  Future<void> writeWithResult(Endpoint e, Uint8List data) {
    final characteristic =
        QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: getCharacteristic(e), deviceId: device.id);
    return flutterReactiveBle.writeCharacteristicWithResponse(characteristic, value: data);

    // device.writeCharacteristic(ServiceUUID, getCharacteristic(e), data, false);
  }

  void tempatureNotification(ByteData value) {}
  void stateNotification(ByteData value) {
    var state = value.getUint8(0);
    var subState = value.getUint8(1);

    log("DE1 is in state: ${states[state]} $state substate: ${subStates[subState]}");
    service.setSubState(subStates[subState]);

    switch (state) {
      case 0x00: // 4 Making espresso
        service.setState(EspressoMachineState.sleep);
        break;
      case 0x04: // 4 Making espresso
        service.setState(EspressoMachineState.espresso);
        break;
      case 0x05: // 5 Making steam
        service.setState(EspressoMachineState.steam);
        break;
      case 0x06: // 6 Making hot water
        service.setState(EspressoMachineState.water);
        break;
      case 0x11: // 6 Water empty
        service.setState(EspressoMachineState.refill);
        break;
      case 0x0f: // flush water in grouphead
        service.setState(EspressoMachineState.flush);
        break;
      default:
        service.setState(EspressoMachineState.idle);
        break;
    }
  }

  void requestedState(ByteData value) {
    var state = value.getUint8(0);

    log('DE1 is in requested state: ${states[state]}');
  }

  void waterLevelNotification(ByteData value) {
    var waterlevel = value.getUint16(0);
    var waterThreshold = value.getUint16(2);
    service.setWaterLevel(WaterLevel(waterlevel, waterThreshold));
  }

  void parseVersion(ByteData value) {
    var bleAPIVersion = value.getUint8(0);
    var bleRelease = value.getUint8(1);
    var bleCommits = value.getUint16(2);
    var bleChanges = value.getUint8(4);
    var bleSHA = value.getUint32(5);

    var fwAPIVersion = value.getUint8(9);
    var fwRelease = value.getUint8(10);
    var fwCommits = value.getUint16(11);
    var fwChanges = value.getUint8(13);
    var fwSHA = value.getUint32(14);

    log('bleAPIVersion = ${bleAPIVersion.toRadixString(16)}');
    log('bleRelease = ${bleRelease.toRadixString(16)}');
    log('bleCommits = ${bleCommits.toRadixString(16)}');
    log('bleChanges = ${bleChanges.toRadixString(16)}');
    log('bleSHA = ${bleSHA.toRadixString(16)}');
    log('fwAPIVersion = ${fwAPIVersion.toRadixString(16)}');
    log('fwRelease = ${fwRelease.toRadixString(16)}');
    log('fwCommits = ${fwCommits.toRadixString(16)}');
    log('fwChanges = ${fwChanges.toRadixString(16)}');
    log('fwSHA = ${fwSHA.toRadixString(16)}');
  }

  void shotSampleNotification(ByteData r) {
    var sampleTime = 100 * (r.getUint16(0)) / (50 * 2);
    var groupPressure = r.getUint16(2) / (1 << 12);
    var groupFlow = r.getUint16(4) / (1 << 12);
    var mixTemp = r.getUint16(6) / (1 << 8);
    var headTemp = ((r.getUint8(8) << 16) + (r.getUint8(9) << 8) + (r.getUint8(10))) / (1 << 16);
    var setMixTemp = r.getUint16(11) / (1 << 8);
    var setHeadTemp = r.getUint16(13) / (1 << 8);
    var setGroupPressure = r.getUint8(15) / (1 << 4);
    var setGroupFlow = r.getUint8(16) / (1 << 4);
    var frameNumber = r.getUint8(17);
    var steamTemp = r.getUint8(18);
    // log("$headTemp $setHeadTemp $mixTemp $setMixTemp");
    sampleTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    // log('Sample ' + sampleTime.toString() + " " + frameNumber.toString());
    service.setShot(ShotState(sampleTime, 0, groupPressure, groupFlow, mixTemp, headTemp, setMixTemp, setHeadTemp,
        setGroupPressure, setGroupFlow, frameNumber, steamTemp, 0, ""));
  }

  De1ShotHeaderClass parseShotHeaderSettings(ByteData r) {
    log("Shotheader received");
    var sh = De1ShotHeaderClass();
    var decoded = De1ShotHeaderClass.decodeDe1ShotHeader(r, sh, true);
    if (!decoded) {
      log("Error decoding header");
    }

    service.setShotHeader(sh);
    return sh;
  }

  void parseShotMapRequest(ByteData r) {
    log("parseShotMapRequest received");
  }

  void parseFrameWrite(ByteData r) {
    var sh = De1ShotFrameClass();
    if (De1ShotFrameClass.decodeDe1ShotFrame(r, sh, true) == false) {
      log("Error decoding shot frame");
    }

    service.setShotFrame(sh);
  }

  void parseShotSetting(ByteData r) {
    var steamBits = r.getUint8(0);
    var targetSteamTemp = r.getUint8(1);
    var targetSteamLength = r.getUint8(2);
    var targetWaterTemp = r.getUint8(3);
    var targetWaterVolume = r.getUint8(4);
    var targetWaterLength = r.getUint8(5);
    var targetEspressoVolume = r.getUint8(6);
    var targetGroupTemp = r.getUint16(7) / (1 << 8);

    log('SteamBits = ${steamBits.toRadixString(16)}');
    log('TargetSteamTemp = $targetSteamTemp');
    log('TargetSteamLength = $targetSteamLength');
    log('TargetWaterTemp = $targetWaterTemp');
    log('TargetWaterVolume = $targetWaterVolume');
    log('TargetWaterLength = $targetWaterLength');
    log('TargetEspressoVolume = $targetEspressoVolume');
    log('TargetGroupTemp = $targetGroupTemp');
  }

  String toHexString(int number) => '0x${number.toRadixString(16).padLeft(2, '0')}';

  void mmrNotification(ByteData value) {
    var list = value.buffer.asUint8List();
    if (kDebugMode) {
      print(list.map(toHexString).toList());
    }
    log('mmr received');
  }

  void get ghcMode {
    log('Reading group head control mode');
    mmrRead(0x803820, 0);
  }

  void ghcInstalled() {
    log('Reading whether the group head controller is installed or not');
    mmrRead(0x80381C, 0);
  }

  void mmrRead(int address, int length) {
    log("MMR READ REQUEST");
    if (!mmrAvailable) {
      log('Unable to mmr_read because MMR not available');
      return;
    }
    // 16 byte 00000000000000000000000000000000
    var buffer = List<int>.filled(20, 0, growable: true);
    buffer[0] = (address >> 16) % 0xFF;
    buffer[1] = (address >> 8) % 0xFF;
    buffer[2] = (address) % 0xFF;
    buffer[3] = (length % 0xFF);

    write(Endpoint.readFromMMR, Uint8List.fromList(buffer));
  }

  Future<void> _onStateChange(DeviceConnectionState state) async {
    log('State changed to $state');
    //_state = state;

    switch (state) {
      case DeviceConnectionState.connected:
        // await device.discoverAllServicesAndCharacteristics();
        // Enable notification

        parseVersion(ByteData.sublistView(Uint8List.fromList((await read(Endpoint.versions)))));
        stateNotification(ByteData.sublistView(Uint8List.fromList((await read(Endpoint.stateInfo)))));
        waterLevelNotification(ByteData.sublistView(Uint8List.fromList((await read(Endpoint.waterLevels)))));
        parseShotSetting(ByteData.sublistView(Uint8List.fromList((await read(Endpoint.shotSettings)))));

        // parseShotMapRequest(ByteData.sublistView(
        //     Uint8List.fromList((await read(Endpoint.ShotMapRequest)))));
        parseShotHeaderSettings(ByteData.sublistView(Uint8List.fromList((await read(Endpoint.headerWrite)))));
        parseFrameWrite(ByteData.sublistView(Uint8List.fromList((await read(Endpoint.frameWrite)))));
        parseFrameWrite(ByteData.sublistView(Uint8List.fromList((await read(Endpoint.frameWrite)))));
        parseFrameWrite(ByteData.sublistView(Uint8List.fromList((await read(Endpoint.frameWrite)))));

        enableNotification(Endpoint.requestedState, requestedState);

        enableNotification(Endpoint.temperatures, tempatureNotification);
        enableNotification(Endpoint.waterLevels, waterLevelNotification);
        enableNotification(Endpoint.stateInfo, stateNotification);

        enableNotification(Endpoint.shotSample, shotSampleNotification);
        enableNotification(Endpoint.shotSettings, parseShotSetting);

        enableNotification(Endpoint.shotMapRequest, parseShotMapRequest);
        enableNotification(Endpoint.headerWrite, parseShotHeaderSettings);
        enableNotification(Endpoint.frameWrite, parseFrameWrite);

        enableNotification(Endpoint.readFromMMR, mmrNotification);
        enableNotification(Endpoint.writeToMMR, mmrNotification);

        ghcInstalled();

        return;
      case DeviceConnectionState.disconnected:
        log('de1 disconnected. Destroying');
        _connectToDeviceSubscription.cancel;
        notifyListeners();
        return;
      default:
        return;
    }
  }

  void handleConnect() {}

  Uuid getCharacteristic(Endpoint e) {
    return Uuid.parse(cuuidLookup[e]!);
  }
}

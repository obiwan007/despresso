// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:despresso/devices/abstract_comm.dart';
import 'package:despresso/devices/abstract_decent_de1.dart';
import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/de1shotclasses.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:logging/logging.dart' as l;
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

enum MMRAddrEnum {
  ExternalFlash,
  HWConfig,
  Model,
  CPUBoardModel,
  v13Model,
  CPUFirmwareBuild,
  DebugLen,
  DebugBuffer,
  DebugConfig,
  FanThreshold,
  TankTemp,
  HeaterUp1Flow,
  HeaterUp2Flow,
  WaterHeaterIdleTemp,
  GHCInfo,
  PrefGHCMCI,
  MaxShotPres,
  TargetSteamFlow,
  SteamStartSecs,
  SerialN,
  HeaterV,
  HeaterUp2Timeout,
  CalFlowEst,
  FlushFlowRate,
  FlushTemp,
  FlushTimeout,
  HotWaterFlowRate,
  SteamPurgeMode,
  AllowUSBCharging,
  AppFeatureFlags,
  RefillKitPresent,
}

class DE1 extends ChangeNotifier implements IDe1 {
  final log = l.Logger('DE1');
  // ignore: non_constant_identifier_names
  static Uuid ServiceUUID =
      useLongCharacteristics() ? Uuid.parse('0000A000-0000-1000-8000-00805F9B34FB') : Uuid.parse('A000');

  static var cuuids = useLongCharacteristics()
      ? {
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
        }
      : {
          'A001': Endpoint.versions,
          'A002': Endpoint.requestedState,
          'A003': Endpoint.setTime,
          'A004': Endpoint.shotDirectory,
          'A005': Endpoint.readFromMMR,
          'A006': Endpoint.writeToMMR,
          'A007': Endpoint.shotMapRequest,
          'A008': Endpoint.deleteShotRange,
          'A009': Endpoint.fwMapRequest,
          'A00A': Endpoint.temperatures,
          'A00B': Endpoint.shotSettings,
          'A00C': Endpoint.deprecatedShotDesc,
          'A00D': Endpoint.shotSample,
          'A00E': Endpoint.stateInfo,
          'A00F': Endpoint.headerWrite,
          'A010': Endpoint.frameWrite,
          'A011': Endpoint.waterLevels,
          'A012': Endpoint.calibration
        };

  static Map<Endpoint, String> cuuidLookup =
      LinkedHashMap.fromEntries(cuuids.entries.map((e) => MapEntry(e.value, e.key)));

  static List<List<Object>> mmrList = [
    [0x00000000, MMRAddrEnum.ExternalFlash, 0xFFFFF, "Flash RW"],
    [0x00800000, MMRAddrEnum.HWConfig, 4, "HWConfig"],
    [0x00800004, MMRAddrEnum.Model, 4, "Model"],
    [0x00800008, MMRAddrEnum.CPUBoardModel, 4, "CPU Board Model * 1000. eg: 1100 = 1.1"],
    [
      0x0080000C,
      MMRAddrEnum.v13Model,
      4,
      "v1.3+ Firmware Model (Unset = 0, DE1 = 1, DE1Plus = 2, DE1Pro = 3, DE1XL = 4, DE1Cafe = 5)"
    ],
    [
      0x00800010,
      MMRAddrEnum.CPUFirmwareBuild,
      4,
      "CPU Board Firmware build number. (Starts at 1000 for 1.3, increments by 1 for every build)"
    ],
    [
      0x00802800,
      MMRAddrEnum.DebugLen,
      4,
      "How many characters in debug buffer are valid. Accessing this pauses BLE debug logging."
    ],
    [
      0x00802804,
      MMRAddrEnum.DebugBuffer,
      0x1000,
      "Last 4K of output. Zero terminated if buffer not full yet. Pauses BLE debug logging."
    ],
    [0x00803804, MMRAddrEnum.DebugConfig, 4, "BLEDebugConfig. (Reading restarts logging into the BLE log)"],
    [0x00803808, MMRAddrEnum.FanThreshold, 4, "Fan threshold temp"],
    [0x0080380C, MMRAddrEnum.TankTemp, 4, "Tank water temp threshold."],
    [0x00803810, MMRAddrEnum.HeaterUp1Flow, 4, "HeaterUp Phase 1 Flow Rate"],
    [0x00803814, MMRAddrEnum.HeaterUp2Flow, 4, "HeaterUp Phase 2 Flow Rate"],
    [0x00803818, MMRAddrEnum.WaterHeaterIdleTemp, 4, "Water Heater Idle Temperature"],
    [
      0x0080381C,
      MMRAddrEnum.GHCInfo,
      4,
      "GHC Info Bitmask, 0x1 = GHC LED Controller Present, 0x2 = GHC Touch Controller_Present, 0x4 GHC Active, 0x80000000 = Factory Mode"
    ],
    [0x00803820, MMRAddrEnum.PrefGHCMCI, 4, "TODO"],
    [0x00803824, MMRAddrEnum.MaxShotPres, 4, "TODO"],
    [0x00803828, MMRAddrEnum.TargetSteamFlow, 4, "Target steam flow rate"],
    [
      0x0080382C,
      MMRAddrEnum.SteamStartSecs,
      4,
      "Seconds of high steam flow * 100. Valid range 0.0 - 4.0. 0 may result in an overheated heater. Be careful."
    ],
    [0x00803830, MMRAddrEnum.SerialN, 4, "Current serial number"],
    [0x00803834, MMRAddrEnum.HeaterV, 4, "Nominal Heater Voltage (0, 120V or 230V). +1000 if it's a set value."],
    [0x00803838, MMRAddrEnum.HeaterUp2Timeout, 4, "HeaterUp Phase 2 Timeout"],
    [0x0080383C, MMRAddrEnum.CalFlowEst, 4, "Flow Estimation Calibration"],
    [0x00803840, MMRAddrEnum.FlushFlowRate, 4, "Flush Flow Rate"],
    [0x00803844, MMRAddrEnum.FlushTemp, 4, "Flush Temp"],
    [0x00803848, MMRAddrEnum.FlushTimeout, 4, "Flush Timeout"],
    [0x0080384C, MMRAddrEnum.HotWaterFlowRate, 4, "Hot Water Flow Rate"],
    [0x00803850, MMRAddrEnum.SteamPurgeMode, 4, "Steam Purge Mode"],
    [0x00803854, MMRAddrEnum.AllowUSBCharging, 4, "Allow USB charging"],
    [0x00803858, MMRAddrEnum.AppFeatureFlags, 4, "App Feature Flags"],
    [0x0080385C, MMRAddrEnum.RefillKitPresent, 4, "Refill Kit Present"],
  ];

  Map<MMRAddrEnum, int> mmrAddrLookup =
      LinkedHashMap.fromEntries(mmrList.map((e) => MapEntry(e[1] as MMRAddrEnum, e[0] as int)));

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

  static const Map<int, String> subStates = {
    0x00: 'no_state', // 0 State is not relevant
    0x01: 'heat_water_tank', // 1 Cold water is not hot enough. Heating hot water tank.
    0x02: 'heat_water_heater', // 2 Warm up hot water heater for shot.
    0x03: 'stabilize_mix_temp', // 3 Stabilize mix temp and get entire water path up to temperature.
    0x04: 'pre_infuse', // 4 Espresso only. Hot Water and Steam will skip this state.
    0x05: 'pour', // 5 Not used in Steam
    0x06: 'end', // 6 Espresso only, atm
    0x07: 'steaming', // 7 Steam only
    0x08: 'descale_int', // 8 Starting descale
    0x09: 'descale_fill_group', // 9 get some descaling solution into the group and let it sit
    0x0a: 'descale_return', // A descaling internals
    0x0b: 'descale_group', // B descaling group
    0x0c: 'descale_steam', // C descaling steam
    0x0d: 'clean_init', // D Starting clean
    0x0e: 'clean_fill_group', // E Fill the group
    0x0f: 'clean_soak', // F Wait for 60 seconds so we soak the group head
    0x10: 'clean_group', // 16 Flush through group
    0x11: 'refill', // 17 Have we given up on a refill
    0x12: 'paused_steam', // 18 Are we paused in steam?
    0x13: 'user_not_present',
    0x14: 'puffing',

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
    214: 'error_hi_current', // 214 Measured a current that is out of bounds.
    215: 'error_lo_current', // 215 Not enough current flowing, despite something being turned on
    216: 'error_boot_fill', // 216 Could not get up to pressure during boot pressure test, possibly because no water
    217: 'error_no_ac' // 217 Front button off
  };

  final DiscoveredDevice device;

  EspressoMachineService service = getIt<EspressoMachineService>();
  // final flutterReactiveBle = FlutterReactiveBle();

  bool mmrAvailable = true;

  late StreamSubscription<ConnectionStateUpdate> _connectToDeviceSubscription;

  int fwAPIVersion = 0;

  int fwRelease = 0;

  int fwCommits = 0;

  int fwChanges = 0;

  int fwSHA = 0;
  late StreamController<List<int>> _controllerMmrStream;
  late Stream<List<int>> _streamMMR;

  int ghcInfo = 0;

  int ghcMode = 0;

  int machineSerial = 0;

  int firmware = 0;

  @override
  int usbChargerMode = 0;

  @override
  double steamFlow = 0.5;

  @override
  int steamPurgeMode = 0;

  double flowEstimation = 0;

  late SettingsService _settings;

  bool ghcLEDPresent = false;

  bool ghcTouchPresent = false;

  bool ghcActive = false;
  DeviceCommunication connection;
  DE1(this.device, this.connection) {
    // device
    //     .observeConnectionState(
    //         emitCurrentValue: false, completeOnDisconnect: true)
    //     .listen((connectionState) {
    //   log.info('Peripheral ${device.identifier} connection state is $connectionState');
    //   _onStateChange(connectionState);
    // });
    // device.connect();
    _controllerMmrStream = StreamController<List<int>>();
    _streamMMR = _controllerMmrStream.stream.asBroadcastStream();

    service.setState(EspressoMachineState.connecting);
    _connectToDeviceSubscription = connection.connectToDevice(id: device.id).listen((connectionState) {
      // Handle connection state updates
      log.info('DE1 Peripheral ${device.name} connection state is $connectionState');
      _onStateChange(connectionState.connectionState);
    }, onError: (Object error) {
      // Handle a possible error
    });

    service.setDecentInstance(this);
    _settings = getIt<SettingsService>();
  }

  void _enableNotification(Endpoint e, Function(ByteData) callback) {
    log.info('enableNotification for $e (${getCharacteristic(e)})');

    final characteristic =
        QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: getCharacteristic(e), deviceId: device.id);
    connection.subscribeToCharacteristic(characteristic).listen((data) {
      // Handle connection state updates
      try {
        callback(ByteData.sublistView(Uint8List.fromList(data)));
      } catch (err) {
        log.info("Callback not catched $e $err");
      }
    }, onError: (Object error) {
      // Handle a possible error
      log.info("Error subscribing to $e $error");
    });
  }

  @override
  Future<void> setIdleState() {
    log.info('idleState Requested');
    return requestState(De1StateEnum.idle);
  }

  @override
  Future<void> switchOn() {
    log.info('SwitchOn Requested');
    return requestState(De1StateEnum.idle);
  }

  @override
  Future<void> switchOff() {
    log.info('SwitchOff Requested');
    return requestState(De1StateEnum.sleep);
  }

  @override
  Future<void> requestState(De1StateEnum state) {
    try {
      log.info("RequestState $state");
      return _write(Endpoint.requestedState, Uint8List.fromList([state.index]));
    } catch (e) {
      log.severe("State could not be set $state");
      return Future.error("State set error $e");
    }
  }

  Future<List<int>> _read(Endpoint e) {
    if (connection.status != BleStatus.ready) throw ("de1 not connected ${connection.status}");
    final characteristic =
        QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: getCharacteristic(e), deviceId: device.id);
    var data = connection.readCharacteristic(characteristic);
    // return device.readCharacteristic(ServiceUUID, getCharacteristic(e));
    return data;
  }

  Future<void> _write(Endpoint e, Uint8List data) {
    try {
      if (connection.status != BleStatus.ready) throw ("de1 not connected ${connection.status}");
      final characteristic =
          QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: getCharacteristic(e), deviceId: device.id);
      log.info("encode Sending: ${getCharacteristic(e)}: ${data.length} ${Helper.toHex(data)}");
      return connection.writeCharacteristicWithResponse(characteristic, value: data);
    } catch (e) {
      log.severe("Failing BLE write $e");
      rethrow;
    }

    // device.writeCharacteristic(ServiceUUID, getCharacteristic(e), data, false);
  }

  @override
  Future<void> writeWithResult(Endpoint e, Uint8List data) {
    if (connection.status != BleStatus.ready) throw ("de1 not connected ${connection.status}");
    final characteristic =
        QualifiedCharacteristic(serviceId: ServiceUUID, characteristicId: getCharacteristic(e), deviceId: device.id);
    log.info("encode Sending: ${getCharacteristic(e)}: ${data.length} ${Helper.toHex(data)}");
    return connection.writeCharacteristicWithResponse(characteristic, value: data);

    // device.writeCharacteristic(ServiceUUID, getCharacteristic(e), data, false);
  }

  void _tempatureNotification(ByteData value) {}
  void _stateNotification(ByteData value) {
    var state = value.getUint8(0);
    var subState = value.getUint8(1);

    log.info("DE1 is in state: ${states[state]} $state substate: $subState");
    service.setSubState(subStates[subState] ?? subState.toString());

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
      case 0x0a: // 10 Descaling
        service.setState(EspressoMachineState.descale);
        break;
      case 0x12: // 10 Descaling
        service.setState(EspressoMachineState.clean);
        break;
      case 0x11: // 6 Water empty
        service.setState(EspressoMachineState.refill);
        break;
      case 0x0f: // flush water in grouphead
        service.setState(EspressoMachineState.flush);
        break;
      case 0x14: // pump out water from system
        service.setState(EspressoMachineState.airPurge);
        break;
      default:
        service.setState(EspressoMachineState.idle);
        break;
    }
  }

  void _requestedState(ByteData value) {
    var state = value.getUint8(0);

    log.info('DE1 is in requested state: ${states[state]}');
  }

  void _waterLevelNotification(ByteData value) {
    try {
      var waterlevel = value.getUint16(0, Endian.big);
      var waterThreshold = value.getUint16(2, Endian.big);
      var wl = WaterLevel(waterlevel, waterThreshold);

      if (service.state.water?.waterLimit != waterThreshold) {
        _settings.targetWaterlevel = wl.getLevelRefill();
        log.info("WaterThreshold changed ${_settings.targetWaterlevel}");
      }
      service.setWaterLevel(wl);
    } catch (e) {
      log.severe("waternotify: $e");
    }
  }

  @override
  Future<void> setWaterLevelWarning(int warningLevelVolume) {
    ByteData value = ByteData(4);
    try {
      // 00 00 0c 00
      // 00 00 00 07
      int height = WaterLevel.getLevelFromVolume(warningLevelVolume);
      value.setInt16(0, 0, Endian.big);
      value.setInt16(2, height * 256, Endian.big);

      return writeWithResult(Endpoint.waterLevels, value.buffer.asUint8List());
    } catch (e) {
      log.severe("waternotify: $e");
      rethrow;
    }
  }

  void _parseVersion(ByteData value) {
    var bleAPIVersion = value.getUint8(0);
    var bleRelease = value.getUint8(1);
    var bleCommits = value.getUint16(2);
    var bleChanges = value.getUint8(4);
    var bleSHA = value.getUint32(5);

    fwAPIVersion = value.getUint8(9);
    fwRelease = value.getUint8(10);
    fwCommits = value.getUint16(11);
    fwChanges = value.getUint8(13);
    fwSHA = value.getUint32(14);

    log.info('bleAPIVersion = ${bleAPIVersion.toRadixString(16)}');
    log.info('bleRelease = ${bleRelease.toRadixString(16)}');
    log.info('bleCommits = ${bleCommits.toRadixString(16)}');
    log.info('bleChanges = ${bleChanges.toRadixString(16)}');
    log.info('bleSHA = ${bleSHA.toRadixString(16)}');
    log.info('fwAPIVersion = ${fwAPIVersion.toRadixString(16)}');
    log.info('fwRelease = ${fwRelease.toRadixString(16)}');
    log.info('fwCommits = ${fwCommits.toRadixString(16)}');
    log.info('fwChanges = ${fwChanges.toRadixString(16)}');
    log.info('fwSHA = ${fwSHA.toRadixString(16)}');
  }

  void _shotSampleNotification(ByteData r) {
    try {
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
      // log.info("$headTemp $setHeadTemp $mixTemp $setMixTemp");
      sampleTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
      // log.info('Sample ' + sampleTime.toString() + " " + frameNumber.toString());
      service.setShot(ShotState(sampleTime, 0, groupPressure, groupFlow, mixTemp, headTemp, setMixTemp, setHeadTemp,
          setGroupPressure, setGroupFlow, frameNumber, steamTemp, 0, ""));
    } catch (e) {
      log.severe("shotSampleNotification $e");
    }
  }

  De1ShotHeaderClass _parseShotHeaderSettings(ByteData r) {
    try {
      log.info("Shotheader received");
      var sh = De1ShotHeaderClass();
      var decoded = De1ShotHeaderClass.decodeDe1ShotHeader(r, sh, true);
      if (!decoded) {
        log.info("Error decoding header");
      }

      service.setShotHeader(sh);
      return sh;
    } catch (e) {
      log.severe("parseShotHeaderSettings $e");
      rethrow;
    }
  }

  void _parseShotMapRequest(ByteData r) {
    log.info("parseShotMapRequest received");
  }

  // De1ShotFrameClass _parseFrameWrite(ByteData r) {
  //   log.info("parseFrameWrite: decoding shot frame ${r.buffer.lengthInBytes}");
  //   var sh = De1ShotFrameClass();
  //   if (De1ShotFrameClass.decodeDe1ShotFrame(r, sh, true) == false) {
  //     log.info("Error decoding shot frame");
  //   }

  //   service.setShotFrame(sh);
  //   return sh;
  // }

  void _parseShotSetting(ByteData r) {
    var steamBits = r.getUint8(0);
    var targetSteamTemp = r.getUint8(1);
    var targetSteamLength = r.getUint8(2);
    var targetWaterTemp = r.getUint8(3);
    var targetWaterVolume = r.getUint8(4);
    var targetWaterLength = r.getUint8(5);
    var targetEspressoVolume = r.getUint8(6);
    var targetGroupTemp = r.getUint16(7) / (1 << 8);

    log.info('SteamBits = ${steamBits.toRadixString(16)}');
    log.info('TargetSteamTemp = $targetSteamTemp');
    log.info('TargetSteamLength = $targetSteamLength');
    log.info('TargetWaterTemp = $targetWaterTemp');
    log.info('TargetWaterVolume = $targetWaterVolume');
    log.info('TargetWaterLength = $targetWaterLength');
    log.info('TargetEspressoVolume = $targetEspressoVolume');
    log.info('TargetGroupTemp = $targetGroupTemp');
  }

  String toHexString(int number) => '0x${number.toRadixString(16).padLeft(2, '0')}';

  void _mmrNotification(ByteData value) {
    var list = value.buffer.asUint8List();
    if (kDebugMode) {
      log.info("MMR Notify: ${list.map(toHexString).toList()}");
    }
    _controllerMmrStream.add(list);
  }

  @override
  Future<int> getGhcMode() async {
    log.info('Reading group head control mode');
    var data = _getInt(await _mmrRead(mmrAddrLookup[MMRAddrEnum.PrefGHCMCI]!, 0));
    log.info("ghc controll mode: ${toHexString(data)}");
    return data;
  }

  @override
  Future<int> getGhcInfo() async {
    log.info('getGhcInfo');
    var data = _getInt(await _mmrRead(mmrAddrLookup[MMRAddrEnum.GHCInfo]!, 0));
// GHC Info Bitmask, 0x1 = GHC LED Controller Present, 0x2 = GHC Touch Controller_Present, 0x4 GHC Active, 0x80000000 = Factory Mode

    ghcLEDPresent = data & 0x1 == 0x1;
    ghcTouchPresent = data & 0x2 == 0x2;
    ghcActive = data & 0x4 == 0x4;

    log.info("ghc Info: LED:$ghcLEDPresent Touch:$ghcTouchPresent Active:$ghcActive ${toHexString(data)}");
    return data;
  }

  @override
  Future<int> getSerialNumber() async {
    log.info('getSerialNumber');
    var data = _getInt(await _mmrRead(mmrAddrLookup[MMRAddrEnum.SerialN]!, 0));
    log.info("SerialNo: $data ${toHexString(data)}");
    return data;
  }

  @override
  Future<int> getFirmwareBuild() async {
    log.info('getFirmwareBuild');
    var data = _getInt(await _mmrRead(mmrAddrLookup[MMRAddrEnum.CPUFirmwareBuild]!, 0));
    log.info("Firmware Version: $data ${toHexString(data)}");
    return data;
  }

  @override
  Future<int> getFanThreshhold() async {
    var data = _getInt(await _mmrRead(mmrAddrLookup[MMRAddrEnum.FanThreshold]!, 0));
    log.info("getFanThreshold: $data ${toHexString(data)}");
    return data;
  }

  @override
  Future<double> getSteamFlow() async {
    var data = _getInt(await _mmrRead(mmrAddrLookup[MMRAddrEnum.TargetSteamFlow]!, 0));
    log.info("TargetSteamFlow: $data ${toHexString(data)}");
    return data / 100;
  }

  @override
  Future<double> getFlowEstimation() async {
    var data = _getInt(await _mmrRead(mmrAddrLookup[MMRAddrEnum.CalFlowEst]!, 0));
    log.info("getFlowEstimation: $data ${toHexString(data)}");
    return data / 1000;
  }

  @override
  Future<void> setFlowEstimation(double newFlow) {
    ByteData bytes = ByteData(4);
    var data = (double.parse(newFlow.toStringAsFixed(2)) * 1000).toInt();
    bytes.setUint32(0, data, Endian.little);

    steamFlow = newFlow;
    return _mmrWrite(mmrAddrLookup[MMRAddrEnum.CalFlowEst]!, bytes.buffer.asUint8List());
  }

  @override
  Future<void> setFlushTimeout(double newTimeout) {
    ByteData bytes = ByteData(4);
    var data = (newTimeout * 10).toInt();
    bytes.setUint32(0, data, Endian.little);
    return _mmrWrite(mmrAddrLookup[MMRAddrEnum.FlushTimeout]!, bytes.buffer.asUint8List());
  }

  @override
  Future<void> setFanThreshhold(int t) {
    ByteData bytes = ByteData(4);
    bytes.setUint32(0, t, Endian.little);
    return _mmrWrite(mmrAddrLookup[MMRAddrEnum.FanThreshold]!, bytes.buffer.asUint8List());
  }

  @override
  Future<void> setSteamFlow(double newFlow) {
    ByteData bytes = ByteData(4);
    bytes.setUint32(0, (newFlow * 100).toInt(), Endian.little);

    steamFlow = newFlow;
    return _mmrWrite(mmrAddrLookup[MMRAddrEnum.TargetSteamFlow]!, bytes.buffer.asUint8List());
  }

  @override
  Future<int> getUsbChargerMode() async {
    var data = _getInt(await _mmrRead(mmrAddrLookup[MMRAddrEnum.AllowUSBCharging]!, 0));
    log.info("getUsbChargerMode: $data ${toHexString(data)}");
    usbChargerMode = data;
    return data;
  }

  Future<int> getExternalFlash() async {
    var data = _getInt(await _mmrRead(mmrAddrLookup[MMRAddrEnum.ExternalFlash]!, 0));
    log.info("getExternalFlash: $data ${toHexString(data)}");
    return data;
  }

  Future<int> getMaxShotPres() async {
    var data = _getInt(await _mmrRead(mmrAddrLookup[MMRAddrEnum.MaxShotPres]!, 0));
    log.info("getMaxShotPres: $data ${toHexString(data)}");
    return data;
  }

  @override
  Future<void> setUsbChargerMode(int t) {
    ByteData bytes = ByteData(4);
    bytes.setUint32(0, t, Endian.little);

    usbChargerMode = t;
    return _mmrWrite(mmrAddrLookup[MMRAddrEnum.AllowUSBCharging]!, bytes.buffer.asUint8List());
  }

  @override
  Future<void> setSteamPurgeMode(int t) {
    ByteData bytes = ByteData(4);
    bytes.setUint32(0, t, Endian.little);

    steamPurgeMode = t;
    return _mmrWrite(mmrAddrLookup[MMRAddrEnum.SteamPurgeMode]!, bytes.buffer.asUint8List());
  }

  @override
  Future<int> getSteamPurgeMode() async {
    var data = _getInt(await _mmrRead(mmrAddrLookup[MMRAddrEnum.SteamPurgeMode]!, 0));
    log.info("getSteamPurgeMode: $data ${toHexString(data)}");
    steamPurgeMode = data;
    return data;
  }

  int _getInt(List<int> buffer) {
    ByteData bytes = ByteData(20);
    var i = 0;
    var list = bytes.buffer.asUint8List();
    for (var _ in list) {
      list[i] = buffer[i++];
    }
    return bytes.getInt32(4, Endian.little);
  }

  Future<List<int>> _mmrRead(int address, int length) async {
    for (var element in mmrList) {
      if (element[0] == address) {
        log.info("MMR Read  ${toHexString(address)} = ${element[1]} : ${element[3]}");
        break;
      }
    }
    if (!mmrAvailable) {
      log.info('Unable to mmr_read because MMR not available');
      throw ("Error in mmr");
    }

    ByteData bytes = ByteData(20);
    bytes.setInt32(0, address, Endian.big);
    var buffer = bytes.buffer.asUint8List();
    buffer[0] = (length % 0xFF);

    if (kDebugMode) {
      // log.info("MMR READ: ${byteData.buffer.asUint8List().map(toHexString).toList()}");
      log.fine("MMR READ: ${buffer.map(toHexString).toList()}");
    }

    await _write(Endpoint.readFromMMR, Uint8List.fromList(buffer));

    var result = await _streamMMR.firstWhere(
      (element) {
        // log.info("listen where event  ${element.map(toHexString).toList()}");

        if (buffer[1] == element[1] && buffer[2] == element[2] && buffer[3] == element[3]) {
          return true;
        } else {
          return false;
        }
      },
      orElse: () => [],
    );
    log.info("listen event Result:  ${result.map(toHexString).toList()}");
    return result;
  }

  Future<void> _mmrWrite(int address, List<int> bufferData) {
    log.info("MMR WRITE REQUEST");
    if (!mmrAvailable) {
      log.info('Unable to mmr_read because MMR not available');
      return Future.error("No MMR");
    }

    ByteData bytes = ByteData(20);
    bytes.setInt32(0, address, Endian.big);
    var buffer = bytes.buffer.asUint8List();
    buffer[0] = (bufferData.length % 0xFF);
    var i = 0;
    for (var _ in bufferData) {
      buffer[i + 4] = bufferData[i++];
    }
    log.info("MMR WRITE: ${buffer.map(toHexString).toList()}");
    return _write(Endpoint.writeToMMR, Uint8List.fromList(buffer));
  }

  Future<void> _onStateChange(DeviceConnectionState state) async {
    log.info('State changed to $state');
    //_state = state;

    switch (state) {
      case DeviceConnectionState.connected:
        // await device.discoverAllServicesAndCharacteristics();
        // Enable notification
        service.setSubState("5");
        _parseVersion(ByteData.sublistView(Uint8List.fromList((await _read(Endpoint.versions)))));
        _stateNotification(ByteData.sublistView(Uint8List.fromList((await _read(Endpoint.stateInfo)))));
        _waterLevelNotification(ByteData.sublistView(Uint8List.fromList((await _read(Endpoint.waterLevels)))));
        _parseShotSetting(ByteData.sublistView(Uint8List.fromList((await _read(Endpoint.shotSettings)))));
        service.setSubState("7");
        // parseShotMapRequest(ByteData.sublistView(
        //     Uint8List.fromList((await read(Endpoint.ShotMapRequest)))));
        var header =
            _parseShotHeaderSettings(ByteData.sublistView(Uint8List.fromList((await _read(Endpoint.headerWrite)))));
        log.info("loaded header ${header.numberOfFrames} $header");
        // for (var f = 0; f < header.numberOfFrames; f++) {
        //   var frame = parseFrameWrite(ByteData.sublistView(Uint8List.fromList((await read(Endpoint.frameWrite)))));
        //   log.info("loaded frame $frame");
        // }

        _enableNotification(Endpoint.requestedState, _requestedState);

        _enableNotification(Endpoint.temperatures, _tempatureNotification);
        _enableNotification(Endpoint.waterLevels, _waterLevelNotification);
        _enableNotification(Endpoint.stateInfo, _stateNotification);
        service.setSubState("8");
        _enableNotification(Endpoint.shotSample, _shotSampleNotification);
        _enableNotification(Endpoint.shotSettings, _parseShotSetting);

        _enableNotification(Endpoint.shotMapRequest, _parseShotMapRequest);
        // enableNotification(Endpoint.headerWrite, parseShotHeaderSettings);
        // _enableNotification(Endpoint.frameWrite, _parseFrameWrite);

        _enableNotification(Endpoint.readFromMMR, _mmrNotification);
        _enableNotification(Endpoint.writeToMMR, _mmrNotification);

        try {
          service.setSubState("10%");
          await updateSettings();
          service.setSubState("20%");
          ghcInfo = await getGhcInfo();
          ghcMode = await getGhcMode();
          service.setSubState("30%");
          machineSerial = await getSerialNumber();
          log.info("Serial Number $machineSerial");
          service.setSubState("40%");
          firmware = await getFirmwareBuild();
          service.setSubState("50%");
          var fan = await getFanThreshhold();
          service.setSubState("60%");
          if (fan < 50) setFanThreshhold(50);
          service.setSubState("70%");
          await setWaterLevelWarning(_settings.targetWaterlevel);
          service.setSubState("80%");
          await setSteamFlow(_settings.targetSteamFlow);
          steamFlow = await getSteamFlow();
          service.setSubState("90%");
          steamPurgeMode = await getSteamPurgeMode();

          flowEstimation = await getFlowEstimation();

          await setFlushTimeout(max(_settings.targetFlushTime, _settings.targetFlushTime2));

          if (_settings.launchWake) {
            await switchOn();
          }

          var coffeeService = getIt<CoffeeService>();
          await coffeeService.setSelectedRecipe(_settings.selectedRecipe);
          service.setSubState("100%");
          Future.delayed(const Duration(seconds: 10), () => service.setSubState(""));
          log.info(
              "Fan:$fan GHCInfo:$ghcInfo GHCMode:$ghcMode Firmware:$firmware Serial:$machineSerial SteamFlow: $steamFlow SteamPurgeMode: $steamPurgeMode FlowEstimation> $flowEstimation");
        } catch (e) {
          log.severe("Error getting machine details $e");
        }

        return;
      case DeviceConnectionState.disconnected:
        log.info('de1 disconnected. Destroying');
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

  @override
  Future<void> updateSettings() async {
    var bytes = _encodeDe1OtherSetn();
    try {
      log.info("Write Shot Settings: $bytes");
      await writeWithResult(Endpoint.shotSettings, bytes);
      log.info("Written shotSettings to de1");
    } catch (ex) {
      log.severe("Error writing shot settings $bytes");
    }
  }

  Uint8List _encodeDe1OtherSetn() {
    var settingsService = getIt<SettingsService>();

    Uint8List data = Uint8List(9);

    int index = 0;
    data[index] = settingsService.steamSettings;
    index++;
    data[index] = settingsService.steamHeaterOff ? 0 : settingsService.targetSteamTemp;
    log.info("Set steam to temp: ${data[index]}");
    index++;
    data[index] = settingsService.targetSteamLength;
    index++;
    data[index] = settingsService.targetHotWaterTemp;
    index++;
    data[index] = settingsService.targetHotWaterVol;
    index++;
    data[index] = settingsService.targetHotWaterLength;
    index++;
    data[index] = settingsService.targetEspressoVol;
    index++;

    data[index] = settingsService.targetGroupTemp.toInt();
    index++;
    data[index] = ((settingsService.targetGroupTemp - settingsService.targetGroupTemp.floor()) * 256.0).toInt();
    index++;

    return data;
  }
}

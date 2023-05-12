// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:math';

import 'package:despresso/devices/abstract_decent_de1.dart';
import 'package:despresso/devices/decent_de1.dart';
import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/model/shot.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:logging/logging.dart' as l;
import '../model/shotstate.dart';
// import 'package:flutter_ble_lib/flutter_ble_lib.dart';

class DE1Simulated extends ChangeNotifier implements IDe1 {
  final log = l.Logger('DE1Sim');
  // ignore: non_constant_identifier_names

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

  EspressoMachineService service = getIt<EspressoMachineService>();
  final flutterReactiveBle = FlutterReactiveBle();

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

  De1StateEnum _state = De1StateEnum.busy;
  final int _subState = 0;

  double _sampleTime = 0;
  double _setMixTemp = 89;
  double _setHeadTemp = 88;
  double _mixTemp = 20;
  double _headTemp = 20;
  double _groupPressure = 6;
  double _groupFlow = 2;
  int _steamTemp = 120;
  double _setGroupPressure = 7;
  double _setGroupFlow = 7;
  int _frameNumber = 0;

  int _tick = 0;

  De1StateEnum _lastState = De1StateEnum.sleep;

  Shot? _shot;

  int shotPointer = 0;

  String _lastSubState = "";

  DE1Simulated() {
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

    service.setDecentInstance(this);
    _settings = getIt<SettingsService>();

    var coffee = getIt<CoffeeService>();
    _shot = coffee.getLastShot();
    _onStateChange(DeviceConnectionState.connected);

    service.scaleService.setState(ScaleState.connected);
    service.scaleService.setWeight(0.1);
    var hz = 4;
    Timer.periodic(Duration(milliseconds: (1.0 / hz * 1000).toInt()), (Timer t) {
      try {
        _stateTick();
      } catch (e) {}
    });
    Timer(
      const Duration(seconds: 1),
      () {
        service.scaleService.setWeight(0.1);
        requestState(De1StateEnum.idle);
      },
    );
  }

  _stateTick() {
    _tick++;
    // log.info("$headTemp $setHeadTemp $mixTemp $setMixTemp");
    _sampleTime = DateTime.now().millisecondsSinceEpoch / 1000.0;

    if (_state == De1StateEnum.idle) {
      if (_mixTemp < 87) {
        _mixTemp += 0.1;
        _headTemp = _mixTemp;
        _setMixTemp = 87;
      }
    }
    if (_state == De1StateEnum.sleep) {
      if (_mixTemp > 20) {
        _mixTemp -= 0.1;
        _headTemp = _mixTemp;
        _setMixTemp = 87;
      }
    }
    if (_state == De1StateEnum.espresso && _lastState != _state) {
      shotPointer = 0;
      _lastSubState = "";
      _lastState = De1StateEnum.idle;
    }

    if (_state == De1StateEnum.espresso && _shot != null) {
      if (shotPointer < (_shot?.shotstates.length ?? 0)) {
        if (_shot?.shotstates[shotPointer] != null) {
          ShotState s = (_shot?.shotstates[shotPointer])!;
          _groupPressure = s.groupPressure;
          _groupFlow = s.groupFlow;
          _mixTemp = s.mixTemp;
          _headTemp = s.headTemp;
          _setMixTemp = s.setMixTemp;
          _setHeadTemp = s.setHeadTemp;
          _setGroupPressure = s.setGroupPressure;
          _setGroupFlow = s.setGroupFlow;
          _frameNumber = s.frameNumber;
          _steamTemp = s.steamTemp;
          service.scaleService.setWeight(s.weight);
          log.info("$_groupPressure ${s.subState} $shotPointer");
          shotPointer++;
          if (s.subState != _lastSubState && s.subState != "") {
            log.info("Substate ${s.subState}");
            service.setSubState(s.subState);
            _lastSubState = s.subState;
          }
        }
        // service.setShot(s);
      } else {
        requestState(De1StateEnum.idle);
      }
    }

    service.setShot(ShotState(_sampleTime, 0, _groupPressure, _groupFlow, _mixTemp, _headTemp, _setMixTemp,
        _setHeadTemp, _setGroupPressure, _setGroupFlow, _frameNumber, _steamTemp, 0, ""));

    _lastState = _state;
  }

  @override
  Future<void> setIdleState() async {
    log.info('idleState Requested');

    await Future.delayed(const Duration(milliseconds: 10));
    requestState(De1StateEnum.idle);
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
  Future<void> requestState(De1StateEnum state) async {
    log.info("RequestState $state");
    await Future.delayed(const Duration(milliseconds: 10));
    _state = state;
    _stateNotification();
  }

  void _tempatureNotification(ByteData value) {}
  void _stateNotification() {
    var state = _state;
    var subState = _subState;

    log.info("DE1 is in state: ${states[state]} $state substate: $subState");
    service.setSubState(subStates[subState] ?? subState.toString());

    switch (state) {
      case De1StateEnum.sleep: // 4 Making espresso
        service.setState(EspressoMachineState.sleep);
        break;
      case De1StateEnum.espresso: // 4 Making espresso
        service.setState(EspressoMachineState.espresso);
        break;
      case De1StateEnum.steam: // 5 Making steam
        service.setState(EspressoMachineState.steam);
        break;
      case De1StateEnum.hotWater: // 6 Making hot water
        service.setState(EspressoMachineState.water);
        break;
      case De1StateEnum.refill: // 6 Water empty
        service.setState(EspressoMachineState.refill);
        break;
      case De1StateEnum.hotWaterRinse: // flush water in grouphead
        service.setState(EspressoMachineState.flush);
        break;
      default:
        service.setState(EspressoMachineState.idle);
        service.setSubState("?");
        break;
    }
  }

  @override
  Future<int> getGhcMode() async {
    return 0x1;
  }

  @override
  Future<int> getGhcInfo() async {
    log.info('getGhcInfo');

// GHC Info Bitmask, 0x1 = GHC LED Controller Present, 0x2 = GHC Touch Controller_Present, 0x4 GHC Active, 0x80000000 = Factory Mode

    ghcLEDPresent = true;
    ghcTouchPresent = true;
    ghcActive = true;

    return 255;
  }

  @override
  Future<int> getSerialNumber() async {
    log.info('getSerialNumber');
    var data = 0x123;

    return data;
  }

  @override
  Future<int> getFirmwareBuild() async {
    log.info('getFirmwareBuild');
    return 0x0815;
  }

  @override
  Future<int> getFanThreshhold() async {
    return 0x20;
  }

  @override
  Future<double> getSteamFlow() async {
    return 1;
  }

  @override
  Future<double> getFlowEstimation() async {
    return 20 / 1000;
  }

  @override
  Future<void> setFlowEstimation(double newFlow) {
    ByteData bytes = ByteData(4);
    var data = (double.parse(newFlow.toStringAsFixed(2)) * 1000).toInt();
    bytes.setUint32(0, data, Endian.little);

    steamFlow = newFlow;
    return Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  Future<void> setFlushTimeout(double newTimeout) {
    ByteData bytes = ByteData(4);
    var data = (newTimeout * 10).toInt();
    bytes.setUint32(0, data, Endian.little);
    return Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  Future<void> setFanThreshhold(int t) {
    ByteData bytes = ByteData(4);
    bytes.setUint32(0, t, Endian.little);
    return Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  Future<void> setSteamFlow(double newFlow) {
    ByteData bytes = ByteData(4);
    bytes.setUint32(0, (newFlow * 100).toInt(), Endian.little);

    steamFlow = newFlow;
    return Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  Future<int> getUsbChargerMode() async {
    usbChargerMode = 70;
    return usbChargerMode;
  }

  @override
  Future<void> setUsbChargerMode(int t) {
    ByteData bytes = ByteData(4);
    bytes.setUint32(0, t, Endian.little);

    usbChargerMode = t;
    return Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  Future<void> setSteamPurgeMode(int t) {
    ByteData bytes = ByteData(4);
    bytes.setUint32(0, t, Endian.little);

    steamPurgeMode = t;
    return Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  Future<int> getSteamPurgeMode() async {
    return steamPurgeMode;
  }

  Future<void> _onStateChange(DeviceConnectionState state) async {
    log.info('State changed to $state');
    //_state = state;

    switch (state) {
      case DeviceConnectionState.connected:
        // await device.discoverAllServicesAndCharacteristics();
        // Enable notification

        try {
          await updateSettings();

          ghcInfo = await getGhcInfo();
          ghcMode = await getGhcMode();

          machineSerial = await getSerialNumber();

          firmware = await getFirmwareBuild();
          var fan = await getFanThreshhold();
          if (fan < 50) setFanThreshhold(50);

          steamFlow = await getSteamFlow();

          steamPurgeMode = await getSteamPurgeMode();

          flowEstimation = await getFlowEstimation();
          service.setWaterLevel(WaterLevel(9550, 100));
          service.scaleService.setWeight(0);
          await setFlushTimeout(max(_settings.targetFlushTime, _settings.targetFlushTime2));

          if (_settings.launchWake) {
            await switchOn();
          }

          var coffeeService = getIt<CoffeeService>();
          await coffeeService.setSelectedRecipe(_settings.selectedRecipe);

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

  @override
  Future<void> updateSettings() async {}

  @override
  Future<void> writeWithResult(Endpoint e, Uint8List data) {
    // TODO: implement writeWithResult
    log.info("write");
    return Future.delayed(const Duration(milliseconds: 10));
  }
}

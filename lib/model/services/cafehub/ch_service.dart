import 'dart:async';
import 'dart:convert';

// import 'dart:html';
// import 'dart:html';

import 'package:collection/collection.dart';
import 'package:despresso/devices/abstract_comm.dart';
import 'package:despresso/devices/acaia_pyxis_scale.dart';
import 'package:despresso/devices/decent_scale.dart';
import 'package:despresso/devices/felicita_scale.dart';
import 'package:despresso/devices/meater_thermometer.dart';
import 'package:despresso/devices/skale2_scale.dart';
import 'package:despresso/helper/permissioncheck.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/model/services/cafehub/data_models.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:despresso/devices/acaia_scale.dart';
import 'package:despresso/devices/eureka_scale.dart';
import 'package:despresso/devices/hiroia_scale.dart';
import 'package:despresso/devices/decent_de1.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart' as ble;

class RequestEntry {
  int id;
  void Function(T_IncomingMsg) onResponse;
  RequestEntry({required this.id, required this.onResponse});
}

class GATTNotify {
  String deviceId;
  String characteristicsId;
  List<int> data;

  GATTNotify({required this.deviceId, required this.characteristicsId, required this.data});
}

class CallbackHandler {
  List<RequestEntry> store = [];
  addRequest(RequestEntry request) {
    store.add(request);
  }

  RequestEntry? get(int id) {
    return store.firstWhereOrNull((element) => element.id == id);
  }

  RequestEntry? use(int id) {
    var r = get(id);
    store.remove(r);
    return r;
  }
}

class CHService extends ChangeNotifier implements DeviceCommunication {
  final log = Logger('CHService');

  // static BleManager bleManager = BleManager();
  final flutterReactiveBle = ble.FlutterReactiveBle();

  final List<ble.DiscoveredDevice> _devicesList = <ble.DiscoveredDevice>[];
  final List<ble.DiscoveredDevice> _devicesIgnoreList = <ble.DiscoveredDevice>[];

  StreamSubscription<ble.DiscoveredDevice>? _subscription;

  bool isScanning = false;

  String error = "";

  WebSocketChannel? _channel;

  late SettingsService _settings;

  String _connectionString = "";

  int _id = 1;

  CallbackHandler _store = CallbackHandler();
  StreamController<ble.ConnectionStateUpdate> _controllerConnectionStream =
      StreamController<ble.ConnectionStateUpdate>();

  StreamController<GATTNotify> _gattNotificationController = StreamController<GATTNotify>();

  ble.BleStatus _status = ble.BleStatus.unknown;

  late Stream<GATTNotify> _gattNotificationStream;

  CHService() {
    _settings = getIt<SettingsService>();
    _settings.addListener(
      () {
        if (_settings.chUrl != _connectionString) {
          _connectionString = _settings.chUrl;
          init();
        }
      },
    );
    _gattNotificationStream = _gattNotificationController.stream.asBroadcastStream();
    _connectionString = _settings.chUrl;
    init();
  }

  void init() async {
    await checkPermissions();
    // await bleManager.createClient();

    // bleManager.observeBluetoothState().listen(btStateListener);
    // startScanning();
    final wsUrl = Uri.parse(_connectionString);
    _channel = WebSocketChannel.connect(wsUrl);

    _channel?.stream.listen((message) {
      _status = ble.BleStatus.ready;
      // log.info("REC: $message");
      log.info("Stream: REC: $message");
      var msg = makeIncomingMsgFromJSON(message);

      if (msg.type == "UPDATE" && (msg as dynamic).update == "GATTNotify") {
        log.info("RESP GATT NOTIFY: $msg");
        _gattNotificationController.add(GATTNotify(
            deviceId: msg.results!["MAC"],
            characteristicsId: msg.results!["Char"],
            data: base64.decode(msg.results!["Data"])));
      } else {
        var cb = _store.get(msg.id);
        cb?.onResponse(msg);
        log.info("RESP: $msg");
      }
      // channel.sink.add('received!');
      // channel.sink.close(status.goingAway);
    }, onError: (e) {
      log.info("ERROR: $e");
    });

    startScan();
  }

  T_Request makeScan(int timeout) {
    // Scan(timeout : U32)
    var params = {"Timeout": timeout};
    return makeReq("Scan", _id++, params);
  }

  T_Request makeReq(String command, int rid, Map<String, dynamic> params) {
    return T_Request(command: command, params: params, id: rid);
  }

  T_IncomingMsg makeIncomingMsgFromJSON(String jsondata) {
    final parsedJson = json.decode(jsondata);
    String type = parsedJson["type"];
    log.info(parsedJson["type"]);
    if (type == "RESP") {
      // Response
      // let resp = msg as T_Response;
      // return resp;
      log.info("RESP: $parsedJson");

      var res = T_Response.fromJson(parsedJson);
      return res;
    }
    if (type == "UPDATE") {
      // Update
      var res = T_Update.fromJson(parsedJson);
      return res;
    }
    throw "Unrecognised Incoming Message";
  }

  _sendAsJSON(T_Request thing) {
    var e = JsonEncoder();
    var json = thing.toJson();
    String jsonS = e.convert(json);
    log.info("Sending Request $jsonS");
    _channel?.sink.add(jsonS);
  }

  // void btStateListener(BluetoothState btState) {
  //   print(btState);
  // }

  void startScan() {
    if (isScanning) {
      log.info("Already scanning");
      return;
    }

    isScanning = true;

    var s = makeScan(30);
    _sendAsJSON(s);
    _store.addRequest(RequestEntry(
        id: s.id,
        onResponse: (data) {
          var d = (data as T_Update);
          if (d.results == null) {
            log.info("Update no data");
            return;
          }
          if (d.results!["Name"] == null) {
            d.results!["Name"] = "";
          }
          var sr = T_ScanResult.fromJson(d.results!);
          log.info("Received Scanned Data $sr");
          var uuids = sr.UUIDs.map((uuid) => ble.Uuid.parse(uuid));
          deviceScanListener(
            ble.DiscoveredDevice(
              id: sr.MAC,
              name: sr.Name,
              manufacturerData: Uint8List(0),
              rssi: 0,
              serviceData: {},
              serviceUuids: uuids.toList(),
            ),
          );
        }));

    // _devicesList.clear();
    // if (_subscription != null) _subscription?.cancel();

    // log.info('startScan');
    // ScaleService scaleService = getIt<ScaleService>();
    // if (scaleService.state != ScaleState.connected) {
    //   scaleService.setState(ScaleState.connecting);
    // }
    // _subscription =
    //     flutterReactiveBle.scanForDevices(withServices: [], scanMode: ble.ScanMode.lowLatency).listen((device) {
    //   deviceScanListener(device);
    // }, onError: (err) {
    //   // ignore: prefer_interpolation_to_compose_strings
    //   log.info('Scanner Error:' + err?.message?.message);
    //   error = err.message?.message;
    //   notifyListeners();
    // });

    // Timer(const Duration(seconds: 30), () {
    //   _subscription?.cancel();
    //   log.info('stoppedScan');
    //   _subscription = null;
    //   isScanning = false;
    //   if (scaleService.state == ScaleState.connecting) {
    //     scaleService.setState(ScaleState.disconnected);
    //   }
    //   notifyListeners();
    // });

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

  T_Request makeConnect(String mac, int rid) {
    Map<String, dynamic> params = {
      'MAC': mac,
    };
    return makeReq("GATTConnect", rid, params);
  }

  T_Request makeGATTRead(String mac, String char, int rlen, int rid) {
    Map<String, dynamic> params = {'MAC': mac, 'Char': char, 'Len': rlen};
    return makeReq("GATTRead", rid, params);
  }

  T_Request makeGATTWrite(String mac, String char, List<int> data, int rid, bool requireresponse) {
    Map<String, dynamic> params = {'MAC': mac, 'Char': char, 'Data': base64.encode(data), 'RR': requireresponse};
    return makeReq("GATTWrite", rid, params);
  }

  T_Request makeGATTSetNotify(String mac, String char, bool enable, int rid) {
    Map<String, dynamic> params = {'MAC': mac, 'Char': char, 'Enable': enable};
    return makeReq("GATTSetNotify", rid, params);
  }

  @override
  Stream<ble.ConnectionStateUpdate> connectToDevice(
      {required String id,
      Map<ble.Uuid, List<ble.Uuid>>? servicesWithCharacteristicsToDiscover,
      Duration? connectionTimeout}) {
    // TODO: implement connectToDevice

    /**
   * Request a connection to the GATT server on a device
   * 
   * Will return with a connection state after connection fails or succeeds, and then
   * the callback will be forgotten.
   * 
   * Register for unsolicited callbacks using registerForNotifies to be informed
   * of things like disconnects.
   * 
   * @param mac MAC address of server, eg "20:C3:8F:E3:B6:A3"
   * @param callback Function to call back with the result
   */
    // requestGATTConnect = (mac : string, callback : I_ConnectionStateCallback) => {
    // const conncb = (request: T_Request, response: T_IncomingMsg): boolean => {
    //   // We proxy the callback so we can update our list of connected devices.
    //   const update = this.MM.updateFromMsg(response)
    //   let connstate = this.MM.connStateFromUpdate(update);
    //   this._updateConnState(connstate.MAC, connstate.CState);
    //   console.log("BLE: requestGATTConnect response:", connstate)
    //   callback(request, connstate);
    //   return false;
    // }

    _sendRequest(makeConnect(id, 0), (data) {
      if ((data as dynamic).update == "ExecutionError") {
        ble.ConnectionStateUpdate update = ble.ConnectionStateUpdate(
            failure: null, deviceId: id, connectionState: ble.DeviceConnectionState.disconnected);
        _controllerConnectionStream.add(update);
        return;
      }
      var state = T_ConnectionStateNotify.fromJson(data.results!);
      ble.ConnectionStateUpdate? update;
      // type T_ConnectionState = "INIT" | "DISCONNECTED" | "CONNECTED" | "CANCELLED";
      switch (state.CState) {
        case "INIT":
          update = ble.ConnectionStateUpdate(
              failure: null, deviceId: id, connectionState: ble.DeviceConnectionState.connecting);

          break;
        case "DISCONNECTED":
          update = ble.ConnectionStateUpdate(
              failure: null, deviceId: id, connectionState: ble.DeviceConnectionState.disconnected);
          break;
        case "CONNECTED":
          update = ble.ConnectionStateUpdate(
              failure: null, deviceId: id, connectionState: ble.DeviceConnectionState.connected);
          break;
        case "CANCELLED":
          update = ble.ConnectionStateUpdate(
              failure: null, deviceId: id, connectionState: ble.DeviceConnectionState.disconnecting);

          break;
      }
      if (update != null) {
        _controllerConnectionStream.add(update);
      }
      log.info("Connection update: $data $state");
    });

    return _controllerConnectionStream.stream;
  }

// /**
//      * Do a callback read from a GATT device
//      *
//      * @param mac MAC address
//      * @param char Characteristic to read
//      * @param readlen Number of bytes to read (should just be the size of the characteristic, for now)
//      * @param callback Callback to call with response. Return false from callback.
//      */
//     requestGATTRead = (mac: string, char: string, readlen: number, callback: I_BLEResponseCallback) => {
//         this._sendRequest(this.MM.makeGATTRead(mac, char, readlen, 0), BLE._makeResponseTrampoline(callback));
//     }

  @override
  Future<List<int>> readCharacteristic(ble.QualifiedCharacteristic characteristic) {
    // TODO: implement readCharacteristic
    var c = Completer<List<int>>();
    _sendRequest(
        makeGATTRead(
          characteristic.deviceId,
          characteristic.characteristicId.toString(),
          16,
          0,
        ), (data) {
      if (data.type == "UPDATE") {
        c.completeError(data.results!["errmsg"]);
      } else {
        /// todo: wait until "Data:" is only "Data"
        var res = data.results!["Data:"].toString();
        log.info("Resposne: $res");

        List<int> result = base64.decode(res).toList();
        c.complete(result);
      }
    });

    return c.future;
  }

  _sendRequest(T_Request reqtosend, Function(T_IncomingMsg) callback) {
    var id = _id++;
    reqtosend.id = id;
    _store.addRequest(RequestEntry(id: id, onResponse: callback));
    _sendAsJSON(reqtosend);
  }

  @override
  Stream<List<int>> subscribeToCharacteristic(ble.QualifiedCharacteristic characteristic) {
    StreamController<List<int>> ctrl = StreamController();

    _sendRequest(makeGATTSetNotify(characteristic.deviceId, characteristic.characteristicId.toString(), true, 0),
        (data) {
      if (data.type == "UPDATE") {
        log.severe(data.results!["errmsg"]);
      } else {
        /// todo: wait until "Data:" is only "Data"
        if (data.results?.containsKey("Data:") == true) {
          var res = data.results!["Data:"].toString();
          log.info("Resposne: $res");

          List<int> codeUnits = res.codeUnits;
          if (codeUnits != null) {
            ctrl.add(codeUnits);
          }
        }
      }
    });
    _gattNotificationStream.listen((event) {
      log.info("Listening for Message");
      if (event.characteristicsId == characteristic.characteristicId.toString() &&
          event.deviceId == characteristic.deviceId) {
        log.info("Found for Message");
        ctrl.add(event.data);
      }
    });
    return ctrl.stream;
  }

  @override
  Future<void> writeCharacteristicWithResponse(ble.QualifiedCharacteristic characteristic, {required List<int> value}) {
    var c = Completer<List<int>>();

    _sendRequest(makeGATTWrite(characteristic.deviceId, characteristic.characteristicId.toString(), value, 0, true),
        (data) {
      if (data.type == "UPDATE") {
        c.completeError(data.results!["errmsg"]);
      } else {
        /// todo: wait until "Data:" is only "Data"
        var res = base64.decode(data.results!["Data:"]);
        log.info("Resposne: $res");

        c.complete(res);
      }
    });

    return c.future;
  }

  @override
  Future<void> writeCharacteristicWithoutResponse(ble.QualifiedCharacteristic characteristic,
      {required List<int> value}) {
    var c = Completer<List<int>>();
    _sendRequest(makeGATTWrite(characteristic.deviceId, characteristic.characteristicId.toString(), value, 0, false),
        (data) {
      if (data.type == "UPDATE") {
        c.completeError(data.results!["errmsg"]);
      } else {
        /// todo: wait until "Data:" is only "Data"
        var res = base64.decode(data.results!["Data:"]);
        log.info("Resposne: $res");

        c.complete(res);
      }
    });

    return c.future;
  }

  @override
  // TODO: implement status
  ble.BleStatus get status => _status;
}

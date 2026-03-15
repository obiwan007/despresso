import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/shotstate.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'settings_service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:shelf_static/shelf_static.dart' as shelf_static;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
// final client = MqttServerClient(mqttServer, mqttPort.toString());

class WebService extends ChangeNotifier {
  final log = Logger('WebService');

  late SettingsService settingsService;
  late EspressoMachineService machineService;

  StreamSubscription<EspressoMachineFullState>? streamStateSubscription;
  StreamSubscription<int>? streamBatterySubscription;
  StreamSubscription<ShotState>? streamShotSubscription;
  StreamSubscription<WaterLevel>? streamWaterSubscription;

  HttpServer? server;

  bool isRunning = false;
  bool isStarting = false;

  final Set<WebSocketChannel> _machineStateSockets = {};
  ShotState? _lastShotState;

  final Map<String, String> header = {
    "content-type": 'application/json',
    "Access-Control-Allow-Origin": "*",
  };

  WebService() {
    settingsService = getIt<SettingsService>();
    machineService = getIt<EspressoMachineService>();

    settingsService.addListener(() async {
      if (settingsService.webServer && isRunning == false) {
        await startService();
      }

      if (settingsService.webServer == false && isRunning == true) {
        await stopService();
      }
    });

    if (settingsService.webServer == true && isRunning == false) {
      startService();
    }
  }

  Future<int> startService() async {
    if (isStarting == true) {
      return 0;
    }
    log.info('startService');
    isStarting = true;
    await prepareWebsite();
    var root = await getWebPath();
    var staticHandler = shelf_static.createStaticHandler(root, defaultDocument: 'index.html');

    var router = shelf_router.Router();
    final cascade = Cascade()
        // First, serve files from the 'web' directory
        .add(staticHandler)
        // If a corresponding file is not found, send requests to a `Router`
        .add(router);

    router.get('/api/hello', (Request request) {
      return Response.ok('{"text": "hello-world"}', headers: header);
    });

    router.get('/api/user/<user>', (Request request, String user) {
      return Response.ok('{"text": "hello $user}"');
    });

    router.get('/api/state', (Request request) {
      var s = machineService.currentFullState;
      var res = Response.ok('{"state": "${s.state.name}", "subState": "${s.subState}"}', headers: header);
      return res;
    });

    router.post('/api/state', (Request request) {
      return setMachineState(request);
    });

    router.get('/api/shot', (Request request) {
      var s = jsonEncode(machineService.state.shot?.toJson());
      var res = Response.ok(s, headers: header);
      return res;
    });

    router.get(
      '/ws/v1/machine/state',
      webSocketHandler((WebSocketChannel socket, _) {
        _machineStateSockets.add(socket);
        _sendMachineState(socket, _lastShotState);
        socket.stream.listen(
          (_) {},
          onDone: () {
            _machineStateSockets.remove(socket);
          },
          onError: (_) {
            _machineStateSockets.remove(socket);
          },
        );
      }),
    );

    try {
      server = await shelf_io.serve(
        logRequests()
            // See https://pub.dev/documentation/shelf/latest/shelf/MiddlewareExtensions/addHandler.html
            .addHandler(cascade.handler),
        InternetAddress.anyIPv4,
        8888,
      );

      // Enable content compression
      server!.autoCompress = true;

      log.info('Serving at http://${server!.address.host}:${server!.port}');
      isRunning = true;

      await streamShotSubscription?.cancel();
      await streamStateSubscription?.cancel();
      streamShotSubscription = machineService.streamShotState.listen((shotState) {
        _lastShotState = shotState;
        _broadcastMachineState(shotState);
      });
      streamStateSubscription = machineService.streamState.listen((_) {
        _broadcastMachineState(_lastShotState);
      });
    } catch (e) {
      log.severe('webserving error $e');
      isRunning = false;
    }
    isStarting = false;
    return 0;
  }

  Future<Response> setMachineState(Request request) async {
    var data = await request.readAsString();
    var js = jsonDecode(data);
    String newState = js['state'];
    switch (newState) {
      case 'idle':
        machineService.de1?.switchOn();
        break;
      case 'sleep':
        machineService.de1?.switchOff();
        break;
    }
    await Future.delayed(const Duration(milliseconds: 1000));
    var s = machineService.currentFullState;
    log.info("post: $data ${js['state']}");
    var res = Response.ok('{"state": "${s.state.name}", "subState": "${s.subState}"}', headers: header);
    return res;
  }

  stopService() async {
    if (server != null) {
      await streamShotSubscription?.cancel();
      await streamStateSubscription?.cancel();
      await streamBatterySubscription?.cancel();
      await streamWaterSubscription?.cancel();
      for (final socket in _machineStateSockets.toList()) {
        await socket.sink.close();
      }
      _machineStateSockets.clear();
      await server!.close(force: true);
      isRunning = false;
      log.info('server stopped');
    }
  }

  void _broadcastMachineState(ShotState? shotState) {
    if (_machineStateSockets.isEmpty) {
      return;
    }
    for (final socket in _machineStateSockets.toList()) {
      _sendMachineState(socket, shotState);
    }
  }

  void _sendMachineState(WebSocketChannel socket, ShotState? shotState) {
    try {
      socket.sink.add(jsonEncode(_buildMachineStatePayload(shotState)));
    } catch (e) {
      _machineStateSockets.remove(socket);
      socket.sink.close();
    }
  }

  Map<String, dynamic> _buildMachineStatePayload(ShotState? shotState) {
    final state = machineService.currentFullState;
    return {
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'state': {'state': state.state.name, 'substate': state.subState},
      'flow': shotState?.groupFlow ?? 0.0,
      'pressure': shotState?.groupPressure ?? 0.0,
      'targetFlow': shotState?.setGroupFlow ?? 0.0,
      'targetPressure': shotState?.setGroupPressure ?? 0.0,
      'mixTemperature': shotState?.mixTemp ?? 0.0,
      'groupTemperature': shotState?.headTemp ?? 0.0,
      'targetMixTemperature': shotState?.setMixTemp ?? 0.0,
      'targetGroupTemperature': shotState?.setHeadTemp ?? 0.0,
      'profileFrame': shotState?.frameNumber ?? 0,
      'steamTemperature': shotState?.steamTemp ?? 0,
    };
  }

  Future<void> prepareWebsite() async {
    String webPath = await getWebPath();
    var dir = Directory(webPath);
    dir.create(recursive: true);

    // This will give a list of all files inside the `assets`.

    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final get = manifest.listAssets().where((path) => path.startsWith("assets/website")).toList();    
    log.info("Found web content: $get");

    for (String element in get) {
      try {
        ByteData data = await rootBundle.load(element);
        log.info("Copy $element");
        var assetFile = element.replaceFirst("assets/website/", "");
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        var file = File("$webPath/$assetFile");
        await file.create(recursive: true);
        await file.writeAsBytes(bytes);
      } catch (e) {
        log.severe("Error writing file $e");
      }
    }
  }

  Future<String> getWebPath() async {
    Directory directory = await getApplicationDocumentsDirectory();
    var webPath = join(directory.path, "web");
    return webPath;
  }
}

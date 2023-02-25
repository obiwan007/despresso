import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/shotstate.dart';
import 'package:despresso/service_locator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'settings_service.dart';
import 'package:despresso/logger_util.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:shelf_static/shelf_static.dart' as shelf_static;
// final client = MqttServerClient(mqttServer, mqttPort.toString());

class WebService extends ChangeNotifier {
  final log = Logger('WebService');

  late SettingsService settingsService;
  late EspressoMachineService machineService;

  late StreamSubscription<EspressoMachineFullState> streamStateSubscription;
  late StreamSubscription<int> streamBatterySubscription;
  late StreamSubscription<ShotState> streamShotSubscription;
  late StreamSubscription<WaterLevel> streamWaterSubscription;

  HttpServer? server;

  bool isRunning = false;
  bool isStarting = false;

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
    var _staticHandler = shelf_static.createStaticHandler(root, defaultDocument: 'index.html');

    var _router = shelf_router.Router();
    final cascade = Cascade()
        // First, serve files from the 'web' directory
        .add(_staticHandler)
        // If a corresponding file is not found, send requests to a `Router`
        .add(_router);

    _router.get('/hello', (Request request) {
      return Response.ok('hello-world');
    });

    _router.get('/user/<user>', (Request request, String user) {
      return Response.ok('hello $user');
    });
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
    } catch (e) {
      log.severe('webserving error $e');
      isRunning = false;
    }
    isStarting = false;
    return 0;
  }

  stopService() async {
    if (server != null) {
      await server!.close(force: true);
      isRunning = false;
      log.info('server stopped');
    }
  }

  Future<void> prepareWebsite() async {
    String webPath = await getWebPath();
    var dir = Directory(webPath);
    dir.create(recursive: true);

    // This will give a list of all files inside the `assets`.
    var assets = await rootBundle.loadString('AssetManifest.json');
    Map jn = json.decode(assets);
    List get = jn.keys.where((element) => element.startsWith("assets/website")).toList();
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

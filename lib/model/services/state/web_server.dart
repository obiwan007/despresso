import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:despresso/model/coffee.dart';

import 'package:despresso/model/de1shotclasses.dart';
import 'package:despresso/model/recipe.dart';
import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/ble/scale_service.dart';
import 'package:despresso/model/services/state/coffee_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/shot.dart';
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
  late ScaleService scaleService;
  late CoffeeService coffeeService;
  late ProfileService profileService;

  StreamSubscription<EspressoMachineFullState>? streamStateSubscription;
  StreamSubscription<int>? streamBatterySubscription;
  StreamSubscription<ShotState>? streamShotSubscription;
  StreamSubscription<WaterLevel>? streamWaterSubscription;
  StreamSubscription<WeightMeassurement>? streamScaleSubscription;
  StreamSubscription<BatteryLevel>? streamScaleBatterySubscription;

  HttpServer? server;

  bool isRunning = false;
  bool isStarting = false;

  final Set<WebSocketChannel> _machineStateSockets = {};
  final Set<WebSocketChannel> _scaleSnapshotSockets = {};
  final Set<WebSocketChannel> _waterLevelSockets = {};
  ShotState? _lastShotState;
  double _lastScaleWeight = 0.0;
  int _lastScaleBattery = 0;
  int _lastWaterLevel = 0;
  int _lastRefillLevel = 0;

  final Map<String, String> header = {"content-type": 'application/json', "Access-Control-Allow-Origin": "*"};

  WebService() {
    settingsService = getIt<SettingsService>();
    machineService = getIt<EspressoMachineService>();
    scaleService = getIt<ScaleService>();
    coffeeService = getIt<CoffeeService>();
    profileService = getIt<ProfileService>();

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

    router.put('/api/v1/machine/state/<target>', (Request request, String target) {
      return setMachineStateByTarget(target);
    });

    router.put('/api/v1/scale/tare', (Request request) {
      return tareScale();
    });

    router.get('/api/v1/shots/ids', (Request request) {
      return getShotIds();
    });

    router.get('/api/v1/shots', (Request request) {
      return getShots(request);
    });

    router.delete('/api/v1/shot', (Request request) {
      return deleteShots(request);
    });

    router.get('/api/v1/coffee', (Request request) {
      return getCoffees(request);
    });

    router.delete('/api/v1/coffee', (Request request) {
      return deleteCoffees(request);
    });

    router.get('/api/v1/roaster', (Request request) {
      return getRoasters(request);
    });

    router.delete('/api/v1/roaster', (Request request) {
      return deleteRoasters(request);
    });

    router.get('/api/v1/profile', (Request request) {
      return getProfiles(request);
    });

    router.get('/api/v1/recipe', (Request request) {
      return getRecipes(request);
    });

    router.delete('/api/v1/recipe', (Request request) {
      return deleteRecipes(request);
    });

    router.get('/api/v1/coffee/ids', (Request request) {
      return getCoffeeIds();
    });

    router.get('/api/v1/roaster/ids', (Request request) {
      return getRoasterIds();
    });

    router.get('/api/v1/profile/ids', (Request request) {
      return getProfileIds();
    });

    router.get('/api/v1/recipe/ids', (Request request) {
      return getRecipeIds();
    });

    router.get('/api/shot', (Request request) {
      var s = jsonEncode(machineService.state.shot?.toJson());
      var res = Response.ok(s, headers: header);
      return res;
    });

    router.get(
      '/ws/v1/machine/snapshot',
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

    router.get(
      '/ws/v1/scale/snapshot',
      webSocketHandler((WebSocketChannel socket, _) {
        _scaleSnapshotSockets.add(socket);
        _sendScaleSnapshot(socket);
        socket.stream.listen(
          (_) {},
          onDone: () {
            _scaleSnapshotSockets.remove(socket);
          },
          onError: (_) {
            _scaleSnapshotSockets.remove(socket);
          },
        );
      }),
    );

    router.get(
      '/ws/v1/machine/waterLevels',
      webSocketHandler((WebSocketChannel socket, _) {
        _waterLevelSockets.add(socket);
        _sendWaterLevelSnapshot(socket);
        socket.stream.listen(
          (_) {},
          onDone: () {
            _waterLevelSockets.remove(socket);
          },
          onError: (_) {
            _waterLevelSockets.remove(socket);
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
      await streamScaleSubscription?.cancel();
      await streamScaleBatterySubscription?.cancel();
      streamShotSubscription = machineService.streamShotState.listen((shotState) {
        _lastShotState = shotState;
        _broadcastMachineState(shotState);
      });
      streamStateSubscription = machineService.streamState.listen((_) {
        _broadcastMachineState(_lastShotState);
      });
      streamScaleSubscription = scaleService.stream0.listen((measurement) {
        _lastScaleWeight = measurement.weight;
        _broadcastScaleSnapshot();
      });
      streamScaleBatterySubscription = scaleService.streamBattery0.listen((battery) {
        _lastScaleBattery = battery.level;
        _broadcastScaleSnapshot();
      });
      streamWaterSubscription = machineService.streamWaterLevel.listen((water) {
        _lastWaterLevel = water.getLevelML();
        _lastRefillLevel = water.getLevelRefill();
        _broadcastWaterLevelSnapshot();
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

  Future<Response> setMachineStateByTarget(String target) async {
    final mapped = _mapTargetToState(target);
    if (mapped == null) {
      return Response(400, body: '{"error":"Unknown target: $target"}', headers: header);
    }

    if (mapped == EspressoMachineState.idle) {
      machineService.de1?.switchOn();
    } else if (mapped == EspressoMachineState.sleep) {
      machineService.de1?.switchOff();
    }

    await machineService.setState(mapped);
    var s = machineService.currentFullState;
    return Response.ok('{"state": "${s.state.name}", "subState": "${s.subState}"}', headers: header);
  }

  Future<Response> tareScale() async {
    await scaleService.tare();
    return Response.ok('{"status":"ok"}', headers: header);
  }

  Response getShotIds() {
    final ids = coffeeService.shotBox.getAll().map((shot) => shot.id).toList();
    return Response.ok(jsonEncode(ids), headers: header);
  }

  Response getShots(Request request) {
    final ids = _parseShotIds(request);
    if (ids.isEmpty) {
      return Response.ok('[]', headers: header);
    }

    final shots = ids.map((id) => coffeeService.shotBox.get(id)).whereType<Shot>().map(_shotToApi).toList();

    try {
      log.info("getShots with ids: $ids, found: ${shots.length}");
      return Response.ok(jsonEncode(shots), headers: header);
    } catch (e) {
      log.severe("Error getting shots for ids $ids: $e");
      return Response(500, body: '{"error":"Failed to retrieve shots"}', headers: header);
    }
  }

  Response getCoffees(Request request) {
    final ids = _parseCoffeeIds(request);
    if (ids.isEmpty) {
      return Response.ok('[]', headers: header);
    }

    final coffees = ids.map((id) => coffeeService.coffeeBox.get(id)).whereType<Coffee>().map(_coffeeToApi).toList();

    try {
      log.info("getCoffees with ids: $ids, found: ${coffees.length}");
      return Response.ok(jsonEncode(coffees), headers: header);
    } catch (e) {
      log.severe("Error getting coffees for ids $ids: $e");
      return Response(500, body: '{"error":"Failed to retrieve coffee"}', headers: header);
    }
  }

  Response getRoasters(Request request) {
    final ids = _parseRoasterIds(request);
    if (ids.isEmpty) {
      return Response.ok('[]', headers: header);
    }

    final roasters = ids.map((id) => coffeeService.roasterBox.get(id)).whereType<Roaster>().map(_roasterToApi).toList();

    try {
      log.info("getRoasters with ids: $ids, found: ${roasters.length}");
      return Response.ok(jsonEncode(roasters), headers: header);
    } catch (e) {
      log.severe("Error getting roasters for ids $ids: $e");
      return Response(500, body: '{"error":"Failed to retrieve roasters"}', headers: header);
    }
  }

  Response getProfiles(Request request) {
    final ids = _parseProfileIds(request);
    if (ids.isEmpty) {
      return Response.ok('[]', headers: header);
    }

    final profiles = profileService.profiles.where((profile) => ids.contains(profile.id)).map(_profileToApi).toList();

    try {
      log.info("getProfiles with ids: $ids, found: ${profiles.length}");
      return Response.ok(jsonEncode(profiles), headers: header);
    } catch (e) {
      log.severe("Error getting profiles for ids $ids: $e");
      return Response(500, body: '{"error":"Failed to retrieve profiles"}', headers: header);
    }
  }

  Response getRecipes(Request request) {
    final ids = _parseRecipeIds(request);
    final recipes = ids.isEmpty
        ? coffeeService.recipeBox.getAll().map(_recipeToApi).toList()
        : ids.map((id) => coffeeService.recipeBox.get(id)).whereType<Recipe>().map(_recipeToApi).toList();

    try {
      log.info("getRecipes with ids: $ids, found: ${recipes.length}");
      return Response.ok(jsonEncode(recipes), headers: header);
    } catch (e) {
      log.severe("Error getting recipes for ids $ids: $e");
      return Response(500, body: '{"error":"Failed to retrieve recipes"}', headers: header);
    }
  }

  Response deleteShots(Request request) {
    final ids = _parseShotIds(request);
    if (ids.isEmpty) {
      return Response(400, body: '{"error":"ids query parameter is required"}', headers: header);
    }

    var removedCount = 0;
    for (final id in ids) {
      if (coffeeService.shotBox.remove(id)) {
        removedCount++;
      }
    }

    return Response.ok(jsonEncode({'deleted': removedCount, 'requested': ids.length, 'ids': ids}), headers: header);
  }

  Response deleteCoffees(Request request) {
    final ids = _parseCoffeeIds(request);
    if (ids.isEmpty) {
      return Response(400, body: '{"error":"ids query parameter is required"}', headers: header);
    }

    var removedCount = 0;
    for (final id in ids) {
      if (coffeeService.coffeeBox.remove(id)) {
        removedCount++;
      }
    }

    return Response.ok(jsonEncode({'deleted': removedCount, 'requested': ids.length, 'ids': ids}), headers: header);
  }

  Response deleteRoasters(Request request) {
    final ids = _parseRoasterIds(request);
    if (ids.isEmpty) {
      return Response(400, body: '{"error":"ids query parameter is required"}', headers: header);
    }

    var removedCount = 0;
    for (final id in ids) {
      if (coffeeService.roasterBox.remove(id)) {
        removedCount++;
      }
    }

    return Response.ok(jsonEncode({'deleted': removedCount, 'requested': ids.length, 'ids': ids}), headers: header);
  }

  Response deleteRecipes(Request request) {
    final ids = _parseRecipeIds(request);
    if (ids.isEmpty) {
      return Response(400, body: '{"error":"ids query parameter is required"}', headers: header);
    }

    var removedCount = 0;
    for (final id in ids) {
      if (coffeeService.recipeBox.get(id) != null) {
        coffeeService.removeRecipe(id);
        removedCount++;
      }
    }

    return Response.ok(jsonEncode({'deleted': removedCount, 'requested': ids.length, 'ids': ids}), headers: header);
  }

  Response getCoffeeIds() {
    final ids = coffeeService.coffeeBox.getAll().map((coffee) => coffee.id).toList();
    return Response.ok(jsonEncode(ids), headers: header);
  }

  Response getRoasterIds() {
    final ids = coffeeService.roasterBox.getAll().map((roaster) => roaster.id).toList();
    return Response.ok(jsonEncode(ids), headers: header);
  }

  Response getProfileIds() {
    final ids = profileService.profiles.map((profile) => profile.id).toList();
    return Response.ok(jsonEncode(ids), headers: header);
  }

  Response getRecipeIds() {
    final ids = coffeeService.recipeBox.getAll().map((recipe) => recipe.id).toList();
    return Response.ok(jsonEncode(ids), headers: header);
  }

  List<int> _parseShotIds(Request request) {
    final params = request.url.queryParameters;
    final idsParam = params['ids'] ?? params['IDS'] ?? '';
    if (idsParam.trim().isEmpty) {
      return [];
    }
    return idsParam.split(',').map((value) => int.tryParse(value.trim())).whereType<int>().toList();
  }

  List<int> _parseCoffeeIds(Request request) {
    final params = request.url.queryParameters;
    final idsParam = params['ids'] ?? params['IDS'] ?? '';
    if (idsParam.trim().isEmpty) {
      return [];
    }
    return idsParam.split(',').map((value) => int.tryParse(value.trim())).whereType<int>().toList();
  }

  List<int> _parseRoasterIds(Request request) {
    final params = request.url.queryParameters;
    final idsParam = params['ids'] ?? params['IDS'] ?? '';
    if (idsParam.trim().isEmpty) {
      return [];
    }
    return idsParam.split(',').map((value) => int.tryParse(value.trim())).whereType<int>().toList();
  }

  List<String> _parseProfileIds(Request request) {
    final params = request.url.queryParameters;
    final idsParam = params['ids'] ?? params['IDS'] ?? '';
    if (idsParam.trim().isEmpty) {
      return [];
    }
    return idsParam.split(',').map((value) => value.trim()).where((value) => value.isNotEmpty).toList();
  }

  List<int> _parseRecipeIds(Request request) {
    final params = request.url.queryParameters;
    final idsParam = params['ids'] ?? params['IDS'] ?? '';
    if (idsParam.trim().isEmpty) {
      return [];
    }
    return idsParam.split(',').map((value) => int.tryParse(value.trim())).whereType<int>().toList();
  }

  Map<String, dynamic> _shotToApi(Shot shot) {
    final baseTime = shot.date.toUtc();
    final workflowName = shot.description.isNotEmpty ? shot.description : (shot.recipe.target?.name ?? 'shot');
    final measurements = shot.shotstates.map((state) {
      final timestamp = baseTime.add(Duration(milliseconds: _safeMillis(state.sampleTimeCorrected)));
      return {
        'machine': {
          'timestamp': timestamp.toIso8601String(),
          'state': {'state': 'espresso', 'substate': state.subState},
          'flow': _safeNum(state.groupFlow),
          'pressure': _safeNum(state.groupPressure),
          'mixTemperature': _safeNum(state.mixTemp),
        },
        'scale': {'timestamp': timestamp.toIso8601String(), 'weight': _safeNum(state.weight), 'weightFlow': _safeNum(state.flowWeight), 'batteryLevel': 0},
        'volume': _safeNum(state.weight),
      };
    }).toList();

    return {
      'id': shot.id.toString(),
      'timestamp': shot.date.toUtc().toIso8601String(),
      'measurements': measurements,
      'recipe': _recipeToApi(shot.recipe.target),
      'coffee': _coffeeToApi(shot.coffee.target),
      'workflow': {
        'name': workflowName,
        'profileId': shot.profileId.toString(),
        "visualizerId": shot.visualizerId.toString(),
        'doseData': {'doseIn': shot.doseWeight, 'doseOut': shot.drinkWeight},
      },
    };
  }

  Map<String, dynamic> _coffeeToApi(Coffee? coffee) {
    if (coffee == null) {
      return {};
    }
    return {
      'id': coffee.id.toString(),
      'name': coffee.name,
      'description': coffee.description,
      'type': coffee.type,
      'taste': coffee.taste,
      'roasterId': coffee.roaster.targetId.toString(),
      'imageURL': coffee.imageURL,
      'grinderSettings': _safeNum(coffee.grinderSettings),
      'grinderDoseWeight': _safeNum(coffee.grinderDoseWeight),
      'acidRating': _safeNum(coffee.acidRating),
      'intensityRating': _safeNum(coffee.intensityRating),
      'roastLevel': _safeNum(coffee.roastLevel),
      'roastDate': coffee.roastDate.toUtc().toIso8601String(),
      'elevation': coffee.elevation,
      'price': coffee.price,
      'origin': coffee.origin,
      'region': coffee.region,
      'farm': coffee.farm,
      'cropyear': coffee.cropyear.toUtc().toIso8601String(),
      'process': coffee.process,
      'isShot': coffee.isShot,
    };
  }

  Map<String, dynamic> _roasterToApi(Roaster? roaster) {
    if (roaster == null) {
      return {};
    }
    return {
      'id': roaster.id.toString(),
      'name': roaster.name,
      'imageURL': roaster.imageURL,
      'description': roaster.description,
      'address': roaster.address,
      'homepage': roaster.homepage,
    };
  }

  Map<String, dynamic> _profileToApi(De1ShotProfile profile) {
    return {
      'id': profile.id,
      'isDefault': profile.isDefault,
      'title': profile.title,
      'shotHeader': profile.shotHeader.toJson(),
      'shotFrames': profile.shotFrames.map((frame) => frame.toJson()).toList(),
    };
  }

  Map<String, dynamic> _recipeToApi(Recipe? recipe) {
    if (recipe == null) {
      return {};
    }
    return {
      'id': recipe.id.toString(),
      'coffeeId': recipe.coffee.targetId.toString(),
      'profileId': recipe.profileId,
      'adjustedWeight': _safeNum(recipe.adjustedWeight),
      'adjustedPressure': _safeNum(recipe.adjustedPressure),
      'adjustedTemp': _safeNum(recipe.adjustedTemp),
      'grinderDoseWeight': _safeNum(recipe.grinderDoseWeight),
      'grinderSettings': _safeNum(recipe.grinderSettings),
      'grinderModel': recipe.grinderModel,
      'ratio1': _safeNum(recipe.ratio1),
      'ratio2': _safeNum(recipe.ratio2),
      'isDeleted': recipe.isDeleted,
      'isFavorite': recipe.isFavorite,
      'isShot': recipe.isShot,
      'name': recipe.name,
      'description': recipe.description,
      'weightWater': _safeNum(recipe.weightWater),
      'useWater': recipe.useWater,
      'disableStopOnWeight': recipe.disableStopOnWeight,
      'tempWater': _safeNum(recipe.tempWater),
      'timeWater': _safeNum(recipe.timeWater),
      'tempSteam': _safeNum(recipe.tempSteam),
      'flowSteam': _safeNum(recipe.flowSteam),
      'timeSteam': _safeNum(recipe.timeSteam),
      'weightMilk': _safeNum(recipe.weightMilk),
      'useSteam': recipe.useSteam,
    };
  }

  double _safeNum(double value) {
    return value.isFinite ? value : 0.0;
  }

  int _safeMillis(double seconds) {
    return (_safeNum(seconds) * 1000).round();
  }

  EspressoMachineState? _mapTargetToState(String target) {
    switch (target) {
      case 'airPurge':
        return EspressoMachineState.airPurge;
      case 'clean':
        return EspressoMachineState.clean;
      case 'connecting':
        return EspressoMachineState.connecting;
      case 'descale':
        return EspressoMachineState.descale;
      case 'disconnected':
        return EspressoMachineState.disconnected;
      case 'espresso':
        return EspressoMachineState.espresso;
      case 'flush':
        return EspressoMachineState.flush;
      case 'idle':
        return EspressoMachineState.idle;
      case 'refill':
        return EspressoMachineState.refill;
      case 'sleeping':
        return EspressoMachineState.sleep;
      case 'steam':
        return EspressoMachineState.steam;
      case 'hotWater':
        return EspressoMachineState.water;
      default:
        return null;
    }
  }

  stopService() async {
    if (server != null) {
      await streamShotSubscription?.cancel();
      await streamStateSubscription?.cancel();
      await streamBatterySubscription?.cancel();
      await streamWaterSubscription?.cancel();
      await streamScaleSubscription?.cancel();
      await streamScaleBatterySubscription?.cancel();
      for (final socket in _machineStateSockets.toList()) {
        await socket.sink.close();
      }
      _machineStateSockets.clear();
      for (final socket in _scaleSnapshotSockets.toList()) {
        await socket.sink.close();
      }
      _scaleSnapshotSockets.clear();
      for (final socket in _waterLevelSockets.toList()) {
        await socket.sink.close();
      }
      _waterLevelSockets.clear();
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

  void _broadcastScaleSnapshot() {
    if (_scaleSnapshotSockets.isEmpty) {
      return;
    }
    for (final socket in _scaleSnapshotSockets.toList()) {
      _sendScaleSnapshot(socket);
    }
  }

  void _sendScaleSnapshot(WebSocketChannel socket) {
    try {
      socket.sink.add(jsonEncode(_buildScaleSnapshotPayload()));
    } catch (e) {
      _scaleSnapshotSockets.remove(socket);
      socket.sink.close();
    }
  }

  void _broadcastWaterLevelSnapshot() {
    if (_waterLevelSockets.isEmpty) {
      return;
    }
    for (final socket in _waterLevelSockets.toList()) {
      _sendWaterLevelSnapshot(socket);
    }
  }

  void _sendWaterLevelSnapshot(WebSocketChannel socket) {
    try {
      socket.sink.add(jsonEncode(_buildWaterLevelSnapshotPayload()));
    } catch (e) {
      _waterLevelSockets.remove(socket);
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

  Map<String, dynamic> _buildScaleSnapshotPayload() {
    return {'timestamp': DateTime.now().toUtc().toIso8601String(), 'weight': _lastScaleWeight, 'batteryLevel': _lastScaleBattery};
  }

  Map<String, dynamic> _buildWaterLevelSnapshotPayload() {
    return {'currentLevel': _lastWaterLevel, 'refillLevel': _lastRefillLevel};
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

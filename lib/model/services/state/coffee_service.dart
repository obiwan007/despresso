// ignore_for_file: unused_import

import 'dart:convert';

import 'dart:io';

import 'package:despresso/logger_util.dart';
import 'package:despresso/model/coffee.dart';
import 'package:despresso/model/recipe.dart';
import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/services/state/settings_service.dart';
import 'package:despresso/model/shot.dart';
import 'package:despresso/objectbox.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../service_locator.dart';

class CoffeeService extends ChangeNotifier {
  final log = Logger('CoffeeService');
  late ObjectBox objectBox;

  late Box<Coffee> coffeeBox;
  late Box<Roaster> roasterBox;
  late Box<Recipe> recipeBox;
  late Box<Shot> shotBox;

  int selectedRoaster = 0;
  int selectedCoffee = 0;
  int selectedShot = 0;
  int selectedRecipe = 0;

  late StreamController<List<Recipe>> _controllerRecipe;
  late Stream<List<Recipe>> _streamRecipe;

  late SettingsService settings;

  Stream<List<Recipe>> get streamRecipe => _streamRecipe;

  CoffeeService() {
    init();
  }

  void init() async {
    settings = getIt<SettingsService>();
    _controllerRecipe = StreamController<List<Recipe>>();
    _streamRecipe = _controllerRecipe.stream.asBroadcastStream();

    objectBox = getIt<ObjectBox>();
    coffeeBox = objectBox.store.box<Coffee>();
    roasterBox = objectBox.store.box<Roaster>();
    shotBox = objectBox.store.box<Shot>();
    recipeBox = objectBox.store.box<Recipe>();

    await load();
    notifyListeners();
  }

  Shot? getLastShot() {
    var allshots = shotBox.getAll();
    log.info("Number of stored shots: ${allshots.length}");
    if (selectedShot > 0) {
      return shotBox.get(selectedShot);
    } else {
      return Shot();
    }
  }

  addRoaster(Roaster newRoaster) async {
    roasterBox.put(newRoaster);

    // await save();
    notifyListeners();
  }

  deleteRoaster(Roaster r) async {
    await save();
    notifyListeners();
  }

  addCoffee(Coffee newCoffee) async {
    coffeeBox.put(newCoffee);

    await save();
    notifyListeners();
  }

  deleteCoffee(Coffee r) async {
    notifyListeners();
  }

  Future load() async {
    selectedRoaster = settings.selectedRoaster;

    selectedCoffee = settings.selectedCoffee;
    selectedRecipe = settings.selectedRecipe;

    selectedShot = settings.selectedShot;

    log.info("lastshot $selectedShot");

    Future.delayed(
      const Duration(milliseconds: 199),
      () {
        if (roasterBox.count() == 0) {
          log.info("No roasters available. Creating a default one.");
          var r = Roaster();
          r.name = "Default Rouaster";
          selectedRoaster = roasterBox.put(r);
          settings.selectedRoaster = selectedRoaster;
        }

        if (coffeeBox.count() == 0) {
          log.info("No roasters available. Creating a default one.");
          var r = Coffee();
          r.roaster.targetId = selectedRoaster;
          r.name = "Default Beans";
          selectedCoffee = coffeeBox.put(r);
          settings.selectedCoffee = selectedCoffee;
        }
      },
    );

    // try {
    //   log.info("Loading coffees");
    //   final directory = await getApplicationDocumentsDirectory();
    //   log.info("Storing to path:${directory.path}");
    //   var file = File('${directory.path}/db/coffee.json');
    //   if (await file.exists()) {
    //     var json = file.readAsStringSync();
    //     log.info("Loaded: ${json}");
    //     List<dynamic> l = jsonDecode(json);
    //     var data = l.map((value) => Coffee.fromJson(value));
    //     //knownCoffees = data;
    //     this.knownCoffees = data.toList();
    //     log.info("Loaded Coffee entries: ${data.length}");
    //   } else {
    //     log.info("File not existing");
    //   }

    //   var file2 = File('${directory.path}/db/roasters.json');
    //   if (await file2.exists()) {
    //     var json = file2.readAsStringSync();
    //     log.info("Loaded: ${json}");
    //     List<dynamic> l = jsonDecode(json);
    //     var data = l.map((value) => Roaster.fromJson(value));
    //     //knownCoffees = data;
    //     this.knownRoasters = data.toList();
    //     log.info("Loaded Roasters: ${data.length}");
    //   } else {
    //     log.info("Roasters File not existing");
    //   }
    // } catch (ex) {
    //   log.info("loading error");
    // }

    // var id = prefs.getString("selectedRoaster");
    // if (id != null) {
    //   selectedRoaster = knownRoasters.firstWhere((element) => element.id == id);
    // } else {
    //   selectedRoaster = knownRoasters.isNotEmpty ? knownRoasters.first : null;
    // }

    // id = prefs.getString("selectedCoffee");
    // if (id != null) {
    //   selectedCoffee = knownCoffees.firstWhere((element) => element.id == id);
    // } else {
    //   selectedCoffee = knownCoffees.isNotEmpty ? knownCoffees.first : null;
    // }
  }

  save() async {
    // try {
    //   log.info("Storing coffee");

    //   final directory = await getApplicationDocumentsDirectory();
    //   log.info("Storing to path:${directory.path}");

    //   final Directory _appDocDirFolder = Directory('${directory.path}/db/');

    //   if (!_appDocDirFolder.existsSync()) {
    //     await _appDocDirFolder.create(recursive: true);
    //     log.info("Directory created");
    //   }

    //   var file = File('${directory.path}/db/coffee.json');
    //   if (await file.exists()) {
    //     file.deleteSync();
    //   } else {}
    //   var encoded = jsonEncode(knownCoffees);
    //   log.info("Coffee: $encoded");
    //   file.writeAsStringSync(encoded);

    //   file = File('${directory.path}/db/roasters.json');
    //   if (await file.exists()) {
    //     file.deleteSync();
    //   } else {}
    //   encoded = jsonEncode(knownRoasters);
    //   log.info("Roasters: $encoded");
    //   file.writeAsStringSync(encoded);
    // } catch (ex) {
    //   log.info("save error $ex");
    // }
  }

  Future<void> setSelectedRoaster(int id) async {
    if (id == 0) return;

    log.info('Roaster Saving');
    settings.selectedRoaster = id;
    log.info('Roaster Set $id');
    selectedRoaster = id;
    log.info('Roaster Saved');
    notifyListeners();
  }

  Future<void> setSelectedRecipe(int id) async {
    if (id == 0) return;

    selectedRecipe = id;
    settings.selectedRecipe = id;
    var recipe = recipeBox.get(id);

    setSelectedCoffee(recipe!.coffee.targetId);

    var profileService = getIt<ProfileService>();
    var machineService = getIt<EspressoMachineService>();

    profileService.setProfileFromId(recipe.profileId);
    machineService.uploadProfile(profileService.currentProfile!);
    notifyListeners();
  }

  void setSelectedCoffee(int id) {
    if (id == 0) return;

    settings.selectedCoffee = id;
    selectedCoffee = id;

    notifyListeners();
    log.info('Coffee Saved');
  }

  setLastShotId(int id) async {
    selectedShot = id;
    settings.selectedShot = id;
  }

  Coffee? get currentCoffee {
    if (selectedCoffee > 0) {
      return coffeeBox.get(selectedCoffee);
    }
    return null;
// code to return members
  }

  void addRecipe({required String name, required int coffeeId, required String profileId}) {
    var recipe = Recipe();
    recipe.name = name;
    recipe.coffee.targetId = coffeeId;
    recipe.profileId = profileId;
    recipeBox.put(recipe);
    notifyListeners();
    _controllerRecipe.add(getRecipes());
  }

  List<Recipe> getRecipes() {
    return recipeBox.getAll();
  }

  void removeRecipe(int id) {
    recipeBox.remove(id);
    notifyListeners();
    _controllerRecipe.add(getRecipes());
  }

  getBackupData() {
    String file = objectBox.store.directoryPath + "/data.mdb";
    var f = File(file);

    Uint8List data = f.readAsBytesSync();
    log.info("Data read ${data.length}");
    return data;
  }
}

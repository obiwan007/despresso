// ignore_for_file: unused_import

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:despresso/model/coffee.dart';
import 'package:despresso/model/recipe.dart';
import 'package:despresso/model/services/ble/machine_service.dart';
import 'package:despresso/model/services/state/profile_service.dart';
import 'package:despresso/model/shot.dart';
import 'package:despresso/objectbox.dart';
import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../service_locator.dart';

class CoffeeService extends ChangeNotifier {
  late SharedPreferences prefs;

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

  late ProfileService profileService;
  late EspressoMachineService machineService;

  Stream<List<Recipe>> get streamRecipe => _streamRecipe;

  CoffeeService() {
    init();
  }

  void init() async {
    prefs = await SharedPreferences.getInstance();
    _controllerRecipe = StreamController<List<Recipe>>();
    _streamRecipe = _controllerRecipe.stream.asBroadcastStream();

    objectBox = getIt<ObjectBox>();
    coffeeBox = objectBox.store.box<Coffee>();
    roasterBox = objectBox.store.box<Roaster>();
    shotBox = objectBox.store.box<Shot>();
    recipeBox = objectBox.store.box<Recipe>();
    profileService = getIt<ProfileService>();
    machineService = getIt<EspressoMachineService>();

    await load();
    notifyListeners();
  }

  Shot? getLastShot() {
    var allshots = shotBox.getAll();
    log("Number of stored shots: ${allshots.length}");
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
    selectedRoaster = prefs.getInt("selectedRoaster") ?? 0;

    selectedCoffee = prefs.getInt("selectedCoffee") ?? 0;
    selectedRecipe = prefs.getInt("selectedRecipe") ?? 0;

    selectedShot = prefs.getInt("lastShot") ?? 0;

    log("lastshot $selectedShot");
    // try {
    //   log("Loading coffees");
    //   final directory = await getApplicationDocumentsDirectory();
    //   log("Storing to path:${directory.path}");
    //   var file = File('${directory.path}/db/coffee.json');
    //   if (await file.exists()) {
    //     var json = file.readAsStringSync();
    //     log("Loaded: ${json}");
    //     List<dynamic> l = jsonDecode(json);
    //     var data = l.map((value) => Coffee.fromJson(value));
    //     //knownCoffees = data;
    //     this.knownCoffees = data.toList();
    //     log("Loaded Coffee entries: ${data.length}");
    //   } else {
    //     log("File not existing");
    //   }

    //   var file2 = File('${directory.path}/db/roasters.json');
    //   if (await file2.exists()) {
    //     var json = file2.readAsStringSync();
    //     log("Loaded: ${json}");
    //     List<dynamic> l = jsonDecode(json);
    //     var data = l.map((value) => Roaster.fromJson(value));
    //     //knownCoffees = data;
    //     this.knownRoasters = data.toList();
    //     log("Loaded Roasters: ${data.length}");
    //   } else {
    //     log("Roasters File not existing");
    //   }
    // } catch (ex) {
    //   log("loading error");
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
    //   log("Storing coffee");

    //   final directory = await getApplicationDocumentsDirectory();
    //   log("Storing to path:${directory.path}");

    //   final Directory _appDocDirFolder = Directory('${directory.path}/db/');

    //   if (!_appDocDirFolder.existsSync()) {
    //     await _appDocDirFolder.create(recursive: true);
    //     log("Directory created");
    //   }

    //   var file = File('${directory.path}/db/coffee.json');
    //   if (await file.exists()) {
    //     file.deleteSync();
    //   } else {}
    //   var encoded = jsonEncode(knownCoffees);
    //   log("Coffee: $encoded");
    //   file.writeAsStringSync(encoded);

    //   file = File('${directory.path}/db/roasters.json');
    //   if (await file.exists()) {
    //     file.deleteSync();
    //   } else {}
    //   encoded = jsonEncode(knownRoasters);
    //   log("Roasters: $encoded");
    //   file.writeAsStringSync(encoded);
    // } catch (ex) {
    //   log("save error $ex");
    // }
  }

  Future<void> setSelectedRoaster(int id) async {
    if (id == 0) return;

    log('Roaster Saving');
    await prefs.setInt("selectedRoaster", id);
    log('Roaster Set $id');
    selectedRoaster = id;
    log('Roaster Saved');
    notifyListeners();
  }

  Future<void> setSelectedRecipe(int id) async {
    if (id == 0) return;

    selectedRecipe = id;
    prefs.setInt("selectedRecipe", id);
    var recipe = recipeBox.get(id);

    setSelectedCoffee(recipe!.coffee.targetId);
    profileService.setProfileFromId(recipe.profileId);

    machineService.uploadProfile(profileService.currentProfile!);
    notifyListeners();
  }

  void setSelectedCoffee(int id) {
    if (id == 0) return;

    prefs.setInt("selectedCoffee", id);
    selectedCoffee = id;

    // notifyListeners();
    log('Coffee Saved');
  }

  setLastShotId(int id) async {
    selectedShot = id;
    await prefs.setInt("lastShot", id);
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
}

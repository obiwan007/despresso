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
import 'package:objectbox/internal.dart';
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

  int selectedRoasterId = 0;
  int selectedCoffeeId = 0;
  int selectedShotId = 0;
  int selectedRecipeId = 0;

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
    if (selectedShotId > 0) {
      return shotBox.get(selectedShotId);
    } else {
      return (allshots.isNotEmpty) ? allshots.last : Shot();
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
    selectedRoasterId = settings.selectedRoaster;

    selectedCoffeeId = settings.selectedCoffee;
    selectedRecipeId = settings.selectedRecipe;

    selectedShotId = settings.selectedShot;

    log.info("lastshot $selectedShotId");

    Future.delayed(
      const Duration(milliseconds: 199),
      () {
        if (roasterBox.count() == 0) {
          log.info("No roasters available. Creating a default one.");
          var r = Roaster();
          r.name = "Default Rouaster";
          selectedRoasterId = roasterBox.put(r);
          settings.selectedRoaster = selectedRoasterId;
        }

        if (coffeeBox.count() == 0) {
          log.info("No roasters available. Creating a default one.");
          var r = Coffee();
          r.roaster.targetId = selectedRoasterId;
          r.name = "Default Beans";
          selectedCoffeeId = coffeeBox.put(r);
          settings.selectedCoffee = selectedCoffeeId;
        }
      },
    );
  }

  save() async {}

  Future<void> setSelectedRoaster(int id) async {
    if (id == 0) return;

    log.info('Roaster Saving');
    settings.selectedRoaster = id;
    log.info('Roaster Set $id');
    selectedRoasterId = id;
    log.info('Roaster Saved');
    notifyListeners();
  }

  Future<void> setSelectedRecipe(int id) async {
    if (id == 0) return;

    selectedRecipeId = id;
    settings.selectedRecipe = id;
    var recipe = recipeBox.get(id);

    setSelectedCoffee(recipe!.coffee.targetId);

    var profileService = getIt<ProfileService>();
    var machineService = getIt<EspressoMachineService>();
    settings.targetEspressoWeight = recipe.adjustedWeight;
    settings.targetTempCorrection = recipe.adjustedTemp;

    profileService.setProfileFromId(recipe.profileId);
    machineService.uploadProfile(profileService.currentProfile!);
    settings.notifyListeners;
    notifyListeners();
  }

  void setSelectedCoffee(int id) {
    if (id == 0) return;

    settings.selectedCoffee = id;
    selectedCoffeeId = id;

    notifyListeners();
    log.info('Coffee Saved');
  }

  setLastShotId(int id) async {
    selectedShotId = id;
    settings.selectedShot = id;
  }

  Coffee? get currentCoffee {
    if (selectedCoffeeId > 0) {
      return coffeeBox.get(selectedCoffeeId);
    }
    return null;
// code to return members
  }

  Recipe? get currentRecipe {
    if (selectedRecipeId > 0) {
      return recipeBox.get(selectedRecipeId);
    }
    return null;
// code to return members
  }

  void addRecipe({required String name, required int coffeeId, required String profileId}) {
    var recipe = Recipe();
    recipe.name = name;
    recipe.coffee.targetId = coffeeId;
    recipe.profileId = profileId;
    recipe.adjustedWeight = settings.targetEspressoWeight;
    var id = recipeBox.put(recipe);

    settings.selectedRecipe = id;
    selectedRecipeId = id;
    settings.notifyListeners();
    notifyListeners();
    _controllerRecipe.add(getRecipes());
  }

  List<Recipe> getRecipes() {
    return recipeBox.getAll();
  }

  Recipe? getRecipe(int id) {
    return recipeBox.get(id);
  }

  void updateRecipe(Recipe recipe) {
    recipeBox.put(recipe);
    settings.targetEspressoWeight = recipe.adjustedWeight;
    settings.targetTempCorrection = recipe.adjustedTemp;
    notifyListeners();
    _controllerRecipe.add(getRecipes());
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

  void setSelectedRecipeProfile(String profileId) {
    var res = currentRecipe;
    if (res != null) {
      res.profileId = profileId;
      updateRecipe(res);
      notifyListeners();
    }
  }

  void setSelectedRecipeCoffee(int coffeeId) {
    var res = currentRecipe;
    if (res != null) {
      res.coffee.targetId = coffeeId;
      updateRecipe(res);
      notifyListeners();
    }
  }
}

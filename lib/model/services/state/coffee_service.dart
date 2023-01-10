import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:despresso/model/coffee.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CoffeeService extends ChangeNotifier {
  Coffee? currentCoffee;
  List<Coffee> knownCoffees = [];
  List<Roaster> knownRoasters = [];
  late SharedPreferences prefs;

  CoffeeService() {
    init();
  }

  void init() async {
    prefs = await SharedPreferences.getInstance();
    //TODO read coffee
    await load();
    notifyListeners();
  }

  Future<List<Roaster>> getRoaster(String query) async {
    return knownRoasters;
  }

  Future<List<Coffee>> getCoffeeSuggestions(String query, String roasterId) async {
    return knownCoffees;
  }

  updateRoaster(Roaster roaster) async {
    var index = knownRoasters.indexWhere((element) => element.id == roaster.id);
    if (index > -1) {
      knownRoasters[index] = roaster;
    }

    await save();
    notifyListeners();
  }

  addRoaster(Roaster newRoaster) async {
    knownRoasters.insert(0, newRoaster);
    await save();
    notifyListeners();
  }

  deleteRoaster(Roaster r) async {
    knownRoasters.removeWhere((element) => element.id == r.id);
    await save();
    notifyListeners();
  }

  addCoffee(Coffee newCoffee) async {
    knownCoffees.insert(0, newCoffee);
    await save();
    notifyListeners();
  }

  Future load() async {
    try {
      log("Loading coffees");
      final directory = await getApplicationDocumentsDirectory();
      log("Storing to path:${directory.path}");
      var file = File('${directory.path}/db/coffee.json');
      if (await file.exists()) {
        var json = file.readAsStringSync();
        log("Loaded: ${json}");
        List<dynamic> l = jsonDecode(json);
        var data = l.map((value) => Coffee.fromJson(value));
        //knownCoffees = data;
        this.knownCoffees = data.toList();
        log("Loaded entries: $data");
      } else {
        log("File not existing");
      }

      var file2 = File('${directory.path}/db/roasters.json');
      if (await file2.exists()) {
        var json = file2.readAsStringSync();
        log("Loaded: ${json}");
        List<dynamic> l = jsonDecode(json);
        var data = l.map((value) => Roaster.fromJson(value));
        //knownCoffees = data;
        this.knownRoasters = data.toList();
        log("Loaded Roasters: $data");
      } else {
        log("Roasters File not existing");
      }
    } catch (ex) {
      log("loading error");
    }
  }

  save() async {
    try {
      log("Storing coffee");

      final directory = await getApplicationDocumentsDirectory();
      log("Storing to path:${directory.path}");

      final Directory _appDocDirFolder = Directory('${directory.path}/db/');

      if (!_appDocDirFolder.existsSync()) {
        await _appDocDirFolder.create(recursive: true);
        log("Directory created");
      }

      var file = File('${directory.path}/db/coffee.json');
      if (await file.exists()) {
        file.deleteSync();
      } else {}
      var encoded = jsonEncode(knownCoffees);
      log("Coffee: $encoded");
      file.writeAsStringSync(encoded);

      file = File('${directory.path}/db/roasters.json');
      if (await file.exists()) {
        file.deleteSync();
      } else {}
      encoded = jsonEncode(knownRoasters);
      log("Roasters: $encoded");
      file.writeAsStringSync(encoded);
    } catch (ex) {
      log("save error $ex");
    }
  }
}

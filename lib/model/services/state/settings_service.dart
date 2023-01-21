import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:despresso/model/coffee.dart';
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

class SettingsService extends ChangeNotifier {
  // Coffee? currentCoffee;
  // List<Coffee> knownCoffees = [];
  // List<Roaster> knownRoasters = [];
  late SharedPreferences prefs;

  late ObjectBox objectBox;

  SettingsService() {
    init();
  }

  void init() async {
    objectBox = getIt<ObjectBox>();
    // coffeeBox = objectBox.store.box<Coffee>();
    // roasterBox = objectBox.store.box<Roaster>();
    // shotBox = objectBox.store.box<Shot>();

    prefs = await SharedPreferences.getInstance();
    notifyListeners();
  }
}

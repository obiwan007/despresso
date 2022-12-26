import 'package:despresso/model/coffee.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CoffeeService extends ChangeNotifier {
  Coffee? currentCoffee;
  List<Coffee> knownCoffees = [];
  late SharedPreferences prefs;

  CoffeeService() {
    init();
  }

  void init() async {
    prefs = await SharedPreferences.getInstance();
    //TODO read coffee
  }

  Future<List<String>> getRoasterSuggestions(String query) async {
    var matches = await fetchCoffees();

    if (matches.isEmpty) {
      //TODO fetch local storage?
      return <String>[];
    }

    //TODO add last used

    matches.retainWhere(
        (s) => s.roaster.toLowerCase().contains(query.toLowerCase()));
    return matches.map((e) => e.roaster).toList();
  }

  Future<List<String>> getCoffeeSuggestions(
      String query, String roaster) async {
    var matches = await fetchCoffees();

    if (matches.isEmpty) {
      //TODO fetch local storage?
      return <String>[];
    }

    //TODO add last used
    if (roaster != null && roaster != '') {
      matches.retainWhere(
          (s) => s.roaster.toLowerCase().contains(roaster.toLowerCase()));
    }
    matches
        .retainWhere((s) => s.name.toLowerCase().contains(query.toLowerCase()));
    return matches.map((e) => e.name).toList();
  }

  Future<List<Coffee>> fetchCoffees() async {
    final response =
        await http.get(Uri.parse("https://coffee.mimoja.de/api/v1/coffees"));

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.

      List result = await jsonDecode(response.body);
      if (result == null) {
        return [];
      }
      List<Coffee> coffees = result.map((e) => Coffee.fromJson(e)).toList();
      return coffees;
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load album');
    }
  }
}

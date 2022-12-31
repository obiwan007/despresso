import 'package:despresso/model/machine.dart';
import 'package:despresso/model/shotdecoder.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class MachineService extends ChangeNotifier {
  static Future<List<String>> getVendorSuggestions(String query) async {
    var matches = await fetchMachines();

    if (matches.isEmpty) {
      //TODO fetch local storage?
      return [];
    }

    //TODO add last used

    matches.retainWhere(
        (s) => s.vendor.toLowerCase().contains(query.toLowerCase()));
    return matches.map((e) => e.vendor).toList();
  }

  static Future<List<String>> getModellSuggestions(
      String query, String roaster) async {
    var matches = await fetchMachines();

    if (matches.isEmpty) {
      //TODO fetch local storage?
      return [];
    }

    //TODO add last used
    if (roaster != null && roaster != '') {
      matches.retainWhere(
          (s) => s.vendor.toLowerCase().contains(roaster.toLowerCase()));
    }
    matches
        .retainWhere((s) => s.name.toLowerCase().contains(query.toLowerCase()));
    return matches.map((e) => e.name).toList();
  }

  void notify() {
    notifyListeners();
  }

  static Future<List<Machine>> fetchMachines() async {
    final response =
        await http.get(Uri.parse('https://coffee.mimoja.de/api/v1/machines'));

    if (response.statusCode == 200) {
      List result = await jsonDecode(response.body);
      if (result == null) {
        return [];
      }
      List<Machine> machines = result.map((e) => Machine.fromJson(e)).toList();
      return machines;
    } else {
      throw Exception('Failed to load Machines');
    }
  }
}

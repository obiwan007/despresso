import 'dart:convert';
import 'dart:developer';

import 'package:despresso/model/profile.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService extends ChangeNotifier {
  static const String testInput = '''{
    "name": "New Profile",
  "frames": [
    {
      "name": "Infuse",
      "index": 0,
      "temp": 90.0,
      "duration": 7,
      "target": {
        "value": 5.0,
        "type": "flow",
        "interpolate": false
      },
      "trigger": {
        "type": "pressure",
        "value": 1.0,
        "operator": "greater_than"
      }
    },
    {
      "name": "Brew",
      "index": 1,
      "temp": 95.0,
      "duration": 10,
      "target": {
        "value": 2.0,
        "type": "flow",
        "interpolate": false
      },
      "trigger": {
        "type": "flow",
        "value": 4,
        "operator": "greater_than"
      }
    },
    {
      "name": "Brew",
      "index": 2,
      "temp": 90.0,
      "duration": 5,
      "target": {
        "value": 2.0,
        "type": "flow",
        "interpolate": true
      }
    },
    {
      "name": "Brew",
      "index": 3,
      "temp": 90.0,
      "duration": 2,
      "target": {
        "value": 4.0,
        "type": "flow",
        "interpolate": false
      }
    },
    {
      "name": "Brew",
      "index": 4,
      "temp": 90.0,
      "duration": 10,
      "target": {
        "value": 2.0,
        "type": "flow",
        "interpolate": false
      }
    }
  ]
}''';

  late Profile currentProfile;
  List<Profile> knownProfiles = [];
  late SharedPreferences prefs;

  ProfileService() {
    Map userMap = jsonDecode(ProfileService.testInput);
    currentProfile = Profile.fromJson(userMap);
    init();
    Map<String, dynamic> user = jsonDecode(testInput);
    log(user.toString());
  }

  void init() async {
    prefs = await SharedPreferences.getInstance();
    //TODO read profiles
  }
}

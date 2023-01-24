import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:despresso/model/de1shotclasses.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// FrameFlag of zero and pressure of 0 means end of shot, unless we are at the tenth frame, in which case
// it's the end of shot no matter what
// ignore: constant_identifier_names
const int CtrlF = 0x01; // Are we in Pressure or Flow priority mode?
// ignore: constant_identifier_names
const int DoCompare = 0x02; // Do a compare, early exit current frame if compare true
// ignore: constant_identifier_names
const int DC_GT = 0x04; // If we are doing a compare, then 0 = less than, 1 = greater than
// ignore: constant_identifier_names
const int DC_CompF = 0x08; // Compare Pressure or Flow?
// ignore: constant_identifier_names
const int TMixTemp = 0x10; // Disable shower head temperature compensation. Target Mix Temp instead.
// ignore: constant_identifier_names
const int Interpolate = 0x20; // Hard jump to target value, or ramp?
// ignore: constant_identifier_names
const int IgnoreLimit = 0x40; // Ignore minimum pressure and max flow settings

class ProfileService extends ChangeNotifier {
  De1ShotProfile? currentProfile;
  late SharedPreferences prefs;
  List<De1ShotProfile> defaultProfiles = <De1ShotProfile>[];

  List<De1ShotProfile> profiles = <De1ShotProfile>[];

  ProfileService() {
    init();
  }

  void init() async {
    prefs = await SharedPreferences.getInstance();
    log('Preferences loaded');

    var profileId = prefs.getString("profilename");
    await loadAllDefaultProfiles();
    log('Profiles loaded');

    try {
      var dirs = await getSavedProfileFiles();

      for (var element in dirs) {
        log(element.path);
        var i = element.path.lastIndexOf('/');
        var file = element.path.substring(i);
        try {
          var loaded = await loadProfileFromDocuments(file);
          log("Saved profile loaded $loaded");
          var defaultProfile = defaultProfiles.where((element) => element.id == loaded.id);
          if (defaultProfile.isNotEmpty) {
            profiles.add(loaded);
          } else {
            // profiles.add(defaultProfile.first);
          }
        } catch (ex) {
          log("Error loading profile $ex");
        }
      }
      // dirs.forEach((element) => {
      //   loadUserProfile(element.path);
      // });

    } catch (ex) {
      log("List files $ex");
    }

// Add defaultprofile if not already modified;
    for (var prof in defaultProfiles) {
      if (profiles.where((element) => element.id == prof.id).isEmpty) {
        profiles.add(prof);
      }
    }

    currentProfile = profiles.first;
    if (profileId != null && profileId.isNotEmpty) {
      try {
        currentProfile = profiles.where((element) => element.id == profileId).first;
      } catch (_) {}
      log("Profile ${currentProfile!.shotHeader.title} loaded");
    }
    notifyListeners();
  }

  void notify() {
    notifyListeners();
  }

  void setProfileFromId(String profileId) {
    var found = profiles.where((element) => profileId == element.id);
    if (found.isNotEmpty) {
      setProfile(found.first);
    }
  }

  void setProfile(De1ShotProfile profile) {
    currentProfile = profile;
    prefs.setString("profilename", profile.id);
    log("Profile selected and saved ${profile.id}");
    notify();
  }

  saveAsNew(De1ShotProfile profile) {
    log("Saving as a new profile");
    profile.isDefault = false;
    profile.id = const Uuid().toString();
  }

  save(De1ShotProfile profile) async {
    log("Saving as a existing profile to documents region");
    profile.isDefault = false;
    await saveProvileToDocuments(profile, profile.id);
    currentProfile = profile;
    notify();
  }

  Future<List<FileSystemEntity>> getSavedProfileFiles() async {
    final dir = "${(await getApplicationDocumentsDirectory()).path}/profiles";

    String pdfDirectory = '$dir/';

    final myDir = Directory(pdfDirectory);

    var dirs = myDir.listSync(recursive: true, followLinks: false);

    return dirs;
  }

  Future<De1ShotProfile> loadProfileFromDocuments(String fileName) async {
    try {
      log("Loading shot: $fileName");
      final directory = await getApplicationDocumentsDirectory();
      log("LoadingFrom path:${directory.path}");
      var file = File('${directory.path}/profiles/$fileName');
      if (await file.exists()) {
        var json = file.readAsStringSync();

        Map<String, dynamic> map = jsonDecode(json);
        var data = De1ShotProfile.fromJson(map);

        log("Loaded Profile: ${data.id}");
        return data;
      } else {
        log("File $fileName not existing");
        throw Exception("File not found");
      }
    } catch (ex) {
      log("loading error $ex");
      Future.error("Error loading filename $ex");
      rethrow;
    }
  }

  Future<File> saveProvileToDocuments(De1ShotProfile profile, String filename) async {
    log("Storing shot: ${profile.id}");

    final directory = await getApplicationDocumentsDirectory();
    log("Storing to path:${directory.path}");
    final Directory appDocDirFolder = Directory('${directory.path}/profiles/');

    if (!appDocDirFolder.existsSync()) {
      appDocDirFolder.create(recursive: true);
    }

    var file = File('${directory.path}/profiles/$filename');
    if (await file.exists()) {
      file.deleteSync();
    }
    await file.create();
    var json = profile.toJson();
    log("Save json $json");
    return file.writeAsString(jsonEncode(json));
  }

  Future<void> loadAllDefaultProfiles() async {
    var assets = await rootBundle.loadString('AssetManifest.json');
    Map jsondata = json.decode(assets);
    List get = jsondata.keys.where((element) => element.endsWith(".json")).toList();

    for (var file in get) {
      log("Parsing profile $file");
      var rawJson = await rootBundle.loadString(file);
      try {
        parseDefaultProfile(rawJson, true);
      } catch (ex) {
        log("Profile parse error: $ex");
      }
    }
    log('all profiles loaded');
  }

  String parseDefaultProfile(String json, bool isDefault) {
    log("parse json profile data");
    De1ShotHeaderClass header = De1ShotHeaderClass();
    List<De1ShotFrameClass> frames = <De1ShotFrameClass>[];
    List<De1ShotExtFrameClass> exFrames = <De1ShotExtFrameClass>[];
    var p = De1ShotProfile(header, frames, exFrames);
    if (!shotJsonParser(json, p)) return "Failed to encode profile, try to load another profile";

    p.isDefault = isDefault;
    defaultProfiles.add(p);
    log("$header $frames $exFrames");

    return "";
  }

  static bool shotJsonParser(String jsonStr, De1ShotProfile profile) {
    var jsonMap = jsonDecode(jsonStr);
    return shotJsonParserAdvanced(jsonMap, profile);

    // return ShotJsonParserAdvanced(json_obj, shot_header, shot_frames, shot_exframes);
  }

  static double dynamic2Double(dynamic dynData) {
    dynamic d = dynData;

    if (d is double || d is int) {
      return d.toDouble();
    } else if (d is String) {
      return double.parse(d);
    } else {
      return double.negativeInfinity;
    }
  }

  static String dynamic2String(dynamic dynData) {
    dynamic d = dynData;

    if (d is String) {
      return d;
    } else {
      return "";
    }
  }

  static bool shotJsonParserAdvanced(
    Map<String, dynamic> json,
    De1ShotProfile profile,
  ) {
    De1ShotHeaderClass shotHeader = profile.shotHeader;
    List<De1ShotFrameClass> shotFrames = profile.shotFrames;
    List<De1ShotExtFrameClass> shotExframes = profile.shotExframes;
    if (!json.containsKey("version")) return false;
    if (dynamic2Double(json["version"]) != 2.0) return false;

    profile.id = dynamic2String(json["id"]);
    shotHeader.hidden = dynamic2Double(json["hidden"]).toInt();
    shotHeader.type = dynamic2String(json["type"]);
    shotHeader.type = dynamic2String(json["type"]);
    shotHeader.lang = dynamic2String(json["lang"]);
    shotHeader.legacyProfileType = dynamic2String(json["legacy_profile_type"]);
    shotHeader.targetWeight = dynamic2Double(json["target_weight"]);
    shotHeader.targetVolume = dynamic2Double(json["target_volume"]);
    shotHeader.targetVolumeCountStart = dynamic2Double(json["target_volume_count_start"]);
    shotHeader.tankTemperature = dynamic2Double(json["tank_temperature"]);
    shotHeader.title = dynamic2String(json["title"]);
    shotHeader.author = dynamic2String(json["author"]);
    shotHeader.notes = dynamic2String(json["notes"]);
    shotHeader.beverageType = dynamic2String(json["beverage_type"]);

    if (!json.containsKey("steps")) return false;
    for (Map<String, dynamic> frameData in json["steps"]) {
      if (!frameData.containsKey("name")) return false;

      De1ShotFrameClass frame = De1ShotFrameClass();
      var features = IgnoreLimit;

      frame.pump = dynamic2String(frameData["pump"]);
      frame.name = dynamic2String(frameData["name"]);

      // flow control
      if (!frameData.containsKey("pump")) return false;
      var pump = dynamic2String(frameData["pump"]);
      frame.pump = pump;

      if (pump == "") return false;
      if (pump == "flow") {
        features |= CtrlF;
        if (!frameData.containsKey("flow")) return false;
        var flow = dynamic2Double(frameData["flow"]);
        if (flow == double.negativeInfinity) return false;
        frame.setVal = flow;
      } else {
        if (!frameData.containsKey("pressure")) return false;
        var pressure = dynamic2Double(frameData["pressure"]);
        if (pressure == double.negativeInfinity) return false;
        frame.setVal = pressure;
      }

      // use boiler water temperature as the goal
      if (!frameData.containsKey("sensor")) return false;
      var sensor = dynamic2String(frameData["sensor"]);
      if (sensor == "") return false;
      if (sensor == "water") features |= TMixTemp;

      if (!frameData.containsKey("transition")) return false;
      var transition = dynamic2String(frameData["transition"]);
      if (transition == "") return false;

      if (transition == "smooth") features |= Interpolate;

      // "move on if...."
      if (frameData.containsKey("exit")) {
        var exitData = frameData["exit"];

        if (!exitData.containsKey("type")) return false;
        if (!exitData.containsKey("condition")) return false;
        if (!exitData.containsKey("value")) return false;

        var exitType = dynamic2String(exitData["type"]);
        var exitCondition = dynamic2String(exitData["condition"]);
        var exitValue = dynamic2Double(exitData["value"]);

        if (exitType == "pressure" && exitCondition == "under") {
          features |= DoCompare;
          frame.triggerVal = exitValue;
        } else if (exitType == "pressure" && exitCondition == "over") {
          features |= DoCompare | DC_GT;
          frame.triggerVal = exitValue;
        } else if (exitType == "flow" && exitCondition == "under") {
          features |= DoCompare | DC_CompF;
          frame.triggerVal = exitValue;
        } else if (exitType == "flow" && exitCondition == "over") {
          features |= DoCompare | DC_GT | DC_CompF;
          frame.triggerVal = exitValue;
        } else {
          return false;
        }
      } else {
        frame.triggerVal = 0;
      } // no exit condition was checked

      // "limiter...."
      var limiterValue = double.negativeInfinity;
      var limiterRange = double.negativeInfinity;

      if (frameData.containsKey("limiter")) {
        var limiterData = frameData["limiter"];

        if (!limiterData.containsKey("value")) return false;
        if (!limiterData.containsKey("range")) return false;

        limiterValue = dynamic2Double(limiterData["value"]);
        limiterRange = dynamic2Double(limiterData["range"]);
      }

      if (!frameData.containsKey("temperature")) return false;
      if (!frameData.containsKey("seconds")) return false;

      var temperature = dynamic2Double(frameData["temperature"]);
      if (temperature == double.negativeInfinity) return false;
      var seconds = dynamic2Double(frameData["seconds"]);
      if (seconds == double.negativeInfinity) return false;

      int frameCounter = shotFrames.length;

      // MaxVol for the first frame only
      double inputMaxVol = 0.0;
      if (frameCounter == 0 && frameData.containsKey("volume")) {
        inputMaxVol = dynamic2Double(frameData["volume"]);
        if (inputMaxVol == double.negativeInfinity) inputMaxVol = 0.0;
      }

      frame.frameToWrite = frameCounter;
      frame.flag = features;
      frame.temp = temperature;
      frame.frameLen = seconds;
      frame.maxVol = inputMaxVol;
      shotFrames.add(frame);

      if (limiterValue != 0.0 && limiterValue != double.negativeInfinity && limiterRange != double.negativeInfinity) {
        De1ShotExtFrameClass exFrame = De1ShotExtFrameClass();
        exFrame.frameToWrite = (frameCounter + 32).toInt();
        exFrame.limiterValue = limiterValue;
        exFrame.limiterRange = limiterRange;
        shotExframes.add(exFrame);
      }
    }

    // header
    shotHeader.numberOfFrames = shotFrames.length;
    shotHeader.numberOfPreinfuseFrames = 1;

    // update the byte array inside shot header and frame, so we are ready to write it to DE
    encodeHeaderAndFrames(shotHeader, shotFrames, shotExframes);
    return true;
  }

  static encodeHeaderAndFrames(
      De1ShotHeaderClass shotHeader, List<De1ShotFrameClass> shotFrames, List<De1ShotExtFrameClass> shotExframes) {
    shotHeader.bytes = De1ShotHeaderClass.encodeDe1ShotHeader(shotHeader);
    for (var frame in shotFrames) {
      frame.bytes = De1ShotFrameClass.encodeDe1ShotFrame(frame);
    }
    for (var exframe in shotExframes) {
      exframe.bytes = De1ShotExtFrameClass.encodeDe1ExtentionFrame(exframe);
    }
  }
}

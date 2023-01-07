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
const int CtrlF = 0x01; // Are we in Pressure or Flow priority mode?
const int DoCompare = 0x02; // Do a compare, early exit current frame if compare true
const int DC_GT = 0x04; // If we are doing a compare, then 0 = less than, 1 = greater than
const int DC_CompF = 0x08; // Compare Pressure or Flow?
const int TMixTemp = 0x10; // Disable shower head temperature compensation. Target Mix Temp instead.
const int Interpolate = 0x20; // Hard jump to target value, or ramp?
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
        log("${element.path}");
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

  void setProfile(De1ShotProfile profile) {
    currentProfile = profile;
    prefs.setString("profilename", profile.id);
    log("Profile selected and saved ${profile.id}");
  }

  saveAsNew(De1ShotProfile profile) {
    log("Saving as a new profile");
    profile.isDefault = false;
    profile.id = Uuid().toString();
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
      log("Loading shot: ${fileName}");
      final directory = await getApplicationDocumentsDirectory();
      log("LoadingFrom path:${directory.path}");
      var file = File('${directory.path}/profiles/$fileName');
      if (await file.exists()) {
        var json = file.readAsStringSync();
        log("Loaded: ${json}");
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
    final Directory _appDocDirFolder = Directory('${directory.path}/profiles/');

    if (!_appDocDirFolder.existsSync()) {
      _appDocDirFolder.create(recursive: true);
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

  String parseDefaultProfile(String json_string, bool isDefault) {
    log("parse json profile data");
    De1ShotHeaderClass header = De1ShotHeaderClass();
    List<De1ShotFrameClass> frames = <De1ShotFrameClass>[];
    List<De1ShotExtFrameClass> ex_frames = <De1ShotExtFrameClass>[];
    var p = De1ShotProfile(header, frames, ex_frames);
    if (!ShotJsonParser(json_string, p)) return "Failed to encode profile " + ", try to load another profile";

    p.isDefault = isDefault;
    defaultProfiles.add(p);
    log("$header $frames $ex_frames");

    return "";
  }

  static bool ShotJsonParser(String json_string, De1ShotProfile profile) {
    var json_obj = jsonDecode(json_string);
    return ShotJsonParserAdvanced(json_obj, profile);

    // return ShotJsonParserAdvanced(json_obj, shot_header, shot_frames, shot_exframes);
  }

  static double Dynamic2Double(dynamic d_obj) {
    dynamic d = d_obj;

    if (d is double || d is int) {
      return d.toDouble();
    } else if (d is String) {
      return double.parse(d);
    } else {
      return double.negativeInfinity;
    }
  }

  static String Dynamic2String(dynamic d_obj) {
    dynamic d = d_obj;

    if (d is String) {
      return d;
    } else {
      return "";
    }
  }

  static bool ShotJsonParserAdvanced(
    Map<String, dynamic> json_obj,
    De1ShotProfile profile,
  ) {
    De1ShotHeaderClass shot_header = profile.shotHeader;
    List<De1ShotFrameClass> shot_frames = profile.shotFrames;
    List<De1ShotExtFrameClass> shot_exframes = profile.shotExframes;
    if (!json_obj.containsKey("version")) return false;
    if (Dynamic2Double(json_obj["version"]) != 2.0) return false;

    profile.id = Dynamic2String(json_obj["id"]);
    shot_header.hidden = Dynamic2Double(json_obj["hidden"]).toInt();
    shot_header.type = Dynamic2String(json_obj["type"]);
    shot_header.type = Dynamic2String(json_obj["type"]);
    shot_header.lang = Dynamic2String(json_obj["lang"]);
    shot_header.legacyProfileType = Dynamic2String(json_obj["legacy_profile_type"]);
    shot_header.target_weight = Dynamic2Double(json_obj["target_weight"]);
    shot_header.target_volume = Dynamic2Double(json_obj["target_volume"]);
    shot_header.target_volume_count_start = Dynamic2Double(json_obj["target_volume_count_start"]);
    shot_header.tank_temperature = Dynamic2Double(json_obj["tank_temperature"]);
    shot_header.title = Dynamic2String(json_obj["title"]);
    shot_header.author = Dynamic2String(json_obj["author"]);
    shot_header.notes = Dynamic2String(json_obj["notes"]);
    shot_header.beverage_type = Dynamic2String(json_obj["beverage_type"]);

    if (!json_obj.containsKey("steps")) return false;
    for (Map<String, dynamic> frame_obj in json_obj["steps"]) {
      if (!frame_obj.containsKey("name")) return false;

      De1ShotFrameClass frame = new De1ShotFrameClass();
      var features = IgnoreLimit;

      frame.pump = Dynamic2String(frame_obj["pump"]);
      frame.name = Dynamic2String(frame_obj["name"]);

      // flow control
      if (!frame_obj.containsKey("pump")) return false;
      var pump = Dynamic2String(frame_obj["pump"]);
      frame.pump = pump;

      if (pump == "") return false;
      if (pump == "flow") {
        features |= CtrlF;
        if (!frame_obj.containsKey("flow")) return false;
        var flow = Dynamic2Double(frame_obj["flow"]);
        if (flow == double.negativeInfinity) return false;
        frame.setVal = flow;
      } else {
        if (!frame_obj.containsKey("pressure")) return false;
        var pressure = Dynamic2Double(frame_obj["pressure"]);
        if (pressure == double.negativeInfinity) return false;
        frame.setVal = pressure;
      }

      // use boiler water temperature as the goal
      if (!frame_obj.containsKey("sensor")) return false;
      var sensor = Dynamic2String(frame_obj["sensor"]);
      if (sensor == "") return false;
      if (sensor == "water") features |= TMixTemp;

      if (!frame_obj.containsKey("transition")) return false;
      var transition = Dynamic2String(frame_obj["transition"]);
      if (transition == "") return false;

      if (transition == "smooth") features |= Interpolate;

      // "move on if...."
      if (frame_obj.containsKey("exit")) {
        var exit_obj = frame_obj["exit"];

        if (!exit_obj.containsKey("type")) return false;
        if (!exit_obj.containsKey("condition")) return false;
        if (!exit_obj.containsKey("value")) return false;

        var exit_type = Dynamic2String(exit_obj["type"]);
        var exit_condition = Dynamic2String(exit_obj["condition"]);
        var exit_value = Dynamic2Double(exit_obj["value"]);

        if (exit_type == "pressure" && exit_condition == "under") {
          features |= DoCompare;
          frame.triggerVal = exit_value;
        } else if (exit_type == "pressure" && exit_condition == "over") {
          features |= DoCompare | DC_GT;
          frame.triggerVal = exit_value;
        } else if (exit_type == "flow" && exit_condition == "under") {
          features |= DoCompare | DC_CompF;
          frame.triggerVal = exit_value;
        } else if (exit_type == "flow" && exit_condition == "over") {
          features |= DoCompare | DC_GT | DC_CompF;
          frame.triggerVal = exit_value;
        } else {
          return false;
        }
      } else
        frame.triggerVal = 0; // no exit condition was checked

      // "limiter...."
      var limiter_value = double.negativeInfinity;
      var limiter_range = double.negativeInfinity;

      if (frame_obj.containsKey("limiter")) {
        var limiter_obj = frame_obj["limiter"];

        if (!limiter_obj.containsKey("value")) return false;
        if (!limiter_obj.containsKey("range")) return false;

        limiter_value = Dynamic2Double(limiter_obj["value"]);
        limiter_range = Dynamic2Double(limiter_obj["range"]);
      }

      if (!frame_obj.containsKey("temperature")) return false;
      if (!frame_obj.containsKey("seconds")) return false;

      var temperature = Dynamic2Double(frame_obj["temperature"]);
      if (temperature == double.negativeInfinity) return false;
      var seconds = Dynamic2Double(frame_obj["seconds"]);
      if (seconds == double.negativeInfinity) return false;

      int frame_counter = shot_frames.length;

      // MaxVol for the first frame only
      double input_max_vol = 0.0;
      if (frame_counter == 0 && frame_obj.containsKey("volume")) {
        input_max_vol = Dynamic2Double(frame_obj["volume"]);
        if (input_max_vol == double.negativeInfinity) input_max_vol = 0.0;
      }

      frame.frameToWrite = frame_counter;
      frame.flag = features;
      frame.temp = temperature;
      frame.frameLen = seconds;
      frame.maxVol = input_max_vol;
      shot_frames.add(frame);

      if (limiter_value != 0.0 &&
          limiter_value != double.negativeInfinity &&
          limiter_range != double.negativeInfinity) {
        De1ShotExtFrameClass ex_frame = De1ShotExtFrameClass();
        ex_frame.frameToWrite = (frame_counter + 32).toInt();
        ex_frame.limiterValue = limiter_value;
        ex_frame.limiterRange = limiter_range;
        shot_exframes.add(ex_frame);
      }
    }

    // header
    shot_header.numberOfFrames = shot_frames.length;
    shot_header.numberOfPreinfuseFrames = 1;

    // update the byte array inside shot header and frame, so we are ready to write it to DE
    EncodeHeaderAndFrames(shot_header, shot_frames, shot_exframes);
    return true;
  }

  static EncodeHeaderAndFrames(
      De1ShotHeaderClass shot_header, List<De1ShotFrameClass> shot_frames, List<De1ShotExtFrameClass> shot_exframes) {
    shot_header.bytes = De1ShotHeaderClass.encodeDe1ShotHeader(shot_header);
    for (var frame in shot_frames) frame.bytes = De1ShotFrameClass.EncodeDe1ShotFrame(frame);
    for (var exframe in shot_exframes) exframe.bytes = De1ShotExtFrameClass.EncodeDe1ExtentionFrame(exframe);
  }
}

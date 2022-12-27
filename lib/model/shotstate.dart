import 'dart:convert';
import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'dart:developer';

import 'package:path_provider/path_provider.dart';

/// This allows the `User` class to access private members in
/// the generated file. The value for this is *.g.dart, where
/// the star denotes the source file name.
part 'shotstate.g.dart';

@JsonSerializable(explicitToJson: true)
class ShotList {
  bool saving = false;

  bool saved = false;

  ShotList(this.entries);
  List<ShotState> entries;

  factory ShotList.fromJson(Map<String, dynamic> json) =>
      _$ShotListFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$ShotListToJson(this);

  void clear() {
    entries.clear();
    saved = false;
    saving = false;
  }

  void add(ShotState shot) {
    entries.add(shot);
    saved = false;
  }

  void load(String s) async {
    try {
      saved = true;
      log("Loading shot: ${s}");
      final directory = await getApplicationDocumentsDirectory();
      log("Storing to path:${directory.path}");
      var file = File('${directory.path}/$s');
      if (await file.exists()) {
        var json = file.readAsStringSync();
        log("Loaded: ${json}");
        Map<String, dynamic> map = jsonDecode(json);
        var data = ShotList.fromJson(map);
        entries = data.entries;
        log("Loaded entries: ${entries.length}");
      } else {
        log("File $s not existing");
      }
    } catch (ex) {
      log("loading error");
    }
  }

  saveData(String filename) async {
    saving = true;
    log("Storing shot: ${entries.length}");
    if (entries.length > 0) {
      final directory = await getApplicationDocumentsDirectory();
      log("Storing to path:${directory.path}");
      var file = File('${directory.path}/$filename');
      if (await file.exists()) {
        file.delete();
      }

      file.writeAsStringSync(jsonEncode(this));
    }
    saved = true;
    saving = false;
  }
}

@JsonSerializable()
class ShotState {
  ShotState(
      this.sampleTime,
      this.sampleTimeCorrected,
      this.groupPressure,
      this.groupFlow,
      this.mixTemp,
      this.headTemp,
      this.setMixTemp,
      this.setHeadTemp,
      this.setGroupPressure,
      this.setGroupFlow,
      this.frameNumber,
      this.steamTemp,
      this.weight,
      this.subState);

  String subState;
  double weight;
  double sampleTime;
  double sampleTimeCorrected = 0;
  double groupPressure;
  double groupFlow;
  double mixTemp;
  double headTemp;
  double setMixTemp;
  double setHeadTemp;
  double setGroupPressure;
  double setGroupFlow;
  int frameNumber;
  int steamTemp;

  /// A necessary factory constructor for creating a new User instance
  /// from a map. Pass the map to the generated `_$UserFromJson()` constructor.
  /// The constructor is named after the source class, in this case, User.
  factory ShotState.fromJson(Map<String, dynamic> json) =>
      _$ShotStateFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$ShotStateToJson(this);

  // ShotState.fromJson(Map<String, dynamic> json)
  //     : sampleTime = json['sampleTime'],
  //       groupPressure = json['groupPressure'],
  //       groupFlow = json['groupFlow'],
  //       mixTemp = json['mixTemp'],
  //       headTemp = json['headTemp'],
  //       setMixTemp = json['setMixTemp'],
  //       setHeadTemp = json['setHeadTemp'],
  //       setGroupPressure = json['setGroupPressure'],
  //       setGroupFlow = json['setGroupFlow'],
  //       frameNumber = json['frameNumber'],
  //       steamTemp = json['steamTemp'];

  // Map<String, dynamic> toJson() => {
  //       'sampleTime': sampleTime,
  //       'groupPressure': groupPressure,
  //       'groupFlow': groupFlow,
  //       'mixTemp': mixTemp,
  //       'headTemp': headTemp,
  //       'setMixTemp': setMixTemp,
  //       'setHeadTemp': setHeadTemp,
  //       'setGroupPressure': setGroupPressure,
  //       'setGroupFlow': setGroupFlow,
  //       'frameNumber': frameNumber,
  //       'steamTemp': steamTemp,
  //     };
}

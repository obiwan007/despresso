import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
part 'settings.g.dart';

@JsonSerializable()
class Settings {
  int steamSettings = 0; // do not know what is this, use always 0
  int targetSteamTemp = 130;
  int targetSteamLength = 120;
  int targetHotWaterTemp = 85;
  int targetHotWaterVol = 120;
  int targetHotWaterWeight = 120;
  int targetHotWaterLength = 45;
  int targetEspressoVol = 35;
  int targetFlushTime = 3;
  double targetGroupTemp = 98.0; // taken form the shot data

  Settings();

  factory Settings.fromJson(Map<String, dynamic> json) => _$SettingsFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$SettingsToJson(this);

  static Uint8List encodeDe1OtherSetn(Settings otherSetn) {
    Uint8List data = Uint8List(9);

    int index = 0;
    data[index] = otherSetn.steamSettings;
    index++;
    data[index] = otherSetn.targetSteamTemp;
    index++;
    data[index] = otherSetn.targetSteamLength;
    index++;
    data[index] = otherSetn.targetHotWaterTemp;
    index++;
    data[index] = otherSetn.targetHotWaterVol;
    index++;
    data[index] = otherSetn.targetHotWaterLength;
    index++;
    data[index] = otherSetn.targetEspressoVol;
    index++;

    data[index] = otherSetn.targetGroupTemp.toInt();
    index++;
    data[index] = ((otherSetn.targetGroupTemp - otherSetn.targetGroupTemp.floor()) * 256.0).toInt();
    index++;

    return data;
  }
}

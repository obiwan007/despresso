// ------------------ shot header/frame encoding / decoding ------------------------------

import 'dart:developer';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

import 'dart:typed_data';

part "de1shotclasses.g.dart";

class Uint8ListConverter implements JsonConverter<Uint8List, List<int>> {
  const Uint8ListConverter();

  @override
  Uint8List fromJson(List<int> json) {
    return Uint8List.fromList(json);
  }

  @override
  List<int> toJson(Uint8List object) {
    return object.toList();
  }
}

@JsonSerializable()
class De1ShotProfile {
  bool isDefault = false;

  String id = "";

  De1ShotProfile(this.shotHeader, this.shotFrames, this.shotExframes);

  De1ShotHeaderClass shotHeader;
  List<De1ShotFrameClass> shotFrames;
  List<De1ShotExtFrameClass> shotExframes;

  factory De1ShotProfile.fromJson(Map<String, dynamic> json) =>
      _$De1ShotProfileFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$De1ShotProfileToJson(this);

  De1ShotProfile clone() {
    var copy = De1ShotProfile(De1ShotHeaderClass(), [], []);
    copy.id = id;
    copy.isDefault = isDefault;
    copy.shotHeader = shotHeader.clone();
    copy.shotFrames = shotFrames.map((e) => e.clone()).toList();
    copy.shotExframes = shotExframes.map((e) => e.clone()).toList();

    return copy;
  }
}

@JsonSerializable()
class De1ShotHeaderClass // proc spec_shotdescheader
{
  int headerV = 1; // hard-coded
  int numberOfFrames = 0; // total num frames
  int numberOfPreinfuseFrames = 0; // num preinf frames
  int minimumPressure = 0; // hard-coded, read as {
  double maximumFlow = 6; // hard-coded, read as {

  @Uint8ListConverter()
  Uint8List bytes = Uint8List(5);

  int hidden = 0;

  String type = "";

  String lang = "";

  String legacyProfileType = "";

  double target_weight = 0;

  double target_volume = 0;

  double target_volume_count_start = 0;

  double tank_temperature = 0;

  String title = "";

  String author = "";

  String notes = "";

  String beverage_type = "";

  double targetGroupTemp = 0.0; // to compare bytes

  De1ShotHeaderClass();

  factory De1ShotHeaderClass.fromJson(Map<String, dynamic> json) =>
      _$De1ShotHeaderClassFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$De1ShotHeaderClassToJson(this);

  // bool compareBytes(De1ShotHeaderClass sh) {
  //   if (sh.bytes.buffer.lengthInBytes != bytes.buffer.lengthInBytes) {
  //     return false;
  //   }
  //   for (int i = 0; i < sh.bytes.buffer.lengthInBytes; i++) {
  //     if (sh.bytes[i] != bytes[i]) {
  //       return false;
  //     }
  //   }

  //   return true;
  // }
  De1ShotHeaderClass clone() {
    var copy = De1ShotHeaderClass();
    copy.author = author;
    copy.beverage_type = beverage_type;
    copy.bytes = Uint8List.fromList(bytes);
    copy.headerV = headerV;
    copy.hidden = hidden;
    copy.lang = lang;
    copy.legacyProfileType = legacyProfileType;
    copy.maximumFlow = maximumFlow;
    copy.minimumPressure = minimumPressure;
    copy.notes = notes;
    copy.numberOfFrames = numberOfFrames;
    copy.numberOfPreinfuseFrames = numberOfPreinfuseFrames;
    copy.tank_temperature = tank_temperature;
    copy.targetGroupTemp = targetGroupTemp;
    copy.target_volume = target_volume;
    copy.target_volume_count_start = target_volume_count_start;
    copy.target_weight = target_weight;
    copy.title = title;
    copy.type = type;

    return copy;
  }

  @override
  String toString() {
    return "FrameNum:$numberOfFrames(PreFrames:$numberOfPreinfuseFrames) MinPres:$minimumPressure MaxFlow:$maximumFlow";
  }

  static bool decodeDe1ShotHeader(
      ByteData data, De1ShotHeaderClass shotHeader, bool checkEncoding) {
    if (data.buffer.lengthInBytes != 5) return false;

    try {
      int index = 0;
      shotHeader.headerV = data.getUint8(index++);
      shotHeader.numberOfFrames = data.getUint8(index++);
      shotHeader.numberOfPreinfuseFrames = data.getUint8(index++);
      shotHeader.minimumPressure = data.getUint8(index++);
      shotHeader.maximumFlow = data.getUint8(index++) / 16.0;

      if (shotHeader.headerV != 1) {
        return false;
      }

      if (checkEncoding) {
        var array = data.buffer.asUint8List();
        var new_bytes = encodeDe1ShotHeader(shotHeader);
        if (new_bytes.buffer.lengthInBytes != data.buffer.lengthInBytes) {
          return false;
        }
        for (int i = 0; i < new_bytes.buffer.lengthInBytes; i++) {
          if (new_bytes[i] != array[i]) {
            log("Error in decoding header:${new_bytes[i]} != ${array[i]}");
            return false;
          }
        }
      }

      return true;
    } catch (ex) {
      log("Exception in header decode $ex");
      return false;
    }
  }

  static Uint8List encodeDe1ShotHeader(De1ShotHeaderClass shotHeader) {
    Uint8List data = Uint8List(5);

    int index = 0;
    data[index] = shotHeader.headerV;
    index++;
    data[index] = shotHeader.numberOfFrames;
    index++;
    data[index] = shotHeader.numberOfPreinfuseFrames;
    index++;
    data[index] = shotHeader.minimumPressure;
    index++;
    data[index] = (0.5 + shotHeader.maximumFlow * 16.0).toInt();

    index++;
    log('EncodeDe1ShotFrame:$shotHeader ${Helper.toHex(data)}');
    return data;
  }

  static Uint8List encodeDe1ShotTail(int frameToWrite, double maxTotalVolume) {
    Uint8List data = Uint8List(8);

    data[0] = frameToWrite;

    Helper.convert_float_to_U10P0_for_tail(maxTotalVolume, data, 1);

    data[3] = 0;
    data[4] = 0;
    data[5] = 0;
    data[6] = 0;
    data[7] = 0;
    log('encodeDe1ShotTail: Frame#: $frameToWrite Volume:$maxTotalVolume ${Helper.toHex(data)}');
    return data;
  }
}

@JsonSerializable()
class De1ShotFrameClass // proc spec_shotframe
{
  int frameToWrite = 0;
  int flag = 0;
  double setVal = 0; // {
  double temp = 0; // {
  double frameLen = 0.0; // convert_F8_1_7_to_float
  double triggerVal = 0; // {
  double maxVol = 0.0; // convert_bottom_10_of_U10P0
  String name = "";
  String pump = "";
  String sensor = "";
  String transition = "";
  @Uint8ListConverter()
  Uint8List bytes = Uint8List(8);

  De1ShotFrameClass();

  factory De1ShotFrameClass.fromJson(Map<String, dynamic> json) =>
      _$De1ShotFrameClassFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$De1ShotFrameClassToJson(this);

  De1ShotFrameClass clone() {
    var copy = De1ShotFrameClass();
    copy.bytes = Uint8List.fromList(bytes);
    copy.flag = flag;
    copy.frameLen = frameLen;
    copy.frameToWrite = frameToWrite;
    copy.maxVol = maxVol;
    copy.name = name;
    copy.pump = pump;
    copy.sensor = sensor;
    copy.setVal = setVal;
    copy.temp = temp;
    copy.transition = transition;
    copy.triggerVal = triggerVal;

    return copy;
  }

  toDeclineProfile() {
    name = "decline";
    flag = 0x60;
    temp = 88;
  }

  // bool compareBytes(De1ShotFrameClass sh) {
  //   if (sh.bytes.buffer.lengthInBytes != bytes.buffer.lengthInBytes) {
  //     return false;
  //   }
  //   for (int i = 0; i < sh.bytes.buffer.lengthInBytes; i++) {
  //     if (sh.bytes[i] != bytes[i]) {
  //       return false;
  //     }
  //   }

  //   return true;
  // }

  static bool DecodeDe1ShotFrame(
      ByteData data, De1ShotFrameClass shot_frame, bool check_encoding) {
    if (data.buffer.lengthInBytes != 8) return false;
    log('DecodeDe1ShotFrame:${Helper.toHex(data.buffer.asUint8List())}');
    try {
      int index = 0;
      shot_frame.frameToWrite = data.getUint8(index++);

      shot_frame.flag = data.getUint8(index++);
      shot_frame.setVal = data.getUint8(index++) / 16.0;
      shot_frame.temp = data.getUint8(index++) / 2.0;
      shot_frame.frameLen =
          Helper.convert_F8_1_7_to_float(data.getUint8(index++));
      shot_frame.triggerVal = data.getUint8(index++) / 16.0;
      shot_frame.maxVol = Helper.convert_bottom_10_of_U10P0(
          256 * data.getUint8(index++) +
              data.getUint8(index++)); // convert_bottom_10_of_U10P0

      if (check_encoding) {
        var array = data.buffer.asUint8List();
        var new_bytes = EncodeDe1ShotFrame(shot_frame);
        if (new_bytes.length != array.buffer.lengthInBytes) {
          log("Error in decoding frame Length not matching");
          return false;
        }

        for (int i = 0; i < new_bytes.length; i++) {
          if (new_bytes[i] != array[i]) {
            log("Error in decoding frame:${new_bytes[i]} != ${array[i]}");
            return false;
          }
        }
      }

      return true;
    } catch (ex) {
      log("Exception $ex");
      return false;
    }
  }

  static Uint8List EncodeDe1ShotFrame(De1ShotFrameClass shot_frame) {
    Uint8List data = Uint8List(8);

    int index = 0;
    data[index] = shot_frame.frameToWrite;
    index++;
    data[index] = shot_frame.flag;
    index++;
    data[index] = (0.5 + shot_frame.setVal * 16.0).toInt();
    index++; // note to add 0.5, as "round" is used, not truncate
    data[index] = (0.5 + shot_frame.temp * 2.0).toInt();
    index++;
    data[index] = Helper.convert_float_to_F8_1_7(shot_frame.frameLen);
    log("FrameLen ${data[index].toRadixString(16)}");
    index++;
    data[index] = (0.5 + shot_frame.triggerVal * 16.0).toInt();
    index++;
    Helper.convert_float_to_U10P0(shot_frame.maxVol, data, index);
    log('EncodeDe1ShotFrame:$shot_frame ${Helper.toHex(data)}');
    return data;
  }

  @override
  String toString() {
    const int CtrlF = 0x01; // Are we in Pressure or Flow priority mode?
    const int DoCompare =
        0x02; // Do a compare, early exit current frame if compare true
    const int DC_GT =
        0x04; // If we are doing a compare, then 0 = less than, 1 = greater than
    const int DC_CompF = 0x08; // Compare Pressure or Flow?
    const int TMixTemp =
        0x10; // Disable shower head temperature compensation. Target Mix Temp instead.
    const int Interpolate = 0x20; // Hard jump to target value, or ramp?
    const int IgnoreLimit =
        0x40; // Ignore minimum pressure and max flow settings

    var flagStr = "";
    if ((flag & CtrlF) > 0) flagStr += "CtrlF";
    if ((flag & DoCompare) > 0) flagStr += " DoCompare";
    if ((flag & DC_GT) > 0) flagStr += " DC_GT";
    if ((flag & DC_CompF) > 0) flagStr += " DC_CompF";
    if ((flag & TMixTemp) > 0) flagStr += " TMixTemp";
    if ((flag & Interpolate) > 0) flagStr += " Interpolate";
    if ((flag & IgnoreLimit) > 0) flagStr += " IgnoreLimit";

    // StringBuilder sb = new StringBuilder();
    var sb = "";
    bytes.forEach((b) {
      sb += "${b.toRadixString(16)}-";
    });
    return "Frame:$name $frameToWrite Flag:$flag/0x${flag.toRadixString(16)} $flagStr Value:$setVal Temp:$temp FrameLen:$frameLen TriggerVal:$triggerVal MaxVol:$maxVol B:$sb";
  }
}

@JsonSerializable()
class De1ShotExtFrameClass // extended frames
{
  int frameToWrite = 0;
  double limiterValue = 0.0;
  double limiterRange = 0.0;
  @Uint8ListConverter()
  Uint8List bytes = Uint8List(8);

  De1ShotExtFrameClass();
  factory De1ShotExtFrameClass.fromJson(Map<String, dynamic> json) =>
      _$De1ShotExtFrameClassFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$De1ShotExtFrameClassToJson(this);
  De1ShotExtFrameClass clone() {
    var copy = De1ShotExtFrameClass();
    copy.bytes = Uint8List.fromList(bytes);
    copy.frameToWrite = frameToWrite;
    copy.limiterRange = limiterRange;
    copy.limiterValue = limiterValue;

    return copy;
  }

  bool compareBytes(De1ShotExtFrameClass sh) {
    if (sh.bytes.buffer.lengthInBytes != bytes.buffer.lengthInBytes) {
      return false;
    }
    for (int i = 0; i < sh.bytes.buffer.lengthInBytes; i++) {
      if (sh.bytes[i] != bytes[i]) {
        return false;
      }
    }

    return true;
  }

  static Uint8List EncodeDe1ExtentionFrame(De1ShotExtFrameClass exshot) {
    return EncodeDe1ExtentionFrame2(
        exshot.frameToWrite, exshot.limiterValue, exshot.limiterRange);
  }

  static Uint8List EncodeDe1ExtentionFrame2(
      int frameToWrite, double limit_value, double limit_range) {
    Uint8List data = Uint8List(8);

    data[0] = frameToWrite;

    data[1] = (0.5 + limit_value * 16.0).toInt();
    data[2] = (0.5 + limit_range * 16.0).toInt();

    data[3] = 0;
    data[4] = 0;
    data[5] = 0;
    data[6] = 0;
    data[7] = 0;

    return data;
  }

  @override
  String toString() {
    var sb = "";
    bytes.forEach((b) {
      sb += "${b.toRadixString(16)}-";
    });

    return "Frame:$frameToWrite Limiter:$limiterValue LimiterRange:$limiterRange   $sb";
  }
}

class Helper {
  static String toHex(Uint8List data) {
    var sb = "";
    data.forEach((b) {
      sb += "${b.toRadixString(16)}-";
    });
    return sb;
  }

  static double convert_F8_1_7_to_float(int x) {
    if ((x & 128) == 0) {
      return x / 10.0;
    } else {
      return (x & 127).toDouble();
    }
  }

  static int convert_float_to_F8_1_7(double x) {
    var ret = 0;
    if (x >= 12.75) // need to set the high bit on (0x80);
    {
      if (x > 127)
        ret = (127 | 0x80);
      else
        ret = (0x80 | (0.5 + x).toInt());
    } else {
      ret = (0.5 + x * 10).toInt();
    }
    return ret;
  }

  static void convert_float_to_U10P0_for_tail(
      double x, Uint8List data, int index) {
    int ix = x.toInt();

    if (ix > 255) // lets make life esier and limit x to 255
      ix = 255;

    data[index] = 0x4; // take PI into account
    data[index + 1] = ix;
  }

  static double convert_bottom_10_of_U10P0(int x) {
    return (x & 1023).toDouble();
  }

  static convert_float_to_U10P0(double x, Uint8List data, int index) {
    Uint8List d = Uint8List(2);

    int ix = x.toInt() | 1024;
    d.buffer.asByteData().setInt16(0, ix);

    // if (ix > 255) {
    //   ix = 255;
    // }

    data[index] = d.buffer.asByteData().getUint8(0);
    data[index + 1] = d.buffer.asByteData().getUint8(1);

    log("Final: $x = ${data[index]} ${data[index + 1]}");
  }
}

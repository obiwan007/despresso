// ------------------ shot header/frame encoding / decoding ------------------------------

import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:logging/logging.dart';

part "de1shotclasses.g.dart";

class Uint8ListConverter implements JsonConverter<Uint8List, List<dynamic>> {
  const Uint8ListConverter();

  @override
  Uint8List fromJson(List<dynamic> json) {
    return Uint8List.fromList(List.from(json));
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

  factory De1ShotProfile.fromJson(Map<String, dynamic> json) => _$De1ShotProfileFromJson(json);

  String get title => shotHeader.title;

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

  De1ShotFrameClass? firstFrame() {
    if (shotFrames.isEmpty) return null;

    return shotFrames.first;
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

  double targetWeight = 0;

  double targetVolume = 0;

  double targetVolumeCountStart = 0;

  double tankTemperature = 0;

  String title = "";

  String author = "";

  String notes = "";

  String beverageType = "";

  double targetGroupTemp = 0.0; // to compare bytes

  De1ShotHeaderClass();

  factory De1ShotHeaderClass.fromJson(Map<String, dynamic> json) => _$De1ShotHeaderClassFromJson(json);

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
    copy.beverageType = beverageType;
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
    copy.tankTemperature = tankTemperature;
    copy.targetGroupTemp = targetGroupTemp;
    copy.targetVolume = targetVolume;
    copy.targetVolumeCountStart = targetVolumeCountStart;
    copy.targetWeight = targetWeight;
    copy.title = title;
    copy.type = type;

    return copy;
  }

  @override
  String toString() {
    return "FrameNum:$numberOfFrames(PreFrames:$numberOfPreinfuseFrames) MinPres:$minimumPressure MaxFlow:$maximumFlow";
  }

  static bool decodeDe1ShotHeader(ByteData data, De1ShotHeaderClass shotHeader, bool checkEncoding) {
    final log = Logger('decodeDe1ShotHeader');
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
        var newBytes = encodeDe1ShotHeader(shotHeader);
        if (newBytes.buffer.lengthInBytes != data.buffer.lengthInBytes) {
          return false;
        }
        for (int i = 0; i < newBytes.buffer.lengthInBytes; i++) {
          if (newBytes[i] != array[i]) {
            log.severe("Error in decoding header:${newBytes[i]} != ${array[i]}");
            return false;
          }
        }
      }

      return true;
    } catch (ex) {
      log.severe("Exception in header decode $ex");
      return false;
    }
  }

  static Uint8List encodeDe1ShotHeader(De1ShotHeaderClass shotHeader) {
    final log = Logger('encodeDe1ShotHeader');

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
    log.fine('EncodeDe1ShotFrame:$shotHeader ${Helper.toHex(data)}');
    return data;
  }

  static Uint8List encodeDe1ShotTail(int frameToWrite, double maxTotalVolume) {
    final log = Logger('encodeDe1ShotTail');

    Uint8List data = Uint8List(8);

    data[0] = frameToWrite;

    Helper.convert_float_to_U10P0_for_tail(maxTotalVolume, data, 1);

    data[3] = 0;
    data[4] = 0;
    data[5] = 0;
    data[6] = 0;
    data[7] = 0;
    log.fine('encodeDe1ShotTail: Frame#: $frameToWrite Volume:$maxTotalVolume ${Helper.toHex(data)}');
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

  static int CtrlF = 0x01; // Are we in Pressure or Flow priority mode?
  // ignore: constant_identifier_names
  static int DoCompare = 0x02; // Do a compare, early exit current frame if compare true
  // ignore: constant_identifier_names
  static int DC_GT = 0x04; // If we are doing a compare, then 0 = less than, 1 = greater than
  // ignore: constant_identifier_names
  static int DC_CompF = 0x08; // Compare Pressure or Flow?
  // ignore: constant_identifier_names
  static int TMixTemp = 0x10; // Disable shower head temperature compensation. Target Mix Temp instead.
  // ignore: constant_identifier_names
  static int Interpolate = 0x20; // Hard jump to target value, or ramp?
  // ignore: constant_identifier_names
  static int IgnoreLimit = 0x40; // Ignore minimum pressure and max flow settings

  factory De1ShotFrameClass.fromJson(Map<String, dynamic> json) => _$De1ShotFrameClassFromJson(json);

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

  static bool decodeDe1ShotFrame(ByteData data, De1ShotFrameClass shotFrame, bool checkEncoding) {
    final log = Logger('decodeDe1ShotFrame');

    if (data.buffer.lengthInBytes != 8) return false;
    log.fine('DecodeDe1ShotFrame:${Helper.toHex(data.buffer.asUint8List())}');
    try {
      int index = 0;
      shotFrame.frameToWrite = data.getUint8(index++);

      shotFrame.flag = data.getUint8(index++);
      shotFrame.setVal = data.getUint8(index++) / 16.0;
      shotFrame.temp = data.getUint8(index++) / 2.0;
      shotFrame.frameLen = Helper.convert_F8_1_7_to_float(data.getUint8(index++));
      shotFrame.triggerVal = data.getUint8(index++) / 16.0;
      shotFrame.maxVol = Helper.convert_bottom_10_of_U10P0(
          256 * data.getUint8(index++) + data.getUint8(index++)); // convert_bottom_10_of_U10P0

      if (checkEncoding) {
        var array = data.buffer.asUint8List();
        var newBytes = encodeDe1ShotFrame(shotFrame);
        if (newBytes.length != array.buffer.lengthInBytes) {
          log.severe("Error in decoding frame Length not matching");
          return false;
        }

        for (int i = 0; i < newBytes.length; i++) {
          if (newBytes[i] != array[i]) {
            // todo: fix issue with encoding/decoding error.
            log.info("Error in decoding frame:${newBytes[i]} != ${array[i]}");
            return false;
          }
        }
      }

      return true;
    } catch (ex) {
      log.severe("Exception $ex");
      return false;
    }
  }

  static Uint8List encodeDe1ShotFrame(De1ShotFrameClass shotFrame) {
    final log = Logger('encodeDe1ShotFrame');

    Uint8List data = Uint8List(8);

    int index = 0;
    data[index] = shotFrame.frameToWrite;
    index++;
    data[index] = shotFrame.flag;
    index++;
    data[index] = (0.5 + shotFrame.setVal * 16.0).toInt();
    index++; // note to add 0.5, as "round" is used, not truncate
    data[index] = (0.5 + shotFrame.temp * 2.0).toInt();
    index++;
    data[index] = Helper.convert_float_to_F8_1_7(shotFrame.frameLen);
    log.fine("FrameLen ${data[index].toRadixString(16)}");
    index++;
    data[index] = (0.5 + shotFrame.triggerVal * 16.0).toInt();
    index++;
    Helper.convert_float_to_U10P0(shotFrame.maxVol, data, index);
    log.fine('EncodeDe1ShotFrame:$shotFrame ${Helper.toHex(data)}');
    return data;
  }

  @override
  String toString() {
    // ignore: constant_identifier_names
//     const int CtrlF = 0x01; // Are we in Pressure or Flow priority mode?
//     // ignore: constant_identifier_names
//     const int DoCompare = 0x02; // Do a compare, early exit current frame if compare true
//     // ignore: constant_identifier_names
//     const int DC_GT = 0x04; // If we are doing a compare, then 0 = less than, 1 = greater than
//     // ignore: constant_identifier_names
//     const int DC_CompF = 0x08; // Compare Pressure or Flow?
//     // ignore: constant_identifier_names
//     const int TMixTemp = 0x10; // Disable shower head temperature compensation. Target Mix Temp instead.
//     // ignore: constant_identifier_names
// // Hard jump to target value, or ramp?
//     // ignore: constant_identifier_names
//     const int IgnoreLimit = 0x40; // Ignore minimum pressure and max flow settings

    var flagStr = "";
    if ((flag & CtrlF) > 0) flagStr += "CtrlF";
    if ((flag & DoCompare) > 0) flagStr += " DoCompare";
    if ((flag & DC_GT) > 0) flagStr += " DC_GT";
    if ((flag & DC_CompF) > 0) flagStr += " DC_CompF";
    if ((flag & TMixTemp) > 0) flagStr += " TMixTemp";
    if ((flag & 0x20) > 0) flagStr += " Interpolate";
    if ((flag & IgnoreLimit) > 0) flagStr += " IgnoreLimit";

    // StringBuilder sb = new StringBuilder();
    var sb = "";
    for (var b in bytes) {
      sb += "${b.toRadixString(16)}-";
    }
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
  factory De1ShotExtFrameClass.fromJson(Map<String, dynamic> json) => _$De1ShotExtFrameClassFromJson(json);

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

  static Uint8List encodeDe1ExtentionFrame(De1ShotExtFrameClass exshot) {
    return encodeDe1ExtentionFrame2(exshot.frameToWrite, exshot.limiterValue, exshot.limiterRange);
  }

  static Uint8List encodeDe1ExtentionFrame2(int frameToWrite, double limitValue, double limitRange) {
    Uint8List data = Uint8List(8);

    data[0] = frameToWrite;

    data[1] = (0.5 + limitValue * 16.0).toInt();
    data[2] = (0.5 + limitRange * 16.0).toInt();

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
    for (var b in bytes) {
      sb += "${b.toRadixString(16)}-";
    }

    return "Frame:$frameToWrite Limiter:$limiterValue LimiterRange:$limiterRange   $sb";
  }
}

class Helper {
  static String toHex(Uint8List data) {
    var sb = "";
    for (var b in data) {
      sb += "${b.toRadixString(16)}-";
    }
    return sb;
  }

  // ignore: non_constant_identifier_names
  static double convert_F8_1_7_to_float(int x) {
    if ((x & 128) == 0) {
      return x / 10.0;
    } else {
      return (x & 127).toDouble();
    }
  }

  // ignore: non_constant_identifier_names
  static int convert_float_to_F8_1_7(double x) {
    var ret = 0;
    if (x >= 12.75) // need to set the high bit on (0x80);
    {
      if (x > 127) {
        ret = (127 | 0x80);
      } else {
        ret = (0x80 | (0.5 + x).toInt());
      }
    } else {
      ret = (0.5 + x * 10).toInt();
    }
    return ret;
  }

  // ignore: non_constant_identifier_names
  static void convert_float_to_U10P0_for_tail(double x, Uint8List data, int index) {
    int ix = x.toInt();

    if (ix > 255) {
      ix = 255;
    }

    data[index] = 0x4; // take PI into account
    data[index + 1] = ix;
  }

  // ignore: non_constant_identifier_names
  static double convert_bottom_10_of_U10P0(int x) {
    return (x & 1023).toDouble();
  }

  // ignore: non_constant_identifier_names
  static convert_float_to_U10P0(double x, Uint8List data, int index) {
    final log = Logger('convert_float_to_U10P0');

    Uint8List d = Uint8List(2);

    int ix = x.toInt() | 1024;
    d.buffer.asByteData().setInt16(0, ix);

    // if (ix > 255) {
    //   ix = 255;
    // }

    data[index] = d.buffer.asByteData().getUint8(0);
    data[index + 1] = d.buffer.asByteData().getUint8(1);

    log.fine("Final: $x = ${data[index]} ${data[index + 1]}");
  }
}

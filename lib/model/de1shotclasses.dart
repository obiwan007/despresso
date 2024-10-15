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

@JsonSerializable(explicitToJson: true)
class De1ShotProfile {
  // Will this help us migrate to decent v2 json schema?
  String? semanticVersion = "0.0.9";

  bool isDefault = false;

  String id = "";

  De1ShotProfile(this.shotHeader, this.shotFrames);

  De1ShotHeaderClass shotHeader;

  List<De1ShotFrameClass> shotFrames;

  factory De1ShotProfile.fromJson(Map<String, dynamic> json) {
    De1ShotProfile profile = _$De1ShotProfileFromJson(json);
    profile.shotHeader.numberOfFrames = profile.shotFrames.length;
    return profile;
  }

  String get title => shotHeader.title;

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() {
// just in case we have a mismatch
    shotHeader.numberOfFrames = shotFrames.length;
    return _$De1ShotProfileToJson(this);
  }

  De1ShotProfile clone() {
    var copy = De1ShotProfile(De1ShotHeaderClass(), []);
    copy.id = id;
    copy.isDefault = isDefault;
    copy.shotHeader = shotHeader.clone();
    copy.shotFrames = shotFrames.map((e) => e.clone()).toList();

    return copy;
  }

  De1ShotFrameClass? firstFrame() {
    if (shotFrames.isEmpty) return null;

    return shotFrames.first;
  }

  void deleteStep(int index) {
    if (index < 0 || index >= shotFrames.length) return;
    shotFrames.removeAt(index);
    shotHeader.numberOfFrames = shotFrames.length;
  }

  void insertStep(int index, De1ShotFrameClass frame) {
    if (index < 0 || index >= shotFrames.length) return;
    shotFrames.insert(index, frame);
    shotHeader.numberOfFrames = shotFrames.length;
  }

  void reorderStep(int oldIndex, int direction) {
    if (oldIndex < 0 || oldIndex >= shotFrames.length) return;
    if (oldIndex + direction < 0 || oldIndex + direction >= shotFrames.length)
      return;
    var frame = shotFrames.removeAt(oldIndex);
    shotFrames.insert(oldIndex + direction, frame);
  }

  // TODO: presently unused - consider migrating header data into profile to avoid issues with synchronizing data
  void updateStep(int index, De1ShotFrameClass frame) {
    if (index < 0 || index >= shotFrames.length) return;
    shotFrames[index] = frame;
  }

  void addStep(De1ShotFrameClass frame) {
    shotFrames.add(frame);
    shotHeader.numberOfFrames = shotFrames.length;
  }

  void addStepAt(int index, De1ShotFrameClass frame) {
    shotFrames.insert(index, frame);
    shotHeader.numberOfFrames = shotFrames.length;
  }

  void setHeader(De1ShotHeaderClass header) {
    shotHeader = header;
  }

  void setFrames(List<De1ShotFrameClass> frames) {
    shotFrames = frames;
    shotHeader.numberOfFrames = shotFrames.length;
  }
}

class De1ProfileMachineData {
  Uint8List headerData;
  List<Uint8List> frameData;
  List<Uint8List> extFrameData;
  Uint8List tailData;

  De1ProfileMachineData._internal(
      this.headerData, this.frameData, this.extFrameData, this.tailData);

  factory De1ProfileMachineData(De1ShotProfile profile) {
    List<Uint8List> frameData = [];
    List<Uint8List> extFrameData = [];
    int i = 0;
    for (i; i < profile.shotFrames.length; i++) {
      De1ShotFrameClass frame = profile.shotFrames[i];
      frameData.add(De1ShotFrameClass.encodeDe1ShotFrame(frame, i));
      if (frame.limiter != null) {
        extFrameData.add(De1ShotFrameClass.encodeDe1ExtentionFrame(frame, i));
      }
    }
    Uint8List tailData = Uint8List(8);

    tailData[0] = i;

    Helper.convert_float_to_U10P0_for_tail(
        profile.shotHeader.targetVolume, tailData, 1);

    return De1ProfileMachineData._internal(
        profile.shotHeader.encode(), frameData, extFrameData, tailData);
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

  @JsonKey(includeToJson: false, includeFromJson: false)
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

  double targetGroupTemp = 0.0;

  String version = "2";

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

  static bool decodeDe1ShotHeader(
      ByteData data, De1ShotHeaderClass shotHeader, bool checkEncoding) {
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
            log.severe(
                "Error in decoding header:${newBytes[i]} != ${array[i]}");
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

  Uint8List encode() {
    return De1ShotHeaderClass.encodeDe1ShotHeader(this);
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
    log.fine(
        'encodeDe1ShotTail: Frame#: $frameToWrite Volume:$maxTotalVolume ${Helper.toHex(data)}');
    return data;
  }
}

enum De1PumpMode {
  @JsonValue("pressure")
  pressure,
  @JsonValue("flow")
  flow
}

enum De1SensorType {
  @JsonValue("water")
  water,
  @JsonValue("coffee")
  coffee
}

enum De1Transition {
  @JsonValue("fast")
  fast,
  @JsonValue("smooth")
  smooth
}

@JsonSerializable()
class De1StepLimiterData {
  double value = 0.0;
  double range = 0.6;

  De1StepLimiterData();

  factory De1StepLimiterData.fromJson(Map<String, dynamic> json) =>
      _$De1StepLimiterDataFromJson(json);

  Map<String, dynamic> toJson() => _$De1StepLimiterDataToJson(this);

  De1StepLimiterData clone() {
    return De1StepLimiterData()
      ..value = value
      ..range = range;
  }
}

@JsonSerializable()
class De1ShotFrameClass // proc spec_shotframe
{
  int flag = 0;
  double setVal = 0; // {
  double temp = 0; // {
  double frameLen = 0.0; // convert_F8_1_7_to_float
  double triggerVal = 0; // {
  double maxVol = 0.0; // convert_bottom_10_of_U10P0
  double maxWeight = 0.0;
  String name = "";
  De1PumpMode pump = De1PumpMode.pressure;
  De1SensorType sensor = De1SensorType.water;
  De1Transition transition = De1Transition.fast;
  De1StepLimiterData? limiter;
  @JsonKey(ignore: true)
  @Uint8ListConverter()
  Uint8List bytes = Uint8List(8);

  static const int extFrameOffset = 32;

  // helpers for limiter values
  @JsonKey(ignore: true)
  double get limiterValue => limiter?.value ?? 0;
  set limiterValue(double value) {
    if (limiter != null) {
      limiter!.value = value;
    } else {
      limiter = De1StepLimiterData()..value = value;
    }
  }

  @JsonKey(ignore: true)
  double get limiterRange => limiter?.range ?? 0;
  set limiterRange(double range) {
    if (limiter != null) {
      limiter!.range = range;
    } else {
      limiter = De1StepLimiterData()..range = range;
    }
  }

  De1ShotFrameClass();

  static int ctrlF = 0x01; // Are we in Pressure or Flow priority mode?
  // ignore: constant_identifier_names
  static int doCompare =
      0x02; // Do a compare, early exit current frame if compare true
  // ignore: constant_identifier_names
  static int dcGT =
      0x04; // If we are doing a compare, then 0 = less than, 1 = greater than
  // ignore: constant_identifier_names
  static int dcCompF = 0x08; // Compare Pressure or Flow?
  // ignore: constant_identifier_names
  static int tMixTemp =
      0x10; // Disable shower head temperature compensation. Target Mix Temp instead.
  // ignore: constant_identifier_names
  static int interpolate = 0x20; // Hard jump to target value, or ramp?
  // ignore: constant_identifier_names
  static int ignoreLimit =
      0x40; // Ignore minimum pressure and max flow settings

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
    copy.maxVol = maxVol;
    copy.name = name;
    copy.pump = pump;
    copy.sensor = sensor;
    copy.setVal = setVal;
    copy.temp = temp;
    copy.transition = transition;
    copy.triggerVal = triggerVal;
    copy.maxWeight = maxWeight;
    copy.limiter = limiter?.clone();

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

  static Uint8List encodeDe1ShotFrame(
      De1ShotFrameClass shotFrame, int frameIndex) {
    final log = Logger('encodeDe1ShotFrame');

    Uint8List data = Uint8List(8);

    int index = 0;
    data[index] = frameIndex;
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

  static Uint8List encodeDe1ExtentionFrame(
      De1ShotFrameClass frame, int frameIndex) {
    int frameToWrite = frameIndex + De1ShotFrameClass.extFrameOffset;
    Uint8List data = Uint8List(8);

    data[0] = frameToWrite;

    if (frame.limiter == null) {
      return data;
    }
    double limiterValue = frame.limiter!.value;
    double limiterRange = frame.limiter!.range;

    data[1] = (0.5 + limiterValue * 16.0).toInt();
    data[2] = (0.5 + limiterRange * 16.0).toInt();

    data[3] = 0;
    data[4] = 0;
    data[5] = 0;
    data[6] = 0;
    data[7] = 0;

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
    if ((flag & ctrlF) > 0) flagStr += "CtrlF";
    if ((flag & doCompare) > 0) flagStr += " DoCompare";
    if ((flag & dcGT) > 0) flagStr += " DC_GT";
    if ((flag & dcCompF) > 0) flagStr += " DC_CompF";
    if ((flag & tMixTemp) > 0) flagStr += " TMixTemp";
    if ((flag & 0x20) > 0) flagStr += " Interpolate";
    if ((flag & ignoreLimit) > 0) flagStr += " IgnoreLimit";

    // StringBuilder sb = new StringBuilder();
    var sb = "";
    for (var b in bytes) {
      sb += "${b.toRadixString(16)}-";
    }
    return "Frame:$name Flag:$flag/0x${flag.toRadixString(16)} $flagStr Value:$setVal Temp:$temp FrameLen:$frameLen TriggerVal:$triggerVal MaxVol:$maxVol LimitValue: ${limiter?.value ?? 0} LimitRange: ${limiter?.range ?? 0} B:$sb BEX: ${De1ShotFrameClass.encodeDe1ExtentionFrame(this, 0)}";
  }
}

class Helper {
  static String toHex(Uint8List data) {
    var sb = "";
    for (var b in data) {
      sb += " ${b.toRadixString(16).padLeft(2, "0")}";
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
  static void convert_float_to_U10P0_for_tail(
      double maxTotalVolume, Uint8List data, int index) {
    int ix = maxTotalVolume.toInt();

    if (ix > 1023) {
      // clamp to 1 liter, should be enough for a tasty brew
      ix = 1023;
    }
    // there is a mismatch between docs and actual implementation in the firmware
    // instead 0f 0x8000 for ignorePI, 0x400 sets PI counting to enabled.
    data[index] = ix >> 8; // Ignore preinfusion, only measure volume afterwards
    data[index + 1] = (ix & 0xff);
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

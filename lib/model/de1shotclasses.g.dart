// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'de1shotclasses.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

De1ShotProfile _$De1ShotProfileFromJson(Map<String, dynamic> json) =>
    De1ShotProfile(
      De1ShotHeaderClass.fromJson(json['shotHeader'] as Map<String, dynamic>),
      (json['shotFrames'] as List<dynamic>)
          .map((e) => De1ShotFrameClass.fromJson(e as Map<String, dynamic>))
          .toList(),
    )
      ..semanticVersion = json['semanticVersion'] as String?
      ..isDefault = json['isDefault'] as bool
      ..id = json['id'] as String;

Map<String, dynamic> _$De1ShotProfileToJson(De1ShotProfile instance) =>
    <String, dynamic>{
      'semanticVersion': instance.semanticVersion,
      'isDefault': instance.isDefault,
      'id': instance.id,
      'shotHeader': instance.shotHeader.toJson(),
      'shotFrames': instance.shotFrames.map((e) => e.toJson()).toList(),
    };

De1ShotHeaderClass _$De1ShotHeaderClassFromJson(Map<String, dynamic> json) =>
    De1ShotHeaderClass()
      ..headerV = (json['headerV'] as num).toInt()
      ..numberOfFrames = (json['numberOfFrames'] as num).toInt()
      ..numberOfPreinfuseFrames =
          (json['numberOfPreinfuseFrames'] as num).toInt()
      ..minimumPressure = (json['minimumPressure'] as num).toInt()
      ..maximumFlow = (json['maximumFlow'] as num).toDouble()
      ..hidden = (json['hidden'] as num).toInt()
      ..type = json['type'] as String
      ..lang = json['lang'] as String
      ..legacyProfileType = json['legacyProfileType'] as String
      ..targetWeight = (json['targetWeight'] as num).toDouble()
      ..targetVolume = (json['targetVolume'] as num).toDouble()
      ..targetVolumeCountStart =
          (json['targetVolumeCountStart'] as num).toDouble()
      ..tankTemperature = (json['tankTemperature'] as num).toDouble()
      ..title = json['title'] as String
      ..author = json['author'] as String
      ..notes = json['notes'] as String
      ..beverageType = json['beverageType'] as String
      ..targetGroupTemp = (json['targetGroupTemp'] as num).toDouble()
      ..version = json['version'] as String;

Map<String, dynamic> _$De1ShotHeaderClassToJson(De1ShotHeaderClass instance) =>
    <String, dynamic>{
      'headerV': instance.headerV,
      'numberOfFrames': instance.numberOfFrames,
      'numberOfPreinfuseFrames': instance.numberOfPreinfuseFrames,
      'minimumPressure': instance.minimumPressure,
      'maximumFlow': instance.maximumFlow,
      'hidden': instance.hidden,
      'type': instance.type,
      'lang': instance.lang,
      'legacyProfileType': instance.legacyProfileType,
      'targetWeight': instance.targetWeight,
      'targetVolume': instance.targetVolume,
      'targetVolumeCountStart': instance.targetVolumeCountStart,
      'tankTemperature': instance.tankTemperature,
      'title': instance.title,
      'author': instance.author,
      'notes': instance.notes,
      'beverageType': instance.beverageType,
      'targetGroupTemp': instance.targetGroupTemp,
      'version': instance.version,
    };

De1StepLimiterData _$De1StepLimiterDataFromJson(Map<String, dynamic> json) =>
    De1StepLimiterData()
      ..value = (json['value'] as num).toDouble()
      ..range = (json['range'] as num).toDouble();

Map<String, dynamic> _$De1StepLimiterDataToJson(De1StepLimiterData instance) =>
    <String, dynamic>{
      'value': instance.value,
      'range': instance.range,
    };

De1ShotFrameClass _$De1ShotFrameClassFromJson(Map<String, dynamic> json) =>
    De1ShotFrameClass()
      ..flag = (json['flag'] as num).toInt()
      ..setVal = (json['setVal'] as num).toDouble()
      ..temp = (json['temp'] as num).toDouble()
      ..frameLen = (json['frameLen'] as num).toDouble()
      ..triggerVal = (json['triggerVal'] as num).toDouble()
      ..maxVol = (json['maxVol'] as num).toDouble()
      ..maxWeight = (json['maxWeight'] as num).toDouble()
      ..name = json['name'] as String
      ..pump = $enumDecode(_$De1PumpModeEnumMap, json['pump'])
      ..sensor = $enumDecode(_$De1SensorTypeEnumMap, json['sensor'])
      ..transition = $enumDecode(_$De1TransitionEnumMap, json['transition'])
      ..limiter = json['limiter'] == null
          ? null
          : De1StepLimiterData.fromJson(
              json['limiter'] as Map<String, dynamic>);

Map<String, dynamic> _$De1ShotFrameClassToJson(De1ShotFrameClass instance) =>
    <String, dynamic>{
      'flag': instance.flag,
      'setVal': instance.setVal,
      'temp': instance.temp,
      'frameLen': instance.frameLen,
      'triggerVal': instance.triggerVal,
      'maxVol': instance.maxVol,
      'maxWeight': instance.maxWeight,
      'name': instance.name,
      'pump': _$De1PumpModeEnumMap[instance.pump]!,
      'sensor': _$De1SensorTypeEnumMap[instance.sensor]!,
      'transition': _$De1TransitionEnumMap[instance.transition]!,
      'limiter': instance.limiter,
    };

const _$De1PumpModeEnumMap = {
  De1PumpMode.pressure: 'pressure',
  De1PumpMode.flow: 'flow',
};

const _$De1SensorTypeEnumMap = {
  De1SensorType.water: 'water',
  De1SensorType.coffee: 'coffee',
};

const _$De1TransitionEnumMap = {
  De1Transition.fast: 'fast',
  De1Transition.smooth: 'smooth',
};

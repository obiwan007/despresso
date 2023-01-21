// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'de1shotclasses.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

De1ShotProfile _$De1ShotProfileFromJson(Map<String, dynamic> json) => De1ShotProfile(
      De1ShotHeaderClass.fromJson(json['shotHeader'] as Map<String, dynamic>),
      (json['shotFrames'] as List<dynamic>).map((e) => De1ShotFrameClass.fromJson(e as Map<String, dynamic>)).toList(),
      (json['shotExframes'] as List<dynamic>)
          .map((e) => De1ShotExtFrameClass.fromJson(e as Map<String, dynamic>))
          .toList(),
    )
      ..isDefault = json['isDefault'] as bool
      ..id = json['id'] as String;

Map<String, dynamic> _$De1ShotProfileToJson(De1ShotProfile instance) => <String, dynamic>{
      'isDefault': instance.isDefault,
      'id': instance.id,
      'shotHeader': instance.shotHeader,
      'shotFrames': instance.shotFrames,
      'shotExframes': instance.shotExframes,
    };

De1ShotHeaderClass _$De1ShotHeaderClassFromJson(Map<String, dynamic> json) => De1ShotHeaderClass()
  ..headerV = json['headerV'] as int
  ..numberOfFrames = json['numberOfFrames'] as int
  ..numberOfPreinfuseFrames = json['numberOfPreinfuseFrames'] as int
  ..minimumPressure = json['minimumPressure'] as int
  ..maximumFlow = (json['maximumFlow'] as num).toDouble()
  ..bytes = const Uint8ListConverter().fromJson(json['bytes'] as List)
  ..hidden = json['hidden'] as int
  ..type = json['type'] as String
  ..lang = json['lang'] as String
  ..legacyProfileType = json['legacyProfileType'] as String
  ..targetWeight = (json['target_weight'] as num).toDouble()
  ..targetVolume = (json['target_volume'] as num).toDouble()
  ..targetVolumeCountStart = (json['target_volume_count_start'] as num).toDouble()
  ..tankTemperature = (json['tank_temperature'] as num).toDouble()
  ..title = json['title'] as String
  ..author = json['author'] as String
  ..notes = json['notes'] as String
  ..beverageType = json['beverage_type'] as String
  ..targetGroupTemp = (json['targetGroupTemp'] as num).toDouble();

Map<String, dynamic> _$De1ShotHeaderClassToJson(De1ShotHeaderClass instance) => <String, dynamic>{
      'headerV': instance.headerV,
      'numberOfFrames': instance.numberOfFrames,
      'numberOfPreinfuseFrames': instance.numberOfPreinfuseFrames,
      'minimumPressure': instance.minimumPressure,
      'maximumFlow': instance.maximumFlow,
      'bytes': const Uint8ListConverter().toJson(instance.bytes),
      'hidden': instance.hidden,
      'type': instance.type,
      'lang': instance.lang,
      'legacyProfileType': instance.legacyProfileType,
      'target_weight': instance.targetWeight,
      'target_volume': instance.targetVolume,
      'target_volume_count_start': instance.targetVolumeCountStart,
      'tank_temperature': instance.tankTemperature,
      'title': instance.title,
      'author': instance.author,
      'notes': instance.notes,
      'beverage_type': instance.beverageType,
      'targetGroupTemp': instance.targetGroupTemp,
    };

De1ShotFrameClass _$De1ShotFrameClassFromJson(Map<String, dynamic> json) => De1ShotFrameClass()
  ..frameToWrite = json['frameToWrite'] as int
  ..flag = json['flag'] as int
  ..setVal = (json['setVal'] as num).toDouble()
  ..temp = (json['temp'] as num).toDouble()
  ..frameLen = (json['frameLen'] as num).toDouble()
  ..triggerVal = (json['triggerVal'] as num).toDouble()
  ..maxVol = (json['maxVol'] as num).toDouble()
  ..name = json['name'] as String
  ..pump = json['pump'] as String
  ..sensor = json['sensor'] as String
  ..transition = json['transition'] as String
  ..bytes = const Uint8ListConverter().fromJson(json['bytes'] as List);

Map<String, dynamic> _$De1ShotFrameClassToJson(De1ShotFrameClass instance) => <String, dynamic>{
      'frameToWrite': instance.frameToWrite,
      'flag': instance.flag,
      'setVal': instance.setVal,
      'temp': instance.temp,
      'frameLen': instance.frameLen,
      'triggerVal': instance.triggerVal,
      'maxVol': instance.maxVol,
      'name': instance.name,
      'pump': instance.pump,
      'sensor': instance.sensor,
      'transition': instance.transition,
      'bytes': const Uint8ListConverter().toJson(instance.bytes),
    };

De1ShotExtFrameClass _$De1ShotExtFrameClassFromJson(Map<String, dynamic> json) => De1ShotExtFrameClass()
  ..frameToWrite = json['frameToWrite'] as int
  ..limiterValue = (json['limiterValue'] as num).toDouble()
  ..limiterRange = (json['limiterRange'] as num).toDouble()
  ..bytes = const Uint8ListConverter().fromJson(json['bytes'] as List);

Map<String, dynamic> _$De1ShotExtFrameClassToJson(De1ShotExtFrameClass instance) => <String, dynamic>{
      'frameToWrite': instance.frameToWrite,
      'limiterValue': instance.limiterValue,
      'limiterRange': instance.limiterRange,
      'bytes': const Uint8ListConverter().toJson(instance.bytes),
    };

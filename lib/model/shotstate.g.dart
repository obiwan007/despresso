// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shotstate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShotList _$ShotListFromJson(Map<String, dynamic> json) => ShotList(
      (json['entries'] as List<dynamic>)
          .map((e) => ShotState.fromJson(e as Map<String, dynamic>))
          .toList(),
    )
      ..saving = json['saving'] as bool
      ..saved = json['saved'] as bool;

Map<String, dynamic> _$ShotListToJson(ShotList instance) => <String, dynamic>{
      'saving': instance.saving,
      'saved': instance.saved,
      'entries': instance.entries.map((e) => e.toJson()).toList(),
    };

ShotState _$ShotStateFromJson(Map<String, dynamic> json) => ShotState(
      (json['sampleTime'] as num).toDouble(),
      (json['sampleTimeCorrected'] as num).toDouble(),
      (json['groupPressure'] as num).toDouble(),
      (json['groupFlow'] as num).toDouble(),
      (json['mixTemp'] as num).toDouble(),
      (json['headTemp'] as num).toDouble(),
      (json['setMixTemp'] as num).toDouble(),
      (json['setHeadTemp'] as num).toDouble(),
      (json['setGroupPressure'] as num).toDouble(),
      (json['setGroupFlow'] as num).toDouble(),
      json['frameNumber'] as int,
      json['steamTemp'] as int,
      (json['weight'] as num).toDouble(),
      json['subState'] as String,
    );

Map<String, dynamic> _$ShotStateToJson(ShotState instance) => <String, dynamic>{
      'subState': instance.subState,
      'weight': instance.weight,
      'sampleTime': instance.sampleTime,
      'sampleTimeCorrected': instance.sampleTimeCorrected,
      'groupPressure': instance.groupPressure,
      'groupFlow': instance.groupFlow,
      'mixTemp': instance.mixTemp,
      'headTemp': instance.headTemp,
      'setMixTemp': instance.setMixTemp,
      'setHeadTemp': instance.setHeadTemp,
      'setGroupPressure': instance.setGroupPressure,
      'setGroupFlow': instance.setGroupFlow,
      'frameNumber': instance.frameNumber,
      'steamTemp': instance.steamTemp,
    };

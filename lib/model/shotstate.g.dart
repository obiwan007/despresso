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
      ..lastTouched = (json['lastTouched'] as num).toInt()
      ..saved = json['saved'] as bool;

Map<String, dynamic> _$ShotListToJson(ShotList instance) => <String, dynamic>{
      'saving': instance.saving,
      'lastTouched': instance.lastTouched,
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
      (json['frameNumber'] as num).toInt(),
      (json['steamTemp'] as num).toInt(),
      (json['weight'] as num).toDouble(),
      json['subState'] as String,
    )
      ..id = (json['id'] as num).toInt()
      ..pourTime = (json['pourTime'] as num).toDouble()
      ..flowWeight = (json['flowWeight'] as num).toDouble()
      ..timeToWeight = (json['timeToWeight'] as num).toDouble()
      ..isPouring = json['isPouring'] as bool
      ..isInterpolated = json['isInterpolated'] as bool;

Map<String, dynamic> _$ShotStateToJson(ShotState instance) => <String, dynamic>{
      'id': instance.id,
      'subState': instance.subState,
      'weight': instance.weight,
      'sampleTime': instance.sampleTime,
      'sampleTimeCorrected': instance.sampleTimeCorrected,
      'pourTime': instance.pourTime,
      'groupPressure': instance.groupPressure,
      'groupFlow': instance.groupFlow,
      'mixTemp': instance.mixTemp,
      'headTemp': instance.headTemp,
      'setMixTemp': instance.setMixTemp,
      'setHeadTemp': instance.setHeadTemp,
      'setGroupPressure': instance.setGroupPressure,
      'setGroupFlow': instance.setGroupFlow,
      'flowWeight': instance.flowWeight,
      'frameNumber': instance.frameNumber,
      'steamTemp': instance.steamTemp,
      'timeToWeight': instance.timeToWeight,
      'isPouring': instance.isPouring,
      'isInterpolated': instance.isInterpolated,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Settings _$SettingsFromJson(Map<String, dynamic> json) => Settings()
  ..steamSettings = json['steamSettings'] as int
  ..targetSteamTemp = json['targetSteamTemp'] as int
  ..targetSteamLength = json['targetSteamLength'] as int
  ..targetMilkTemperature = json['targetMilkTemperature'] as int
  ..targetHotWaterTemp = json['targetHotWaterTemp'] as int
  ..targetHotWaterVol = json['targetHotWaterVol'] as int
  ..targetHotWaterWeight = json['targetHotWaterWeight'] as int
  ..targetHotWaterLength = json['targetHotWaterLength'] as int
  ..targetEspressoVol = json['targetEspressoVol'] as int
  ..targetFlushTime = json['targetFlushTime'] as int
  ..targetGroupTemp = (json['targetGroupTemp'] as num).toDouble();

Map<String, dynamic> _$SettingsToJson(Settings instance) => <String, dynamic>{
      'steamSettings': instance.steamSettings,
      'targetSteamTemp': instance.targetSteamTemp,
      'targetSteamLength': instance.targetSteamLength,
      'targetMilkTemperature': instance.targetMilkTemperature,
      'targetHotWaterTemp': instance.targetHotWaterTemp,
      'targetHotWaterVol': instance.targetHotWaterVol,
      'targetHotWaterWeight': instance.targetHotWaterWeight,
      'targetHotWaterLength': instance.targetHotWaterLength,
      'targetEspressoVol': instance.targetEspressoVol,
      'targetFlushTime': instance.targetFlushTime,
      'targetGroupTemp': instance.targetGroupTemp,
    };

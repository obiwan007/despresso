// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

T_Request _$T_RequestFromJson(Map<String, dynamic> json) => T_Request(
      command: json['command'] as String,
      id: (json['id'] as num).toInt(),
      params: json['params'] as Map<String, dynamic>?,
    )..type = json['type'] as String;

Map<String, dynamic> _$T_RequestToJson(T_Request instance) => <String, dynamic>{
      'type': instance.type,
      'command': instance.command,
      'params': instance.params,
      'id': instance.id,
    };

T_ScanResult _$T_ScanResultFromJson(Map<String, dynamic> json) => T_ScanResult()
  ..MAC = json['MAC'] as String
  ..Name = json['Name'] as String
  ..UUIDs = (json['UUIDs'] as List<dynamic>).map((e) => e as String).toList();

Map<String, dynamic> _$T_ScanResultToJson(T_ScanResult instance) =>
    <String, dynamic>{
      'MAC': instance.MAC,
      'Name': instance.Name,
      'UUIDs': instance.UUIDs,
    };

T_ErrorDesc _$T_ErrorDescFromJson(Map<String, dynamic> json) => T_ErrorDesc()
  ..eid = (json['eid'] as num).toInt()
  ..errmsg = json['errmsg'] as String;

Map<String, dynamic> _$T_ErrorDescToJson(T_ErrorDesc instance) =>
    <String, dynamic>{
      'eid': instance.eid,
      'errmsg': instance.errmsg,
    };

T_ConnectionStateNotify _$T_ConnectionStateNotifyFromJson(
        Map<String, dynamic> json) =>
    T_ConnectionStateNotify()
      ..MAC = json['MAC'] as String
      ..CState = json['CState'] as String
      ..UUIDs =
          (json['UUIDs'] as List<dynamic>).map((e) => e as String).toList();

Map<String, dynamic> _$T_ConnectionStateNotifyToJson(
        T_ConnectionStateNotify instance) =>
    <String, dynamic>{
      'MAC': instance.MAC,
      'CState': instance.CState,
      'UUIDs': instance.UUIDs,
    };

T_Results_GATTNotify _$T_Results_GATTNotifyFromJson(
        Map<String, dynamic> json) =>
    T_Results_GATTNotify()
      ..MAC = json['MAC'] as String
      ..Char = json['Char'] as String
      ..Data = json['Data'] as String;

Map<String, dynamic> _$T_Results_GATTNotifyToJson(
        T_Results_GATTNotify instance) =>
    <String, dynamic>{
      'MAC': instance.MAC,
      'Char': instance.Char,
      'Data': instance.Data,
    };

T_Response _$T_ResponseFromJson(Map<String, dynamic> json) => T_Response()
  ..type = json['type'] as String
  ..error = json['error'] == null
      ? null
      : T_ErrorDesc.fromJson(json['error'] as Map<String, dynamic>)
  ..id = (json['id'] as num).toInt()
  ..results = json['results'] as Map<String, dynamic>?;

Map<String, dynamic> _$T_ResponseToJson(T_Response instance) =>
    <String, dynamic>{
      'type': instance.type,
      'error': instance.error,
      'id': instance.id,
      'results': instance.results,
    };

T_Update _$T_UpdateFromJson(Map<String, dynamic> json) => T_Update()
  ..type = json['type'] as String
  ..update = json['update'] as String
  ..id = (json['id'] as num).toInt()
  ..results = json['results'] as Map<String, dynamic>?;

Map<String, dynamic> _$T_UpdateToJson(T_Update instance) => <String, dynamic>{
      'type': instance.type,
      'update': instance.update,
      'id': instance.id,
      'results': instance.results,
    };

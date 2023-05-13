import 'package:json_annotation/json_annotation.dart';
import 'package:logging/logging.dart';

part 'data_models.g.dart';

const String T_MsgType_REQ = "REQ";

@JsonSerializable()
class T_Request {
  T_Request({required this.command, required this.id, this.params});
  String type = T_MsgType_REQ;
  String command;
  Map<String, dynamic>? params;
  int id = 0;

  Map<String, dynamic> toJson() => _$T_RequestToJson(this);
  factory T_Request.fromJson(Map<String, dynamic> json) => _$T_RequestFromJson(json);

  @override
  toString() {
    return "$id $type $command $params";
  }
}

// export type T_UpdateResult = T_ScanResult | T_Results_GATTNotify | T_ConnectionStateNotify | T_ErrorDesc;

abstract class T_UpdateResult {}

@JsonSerializable()
class T_ScanResult implements T_UpdateResult {
  String MAC = "";
  String Name = "";
  List<String> UUIDs = [];
  T_ScanResult();

  @override
  String toString() {
    return "$MAC $Name $UUIDs";
  }

  factory T_ScanResult.fromJson(Map<String, dynamic> json) => _$T_ScanResultFromJson(json);
}

@JsonSerializable()
class T_ErrorDesc implements T_UpdateResult {
  int eid = 0;
  String errmsg = "";
  T_ErrorDesc();
  factory T_ErrorDesc.fromJson(Map<String, dynamic> json) => _$T_ErrorDescFromJson(json);
}

@JsonSerializable()
class T_ConnectionStateNotify implements T_UpdateResult {
  String MAC = "";
  String CState = "";
  List<String> UUIDs = [];
  T_ConnectionStateNotify();
  factory T_ConnectionStateNotify.fromJson(Map<String, dynamic> json) => _$T_ConnectionStateNotifyFromJson(json);

  @override
  String toString() {
    return "$MAC $CState $UUIDs";
  }
}

@JsonSerializable()
class T_Results_GATTNotify implements T_UpdateResult {
  String MAC = "";
  String Char = "";
  String Data = "";
  T_Results_GATTNotify();
  factory T_Results_GATTNotify.fromJson(Map<String, dynamic> json) => _$T_Results_GATTNotifyFromJson(json);
}

abstract class T_IncomingMsg {
  String type = ""; // T_MsgType
  int id = 0;
  Map<String, dynamic>? results;
}

@JsonSerializable()
class T_Response implements T_IncomingMsg {
  @override
  String type = "RESP"; // T_MsgType
  T_ErrorDesc? error;

  T_Response();

  Map<String, dynamic> toJson() => _$T_ResponseToJson(this);
  factory T_Response.fromJson(Map<String, dynamic> json) => _$T_ResponseFromJson(json);

  @override
  int id = 0;

  @override
  Map<String, dynamic>? results;

  @override
  toString() {
    return "$type $results $error";
  }
}

@JsonSerializable()
class T_Update implements T_IncomingMsg {
  final log = Logger("T_Update");

  @override
  String type = "UPDATE"; // T_MsgType
  String update = "";

  T_Update();

  @override
  int id = 0;

  @override
  Map<String, dynamic>? results;
  Map<String, dynamic> toJson() => _$T_UpdateToJson(this);
  factory T_Update.fromJson(Map<String, dynamic> json) => _$T_UpdateFromJson(json);

  @override
  String toString() {
    return "$id $update $results";
  }
}

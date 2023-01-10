import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:uuid/uuid.dart' as uuid;

part 'coffee.g.dart';

@JsonSerializable()
class Coffee {
  String name = "";
  String roasterId = "";
  String imageURL = "";
  String id = "";
  int grinderSettings = 0;

  int acidRating = 3;
  int intensityRating = 3;
  int roastLevel = 3;

  int arabica = 50;
  int robusta = 50;

  String description = "";
  String origin = "";

  String price = "";

  Coffee() {
    id = uuid.Uuid().v4().toString();
  }

  factory Coffee.fromJson(Map<String, dynamic> json) => _$CoffeeFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$CoffeeToJson(this);
}

@JsonSerializable()
class Roaster {
  String name = "";
  String imageURL = "";
  String id = "";
  String description = "";
  String address = "";
  String homepage = "";

  Roaster() {
    id = uuid.Uuid().v4().toString();
  }

  factory Roaster.fromJson(Map<String, dynamic> json) => _$RoasterFromJson(json);

  /// `toJson` is the convention for a class to declare support for serialization
  /// to JSON. The implementation simply calls the private, generated
  /// helper method `_$UserToJson`.
  Map<String, dynamic> toJson() => _$RoasterToJson(this);
}

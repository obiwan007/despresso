// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coffee.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Coffee _$CoffeeFromJson(Map<String, dynamic> json) => Coffee()
  ..id = json['id'] as int
  ..name = json['name'] as String
  ..description = json['description'] as String
  ..type = json['type'] as String
  ..taste = json['taste'] as String
  ..imageURL = json['imageURL'] as String
  ..grinderSettings = (json['grinderSettings'] as num).toDouble()
  ..grinderDoseWeight = (json['grinderDoseWeight'] as num).toDouble()
  ..acidRating = (json['acidRating'] as num).toDouble()
  ..intensityRating = (json['intensityRating'] as num).toDouble()
  ..roastLevel = (json['roastLevel'] as num).toDouble()
  ..origin = json['origin'] as String
  ..roastDate = DateTime.parse(json['roastDate'] as String)
  ..price = json['price'] as String;

Map<String, dynamic> _$CoffeeToJson(Coffee instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': instance.type,
      'taste': instance.taste,
      'imageURL': instance.imageURL,
      'grinderSettings': instance.grinderSettings,
      'grinderDoseWeight': instance.grinderDoseWeight,
      'acidRating': instance.acidRating,
      'intensityRating': instance.intensityRating,
      'roastLevel': instance.roastLevel,
      'origin': instance.origin,
      'roastDate': instance.roastDate.toIso8601String(),
      'price': instance.price,
    };

Roaster _$RoasterFromJson(Map<String, dynamic> json) => Roaster()
  ..id = json['id'] as int
  ..name = json['name'] as String
  ..imageURL = json['imageURL'] as String
  ..description = json['description'] as String
  ..address = json['address'] as String
  ..homepage = json['homepage'] as String;

Map<String, dynamic> _$RoasterToJson(Roaster instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'imageURL': instance.imageURL,
      'description': instance.description,
      'address': instance.address,
      'homepage': instance.homepage,
    };

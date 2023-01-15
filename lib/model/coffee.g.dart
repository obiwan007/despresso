// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coffee.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Coffee _$CoffeeFromJson(Map<String, dynamic> json) => Coffee()
  ..id = json['id'] as int
  ..name = json['name'] as String
  ..imageURL = json['imageURL'] as String
  ..grinderSettings = (json['grinderSettings'] as num).toDouble()
  ..acidRating = (json['acidRating'] as num).toDouble()
  ..intensityRating = (json['intensityRating'] as num).toDouble()
  ..roastLevel = (json['roastLevel'] as num).toDouble()
  ..arabica = json['arabica'] as int
  ..robusta = json['robusta'] as int
  ..description = json['description'] as String
  ..origin = json['origin'] as String
  ..price = json['price'] as String;

Map<String, dynamic> _$CoffeeToJson(Coffee instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'imageURL': instance.imageURL,
      'grinderSettings': instance.grinderSettings,
      'acidRating': instance.acidRating,
      'intensityRating': instance.intensityRating,
      'roastLevel': instance.roastLevel,
      'arabica': instance.arabica,
      'robusta': instance.robusta,
      'description': instance.description,
      'origin': instance.origin,
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

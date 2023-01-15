import 'package:json_annotation/json_annotation.dart';
import 'package:objectbox/objectbox.dart';
part 'coffee.g.dart';

@Entity()
@JsonSerializable()
class Coffee {
  Coffee();

  int id = 0;
  String name = "";

  final roaster = ToOne<Roaster>();

  String imageURL = "";
  double grinderSettings = 0;

  double acidRating = 3;
  double intensityRating = 3;
  double roastLevel = 3;

  int arabica = 50;
  int robusta = 50;

  String description = "";
  String origin = "";

  String price = "";
  Map<String, dynamic> toJson() => _$CoffeeToJson(this);
  factory Coffee.fromJson(Map<String, dynamic> json) => _$CoffeeFromJson(json);
}

@Entity()
@JsonSerializable()
class Roaster {
  Roaster();

  int id = 0;

  @Backlink('roaster')
  final coffees = ToMany<Coffee>();

  String name = "";
  String imageURL = "";
  String description = "";
  String address = "";
  String homepage = "";

  Map<String, dynamic> toJson() => _$RoasterToJson(this);
  factory Roaster.fromJson(Map<String, dynamic> json) => _$RoasterFromJson(json);
}

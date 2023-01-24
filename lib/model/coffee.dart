import 'package:objectbox/objectbox.dart';

@Entity()
class Coffee {
  Coffee();

  int id = 0;
  String name = "";
  String description = "";
  String type = "";
  String taste = "";
  final roaster = ToOne<Roaster>();

  String imageURL = "";

  double grinderSettings = 0;

  double grinderDoseWeight = 35;

  double acidRating = 3;
  double intensityRating = 3;
  double roastLevel = 3;

  String origin = "";

  @Property(type: PropertyType.date)
  DateTime roastDate = DateTime.now();

  String price = "";
}

@Entity()
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
}

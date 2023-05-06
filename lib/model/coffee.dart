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
  @Property(type: PropertyType.date)
  DateTime roastDate = DateTime.now();
  int elevation = 0;
  String price = "";
  String origin = "";
  String region = "";
  String farm = "";
  @Property(type: PropertyType.date)
  DateTime cropyear = DateTime.now();
  String process = "";
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

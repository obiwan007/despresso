import 'package:despresso/model/coffee.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class Recipe {
  Recipe();

  int id = 0;

  final coffee = ToOne<Coffee>();
  String profileId = "";

  double adjustedWeight = 0;
  double adjustedPressure = 0;
  double adjustedTemp = 0;
  double grinderDoseWeight = 0;
  double grinderSettings = 0;
  bool isDeleted = false;
  bool isFavorite = false;

  String name = "Espresso";
}

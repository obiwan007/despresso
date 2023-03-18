import 'package:despresso/model/coffee.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class Recipe {
  Recipe();

  int id = 0;

  final coffee = ToOne<Coffee>();
  String profileId = "";

  double adjustedWeight = 36;
  double adjustedPressure = 0;
  double adjustedTemp = 0;
  double grinderDoseWeight = 18;
  double grinderSettings = 0;

  double ratio1 = 1;
  double ratio2 = 2;

  bool isDeleted = false;
  bool isFavorite = false;

  String name = "Espresso";

  /// For added water
  double weightWater = 120;
  bool useWater = true;
  double tempWater = 120;
  double timeWater = 20;

  // Steaming milk for recipe
  double tempSteam = 120;
  double flowSteam = 1;
  double timeSteam = 30;
  double weightMilk = 120;
  bool useSteam = false;
}

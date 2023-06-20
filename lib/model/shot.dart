import 'package:despresso/model/coffee.dart';
import 'package:despresso/model/recipe.dart';
import 'package:despresso/model/shotstate.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class Shot {
  @Id()
  int id = 0;

  // ShotList shotData = ShotList([]);

  // Coffee? coffee;

  @Property(type: PropertyType.date)
  DateTime date = DateTime.now();

  String profileId = "";

  final coffee = ToOne<Coffee>();
  final recipe = ToOne<Recipe>();

  final shotstates = ToMany<ShotState>();

  double pourTime = 0;
  double pourWeight = 0;
  double targetEspressoWeight = 0;
  double targetTempCorrection = 0;
  double doseWeight = 0;
  double drinkWeight = 0;

  double grinderSettings = 0;

  String description = "";
  String grinderName = "";
  DateTime roastingDate = DateTime.now();
  double totalDissolvedSolids = 0;
  double extractionYield = 0;
  double enjoyment = 0;
  String barrista = "";
  String drinker = "";

  String visualizerId = "";

  double estimatedWeightReachedTime = 0;
  // ignore: non_constant_identifier_names
  double estimatedWeight_m = 0;
  // ignore: non_constant_identifier_names
  double estimatedWeight_b = 0;
  // ignore: non_constant_identifier_names
  double estimatedWeight_tEnd = 0;
  // ignore: non_constant_identifier_names
  double estimatedWeight_tStart = 0;

  double ratio1 = 1;
  double ratio2 = 2;
}

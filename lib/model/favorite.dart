import 'package:despresso/model/recipe.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class Favorite {
  Favorite();

  int id = 0;

  final recipe = ToOne<Recipe>();
}

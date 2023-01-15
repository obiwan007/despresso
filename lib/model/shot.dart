import 'package:despresso/model/coffee.dart';
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

  final shotstates = ToMany<ShotState>();

  double pourTime = 0;
  double pourWeight = 0;
}

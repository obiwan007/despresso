import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'objectbox.g.dart'; // created by `flutter pub run build_runner build`

class ObjectBox {
  /// The Store of this app.
  late final Store store;

  ObjectBox._create(this.store) {
    // Add any additional setup code, e.g. build queries.
  }

  /// Create an instance of ObjectBox to use throughout the app.
  static Future<ObjectBox> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    // Future<Store> openStore() {...} is defined in the generated objectbox.g.dart
    try {
      final store = await openStore(directory: p.join(docsDir.path, "database"));
      return ObjectBox._create(store);
    } catch (e) {
      print("Error $e");
      rethrow;
    }
  }

  getBackupData() {
    String file = "${store.directoryPath}/data.mdb";
    var f = File(file);

    Uint8List data = f.readAsBytesSync();
    return data;
  }

  restoreBackupData(String fileSrc) async {
    String fileDestination = "${store.directoryPath}/data.mdb";
    store.close();
    var f = File(fileSrc);

    await f.copy(fileDestination);
  }
}

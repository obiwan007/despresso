import 'package:despresso/objectbox.dart';
import 'package:despresso/objectbox.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:objectbox/objectbox.dart';

import '../service_locator.dart';

@Entity()
class SettingsEntry {
  int id = 0;
  double doubleVal = 0;
  int intVal = 0;
  String stringVal = "";
  bool boolVal = false;

  @Index()
  String key = "";

  String type = "";

  @override
  String toString() {
    return "SettingsEntry:$key ${type == "b" ? boolVal : type == "d" ? doubleVal : type == "s" ? stringVal : type == "i" ? intVal : "?"}";
  }
}

/// A cache access provider class for shared preferences using shared_preferences library.
///
/// This cache provider implementation is used by default, if non is provided explicitly.
class ObjectBoxPreferenceCache extends CacheProvider {
  ObjectBox? _objectBox;
  late Box<SettingsEntry> settingsBox;

  @override
  Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    _objectBox = getIt<ObjectBox>();
    settingsBox = _objectBox!.store.box<SettingsEntry>();
    getKeys();
  }

  Set get keys => getKeys();

  SettingsEntry? getEntryByKey(String key) {
    final builder = settingsBox.query(SettingsEntry_.key.equals(key)).build();
    return builder.findFirst();
  }

  @override
  bool? getBool(String key, {bool? defaultValue}) {
    return getEntryByKey(key)?.boolVal ?? defaultValue;
  }

  @override
  double? getDouble(String key, {double? defaultValue}) {
    return getEntryByKey(key)?.doubleVal ?? defaultValue;
  }

  @override
  int? getInt(String key, {int? defaultValue}) {
    return getEntryByKey(key)?.intVal ?? defaultValue;
  }

  @override
  String? getString(String key, {String? defaultValue}) {
    return getEntryByKey(key)?.stringVal ?? defaultValue;
  }

  @override
  Future<void> setBool(String key, bool? value) async {
    SettingsEntry existing = getEntryByKey(key) ?? SettingsEntry();
    existing.boolVal = value ?? false;
    existing.key = key;
    existing.type = "b";
    settingsBox.put(existing);
  }

  @override
  Future<void> setDouble(String key, double? value) async {
    SettingsEntry existing = getEntryByKey(key) ?? SettingsEntry();
    existing.doubleVal = value ?? 0;
    existing.key = key;
    existing.type = "d";
    settingsBox.put(existing);
  }

  @override
  Future<void> setInt(String key, int? value) async {
    SettingsEntry existing = getEntryByKey(key) ?? SettingsEntry();
    existing.intVal = value ?? 0;
    existing.key = key;
    existing.type = "i";
    settingsBox.put(existing);
  }

  @override
  Future<void> setString(String key, String? value) async {
    SettingsEntry existing = getEntryByKey(key) ?? SettingsEntry();
    existing.stringVal = value ?? "";
    existing.key = key;
    existing.type = "s";
    settingsBox.put(existing);
  }

  @override
  Future<void> setObject<T>(String key, T? value) async {
    if (T == int || value is int) {
      await setInt(key, value as int);
    } else if (T == double || value is double) {
      await setDouble(key, value as double);
    } else if (T == bool || value is bool) {
      await setBool(key, value as bool);
    } else if (T == String || value is String) {
      await setString(key, value as String);
    } else {
      throw Exception('No Implementation Found');
    }
  }

  @override
  bool containsKey(String key) {
    return getEntryByKey(key) != null;
  }

  @override
  Set getKeys() {
    var all = settingsBox.getAll();
    debugPrint("All SettingKeys $all");
    return Set<String>.from(all.map(
      (e) => e.key,
    ));
  }

  @override
  Future<void> remove(String key) async {
    var entry = getEntryByKey(key);
    if (entry != null) {
      settingsBox.remove(entry.id);
    }
  }

  @override
  Future<void> removeAll() async {
    settingsBox.removeAll();
  }

  @override
  T? getValue<T>(String key, {T? defaultValue}) {
    if (T == int || defaultValue is int) {
      return getInt(key) as T;
    }
    if (T == double || defaultValue is double) {
      return getDouble(key) as T;
    }
    if (T == bool || defaultValue is bool) {
      return getBool(key) as T;
    }
    if (T == String || defaultValue is String) {
      return getString(key) as T;
    }
    throw Exception('No Implementation Found');
  }
}

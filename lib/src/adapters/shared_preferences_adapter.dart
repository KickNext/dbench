import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../benchmark/database_adapter.dart';

final class SharedPreferencesAdapter implements DatabaseAdapter {
  SharedPreferences? _preferences;

  @override
  String get name => 'shared_preferences';

  @override
  Future<bool> get isSupported async => true;

  @override
  Future<void> open() async {
    _preferences = await SharedPreferences.getInstance();
  }

  @override
  Future<void> clear() async {
    final preferences = _requireOpen();
    for (final key in preferences.getKeys().where(
      (key) => key.startsWith(_keyPrefix),
    )) {
      await preferences.remove(key);
    }
  }

  @override
  Future<void> write(BenchmarkRecord record) async {
    await _requireOpen().setString(
      _key(record.id),
      jsonEncode(record.toJson()),
    );
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final value = _requireOpen().getString(_key(id));
    if (value == null) {
      return null;
    }
    return BenchmarkRecord.fromJson(jsonDecode(value) as Map<String, Object?>);
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    final preferences = _requireOpen();
    final records = <BenchmarkRecord>[];
    for (final key in preferences.getKeys().where(
      (key) => key.startsWith(_keyPrefix),
    )) {
      final value = preferences.getString(key);
      if (value == null) {
        continue;
      }
      final record = BenchmarkRecord.fromJson(
        jsonDecode(value) as Map<String, Object?>,
      );
      if (record.group == group) {
        records.add(record);
      }
    }
    return records;
  }

  @override
  Future<void> update(BenchmarkRecord record) => write(record);

  @override
  Future<void> delete(int id) async {
    await _requireOpen().remove(_key(id));
  }

  @override
  Future<void> close() async {}

  SharedPreferences _requireOpen() {
    final preferences = _preferences;
    if (preferences == null) {
      throw StateError('SharedPreferencesAdapter is not open.');
    }
    return preferences;
  }

  static const _keyPrefix = 'dbench.record.';

  static String _key(int id) => '$_keyPrefix$id';
}

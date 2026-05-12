import 'package:get_storage/get_storage.dart';

import '../benchmark/database_adapter.dart';

DatabaseAdapter createGetStorageAdapter() => GetStorageAdapter();

final class GetStorageAdapter implements DatabaseAdapter {
  GetStorage? _box;

  @override
  String get name => 'get_storage';

  @override
  Future<bool> get isSupported async => true;

  @override
  Future<void> open() async {
    await GetStorage.init('dbench_get_storage');
    _box = GetStorage('dbench_get_storage');
  }

  @override
  Future<void> clear() async {
    await _requireOpen().erase();
  }

  @override
  Future<void> write(BenchmarkRecord record) async {
    await _requireOpen().write(_key(record.id), record.toJson());
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final value = _requireOpen().read(_key(id));
    if (value is Map) {
      return BenchmarkRecord.fromJson(value);
    }
    return null;
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    final box = _requireOpen();
    final records = <BenchmarkRecord>[];
    for (final key in box.getKeys().whereType<String>()) {
      if (!key.startsWith(_keyPrefix)) {
        continue;
      }
      final value = box.read(key);
      if (value is! Map) {
        continue;
      }
      final record = BenchmarkRecord.fromJson(value);
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
  Future<void> close() async {
    await _box?.save();
  }

  GetStorage _requireOpen() {
    final box = _box;
    if (box == null) {
      throw StateError('GetStorageAdapter is not open.');
    }
    return box;
  }

  static const _keyPrefix = 'record_';

  static String _key(int id) => '$_keyPrefix$id';
}

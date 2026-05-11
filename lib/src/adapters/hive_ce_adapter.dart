import 'package:hive_ce/hive.dart';

import '../benchmark/database_adapter.dart';
import '../platform/storage_directory.dart';

final class HiveCeAdapter implements DatabaseAdapter {
  Box<Map>? _box;

  @override
  String get name => 'hive_ce';

  @override
  Future<bool> get isSupported async => true;

  @override
  Future<void> open() async {
    final path = await benchmarkStoragePath();
    if (!_isInitialized) {
      Hive.init(path);
      _isInitialized = true;
    }
    _box = await Hive.openBox<Map>('dbench_hive_ce');
  }

  @override
  Future<void> clear() async {
    await _requireOpen().clear();
  }

  @override
  Future<void> write(BenchmarkRecord record) async {
    await _requireOpen().put(record.id, record.toJson());
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final value = _requireOpen().get(id);
    if (value == null) {
      return null;
    }
    return BenchmarkRecord.fromJson(value);
  }

  @override
  Future<void> update(BenchmarkRecord record) => write(record);

  @override
  Future<void> delete(int id) async {
    await _requireOpen().delete(id);
  }

  @override
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }

  Box<Map> _requireOpen() {
    final box = _box;
    if (box == null) {
      throw StateError('HiveCeAdapter is not open.');
    }
    return box;
  }

  static var _isInitialized = false;
}

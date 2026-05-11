import 'package:path/path.dart' as p;
import 'package:sembast/sembast.dart';

import '../benchmark/database_adapter.dart';
import '../platform/storage_directory.dart';
import 'sembast_adapter_label.dart';
import 'sembast_factory.dart';

final class SembastAdapter implements DatabaseAdapter {
  Database? _database;
  final _store = intMapStoreFactory.store('records');

  @override
  String get name => sembastAdapterName();

  @override
  Future<bool> get isSupported async => true;

  @override
  Future<void> open() async {
    final basePath = await benchmarkStoragePath();
    final path = basePath == null
        ? 'dbench_sembast.db'
        : p.join(basePath, 'dbench_sembast.db');
    _database = await sembastFactory().openDatabase(path);
  }

  @override
  Future<void> clear() async {
    await _store.delete(_requireOpen());
  }

  @override
  Future<void> write(BenchmarkRecord record) async {
    await _store.record(record.id).put(_requireOpen(), record.toJson());
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final value = await _store.record(id).get(_requireOpen());
    if (value == null) {
      return null;
    }
    return BenchmarkRecord.fromJson(value);
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    final snapshots = await _store.find(
      _requireOpen(),
      finder: Finder(filter: Filter.equals('group', group)),
    );
    return [
      for (final snapshot in snapshots)
        BenchmarkRecord.fromJson(snapshot.value),
    ];
  }

  @override
  Future<void> update(BenchmarkRecord record) => write(record);

  @override
  Future<void> delete(int id) async {
    await _store.record(id).delete(_requireOpen());
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  Database _requireOpen() {
    final database = _database;
    if (database == null) {
      throw StateError('SembastAdapter is not open.');
    }
    return database;
  }
}

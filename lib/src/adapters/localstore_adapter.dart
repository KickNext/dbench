import 'package:localstore/localstore.dart';

import '../benchmark/database_adapter.dart';

final class LocalstoreAdapter implements DatabaseAdapter {
  final Localstore _database = Localstore.instance;

  @override
  String get name => 'localstore';

  @override
  Future<bool> get isSupported async => true;

  @override
  Future<void> open() async {}

  @override
  Future<void> clear() async {
    await _collection.delete();
  }

  @override
  Future<void> write(BenchmarkRecord record) async {
    await _collection.doc('${record.id}').set(record.toJson());
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final value = await _collection.doc('$id').get();
    if (value == null) {
      return null;
    }
    return BenchmarkRecord.fromJson(value);
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    final values = await _collection.get();
    if (values == null) {
      return const [];
    }
    return [
      for (final value in values.values)
        if ((value as Map<dynamic, dynamic>)['group'] == group)
          BenchmarkRecord.fromJson(value),
    ];
  }

  @override
  Future<void> update(BenchmarkRecord record) => write(record);

  @override
  Future<void> delete(int id) async {
    await _collection.doc('$id').delete();
  }

  @override
  Future<void> close() async {}

  CollectionRef get _collection => _database.collection('dbench_records');
}

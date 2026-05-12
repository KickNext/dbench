import 'package:flutter/foundation.dart';
import 'package:localstore/localstore.dart';

import '../benchmark/database_adapter.dart';

DatabaseAdapter createLocalstoreAdapter() => LocalstoreAdapter();

final class LocalstoreAdapter implements DatabaseAdapter {
  final Localstore _database = Localstore.getInstance(useSupportDir: true);

  @override
  String get name => 'localstore';

  @override
  Future<bool> get isSupported async => true;

  @override
  Future<void> open() async {}

  @override
  Future<void> clear() => _withoutLocalstoreDebug(() => _collection.delete());

  @override
  Future<void> write(BenchmarkRecord record) => _withoutLocalstoreDebug(
    () => _collection.doc('${record.id}').set(record.toJson()),
  );

  @override
  Future<BenchmarkRecord?> read(int id) => _withoutLocalstoreDebug(() async {
    final value = await _collection.doc('$id').get();
    if (value == null) {
      return null;
    }
    return BenchmarkRecord.fromJson(value);
  });

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) =>
      _withoutLocalstoreDebug(() async {
        final values = await _collection.get();
        if (values == null) {
          return const [];
        }
        return [
          for (final value in values.values)
            if ((value as Map<dynamic, dynamic>)['group'] == group)
              BenchmarkRecord.fromJson(value),
        ];
      });

  @override
  Future<void> update(BenchmarkRecord record) => write(record);

  @override
  Future<void> delete(int id) =>
      _withoutLocalstoreDebug(() => _collection.doc('$id').delete());

  @override
  Future<void> close() async {}

  CollectionRef get _collection => _database.collection('dbench_records');

  Future<T> _withoutLocalstoreDebug<T>(Future<T> Function() action) async {
    final previousDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {};
    try {
      return await action();
    } finally {
      debugPrint = previousDebugPrint;
    }
  }
}

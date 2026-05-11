import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import '../benchmark/database_adapter.dart';
import '../platform/storage_directory.dart';

DatabaseAdapter createDriftAdapter() => DriftAdapter();

final class DriftAdapter implements TransactionalDatabaseAdapter {
  _BenchmarkDriftDatabase? _database;

  @override
  String get name => 'drift';

  @override
  Future<bool> get isSupported async {
    return Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows ||
        Platform.isLinux;
  }

  @override
  Future<void> open() async {
    final basePath = await benchmarkStoragePath();
    final databasePath = p.join(basePath!, 'dbench_drift.db');
    final database = _BenchmarkDriftDatabase(
      NativeDatabase(File(databasePath)),
    );
    _database = database;
    await database.customStatement('''
CREATE TABLE IF NOT EXISTS records(
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  record_group TEXT NOT NULL,
  value INTEGER NOT NULL,
  payload TEXT NOT NULL,
  updated_at_micros INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_records_group ON records(record_group);
''');
  }

  @override
  Future<void> clear() async {
    await _requireOpen().customStatement('DELETE FROM records');
  }

  @override
  Future<void> write(BenchmarkRecord record) async {
    await _requireOpen().customStatement('''
INSERT INTO records(id, title, record_group, value, payload, updated_at_micros)
VALUES (?, ?, ?, ?, ?, ?)
''', _rowValues(record));
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final rows = await _requireOpen()
        .customSelect(
          'SELECT * FROM records WHERE id = ? LIMIT 1',
          variables: [Variable.withInt(id)],
        )
        .get();
    if (rows.isEmpty) {
      return null;
    }
    return _record(rows.single.data);
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    final rows = await _requireOpen()
        .customSelect(
          'SELECT * FROM records WHERE record_group = ?',
          variables: [Variable.withString(group)],
        )
        .get();
    return [for (final row in rows) _record(row.data)];
  }

  @override
  Future<void> update(BenchmarkRecord record) async {
    await _requireOpen().customStatement(
      '''
UPDATE records
SET title = ?, record_group = ?, value = ?, payload = ?, updated_at_micros = ?
WHERE id = ?
''',
      [
        record.title,
        record.group,
        record.value,
        record.payload,
        record.updatedAtMicros,
        record.id,
      ],
    );
  }

  @override
  Future<void> delete(int id) async {
    await _requireOpen().customStatement('DELETE FROM records WHERE id = ?', [
      id,
    ]);
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  @override
  Future<T> runWriteTransaction<T>(Future<T> Function() action) {
    return _requireOpen().transaction(action);
  }

  _BenchmarkDriftDatabase _requireOpen() {
    final database = _database;
    if (database == null) {
      throw StateError('DriftAdapter is not open.');
    }
    return database;
  }

  List<Object?> _rowValues(BenchmarkRecord record) {
    return [
      record.id,
      record.title,
      record.group,
      record.value,
      record.payload,
      record.updatedAtMicros,
    ];
  }

  BenchmarkRecord _record(Map<String, Object?> row) {
    return BenchmarkRecord(
      id: row['id']! as int,
      title: row['title']! as String,
      group: row['record_group']! as String,
      value: row['value']! as int,
      payload: row['payload']! as String,
      updatedAtMicros: row['updated_at_micros']! as int,
    );
  }
}

final class _BenchmarkDriftDatabase extends GeneratedDatabase {
  _BenchmarkDriftDatabase(super.executor);

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  int get schemaVersion => 1;
}

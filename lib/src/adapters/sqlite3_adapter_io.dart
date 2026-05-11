import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../benchmark/database_adapter.dart';
import '../platform/storage_directory.dart';

DatabaseAdapter createSqlite3Adapter() => Sqlite3Adapter();

final class Sqlite3Adapter implements TransactionalDatabaseAdapter {
  sqlite.Database? _database;

  @override
  String get name => 'sqlite3';

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
    final databasePath = p.join(basePath!, 'dbench_sqlite3.db');
    final database = sqlite.sqlite3.open(databasePath);
    database.execute('''
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
    _database = database;
  }

  @override
  Future<void> clear() async {
    _requireOpen().execute('DELETE FROM records');
  }

  @override
  Future<void> write(BenchmarkRecord record) async {
    _requireOpen().execute('''
INSERT INTO records(id, title, record_group, value, payload, updated_at_micros)
VALUES (?, ?, ?, ?, ?, ?)
''', _rowValues(record));
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final result = _requireOpen().select(
      'SELECT * FROM records WHERE id = ? LIMIT 1',
      [id],
    );
    if (result.isEmpty) {
      return null;
    }
    return _record(result.first);
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    final result = _requireOpen().select(
      'SELECT * FROM records WHERE record_group = ?',
      [group],
    );
    return [for (final row in result) _record(row)];
  }

  @override
  Future<void> update(BenchmarkRecord record) async {
    _requireOpen().execute(
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
    _requireOpen().execute('DELETE FROM records WHERE id = ?', [id]);
  }

  @override
  Future<void> close() async {
    _database?.close();
    _database = null;
  }

  @override
  Future<T> runWriteTransaction<T>(Future<T> Function() action) async {
    final database = _requireOpen();
    database.execute('BEGIN IMMEDIATE');
    try {
      final result = await action();
      database.execute('COMMIT');
      return result;
    } catch (_) {
      database.execute('ROLLBACK');
      rethrow;
    }
  }

  sqlite.Database _requireOpen() {
    final database = _database;
    if (database == null) {
      throw StateError('Sqlite3Adapter is not open.');
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

  BenchmarkRecord _record(sqlite.Row row) {
    return BenchmarkRecord(
      id: row['id'] as int,
      title: row['title'] as String,
      group: row['record_group'] as String,
      value: row['value'] as int,
      payload: row['payload'] as String,
      updatedAtMicros: row['updated_at_micros'] as int,
    );
  }
}

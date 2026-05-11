import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite_async/sqlite_async.dart';

import '../benchmark/database_adapter.dart';
import '../platform/storage_directory.dart';

DatabaseAdapter createSqliteAsyncAdapter() => SqliteAsyncAdapter();

final class SqliteAsyncAdapter implements TransactionalDatabaseAdapter {
  SqliteDatabase? _database;
  SqliteWriteContext? _transaction;

  @override
  String get name => 'sqlite_async';

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
    final databasePath = p.join(basePath!, 'dbench_sqlite_async.db');
    final database = SqliteDatabase(path: databasePath);
    await database.initialize();
    _database = database;
    await database.executeMultiple('''
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
    await _writer.execute('DELETE FROM records');
  }

  @override
  Future<void> write(BenchmarkRecord record) async {
    await _writer.execute('''
INSERT INTO records(id, title, record_group, value, payload, updated_at_micros)
VALUES (?, ?, ?, ?, ?, ?)
''', _rowValues(record));
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final row = await _reader.getOptional(
      'SELECT * FROM records WHERE id = ? LIMIT 1',
      [id],
    );
    if (row == null) {
      return null;
    }
    return _record(row);
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    final rows = await _reader.getAll(
      'SELECT * FROM records WHERE record_group = ?',
      [group],
    );
    return [for (final row in rows) _record(row)];
  }

  @override
  Future<void> update(BenchmarkRecord record) async {
    await _writer.execute(
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
    await _writer.execute('DELETE FROM records WHERE id = ?', [id]);
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  @override
  Future<T> runWriteTransaction<T>(Future<T> Function() action) async {
    return _requireOpen().writeTransaction((transaction) async {
      _transaction = transaction;
      try {
        return await action();
      } finally {
        _transaction = null;
      }
    });
  }

  SqliteDatabase _requireOpen() {
    final database = _database;
    if (database == null) {
      throw StateError('SqliteAsyncAdapter is not open.');
    }
    return database;
  }

  SqliteReadContext get _reader => _transaction ?? _requireOpen();

  SqliteWriteContext get _writer => _transaction ?? _requireOpen();

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

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

import '../benchmark/database_adapter.dart';
import '../platform/storage_directory.dart';

DatabaseAdapter createSqliteAdapter() => SqliteAdapter();

final class SqliteAdapter implements DatabaseAdapter {
  sqflite.Database? _database;

  @override
  String get name =>
      Platform.isWindows || Platform.isLinux ? 'sqflite_common_ffi' : 'sqflite';

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
    final factory = _databaseFactory();
    final path = await _databasePath(factory);
    _database = await factory.openDatabase(
      path,
      options: sqflite.OpenDatabaseOptions(
        version: 1,
        onCreate: (database, version) async {
          await database.execute('''
CREATE TABLE records(
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  record_group TEXT NOT NULL,
  value INTEGER NOT NULL,
  payload TEXT NOT NULL,
  updated_at_micros INTEGER NOT NULL
)
''');
        },
      ),
    );
  }

  @override
  Future<void> clear() async {
    await _requireOpen().delete('records');
  }

  @override
  Future<void> write(BenchmarkRecord record) async {
    await _requireOpen().insert('records', _row(record));
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final rows = await _requireOpen().query(
      'records',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _record(rows.single);
  }

  @override
  Future<void> update(BenchmarkRecord record) async {
    await _requireOpen().update(
      'records',
      _row(record),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  @override
  Future<void> delete(int id) async {
    await _requireOpen().delete('records', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  sqflite.DatabaseFactory _databaseFactory() {
    if (Platform.isWindows || Platform.isLinux) {
      ffi.sqfliteFfiInit();
      return ffi.databaseFactoryFfi;
    }
    return sqflite.databaseFactory;
  }

  Future<String> _databasePath(sqflite.DatabaseFactory factory) async {
    if (Platform.isWindows || Platform.isLinux) {
      final basePath = await benchmarkStoragePath();
      return p.join(basePath!, 'dbench_sqflite_ffi.db');
    }
    return p.join(await sqflite.getDatabasesPath(), 'dbench_sqflite.db');
  }

  sqflite.Database _requireOpen() {
    final database = _database;
    if (database == null) {
      throw StateError('SqliteAdapter is not open.');
    }
    return database;
  }

  Map<String, Object?> _row(BenchmarkRecord record) {
    return {
      'id': record.id,
      'title': record.title,
      'record_group': record.group,
      'value': record.value,
      'payload': record.payload,
      'updated_at_micros': record.updatedAtMicros,
    };
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

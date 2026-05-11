import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:entidb_flutter/entidb_flutter.dart' as entidb;
import 'package:ffastdb/ffastdb.dart' as ffastdb;
import 'package:hive/hive.dart' as hive;
import 'package:objectdb/objectdb.dart' as objectdb;
// objectdb exposes StorageInterface publicly but keeps the concrete file
// storage backend internal; the adapter needs that backend to benchmark IO.
// ignore: implementation_imports
import 'package:objectdb/src/objectdb_storage_filesystem.dart'
    as objectdb_storage;
import 'package:path/path.dart' as p;
import 'package:powersync/powersync.dart' as powersync;
import 'package:reaxdb_dart/reaxdb_dart.dart' as reaxdb;
import 'package:sembast/sembast.dart' as sembast;
import 'package:sembast_sqflite/sembast_sqflite.dart' as sembast_sqflite;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_sqlcipher/sqflite.dart' as cipher;
import 'package:sqlite_async/sqlite_async.dart' as sqlite_async;
import 'package:store_box/store_box.dart' as store_box;
import 'package:tiny_db/tiny_db.dart' as tiny_db;
import 'package:torex_local_store/torex_local_store.dart' as torex;
import 'package:work_db/work_db.dart' as work_db;

import '../benchmark/database_adapter.dart';
import '../platform/storage_directory.dart';

List<DatabaseAdapter> extendedAdapters() {
  return [
    HiveAdapter(),
    SqfliteSqlcipherAdapter(),
    SembastSqfliteAdapter(),
    ObjectDbAdapter(),
    TinyDbAdapter(),
    StoreBoxAdapter(),
    WorkDbAdapter(),
    FfastDbAdapter(),
    ReaxDbAdapter(),
    TorexLocalStoreAdapter(),
    const UnsupportedDatabaseAdapter(
      name: 'flutter_local_db',
      reason:
          'flutter_local_db 1.5.1 declares a Windows plugin but does not ship a windows plugin directory, which breaks Flutter desktop CMake generation.',
    ),
    EntiDbAdapter(),
    PowerSyncAdapter(),
    const UnsupportedDatabaseAdapter(
      name: 'cbl_flutter',
      reason: 'Couchbase Lite adapter requires native library initialization.',
    ),
    const UnsupportedDatabaseAdapter(
      name: 'couchbase_lite',
      reason:
          'couchbase_lite is the older Couchbase Lite package line; current Flutter runtime coverage is represented by cbl_flutter.',
    ),
    const UnsupportedDatabaseAdapter(
      name: 'torexstore',
      reason:
          'torexstore is an early package line superseded by torex_local_store for the measurable Flutter adapter.',
    ),
    const UnsupportedDatabaseAdapter(
      name: 'floor',
      reason:
          'Floor is a sqflite ORM that requires generated database classes; raw SQLite performance is measured by sqflite.',
    ),
    const UnsupportedDatabaseAdapter(
      name: 'objectbox',
      reason:
          'ObjectBox requires generated model bindings for benchmark entities.',
    ),
    const UnsupportedDatabaseAdapter(
      name: 'isar',
      reason: 'Isar requires generated collection schema for benchmark models.',
    ),
    const UnsupportedDatabaseAdapter(
      name: 'isar_community',
      reason:
          'Isar Community requires generated collection schema for benchmark models.',
    ),
    const UnsupportedDatabaseAdapter(
      name: 'isar_db',
      reason:
          'isar_db depends on build ^2.4.x and is incompatible with build_runner 2.15.',
    ),
    const UnsupportedDatabaseAdapter(
      name: 'isar_plus',
      reason:
          'isar_plus is an Isar fork that requires generated collection schema.',
    ),
    const UnsupportedDatabaseAdapter(
      name: 'realm',
      reason:
          'Realm depends on realm_generator versions incompatible with analyzer 10/build_runner 2.15.',
    ),
    const UnsupportedDatabaseAdapter(
      name: 'quanta_db',
      reason:
          'quanta_db depends on build ^2.4.x and is incompatible with build_runner 2.15.',
    ),
    const UnsupportedDatabaseAdapter(
      name: 'rxdb',
      reason:
          'rxdb pins shared_preferences 2.0.17, conflicting with shared_preferences 2.5.5.',
    ),
  ];
}

final class HiveAdapter implements DatabaseAdapter {
  hive.Box<Map>? _box;

  @override
  String get name => 'hive';

  @override
  Future<bool> get isSupported async => true;

  @override
  Future<void> open() async {
    final path = await benchmarkStoragePath();
    if (!_isInitialized) {
      hive.Hive.init(path);
      _isInitialized = true;
    }
    _box = await hive.Hive.openBox<Map>('dbench_hive');
  }

  @override
  Future<void> clear() => _requireOpen().clear();

  @override
  Future<void> write(BenchmarkRecord record) {
    return _requireOpen().put(record.id, record.toJson());
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final value = _requireOpen().get(id);
    return value == null ? null : BenchmarkRecord.fromJson(value);
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    return [
      for (final value in _requireOpen().values)
        if (BenchmarkRecord.fromJson(value).group == group)
          BenchmarkRecord.fromJson(value),
    ];
  }

  @override
  Future<void> update(BenchmarkRecord record) => write(record);

  @override
  Future<void> delete(int id) => _requireOpen().delete(id);

  @override
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }

  hive.Box<Map> _requireOpen() {
    final box = _box;
    if (box == null) {
      throw StateError('HiveAdapter is not open.');
    }
    return box;
  }

  static var _isInitialized = false;
}

final class SqfliteSqlcipherAdapter implements TransactionalDatabaseAdapter {
  cipher.Database? _database;
  cipher.Transaction? _transaction;

  @override
  String get name => 'sqflite_sqlcipher';

  @override
  Future<bool> get isSupported async =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  @override
  Future<void> open() async {
    final basePath = await benchmarkStoragePath();
    _database = await cipher.openDatabase(
      p.join(basePath!, 'dbench_sqlcipher.db'),
      password: 'dbench',
      version: 1,
      onCreate: (database, version) async {
        await database.execute(_createSql);
        await database.execute(_createGroupIndexSql);
      },
    );
    await _database!.execute(_createGroupIndexSql);
  }

  @override
  Future<void> clear() => _executor.delete('records');

  @override
  Future<void> write(BenchmarkRecord record) {
    return _executor.insert('records', _row(record));
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final rows = await _executor.query(
      'records',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _record(rows.single);
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    final rows = await _executor.query(
      'records',
      where: 'record_group = ?',
      whereArgs: [group],
    );
    return [for (final row in rows) _record(row)];
  }

  @override
  Future<void> update(BenchmarkRecord record) {
    return _executor.update(
      'records',
      _row(record),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  @override
  Future<void> delete(int id) {
    return _executor.delete('records', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  @override
  Future<T> runWriteTransaction<T>(Future<T> Function() action) {
    return _requireOpen().transaction((transaction) async {
      _transaction = transaction;
      try {
        return await action();
      } finally {
        _transaction = null;
      }
    });
  }

  cipher.Database _requireOpen() {
    final database = _database;
    if (database == null) {
      throw StateError('SqfliteSqlcipherAdapter is not open.');
    }
    return database;
  }

  cipher.DatabaseExecutor get _executor => _transaction ?? _requireOpen();
}

final class SembastSqfliteAdapter implements DatabaseAdapter {
  sembast.Database? _database;
  final _store = sembast.intMapStoreFactory.store('records');

  @override
  String get name => 'sembast_sqflite';

  @override
  Future<bool> get isSupported async =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  @override
  Future<void> open() async {
    final factory = sembast_sqflite.getDatabaseFactorySqflite(
      sqflite.databaseFactory,
    );
    final basePath = await benchmarkStoragePath();
    _database = await factory.openDatabase(
      p.join(basePath!, 'dbench_sembast_sqflite.db'),
    );
  }

  @override
  Future<void> clear() => _store.delete(_requireOpen());

  @override
  Future<void> write(BenchmarkRecord record) {
    return _store.record(record.id).put(_requireOpen(), record.toJson());
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final value = await _store.record(id).get(_requireOpen());
    return value == null ? null : BenchmarkRecord.fromJson(value);
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    final snapshots = await _store.find(
      _requireOpen(),
      finder: sembast.Finder(filter: sembast.Filter.equals('group', group)),
    );
    return [
      for (final snapshot in snapshots)
        BenchmarkRecord.fromJson(snapshot.value),
    ];
  }

  @override
  Future<void> update(BenchmarkRecord record) => write(record);

  @override
  Future<void> delete(int id) => _store.record(id).delete(_requireOpen());

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  sembast.Database _requireOpen() {
    final database = _database;
    if (database == null) {
      throw StateError('SembastSqfliteAdapter is not open.');
    }
    return database;
  }
}

final class ObjectDbAdapter implements DatabaseAdapter {
  objectdb.ObjectDB? _database;

  @override
  String get name => 'objectdb';

  @override
  Future<bool> get isSupported async => true;

  @override
  Future<void> open() async {
    final basePath = await benchmarkStoragePath();
    final path = p.join(basePath!, 'dbench.objectdb');
    final file = File(path);
    if (file.existsSync()) {
      file.deleteSync();
    }
    _database = objectdb.ObjectDB(objectdb_storage.FileSystemStorage(path));
  }

  @override
  Future<void> clear() => _requireOpen().remove({});

  @override
  Future<void> write(BenchmarkRecord record) async {
    await _requireOpen().insert(record.toJson());
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final rows = await _requireOpen().find({'id': id});
    return rows.isEmpty ? null : BenchmarkRecord.fromJson(rows.first);
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    final rows = await _requireOpen().find({'group': group});
    return [for (final row in rows) BenchmarkRecord.fromJson(row)];
  }

  @override
  Future<void> update(BenchmarkRecord record) async {
    await _requireOpen().update({'id': record.id}, record.toJson());
  }

  @override
  Future<void> delete(int id) async {
    await _requireOpen().remove({'id': id});
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  objectdb.ObjectDB _requireOpen() {
    final database = _database;
    if (database == null) {
      throw StateError('ObjectDbAdapter is not open.');
    }
    return database;
  }
}

final class TinyDbAdapter implements DatabaseAdapter {
  tiny_db.TinyDb? _database;

  @override
  String get name => 'tiny_db';

  @override
  Future<bool> get isSupported async => true;

  @override
  Future<void> open() async {
    final basePath = await benchmarkStoragePath();
    _database = tiny_db.TinyDb(
      tiny_db.JsonStorage(p.join(basePath!, 'dbench_tiny_db.json')),
    );
  }

  @override
  Future<void> clear() => _requireOpen().truncate();

  @override
  Future<void> write(BenchmarkRecord record) async {
    await _requireOpen().insert(record.toJson());
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final row = await _requireOpen().defaultTable.get(
      tiny_db.where('id').equals(id),
    );
    return row == null ? null : BenchmarkRecord.fromJson(row);
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    final rows = await _requireOpen().defaultTable.search(
      tiny_db.where('group').equals(group),
    );
    return [for (final row in rows) BenchmarkRecord.fromJson(row)];
  }

  @override
  Future<void> update(BenchmarkRecord record) async {
    await delete(record.id);
    await write(record);
  }

  @override
  Future<void> delete(int id) async {
    await _requireOpen().defaultTable.remove(tiny_db.where('id').equals(id));
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  tiny_db.TinyDb _requireOpen() {
    final database = _database;
    if (database == null) {
      throw StateError('TinyDbAdapter is not open.');
    }
    return database;
  }
}

final class StoreBoxAdapter implements DatabaseAdapter {
  store_box.Box<Map>? _box;

  @override
  String get name => 'store_box';

  @override
  Future<bool> get isSupported async => true;

  @override
  Future<void> open() async {
    final basePath = await benchmarkStoragePath();
    await store_box.StoreBox.init(p.join(basePath!, 'store_box'));
    _box = await store_box.StoreBox.openBox<Map>('records');
  }

  @override
  Future<void> clear() => _requireOpen().clear();

  @override
  Future<void> write(BenchmarkRecord record) {
    return _requireOpen().put('${record.id}', record.toJson());
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final value = _requireOpen().get('$id');
    return value == null ? null : BenchmarkRecord.fromJson(value);
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    return [
      for (final value in _requireOpen().getAll().values)
        if (BenchmarkRecord.fromJson(value).group == group)
          BenchmarkRecord.fromJson(value),
    ];
  }

  @override
  Future<void> update(BenchmarkRecord record) => write(record);

  @override
  Future<void> delete(int id) => _requireOpen().delete('$id');

  @override
  Future<void> close() async {
    _box = null;
  }

  store_box.Box<Map> _requireOpen() {
    final box = _box;
    if (box == null) {
      throw StateError('StoreBoxAdapter is not open.');
    }
    return box;
  }
}

final class WorkDbAdapter implements DatabaseAdapter {
  work_db.IWorkDb? _database;

  @override
  String get name => 'work_db';

  @override
  Future<bool> get isSupported async => true;

  @override
  Future<void> open() async {
    final basePath = await benchmarkStoragePath();
    _database = work_db.ClientWorkDb(
      work_db.IoWorkDb(p.join(basePath!, 'work_db')),
    );
  }

  @override
  Future<void> clear() => _requireOpen().clearDatabase();

  @override
  Future<void> write(BenchmarkRecord record) {
    return _requireOpen().createOrUpdate(_item(record));
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final item = await _requireOpen().retrieve(_id(id));
    return item == null ? null : BenchmarkRecord.fromJson(item.item);
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    final ids = await _requireOpen().getItemsInCollection('records');
    final records = <BenchmarkRecord>[];
    for (final id in ids) {
      final item = await _requireOpen().retrieve(
        work_db.ItemId(id: id, collection: 'records'),
      );
      if (item == null) {
        continue;
      }
      final record = BenchmarkRecord.fromJson(item.item);
      if (record.group == group) {
        records.add(record);
      }
    }
    return records;
  }

  @override
  Future<void> update(BenchmarkRecord record) {
    return _requireOpen().createOrUpdate(_item(record));
  }

  @override
  Future<void> delete(int id) => _requireOpen().delete(_id(id));

  @override
  Future<void> close() async {
    _database = null;
  }

  work_db.IWorkDb _requireOpen() {
    final database = _database;
    if (database == null) {
      throw StateError('WorkDbAdapter is not open.');
    }
    return database;
  }

  work_db.ItemId _id(int id) {
    return work_db.ItemId(id: '$id', collection: 'records');
  }

  work_db.ItemWithId _item(BenchmarkRecord record) {
    return work_db.ItemWithId(
      id: '${record.id}',
      collection: 'records',
      item: record.toJson(),
    );
  }
}

final class FfastDbAdapter implements TransactionalDatabaseAdapter {
  ffastdb.FastDB? _database;
  final _ids = <int>{};

  @override
  String get name => 'ffastdb';

  @override
  Future<bool> get isSupported async => true;

  @override
  Future<void> open() async {
    final basePath = await benchmarkStoragePath();
    _database = ffastdb.FastDB(
      ffastdb.WalStorageStrategy(
        main: ffastdb.IoStorageStrategy(p.join(basePath!, 'ffastdb.data')),
        wal: ffastdb.IoStorageStrategy(p.join(basePath, 'ffastdb.wal')),
      ),
    );
    await _database!.open();
  }

  @override
  Future<void> clear() async {
    for (final id in _ids.toList()) {
      await _requireOpen().delete(id);
    }
    _ids.clear();
  }

  @override
  Future<void> write(BenchmarkRecord record) {
    _ids.add(record.id);
    return _requireOpen().put(record.id, record.toJson());
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final value = await _requireOpen().findById(id);
    return value is Map ? BenchmarkRecord.fromJson(value) : null;
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    final records = <BenchmarkRecord>[];
    for (final id in _ids) {
      final record = await read(id);
      if (record != null && record.group == group) {
        records.add(record);
      }
    }
    return records;
  }

  @override
  Future<void> update(BenchmarkRecord record) {
    return _requireOpen().put(record.id, record.toJson());
  }

  @override
  Future<void> delete(int id) async {
    _ids.remove(id);
    await _requireOpen().delete(id);
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

  ffastdb.FastDB _requireOpen() {
    final database = _database;
    if (database == null) {
      throw StateError('FfastDbAdapter is not open.');
    }
    return database;
  }
}

final class ReaxDbAdapter implements DatabaseAdapter {
  reaxdb.SimpleReaxDB? _database;

  @override
  String get name => 'reaxdb_dart';

  @override
  Future<bool> get isSupported async => true;

  @override
  Future<void> open() async {
    final basePath = await benchmarkStoragePath();
    _database = await reaxdb.SimpleReaxDB.open(
      'dbench_reaxdb',
      path: p.join(basePath!, 'reaxdb'),
    );
  }

  @override
  Future<void> clear() => _requireOpen().clear();

  @override
  Future<void> write(BenchmarkRecord record) {
    return _requireOpen().put(_key(record.id), record.toJson());
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final value = await _requireOpen().get(_key(id));
    return value is Map ? BenchmarkRecord.fromJson(value) : null;
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    final values = await _requireOpen().getAll('record:*');
    return [
      for (final value in values.values)
        if (value is Map && value['group'] == group)
          BenchmarkRecord.fromJson(value),
    ];
  }

  @override
  Future<void> update(BenchmarkRecord record) => write(record);

  @override
  Future<void> delete(int id) => _requireOpen().delete(_key(id));

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  reaxdb.SimpleReaxDB _requireOpen() {
    final database = _database;
    if (database == null) {
      throw StateError('ReaxDbAdapter is not open.');
    }
    return database;
  }

  String _key(int id) => 'record:$id';
}

final class TorexLocalStoreAdapter implements DatabaseAdapter {
  late torex.TorexBox _box;
  var _isOpen = false;

  @override
  String get name => 'torex_local_store';

  @override
  Future<bool> get isSupported async =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  @override
  Future<void> open() async {
    _box = torex.Torex.box('dbench_records');
    _isOpen = true;
  }

  @override
  Future<void> clear() => _requireOpen().clear();

  @override
  Future<void> write(BenchmarkRecord record) {
    return _requireOpen().putJson('${record.id}', record.toJson());
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final value = await _requireOpen().getJson('$id');
    return value == null ? null : BenchmarkRecord.fromJson(value);
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    final entries = await _requireOpen().scanStrings();
    return [
      for (final entry in entries)
        if (_decodeRecord(entry.$2).group == group) _decodeRecord(entry.$2),
    ];
  }

  @override
  Future<void> update(BenchmarkRecord record) => write(record);

  @override
  Future<void> delete(int id) => _requireOpen().delete('$id');

  @override
  Future<void> close() async {
    _isOpen = false;
  }

  torex.TorexBox _requireOpen() {
    if (!_isOpen) {
      throw StateError('TorexLocalStoreAdapter is not open.');
    }
    return _box;
  }
}

final class EntiDbAdapter implements TransactionalDatabaseAdapter {
  entidb.Database? _database;
  late entidb.Collection _collection;
  entidb.Transaction? _transaction;

  @override
  String get name => 'entidb_flutter';

  @override
  Future<bool> get isSupported async =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  @override
  Future<void> open() async {
    final basePath = await benchmarkStoragePath();
    _database = entidb.Database.open(p.join(basePath!, 'entidb'));
    _collection = _database!.collection('records');
  }

  @override
  Future<void> clear() async {
    for (final entry in _requireOpen().list(_collection)) {
      _executorDelete(entry.$1);
    }
  }

  @override
  Future<void> write(BenchmarkRecord record) async {
    _executorPut(_entityId(record.id), _bytes(record));
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final bytes = _executorGet(_entityId(id));
    return bytes == null ? null : _recordFromBytes(bytes);
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    return [
      for (final entry in _requireOpen().list(_collection))
        if (_recordFromBytes(entry.$2).group == group)
          _recordFromBytes(entry.$2),
    ];
  }

  @override
  Future<void> update(BenchmarkRecord record) => write(record);

  @override
  Future<void> delete(int id) async {
    _executorDelete(_entityId(id));
  }

  @override
  Future<void> close() async {
    _database?.close();
    _database = null;
  }

  @override
  Future<T> runWriteTransaction<T>(Future<T> Function() action) async {
    return _requireOpen().transaction((transaction) {
      _transaction = transaction;
      try {
        return action();
      } finally {
        _transaction = null;
      }
    });
  }

  entidb.Database _requireOpen() {
    final database = _database;
    if (database == null) {
      throw StateError('EntiDbAdapter is not open.');
    }
    return database;
  }

  Uint8List? _executorGet(entidb.EntityId id) {
    final transaction = _transaction;
    if (transaction != null) {
      return transaction.get(_collection, id);
    }
    return _requireOpen().get(_collection, id);
  }

  void _executorPut(entidb.EntityId id, Uint8List data) {
    final transaction = _transaction;
    if (transaction != null) {
      transaction.put(_collection, id, data);
    } else {
      _requireOpen().put(_collection, id, data);
    }
  }

  void _executorDelete(entidb.EntityId id) {
    final transaction = _transaction;
    if (transaction != null) {
      transaction.delete(_collection, id);
    } else {
      _requireOpen().delete(_collection, id);
    }
  }

  entidb.EntityId _entityId(int id) {
    final bytes = Uint8List(16);
    final data = ByteData.view(bytes.buffer);
    data.setInt64(8, id);
    return entidb.EntityId.fromBytes(bytes);
  }

  Uint8List _bytes(BenchmarkRecord record) {
    return Uint8List.fromList(utf8.encode(jsonEncode(record.toJson())));
  }

  BenchmarkRecord _recordFromBytes(Uint8List bytes) {
    return BenchmarkRecord.fromJson(jsonDecode(utf8.decode(bytes)) as Map);
  }
}

final class PowerSyncAdapter implements TransactionalDatabaseAdapter {
  powersync.PowerSyncDatabase? _database;
  sqlite_async.SqliteWriteContext? _transaction;

  @override
  String get name => 'powersync';

  @override
  Future<bool> get isSupported async => true;

  @override
  Future<void> open() async {
    final basePath = await benchmarkStoragePath();
    _database = powersync.PowerSyncDatabase(
      schema: powersync.Schema([
        powersync.Table.localOnly(
          'records',
          [
            const powersync.Column.text('title'),
            const powersync.Column.text('record_group'),
            const powersync.Column.integer('value'),
            const powersync.Column.text('payload'),
            const powersync.Column.integer('updated_at_micros'),
          ],
          indexes: [
            powersync.Index.ascending('idx_records_group', ['record_group']),
          ],
        ),
      ]),
      path: p.join(basePath!, 'powersync.db'),
    );
    await _database!.initialize();
  }

  @override
  Future<void> clear() => _execute('DELETE FROM records');

  @override
  Future<void> write(BenchmarkRecord record) {
    return _execute(
      '''
INSERT INTO records(id, title, record_group, value, payload, updated_at_micros)
VALUES (?, ?, ?, ?, ?, ?)
''',
      [
        '${record.id}',
        record.title,
        record.group,
        record.value,
        record.payload,
        record.updatedAtMicros,
      ],
    );
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final row = await _readOptional(
      'SELECT * FROM records WHERE id = ? LIMIT 1',
      ['$id'],
    );
    return row == null ? null : _record(row);
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    final rows = await _readAll(
      'SELECT * FROM records WHERE record_group = ?',
      [group],
    );
    return [for (final row in rows) _record(row)];
  }

  @override
  Future<void> update(BenchmarkRecord record) {
    return _execute(
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
        '${record.id}',
      ],
    );
  }

  @override
  Future<void> delete(int id) {
    return _execute('DELETE FROM records WHERE id = ?', ['$id']);
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  @override
  Future<T> runWriteTransaction<T>(Future<T> Function() action) {
    if (_transaction != null) {
      return action();
    }
    return _requireOpen().writeTransaction((tx) async {
      _transaction = tx;
      try {
        return await action();
      } finally {
        _transaction = null;
      }
    });
  }

  powersync.PowerSyncDatabase _requireOpen() {
    final database = _database;
    if (database == null) {
      throw StateError('PowerSyncAdapter is not open.');
    }
    return database;
  }

  Future<void> _execute(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    final transaction = _transaction;
    if (transaction != null) {
      await transaction.execute(sql, parameters);
    } else {
      await _requireOpen().execute(sql, parameters);
    }
  }

  Future<List<Map<String, Object?>>> _readAll(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    final transaction = _transaction;
    if (transaction != null) {
      return transaction.getAll(sql, parameters);
    }
    return _requireOpen().getAll(sql, parameters);
  }

  Future<Map<String, Object?>?> _readOptional(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    final transaction = _transaction;
    if (transaction != null) {
      return transaction.getOptional(sql, parameters);
    }
    return _requireOpen().getOptional(sql, parameters);
  }

  BenchmarkRecord _record(Map<String, Object?> row) {
    return BenchmarkRecord(
      id: int.parse(row['id']! as String),
      title: row['title']! as String,
      group: row['record_group']! as String,
      value: row['value']! as int,
      payload: row['payload']! as String,
      updatedAtMicros: row['updated_at_micros']! as int,
    );
  }
}

const _createSql = '''
CREATE TABLE records(
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  record_group TEXT NOT NULL,
  value INTEGER NOT NULL,
  payload TEXT NOT NULL,
  updated_at_micros INTEGER NOT NULL
)
''';

const _createGroupIndexSql =
    'CREATE INDEX IF NOT EXISTS idx_records_group ON records(record_group)';

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

BenchmarkRecord _decodeRecord(String source) {
  return BenchmarkRecord.fromJson(jsonDecode(source) as Map);
}

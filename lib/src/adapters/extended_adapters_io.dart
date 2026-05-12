// ignore_for_file: experimental_member_use

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:entidb_flutter/entidb_flutter.dart' as entidb;
import 'package:fdatabase/fdatabase.dart' as fdatabase;
import 'package:ffastdb/ffastdb.dart' as ffastdb;
import 'package:flutterdb/flutterdb.dart' as flutterdb;
import 'package:hive/hive.dart' as hive;
import 'package:isar/isar.dart' as original_isar;
import 'package:isar_community/isar.dart' as isar;
import 'package:isar_db/isar_db.dart' as isar_db;
import 'package:isar_plus/isar_plus.dart' as isar_plus;
import 'package:local_shared/local_shared.dart' as local_shared;
import 'package:localstorage/localstorage.dart' as localstorage;
import 'package:objectdb/objectdb.dart' as objectdb;
import 'package:objectbox/objectbox.dart' as objectbox;
import 'package:offline_db/offline_db.dart' as offline_db;
// objectdb exposes StorageInterface publicly but keeps the concrete file
// storage backend internal; the adapter needs that backend to benchmark IO.
// ignore: implementation_imports
import 'package:objectdb/src/objectdb_storage_filesystem.dart'
    as objectdb_storage;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:powersync/powersync.dart' as powersync;
import 'package:reaxdb_dart/reaxdb_dart.dart' as reaxdb;
import 'package:relax_orm/relax_orm.dart' as relax_orm;
import 'package:sembast/sembast.dart' as sembast;
import 'package:sembast_sqflite/sembast_sqflite.dart' as sembast_sqflite;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_sqlcipher/sqflite.dart' as cipher;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:sqlbrite/sqlbrite.dart' as sqlbrite;
import 'package:sqlite_async/sqlite_async.dart' as sqlite_async;
import 'package:store_box/store_box.dart' as store_box;
import 'package:tiny_db/tiny_db.dart' as tiny_db;
import 'package:work_db/work_db.dart' as work_db;

import '../benchmark/database_adapter.dart';
import '../platform/storage_directory.dart';
import '../../objectbox.g.dart' as objectbox_model;
import 'isar_community_models.dart';
import 'isar_db_models.dart';
import 'isar_models.dart';
import 'isar_plus_models.dart';
import 'objectbox_models.dart';

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
      name: 'floor',
      reason:
          'Floor is a sqflite ORM that requires generated database classes; raw SQLite performance is measured by sqflite.',
    ),
    SqlBriteAdapter(),
    FlutterDbAdapter(),
    const UnsupportedDatabaseAdapter(
      name: 'drift_flutter',
      reason:
          'drift_flutter configures Drift for Flutter platforms; storage performance is measured by the Drift adapter.',
    ),
    const UnsupportedDatabaseAdapter(
      name: 'drift_sqlite_async',
      reason:
          'drift_sqlite_async bridges Drift to sqlite_async; the underlying engines are measured by Drift and sqlite_async adapters.',
    ),
    const UnsupportedDatabaseAdapter(
      name: 'sqlite3_flutter_libs',
      reason:
          'sqlite3_flutter_libs is an end-of-life runtime package; sqlite3 3.x is measured directly without this dependency.',
    ),
    ObjectBoxAdapter(),
    const UnsupportedDatabaseAdapter(
      name: 'objectbox_flutter_libs',
      reason:
          'objectbox_flutter_libs ships ObjectBox runtime libraries; object database coverage is represented by objectbox.',
    ),
    IsarAdapter(),
    IsarCommunityAdapter(),
    IsarDbAdapter(),
    IsarPlusAdapter(),
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
    FDatabaseAdapter(),
    RelaxOrmAdapter(),
    LocalSharedAdapter(),
    const UnsupportedDatabaseAdapter(
      name: 'rxdb',
      reason:
          'rxdb pins shared_preferences 2.0.17, conflicting with shared_preferences 2.5.5.',
    ),
    const UnsupportedDatabaseAdapter(
      name: 'instantdb_flutter',
      reason:
          'instantdb_flutter is an offline-first sync client; a fair benchmark requires a configured Instant backend instead of a local-only synthetic adapter.',
    ),
    const UnsupportedDatabaseAdapter(
      name: 'appwrite_offline',
      reason:
          'appwrite_offline is an Appwrite sync adapter; a fair benchmark requires an Appwrite project and sync workload.',
    ),
    OfflineDbAdapter(),
    const UnsupportedDatabaseAdapter(
      name: 'cloud_firestore',
      reason:
          'cloud_firestore is a hosted database SDK; benchmark results would include Firebase project configuration, network, and cache policy rather than only local storage.',
    ),
    const UnsupportedDatabaseAdapter(
      name: 'firebase_database',
      reason:
          'firebase_database is a hosted realtime database SDK; benchmark results would include Firebase project configuration, network, and cache policy rather than only local storage.',
    ),
    const UnsupportedDatabaseAdapter(
      name: 'serverpod',
      reason:
          'serverpod is an app server framework, not an embedded Flutter database adapter.',
    ),
    LocalStorageAdapter(),
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

final class SqlBriteAdapter implements TransactionalDatabaseAdapter {
  sqlbrite.IBriteDatabase? _database;
  sqflite.Transaction? _transaction;

  @override
  String get name => 'sqlbrite';

  @override
  Future<bool> get isSupported async =>
      Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isMacOS ||
      Platform.isWindows ||
      Platform.isLinux;

  @override
  Future<void> open() async {
    _ensureSqfliteFfiFactory();
    final basePath = await benchmarkStoragePath();
    final database = await sqflite.databaseFactory.openDatabase(
      p.join(basePath!, 'dbench_sqlbrite.db'),
      options: sqflite.OpenDatabaseOptions(
        version: 1,
        onCreate: (database, version) async {
          await database.execute(_createSql);
          await database.execute(_createGroupIndexSql);
        },
      ),
    );
    await database.execute(_createGroupIndexSql);
    _database = sqlbrite.BriteDatabase(database, logger: null);
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
    _transaction = null;
  }

  @override
  Future<T> runWriteTransaction<T>(Future<T> Function() action) {
    return _requireOpen().transactionAndTrigger((transaction) async {
      _transaction = transaction;
      try {
        return await action();
      } finally {
        _transaction = null;
      }
    });
  }

  sqlbrite.IBriteDatabase _requireOpen() {
    final database = _database;
    if (database == null) {
      throw StateError('SqlBriteAdapter is not open.');
    }
    return database;
  }

  sqflite.DatabaseExecutor get _executor => _transaction ?? _requireOpen();
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

final class FlutterDbAdapter implements DatabaseAdapter {
  flutterdb.FlutterDB? _database;
  flutterdb.Collection? _collection;

  @override
  String get name => 'flutterdb';

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
    _ensureSqfliteFfiFactory();
    final database = flutterdb.FlutterDB();
    await database.dropCollection('records');
    _database = database;
    _collection = await database.collection('records');
  }

  @override
  Future<void> clear() async {
    final database = _requireDatabase();
    await database.dropCollection('records');
    _collection = await database.collection('records');
  }

  @override
  Future<void> write(BenchmarkRecord record) {
    return _requireOpen().insert(_document(record));
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final value = await _requireOpen().findById('$id');
    return value == null ? null : _record(value);
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    final values = await _requireOpen().find({'group': group});
    return [for (final value in values) _record(value)];
  }

  @override
  Future<void> update(BenchmarkRecord record) async {
    await _requireOpen().updateById('${record.id}', _document(record));
  }

  @override
  Future<void> delete(int id) async {
    await _requireOpen().deleteById('$id');
  }

  @override
  Future<void> close() async {
    _collection = null;
    _database = null;
  }

  flutterdb.FlutterDB _requireDatabase() {
    final database = _database;
    if (database == null) {
      throw StateError('FlutterDbAdapter is not open.');
    }
    return database;
  }

  flutterdb.Collection _requireOpen() {
    final collection = _collection;
    if (collection == null) {
      throw StateError('FlutterDbAdapter is not open.');
    }
    return collection;
  }

  Map<String, dynamic> _document(BenchmarkRecord record) {
    return {'_id': '${record.id}', ...record.toJson().cast<String, dynamic>()};
  }

  BenchmarkRecord _record(Map<String, dynamic> value) {
    return BenchmarkRecord.fromJson(value);
  }
}

final class FDatabaseAdapter implements DatabaseAdapter {
  fdatabase.FDatabase? _database;
  final _ids = <int>{};

  @override
  String get name => 'fdatabase';

  @override
  Future<bool> get isSupported async => true;

  @override
  Future<void> open() async {
    _database = await fdatabase.FDatabase.getInstance();
  }

  @override
  Future<void> clear() async {
    _requireOpen().clear();
    _ids.clear();
  }

  @override
  Future<void> write(BenchmarkRecord record) async {
    _ids.add(record.id);
    _requireOpen().put<String>(_key(record.id), jsonEncode(record.toJson()));
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final value = _requireOpen().get<String>(_key(id));
    return value == null
        ? null
        : BenchmarkRecord.fromJson(jsonDecode(value) as Map);
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
  Future<void> update(BenchmarkRecord record) => write(record);

  @override
  Future<void> delete(int id) async {
    _ids.remove(id);
    _requireOpen().delete(_key(id));
  }

  @override
  Future<void> close() async {
    _database = null;
    _ids.clear();
  }

  fdatabase.FDatabase _requireOpen() {
    final database = _database;
    if (database == null) {
      throw StateError('FDatabaseAdapter is not open.');
    }
    return database;
  }

  String _key(int id) => 'record:$id';
}

final class LocalSharedAdapter implements DatabaseAdapter {
  local_shared.SharedCollection? _collection;

  @override
  String get name => 'local_shared';

  @override
  Future<bool> get isSupported async => true;

  @override
  Future<void> open() async {
    await const local_shared.LocalShared('').initialize();
    _collection = local_shared.Shared.col(_localSharedCollectionId);
    await _collection!.create(replace: true);
  }

  @override
  Future<void> clear() async {
    await _requireOpen().delete();
    await _requireOpen().create(replace: true);
  }

  @override
  Future<void> write(BenchmarkRecord record) async {
    final response = await _requireOpen()
        .doc('${record.id}')
        .create(record.toJson().cast<String, dynamic>(), merge: true);
    _checkLocalSharedResponse(response, 'write', record.id);
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final response = await _requireOpen().doc('$id').read();
    if (!response.success) {
      return null;
    }
    return BenchmarkRecord.fromJson(response.data! as Map);
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    final response = await _requireOpen().read();
    if (!response.success) {
      return const [];
    }
    final values = response.data! as List;
    return [
      for (final value in values)
        if (BenchmarkRecord.fromJson(value).group == group)
          BenchmarkRecord.fromJson(value),
    ];
  }

  @override
  Future<void> update(BenchmarkRecord record) async {
    final response = await _requireOpen()
        .doc('${record.id}')
        .update(record.toJson().cast<String, dynamic>(), force: true);
    _checkLocalSharedResponse(response, 'update', record.id);
  }

  @override
  Future<void> delete(int id) async {
    final response = await _requireOpen().doc('$id').delete();
    _checkLocalSharedResponse(response, 'delete', id);
  }

  @override
  Future<void> close() async {
    _collection = null;
  }

  local_shared.SharedCollection _requireOpen() {
    final collection = _collection;
    if (collection == null) {
      throw StateError('LocalSharedAdapter is not open.');
    }
    return collection;
  }

  void _checkLocalSharedResponse(
    local_shared.SharedResponse response,
    String operation,
    int id,
  ) {
    if (!response.success) {
      throw StateError('local_shared $operation failed for record $id.');
    }
  }

  static const _localSharedCollectionId = 'dbench_local_shared_records';
}

final class RelaxOrmAdapter implements DatabaseAdapter {
  relax_orm.RelaxDB? _database;
  relax_orm.Collection<BenchmarkRecord>? _collection;

  @override
  String get name => 'relax_orm';

  @override
  Future<bool> get isSupported async =>
      Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isMacOS ||
      Platform.isWindows ||
      Platform.isLinux;

  @override
  Future<void> open() async {
    final basePath = await benchmarkStoragePath();
    final file = File(p.join(basePath!, 'dbench_relax_orm.sqlite'));
    _database = await relax_orm.RelaxDB.openFile(
      file: file,
      schemas: [_relaxBenchmarkRecordSchema],
    );
    _collection = _database!.collection<BenchmarkRecord>();
  }

  @override
  Future<void> clear() => _requireOpen().deleteAll();

  @override
  Future<void> write(BenchmarkRecord record) => _requireOpen().add(record);

  @override
  Future<BenchmarkRecord?> read(int id) => _requireOpen().get(id);

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) {
    return _requireOpen().query().where('record_group', equals: group).find();
  }

  @override
  Future<void> update(BenchmarkRecord record) async {
    await _requireOpen().update(record);
  }

  @override
  Future<void> delete(int id) async {
    await _requireOpen().delete(id);
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
    _collection = null;
  }

  relax_orm.Collection<BenchmarkRecord> _requireOpen() {
    final collection = _collection;
    if (collection == null) {
      throw StateError('RelaxOrmAdapter is not open.');
    }
    return collection;
  }
}

final _relaxBenchmarkRecordSchema = relax_orm.TableSchema<BenchmarkRecord>(
  tableName: 'records',
  columns: const [
    relax_orm.ColumnDef.integer('id', isPrimaryKey: true),
    relax_orm.ColumnDef.text('title'),
    relax_orm.ColumnDef.text('record_group'),
    relax_orm.ColumnDef.integer('value'),
    relax_orm.ColumnDef.text('payload'),
    relax_orm.ColumnDef.integer('updated_at_micros'),
  ],
  fromMap: (map) => BenchmarkRecord(
    id: map['id'] as int,
    title: map['title'] as String,
    group: map['record_group'] as String,
    value: map['value'] as int,
    payload: map['payload'] as String,
    updatedAtMicros: map['updated_at_micros'] as int,
  ),
  toMap: _row,
);

final class LocalStorageAdapter implements DatabaseAdapter {
  localstorage.LocalStorage? _storage;

  @override
  String get name => 'localstorage';

  @override
  Future<bool> get isSupported async => true;

  @override
  Future<void> open() async {
    await _seedLocalStorageFile();
    await localstorage.initLocalStorage();
    _storage = localstorage.localStorage;
  }

  @override
  Future<void> clear() async {
    _requireOpen().clear();
  }

  @override
  Future<void> write(BenchmarkRecord record) async {
    _requireOpen().setItem(_key(record.id), jsonEncode(record.toJson()));
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final value = _requireOpen().getItem(_key(id));
    return value == null
        ? null
        : BenchmarkRecord.fromJson(jsonDecode(value) as Map);
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    final storage = _requireOpen();
    final records = <BenchmarkRecord>[];
    for (var index = 0; index < storage.length; index++) {
      final key = storage.key(index);
      if (key == null || !key.startsWith('record:')) {
        continue;
      }
      final value = storage.getItem(key);
      if (value == null) {
        continue;
      }
      final record = BenchmarkRecord.fromJson(jsonDecode(value) as Map);
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
    _requireOpen().removeItem(_key(id));
  }

  @override
  Future<void> close() async {
    _storage = null;
  }

  localstorage.LocalStorage _requireOpen() {
    final storage = _storage;
    if (storage == null) {
      throw StateError('LocalStorageAdapter is not open.');
    }
    return storage;
  }

  String _key(int id) => 'record:$id';
}

Future<void> _seedLocalStorageFile() async {
  if (!Platform.isAndroid &&
      !Platform.isIOS &&
      !Platform.isMacOS &&
      !Platform.isWindows &&
      !Platform.isLinux) {
    return;
  }
  final directory = await path_provider.getApplicationDocumentsDirectory();
  final file = File(
    p.join(directory.path, 'storage-61f76cb0-842b-4318-a644-e245f50a0b5a.json'),
  );
  if (!await file.exists()) {
    await file.create(recursive: true);
    await file.writeAsString('{}');
  }
}

final class OfflineDbAdapter implements DatabaseAdapter {
  offline_db.OfflineDB? _database;
  offline_db.OfflineNode<BenchmarkRecord>? _node;

  @override
  String get name => 'offline_db';

  @override
  Future<bool> get isSupported async => true;

  @override
  Future<void> open() async {
    final basePath = await benchmarkStoragePath();
    final directory = p.join(basePath!, 'offline_db');
    Directory(directory).createSync(recursive: true);
    final node = offline_db.OfflineNode<BenchmarkRecord>.standalone(
      'records',
      adapter: offline_db.SimpleAdapter<BenchmarkRecord>(
        getId: (record) => '${record.id}',
        toJson: (record) => {
          ...record.toJson().cast<String, dynamic>(),
          'id': '${record.id}',
        },
        fromJson: (json) => BenchmarkRecord.fromJson({
          ...json,
          'id': int.parse(json['id'] as String),
        }),
      ),
    );
    final database = offline_db.OfflineDB(
      nodes: [node],
      localDB: offline_db.HiveOfflineDelegate(customPath: directory),
    );
    await database.initialize();
    _database = database;
    _node = node;
  }

  @override
  Future<void> clear() => _requireOpen().clearAllData();

  @override
  Future<void> write(BenchmarkRecord record) => _requireNode().upsert(record);

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final records = await _requireNode()
        .query()
        .where('id', isEqualTo: '$id')
        .getAll();
    return records.isEmpty ? null : records.single.item;
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    final records = await _requireNode()
        .query()
        .where('group', isEqualTo: group)
        .getAll();
    return [for (final record in records) record.item];
  }

  @override
  Future<void> update(BenchmarkRecord record) => write(record);

  @override
  Future<void> delete(int id) => _requireNode().delete('$id');

  @override
  Future<void> close() async {
    await _database?.dispose();
    _database = null;
    _node = null;
  }

  offline_db.OfflineDB _requireOpen() {
    final database = _database;
    if (database == null) {
      throw StateError('OfflineDbAdapter is not open.');
    }
    return database;
  }

  offline_db.OfflineNode<BenchmarkRecord> _requireNode() {
    final node = _node;
    if (node == null) {
      throw StateError('OfflineDbAdapter is not open.');
    }
    return node;
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

final class ObjectBoxAdapter implements DatabaseAdapter {
  objectbox.Store? _store;
  objectbox.Box<ObjectBoxBenchmarkRecord>? _box;

  @override
  String get name => 'objectbox';

  @override
  Future<bool> get isSupported async =>
      Platform.isAndroid ||
      Platform.isIOS ||
      Abi.current() == Abi.windowsX64 ||
      Abi.current() == Abi.linuxX64 ||
      Abi.current() == Abi.macosX64 ||
      Abi.current() == Abi.macosArm64;

  @override
  Future<void> open() async {
    final basePath = await benchmarkStoragePath();
    final directory = p.join(basePath!, 'objectbox');
    Directory(directory).createSync(recursive: true);
    await _ensureObjectBoxRuntime();
    _store = await objectbox_model.openStore(directory: directory);
    _box = _store!.box<ObjectBoxBenchmarkRecord>();
  }

  @override
  Future<void> clear() async {
    _requireBox().removeAll();
  }

  @override
  Future<void> write(BenchmarkRecord record) async {
    _requireBox().put(_objectBoxRecord(record));
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final record = _requireBox().get(_objectBoxId(id));
    return record == null ? null : _recordFromObjectBox(record);
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    final query = _requireBox()
        .query(objectbox_model.ObjectBoxBenchmarkRecord_.group.equals(group))
        .build();
    try {
      return [for (final record in query.find()) _recordFromObjectBox(record)];
    } finally {
      query.close();
    }
  }

  @override
  Future<void> update(BenchmarkRecord record) => write(record);

  @override
  Future<void> delete(int id) async {
    _requireBox().remove(_objectBoxId(id));
  }

  @override
  Future<void> close() async {
    _box = null;
    _store?.close();
    _store = null;
  }

  objectbox.Box<ObjectBoxBenchmarkRecord> _requireBox() {
    final box = _box;
    if (box == null) {
      throw StateError('ObjectBoxAdapter is not open.');
    }
    return box;
  }

  ObjectBoxBenchmarkRecord _objectBoxRecord(BenchmarkRecord record) {
    return ObjectBoxBenchmarkRecord(
      id: _objectBoxId(record.id),
      title: record.title,
      group: record.group,
      value: record.value,
      payload: record.payload,
      updatedAtMicros: record.updatedAtMicros,
    );
  }

  BenchmarkRecord _recordFromObjectBox(ObjectBoxBenchmarkRecord record) {
    return BenchmarkRecord(
      id: record.id - 1,
      title: record.title,
      group: record.group,
      value: record.value,
      payload: record.payload,
      updatedAtMicros: record.updatedAtMicros,
    );
  }

  int _objectBoxId(int benchmarkId) => benchmarkId + 1;
}

Future<void> _ensureObjectBoxRuntime() async {
  final config = _objectBoxRuntimeConfig();
  if (config == null) {
    return;
  }
  final library = File(p.join(Directory.current.path, 'lib', config.fileName));
  if (await library.exists()) {
    return;
  }
  await library.parent.create(recursive: true);
  final archive = File(p.join(Directory.systemTemp.path, config.archiveName));
  if (!await archive.exists()) {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(config.downloadUrl));
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw StateError(
          'ObjectBox runtime download failed: HTTP ${response.statusCode}.',
        );
      }
      await response.pipe(archive.openWrite());
    } finally {
      client.close(force: true);
    }
  }
  final extraction = Directory(
    p.join(Directory.systemTemp.path, config.extractionName),
  );
  if (await extraction.exists()) {
    await extraction.delete(recursive: true);
  }
  await extraction.create(recursive: true);
  final extractionResult = config.isZip
      ? await Process.run(
          Platform.isWindows ? 'powershell' : 'unzip',
          Platform.isWindows
              ? [
                  '-NoProfile',
                  '-Command',
                  'Expand-Archive -LiteralPath ${_psQuote(archive.path)} '
                      '-DestinationPath ${_psQuote(extraction.path)} -Force',
                ]
              : ['-q', archive.path, '-d', extraction.path],
        )
      : await Process.run('tar', ['-xzf', archive.path, '-C', extraction.path]);
  if (extractionResult.exitCode != 0) {
    throw StateError(
      'ObjectBox runtime extraction failed: ${extractionResult.stderr}',
    );
  }
  File? runtime;
  await for (final entity in extraction.list(recursive: true)) {
    if (entity is File && p.basename(entity.path) == config.fileName) {
      runtime = entity;
      break;
    }
  }
  if (runtime == null) {
    throw StateError(
      'ObjectBox runtime archive did not contain ${config.fileName}.',
    );
  }
  await runtime.copy(library.path);
}

String _psQuote(String value) => "'${value.replaceAll("'", "''")}'";

({
  String fileName,
  String archiveName,
  String extractionName,
  String downloadUrl,
  bool isZip,
})?
_objectBoxRuntimeConfig() {
  const version = '5.3.1';
  const baseUrl =
      'https://github.com/objectbox/objectbox-c/releases/download/v$version';
  if (Abi.current() == Abi.windowsX64) {
    return (
      fileName: 'objectbox.dll',
      archiveName: 'objectbox-windows-x64-$version.zip',
      extractionName: 'objectbox-windows-x64-$version',
      downloadUrl: '$baseUrl/objectbox-windows-x64.zip',
      isZip: true,
    );
  }
  if (Abi.current() == Abi.linuxX64) {
    return (
      fileName: 'libobjectbox.so',
      archiveName: 'objectbox-linux-x64-$version.tar.gz',
      extractionName: 'objectbox-linux-x64-$version',
      downloadUrl: '$baseUrl/objectbox-linux-x64.tar.gz',
      isZip: false,
    );
  }
  if (Abi.current() == Abi.macosX64 || Abi.current() == Abi.macosArm64) {
    return (
      fileName: 'libobjectbox.dylib',
      archiveName: 'objectbox-macos-universal-$version.zip',
      extractionName: 'objectbox-macos-universal-$version',
      downloadUrl: '$baseUrl/objectbox-macos-universal.zip',
      isZip: true,
    );
  }
  return null;
}

final class IsarAdapter implements TransactionalDatabaseAdapter {
  original_isar.Isar? _database;
  var _isInWriteTransaction = false;

  @override
  String get name => 'isar';

  @override
  Future<bool> get isSupported async =>
      Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isMacOS ||
      Platform.isWindows ||
      Platform.isLinux;

  @override
  Future<void> open() async {
    final basePath = await benchmarkStoragePath();
    final directory = p.join(basePath!, 'isar');
    Directory(directory).createSync(recursive: true);
    await _initializeOriginalIsarCore();
    _database = await original_isar.Isar.open(
      [IsarBenchmarkRecordSchema],
      directory: directory,
      name: 'dbench_isar',
      inspector: false,
    );
  }

  @override
  Future<void> clear() => _write(() => _collection.clear());

  @override
  Future<void> write(BenchmarkRecord record) {
    return _write(() => _collection.put(_isarRecord(record)));
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final record = await _collection.get(id);
    return record == null ? null : _recordFromIsar(record);
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    final records = await _collection
        .buildQuery<IsarBenchmarkRecord>(
          whereClauses: const [original_isar.IdWhereClause.any()],
          filter: original_isar.FilterCondition.equalTo(
            property: 'group',
            value: group,
          ),
        )
        .findAll();
    return [for (final record in records) _recordFromIsar(record)];
  }

  @override
  Future<void> update(BenchmarkRecord record) => write(record);

  @override
  Future<void> delete(int id) => _write(() => _collection.delete(id));

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
    _isInWriteTransaction = false;
  }

  @override
  Future<T> runWriteTransaction<T>(Future<T> Function() action) {
    if (_isInWriteTransaction) {
      return action();
    }
    return _requireOpen().writeTxn(() async {
      _isInWriteTransaction = true;
      try {
        return await action();
      } finally {
        _isInWriteTransaction = false;
      }
    });
  }

  Future<T> _write<T>(Future<T> Function() action) {
    if (_isInWriteTransaction) {
      return action();
    }
    return runWriteTransaction(action);
  }

  original_isar.Isar _requireOpen() {
    final database = _database;
    if (database == null) {
      throw StateError('IsarAdapter is not open.');
    }
    return database;
  }

  original_isar.IsarCollection<IsarBenchmarkRecord> get _collection {
    return _requireOpen().collection<IsarBenchmarkRecord>();
  }

  IsarBenchmarkRecord _isarRecord(BenchmarkRecord record) {
    return IsarBenchmarkRecord()
      ..id = record.id
      ..title = record.title
      ..group = record.group
      ..value = record.value
      ..payload = record.payload
      ..updatedAtMicros = record.updatedAtMicros;
  }

  BenchmarkRecord _recordFromIsar(IsarBenchmarkRecord record) {
    return BenchmarkRecord(
      id: record.id,
      title: record.title,
      group: record.group,
      value: record.value,
      payload: record.payload,
      updatedAtMicros: record.updatedAtMicros,
    );
  }
}

Future<void> _initializeOriginalIsarCore() async {
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
    return;
  }
  final packageRoot = await _packageRootPath('isar_flutter_libs');
  if (packageRoot == null) {
    return;
  }
  final relativeLibraryPath = switch (Abi.current()) {
    Abi.windowsX64 || Abi.windowsArm64 => p.join('windows', 'isar.dll'),
    Abi.linuxX64 => p.join('linux', 'libisar.so'),
    Abi.macosX64 || Abi.macosArm64 => p.join('macos', 'libisar.dylib'),
    _ => null,
  };
  if (relativeLibraryPath == null) {
    return;
  }
  final libraryPath = p.join(packageRoot, relativeLibraryPath);
  if (File(libraryPath).existsSync()) {
    await original_isar.Isar.initializeIsarCore(
      libraries: {Abi.current(): libraryPath},
    );
  }
}

final class IsarDbAdapter implements DatabaseAdapter {
  isar_db.Isar? _database;

  @override
  String get name => 'isar_db';

  @override
  Future<bool> get isSupported async =>
      Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isMacOS ||
      Platform.isWindows ||
      Platform.isLinux;

  @override
  Future<void> open() async {
    final basePath = await benchmarkStoragePath();
    final directory = p.join(basePath!, 'isar_db');
    Directory(directory).createSync(recursive: true);
    await _initializeIsarDbCore();
    _database = isar_db.Isar.open(
      schemas: [IsarDbBenchmarkRecordSchema],
      directory: directory,
      name: 'dbench_isar_db',
      inspector: false,
    );
  }

  @override
  Future<void> clear() async {
    _requireOpen().write((_) => _collection.clear());
  }

  @override
  Future<void> write(BenchmarkRecord record) async {
    _requireOpen().write((_) => _collection.put(_isarRecord(record)));
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final record = _collection.get(id);
    return record == null ? null : _recordFromIsar(record);
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    final query = _collection.buildQuery<IsarDbBenchmarkRecord>(
      filter: isar_db.EqualCondition(property: 1, value: group),
    );
    try {
      final records = query.findAll();
      return [for (final record in records) _recordFromIsar(record)];
    } finally {
      query.close();
    }
  }

  @override
  Future<void> update(BenchmarkRecord record) => write(record);

  @override
  Future<void> delete(int id) async {
    _requireOpen().write((_) => _collection.delete(id));
  }

  @override
  Future<void> close() async {
    final database = _database;
    _database = null;
    if (database != null && database.isOpen) {
      await database.close();
    }
  }

  isar_db.Isar _requireOpen() {
    final database = _database;
    if (database == null) {
      throw StateError('IsarDbAdapter is not open.');
    }
    return database;
  }

  isar_db.IsarCollection<int, IsarDbBenchmarkRecord> get _collection {
    return _requireOpen().collection<int, IsarDbBenchmarkRecord>();
  }

  IsarDbBenchmarkRecord _isarRecord(BenchmarkRecord record) {
    return IsarDbBenchmarkRecord()
      ..id = record.id
      ..title = record.title
      ..group = record.group
      ..value = record.value
      ..payload = record.payload
      ..updatedAtMicros = record.updatedAtMicros;
  }

  BenchmarkRecord _recordFromIsar(IsarDbBenchmarkRecord record) {
    return BenchmarkRecord(
      id: record.id,
      title: record.title,
      group: record.group,
      value: record.value,
      payload: record.payload,
      updatedAtMicros: record.updatedAtMicros,
    );
  }
}

Future<void> _initializeIsarDbCore() async {
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
    return;
  }
  final packageRoot = await _packageRootPath('isar_plus_flutter_libs');
  if (packageRoot == null) {
    return;
  }
  final relativeLibraryPath = switch (Abi.current()) {
    Abi.windowsX64 || Abi.windowsArm64 => p.join('windows', 'isar.dll'),
    Abi.linuxX64 => p.join('linux', 'libisar.so'),
    Abi.macosX64 || Abi.macosArm64 => p.join('macos', 'libisar.dylib'),
    _ => null,
  };
  if (relativeLibraryPath == null) {
    return;
  }
  final libraryPath = p.join(packageRoot, relativeLibraryPath);
  if (File(libraryPath).existsSync()) {
    await isar_db.Isar.initialize(libraryPath);
  }
}

final class IsarPlusAdapter implements DatabaseAdapter {
  isar_plus.Isar? _database;

  @override
  String get name => 'isar_plus';

  @override
  Future<bool> get isSupported async =>
      Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isMacOS ||
      Platform.isWindows ||
      Platform.isLinux;

  @override
  Future<void> open() async {
    final basePath = await benchmarkStoragePath();
    final directory = p.join(basePath!, 'isar_plus');
    Directory(directory).createSync(recursive: true);
    await _initializeIsarPlusCore();
    _database = isar_plus.Isar.open(
      schemas: [IsarPlusBenchmarkRecordSchema],
      directory: directory,
      name: 'dbench_isar_plus',
      inspector: false,
    );
  }

  @override
  Future<void> clear() async {
    _requireOpen().write((_) => _collection.clear());
  }

  @override
  Future<void> write(BenchmarkRecord record) async {
    _requireOpen().write((_) => _collection.put(_isarRecord(record)));
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final record = _collection.get(id);
    return record == null ? null : _recordFromIsar(record);
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    final query = _collection.buildQuery<IsarPlusBenchmarkRecord>(
      filter: isar_plus.EqualCondition(property: 1, value: group),
    );
    try {
      final records = query.findAll();
      return [for (final record in records) _recordFromIsar(record)];
    } finally {
      query.close();
    }
  }

  @override
  Future<void> update(BenchmarkRecord record) => write(record);

  @override
  Future<void> delete(int id) async {
    _requireOpen().write((_) => _collection.delete(id));
  }

  @override
  Future<void> close() async {
    _database?.close();
    _database = null;
  }

  isar_plus.Isar _requireOpen() {
    final database = _database;
    if (database == null) {
      throw StateError('IsarPlusAdapter is not open.');
    }
    return database;
  }

  isar_plus.IsarCollection<int, IsarPlusBenchmarkRecord> get _collection {
    return _requireOpen().collection<int, IsarPlusBenchmarkRecord>();
  }

  IsarPlusBenchmarkRecord _isarRecord(BenchmarkRecord record) {
    return IsarPlusBenchmarkRecord()
      ..id = record.id
      ..title = record.title
      ..group = record.group
      ..value = record.value
      ..payload = record.payload
      ..updatedAtMicros = record.updatedAtMicros;
  }

  BenchmarkRecord _recordFromIsar(IsarPlusBenchmarkRecord record) {
    return BenchmarkRecord(
      id: record.id,
      title: record.title,
      group: record.group,
      value: record.value,
      payload: record.payload,
      updatedAtMicros: record.updatedAtMicros,
    );
  }
}

Future<void> _initializeIsarPlusCore() async {
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
    return;
  }
  final packageRoot = await _packageRootPath('isar_plus_flutter_libs');
  if (packageRoot == null) {
    return;
  }
  final relativeLibraryPath = switch (Abi.current()) {
    Abi.windowsX64 || Abi.windowsArm64 => p.join('windows', 'isar.dll'),
    Abi.linuxX64 => p.join('linux', 'libisar.so'),
    Abi.macosX64 || Abi.macosArm64 => p.join('macos', 'libisar.dylib'),
    _ => null,
  };
  if (relativeLibraryPath == null) {
    return;
  }
  final libraryPath = p.join(packageRoot, relativeLibraryPath);
  if (File(libraryPath).existsSync()) {
    await isar_plus.Isar.initialize(libraryPath);
  }
}

final class IsarCommunityAdapter implements TransactionalDatabaseAdapter {
  isar.Isar? _database;
  var _isInWriteTransaction = false;

  @override
  String get name => 'isar_community';

  @override
  Future<bool> get isSupported async =>
      Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isMacOS ||
      Platform.isWindows ||
      Platform.isLinux;

  @override
  Future<void> open() async {
    final basePath = await benchmarkStoragePath();
    final directory = p.join(basePath!, 'isar_community');
    Directory(directory).createSync(recursive: true);
    await _initializeIsarCommunityCore();
    _database = await isar.Isar.open(
      [IsarCommunityBenchmarkRecordSchema],
      directory: directory,
      name: 'dbench_isar_community',
      inspector: false,
    );
  }

  @override
  Future<void> clear() => _write(() => _collection.clear());

  @override
  Future<void> write(BenchmarkRecord record) {
    return _write(() => _collection.put(_isarRecord(record)));
  }

  @override
  Future<BenchmarkRecord?> read(int id) async {
    final record = await _collection.get(id);
    return record == null ? null : _recordFromIsar(record);
  }

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    final records = await _collection.filter().groupEqualTo(group).findAll();
    return [for (final record in records) _recordFromIsar(record)];
  }

  @override
  Future<void> update(BenchmarkRecord record) => write(record);

  @override
  Future<void> delete(int id) => _write(() => _collection.delete(id));

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
    _isInWriteTransaction = false;
  }

  @override
  Future<T> runWriteTransaction<T>(Future<T> Function() action) {
    if (_isInWriteTransaction) {
      return action();
    }
    return _requireOpen().writeTxn(() async {
      _isInWriteTransaction = true;
      try {
        return await action();
      } finally {
        _isInWriteTransaction = false;
      }
    });
  }

  Future<T> _write<T>(Future<T> Function() action) {
    if (_isInWriteTransaction) {
      return action();
    }
    return runWriteTransaction(action);
  }

  isar.Isar _requireOpen() {
    final database = _database;
    if (database == null) {
      throw StateError('IsarCommunityAdapter is not open.');
    }
    return database;
  }

  isar.IsarCollection<IsarCommunityBenchmarkRecord> get _collection {
    return _requireOpen().collection<IsarCommunityBenchmarkRecord>();
  }

  IsarCommunityBenchmarkRecord _isarRecord(BenchmarkRecord record) {
    return IsarCommunityBenchmarkRecord()
      ..id = record.id
      ..title = record.title
      ..group = record.group
      ..value = record.value
      ..payload = record.payload
      ..updatedAtMicros = record.updatedAtMicros;
  }

  BenchmarkRecord _recordFromIsar(IsarCommunityBenchmarkRecord record) {
    return BenchmarkRecord(
      id: record.id,
      title: record.title,
      group: record.group,
      value: record.value,
      payload: record.payload,
      updatedAtMicros: record.updatedAtMicros,
    );
  }
}

Future<void> _initializeIsarCommunityCore() async {
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
    return;
  }
  final packageRoot = await _packageRootPath('isar_community_flutter_libs');
  if (packageRoot == null) {
    return;
  }
  final relativeLibraryPath = switch (Abi.current()) {
    Abi.windowsX64 || Abi.windowsArm64 => p.join('windows', 'libisar.dll'),
    Abi.linuxX64 => p.join('linux', 'libisar.so'),
    Abi.macosX64 || Abi.macosArm64 => p.join('macos', 'libisar.dylib'),
    _ => null,
  };
  if (relativeLibraryPath == null) {
    return;
  }
  final libraryPath = p.join(packageRoot, relativeLibraryPath);
  if (File(libraryPath).existsSync()) {
    await isar.Isar.initializeIsarCore(libraries: {Abi.current(): libraryPath});
  }
}

Future<String?> _packageRootPath(String packageName) async {
  final packageConfigFile = File(
    p.join(Directory.current.path, '.dart_tool', 'package_config.json'),
  );
  if (!await packageConfigFile.exists()) {
    return null;
  }
  final packageConfig =
      jsonDecode(await packageConfigFile.readAsString())
          as Map<String, Object?>;
  final packages = packageConfig['packages']! as List;
  for (final package in packages.cast<Map<String, Object?>>()) {
    if (package['name'] != packageName) {
      continue;
    }
    final rootUri = package['rootUri']! as String;
    final root = Uri.parse(rootUri);
    if (root.isAbsolute) {
      return File.fromUri(root).path;
    }
    return p.normalize(
      p.join(packageConfigFile.parent.path, root.toFilePath()),
    );
  }
  return null;
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

void _ensureSqfliteFfiFactory() {
  if (!Platform.isWindows && !Platform.isLinux) {
    return;
  }
  ffi.sqfliteFfiInit();
  try {
    if (identical(sqflite.databaseFactory, ffi.databaseFactoryFfi)) {
      return;
    }
  } on StateError {
    // sqflite has no default factory on desktop until one is assigned.
  }
  sqflite.databaseFactory = ffi.databaseFactoryFfi;
}

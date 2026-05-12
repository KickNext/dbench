import '../benchmark/database_adapter.dart';

List<DatabaseAdapter> extendedAdapters() {
  return const [
    UnsupportedDatabaseAdapter(
      name: 'sqflite_sqlcipher',
      reason: 'sqflite_sqlcipher is an Android/iOS SQLCipher plugin.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'sembast_sqflite',
      reason: 'sembast_sqflite requires a sqflite native backend.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'hive',
      reason: 'Hive adapter is measured on Dart IO and Flutter native targets.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'objectdb',
      reason: 'objectdb file-system storage is a Dart IO backend.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'tiny_db',
      reason: 'tiny_db JSON storage adapter is measured on Dart IO targets.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'store_box',
      reason: 'store_box currently exposes a dart:io file backend.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'work_db',
      reason: 'work_db IO adapter is measured on Dart IO targets.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'ffastdb',
      reason: 'ffastdb file storage adapter is measured on Dart IO targets.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'reaxdb_dart',
      reason: 'ReaxDB file storage adapter is measured on Dart IO targets.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'torex_local_store',
      reason:
          'Torex native Rust backend is measured on Flutter native targets.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'flutter_local_db',
      reason:
          'flutter_local_db 1.5.1 declares a Windows plugin but does not ship a Windows plugin directory, which breaks Flutter desktop CMake generation.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'entidb_flutter',
      reason: 'EntiDB FFI backend is measured on Flutter native targets.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'powersync',
      reason: 'PowerSync local SQLite adapter requires native or WASM assets.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'cbl_flutter',
      reason: 'Couchbase Lite requires the Couchbase Lite Flutter runtime.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'couchbase_lite',
      reason:
          'couchbase_lite is the older Couchbase Lite package line; current Flutter runtime coverage is represented by cbl_flutter.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'torexstore',
      reason:
          'torexstore is an early package line superseded by torex_local_store for the measurable Flutter adapter.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'floor',
      reason:
          'Floor is a sqflite ORM that requires generated database classes; raw SQLite performance is measured by sqflite.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'sqlbrite',
      reason:
          'Sqlbrite is a reactive sqflite wrapper; storage performance is measured by sqflite and sqflite_common_ffi.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'flutterdb',
      reason:
          'FlutterDB is a Mongo-like wrapper over sqflite; storage performance is measured by sqflite.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'drift_flutter',
      reason:
          'drift_flutter configures Drift for Flutter platforms; storage performance is measured by the Drift adapter.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'drift_sqlite_async',
      reason:
          'drift_sqlite_async bridges Drift to sqlite_async; the underlying engines are measured by Drift and sqlite_async adapters.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'sqlite3_flutter_libs',
      reason:
          'sqlite3_flutter_libs is an end-of-life runtime package; sqlite3 3.x is measured directly without this dependency.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'objectbox',
      reason:
          'ObjectBox requires generated model bindings for benchmark entities.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'objectbox_flutter_libs',
      reason:
          'objectbox_flutter_libs ships ObjectBox runtime libraries; object database coverage is represented by objectbox.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'isar',
      reason: 'Isar requires generated collection schema for benchmark models.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'isar_community',
      reason:
          'Isar Community requires generated collection schema for benchmark models.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'isar_db',
      reason:
          'isar_db depends on older build tooling incompatible with this Flutter SDK setup.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'isar_plus',
      reason:
          'isar_plus is an Isar fork that requires generated collection schema.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'realm',
      reason:
          'Realm depends on realm_generator versions incompatible with the current analyzer/build_runner set.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'quanta_db',
      reason:
          'quanta_db depends on older build tooling incompatible with this Flutter SDK setup.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'fdatabase',
      reason:
          'fdatabase is a small synchronous local file package with sparse API documentation; package-level coverage records why a stable CRUD contract is not verified yet.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'relax_orm',
      reason:
          'relax_orm requires generated ORM code; underlying storage is Drift and is measured by the Drift adapter.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'rxdb',
      reason:
          'rxdb pins an obsolete settings-storage dependency, conflicting with the benchmark app dependency set.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'instantdb_flutter',
      reason:
          'instantdb_flutter is an offline-first sync client; a fair benchmark requires a configured Instant backend instead of a local-only synthetic adapter.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'appwrite_offline',
      reason:
          'appwrite_offline is an Appwrite sync adapter; a fair benchmark requires an Appwrite project and sync workload.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'offline_db',
      reason:
          'offline_db delegates local persistence to hive_ce; storage performance is measured by the hive_ce adapter.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'cloud_firestore',
      reason:
          'cloud_firestore is a hosted database SDK; benchmark results would include Firebase project configuration, network, and cache policy rather than only local storage.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'firebase_database',
      reason:
          'firebase_database is a hosted realtime database SDK; benchmark results would include Firebase project configuration, network, and cache policy rather than only local storage.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'serverpod',
      reason:
          'serverpod is an app server framework, not an embedded Flutter database adapter.',
    ),
  ];
}

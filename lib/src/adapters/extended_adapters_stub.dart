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
      name: 'objectbox',
      reason:
          'ObjectBox requires generated model bindings for benchmark entities.',
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
      name: 'rxdb',
      reason:
          'rxdb pins shared_preferences 2.0.17, conflicting with the benchmark app dependency set.',
    ),
  ];
}

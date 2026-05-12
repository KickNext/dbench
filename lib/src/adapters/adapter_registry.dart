import '../benchmark/database_adapter.dart';
import '../platform/package_coverage_adapters.dart';
import 'drift_adapter.dart';
import 'extended_adapters.dart';
import 'get_storage_adapter.dart';
import 'hive_ce_adapter.dart';
import 'localstore_adapter.dart';
import 'memory_adapter.dart';
import 'sembast_adapter.dart';
import 'shared_preferences_adapter.dart';
import 'sqlite_async_adapter.dart';
import 'sqlite3_adapter.dart';
import 'sqlite_adapter.dart';

List<DatabaseAdapter> availableAdapters() {
  return [
    MemoryAdapter(),
    SharedPreferencesAdapter(),
    createGetStorageAdapter(),
    HiveCeAdapter(),
    createLocalstoreAdapter(),
    SembastAdapter(),
    createSqliteAdapter(),
    createSqlite3Adapter(),
    createSqliteAsyncAdapter(),
    createDriftAdapter(),
    ...extendedAdapters(),
    ...platformPackageCoverageAdapters(),
  ];
}

Set<String> adapterCoverageNames() {
  return const {
    'shared_preferences',
    'get_storage',
    'hive_ce',
    'localstore',
    'sembast',
    'sembast_web',
    'sqflite',
    'sqflite_common_ffi',
    'sqlite3',
    'sqlite_async',
    'drift',
    'drift_flutter',
    'drift_sqlite_async',
    'sqflite_sqlcipher',
    'sembast_sqflite',
    'sqlite3_flutter_libs',
    'hive',
    'isar',
    'isar_community',
    'isar_db',
    'isar_plus',
    'objectbox',
    'objectbox_flutter_libs',
    'realm',
    'cbl_flutter',
    'couchbase_lite',
    'floor',
    'sqlbrite',
    'objectdb',
    'tiny_db',
    'store_box',
    'work_db',
    'flutterdb',
    'fdatabase',
    'flutter_local_db',
    'ffastdb',
    'reaxdb_dart',
    'relax_orm',
    'local_shared',
    'quanta_db',
    'torex_local_store',
    'torexstore',
    'entidb_flutter',
    'rxdb',
    'instantdb_flutter',
    'appwrite_offline',
    'offline_db',
    'cloud_firestore',
    'firebase_database',
    'serverpod',
    'localstorage',
    'powersync',
  };
}

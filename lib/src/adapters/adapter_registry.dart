import '../benchmark/database_adapter.dart';
import '../platform/package_coverage_adapters.dart';
import 'drift_adapter.dart';
import 'extended_adapters.dart';
import 'hive_ce_adapter.dart';
import 'localstore_adapter.dart';
import 'memory_adapter.dart';
import 'sembast_adapter.dart';
import 'sqlite_async_adapter.dart';
import 'sqlite3_adapter.dart';
import 'sqlite_adapter.dart';

List<DatabaseAdapter> availableAdapters() {
  return [
    MemoryAdapter(),
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
    'hive_ce',
    'localstore',
    'sembast',
    'sembast_web',
    'sqflite',
    'sqflite_common_ffi',
    'sqlite3',
    'sqlite_async',
    'drift',
    'sqflite_sqlcipher',
    'hive',
    'isar',
    'isar_community',
    'isar_db',
    'isar_plus',
    'objectbox',
    'objectbox_flutter_libs',
    'realm',
    'cbl_flutter',
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
    'quanta_db',
    'torex_local_store',
    'entidb_flutter',
    'rxdb',
    'offline_db',
    'powersync',
  };
}

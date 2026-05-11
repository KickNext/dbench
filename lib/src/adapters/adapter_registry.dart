import '../benchmark/database_adapter.dart';
import '../platform/package_coverage_adapters.dart';
import 'drift_adapter.dart';
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
    GetStorageAdapter(),
    HiveCeAdapter(),
    LocalstoreAdapter(),
    SembastAdapter(),
    createSqliteAdapter(),
    createSqlite3Adapter(),
    createSqliteAsyncAdapter(),
    createDriftAdapter(),
    ...platformPackageCoverageAdapters(),
    const UnsupportedDatabaseAdapter(
      name: 'isar_community',
      reason:
          'Tracked package; generated model adapter is not implemented yet.',
    ),
    const UnsupportedDatabaseAdapter(
      name: 'isar_db',
      reason: 'Tracked package; compatibility adapter is not implemented yet.',
    ),
    const UnsupportedDatabaseAdapter(
      name: 'isar',
      reason:
          'Tracked historical package; adapter is not implemented in this suite.',
    ),
    const UnsupportedDatabaseAdapter(
      name: 'objectbox',
      reason:
          'Tracked package; generated model and native binding adapter is not implemented yet.',
    ),
    const UnsupportedDatabaseAdapter(
      name: 'realm',
      reason:
          'Tracked package; generated object model adapter is not implemented yet.',
    ),
    const UnsupportedDatabaseAdapter(
      name: 'floor',
      reason: 'Tracked package; generated DAO adapter is not implemented yet.',
    ),
    const UnsupportedDatabaseAdapter(
      name: 'hive',
      reason:
          'Tracked historical package; Hive CE is the runnable Hive-family adapter.',
    ),
    const UnsupportedDatabaseAdapter(
      name: 'sembast_sqflite',
      reason:
          'Tracked package; sqflite-backed Sembast adapter is not implemented yet.',
    ),
  ];
}

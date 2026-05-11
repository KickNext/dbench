import '../benchmark/database_adapter.dart';
import 'get_storage_adapter.dart';
import 'hive_ce_adapter.dart';
import 'memory_adapter.dart';
import 'sembast_adapter.dart';
import 'shared_preferences_adapter.dart';
import 'sqlite_adapter.dart';

List<DatabaseAdapter> availableAdapters() {
  return [
    MemoryAdapter(),
    SharedPreferencesAdapter(),
    GetStorageAdapter(),
    HiveCeAdapter(),
    SembastAdapter(),
    createSqliteAdapter(),
  ];
}

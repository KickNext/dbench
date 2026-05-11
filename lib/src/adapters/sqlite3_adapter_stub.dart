import '../benchmark/database_adapter.dart';

DatabaseAdapter createSqlite3Adapter() {
  return const UnsupportedDatabaseAdapter(
    name: 'sqlite3',
    reason: 'sqlite3 direct adapter is not available on this target.',
  );
}

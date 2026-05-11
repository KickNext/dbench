import '../benchmark/database_adapter.dart';

DatabaseAdapter createSqliteAdapter() {
  return const UnsupportedDatabaseAdapter(
    name: 'sqflite_sqlite',
    reason: 'SQLite adapter is not available on this target.',
  );
}

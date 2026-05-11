import '../benchmark/database_adapter.dart';

DatabaseAdapter createSqliteAdapter() {
  return const UnsupportedDatabaseAdapter(
    name: 'sqflite',
    reason: 'SQLite adapter is not available on this target.',
  );
}

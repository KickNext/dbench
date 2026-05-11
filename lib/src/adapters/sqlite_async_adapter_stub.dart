import '../benchmark/database_adapter.dart';

DatabaseAdapter createSqliteAsyncAdapter() {
  return const UnsupportedDatabaseAdapter(
    name: 'sqlite_async',
    reason:
        'sqlite_async Web support requires sqlite3.wasm and worker assets; native CI adapter is measured separately.',
  );
}

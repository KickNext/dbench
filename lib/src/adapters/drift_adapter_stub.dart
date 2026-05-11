import '../benchmark/database_adapter.dart';

DatabaseAdapter createDriftAdapter() {
  return const UnsupportedDatabaseAdapter(
    name: 'drift',
    reason:
        'Drift Web support requires sqlite3 WASM/worker assets; native CI adapter is measured separately.',
  );
}

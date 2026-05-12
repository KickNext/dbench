import '../benchmark/database_adapter.dart';

DatabaseAdapter createDriftAdapter() {
  return const UnsupportedDatabaseAdapter(
    name: 'drift',
    reason:
        'Drift Web support requires sqlite3 Wasm/worker assets; native adapter is measured separately.',
  );
}

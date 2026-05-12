import '../benchmark/database_adapter.dart';

DatabaseAdapter createGetStorageAdapter() => const UnsupportedDatabaseAdapter(
  name: 'get_storage',
  reason:
      'get_storage imports dart:html on Web; Flutter Wasm cannot compile dart:html packages, so the adapter is skipped for Wasm builds.',
);

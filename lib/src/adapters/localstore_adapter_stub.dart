import '../benchmark/database_adapter.dart';

DatabaseAdapter createLocalstoreAdapter() => const UnsupportedDatabaseAdapter(
  name: 'localstore',
  reason:
      'localstore imports dart:html on Web; Flutter Wasm cannot compile dart:html packages, so the adapter is skipped for Wasm builds.',
);

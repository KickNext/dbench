import '../benchmark/database_adapter.dart';

List<DatabaseAdapter> platformPackageCoverageAdapters() {
  return const [
    UnsupportedDatabaseAdapter(
      name: 'sqflite_common_ffi',
      reason: 'sqflite_common_ffi is a native desktop/test backend, not Web.',
    ),
    UnsupportedDatabaseAdapter(
      name: 'sembast',
      reason:
          'File-backed Sembast is not used on Web; sembast_web is measured.',
    ),
  ];
}

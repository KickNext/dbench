import 'dart:io';

import '../benchmark/database_adapter.dart';

List<DatabaseAdapter> platformPackageCoverageAdapters() {
  return [
    if (Platform.isWindows || Platform.isLinux)
      const UnsupportedDatabaseAdapter(
        name: 'sqflite',
        reason:
            'sqflite targets Android, iOS, and macOS; desktop runs measure sqflite_common_ffi.',
      ),
    const UnsupportedDatabaseAdapter(
      name: 'sembast_web',
      reason:
          'sembast_web is Web-only; native runs measure file-backed sembast.',
    ),
  ];
}

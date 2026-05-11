import 'dart:isolate';
import 'dart:io';

import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as p;
import 'package:sembast/sembast_io.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../platform/storage_directory.dart';

final class IsolateProbeResult {
  const IsolateProbeResult({
    required this.database,
    required this.status,
    required this.sharedRead,
    required this.notes,
  });

  final String database;
  final String status;
  final bool? sharedRead;
  final String notes;

  Map<String, Object?> toJson() {
    return {
      'database': database,
      'status': status,
      'sharedRead': sharedRead,
      'notes': notes,
    };
  }
}

Future<List<IsolateProbeResult>> runIsolateProbes() async {
  final basePath = await benchmarkStoragePath();
  return [
    const IsolateProbeResult(
      database: 'memory_baseline',
      status: 'completed',
      sharedRead: false,
      notes:
          'Dart isolates have separate heaps; in-memory maps are not shared.',
    ),
    await _hiveProbe(basePath),
    await _sembastProbe(basePath),
    if (Platform.isWindows || Platform.isLinux)
      await _sqfliteFfiProbe(basePath),
    if (Platform.isWindows || Platform.isLinux)
      const IsolateProbeResult(
        database: 'sqlite3',
        status: 'skipped',
        sharedRead: null,
        notes:
            'Runnable adapter exists, but direct sqlite3 isolate reopening is not probed yet.',
      ),
    const IsolateProbeResult(
      database: 'shared_preferences',
      status: 'skipped',
      sharedRead: null,
      notes: 'Plugin-backed storage is not probed from a background isolate.',
    ),
    const IsolateProbeResult(
      database: 'get_storage',
      status: 'skipped',
      sharedRead: null,
      notes:
          'Flutter/widget-bound package; isolate sharing needs a dedicated adapter.',
    ),
    const IsolateProbeResult(
      database: 'localstore',
      status: 'skipped',
      sharedRead: null,
      notes:
          'Runnable adapter exists, but file-backed isolate sharing is not probed yet.',
    ),
    if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)
      const IsolateProbeResult(
        database: 'sqflite',
        status: 'skipped',
        sharedRead: null,
        notes:
            'Not yet probed; sqflite method-channel access needs a background-isolate-specific adapter.',
      ),
  ];
}

Future<IsolateProbeResult> _hiveProbe(String? basePath) async {
  try {
    Hive.init(basePath);
    final box = await Hive.openBox<Map>('dbench_isolate_hive_ce');
    await box.clear();
    await box.put(1, {'payload': 'from-main-isolate'});
    await box.close();

    final sharedRead = await Isolate.run(() async {
      Hive.init(basePath);
      final isolateBox = await Hive.openBox<Map>('dbench_isolate_hive_ce');
      final value = isolateBox.get(1);
      await isolateBox.close();
      return value?['payload'] == 'from-main-isolate';
    });

    return IsolateProbeResult(
      database: 'hive_ce',
      status: 'completed',
      sharedRead: sharedRead,
      notes:
          'Separate isolate reopened the same box path and read the main isolate record.',
    );
  } catch (error) {
    return IsolateProbeResult(
      database: 'hive_ce',
      status: 'failed',
      sharedRead: false,
      notes: '$error',
    );
  }
}

Future<IsolateProbeResult> _sqfliteFfiProbe(String? basePath) async {
  try {
    sqfliteFfiInit();
    final databasePath = p.join(basePath!, 'dbench_isolate_sqflite_ffi.db');
    final database = await databaseFactoryFfi.openDatabase(databasePath);
    await database.execute(
      'CREATE TABLE IF NOT EXISTS records(id INTEGER PRIMARY KEY, payload TEXT NOT NULL)',
    );
    await database.delete('records');
    await database.insert('records', {'id': 1, 'payload': 'from-main-isolate'});
    await database.close();

    final sharedRead = await Isolate.run(() async {
      sqfliteFfiInit();
      final isolateDatabase = await databaseFactoryFfi.openDatabase(
        databasePath,
      );
      final rows = await isolateDatabase.query(
        'records',
        where: 'id = ?',
        whereArgs: [1],
        limit: 1,
      );
      await isolateDatabase.close();
      return rows.isNotEmpty && rows.single['payload'] == 'from-main-isolate';
    });

    return IsolateProbeResult(
      database: 'sqflite_common_ffi',
      status: 'completed',
      sharedRead: sharedRead,
      notes:
          'Separate isolate reopened the same SQLite file through sqflite_common_ffi and read the main isolate record.',
    );
  } catch (error) {
    return IsolateProbeResult(
      database: 'sqflite_common_ffi',
      status: 'failed',
      sharedRead: false,
      notes: '$error',
    );
  }
}

Future<IsolateProbeResult> _sembastProbe(String? basePath) async {
  try {
    final databasePath = p.join(basePath!, 'dbench_isolate_sembast.db');
    final store = intMapStoreFactory.store('records');
    final database = await databaseFactoryIo.openDatabase(databasePath);
    await store.delete(database);
    await store.record(1).put(database, {'payload': 'from-main-isolate'});
    await database.close();

    final sharedRead = await Isolate.run(() async {
      final isolateDatabase = await databaseFactoryIo.openDatabase(
        databasePath,
      );
      final value = await store.record(1).get(isolateDatabase);
      await isolateDatabase.close();
      return value?['payload'] == 'from-main-isolate';
    });

    return IsolateProbeResult(
      database: 'sembast',
      status: 'completed',
      sharedRead: sharedRead,
      notes:
          'Separate isolate reopened the same database file and read the main isolate record.',
    );
  } catch (error) {
    return IsolateProbeResult(
      database: 'sembast',
      status: 'failed',
      sharedRead: false,
      notes: '$error',
    );
  }
}

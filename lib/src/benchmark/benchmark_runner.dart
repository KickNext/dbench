import 'dart:convert';

import 'database_adapter.dart';
import 'isolate_probe.dart';

final class BenchmarkRunner {
  const BenchmarkRunner({
    required this.workload,
    this.includeIsolateProbes = false,
  });

  final BenchmarkWorkload workload;
  final bool includeIsolateProbes;

  Future<BenchmarkReport> runAll(
    List<DatabaseAdapter> adapters, {
    required String environment,
  }) async {
    final results = <BenchmarkResult>[];
    for (final adapter in adapters) {
      results.add(await _runOne(adapter));
    }
    return BenchmarkReport(
      environment: environment,
      generatedAt: DateTime.timestamp().toUtc(),
      workload: workload,
      results: results,
      isolateProbes: includeIsolateProbes ? await runIsolateProbes() : const [],
    );
  }

  Future<BenchmarkResult> _runOne(DatabaseAdapter adapter) async {
    if (!await adapter.isSupported) {
      final reason = adapter is UnsupportedDatabaseAdapter
          ? adapter.reason
          : 'Adapter is not supported on this target.';
      return BenchmarkResult.skipped(adapter.name, reason);
    }

    final stopwatch = Stopwatch()..start();
    var writeOps = 0;
    var readOps = 0;
    var updateOps = 0;
    var deleteOps = 0;

    try {
      await adapter.open();
      await adapter.clear();

      for (var i = 0; i < workload.records; i++) {
        await adapter.write(_record(i));
        writeOps++;
      }

      for (var i = 0; i < workload.records; i++) {
        final record = await adapter.read(i);
        if (record == null || record.id != i) {
          throw StateError('Read verification failed for record $i.');
        }
        readOps++;
      }

      for (var i = 0; i < workload.records; i++) {
        await adapter.update(_record(i).updated());
        updateOps++;
      }

      for (var i = 0; i < workload.records; i++) {
        final record = await adapter.read(i);
        if (record == null || record.value != i * 7 + 1) {
          throw StateError('Update verification failed for record $i.');
        }
      }

      for (var i = 0; i < workload.records; i++) {
        await adapter.delete(i);
        deleteOps++;
      }

      for (var i = 0; i < workload.records; i++) {
        final record = await adapter.read(i);
        if (record != null) {
          throw StateError('Delete verification failed for record $i.');
        }
      }

      stopwatch.stop();
      return BenchmarkResult(
        database: adapter.name,
        status: BenchmarkStatus.completed,
        elapsedMicros: stopwatch.elapsedMicroseconds,
        writeOps: writeOps,
        readOps: readOps,
        updateOps: updateOps,
        deleteOps: deleteOps,
      );
    } catch (error, stackTrace) {
      stopwatch.stop();
      return BenchmarkResult(
        database: adapter.name,
        status: BenchmarkStatus.failed,
        elapsedMicros: stopwatch.elapsedMicroseconds,
        writeOps: writeOps,
        readOps: readOps,
        updateOps: updateOps,
        deleteOps: deleteOps,
        notes:
            '$error\n${stackTrace.toString().split('\n').take(4).join('\n')}',
      );
    } finally {
      await adapter.close();
    }
  }

  BenchmarkRecord _record(int id) {
    final seed = 'record-$id'.padRight(workload.payloadBytes, 'x');
    return BenchmarkRecord(
      id: id,
      title: 'Record $id',
      group: 'group-${id % 10}',
      value: id * 7,
      payload: seed,
      updatedAtMicros: 1800000000000000 + id,
    );
  }
}

final class BenchmarkReport {
  const BenchmarkReport({
    required this.environment,
    required this.generatedAt,
    required this.workload,
    required this.results,
    this.isolateProbes = const [],
  });

  final String environment;
  final DateTime generatedAt;
  final BenchmarkWorkload workload;
  final List<BenchmarkResult> results;
  final List<IsolateProbeResult> isolateProbes;

  Map<String, Object?> toJson() {
    return {
      'environment': environment,
      'generatedAt': generatedAt.toIso8601String(),
      'workload': {
        'records': workload.records,
        'payloadBytes': workload.payloadBytes,
      },
      'results': [for (final result in results) result.toJson()],
      'isolateProbes': [for (final probe in isolateProbes) probe.toJson()],
    };
  }

  String toPrettyJson() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  String toCompactJson() {
    return jsonEncode(toJson());
  }
}

final class BenchmarkResult {
  const BenchmarkResult({
    required this.database,
    required this.status,
    required this.elapsedMicros,
    required this.writeOps,
    required this.readOps,
    required this.updateOps,
    required this.deleteOps,
    this.notes = '',
  });

  factory BenchmarkResult.skipped(String database, String reason) {
    return BenchmarkResult(
      database: database,
      status: BenchmarkStatus.skipped,
      elapsedMicros: 0,
      writeOps: 0,
      readOps: 0,
      updateOps: 0,
      deleteOps: 0,
      notes: reason,
    );
  }

  final String database;
  final BenchmarkStatus status;
  final int elapsedMicros;
  final int writeOps;
  final int readOps;
  final int updateOps;
  final int deleteOps;
  final String notes;

  int get totalOps => writeOps + readOps + updateOps + deleteOps;

  double get opsPerSecond {
    if (elapsedMicros <= 0 || totalOps == 0) {
      return 0;
    }
    return totalOps * 1000000 / elapsedMicros;
  }

  Map<String, Object?> toJson() {
    return {
      'database': database,
      'status': status.name,
      'elapsedMicros': elapsedMicros,
      'writeOps': writeOps,
      'readOps': readOps,
      'updateOps': updateOps,
      'deleteOps': deleteOps,
      'totalOps': totalOps,
      'opsPerSecond': opsPerSecond,
      'notes': notes,
    };
  }
}

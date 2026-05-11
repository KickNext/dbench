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
    for (final scenario in workload.effectiveScenarios) {
      for (final adapter in adapters) {
        results.add(await _runOne(adapter, scenario));
      }
    }
    return BenchmarkReport(
      environment: environment,
      generatedAt: DateTime.timestamp().toUtc(),
      workload: workload,
      results: results,
      isolateProbes: includeIsolateProbes ? await runIsolateProbes() : const [],
    );
  }

  Future<BenchmarkResult> _runOne(
    DatabaseAdapter adapter,
    BenchmarkScenario scenario,
  ) async {
    if (!await adapter.isSupported) {
      final reason = adapter is UnsupportedDatabaseAdapter
          ? adapter.reason
          : 'Adapter is not supported on this target.';
      return BenchmarkResult.skipped(adapter.name, scenario, reason);
    }
    if (scenario.requiresWriteTransaction &&
        adapter is! TransactionalDatabaseAdapter) {
      return BenchmarkResult.skipped(
        adapter.name,
        scenario,
        'Scenario requires adapter-native write transactions.',
      );
    }

    final samples = <_BenchmarkSample>[];
    try {
      for (
        var sample = 0;
        sample < _scenarioSampleRuns(scenario);
        sample += 1
      ) {
        samples.add(await _runSample(adapter, scenario));
      }
      final median = _medianSample(samples);
      return BenchmarkResult(
        database: adapter.name,
        scenario: scenario.name,
        scenarioDescription: scenario.description,
        records: scenario.records,
        payloadBytes: scenario.payloadBytes,
        status: BenchmarkStatus.completed,
        elapsedMicros: median.elapsedMicros,
        sampleRuns: samples.length,
        sampleElapsedMicros: [
          for (final sample in samples) sample.elapsedMicros,
        ],
        minElapsedMicros: samples
            .map((sample) => sample.elapsedMicros)
            .reduce((a, b) => a < b ? a : b),
        maxElapsedMicros: samples
            .map((sample) => sample.elapsedMicros)
            .reduce((a, b) => a > b ? a : b),
        writeOps: median.writeOps,
        readOps: median.readOps,
        queryOps: median.queryOps,
        queryRows: median.queryRows,
        updateOps: median.updateOps,
        deleteOps: median.deleteOps,
        verificationOps: median.verificationOps,
      );
    } catch (error, stackTrace) {
      final elapsedMicros = samples.isEmpty ? 0 : samples.last.elapsedMicros;
      return BenchmarkResult(
        database: adapter.name,
        scenario: scenario.name,
        scenarioDescription: scenario.description,
        records: scenario.records,
        payloadBytes: scenario.payloadBytes,
        status: BenchmarkStatus.failed,
        elapsedMicros: elapsedMicros,
        sampleRuns: samples.length,
        sampleElapsedMicros: [
          for (final sample in samples) sample.elapsedMicros,
        ],
        writeOps: 0,
        readOps: 0,
        queryOps: 0,
        queryRows: 0,
        updateOps: 0,
        deleteOps: 0,
        verificationOps: 0,
        notes:
            '$error\n${stackTrace.toString().split('\n').take(4).join('\n')}',
      );
    }
  }

  Future<_BenchmarkSample> _runSample(
    DatabaseAdapter adapter,
    BenchmarkScenario scenario,
  ) async {
    final stopwatch = Stopwatch()..start();
    var writeOps = 0;
    var readOps = 0;
    var queryOps = 0;
    var queryRows = 0;
    var updateOps = 0;
    var deleteOps = 0;
    var verificationOps = 0;
    var adapterClosed = false;

    try {
      await adapter.open();
      await adapter.clear();

      await _runWriteBlock(adapter, scenario, () async {
        for (var i = 0; i < scenario.records; i++) {
          await adapter.write(_record(i, scenario));
          writeOps++;
        }
      });

      for (var round = 0; round < scenario.pointReadRounds; round++) {
        for (var i = 0; i < scenario.records; i++) {
          final record = await adapter.read(i);
          if (record == null || record.id != i) {
            throw StateError('Read verification failed for record $i.');
          }
          readOps++;
        }
      }

      for (var round = 0; round < scenario.groupQueryRounds; round++) {
        for (var groupIndex = 0; groupIndex < 10; groupIndex++) {
          final group = 'group-$groupIndex';
          final records = await adapter.readByGroup(group);
          queryOps++;
          final expected = _expectedGroupCount(scenario.records, groupIndex);
          if (records.length != expected ||
              records.any((record) => record.group != group)) {
            throw StateError(
              'Group query verification failed for $group: '
              'expected $expected, got ${records.length}.',
            );
          }
          queryRows += records.length;
        }
      }

      await _runWriteBlock(adapter, scenario, () async {
        for (var round = 0; round < scenario.updateRounds; round++) {
          for (var i = 0; i < scenario.records; i++) {
            final current = await adapter.read(i);
            if (current == null) {
              throw StateError('Update source record $i was not found.');
            }
            verificationOps++;
            await adapter.update(current.updated());
            updateOps++;
          }
        }
      });

      for (var i = 0; i < scenario.records; i++) {
        final record = await adapter.read(i);
        verificationOps++;
        if (record == null || record.value != i * 7 + scenario.updateRounds) {
          throw StateError('Update verification failed for record $i.');
        }
      }

      await _runWriteBlock(adapter, scenario, () async {
        for (var i = 0; i < scenario.records; i++) {
          await adapter.delete(i);
          deleteOps++;
        }
      });

      for (var i = 0; i < scenario.records; i++) {
        final record = await adapter.read(i);
        verificationOps++;
        if (record != null) {
          throw StateError('Delete verification failed for record $i.');
        }
      }

      await adapter.close();
      adapterClosed = true;
      stopwatch.stop();
      final elapsedMicros = stopwatch.elapsedMicroseconds;
      return _BenchmarkSample(
        elapsedMicros: elapsedMicros < 1 ? 1 : elapsedMicros,
        writeOps: writeOps,
        readOps: readOps,
        queryOps: queryOps,
        queryRows: queryRows,
        updateOps: updateOps,
        deleteOps: deleteOps,
        verificationOps: verificationOps,
      );
    } finally {
      if (!adapterClosed) {
        await adapter.close();
      }
    }
  }

  _BenchmarkSample _medianSample(List<_BenchmarkSample> samples) {
    final sorted = [...samples]
      ..sort((a, b) => a.elapsedMicros.compareTo(b.elapsedMicros));
    return sorted[sorted.length ~/ 2];
  }

  Future<T> _runWriteBlock<T>(
    DatabaseAdapter adapter,
    BenchmarkScenario scenario,
    Future<T> Function() action,
  ) {
    if (!scenario.requiresWriteTransaction) {
      return action();
    }
    return (adapter as TransactionalDatabaseAdapter).runWriteTransaction(
      action,
    );
  }

  int _scenarioSampleRuns(BenchmarkScenario scenario) {
    if (scenario.sampleRuns < 1) {
      return 1;
    }
    return scenario.sampleRuns;
  }

  BenchmarkRecord _record(int id, BenchmarkScenario scenario) {
    final seed = 'record-$id'.padRight(scenario.payloadBytes, 'x');
    return BenchmarkRecord(
      id: id,
      title: 'Record $id',
      group: 'group-${id % 10}',
      value: id * 7,
      payload: seed,
      updatedAtMicros: 1800000000000000 + id,
    );
  }

  int _expectedGroupCount(int records, int groupIndex) {
    if (records <= groupIndex) {
      return 0;
    }
    return ((records - 1 - groupIndex) ~/ 10) + 1;
  }
}

final class _BenchmarkSample {
  const _BenchmarkSample({
    required this.elapsedMicros,
    required this.writeOps,
    required this.readOps,
    required this.queryOps,
    required this.queryRows,
    required this.updateOps,
    required this.deleteOps,
    required this.verificationOps,
  });

  final int elapsedMicros;
  final int writeOps;
  final int readOps;
  final int queryOps;
  final int queryRows;
  final int updateOps;
  final int deleteOps;
  final int verificationOps;
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
        'scenarios': [
          for (final scenario in workload.effectiveScenarios) scenario.toJson(),
        ],
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
    required this.scenario,
    required this.scenarioDescription,
    required this.records,
    required this.payloadBytes,
    required this.status,
    required this.elapsedMicros,
    this.sampleRuns = 1,
    this.sampleElapsedMicros = const [],
    this.minElapsedMicros,
    this.maxElapsedMicros,
    required this.writeOps,
    required this.readOps,
    required this.queryOps,
    required this.queryRows,
    required this.updateOps,
    required this.deleteOps,
    required this.verificationOps,
    this.notes = '',
  });

  factory BenchmarkResult.skipped(
    String database,
    BenchmarkScenario scenario,
    String reason,
  ) {
    return BenchmarkResult(
      database: database,
      scenario: scenario.name,
      scenarioDescription: scenario.description,
      records: scenario.records,
      payloadBytes: scenario.payloadBytes,
      status: BenchmarkStatus.skipped,
      elapsedMicros: 0,
      sampleRuns: 0,
      sampleElapsedMicros: const [],
      minElapsedMicros: 0,
      maxElapsedMicros: 0,
      writeOps: 0,
      readOps: 0,
      queryOps: 0,
      queryRows: 0,
      updateOps: 0,
      deleteOps: 0,
      verificationOps: 0,
      notes: reason,
    );
  }

  final String database;
  final String scenario;
  final String scenarioDescription;
  final int records;
  final int payloadBytes;
  final BenchmarkStatus status;
  final int elapsedMicros;
  final int sampleRuns;
  final List<int> sampleElapsedMicros;
  final int? minElapsedMicros;
  final int? maxElapsedMicros;
  final int writeOps;
  final int readOps;
  final int queryOps;
  final int queryRows;
  final int updateOps;
  final int deleteOps;
  final int verificationOps;
  final String notes;

  int get totalOps =>
      writeOps + readOps + queryOps + updateOps + deleteOps + verificationOps;

  double get opsPerSecond {
    if (elapsedMicros <= 0 || totalOps == 0) {
      return 0;
    }
    return totalOps * 1000000 / elapsedMicros;
  }

  Map<String, Object?> toJson() {
    return {
      'database': database,
      'scenario': scenario,
      'scenarioDescription': scenarioDescription,
      'records': records,
      'payloadBytes': payloadBytes,
      'status': status.name,
      'elapsedMicros': elapsedMicros,
      'sampleRuns': sampleRuns,
      'sampleElapsedMicros': sampleElapsedMicros,
      'minElapsedMicros': minElapsedMicros ?? elapsedMicros,
      'maxElapsedMicros': maxElapsedMicros ?? elapsedMicros,
      'writeOps': writeOps,
      'readOps': readOps,
      'queryOps': queryOps,
      'queryRows': queryRows,
      'updateOps': updateOps,
      'deleteOps': deleteOps,
      'verificationOps': verificationOps,
      'totalOps': totalOps,
      'opsPerSecond': opsPerSecond,
      'notes': notes,
    };
  }
}

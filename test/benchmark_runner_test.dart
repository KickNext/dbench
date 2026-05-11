import 'package:dbench/src/benchmark/benchmark_runner.dart';
import 'package:dbench/src/benchmark/database_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'runner records operation counts and rates for a supported adapter',
    () async {
      final adapter = _FakeAdapter('fake');
      final runner = BenchmarkRunner(
        workload: const BenchmarkWorkload(
          scenarios: [
            BenchmarkScenario(
              name: 'test_crud',
              description: 'test',
              records: 4,
              payloadBytes: 16,
              groupQueryRounds: 1,
            ),
          ],
        ),
      );

      final report = await runner.runAll([adapter], environment: 'test');

      expect(report.environment, 'test');
      expect(report.results, hasLength(1));
      final result = report.results.single;
      expect(result.database, 'fake');
      expect(result.scenario, 'test_crud');
      expect(result.status, BenchmarkStatus.completed);
      expect(result.writeOps, 4);
      expect(result.readOps, 4);
      expect(result.queryOps, 10);
      expect(result.queryRows, 4);
      expect(result.updateOps, 4);
      expect(result.deleteOps, 4);
      expect(result.verificationOps, 12);
      expect(result.totalOps, 38);
      expect(result.opsPerSecond, greaterThan(0));
    },
  );

  test('runner reports unsupported adapters as skipped results', () async {
    final runner = BenchmarkRunner(
      workload: const BenchmarkWorkload(
        scenarios: [
          BenchmarkScenario(
            name: 'test_crud',
            description: 'test',
            records: 2,
            payloadBytes: 16,
          ),
        ],
      ),
    );

    final report = await runner.runAll([
      const UnsupportedDatabaseAdapter(
        name: 'native-only',
        reason: 'not available here',
      ),
    ], environment: 'web');

    expect(report.results.single.status, BenchmarkStatus.skipped);
    expect(report.results.single.notes, contains('not available here'));
    expect(report.results.single.totalOps, 0);
  });

  test('runner fails adapters that do not persist updates', () async {
    final runner = BenchmarkRunner(
      workload: const BenchmarkWorkload(
        scenarios: [
          BenchmarkScenario(
            name: 'test_crud',
            description: 'test',
            records: 2,
            payloadBytes: 16,
          ),
        ],
      ),
    );

    final report = await runner.runAll([
      _BadUpdateAdapter(),
    ], environment: 'test');

    expect(report.results.single.status, BenchmarkStatus.failed);
    expect(report.results.single.notes, contains('Update verification failed'));
  });

  test('runner fails adapters that do not delete records', () async {
    final runner = BenchmarkRunner(
      workload: const BenchmarkWorkload(
        scenarios: [
          BenchmarkScenario(
            name: 'test_crud',
            description: 'test',
            records: 2,
            payloadBytes: 16,
          ),
        ],
      ),
    );

    final report = await runner.runAll([
      _BadDeleteAdapter(),
    ], environment: 'test');

    expect(report.results.single.status, BenchmarkStatus.failed);
    expect(report.results.single.notes, contains('Delete verification failed'));
  });

  test(
    'runner includes successful adapter close and flush in elapsed time',
    () async {
      final adapter = _CloseRecordingAdapter();
      final runner = BenchmarkRunner(
        workload: const BenchmarkWorkload(
          scenarios: [
            BenchmarkScenario(
              name: 'test_crud',
              description: 'test',
              records: 1,
              payloadBytes: 16,
            ),
          ],
        ),
      );

      final report = await runner.runAll([adapter], environment: 'test');

      expect(adapter.closeCount, 1);
      expect(report.results.single.status, BenchmarkStatus.completed);
      expect(report.results.single.elapsedMicros, greaterThanOrEqualTo(4000));
    },
  );
}

final class _FakeAdapter implements DatabaseAdapter {
  _FakeAdapter(this.name);

  final Map<int, BenchmarkRecord> _records = {};

  @override
  final String name;

  @override
  Future<bool> get isSupported async => true;

  @override
  Future<void> open() async {}

  @override
  Future<void> clear() async {
    _records.clear();
  }

  @override
  Future<void> write(BenchmarkRecord record) async {
    _records[record.id] = record;
  }

  @override
  Future<BenchmarkRecord?> read(int id) async => _records[id];

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async {
    return _records.values.where((record) => record.group == group).toList();
  }

  @override
  Future<void> update(BenchmarkRecord record) async {
    _records[record.id] = record;
  }

  @override
  Future<void> delete(int id) async {
    _records.remove(id);
  }

  @override
  Future<void> close() async {}
}

final class _BadUpdateAdapter extends _FakeAdapter {
  _BadUpdateAdapter() : super('bad_update');

  @override
  Future<void> update(BenchmarkRecord record) async {}
}

final class _BadDeleteAdapter extends _FakeAdapter {
  _BadDeleteAdapter() : super('bad_delete');

  @override
  Future<void> delete(int id) async {}
}

final class _CloseRecordingAdapter extends _FakeAdapter {
  _CloseRecordingAdapter() : super('close_recording');

  var closeCount = 0;

  @override
  Future<void> close() async {
    closeCount += 1;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

import 'package:dbench/src/benchmark/benchmark_runner.dart';
import 'package:dbench/src/benchmark/database_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'runner records operation counts and rates for a supported adapter',
    () async {
      final adapter = _FakeAdapter('fake');
      final runner = BenchmarkRunner(
        workload: const BenchmarkWorkload(records: 4),
      );

      final report = await runner.runAll([adapter], environment: 'test');

      expect(report.environment, 'test');
      expect(report.results, hasLength(1));
      final result = report.results.single;
      expect(result.database, 'fake');
      expect(result.status, BenchmarkStatus.completed);
      expect(result.writeOps, 4);
      expect(result.readOps, 4);
      expect(result.updateOps, 4);
      expect(result.deleteOps, 4);
      expect(result.totalOps, 16);
      expect(result.opsPerSecond, greaterThan(0));
    },
  );

  test('runner reports unsupported adapters as skipped results', () async {
    final runner = BenchmarkRunner(
      workload: const BenchmarkWorkload(records: 2),
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

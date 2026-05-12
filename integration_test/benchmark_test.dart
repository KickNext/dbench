import 'package:flutter_database_benchmarks/src/adapters/adapter_registry.dart';
import 'package:flutter_database_benchmarks/src/benchmark/benchmark_runner.dart';
import 'package:flutter_database_benchmarks/src/benchmark/database_adapter.dart';
import 'package:flutter_database_benchmarks/src/platform/environment_label.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('runs database benchmarks', (tester) async {
    final records =
        int.tryParse(
          const String.fromEnvironment('DBENCH_RECORDS', defaultValue: '500'),
        ) ??
        500;
    final payloadBytes =
        int.tryParse(
          const String.fromEnvironment(
            'DBENCH_PAYLOAD_BYTES',
            defaultValue: '256',
          ),
        ) ??
        256;

    final adapterFilter = const String.fromEnvironment('DBENCH_ADAPTERS')
        .split(',')
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet();
    final adapters = adapterFilter.isEmpty
        ? availableAdapters()
        : availableAdapters()
              .where((adapter) => adapterFilter.contains(adapter.name))
              .toList();

    final report = await BenchmarkRunner(
      workload: BenchmarkWorkload(records: records, payloadBytes: payloadBytes),
      includeIsolateProbes: true,
    ).runAll(adapters, environment: environmentLabel());

    // CI and local scripts scrape this single-line marker.
    // ignore: avoid_print
    print('DBENCH_RESULT_JSON=${report.toCompactJson()}');

    expect(report.results, isNotEmpty);
    expect(
      report.results.where(
        (result) => result.status == BenchmarkStatus.completed,
      ),
      isNotEmpty,
    );
    expect(
      report.results.where((result) => result.status == BenchmarkStatus.failed),
      isEmpty,
    );
    expect(
      report.results.where(
        (result) =>
            result.database != 'memory_baseline' &&
            result.status == BenchmarkStatus.completed,
      ),
      isNotEmpty,
    );
  });
}

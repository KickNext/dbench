import 'dart:io';

import 'package:flutter_database_benchmarks/src/adapters/adapter_registry.dart';
import 'package:flutter_database_benchmarks/src/benchmark/benchmark_runner.dart';
import 'package:flutter_database_benchmarks/src/benchmark/database_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    PathProviderPlatform.instance = _FakePathProviderPlatform(
      Directory.systemTemp.createTempSync('dbench_adapter_smoke_').path,
    );
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'supported adapters satisfy the benchmark CRUD contract',
    () async {
      final scenario = BenchmarkScenario(
        name: 'adapter_smoke',
        description: 'Small adapter contract smoke test.',
        records: 3,
        payloadBytes: 16,
        pointReadRounds: 1,
        groupQueryRounds: 1,
        updateRounds: 1,
        sampleRuns: 1,
      );
      final runner = BenchmarkRunner(
        workload: BenchmarkWorkload(scenarios: [scenario]),
      );
      final failures = <String>[];

      for (final adapter in availableAdapters()) {
        if (adapter is UnsupportedDatabaseAdapter ||
            !await adapter.isSupported) {
          continue;
        }
        final report = await runner.runAll([adapter], environment: 'test');
        final result = report.results.single;
        if (result.status != BenchmarkStatus.completed) {
          failures.add('${adapter.name}: ${result.notes}');
        }
      }

      expect(failures, isEmpty);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

final class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.path);

  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;

  @override
  Future<String?> getTemporaryPath() async => path;
}

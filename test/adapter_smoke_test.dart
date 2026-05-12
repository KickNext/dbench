import 'dart:io';

import 'package:flutter_database_benchmarks/src/adapters/adapter_registry.dart';
import 'package:flutter_database_benchmarks/src/benchmark/benchmark_runner.dart';
import 'package:flutter_database_benchmarks/src/benchmark/database_adapter.dart';
import 'package:flutter/services.dart';
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
    _installFlutterSecureStorageMock();
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

  test(
    'generated object-store adapters are runnable database adapters',
    () async {
      final adaptersByName = {
        for (final adapter in availableAdapters()) adapter.name: adapter,
      };
      final scenario = BenchmarkScenario(
        name: 'generated_object_store_smoke',
        description: 'Small generated object-store adapter smoke test.',
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

      for (final name in [
        'isar',
        'isar_community',
        'isar_db',
        'isar_plus',
        'objectbox',
      ]) {
        final adapter = adaptersByName[name];
        expect(adapter, isNotNull, reason: '$name must be registered.');
        expect(
          adapter,
          isNot(isA<UnsupportedDatabaseAdapter>()),
          reason: '$name must have a real generated adapter.',
        );
        expect(await adapter!.isSupported, isTrue);

        final report = await runner.runAll([adapter], environment: 'test');
        expect(report.results, hasLength(1));
        expect(
          report.results.single.status,
          BenchmarkStatus.completed,
          reason: '${adapter.name}: ${report.results.single.notes}',
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'additional local database packages are runnable adapters',
    () async {
      final adaptersByName = {
        for (final adapter in availableAdapters()) adapter.name: adapter,
      };
      final scenario = BenchmarkScenario(
        name: 'additional_local_adapter_smoke',
        description: 'Small local package adapter smoke test.',
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

      for (final name in [
        'fdatabase',
        'flutterdb',
        'local_shared',
        'localstorage',
        'offline_db',
        'relax_orm',
        'sqlbrite',
      ]) {
        final adapter = adaptersByName[name];
        expect(adapter, isNotNull, reason: '$name must be registered.');
        expect(
          adapter,
          isNot(isA<UnsupportedDatabaseAdapter>()),
          reason: '$name must have a real adapter.',
        );
        expect(await adapter!.isSupported, isTrue);

        final report = await runner.runAll([adapter], environment: 'test');
        expect(report.results, hasLength(1));
        expect(
          report.results.single.status,
          BenchmarkStatus.completed,
          reason: '${adapter.name}: ${report.results.single.notes}',
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

void _installFlutterSecureStorageMock() {
  final storage = <String, String>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (call) async {
          final arguments = Map<Object?, Object?>.from(call.arguments as Map);
          final key = arguments['key'] as String?;
          switch (call.method) {
            case 'containsKey':
              return storage.containsKey(key);
            case 'delete':
              storage.remove(key);
              return null;
            case 'deleteAll':
              storage.clear();
              return null;
            case 'read':
              return storage[key];
            case 'readAll':
              return storage;
            case 'write':
              storage[key!] = arguments['value'] as String;
              return null;
          }
          throw MissingPluginException('No mock for ${call.method}.');
        },
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

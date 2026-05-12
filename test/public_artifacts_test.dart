import 'dart:convert';
import 'dart:io';

import 'package:flutter_database_benchmarks/src/adapters/adapter_registry.dart';
import 'package:flutter_database_benchmarks/src/benchmark/database_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public branding uses the descriptive repository name', () {
    final readme = File('README.md').readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final html = File('docs/results.html').readAsStringSync();

    expect(readme, startsWith('# Flutter Database Benchmarks'));
    expect(pubspec, contains('name: flutter_database_benchmarks'));
    expect(
      html,
      contains('<title>Flutter Database Benchmarks Results</title>'),
    );
    expect(readme, isNot(contains('Dbench')));
  });

  test('package matrix only lists packages with adapter coverage', () {
    final packages =
        (jsonDecode(File('data/package_matrix.json').readAsStringSync())
                as List)
            .cast<Map<String, Object?>>();
    final packageNames = packages
        .map((package) => '${package['package']}')
        .toSet();
    final unsupportedMatrixAdapters =
        availableAdapters()
            .whereType<UnsupportedDatabaseAdapter>()
            .where((adapter) => packageNames.contains(adapter.name))
            .where(
              (adapter) =>
                  adapter.reason.toLowerCase().contains('pending') ||
                  adapter.reason.toLowerCase().contains('tracked') ||
                  adapter.reason.toLowerCase().contains('not implemented') ||
                  adapter.reason.toLowerCase().contains('historical'),
            )
            .map((adapter) => adapter.name)
            .toList()
          ..sort();
    final pendingPackages =
        packages
            .where(
              (package) =>
                  '${package['benchmarkStatus']}'.toLowerCase().contains(
                    'pending',
                  ) ||
                  '${package['benchmarkStatus']}'.toLowerCase().contains(
                    'tracked',
                  ),
            )
            .map((package) => '${package['package']}')
            .toList()
          ..sort();

    expect(pendingPackages, isEmpty);
    expect(unsupportedMatrixAdapters, isEmpty);
    expect(packageNames.difference(adapterCoverageNames()), isEmpty);
  });

  test('pub.dev database catalog is fully covered by benchmark adapters', () {
    final catalog =
        (jsonDecode(
                  File('data/pubdev_database_catalog.json').readAsStringSync(),
                )
                as List)
            .cast<Map<String, Object?>>();
    final packages =
        (jsonDecode(File('data/package_matrix.json').readAsStringSync())
                as List)
            .cast<Map<String, Object?>>();
    final matrixNames = packages
        .map((package) => '${package['package']}')
        .toSet();
    final curatedNames = catalog
        .where(
          (entry) =>
              entry['scope'] == 'primary' || entry['scope'] == 'companion',
        )
        .map((entry) => '${entry['package']}')
        .toSet();

    expect(curatedNames.difference(matrixNames), isEmpty);
    expect(curatedNames.difference(adapterCoverageNames()), isEmpty);
    expect(matrixNames, isNot(contains('drift_flutter')));
    expect(matrixNames, isNot(contains('drift_sqlite_async')));
    expect(matrixNames, isNot(contains('sqlite3_flutter_libs')));
    expect(matrixNames, isNot(contains('couchbase_lite')));
    expect(matrixNames, isNot(contains('torexstore')));
    expect(matrixNames, isNot(contains('shared_preferences')));
    expect(matrixNames, isNot(contains('get_storage')));
    expect(matrixNames, isNot(contains('localstorage')));
    expect(matrixNames, isNot(contains('local_shared')));
  });

  test('HTML report exposes sortable tables', () {
    final html = File('docs/results.html').readAsStringSync();

    expect(html, contains('data-sort-table'));
    expect(html, contains('data-sort-key'));
    expect(html, contains('aria-sort="'));
    expect(html, contains('Sort by '));
    expect(html, contains('data-sort-default'));
    expect(html, contains('function sortTable'));
  });

  test('public artifacts do not publish skipped benchmark rows', () {
    final readme = File('README.md').readAsStringSync().toLowerCase();
    final html = File('docs/results.html').readAsStringSync().toLowerCase();
    final resultFiles =
        Directory('results')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    expect(readme, isNot(contains('skipped')));
    expect(html, isNot(contains('skipped')));
    for (final file in resultFiles) {
      final report =
          jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      final results = (report['results'] as List).cast<Map<String, Object?>>();
      final probes =
          (report['isolateProbes'] as List?)?.cast<Map<String, Object?>>() ??
          const [];
      expect(
        results.where((result) => result['status'] == 'skipped'),
        isEmpty,
        reason: file.path,
      );
      expect(
        probes.where((probe) => probe['status'] == 'skipped'),
        isEmpty,
        reason: file.path,
      );
    }
  });

  test('public result snapshots declare release measurement modes', () {
    final resultFiles =
        Directory('results')
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in resultFiles) {
      final report =
          jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      final environment = '${report['environment']}';
      final mode = '${report['measurementMode'] ?? ''}';
      if (environment == 'web-js') {
        expect(mode, 'release-web-js', reason: file.path);
      } else if (environment == 'web-wasm') {
        expect(mode, 'release-web-wasm', reason: file.path);
      } else if (environment.startsWith('native-')) {
        expect(mode, 'release-aot', reason: file.path);
      } else {
        expect(mode, startsWith('release-'), reason: file.path);
      }
    }
  });

  test('HTML report has an overall ranking instead of cross-target table', () {
    final html = File('docs/results.html').readAsStringSync();

    expect(html, contains('Overall ranking'));
    expect(html, contains('normalized score'));
    expect(html, isNot(contains('Cross-target Comparison')));
  });

  test('public artifacts describe local-only benchmark runs, not CI', () {
    final readme = File('README.md').readAsStringSync();
    final specs =
        jsonDecode(File('data/device_specs.json').readAsStringSync())
            as Map<String, Object?>;

    expect(Directory('.github/workflows').existsSync(), isFalse);
    expect(readme, isNot(contains('GitHub Actions')));
    expect(readme, isNot(contains(RegExp(r'\bCI\b'))));
    expect(readme, contains('tool/run_all_benchmarks.ps1'));
    expect(specs.containsKey('ci'), isFalse);
    expect(specs.containsKey('targets'), isTrue);
  });

  test('single benchmark launcher covers web JS, web Wasm, and native', () {
    final script = File('tool/run_all_benchmarks.ps1').readAsStringSync();

    expect(script, contains('web-js'));
    expect(script, contains('web-wasm'));
    expect(script, contains('native'));
    expect(script, contains('flutter build web --release'));
    expect(script, contains('flutter build web --wasm'));
    expect(script, contains('--no-wasm-dry-run'));
    expect(script, contains('flutter build windows --release'));
    expect(script, contains('DBENCH_MEASUREMENT_MODE=release-aot'));
    expect(script, contains('flutter_database_benchmarks.exe'));
    expect(script, isNot(contains('integration_test/benchmark_test.dart')));
    expect(script, contains('dart run tool/update_readme.dart'));
    expect(script, contains('dart run tool/validate_results.dart'));
  });

  test(
    'Wasm-sensitive web adapters are hidden behind conditional wrappers',
    () {
      final localstore = File(
        'lib/src/adapters/localstore_adapter.dart',
      ).readAsStringSync();

      expect(localstore, contains("if (dart.library.io)"));
      expect(localstore, contains("if (dart.library.html)"));
      expect(localstore, isNot(contains("package:localstore/localstore.dart")));
    },
  );
}

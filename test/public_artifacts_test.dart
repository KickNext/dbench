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
    final databaseNames = catalog
        .where((entry) => entry['scope'] == 'database')
        .map((entry) => '${entry['package']}')
        .toSet();

    expect(databaseNames.difference(matrixNames), isEmpty);
    expect(databaseNames.difference(adapterCoverageNames()), isEmpty);
  });

  test('HTML report exposes sortable tables', () {
    final html = File('docs/results.html').readAsStringSync();

    expect(html, contains('data-sort-table'));
    expect(html, contains('data-sort-key'));
    expect(html, contains('function sortTable'));
  });
}

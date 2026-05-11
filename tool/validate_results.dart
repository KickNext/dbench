import 'dart:convert';
import 'dart:io';

void main() {
  final root = Directory.current;
  final packages =
      (jsonDecode(
                File(
                  '${root.path}/data/package_matrix.json',
                ).readAsStringSync(),
              )
              as List)
          .cast<Map<String, Object?>>();
  final packageNames = packages
      .map((package) => '${package['package']}')
      .toSet();
  final resultDirectory = Directory('${root.path}/results');
  if (!resultDirectory.existsSync()) {
    throw StateError('Missing results directory.');
  }

  final files =
      resultDirectory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  if (files.isEmpty) {
    throw StateError('No result JSON files found.');
  }

  final failures = <String>[];
  for (final file in files) {
    _validateReport(file, packageNames, failures);
  }
  if (failures.isNotEmpty) {
    stderr.writeln('Result validation failed:');
    for (final failure in failures) {
      stderr.writeln('- $failure');
    }
    exitCode = 1;
  }
}

void _validateReport(
  File file,
  Set<String> packageNames,
  List<String> failures,
) {
  final report = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  final environment = '${report['environment']}';
  final scenarios = ((report['workload'] as Map)['scenarios'] as List)
      .cast<Map<String, Object?>>();
  final results = (report['results'] as List).cast<Map<String, Object?>>();
  final scenarioSampleRuns = {
    for (final scenario in scenarios)
      '${scenario['name']}': (scenario['sampleRuns'] as num?)?.toInt() ?? 1,
  };
  final scenarioNames = scenarioSampleRuns.keys.toSet();

  for (final result in results) {
    final scenario = '${result['scenario']}';
    final database = '${result['database']}';
    if (!scenarioNames.contains(scenario)) {
      failures.add(
        '${file.path}: $database references unknown scenario $scenario.',
      );
    }
    if (database != 'memory_baseline' && !packageNames.contains(database)) {
      failures.add(
        '${file.path}: result database $database is not in package matrix.',
      );
    }
    if (result['status'] == 'completed') {
      final expectedSamples = scenarioSampleRuns[scenario] ?? 1;
      final sampleRuns = (result['sampleRuns'] as num?)?.toInt() ?? 1;
      final sampleElapsed =
          (result['sampleElapsedMicros'] as List?)?.cast<Object?>() ?? const [];
      if (sampleRuns != expectedSamples) {
        failures.add(
          '${file.path}: $environment/$scenario/$database has sampleRuns=$sampleRuns, expected $expectedSamples.',
        );
      }
      if (sampleElapsed.length != expectedSamples) {
        failures.add(
          '${file.path}: $environment/$scenario/$database has ${sampleElapsed.length} elapsed samples, expected $expectedSamples.',
        );
      }
      if (sampleElapsed.any((value) => (value as num).toInt() < 1)) {
        failures.add(
          '${file.path}: $environment/$scenario/$database has non-positive elapsed sample.',
        );
      }
    }
  }

  for (final scenario in scenarioNames) {
    final resultNames = results
        .where((result) => result['scenario'] == scenario)
        .map((result) => '${result['database']}')
        .toSet();
    final missing = packageNames.difference(resultNames);
    if (missing.isNotEmpty) {
      failures.add(
        '${file.path}: $environment/$scenario missing package result rows: ${missing.toList()..sort()}',
      );
    }
  }
}

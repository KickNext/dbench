import 'dart:convert';
import 'dart:io';

void main() {
  final root = Directory.current;
  final matrixFile = File('${root.path}/data/package_matrix.json');
  final specsFile = File('${root.path}/data/device_specs.json');
  final readmeFile = File('${root.path}/README.md');

  final packages = (jsonDecode(matrixFile.readAsStringSync()) as List)
      .cast<Map<String, Object?>>();
  final specs =
      jsonDecode(specsFile.readAsStringSync()) as Map<String, Object?>;
  final results = _loadResults(Directory('${root.path}/results'));

  var readme = readmeFile.readAsStringSync();
  readme = _replaceSection(readme, 'PACKAGE_MATRIX', _packageMatrix(packages));
  readme = _replaceSection(readme, 'DEVICE_SPECS', _deviceSpecs(specs));
  readme = _replaceSection(
    readme,
    'BENCHMARK_RESULTS',
    _benchmarkResults(results),
  );
  readmeFile.writeAsStringSync(readme);
}

List<Map<String, Object?>> _loadResults(Directory directory) {
  if (!directory.existsSync()) {
    return [];
  }
  final reports = <Map<String, Object?>>[];
  for (final file in directory.listSync().whereType<File>()) {
    if (!file.path.endsWith('.json')) {
      continue;
    }
    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    reports.add(decoded);
  }
  reports.sort(
    (a, b) => '${a['environment']}'.compareTo('${b['environment']}'),
  );
  return reports;
}

String _replaceSection(String readme, String marker, String content) {
  final start = '<!-- DBENCH:$marker:start -->';
  final end = '<!-- DBENCH:$marker:end -->';
  final pattern = RegExp('$start[\\s\\S]*?$end');
  final replacement = '$start\n$content\n$end';
  if (!pattern.hasMatch(readme)) {
    throw StateError('Missing README marker $marker.');
  }
  return readme.replaceFirst(pattern, replacement);
}

String _packageMatrix(List<Map<String, Object?>> packages) {
  final buffer = StringBuffer()
    ..writeln(
      '| Package | Latest | Type | Platforms | Transactions | Benchmark status |',
    )
    ..writeln('| --- | ---: | --- | --- | --- | --- |');
  for (final package in packages) {
    buffer.writeln(
      '| [${package['package']}](https://pub.dev/packages/${package['package']}) '
      '| ${package['latest']} '
      '| ${package['type']} '
      '| ${package['platforms']} '
      '| ${package['transactions']} '
      '| ${package['benchmarkStatus']} |',
    );
  }
  return buffer.toString().trimRight();
}

String _deviceSpecs(Map<String, Object?> specs) {
  final android = (specs['androidDevice'] as Map).cast<String, Object?>();
  final toolchain = (specs['localToolchain'] as Map).cast<String, Object?>();
  return '''
| Area | Value |
| --- | --- |
| Android test device | ${android['model']} (${android['manufacturer']}, ${android['device']}) |
| Android hardware | ${android['hardware']} |
| Android OS | Android ${android['android']} / API ${android['apiLevel']} |
| Android CPU | ${android['cpu']} |
| Android memory | ${android['memory']} |
| Android display | ${android['display']} |
| Flutter | ${toolchain['flutter']} |
| Dart | ${toolchain['dart']} |
| Windows | ${toolchain['windows']} |
| Chrome | ${toolchain['chrome']} |
| Edge | ${toolchain['edge']} |''';
}

String _benchmarkResults(List<Map<String, Object?>> reports) {
  if (reports.isEmpty) {
    return 'No benchmark result JSON files have been committed yet.';
  }

  final buffer = StringBuffer()
    ..writeln(
      '| Environment | Database | Status | Records | Payload | Total ops | Ops/sec | Notes |',
    )
    ..writeln('| --- | --- | --- | ---: | ---: | ---: | ---: | --- |');
  for (final report in reports) {
    final workload = (report['workload'] as Map).cast<String, Object?>();
    final results = (report['results'] as List).cast<Map<String, Object?>>();
    for (final result in results) {
      final rate = (result['opsPerSecond'] as num).toStringAsFixed(0);
      final notes = '${result['notes'] ?? ''}'.replaceAll('\n', '<br>');
      buffer.writeln(
        '| ${report['environment']} '
        '| ${result['database']} '
        '| ${result['status']} '
        '| ${workload['records']} '
        '| ${workload['payloadBytes']} '
        '| ${result['totalOps']} '
        '| $rate '
        '| $notes |',
      );
    }
  }
  return buffer.toString().trimRight();
}

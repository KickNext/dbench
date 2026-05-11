import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

const _ciResultEnvironments = {'web', 'linux', 'windows'};
const _productName = 'Flutter Database Benchmarks';

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
    'CI_VISUALIZATION',
    _ciVisualization(results, packages),
  );
  readme = _replaceSection(
    readme,
    'BENCHMARK_RESULTS',
    _benchmarkResults(results, packages),
  );
  readme = _replaceSection(readme, 'ISOLATE_RESULTS', _isolateResults(results));
  readmeFile.writeAsStringSync(readme);

  File(
    '${root.path}/docs/results.html',
  ).writeAsStringSync(_htmlReport(results, packages, specs));
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
    final environment = '${decoded['environment']}';
    if (!_ciResultEnvironments.contains(environment)) {
      continue;
    }
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
  final table = StringBuffer()
    ..writeln(
      '| Package | Latest | Family | Type | Platforms | Transactions | Benchmark status |',
    )
    ..writeln('| --- | ---: | --- | --- | --- | --- | --- |');
  for (final package in packages) {
    table.writeln(
      '| [${package['package']}](https://pub.dev/packages/${package['package']}) '
      '| ${package['latest']} '
      '| ${_family(package)} '
      '| ${package['type']} '
      '| ${package['platforms']} '
      '| ${package['transactions']} '
      '| ${package['benchmarkStatus']} |',
    );
  }
  return '''
<details>
<summary>Adapter-covered package matrix (${packages.length} packages)</summary>

${table.toString().trimRight()}

</details>''';
}

String _family(Map<String, Object?> package) {
  final name = '${package['package']}';
  final type = '${package['type']}'.toLowerCase();
  if (type.contains('sqlite')) {
    return 'SQL';
  }
  if (name == 'shared_preferences' ||
      name == 'get_storage' ||
      name == 'hive' ||
      name == 'hive_ce') {
    return 'Key-value baseline';
  }
  return 'NoSQL';
}

String _deviceSpecs(Map<String, Object?> specs) {
  final policy = (specs['resultPolicy'] as Map).cast<String, Object?>();
  final ci = (specs['ci'] as Map).cast<String, Object?>();
  return '''
| Area | Value |
| --- | --- |
| README results | ${policy['readmeResults']} |
| Local results | ${policy['localResults']} |
| Flutter | ${ci['flutter']} |
| Web CI | ${ci['web']} |
| Linux CI | ${ci['linux']} |
| Windows CI | ${ci['windows']} |
| Android | ${ci['android']} |''';
}

String _ciVisualization(
  List<Map<String, Object?>> reports,
  List<Map<String, Object?>> packages,
) {
  if (reports.isEmpty) {
    return 'No CI benchmark result JSON files have been committed yet.';
  }

  final environments = reports
      .map((report) => '${report['environment']}')
      .toSet();
  final completedPackages = _completedPackageNames(reports, packages);
  final unmeasuredPackages =
      packages
          .map((package) => '${package['package']}')
          .where((name) => !completedPackages.contains(name))
          .toList()
        ..sort();

  final buffer = StringBuffer()
    ..writeln(
      'Open [docs/results.html](docs/results.html) for the visual dashboard with SVG charts and cross-target tables.',
    )
    ..writeln()
    ..writeln(
      'Committed result snapshots currently present: ${environments.map((environment) => '`$environment`').join(', ')}.',
    );
  if (!environments.contains('linux')) {
    buffer.writeln(
      '`linux` is configured in GitHub Actions but no Linux JSON snapshot is committed in this checkout yet. It should appear only after a real Linux workflow run generates `results/linux.json`.',
    );
  }
  buffer
    ..writeln()
    ..writeln(
      'Measured packages in committed snapshots: ${completedPackages.length} of ${packages.length}. '
      'Skipped rows are target-specific platform or scenario limits, not hidden benchmark numbers.',
    )
    ..writeln()
    ..writeln('### Coverage Snapshot')
    ..writeln()
    ..writeln(
      '| Environment | Completed adapters | Skipped rows | Failed rows |',
    )
    ..writeln('| --- | --- | ---: | ---: |');
  for (final report in reports) {
    final results = (report['results'] as List).cast<Map<String, Object?>>();
    final completed =
        results
            .where(
              (result) =>
                  result['status'] == 'completed' &&
                  result['database'] != 'memory_baseline',
            )
            .map((result) => '${result['database']}')
            .toSet()
            .toList()
          ..sort();
    buffer.writeln(
      '| ${report['environment']} '
      '| ${completed.isEmpty ? '-' : completed.map((name) => '`$name`').join(', ')} '
      '| ${_statusCount(results, 'skipped')} '
      '| ${_statusCount(results, 'failed')} |',
    );
  }

  if (unmeasuredPackages.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('### Adapter-Covered But Not Present In CI Numbers')
      ..writeln()
      ..writeln(unmeasuredPackages.map((name) => '`$name`').join(', '))
      ..writeln()
      ..writeln(
        'Reasons are kept in raw JSON skipped rows, typically platform-only adapters such as `sqflite` on Android/iOS/macOS or Web SQLite WASM/worker setup that is intentionally not counted as a completed CI number.',
      );
  }

  buffer
    ..writeln()
    ..writeln('### Fastest Rows')
    ..writeln()
    ..writeln(
      '| Environment | Scenario | Fastest SQL/document adapter | Fastest persistent adapter | Completed | Skipped | Failed |',
    )
    ..writeln('| --- | --- | --- | --- | ---: | ---: | ---: |');
  for (final report in reports) {
    final results = (report['results'] as List).cast<Map<String, Object?>>();
    final scenarioNames = results.map(_scenarioName).toSet().toList()..sort();
    for (final scenarioName in scenarioNames) {
      final scenarioResults = results
          .where((result) => _scenarioName(result) == scenarioName)
          .toList();
      buffer.writeln(
        '| ${report['environment']} '
        '| $scenarioName '
        '| ${_fastestCompletedLabel(scenarioResults, packages, databaseEnginesOnly: true)} '
        '| ${_fastestCompletedLabel(scenarioResults, packages)} '
        '| ${_statusCount(scenarioResults, 'completed')} '
        '| ${_statusCount(scenarioResults, 'skipped')} '
        '| ${_statusCount(scenarioResults, 'failed')} |',
      );
    }
  }
  return buffer.toString().trimRight();
}

String _benchmarkResults(
  List<Map<String, Object?>> reports,
  List<Map<String, Object?>> packages,
) {
  if (reports.isEmpty) {
    return 'No benchmark result JSON files have been committed yet.';
  }

  final packageNames = packages
      .map((package) => '${package['package']}')
      .toSet();
  final completedPackages = _completedPackageNames(reports, packages).length;
  final rows = <String>[
    '| Environment | JSON source | Generated | Scenario rows | Measured packages |',
    '| --- | --- | --- | ---: | ---: |',
  ];
  for (final report in reports) {
    final environment = '${report['environment']}';
    final results = (report['results'] as List).cast<Map<String, Object?>>();
    final measuredPackages = results
        .where(
          (result) =>
              result['status'] == 'completed' &&
              packageNames.contains('${result['database']}'),
        )
        .map((result) => '${result['database']}')
        .toSet()
        .length;
    rows.add(
      '| $environment '
      '| [`results/$environment.json`](results/$environment.json) '
      '| `${report['generatedAt'] ?? 'unknown'}` '
      '| ${results.length} '
      '| $measuredPackages |',
    );
  }
  return '''
The readable dashboard is [docs/results.html](docs/results.html). Raw machine-readable snapshots stay in `results/*.json` instead of being duplicated into README tables.

Measured packages across committed snapshots: $completedPackages of ${packages.length}.

${rows.join('\n')}''';
}

String _scenarioName(Map<String, Object?> result) {
  return '${result['scenario'] ?? 'crud_balanced'}';
}

String _statusSummary(List<Map<String, Object?>> results) {
  final completed = results.where((result) => result['status'] == 'completed');
  final failed = results.where((result) => result['status'] == 'failed');
  final skipped = results.where((result) => result['status'] == 'skipped');
  return '${completed.length} completed, ${failed.length} failed, ${skipped.length} skipped';
}

int _statusCount(List<Map<String, Object?>> results, String status) {
  return results.where((result) => result['status'] == status).length;
}

Set<String> _completedPackageNames(
  List<Map<String, Object?>> reports,
  List<Map<String, Object?>> packages,
) {
  final packageNames = packages
      .map((package) => '${package['package']}')
      .toSet();
  final completed = <String>{};
  for (final report in reports) {
    final results = (report['results'] as List).cast<Map<String, Object?>>();
    for (final result in results) {
      final database = '${result['database']}';
      if (result['status'] == 'completed' && packageNames.contains(database)) {
        completed.add(database);
      }
    }
  }
  return completed;
}

String _fastestCompletedLabel(
  List<Map<String, Object?>> results,
  List<Map<String, Object?>> packages, {
  bool databaseEnginesOnly = false,
}) {
  final completed =
      results
          .where(
            (result) =>
                result['status'] == 'completed' &&
                result['database'] != 'memory_baseline' &&
                (result['opsPerSecond'] as num) > 0 &&
                (!databaseEnginesOnly ||
                    _resultFamily('${result['database']}', packages) !=
                        'Key-value baseline'),
          )
          .toList()
        ..sort(
          (a, b) =>
              (b['opsPerSecond'] as num).compareTo(a['opsPerSecond'] as num),
        );
  if (completed.isEmpty) {
    return '-';
  }
  final fastest = completed.first;
  final database = '${fastest['database']}';
  final rate = _formatRate(fastest['opsPerSecond'] as num);
  return '`$database` $rate ops/sec';
}

String _isolateResults(List<Map<String, Object?>> reports) {
  final rows = <String>[];
  for (final report in reports) {
    final probes =
        (report['isolateProbes'] as List?)?.cast<Map<String, Object?>>() ?? [];
    for (final probe in probes) {
      rows.add(
        '| ${report['environment']} '
        '| ${probe['database']} '
        '| ${probe['status']} '
        '| ${_sharedReadLabel(probe['sharedRead'])} '
        '| ${'${probe['notes'] ?? ''}'.replaceAll('\n', '<br>')} |',
      );
    }
  }
  if (rows.isEmpty) {
    return 'No isolate probe results have been committed yet.';
  }
  final table = [
    '| Environment | Database | Status | Shared read across isolates | Notes |',
    '| --- | --- | --- | --- | --- |',
    ...rows,
  ].join('\n');
  return '''
<details>
<summary>Isolate sharing probe rows</summary>

$table

</details>''';
}

String _resultFamily(String database, List<Map<String, Object?>> packages) {
  final matrixMatch = packages
      .where((package) => package['package'] == database)
      .firstOrNull;
  if (matrixMatch != null) {
    return _family(matrixMatch);
  }
  if (database.contains('sqflite') || database.contains('sqlite')) {
    return 'SQL';
  }
  if (database == 'memory_baseline' ||
      database == 'shared_preferences' ||
      database == 'get_storage' ||
      database == 'hive_ce') {
    return 'Key-value baseline';
  }
  return 'NoSQL';
}

String _sharedReadLabel(Object? value) {
  if (value == null) {
    return 'not tested';
  }
  return value == true ? 'yes' : 'no';
}

String _htmlReport(
  List<Map<String, Object?>> reports,
  List<Map<String, Object?>> packages,
  Map<String, Object?> specs,
) {
  final generatedAt = _reportGeneratedAt(reports);
  final buffer = StringBuffer()
    ..writeln('<!doctype html>')
    ..writeln('<html lang="en">')
    ..writeln('<head>')
    ..writeln('<meta charset="utf-8">')
    ..writeln(
      '<meta name="viewport" content="width=device-width, initial-scale=1">',
    )
    ..writeln('<title>$_productName Results</title>')
    ..writeln('<style>')
    ..writeln(_htmlStyles)
    ..writeln('</style>')
    ..writeln('</head>')
    ..writeln('<body>')
    ..writeln('<main>')
    ..writeln('<header class="hero">')
    ..writeln('<p class="eyebrow">Dart / Flutter database benchmark</p>')
    ..writeln('<h1>$_productName CI Results</h1>')
    ..writeln(
      '<p class="lede">Self-contained visual report generated from committed JSON results. Persistent adapters are charted separately from the synthetic memory ceiling; chart bars use a log scale so slower adapters remain visually comparable.</p>',
    )
    ..writeln('<dl class="meta">')
    ..writeln('<div><dt>Generated</dt><dd>${_h(generatedAt)}</dd></div>')
    ..writeln('<div><dt>Reports</dt><dd>${reports.length}</dd></div>')
    ..writeln('<div><dt>Tracked packages</dt><dd>${packages.length}</dd></div>')
    ..writeln('</dl>')
    ..writeln('</header>');

  if (reports.isEmpty) {
    buffer
      ..writeln('<section class="panel">')
      ..writeln('<h2>No committed CI results yet</h2>')
      ..writeln('<p>Run the benchmark workflow and regenerate this report.</p>')
      ..writeln('</section>');
  } else {
    buffer
      ..writeln('<section class="panel guardrails">')
      ..writeln('<h2>Decision Guardrails</h2>')
      ..writeln('<ul>')
      ..writeln(
        '<li>Key-value baselines are included to set a ceiling, not to recommend them as replacements for SQL, document, or object databases.</li>',
      )
      ..writeln(
        '<li>Rows marked skipped are explicit coverage gaps or unsupported targets, not hidden failures.</li>',
      )
      ..writeln(
        '<li>Push and pull-request runs are smoke-sized; scheduled CI runs use the larger stress record count declared in the workflow.</li>',
      )
      ..writeln('</ul>')
      ..writeln('</section>')
      ..writeln('<section class="panel">')
      ..writeln('<h2>Fastest SQL / Document Adapters</h2>')
      ..writeln(
        '<p class="note">This view excludes key-value and settings-style baselines so database engines can be compared without `shared_preferences`, `get_storage`, or memory ceilings.</p>',
      )
      ..writeln(_summaryCards(reports, packages, databaseEnginesOnly: true))
      ..writeln('</section>')
      ..writeln('<section class="panel">')
      ..writeln('<h2>Fastest Persistent Adapter By Scenario</h2>')
      ..writeln(_summaryCards(reports, packages))
      ..writeln('</section>')
      ..writeln('<section class="charts">')
      ..writeln('<div class="section-head">')
      ..writeln('<h2>Scenario Charts</h2>')
      ..writeln(_chartLegend())
      ..writeln('</div>');
    for (final report in reports) {
      final results = (report['results'] as List).cast<Map<String, Object?>>();
      final scenarioNames = results.map(_scenarioName).toSet().toList()..sort();
      for (final scenarioName in scenarioNames) {
        final scenarioResults = results
            .where((result) => _scenarioName(result) == scenarioName)
            .toList();
        buffer.writeln(
          _scenarioChart(report, scenarioName, scenarioResults, packages),
        );
      }
    }
    buffer
      ..writeln('</section>')
      ..writeln('<section class="panel">')
      ..writeln('<h2>Cross-target Comparison</h2>')
      ..writeln(
        '<p class="note">Cells show ops/sec for completed persistent adapters. Exhaustive package coverage is kept here after the charts so the visual comparison stays readable first.</p>',
      )
      ..writeln(_comparisonTable(reports, packages))
      ..writeln('</section>');
  }

  buffer
    ..writeln('<section class="panel">')
    ..writeln('<h2>Package Coverage</h2>')
    ..writeln(_packageCoverageTable(packages))
    ..writeln('</section>')
    ..writeln('<section class="panel">')
    ..writeln('<h2>Result Policy</h2>')
    ..writeln(_resultPolicy(specs))
    ..writeln('</section>')
    ..writeln('</main>')
    ..writeln('<script>')
    ..writeln(_sortScript)
    ..writeln('</script>')
    ..writeln('</body>')
    ..writeln('</html>');
  return buffer.toString();
}

String _reportGeneratedAt(List<Map<String, Object?>> reports) {
  if (reports.isEmpty) {
    return 'no committed results';
  }
  return reports
      .map((report) => '${report['generatedAt'] ?? 'unknown'}')
      .join(' / ');
}

String _summaryCards(
  List<Map<String, Object?>> reports,
  List<Map<String, Object?>> packages, {
  bool databaseEnginesOnly = false,
}) {
  final cards = <String>[];
  for (final report in reports) {
    final results = (report['results'] as List).cast<Map<String, Object?>>();
    final scenarioNames = results.map(_scenarioName).toSet().toList()..sort();
    for (final scenarioName in scenarioNames) {
      final persistent =
          results
              .where(
                (result) =>
                    _scenarioName(result) == scenarioName &&
                    result['status'] == 'completed' &&
                    result['database'] != 'memory_baseline' &&
                    (!databaseEnginesOnly ||
                        _resultFamily('${result['database']}', packages) !=
                            'Key-value baseline'),
              )
              .toList()
            ..sort(
              (a, b) => (b['opsPerSecond'] as num).compareTo(
                a['opsPerSecond'] as num,
              ),
            );
      if (persistent.isEmpty) {
        continue;
      }
      final fastest = persistent.first;
      cards.add('''
<article class="summary-card">
  <div class="summary-key">${_h('${report['environment']} / $scenarioName')}</div>
  <div class="summary-db">${_h('${fastest['database']}')}</div>
  <div class="summary-rate">${_formatRate(fastest['opsPerSecond'] as num)} ops/sec</div>
  <div class="summary-family">${_h(_resultFamily('${fastest['database']}', packages))}</div>
</article>''');
    }
  }
  if (cards.isEmpty) {
    return '<p class="note">No completed database-engine adapters in the committed result set.</p>';
  }
  return '<div class="summary-grid">${cards.join('\n')}</div>';
}

String _comparisonTable(
  List<Map<String, Object?>> reports,
  List<Map<String, Object?>> packages,
) {
  final environments =
      reports.map((report) => '${report['environment']}').toList()..sort();
  final rows = <({String scenario, String database})>{};
  final rates = <String, num>{};
  for (final report in reports) {
    final environment = '${report['environment']}';
    final results = (report['results'] as List).cast<Map<String, Object?>>();
    for (final result in results) {
      if (result['database'] == 'memory_baseline') {
        continue;
      }
      final key = (
        scenario: _scenarioName(result),
        database: '${result['database']}',
      );
      rows.add(key);
      if (result['status'] == 'completed') {
        rates['$environment|${key.scenario}|${key.database}'] =
            result['opsPerSecond'] as num;
      }
    }
  }
  final sortedRows = rows.toList()
    ..sort((a, b) {
      final scenario = a.scenario.compareTo(b.scenario);
      return scenario == 0 ? a.database.compareTo(b.database) : scenario;
    });

  final buffer = StringBuffer()
    ..writeln('<div class="table-wrap"><table data-sort-table>')
    ..writeln('<thead><tr>')
    ..writeln(
      '${_sortHeader('Scenario', 'text')}${_sortHeader('Family', 'text')}${_sortHeader('Adapter', 'text')}',
    );
  for (final environment in environments) {
    buffer.writeln(_sortHeader(environment, 'number'));
  }
  buffer
    ..writeln('</tr></thead>')
    ..writeln('<tbody>');
  for (final row in sortedRows) {
    buffer
      ..writeln('<tr>')
      ..writeln(_sortCell(row.scenario))
      ..writeln(_sortCell(_resultFamily(row.database, packages)))
      ..writeln(_sortCell(row.database));
    for (final environment in environments) {
      final rate = rates['$environment|${row.scenario}|${row.database}'];
      buffer.writeln(
        _sortCell(
          rate == null ? '-' : _formatRate(rate),
          sortValue: rate ?? -1,
        ),
      );
    }
    buffer.writeln('</tr>');
  }
  buffer
    ..writeln('</tbody>')
    ..writeln('</table></div>');
  return buffer.toString();
}

String _scenarioChart(
  Map<String, Object?> report,
  String scenarioName,
  List<Map<String, Object?>> scenarioResults,
  List<Map<String, Object?>> packages,
) {
  final completed =
      scenarioResults
          .where(
            (result) =>
                result['status'] == 'completed' &&
                result['database'] != 'memory_baseline',
          )
          .toList()
        ..sort(
          (a, b) =>
              (b['opsPerSecond'] as num).compareTo(a['opsPerSecond'] as num),
        );
  final maxRate = completed.isEmpty
      ? 0
      : completed.first['opsPerSecond'] as num;
  final memory = scenarioResults
      .where(
        (result) =>
            result['database'] == 'memory_baseline' &&
            result['status'] == 'completed',
      )
      .firstOrNull;
  final notCompleted = scenarioResults
      .where((result) => result['status'] != 'completed')
      .toList();
  final description = scenarioResults.isEmpty
      ? ''
      : '${scenarioResults.first['scenarioDescription'] ?? ''}';

  return '''
<article class="chart-card">
  <div class="chart-head">
    <div>
      <h3>${_h('${report['environment']} / $scenarioName')}</h3>
      <p>${_h(description)}</p>
    </div>
    <div class="chart-meta">${_h(_statusSummary(scenarioResults))}</div>
  </div>
  ${_scenarioFacts(report, scenarioResults)}
  ${memory == null ? '' : '<p class="note">Synthetic memory ceiling: ${_formatRate(memory['opsPerSecond'] as num)} ops/sec.</p>'}
  <p class="note">Bar length uses log10(ops/sec + 1); labels show raw median-sample ops/sec.</p>
  ${_barSvg(completed, maxRate, packages)}
  ${notCompleted.isEmpty ? '' : _statusList(notCompleted)}
</article>''';
}

String _scenarioFacts(
  Map<String, Object?> report,
  List<Map<String, Object?>> scenarioResults,
) {
  if (scenarioResults.isEmpty) {
    return '';
  }
  final first = scenarioResults.first;
  return '''
<div class="facts">
  <span>samples ${_h('${first['sampleRuns'] ?? 1}')}</span>
  <span>records ${_h('${first['records'] ?? '-'}')}</span>
  <span>payload ${_h('${first['payloadBytes'] ?? '-'}')} bytes</span>
  <span>median timing</span>
  <span>${_h('${report['generatedAt'] ?? 'unknown'}')}</span>
</div>''';
}

String _barSvg(
  List<Map<String, Object?>> results,
  num maxRate,
  List<Map<String, Object?>> packages,
) {
  if (results.isEmpty) {
    return '<p class="note">No completed persistent adapters for this scenario.</p>';
  }
  const left = 190;
  const right = 140;
  const barWidth = 620;
  const rowHeight = 38;
  const top = 18;
  final height = top * 2 + results.length * rowHeight;
  final width = left + barWidth + right;
  final rows = StringBuffer();
  for (var index = 0; index < results.length; index += 1) {
    final result = results[index];
    final rate = result['opsPerSecond'] as num;
    final fraction = maxRate <= 0
        ? 0.0
        : (math.log(rate + 1) / math.log(maxRate + 1)).clamp(0.0, 1.0);
    final y = top + index * rowHeight;
    final fill = _familyColor(_resultFamily('${result['database']}', packages));
    rows
      ..writeln(
        '<text x="0" y="${y + 19}" class="axis">${_h('${result['database']}')}</text>',
      )
      ..writeln(
        '<rect x="$left" y="$y" width="$barWidth" height="24" rx="5" class="track"></rect>',
      )
      ..writeln(
        '<rect x="$left" y="$y" width="${(barWidth * fraction).toStringAsFixed(1)}" height="24" rx="5" fill="$fill"></rect>',
      )
      ..writeln(
        '<text x="${left + barWidth + 14}" y="${y + 18}" class="value">${_formatRate(rate)}</text>',
      );
  }
  return '''
<div class="svg-wrap">
<svg viewBox="0 0 $width $height" role="img" aria-label="Ops per second by adapter">
  ${rows.toString()}
</svg>
</div>''';
}

String _statusList(List<Map<String, Object?>> results) {
  final items = results
      .map(
        (result) =>
            '<li><strong>${_h('${result['database']}')}</strong> ${_h('${result['status']}')}: ${_h('${result['notes'] ?? ''}')}</li>',
      )
      .join('\n');
  return '''
<details class="status-details">
  <summary>${results.length} skipped / failed adapters</summary>
  <ul class="status-list">$items</ul>
</details>''';
}

String _chartLegend() {
  return '''
<div class="legend" aria-label="Chart color legend">
  <span><i style="background:#2563eb"></i>SQL</span>
  <span><i style="background:#047857"></i>NoSQL / document / object</span>
  <span><i style="background:#b45309"></i>Key-value baseline</span>
</div>''';
}

String _packageCoverageTable(List<Map<String, Object?>> packages) {
  final buffer = StringBuffer()
    ..writeln('<div class="table-wrap"><table data-sort-table>')
    ..writeln('<thead><tr>')
    ..writeln(
      '${_sortHeader('Package', 'text')}${_sortHeader('Family', 'text')}${_sortHeader('Platforms', 'text')}${_sortHeader('Status', 'text')}',
    )
    ..writeln('</tr></thead>')
    ..writeln('<tbody>');
  for (final package in packages) {
    buffer
      ..writeln('<tr>')
      ..writeln(
        _sortCell(
          '<a href="https://pub.dev/packages/${_u('${package['package']}')}">${_h('${package['package']}')}</a>',
          sortValue: '${package['package']}',
          escape: false,
        ),
      )
      ..writeln(_sortCell(_family(package)))
      ..writeln(_sortCell('${package['platforms']}'))
      ..writeln(_sortCell('${package['benchmarkStatus']}'))
      ..writeln('</tr>');
  }
  buffer
    ..writeln('</tbody>')
    ..writeln('</table></div>');
  return buffer.toString();
}

String _resultPolicy(Map<String, Object?> specs) {
  final policy = (specs['resultPolicy'] as Map).cast<String, Object?>();
  final ci = (specs['ci'] as Map).cast<String, Object?>();
  return '''
<dl class="policy">
  <div><dt>README results</dt><dd>${_h('${policy['readmeResults']}')}</dd></div>
  <div><dt>Local results</dt><dd>${_h('${policy['localResults']}')}</dd></div>
  <div><dt>Flutter</dt><dd>${_h('${ci['flutter']}')}</dd></div>
  <div><dt>Web CI</dt><dd>${_h('${ci['web']}')}</dd></div>
  <div><dt>Linux CI</dt><dd>${_h('${ci['linux']}')}</dd></div>
  <div><dt>Windows CI</dt><dd>${_h('${ci['windows']}')}</dd></div>
  <div><dt>Android</dt><dd>${_h('${ci['android']}')}</dd></div>
</dl>''';
}

String _formatRate(num value) {
  final rounded = value.round();
  final text = rounded.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i += 1) {
    final fromEnd = text.length - i;
    buffer.write(text[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

String _sortHeader(String label, String type) {
  return '<th data-sort-key="${_h(label.toLowerCase())}" data-sort-type="$type" tabindex="0">${_h(label)} <span aria-hidden="true">sort</span></th>';
}

String _sortCell(Object display, {Object? sortValue, bool escape = true}) {
  final value = sortValue ?? display;
  final rendered = escape ? _h('$display') : '$display';
  return '<td data-sort-value="${_h('$value')}">$rendered</td>';
}

String _familyColor(String family) {
  return switch (family) {
    'SQL' => '#2563eb',
    'Key-value baseline' => '#b45309',
    _ => '#047857',
  };
}

String _h(String value) => const HtmlEscape().convert(value);

String _u(String value) => Uri.encodeComponent(value);

const _htmlStyles = '''
:root {
  color-scheme: light;
  --ink: #172033;
  --muted: #5d687c;
  --line: #d8deea;
  --panel: #ffffff;
  --bg: #f5f7fb;
  --track: #e9edf5;
}
* { box-sizing: border-box; }
body {
  margin: 0;
  background: var(--bg);
  color: var(--ink);
  font: 14px/1.5 system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
}
main {
  width: min(1180px, calc(100% - 32px));
  margin: 0 auto;
  padding: 32px 0 56px;
}
.hero {
  padding: 30px 0 18px;
}
.eyebrow {
  margin: 0 0 8px;
  color: var(--muted);
  font-size: 13px;
  font-weight: 700;
  letter-spacing: .06em;
  text-transform: uppercase;
}
h1, h2, h3, p { margin-top: 0; }
h1 {
  margin-bottom: 10px;
  font-size: clamp(34px, 7vw, 64px);
  line-height: 1;
}
h2 {
  margin-bottom: 18px;
  font-size: 24px;
}
h3 {
  margin-bottom: 4px;
  font-size: 18px;
}
.lede {
  max-width: 760px;
  color: var(--muted);
  font-size: 17px;
}
.meta, .policy {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 10px;
  margin: 22px 0 0;
}
.meta div, .policy div {
  padding: 12px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: var(--panel);
}
dt {
  color: var(--muted);
  font-size: 12px;
  font-weight: 700;
  text-transform: uppercase;
}
dd { margin: 3px 0 0; }
.panel, .chart-card {
  margin-top: 18px;
  padding: 20px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: var(--panel);
}
.charts h2 { margin: 0; }
.summary-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(210px, 1fr));
  gap: 12px;
}
.summary-card {
  padding: 14px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: #fbfcff;
}
.summary-key, .summary-family, .note {
  color: var(--muted);
}
.summary-db {
  margin-top: 8px;
  font-size: 20px;
  font-weight: 750;
}
.summary-rate {
  font-variant-numeric: tabular-nums;
  font-weight: 700;
}
.chart-head {
  display: flex;
  justify-content: space-between;
  gap: 18px;
  align-items: flex-start;
}
.chart-head p { color: var(--muted); }
.chart-meta {
  white-space: nowrap;
  color: var(--muted);
  font-weight: 650;
}
.svg-wrap {
  overflow-x: auto;
  padding-top: 8px;
}
svg {
  display: block;
  min-width: 760px;
  width: 100%;
}
.axis {
  fill: var(--ink);
  font-size: 13px;
  font-weight: 650;
}
.value {
  fill: var(--muted);
  font-size: 13px;
  font-variant-numeric: tabular-nums;
}
.track { fill: var(--track); }
.section-head {
  display: flex;
  justify-content: space-between;
  gap: 18px;
  align-items: center;
  margin-top: 30px;
}
.legend {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  color: var(--muted);
  font-size: 13px;
  font-weight: 650;
}
.legend span {
  display: inline-flex;
  gap: 6px;
  align-items: center;
}
.legend i {
  display: inline-block;
  width: 12px;
  height: 12px;
  border-radius: 3px;
}
.facts {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin: 10px 0;
}
.facts span {
  padding: 4px 8px;
  border: 1px solid var(--line);
  border-radius: 999px;
  color: var(--muted);
  font-size: 12px;
  font-weight: 650;
}
.status-details {
  margin-top: 12px;
  color: var(--muted);
}
.status-details summary {
  cursor: pointer;
  font-weight: 700;
}
.status-list {
  margin: 12px 0 0;
  padding-left: 18px;
  color: var(--muted);
}
.table-wrap {
  overflow-x: auto;
}
table {
  width: 100%;
  min-width: 760px;
  border-collapse: collapse;
  font-variant-numeric: tabular-nums;
}
th, td {
  padding: 9px 10px;
  border-bottom: 1px solid var(--line);
  text-align: left;
  vertical-align: top;
}
th {
  color: var(--muted);
  font-size: 12px;
  text-transform: uppercase;
}
th[data-sort-key] {
  cursor: pointer;
  user-select: none;
}
th[data-sort-key]:focus-visible {
  outline: 2px solid #1d4ed8;
  outline-offset: 2px;
}
a { color: #1d4ed8; }
@media (max-width: 760px) {
  main { width: min(100% - 20px, 1180px); padding-top: 18px; }
  .panel, .chart-card { padding: 14px; }
  .section-head { display: block; }
  .legend { margin-top: 10px; }
  .chart-head { display: block; }
  .chart-meta { white-space: normal; }
}
''';

const _sortScript = '''
function sortTable(table, columnIndex, type, direction) {
  const body = table.tBodies[0];
  const rows = Array.from(body.rows);
  rows.sort((left, right) => {
    const leftValue = left.cells[columnIndex].dataset.sortValue || left.cells[columnIndex].textContent.trim();
    const rightValue = right.cells[columnIndex].dataset.sortValue || right.cells[columnIndex].textContent.trim();
    if (type === 'number') {
      return (Number(leftValue) - Number(rightValue)) * direction;
    }
    return leftValue.localeCompare(rightValue, undefined, { numeric: true, sensitivity: 'base' }) * direction;
  });
  body.replaceChildren(...rows);
}

document.querySelectorAll('[data-sort-table]').forEach((table) => {
  table.querySelectorAll('th[data-sort-key]').forEach((header, columnIndex) => {
    header.addEventListener('click', () => {
      const current = header.dataset.sortDirection === 'asc' ? 'desc' : 'asc';
      table.querySelectorAll('th[data-sort-key]').forEach((cell) => {
        delete cell.dataset.sortDirection;
      });
      header.dataset.sortDirection = current;
      sortTable(table, columnIndex, header.dataset.sortType || 'text', current === 'asc' ? 1 : -1);
    });
    header.addEventListener('keydown', (event) => {
      if (event.key === 'Enter' || event.key === ' ') {
        event.preventDefault();
        header.click();
      }
    });
  });
});
''';

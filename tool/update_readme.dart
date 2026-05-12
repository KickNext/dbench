import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

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
    'RUN_VISUALIZATION',
    _runVisualization(results, packages),
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
      '| Package | Scope | Latest | Family | Type | Platforms | Transactions | Benchmark status |',
    )
    ..writeln('| --- | --- | ---: | --- | --- | --- | --- | --- |');
  for (final package in packages) {
    table.writeln(
      '| [${package['package']}](https://pub.dev/packages/${package['package']}) '
      '| ${package['scope'] ?? 'primary'} '
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
<summary>Curated package matrix (${_primaryPackageCount(packages)} primary, ${_companionPackageCount(packages)} companion)</summary>

${table.toString().trimRight()}

</details>''';
}

String _family(Map<String, Object?> package) {
  final name = '${package['package']}';
  final type = '${package['type']}'.toLowerCase();
  if (type.contains('sqlite')) {
    return 'SQL';
  }
  if (name == 'hive' || name == 'hive_ce' || name == 'store_box') {
    return 'Key-value';
  }
  return 'NoSQL';
}

String _deviceSpecs(Map<String, Object?> specs) {
  final policy = (specs['resultPolicy'] as Map).cast<String, Object?>();
  final targets = (specs['targets'] as Map).cast<String, Object?>();
  return '''
| Area | Value |
| --- | --- |
| README results | ${policy['readmeResults']} |
| Local results | ${policy['localResults']} |
| Flutter | ${targets['flutter']} |
| Web JS | ${targets['webJs']} |
| Web Wasm | ${targets['webWasm']} |
| Native | ${targets['native']} |''';
}

String _runVisualization(
  List<Map<String, Object?>> reports,
  List<Map<String, Object?>> packages,
) {
  if (reports.isEmpty) {
    return 'No benchmark result JSON files have been generated yet.';
  }

  final environments = reports
      .map((report) => '${report['environment']}')
      .toSet();
  final completedPackages = _completedPackageNames(reports, packages);
  final primaryPackages = _primaryPackageCount(packages);

  final buffer = StringBuffer()
    ..writeln(
      'Open [docs/results.html](docs/results.html) for the visual dashboard with overall ranking, scenario winners, and per-target charts.',
    )
    ..writeln()
    ..writeln(
      'Committed result snapshots currently present: ${environments.map((environment) => '`$environment`').join(', ')}.',
    );
  buffer
    ..writeln()
    ..writeln(
      'Measured curated packages in committed snapshots: ${completedPackages.length} of ${packages.length}. '
      'Primary package targets in scope: $primaryPackages. '
      'The public result set only includes completed scenario measurements.',
    )
    ..writeln()
    ..writeln('### Measurement Snapshot')
    ..writeln()
    ..writeln(
      '| Environment | Measured adapters | Scenario rows | Failed rows |',
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
      '| ${results.length} '
      '| ${_statusCount(results, 'failed')} |',
    );
  }

  buffer
    ..writeln()
    ..writeln('### Overall Ranking')
    ..writeln()
    ..writeln(_overallRankingMarkdown(reports, packages))
    ..writeln()
    ..writeln('### Scenario Winners')
    ..writeln()
    ..writeln(
      '| Environment | Scenario | Fastest SQL/document adapter | Fastest persistent adapter | Completed | Failed |',
    )
    ..writeln('| --- | --- | --- | --- | ---: | ---: |');
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
    '| Environment | Mode | JSON source | Generated | Scenario rows | Measured packages |',
    '| --- | --- | --- | --- | ---: | ---: |',
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
      '| `${report['measurementMode'] ?? 'unknown'}` '
      '| [`results/$environment.json`](results/$environment.json) '
      '| `${report['generatedAt'] ?? 'unknown'}` '
      '| ${results.length} '
      '| $measuredPackages |',
    );
  }
  return '''
The readable dashboard is [docs/results.html](docs/results.html). Raw machine-readable snapshots stay in `results/*.json` instead of being duplicated into README tables.

Measured curated packages across committed snapshots: $completedPackages of ${packages.length}.
Primary package targets in scope: ${_primaryPackageCount(packages)}.

${rows.join('\n')}''';
}

String _scenarioName(Map<String, Object?> result) {
  return '${result['scenario'] ?? 'crud_balanced'}';
}

String _statusSummary(List<Map<String, Object?>> results) {
  final completed = results.where((result) => result['status'] == 'completed');
  final failed = results.where((result) => result['status'] == 'failed');
  return '${completed.length} completed, ${failed.length} failed';
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

int _primaryPackageCount(List<Map<String, Object?>> packages) {
  return packages
      .where((package) => '${package['scope'] ?? 'primary'}' == 'primary')
      .length;
}

int _companionPackageCount(List<Map<String, Object?>> packages) {
  return packages
      .where((package) => '${package['scope'] ?? 'primary'}' == 'companion')
      .length;
}

List<
  ({
    String database,
    String family,
    int appearances,
    double score,
    num averageRate,
  })
>
_overallRankingRows(
  List<Map<String, Object?>> reports,
  List<Map<String, Object?>> packages,
) {
  final scoreByDatabase = <String, double>{};
  final rateByDatabase = <String, num>{};
  final countByDatabase = <String, int>{};

  for (final report in reports) {
    final results = (report['results'] as List).cast<Map<String, Object?>>();
    final scenarioNames = results.map(_scenarioName).toSet().toList()..sort();
    for (final scenarioName in scenarioNames) {
      final completed =
          results
              .where(
                (result) =>
                    _scenarioName(result) == scenarioName &&
                    result['status'] == 'completed' &&
                    result['database'] != 'memory_baseline' &&
                    (result['opsPerSecond'] as num) > 0,
              )
              .toList()
            ..sort(
              (a, b) => (b['opsPerSecond'] as num).compareTo(
                a['opsPerSecond'] as num,
              ),
            );
      if (completed.isEmpty) {
        continue;
      }
      final fastestRate = completed.first['opsPerSecond'] as num;
      for (final result in completed) {
        final database = '${result['database']}';
        final rate = result['opsPerSecond'] as num;
        scoreByDatabase.update(
          database,
          (score) => score + rate / fastestRate * 100,
          ifAbsent: () => rate / fastestRate * 100,
        );
        rateByDatabase.update(
          database,
          (total) => total + rate,
          ifAbsent: () => rate,
        );
        countByDatabase.update(
          database,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }
  }

  final rows =
      <
        ({
          String database,
          String family,
          int appearances,
          double score,
          num averageRate,
        })
      >[];
  for (final entry in scoreByDatabase.entries) {
    final appearances = countByDatabase[entry.key] ?? 1;
    rows.add((
      database: entry.key,
      family: _resultFamily(entry.key, packages),
      appearances: appearances,
      score: entry.value / appearances,
      averageRate: (rateByDatabase[entry.key] ?? 0) / appearances,
    ));
  }
  rows.sort((a, b) {
    final score = b.score.compareTo(a.score);
    return score == 0 ? b.averageRate.compareTo(a.averageRate) : score;
  });
  return rows;
}

String _overallRankingMarkdown(
  List<Map<String, Object?>> reports,
  List<Map<String, Object?>> packages,
) {
  final rows = _overallRankingRows(reports, packages);
  if (rows.isEmpty) {
    return 'No completed persistent adapter measurements are available yet.';
  }
  final table = StringBuffer()
    ..writeln(
      '| Rank | Adapter | Family | Score | Avg ops/sec | Measurements |',
    )
    ..writeln('| ---: | --- | --- | ---: | ---: | ---: |');
  for (var index = 0; index < rows.length && index < 12; index += 1) {
    final row = rows[index];
    table.writeln(
      '| ${index + 1} | `${row.database}` | ${row.family} | ${row.score.toStringAsFixed(1)} | ${_formatRate(row.averageRate)} | ${row.appearances} |',
    );
  }
  return table.toString().trimRight();
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
                    _isSqlOrDocumentFamily(
                      _resultFamily('${result['database']}', packages),
                    )),
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
      if (probe['status'] == 'skipped') {
        continue;
      }
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
  if (database == 'hive' || database == 'hive_ce' || database == 'store_box') {
    return 'Key-value';
  }
  return 'NoSQL';
}

bool _isSqlOrDocumentFamily(String family) {
  return family == 'SQL' || family == 'NoSQL';
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
    ..writeln('<h1>$_productName Results</h1>')
    ..writeln(
      '<p class="lede">Self-contained visual report generated from one local benchmark pass. Persistent adapters are charted separately from the synthetic memory ceiling; chart bars use a log scale so slower adapters remain visually comparable.</p>',
    )
    ..writeln('<dl class="meta">')
    ..writeln('<div><dt>Generated</dt><dd>${_h(generatedAt)}</dd></div>')
    ..writeln('<div><dt>Reports</dt><dd>${reports.length}</dd></div>')
    ..writeln(
      '<div><dt>Primary packages</dt><dd>${_primaryPackageCount(packages)}</dd></div>',
    )
    ..writeln(
      '<div><dt>Result rows</dt><dd>${_completedResultRows(reports)}</dd></div>',
    )
    ..writeln('</dl>')
    ..writeln('</header>');

  if (reports.isEmpty) {
    buffer
      ..writeln('<section class="panel">')
      ..writeln('<h2>No benchmark results yet</h2>')
      ..writeln('<p>Run the benchmark launcher and regenerate this report.</p>')
      ..writeln('</section>');
  } else {
    buffer
      ..writeln('<section class="scoreboard">')
      ..writeln(_heroStats(reports, packages))
      ..writeln('</section>')
      ..writeln('<section class="panel ranking-panel">')
      ..writeln('<div class="section-head compact">')
      ..writeln('<div>')
      ..writeln('<h2>Overall ranking</h2>')
      ..writeln(
        '<p class="note">Score averages each adapter against the fastest persistent adapter in the same environment and scenario. Memory is excluded from the ranking.</p>',
      )
      ..writeln('</div>')
      ..writeln('</div>')
      ..writeln(_overallRankingPanel(reports, packages))
      ..writeln('</section>')
      ..writeln('<section class="panel">')
      ..writeln('<h2>Database-engine winners</h2>')
      ..writeln(
        '<p class="note">This view focuses on SQL and document/object stores; memory is excluded from all persistent rankings.</p>',
      )
      ..writeln(_summaryCards(reports, packages, databaseEnginesOnly: true))
      ..writeln('</section>')
      ..writeln('<section class="panel">')
      ..writeln('<h2>Scenario winners</h2>')
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
    buffer.writeln('</section>');
  }

  buffer
    ..writeln('<section class="panel">')
    ..writeln('<h2>Package Coverage</h2>')
    ..writeln(_packageCoverageTable(packages))
    ..writeln('</section>')
    ..writeln('<section class="panel">')
    ..writeln('<h2>Measurement Contract</h2>')
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

int _completedResultRows(List<Map<String, Object?>> reports) {
  var count = 0;
  for (final report in reports) {
    final results = (report['results'] as List).cast<Map<String, Object?>>();
    count += results.where((result) => result['status'] == 'completed').length;
  }
  return count;
}

String _heroStats(
  List<Map<String, Object?>> reports,
  List<Map<String, Object?>> packages,
) {
  final completedPackages = _completedPackageNames(reports, packages).length;
  final scenarios = <String>{};
  for (final report in reports) {
    final results = (report['results'] as List).cast<Map<String, Object?>>();
    scenarios.addAll(results.map(_scenarioName));
  }
  final rows = _overallRankingRows(reports, packages);
  final leader = rows.isEmpty ? '-' : rows.first.database;
  final leaderScore = rows.isEmpty ? '-' : rows.first.score.toStringAsFixed(1);
  return '''
<article class="stat-card primary-stat">
  <span>Overall leader</span>
  <strong>${_h(leader)}</strong>
  <small>${_h(leaderScore)} normalized score</small>
</article>
<article class="stat-card">
  <span>Measured curated packages</span>
  <strong>$completedPackages</strong>
  <small>present in completed snapshots</small>
</article>
<article class="stat-card">
  <span>Scenarios</span>
  <strong>${scenarios.length}</strong>
  <small>measured per available adapter</small>
</article>
<article class="stat-card">
  <span>Result rows</span>
  <strong>${_completedResultRows(reports)}</strong>
  <small>completed measurements</small>
</article>''';
}

String _overallRankingPanel(
  List<Map<String, Object?>> reports,
  List<Map<String, Object?>> packages,
) {
  final rows = _overallRankingRows(reports, packages);
  if (rows.isEmpty) {
    return '<p class="note">No completed persistent adapter measurements are available yet.</p>';
  }
  final topCards = rows.take(3).toList();
  final cards = <String>[];
  for (var index = 0; index < topCards.length; index += 1) {
    final row = topCards[index];
    cards.add('''
<article class="leader-card rank-${index + 1}">
  <div class="leader-rank">#${index + 1}</div>
  <div>
    <h3>${_h(row.database)}</h3>
    <p>${_h(row.family)}</p>
  </div>
  <strong>${row.score.toStringAsFixed(1)}</strong>
  <small>${_formatRate(row.averageRate)} avg ops/sec across ${row.appearances} rows</small>
</article>''');
  }

  final table = StringBuffer()
    ..writeln('<div class="table-wrap compact-table"><table data-sort-table>')
    ..writeln('<thead><tr>')
    ..writeln(
      '${_sortHeader('Rank', 'number')}${_sortHeader('Adapter', 'text')}${_sortHeader('Family', 'text')}${_sortHeader('Score', 'number')}${_sortHeader('Average ops/sec', 'number')}${_sortHeader('Measurements', 'number')}',
    )
    ..writeln('</tr></thead>')
    ..writeln('<tbody>');
  for (var index = 0; index < rows.length; index += 1) {
    final row = rows[index];
    table
      ..writeln('<tr>')
      ..writeln(_sortCell(index + 1, sortValue: index + 1))
      ..writeln(_sortCell(row.database))
      ..writeln(_sortCell(row.family))
      ..writeln(_sortCell(row.score.toStringAsFixed(1), sortValue: row.score))
      ..writeln(
        _sortCell(_formatRate(row.averageRate), sortValue: row.averageRate),
      )
      ..writeln(_sortCell(row.appearances, sortValue: row.appearances))
      ..writeln('</tr>');
  }
  table
    ..writeln('</tbody>')
    ..writeln('</table></div>');

  return '''
<div class="leader-grid">${cards.join('\n')}</div>
${table.toString()}''';
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
                        _isSqlOrDocumentFamily(
                          _resultFamily('${result['database']}', packages),
                        )),
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
  final failed = scenarioResults
      .where((result) => result['status'] == 'failed')
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
  ${failed.isEmpty ? '' : _statusList(failed)}
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
  <span>${_h('${report['measurementMode'] ?? 'unknown'}')}</span>
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
  <summary>${results.length} failed adapters</summary>
  <ul class="status-list">$items</ul>
</details>''';
}

String _chartLegend() {
  return '''
<div class="legend" aria-label="Chart color legend">
  <span><i style="background:#2563eb"></i>SQL</span>
  <span><i style="background:#047857"></i>NoSQL / document / object</span>
  <span><i style="background:#b45309"></i>Key-value database</span>
</div>''';
}

String _packageCoverageTable(List<Map<String, Object?>> packages) {
  final buffer = StringBuffer()
    ..writeln('<div class="table-wrap"><table data-sort-table>')
    ..writeln('<thead><tr>')
    ..writeln(
      '${_sortHeader('Package', 'text')}${_sortHeader('Scope', 'text')}${_sortHeader('Family', 'text')}${_sortHeader('Platforms', 'text')}${_sortHeader('Status', 'text')}',
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
      ..writeln(_sortCell('${package['scope'] ?? 'primary'}'))
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
  final targets = (specs['targets'] as Map).cast<String, Object?>();
  return '''
<dl class="policy">
  <div><dt>Published source</dt><dd>${_h('${policy['readmeResults']}')}</dd></div>
  <div><dt>Private reruns</dt><dd>${_h('${policy['localResults']}')}</dd></div>
  <div><dt>Completion rule</dt><dd>Every adapter row in a published snapshot is a completed measurement for every workload scenario emitted by that snapshot.</dd></div>
  <div><dt>Mode rule</dt><dd>Published result snapshots must declare a release measurement mode; native desktop results use release AOT.</dd></div>
  <div><dt>Ranking rule</dt><dd>Overall score normalizes each adapter against the fastest persistent adapter inside the same environment and scenario, then averages those percentages.</dd></div>
  <div><dt>Web JS</dt><dd>${_h('${targets['webJs']}')}</dd></div>
  <div><dt>Web Wasm</dt><dd>${_h('${targets['webWasm']}')}</dd></div>
  <div><dt>Native</dt><dd>${_h('${targets['native']}')}</dd></div>
  <div><dt>Flutter</dt><dd>${_h('${targets['flutter']}')}</dd></div>
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
  return '<th data-sort-key="${_h(label.toLowerCase())}" data-sort-type="$type" data-sort-default="none" aria-sort="none" tabindex="0" title="Sort by ${_h(label)}">${_h(label)} <span class="sort-indicator" aria-hidden="true">-</span></th>';
}

String _sortCell(Object display, {Object? sortValue, bool escape = true}) {
  final value = sortValue ?? display;
  final rendered = escape ? _h('$display') : '$display';
  return '<td data-sort-value="${_h('$value')}">$rendered</td>';
}

String _familyColor(String family) {
  return switch (family) {
    'SQL' => '#2563eb',
    'Key-value' => '#b45309',
    _ => '#047857',
  };
}

String _h(String value) => const HtmlEscape().convert(value);

String _u(String value) => Uri.encodeComponent(value);

const _htmlStyles = '''
:root {
  color-scheme: light;
  --ink: #152035;
  --muted: #647087;
  --line: #d9e0ec;
  --panel: #ffffff;
  --panel-soft: #f8fafc;
  --bg: #f3f5f1;
  --track: #e8edf3;
  --accent: #176b5d;
  --accent-2: #b45b38;
  --shadow: 0 18px 48px rgba(43, 54, 76, .10);
}
* { box-sizing: border-box; }
body {
  margin: 0;
  background:
    radial-gradient(circle at 16% 0%, rgba(23, 107, 93, .12), transparent 28rem),
    radial-gradient(circle at 90% 12%, rgba(180, 91, 56, .12), transparent 24rem),
    linear-gradient(180deg, #f8faf7 0%, var(--bg) 42%, #eef2f5 100%);
  color: var(--ink);
  font: 14px/1.5 "Aptos", "Segoe UI", system-ui, sans-serif;
}
main {
  width: min(1280px, calc(100% - 32px));
  margin: 0 auto;
  padding: 34px 0 64px;
}
.hero {
  padding: 34px 0 20px;
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
  max-width: 900px;
  font-size: 56px;
  line-height: 1;
  text-wrap: balance;
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
  text-wrap: pretty;
}
.meta, .policy {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 10px;
  margin: 22px 0 0;
}
.meta div, .policy div {
  padding: 14px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: rgba(255, 255, 255, .78);
  box-shadow: 0 1px 0 rgba(255, 255, 255, .75) inset;
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
  padding: 22px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: rgba(255, 255, 255, .88);
  box-shadow: var(--shadow);
}
.scoreboard {
  display: grid;
  grid-template-columns: 1.4fr repeat(3, 1fr);
  gap: 12px;
  margin: 10px 0 18px;
}
.stat-card {
  min-height: 132px;
  padding: 18px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: rgba(255, 255, 255, .86);
  box-shadow: var(--shadow);
}
.stat-card span, .leader-card small {
  display: block;
  color: var(--muted);
  font-size: 12px;
  font-weight: 750;
  text-transform: uppercase;
}
.stat-card strong {
  display: block;
  margin-top: 10px;
  font-size: 32px;
  line-height: 1.05;
  font-variant-numeric: tabular-nums;
}
.stat-card small {
  color: var(--muted);
}
.primary-stat {
  background: #17342f;
  color: #f7fbf8;
}
.primary-stat span, .primary-stat small { color: #bad6cf; }
.leader-grid {
  display: grid;
  grid-template-columns: 1.2fr 1fr 1fr;
  gap: 12px;
  margin-bottom: 16px;
}
.leader-card {
  display: grid;
  grid-template-columns: auto 1fr;
  gap: 10px 14px;
  align-items: start;
  padding: 16px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: var(--panel-soft);
}
.leader-card strong {
  grid-column: 1 / -1;
  font-size: 30px;
  line-height: 1;
  font-variant-numeric: tabular-nums;
}
.leader-card h3 { margin: 0; }
.leader-card p {
  margin: 2px 0 0;
  color: var(--muted);
}
.leader-rank {
  width: 38px;
  height: 38px;
  display: grid;
  place-items: center;
  border-radius: 8px;
  background: var(--accent);
  color: white;
  font-weight: 800;
}
.rank-1 {
  background: #fff7ed;
  border-color: #f1c9a8;
}
.rank-1 .leader-rank { background: var(--accent-2); }
.compact { margin-top: 0; }
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
  background: var(--panel-soft);
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
th[data-sort-direction="asc"] .sort-indicator::before { content: "^"; }
th[data-sort-direction="desc"] .sort-indicator::before { content: "v"; }
th[data-sort-direction] .sort-indicator {
  font-size: 0;
}
th[data-sort-direction] .sort-indicator::before {
  font-size: 12px;
}
th[data-sort-key]:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
}
a { color: var(--accent); }
@media (max-width: 760px) {
  main { width: min(100% - 20px, 1180px); padding-top: 18px; }
  h1 { font-size: 38px; }
  .panel, .chart-card { padding: 14px; }
  .scoreboard, .leader-grid { grid-template-columns: 1fr; }
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
        cell.setAttribute('aria-sort', 'none');
      });
      header.dataset.sortDirection = current;
      header.setAttribute('aria-sort', current === 'asc' ? 'ascending' : 'descending');
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

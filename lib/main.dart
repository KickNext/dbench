import 'package:flutter/material.dart';

import 'src/adapters/adapter_registry.dart';
import 'src/benchmark/benchmark_runner.dart';
import 'src/benchmark/database_adapter.dart';
import 'src/platform/environment_label.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DatabaseBenchmarksApp());
}

final class DatabaseBenchmarksApp extends StatelessWidget {
  const DatabaseBenchmarksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Database Benchmarks',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff2f6fed),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const BenchmarkHomePage(),
    );
  }
}

final class BenchmarkHomePage extends StatefulWidget {
  const BenchmarkHomePage({super.key});

  @override
  State<BenchmarkHomePage> createState() => _BenchmarkHomePageState();
}

final class _BenchmarkHomePageState extends State<BenchmarkHomePage> {
  BenchmarkReport? _report;
  var _isRunning = false;

  @override
  void initState() {
    super.initState();
    if (const bool.fromEnvironment('DBENCH_AUTORUN')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runBenchmarks();
      });
    }
  }

  Future<void> _runBenchmarks() async {
    setState(() {
      _isRunning = true;
    });

    const records = int.fromEnvironment('DBENCH_RECORDS', defaultValue: 1000);
    const payloadBytes = int.fromEnvironment(
      'DBENCH_PAYLOAD_BYTES',
      defaultValue: 256,
    );
    final runner = BenchmarkRunner(
      workload: const BenchmarkWorkload(
        records: records,
        payloadBytes: payloadBytes,
      ),
      includeIsolateProbes: true,
    );
    final report = await runner.runAll(
      availableAdapters(),
      environment: environmentLabel(),
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _report = report;
      _isRunning = false;
    });
    if (const bool.fromEnvironment('DBENCH_AUTORUN')) {
      // CI and local browser automation scrape this single-line marker.
      // ignore: avoid_print
      print('DBENCH_RESULT_JSON=${report.toCompactJson()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Database Benchmarks')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Dart and Flutter local database benchmark',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text('Target: ${environmentLabel()}'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isRunning ? null : _runBenchmarks,
            child: Text(_isRunning ? 'Running...' : 'Run benchmarks'),
          ),
          const SizedBox(height: 24),
          if (report == null)
            const Text('No benchmark results yet.')
          else
            ..._scenarioSections(context, report),
        ],
      ),
    );
  }

  List<Widget> _scenarioSections(BuildContext context, BenchmarkReport report) {
    final scenarios = report.results.map((result) => result.scenario).toSet();
    return [
      for (final scenario in scenarios) ...[
        _ScenarioResultTable(
          scenario: scenario,
          results:
              report.results
                  .where((result) => result.scenario == scenario)
                  .toList()
                ..sort(_compareResultsForDisplay),
        ),
        const SizedBox(height: 16),
      ],
    ];
  }

  int _compareResultsForDisplay(BenchmarkResult a, BenchmarkResult b) {
    if (a.database == 'memory_baseline' && b.database != 'memory_baseline') {
      return 1;
    }
    if (a.database != 'memory_baseline' && b.database == 'memory_baseline') {
      return -1;
    }
    return b.opsPerSecond.compareTo(a.opsPerSecond);
  }
}

final class _ScenarioResultTable extends StatelessWidget {
  const _ScenarioResultTable({required this.scenario, required this.results});

  final String scenario;
  final List<BenchmarkResult> results;

  @override
  Widget build(BuildContext context) {
    final completed = results.where(
      (result) =>
          result.status == BenchmarkStatus.completed &&
          result.database != 'memory_baseline',
    );
    final maxRate = completed.fold<double>(
      0,
      (max, result) => result.opsPerSecond > max ? result.opsPerSecond : max,
    );
    final description = results.isEmpty
        ? ''
        : results.first.scenarioDescription;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(scenario, style: Theme.of(context).textTheme.titleLarge),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(description),
        ],
        const SizedBox(height: 8),
        Text(_summaryText),
        const SizedBox(height: 8),
        for (var index = 0; index < results.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ResultRow(
              rank: index + 1,
              result: results[index],
              maxRate: maxRate,
            ),
          ),
      ],
    );
  }

  String get _summaryText {
    final completed = results
        .where((result) => result.status == BenchmarkStatus.completed)
        .length;
    final failed = results
        .where((result) => result.status == BenchmarkStatus.failed)
        .length;
    final skipped = results
        .where((result) => result.status == BenchmarkStatus.skipped)
        .length;
    return '$completed completed, $failed failed, $skipped skipped';
  }
}

final class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.rank,
    required this.result,
    required this.maxRate,
  });

  final int rank;
  final BenchmarkResult result;
  final double maxRate;

  @override
  Widget build(BuildContext context) {
    final rate = result.opsPerSecond;
    final fraction = maxRate <= 0 ? 0.0 : (rate / maxRate).clamp(0.0, 1.0);
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = switch (result.status) {
      BenchmarkStatus.completed => colorScheme.primary,
      BenchmarkStatus.skipped => colorScheme.tertiary,
      BenchmarkStatus.failed => colorScheme.error,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: statusColor.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    '#$rank',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: Text(
                    result.database,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('${rate.toStringAsFixed(0)} ops/s'),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(
                  result.status.name,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text('${result.records} records'),
                Text('${result.payloadBytes} bytes'),
                Text('read ${result.readOps}'),
                Text('query ${result.queryOps}'),
                Text('rows ${result.queryRows}'),
                Text('write ${result.writeOps}'),
                Text('update ${result.updateOps}'),
                Text('delete ${result.deleteOps}'),
                Text('verify ${result.verificationOps}'),
              ],
            ),
            if (result.notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(result.notes, style: TextStyle(color: colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'src/adapters/adapter_registry.dart';
import 'src/benchmark/benchmark_runner.dart';
import 'src/benchmark/database_adapter.dart';
import 'src/platform/environment_label.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DbenchApp());
}

final class DbenchApp extends StatelessWidget {
  const DbenchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dbench',
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
      appBar: AppBar(title: const Text('Dbench')),
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
            ...report.results.map((result) {
              final rate = result.opsPerSecond.toStringAsFixed(0);
              return Card(
                child: ListTile(
                  title: Text(result.database),
                  subtitle: Text(
                    '${result.status.name} - ${result.totalOps} ops',
                  ),
                  trailing: Text('$rate ops/s'),
                ),
              );
            }),
        ],
      ),
    );
  }
}

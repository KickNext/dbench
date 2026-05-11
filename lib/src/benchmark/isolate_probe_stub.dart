final class IsolateProbeResult {
  const IsolateProbeResult({
    required this.database,
    required this.status,
    required this.sharedRead,
    required this.notes,
  });

  final String database;
  final String status;
  final bool? sharedRead;
  final String notes;

  Map<String, Object?> toJson() {
    return {
      'database': database,
      'status': status,
      'sharedRead': sharedRead,
      'notes': notes,
    };
  }
}

Future<List<IsolateProbeResult>> runIsolateProbes() async {
  return const [
    IsolateProbeResult(
      database: 'all',
      status: 'skipped',
      sharedRead: null,
      notes: 'Flutter Web does not expose Dart VM isolates for this benchmark.',
    ),
  ];
}

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
  return const [];
}

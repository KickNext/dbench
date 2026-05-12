enum BenchmarkStatus { completed, skipped, failed }

final class BenchmarkWorkload {
  const BenchmarkWorkload({
    this.records = 1000,
    this.payloadBytes = 256,
    this.scenarios = const [],
  });

  final int records;
  final int payloadBytes;
  final List<BenchmarkScenario> scenarios;

  List<BenchmarkScenario> get effectiveScenarios {
    if (scenarios.isNotEmpty) {
      return scenarios;
    }
    return defaultBenchmarkScenarios(
      baseRecords: records,
      basePayloadBytes: payloadBytes,
    );
  }
}

List<BenchmarkScenario> defaultBenchmarkScenarios({
  required int baseRecords,
  required int basePayloadBytes,
}) {
  final smallRecords = baseRecords <= 25
      ? baseRecords
      : (baseRecords / 4).round().clamp(25, baseRecords);
  final stressRecords = baseRecords >= 10000
      ? baseRecords
      : (baseRecords * 2).clamp(baseRecords, 10000);
  return [
    BenchmarkScenario(
      name: 'crud_balanced',
      description: 'Balanced create/read/query/update/delete workload.',
      records: baseRecords,
      payloadBytes: basePayloadBytes,
      pointReadRounds: 1,
      groupQueryRounds: 1,
      updateRounds: 1,
      sampleRuns: 3,
    ),
    BenchmarkScenario(
      name: 'read_heavy',
      description: 'App startup/feed style repeated point reads and filters.',
      records: baseRecords,
      payloadBytes: basePayloadBytes,
      pointReadRounds: 5,
      groupQueryRounds: 3,
      updateRounds: 1,
      sampleRuns: 3,
    ),
    BenchmarkScenario(
      name: 'large_payload',
      description: 'Fewer records with larger JSON-like payloads.',
      records: smallRecords,
      payloadBytes: basePayloadBytes * 16,
      pointReadRounds: 2,
      groupQueryRounds: 1,
      updateRounds: 1,
      sampleRuns: 3,
    ),
    BenchmarkScenario(
      name: 'write_churn_stress',
      description: 'Larger insert/update/delete churn under deterministic IDs.',
      records: stressRecords,
      payloadBytes: basePayloadBytes,
      pointReadRounds: 1,
      groupQueryRounds: 1,
      updateRounds: 3,
      sampleRuns: 3,
    ),
    BenchmarkScenario(
      name: 'batched_transaction',
      description:
          'Balanced CRUD with grouped write phases; transactional adapters use their native write transaction.',
      records: baseRecords,
      payloadBytes: basePayloadBytes,
      pointReadRounds: 1,
      groupQueryRounds: 1,
      updateRounds: 1,
      sampleRuns: 3,
      requiresWriteTransaction: true,
    ),
  ];
}

final class BenchmarkScenario {
  const BenchmarkScenario({
    required this.name,
    required this.description,
    required this.records,
    required this.payloadBytes,
    this.pointReadRounds = 1,
    this.groupQueryRounds = 0,
    this.updateRounds = 1,
    this.sampleRuns = 1,
    this.requiresWriteTransaction = false,
  });

  final String name;
  final String description;
  final int records;
  final int payloadBytes;
  final int pointReadRounds;
  final int groupQueryRounds;
  final int updateRounds;
  final int sampleRuns;
  final bool requiresWriteTransaction;

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'description': description,
      'records': records,
      'payloadBytes': payloadBytes,
      'pointReadRounds': pointReadRounds,
      'groupQueryRounds': groupQueryRounds,
      'updateRounds': updateRounds,
      'sampleRuns': sampleRuns,
      'requiresWriteTransaction': requiresWriteTransaction,
    };
  }
}

final class BenchmarkRecord {
  const BenchmarkRecord({
    required this.id,
    required this.title,
    required this.group,
    required this.value,
    required this.payload,
    required this.updatedAtMicros,
  });

  final int id;
  final String title;
  final String group;
  final int value;
  final String payload;
  final int updatedAtMicros;

  BenchmarkRecord updated() {
    return BenchmarkRecord(
      id: id,
      title: '$title updated',
      group: group,
      value: value + 1,
      payload: payload,
      updatedAtMicros: updatedAtMicros + 1,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'title': title,
      'group': group,
      'value': value,
      'payload': payload,
      'updatedAtMicros': updatedAtMicros,
    };
  }

  static BenchmarkRecord fromJson(Map<dynamic, dynamic> json) {
    return BenchmarkRecord(
      id: json['id'] as int,
      title: json['title'] as String,
      group: json['group'] as String,
      value: json['value'] as int,
      payload: json['payload'] as String,
      updatedAtMicros: json['updatedAtMicros'] as int,
    );
  }
}

abstract interface class DatabaseAdapter {
  String get name;

  Future<bool> get isSupported;

  Future<void> open();

  Future<void> clear();

  Future<void> write(BenchmarkRecord record);

  Future<BenchmarkRecord?> read(int id);

  Future<List<BenchmarkRecord>> readByGroup(String group);

  Future<void> update(BenchmarkRecord record);

  Future<void> delete(int id);

  Future<void> close();
}

abstract interface class TransactionalDatabaseAdapter
    implements DatabaseAdapter {
  Future<T> runWriteTransaction<T>(Future<T> Function() action);
}

final class UnsupportedDatabaseAdapter implements DatabaseAdapter {
  const UnsupportedDatabaseAdapter({required this.name, required this.reason});

  @override
  final String name;

  final String reason;

  @override
  Future<bool> get isSupported async => false;

  @override
  Future<void> open() async {}

  @override
  Future<void> clear() async {}

  @override
  Future<void> write(BenchmarkRecord record) async {}

  @override
  Future<BenchmarkRecord?> read(int id) async => null;

  @override
  Future<List<BenchmarkRecord>> readByGroup(String group) async => const [];

  @override
  Future<void> update(BenchmarkRecord record) async {}

  @override
  Future<void> delete(int id) async {}

  @override
  Future<void> close() async {}
}

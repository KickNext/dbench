enum BenchmarkStatus { completed, skipped, failed }

final class BenchmarkWorkload {
  const BenchmarkWorkload({this.records = 1000, this.payloadBytes = 256});

  final int records;
  final int payloadBytes;
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

  Future<void> update(BenchmarkRecord record);

  Future<void> delete(int id);

  Future<void> close();
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
  Future<void> update(BenchmarkRecord record) async {}

  @override
  Future<void> delete(int id) async {}

  @override
  Future<void> close() async {}
}

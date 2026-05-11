import '../benchmark/database_adapter.dart';

final class MemoryAdapter implements DatabaseAdapter {
  final Map<int, BenchmarkRecord> _records = {};

  @override
  String get name => 'memory_baseline';

  @override
  Future<bool> get isSupported async => true;

  @override
  Future<void> open() async {}

  @override
  Future<void> clear() async {
    _records.clear();
  }

  @override
  Future<void> write(BenchmarkRecord record) async {
    _records[record.id] = record;
  }

  @override
  Future<BenchmarkRecord?> read(int id) async => _records[id];

  @override
  Future<void> update(BenchmarkRecord record) async {
    _records[record.id] = record;
  }

  @override
  Future<void> delete(int id) async {
    _records.remove(id);
  }

  @override
  Future<void> close() async {}
}

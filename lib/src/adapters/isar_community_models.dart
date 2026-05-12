import 'package:isar_community/isar.dart';

part 'isar_community_models.g.dart';

@collection
class IsarCommunityBenchmarkRecord {
  Id id = Isar.autoIncrement;

  late String title;

  @Index()
  late String group;

  late int value;

  late String payload;

  late int updatedAtMicros;
}

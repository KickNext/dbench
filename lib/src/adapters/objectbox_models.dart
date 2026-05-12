import 'package:objectbox/objectbox.dart';

@Entity()
class ObjectBoxBenchmarkRecord {
  ObjectBoxBenchmarkRecord({
    required this.id,
    required this.title,
    required this.group,
    required this.value,
    required this.payload,
    required this.updatedAtMicros,
  });

  @Id(assignable: true)
  int id;

  String title;

  @Index()
  String group;

  int value;

  String payload;

  int updatedAtMicros;
}

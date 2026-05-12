// ignore_for_file: constant_identifier_names, invalid_use_of_protected_member
// ignore_for_file: public_member_api_docs

import 'package:isar_db/isar_db.dart' as isar_db;

final class IsarDbBenchmarkRecord {
  int id = 0;
  late String title;
  late String group;
  late int value;
  late String payload;
  late int updatedAtMicros;
}

const IsarDbBenchmarkRecordSchema = isar_db.IsarGeneratedSchema(
  schema: isar_db.IsarSchema(
    name: r'IsarDbBenchmarkRecord',
    idName: r'id',
    embedded: false,
    properties: [
      isar_db.IsarPropertySchema(name: r'group', type: isar_db.IsarType.string),
      isar_db.IsarPropertySchema(
        name: r'payload',
        type: isar_db.IsarType.string,
      ),
      isar_db.IsarPropertySchema(name: r'title', type: isar_db.IsarType.string),
      isar_db.IsarPropertySchema(
        name: r'updatedAtMicros',
        type: isar_db.IsarType.long,
      ),
      isar_db.IsarPropertySchema(name: r'value', type: isar_db.IsarType.long),
    ],
    indexes: [
      isar_db.IsarIndexSchema(
        name: r'group',
        properties: [r'group'],
        unique: false,
        hash: true,
      ),
    ],
  ),
  converter: isar_db.IsarObjectConverter<int, IsarDbBenchmarkRecord>(
    serialize: _isarDbBenchmarkRecordSerialize,
    deserialize: _isarDbBenchmarkRecordDeserialize,
    deserializeProperty: _isarDbBenchmarkRecordDeserializeProp,
  ),
  embeddedSchemas: [],
);

int _isarDbBenchmarkRecordSerialize(
  isar_db.IsarWriter writer,
  IsarDbBenchmarkRecord object,
) {
  isar_db.IsarCore.writeString(writer, 1, object.group);
  isar_db.IsarCore.writeString(writer, 2, object.payload);
  isar_db.IsarCore.writeString(writer, 3, object.title);
  isar_db.IsarCore.writeLong(writer, 4, object.updatedAtMicros);
  isar_db.IsarCore.writeLong(writer, 5, object.value);
  return object.id;
}

IsarDbBenchmarkRecord _isarDbBenchmarkRecordDeserialize(
  isar_db.IsarReader reader,
) {
  return IsarDbBenchmarkRecord()
    ..id = isar_db.IsarCore.readId(reader)
    ..group = isar_db.IsarCore.readString(reader, 1)!
    ..payload = isar_db.IsarCore.readString(reader, 2)!
    ..title = isar_db.IsarCore.readString(reader, 3)!
    ..updatedAtMicros = isar_db.IsarCore.readLong(reader, 4)
    ..value = isar_db.IsarCore.readLong(reader, 5);
}

Object? _isarDbBenchmarkRecordDeserializeProp(
  isar_db.IsarReader reader,
  int property,
) {
  return switch (property) {
    0 => isar_db.IsarCore.readId(reader),
    1 => isar_db.IsarCore.readString(reader, 1),
    2 => isar_db.IsarCore.readString(reader, 2),
    3 => isar_db.IsarCore.readString(reader, 3),
    4 => isar_db.IsarCore.readLong(reader, 4),
    5 => isar_db.IsarCore.readLong(reader, 5),
    _ => throw ArgumentError('Unknown property with id $property'),
  };
}

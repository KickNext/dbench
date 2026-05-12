// ignore_for_file: constant_identifier_names, invalid_use_of_protected_member
// ignore_for_file: public_member_api_docs

import 'package:isar_plus/isar_plus.dart' as isar_plus;

final class IsarPlusBenchmarkRecord {
  int id = 0;
  late String title;
  late String group;
  late int value;
  late String payload;
  late int updatedAtMicros;
}

const IsarPlusBenchmarkRecordSchema = isar_plus.IsarGeneratedSchema(
  schema: isar_plus.IsarSchema(
    name: r'IsarPlusBenchmarkRecord',
    idName: r'id',
    embedded: false,
    properties: [
      isar_plus.IsarPropertySchema(
        name: r'group',
        type: isar_plus.IsarType.string,
      ),
      isar_plus.IsarPropertySchema(
        name: r'payload',
        type: isar_plus.IsarType.string,
      ),
      isar_plus.IsarPropertySchema(
        name: r'title',
        type: isar_plus.IsarType.string,
      ),
      isar_plus.IsarPropertySchema(
        name: r'updatedAtMicros',
        type: isar_plus.IsarType.long,
      ),
      isar_plus.IsarPropertySchema(
        name: r'value',
        type: isar_plus.IsarType.long,
      ),
    ],
    indexes: [
      isar_plus.IsarIndexSchema(
        name: r'group',
        properties: [r'group'],
        unique: false,
        hash: true,
      ),
    ],
  ),
  converter: isar_plus.IsarObjectConverter<int, IsarPlusBenchmarkRecord>(
    serialize: _isarPlusBenchmarkRecordSerialize,
    deserialize: _isarPlusBenchmarkRecordDeserialize,
    deserializeProperty: _isarPlusBenchmarkRecordDeserializeProp,
  ),
  embeddedSchemas: [],
);

int _isarPlusBenchmarkRecordSerialize(
  isar_plus.IsarWriter writer,
  IsarPlusBenchmarkRecord object,
) {
  isar_plus.IsarCore.writeString(writer, 1, object.group);
  isar_plus.IsarCore.writeString(writer, 2, object.payload);
  isar_plus.IsarCore.writeString(writer, 3, object.title);
  isar_plus.IsarCore.writeLong(writer, 4, object.updatedAtMicros);
  isar_plus.IsarCore.writeLong(writer, 5, object.value);
  return object.id;
}

IsarPlusBenchmarkRecord _isarPlusBenchmarkRecordDeserialize(
  isar_plus.IsarReader reader,
) {
  return IsarPlusBenchmarkRecord()
    ..id = isar_plus.IsarCore.readId(reader)
    ..group = isar_plus.IsarCore.readString(reader, 1)!
    ..payload = isar_plus.IsarCore.readString(reader, 2)!
    ..title = isar_plus.IsarCore.readString(reader, 3)!
    ..updatedAtMicros = isar_plus.IsarCore.readLong(reader, 4)
    ..value = isar_plus.IsarCore.readLong(reader, 5);
}

Object? _isarPlusBenchmarkRecordDeserializeProp(
  isar_plus.IsarReader reader,
  int property,
) {
  return switch (property) {
    0 => isar_plus.IsarCore.readId(reader),
    1 => isar_plus.IsarCore.readString(reader, 1),
    2 => isar_plus.IsarCore.readString(reader, 2),
    3 => isar_plus.IsarCore.readString(reader, 3),
    4 => isar_plus.IsarCore.readLong(reader, 4),
    5 => isar_plus.IsarCore.readLong(reader, 5),
    _ => throw ArgumentError('Unknown property with id $property'),
  };
}

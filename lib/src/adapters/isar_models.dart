// ignore_for_file: constant_identifier_names, invalid_use_of_protected_member
// ignore_for_file: public_member_api_docs

import 'package:isar/isar.dart' as isar;

final class IsarBenchmarkRecord {
  isar.Id id = isar.Isar.autoIncrement;
  late String title;
  late String group;
  late int value;
  late String payload;
  late int updatedAtMicros;
}

const IsarBenchmarkRecordSchema = isar.CollectionSchema(
  name: r'IsarBenchmarkRecord',
  id: -8704294517023669270,
  properties: {
    r'group': isar.PropertySchema(
      id: 0,
      name: r'group',
      type: isar.IsarType.string,
    ),
    r'payload': isar.PropertySchema(
      id: 1,
      name: r'payload',
      type: isar.IsarType.string,
    ),
    r'title': isar.PropertySchema(
      id: 2,
      name: r'title',
      type: isar.IsarType.string,
    ),
    r'updatedAtMicros': isar.PropertySchema(
      id: 3,
      name: r'updatedAtMicros',
      type: isar.IsarType.long,
    ),
    r'value': isar.PropertySchema(
      id: 4,
      name: r'value',
      type: isar.IsarType.long,
    ),
  },
  estimateSize: _isarBenchmarkRecordEstimateSize,
  serialize: _isarBenchmarkRecordSerialize,
  deserialize: _isarBenchmarkRecordDeserialize,
  deserializeProp: _isarBenchmarkRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'group': isar.IndexSchema(
      id: -7980787437430964260,
      name: r'group',
      unique: false,
      replace: false,
      properties: [
        isar.IndexPropertySchema(
          name: r'group',
          type: isar.IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _isarBenchmarkRecordGetId,
  getLinks: _isarBenchmarkRecordGetLinks,
  attach: _isarBenchmarkRecordAttach,
  version: '3.1.0+1',
);

int _isarBenchmarkRecordEstimateSize(
  IsarBenchmarkRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.group.length * 3;
  bytesCount += 3 + object.payload.length * 3;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _isarBenchmarkRecordSerialize(
  IsarBenchmarkRecord object,
  isar.IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.group);
  writer.writeString(offsets[1], object.payload);
  writer.writeString(offsets[2], object.title);
  writer.writeLong(offsets[3], object.updatedAtMicros);
  writer.writeLong(offsets[4], object.value);
}

IsarBenchmarkRecord _isarBenchmarkRecordDeserialize(
  isar.Id id,
  isar.IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  return IsarBenchmarkRecord()
    ..id = id
    ..group = reader.readString(offsets[0])
    ..payload = reader.readString(offsets[1])
    ..title = reader.readString(offsets[2])
    ..updatedAtMicros = reader.readLong(offsets[3])
    ..value = reader.readLong(offsets[4]);
}

P _isarBenchmarkRecordDeserializeProp<P>(
  isar.IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return reader.readString(offset) as P;
    case 1:
      return reader.readString(offset) as P;
    case 2:
      return reader.readString(offset) as P;
    case 3:
      return reader.readLong(offset) as P;
    case 4:
      return reader.readLong(offset) as P;
    default:
      throw isar.IsarError('Unknown property with id $propertyId');
  }
}

isar.Id _isarBenchmarkRecordGetId(IsarBenchmarkRecord object) => object.id;

List<isar.IsarLinkBase<dynamic>> _isarBenchmarkRecordGetLinks(
  IsarBenchmarkRecord object,
) {
  return const [];
}

void _isarBenchmarkRecordAttach(
  isar.IsarCollection<dynamic> collection,
  isar.Id id,
  IsarBenchmarkRecord object,
) {
  object.id = id;
}

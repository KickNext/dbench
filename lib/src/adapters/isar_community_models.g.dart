// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_community_models.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIsarCommunityBenchmarkRecordCollection on Isar {
  IsarCollection<IsarCommunityBenchmarkRecord>
  get isarCommunityBenchmarkRecords => this.collection();
}

const IsarCommunityBenchmarkRecordSchema = CollectionSchema(
  name: r'IsarCommunityBenchmarkRecord',
  id: 3709736444824832794,
  properties: {
    r'group': PropertySchema(id: 0, name: r'group', type: IsarType.string),
    r'payload': PropertySchema(id: 1, name: r'payload', type: IsarType.string),
    r'title': PropertySchema(id: 2, name: r'title', type: IsarType.string),
    r'updatedAtMicros': PropertySchema(
      id: 3,
      name: r'updatedAtMicros',
      type: IsarType.long,
    ),
    r'value': PropertySchema(id: 4, name: r'value', type: IsarType.long),
  },

  estimateSize: _isarCommunityBenchmarkRecordEstimateSize,
  serialize: _isarCommunityBenchmarkRecordSerialize,
  deserialize: _isarCommunityBenchmarkRecordDeserialize,
  deserializeProp: _isarCommunityBenchmarkRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'group': IndexSchema(
      id: -7980787437430964260,
      name: r'group',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'group',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _isarCommunityBenchmarkRecordGetId,
  getLinks: _isarCommunityBenchmarkRecordGetLinks,
  attach: _isarCommunityBenchmarkRecordAttach,
  version: '3.3.2',
);

int _isarCommunityBenchmarkRecordEstimateSize(
  IsarCommunityBenchmarkRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.group.length * 3;
  bytesCount += 3 + object.payload.length * 3;
  bytesCount += 3 + object.title.length * 3;
  return bytesCount;
}

void _isarCommunityBenchmarkRecordSerialize(
  IsarCommunityBenchmarkRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.group);
  writer.writeString(offsets[1], object.payload);
  writer.writeString(offsets[2], object.title);
  writer.writeLong(offsets[3], object.updatedAtMicros);
  writer.writeLong(offsets[4], object.value);
}

IsarCommunityBenchmarkRecord _isarCommunityBenchmarkRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IsarCommunityBenchmarkRecord();
  object.group = reader.readString(offsets[0]);
  object.id = id;
  object.payload = reader.readString(offsets[1]);
  object.title = reader.readString(offsets[2]);
  object.updatedAtMicros = reader.readLong(offsets[3]);
  object.value = reader.readLong(offsets[4]);
  return object;
}

P _isarCommunityBenchmarkRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _isarCommunityBenchmarkRecordGetId(IsarCommunityBenchmarkRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _isarCommunityBenchmarkRecordGetLinks(
  IsarCommunityBenchmarkRecord object,
) {
  return [];
}

void _isarCommunityBenchmarkRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  IsarCommunityBenchmarkRecord object,
) {
  object.id = id;
}

extension IsarCommunityBenchmarkRecordQueryWhereSort
    on
        QueryBuilder<
          IsarCommunityBenchmarkRecord,
          IsarCommunityBenchmarkRecord,
          QWhere
        > {
  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterWhere
  >
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IsarCommunityBenchmarkRecordQueryWhere
    on
        QueryBuilder<
          IsarCommunityBenchmarkRecord,
          IsarCommunityBenchmarkRecord,
          QWhereClause
        > {
  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterWhereClause
  >
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterWhereClause
  >
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterWhereClause
  >
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterWhereClause
  >
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterWhereClause
  >
  groupEqualTo(String group) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'group', value: [group]),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterWhereClause
  >
  groupNotEqualTo(String group) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'group',
                lower: [],
                upper: [group],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'group',
                lower: [group],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'group',
                lower: [group],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'group',
                lower: [],
                upper: [group],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension IsarCommunityBenchmarkRecordQueryFilter
    on
        QueryBuilder<
          IsarCommunityBenchmarkRecord,
          IsarCommunityBenchmarkRecord,
          QFilterCondition
        > {
  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  groupEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'group',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  groupGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'group',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  groupLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'group',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  groupBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'group',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  groupStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'group',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  groupEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'group',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  groupContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'group',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  groupMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'group',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  groupIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'group', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  groupIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'group', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  payloadEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'payload',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  payloadGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'payload',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  payloadLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'payload',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  payloadBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'payload',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  payloadStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'payload',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  payloadEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'payload',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  payloadContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'payload',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  payloadMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'payload',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  payloadIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'payload', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  payloadIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'payload', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  titleEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'title',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  titleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  titleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'title',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  updatedAtMicrosEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAtMicros', value: value),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  updatedAtMicrosGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAtMicros',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  updatedAtMicrosLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAtMicros',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  updatedAtMicrosBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAtMicros',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  valueEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'value', value: value),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  valueGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'value',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  valueLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'value',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterFilterCondition
  >
  valueBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'value',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension IsarCommunityBenchmarkRecordQueryObject
    on
        QueryBuilder<
          IsarCommunityBenchmarkRecord,
          IsarCommunityBenchmarkRecord,
          QFilterCondition
        > {}

extension IsarCommunityBenchmarkRecordQueryLinks
    on
        QueryBuilder<
          IsarCommunityBenchmarkRecord,
          IsarCommunityBenchmarkRecord,
          QFilterCondition
        > {}

extension IsarCommunityBenchmarkRecordQuerySortBy
    on
        QueryBuilder<
          IsarCommunityBenchmarkRecord,
          IsarCommunityBenchmarkRecord,
          QSortBy
        > {
  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterSortBy
  >
  sortByGroup() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'group', Sort.asc);
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterSortBy
  >
  sortByGroupDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'group', Sort.desc);
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterSortBy
  >
  sortByPayload() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.asc);
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterSortBy
  >
  sortByPayloadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.desc);
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterSortBy
  >
  sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterSortBy
  >
  sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterSortBy
  >
  sortByUpdatedAtMicros() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMicros', Sort.asc);
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterSortBy
  >
  sortByUpdatedAtMicrosDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMicros', Sort.desc);
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterSortBy
  >
  sortByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.asc);
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterSortBy
  >
  sortByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.desc);
    });
  }
}

extension IsarCommunityBenchmarkRecordQuerySortThenBy
    on
        QueryBuilder<
          IsarCommunityBenchmarkRecord,
          IsarCommunityBenchmarkRecord,
          QSortThenBy
        > {
  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterSortBy
  >
  thenByGroup() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'group', Sort.asc);
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterSortBy
  >
  thenByGroupDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'group', Sort.desc);
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterSortBy
  >
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterSortBy
  >
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterSortBy
  >
  thenByPayload() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.asc);
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterSortBy
  >
  thenByPayloadDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payload', Sort.desc);
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterSortBy
  >
  thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterSortBy
  >
  thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterSortBy
  >
  thenByUpdatedAtMicros() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMicros', Sort.asc);
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterSortBy
  >
  thenByUpdatedAtMicrosDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAtMicros', Sort.desc);
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterSortBy
  >
  thenByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.asc);
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QAfterSortBy
  >
  thenByValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'value', Sort.desc);
    });
  }
}

extension IsarCommunityBenchmarkRecordQueryWhereDistinct
    on
        QueryBuilder<
          IsarCommunityBenchmarkRecord,
          IsarCommunityBenchmarkRecord,
          QDistinct
        > {
  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QDistinct
  >
  distinctByGroup({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'group', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QDistinct
  >
  distinctByPayload({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payload', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QDistinct
  >
  distinctByTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QDistinct
  >
  distinctByUpdatedAtMicros() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAtMicros');
    });
  }

  QueryBuilder<
    IsarCommunityBenchmarkRecord,
    IsarCommunityBenchmarkRecord,
    QDistinct
  >
  distinctByValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'value');
    });
  }
}

extension IsarCommunityBenchmarkRecordQueryProperty
    on
        QueryBuilder<
          IsarCommunityBenchmarkRecord,
          IsarCommunityBenchmarkRecord,
          QQueryProperty
        > {
  QueryBuilder<IsarCommunityBenchmarkRecord, int, QQueryOperations>
  idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IsarCommunityBenchmarkRecord, String, QQueryOperations>
  groupProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'group');
    });
  }

  QueryBuilder<IsarCommunityBenchmarkRecord, String, QQueryOperations>
  payloadProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payload');
    });
  }

  QueryBuilder<IsarCommunityBenchmarkRecord, String, QQueryOperations>
  titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<IsarCommunityBenchmarkRecord, int, QQueryOperations>
  updatedAtMicrosProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAtMicros');
    });
  }

  QueryBuilder<IsarCommunityBenchmarkRecord, int, QQueryOperations>
  valueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'value');
    });
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress.dart';

// ignore_for_file: type=lint
class $ProgressEntriesTable extends ProgressEntries
    with TableInfo<$ProgressEntriesTable, ProgressEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgressEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _requirementIdMeta = const VerificationMeta(
    'requirementId',
  );
  @override
  late final GeneratedColumn<String> requirementId = GeneratedColumn<String>(
    'requirement_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checkedMeta = const VerificationMeta(
    'checked',
  );
  @override
  late final GeneratedColumn<bool> checked = GeneratedColumn<bool>(
    'checked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("checked" IN (0, 1))',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    documentId,
    requirementId,
    checked,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'progress_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProgressEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('requirement_id')) {
      context.handle(
        _requirementIdMeta,
        requirementId.isAcceptableOrUnknown(
          data['requirement_id']!,
          _requirementIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requirementIdMeta);
    }
    if (data.containsKey('checked')) {
      context.handle(
        _checkedMeta,
        checked.isAcceptableOrUnknown(data['checked']!, _checkedMeta),
      );
    } else if (isInserting) {
      context.missing(_checkedMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId, requirementId};
  @override
  ProgressEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgressEntry(
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      requirementId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}requirement_id'],
      )!,
      checked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}checked'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProgressEntriesTable createAlias(String alias) {
    return $ProgressEntriesTable(attachedDatabase, alias);
  }
}

class ProgressEntry extends DataClass implements Insertable<ProgressEntry> {
  final String documentId;
  final String requirementId;
  final bool checked;
  final int updatedAt;
  const ProgressEntry({
    required this.documentId,
    required this.requirementId,
    required this.checked,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<String>(documentId);
    map['requirement_id'] = Variable<String>(requirementId);
    map['checked'] = Variable<bool>(checked);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ProgressEntriesCompanion toCompanion(bool nullToAbsent) {
    return ProgressEntriesCompanion(
      documentId: Value(documentId),
      requirementId: Value(requirementId),
      checked: Value(checked),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProgressEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgressEntry(
      documentId: serializer.fromJson<String>(json['documentId']),
      requirementId: serializer.fromJson<String>(json['requirementId']),
      checked: serializer.fromJson<bool>(json['checked']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentId': serializer.toJson<String>(documentId),
      'requirementId': serializer.toJson<String>(requirementId),
      'checked': serializer.toJson<bool>(checked),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ProgressEntry copyWith({
    String? documentId,
    String? requirementId,
    bool? checked,
    int? updatedAt,
  }) => ProgressEntry(
    documentId: documentId ?? this.documentId,
    requirementId: requirementId ?? this.requirementId,
    checked: checked ?? this.checked,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProgressEntry copyWithCompanion(ProgressEntriesCompanion data) {
    return ProgressEntry(
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      requirementId: data.requirementId.present
          ? data.requirementId.value
          : this.requirementId,
      checked: data.checked.present ? data.checked.value : this.checked,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgressEntry(')
          ..write('documentId: $documentId, ')
          ..write('requirementId: $requirementId, ')
          ..write('checked: $checked, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(documentId, requirementId, checked, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgressEntry &&
          other.documentId == this.documentId &&
          other.requirementId == this.requirementId &&
          other.checked == this.checked &&
          other.updatedAt == this.updatedAt);
}

class ProgressEntriesCompanion extends UpdateCompanion<ProgressEntry> {
  final Value<String> documentId;
  final Value<String> requirementId;
  final Value<bool> checked;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const ProgressEntriesCompanion({
    this.documentId = const Value.absent(),
    this.requirementId = const Value.absent(),
    this.checked = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProgressEntriesCompanion.insert({
    required String documentId,
    required String requirementId,
    required bool checked,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : documentId = Value(documentId),
       requirementId = Value(requirementId),
       checked = Value(checked),
       updatedAt = Value(updatedAt);
  static Insertable<ProgressEntry> custom({
    Expression<String>? documentId,
    Expression<String>? requirementId,
    Expression<bool>? checked,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
      if (requirementId != null) 'requirement_id': requirementId,
      if (checked != null) 'checked': checked,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProgressEntriesCompanion copyWith({
    Value<String>? documentId,
    Value<String>? requirementId,
    Value<bool>? checked,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProgressEntriesCompanion(
      documentId: documentId ?? this.documentId,
      requirementId: requirementId ?? this.requirementId,
      checked: checked ?? this.checked,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (requirementId.present) {
      map['requirement_id'] = Variable<String>(requirementId.value);
    }
    if (checked.present) {
      map['checked'] = Variable<bool>(checked.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgressEntriesCompanion(')
          ..write('documentId: $documentId, ')
          ..write('requirementId: $requirementId, ')
          ..write('checked: $checked, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$KumpletoDb extends GeneratedDatabase {
  _$KumpletoDb(QueryExecutor e) : super(e);
  $KumpletoDbManager get managers => $KumpletoDbManager(this);
  late final $ProgressEntriesTable progressEntries = $ProgressEntriesTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [progressEntries];
}

typedef $$ProgressEntriesTableCreateCompanionBuilder =
    ProgressEntriesCompanion Function({
      required String documentId,
      required String requirementId,
      required bool checked,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$ProgressEntriesTableUpdateCompanionBuilder =
    ProgressEntriesCompanion Function({
      Value<String> documentId,
      Value<String> requirementId,
      Value<bool> checked,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$ProgressEntriesTableFilterComposer
    extends Composer<_$KumpletoDb, $ProgressEntriesTable> {
  $$ProgressEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requirementId => $composableBuilder(
    column: $table.requirementId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get checked => $composableBuilder(
    column: $table.checked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProgressEntriesTableOrderingComposer
    extends Composer<_$KumpletoDb, $ProgressEntriesTable> {
  $$ProgressEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requirementId => $composableBuilder(
    column: $table.requirementId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get checked => $composableBuilder(
    column: $table.checked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProgressEntriesTableAnnotationComposer
    extends Composer<_$KumpletoDb, $ProgressEntriesTable> {
  $$ProgressEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get requirementId => $composableBuilder(
    column: $table.requirementId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get checked =>
      $composableBuilder(column: $table.checked, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProgressEntriesTableTableManager
    extends
        RootTableManager<
          _$KumpletoDb,
          $ProgressEntriesTable,
          ProgressEntry,
          $$ProgressEntriesTableFilterComposer,
          $$ProgressEntriesTableOrderingComposer,
          $$ProgressEntriesTableAnnotationComposer,
          $$ProgressEntriesTableCreateCompanionBuilder,
          $$ProgressEntriesTableUpdateCompanionBuilder,
          (
            ProgressEntry,
            BaseReferences<_$KumpletoDb, $ProgressEntriesTable, ProgressEntry>,
          ),
          ProgressEntry,
          PrefetchHooks Function()
        > {
  $$ProgressEntriesTableTableManager(
    _$KumpletoDb db,
    $ProgressEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgressEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgressEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgressEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> documentId = const Value.absent(),
                Value<String> requirementId = const Value.absent(),
                Value<bool> checked = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProgressEntriesCompanion(
                documentId: documentId,
                requirementId: requirementId,
                checked: checked,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String documentId,
                required String requirementId,
                required bool checked,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProgressEntriesCompanion.insert(
                documentId: documentId,
                requirementId: requirementId,
                checked: checked,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProgressEntriesTable, ProgressEntry>(table),
                  BaseReferences<
                    _$KumpletoDb,
                    $ProgressEntriesTable,
                    ProgressEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProgressEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$KumpletoDb,
      $ProgressEntriesTable,
      ProgressEntry,
      $$ProgressEntriesTableFilterComposer,
      $$ProgressEntriesTableOrderingComposer,
      $$ProgressEntriesTableAnnotationComposer,
      $$ProgressEntriesTableCreateCompanionBuilder,
      $$ProgressEntriesTableUpdateCompanionBuilder,
      (
        ProgressEntry,
        BaseReferences<_$KumpletoDb, $ProgressEntriesTable, ProgressEntry>,
      ),
      ProgressEntry,
      PrefetchHooks Function()
    >;

class $KumpletoDbManager {
  final _$KumpletoDb _db;
  $KumpletoDbManager(this._db);
  $$ProgressEntriesTableTableManager get progressEntries =>
      $$ProgressEntriesTableTableManager(_db, _db.progressEntries);
}

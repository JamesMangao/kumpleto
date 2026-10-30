import 'package:drift/drift.dart';

part 'progress.g.dart';

/// One ticked (or explicitly unticked) checklist row.
///
/// Only rows that differ from the default are stored: a requirement with no
/// row is simply unchecked. The composite primary key keeps the table
/// idempotent and lets progress be pruned when data changes.
class ProgressEntries extends Table {
  TextColumn get documentId => text()();
  TextColumn get requirementId => text()();
  BoolColumn get checked => boolean()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {documentId, requirementId};
}

@DriftDatabase(tables: [ProgressEntries])
class KumpletoDb extends _$KumpletoDb {
  KumpletoDb(super.executor);

  @override
  int get schemaVersion => 1;
}
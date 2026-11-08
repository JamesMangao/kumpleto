import 'package:drift/drift.dart';

part 'progress.g.dart';

/// One ticked (or explicitly unticked) checklist row, for one person.
///
/// Only rows that differ from the default are stored: a requirement with no
/// row is simply unchecked. The composite primary key keeps the table
/// idempotent and lets progress be pruned when data changes.
class ProgressEntries extends Table {
  /// Which person this row belongs to.
  ///
  /// Households chase documents for more than one person, so progress is keyed
  /// per profile: the same requirement can be ticked for "me" and untouched for
  /// a profile added for a spouse. Rows written before profiles existed belong
  /// to [defaultProfileId].
  TextColumn get profileId => text().withDefault(const Constant('me'))();

  TextColumn get documentId => text()();
  TextColumn get requirementId => text()();
  BoolColumn get checked => boolean()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {profileId, documentId, requirementId};
}

@DriftDatabase(tables: [ProgressEntries])
class KumpletoDb extends _$KumpletoDb {
  KumpletoDb(super.executor);

  /// v2 added `profile_id` to the primary key, which SQLite cannot do in place;
  /// the migration rebuilds the table and carries the old rows over as "me".
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.alterTable(TableMigration(progressEntries));
      }
    },
  );
}

import 'package:drift/drift.dart';

import 'progress.dart';

/// Reads and writes checklist progress.
///
/// Stored as `documentId → {requirementId, …}` for the checked rows, which is
/// what the UI needs to render a checklist and a progress bar.
class ProgressRepository {
  ProgressRepository(this._db);

  final KumpletoDb _db;

  /// Emits on every change (drift watches the table).
  Stream<Map<String, Set<String>>> watchAll() {
    final query = _db.select(_db.progressEntries)
      ..where((row) => row.checked.equals(true));
    return query.watch().map(_group);
  }

  Future<void> setChecked(
    String documentId,
    String requirementId,
    bool checked,
  ) {
    return _db
        .into(_db.progressEntries)
        .insertOnConflictUpdate(
          ProgressEntriesCompanion.insert(
            documentId: documentId,
            requirementId: requirementId,
            checked: checked,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> resetDocument(String documentId) {
    final statement = _db.delete(_db.progressEntries)
      ..where((row) => row.documentId.equals(documentId));
    return statement.go();
  }

  Future<void> resetAll() => _db.delete(_db.progressEntries).go();

  /// Deletes rows whose document or requirement no longer exists in the loaded
  /// data (a document can be renamed or withdrawn between data versions).
  /// Returns the number of rows removed.
  Future<int> pruneOrphans(Set<String> validPairs) async {
    final rows = await _db.select(_db.progressEntries).get();
    final orphans = [
      for (final row in rows)
        if (!validPairs.contains('${row.documentId}/${row.requirementId}')) row,
    ];
    if (orphans.isEmpty) return 0;
    await _db.transaction(() async {
      for (final row in orphans) {
        await (_db.delete(_db.progressEntries)..where(
              (entry) =>
                  entry.documentId.equals(row.documentId) &
                  entry.requirementId.equals(row.requirementId),
            ))
            .go();
      }
    });
    return orphans.length;
  }

  Map<String, Set<String>> _group(List<ProgressEntry> rows) {
    final grouped = <String, Set<String>>{};
    for (final row in rows) {
      grouped.putIfAbsent(row.documentId, () => <String>{}).add(row.requirementId);
    }
    return grouped;
  }
}
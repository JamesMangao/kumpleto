import 'package:drift/drift.dart';

import 'progress.dart';

/// Reads and writes checklist progress.
///
/// Stored as `documentId → {requirementId, …}` for the checked rows, which is
/// what the UI needs to render a checklist and a progress bar.
class ProgressRepository {
  ProgressRepository(this._db);

  /// The requirement id that stands for "the whole document is in hand".
  ///
  /// It is not a real requirement, so nothing renders a row for it; its
  /// `updatedAt` is when the reader said they already had the document, which
  /// is what validity counts from.
  static const String acquiredRowId = '__acquired__';

  final KumpletoDb _db;

  /// Emits on every change (drift watches the table).
  Stream<Map<String, Set<String>>> watchAll() {
    final query = _db.select(_db.progressEntries)
      ..where((row) => row.checked.equals(true));
    return query.watch().map(_group);
  }

  /// When each document was marked as acquired, keyed by document id.
  ///
  /// Documents acquired by ticking every requirement have no acquired row and
  /// so no date — validity is only shown when the day is actually known.
  Stream<Map<String, DateTime>> watchAcquiredDates() {
    final query = _db.select(_db.progressEntries)
      ..where((row) => row.requirementId.equals(acquiredRowId));
    return query.watch().map(
      (rows) => {
        for (final row in rows)
          if (row.checked)
            row.documentId: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
      },
    );
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

  /// Marks an entire document as acquired (ticks all requirements + stores an
  /// acquired marker).
  Future<void> markDocumentAcquired(
    String documentId,
    Iterable<String> requirementIds,
  ) async {
    await _db.transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final reqId in requirementIds) {
        await _db.into(_db.progressEntries).insertOnConflictUpdate(
              ProgressEntriesCompanion.insert(
                documentId: documentId,
                requirementId: reqId,
                checked: true,
                updatedAt: now,
              ),
            );
      }
      await _db.into(_db.progressEntries).insertOnConflictUpdate(
            ProgressEntriesCompanion.insert(
              documentId: documentId,
              requirementId: acquiredRowId,
              checked: true,
              updatedAt: now,
            ),
          );
    });
  }

  /// Clears the acquired status and unchecks all requirements for [documentId].
  Future<void> unmarkDocumentAcquired(String documentId) =>
      resetDocument(documentId);

  Future<void> resetAll() => _db.delete(_db.progressEntries).go();

  /// Deletes rows whose document or requirement no longer exists in the loaded
  /// data (a document can be renamed or withdrawn between data versions).
  /// Returns the number of rows removed.
  Future<int> pruneOrphans(Set<String> validPairs) async {
    final rows = await _db.select(_db.progressEntries).get();
    final orphans = [
      for (final row in rows)
        if (row.requirementId != acquiredRowId &&
            !validPairs.contains('${row.documentId}/${row.requirementId}'))
          row,
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
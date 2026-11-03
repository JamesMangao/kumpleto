import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../models/models.dart';
import 'app_paths.dart';
import 'data_repository.dart';
import 'location.dart';
import 'place_tokens.dart';
import 'progress.dart';
import 'progress_repository.dart';
import 'update_service.dart';

/// Device paths — overridden in `main()` once resolved.
final Provider<AppPaths> appPathsProvider = Provider<AppPaths>(
  (ref) => throw UnimplementedError('appPathsProvider must be overridden'),
);

/// Open progress database — overridden in `main()` (also closed there).
final Provider<KumpletoDb> kumpletoDbProvider = Provider<KumpletoDb>(
  (ref) => throw UnimplementedError('kumpletoDbProvider must be overridden'),
);

/// SharedPreferences — overridden in `main()` once loaded.
final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>(
      (ref) => throw UnimplementedError(
        'sharedPreferencesProvider must be overridden',
      ),
    );

final Provider<UpdateService> updateServiceProvider = Provider<UpdateService>(
  (ref) => UpdateService(
    client: http.Client(),
    url: Uri.parse(dataUrl),
    prefs: ref.watch(sharedPreferencesProvider),
    repository: ref.watch(dataRepositoryProvider),
  ),
);

/// Silent feed refresh, at most once every 24 h (docs/DECISIONS.md, P2).
///
/// Started by `main()` after the first frame and never awaited by the UI:
/// a failure is a value, and an accepted payload invalidates the loaded
/// data so every consumer rebuilds from the fresher copy.
final FutureProvider<UpdateResult?> scheduledUpdateProvider =
    FutureProvider<UpdateResult?>((ref) async {
      final result = await ref.watch(updateServiceProvider).maybeCheck();
      if (result is UpdateAccepted) ref.invalidate(loadedDataProvider);
      return result;
    });

final Provider<DataRepository> dataRepositoryProvider =
    Provider<DataRepository>(
      (ref) => DataRepository(paths: ref.watch(appPathsProvider)),
    );

/// The loaded dataset (bundled asset, or a newer verified cache).
final FutureProvider<LoadedData> loadedDataProvider = FutureProvider<LoadedData>(
  (ref) => ref.watch(dataRepositoryProvider).load(),
);

/// The place chosen in Settings → My location, live for the session.
///
/// Saved to SharedPreferences by the location screen; held here as well so the
/// document text that depends on it rebuilds the moment it changes.
class SavedLocationNotifier extends Notifier<SavedLocation?> {
  @override
  SavedLocation? build() =>
      SavedLocation.read(ref.watch(sharedPreferencesProvider));

  void set(SavedLocation? value) => state = value;
}

final NotifierProvider<SavedLocationNotifier, SavedLocation?>
savedLocationProvider = NotifierProvider<SavedLocationNotifier, SavedLocation?>(
  SavedLocationNotifier.new,
);

/// Convenience view of the loaded dataset for widgets.
///
/// Place placeholders (`{{barangay}}`, `{{city}}`, `{{address}}`) are resolved
/// here, once, so every screen already reading the bundle shows the user's own
/// barangay without a second lookup.
final Provider<AsyncValue<DataBundle>> dataBundleProvider =
    Provider<AsyncValue<DataBundle>>((ref) {
      final tokens = PlaceTokens.of(ref.watch(savedLocationProvider));
      return ref
          .watch(loadedDataProvider)
          .whenData((loaded) => loaded.data.filled(tokens.values));
    });

final Provider<ProgressRepository> progressRepositoryProvider =
    Provider<ProgressRepository>(
      (ref) => ProgressRepository(ref.watch(kumpletoDbProvider)),
    );

/// `documentId → checked requirement ids`, live from the database.
final StreamProvider<Map<String, Set<String>>> progressProvider =
    StreamProvider<Map<String, Set<String>>>(
      (ref) => ref.watch(progressRepositoryProvider).watchAll(),
    );

/// All documents, name-sorted for the list screen.
final Provider<List<Document>> documentsProvider = Provider<List<Document>>((
  ref,
) {
  final data = ref.watch(dataBundleProvider).value;
  if (data == null) return const <Document>[];
  final documents = [...data.documents]
    ..sort((a, b) => a.name.en.toLowerCase().compareTo(b.name.en.toLowerCase()));
  return documents;
});

/// All bundles, name-sorted.
final Provider<List<Bundle>> bundlesProvider = Provider<List<Bundle>>((ref) {
  final data = ref.watch(dataBundleProvider).value;
  if (data == null) return const <Bundle>[];
  final bundles = [...data.bundles]
    ..sort((a, b) => a.name.en.toLowerCase().compareTo(b.name.en.toLowerCase()));
  return bundles;
});

/// The loaded dataset itself (null while loading or on failure).
final Provider<DataBundle?> currentDataProvider = Provider<DataBundle?>(
  (ref) => ref.watch(dataBundleProvider).value,
);

const String acquiredSentinel = '__acquired__';

/// Checked requirement ids for one document (empty when untouched).
Set<String> checkedFor(WidgetRef ref, String documentId) =>
    ref.watch(progressProvider).value?[documentId] ?? const <String>{};

/// Returns true if the user marked this document as already acquired,
/// or if all its requirements are checked.
bool isDocumentAcquired(Document document, Set<String> checkedIds) {
  if (checkedIds.contains(acquiredSentinel)) return true;
  if (document.requirements.isNotEmpty &&
      document.requirements.every((r) => checkedIds.contains(r.id))) {
    return true;
  }
  return false;
}

/// How many of [document]'s requirements are ticked.
int checkedCount(Document document, Set<String> checkedIds) =>
    document.requirements.where((r) => checkedIds.contains(r.id)).length;

/// Overall bundle progress: ticked requirements across its documents.
({int checked, int total}) bundleProgress({
  required List<Document> documents,
  required Map<String, Set<String>> progress,
}) {
  var checked = 0;
  var total = 0;
  for (final document in documents) {
    total += document.requirements.length;
    checked += checkedCount(document, progress[document.id] ?? const <String>{});
  }
  return (checked: checked, total: total);
}
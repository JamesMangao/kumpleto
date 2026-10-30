/// Single source of truth for repo/network/app identity constants.
///
/// To move the project to another owner or host, change these four values
/// (and the matching GitHub Pages configuration).
library;

/// GitHub repository owner (case as shown on GitHub).
const String repoOwner = 'JamesMangao';

/// GitHub repository name (kebab-case, matches applicationId last segment).
const String repoName = 'kumpleto';

/// Public URL of the compiled, release-safe data bundle (no drafts).
/// Served by GitHub Pages from `dist/data.json` (see .github/workflows/pages-data.yml).
const String dataUrl = 'https://jamesmangao.github.io/kumpleto/data.json';

/// Highest `schema_version` this app knows how to read.
/// Data with a greater schema_version is ignored (kept: current data).
const int supportedSchemaVersion = 1;

/// Android applicationId (also the basis of the Play listing identity).
const String applicationId = 'io.github.jamesmangao.kumpleto';

/// Display name used for the launcher label and Play listing.
const String appDisplayName = 'Kumpleto';

/// Network limits for the data update flow (see docs/DECISIONS.md, P2).
const Duration dataFetchTimeout = Duration(seconds: 10);

/// Minimum spacing between *automatic* feed checks (Settings can check
/// manually at any time).
const Duration dataCheckInterval = Duration(hours: 24);
const int dataFetchMaxBytes = 2 * 1024 * 1024; // 2 MB
const int dataFetchMaxRedirects = 3;

/// GitHub "report outdated info" issue URL builder.
Uri reportOutdatedUri({
  required String documentId,
  required String documentName,
  required String appVersion,
  required String dataVersion,
}) {
  return Uri.https('github.com', '/$repoOwner/$repoName/issues/new', {
    'template': 'outdated-info.yml',
    'title': 'Outdated: $documentName',
    'labels': 'outdated-info',
    'fields': [
      'document_id=$documentId',
      'app_version=$appVersion',
      'data_version=$dataVersion',
    ].join(','),
  });
}

/// GitHub repository link (Settings "view on GitHub").
Uri repositoryUri() => Uri.https('github.com', '/$repoOwner/$repoName');

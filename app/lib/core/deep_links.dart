import 'package:flutter/widgets.dart';

import 'constants.dart';

/// Deep links the app answers to, matching the intent-filter in
/// `android/app/src/main/AndroidManifest.xml`:
///
/// * `kumpleto://doc/nbi-clearance` — one document
/// * `kumpleto://bundle/job-hunt-pack` — one bundle
/// * `https://jamesmangao.github.io/kumpleto/doc/nbi-clearance` — the same
///   document, as shared by the public checklist pages. A link that arrives
///   in a chat opens the page in a browser when the app is not installed, and
///   offers the app when it is.
const String kumpletoDeepLinkScheme = 'kumpleto';

/// Host of the published checklist pages, derived from [dataUrl] so the app
/// and the site can never disagree about where the data lives.
final String _httpsHost = Uri.parse(dataUrl).host;

/// Repository path on that host (`/kumpleto`), also from [dataUrl].
final String _httpsPathPrefix = Uri.parse(dataUrl).pathSegments.isEmpty
    ? ''
    : '/${Uri.parse(dataUrl).pathSegments.first}';

final RegExp _idPattern = RegExp(r'^[a-z0-9][a-z0-9-]{0,63}$');

/// Maps a `kumpleto://` or published `https://` [uri] to its in-app route, or
/// null when it is not a link this app understands (wrong scheme/host, unknown
/// kind, malformed id).
String? deepLinkPathForUri(Uri? uri) {
  if (uri == null) return null;
  if (uri.scheme == kumpletoDeepLinkScheme) {
    final parts = <String>[
      if (uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments.where((segment) => segment.isNotEmpty),
    ];
    return parts.length == 2 ? _route(parts[0], parts[1]) : null;
  }
  if ((uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host == _httpsHost) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    // /kumpleto/doc/<id> — the repository name is the first segment on a
    // GitHub Pages project site.
    final expectedPrefix = _httpsPathPrefix
        .split('/')
        .where((s) => s.isNotEmpty);
    if (segments.length != expectedPrefix.length + 2) return null;
    if (!segments
        .take(expectedPrefix.length)
        .join('/')
        .startsWith(expectedPrefix.join('/'))) {
      return null;
    }
    return _route(segments[segments.length - 2], segments.last);
  }
  return null;
}

String? _route(String kind, String id) {
  if (kind != 'doc' && kind != 'bundle') return null;
  if (!_idPattern.hasMatch(id)) return null;
  return '/$kind/$id';
}

/// [deepLinkPathForUri] for a raw location string, as the platform reports it.
String? deepLinkPath(String? location) {
  if (location == null || location.isEmpty) return null;
  return deepLinkPathForUri(Uri.tryParse(location));
}

/// The route to open on a cold start when the app was launched by a deep link,
/// otherwise null so the router keeps its normal entry point.
String? initialDeepLinkPath() {
  final route = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  return deepLinkPath(route);
}

/// Public page for a document, used by share links and the QR code.
Uri documentPageUri(String documentId) =>
    Uri.parse('${_siteBase()}/doc/$documentId');

/// Public page for a bundle.
Uri bundlePageUri(String bundleId) =>
    Uri.parse('${_siteBase()}/bundle/$bundleId');

String _siteBase() {
  final base = dataUrl.endsWith('data.json')
      ? dataUrl.substring(0, dataUrl.length - 'data.json'.length)
      : dataUrl;
  return base.endsWith('/') ? base.substring(0, base.length - 1) : base;
}

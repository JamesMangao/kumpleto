import 'package:flutter/widgets.dart';

/// Deep links the app answers to, matching the intent-filter in
/// `android/app/src/main/AndroidManifest.xml`:
///
/// * `kumpleto://doc/nbi-clearance` — one document
/// * `kumpleto://bundle/job-hunt-pack` — one bundle
///
/// Only the custom scheme is registered: an `https` link would need a domain
/// the project does not own, and an unverified link opens browsers instead of
/// the app.
const String kumpletoDeepLinkScheme = 'kumpleto';

final RegExp _idPattern = RegExp(r'^[a-z0-9][a-z0-9-]{0,63}$');

/// Maps a `kumpleto://` [uri] to its in-app route, or null when it is not a
/// link this app understands (wrong scheme, unknown kind, malformed id).
String? deepLinkPathForUri(Uri? uri) {
  if (uri == null || uri.scheme != kumpletoDeepLinkScheme) return null;
  final parts = <String>[
    if (uri.host.isNotEmpty) uri.host,
    ...uri.pathSegments.where((segment) => segment.isNotEmpty),
  ];
  if (parts.length != 2) return null;
  final kind = parts[0];
  if (kind != 'doc' && kind != 'bundle') return null;
  if (!_idPattern.hasMatch(parts[1])) return null;
  return '/$kind/${parts[1]}';
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

/// Silent background refresh of the published data feed.
///
/// Implements the P2 fetch hardening (docs/DECISIONS.md): HTTPS only, a
/// hand-rolled redirect loop capped at 3 hops (each hop re-checked for
/// https), a 2 MB body cap enforced *while* streaming, a 10 s overall
/// timeout, and ETag revalidation.
///
/// Every failure is a value, never an exception: the UI keeps whatever data
/// it already has and nothing blocks on this.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/canonical.dart';
import '../core/constants.dart';
import '../core/settings.dart';
import 'data_repository.dart';

/// Outcome of one feed check. Sealed so callers must handle every case.
sealed class UpdateResult {
  const UpdateResult();

  /// 304 — the feed has not changed since the stored ETag.
  const factory UpdateResult.notModified() = UpdateNotModified;

  /// 200 with a payload that passed verification. [body] is the raw JSON, so
  /// it can be cached byte for byte.
  const factory UpdateResult.updated(String body, {String? etag}) =
      UpdateAccepted;

  /// The response was unusable (bad JSON, wrong shape, sha256 mismatch,
  /// unsupported `schema_version`). Current data is kept.
  const factory UpdateResult.invalid(String reason) = UpdateInvalid;

  /// Transport-level problem: network, HTTP status, redirect or size/timeout
  /// limit. Current data is kept.
  const factory UpdateResult.failed(String reason) = UpdateFailed;

  /// Human-readable reason for the unsuccessful results, for Settings/tests.
  String get reasonOrNull => switch (this) {
    UpdateInvalid(:final reason) || UpdateFailed(:final reason) => reason,
    _ => '',
  };
}

final class UpdateNotModified extends UpdateResult {
  const UpdateNotModified();
}

final class UpdateAccepted extends UpdateResult {
  const UpdateAccepted(this.body, {this.etag});

  final String body;
  final String? etag;
}

final class UpdateInvalid extends UpdateResult {
  const UpdateInvalid(this.reason);

  final String reason;
}

final class UpdateFailed extends UpdateResult {
  const UpdateFailed(this.reason);

  final String reason;
}

/// Fetches and verifies the feed, then persists it through
/// [DataRepository.saveCache].
class UpdateService {
  UpdateService({
    required this.client,
    required this.url,
    required this.prefs,
    required this.repository,
    this.timeout = dataFetchTimeout,
    this.checkInterval = dataCheckInterval,
    DateTime Function()? now,
  }) : clock = now ?? DateTime.now;

  final http.Client client;
  final Uri url;
  final SharedPreferences prefs;
  final DataRepository repository;

  /// Overall budget for one check, covering every redirect hop.
  final Duration timeout;

  /// Minimum spacing between automatic checks (the manual Settings button
  /// calls [checkNow] and ignores this).
  final Duration checkInterval;

  final DateTime Function() clock;

  /// Automatic entry point: runs at most once per [checkInterval].
  /// Returns null when the gate has not elapsed yet.
  Future<UpdateResult?> maybeCheck() async {
    final last = prefs.getInt(PrefsKeys.lastDataCheck) ?? 0;
    if (last > 0 &&
        clock().millisecondsSinceEpoch - last < checkInterval.inMilliseconds) {
      return null;
    }
    return checkNow();
  }

  /// Always runs a check (used by the Settings "check for updates" button).
  ///
  /// Records the attempt time whatever happens, so a flaky network cannot
  /// turn every app launch into a fetch.
  Future<UpdateResult> checkNow() async {
    final UpdateResult result = await _fetchGuarded();

    await prefs.setInt(PrefsKeys.lastDataCheck, clock().millisecondsSinceEpoch);

    if (result case UpdateAccepted(:final body, :final etag)) {
      await repository.saveCache(body);
      if (etag != null && etag.isNotEmpty) {
        await prefs.setString(PrefsKeys.lastDataETag, etag);
      } else {
        await prefs.remove(PrefsKeys.lastDataETag);
      }
    }
    // 304 revalidation keeps the stored ETag as it is; invalid/failed
    // responses leave both the cached data and the ETag untouched.
    return result;
  }

  /// Runs [_fetch] under the overall timeout, converting an unexpected
  /// transport exception into a failed result.
  Future<UpdateResult> _fetchGuarded() async {
    try {
      return await _fetch().timeout(
        timeout,
        onTimeout: () => UpdateFailed('timed out after ${timeout.inSeconds}s'),
      );
    } on Object catch (error) {
      return UpdateFailed('$error');
    }
  }

  Future<UpdateResult> _fetch() async {
    if (url.scheme != 'https') {
      return const UpdateFailed('feed URL is not https');
    }
    final storedEtag = prefs.getString(PrefsKeys.lastDataETag);

    var current = url;
    var redirects = 0;
    while (true) {
      if (current.scheme != 'https') {
        return const UpdateFailed('redirected to a non-https URL');
      }
      final request =
          http.Request('GET', current)
            ..followRedirects = false
            ..persistentConnection = false
            ..headers.addAll(const {
              'Accept': 'application/json',
              'User-Agent': appDisplayName,
            });
      if (redirects == 0 && storedEtag != null && storedEtag.isNotEmpty) {
        request.headers['If-None-Match'] = storedEtag;
      }

      final response = await client.send(request);

      if (_isRedirect(response.statusCode)) {
        final location = response.headers['location'];
        if (location == null || location.isEmpty) {
          return const UpdateFailed('redirect without a Location header');
        }
        if (redirects >= dataFetchMaxRedirects) {
          return UpdateFailed(
            'more than $dataFetchMaxRedirects redirects',
          );
        }
        redirects += 1;
        current = current.resolve(location);
        continue;
      }
      return _handleResponse(response);
    }
  }

  Future<UpdateResult> _handleResponse(http.StreamedResponse response) async {
    if (response.statusCode == 304) return const UpdateNotModified();
    if (response.statusCode != 200) {
      return UpdateFailed('HTTP ${response.statusCode}');
    }

    final declared = response.contentLength;
    if (declared != null && declared > dataFetchMaxBytes) {
      return UpdateFailed('body too large ($declared bytes)');
    }

    final builder = BytesBuilder(copy: false);
    var oversize = false;
    await for (final chunk in response.stream) {
      builder.add(chunk);
      if (builder.length > dataFetchMaxBytes) {
        oversize = true;
        break; // cancels the subscription — we stop reading immediately
      }
    }
    if (oversize) return const UpdateFailed('body exceeded 2 MB while reading');

    final String raw;
    try {
      raw = utf8.decode(builder.takeBytes());
    } on FormatException {
      return const UpdateInvalid('body is not valid UTF-8');
    }

    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      return UpdateInvalid('body is not valid JSON (${error.message})');
    }
    if (decoded is! Map<Object?, Object?>) {
      return const UpdateInvalid('top level is not an object');
    }
    final json = <String, Object?>{
      for (final entry in decoded.entries) entry.key.toString(): entry.value,
    };
    final reason = verifyDataJson(
      json,
      maxSchemaVersion: supportedSchemaVersion,
    );
    if (reason != null) return UpdateInvalid(reason);

    return UpdateAccepted(raw, etag: response.headers['etag']);
  }

  static bool _isRedirect(int status) =>
      status == 301 ||
      status == 302 ||
      status == 303 ||
      status == 307 ||
      status == 308;
}

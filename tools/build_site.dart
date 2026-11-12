// Publishes the checklist library as static pages next to the data feed.
//
// Usage (repo root, after `dart run tools/build_data.dart`):
//   dart run tools/build_site.dart
//
// Output (gitignored): site/
//   index.html                  every document and bundle
//   doc/<id>.html               one page per document
//   bundle/<id>.html            one page per bundle
//   data.json                   the same release payload the app fetches
//   sitemap.xml, robots.txt
//
// Each page is self-contained (inline CSS, no JavaScript), so it works on a
// slow connection and does not need the app installed. The pages exist to be
// found by search and to give shared links somewhere real to land.
import 'dart:convert';
import 'dart:io';

const _siteBase = 'https://jamesmangao.github.io/kumpleto';
const _appName = 'Kumpleto';

Future<void> main(List<String> args) async {
  final root = Directory.current;
  final dataFile = File('${root.path}/dist/data.json');
  if (!dataFile.existsSync()) {
    stderr.writeln(
      'dist/data.json is missing — run `dart run tools/build_data.dart` first.',
    );
    exitCode = 1;
    return;
  }

  final payload = jsonDecode(dataFile.readAsStringSync()) as Map<String, dynamic>;
  final documents = (payload['documents'] as List? ?? const [])
      .cast<Map<String, dynamic>>();
  final bundles = (payload['bundles'] as List? ?? const [])
      .cast<Map<String, dynamic>>();
  final agencies = (payload['agencies'] as List? ?? const [])
      .cast<Map<String, dynamic>>();

  final agencyNames = {
    for (final agency in agencies)
      agency['id'] as String: _text(agency['name'], 'en'),
  };
  final docNames = {
    for (final doc in documents) doc['id'] as String: _text(doc['name'], 'en'),
  };

  final out = Directory('${root.path}/site');
  if (out.existsSync()) out.deleteSync(recursive: true);
  Directory('${out.path}/doc').createSync(recursive: true);
  Directory('${out.path}/bundle').createSync(recursive: true);

  File('${out.path}/data.json').writeAsStringSync(dataFile.readAsStringSync());
  // One shared social card: the same 1024×500 feature graphic the store
  // listing uses, copied into the site so the absolute og:image URL always
  // resolves next to the pages that point at it.
  final ogSource = File(
    '${root.path}/app/assets/logo/feature-graphic-1024x500.png',
  );
  if (ogSource.existsSync()) {
    ogSource.copySync('${out.path}/og.png');
  } else {
    stderr.writeln('warning: ${ogSource.path} missing — pages will link a 404 '
        'og:image');
  }
  File('${out.path}/robots.txt').writeAsStringSync(
    'User-agent: *\nAllow: /\nSitemap: $_siteBase/sitemap.xml\n',
  );
  // GitHub Pages serves this for any unknown path, so a mistyped /doc/<id> —
  // or a QR code printed for an entry that was later renamed — lands on a page
  // that explains itself instead of the host's bare default. Pages uses
  // 404.html by name, so the filename is the whole wiring.
  File('${out.path}/404.html').writeAsStringSync(_notFoundPage());

  // <lastmod> tells a crawler which pages actually changed. Every page is
  // rendered from the same payload, so the payload's own timestamp is an
  // honest date for the whole site — better than "now", which would claim a
  // change on every deploy.
  final lastmod = _isoDate(payload['data_version']);
  String urlEntry(String loc) => lastmod == null
      ? '  <url><loc>$loc</loc></url>'
      : '  <url><loc>$loc</loc><lastmod>$lastmod</lastmod></url>';

  final sitemap = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
    ..writeln(urlEntry('$_siteBase/'));

  File('${out.path}/index.html').writeAsStringSync(
    _indexPage(documents: documents, bundles: bundles, agencyNames: agencyNames),
  );

  for (final doc in documents) {
    final id = doc['id'] as String;
    File('${out.path}/doc/$id.html').writeAsStringSync(
      _documentPage(
        doc: doc,
        agencyName: agencyNames[doc['agency']] ?? '',
      ),
    );
    sitemap.writeln(urlEntry('$_siteBase/doc/$id'));
  }

  for (final bundle in bundles) {
    final id = bundle['id'] as String;
    File('${out.path}/bundle/$id.html').writeAsStringSync(
      _bundlePage(bundle: bundle, docNames: docNames),
    );
    sitemap.writeln(urlEntry('$_siteBase/bundle/$id'));
  }

  sitemap.writeln('</urlset>');
  File('${out.path}/sitemap.xml').writeAsStringSync(sitemap.toString());

  stdout.writeln(
    'Built site/: index, ${documents.length} document pages, '
    '${bundles.length} bundle pages, sitemap.xml, robots.txt, 404.html, '
    'data.json',
  );
}

// ---------------------------------------------------------------------------
// Pages
// ---------------------------------------------------------------------------

String _indexPage({
  required List<Map<String, dynamic>> documents,
  required List<Map<String, dynamic>> bundles,
  required Map<String, String> agencyNames,
}) {
  final docItems = StringBuffer();
  final sortedDocs = [...documents]
    ..sort((a, b) => _text(a['name'], 'en').compareTo(_text(b['name'], 'en')));
  for (final doc in sortedDocs) {
    final id = doc['id'] as String;
    final agency = agencyNames[doc['agency']] ?? '';
    docItems.writeln(
      '<li><a href="doc/$id.html">${_esc(_text(doc['name'], 'en'))}</a>'
      '${agency.isEmpty ? '' : ' <span class="meta">· ${_esc(agency)}</span>'}</li>',
    );
  }

  final bundleItems = StringBuffer();
  for (final bundle in bundles) {
    final id = bundle['id'] as String;
    bundleItems.writeln(
      '<li><a href="bundle/$id.html">${_esc(_text(bundle['name'], 'en'))}</a></li>',
    );
  }

  return _shell(
    title: 'Philippine document requirements — $_appName',
    description:
        'Unofficial offline checklists for Philippine government document '
        'requirements: NBI clearance, PSA certificates, passport, driver\'s '
        'licence, PRC ID, SSS, PhilHealth and more.',
    canonical: '$_siteBase/',
    body: '''
<h1>Philippine government document requirements</h1>
<p class="lede">$_appName is an unofficial, offline checklist app. Every entry
lists the requirements, the steps, the fees and the official government page it
was checked against. It is not a government app.</p>
<p><a class="cta" href="https://play.google.com/store/apps/details?id=io.github.jamesmangao.kumpleto">Get the app</a></p>
<h2>Documents (${documents.length})</h2>
<ul class="list">
$docItems</ul>
<h2>Life-event packs (${bundles.length})</h2>
<ul class="list">
$bundleItems</ul>
<p class="note">Requirements and fees change. Always confirm with the official
agency before you pay or apply.</p>
''',
  );
}

String _documentPage({
  required Map<String, dynamic> doc,
  required String agencyName,
}) {
  final id = doc['id'] as String;
  final name = _text(doc['name'], 'en');
  final summary = _text(doc['summary'], 'en');
  final source = doc['source_url'] as String?;
  final requirements = (doc['requirements'] as List? ?? const [])
      .cast<Map<String, dynamic>>();
  final steps = (doc['steps'] as List? ?? const []).cast<Map<String, dynamic>>();
  final fee = _text(doc['fee_note'], 'en');
  final processing = _text(doc['processing_note'], 'en');
  final validity = doc['validity_months'] as int?;

  final buffer = StringBuffer();
  buffer.writeln('<h1>$name</h1>');
  buffer.writeln(
    '<p class="meta">${_esc(agencyName)}${_verifiedLine(doc)}</p>',
  );
  if (summary.isNotEmpty) buffer.writeln('<p class="lede">${_esc(summary)}</p>');
  buffer.writeln(
    '<p><a class="cta" href="kumpleto://doc/$id">Open in the app</a> '
    '<span class="note">· the same checklist, offline</span></p>',
  );

  if (requirements.isNotEmpty) {
    buffer.writeln('<h2>What to bring</h2><ul>');
    for (final req in requirements) {
      final tag = req['original'] == true
          ? ' (original)'
          : ((req['photocopies'] as int? ?? 0) > 0 ? ' (photocopy)' : '');
      buffer.writeln('<li>${_esc(_text(req['text'], 'en'))}$tag</li>');
    }
    buffer.writeln('</ul>');
  }

  if (steps.isNotEmpty) {
    buffer.writeln('<h2>How to apply</h2><ol>');
    for (final step in steps) {
      buffer.writeln('<li>${_esc(_text(step, 'en'))}</li>');
    }
    buffer.writeln('</ol>');
  }

  final facts = <String>[];
  if (fee.isNotEmpty) facts.add('<strong>Fee:</strong> ${_esc(fee)}');
  if (processing.isNotEmpty) {
    facts.add('<strong>Processing:</strong> ${_esc(processing)}');
  }
  if (validity != null && validity > 0) {
    facts.add('<strong>Validity:</strong> ${_esc('$validity months')}');
  }
  if (facts.isNotEmpty) {
    buffer.writeln('<h2>Fees, processing time and validity</h2><ul>');
    for (final fact in facts) {
      buffer.writeln('<li>$fact</li>');
    }
    buffer.writeln('</ul>');
  }

  if (source != null) {
    buffer.writeln(
      '<p><a href="${_esc(source)}" rel="noopener">Official source</a> · '
      'always confirm the requirements there before you apply.</p>',
    );
  }

  return _shell(
    title: '$name requirements — $_appName',
    description: summary.isEmpty
        ? 'Requirements, steps and fees for $name, with the official government source.'
        : summary,
    canonical: '$_siteBase/doc/$id',
    ogType: 'article',
    body: buffer.toString(),
  );
}

String _bundlePage({
  required Map<String, dynamic> bundle,
  required Map<String, String> docNames,
}) {
  final id = bundle['id'] as String;
  final name = _text(bundle['name'], 'en');
  final description = _text(bundle['description'], 'en');
  final ids = (bundle['documents'] as List? ?? const []).cast<String>();

  final buffer = StringBuffer()
    ..writeln('<h1>$name</h1>')
    ..writeln('<p class="lede">${_esc(description)}</p>')
    ..writeln(
      '<p><a class="cta" href="kumpleto://bundle/$id">Open in the app</a></p>',
    )
    ..writeln('<h2>Documents in this pack</h2><ol>');

  for (final docId in ids) {
    buffer.writeln(
      '<li><a href="../doc/$docId.html">'
      '${_esc(docNames[docId] ?? docId)}</a></li>',
    );
  }
  buffer.writeln('</ol>');

  return _shell(
    title: '$name — $_appName',
    description: description,
    canonical: '$_siteBase/bundle/$id',
    ogType: 'article',
    body: buffer.toString(),
  );
}

/// The page GitHub Pages serves for any path it does not have.
String _notFoundPage() => _shell(
  title: 'Page not found — $_appName',
  description:
      'This checklist page does not exist. Every document and bundle in '
      '$_appName is listed on the index.',
  canonical: '$_siteBase/404.html',
  body: '''
<h1>That page is not here.</h1>
<p class="lede">A link may be mistyped, or the checklist it pointed at may
have been renamed since the link was shared.</p>
<p><a class="cta" href="$_siteBase/">See every document and bundle</a></p>
<p class="note">If a QR code sent you here, search the index for the document
name — the codes always point at a page that exists.</p>
''',
);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _shell({
  required String title,
  required String description,
  required String canonical,
  required String body,
  String ogType = 'website',
}) {
  // Facebook, Messenger, WhatsApp, Telegram, Slack, X and Discord all read
  // these four Open Graph tags; Twitter/X and a few others read the twitter:
  // mirror. Without them a shared checklist link previews as a bare URL.
  final image = '$_siteBase/og.png';
  return '''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${_esc(title)}</title>
<meta name="description" content="${_esc(description)}">
<link rel="canonical" href="${_esc(canonical)}">
<meta property="og:type" content="$ogType">
<meta property="og:site_name" content="$_appName">
<meta property="og:title" content="${_esc(title)}">
<meta property="og:description" content="${_esc(description)}">
<meta property="og:url" content="${_esc(canonical)}">
<meta property="og:image" content="$image">
<meta property="og:image:width" content="1024">
<meta property="og:image:height" content="500">
<meta property="og:image:alt" content="$_appName — a checkmark over a document folder">
<meta property="og:locale" content="en_PH">
<meta property="og:locale:alternate" content="fil_PH">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="${_esc(title)}">
<meta name="twitter:description" content="${_esc(description)}">
<meta name="twitter:image" content="$image">
<meta name="theme-color" content="#0E6B58">
<style>
  :root { color-scheme: light dark; }
  body { margin: 0 auto; max-width: 44rem; padding: 2rem 1.25rem 4rem;
         font: 16px/1.6 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
         background: #f6f1e7; color: #14211d; }
  h1 { font-size: 1.9rem; line-height: 1.2; margin: 0 0 .5rem; }
  h2 { font-size: 1.15rem; margin: 2rem 0 .5rem; }
  a { color: #0e6b58; }
  .lede { color: #3d4f48; }
  .meta { color: #5e6f69; font-size: .9rem; margin-top: 0; }
  .note { color: #5e6f69; font-size: .9rem; }
  .cta { display: inline-block; margin: .5rem 0 1rem; padding: .6rem 1rem;
         border-radius: 999px; background: #0e6b58; color: #fff;
         text-decoration: none; font-weight: 600; }
  ul, ol { padding-left: 1.25rem; }
  .list li { margin: .35rem 0; }
  footer { margin-top: 3rem; font-size: .85rem; color: #5e6f69; }
  @media (prefers-color-scheme: dark) {
    body { background: #101715; color: #f1f5f3; }
    .lede { color: #cfdcd6; }
    .meta, .note, footer { color: #9db3ab; }
    a { color: #6fd3b8; }
  }
</style>
</head>
<body>
<header><a href="$_siteBase/">$_appName</a> <span class="note">· unofficial</span></header>
<main>
$body
</main>
<footer>
  $_appName is not a government app and is not affiliated with any agency.
  Requirements and fees change — confirm with the official source before you
  apply. <a href="$_siteBase/">All documents</a>
</footer>
</body>
</html>
''';
}

String _verifiedLine(Map<String, dynamic> doc) {
  final verified = doc['last_verified'] as String?;
  if (verified == null || verified.isEmpty) return '';
  return ' · checked $verified';
}

/// `YYYY-MM-DD` from a `data_version` timestamp, or null when the payload has
/// no usable date. A sitemap may omit `<lastmod>`; a malformed one is worse
/// than none, so anything unexpected is dropped.
String? _isoDate(Object? value) {
  if (value is! String) return null;
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value);
  if (match == null) return null;
  final month = int.tryParse(match.group(2)!) ?? 0;
  final day = int.tryParse(match.group(3)!) ?? 0;
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  return '${match.group(1)}-${match.group(2)}-${match.group(3)}';
}

String _text(Object? value, String locale) {
  if (value is String) return value;
  if (value is Map) {
    final picked = value[locale] ?? value['en'];
    if (picked is String) return picked;
  }
  return '';
}

String _esc(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

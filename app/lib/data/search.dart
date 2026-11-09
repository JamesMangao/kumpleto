library;

import '../models/models.dart';

/// Fold accented characters: á à â ä ã å → a, é è ê ë → e, etc.
const _folds = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ä': 'a',
  'ã': 'a',
  'å': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'ö': 'o',
  'õ': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ñ': 'n',
  'ç': 'c',
};

/// Text matching for the document list.
///
/// The search box used to look at the document name and the agency's English
/// name only, so a reader who typed "cedula", "proof of billing" or "NSO"
/// got an empty list while the answer was in the summary or a requirement
/// line. Everything a person might type now counts: both names, the agency in
/// both languages, tags, summary, requirements (with their notes), steps, the
/// fee and processing notes, extra notes, and the id's words.
///
/// Matching is per word: every word typed has to appear somewhere in the
/// entry, so "nbi appointment" still finds the clearance, but words are never
/// required to be adjacent. Accented letters are folded (`ñ` → `n`) so a
/// reader on a Filipino keyboard finds the same entry either way.
String normalizeSearch(String input) {
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_folds[char] ?? char);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Every searchable word of [document], normalized.
String documentHaystack(Document document, {Agency? agency}) {
  final parts = <String>[
    document.id.replaceAll('-', ' '),
    document.name.en,
    document.name.fil,
    if (agency != null) ...[agency.name.en, agency.name.fil],
    ...document.tags,
    if (document.summary != null) ...[
      document.summary!.en,
      document.summary!.fil,
    ],
    if (document.whereToApply != null) ...[
      document.whereToApply!.en,
      document.whereToApply!.fil,
    ],
    if (document.feeNote != null) ...[
      document.feeNote!.en,
      document.feeNote!.fil,
    ],
    if (document.processingNote != null) ...[
      document.processingNote!.en,
      document.processingNote!.fil,
    ],
    for (final requirement in document.requirements) ...[
      requirement.text.en,
      requirement.text.fil,
      if (requirement.note != null) ...[
        requirement.note!.en,
        requirement.note!.fil,
      ],
    ],
    for (final step in document.steps) ...[step.en, step.fil],
    for (final note in document.notes) ...[note.en, note.fil],
  ];
  return normalizeSearch(parts.join(' '));
}

/// True when [query] (possibly empty) matches [document].
bool documentMatches(
  Document document, {
  required String query,
  Agency? agency,
}) {
  final needle = normalizeSearch(query);
  if (needle.isEmpty) return true;
  final haystack = documentHaystack(document, agency: agency);
  return needle.split(' ').every(haystack.contains);
}

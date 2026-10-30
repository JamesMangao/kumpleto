/// Bilingual content string, as authored in `data/**.yaml`.
library;

/// A `{en, fil}` pair. [fil] falls back to [en] when missing or empty, so a
/// partially translated entry never renders as blank text.
class LocalizedText {
  const LocalizedText({required this.en, required this.fil});

  final String en;
  final String fil;

  /// Tolerant parse: returns null when there is no usable English text.
  static LocalizedText? fromJson(Object? json) {
    if (json is! Map<Object?, Object?>) return null;
    final rawEn = json['en'];
    if (rawEn is! String || rawEn.trim().isEmpty) return null;
    final rawFil = json['fil'];
    final fil = rawFil is String && rawFil.trim().isNotEmpty ? rawFil : rawEn;
    return LocalizedText(en: rawEn, fil: fil);
  }

  /// Picks the string for [languageCode] ('fil' → Filipino, anything else →
  /// English).
  String pick(String languageCode) => languageCode == 'fil' ? fil : en;

  @override
  String toString() => en;
}
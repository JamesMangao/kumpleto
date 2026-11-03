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

  static final RegExp _token = RegExp(r'\{\{(\w+)\}\}');

  /// Replaces every `{{name}}` with the matching entry of [values].
  ///
  /// Text without tokens (almost every document) is returned untouched, and a
  /// token whose value is missing is left as written rather than dropped, so an
  /// authoring mistake shows up instead of silently reading as a blank.
  LocalizedText filled(Map<String, LocalizedText> values) {
    if (values.isEmpty || !(en.contains('{{') || fil.contains('{{'))) {
      return this;
    }
    String apply(String text, String Function(LocalizedText) pick) =>
        text.replaceAllMapped(
          _token,
          (match) => switch (values[match[1]]) {
            final value? => pick(value),
            null => match[0]!,
          },
        );
    return LocalizedText(en: apply(en, (value) => value.en), fil: apply(fil, (value) => value.fil));
  }

  @override
  String toString() => en;
}
import '../core/place_names.dart';
import '../models/localized_text.dart';
import 'location.dart';

/// The user's saved place expressed as the `{{placeholders}}` that document
/// text may contain.
///
/// A document written once, for everyone, still has to read correctly for the
/// person holding the phone: the barangay clearance names *their* barangay, not
/// the one the entry was first written for. Authors write `{{barangay}}`,
/// `{{city}}` or `{{address}}` in `data/documents/*.yaml`; this class turns the
/// saved location into those values.
///
/// When no location is saved every token still resolves to a neutral phrase, so
/// the sentence stays grammatical ("the hall of your barangay") instead of
/// leaving a hole. Fallbacks are written to follow a preposition, never to
/// start a sentence.
class PlaceTokens {
  const PlaceTokens(this.values);

  final Map<String, LocalizedText> values;

  static const Map<String, LocalizedText> _fallback = {
    'barangay': LocalizedText(
      en: 'your barangay',
      fil: 'barangay ninyo',
    ),
    'city': LocalizedText(
      en: 'your city or municipality',
      fil: 'lungsod o munisipalidad ninyo',
    ),
    'address': LocalizedText(
      en: 'your barangay, city and province',
      fil: 'barangay, lungsod at lalawigan ninyo',
    ),
  };

  factory PlaceTokens.of(SavedLocation? location) {
    final barangay = location?.barangay?.name;
    final city = location?.city?.name;
    final province = location?.province?.name;
    final zip = location?.zip.trim() ?? '';
    if (barangay == null && city == null) {
      return const PlaceTokens(_fallback);
    }

    // "Barangay Pacita 1, City of San Pedro, Laguna 4023" — the same order a
    // Philippine address is written in, minus whatever the user has not set.
    final barangayLabel = barangay == null ? null : 'Barangay $barangay';
    // The PSGC catalogue is English-only, so the Filipino sentence says
    // "Lungsod ng San Pedro" instead of pasting "City of San Pedro" into it.
    final cityFil = city == null ? null : filipinoPlaceName(city);
    String addressWith(String? cityName) => [
      [?barangayLabel, ?cityName, ?province].join(', '),
      if (zip.isNotEmpty) zip,
    ].join(' ');

    final barangayText = barangayLabel == null
        ? null
        : LocalizedText(en: barangayLabel, fil: barangayLabel);
    final cityText = city == null
        ? null
        : LocalizedText(en: city, fil: cityFil!);

    return PlaceTokens({
      ..._fallback,
      'barangay': ?barangayText,
      'city': ?cityText,
      'address': LocalizedText(
        en: addressWith(city),
        fil: addressWith(cityFil),
      ),
    });
  }
}

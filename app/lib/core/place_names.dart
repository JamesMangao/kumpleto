/// Filipino names for the PSA place entries shown in the app's own prose.
///
/// The PSGC catalogue is published in English only: "City of San Pedro",
/// "Municipality of Pila", "Quezon City". Shown verbatim inside a Filipino
/// sentence they read like a form field, so the display layer translates the
/// generic part and leaves the proper noun alone. Barangays and provinces keep
/// their official names — those are what the barangay hall and the LGU know.
library;

/// "City of San Pedro" → "Lungsod ng San Pedro"; "Quezon City" → "Lungsod ng
/// Quezon"; "Municipality of Pila" → "Bayan ng Pila". Anything unrecognised
/// comes back unchanged.
String filipinoPlaceName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return trimmed;

  const cityOf = 'City of ';
  if (trimmed.startsWith(cityOf)) {
    return 'Lungsod ng ${trimmed.substring(cityOf.length)}';
  }

  const municipalityOf = 'Municipality of ';
  if (trimmed.startsWith(municipalityOf)) {
    return 'Bayan ng ${trimmed.substring(municipalityOf.length)}';
  }

  const citySuffix = ' City';
  if (trimmed.endsWith(citySuffix) && trimmed.length > citySuffix.length) {
    final stem = trimmed.substring(0, trimmed.length - citySuffix.length);
    return 'Lungsod ng $stem';
  }

  const municipalitySuffix = ' Municipality';
  if (trimmed.endsWith(municipalitySuffix) &&
      trimmed.length > municipalitySuffix.length) {
    final stem = trimmed.substring(
      0,
      trimmed.length - municipalitySuffix.length,
    );
    return 'Bayan ng $stem';
  }

  return trimmed;
}

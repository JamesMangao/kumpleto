import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/data/data_repository.dart';
import 'package:kumpleto/data/location.dart';
import 'package:kumpleto/data/place_tokens.dart';
import 'package:kumpleto/data/providers.dart';
import 'package:kumpleto/models/localized_text.dart';
import 'package:kumpleto/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Document text can name the place it is about (`{{barangay}}`), and the text
/// is filled from the location saved in Settings. With no location saved the
/// entry must still read as a sentence, never as a hole.
void main() {
  const pacita1 = Place(code: '0403425026', name: 'Pacita 1');
  const sanPedro = Place(code: '0403425', name: 'City of San Pedro');
  const laguna = Place(code: '04034', name: 'Laguna');
  const saved = SavedLocation(
    region: Place(code: '04', name: 'Region IV-A (CALABARZON)'),
    province: laguna,
    city: sanPedro,
    barangay: pacita1,
    zip: '4023',
  );

  group('LocalizedText.filled', () {
    test('replaces tokens in both languages', () {
      const text = LocalizedText(
        en: 'The hall of {{barangay}} in {{city}}.',
        fil: 'Ang hall ng {{barangay}} sa {{city}}.',
      );
      final filled = text.filled(PlaceTokens.of(saved).values);
      expect(filled.en, 'The hall of Barangay Pacita 1 in City of San Pedro.');
      expect(filled.fil, 'Ang hall ng Barangay Pacita 1 sa City of San Pedro.');
    });

    test('leaves text without tokens alone', () {
      const text = LocalizedText(en: 'Passport', fil: 'Pasaporte');
      final filled = text.filled(PlaceTokens.of(saved).values);
      expect(identical(filled, text), isTrue);
    });

    test('keeps an unknown token written rather than dropping it', () {
      const text = LocalizedText(en: 'Hello {{nobody}}', fil: 'Hello');
      expect(
        text.filled(PlaceTokens.of(saved).values).en,
        'Hello {{nobody}}',
      );
    });
  });

  group('PlaceTokens', () {
    test('names the saved barangay, city and postal code', () {
      final values = PlaceTokens.of(saved).values;
      expect(values['barangay']!.en, 'Barangay Pacita 1');
      expect(values['city']!.en, 'City of San Pedro');
      expect(values['address']!.en, 'Barangay Pacita 1, City of San Pedro, Laguna 4023');
    });

    test('falls back to a neutral phrase with nothing saved', () {
      final values = PlaceTokens.of(null).values;
      expect(values['barangay']!.en, 'your barangay');
      expect(values['barangay']!.fil, 'barangay ninyo');
      expect(values['city']!.en, 'your city or municipality');
      expect(values['address']!.fil, 'barangay, lungsod at lalawigan ninyo');
    });

    test('a barangay without a province still builds an address', () {
      final values = PlaceTokens.of(
        const SavedLocation(
          city: Place(code: '1380600', name: 'City of Manila'),
          barangay: Place(code: '1380601001', name: 'Barangay 1'),
        ),
      ).values;
      expect(values['address']!.en, 'Barangay Barangay 1, City of Manila');
    });
  });

  group('Document filling', () {
    test('resolves every placeholder and reports it waits for a place', () {
      final document = Document.fromJson({
        'id': 'barangay-clearance',
        'name': {'en': 'Barangay Clearance'},
        'agency': 'barangay',
        'status': 'verified',
        'summary': {
          'en': 'Filled in for {{address}}.',
          'fil': 'Nakasagot para sa {{address}}.',
        },
        'requirements': [
          {
            'id': 'proof-of-residence',
            'text': {
              'en': 'ID showing your address in {{barangay}}.',
              'fil': 'ID na may address sa {{barangay}}.',
            },
          },
        ],
        'steps': [
          {'en': 'Go to the hall of {{barangay}}.', 'fil': 'Pumunta sa hall ng {{barangay}}.'},
        ],
      })!;

      expect(document.awaitsPlace, isTrue);

      final filled = document.filled(PlaceTokens.of(saved).values);
      expect(filled.summary!.en, contains('Barangay Pacita 1'));
      expect(filled.requirements.single.text.en, contains('Barangay Pacita 1'));
      expect(filled.steps.single.fil, contains('Barangay Pacita 1'));
      expect(filled.summary!.en, isNot(contains('{{')));
      expect(filled.steps.single.fil, isNot(contains('{{')));
    });

    test('the bundle the app reads is filled from the saved location', () async {
      SharedPreferences.setMockInitialValues({
        SavedLocation.prefsKey: jsonEncode({
          'region': {'c': '04', 'n': 'Region IV-A (CALABARZON)'},
          'province': {'c': '04034', 'n': 'Laguna'},
          'city': {'c': '0403425', 'n': 'City of San Pedro'},
          'barangay': {'c': '0403425026', 'n': 'Pacita 1'},
          'zip': '4023',
        }),
      });
      final prefs = await SharedPreferences.getInstance();
      final payload = {
        'schema_version': 1,
        'data_version': 'test',
        'agencies': <Object?>[],
        'documents': [
          {
            'id': 'barangay-clearance',
            'name': {'en': 'Barangay Clearance'},
            'agency': 'barangay',
            'summary': {'en': 'Filled in for {{address}}.'},
          },
        ],
        'bundles': <Object?>[],
      };
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          loadedDataProvider.overrideWith(
            (ref) async => LoadedData(
              data: DataBundle.fromJson(payload),
              source: DataSource.bundledRelease,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(loadedDataProvider.future);
      final bundle = container.read(dataBundleProvider).value!;
      expect(
        bundle.document('barangay-clearance')!.summary!.en,
        'Filled in for Barangay Pacita 1, City of San Pedro, Laguna 4023.',
      );
      expect(
        container.read(savedLocationProvider)!.barangay!.code,
        '0403425026',
      );
    });

    test('a document written without placeholders does not wait for one', () {
      final document = Document.fromJson({
        'id': 'passport-dfa',
        'name': {'en': 'Passport'},
        'agency': 'dfa',
      })!;
      expect(document.awaitsPlace, isFalse);
    });
  });
}

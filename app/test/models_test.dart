import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/models/localized_text.dart';
import 'package:kumpleto/models/models.dart';

/// Draft entries omit optional fields, so parsing must be tolerant: nulls and
/// schema defaults instead of exceptions, and `fil` falls back to `en`.
void main() {
  group('LocalizedText', () {
    test('falls back to English when fil is missing or empty', () {
      expect(LocalizedText.fromJson({'en': 'Passport'})?.pick('fil'),
          'Passport');
      expect(
          LocalizedText.fromJson({'en': 'Passport', 'fil': 'Pasaporte'})
              ?.pick('fil'),
          'Pasaporte');
      expect(LocalizedText.fromJson({'en': 'Passport', 'fil': ''})?.pick('fil'),
          'Passport');
    });

    test('returns null when there is no usable English text', () {
      expect(LocalizedText.fromJson(<String, Object?>{}), isNull);
      expect(LocalizedText.fromJson({'fil': 'Wala'}), isNull);
      expect(LocalizedText.fromJson('not a map'), isNull);
      expect(LocalizedText.fromJson({'en': '   '}), isNull);
    });

    test('pick uses English for unknown locales', () {
      final text = LocalizedText.fromJson({'en': 'NBI', 'fil': 'NBI Fil'})!;
      expect(text.pick('en'), 'NBI');
      expect(text.pick('tl'), 'NBI');
      expect(text.pick('fil'), 'NBI Fil');
    });
  });

  group('Requirement', () {
    test('defaults: not original, zero photocopies, not optional', () {
      final requirement = Requirement.fromJson({
        'id': 'valid-id',
        'text': {'en': 'Valid ID'},
      })!;
      expect(requirement.original, isFalse);
      expect(requirement.photocopies, 0);
      expect(requirement.optional, isFalse);
      expect(requirement.note, isNull);
    });

    test('requires id and text', () {
      expect(Requirement.fromJson(<String, Object?>{'id': 'x'}), isNull);
      expect(Requirement.fromJson(<String, Object?>{}), isNull);
      expect(Requirement.fromJson('junk'), isNull);
    });

    test('junk types in optional fields become defaults', () {
      final requirement = Requirement.fromJson({
        'id': 'x',
        'text': {'en': 'X'},
        'original': 'yes',
        'photocopies': 'two',
        'optional': 1,
      })!;
      expect(requirement.original, isFalse);
      expect(requirement.photocopies, 0);
      expect(requirement.optional, isFalse);
    });
  });

  group('Document', () {
    test('a draft with only the required fields parses with nulls', () {
      final document = Document.fromJson({
        'id': 'nbi-clearance',
        'name': {'en': 'NBI Clearance'},
        'agency': 'nbi',
        'status': 'draft',
      })!;
      expect(document.status, DocStatus.draft);
      expect(document.summary, isNull);
      expect(document.sourceUrl, isNull);
      expect(document.lastVerified, isNull);
      expect(document.verifiedBy, isNull);
      expect(document.validityMonths, isNull);
      expect(document.applyOnline, isNull);
      expect(document.requirements, isEmpty);
      expect(document.steps, isEmpty);
      expect(document.tags, isEmpty);
      expect(document.isEmpty, isTrue);
    });

    test('parses a fully populated verified document', () {
      final document = Document.fromJson({
        'id': 'nbi-clearance',
        'name': {'en': 'NBI Clearance', 'fil': 'NBI Clearance'},
        'agency': 'nbi',
        'status': 'verified',
        'summary': {'en': 'Summary'},
        'source_url': 'https://nbi.gov.ph/',
        'last_verified': '2026-10-15',
        'verified_by': 'maintainer',
        'validity_months': 6,
        'apply_online': true,
        'apply_online_url': 'https://nbi.clearance.online/',
        'depends_on': ['psa-birth-certificate'],
        'tags': ['job-hunt'],
        'requirements': [
          {
            'id': 'valid-id',
            'text': {'en': 'Valid ID'},
            'original': true,
            'photocopies': 2,
          },
        ],
        'steps': [
          {
            'en': 'Go to the office',
            'fil': 'Pumunta sa opisina',
          },
        ],
        'fee_note': {'en': '₱130'},
        'processing_note': {'en': 'Same day'},
        'notes': [
          {'en': 'Bring cash'},
        ],
      })!;
      expect(document.status, DocStatus.verified);
      expect(document.sourceUrl, 'https://nbi.gov.ph/');
      expect(document.lastVerified, isNotNull);
      expect(
        [document.lastVerified!.year, document.lastVerified!.month,
         document.lastVerified!.day],
        [2026, 10, 15],
      );
      expect(document.validityMonths, 6);
      expect(document.applyOnline, isTrue);
      expect(document.requirements.single.photocopies, 2);
      expect(document.steps.single.pick('fil'), 'Pumunta sa opisina');
      expect(document.feeNote?.pick('en'), '₱130');
      expect(document.notes, hasLength(1));
      expect(document.tags, ['job-hunt']);
      expect(document.isEmpty, isFalse);
    });

    test('id, name and agency are required', () {
      expect(Document.fromJson(<String, Object?>{}), isNull);
      expect(
        Document.fromJson({
          'name': {'en': 'X'},
          'agency': 'a',
        }),
        isNull,
      );
      expect(
        Document.fromJson({
          'id': 'x',
          'agency': 'a',
        }),
        isNull,
      );
      expect(
        Document.fromJson({
          'id': 'x',
          'name': {'en': 'X'},
        }),
        isNull,
      );
    });

    test('non-list requirements/steps degrade to empty lists', () {
      final document = Document.fromJson({
        'id': 'x',
        'name': {'en': 'X'},
        'agency': 'a',
        'requirements': 'nope',
        'steps': 7,
        'tags': 'nope',
      })!;
      expect(document.requirements, isEmpty);
      expect(document.steps, isEmpty);
      expect(document.tags, isEmpty);
    });
  });

  group('Bundle', () {
    test('parses a bundle with documents, tags and icon', () {
      final bundle = Bundle.fromJson({
        'id': 'job-hunt-pack',
        'name': {'en': 'Job Hunt Pack'},
        'description': {'en': 'Everything for applying'},
        'status': 'draft',
        'documents': ['nbi-clearance', 'sss'],
        'tags': ['job-hunt'],
        'icon': 'work',
        'notes': [
          {'en': 'RA 11261'},
        ],
      })!;
      expect(bundle.documentIds, ['nbi-clearance', 'sss']);
      expect(bundle.icon, 'work');
      expect(bundle.notes.single.en, 'RA 11261');
      expect(bundle.status, DocStatus.draft);
    });

    test('requires id, name and description', () {
      expect(Bundle.fromJson(<String, Object?>{}), isNull);
      expect(
        Bundle.fromJson({
          'id': 'b',
          'name': {'en': 'B'},
        }),
        isNull,
      );
    });
  });

  group('DataBundle', () {
    DataBundle bundleOf() => DataBundle.fromJson({
      'schema_version': 1,
      'data_version': '2026-10-15T00:00:00.000Z',
      'agencies': [
        {'id': 'nbi', 'name': {'en': 'NBI'}},
      ],
      'documents': [
        {
          'id': 'nbi-clearance',
          'name': {'en': 'NBI Clearance'},
          'agency': 'nbi',
          'status': 'draft',
        },
      ],
      'bundles': [
        {
          'id': 'job-hunt-pack',
          'name': {'en': 'Job Hunt'},
          'description': {'en': 'x'},
          'documents': ['nbi-clearance', 'missing-doc'],
        },
      ],
    });

    test('id lookups work', () {
      final data = bundleOf();
      expect(data.agency('nbi')?.name.en, 'NBI');
      expect(data.document('nbi-clearance'), isNotNull);
      expect(data.bundle('job-hunt-pack'), isNotNull);
      expect(data.document('nope'), isNull);
      expect(data.dataVersion, '2026-10-15T00:00:00.000Z');
      expect(data.schemaVersion, 1);
    });

    test('documentsOf keeps authored order and skips unknown ids', () {
      final data = bundleOf();
      final documents = data.documentsOf(data.bundle('job-hunt-pack')!);
      expect(documents.map((d) => d.id), ['nbi-clearance']);
    });
  });

  test('DocStatus.parse is tolerant', () {
    expect(DocStatus.parse('verified'), DocStatus.verified);
    expect(DocStatus.parse('deprecated'), DocStatus.deprecated);
    expect(DocStatus.parse('draft'), DocStatus.draft);
    expect(DocStatus.parse('anything-else'), DocStatus.draft);
    expect(DocStatus.parse(null), DocStatus.draft);
  });

  test('DataBundle.empty is safe to render', () {
    final empty = DataBundle.empty();
    expect(empty.documents, isEmpty);
    expect(empty.bundles, isEmpty);
    expect(empty.agencies, isEmpty);
    expect(empty.dataVersion, 'none');
  });
}

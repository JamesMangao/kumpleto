import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/data/search.dart';
import 'package:kumpleto/models/localized_text.dart';
import 'package:kumpleto/models/models.dart';

Document _document({
  String id = 'barangay-clearance',
  LocalizedText? summary,
  List<String> tags = const <String>[],
  List<Requirement> requirements = const <Requirement>[],
  List<LocalizedText> steps = const <LocalizedText>[],
  List<LocalizedText> notes = const <LocalizedText>[],
}) => Document(
  id: id,
  name: const LocalizedText(
    en: 'Barangay Clearance',
    fil: 'Barangay Clearance',
  ),
  agencyId: 'barangay',
  status: DocStatus.verified,
  summary: summary,
  tags: tags,
  requirements: requirements,
  steps: steps,
  notes: notes,
);

void main() {
  group('normalizeSearch', () {
    test('lowercases, folds accents and collapses whitespace', () {
      expect(normalizeSearch('  Peñafrancia   CITY '), 'penafrancia city');
    });
  });

  group('documentMatches', () {
    test('an empty query matches everything', () {
      expect(documentMatches(_document(), query: '   '), isTrue);
    });

    test('matches a word that only appears in a requirement', () {
      final document = _document(
        requirements: const [
          Requirement(
            id: 'cedula',
            text: LocalizedText(
              en: 'Community tax certificate (cedula)',
              fil: 'Sedula (community tax certificate)',
            ),
          ),
        ],
      );
      expect(documentMatches(document, query: 'cedula'), isTrue);
    });

    test('matches a requirement note', () {
      final document = _document(
        requirements: const [
          Requirement(
            id: 'id',
            text: LocalizedText(en: 'Valid ID', fil: 'Valid ID'),
            note: LocalizedText(
              en: 'A barangay certificate is not accepted',
              fil: 'Hindi tinatanggap ang barangay certificate',
            ),
          ),
        ],
      );
      expect(documentMatches(document, query: 'not accepted'), isTrue);
    });

    test('matches a tag typed with a space instead of a dash', () {
      final document = _document(tags: const ['job-hunt']);
      expect(documentMatches(document, query: 'job hunt'), isTrue);
    });

    test('matches the agency in Filipino', () {
      final document = _document();
      const agency = Agency(
        id: 'barangay',
        name: LocalizedText(en: 'Barangay', fil: 'Tanggapan ng Barangay'),
      );
      expect(
        documentMatches(document, query: 'tanggapan', agency: agency),
        isTrue,
      );
    });

    test('matches an accented word typed without the accent', () {
      final document = _document(
        summary: const LocalizedText(
          en: 'Feast of Our Lady of Peñafrancia',
          fil: 'Pista ng Peñafrancia',
        ),
      );
      expect(documentMatches(document, query: 'penafrancia'), isTrue);
    });

    test('matches a step and extra notes', () {
      final document = _document(
        steps: const [
          LocalizedText(
            en: 'Book an appointment online',
            fil: 'Mag-book ng appointment online',
          ),
        ],
        notes: const [
          LocalizedText(en: 'Bring exact change', fil: 'Magdala ng barya'),
        ],
      );
      expect(documentMatches(document, query: 'appointment'), isTrue);
      expect(documentMatches(document, query: 'exact change'), isTrue);
    });

    test('every word has to appear somewhere', () {
      final document = _document(
        summary: const LocalizedText(en: 'NBI clearance', fil: 'NBI clearance'),
      );
      expect(documentMatches(document, query: 'nbi clearance'), isTrue);
      expect(documentMatches(document, query: 'nbi passport'), isFalse);
    });

    test('an absent word matches nothing', () {
      expect(documentMatches(_document(), query: 'passport'), isFalse);
    });
  });
}

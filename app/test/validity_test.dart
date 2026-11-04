import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/data/validity.dart';
import 'package:kumpleto/models/localized_text.dart';
import 'package:kumpleto/models/models.dart';

Document _document(int? validityMonths) => Document(
  id: 'nbi-clearance',
  name: const LocalizedText(en: 'NBI Clearance', fil: 'NBI Clearance'),
  agencyId: 'nbi',
  status: DocStatus.verified,
  validityMonths: validityMonths,
);

void main() {
  test('valid until is counted from the acquisition day', () {
    expect(validUntilOf(_document(6), DateTime(2026, 11, 4)), DateTime(2027, 5, 4));
  });

  test('month arithmetic cannot overflow a short month', () {
    expect(validUntilOf(_document(1), DateTime(2026, 1, 31)), DateTime(2026, 2, 28));
    expect(validUntilOf(_document(6), DateTime(2026, 8, 31)), DateTime(2027, 2, 28));
  });

  test('no validity period and no acquisition day mean no promise', () {
    expect(validUntilOf(_document(null), DateTime(2026, 11, 4)), isNull);
    expect(validUntilOf(_document(6), null), isNull);
  });

  test('months left rounds down and goes negative after expiry', () {
    expect(monthsBetween(DateTime(2026, 11, 4), DateTime(2027, 5, 4)), 6);
    expect(monthsBetween(DateTime(2026, 11, 5), DateTime(2027, 5, 4)), 5);
    expect(monthsBetween(DateTime(2027, 6, 1), DateTime(2027, 5, 4)), -1);
  });
}

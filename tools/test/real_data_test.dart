// FAKE-FREE: this suite validates the REAL data/ tree and must stay green.
import 'dart:io';

import 'package:kumpleto_tools/kumpleto_data.dart';
import 'package:test/test.dart';

void main() {
  test('real data/ tree has zero errors (warnings allowed: pagibig .com)',
      () {
    final root = repoRoot(Directory.current);
    final ds = DataSet.loadFromDirectory(Directory('${root.path}/data'));
    final report = validateDataSet(
      ds,
      now: DateTime.now().toUtc(),
      schemaDir: Directory('${root.path}/schema'),
    );
    expect(
      report.errors.map((e) => e.message).toList(),
      isEmpty,
      reason: 'data/ must always validate cleanly; fix the data, not the test',
    );
  });
}

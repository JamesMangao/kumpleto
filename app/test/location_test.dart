import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/data/location.dart';

/// A tiny in-memory asset bundle: one gzipped barangay shard.
class _ShardBundle extends CachingAssetBundle {
  _ShardBundle(this.groups);

  final Map<String, List<Place>> groups;

  @override
  Future<ByteData> load(String key) async {
    final payload = jsonEncode({
      for (final entry in groups.entries)
        entry.key: [for (final place in entry.value) place.toJson()],
    });
    final packed = Uint8List.fromList(
      gzip.encode(Uint8List.fromList(utf8.encode(payload))),
    );
    return ByteData.sublistView(packed);
  }
}

/// NCR has no province, and Manila's barangays hang off its sub-municipalities
/// (`1380601`…`1380614`) rather than off the city code, so a picker that reads
/// only the exact city code would show Manila as empty.
void main() {
  final bundle = _ShardBundle({
    '1380600': const [], // the city row itself carries no barangays
    '1380601': const [
      Place(code: '1380601002', name: 'Barangay 2'),
      Place(code: '1380601001', name: 'Barangay 1'),
    ],
    '1380602': const [Place(code: '1380602001', name: 'Barangay 287')],
    '1380200': const [Place(code: '1380200001', name: 'Almanza Uno')],
  });

  test('a city gathers its sub-municipalities, name-sorted', () async {
    final source = BarangaySource(bundle: bundle);
    final barangays = await source.barangaysFor(
      shard: 'R13',
      cityCode: '1380600',
    );
    expect(
      [for (final place in barangays) place.name],
      ['Barangay 1', 'Barangay 2', 'Barangay 287'],
    );
  });

  test('a city with its own rows is not widened to its neighbours', () async {
    final source = BarangaySource(bundle: bundle);
    final barangays = await source.barangaysFor(
      shard: 'R13',
      cityCode: '1380200',
    );
    expect([for (final place in barangays) place.name], ['Almanza Uno']);
  });
}

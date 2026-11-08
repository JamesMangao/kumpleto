import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/data/location.dart';

/// The location picker is only as good as the bundled PSGC assets: the index
/// lists a city by code, and its barangays live in a per-province shard under
/// that same code. When the two were generated from different code paddings the
/// picker silently offered an empty drawer, so these tests read the real
/// assets and walk every city the picker can reach.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlaceIndex index;
  late BarangaySource source;

  setUpAll(() async {
    index = await PlaceIndex.load();
    source = BarangaySource();
  });

  test('every city the picker can reach lists its barangays', () async {
    final missing = <String>[];
    var checked = 0;

    for (final region in index.regions) {
      final provinces = index.provincesOf(region.code);
      final shards = provinces.isEmpty
          ? <Place?, String>{null: PlaceIndex.regionShard(region.code)}
          : <Place?, String>{
              for (final province in provinces) province: province.code,
            };

      for (final entry in shards.entries) {
        final cities = index.citiesOf(
          regionCode: region.code,
          province: entry.key,
        );
        if (cities.isEmpty) {
          missing.add('${region.name}: no cities');
          continue;
        }
        for (final city in cities) {
          checked++;
          final barangays = await source.barangaysFor(
            shard: entry.value,
            cityCode: city.code,
          );
          if (barangays.isEmpty) missing.add('${region.name} / ${city.name}');
        }
      }
    }

    expect(
      missing,
      isEmpty,
      reason: 'cities with an empty barangay picker: ${missing.take(10).join(', ')}',
    );
    expect(checked, greaterThan(1600));
  });

  test('San Pedro, Laguna offers Pacita 1', () async {
    final laguna = index
        .provincesOf('04')
        .firstWhere((place) => place.name == 'Laguna');
    final city = index
        .citiesOf(regionCode: '04', province: laguna)
        .firstWhere((place) => place.name.contains('San Pedro'));
    final barangays = await source.barangaysFor(
      shard: laguna.code,
      cityCode: city.code,
    );
    expect(barangays.map((place) => place.name), contains('Pacita 1'));
  });

  test('NCR skips the province step and Manila lists barangays', () async {
    expect(index.provincesOf('13'), isEmpty);
    final cities = index.citiesOf(regionCode: '13');
    expect(cities, isNotEmpty);
    final manila = cities.firstWhere(
      (place) => place.name == 'City of Manila',
      orElse: () => cities.first,
    );
    final barangays = await source.barangaysFor(
      shard: PlaceIndex.regionShard('13'),
      cityCode: manila.code,
    );
    expect(barangays, isNotEmpty);
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// One selectable place: a PSGC code plus its display name.
class Place {
  const Place({required this.code, required this.name});

  final String code;
  final String name;

  factory Place.fromJson(Map<String, Object?> json) => Place(
    code: json['c'] as String? ?? '',
    name: json['n'] as String? ?? '',
  );

  Map<String, Object?> toJson() => {'c': code, 'n': name};

  @override
  bool operator ==(Object other) => other is Place && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => name;
}

/// The bundled place names, loaded from `assets/psgc/index.json`.
///
/// About 390 KB in total: the index (regions, provinces, cities) plus one
/// gzipped barangay shard per province, which is only read when the user opens
/// that province.
class PlaceIndex {
  const PlaceIndex({
    required this.regions,
    required this.provinces,
    required this.cities,
    required this.regionShards,
    required this.release,
    required this.attribution,
  });

  final List<Place> regions;

  /// Region code → provinces. NCR and highly urbanised cities have none.
  final Map<String, List<Place>> provinces;

  /// Shard code → cities or municipalities.
  final Map<String, List<Place>> cities;

  /// Region code → every shard that belongs to it.
  final Map<String, List<String>> regionShards;

  final String release;
  final String attribution;

  static const String assetPath = 'assets/psgc/index.json';

  static Future<PlaceIndex> load({AssetBundle? bundle}) async {
    final source = bundle ?? rootBundle;
    final decoded =
        jsonDecode(await source.loadString(assetPath)) as Map<String, Object?>;

    List<Place> places(Object? raw) => [
      for (final entry in (raw as List<Object?>? ?? const []))
        Place.fromJson(entry as Map<String, Object?>),
    ];
    Map<String, List<Place>> groups(Object? raw) => {
      for (final entry in (raw as Map<String, Object?>? ?? const {}).entries)
        entry.key: places(entry.value),
    };

    return PlaceIndex(
      regions: places(decoded['regions']),
      provinces: groups(decoded['provinces']),
      cities: groups(decoded['cities']),
      regionShards: {
        for (final entry
            in (decoded['regionShards'] as Map<String, Object?>? ?? const {})
                .entries)
          entry.key: [
            for (final shard in (entry.value as List<Object?>? ?? const []))
              shard as String,
          ],
      },
      release: decoded['release'] as String? ?? '',
      attribution: decoded['attribution'] as String? ?? '',
    );
  }

  List<Place> provincesOf(String? regionCode) =>
      provinces[regionCode] ?? const [];

  /// The shard that holds [regionCode]'s cities when it has no province.
  static String regionShard(String regionCode) => 'R$regionCode';

  /// Shard for a city selection: the province code, or the region shard.
  String shardFor({String? regionCode, Place? province}) {
    if (province != null && province.code.isNotEmpty) return province.code;
    return regionShard(regionCode ?? '');
  }

  /// Cities of the given region/province pair.
  ///
  /// Regions without provinces (NCR) list every city from every shard that
  /// belongs to them, so the cascade still ends at a real city.
  List<Place> citiesOf({String? regionCode, Place? province}) {
    if (province != null && province.code.isNotEmpty) {
      return cities[province.code] ?? const [];
    }
    final shards = regionShards[regionCode] ?? const <String>[];
    if (shards.isEmpty) return const [];
    final all = <Place>[
      for (final shard in shards) ...(cities[shard] ?? const <Place>[]),
    ];
    all.sort((a, b) => a.name.compareTo(b.name));
    return all;
  }
}

/// A saved location: region → province (optional) → city → barangay + ZIP.
class SavedLocation {
  const SavedLocation({
    this.region,
    this.province,
    this.city,
    this.barangay,
    this.zip = '',
  });

  final Place? region;
  final Place? province;
  final Place? city;
  final Place? barangay;
  final String zip;

  bool get isEmpty => city == null && barangay == null;

  /// "Pacita 1, San Pedro, Laguna" (province omitted when there is none).
  String get label => [
    if (barangay != null) barangay!.name,
    if (city != null) city!.name,
    if (province != null) province!.name,
  ].join(', ');

  static const String prefsKey = 'saved_location';

  static SavedLocation? read(SharedPreferences prefs) {
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, Object?>;
      Place? place(Object? value) => value == null
          ? null
          : Place.fromJson(value as Map<String, Object?>);
      return SavedLocation(
        region: place(map['region']),
        province: place(map['province']),
        city: place(map['city']),
        barangay: place(map['barangay']),
        zip: map['zip'] as String? ?? '',
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> save(SharedPreferences prefs) => prefs.setString(
    prefsKey,
    jsonEncode({
      'region': region?.toJson(),
      'province': province?.toJson(),
      'city': city?.toJson(),
      'barangay': barangay?.toJson(),
      'zip': zip,
    }),
  );
}

/// Loads barangay shards on demand and keeps them for the session.
class BarangaySource {
  BarangaySource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final Map<String, Map<String, List<Place>>> _cache = {};

  /// Barangays of [cityCode] inside [shard], alphabetical.
  Future<List<Place>> barangaysFor({
    required String shard,
    required String cityCode,
  }) async {
    final groups = _cache[shard] ?? await _loadShard(shard);
    return groups[cityCode] ?? const [];
  }

  Future<Map<String, List<Place>>> _loadShard(String shard) async {
    final data = await _bundle.load('assets/psgc/bgy/$shard.json.gz');
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final decoded =
        jsonDecode(utf8.decode(gzip.decode(bytes))) as Map<String, Object?>;
    final groups = {
      for (final entry in decoded.entries)
        entry.key: [
          for (final raw in (entry.value as List<Object?>))
            Place.fromJson(raw as Map<String, Object?>),
        ],
    };
    _cache[shard] = groups;
    return groups;
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Asset bundle that behaves like `rootBundle`: an absent key throws a
/// [FlutterError], exactly what a missing release asset does.
class FakeAssetBundle extends CachingAssetBundle {
  FakeAssetBundle(this.assets);

  /// Asset key → file contents.
  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) async {
    final value = assets[key];
    if (value == null) throw FlutterError('Asset not found: "$key"');
    return ByteData.view(Uint8List.fromList(utf8.encode(value)).buffer);
  }
}

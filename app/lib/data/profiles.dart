/// Who the checklist is for.
///
/// A household usually chases documents for more than one person, so the
/// progress table is keyed per profile. The first profile is always
/// [Profile.me] — it is not stored, and its label is localized — while the
/// extra people a reader adds are kept as a small JSON list in
/// SharedPreferences. Nothing here leaves the device.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Profile {
  const Profile({required this.id, this.name = ''});

  /// The reader themselves: always present, never removable.
  static const String meId = 'me';
  static const Profile me = Profile(id: meId);

  final String id;

  /// Empty for [me]; the UI shows the localized "Me" label instead.
  final String name;

  bool get isMe => id == meId;

  Map<String, Object?> toJson() => {'id': id, 'name': name};

  static Profile? fromJson(Object? json) {
    if (json is! Map<Object?, Object?>) return null;
    final id = json['id'];
    if (id is! String || id.isEmpty || id == meId) return null;
    final name = json['name'];
    return Profile(
      id: id,
      name: name is String ? name.trim() : '',
    );
  }

  @override
  bool operator ==(Object other) => other is Profile && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Reads and writes the profile list and which one is active.
class ProfilesStore {
  ProfilesStore(this._prefs);

  /// SharedPreferences key holding the added profiles (never [Profile.me]).
  static const String listKey = 'profiles';

  /// SharedPreferences key holding the active profile id.
  static const String activeKey = 'active_profile';

  final SharedPreferences _prefs;

  /// `me` first, then the added people in the order they were created.
  List<Profile> read() {
    final raw = _prefs.getString(listKey);
    if (raw == null || raw.isEmpty) return const [Profile.me];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [Profile.me];
      return [
        Profile.me,
        for (final entry in decoded) ?Profile.fromJson(entry),
      ];
    } on FormatException {
      // A corrupt list is not worth crashing over: fall back to "me" and let
      // the next write repair it.
      return const [Profile.me];
    }
  }

  Future<void> write(List<Profile> profiles) => _prefs.setString(
    listKey,
    jsonEncode([
      for (final profile in profiles)
        if (!profile.isMe) profile.toJson(),
    ]),
  );

  /// The stored active id, or [Profile.meId] when it is missing or refers to a
  /// profile that no longer exists.
  String readActiveId([Iterable<Profile>? known]) {
    final id = _prefs.getString(activeKey);
    if (id == null || id.isEmpty) return Profile.meId;
    if (known != null && !known.any((profile) => profile.id == id)) {
      return Profile.meId;
    }
    return id;
  }

  Future<void> writeActiveId(String id) => _prefs.setString(activeKey, id);
}

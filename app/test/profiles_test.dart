import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/data/profiles.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Profiles are local-only: "me" always exists and is never stored, extra
/// people live in a JSON list, and a stale active id falls back to "me".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProfilesStore> store([Map<String, Object> initial = const {}]) async {
    SharedPreferences.setMockInitialValues(initial);
    return ProfilesStore(await SharedPreferences.getInstance());
  }

  test('a fresh install has exactly one profile: me', () async {
    final prefs = await store();
    expect(prefs.read(), [Profile.me]);
    expect(prefs.read().single.isMe, isTrue);
    expect(prefs.readActiveId(), Profile.meId);
  });

  test('added people round-trip in order, without storing me', () async {
    final prefs = await store();
    await prefs.write(const [
      Profile.me,
      Profile(id: 'p1', name: 'Ana'),
      Profile(id: 'p2', name: 'Ben'),
    ]);

    final read = prefs.read();
    expect(read.map((profile) => profile.id), ['me', 'p1', 'p2']);
    expect(read.map((profile) => profile.name), ['', 'Ana', 'Ben']);

    final raw = jsonDecode(
      (await SharedPreferences.getInstance()).getString(ProfilesStore.listKey)!,
    );
    expect(raw, hasLength(2));
  });

  test('the active profile is remembered', () async {
    final prefs = await store();
    await prefs.writeActiveId('p1');
    expect(prefs.readActiveId(), 'p1');
  });

  test('an active id that no longer exists falls back to me', () async {
    final prefs = await store({'active_profile': 'gone'});
    expect(prefs.readActiveId(const [Profile.me]), Profile.meId);
  });

  test('a corrupt list degrades to me instead of throwing', () async {
    final prefs = await store({ProfilesStore.listKey: '{not json'});
    expect(prefs.read(), [Profile.me]);
  });

  test('entries without a usable id are dropped', () async {
    final prefs = await store({
      ProfilesStore.listKey: jsonEncode([
        {'id': '', 'name': 'Nobody'},
        {'id': 'me', 'name': 'Impostor'},
        {'id': 'p9', 'name': '  Ana  '},
        'junk',
      ]),
    });

    final read = prefs.read();
    expect(read.map((profile) => profile.id), ['me', 'p9']);
    expect(read.last.name, 'Ana');
  });
}

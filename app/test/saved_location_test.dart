import 'package:flutter_test/flutter_test.dart';
import 'package:kumpleto/data/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A household often chases documents for people who live somewhere else, so
/// every profile carries its own place. `me` keeps the original key, which is
/// what a location saved before profiles existed still reads from.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sanPedro = SavedLocation(
    city: Place(code: '0403425', name: 'City of San Pedro'),
    barangay: Place(code: '0403425026', name: 'Pacita 1'),
    zip: '4023',
  );
  const manila = SavedLocation(
    city: Place(code: '1380600', name: 'City of Manila'),
    zip: '1000',
  );

  Future<SharedPreferences> prefs([Map<String, Object> initial = const {}]) async {
    SharedPreferences.setMockInitialValues(initial);
    return SharedPreferences.getInstance();
  }

  test('each profile keeps its own location', () async {
    final store = await prefs();
    await sanPedro.save(store);
    await manila.save(store, profileId: 'p1');

    expect(SavedLocation.read(store)!.barangay!.name, 'Pacita 1');
    expect(SavedLocation.read(store, profileId: 'p1')!.city!.name, 'City of Manila');
    expect(SavedLocation.read(store, profileId: 'p2'), isNull);
  });

  test('clearing one profile leaves the others alone', () async {
    final store = await prefs();
    await sanPedro.save(store);
    await manila.save(store, profileId: 'p1');

    await SavedLocation.clear(store, profileId: 'p1');

    expect(SavedLocation.read(store, profileId: 'p1'), isNull);
    expect(SavedLocation.read(store)!.city!.name, 'City of San Pedro');
  });

  test('a location saved before profiles existed still belongs to me', () async {
    final store = await prefs({
      SavedLocation.prefsKey:
          '{"city":{"c":"0403425","n":"City of San Pedro"},"zip":"4023"}',
    });

    expect(SavedLocation.read(store)!.city!.name, 'City of San Pedro');
    expect(SavedLocation.prefsKeyFor('p1'), isNot(SavedLocation.prefsKey));
  });
}

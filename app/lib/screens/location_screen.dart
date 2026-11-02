import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../data/location.dart';
import '../data/providers.dart';
import '../l10n/app_localizations.dart';
import 'scaffold_with_nav.dart';

/// The bundled PSGC index (about 390 KB), loaded once per app run.
final placeIndexProvider = FutureProvider<PlaceIndex>(
  (ref) => PlaceIndex.load(),
);

/// Region → province → city/municipality → barangay, plus a postal code.
///
/// Fully offline: the index and the barangay shards ship in the APK. Nothing
/// about the selected place is ever sent anywhere — it is stored in
/// SharedPreferences next to the user's language and theme.
class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  final TextEditingController _zip = TextEditingController();
  final BarangaySource _barangays = BarangaySource();

  Place? _region;
  Place? _province;
  Place? _city;
  Place? _barangay;
  Future<List<Place>>? _barangayFuture;
  bool _hydrated = false;

  @override
  void dispose() {
    _zip.dispose();
    super.dispose();
  }

  void _hydrate(PlaceIndex index) {
    if (_hydrated) return;
    _hydrated = true;
    final saved = SavedLocation.read(ref.read(sharedPreferencesProvider));
    if (saved == null) return;
    _region = saved.region;
    _province = saved.province;
    _city = saved.city;
    _barangay = saved.barangay;
    _zip.text = saved.zip;
    if (_city != null) _loadBarangays(index);
  }

  void _loadBarangays(PlaceIndex index) {
    final city = _city;
    if (city == null) {
      _barangayFuture = null;
      return;
    }
    _barangayFuture = _barangays.barangaysFor(
      shard: index.shardFor(regionCode: _region?.code, province: _province),
      cityCode: city.code,
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final location = SavedLocation(
      region: _region,
      province: _province,
      city: _city,
      barangay: _barangay,
      zip: _zip.text.trim(),
    );
    await location.save(ref.read(sharedPreferencesProvider));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.locationSaved)));
    Navigator.of(context).maybePop();
  }

  Future<void> _clear() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(SavedLocation.prefsKey);
    if (!mounted) return;
    setState(() {
      _region = null;
      _province = null;
      _city = null;
      _barangay = null;
      _barangayFuture = null;
      _zip.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final index = ref.watch(placeIndexProvider);

    return Scaffold(
      appBar: unofficialAppBar(context, l10n.locationTitle),
      body: SafeArea(
        child: index.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('$error', textAlign: TextAlign.center),
            ),
          ),
          data: (data) {
            _hydrate(data);
            final provinces = data.provincesOf(_region?.code);
            final cities = data.citiesOf(
              regionCode: _region?.code,
              province: _province,
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Text(
                  l10n.locationSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                _PlaceField(
                  label: l10n.locationRegion,
                  items: data.regions,
                  value: _region,
                  onChanged: (value) => setState(() {
                    _region = value;
                    _province = null;
                    _city = null;
                    _barangay = null;
                    _barangayFuture = null;
                  }),
                ),
                const SizedBox(height: 12),

                if (provinces.isNotEmpty) ...[
                  _PlaceField(
                    label: l10n.locationProvince,
                    items: provinces,
                    value: _province,
                    onChanged: (value) => setState(() {
                      _province = value;
                      _city = null;
                      _barangay = null;
                      _barangayFuture = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                ],

                _PlaceField(
                  label: l10n.locationCity,
                  items: cities,
                  value: _city,
                  onChanged: (value) => setState(() {
                    _city = value;
                    _barangay = null;
                    _loadBarangays(data);
                  }),
                ),
                const SizedBox(height: 12),

                FutureBuilder<List<Place>>(
                  future: _barangayFuture,
                  builder: (context, snapshot) {
                    final items = snapshot.data ?? const <Place>[];
                    return _PlaceField(
                      label: l10n.locationBarangay,
                      items: items,
                      value: _barangay,
                      onChanged: (value) =>
                          setState(() => _barangay = value),
                    );
                  },
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _zip,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.locationZip,
                    helperText: l10n.locationZipHint,
                    helperMaxLines: 2,
                    counterText: '',
                    prefixIcon: const Icon(Icons.markunread_mailbox_outlined),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _city == null ? null : _save,
                    child: Text(l10n.locationSave),
                  ),
                ),
                if (_region != null) ...[
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _clear,
                    child: Text(
                      l10n.locationClear,
                      style: const TextStyle(color: AppTheme.statusRedText),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  l10n.locationAttribution,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PlaceField extends StatelessWidget {
  const _PlaceField({
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<Place> items;
  final Place? value;
  final ValueChanged<Place?> onChanged;

  @override
  Widget build(BuildContext context) {
    // A saved place can be missing from a newer dataset: never assert on it.
    final selected = value != null && items.contains(value) ? value : null;
    final enabled = items.isNotEmpty;
    return DropdownButtonFormField<Place>(
      initialValue: selected,
      isExpanded: true,
      menuMaxHeight: 420,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.place_outlined, size: 20),
      ),
      items: [
        for (final place in items)
          DropdownMenuItem(
            value: place,
            child: Text(place.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }
}

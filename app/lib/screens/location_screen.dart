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

  /// A barangay saved before the shard was read; resolved once the list loads.
  Place? _restoreBarangay;

  @override
  void dispose() {
    _zip.dispose();
    super.dispose();
  }

  /// The place a saved value refers to in this dataset: by code, or — when a
  /// PSGC update changed the codes, as the 3Q 2026 one did for NIR — by name.
  /// Returns null when the name is gone too, so nothing is asserted on.
  Place? _match(List<Place> items, Place? saved) {
    if (saved == null) return null;
    for (final place in items) {
      if (place == saved) return place;
    }
    final name = saved.name.toLowerCase();
    for (final place in items) {
      if (place.name.toLowerCase() == name) return place;
    }
    return null;
  }

  void _hydrate(PlaceIndex index) {
    if (_hydrated) return;
    _hydrated = true;
    final saved = ref.read(savedLocationProvider);
    if (saved == null) return;
    _region = _match(index.regions, saved.region) ?? saved.region;
    _province =
        _match(index.provincesOf(_region?.code), saved.province) ??
        saved.province;
    _city =
        _match(
          index.citiesOf(regionCode: _region?.code, province: _province),
          saved.city,
        ) ??
        saved.city;
    _restoreBarangay = saved.barangay;
    _zip.text = saved.zip;
    if (_city != null) _loadBarangays(index);
  }

  void _loadBarangays(PlaceIndex index) {
    final city = _city;
    if (city == null) {
      _barangayFuture = null;
      return;
    }
    // A saved barangay is restored once, after its shard is readable.
    final restore = _restoreBarangay;
    _restoreBarangay = null;
    _barangayFuture = _barangays
        .barangaysFor(
          shard: index.shardFor(regionCode: _region?.code, province: _province),
          cityCode: city.code,
        )
        .then((items) {
          final match = _match(items, restore);
          if (match != null && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _barangay = match);
            });
          }
          return items;
        });
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
    await location.save(
      ref.read(sharedPreferencesProvider),
      profileId: ref.read(activeProfileProvider),
    );
    ref.read(savedLocationProvider.notifier).set(location);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.locationSaved)));
    Navigator.of(context).maybePop();
  }

  Future<void> _clear() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await SavedLocation.clear(
      prefs,
      profileId: ref.read(activeProfileProvider),
    );
    ref.read(savedLocationProvider.notifier).set(null);
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
    final profile = ref.watch(currentProfileProvider);
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
                const SizedBox(height: 6),
                Text(
                  l10n.locationForProfile(
                    profile.isMe ? l10n.profileMe : profile.name,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: accentColorOf(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),

                _PlaceField(
                  key: const ValueKey('region'),
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
                    key: ValueKey('province:${_region?.code}'),
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
                  key: ValueKey('city:${_region?.code}:${_province?.code}'),
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
                    final loading =
                        snapshot.connectionState == ConnectionState.waiting;
                    final failed = snapshot.hasError;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PlaceField(
                          key: ValueKey('barangay:${_city?.code}'),
                          label: l10n.locationBarangay,
                          items: items,
                          value: _barangay,
                          onChanged: (value) =>
                              setState(() => _barangay = value),
                        ),
                        if (loading)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 12),
                            child: Text(
                              l10n.locationPlacesLoading,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        if (failed)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l10n.locationPlacesUnavailable,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppTheme.statusRedText,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _loadBarangays(data)),
                                  child: Text(l10n.locationRetry),
                                ),
                              ],
                            ),
                          ),
                      ],
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
    super.key,
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

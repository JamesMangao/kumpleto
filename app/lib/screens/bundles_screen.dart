import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../l10n/app_localizations.dart';
import '../widgets/bundle_card.dart';
import 'scaffold_with_nav.dart';

/// Every life-event bundle, in the same grid Home uses.
///
/// Home shows the first six so the page does not end on an orphan card; the
/// rest live here behind "See all >".
class BundlesScreen extends ConsumerWidget {
  const BundlesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final bundles = ref.watch(bundlesProvider);
    final progress =
        ref.watch(progressProvider).value ?? const <String, Set<String>>{};

    return Scaffold(
      appBar: unofficialAppBar(context, l10n.homeBundles),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth > 340
                ? (constraints.maxWidth - 32 - 12) / 2
                : constraints.maxWidth;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final bundle in bundles)
                    SizedBox(
                      width: cardWidth,
                      child: BundleCard(bundle: bundle, progress: progress),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

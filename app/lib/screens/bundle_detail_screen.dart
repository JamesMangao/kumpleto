import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';

/// Bundle detail screen. P4 adds ordered documents with per-doc and
/// overall progress.
class BundleDetailScreen extends StatelessWidget {
  const BundleDetailScreen({super.key, required this.bundleId});

  final String bundleId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.back,
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.bundleDetailTitle),
      ),
      body: SafeArea(
        child: Center(
          child: Text(bundleId, style: Theme.of(context).textTheme.titleLarge),
        ),
      ),
    );
  }
}

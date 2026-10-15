import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'scaffold_with_nav.dart';

/// Home screen. P4 replaces the placeholder body with search, bundle cards
/// with aggregate progress, the "Continue" row, and tag chips.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: unofficialAppBar(context, l10n.appTitle),
      body: SafeArea(
        child: Center(
          child: Text(
            l10n.appTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
    );
  }
}

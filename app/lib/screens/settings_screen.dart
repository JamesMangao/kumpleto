import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'scaffold_with_nav.dart';

/// Settings screen. P4 adds language/theme pickers, data version + update
/// check, reset progress, about/disclaimer/privacy/licenses, GitHub link.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: unofficialAppBar(context, l10n.settingsTitle),
      body: SafeArea(
        child: Center(
          child: Text(
            l10n.settingsTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
    );
  }
}

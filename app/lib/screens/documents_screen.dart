import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'scaffold_with_nav.dart';

/// Documents list screen. P4 adds search, agency/tag filters, status badges.
class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: unofficialAppBar(context, l10n.documentsTitle),
      body: SafeArea(
        child: Center(
          child: Text(
            l10n.documentsTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
    );
  }
}

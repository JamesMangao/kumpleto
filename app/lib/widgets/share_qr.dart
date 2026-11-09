import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';

/// Shows a checklist as a QR code so a friend can open it without typing or
/// sending a link — useful in a barangay hall queue with no data.
///
/// The code encodes the public page for the checklist, which is the same URL
/// the app answers to, so scanning it opens the page in a browser (and offers
/// the app when it is installed).
Future<void> showChecklistQr(
  BuildContext context, {
  required String title,
  required Uri page,
}) {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.docQrTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
              ),
            ),
            child: QrImageView(
              data: page.toString(),
              version: QrVersions.auto,
              size: 216,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF14211D),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF14211D),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.docQrHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.close),
        ),
      ],
    ),
  );
}

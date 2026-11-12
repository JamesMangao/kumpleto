import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';

/// Shows a checklist as a QR code so a friend can open it without typing or
/// sending a link — useful in a barangay hall queue with no data.
///
/// Two links are offered, because they fail in opposite ways:
///
/// * [deepLink] is the `kumpleto://` link. It opens the checklist straight in
///   the installed app, offline — the reason someone shows a code in a queue
///   with no data — but does nothing at all on a phone without Kumpleto.
/// * [page] is the public web page. It works for anyone, including a phone
///   without the app, but needs a browser and a connection to load.
///
/// The app link is the default: a code that only works with a connection
/// defeats the point of scanning one at the counter. The web page is one tap
/// away for a friend who has not installed Kumpleto.
Future<void> showChecklistQr(
  BuildContext context, {
  required String title,
  required Uri page,
  required Uri deepLink,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) =>
        _ChecklistQrDialog(title: title, page: page, deepLink: deepLink),
  );
}

class _ChecklistQrDialog extends StatefulWidget {
  const _ChecklistQrDialog({
    required this.title,
    required this.page,
    required this.deepLink,
  });

  final String title;
  final Uri page;
  final Uri deepLink;

  @override
  State<_ChecklistQrDialog> createState() => _ChecklistQrDialogState();
}

class _ChecklistQrDialogState extends State<_ChecklistQrDialog> {
  /// The app link by default, so the code in front of the reader works with no
  /// connection. The web page is the fallback for a phone without the app.
  bool _useAppLink = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final target = _useAppLink ? widget.deepLink : widget.page;

    // A plain Dialog, not an AlertDialog: the latter measures its content with
    // IntrinsicWidth, and QrImageView lays itself out in a LayoutBuilder, which
    // cannot answer an intrinsic query — it throws during layout and the code
    // never appears.
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.docQrTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
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
                  data: target.toString(),
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
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    label: Text(l10n.docQrModeWeb),
                    selected: !_useAppLink,
                    onSelected: (_) => setState(() => _useAppLink = false),
                  ),
                  ChoiceChip(
                    label: Text(l10n.docQrModeApp),
                    selected: _useAppLink,
                    onSelected: (_) => setState(() => _useAppLink = true),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                target.toString(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _useAppLink ? l10n.docQrHint : l10n.docQrHintWeb,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

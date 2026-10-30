import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/settings.dart';
import '../l10n/app_localizations.dart';

/// First-run screen: disclaimer + language choice, acknowledged once.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late String _language;

  @override
  void initState() {
    super.initState();
    _language = widget.settings.language;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        // Scrollable content with a pinned acknowledge button: at large
        // text scales (200%) the disclaimer and language picker no longer
        // fit on one screen.
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),
                      Text(
                        l10n.onboardingTitle,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 24),
                      Card(
                        color: colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            l10n.onboardingDisclaimer,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onErrorContainer,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(l10n.onboardingLanguageLabel),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'system',
                            label: Text('System'),
                          ),
                          ButtonSegment(value: 'en', label: Text('English')),
                          ButtonSegment(value: 'fil', label: Text('Filipino')),
                        ],
                        selected: {_language},
                        onSelectionChanged: (selection) {
                          setState(() => _language = selection.first);
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _acknowledge,
                  child: Text(l10n.onboardingAcknowledge),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acknowledge() async {
    await widget.settings.setLanguage(_language);
    await widget.settings.setFirstRunDone();
    if (mounted) context.go('/');
  }
}

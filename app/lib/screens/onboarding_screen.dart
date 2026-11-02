import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/settings.dart';
import '../core/theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/shared.dart';

/// First-run screen matching design mockup b405cadf-3745-47ea-b999-422d2441c2e9.jpg.
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
    _language = widget.settings.language == 'fil' ? 'fil' : 'en';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Decorative top-left corner organic shape
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF142921).withValues(alpha: 0.5)
                    : const Color(0xFFE4F3ED).withValues(alpha: 0.8),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(160),
                ),
              ),
            ),
          ),
          // Decorative bottom-right corner organic shape
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF142921).withValues(alpha: 0.5)
                    : const Color(0xFFE4F3ED).withValues(alpha: 0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(150),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 12),
                          // Center Brand Block
                          Column(
                            children: [
                              const SizedBox(height: 24),
                              const KumpletoLogo(size: 96, radius: 26),
                              const SizedBox(height: 20),
                              Text(
                                l10n.onboardingTitle,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 26,
                                  letterSpacing: -0.5,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _language == 'fil'
                                    ? 'Alamin ang dadalhing papel.\nTsek-an isa-isa.'
                                    : 'Know what papers to bring.\nTick them off.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 15,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // Disclaimer Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1A2B24)
                                  : const Color(0xFFEAF5F1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF284036)
                                    : const Color(0xFFCEE5DC),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  color: isDark
                                      ? const Color(0xFF8CE0C4)
                                      : AppTheme.primaryTeal,
                                  size: 28,
                                ),
                                const SizedBox(width: 14),
                                Container(
                                  height: 36,
                                  width: 1,
                                  color: isDark
                                      ? const Color(0xFF385246)
                                      : const Color(0xFFB8D9CC),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    l10n.onboardingDisclaimer,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDark
                                          ? const Color(0xFFD6E8E0)
                                          : const Color(0xFF1B3D32),
                                      fontWeight: FontWeight.w500,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Language Selection Section
                          Column(
                            children: [
                              Text(
                                l10n.onboardingLanguageLabel,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'en',
                                    label: Text(
                                      'English',
                                      style: TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  ButtonSegment(
                                    value: 'fil',
                                    label: Text(
                                      'Filipino',
                                      style: TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                                selected: {_language},
                                onSelectionChanged: (selected) {
                                  final lang = selected.first;
                                  setState(() => _language = lang);
                                  widget.settings.setLanguage(lang);
                                },
                                showSelectedIcon: false,
                                style: ButtonStyle(
                                  backgroundColor:
                                      WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return AppTheme.primaryTeal;
                                    }
                                    return isDark
                                        ? const Color(0xFF1E2F27)
                                        : const Color(0xFFE8F3EE);
                                  }),
                                  foregroundColor:
                                      WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return Colors.white;
                                    }
                                    return isDark
                                        ? Colors.white70
                                        : AppTheme.textPrimaryLight;
                                  }),
                                  shape: WidgetStateProperty.all(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  side: WidgetStateProperty.all(BorderSide.none),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // Bottom Actions: Acknowledge Button + Privacy
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: FilledButton(
                                  onPressed: _acknowledge,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.primaryTeal,
                                    shape: const StadiumBorder(),
                                  ),
                                  child: Text(
                                    l10n.onboardingAcknowledge,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => _showPrivacyDialog(context),
                                child: Text(
                                  l10n.settingsPrivacy,
                                  style: TextStyle(
                                    color: AppTheme.primaryTeal,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppTheme.primaryTeal,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy'),
        content: const SingleChildScrollView(
          child: Text(
            'Kumpleto is an offline-first application. It does not collect, track, or share any personal data. All checklist progress is stored locally on your device.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _acknowledge() async {
    await widget.settings.setLanguage(_language);
    await widget.settings.setFirstRunDone();
    if (mounted) context.go('/');
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/gate_colors.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../l10n/app_localizations.dart';

/// Grounded, citizen-first Welcome & Onboarding screen for Kumpleto.
///
/// Designed to clearly introduce Kumpleto as an unofficial, offline checklist
/// for Philippine government document requirements (PSA, NBI, Passport, etc.).
/// Features clean civil layout, responsive typography, bilingual language
/// selection, and official disclaimer gate.
///
/// Colours come from the app theme rather than fixed dark values, so the flow
/// matches the welcome scene: light mode stays light, dark mode stays dark.
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
    final isFil = _language == 'fil';
    final c = GateColors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24 > 0
                      ? constraints.maxHeight - 24
                      : 0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Header & Intro
                    Column(
                      children: [
                        _buildTopBadge(l10n, c),
                        const SizedBox(height: 18),
                        _buildHeroLogo(c),
                        const SizedBox(height: 14),
                        _buildHeadline(l10n, isFil, c),
                        const SizedBox(height: 18),
                        _buildFeatureHighlights(isFil, c),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Controls & CTA
                    Column(
                      children: [
                        _buildLanguageSelector(l10n, c),
                        const SizedBox(height: 16),
                        _buildCtaButton(l10n),
                        const SizedBox(height: 6),
                        _buildPrivacyButton(l10n, c),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBadge(AppLocalizations l10n, GateColors c) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border, width: 1.2),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.accent,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.unofficialBadge.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: c.accent,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '• 100% OFFLINE',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: c.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroLogo(GateColors c) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.accent, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/logo/app-icon.png',
            width: 42,
            height: 42,
            errorBuilder: (_, _, _) => Icon(
              Icons.assignment_turned_in_rounded,
              color: c.accent,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeadline(AppLocalizations l10n, bool isFil, GateColors c) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            l10n.onboardingTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            isFil
                ? 'Alamin ang dadalhing papel bago pumila.\nI-tsek ang requirements para sa PSA, NBI, Passport, atbp.'
                : 'Know what documents to bring before queuing.\nCheck requirements for PSA, NBI, Passport, and more.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.muted,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureHighlights(bool isFil, GateColors c) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        _FeaturePill(
          colors: c,
          icon: Icons.checklist_rounded,
          label: isFil ? '12+ Dokumento' : '12+ Documents',
        ),
        _FeaturePill(
          colors: c,
          icon: Icons.wifi_off_rounded,
          label: isFil ? '100% Offline' : '100% Offline',
        ),
        _FeaturePill(
          colors: c,
          icon: Icons.lock_outline_rounded,
          label: isFil ? 'Walang Account / Ads' : 'No Account / Ads',
        ),
      ],
    );
  }

  Widget _buildLanguageSelector(AppLocalizations l10n, GateColors c) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            l10n.onboardingLanguageLabel,
            style: TextStyle(
              color: c.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SegmentedButton<String>(
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
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppTheme.primaryTeal;
                  }
                  return c.surface;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return c.ink;
                }),
                side: WidgetStateProperty.all(
                  BorderSide(color: c.border, width: 1.2),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCtaButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.primaryTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: () async {
          await widget.settings.setLanguage(_language);
          await widget.settings.setFirstRunDone();
          if (mounted) context.go('/');
        },
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.onboardingAcknowledge,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyButton(AppLocalizations l10n, GateColors c) {
    return TextButton(
      onPressed: () => context.push('/privacy'),
      style: TextButton.styleFrom(
        foregroundColor: c.muted,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          l10n.settingsPrivacy,
          style: const TextStyle(
            fontSize: 11,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.colors,
    required this.icon,
    required this.label,
  });

  final GateColors colors;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border, width: 1.0),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: colors.accent),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

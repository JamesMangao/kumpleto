import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/settings.dart';
import '../core/theme.dart';
import '../l10n/app_localizations.dart';

/// Grounded, citizen-first Welcome & Onboarding screen for Kumpleto.
///
/// Designed to clearly introduce Kumpleto as an unofficial, offline checklist
/// for Philippine government document requirements (PSA, NBI, Passport, etc.).
/// Features clean civil layout, responsive typography, bilingual language
/// selection, and official disclaimer gate.
const _bgDark = Color(0xFF101715);
const _surfaceCard = Color(0xFF192522);
const _cardBorder = Color(0xFF2C3E38);
const _tealPrimary = AppTheme.primaryTeal; // #0E6B58
const _tealAccent = Color(0xFF2EA78B);

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

    return Scaffold(
      backgroundColor: _bgDark,
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
                        _buildTopBadge(l10n),
                        const SizedBox(height: 14),
                        _buildHeroLogo(),
                        const SizedBox(height: 12),
                        _buildHeadline(l10n, isFil),
                        const SizedBox(height: 14),
                        _buildFeatureHighlights(isFil),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Official Disclaimer Notice Card
                    _buildNoticeCard(l10n),

                    const SizedBox(height: 14),

                    // Controls & CTA
                    Column(
                      children: [
                        _buildLanguageSelector(l10n),
                        const SizedBox(height: 14),
                        _buildCtaButton(l10n),
                        const SizedBox(height: 6),
                        _buildPrivacyButton(l10n),
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

  Widget _buildTopBadge(AppLocalizations l10n) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 1.2),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _tealAccent,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.unofficialBadge.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: Color(0xFFD4ECE3),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '• 100% OFFLINE',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroLogo() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: _surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _tealPrimary, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
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
            errorBuilder: (_, __, ___) => const Icon(
              Icons.assignment_turned_in_rounded,
              color: _tealAccent,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeadline(AppLocalizations l10n, bool isFil) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            l10n.onboardingTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
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
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureHighlights(bool isFil) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        _FeaturePill(
          icon: Icons.checklist_rounded,
          label: isFil ? '12+ Dokumento' : '12+ Documents',
        ),
        _FeaturePill(
          icon: Icons.wifi_off_rounded,
          label: isFil ? '100% Offline' : '100% Offline',
        ),
        _FeaturePill(
          icon: Icons.lock_outline_rounded,
          label: isFil ? 'Walang Account / Ads' : 'No Account / Ads',
        ),
      ],
    );
  }

  Widget _buildNoticeCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _cardBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _tealPrimary.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.policy_outlined,
                  color: _tealAccent,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'PAALALA / DISCLAIMER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: _tealAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 1,
            color: _cardBorder,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingDisclaimer,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w400,
              height: 1.4,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(AppLocalizations l10n) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            l10n.onboardingLanguageLabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
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
                  label: Text('English', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
                ButtonSegment(
                  value: 'fil',
                  label: Text('Filipino', style: TextStyle(fontWeight: FontWeight.w700)),
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
                    return _tealPrimary;
                  }
                  return _surfaceCard;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.white;
                  }
                  return Colors.white.withValues(alpha: 0.75);
                }),
                side: WidgetStateProperty.all(
                  const BorderSide(color: _cardBorder, width: 1.2),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          backgroundColor: _tealPrimary,
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

  Widget _buildPrivacyButton(AppLocalizations l10n) {
    return TextButton(
      onPressed: () => context.push('/settings'),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white.withValues(alpha: 0.6),
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
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _cardBorder,
          width: 1.0,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: _tealAccent),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

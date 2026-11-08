import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../l10n/app_localizations.dart';

const _bgDark = Color(0xFF101715);
const _surfaceCard = Color(0xFF192522);
const _cardBorder = Color(0xFF2C3E38);
const _tealPrimary = AppTheme.primaryTeal; // #0E6B58
const _tealAccent = Color(0xFF2EA78B);

/// First stop on a fresh install: the full disclaimer, shown after the welcome
/// scene and before the language choice.
///
/// It is deliberately a separate gate rather than part of onboarding: the
/// notice has to be readable on its own, and the flow only continues once the
/// reader has actively agreed. The acknowledgement itself is persisted by
/// onboarding's CTA (`setFirstRunDone`), so a launch that stops here shows this
/// screen again.
class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                    Column(
                      children: [
                        _buildTopBadge(l10n),
                        const SizedBox(height: 18),
                        Text(
                          l10n.disclaimerScreenTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildNoticeCard(l10n),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        _buildCtaButton(context, l10n),
                        const SizedBox(height: 6),
                        _buildPrivacyButton(context, l10n),
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
            const SizedBox(width: 6),
            Text(
              l10n.unofficialBadge.toUpperCase(),
              style: const TextStyle(
                color: _tealAccent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder, width: 1.2),
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
          Container(height: 1, color: _cardBorder),
          const SizedBox(height: 10),
          _paragraph(l10n.disclaimerScreenBody),
          const SizedBox(height: 10),
          _paragraph(l10n.disclaimerScreenBody2),
          const SizedBox(height: 10),
          _paragraph(l10n.disclaimerScreenBody3),
        ],
      ),
    );
  }

  Widget _paragraph(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.85),
        fontWeight: FontWeight.w400,
        height: 1.45,
        fontSize: 13,
      ),
    );
  }

  Widget _buildCtaButton(BuildContext context, AppLocalizations l10n) {
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
        onPressed: () => context.go('/onboarding'),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            l10n.disclaimerScreenAgree,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyButton(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      height: 44,
      child: TextButton(
        onPressed: () => context.push('/privacy'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white.withValues(alpha: 0.7),
          minimumSize: const Size(48, 44),
        ),
        child: Text(
          l10n.settingsPrivacy,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}

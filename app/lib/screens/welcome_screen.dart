import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/motion.dart';
import '../core/theme.dart';
import '../l10n/app_localizations.dart';

/// Shows the animated welcome scene on top of the app on every launch.
///
/// Designed to feel like an authentic, dignified Philippine civil document
/// companion — clean paper textures, official stamp seal, deep forest teal ink,
/// and grounded citizen-first typography (no futuristic cyber neon orbs).
class WelcomeGate extends StatefulWidget {
  const WelcomeGate({super.key, required this.show, required this.child});

  /// Set to false in widget tests (and for reduced-motion launches) so the
  /// first frame is the real screen.
  final bool show;
  final Widget child;

  @override
  State<WelcomeGate> createState() => _WelcomeGateState();
}

class _WelcomeGateState extends State<WelcomeGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  bool _started = false;
  bool _finished = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.show) {
      _finished = true;
      return;
    }
    // Reduce-motion keeps a short cross-fade instead of the full sequence.
    _controller.duration = Motion.reduced(context)
        ? const Duration(milliseconds: 300)
        : const Duration(milliseconds: 2200);
    _controller.forward().whenComplete(() {
      if (mounted) setState(() => _finished = true);
    });
  }

  void _skip() {
    if (_finished) return;
    _controller.animateTo(
      1,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show || _finished) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: Semantics(
            button: true,
            label: AppLocalizations.of(context)?.welcomeSkip,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _skip,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => _WelcomeScene(t: _controller.value),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dignified, civil document-inspired welcome scene.
///
/// Sequence:
/// 1. Warm dark paper surface emerges
/// 2. Clean official document sheet slides in
/// 3. Official checklist seal stamps onto the sheet with deep teal ink
/// 4. "Kumpleto" wordmark appears cleanly
/// 5. Tagline & unofficial badge settle
/// 6. Smooth fade out into the main screen
class _WelcomeScene extends StatelessWidget {
  const _WelcomeScene({required this.t});

  final double t;

  static const _word = 'Kumpleto';
  static const _bgDark = Color(0xFF101715);
  static const _paperSurface = Color(0xFF192522);
  static const _cardBorder = Color(0xFF2C3E38);
  static const _tealPrimary = AppTheme.primaryTeal; // #0E6B58
  static const _tealLight = Color(0xFF389B84);

  double _segment(double start, double end) =>
      ((t - start) / (end - start)).clamp(0.0, 1.0);

  double _ease(double start, double end) =>
      Curves.easeOutCubic.transform(_segment(start, end));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fadeOut = _segment(0.88, 1.0);
    final paper = Curves.easeOutBack.transform(_segment(0.06, 0.32));
    final seal = _ease(0.20, 0.50);
    final check = Curves.easeInOutCubic.transform(_segment(0.36, 0.62));
    final wordmark = _ease(0.48, 0.70);
    final tagline = _ease(0.58, 0.78);
    final chip = _ease(0.66, 0.84);
    final skip = _ease(0.72, 0.88);

    final paperY = 40.0 * (1 - paper);

    return Opacity(
      opacity: 1 - fadeOut,
      child: ColoredBox(
        color: _bgDark,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Document sheet with official seal stamp
                  Transform.translate(
                    offset: Offset(0, paperY),
                    child: Opacity(
                      opacity: paper.clamp(0.0, 1.0),
                      child: Container(
                        width: 170,
                        height: 200,
                        decoration: BoxDecoration(
                          color: _paperSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _cardBorder, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: _CivilDocumentPainter(
                            seal: seal,
                            check: check,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Brand Wordmark
                  Opacity(
                    opacity: wordmark,
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - wordmark)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < _word.length; i++)
                            Text(
                              _word[i],
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Practical Citizen Tagline
                  Opacity(
                    opacity: tagline,
                    child: Transform.translate(
                      offset: Offset(0, 8 * (1 - tagline)),
                      child: Text(
                        l10n?.welcomeTagline ??
                            'Alamin ang dadalhing papel bago pumila.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Clear, Dignified Unofficial Badge
                  Opacity(
                    opacity: chip,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _paperSurface,
                        border: Border.all(
                          color: _tealPrimary.withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: _tealLight,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            (l10n?.unofficialBadge ?? 'Unofficial').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4,
                              color: Color(0xFFD4ECE3),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• 100% OFFLINE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Skip prompt
                  Opacity(
                    opacity: skip,
                    child: Text(
                      l10n?.welcomeSkip ?? 'Tap to continue',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 0.5,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a clean document with simulated checklist lines and an authentic
/// circular verification seal stamp in civil deep teal ink.
class _CivilDocumentPainter extends CustomPainter {
  const _CivilDocumentPainter({
    required this.seal,
    required this.check,
  });

  final double seal;
  final double check;

  static const _inkTeal = Color(0xFF138A72);
  static const _ruleColor = Color(0xFF2C3E38);

  @override
  void paint(Canvas canvas, Size size) {
    // Top document header line
    final headerPaint = Paint()
      ..color = _ruleColor
      ..strokeWidth = 2.0;
    canvas.drawLine(
      const Offset(18, 22),
      Offset(size.width - 18, 22),
      headerPaint,
    );

    // Document checklist simulated rows
    final rowPaint = Paint()
      ..color = _ruleColor.withValues(alpha: 0.7)
      ..strokeWidth = 1.2;

    for (var i = 0; i < 4; i++) {
      final y = 38.0 + i * 16;
      canvas.drawLine(
        Offset(34, y),
        Offset(size.width - 20 - (i == 3 ? 30 : 0), y),
        rowPaint,
      );
    }

    // Small square checklist boxes on the rows
    final boxPaint = Paint()
      ..color = _ruleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var i = 0; i < 4; i++) {
      final y = 38.0 + i * 16;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(18, y - 5, 10, 10),
          const Radius.circular(2),
        ),
        boxPaint,
      );
    }

    // Ticks inside top two checkboxes
    if (check > 0.1) {
      final tickPaint = Paint()
        ..color = _inkTeal
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (var i = 0; i < 2; i++) {
        final y = 38.0 + i * 16;
        final p = Path()
          ..moveTo(19.5, y)
          ..lineTo(22, y + 2.5)
          ..lineTo(26.5, y - 2);
        canvas.drawPath(p, tickPaint);
      }
    }

    // Official Seal Stamp in center-bottom
    final center = Offset(size.width * 0.5, size.height * 0.68);

    if (seal > 0.05) {
      final sealPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = _inkTeal.withValues(alpha: 0.9 * seal);

      canvas.drawCircle(center, 38 * seal, sealPaint);
      canvas.drawCircle(center, 32 * seal, sealPaint..strokeWidth = 1.0);

      // Inner circular decorative dots
      final dotPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = _inkTeal.withValues(alpha: 0.7 * seal);
      const dotCount = 12;
      for (var i = 0; i < dotCount; i++) {
        final angle = (i / dotCount) * math.pi * 2;
        final dx = center.dx + math.cos(angle) * (26 * seal);
        final dy = center.dy + math.sin(angle) * (26 * seal);
        canvas.drawCircle(Offset(dx, dy), 1.2 * seal, dotPaint);
      }
    }

    // Clear Civil Checkmark inside seal
    if (check > 0.05) {
      final checkPath = Path()
        ..moveTo(center.dx - 12 * check, center.dy)
        ..lineTo(center.dx - 3 * check, center.dy + 10 * check)
        ..lineTo(center.dx + 13 * check, center.dy - 8 * check);

      final checkPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF26A69A);

      canvas.drawPath(checkPath, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CivilDocumentPainter oldDelegate) =>
      oldDelegate.seal != seal || oldDelegate.check != check;
}

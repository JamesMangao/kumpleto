import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/motion.dart';
import '../core/theme.dart';
import '../data/providers.dart';
import '../l10n/app_localizations.dart';

/// Shows the welcome scene on top of the app.
///
/// - First launch: full ~3s sequence (checklist ticks off, then a
///   "KUMPLETO" rubber stamp lands).
/// - Later launches / reduced motion: ~0.7s compact brand fade. The
///   first-launch flag lives in SharedPreferences, read here, so main.dart
///   needs no changes.
/// - Skip button is available immediately; tapping anywhere also skips.
/// - The scene never leaves on its own: it holds its last frame until the
///   reader skips it.
class WelcomeGate extends ConsumerStatefulWidget {
  const WelcomeGate({
    super.key,
    required this.show,
    required this.child,
    this.compact = false,
  });

  /// Set to false in widget tests so the first frame is the real screen.
  final bool show;

  /// Force the short version. Returning users and reduced motion get it
  /// automatically, so callers normally leave this false.
  final bool compact;

  final Widget child;

  @override
  ConsumerState<WelcomeGate> createState() => _WelcomeGateState();
}

class _WelcomeGateState extends ConsumerState<WelcomeGate>
    with SingleTickerProviderStateMixin {
  static const _seenKey = 'welcome_seen';

  late final AnimationController _controller = AnimationController(vsync: this);
  bool _started = false;
  bool _finished = false;
  bool _dismissing = false;
  bool _compact = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.show) {
      _finished = true;
      return;
    }
    final prefs = ref.read(sharedPreferencesProvider);
    final seen = prefs.getBool(_seenKey) ?? false;
    prefs.setBool(_seenKey, true);
    _compact = widget.compact || seen || Motion.reduced(context);
    _controller.duration = _compact
        ? const Duration(milliseconds: 700)
        : const Duration(milliseconds: 3000);
    _controller.forward();
  }

  /// The scene never hands over on its own: the sequence settles and waits
  /// for this. Fading first keeps the hand-over soft, and reduced motion gets
  /// the instant swap.
  void _skip() {
    if (_finished || _dismissing) return;
    if (Motion.reduced(context)) {
      setState(() => _finished = true);
      return;
    }
    setState(() => _dismissing = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showing = widget.show && !_finished;
    // The app keeps the same parent in every state. Handing the child back
    // bare once the scene ends would reparent the global-keyed Navigator,
    // which leaves live widgets depending on an InheritedWidget that is
    // being torn down (debug asserts with "_dependents.isEmpty").
    return Stack(
      // While the scene is up the app keeps the loose constraints it has
      // always had behind it; once the scene ends it gets the same tight
      // constraints it would get as the bare `builder` child. Only the fit
      // changes, so the child is never reparented.
      fit: showing ? StackFit.loose : StackFit.expand,
      children: [
        // Keep the real app out of the accessibility tree while the overlay
        // is up so TalkBack doesn't read both.
        ExcludeSemantics(excluding: showing, child: widget.child),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !showing,
            child: showing
                ? AnimatedOpacity(
                    opacity: _dismissing ? 0 : 1,
                    duration: Motion.of(context, Motion.fast),
                    curve: Motion.standard,
                    onEnd: () {
                      if (_dismissing && mounted) {
                        setState(() => _finished = true);
                      }
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _skip,
                      child: RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) => _WelcomeScene(
                            t: _controller.value,
                            compact: _compact,
                            onSkip: _skip,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Palette (light + dark)
// ---------------------------------------------------------------------------

class _Palette {
  const _Palette({
    required this.bg,
    required this.card,
    required this.cardBorder,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.stamp,
  });

  final Color bg;
  final Color card;
  final Color cardBorder;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color stamp;

  static _Palette of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark
        ? const _Palette(
            bg: Color(0xFF101715),
            card: Color(0xFF192522),
            cardBorder: Color(0xFF2C3E38),
            ink: Color(0xFFF1F5F3),
            muted: Color(0xFF9DB3AB),
            accent: Color(0xFF2FA88C),
            stamp: Color(0xFF4CC2A6),
          )
        : const _Palette(
            bg: Color(0xFFF6F1E7), // warm paper
            card: Color(0xFFFFFFFF),
            cardBorder: Color(0xFFE2D9C6),
            ink: Color(0xFF14211D),
            muted: Color(0xFF5E6F69),
            accent: AppTheme.primaryTeal, // #0E6B58
            stamp: AppTheme.primaryTeal,
          );
  }
}

bool _isFil(BuildContext context) {
  final code = Localizations.localeOf(context).languageCode;
  return code == 'fil' || code == 'tl';
}

// ---------------------------------------------------------------------------
// Scene
// ---------------------------------------------------------------------------

class _WelcomeScene extends StatelessWidget {
  const _WelcomeScene({
    required this.t,
    required this.compact,
    required this.onSkip,
  });

  final double t;
  final bool compact;
  final VoidCallback onSkip;

  static const _docs = [
    'NBI Clearance',
    'PSA Birth Certificate',
    'National ID',
    'Passport',
  ];

  double _segment(double start, double end) =>
      ((t - start) / (end - start)).clamp(0.0, 1.0);

  double _ease(double start, double end) =>
      compact ? 1.0 : Curves.easeOutCubic.transform(_segment(start, end));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = _Palette.of(context);
    final fil = _isFil(context);

    // The scene holds its last frame until the user skips, so only the
    // entrance fades: the exit is the overlay's own dismiss fade.
    final fadeIn = compact ? _segment(0.0, 0.35) : 1.0;

    final wordmark = _ease(0.02, 0.20);
    final card = _ease(0.08, 0.26);
    final tagline = _ease(0.14, 0.32);
    final chips = _ease(0.62, 0.78);
    final stampT = compact ? 1.0 : _segment(0.58, 0.72);

    final cardWidth = math.min(320.0, MediaQuery.sizeOf(context).width - 48);

    return Opacity(
      opacity: fadeIn,
      child: Material(
        color: p.bg,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Wordmark
                      Opacity(
                        opacity: wordmark,
                        child: Transform.translate(
                          offset: Offset(0, 12 * (1 - wordmark)),
                          child: Text(
                            'Kumpleto',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              color: p.ink,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Opacity(
                        opacity: tagline,
                        child: Text(
                          l10n?.welcomeTagline ??
                              'Alamin ang dadalhing papel bago pumila.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: p.muted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Checklist card + stamp
                      Opacity(
                        opacity: card,
                        child: Transform.translate(
                          offset: Offset(0, 24 * (1 - card)),
                          child: SizedBox(
                            width: cardWidth,
                            child: _ChecklistCard(
                              palette: p,
                              docs: _docs,
                              title: fil
                                  ? 'Kumpleto ba ang papeles mo?'
                                  : 'Is your paperwork complete?',
                              tickProgress: [
                                for (var i = 0; i < _docs.length; i++)
                                  compact
                                      ? 1.0
                                      : Curves.easeInOut.transform(
                                          _segment(
                                            0.18 + i * 0.09,
                                            0.30 + i * 0.09,
                                          ),
                                        ),
                              ],
                              stampProgress: stampT,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Promises
                      Opacity(
                        opacity: chips,
                        child: Transform.translate(
                          offset: Offset(0, 8 * (1 - chips)),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _PromiseChip(
                                palette: p,
                                icon: Icons.wifi_off_rounded,
                                label: 'Offline',
                              ),
                              _PromiseChip(
                                palette: p,
                                icon: Icons.person_off_outlined,
                                label: fil ? 'Walang account' : 'No account',
                              ),
                              _PromiseChip(
                                palette: p,
                                icon: Icons.block_rounded,
                                label: fil ? 'Walang ads' : 'No ads',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Unofficial notice (kept visible, not alarming)
                      Opacity(
                        opacity: chips,
                        child: Text(
                          (l10n?.unofficialBadge ?? 'Unofficial').toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.6,
                            color: p.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Skip: available from the first frame, 48dp target.
              Positioned(
                top: 4,
                right: 8,
                child: Semantics(
                  button: true,
                  label: l10n?.welcomeSkip,
                  child: TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: p.muted,
                    ),
                    child: Text(fil ? 'Laktawan' : 'Skip'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Checklist card
// ---------------------------------------------------------------------------

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({
    required this.palette,
    required this.docs,
    required this.title,
    required this.tickProgress,
    required this.stampProgress,
  });

  final _Palette palette;
  final List<String> docs;
  final String title;
  final List<double> tickProgress;
  final double stampProgress;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final stampScale = 1.0 + 0.8 * (1 - Curves.easeOutBack.transform(stampProgress));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 56),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.cardBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: p.muted,
                ),
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < docs.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CustomPaint(
                          painter: _TickBoxPainter(
                            progress: tickProgress[i],
                            border: p.cardBorder,
                            fill: p.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          docs[i],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: p.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Rubber stamp
        Positioned(
          right: 14,
          bottom: 12,
          child: Opacity(
            opacity: (stampProgress * 2).clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: -0.14,
              child: Transform.scale(
                scale: stampScale,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: p.stamp, width: 3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: p.stamp, width: 1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'KUMPLETO',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        color: p.stamp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromiseChip extends StatelessWidget {
  const _PromiseChip({
    required this.palette,
    required this.icon,
    required this.label,
  });

  final _Palette palette;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: palette.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: palette.ink,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painters
// ---------------------------------------------------------------------------

class _TickBoxPainter extends CustomPainter {
  const _TickBoxPainter({
    required this.progress,
    required this.border,
    required this.fill,
  });

  final double progress;
  final Color border;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(6),
    );

    if (progress > 0) {
      canvas.drawRRect(
        rrect,
        Paint()..color = fill.withValues(alpha: progress),
      );
    }
    canvas.drawRRect(
      rrect.deflate(0.75),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Color.lerp(border, fill, progress)!,
    );

    if (progress > 0.2) {
      final k = ((progress - 0.2) / 0.8).clamp(0.0, 1.0);
      final path = Path()
        ..moveTo(size.width * 0.26, size.height * 0.52)
        ..lineTo(size.width * 0.43, size.height * 0.68)
        ..lineTo(size.width * 0.74, size.height * 0.34);
      final metric = path.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * k),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TickBoxPainter old) =>
      old.progress != progress || old.border != border || old.fill != fill;
}
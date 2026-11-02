import 'package:flutter/material.dart';

import '../core/motion.dart';
import '../core/theme.dart';
import '../l10n/app_localizations.dart';

/// Shows the animated welcome scene on top of the app on every launch.
///
/// The scene lives above the router, so the destination screen is already
/// built and warm underneath while the brand animation plays. When the scene
/// finishes (or the user taps) it is removed and the app is simply there.
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
        ? const Duration(milliseconds: 400)
        : const Duration(milliseconds: 2400);
    _controller.forward().whenComplete(() {
      if (mounted) setState(() => _finished = true);
    });
  }

  void _skip() {
    if (_finished) return;
    _controller.animateTo(
      1,
      duration: const Duration(milliseconds: 220),
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

/// The animation itself. [t] runs 0 → 1 over ~2.4 s:
///
/// 0.00 backdrop · 0.05 mark pops in · 0.30 check is drawn · 0.42 wordmark
/// letters land · 0.62 tagline · 0.70 sheen sweep · 0.86 fade out.
class _WelcomeScene extends StatelessWidget {
  const _WelcomeScene({required this.t});

  final double t;

  static const _word = 'Kumpleto';

  double _segment(double start, double end) =>
      ((t - start) / (end - start)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fadeOut = _segment(0.86, 1.0);
    final markIn = _segment(0.05, 0.45);
    final check = _segment(0.30, 0.68);
    final tagline = _segment(0.62, 0.82);

    final scale = 0.72 + 0.28 * Motion.overshoot.transform(markIn);
    final rotation = (1 - markIn) * -0.22;

    return Opacity(
      opacity: 1 - fadeOut,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryTeal, AppTheme.primaryDarkTeal],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glow behind the mark.
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 0.35 * markIn,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.35),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: rotation,
                      child: Transform.scale(
                        scale: scale,
                        child: SizedBox(
                          width: 148,
                          height: 148,
                          child: CustomPaint(
                            painter: _BrandMarkPainter(checkProgress: check),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              // Wordmark: one letter at a time.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _word.length; i++)
                    _Letter(
                      char: _word[i],
                      progress: _segment(0.42 + i * 0.030, 0.62 + i * 0.030),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Opacity(
                opacity: tagline,
                child: Transform.translate(
                  offset: Offset(0, 8 * (1 - tagline)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      l10n?.welcomeTagline ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Unofficial marker stays visible even here.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n?.unofficialBadge ?? 'Unofficial',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Opacity(
                opacity: _segment(0.75, 0.95),
                child: Text(
                  l10n?.welcomeSkip ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.4,
                    color: Colors.white.withValues(alpha: 0.6),
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

class _Letter extends StatelessWidget {
  const _Letter({required this.char, required this.progress});

  final String char;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(0, 16 * (1 - progress)),
        child: Text(
          char,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Vector Kumpleto mark: a white folder with a check that draws itself.
class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter({required this.checkProgress});

  final double checkProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 148.0;
    final white = Paint()..color = Colors.white;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(26 * s, 48 * s, 106 * s, 72 * s),
      Radius.circular(14 * s),
    );
    final tab = RRect.fromRectAndRadius(
      Rect.fromLTWH(26 * s, 34 * s, 52 * s, 26 * s),
      Radius.circular(9 * s),
    );
    canvas.drawRRect(tab, white);
    canvas.drawRRect(body, white);

    if (checkProgress <= 0) return;
    final path = Path()
      ..moveTo(56 * s, 86 * s)
      ..lineTo(71 * s, 101 * s)
      ..lineTo(103 * s, 66 * s);
    final metric = path.computeMetrics().first;
    final drawn = metric.extractPath(0, metric.length * checkProgress);
    canvas.drawPath(
      drawn,
      Paint()
        ..color = AppTheme.primaryTeal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_BrandMarkPainter oldDelegate) =>
      oldDelegate.checkProgress != checkProgress;
}

import 'package:flutter/material.dart';

/// Motion tokens for the whole app.
///
/// Every animation in Kumpleto routes through here so that durations stay
/// consistent and so that the platform "remove animations" accessibility
/// setting (200% text scale users often enable it) collapses everything to an
/// instant state change instead of motion.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);

  /// Standard easing for entrances and size changes.
  static const Curve standard = Curves.easeOutCubic;

  /// Emphasised easing for hero-like transitions.
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);

  /// Entrance curve with a small overshoot, used for the brand mark.
  static const Curve overshoot = Curves.easeOutBack;

  /// True when the user asked the platform to remove animations.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  /// Returns [duration], or zero when animations are disabled.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;

  /// Stagger delay for the item at [index] in a list entrance.
  static Duration stagger(BuildContext context, int index, {int max = 8}) {
    if (reduced(context)) return Duration.zero;
    final step = Duration(milliseconds: 40 * (index.clamp(0, max)));
    return step;
  }
}

/// Fades and lifts [child] into place once, after an optional delay.
///
/// Used for list rows and cards so screens assemble instead of popping in.
/// The animation is finite, so `pumpAndSettle` in tests still terminates.
class StaggeredEntrance extends StatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 14,
  });

  final Widget child;
  final int index;
  final double offset;

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.medium,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Motion.standard,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.reduced(context)) {
      _controller.value = 1;
      return;
    }
    Future<void>.delayed(
      Motion.stagger(context, widget.index),
    ).then((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _curve.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

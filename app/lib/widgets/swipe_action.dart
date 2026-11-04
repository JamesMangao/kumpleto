import 'package:flutter/material.dart';

/// Swipe a card in [direction] to run [onAction].
///
/// The card follows the finger, a check icon grows in behind it, and letting
/// go past half the threshold commits the action; short drags spring back.
/// Screen readers and switch access get the same action through a semantics
/// button, so a gesture is never the only way in.
class SwipeAction extends StatefulWidget {
  const SwipeAction({
    super.key,
    required this.onAction,
    required this.direction,
    required this.semanticLabel,
    required this.child,
    this.icon = Icons.check_circle_rounded,
    this.color,
  });

  /// Right for "mark", left for "unmark".
  final AxisDirection direction;
  final VoidCallback onAction;

  /// Spoken label for the semantics button ("Mark as acquired").
  final String semanticLabel;
  final IconData icon;
  final Color? color;
  final Widget child;

  @override
  State<SwipeAction> createState() => _SwipeActionState();
}

class _SwipeActionState extends State<SwipeAction> {
  /// Drag distance in logical pixels that commits the action.
  static const double _commitAt = 88;
  static const double _maxTravel = 132;

  double _travel = 0;
  bool _dragging = false;

  bool get _toRight => widget.direction == AxisDirection.right;

  void _onUpdate(DragUpdateDetails details) {
    final delta = _toRight ? details.delta.dx : -details.delta.dx;
    if (delta < 0 && _travel <= 0) return;
    setState(() {
      _dragging = true;
      _travel = (_travel + delta).clamp(0.0, _maxTravel);
    });
  }

  void _release() {
    final commit = _travel >= _commitAt;
    setState(() {
      _dragging = false;
      _travel = 0;
    });
    if (commit) widget.onAction();
  }

  void _abort() {
    setState(() {
      _dragging = false;
      _travel = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.color ?? theme.colorScheme.primary;
    final progress = (_travel / _commitAt).clamp(0.0, 1.0);

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      onTap: widget.onAction,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: _onUpdate,
        onHorizontalDragEnd: (_) => _release(),
        onHorizontalDragCancel: _abort,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: progress,
                  child: Align(
                    alignment: _toRight
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Icon(widget.icon, color: accent, size: 30),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: _dragging
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(
                _toRight ? _travel : -_travel,
                0,
                0,
              ),
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}

/// The arrow + sentence that teaches the swipe, shown inside the card.
class SwipeHint extends StatelessWidget {
  const SwipeHint({super.key, required this.label, this.toRight = true});

  final String label;
  final bool toRight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          toRight ? Icons.swipe_right_alt_rounded : Icons.swipe_left_alt_rounded,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

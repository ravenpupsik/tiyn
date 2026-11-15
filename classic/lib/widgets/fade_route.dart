import 'package:flutter/material.dart';

import 'package:money_app/widgets/backdrop.dart';

/// The pages pushed with it cover the screen with their own background, so the
/// route is opaque: once it settles, the page below stops animating.
Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
  opaque: true,
  transitionDuration: const Duration(milliseconds: 320),
  reverseTransitionDuration: const Duration(milliseconds: 260),
  pageBuilder: (_, _, _) => page,
  transitionsBuilder: (_, anim, _, child) {
    final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
    return _PauseBackdropDuring(
      animation: anim,
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      ),
    );
  },
);

/// Holds the animated background still while the page transition runs.
class _PauseBackdropDuring extends StatefulWidget {
  final Animation<double> animation;
  final Widget child;
  const _PauseBackdropDuring({required this.animation, required this.child});

  @override
  State<_PauseBackdropDuring> createState() => _PauseBackdropDuringState();
}

class _PauseBackdropDuringState extends State<_PauseBackdropDuring> {
  bool _held = false;

  void _onStatus(AnimationStatus s) {
    final moving = s == AnimationStatus.forward || s == AnimationStatus.reverse;
    if (moving == _held) return;
    _held = moving;
    moving ? pauseBackdrop() : resumeBackdrop();
  }

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_onStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onStatus(widget.animation.status);
    });
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onStatus);
    if (_held) resumeBackdrop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

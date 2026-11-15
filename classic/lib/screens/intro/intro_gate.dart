import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;

import 'package:money_app/theme/tokens.dart';

TextStyle logoStyle(Color color) => TextStyle(
  fontFamily: 'Doto',
  fontVariations: kDotoVariations,
  color: color,
  fontSize: 32,
  height: 1.1,
);

/// Enabled in main(); tests never see the intro.
bool introEnabled = false;

final introRunning = ValueNotifier<bool>(false);

final logoKey = GlobalKey();

/// Same as the Android system splash background, so the handoff does not
/// flicker.
Color introBg(bool dark) =>
    dark ? const Color(0xFF050506) : const Color(0xFFF2EAE7);

class IntroGate extends StatefulWidget {
  final Widget child;
  const IntroGate({super.key, required this.child});

  @override
  State<IntroGate> createState() => _IntroGateState();
}

class _IntroGateState extends State<IntroGate>
    with SingleTickerProviderStateMixin {
  final _t = ValueNotifier<double>(0);
  Ticker? _ticker;
  Duration _last = Duration.zero;
  bool _done = !introEnabled;
  bool _checked = false;
  // The key keeps the home screen alive when the intro is removed; without it
  // the screen was recreated and flickered for a frame.
  final _homeKey = GlobalKey();

  // Letters appear, the dot pops, then the logo fades out completely before
  // the app fades in, so the two never overlap.
  static const _total = 620.0;
  static const _logoOutStart = 0.42;
  static const _logoOutEnd = 0.60;
  // Largest step per frame: if the phone stutters at launch, the animation
  // slows down instead of jumping.
  static const _maxStep = 34.0;
  static const _big = 2.2;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checked || _done) return;
    _checked = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _done = true;
      return;
    }
    introRunning.value = true;
    // Start after the first heavy frames are drawn.
    WidgetsBinding.instance.endOfFrame
        .then((_) => WidgetsBinding.instance.endOfFrame)
        .then((_) {
          if (!mounted) return;
          _ticker = createTicker(_tick)..start();
        });
  }

  void _tick(Duration now) {
    final dt = (now - _last).inMicroseconds / 1000.0;
    _last = now;
    _t.value = (_t.value + dt.clamp(0.0, _maxStep) / _total).clamp(0.0, 1.0);
    // The header logo shows up together with the app, not before.
    if (_t.value >= _logoOutEnd) introRunning.value = false;
    if (_t.value >= 1) _finish();
  }

  void _finish() {
    if (_done) return;
    _ticker?.stop();
    introRunning.value = false;
    if (mounted) setState(() => _done = true);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _t.dispose();
    if (!_done) introRunning.value = false;
    super.dispose();
  }

  double _iv(double a, double b, [Curve curve = Curves.linear]) =>
      curve.transform(((_t.value - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final home = KeyedSubtree(key: _homeKey, child: widget.child);
    if (_done) return home;
    final dark = isDark(context);
    final fg = Theme.of(context).colorScheme.onSurface;
    final style = logoStyle(fg);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: Material(
        color: introBg(dark),
        child: AnimatedBuilder(
          animation: _t,
          child: home,
          builder: (context, child) {
            final reveal = _iv(0.0, 0.26, Curves.easeOut);
            final dot = _iv(0.2, 0.36, Curves.easeOutBack);
            final logoFade = _iv(_logoOutStart, _logoOutEnd);
            final content = _iv(_logoOutEnd, 1.0, Curves.easeOut);

            return Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: content,
                    child: Transform.scale(
                      scale: 0.98 + 0.02 * content,
                      child: child,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: introBg(dark).withValues(alpha: 1 - content),
                    ),
                  ),
                ),
                if (logoFade < 1)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: Opacity(
                          opacity: 1 - logoFade,
                          child: Transform.scale(
                            scale: _big,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ShaderMask(
                                  blendMode: BlendMode.dstIn,
                                  shaderCallback: (r) => LinearGradient(
                                    colors: const [
                                      Colors.white,
                                      Colors.transparent,
                                    ],
                                    stops: [
                                      (reveal * 1.15 - 0.1).clamp(0.0, 1.0),
                                      (reveal * 1.15).clamp(0.0, 1.0),
                                    ],
                                  ).createShader(r),
                                  child: Text('Tiyn', style: style),
                                ),
                                Positioned(
                                  right: -10,
                                  bottom: 9,
                                  child: Transform.scale(
                                    scale: dot.clamp(0.0, 1.3),
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: accentOf(context),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;

import 'package:money_app/theme/tokens.dart';

/// Enabled in main(); tests never see the intro.
bool introEnabled = false;

final introRunning = ValueNotifier<bool>(false);

final logoKey = GlobalKey();

/// Shared by the intro and the header so size and weight do not jump at the end
/// of the flight.
TextStyle logoStyle(Color color) => nunito(26, 800, color: color, height: 1.2);

/// Same as `splash_bg` of the Android system splash, so the handoff does not
/// flicker.
Color introBg(bool dark) =>
    Glina.byBrightness(dark ? Brightness.dark : Brightness.light).bg;

/// The home screen always sits in the same `Stack` under the intro layers, so
/// the tree is not rebuilt (and home is not recreated) when the intro ends;
/// otherwise it flickers.
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
  // The key keeps the home screen alive across any reordering.
  final _homeKey = GlobalKey();

  static const _total = 1000.0;
  // Largest step per frame: if the phone stutters at launch, the animation
  // slows down instead of jumping.
  static const _maxStep = 34.0;

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
          if (!mounted || _done) return;
          _ticker = createTicker(_tick)..start();
        });
  }

  void _tick(Duration now) {
    final dt = (now - _last).inMicroseconds / 1000.0;
    _last = now;
    _t.value = (_t.value + dt.clamp(0.0, _maxStep) / _total).clamp(0.0, 1.0);
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
    final g = context.g;
    final style = logoStyle(g.ink);
    final tp = TextPainter(
      text: TextSpan(text: 'Tiyn', style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    var logoSize = tp.size;
    tp.dispose();
    const big = 2.2;

    return AnimatedBuilder(
      animation: _t,
      child: home,
      builder: (context, child) {
        final screen = MediaQuery.sizeOf(context);
        final reveal = _iv(0.0, 0.4, Curves.easeOut);
        final dot = _iv(0.32, 0.5, Curves.easeOutBack);
        final move = _iv(0.5, 0.9, Curves.easeInOutCubic);
        final bgFade = _iv(0.55, 0.9);
        final content = _done ? 1.0 : _iv(0.55, 1.0, Curves.easeOutCubic);
        final dotFade = 1 - _iv(0.6, 0.8);

        Offset to = Offset(20, MediaQuery.paddingOf(context).top + 12);
        final box = logoKey.currentContext?.findRenderObject() as RenderBox?;
        if (!_done && box != null && box.hasSize) {
          to = box.localToGlobal(Offset.zero);
          logoSize = box.size;
        }
        final from = Offset(
          (screen.width - logoSize.width * big) / 2,
          (screen.height - logoSize.height * big) / 2,
        );
        final pos = Offset.lerp(from, to, move)!;
        final scale = big + (1 - big) * move;

        // Material is needed for the intro word: without it Text gets the
        // "error" style (yellow underline). Always present so the tree does not
        // change.
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: g.bg)),
              Positioned.fill(
                child: Opacity(
                  opacity: content,
                  child: Transform.scale(
                    scale: 0.97 + 0.03 * content,
                    child: child,
                  ),
                ),
              ),
              if (!_done) ...[
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _finish,
                    child: ColoredBox(
                      color: g.bg.withValues(alpha: 1 - bgFade),
                    ),
                  ),
                ),
                Positioned(
                  left: pos.dx,
                  top: pos.dy,
                  child: IgnorePointer(
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.topLeft,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ShaderMask(
                            blendMode: BlendMode.dstIn,
                            shaderCallback: (r) => LinearGradient(
                              colors: const [Colors.white, Colors.transparent],
                              stops: [
                                (reveal * 1.15 - 0.1).clamp(0.0, 1.0),
                                (reveal * 1.15).clamp(0.0, 1.0),
                              ],
                            ).createShader(r),
                            child: Text('Tiyn', style: style),
                          ),
                          Positioned(
                            right: -10,
                            bottom: 7,
                            child: Opacity(
                              opacity: dotFade,
                              child: Transform.scale(
                                scale: dot.clamp(0.0, 1.3),
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: g.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

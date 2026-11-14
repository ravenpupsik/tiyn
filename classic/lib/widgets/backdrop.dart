import 'dart:ui' as ui show Image, PictureRecorder;
import 'dart:ui' show FragmentProgram, FragmentShader;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;

import 'package:money_app/theme/tokens.dart';

/// Liquid-silver background shader. If it fails to load, the background falls
/// back to plain blurred blobs.
FragmentProgram? chromeProgram;

/// Kill switch for the background "breathing" animation. Tests turn it off too.
bool breathingEnabled = true;

/// Pauses the background animation while scrolling or while an input sheet is
/// open, so the glass above it is not recomputed needlessly.
final backdropPaused = ValueNotifier<bool>(false);

class Backdrop extends StatefulWidget {
  const Backdrop({super.key});

  @override
  State<Backdrop> createState() => _BackdropState();
}

class _BackdropState extends State<Backdrop>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4500),
  );

  // Shader time: advances while not paused. Updated about 30 times a second,
  // which is enough for the eye and easier on the battery.
  final _time = ValueNotifier<double>(0);
  Ticker? _ticker;
  Duration _last = Duration.zero;
  double _pending = 0;

  bool get _useShader => chromeProgram != null;
  late final FragmentShader? _shader = chromeProgram?.fragmentShader();
  bool _inactive = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inactive = state != AppLifecycleState.resumed;
    _sync();
  }

  void _onTick(Duration elapsed) {
    _pending += (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (_pending >= 1 / 24) {
      _time.value += _pending;
      _pending = 0;
    }
  }

  @override
  void initState() {
    super.initState();
    backdropPaused.addListener(_sync);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  void _sync() {
    if (!mounted) return;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    // Paused while the keyboard is open so the text field stays responsive.
    final keyboard = (MediaQuery.maybeViewInsetsOf(context)?.bottom ?? 0) > 0;
    final run =
        breathingEnabled &&
        !reduce &&
        !backdropPaused.value &&
        !(_useShader && (_inactive || keyboard));
    if (_useShader) {
      _ticker ??= createTicker(_onTick);
      if (run && !_ticker!.isActive) {
        _last = Duration.zero;
        _ticker!.start();
      } else if (!run && _ticker!.isActive) {
        _ticker!.stop();
      }
      return;
    }
    if (run && !_breath.isAnimating) {
      _breath.repeat(reverse: true);
    } else if (!run && _breath.isAnimating) {
      _breath.stop();
    }
  }

  @override
  void dispose() {
    backdropPaused.removeListener(_sync);
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.dispose();
    _shader?.dispose();
    _time.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDark(context);
    if (_useShader) {
      return RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _ChromePainter(shader: _shader!, time: _time, dark: dark),
        ),
      );
    }
    final colors = dark
        ? const [Color(0xFF9A9AA2), Color(0xFF5E5E66), Color(0xFF7A7A82)]
        : const [Color(0xFFFFFFFF), Color(0xFFB9B9C0), Color(0xFFFFFFFF)];

    const slots = [
      (
        top: -120.0,
        left: -100.0,
        right: null,
        size: 440.0,
        od: 0.42,
        ol: 0.95,
        dx: 40.0,
        dy: 30.0,
      ),
      (
        top: 60.0,
        left: null,
        right: -150.0,
        size: 420.0,
        od: 0.38,
        ol: 0.55,
        dx: -50.0,
        dy: 40.0,
      ),
      (
        top: 400.0,
        left: 10.0,
        right: null,
        size: 340.0,
        od: 0.22,
        ol: 0.80,
        dx: 45.0,
        dy: -35.0,
      ),
    ];

    return RepaintBoundary(
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: AnimatedBuilder(
          animation: _breath,
          builder: (context, _) {
            final v = Curves.easeInOut.transform(_breath.value);
            return Stack(
              children: [
                for (var i = 0; i < slots.length; i++)
                  Positioned(
                    top: slots[i].top,
                    left: slots[i].left,
                    right: slots[i].right,
                    child: Transform.translate(
                      offset: Offset(slots[i].dx * v, slots[i].dy * v),
                      child: Transform.scale(
                        scale: 1 + 0.08 * (i.isEven ? v : 1 - v),
                        child: _Blob(
                          color: colors[i],
                          size: slots[i].size,
                          opacity: dark ? slots[i].od : slots[i].ol,
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

/// The shader is evaluated into a small image (4x smaller per side) and
/// stretched up. The background is blurred anyway, so there is no visible
/// difference.
class _ChromePainter extends CustomPainter {
  final FragmentShader shader;
  final ValueNotifier<double> time;
  final bool dark;
  _ChromePainter({required this.shader, required this.time, required this.dark})
    : super(repaint: time);

  static const _scale = 0.25;

  @override
  void paint(Canvas canvas, Size size) {
    final w = (size.width * _scale).ceil().clamp(1, 4096);
    final h = (size.height * _scale).ceil().clamp(1, 4096);
    shader
      ..setFloat(0, w.toDouble())
      ..setFloat(1, h.toDouble())
      // Offset of 7 s so the first frame already looks good.
      ..setFloat(2, 7 + time.value * 0.6)
      ..setFloat(3, dark ? 1 : 0);
    final rec = ui.PictureRecorder();
    Canvas(rec).drawRect(
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint()..shader = shader,
    );
    final pic = rec.endRecording();
    final ui.Image img = pic.toImageSync(w, h);
    pic.dispose();
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
    img.dispose();
  }

  @override
  bool shouldRepaint(_ChromePainter old) =>
      old.dark != dark || old.time != time || old.shader != shader;
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size, opacity;
  const _Blob({required this.color, required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: color),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (_, c, _) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              c!.withValues(alpha: opacity),
              c.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class PauseBackdropOnScroll extends StatelessWidget {
  final Widget child;
  const PauseBackdropOnScroll({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollStartNotification) backdropPaused.value = true;
        if (n is ScrollEndNotification) backdropPaused.value = false;
        return false;
      },
      child: child,
    );
  }
}

import 'package:flutter/material.dart';

import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/format.dart';

class DayBarData {
  final DateTime date;
  final int amount;
  final bool isToday;
  const DayBarData({
    required this.date,
    required this.amount,
    required this.isToday,
  });
}

/// Tapping anywhere in a day's column (bar + label) shows a tooltip like "Сб ·
/// −4 120 ₸"; tapping the same day again or elsewhere hides it. A day without
/// spending is drawn as a dot, not a bar.
class DayBars extends StatefulWidget {
  final List<DayBarData> days;

  final Color todayColor;
  const DayBars({super.key, required this.days, required this.todayColor});

  static const barWidth = 8.0;
  static const maxBarHeight = 64.0;
  static const minBarHeight = 4.0;
  static const dotSize = 6.0;
  static const labelGap = 8.0;
  static const labelHeight = 14.0;

  static const tooltipZone = 36.0;

  static double barHeightFor(int amount, int maxAmount) {
    if (amount <= 0 || maxAmount <= 0) return 0;
    final h = amount / maxAmount * maxBarHeight;
    return h < minBarHeight ? minBarHeight : h;
  }

  @override
  State<DayBars> createState() => _DayBarsState();
}

class _DayBarsState extends State<DayBars> with SingleTickerProviderStateMixin {
  late final AnimationController _grow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  )..forward();
  int? _selected;

  @override
  void dispose() {
    _grow.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DayBars old) {
    super.didUpdateWidget(old);
    if (_selected != null &&
        (old.days.length != widget.days.length ||
            old.days[_selected!].amount != widget.days[_selected!].amount ||
            old.days[_selected!].date != widget.days[_selected!].date)) {
      _selected = null;
    }
  }

  void _toggle(int i) => setState(() => _selected = _selected == i ? null : i);
  void _clear() {
    if (_selected != null) setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final g = context.g;
    final ink = g.ink;
    final barColor = g.ink3.withValues(alpha: dark ? 0.75 : 0.55);
    final maxAmount = widget.days.fold(
      0,
      (m, d) => d.amount > m ? d.amount : m,
    );

    return TapRegion(
      onTapOutside: (_) => _clear(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _clear,
        child: SizedBox(
          height:
              DayBars.tooltipZone +
              DayBars.maxBarHeight +
              DayBars.labelGap +
              DayBars.labelHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                for (var i = 0; i < widget.days.length; i++)
                  Expanded(
                    child: _DayColumn(
                      data: widget.days[i],
                      barHeight: DayBars.barHeightFor(
                        widget.days[i].amount,
                        maxAmount,
                      ),
                      grow: _grow,
                      color: widget.days[i].isToday
                          ? widget.todayColor
                          : barColor,
                      ink: ink,
                      dark: dark,
                      showTooltip: _selected == i,
                      onTap: () => _toggle(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  final DayBarData data;
  final double barHeight;
  final Animation<double> grow;
  final Color color, ink;
  final bool dark, showTooltip;
  final VoidCallback onTap;
  const _DayColumn({
    required this.data,
    required this.barHeight,
    required this.grow,
    required this.color,
    required this.ink,
    required this.dark,
    required this.showTooltip,
    required this.onTap,
  });

  String get _tooltipText =>
      '${weekdayShort(data.date)} · ${data.amount == 0 ? '0 ₸' : formatMoney(-data.amount)}';

  @override
  Widget build(BuildContext context) {
    final empty = barHeight == 0;
    return Semantics(
      button: true,
      label: _tooltipText,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                const SizedBox(height: DayBars.tooltipZone),
                SizedBox(
                  height: DayBars.maxBarHeight,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: empty
                        ? Container(
                            width: DayBars.dotSize,
                            height: DayBars.dotSize,
                            decoration: const BoxDecoration(
                              color: Color(0xFF8D7E74),
                              shape: BoxShape.circle,
                            ),
                          )
                        : AnimatedBuilder(
                            animation: grow,
                            builder: (_, _) => Container(
                              width: DayBars.barWidth,
                              height:
                                  barHeight *
                                  Curves.easeOut.transform(grow.value),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: DayBars.labelGap),
                SizedBox(
                  height: DayBars.labelHeight,
                  child: Text(
                    weekdayShort(data.date),
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                      color: ink.withValues(alpha: data.isToday ? 0.85 : 0.45),
                    ),
                  ),
                ),
              ],
            ),
            if (showTooltip)
              Positioned(
                left: -60,
                right: -60,
                bottom:
                    DayBars.labelHeight +
                    DayBars.labelGap +
                    (empty ? DayBars.dotSize : barHeight) +
                    6,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: _Tooltip(text: _tooltipText, dark: dark),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tooltip extends StatelessWidget {
  final String text;
  final bool dark;
  const _Tooltip({required this.text, required this.dark});

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final fill = g.ink;
    final fg = g.bg;
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              text,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: fg,
              ),
            ),
          ),
          CustomPaint(size: const Size(6, 4), painter: _TailPainter(fill)),
        ],
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  final Color color;
  const _TailPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}

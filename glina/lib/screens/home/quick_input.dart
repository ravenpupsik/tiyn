import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/data/category.dart';
import 'package:money_app/data/txn.dart';
import 'package:money_app/data/wallet.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/format.dart';
import 'package:money_app/utils/spaced_digits.dart';
import 'package:money_app/widgets/cat_bubble.dart';
import 'package:money_app/widgets/surf_panel.dart';

class QuickInput extends StatefulWidget {
  final Wallet wallet;
  final VoidCallback onOpenPiggy;
  const QuickInput({
    super.key,
    required this.wallet,
    required this.onOpenPiggy,
  });

  @override
  State<QuickInput> createState() => _QuickInputState();
}

class _QuickInputState extends State<QuickInput>
    with SingleTickerProviderStateMixin {
  static const _cats = ['Еда', 'Кафе', 'Транспорт', 'Учёба', 'Покупки'];

  final _amount = TextEditingController();
  final _focus = FocusNode();
  late final _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _shake.dispose();
    _focus.dispose();
    _amount.dispose();
    super.dispose();
  }

  int get _value => int.tryParse(_amount.text.replaceAll(' ', '')) ?? 0;

  void _snack(String text, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 4),
          action: action,
        ),
      );
  }

  void _nudge() {
    HapticFeedback.lightImpact();
    _focus.requestFocus();
    _shake.forward(from: 0);
  }

  void _clear() {
    _amount.clear();
    _focus.unfocus();
  }

  void _addExpense(String cat) {
    final v = _value;
    if (v <= 0) return _nudge();
    final w = widget.wallet;
    final t = Txn(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      amount: v,
      kind: TxnKind.expense,
      category: cat,
      note: '',
      date: DateTime.now(),
    );
    HapticFeedback.mediumImpact();
    w.upsert(t);
    w.rememberCategory(t);
    _clear();
    _snack(
      'Добавлено · $cat ${formatMoney(v)}',
      action: SnackBarAction(label: 'Отменить', onPressed: () => w.remove(t)),
    );
  }

  void _toPiggy() {
    final v = _value;
    if (v <= 0) return _nudge();
    final w = widget.wallet;
    // The main balance must not go below zero.
    if (v > w.onHand) {
      HapticFeedback.heavyImpact();
      _snack(
        w.onHand > 0
            ? 'На руках только ${formatMoney(w.onHand)}'
            : 'На руках пусто, откладывать нечего',
      );
      return;
    }
    final t = Txn(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      amount: v,
      kind: TxnKind.toPiggy,
      category: '',
      note: '',
      date: DateTime.now(),
    );
    HapticFeedback.mediumImpact();
    w.upsert(t);
    _clear();
    _snack(
      'Отложено · ${formatMoney(v)}',
      action: SnackBarAction(label: 'Отменить', onPressed: () => w.remove(t)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final ready = _value > 0;
    return SurfPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Быстрый ввод',
            style: golos(13, 600, color: g.ink2, height: 1.2),
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _shake,
            builder: (_, child) => Transform.translate(
              offset: Offset(
                math.sin(_shake.value * math.pi * 4) * 7 * (1 - _shake.value),
                0,
              ),
              child: child,
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _focus.requestFocus,
              child: SizedBox(
                height: 44,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: IntrinsicWidth(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 20),
                          child: TextField(
                            controller: _amount,
                            focusNode: _focus,
                            keyboardType: TextInputType.number,
                            inputFormatters: const [SpacedDigits()],
                            cursorColor: g.accent,
                            cursorWidth: 2,
                            style: literata(32, color: g.ink, height: 1.15),
                            onTapOutside: (_) => _focus.unfocus(),
                            decoration: InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              hintText: '0',
                              hintStyle: literata(
                                32,
                                color: g.ink3,
                                height: 1.15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₸',
                      style: literata(
                        32,
                        color: ready ? g.ink : g.ink3,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final name in _cats)
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'Расход: $name',
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _addExpense(name),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CatBubble(
                            findCategory(name, false),
                            diameter: 48,
                            iconSize: 24,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            softWrap: false,
                            style: golos(11, 600, color: g.ink2, height: 1.2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: g.ink2.withValues(alpha: 0.12)),
          Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onOpenPiggy,
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    Icon(Icons.savings_outlined, size: 22, color: g.accent),
                    const SizedBox(width: 10),
                    Text('Копилка', style: golos(15, 600, color: g.ink)),
                    const Spacer(),
                    if (ready)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _toPiggy,
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: g.accent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Отложить',
                            style: golos(13, 700, color: g.onAccent),
                          ),
                        ),
                      )
                    else ...[
                      Text(
                        formatMoney(widget.wallet.piggy),
                        style: golos(15, 700, color: g.ink),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: g.ink2,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

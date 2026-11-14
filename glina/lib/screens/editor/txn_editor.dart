import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/data/category.dart';
import 'package:money_app/data/txn.dart';
import 'package:money_app/screens/editor/category_grid.dart';
import 'package:money_app/theme/glina_theme.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/format.dart';
import 'package:money_app/utils/spaced_digits.dart';
import 'package:money_app/widgets/primary_button.dart';
import 'package:money_app/widgets/sheet_fields.dart';
import 'package:money_app/widgets/type_switch.dart';

class TxnEditor extends StatefulWidget {
  final Txn? existing;

  final Txn? draft;

  final String? lastExpense, lastIncome;

  final bool autofocus;
  const TxnEditor({
    super.key,
    this.existing,
    this.draft,
    this.lastExpense,
    this.lastIncome,
    this.autofocus = true,
  });

  @override
  State<TxnEditor> createState() => _TxnEditorState();
}

class _TxnEditorState extends State<TxnEditor> {
  late final Txn? _src = widget.existing ?? widget.draft;
  late bool _isIncome = _src?.isIncome ?? false;
  late String _category = _initialCategory();
  late DateTime _date = _src?.date ?? DateTime.now();
  late final _amount = TextEditingController(
    text: _src == null ? '' : SpacedDigits.group(_src.amount.toString()),
  );
  late final _note = TextEditingController(text: _src?.note ?? '');
  final _amountFocus = FocusNode();
  bool _focusScheduled = false;

  String _initialCategory() {
    final src = _src;
    if (src != null &&
        src.kind != TxnKind.toPiggy &&
        src.kind != TxnKind.fromPiggy) {
      return findCategory(src.category, src.isIncome).name;
    }
    return _lastFor(_isIncome);
  }

  String _lastFor(bool income) {
    final last = income ? widget.lastIncome : widget.lastExpense;
    final list = _catsFor(income);
    if (last != null && list.any((c) => c.name == last)) return last;
    return list.first.name;
  }

  List<Category> _catsFor(bool income) {
    if (!income) return expenseCategories;
    // Legacy income categories stay selectable when editing old entries.
    final legacy = legacyIncome.where(
      (c) => c.name == widget.existing?.category,
    );
    return [incomeCategories.first, ...legacy, incomeCategories.last];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Open the keyboard only after the sheet has finished sliding in.
    if (_focusScheduled || _src != null || !widget.autofocus) return;
    _focusScheduled = true;
    final anim = ModalRoute.of(context)?.animation;
    if (anim == null || anim.status == AnimationStatus.completed) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _amountFocus.requestFocus(),
      );
      return;
    }
    void listener(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        anim.removeStatusListener(listener);
        if (mounted) _amountFocus.requestFocus();
      }
    }

    anim.addStatusListener(listener);
  }

  @override
  void dispose() {
    _amountFocus.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  int get _value => int.tryParse(_amount.text.replaceAll(' ', '')) ?? 0;

  void _save() {
    if (_value <= 0) return;
    HapticFeedback.mediumImpact();
    Navigator.pop(
      context,
      Txn(
        id:
            widget.existing?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        amount: _value,
        kind: _isIncome ? TxnKind.income : TxnKind.expense,
        category: _category,
        note: _note.text.trim(),
        date: _date,
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(DateTime.now()) ? DateTime.now() : _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      setState(
        () => _date = DateTime(
          d.year,
          d.month,
          d.day,
          _date.hour,
          _date.minute,
          _date.second,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    final compact = kb > 0;
    final cats = _catsFor(_isIncome);
    final isEdit = widget.existing != null;
    final isDraft = widget.draft != null && !isEdit;
    final ready = _value > 0;

    return Padding(
      padding: EdgeInsets.only(bottom: kb),
      child: Container(
        decoration: BoxDecoration(
          color: g.surf,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          minimum: EdgeInsets.only(bottom: compact ? 8 : 20),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: compact ? 14 : 16,
                  child: Center(
                    child: Container(
                      width: 52,
                      height: 4,
                      decoration: BoxDecoration(
                        color: g.ink.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 2 : 4),
                TypeSwitch(
                  left: 'Трата',
                  right: 'Доход',
                  isRight: _isIncome,
                  onChanged: (v) => setState(() {
                    _isIncome = v;
                    _category = _lastFor(v);
                  }),
                ),
                SizedBox(height: compact ? 4 : 8),
                AmountField(
                  controller: _amount,
                  focusNode: _amountFocus,
                  height: compact ? 68 : 72,
                  onChanged: () => setState(() {}),
                  onSubmitted: _save,
                ),
                SizedBox(height: compact ? 2 : 6),
                AnimatedSize(
                  duration: kFast,
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: CatGrid(
                    key: ValueKey(_isIncome),
                    cats: cats,
                    selected: _category,
                    centered: _isIncome,
                    onTap: (c) => setState(() => _category = c.name),
                  ),
                ),
                SizedBox(height: compact ? 14 : 18),
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      Expanded(
                        child: NoteBox(
                          controller: _note,
                          hint: 'Заметка, например кофе',
                        ),
                      ),
                      const SizedBox(width: 8),
                      DateChip(label: formatDay(_date), onTap: _pickDate),
                    ],
                  ),
                ),
                SizedBox(height: compact ? 10 : 14),
                PrimaryButton(
                  label: isEdit
                      ? 'Сохранить'
                      : (isDraft ? 'Записать расход' : 'Добавить'),
                  enabled: ready,
                  onTap: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

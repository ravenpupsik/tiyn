import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/data/category.dart';
import 'package:money_app/data/txn.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/format.dart';
import 'package:money_app/widgets/category_pill.dart';
import 'package:money_app/widgets/frosted_glass.dart';
import 'package:money_app/widgets/pressable.dart';
import 'package:money_app/widgets/type_switch.dart';

class TxnEditor extends StatefulWidget {
  final Txn? existing;

  /// A draft of a new entry (e.g. from a plan): fields are prefilled but it is
  /// saved as a new entry.
  final Txn? draft;
  const TxnEditor({super.key, this.existing, this.draft});

  @override
  State<TxnEditor> createState() => _TxnEditorState();
}

class _TxnEditorState extends State<TxnEditor> {
  late final Txn? _src = widget.existing ?? widget.draft;
  late bool _isIncome = _src?.isIncome ?? false;
  late String? _category = _src?.category;
  late DateTime _date = _src?.date ?? DateTime.now();
  late final _amount = TextEditingController(
    text: _src?.amount.toString() ?? '',
  );
  late final _note = TextEditingController(text: _src?.note ?? '');
  final _amountFocus = FocusNode();
  bool _focusScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Open the keyboard only after the sheet has finished sliding in.
    if (_focusScheduled || _src != null) return;
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

  int get _value => int.tryParse(_amount.text) ?? 0;

  void _save() {
    if (_value <= 0) return;
    HapticFeedback.mediumImpact();
    final cats = _isIncome ? incomeCategories : expenseCategories;
    final cat = cats.any((c) => c.name == _category)
        ? _category!
        : cats.last.name;
    Navigator.pop(
      context,
      Txn(
        id:
            widget.existing?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        amount: _value,
        kind: _isIncome ? TxnKind.income : TxnKind.expense,
        category: cat,
        note: _note.text.trim(),
        date: _date,
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
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
    final cs = Theme.of(context).colorScheme;
    final dark = isDark(context);
    final cats = _isIncome ? incomeCategories : expenseCategories;
    final isEdit = widget.existing != null;
    final isDraft = widget.draft != null && !isEdit;
    final accent = cs.primary;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: FrostedGlass(
        blur: 20,
        fill: 0.82,
        radius: const BorderRadius.vertical(top: Radius.circular(32)),
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TypeSwitch(
                left: 'Расход',
                right: 'Доход',
                isRight: _isIncome,
                onChanged: (v) => setState(() {
                  _isIncome = v;
                  _category = null;
                }),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: IntrinsicWidth(
                      child: TextField(
                        controller: _amount,
                        focusNode: _amountFocus,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        textAlign: TextAlign.center,
                        cursorColor: accent,
                        style: TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: cs.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.25),
                          ),
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _save(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '₸',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Категория, можно пропустить',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: kFast,
                child: Wrap(
                  key: ValueKey(_isIncome),
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in cats)
                      CategoryPill(
                        cat: c,
                        selected: _category == c.name,
                        onTap: () => setState(
                          () => _category = _category == c.name ? null : c.name,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _note,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Заметка',
                        prefixIcon: const Icon(Icons.edit_note_rounded),
                        filled: true,
                        fillColor: cs.onSurface.withValues(
                          alpha: dark ? 0.07 : 0.05,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Pressable(
                    onTap: _pickDate,
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(
                          alpha: dark ? 0.07 : 0.05,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formatDay(_date),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedOpacity(
                duration: kFast,
                opacity: _value > 0 ? 1 : 0.45,
                child: Pressable(
                  onTap: _value > 0 ? _save : null,
                  child: AnimatedContainer(
                    duration: kFast,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(colors: kAmberGradient),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      isEdit
                          ? 'Сохранить'
                          : (isDraft ? 'Записать расход' : 'Добавить'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

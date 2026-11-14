import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/data/category.dart';
import 'package:money_app/data/plan.dart';
import 'package:money_app/screens/plans/plan_actions.dart';
import 'package:money_app/theme/cat_icons.dart';
import 'package:money_app/theme/glina_theme.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/spaced_digits.dart';
import 'package:money_app/widgets/glass_sheet.dart';
import 'package:money_app/widgets/pressable.dart';
import 'package:money_app/widgets/primary_button.dart';
import 'package:money_app/widgets/round_icon_button.dart';
import 'package:money_app/widgets/sheet_fields.dart';

class _CategoryPill extends StatelessWidget {
  final Category cat;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryPill({
    required this.cat,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final color = cat.forDark(g.dark);
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: kFast,
        curve: Curves.easeOut,
        height: 40,
        padding: const EdgeInsets.only(left: 8, right: 14),
        decoration: BoxDecoration(
          color: selected ? Glina.tint(color, g.surf) : g.field,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CatIcon(cat.icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              cat.name,
              style: golos(
                13,
                selected ? 700 : 600,
                color: selected ? g.ink : g.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlanEditor extends StatefulWidget {
  final Plan? existing;
  const PlanEditor({super.key, this.existing});

  @override
  State<PlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends State<PlanEditor> {
  late String? _category = (widget.existing?.category.isEmpty ?? true)
      ? null
      : widget.existing!.category;
  late DateTime? _due = widget.existing?.due;
  late final _amount = TextEditingController(
    text: widget.existing == null
        ? ''
        : SpacedDigits.group(widget.existing!.amount.toString()),
  );
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  final _amountFocus = FocusNode();
  bool _focusScheduled = false;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_focusScheduled || widget.existing != null) return;
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
    _title.dispose();
    super.dispose();
  }

  int get _value => int.tryParse(_amount.text.replaceAll(' ', '')) ?? 0;
  bool get _ready => _value > 0 && _title.text.trim().isNotEmpty;

  void _save() {
    if (!_ready) return;
    HapticFeedback.mediumImpact();
    Navigator.pop(
      context,
      Plan(
        id:
            widget.existing?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: _title.text.trim(),
        amount: _value,
        category: _category ?? '',
        due: _due,
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _due ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (d != null) setState(() => _due = d);
  }

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final isEdit = widget.existing != null;

    return SheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isEdit ? 'План' : 'Новый план',
            style: golos(17, 700, color: g.ink),
          ),
          const SizedBox(height: 4),
          AmountField(
            controller: _amount,
            focusNode: _amountFocus,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 14),
          NoteBox(controller: _title, hint: 'На что? Например, зубной'),
          const SizedBox(height: 16),
          Text(
            'Категория, можно пропустить',
            style: golos(13, 500, color: g.ink3),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in expenseCategories)
                _CategoryPill(
                  cat: c,
                  selected: _category == c.name,
                  onTap: () => setState(
                    () => _category = _category == c.name ? null : c.name,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              DateChip(
                label: _due == null ? 'Дата, можно без неё' : formatDue(_due!),
                onTap: _pickDate,
              ),
              if (_due != null) ...[
                const SizedBox(width: 8),
                RoundIconButton(
                  icon: Icons.close_rounded,
                  label: 'Убрать дату',
                  onTap: () => setState(() => _due = null),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: isEdit ? 'Сохранить' : 'Запланировать',
            enabled: _ready,
            onTap: _save,
          ),
        ],
      ),
    );
  }
}

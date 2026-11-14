import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/data/category.dart';
import 'package:money_app/data/plan.dart';
import 'package:money_app/screens/plans/plan_actions.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/widgets/category_pill.dart';
import 'package:money_app/widgets/frosted_glass.dart';
import 'package:money_app/widgets/pressable.dart';
import 'package:money_app/widgets/round_icon_button.dart';

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
    text: widget.existing?.amount.toString() ?? '',
  );
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  final _amountFocus = FocusNode();
  bool _focusScheduled = false;

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

  int get _value => int.tryParse(_amount.text) ?? 0;
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
    final cs = Theme.of(context).colorScheme;
    final dark = isDark(context);
    final isEdit = widget.existing != null;
    final fill = cs.onSurface.withValues(alpha: dark ? 0.07 : 0.05);

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
              const SizedBox(height: 14),
              Text(
                isEdit ? 'План' : 'Новый план',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
                        cursorColor: kSlate,
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
              const SizedBox(height: 6),
              TextField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'На что? Например, зубной',
                  helperText: _title.text.trim().isEmpty && _value > 0
                      ? 'Напиши, на что, чтобы потом не забыть'
                      : null,
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  filled: true,
                  fillColor: fill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 14),
              Text(
                'Категория, можно пропустить',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in expenseCategories)
                    CategoryPill(
                      cat: c,
                      selected: _category == c.name,
                      onTap: () => setState(
                        () => _category = _category == c.name ? null : c.name,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Pressable(
                      onTap: _pickDate,
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: fill,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: cs.onSurface.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _due == null
                                    ? 'Дата, можно без неё'
                                    : formatDue(_due!),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _due == null
                                      ? cs.onSurface.withValues(alpha: 0.5)
                                      : cs.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_due != null) ...[
                    const SizedBox(width: 8),
                    RoundIconButton(
                      icon: Icons.close_rounded,
                      onTap: () => setState(() => _due = null),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              AnimatedOpacity(
                duration: kFast,
                opacity: _ready ? 1 : 0.45,
                child: Pressable(
                  onTap: _ready ? _save : null,
                  child: Container(
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(colors: kSlateGradient),
                      boxShadow: [
                        BoxShadow(
                          color: kSlate.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      isEdit ? 'Сохранить' : 'Запланировать',
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

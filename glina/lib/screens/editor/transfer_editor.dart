import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/data/txn.dart';
import 'package:money_app/data/wallet.dart';
import 'package:money_app/theme/glina_theme.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/format.dart';
import 'package:money_app/utils/spaced_digits.dart';
import 'package:money_app/widgets/glass_sheet.dart';
import 'package:money_app/widgets/primary_button.dart';
import 'package:money_app/widgets/sheet_fields.dart';
import 'package:money_app/widgets/type_switch.dart';

class TransferEditor extends StatefulWidget {
  final Wallet wallet;
  final Txn? existing;
  final bool toPiggy;
  const TransferEditor({
    super.key,
    required this.wallet,
    this.existing,
    this.toPiggy = true,
  });

  @override
  State<TransferEditor> createState() => _TransferEditorState();
}

class _TransferEditorState extends State<TransferEditor> {
  late bool _toPiggy = widget.existing == null
      ? widget.toPiggy
      : widget.existing!.kind == TxnKind.toPiggy;
  late DateTime _date = widget.existing?.date ?? DateTime.now();
  late final _amount = TextEditingController(
    text: widget.existing == null
        ? ''
        : SpacedDigits.group(widget.existing!.amount.toString()),
  );
  late final _note = TextEditingController(text: widget.existing?.note ?? '');
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
    _note.dispose();
    super.dispose();
  }

  int get _value => int.tryParse(_amount.text.replaceAll(' ', '')) ?? 0;

  // Available amount excluding this entry (when editing).
  int get _piggyAvailable =>
      widget.wallet.piggy - (widget.existing?.piggyDelta ?? 0);
  int get _handAvailable =>
      widget.wallet.onHand - (widget.existing?.handDelta ?? 0);

  bool get _tooMuchOut =>
      !_toPiggy && _value > _piggyAvailable.clamp(0, 1 << 62);
  bool get _moreThanHand => _toPiggy && _value > _handAvailable;
  // Editing a deposit: it can't become smaller than what was withdrawn after
  // it.
  bool get _tooLittleIn => _toPiggy && _piggyAvailable + _value < 0;
  bool get _canSave => _value > 0 && !_tooMuchOut && !_tooLittleIn;

  void _save() {
    if (!_canSave) return;
    HapticFeedback.mediumImpact();
    Navigator.pop(
      context,
      Txn(
        id:
            widget.existing?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        amount: _value,
        kind: _toPiggy ? TxnKind.toPiggy : TxnKind.fromPiggy,
        category: '',
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
    final g = context.g;
    final isEdit = widget.existing != null;

    String? hint;
    Color hintColor = g.ink2;
    if (_tooMuchOut) {
      hint = 'В копилке только ${formatMoney(_piggyAvailable)}';
      hintColor = g.accentText;
    } else if (_tooLittleIn) {
      hint =
          'Минимум ${formatMoney(-_piggyAvailable)}, иначе копилка уйдёт в минус';
      hintColor = g.accentText;
    } else if (_moreThanHand) {
      hint = 'Это больше, чем у тебя на руках. Может, не вписан доход?';
      hintColor = g.accentText;
    } else {
      hint = _toPiggy
          ? 'На руках: ${formatMoney(_handAvailable)}'
          : 'В копилке: ${formatMoney(_piggyAvailable)}';
    }

    return SheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          TypeSwitch(
            left: 'Положить',
            right: 'Снять',
            isRight: !_toPiggy,
            onChanged: (v) => setState(() => _toPiggy = !v),
          ),
          const SizedBox(height: 8),
          AmountField(
            controller: _amount,
            focusNode: _amountFocus,
            onChanged: () => setState(() {}),
            onSubmitted: _save,
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: kFast,
            child: Text(
              hint,
              key: ValueKey(hint),
              style: golos(13, 600, color: hintColor),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: Row(
              children: [
                Expanded(
                  child: NoteBox(controller: _note, hint: 'Заметка'),
                ),
                const SizedBox(width: 8),
                DateChip(label: formatDay(_date), onTap: _pickDate),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: isEdit
                ? 'Сохранить'
                : (_toPiggy ? 'Положить в копилку' : 'Снять на руки'),
            enabled: _canSave,
            onTap: _save,
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/data/txn.dart';
import 'package:money_app/data/wallet.dart';
import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/format.dart';
import 'package:money_app/widgets/frosted_glass.dart';
import 'package:money_app/widgets/pressable.dart';
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
    text: widget.existing?.amount.toString() ?? '',
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

  int get _value => int.tryParse(_amount.text) ?? 0;

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
    final cs = Theme.of(context).colorScheme;
    final dark = isDark(context);
    final isEdit = widget.existing != null;

    String? hint;
    Color hintColor = cs.onSurface.withValues(alpha: 0.5);
    if (_tooMuchOut) {
      hint = 'В копилке только ${formatMoney(_piggyAvailable)}';
      hintColor = const Color(0xFFFF453A);
    } else if (_tooLittleIn) {
      hint =
          'Минимум ${formatMoney(-_piggyAvailable)}, иначе копилка уйдёт в минус';
      hintColor = const Color(0xFFFF453A);
    } else if (_moreThanHand) {
      hint = 'Это больше, чем у тебя на руках. Может, не вписан доход?';
      hintColor = amberText(context);
    } else {
      hint = _toPiggy
          ? 'На руках: ${formatMoney(_handAvailable)}'
          : 'В копилке: ${formatMoney(_piggyAvailable)}';
    }

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
                left: 'Положить',
                right: 'Снять',
                isRight: !_toPiggy,
                onChanged: (v) => setState(() => _toPiggy = !v),
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
                        cursorColor: kAmber,
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
              AnimatedSwitcher(
                duration: kFast,
                child: Text(
                  hint,
                  key: ValueKey(hint),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: hintColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
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
                opacity: _canSave ? 1 : 0.45,
                child: Pressable(
                  onTap: _canSave ? _save : null,
                  child: Container(
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(colors: kAmberGradient),
                      boxShadow: [
                        BoxShadow(
                          color: kAmber.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      isEdit
                          ? 'Сохранить'
                          : (_toPiggy ? 'Положить в копилку' : 'Снять на руки'),
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

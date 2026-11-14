import 'package:flutter/material.dart';

import 'package:money_app/theme/tokens.dart';
import 'package:money_app/utils/spaced_digits.dart';
import 'package:money_app/widgets/glass_sheet.dart';
import 'package:money_app/widgets/primary_button.dart';
import 'package:money_app/widgets/sheet_fields.dart';

class PiggyStartSheet extends StatefulWidget {
  final int initial;
  const PiggyStartSheet({super.key, required this.initial});

  @override
  State<PiggyStartSheet> createState() => _PiggyStartSheetState();
}

class _PiggyStartSheetState extends State<PiggyStartSheet> {
  late final _ctrl = TextEditingController(
    text: widget.initial > 0
        ? SpacedDigits.group(widget.initial.toString())
        : '',
  );
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  int get _value => int.tryParse(_ctrl.text.replaceAll(' ', '')) ?? 0;

  void _save() => Navigator.pop(context, _value);

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return SheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'Сколько уже лежит?',
            style: golos(20, 700, color: g.ink, height: 1.2),
          ),
          const SizedBox(height: 6),
          Text(
            'Сумма, которая была на депозите до Tiyn.\nВ расходы и историю она не попадёт.',
            style: golos(13, 500, color: g.ink2, height: 1.35),
          ),
          const SizedBox(height: 8),
          AmountField(
            controller: _ctrl,
            focusNode: _focus,
            onChanged: () => setState(() {}),
            onSubmitted: _save,
          ),
          const SizedBox(height: 12),
          PrimaryButton(label: 'Сохранить', onTap: _save),
        ],
      ),
    );
  }
}

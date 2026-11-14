import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:money_app/theme/tokens.dart';
import 'package:money_app/widgets/frosted_glass.dart';
import 'package:money_app/widgets/pressable.dart';

class PiggyStartSheet extends StatefulWidget {
  final int initial;
  const PiggyStartSheet({super.key, required this.initial});

  @override
  State<PiggyStartSheet> createState() => _PiggyStartSheetState();
}

class _PiggyStartSheetState extends State<PiggyStartSheet> {
  late final _ctrl = TextEditingController(
    text: widget.initial > 0 ? widget.initial.toString() : '',
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() => Navigator.pop(context, int.tryParse(_ctrl.text) ?? 0);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: FrostedGlass(
        blur: 20,
        fill: 0.82,
        radius: const BorderRadius.vertical(top: Radius.circular(32)),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 18),
              Text(
                'Сколько уже лежит?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Сумма, которая была на депозите до Tiyn.\nВ расходы и историю она не попадёт.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.55),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: IntrinsicWidth(
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        textAlign: TextAlign.center,
                        cursorColor: cs.onSurface,
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
              const SizedBox(height: 12),
              Pressable(
                onTap: _save,
                child: Container(
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(colors: kAmberGradient),
                  ),
                  child: const Text(
                    'Сохранить',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
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

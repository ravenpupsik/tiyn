import 'dart:async';

import 'package:flutter/material.dart';

import 'package:money_app/theme/glina_theme.dart';
import 'package:money_app/theme/tokens.dart';

Future<T?> showGlassSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: Colors.black.withValues(alpha: isDark(context) ? 0.55 : 0.45),
    builder: (_) => child,
  );
}

class SheetFrame extends StatelessWidget {
  final Widget child;
  const SheetFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: kb),
      child: Container(
        decoration: BoxDecoration(
          color: g.surf,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          minimum: EdgeInsets.only(bottom: kb > 0 ? 8 : 20),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 16,
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
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

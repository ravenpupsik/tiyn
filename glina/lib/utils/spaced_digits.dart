import 'package:flutter/services.dart';

/// Formats digits with spaces between thousands ("36 000"); the field holds
/// digits only.
class SpacedDigits extends TextInputFormatter {
  const SpacedDigits();

  static String group(String digits) {
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final nonDigit = RegExp(r'\D');
    var digits = newValue.text.replaceAll(nonDigit, '');
    if (digits.length > 10) digits = digits.substring(0, 10);
    final end = newValue.selection.end.clamp(0, newValue.text.length);
    var before = newValue.text
        .substring(0, end)
        .replaceAll(nonDigit, '')
        .length;
    if (before > digits.length) before = digits.length;
    final text = group(digits);
    var offset = 0, seen = 0;
    while (offset < text.length && seen < before) {
      if (text[offset] != ' ') seen++;
      offset++;
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

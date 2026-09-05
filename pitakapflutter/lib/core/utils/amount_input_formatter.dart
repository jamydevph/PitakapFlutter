import 'package:flutter/services.dart';

class AmountInputFormatter extends TextInputFormatter {
  static const int maxDecimals = 2;

  const AmountInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = clean(newValue.text);

    if (cleaned == newValue.text) return newValue;

    final removed = newValue.text.length - cleaned.length;
    final offset = (newValue.selection.end - removed).clamp(0, cleaned.length);

    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: offset),
    );
  }

  static String clean(String raw) {
    final kept = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    final firstDot = kept.indexOf('.');

    if (firstDot == -1) return kept;

    final whole = kept.substring(0, firstDot);
    final fraction = kept.substring(firstDot + 1).replaceAll('.', '');

    if (fraction.length <= maxDecimals) return '$whole.$fraction';

    return '$whole.${fraction.substring(0, maxDecimals)}';
  }
}

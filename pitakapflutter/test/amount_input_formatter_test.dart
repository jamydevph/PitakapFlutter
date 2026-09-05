import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pitakapflutter/core/utils/amount_input_formatter.dart';

void main() {
  const formatter = AmountInputFormatter();

  String typed(String input) => formatter
      .formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(
          text: input,
          selection: TextSelection.collapsed(offset: input.length),
        ),
      )
      .text;

  group('AmountInputFormatter.clean', () {
    test('a thousands separator is STRIPPED, not truncated at', () {
      expect(AmountInputFormatter.clean('1,500'), '1500');
      expect(AmountInputFormatter.clean('1,234,567'), '1234567');
    });

    test('a space-separated amount keeps every digit', () {
      expect(AmountInputFormatter.clean('1 500'), '1500');
    });

    test('letters are dropped', () {
      expect(AmountInputFormatter.clean('abc'), '');
      expect(AmountInputFormatter.clean('1a2b3'), '123');
      expect(AmountInputFormatter.clean(r'$100'), '100');
    });

    test('a minus sign is dropped, so a negative can never be entered', () {
      expect(AmountInputFormatter.clean('-100'), '100');
    });

    test('plain values pass through untouched', () {
      expect(AmountInputFormatter.clean(''), '');
      expect(AmountInputFormatter.clean('0'), '0');
      expect(AmountInputFormatter.clean('549'), '549');
      expect(AmountInputFormatter.clean('12.34'), '12.34');
      expect(AmountInputFormatter.clean('.5'), '.5');
    });

    test('decimals are capped at two, keeping the whole part intact', () {
      expect(AmountInputFormatter.clean('12.3456'), '12.34');
      expect(AmountInputFormatter.clean('1500.999'), '1500.99');
    });

    test('only the FIRST decimal point survives', () {
      expect(AmountInputFormatter.clean('12.34.56'), '12.34');
      expect(AmountInputFormatter.clean('1.2.3'), '1.23');
    });

    test('a trailing point is kept so the user can keep typing', () {
      expect(AmountInputFormatter.clean('12.'), '12.');
    });

    test('scientific notation loses the exponent rather than becoming 1', () {
      expect(AmountInputFormatter.clean('1e3'), '13');
    });
  });

  group('formatEditUpdate', () {
    test('1,500 reaches the field as 1500 — the Day 28 bug', () {
      expect(typed('1,500'), '1500');
    });

    test('an untouched value is returned as the same instance', () {
      const value = TextEditingValue(
        text: '549',
        selection: TextSelection.collapsed(offset: 3),
      );

      expect(formatter.formatEditUpdate(TextEditingValue.empty, value), value);
    });

    test('the cursor stays put when a character is rejected mid-string', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '1500',
          selection: TextSelection.collapsed(offset: 1),
        ),
        const TextEditingValue(
          text: '1,500',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );

      expect(result.text, '1500');
      expect(result.selection.baseOffset, 1);
    });

    test('the cursor never lands outside the text', () {
      final result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: 'abc',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );

      expect(result.text, '');
      expect(result.selection.baseOffset, 0);
    });
  });
}

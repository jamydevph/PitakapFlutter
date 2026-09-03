import 'package:flutter_test/flutter_test.dart';

import 'package:pitakapflutter/core/resources/strings.dart';
import 'package:pitakapflutter/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('rejects an empty or whitespace-only value', () {
      expect(Validators.email(null), Strings.emailRequired);
      expect(Validators.email(''), Strings.emailRequired);
      expect(Validators.email('   '), Strings.emailRequired);
    });

    test('rejects addresses that are not well formed', () {
      const invalid = [
        'spiderman',
        'spiderman@',
        '@gmail.com',
        'spiderman@gmail',
        'spider man@gmail.com',
        'spiderman@@gmail.com',
      ];

      for (final value in invalid) {
        expect(Validators.email(value), Strings.emailInvalid, reason: value);
      }
    });

    test('accepts well formed addresses and ignores surrounding space', () {
      const valid = [
        'spiderman@gmail.com',
        '  spiderman@gmail.com  ',
        'peter.parker+news@daily-bugle.co.uk',
        'diane_1@sub.domain.ph',
      ];

      for (final value in valid) {
        expect(Validators.email(value), isNull, reason: value);
      }
    });
  });

  group('Validators.password', () {
    test('rejects an empty value', () {
      expect(Validators.password(null), Strings.passwordRequired);
      expect(Validators.password(''), Strings.passwordRequired);
    });

    test('rejects values below the minimum length', () {
      expect(Validators.password('12345'), Strings.passwordTooShort);
    });

    test('accepts values at or above the minimum length', () {
      expect(Validators.password('123456'), isNull);
      expect(Validators.password('a-longer-passphrase'), isNull);
    });

    test('does not trim, because spaces are valid password characters', () {
      expect(Validators.password('   a  '), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('rejects an empty confirmation', () {
      expect(
        Validators.confirmPassword(null, 'secret123'),
        Strings.confirmPasswordRequired,
      );
      expect(
        Validators.confirmPassword('', 'secret123'),
        Strings.confirmPasswordRequired,
      );
    });

    test('rejects a confirmation that differs', () {
      expect(
        Validators.confirmPassword('secret124', 'secret123'),
        Strings.passwordsDoNotMatch,
      );
    });

    test('is case and whitespace sensitive', () {
      expect(
        Validators.confirmPassword('Secret123', 'secret123'),
        Strings.passwordsDoNotMatch,
      );
      expect(
        Validators.confirmPassword('secret123 ', 'secret123'),
        Strings.passwordsDoNotMatch,
      );
    });

    test('accepts an exact match', () {
      expect(Validators.confirmPassword('secret123', 'secret123'), isNull);
    });
  });

  group('Validators.notEmpty', () {
    test('rejects null, empty and whitespace-only values', () {
      expect(Validators.notEmpty(null, Strings.firstNameRequired),
          Strings.firstNameRequired);
      expect(Validators.notEmpty('', Strings.firstNameRequired),
          Strings.firstNameRequired);
      expect(Validators.notEmpty('   ', Strings.firstNameRequired),
          Strings.firstNameRequired);
    });

    test('accepts any value with visible characters', () {
      expect(Validators.notEmpty('Diane', Strings.firstNameRequired), isNull);
      expect(Validators.notEmpty('  Diane  ', Strings.firstNameRequired),
          isNull);
    });

    test('returns the message it was given', () {
      expect(Validators.notEmpty('', Strings.lastNameRequired),
          Strings.lastNameRequired);
    });
  });

  group('Validators.amount', () {
    test('rejects null, empty and whitespace-only values as REQUIRED', () {
      expect(Validators.amount(null), Strings.amountRequired);
      expect(Validators.amount(''), Strings.amountRequired);
      expect(Validators.amount('   '), Strings.amountRequired);
    });

    test('⭐ zero is INVALID, not missing — the messages differ', () {
      expect(Validators.amount('0'), Strings.amountInvalid);
      expect(Validators.amount('0.00'), Strings.amountInvalid);
      expect(Validators.amount('  '), Strings.amountRequired);
    });

    test('⭐ a negative amount is rejected', () {
      expect(Validators.amount('-1'), Strings.amountInvalid);
      expect(Validators.amount('-0.01'), Strings.amountInvalid);
    });

    test('⭐ anything unparseable is rejected, not silently coerced', () {
      for (final raw in ['abc', '1,500', '12.34.56', '1 500', '\$100', '--5']) {
        expect(Validators.amount(raw), Strings.amountInvalid, reason: raw);
      }
    });

    test('⭐ a bare decimal point is rejected', () {
      expect(Validators.amount('.'), Strings.amountInvalid);
    });

    test('accepts whole numbers and decimals, and ignores surrounding space', () {
      expect(Validators.amount('1'), isNull);
      expect(Validators.amount('549'), isNull);
      expect(Validators.amount('0.01'), isNull);
      expect(Validators.amount('1234.56'), isNull);
      expect(Validators.amount('  250  '), isNull);
    });

    test('a leading decimal point without a whole part is accepted', () {
      expect(Validators.amount('.5'), isNull);
    });

    test('⭐ scientific notation parses, so it is accepted — know that', () {
      expect(Validators.amount('1e3'), isNull);
    });
  });
}

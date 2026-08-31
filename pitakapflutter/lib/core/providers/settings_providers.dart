import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitakapflutter/core/providers/app_providers.dart';
import 'package:pitakapflutter/core/resources/constants.dart';
import 'package:pitakapflutter/core/resources/keys.dart';

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final stored = ref
        .watch(sharedPreferencesProvider)
        .getString(Keys.prefsThemeMode);
    return _decode(stored);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    await ref
        .read(sharedPreferencesProvider)
        .setString(Keys.prefsThemeMode, _encode(mode));
  }

  Future<void> toggle(Brightness current) => setThemeMode(
        current == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
      );

  static ThemeMode _decode(String? value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _encode(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class DefaultCurrencyController extends Notifier<String> {
  @override
  String build() {
    final stored = ref
        .watch(sharedPreferencesProvider)
        .getString(Keys.prefsDefaultCurrency);

    if (stored == null || !Constants.currencies.contains(stored)) {
      return Constants.defaultCurrency;
    }

    return stored;
  }

  Future<void> setCurrency(String code) async {
    if (state == code || !Constants.currencies.contains(code)) return;

    state = code;

    await ref
        .read(sharedPreferencesProvider)
        .setString(Keys.prefsDefaultCurrency, code);
  }
}

final defaultCurrencyProvider =
    NotifierProvider<DefaultCurrencyController, String>(
      DefaultCurrencyController.new,
    );

class DefaultReminderDaysController extends Notifier<int> {
  @override
  int build() {
    final stored = ref
        .watch(sharedPreferencesProvider)
        .getInt(Keys.prefsDefaultReminderDays);

    if (stored == null || !Constants.reminderDayOptions.contains(stored)) {
      return Constants.defaultReminderDaysBefore;
    }

    return stored;
  }

  Future<void> setDays(int days) async {
    if (state == days || !Constants.reminderDayOptions.contains(days)) return;

    state = days;

    await ref
        .read(sharedPreferencesProvider)
        .setInt(Keys.prefsDefaultReminderDays, days);
  }
}

final defaultReminderDaysProvider =
    NotifierProvider<DefaultReminderDaysController, int>(
      DefaultReminderDaysController.new,
    );

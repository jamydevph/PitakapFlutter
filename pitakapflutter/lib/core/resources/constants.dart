import 'package:flutter/material.dart';

class Constants {
  static const String defaultCurrency = 'PHP';
  static const String currencySymbol = '₱';
  static const int defaultReminderDaysBefore = 3;

  static const String appVersion = '1.0.0';

  static const List<String> currencies = [
    'PHP',
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'SGD',
    'AUD',
  ];

  static const List<int> reminderDayOptions = [0, 1, 3, 5, 7];

  static const Duration splashMinimumDuration = Duration(milliseconds: 1200);

  static const List<String> subscriptionCategories = [
    'entertainment',
    'utilities',
    'health',
    'productivity',
    'education',
    'other',
  ];

  static const List<String> expenseCategories = [
    'food',
    'transport',
    'groceries',
    'shopping',
    'bills',
    'health',
    'entertainment',
    'other',
  ];

  static const List<String> paymentMethods = [
    'cash',
    'card',
    'gcash',
    'other',
  ];

  static const Map<String, IconData> categoryIcons = {
    'entertainment': Icons.movie_outlined,
    'utilities': Icons.bolt_outlined,
    'health': Icons.favorite_outline,
    'productivity': Icons.work_outline,
    'education': Icons.school_outlined,
    'food': Icons.restaurant_outlined,
    'transport': Icons.directions_bus_outlined,
    'groceries': Icons.shopping_cart_outlined,
    'shopping': Icons.shopping_bag_outlined,
    'bills': Icons.receipt_long_outlined,
    'other': Icons.category_outlined,
  };

  static const Map<String, IconData> subscriptionIcons = {
    'movie': Icons.movie_outlined,
    'music': Icons.music_note_outlined,
    'cloud': Icons.cloud_outlined,
    'game': Icons.sports_esports_outlined,
    'fitness': Icons.fitness_center_outlined,
    'news': Icons.newspaper_outlined,
    'wifi': Icons.wifi_outlined,
    'phone': Icons.phone_iphone_outlined,
    'tv': Icons.tv_outlined,
    'book': Icons.menu_book_outlined,
    'other': Icons.subscriptions_outlined,
  };
}

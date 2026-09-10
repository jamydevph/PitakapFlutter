import 'package:pitakapflutter/core/resources/constants.dart';

class WalletEntity {
  final String id;
  final String userId;
  final String name;
  final String description;
  final double openingBalance;
  final String currency;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WalletEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.openingBalance,
    this.description = '',
    this.currency = Constants.defaultCurrency,
    this.createdAt,
    this.updatedAt,
  });

  bool get hasDescription => description.isNotEmpty;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WalletEntity &&
            other.id == id &&
            other.userId == userId &&
            other.name == name &&
            other.description == description &&
            other.openingBalance == openingBalance &&
            other.currency == currency &&
            other.createdAt == createdAt &&
            other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    name,
    description,
    openingBalance,
    currency,
    createdAt,
    updatedAt,
  ]);
}

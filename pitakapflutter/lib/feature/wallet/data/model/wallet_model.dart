import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pitakapflutter/core/resources/constants.dart';
import 'package:pitakapflutter/core/resources/keys.dart';
import 'package:pitakapflutter/feature/wallet/domain/entities/wallet_entity.dart';

class WalletModel extends WalletEntity {
  const WalletModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.openingBalance,
    super.description,
    super.currency,
    super.createdAt,
    super.updatedAt,
  });

  factory WalletModel.fromEntity(WalletEntity entity) {
    return WalletModel(
      id: entity.id,
      userId: entity.userId,
      name: entity.name,
      openingBalance: entity.openingBalance,
      description: entity.description,
      currency: entity.currency,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory WalletModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return WalletModel.fromMap(doc.id, doc.data());
  }

  factory WalletModel.fromMap(String id, Map<String, dynamic>? data) {
    final map = data ?? const <String, dynamic>{};

    return WalletModel(
      id: id,
      userId: map[Keys.userId] as String? ?? '',
      name: map[Keys.name] as String? ?? '',
      description: map[Keys.description] as String? ?? '',
      openingBalance: (map[Keys.openingBalance] as num?)?.toDouble() ?? 0,
      currency: map[Keys.currency] as String? ?? Constants.defaultCurrency,
      createdAt: (map[Keys.createdAt] as Timestamp?)?.toDate(),
      updatedAt: (map[Keys.updatedAt] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toCreateMap() => {
    Keys.userId: userId,
    ..._writableFields,
    Keys.createdAt: FieldValue.serverTimestamp(),
    Keys.updatedAt: FieldValue.serverTimestamp(),
  };

  Map<String, dynamic> toUpdateMap() => {
    ..._writableFields,
    Keys.updatedAt: FieldValue.serverTimestamp(),
  };

  Map<String, dynamic> toRestoreMap() => {
    Keys.userId: userId,
    ..._writableFields,
    Keys.createdAt: createdAt == null
        ? FieldValue.serverTimestamp()
        : Timestamp.fromDate(createdAt!),
    Keys.updatedAt: FieldValue.serverTimestamp(),
  };

  Map<String, dynamic> get _writableFields => {
    Keys.name: name,
    Keys.description: description,
    Keys.openingBalance: openingBalance,
    Keys.currency: currency,
  };
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pitakapflutter/core/resources/constants.dart';
import 'package:pitakapflutter/core/resources/keys.dart';
import 'package:pitakapflutter/feature/wallet/data/model/wallet_model.dart';
import 'package:pitakapflutter/feature/wallet/domain/entities/wallet_entity.dart';

void main() {
  group('WalletModel.fromMap', () {
    test('reads the id from the document id, not the payload', () {
      final model = WalletModel.fromMap('wallet-from-doc', {
        Keys.userId: 'uid-1',
        Keys.name: 'Main Wallet',
      });

      expect(model.id, 'wallet-from-doc');
    });

    test('maps every stored field', () {
      final created = DateTime.utc(2026, 8, 15, 4, 30);

      final model = WalletModel.fromMap('wallet-1', {
        Keys.userId: 'uid-1',
        Keys.name: 'Main Wallet',
        Keys.description: 'Everyday spending',
        Keys.openingBalance: 5000.0,
        Keys.currency: 'PHP',
        Keys.createdAt: Timestamp.fromDate(created),
        Keys.updatedAt: Timestamp.fromDate(created),
      });

      expect(model.userId, 'uid-1');
      expect(model.name, 'Main Wallet');
      expect(model.description, 'Everyday spending');
      expect(model.openingBalance, 5000);
      expect(model.currency, 'PHP');
      expect(model.createdAt, created.toLocal());
      expect(model.updatedAt, created.toLocal());
    });

    test('an int balance typed in the console still reads as a double', () {
      final model = WalletModel.fromMap('wallet-1', {
        Keys.openingBalance: 5000,
      });

      expect(model.openingBalance, 5000.0);
      expect(model.openingBalance, isA<double>());
    });

    test('a missing document never throws and defaults every field', () {
      final model = WalletModel.fromMap('wallet-1', null);

      expect(model.name, isEmpty);
      expect(model.description, isEmpty);
      expect(model.hasDescription, isFalse);
      expect(model.openingBalance, 0);
      expect(model.currency, Constants.defaultCurrency);
      expect(model.createdAt, isNull);
    });
  });

  group('write maps', () {
    WalletModel model({DateTime? createdAt}) => WalletModel(
      id: 'wallet-1',
      userId: 'uid-1',
      name: 'Main Wallet',
      description: 'Everyday spending',
      openingBalance: 5000,
      createdAt: createdAt,
    );

    test('toCreateMap stamps the owner and both timestamps', () {
      final map = model().toCreateMap();

      expect(map[Keys.userId], 'uid-1');
      expect(map[Keys.name], 'Main Wallet');
      expect(map[Keys.openingBalance], 5000);
      expect(map[Keys.createdAt], isA<FieldValue>());
      expect(map[Keys.updatedAt], isA<FieldValue>());
    });

    test('toUpdateMap never rewrites the owner or the creation time', () {
      final map = model().toUpdateMap();

      expect(map.containsKey(Keys.userId), isFalse);
      expect(map.containsKey(Keys.createdAt), isFalse);
      expect(map[Keys.updatedAt], isA<FieldValue>());
    });

    test('toRestoreMap preserves the original creation time', () {
      final created = DateTime(2026, 8, 15);
      final map = model(createdAt: created).toRestoreMap();

      expect(map[Keys.userId], 'uid-1');
      expect(map[Keys.createdAt], Timestamp.fromDate(created));
    });

    test('toRestoreMap falls back to a server stamp when none was kept', () {
      final map = model().toRestoreMap();

      expect(map[Keys.createdAt], isA<FieldValue>());
    });
  });

  group('WalletModel.fromEntity', () {
    test('carries every field across', () {
      const entity = WalletEntity(
        id: 'wallet-1',
        userId: 'uid-1',
        name: 'Savings Wallet',
        openingBalance: 3000,
        description: 'Emergency fund',
        currency: 'PHP',
      );

      final model = WalletModel.fromEntity(entity);

      expect(model.id, entity.id);
      expect(model.userId, entity.userId);
      expect(model.name, entity.name);
      expect(model.openingBalance, entity.openingBalance);
      expect(model.description, entity.description);
      expect(model.currency, entity.currency);
    });
  });
}

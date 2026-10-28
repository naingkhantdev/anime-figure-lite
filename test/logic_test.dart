import 'package:flutter_test/flutter_test.dart';

import 'package:anime_figure_shop_lite/logic/stock.dart';
import 'package:anime_figure_shop_lite/logic/subscription.dart';
import 'package:anime_figure_shop_lite/utils/dates.dart';
import 'package:anime_figure_shop_lite/utils/money.dart';
import 'package:anime_figure_shop_lite/utils/phone.dart';

void main() {
  final now = DateTime(2026, 10, 24, 12);

  group('shopStatus', () {
    test('no expiry date means waiting for approval', () {
      expect(shopStatus(null, now), ShopStatus.pending);
    });

    test('more than 7 days left is active', () {
      expect(
          shopStatus(now.add(const Duration(days: 8)), now), ShopStatus.active);
    });

    test('7 days or less is expiring soon', () {
      expect(shopStatus(now.add(const Duration(days: 7)), now),
          ShopStatus.expiringSoon);
      expect(shopStatus(now.add(const Duration(minutes: 1)), now),
          ShopStatus.expiringSoon);
    });

    test('at or after the expiry time is expired', () {
      expect(shopStatus(now, now), ShopStatus.expired);
      expect(shopStatus(now.subtract(const Duration(days: 1)), now),
          ShopStatus.expired);
    });

    test('only pending and expired shops are read-only', () {
      expect(ShopStatus.active.canWrite, isTrue);
      expect(ShopStatus.expiringSoon.canWrite, isTrue);
      expect(ShopStatus.pending.canWrite, isFalse);
      expect(ShopStatus.expired.canWrite, isFalse);
    });
  });

  group('daysLeft', () {
    test('counts part days as a whole day', () {
      expect(daysLeft(now.add(const Duration(hours: 1)), now), 1);
      expect(daysLeft(now.add(const Duration(days: 3)), now), 3);
      expect(daysLeft(now.add(const Duration(days: 3, hours: 1)), now), 4);
    });

    test('is never negative', () {
      expect(daysLeft(now.subtract(const Duration(days: 5)), now), 0);
    });
  });

  group('extendExpiry', () {
    test('extends from now when the shop is pending or expired', () {
      expect(extendExpiry(null, now, 1), DateTime(2026, 11, 24, 12));
      expect(extendExpiry(DateTime(2026, 1, 1), now, 1),
          DateTime(2026, 11, 24, 12));
    });

    test('extends from the current expiry when it is still running', () {
      expect(extendExpiry(DateTime(2026, 12, 1), now, 3), DateTime(2027, 3, 1));
    });

    test('clamps to the last day of a shorter month', () {
      expect(
          extendExpiry(DateTime(2027, 1, 31), now, 1), DateTime(2027, 2, 28));
      expect(
          extendExpiry(DateTime(2027, 8, 31), now, 6), DateTime(2028, 2, 29));
    });

    test('12 months is one year', () {
      expect(
          extendExpiry(DateTime(2027, 5, 10), now, 12), DateTime(2028, 5, 10));
    });
  });

  group('quantityAfter', () {
    test('stock in adds', () {
      expect(quantityAfter(5, MoveType.stockIn, 3), 8);
    });

    test('stock out subtracts', () {
      expect(quantityAfter(5, MoveType.stockOut, 5), 0);
    });

    test('adjust sets the counted quantity', () {
      expect(quantityAfter(5, MoveType.adjust, 2), 2);
      expect(quantityAfter(5, MoveType.adjust, 0), 0);
    });

    test('cannot take out more than is in stock', () {
      expect(() => quantityAfter(2, MoveType.stockOut, 3),
          throwsA(isA<StockException>()));
    });

    test('in and out need at least 1', () {
      expect(() => quantityAfter(2, MoveType.stockIn, 0),
          throwsA(isA<StockException>()));
      expect(() => quantityAfter(2, MoveType.stockOut, 0),
          throwsA(isA<StockException>()));
    });

    test('rejects negative counts and absurd numbers', () {
      expect(() => quantityAfter(2, MoveType.adjust, -1),
          throwsA(isA<StockException>()));
      expect(() => quantityAfter(0, MoveType.stockIn, maxQuantity + 1),
          throwsA(isA<StockException>()));
      expect(() => quantityAfter(maxQuantity, MoveType.stockIn, 1),
          throwsA(isA<StockException>()));
    });

    test('MoveType round-trips through its Firestore code', () {
      for (final t in MoveType.values) {
        expect(MoveType.fromCode(t.code), t);
      }
      expect(MoveType.stockIn.code, 'in');
      expect(MoveType.stockOut.code, 'out');
      expect(MoveType.fromCode('nonsense'), MoveType.adjust);
    });
  });

  group('parseWholeNumber', () {
    test('accepts digits with commas and spaces', () {
      expect(parseWholeNumber('25,000'), 25000);
      expect(parseWholeNumber(' 12 '), 12);
      expect(parseWholeNumber(''), isNull);
      expect(parseWholeNumber('1.5'), isNull);
      expect(parseWholeNumber('-3'), isNull);
    });
  });

  test('formatMmk', () {
    expect(formatMmk(0), '0 Ks');
    expect(formatMmk(25000), '25,000 Ks');
    expect(formatMmk(1234567), '1,234,567 Ks');
  });

  test('formatDate', () {
    expect(formatDate(DateTime(2026, 3, 5)), '5 Mar 2026');
    expect(formatDateTime(DateTime(2026, 3, 5, 9, 7)), '5 Mar 2026, 09:07');
  });

  group('normalizePhone', () {
    test('accepts and cleans Myanmar mobile numbers', () {
      expect(normalizePhone('09 123-456-789'), '09123456789');
      expect(normalizePhone('+959123456789'), '+959123456789');
    });

    test('rejects other input', () {
      expect(normalizePhone(''), isNull);
      expect(normalizePhone('12345'), isNull);
    });
  });
}

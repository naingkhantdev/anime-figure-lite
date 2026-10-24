import 'package:flutter_test/flutter_test.dart';

import 'package:anime_figure_shop_lite/data/order_repository.dart';

void main() {
  group('normalizePhone', () {
    test('accepts 09… and +959… numbers', () {
      expect(normalizePhone('09123456789'), '09123456789');
      expect(normalizePhone('+959123456789'), '+959123456789');
    });

    test('removes spaces and dashes', () {
      expect(normalizePhone('09 123-456-789'), '09123456789');
      expect(normalizePhone(' +95 9 123 456 789 '), '+959123456789');
    });

    test('accepts 7 to 9 digits after the prefix', () {
      expect(normalizePhone('091234567'), '091234567');
      expect(normalizePhone('09123456789'), '09123456789');
      expect(normalizePhone('09123456'), isNull);
      expect(normalizePhone('091234567890'), isNull);
    });

    test('rejects anything that is not a Myanmar mobile number', () {
      expect(normalizePhone(''), isNull);
      expect(normalizePhone('12345678901'), isNull);
      expect(normalizePhone('09abc456789'), isNull);
      expect(normalizePhone('959123456789'), isNull);
    });
  });
}

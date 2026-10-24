import 'package:flutter_test/flutter_test.dart';

import 'package:anime_figure_shop_lite/utils/money.dart';

void main() {
  test('formatCents formats integer cents for display', () {
    expect(formatCents(0), '0.00');
    expect(formatCents(5), '0.05');
    expect(formatCents(1999), '19.99');
    expect(formatCents(123456789), '1,234,567.89');
  });
}

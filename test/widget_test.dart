import 'package:flutter_test/flutter_test.dart';

import 'package:anime_figure_shop_lite/utils/money.dart';

void main() {
  test('formatMmk formats whole kyats for display', () {
    expect(formatMmk(0), '0 Ks');
    expect(formatMmk(500), '500 Ks');
    expect(formatMmk(25000), '25,000 Ks');
    expect(formatMmk(1234567), '1,234,567 Ks');
  });
}

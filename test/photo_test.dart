import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_figure_shop_lite/l10n/app_localizations.dart';
import 'package:anime_figure_shop_lite/providers/providers.dart';
import 'package:anime_figure_shop_lite/ui/pages/product_list_page.dart';

// The smallest valid PNG: one transparent pixel.
final _png = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  testWidgets('a photo saved from the app is read from Firestore',
      (tester) async {
    String? asked;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        photoBytesProvider.overrideWith((ref, id) async {
          asked = id;
          return _png;
        }),
      ],
      child: Localizations(
        locale: const Locale('en'),
        delegates: AppLocalizations.localizationsDelegates,
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: ProductImage(url: 'photo:abc123'),
        ),
      ),
    ));
    await tester.pump();
    expect(asked, 'abc123');
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<MemoryImage>());
  });
}

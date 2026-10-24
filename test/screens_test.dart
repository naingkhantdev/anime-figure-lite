import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_figure_shop_lite/logic/stock.dart';
import 'package:anime_figure_shop_lite/models/customer.dart';
import 'package:anime_figure_shop_lite/models/item.dart';
import 'package:anime_figure_shop_lite/models/product.dart';
import 'package:anime_figure_shop_lite/models/shop.dart';
import 'package:anime_figure_shop_lite/models/stock_move.dart';
import 'package:anime_figure_shop_lite/providers/providers.dart';
import 'package:anime_figure_shop_lite/ui/pages/item_detail_page.dart';
import 'package:anime_figure_shop_lite/ui/pages/product_list_page.dart';
import 'package:anime_figure_shop_lite/ui/pages/shop_home_page.dart';
import 'package:anime_figure_shop_lite/ui/pages/stock_move_page.dart';
import 'package:anime_figure_shop_lite/ui/pages/super_admin_page.dart';
import 'package:anime_figure_shop_lite/ui/theme.dart';

// Builds each screen from sample data, without Firebase, at a small phone
// size, so layout overflows and build errors fail here instead of on a phone.

final now = DateTime.now();

Item item(String id, String name, int qty, {int low = 2}) => Item(
      id: id,
      name: name,
      code: 'SKU-$id',
      unit: 'pcs',
      price: 25000,
      cost: 18000,
      quantity: qty,
      lowStockAt: low,
      isActive: true,
    );

final items = [
  item('1', 'Nendoroid Miku', 12),
  item('2', 'Gojo Satoru 1/7 scale figure, limited edition', 1),
  item('3', 'Acrylic stand', 0),
];

StockMove move(MoveType type, int qty, int before, int after,
        {String customer = ''}) =>
    StockMove(
      id: '$type$qty',
      type: type,
      itemId: '1',
      itemName: 'Nendoroid Miku',
      quantity: qty,
      quantityBefore: before,
      quantityAfter: after,
      unitPrice: type == MoveType.adjust ? 0 : 25000,
      customerId: customer.isEmpty ? '' : 'c1',
      customerName: customer,
      note: '',
      createdAt: now,
    );

final moves = [
  move(MoveType.stockOut, 2, 14, 12, customer: 'Ko Aung'),
  move(MoveType.adjust, 14, 15, 14),
  move(MoveType.stockIn, 10, 5, 15),
];

Shop shop(String id, String name, DateTime? expires) => Shop(
      id: id,
      name: name,
      phone: '09123456789',
      ownerEmail: '$id@example.com',
      expiresAt: expires,
      createdAt: now,
    );

final overrides = [
  authStateProvider.overrideWith((ref) => Stream.value(null)),
  productsProvider.overrideWith((ref) => Stream.value(const [
        Product(
            id: 'p1',
            name: 'Nendoroid Miku',
            description: '',
            price: 45000,
            stockQuantity: 3,
            isActive: true),
        Product(
            id: 'p2',
            name: 'Gojo Satoru 1/7 scale',
            description: '',
            price: 320000,
            stockQuantity: 0,
            isActive: true),
      ])),
  myShopProvider.overrideWith((ref) => Stream.value(
      shop('me', 'Sakura Figures', now.add(const Duration(days: 5))))),
  itemsProvider.overrideWith((ref) => Stream.value(items)),
  itemProvider.overrideWith(
      (ref, id) => Stream.value(items.firstWhere((i) => i.id == id))),
  recentMovesProvider.overrideWith((ref) => Stream.value(moves)),
  itemMovesProvider.overrideWith((ref, id) => Stream.value(moves)),
  customersProvider.overrideWith((ref) => Stream.value(const [
        Customer(
            id: 'c1',
            name: 'Ko Aung',
            phone: '09123456789',
            address: 'Yangon',
            note: ''),
      ])),
  allShopsProvider.overrideWith((ref) => Stream.value([
        shop('a', 'Sakura Figures', now.add(const Duration(days: 5))),
        shop('b', 'Mandalay Toys', now.add(const Duration(days: 120))),
        shop('c', 'New Shop', null),
        shop('d', 'Old Shop', now.subtract(const Duration(days: 3))),
      ])),
];

Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(360, 720) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: overrides,
    child: MaterialApp(theme: buildAppTheme(), home: screen),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('figure shop for guests, with the account menu', (tester) async {
    await pumpScreen(tester, const ProductListPage());
    expect(find.text('Nendoroid Miku'), findsOneWidget);
    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Open a shop'), findsOneWidget);
    expect(find.text('Sign out'), findsNothing);
  });

  testWidgets('shop home, every tab', (tester) async {
    await pumpScreen(tester, const ShopHomePage());
    expect(find.text('Nendoroid Miku'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget, reason: 'phone width');
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.textContaining('expires in 5 days'), findsOneWidget);
    for (final tab in ['History', 'Customers', 'Shop']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
    }
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('tablets get a side rail instead of the bottom bar',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 768) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: overrides,
      child: MaterialApp(theme: buildAppTheme(), home: const ShopHomePage()),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('Customers'));
    await tester.pumpAndSettle();
    expect(find.text('Ko Aung'), findsOneWidget);
  });

  testWidgets('item page', (tester) async {
    await pumpScreen(tester, const ItemDetailPage(itemId: '1'));
    expect(find.text('IN STOCK'), findsOneWidget);
    expect(find.textContaining('Ko Aung', skipOffstage: false), findsWidgets);
  });

  testWidgets('stock out page warns when over stock', (tester) async {
    await pumpScreen(
        tester, StockMovePage(item: items[1], initialType: MoveType.stockOut));
    await tester.enterText(find.byType(TextField).first, '5');
    await tester.pump();
    expect(find.text('Only 1 in stock.'), findsOneWidget);
  });

  testWidgets('super admin page', (tester) async {
    await pumpScreen(tester, const SuperAdminPage());
    expect(find.text('Waiting'), findsWidgets);
    await tester.tap(find.text('New Shop'));
    await tester.pumpAndSettle();
    expect(find.text('+ 1 month'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_figure_shop_lite/l10n/app_localizations.dart';
import 'package:anime_figure_shop_lite/logic/stock.dart';
import 'package:anime_figure_shop_lite/models/blacklist_entry.dart';
import 'package:anime_figure_shop_lite/models/cart_item.dart';
import 'package:anime_figure_shop_lite/models/customer.dart';
import 'package:anime_figure_shop_lite/models/item.dart';
import 'package:anime_figure_shop_lite/models/product.dart';
import 'package:anime_figure_shop_lite/models/shop.dart';
import 'package:anime_figure_shop_lite/models/shop_order.dart';
import 'package:anime_figure_shop_lite/models/shop_public.dart';
import 'package:anime_figure_shop_lite/models/stock_move.dart';
import 'package:anime_figure_shop_lite/providers/providers.dart';
import 'package:anime_figure_shop_lite/ui/pages/blacklist_page.dart';
import 'package:anime_figure_shop_lite/ui/pages/checkout_page.dart';
import 'package:anime_figure_shop_lite/ui/pages/customer_home_page.dart';
import 'package:anime_figure_shop_lite/ui/pages/item_detail_page.dart';
import 'package:anime_figure_shop_lite/ui/pages/orders_page.dart';
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

/// A cart that starts with [items].
class _FixedCart extends CartNotifier {
  _FixedCart(this.items);

  final List<CartItem> items;

  @override
  List<CartItem> build() => items;
}

/// One order for the shop 'me', seen by the shop and by the customer.
final pendingOrder = ShopOrder(
  id: 'order1',
  status: 'pending',
  total: 25000,
  items: const [
    OrderLine(
        productId: 'me_1', name: 'Nendoroid Miku', price: 25000, quantity: 1),
  ],
  phone: '09123456789',
  deliveryMethod: DeliveryMethod.delivery,
  address: 'Yangon',
  note: '',
  createdAt: now,
  shopId: 'me',
);

final overrides = sampleOverrides();

/// The sample data; [shopOrders] are what the shop 'me' sees.
List<Override> sampleOverrides({List<ShopOrder>? shopOrders}) => [
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
      shopOrdersProvider
          .overrideWith((ref) => Stream.value(shopOrders ?? [pendingOrder])),
      myOrdersProvider.overrideWith((ref) => Stream.value([pendingOrder])),
      shopPublicProvider.overrideWith((ref, id) => Stream.value(ShopPublic(
            shopId: id,
            phone: '09123456789',
            deliveryFee: 3000,
            paymentMethods: const [
              PaymentMethod(
                  type: PaymentType.kbzPay,
                  accountName: 'Sakura Figures',
                  number: '09123456789'),
              PaymentMethod(
                  type: PaymentType.bank,
                  accountName: 'Daw Sakura',
                  number: 'KBZ Bank 0123 4567 8901'),
            ],
          ))),
      allShopsProvider.overrideWith((ref) => Stream.value([
            shop('a', 'Sakura Figures', now.add(const Duration(days: 5))),
            shop('b', 'Mandalay Toys', now.add(const Duration(days: 120))),
            shop('c', 'New Shop', null),
            shop('d', 'Old Shop', now.subtract(const Duration(days: 3))),
          ])),
      blacklistProvider.overrideWith((ref) => Stream.value([
            BlacklistEntry(
                email: 'spam@example.com',
                remark: 'Ordered five times and never picked anything up.',
                createdAt: now),
          ])),
    ];

/// Reduce motion on, so looping effects (border beam, skeleton shimmer)
/// stand still and pumpAndSettle can settle.
void stillMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// Pumps [screen] with the sample data, or [withOverrides] instead.
Future<void> pumpScreen(WidgetTester tester, Widget screen,
    {List<Override>? withOverrides}) async {
  tester.view.physicalSize = const Size(360, 720) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  stillMotion(tester);
  await tester.pumpWidget(ProviderScope(
    overrides: withOverrides ?? overrides,
    child: MaterialApp(
      theme: buildAppTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: screen,
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('figure shop for guests, with a bottom bar', (tester) async {
    await pumpScreen(tester, const CustomerHomePage());
    expect(find.text('Nendoroid Miku'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget, reason: 'phone width');
    for (final tab in ['Cart', 'Orders']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
    }
    expect(find.text('Sign in to see your orders'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing, reason: 'only on Account');

    await tester.tap(find.text('Go to Account'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Open a shop'), findsNothing, reason: 'signed in only');
    expect(find.text('Sign out'), findsNothing);
  });

  testWidgets('catalog search, sort and the in-stock filter', (tester) async {
    await pumpScreen(tester, const CustomerHomePage());
    expect(find.text('Gojo Satoru 1/7 scale'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'miku');
    await tester.pumpAndSettle();
    expect(find.text('Gojo Satoru 1/7 scale'), findsNothing);
    expect(find.text('Nendoroid Miku'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('In stock only'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show 1 figure'));
    await tester.pumpAndSettle();
    expect(find.text('Gojo Satoru 1/7 scale'), findsNothing,
        reason: 'sold out');
    expect(find.text('1 of 2 figures · Recommended'), findsOneWidget);
    expect(find.text('In stock'), findsOneWidget, reason: 'removable pill');

    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Highest price'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show 1 figure'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 2 figures · Highest price'), findsOneWidget);
    expect(find.text('Nendoroid Miku'), findsOneWidget);
  });

  testWidgets('price filter: typed min and max', (tester) async {
    await pumpScreen(tester, const CustomerHomePage());
    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();

    TextField box(String label) => tester.widget<TextField>(
        find.ancestor(of: find.text(label), matching: find.byType(TextField)));
    Finder field(String label) =>
        find.ancestor(of: find.text(label), matching: find.byType(TextField));

    await tester.enterText(field('Min'), '300000');
    await tester.pump();
    expect(box('Min').controller!.text, '300,000', reason: 'grouped');
    expect(find.text('Show 1 figure'), findsOneWidget);

    await tester.enterText(field('Max'), '100');
    await tester.pump();
    expect(find.text('Min is more than max.'), findsOneWidget);
    expect(find.text('Check the price range'), findsOneWidget);

    await tester.enterText(field('Max'), '400000');
    await tester.pump();
    await tester.tap(find.text('Show 1 figure'));
    await tester.pumpAndSettle();
    expect(find.text('Nendoroid Miku'), findsNothing);
    expect(find.text('Gojo Satoru 1/7 scale'), findsOneWidget);
  });

  testWidgets('a shop sees orders for its figures and can confirm',
      (tester) async {
    await pumpScreen(tester, const ShopHomePage());
    await tester.tap(find.text('Orders').last);
    await tester.pumpAndSettle();
    expect(find.text('To do · 1'), findsOneWidget);
    expect(find.text('1 × Nendoroid Miku'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget, reason: 'call the customer');
    expect(find.text('Viber'), findsOneWidget);
  });

  testWidgets("checkout adds the shop's delivery fee, not for pickup",
      (tester) async {
    tester.view.physicalSize = const Size(360, 720) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    stillMotion(tester);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...overrides,
        cartProvider.overrideWith(() => _FixedCart(const [
              CartItem(
                product: Product(
                    id: 'me_1',
                    name: 'Nendoroid Miku',
                    description: '',
                    price: 25000,
                    stockQuantity: 3,
                    isActive: true,
                    shopId: 'me',
                    shopName: 'Sakura Figures'),
                quantity: 1,
              ),
            ])),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CheckoutPage(),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
        find.text('Total'), find.byType(ListView).first, const Offset(0, -200));
    expect(find.text('3,000 Ks'), findsOneWidget);
    expect(find.text('28,000 Ks'), findsOneWidget);

    await tester.dragUntilVisible(find.text('Pick up at shop'),
        find.byType(ListView).first, const Offset(0, 200));
    await tester.tap(find.text('Pick up at shop'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
        find.text('Total'), find.byType(ListView).first, const Offset(0, -200));
    expect(find.text('None, you pick up'), findsOneWidget);
    expect(find.text('25,000 Ks'), findsNWidgets(2), reason: 'figures, total');
  });

  testWidgets("a customer's order has the shop's Call and Viber",
      (tester) async {
    await pumpScreen(tester, const OrdersPage());
    await tester.tap(find.text('Nendoroid Miku'));
    await tester.pumpAndSettle();
    expect(find.text('Contact the shop'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);
    expect(find.text('Viber'), findsOneWidget);
    expect(find.text('Pay 25,000 Ks to the shop'), findsOneWidget);
    expect(find.text('KBZPay'), findsOneWidget);
    expect(find.text('KBZ Bank 0123 4567 8901'), findsOneWidget);
    expect(find.byTooltip('Copy'), findsNWidgets(2));
    await tester.dragUntilVisible(find.text('Send payment screenshot'),
        find.byType(SingleChildScrollView).last, const Offset(0, -200));
    expect(find.text('Send payment screenshot'), findsOneWidget);
  });

  testWidgets('the shop sees when a payment screenshot has come',
      (tester) async {
    final paid = ShopOrder(
      id: 'order2',
      status: 'pending',
      total: 25000,
      items: pendingOrder.items,
      phone: '09123456789',
      deliveryMethod: DeliveryMethod.pickup,
      address: '',
      note: '',
      createdAt: now,
      shopId: 'me',
      paymentProofId: 'proof1',
    );
    await pumpScreen(tester, const ShopHomePage(),
        withOverrides: sampleOverrides(shopOrders: [paid]));
    await tester.tap(find.text('Orders').last);
    await tester.pumpAndSettle();
    expect(find.text('Customer sent a payment screenshot'), findsOneWidget);
  });

  testWidgets('"View cart" after adding closes the product, opens Cart',
      (tester) async {
    await pumpScreen(tester, const CustomerHomePage());
    await tester.tap(find.text('Nendoroid Miku'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View cart'));
    await tester.pumpAndSettle();
    expect(find.text('Add to cart'), findsNothing, reason: 'product closed');
    expect(find.text('Checkout'), findsOneWidget);
    expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        CustomerTab.cart.index);
  });

  testWidgets('product photos: bundled asset or web', (tester) async {
    await tester.pumpWidget(const Column(children: [
      Expanded(child: ProductImage(url: 'assets/products/fig-ph-924.webp')),
      Expanded(child: ProductImage(url: 'https://example.com/a.webp')),
    ]));
    final images = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(images[0].image, isA<AssetImage>());
    expect(images[1].image, isA<NetworkImage>());
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

  testWidgets('shop settings: delivery fee and ways to pay', (tester) async {
    await pumpScreen(tester, const ShopHomePage());
    await tester.tap(find.text('Shop').last);
    await tester.pumpAndSettle();
    expect(find.text('Delivery and payment'), findsOneWidget);
    expect(find.textContaining('Delivery 3,000 Ks'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Shop settings'), findsOneWidget);
    expect(find.text('3000'), findsOneWidget, reason: 'saved fee');
    expect(find.text('Daw Sakura'), findsOneWidget, reason: 'saved method');

    await tester.dragUntilVisible(find.text('Add a way to pay'),
        find.byType(ListView).first, const Offset(0, -200));
    await tester.tap(find.text('Add a way to pay'));
    await tester.pumpAndSettle();
    expect(find.text('Account name'), findsNWidgets(3));
    await tester.tap(find.byTooltip('Remove').last);
    await tester.pumpAndSettle();
    expect(find.text('Account name'), findsNWidgets(2));
  });

  testWidgets('shop owners are told to contact us to delete their account',
      (tester) async {
    await pumpScreen(tester, const ShopHomePage());
    await tester.tap(find.text('Shop').last);
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(find.text('Delete my account'),
        find.byType(ListView).first, const Offset(0, -200));
    await tester.tap(find.text('Delete my account'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('Contact us to close your shop'), findsOneWidget);
    expect(find.byType(TextField), findsNothing, reason: 'nothing to confirm');
  });

  testWidgets('tablets get a side rail instead of the bottom bar',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 768) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    stillMotion(tester);
    await tester.pumpWidget(ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: buildAppTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ShopHomePage(),
      ),
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

  testWidgets('blacklist shows the remark and blocks with one', (tester) async {
    await pumpScreen(tester, const BlacklistPage());
    expect(find.textContaining('never picked anything up'), findsOneWidget);
    await tester.tap(find.text('Block someone'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'x@example.com');
    await tester.tap(find.text('Block'));
    await tester.pumpAndSettle();
    expect(find.text('Write a remark: why you are blocking them.'),
        findsOneWidget);
  });
}

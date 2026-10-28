import 'package:flutter_test/flutter_test.dart';

import 'package:anime_figure_shop_lite/logic/catalog.dart';
import 'package:anime_figure_shop_lite/models/product.dart';

Product p(String name, int price,
        {int stock = 3,
        String category = 'Scale figure',
        String anime = 'One Piece',
        String shopId = '',
        String shopName = '',
        DateTime? openUntil}) =>
    Product(
      id: name,
      name: name,
      description: '',
      price: price,
      stockQuantity: stock,
      isActive: true,
      category: category,
      anime: anime,
      shopId: shopId,
      shopName: shopName,
      shopOpenUntil: openUntil,
    );

void main() {
  final luffy = p('Luffy', 900000, category: 'Garage kit');
  final robin = p('Robin', 300000, stock: 0);
  final nagi = p('Nagi', 420000,
      anime: 'Blue Lock', shopId: 'sakura', shopName: 'Sakura Figures');
  final all = [luffy, robin, nagi];

  List<String> names(CatalogFilter f) =>
      f.apply(all).map((p) => p.name).toList();

  test('recommended puts what can be bought first, then by name', () {
    expect(names(const CatalogFilter()), ['Luffy', 'Nagi', 'Robin']);
  });

  test('sorts by price both ways', () {
    expect(names(const CatalogFilter(sort: CatalogSort.priceLow)),
        ['Robin', 'Nagi', 'Luffy']);
    expect(names(const CatalogFilter(sort: CatalogSort.priceHigh)),
        ['Luffy', 'Nagi', 'Robin']);
  });

  test('filters by category, anime (any case), shop and stock', () {
    expect(names(const CatalogFilter(category: 'Garage kit')), ['Luffy']);
    expect(names(const CatalogFilter(anime: 'blue lock')), ['Nagi']);
    expect(names(const CatalogFilter(shopId: 'sakura')), ['Nagi']);
    expect(names(const CatalogFilter(shopId: '')), ['Luffy', 'Robin'],
        reason: "'' is the house's own figures");
    expect(names(const CatalogFilter(inStockOnly: true)), ['Luffy', 'Nagi']);
  });

  test('price range includes both ends', () {
    expect(names(const CatalogFilter(minPrice: 300000, maxPrice: 420000)),
        ['Nagi', 'Robin']);
    expect(names(const CatalogFilter(maxPrice: 299999)), isEmpty);
  });

  test('search looks at name, anime, category and shop', () {
    expect(names(const CatalogFilter(query: 'sakura')), ['Nagi']);
    expect(names(const CatalogFilter(query: 'GARAGE')), ['Luffy']);
    expect(names(const CatalogFilter(query: 'one piece')), ['Luffy', 'Robin']);
  });

  test('clearing keeps the search and sort', () {
    const f = CatalogFilter(
        query: 'x', sort: CatalogSort.name, anime: 'A', inStockOnly: true);
    expect(f.activeCount, 2);
    final c = f.cleared();
    expect((c.query, c.sort, c.activeCount), ('x', CatalogSort.name, 0));
  });

  test('facet counts values, most common first, ignoring case', () {
    final list = [...all, p('Zoro', 1, anime: 'one piece')];
    expect(facet(list, (p) => p.anime), [('One Piece', 3), ('Blue Lock', 1)]);
  });

  test("a shop's figures show only while the shop is open", () {
    final now = DateTime(2026, 10, 26);
    expect(p('a', 1).isVisibleAt(now), isTrue, reason: 'house');
    expect(
        p('b', 1, shopId: 's', openUntil: DateTime(2026, 11, 1))
            .isVisibleAt(now),
        isTrue);
    expect(
        p('c', 1, shopId: 's', openUntil: DateTime(2026, 10, 1))
            .isVisibleAt(now),
        isFalse);
    expect(p('d', 1, shopId: 's').isVisibleAt(now), isFalse,
        reason: 'pending shop');
  });
}

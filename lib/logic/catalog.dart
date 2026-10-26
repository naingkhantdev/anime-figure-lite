import '../models/product.dart';

/// The kinds of figure a product can be. Stored as written; a shop picks one
/// when it lists an item, and the catalog filters by it.
const productCategories = [
  'Scale figure',
  'Nendoroid',
  'Garage kit',
  'Prize figure',
  'Action figure',
  'Acrylic stand',
  'Other',
];

enum CatalogSort {
  featured('Recommended'),
  priceLow('Lowest price'),
  priceHigh('Highest price'),
  name('Name A to Z');

  const CatalogSort(this.label);
  final String label;
}

/// What the customer has asked the catalog to show. Empty strings and null
/// prices mean "any".
class CatalogFilter {
  const CatalogFilter({
    this.query = '',
    this.sort = CatalogSort.featured,
    this.category = '',
    this.anime = '',
    this.shopId,
    this.minPrice,
    this.maxPrice,
    this.inStockOnly = false,
  });

  final String query;
  final CatalogSort sort;
  final String category;
  final String anime;

  /// Null for any shop; '' for the house's own figures.
  final String? shopId;
  final int? minPrice;
  final int? maxPrice;
  final bool inStockOnly;

  bool get hasPrice => minPrice != null || maxPrice != null;

  /// How many filters are on, search and sort aside.
  int get activeCount => [
        category.isNotEmpty,
        anime.isNotEmpty,
        shopId != null,
        hasPrice,
        inStockOnly,
      ].where((on) => on).length;

  CatalogFilter copyWith({
    String? query,
    CatalogSort? sort,
    String? category,
    String? anime,
    String? Function()? shopId,
    int? Function()? minPrice,
    int? Function()? maxPrice,
    bool? inStockOnly,
  }) =>
      CatalogFilter(
        query: query ?? this.query,
        sort: sort ?? this.sort,
        category: category ?? this.category,
        anime: anime ?? this.anime,
        shopId: shopId == null ? this.shopId : shopId(),
        minPrice: minPrice == null ? this.minPrice : minPrice(),
        maxPrice: maxPrice == null ? this.maxPrice : maxPrice(),
        inStockOnly: inStockOnly ?? this.inStockOnly,
      );

  /// Every filter off; the search and sort stay.
  CatalogFilter cleared() => CatalogFilter(query: query, sort: sort);

  bool matches(Product p) {
    if (category.isNotEmpty && p.category != category) return false;
    if (anime.isNotEmpty && p.anime.toLowerCase() != anime.toLowerCase()) {
      return false;
    }
    if (shopId != null && p.shopId != shopId) return false;
    if (minPrice != null && p.price < minPrice!) return false;
    if (maxPrice != null && p.price > maxPrice!) return false;
    if (inStockOnly && !p.inStock) return false;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [p.name, p.anime, p.category, p.shopName]
        .any((field) => field.toLowerCase().contains(q));
  }

  /// The products this filter lets through, in its order.
  List<Product> apply(Iterable<Product> products) {
    final list = products.where(matches).toList();
    int byName(Product a, Product b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase());
    list.sort(switch (sort) {
      // What can be bought first, then by name.
      CatalogSort.featured => (a, b) =>
          a.inStock == b.inStock ? byName(a, b) : (a.inStock ? -1 : 1),
      CatalogSort.priceLow => (a, b) =>
          a.price == b.price ? byName(a, b) : a.price.compareTo(b.price),
      CatalogSort.priceHigh => (a, b) =>
          a.price == b.price ? byName(a, b) : b.price.compareTo(a.price),
      CatalogSort.name => byName,
    });
    return list;
  }
}

/// The values one field takes across [products], most common first, with
/// how many products have each. For the filter sheets.
List<(String, int)> facet(
    Iterable<Product> products, String Function(Product) field) {
  final counts = <String, int>{};
  final shown = <String, String>{};
  for (final p in products) {
    final value = field(p).trim();
    if (value.isEmpty) continue;
    // "One Piece" and "one piece" count as one, shown as first seen.
    final key = value.toLowerCase();
    shown.putIfAbsent(key, () => value);
    counts[key] = (counts[key] ?? 0) + 1;
  }
  final keys = counts.keys.toList()
    ..sort((a, b) => counts[a] == counts[b]
        ? a.compareTo(b)
        : counts[b]!.compareTo(counts[a]!));
  return [for (final k in keys) (shown[k]!, counts[k]!)];
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config.dart';
import '../../logic/catalog.dart';
import '../../models/product.dart';
import '../../providers/providers.dart';
import '../../utils/money.dart';
import '../theme.dart';

/// Who sells a product, as customers see it.
String sellerName(Product p) => p.shopId.isEmpty ? appName : p.shopName;

/// The small line above a product's name on its card: the series, and the
/// shop when it isn't the house's own.
String cardKicker(Product p) => [if (p.shopId.isNotEmpty) p.shopName, p.anime]
    .where((s) => s.isNotEmpty)
    .join(' · ');

String priceRangeLabel(int? min, int? max) {
  if (min != null && max != null) {
    return '${formatMmk(min)} – ${formatMmk(max)}';
  }
  if (min != null) return 'From ${formatMmk(min)}';
  if (max != null) return 'Up to ${formatMmk(max)}';
  return 'Any price';
}

/// An icon for each category, so the row reads at a glance.
IconData categoryIcon(String category) => switch (category) {
      'Scale figure' => Icons.straighten,
      'Nendoroid' => Icons.face_retouching_natural,
      'Garage kit' => Icons.construction,
      'Prize figure' => Icons.emoji_events_outlined,
      'Action figure' => Icons.sports_martial_arts,
      'Acrylic stand' => Icons.crop_portrait,
      _ => Icons.category_outlined,
    };

const _sortIcons = {
  CatalogSort.featured: (
    Icons.auto_awesome_outlined,
    'In stock first, then A to Z'
  ),
  CatalogSort.priceLow: (Icons.south, 'Cheapest first'),
  CatalogSort.priceHigh: (Icons.north, 'Most expensive first'),
  CatalogSort.name: (Icons.sort_by_alpha, 'Alphabetical'),
};

// ---------------------------------------------------------------- search

/// The search box, with one filter button beside it. Sorting lives in the
/// filter sheet, so there is a single place to change what is shown.
class CatalogSearchRow extends ConsumerStatefulWidget {
  const CatalogSearchRow({super.key, required this.products});

  /// Everything on sale, for the filter choices.
  final List<Product> products;

  @override
  ConsumerState<CatalogSearchRow> createState() => _CatalogSearchRowState();
}

class _CatalogSearchRowState extends ConsumerState<CatalogSearchRow> {
  late final _query =
      TextEditingController(text: ref.read(catalogFilterProvider).query);

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _set(String q) => ref
      .read(catalogFilterProvider.notifier)
      .update((f) => f.copyWith(query: q));

  @override
  Widget build(BuildContext context) {
    final f = ref.watch(catalogFilterProvider);
    // Sorting counts as a change too: the button says "not the default".
    final changes = f.activeCount + (f.sort == CatalogSort.featured ? 0 : 1);
    return Row(
      children: [
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: _query,
            builder: (context, value, _) => TextField(
              controller: _query,
              onChanged: _set,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search figures or anime',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: value.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.cancel, size: 20),
                        color: AppColors.inkSubtle,
                        onPressed: () {
                          _query.clear();
                          _set('');
                        },
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _FilterIconButton(
          count: changes,
          onPressed: () => showCatalogFilters(context, widget.products),
        ),
      ],
    );
  }
}

/// A pink square with the filter icon, the height of the search box; a
/// white badge counts what is changed.
class _FilterIconButton extends StatelessWidget {
  const _FilterIconButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(AppRadius.md + 2);
    return Tooltip(
      message: 'Filters',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: shape,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.glow, AppColors.accent],
              ),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x40E0115F),
                    offset: Offset(0, 6),
                    blurRadius: 14,
                    spreadRadius: -4),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: shape,
                onTap: onPressed,
                child: const SizedBox.square(
                  dimension: 50,
                  child: Icon(Icons.tune, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
          if (count > 0)
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20),
                height: 20,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.accent, width: 1.5),
                ),
                child: Text('$count',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent)),
              ),
            ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- chips

/// A pale chip that turns pink when picked, for every choice in the
/// catalog: quick categories, filter pills and the sheet's options.
class CatalogChip extends StatelessWidget {
  const CatalogChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.count,
    this.onRemove,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final int? count;

  /// Shows a cross that clears this one filter.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.accent : AppColors.ink;
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: AppMotion.quick,
        decoration: ShapeDecoration(
          color: selected ? AppColors.accentSoft : AppColors.glassStrong,
          shape: StadiumBorder(
            side: BorderSide(
                color: selected
                    ? AppColors.accent.withOpacity(0.4)
                    : AppColors.glassEdge),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  icon == null ? 14 : 10, 8, onRemove == null ? 14 : 8, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon,
                        size: 16,
                        color:
                            selected ? AppColors.accent : AppColors.inkMuted),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: fg,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500)),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: 6),
                    Text('$count',
                        style: TextStyle(
                            fontSize: 12,
                            color: selected
                                ? AppColors.accent
                                : AppColors.inkSubtle)),
                  ],
                  if (onRemove != null) ...[
                    const SizedBox(width: 4),
                    InkResponse(
                      onTap: onRemove,
                      radius: 14,
                      child: Icon(Icons.close, size: 16, color: fg),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One tap to a category, under the deck.
class CatalogCategoryBar extends ConsumerWidget {
  const CatalogCategoryBar({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(catalogFilterProvider.select((f) => f.category));
    final set = ref.read(catalogFilterProvider.notifier).update;
    final chips = [
      CatalogChip(
        label: 'All',
        icon: Icons.apps,
        selected: category.isEmpty,
        onTap: () => set((f) => f.copyWith(category: '')),
      ),
      for (final (c, _) in facet(products, (p) => p.category))
        CatalogChip(
          label: c,
          icon: categoryIcon(c),
          selected: category == c,
          onTap: () =>
              set((f) => f.copyWith(category: f.category == c ? '' : c)),
        ),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Center(child: chips[i]),
      ),
    );
  }
}

/// A pill for each filter set in the sheet (not category, which has its
/// own row), each with a cross. Nothing when none is on.
class CatalogActiveFilters extends ConsumerWidget {
  const CatalogActiveFilters({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(catalogFilterProvider);
    final set = ref.read(catalogFilterProvider.notifier).update;
    final shopName = f.shopId == null
        ? null
        : products
            .where((p) => p.shopId == f.shopId)
            .map(sellerName)
            .firstOrNull;
    void open() => showCatalogFilters(context, products);

    final pills = [
      if (f.anime.isNotEmpty)
        CatalogChip(
          label: f.anime,
          icon: Icons.movie_outlined,
          selected: true,
          onTap: open,
          onRemove: () => set((f) => f.copyWith(anime: '')),
        ),
      if (shopName != null)
        CatalogChip(
          label: shopName,
          icon: Icons.storefront_outlined,
          selected: true,
          onTap: open,
          onRemove: () => set((f) => f.copyWith(shopId: () => null)),
        ),
      if (f.hasPrice)
        CatalogChip(
          label: priceRangeLabel(f.minPrice, f.maxPrice),
          icon: Icons.payments_outlined,
          selected: true,
          onTap: open,
          onRemove: () => set(
              (f) => f.copyWith(minPrice: () => null, maxPrice: () => null)),
        ),
      if (f.inStockOnly)
        CatalogChip(
          label: 'In stock',
          icon: Icons.inventory_2_outlined,
          selected: true,
          onTap: open,
          onRemove: () => set((f) => f.copyWith(inStockOnly: false)),
        ),
    ];
    if (pills.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Wrap(spacing: 8, runSpacing: 8, children: pills),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.text, {this.subtitle});

  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            if (subtitle != null)
              Text(subtitle!,
                  style: const TextStyle(color: AppColors.inkMuted)),
          ],
        ),
      );
}

// --------------------------------------------------------------- filters

/// All filters on one sheet. Nothing changes behind it until "Show"; the
/// button counts what the choices would find as they are made.
Future<void> showCatalogFilters(BuildContext context, List<Product> products) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FiltersSheet(products: products),
    );

class _FiltersSheet extends ConsumerStatefulWidget {
  const _FiltersSheet({required this.products});

  final List<Product> products;

  @override
  ConsumerState<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends ConsumerState<_FiltersSheet> {
  static const _step = 10000;

  late CatalogFilter _draft = ref.read(catalogFilterProvider);

  late final int _floor;
  late final int _ceil;
  late final _min = TextEditingController(text: _digits(_draft.minPrice));
  late final _max = TextEditingController(text: _digits(_draft.maxPrice));

  static String _digits(int? v) => v == null ? '' : groupThousands(v);

  @override
  void initState() {
    super.initState();
    final prices = widget.products.map((p) => p.price);
    _floor = prices.isEmpty
        ? 0
        : (prices.reduce((a, b) => a < b ? a : b) ~/ _step) * _step;
    final top = prices.isEmpty ? _step : prices.reduce((a, b) => a > b ? a : b);
    _ceil = ((top + _step - 1) ~/ _step) * _step;
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _edit(CatalogFilter Function(CatalogFilter) change) =>
      setState(() => _draft = change(_draft));

  /// Sets the price from the slider or a ready range, and shows it in the
  /// boxes too.
  void _setPrice(int? min, int? max) {
    _min.text = _digits(min);
    _max.text = _digits(max);
    _edit((f) => f.copyWith(minPrice: () => min, maxPrice: () => max));
  }

  /// From the boxes: empty means no limit on that side.
  void _typedPrice() {
    int? read(TextEditingController c) {
      final digits = c.text.replaceAll(RegExp(r'[^0-9]'), '');
      return digits.isEmpty ? null : int.tryParse(digits);
    }

    _edit((f) =>
        f.copyWith(minPrice: () => read(_min), maxPrice: () => read(_max)));
  }

  RangeValues get _range {
    final lo = (_draft.minPrice ?? _floor).clamp(_floor, _ceil).toDouble();
    final hi = (_draft.maxPrice ?? _ceil).clamp(_floor, _ceil).toDouble();
    return RangeValues(lo, hi < lo ? lo : hi);
  }

  bool get _priceBackwards =>
      _draft.minPrice != null &&
      _draft.maxPrice != null &&
      _draft.minPrice! > _draft.maxPrice!;

  @override
  Widget build(BuildContext context) {
    final products = widget.products;
    final count = _priceBackwards ? 0 : _draft.apply(products).length;
    final shops = <String, String>{
      for (final p in products) p.shopId: sellerName(p)
    };
    final shopCounts = <String, int>{};
    for (final p in products) {
      shopCounts[p.shopId] = (shopCounts[p.shopId] ?? 0) + 1;
    }

    Widget section(IconData icon, String title, Widget child,
            {Widget? trailing}) =>
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        );

    Widget choices(List<(String, String, int)> options, String current,
            void Function(String) pick,
            {IconData Function(String)? icon}) =>
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (value, label, n) in options)
              CatalogChip(
                label: label,
                icon: icon?.call(value),
                count: n,
                selected: value == current,
                onTap: () => pick(value == current ? '' : value),
              ),
          ],
        );

    Widget priceBox(String label, TextEditingController c, int hint) =>
        Expanded(
          child: TextField(
            controller: c,
            keyboardType: TextInputType.number,
            inputFormatters: [_ThousandsFormatter()],
            onChanged: (_) => _typedPrice(),
            style: const TextStyle(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: label,
              hintText: groupThousands(hint),
              suffixText: 'Ks',
              isDense: true,
            ),
          ),
        );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _SheetTitle('Sort & filter',
                      subtitle: '$count of ${products.length} figures'),
                ),
                TextButton.icon(
                  onPressed: _draft.activeCount == 0 &&
                          _draft.sort == CatalogSort.featured
                      ? null
                      : () {
                          _min.clear();
                          _max.clear();
                          _edit((f) => CatalogFilter(query: f.query));
                        },
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: const Text('Reset'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.swap_vert,
                              size: 18, color: AppColors.accent),
                          SizedBox(width: 8),
                          Text('Sort by',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in CatalogSort.values)
                            CatalogChip(
                              label: s.label,
                              icon: _sortIcons[s]!.$1,
                              selected: _draft.sort == s,
                              onTap: () => _edit((f) => f.copyWith(sort: s)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Material(
                    color: _draft.inStockOnly
                        ? AppColors.accentSoft
                        : AppColors.surfaceSunken,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: SwitchListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg)),
                      secondary: const Icon(Icons.inventory_2_outlined,
                          color: AppColors.accent),
                      title: const Text('In stock only',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('Hide figures that are sold out'),
                      value: _draft.inStockOnly,
                      onChanged: (on) =>
                          _edit((f) => f.copyWith(inStockOnly: on)),
                    ),
                  ),
                ),
                section(
                  Icons.payments_outlined,
                  'Price',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          priceBox('Min', _min, _floor),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text('–',
                                style: TextStyle(
                                    fontSize: 18, color: AppColors.inkMuted)),
                          ),
                          priceBox('Max', _max, _ceil),
                        ],
                      ),
                      if (_priceBackwards)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text('Min is more than max.',
                              style: TextStyle(
                                  color: AppColors.dangerInk, fontSize: 13)),
                        ),
                      const SizedBox(height: 8),
                      RangeSlider(
                        values: _range,
                        min: _floor.toDouble(),
                        max: _ceil.toDouble(),
                        divisions: ((_ceil - _floor) ~/ _step).clamp(1, 200),
                        // Null at the ends means "any", so new figures
                        // past them still show.
                        onChanged: (r) => _setPrice(
                          r.start <= _floor ? null : r.start.round(),
                          r.end >= _ceil ? null : r.end.round(),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final (label, lo, hi) in const [
                            ('Under 200K', null, 200000),
                            ('200K – 500K', 200000, 500000),
                            ('500K – 1M', 500000, 1000000),
                            ('Over 1M', 1000000, null),
                          ])
                            CatalogChip(
                              label: label,
                              selected: _draft.minPrice == lo &&
                                  _draft.maxPrice == hi,
                              onTap: () => _setPrice(lo, hi),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                section(
                  Icons.category_outlined,
                  'Category',
                  choices(
                    [
                      for (final (c, n) in facet(products, (p) => p.category))
                        (c, c, n)
                    ],
                    _draft.category,
                    (c) => _edit((f) => f.copyWith(category: c)),
                    icon: categoryIcon,
                  ),
                ),
                section(
                  Icons.movie_outlined,
                  'Anime',
                  choices(
                    [
                      for (final (a, n) in facet(products, (p) => p.anime))
                        (a, a, n)
                    ],
                    _draft.anime,
                    (a) => _edit((f) => f.copyWith(anime: a)),
                  ),
                ),
                section(
                  Icons.storefront_outlined,
                  'Shop',
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final id
                          in shops.keys.toList()
                            ..sort((a, b) => shops[a]!.compareTo(shops[b]!)))
                        CatalogChip(
                          label: shops[id]!,
                          count: shopCounts[id],
                          selected: _draft.shopId == id,
                          // '' is a real choice here: the house's figures.
                          onTap: () => _edit((f) => f.copyWith(
                              shopId: () => f.shopId == id ? null : id)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: count == 0
                        ? null
                        : () {
                            ref.read(catalogFilterProvider.notifier).state =
                                _draft;
                            Navigator.pop(context);
                          },
                    child: Text(_priceBackwards
                        ? 'Check the price range'
                        : count == 0
                            ? 'No figures match'
                            : 'Show $count ${count == 1 ? 'figure' : 'figures'}'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Keeps only digits and groups them by thousands as they are typed:
/// 1500000 shows as 1,500,000.
class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final value =
        int.tryParse(digits.length > 10 ? digits.substring(0, 10) : digits);
    if (value == null) return oldValue;
    final text = groupThousands(value);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

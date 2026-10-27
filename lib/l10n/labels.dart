import '../logic/catalog.dart';
import '../logic/stock.dart';
import '../models/shop_order.dart';
import 'app_localizations.dart';

// Display names for values the data and logic code keep as plain enums or
// stored English strings.

extension MoveTypeLabel on MoveType {
  String label(AppLocalizations l) => switch (this) {
        MoveType.stockIn => l.moveIn,
        MoveType.stockOut => l.moveOut,
        MoveType.adjust => l.moveCount,
      };
}

extension CatalogSortLabel on CatalogSort {
  String label(AppLocalizations l) => switch (this) {
        CatalogSort.featured => l.sortFeatured,
        CatalogSort.priceLow => l.sortPriceLow,
        CatalogSort.priceHigh => l.sortPriceHigh,
        CatalogSort.name => l.sortName,
      };
}

extension DeliveryMethodLabel on DeliveryMethod {
  String label(AppLocalizations l) => switch (this) {
        DeliveryMethod.delivery => l.deliveryMethodDelivery,
        DeliveryMethod.pickup => l.deliveryMethodPickup,
      };
}

/// A stored category (one of [productCategories]) in the app's language.
/// Anything else, such as an old value, is shown as stored.
String categoryLabel(AppLocalizations l, String category) =>
    switch (category) {
      'Scale figure' => l.categoryScaleFigure,
      'Nendoroid' => l.categoryNendoroid,
      'Garage kit' => l.categoryGarageKit,
      'Prize figure' => l.categoryPrizeFigure,
      'Action figure' => l.categoryActionFigure,
      'Acrylic stand' => l.categoryAcrylicStand,
      'Other' => l.categoryOther,
      _ => category,
    };

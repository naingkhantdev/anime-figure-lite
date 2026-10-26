import 'package:cloud_firestore/cloud_firestore.dart';

import '../logic/catalog.dart';
import '../logic/stock.dart';
import '../models/customer.dart';
import '../models/item.dart';
import '../models/shop.dart';
import '../models/stock_move.dart';
import '../utils/phone.dart';
import 'photo_repository.dart';

// These must match firestore.rules.
const maxNameLength = 100;
const maxCodeLength = 40;
const maxUnitLength = 20;
const maxTextLength = 500;
const maxPrice = 1000000000;
const maxAnimeLength = 60;

/// How many recent movements the History tab loads.
const recentMovesLimit = 300;

class InventoryException implements Exception {
  InventoryException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The fields of an item a person types in. Quantity is not here: it only
/// changes through [InventoryRepository.recordMove].
class ItemDraft {
  const ItemDraft({
    required this.name,
    this.code = '',
    this.unit = '',
    this.price = 0,
    this.cost = 0,
    this.lowStockAt = 0,
    this.listed = false,
    this.category = '',
    this.anime = '',
    this.description = '',
    this.imageUrl = '',
  });

  final String name;
  final String code;
  final String unit;
  final int price;
  final int cost;
  final int lowStockAt;

  /// Sell it in the app: customers see it in the catalog.
  final bool listed;
  final String category;
  final String anime;
  final String description;

  /// A web address (https://…) or a photo bundled with the app (assets/…).
  final String imageUrl;

  Map<String, Object> toFields() {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw InventoryException('Enter the item name.');
    if (cleanName.length > maxNameLength) {
      throw InventoryException('Keep the name under $maxNameLength letters.');
    }
    if (code.trim().length > maxCodeLength) {
      throw InventoryException('Keep the code under $maxCodeLength letters.');
    }
    if (unit.trim().length > maxUnitLength) {
      throw InventoryException('Keep the unit under $maxUnitLength letters.');
    }
    if (price > maxPrice || cost > maxPrice) {
      throw InventoryException('That price is too large.');
    }
    if (lowStockAt > maxQuantity) {
      throw InventoryException('The low stock level is too large.');
    }
    final cleanAnime = anime.trim();
    final cleanDescription = description.trim();
    final cleanImage = imageUrl.trim();
    if (category.isNotEmpty && !productCategories.contains(category)) {
      throw InventoryException('Pick a category from the list.');
    }
    if (cleanAnime.length > maxAnimeLength) {
      throw InventoryException(
          'Keep the anime name under $maxAnimeLength letters.');
    }
    if (cleanDescription.length > maxTextLength ||
        cleanImage.length > maxTextLength) {
      throw InventoryException('Keep it under $maxTextLength letters.');
    }
    if (cleanImage.isNotEmpty &&
        !cleanImage.startsWith('https://') &&
        !cleanImage.startsWith('assets/') &&
        !cleanImage.startsWith(photoUrlPrefix)) {
      throw InventoryException('That photo address is not one the app knows.');
    }
    if (listed && price <= 0) {
      throw InventoryException(
          'Set a selling price to sell this item in the app.');
    }
    return {
      'name': cleanName,
      'code': code.trim(),
      'unit': unit.trim(),
      'price': price,
      'cost': cost,
      'low_stock_at': lowStockAt,
      'listed': listed,
      'category': category,
      'anime': cleanAnime,
      'description': cleanDescription,
      'image_url': cleanImage,
    };
  }
}

/// Everything inside one shop: items, stock movements and customers.
/// firestore.rules only let the owner write, and only while the shop is
/// active.
class InventoryRepository {
  InventoryRepository(this._db, {required this.shopId, required this.shop});

  final FirebaseFirestore _db;

  /// Also the owner's uid.
  final String shopId;

  /// The shop as last loaded; its name and expiry go on listed items.
  final Shop? Function() shop;

  DocumentReference<Map<String, dynamic>> get _shop =>
      _db.collection('shops').doc(shopId);
  CollectionReference<Map<String, dynamic>> get _items =>
      _shop.collection('items');
  CollectionReference<Map<String, dynamic>> get _moves =>
      _shop.collection('moves');
  CollectionReference<Map<String, dynamic>> get _customers =>
      _shop.collection('customers');

  /// An item's copy in the customer catalog.
  DocumentReference<Map<String, dynamic>> listingRef(String itemId) =>
      _db.collection('products').doc('${shopId}_$itemId');

  /// The catalog copy of an item with these [fields] (as stored on the
  /// item). firestore.rules checks every value against the item and shop.
  Map<String, Object?> _listing(String itemId, Map<String, Object?> fields) {
    final shop = this.shop();
    if (shop == null) throw InventoryException('Your shop is still loading.');
    return {
      'name': fields['name'],
      'description': fields['description'] ?? '',
      'price': fields['price'],
      'stock_quantity': fields['quantity'],
      'image_url': fields['image_url'] ?? '',
      'category': fields['category'] ?? '',
      'anime': fields['anime'] ?? '',
      'is_active': fields['listed'] == true && fields['is_active'] == true,
      'shop_id': shopId,
      'shop_name': shop.name,
      'shop_open_until':
          shop.expiresAt == null ? null : Timestamp.fromDate(shop.expiresAt!),
      'item_id': itemId,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  // ---------------------------------------------------------------- items

  /// Sorted client-side so no composite index is needed.
  Stream<List<Item>> watchItems() =>
      _items.snapshots().map((snap) => snap.docs.map(Item.fromDoc).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())));

  Stream<Item?> watchItem(String itemId) => _items
      .doc(itemId)
      .snapshots()
      .map((snap) => snap.exists ? Item.fromDoc(snap) : null);

  /// Creates an item. A starting quantity is recorded as a "Stock in"
  /// movement in the same write, so the history explains it.
  Future<String> createItem(ItemDraft draft, {int initialQuantity = 0}) async {
    final fields = draft.toFields();
    if (initialQuantity > 0) {
      quantityAfter(0, MoveType.stockIn, initialQuantity); // validates
    }
    final itemRef = _items.doc();
    final moveRef = _moves.doc();
    final batch = _db.batch();
    batch.set(itemRef, {
      ...fields,
      'quantity': initialQuantity,
      'is_active': true,
      'last_move_id': initialQuantity > 0 ? moveRef.id : '',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    if (draft.listed) {
      batch.set(
          listingRef(itemRef.id),
          _listing(itemRef.id,
              {...fields, 'quantity': initialQuantity, 'is_active': true}));
    }
    if (initialQuantity > 0) {
      batch.set(
          moveRef,
          _moveFields(
            type: MoveType.stockIn,
            itemId: itemRef.id,
            itemName: fields['name'] as String,
            quantity: initialQuantity,
            before: 0,
            after: initialQuantity,
            unitPrice: draft.cost,
            note: 'Opening stock',
          ));
    }
    await batch.commit();
    return itemRef.id;
  }

  Future<void> updateItem(String itemId, ItemDraft draft) =>
      _changeItem(itemId, draft.toFields());

  /// Hidden items stay in history but drop out of the stock list, and out
  /// of the catalog.
  Future<void> setItemActive(String itemId, bool isActive) =>
      _changeItem(itemId, {'is_active': isActive});

  /// Updates an item and, when it is or was for sale in the app, its
  /// catalog copy in the same transaction, from the stored item.
  Future<void> _changeItem(String itemId, Map<String, Object?> changes) async {
    final itemRef = _items.doc(itemId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(itemRef);
      final stored = snap.data();
      if (stored == null) {
        throw InventoryException('This item no longer exists.');
      }
      final after = {...stored, ...changes};
      tx.update(itemRef, {
        ...changes,
        'updated_at': FieldValue.serverTimestamp(),
      });
      if (stored['listed'] == true || after['listed'] == true) {
        tx.set(listingRef(itemId), _listing(itemId, after));
      }
    });
  }

  // ------------------------------------------------------------ movements

  /// Records stock in / out / count and updates the item's quantity together.
  /// Runs as a transaction on the current stored quantity, so it needs a
  /// connection; two phones changing the same item can't lose an update.
  Future<void> recordMove({
    required String itemId,
    required MoveType type,
    required int quantity,
    required int unitPrice,
    Customer? customer,
    String note = '',
  }) async {
    if (unitPrice < 0 || unitPrice > maxPrice) {
      throw InventoryException('That price is too large.');
    }
    if (note.trim().length > maxTextLength) {
      throw InventoryException('Keep the note under $maxTextLength letters.');
    }
    final itemRef = _items.doc(itemId);
    final moveRef = _moves.doc();
    await _db.runTransaction((tx) async {
      final snap = await tx.get(itemRef);
      if (!snap.exists) throw InventoryException('This item no longer exists.');
      final item = Item.fromDoc(snap);
      final after = quantityAfter(item.quantity, type, quantity);
      tx.set(
          moveRef,
          _moveFields(
            type: type,
            itemId: itemId,
            itemName: item.name,
            quantity: quantity,
            before: item.quantity,
            after: after,
            unitPrice: type == MoveType.adjust ? 0 : unitPrice,
            customer: type == MoveType.stockOut ? customer : null,
            note: note.trim(),
          ));
      tx.update(itemRef, {
        'quantity': after,
        'last_move_id': moveRef.id,
        'updated_at': FieldValue.serverTimestamp(),
      });
      if (item.listed) {
        tx.set(listingRef(itemId),
            _listing(itemId, {...snap.data()!, 'quantity': after}));
      }
    });
  }

  Map<String, Object> _moveFields({
    required MoveType type,
    required String itemId,
    required String itemName,
    required int quantity,
    required int before,
    required int after,
    required int unitPrice,
    Customer? customer,
    String note = '',
  }) =>
      {
        'type': type.code,
        'item_id': itemId,
        'item_name': itemName,
        'quantity': quantity,
        'quantity_before': before,
        'quantity_after': after,
        'unit_price': unitPrice,
        'customer_id': customer?.id ?? '',
        'customer_name': customer?.name ?? '',
        'note': note,
        'created_by': shopId,
        'created_at': FieldValue.serverTimestamp(),
      };

  /// The latest [recentMovesLimit] movements, newest first. Ordering on one
  /// field needs no composite index.
  Stream<List<StockMove>> watchRecentMoves() => _moves
      .orderBy('created_at', descending: true)
      .limit(recentMovesLimit)
      .snapshots()
      .map((snap) => snap.docs.map(StockMove.fromDoc).toList());

  /// Every movement of one item, newest first. Sorted client-side so no
  /// composite index is needed.
  Stream<List<StockMove>> watchItemMoves(String itemId) => _moves
      .where('item_id', isEqualTo: itemId)
      .snapshots()
      .map((snap) => snap.docs.map(StockMove.fromDoc).toList()
        ..sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now())));

  // ------------------------------------------------------------ customers

  Stream<List<Customer>> watchCustomers() => _customers.snapshots().map(
      (snap) => snap.docs.map(Customer.fromDoc).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())));

  /// Creates the customer when [customerId] is null, otherwise updates it.
  Future<void> saveCustomer({
    String? customerId,
    required String name,
    required String phone,
    required String address,
    required String note,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw InventoryException('Enter the name.');
    if (cleanName.length > maxNameLength) {
      throw InventoryException('Keep the name under $maxNameLength letters.');
    }
    var cleanPhone = '';
    if (phone.trim().isNotEmpty) {
      cleanPhone = normalizePhone(phone) ??
          (throw InventoryException('Enter a phone number like 09xxxxxxxxx.'));
    }
    if (address.trim().length > maxTextLength ||
        note.trim().length > maxTextLength) {
      throw InventoryException('Keep it under $maxTextLength letters.');
    }
    final fields = {
      'name': cleanName,
      'phone': cleanPhone,
      'address': address.trim(),
      'note': note.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (customerId == null) {
      await _customers
          .doc()
          .set({...fields, 'created_at': FieldValue.serverTimestamp()});
    } else {
      await _customers.doc(customerId).update(fields);
    }
  }

  Future<void> deleteCustomer(String customerId) =>
      _customers.doc(customerId).delete();
}

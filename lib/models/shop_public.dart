import 'package:cloud_firestore/cloud_firestore.dart';

/// Ways a Myanmar customer pays a shop. [code] is what is stored.
enum PaymentType {
  kbzPay('kbzpay', 'KBZPay'),
  wavePay('wavepay', 'WavePay'),
  ayaPay('ayapay', 'AYA Pay'),
  cbPay('cbpay', 'CB Pay'),
  bank('bank', '');

  const PaymentType(this.code, this.brand);

  final String code;

  /// The wallet's own name, the same in every language; empty for a bank
  /// account, which the app names in the reader's language.
  final String brand;

  static PaymentType fromCode(String? code) =>
      values.firstWhere((t) => t.code == code, orElse: () => bank);
}

/// One way to pay: the wallet or bank, whose account it is, and its number.
class PaymentMethod {
  const PaymentMethod({
    required this.type,
    required this.accountName,
    required this.number,
  });

  final PaymentType type;
  final String accountName;

  /// The wallet's phone number, or the bank and account number.
  final String number;

  factory PaymentMethod.fromMap(Map<String, dynamic> map) => PaymentMethod(
        type: PaymentType.fromCode(map['type'] as String?),
        accountName: map['name'] as String? ?? '',
        number: map['number'] as String? ?? '',
      );

  Map<String, Object> toMap() =>
      {'type': type.code, 'name': accountName, 'number': number};
}

/// Firestore: `shop_public/{shop id}`, readable by anyone.
/// Fields: phone, delivery_fee (int, whole kyats), payment_methods (list of
/// {type, name, number}), updated_at. Written with `shops/{id}`, whose phone
/// it repeats; see firestore.rules.
class ShopPublic {
  const ShopPublic({
    required this.shopId,
    this.phone = '',
    this.deliveryFee = 0,
    this.paymentMethods = const [],
  });

  final String shopId;
  final String phone;
  final int deliveryFee;
  final List<PaymentMethod> paymentMethods;

  factory ShopPublic.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return ShopPublic(
      shopId: doc.id,
      phone: data['phone'] as String? ?? '',
      deliveryFee: (data['delivery_fee'] as num?)?.toInt() ?? 0,
      paymentMethods: (data['payment_methods'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((m) => PaymentMethod.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }
}

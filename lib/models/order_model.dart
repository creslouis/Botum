import 'cart_item_model.dart';

class ShippingInfo {
  const ShippingInfo({
    required this.fullName,
    required this.street,
    required this.city,
    required this.phone,
  });

  final String fullName;
  final String street;
  final String city;
  final String phone;

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'street': street,
      'city': city,
      'phone': phone,
    };
  }

  factory ShippingInfo.fromMap(Map<String, dynamic> map) {
    return ShippingInfo(
      fullName: map['fullName'] as String? ?? '',
      street: map['street'] as String? ?? '',
      city: map['city'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
    );
  }
}

class OrderModel {
  const OrderModel({
    required this.orderId,
    required this.userId,
    required this.items,
    required this.totalPrice,
    required this.paymentMethod,
    required this.shippingInfo,
    required this.status,
    required this.createdAt,
  });

  final String orderId;
  final String userId;
  final List<CartItemModel> items;
  final double totalPrice;
  final String paymentMethod;
  final ShippingInfo shippingInfo;
  final String status;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalPrice': totalPrice,
      'paymentMethod': paymentMethod,
      'shippingInfo': shippingInfo.toMap(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      orderId: map['orderId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      items: ((map['items'] as List<dynamic>?) ?? <dynamic>[])
          .map((item) => CartItemModel.fromMap(item as Map<String, dynamic>))
          .toList(),
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['paymentMethod'] as String? ?? '',
      shippingInfo: ShippingInfo.fromMap(
        map['shippingInfo'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      status: map['status'] as String? ?? 'pending',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

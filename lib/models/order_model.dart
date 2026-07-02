import 'cart_item_model.dart';

class ShippingInfo {
  final String fullName;
  final String street;
  final String city;
  final String phone;

  ShippingInfo({
    this.fullName = '',
    this.street = '',
    this.city = '',
    this.phone = '',
  });

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

  ShippingInfo copyWith({
    String? fullName,
    String? street,
    String? city,
    String? phone,
  }) {
    return ShippingInfo(
      fullName: fullName ?? this.fullName,
      street: street ?? this.street,
      city: city ?? this.city,
      phone: phone ?? this.phone,
    );
  }

  bool get isValid =>
      fullName.isNotEmpty &&
      street.isNotEmpty &&
      city.isNotEmpty &&
      phone.isNotEmpty;
}

class OrderModel {
  final String orderId;
  final String userId;
  final List<CartItemModel> items;
  final double totalPrice;
  final String paymentMethod;
  final ShippingInfo shippingInfo;
  final String status; // pending, confirmed, shipped, delivered
  final DateTime createdAt;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.items,
    required this.totalPrice,
    required this.paymentMethod,
    required this.shippingInfo,
    this.status = 'pending',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get itemCount => items.length;
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

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
      items: (map['items'] as List<dynamic>?)
              ?.map((e) =>
                  CartItemModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] as String? ?? '',
      shippingInfo: ShippingInfo.fromMap(
          map['shippingInfo'] as Map<String, dynamic>? ?? {}),
      status: map['status'] as String? ?? 'pending',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  OrderModel copyWith({
    String? orderId,
    String? userId,
    List<CartItemModel>? items,
    double? totalPrice,
    String? paymentMethod,
    ShippingInfo? shippingInfo,
    String? status,
    DateTime? createdAt,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      shippingInfo: shippingInfo ?? this.shippingInfo,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

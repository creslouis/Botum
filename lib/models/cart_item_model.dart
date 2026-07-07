class CartItemModel {
  const CartItemModel({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    this.selectedColor,
    this.selectedSize,
  });

  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final String? selectedColor;
  final String? selectedSize;

  CartItemModel copyWith({
    String? productId,
    String? productName,
    String? productImage,
    double? price,
    int? quantity,
    String? selectedColor,
    String? selectedSize,
  }) {
    return CartItemModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedSize: selectedSize ?? this.selectedSize,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'selectedColor': selectedColor,
      'selectedSize': selectedSize,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      productImage: map['productImage'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      quantity: map['quantity'] as int? ?? 1,
      selectedColor: map['selectedColor'] as String?,
      selectedSize: map['selectedSize'] as String?,
    );
  }
}

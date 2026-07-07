import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item_model.dart';

class CartProvider extends ChangeNotifier {
  static const _storageKey = 'botum_cart_items';
  static const int maxQuantityPerItem = 10;
  static const double standardShippingFee = 3.99;
  static const double freeShippingThreshold = 100;

  final List<CartItemModel> _items = <CartItemModel>[];
  bool _isLoading = false;

  List<CartItemModel> get items => List<CartItemModel>.unmodifiable(_items);
  bool get isLoading => _isLoading;

  double get subtotal => _items.fold<double>(
    0,
    (total, item) => total + (item.price * item.quantity),
  );

  double get shippingFee => _items.isEmpty || subtotal >= freeShippingThreshold
      ? 0
      : standardShippingFee;

  double get totalPrice => subtotal + shippingFee;

  int get itemCount => _items.length;

  int get totalQuantity =>
      _items.fold<int>(0, (total, item) => total + item.quantity);

  Future<void> loadCart() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawItems = prefs.getStringList(_storageKey) ?? <String>[];
      _items
        ..clear()
        ..addAll(
          rawItems
              .map((item) => jsonDecode(item) as Map<String, dynamic>)
              .map(CartItemModel.fromMap),
        );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addToCart(CartItemModel item) async {
    final index = _items.indexWhere(
      (existing) =>
          existing.productId == item.productId &&
          existing.selectedColor == item.selectedColor &&
          existing.selectedSize == item.selectedSize,
    );

    if (index >= 0) {
      final existing = _items[index];
      _items[index] = existing.copyWith(
        quantity: _normalizeQuantity(existing.quantity + item.quantity),
      );
    } else {
      _items.add(item.copyWith(quantity: _normalizeQuantity(item.quantity)));
    }

    await _persistCart();
    notifyListeners();
  }

  Future<void> removeFromCart(String productId) async {
    _items.removeWhere((item) => item.productId == productId);
    await _persistCart();
    notifyListeners();
  }

  Future<void> updateQuantity(String productId, int newQuantity) async {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index < 0) {
      return;
    }

    if (newQuantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index] = _items[index].copyWith(
        quantity: _normalizeQuantity(newQuantity),
      );
    }

    await _persistCart();
    notifyListeners();
  }

  Future<void> clearCart() async {
    _items.clear();
    await _persistCart();
    notifyListeners();
  }

  Future<void> seedDemoItem() async {
    await addToCart(
      const CartItemModel(
        productId: 'demo-cyclo-pin',
        productName: 'Cyclo Enamel Pin',
        productImage: '',
        price: 29.99,
        quantity: 1,
        selectedColor: 'Gold',
        selectedSize: '17 cm',
      ),
    );
  }

  Future<void> _persistCart() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _items.map((item) => jsonEncode(item.toMap())).toList();
    await prefs.setStringList(_storageKey, payload);
  }

  int _normalizeQuantity(int quantity) {
    if (quantity < 1) {
      return 1;
    }

    if (quantity > maxQuantityPerItem) {
      return maxQuantityPerItem;
    }

    return quantity;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

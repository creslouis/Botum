import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';

/// Placeholder — Hokdo will implement this provider.
class CartProvider extends ChangeNotifier {
  final List<CartItemModel> _items = [];
  final bool _isLoading = false;

  List<CartItemModel> get items => _items;
  int get itemCount => _items.length;
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice => _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  bool get isLoading => _isLoading;

  void addToCart(CartItemModel item) {
    final index = _items.indexWhere((i) => i.productId == item.productId);
    if (index >= 0) {
      _items[index].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _items.removeWhere((i) => i.productId == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere((i) => i.productId == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  bool containsProduct(String productId) {
    return _items.any((i) => i.productId == productId);
  }
}

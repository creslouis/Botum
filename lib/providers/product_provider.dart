import 'package:flutter/foundation.dart';
import '../models/product_model.dart';

/// Placeholder — Thebdey will implement this provider.
class ProductProvider extends ChangeNotifier {
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = 'All';

  List<ProductModel> get products => _filteredProducts;
  List<ProductModel> get allProducts => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;

  Future<void> fetchProducts() async {
    // Thebdey will implement
  }

  Future<void> fetchProductsByCategory(String category) async {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> searchProducts(String query) async {
    // Thebdey will implement
  }
}

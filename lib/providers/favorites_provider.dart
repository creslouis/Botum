import 'package:flutter/foundation.dart';
import '../models/product_model.dart';

/// Placeholder — Rithy will implement this provider.
class FavoritesProvider extends ChangeNotifier {
  final List<ProductModel> _favorites = [];
  bool _isLoading = false;

  List<ProductModel> get favorites => _favorites;
  int get favoriteCount => _favorites.length;
  bool get isLoading => _isLoading;

  void toggleFavorite(ProductModel product) {
    final index = _favorites.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _favorites.removeAt(index);
    } else {
      _favorites.add(product);
    }
    notifyListeners();
  }

  bool isFavorite(String productId) {
    return _favorites.any((p) => p.id == productId);
  }

  void removeFavorite(String productId) {
    _favorites.removeWhere((p) => p.id == productId);
    notifyListeners();
  }

  Future<void> loadFavorites(String userId) async {
    // Rithy will implement with Firestore sync
  }
}

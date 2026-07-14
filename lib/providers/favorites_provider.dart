import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<ProductModel> _favorites = [];
  Map<String, ProductModel> _favoritesMap = {};
  bool _isLoading = false;
  String? _error;
  String? _userId;
  StreamSubscription<List<String>>? _favStreamSub;
  StreamSubscription? _authSub;

  List<ProductModel> get favorites => _favorites;
  int get favoriteCount => _favorites.length;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void initAuthListener(Stream<User?> authStream) {
    _authSub = authStream.listen((user) {
      setUserId(user?.uid);
    });
  }

  void setUserId(String? userId) {
    if (_userId != userId) {
      _favStreamSub?.cancel();
      _favStreamSub = null;
      _userId = userId;
      if (userId != null) {
        _listenToFavorites(userId);
      } else {
        _favorites.clear();
        _favoritesMap.clear();
        notifyListeners();
      }
    }
  }

  void _listenToFavorites(String userId) {
    _isLoading = true;
    notifyListeners();

    _favStreamSub = _firestoreService.streamFavoriteIds(userId).listen(
      (ids) async {
        final products = <ProductModel>[];
        final map = <String, ProductModel>{};

        for (final id in ids) {
          final product = await _firestoreService.getProductById(id);
          if (product != null) {
            products.add(product);
            map[id] = product;
          }
        }

        _favorites = products;
        _favoritesMap = map;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Failed to load favorites.';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> loadFavorites(String userId) async {
    setUserId(userId);
  }

  Future<void> toggleFavorite(ProductModel product) async {
    if (_userId == null) return;

    final exists = _favoritesMap.containsKey(product.id);
    if (exists) {
      _favorites.removeWhere((p) => p.id == product.id);
      _favoritesMap.remove(product.id);
    } else {
      _favorites.add(product);
      _favoritesMap[product.id] = product;
    }
    notifyListeners();

    try {
      await _firestoreService.toggleFavorite(_userId!, product.id);
    } catch (e) {
      if (exists) {
        _favorites.add(product);
        _favoritesMap[product.id] = product;
      } else {
        _favorites.removeWhere((p) => p.id == product.id);
        _favoritesMap.remove(product.id);
      }
      notifyListeners();
    }
  }

  bool isFavorite(String productId) {
    return _favoritesMap.containsKey(productId);
  }

  Future<void> removeFavorite(String productId) async {
    if (_userId == null) return;

    final removed = _favoritesMap[productId];
    _favorites.removeWhere((p) => p.id == productId);
    _favoritesMap.remove(productId);
    notifyListeners();

    try {
      await _firestoreService.toggleFavorite(_userId!, productId);
    } catch (e) {
      if (removed != null) {
        _favorites.add(removed);
        _favoritesMap[productId] = removed;
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _favStreamSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}

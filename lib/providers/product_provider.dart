import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';

class ProductProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _useMockData = false;

  List<ProductModel> get products => _filteredProducts;
  List<ProductModel> get allProducts => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetched = await _firestoreService.getProductsOnce();
      if (fetched.isEmpty) {
        _products = _generateMockProducts();
        _useMockData = true;
      } else {
        _products = fetched;
        _useMockData = false;
      }
      _applyFilters();
    } catch (e) {
      _products = _generateMockProducts();
      _useMockData = true;
      _applyFilters();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchProductsByCategory(String category) async {
    _selectedCategory = category;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (category == 'All') {
        await fetchProducts();
        return;
      }
      if (_useMockData) {
        _applyFilters();
      } else {
        final fetched = await _firestoreService.getProductsOnce();
        _products = fetched;
        _applyFilters();
      }
    } catch (e) {
      _applyFilters();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchProducts(String query) async {
    _searchQuery = query.trim();
    _applyFilters();
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  ProductModel? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<ProductModel> get productsByCategory {
    if (_selectedCategory == 'All') return _products;
    return _products
        .where((p) => p.category.toLowerCase() == _selectedCategory.toLowerCase())
        .toList();
  }

  void _applyFilters() {
    var result = List<ProductModel>.from(_products);

    if (_selectedCategory != 'All') {
      result = result.where((p) =>
          p.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((p) =>
          p.name.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query)).toList();
    }

    _filteredProducts = result;
  }

  List<ProductModel> _generateMockProducts() {
    return [
      ProductModel(
        id: 'mock_1',
        name: 'Angkor Wat Keychain',
        description: 'Handcrafted wooden keychain featuring the iconic Angkor Wat silhouette. Each piece is carefully carved and painted by skilled artisans in Siem Reap.',
        price: 4.99,
        images: [],
        category: 'Keychains',
        colors: ['Brown', 'Natural', 'Dark'],
        sizes: ['10 cm'],
        stock: 50,
      ),
      ProductModel(
        id: 'mock_2',
        name: 'Elephant Keychain',
        description: 'Cute elephant-shaped keychain made from resin. A symbol of good luck in Khmer culture, perfect as a small gift.',
        price: 3.99,
        images: [],
        category: 'Keychains',
        colors: ['White', 'Pink', 'Blue'],
        sizes: ['8 cm'],
        stock: 45,
      ),
      ProductModel(
        id: 'mock_3',
        name: 'Naga Dragon Keychain',
        description: 'Traditional Naga dragon keychain made of brass. The Naga is a mythical serpent that protects temples in Khmer mythology.',
        price: 5.99,
        images: [],
        category: 'Keychains',
        colors: ['Gold', 'Silver', 'Bronze'],
        sizes: ['12 cm'],
        stock: 30,
      ),
      ProductModel(
        id: 'mock_4',
        name: 'Krama Scarf',
        description: 'Authentic Khmer traditional checkered scarf made from 100% cotton. Handwoven by local communities in Kampong Cham province.',
        price: 12.99,
        images: [],
        category: 'Clothing',
        colors: ['Red & White', 'Blue & White', 'Green & White'],
        sizes: ['One Size'],
        stock: 100,
      ),
      ProductModel(
        id: 'mock_5',
        name: 'Silk Sarong',
        description: 'Luxurious handwoven silk sarong with traditional Khmer patterns. Each piece takes several days to complete by master weavers.',
        price: 34.99,
        images: [],
        category: 'Clothing',
        colors: ['Gold', 'Purple', 'Emerald'],
        sizes: ['Standard', 'Long'],
        stock: 25,
      ),
      ProductModel(
        id: 'mock_6',
        name: 'Traditional Cambodian Shirt',
        description: 'Comfortable cotton shirt with traditional Khmer embroidery details on collar and cuffs. Features Angkor-inspired patterns.',
        price: 19.99,
        images: [],
        category: 'Clothing',
        colors: ['White', 'Black', 'Navy'],
        sizes: ['S', 'M', 'L', 'XL'],
        stock: 60,
      ),
      ProductModel(
        id: 'mock_7',
        name: 'Wood Carving Buddha',
        description: 'Intricately carved wooden Buddha head statue. Made from sustainably sourced neem tree wood by artisans in Kampong Thom.',
        price: 45.00,
        images: [],
        category: 'Handicraft',
        colors: ['Natural Wood', 'Dark Wood'],
        sizes: ['15 cm', '25 cm', '40 cm'],
        stock: 15,
      ),
      ProductModel(
        id: 'mock_8',
        name: 'Bamboo Woven Basket',
        description: 'Traditional Khmer bamboo basket handwoven using techniques passed down through generations. Perfect for storage or decoration.',
        price: 22.50,
        images: [],
        category: 'Handicraft',
        colors: ['Natural', 'Dyed Pattern'],
        sizes: ['Small', 'Medium', 'Large'],
        stock: 20,
      ),
      ProductModel(
        id: 'mock_9',
        name: 'Stone Elephant Statue',
        description: 'Hand-carved sandstone elephant statue inspired by temple guardians. Each statue is unique due to the natural stone veining.',
        price: 55.00,
        images: [],
        category: 'Handicraft',
        colors: ['Sandstone', 'Grey Stone'],
        sizes: ['10 cm', '20 cm'],
        stock: 10,
      ),
      ProductModel(
        id: 'mock_10',
        name: 'Silver Lotus Earrings',
        description: 'Elegant silver earrings designed as blooming lotus flowers. Made by silversmiths in Kampong Luong, a village famous for silverwork.',
        price: 28.00,
        images: [],
        category: 'Jewelry',
        colors: ['Silver'],
        sizes: ['3 cm'],
        stock: 35,
      ),
      ProductModel(
        id: 'mock_11',
        name: 'Khmer Friendship Bracelet',
        description: 'Hand-braided cotton bracelet with traditional Khmer patterns. Each color combination carries a different meaning in Khmer culture.',
        price: 6.99,
        images: [],
        category: 'Jewelry',
        colors: ['Rainbow', 'Red & Gold', 'Blue & Silver'],
        sizes: ['Adjustable'],
        stock: 80,
      ),
      ProductModel(
        id: 'mock_12',
        name: 'Pearl & Crystal Necklace',
        description: 'Stunning necklace combining freshwater pearls with Swarovski crystals in traditional Khmer floral design. Handcrafted in Phnom Penh.',
        price: 39.99,
        images: [],
        category: 'Jewelry',
        colors: ['White Pearl', 'Golden Pearl'],
        sizes: ['45 cm'],
        stock: 20,
      ),
    ];
  }
}

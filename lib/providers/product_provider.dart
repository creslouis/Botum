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
        images: ['https://ph-test-11.slatic.net/p/255c6187cbb6d8c4c5e4d09fa2aa25e5.jpg'],
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
        images: ['https://images-na.ssl-images-amazon.com/images/I/61WlaZGdQpL._SS400_.jpg'],
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
        images: ['https://img-new.cgtrader.com/items/4394286/437c52e5de/naga-khmer-pendants-gold-dragon-cambodia-naga-3d-print-model-3d-model-437c52e5de.jpg'],
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
        images: ['https://upload.wikimedia.org/wikipedia/commons/5/56/Krama_-_%E3%81%8A%E5%9C%9F%E7%94%A3%E3%81%AB%E8%B2%B7%E3%81%A3%E3%81%9F%E3%82%AF%E3%83%AD%E3%83%9E%E3%83%BC%EF%BC%88%E3%83%9E%E3%83%95%E3%83%A9%E3%83%BC%EF%BC%89.jpg'],
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
        images: ['https://image.invaluable.com/housePhotos/ashcroftandmoore/21/746221/H20734-L329112582.jpg'],
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
        images: ['https://nimbu.sg/cdn/shop/files/Cotton_Adults_unisex_shirt_Cambodia.jpg?v=1730428933&width=1920'],
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
        images: ['https://www.hdasianart.com/cdn/shop/articles/SCWO1100-5_1260x.jpg?v=1703587833'],
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
        images: ['https://www.thestatesman.com/wp-content/uploads/2022/07/iStock-1308102182-e1658662413692.jpg'],
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
        images: ['https://elements-resized.envatousercontent.com/elements-video-cover-images/files/096460bf-2200-4080-882b-327dfd51ca03/inline_image_preview.jpg?w=500&cf_fit=cover&q=85&format=auto&s=0a0c9cd8a4deb6fd0cdff15d133809ce0cf73d847ccb5372c1fa4789d3e3d4ff'],
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
        images: ['https://bloombysushmita.com/cdn/shop/products/D551BE7B-B521-407D-AFCD-F8363C7E7E3D.jpg?v=1719475928&width=1946'],
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
        images: ['https://i.etsystatic.com/7678544/r/il/cf1775/5386170905/il_fullxfull.5386170905_bknj.jpg'],
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
        images: ['https://images.pexels.com/photos/7514818/pexels-photo-7514818.jpeg?auto=compress&cs=tinysrgb&w=600&h=600&fit=crop'],
        category: 'Jewelry',
        colors: ['White Pearl', 'Golden Pearl'],
        sizes: ['45 cm'],
        stock: 20,
      ),
    ];
  }
}

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
  bool get usingMockData => _useMockData;

  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetched = await _firestoreService.getProductsOnce();
      if (fetched.isEmpty) {
        // Firestore is empty — use mock data as seed only if we have nothing
        if (_products.isEmpty) {
          _products = _generateMockProducts();
          _useMockData = true;
        }
      } else {
        _products = fetched;
        _useMockData = false;
      }
      _error = null;
      _applyFilters();
    } catch (e) {
      // Bug fix: only use mock data if we have no existing products,
      // don't silently replace real data with mock data on errors
      _error = 'Failed to load products: ${e.toString()}';
      if (_products.isEmpty) {
        _products = _generateMockProducts();
        _useMockData = true;
      }
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

  void resetFilters() {
    _selectedCategory = 'All';
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  ProductModel? getProductById(String id) {
    // Use safe firstWhere with orElse instead of try/catch
    return _products.firstWhere(
      (p) => p.id == id,
      orElse: () => ProductModel(id: '', name: '', description: '', price: 0),
    ).id.isEmpty
        ? null
        : _products.firstWhere((p) => p.id == id);
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
        images: ['assets/images/product/1.jpg'],
        category: 'Keychains',
        colors: ['Brown', 'Natural', 'Dark'],
        sizes: ['10 cm'],
        features: [
          'Authentic Angkor Wat design',
          'Hand-carved by local artisans',
          'Lightweight and durable',
          'Perfect souvenir or gift item',
        ],
        stock: 50,
      ),
      ProductModel(
        id: 'mock_2',
        name: 'Elephant Keychain',
        description: 'Cute elephant-shaped keychain made from resin. A symbol of good luck in Khmer culture, perfect as a small gift.',
        price: 3.99,
        images: ['assets/images/product/2.jpg'],
        category: 'Keychains',
        colors: ['White', 'Pink', 'Blue'],
        sizes: ['8 cm'],
        features: [
          'Lucky elephant symbol in Khmer culture',
          'Resin construction',
          'Vivid color options',
          'Ideal for keys, bags, backpacks',
        ],
        stock: 45,
      ),
      ProductModel(
        id: 'mock_3',
        name: 'Cyclo Enamel Pin',
        description: 'Carry a piece of Cambodia wherever you go with this beautifully crafted Cyclo Keychain. Inspired by the iconic cyclo, a traditional three-wheeled bicycle that symbolizes Cambodia\'s rich cultural heritage, this souvenir combines elegance with local charm.',
        price: 29.99,
        images: ['assets/images/product/3.jpg'],
        category: 'Keychains',
        colors: ['Gold', 'Silver', 'Bronze'],
        sizes: ['17 cm'],
        features: [
          'Authentic Cambodian cyclo design',
          'Premium metal construction with gold-tone plating',
          'Vibrant enamel detailing',
          'Lightweight and durable',
          'Perfect souvenir or gift item',
        ],
        stock: 30,
      ),
      ProductModel(
        id: 'mock_4',
        name: 'Krama Scarf',
        description: 'Authentic Khmer traditional checkered scarf made from 100% cotton. Handwoven by local communities in Kampong Cham province.',
        price: 12.99,
        images: ['assets/images/product/4.jpg'],
        category: 'Clothing',
        colors: ['Red & White', 'Blue & White', 'Green & White'],
        sizes: ['One Size'],
        features: [
          '100% natural cotton',
          'Traditional Khmer checkered pattern',
          'Handwoven by local artisans',
          'Versatile — scarf, headwrap, or decoration',
        ],
        stock: 100,
      ),
      ProductModel(
        id: 'mock_5',
        name: 'Silk Sarong',
        description: 'Luxurious handwoven silk sarong with traditional Khmer patterns. Each piece takes several days to complete by master weavers.',
        price: 34.99,
        images: ['assets/images/product/5.jpg'],
        category: 'Clothing',
        colors: ['Gold', 'Purple', 'Emerald'],
        sizes: ['Standard', 'Long'],
        features: [
          'Pure silk construction',
          'Master-woven traditional Khmer patterns',
          'Rich, vibrant colors',
          'Each piece takes days to complete',
        ],
        stock: 25,
      ),
      ProductModel(
        id: 'mock_6',
        name: 'Traditional Cambodian Shirt',
        description: 'Comfortable cotton shirt with traditional Khmer embroidery details on collar and cuffs. Features Angkor-inspired patterns.',
        price: 19.99,
        images: ['assets/images/product/6.jpg'],
        category: 'Clothing',
        colors: ['White', 'Black', 'Navy'],
        sizes: ['S', 'M', 'L', 'XL'],
        features: [
          'Soft breathable cotton',
          'Khmer embroidery on collar and cuffs',
          'Angkor-inspired patterns',
          'Machine washable',
        ],
        stock: 60,
      ),
      ProductModel(
        id: 'mock_7',
        name: 'Wood Carving Buddha',
        description: 'Intricately carved wooden Buddha head statue. Made from sustainably sourced neem tree wood by artisans in Kampong Thom.',
        price: 45.00,
        images: ['assets/images/product/7.jpg'],
        category: 'Handicraft',
        colors: ['Natural Wood', 'Dark Wood'],
        sizes: ['15 cm', '25 cm', '40 cm'],
        features: [
          'Sustainably sourced neem wood',
          'Hand-carved by Kampong Thom artisans',
          'Each piece is unique',
          'Multiple size options',
        ],
        stock: 15,
      ),
      ProductModel(
        id: 'mock_8',
        name: 'Bamboo Woven Basket',
        description: 'Traditional Khmer bamboo basket handwoven using techniques passed down through generations. Perfect for storage or decoration.',
        price: 22.50,
        images: ['assets/images/product/8.jpg'],
        category: 'Handicraft',
        colors: ['Natural', 'Dyed Pattern'],
        sizes: ['Small', 'Medium', 'Large'],
        features: [
          'Handwoven using traditional techniques',
          'Sustainable bamboo material',
          'Multiple size options',
          'Functional and decorative',
        ],
        stock: 20,
      ),
      ProductModel(
        id: 'mock_9',
        name: 'Stone Elephant Statue',
        description: 'Hand-carved sandstone elephant statue inspired by temple guardians. Each statue is unique due to the natural stone veining.',
        price: 55.00,
        images: ['assets/images/product/9.jpg'],
        category: 'Handicraft',
        colors: ['Sandstone', 'Grey Stone'],
        sizes: ['10 cm', '20 cm'],
        features: [
          'Hand-carved sandstone',
          'Inspired by Angkor temple guardians',
          'Each piece is unique',
          'Natural stone veining patterns',
        ],
        stock: 10,
      ),
      ProductModel(
        id: 'mock_10',
        name: 'Silver Lotus Earrings',
        description: 'Elegant silver earrings designed as blooming lotus flowers. Made by silversmiths in Kampong Luong, a village famous for silverwork.',
        price: 28.00,
        images: ['assets/images/product/10.jpg'],
        category: 'Jewelry',
        colors: ['Silver'],
        sizes: ['3 cm'],
        features: [
          'Sterling silver construction',
          'Lotus flower design',
          'Handcrafted by Kampong Luong silversmiths',
          'Nickel-free, hypoallergenic',
        ],
        stock: 35,
      ),
      ProductModel(
        id: 'mock_11',
        name: 'Khmer Friendship Bracelet',
        description: 'Hand-braided cotton bracelet with traditional Khmer patterns. Each color combination carries a different meaning in Khmer culture.',
        price: 6.99,
        images: ['assets/images/product/11.jpg'],
        category: 'Jewelry',
        colors: ['Rainbow', 'Red & Gold', 'Blue & Silver'],
        sizes: ['Adjustable'],
        features: [
          'Hand-braided cotton',
          'Traditional Khmer patterns',
          'Each color has cultural meaning',
          'Adjustable fit',
        ],
        stock: 80,
      ),
      ProductModel(
        id: 'mock_12',
        name: 'Pearl & Crystal Necklace',
        description: 'Stunning necklace combining freshwater pearls with Swarovski crystals in traditional Khmer floral design. Handcrafted in Phnom Penh.',
        price: 39.99,
        images: ['assets/images/product/12.jpg'],
        category: 'Jewelry',
        colors: ['White Pearl', 'Golden Pearl'],
        sizes: ['45 cm'],
        features: [
          'Freshwater pearls',
          'Swarovski crystal accents',
          'Traditional Khmer floral design',
          'Handcrafted in Phnom Penh',
        ],
        stock: 20,
      ),
    ];
  }
}

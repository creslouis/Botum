import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../core/constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _users =>
      _firestore.collection(AppConstants.collectionUsers);
  CollectionReference get _products =>
      _firestore.collection(AppConstants.collectionProducts);
  CollectionReference get _orders =>
      _firestore.collection(AppConstants.collectionOrders);

  // ─── Users ───────────────────────────────────────────────

  Future<void> createUser(UserModel user) async {
    await _users.doc(user.uid).set(user.toMap());
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).update(data);
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  Stream<UserModel?> streamUser(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return UserModel.fromMap(snapshot.data() as Map<String, dynamic>);
    });
  }

  // ─── Products ────────────────────────────────────────────

  Future<void> addProduct(ProductModel product) async {
    await _products.doc(product.id).set(product.toMap());
  }

  Future<void> updateProduct(
      String productId, Map<String, dynamic> data) async {
    await _products.doc(productId).update(data);
  }

  Future<void> deleteProduct(String productId) async {
    await _products.doc(productId).delete();
  }

  Future<ProductModel?> getProductById(String productId) async {
    final doc = await _products.doc(productId).get();
    if (!doc.exists) return null;
    return ProductModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  Stream<List<ProductModel>> getProducts() {
    return _products
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_productsListFromSnapshot);
  }

  Future<List<ProductModel>> getProductsOnce() async {
    final snapshot = await _products
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();
    return _productsListFromSnapshot(snapshot);
  }

  Stream<List<ProductModel>> getProductsByCategory(String category) {
    return _products
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_productsListFromSnapshot);
  }

  Stream<List<ProductModel>> getAllProductsForAdmin() {
    return _products
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_productsListFromSnapshot);
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    final snapshot = await _products
        .where('isActive', isEqualTo: true)
        .get();
    final allProducts = _productsListFromSnapshot(snapshot);
    final lowerQuery = query.toLowerCase();
    return allProducts.where((product) {
      return product.name.toLowerCase().contains(lowerQuery) ||
          product.description.toLowerCase().contains(lowerQuery) ||
          product.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  List<ProductModel> _productsListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return ProductModel.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
  }

  // ─── Orders ──────────────────────────────────────────────

  Future<void> createOrder(OrderModel order) async {
    await _orders.doc(order.orderId).set(order.toMap());
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _orders.doc(orderId).update({'status': status});
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    final doc = await _orders.doc(orderId).get();
    if (!doc.exists) return null;
    return OrderModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  Stream<List<OrderModel>> getUserOrders(String userId) {
    return _orders
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_ordersListFromSnapshot);
  }

  Stream<List<OrderModel>> getAllOrders() {
    return _orders
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_ordersListFromSnapshot);
  }

  List<OrderModel> _ordersListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return OrderModel.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
  }

  // ─── Favorites (subcollection) ───────────────────────────

  Future<void> toggleFavorite(String userId, String productId) async {
    final favDoc = _users
        .doc(userId)
        .collection(AppConstants.collectionFavorites)
        .doc(productId);
    final doc = await favDoc.get();
    if (doc.exists) {
      await favDoc.delete();
    } else {
      await favDoc.set({'productId': productId, 'addedAt': FieldValue.serverTimestamp()});
    }
  }

  Future<bool> isFavorite(String userId, String productId) async {
    final doc = await _users
        .doc(userId)
        .collection(AppConstants.collectionFavorites)
        .doc(productId)
        .get();
    return doc.exists;
  }

  Stream<List<String>> streamFavoriteIds(String userId) {
    return _users
        .doc(userId)
        .collection(AppConstants.collectionFavorites)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.id)
            .toList());
  }
}

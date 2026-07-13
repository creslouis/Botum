import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/payment_method_model.dart';
import '../core/constants/app_constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _users =>
      _firestore.collection(AppConstants.collectionUsers);
  CollectionReference get _products =>
      _firestore.collection(AppConstants.collectionProducts);
  CollectionReference get _orders =>
      _firestore.collection(AppConstants.collectionOrders);
  CollectionReference get _paymentMethods =>
      _firestore.collection(AppConstants.collectionPaymentMethods);
  CollectionReference get _appSettings =>
      _firestore.collection(AppConstants.collectionAppSettings);

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

  Future<UserModel?> getUserByEmail(String email) async {
    final snapshot = await _users.where('email', isEqualTo: email.trim()).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    return UserModel.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
  }

  Stream<UserModel?> streamUser(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return UserModel.fromMap(snapshot.data() as Map<String, dynamic>);
    });
  }

  /// Get all users (admin only)
  Stream<List<UserModel>> getAllUsers() {
    return _users
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Update a user's role (admin only)
  Future<void> updateUserRole(String uid, String role) async {
    await _users.doc(uid).update({'role': role});
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

  /// Seed mock products into Firestore (admin only)
  Future<int> seedProducts(List<ProductModel> products) async {
    final batch = _firestore.batch();
    int count = 0;
    for (final product in products) {
      final docRef = _products.doc(product.id);
      final existing = await docRef.get();
      if (!existing.exists) {
        batch.set(docRef, product.toMap());
        count++;
      }
    }
    await batch.commit();
    return count;
  }

  /// Save or update banner settings
  Future<void> updateBannerSettings(Map<String, dynamic> data) async {
    await _appSettings.doc('banner').set(data, SetOptions(merge: true));
  }

  /// Get banner settings
  Future<Map<String, dynamic>?> getBannerSettings() async {
    final doc = await _appSettings.doc('banner').get();
    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>?;
  }

  Stream<Map<String, dynamic>?> streamBannerSettings() {
    return _appSettings.doc('banner').snapshots().map((doc) {
      if (!doc.exists) return null;
      return doc.data() as Map<String, dynamic>?;
    });
  }

  Future<ProductModel?> getProductById(String productId) async {
    final doc = await _products.doc(productId).get();
    if (!doc.exists) return null;
    return ProductModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  Stream<List<ProductModel>> getProducts() {
    return _products
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final list = _productsListFromSnapshot(snapshot);
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<List<ProductModel>> getProductsOnce() async {
    final snapshot = await _products
        .where('isActive', isEqualTo: true)
        .get();
    final list = _productsListFromSnapshot(snapshot);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Stream<List<ProductModel>> getProductsByCategory(String category) {
    return _products
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final list = _productsListFromSnapshot(snapshot);
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<ProductModel>> getAllProductsForAdmin() {
    return _products
        .snapshots()
        .map((snapshot) {
          final list = _productsListFromSnapshot(snapshot);
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
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
        .snapshots()
        .map((snapshot) {
          final list = _ordersListFromSnapshot(snapshot);
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<OrderModel>> getAllOrders() {
    return _orders
        .snapshots()
        .map((snapshot) {
          final list = _ordersListFromSnapshot(snapshot);
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
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

  // ─── Payment Methods ─────────────────────────────────────

  /// Stream of active payment methods sorted by sortOrder (for checkout screen)
  Stream<List<PaymentMethodModel>> getPaymentMethods() {
    return _paymentMethods
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => PaymentMethodModel.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
          list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          return list;
        });
  }

  /// Stream of all payment methods including inactive (for admin panel)
  Stream<List<PaymentMethodModel>> getAllPaymentMethods() {
    return _paymentMethods
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => PaymentMethodModel.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
          list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          return list;
        });
  }

  Future<void> addPaymentMethod(PaymentMethodModel method) async {
    await _paymentMethods.doc(method.id).set(method.toMap());
  }

  Future<void> updatePaymentMethod(String id, Map<String, dynamic> data) async {
    await _paymentMethods.doc(id).update({
      ...data,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deletePaymentMethod(String id) async {
    await _paymentMethods.doc(id).delete();
  }

  // ─── App Settings ─────────────────────────────────────────

  Future<Map<String, dynamic>?> getAppSettings() async {
    final doc = await _appSettings.doc('general').get();
    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>?;
  }

  Future<void> updateAppSettings(Map<String, dynamic> data) async {
    await _appSettings.doc('general').set(data, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>?> streamAppSettings() {
    return _appSettings.doc('general').snapshots().map((doc) {
      if (!doc.exists) return null;
      return doc.data() as Map<String, dynamic>?;
    });
  }

  // ─── Dashboard Stats ──────────────────────────────────────

  Future<Map<String, int>> getDashboardStats() async {
    final results = await Future.wait([
      _products.count().get(),
      _orders.count().get(),
      _users.count().get(),
    ]);
    return {
      'products': results[0].count ?? 0,
      'orders': results[1].count ?? 0,
      'users': results[2].count ?? 0,
    };
  }
}

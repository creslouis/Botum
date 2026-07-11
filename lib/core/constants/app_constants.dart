class AppConstants {
  AppConstants._();

  static const String appName = 'Botum';
  static const String appTagline = 'Authentic Khmer Handmade Souvenir';

  static const String defaultAvatar = 'assets/images/default_avatar.png';
  static const String placeholderImage = 'assets/images/placeholder.png';

  static const String phonePrefix = '+855';

  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double buttonRadius = 25.0;
  static const double cardRadius = 12.0;
  static const double largeCardRadius = 16.0;

  static const List<String> categories = [
    'Keychains',
    'Clothing',
    'Handicraft',
    'Jewelry',
  ];

  static const List<String> categoryIcons = [
    '🔑',
    '👕',
    '🎨',
    '💍',
  ];

  static const List<String> paymentMethods = [
    'ABA Payway',
    'Acleda Bank',
    'Mastercard',
    'Paypal',
    'Cash On Delivery',
  ];

  static const List<String> orderStatuses = [
    'pending',
    'confirmed',
    'shipped',
    'delivered',
  ];

  static const String userRoleAdmin = 'admin';
  static const String userRoleUser = 'user';

  // Admin emails that are auto-promoted on first sign-in
  static const List<String> adminEmails = ['kimhengmorm3@gmail.com'];

  // Firestore collection names
  static const String collectionUsers = 'users';
  static const String collectionProducts = 'products';
  static const String collectionOrders = 'orders';
  static const String collectionFavorites = 'favorites';
  static const String collectionCart = 'cart';
  static const String collectionPaymentMethods = 'payment_methods';
  static const String collectionAppSettings = 'app_settings';

  // Firebase Storage paths
  static const String storageProducts = 'products';
  static const String storageAvatars = 'avatars';
  static const String storagePaymentMethods = 'payment_methods';
}

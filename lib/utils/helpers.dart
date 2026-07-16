import 'package:intl/intl.dart';

class Helpers {
  Helpers._();

  static String normalizeImageUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('assets/')) return trimmed;
    if (trimmed.startsWith('//')) return 'https:$trimmed';
    if (trimmed.toLowerCase().startsWith('www.')) return 'https://$trimmed';
    return trimmed;
  }

  static bool isRemoteImageUrl(String value) {
    final normalized = normalizeImageUrl(value);
    final uri = Uri.tryParse(normalized);
    return uri != null &&
        (uri.scheme.toLowerCase() == 'http' ||
            uri.scheme.toLowerCase() == 'https');
  }

  static bool isAssetImagePath(String value) {
    return normalizeImageUrl(value).startsWith('assets/');
  }

  static String formatPrice(double price) {
    final format = NumberFormat.currency(symbol: '\$ ', decimalDigits: 2);
    return format.format(price);
  }

  static String formatDate(DateTime date) {
    final format = DateFormat('MMM dd, yyyy');
    return format.format(date);
  }

  static String formatDateTime(DateTime date) {
    final format = DateFormat('MMM dd, yyyy HH:mm');
    return format.format(date);
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static String shortenOrderId(String orderId) {
    if (orderId.length <= 8) return orderId;
    return '...${orderId.substring(orderId.length - 8)}';
  }

  static String maskCardNumber(String cardNumber) {
    if (cardNumber.length < 4) return cardNumber;
    return '•••• ${cardNumber.substring(cardNumber.length - 4)}';
  }

  static bool isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    final regex = RegExp(r'^\+?[\d\s\-()]{7,15}$');
    return regex.hasMatch(phone);
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  static String getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return '#F57C00';
      case 'confirmed':
        return '#1976D2';
      case 'shipped':
        return '#E91E8C';
      case 'delivered':
        return '#388E3C';
      default:
        return '#9E9E9E';
    }
  }

  static String getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'keychains':
        return '🔑';
      case 'clothing':
        return '👕';
      case 'handicraft':
        return '🎨';
      case 'jewelry':
        return '💍';
      default:
        return '🎁';
    }
  }
}

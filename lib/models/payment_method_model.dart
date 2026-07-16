import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentMethodModel {
  final String id;
  final String name;
  final String iconUrl; // Firebase Storage download URL for the payment brand icon
  final bool isActive;
  final int sortOrder;
  final bool requiresCard; // true for card-based payments like Mastercard
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentMethodModel({
    required this.id,
    required this.name,
    this.iconUrl = '',
    this.isActive = true,
    this.sortOrder = 0,
    this.requiresCard = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Parse a dynamic value that could be a Firestore Timestamp, an ISO string,
  /// or null into a DateTime. Returns fallback on failure.
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconUrl': iconUrl,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'requiresCard': requiresCard,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PaymentMethodModel.fromMap(Map<String, dynamic> map) {
    return PaymentMethodModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      iconUrl: map['iconUrl'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      requiresCard: map['requiresCard'] as bool? ?? false,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  PaymentMethodModel copyWith({
    String? id,
    String? name,
    String? iconUrl,
    bool? isActive,
    int? sortOrder,
    bool? requiresCard,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconUrl: iconUrl ?? this.iconUrl,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      requiresCard: requiresCard ?? this.requiresCard,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

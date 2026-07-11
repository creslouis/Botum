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
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
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

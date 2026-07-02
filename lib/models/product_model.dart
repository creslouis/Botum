class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final List<String> images;
  final String category; // "Keychains", "Clothing", "Handicraft", "Jewelry"
  final List<String> colors;
  final List<String> sizes;
  final int stock;
  final DateTime createdAt;
  final bool isActive;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.images = const [],
    this.category = 'Handicraft',
    this.colors = const [],
    this.sizes = const [],
    this.stock = 0,
    DateTime? createdAt,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'images': images,
      'category': category,
      'colors': colors,
      'sizes': sizes,
      'stock': stock,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      images: (map['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      category: map['category'] as String? ?? 'Handicraft',
      colors: (map['colors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      sizes: (map['sizes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    List<String>? images,
    String? category,
    List<String>? colors,
    List<String>? sizes,
    int? stock,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      images: images ?? this.images,
      category: category ?? this.category,
      colors: colors ?? this.colors,
      sizes: sizes ?? this.sizes,
      stock: stock ?? this.stock,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

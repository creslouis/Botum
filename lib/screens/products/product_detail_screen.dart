import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';

import '../../models/product_model.dart';
import '../../models/cart_item_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../utils/helpers.dart';
import '../../app/routes.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _currentImageIndex = 0;
  String? _selectedColor;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final cartProvider = context.watch<CartProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final product = productProvider.getProductById(widget.productId);

    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Product not found'),
        ),
      );
    }

    _selectedColor ??= product.colors.isNotEmpty ? product.colors.first : null;
    final isFavorite = favoritesProvider.isFavorite(product.id);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageCarousel(product),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCategoryBadge(product.category),
                          const SizedBox(height: 8),
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            Helpers.formatPrice(product.price),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (product.colors.isNotEmpty) ...[
                            _buildColorSelector(product.colors),
                            const SizedBox(height: 20),
                          ],
                          if (product.sizes.isNotEmpty) ...[
                            _buildSizeInfo(product.sizes),
                            const SizedBox(height: 20),
                          ],
                          _buildDescription(product.description),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomBar(context, product, cartProvider, isFavorite),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(ProductModel product) {
    final images = product.images;
    final hasImages = images.isNotEmpty;

    return Container(
      height: 320,
      color: AppColors.lightGrey,
      child: Stack(
        children: [
          if (hasImages)
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) =>
                  setState(() => _currentImageIndex = index),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final url = images[index];
                if (url.startsWith('http')) {
                  return CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    memCacheWidth: 800,
                    fadeInDuration: const Duration(milliseconds: 300),
                    useOldImageOnUrlChange: true,
                    placeholder: (_, _) => _imagePlaceholder(),
                    errorWidget: (_, _, _) => _imagePlaceholder(),
                  );
                } else if (url.startsWith('assets/')) {
                  return Image.asset(
                    url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, _, _) => _imagePlaceholder(),
                  );
                }
                return _imagePlaceholder();
              },
            )
          else
            _imagePlaceholder(),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                hasImages ? images.length : 1,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == index
                        ? AppColors.primary
                        : AppColors.grey.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: AppColors.lightGrey,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, size: 72, color: AppColors.grey),
            SizedBox(height: 8),
            Text(
              'No image available',
              style: TextStyle(color: AppColors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${Helpers.getCategoryEmoji(category)}  $category',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildColorSelector(List<String> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Color',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: colors.map((color) {
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _parseColor(color),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Text(
          _selectedColor ?? '',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.grey,
          ),
        ),
      ],
    );
  }

  Color _parseColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'red & white':
        return Colors.redAccent;
      case 'blue':
        return Colors.blue;
      case 'blue & white':
        return Colors.blueAccent;
      case 'gold':
        return Colors.amber;
      case 'silver':
        return Colors.grey;
      case 'brown':
        return Colors.brown;
      case 'white':
        return Colors.white;
      case 'black':
        return Colors.black;
      case 'navy':
        return const Color(0xFF000080);
      case 'purple':
        return Colors.purple;
      case 'pink':
        return AppColors.primary;
      case 'green & white':
        return Colors.green;
      case 'natural':
      case 'natural wood':
        return const Color(0xFFD2B48C);
      case 'dark':
      case 'dark wood':
        return const Color(0xFF654321);
      case 'rainbow':
        return Colors.amber;
      case 'red & gold':
        return Colors.redAccent;
      case 'blue & silver':
        return Colors.blueAccent;
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'emerald':
        return const Color(0xFF50C878);
      case 'white pearl':
        return const Color(0xFFFFF8DC);
      case 'golden pearl':
        return const Color(0xFFDAA520);
      case 'dyed pattern':
        return AppColors.primary;
      case 'sandstone':
        return const Color(0xFFC2B280);
      case 'grey stone':
        return Colors.grey;
      default:
        return AppColors.primary.withValues(alpha: 0.3);
    }
  }

  Widget _buildSizeInfo(List<String> sizes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Size',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          sizes.join(' | '),
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.darkGrey,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    ProductModel product,
    CartProvider cartProvider,
    bool isFavorite,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildQuantitySelector(),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                context.read<FavoritesProvider>().toggleFavorite(product);
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
border: Border.all(color: AppColors.grey.withValues(alpha: 0.3)),
                ),
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? AppColors.primary : AppColors.grey,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _addToCart(product, cartProvider);
                  Navigator.pushNamed(context, AppRoutes.checkout);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'BUY NOW',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _addToCart(product, cartProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} added to cart'),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text(
                  'Add to Cart',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_quantity > 1) {
                setState(() => _quantity--);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Minimum quantity is 1'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: const Icon(Icons.remove, size: 18, color: AppColors.black),
            ),
          ),
          Text(
            _quantity.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          GestureDetector(
            onTap: () {
              if (_quantity < 99) {
                setState(() => _quantity++);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Maximum quantity is 99'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: const Icon(Icons.add, size: 18, color: AppColors.black),
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(ProductModel product, CartProvider cartProvider) {
    final item = CartItemModel(
      productId: product.id,
      productName: product.name,
      productImage: product.images.isNotEmpty ? product.images.first : '',
      price: product.price,
      quantity: _quantity,
      selectedColor: _selectedColor,
      selectedSize: product.sizes.isNotEmpty ? product.sizes.first : null,
    );
    cartProvider.addToCart(item);
  }
}

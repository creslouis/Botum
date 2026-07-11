import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/product_model.dart';
import '../../models/cart_item_model.dart';
import '../../widgets/favorite_product_tile.dart';
import '../../app/routes.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Bug fix: moved setUserId from build() to didChangeDependencies() to prevent infinite rebuild loops
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated && !authProvider.isGuest) {
      final uid = authProvider.userModel?.uid;
      if (uid != null) {
        Provider.of<FavoritesProvider>(context, listen: false).setUserId(uid);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final favProvider = context.watch<FavoritesProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Favorites'),
        centerTitle: true,
      ),
      body: favProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : favProvider.favorites.isEmpty
              ? _buildEmptyState(context)
              : _buildFavoritesList(context, favProvider),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 20),
            const Text(
              'No favorites yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start adding your favorite souvenirs!',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(
                    context, AppRoutes.home),
                child: const Text('Browse Products'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(
      BuildContext context, FavoritesProvider favProvider) {
    return RefreshIndicator(
      onRefresh: () async {
        final userId = context.read<AuthProvider>().userModel?.uid;
        if (userId != null) {
          await context.read<FavoritesProvider>().loadFavorites(userId);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: favProvider.favorites.length,
        itemBuilder: (context, index) {
          final product = favProvider.favorites[index];
          return FavoriteProductTile(
            product: product,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.productDetail,
              arguments: product.id,
            ),
            onRemove: () {
              favProvider.removeFavorite(product.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Removed from favorites')),
              );
            },
            onAddToCart: () {
              _addToCart(context, product);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to cart')),
              );
            },
          );
        },
      ),
    );
  }

  void _addToCart(BuildContext context, ProductModel product) {
    final cart = context.read<CartProvider>();
    cart.addToCart(CartItemModel(
      productId: product.id,
      productName: product.name,
      productImage: product.images.isNotEmpty ? product.images.first : '',
      price: product.price,
      quantity: 1,
      selectedColor: product.colors.isNotEmpty ? product.colors.first : null,
      selectedSize: product.sizes.isNotEmpty ? product.sizes.first : null,
    ));
  }
}

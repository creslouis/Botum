import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/category_chip.dart';
import '../../app/routes.dart';
import '../../services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(user),
              const SizedBox(height: 16),
              _buildSearchBar(context),
              const SizedBox(height: 20),
              _buildBanner(context),
              const SizedBox(height: 24),
              _buildSectionTitle('Categories'),
              const SizedBox(height: 12),
              _buildCategoryChips(context, productProvider),
              const SizedBox(height: 24),
              _buildSectionTitle('Popular Souvenirs'),
              const SizedBox(height: 12),
              _buildProductGrid(context, productProvider),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildTopBar(dynamic user) {
    final cartQty = context.watch<CartProvider>().totalQuantity;
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage: user?.photoUrl != null
              ? CachedNetworkImageProvider(user!.photoUrl!)
              : null,
          child: user?.photoUrl == null
              ? const Icon(Icons.person, color: AppColors.primary, size: 26)
              : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.displayName ?? 'Guest',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.grey),
                const SizedBox(width: 4),
                Text(
                  'Phnom Penh, KH',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined,
                  color: AppColors.black),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
            ),
            if (cartQty > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$cartQty',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.products),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.lightGrey,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.grey, size: 20),
            const SizedBox(width: 10),
            Text(
              'Search for more souvenirs',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: FirestoreService().streamBannerSettings(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final enabled = data?['enabled'] ?? true;
        if (!enabled) return const SizedBox.shrink();
        
        final title = data?['title'] ?? 'BEST SOUVENIRS,\nONE TAP AWAY!';
        final buttonText = data?['buttonText'] ?? 'Explore';
        final imageUrl = data?['imageUrl'] as String?;

        return Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.pinkGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 0, 20),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.replaceAll('\\n', '\n'),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.products),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        buttonText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.white.withValues(alpha: 0.15),
                  ),
                  margin: const EdgeInsets.only(right: 16),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: Icon(Icons.card_giftcard, size: 64, color: AppColors.white),
                            ),
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(Icons.card_giftcard, size: 64, color: AppColors.white),
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.card_giftcard,
                            size: 64,
                            color: AppColors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.products),
          child: const Text(
            'See All',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips(BuildContext context, ProductProvider provider) {
    final categories = ['All', ...AppConstants.categories];
    final icons = ['✨', ...AppConstants.categoryIcons];

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = provider.selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: CategoryChip(
              label: category,
              emoji: icons[index],
              isSelected: isSelected,
              onTap: () {
                if (category == 'All') {
                  provider.setCategory('All');
                  Navigator.pushNamed(context, AppRoutes.products);
                } else {
                  provider.setCategory(category);
                  Navigator.pushNamed(context, AppRoutes.products);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, ProductProvider provider) {
    final displayed = provider.products.take(4).toList();

    if (provider.isLoading) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (displayed.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'No products available yet.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: displayed.length,
      itemBuilder: (context, index) {
        final product = displayed[index];
        return ProductCard(
          product: product,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.productDetail,
            arguments: product.id,
          ),
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
      onTap: (index) {
        if (index == 0) {
          setState(() => _currentNavIndex = 0);
          return;
        }
        setState(() => _currentNavIndex = index);
        switch (index) {
          case 1:
            Navigator.pushNamed(context, AppRoutes.products).then((_) {
              if (mounted) setState(() => _currentNavIndex = 0);
            });
            break;
          case 2:
            Navigator.pushNamed(context, AppRoutes.favorites).then((_) {
              if (mounted) setState(() => _currentNavIndex = 0);
            });
            break;
          case 3:
            Navigator.pushNamed(context, AppRoutes.profile).then((_) {
              if (mounted) setState(() => _currentNavIndex = 0);
            });
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          activeIcon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_outline),
          activeIcon: Icon(Icons.favorite),
          label: 'Favorites',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

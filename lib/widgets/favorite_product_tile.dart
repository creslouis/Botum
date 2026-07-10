import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/constants/app_constants.dart';
import '../utils/helpers.dart';
import '../models/product_model.dart';

class FavoriteProductTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onRemove;
  final VoidCallback? onAddToCart;
  final VoidCallback? onTap;

  const FavoriteProductTile({
    super.key,
    required this.product,
    this.onRemove,
    this.onAddToCart,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(AppConstants.cardRadius),
              ),
              child: SizedBox(
                width: 100,
                height: 100,
                child: _buildImage(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category,
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      Helpers.formatPrice(product.price),
                      style: AppTextStyles.priceSmall,
                    ),
                  ],
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.favorite, color: AppColors.primary),
                  tooltip: 'Remove from favorites',
                ),
                if (onAddToCart != null)
                  IconButton(
                    onPressed: onAddToCart,
                    icon: const Icon(Icons.add_shopping_cart_outlined,
                        color: AppColors.darkGrey),
                    tooltip: 'Add to cart',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (product.images.isNotEmpty) {
      final url = product.images.first;
      if (url.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          memCacheWidth: 200,
          fadeInDuration: const Duration(milliseconds: 300),
          useOldImageOnUrlChange: true,
          placeholder: (_, _) => _placeholder(),
          errorWidget: (_, _, _) => _placeholder(),
        );
      }
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.lightGrey,
      child: const Center(
        child: Icon(Icons.image_outlined, size: 30, color: AppColors.grey),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/cart_item_model.dart';
import '../utils/helpers.dart';

class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final CartItemModel item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0D7E6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductImage(imageUrl: item.productImage),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if ((item.selectedColor ?? '').isNotEmpty)
                      'Color: ${item.selectedColor}',
                    if ((item.selectedSize ?? '').isNotEmpty)
                      'Size: ${item.selectedSize}',
                  ].join('  |  '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _QuantityButton(
                      icon: Icons.remove,
                      onTap: () => onQuantityChanged(item.quantity - 1),
                    ),
                    Container(
                      width: 42,
                      alignment: Alignment.center,
                      child: Text(
                        item.quantity.toString().padLeft(2, '0'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _QuantityButton(
                      icon: Icons.add,
                      onTap: () => onQuantityChanged(item.quantity + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
              const SizedBox(height: 18),
              Text(
                '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          color: const Color(0xFFEEC7D9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
      );
    }

    final normalizedImageUrl = Helpers.normalizeImageUrl(imageUrl);

    if (Helpers.isRemoteImageUrl(normalizedImageUrl)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: normalizedImageUrl,
          width: 74,
          height: 74,
          fit: BoxFit.cover,
          memCacheWidth: 148,
          placeholder: (context, url) => Container(
            width: 74,
            height: 74,
            color: const Color(0xFFEEC7D9),
            child: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
          ),
          errorWidget: (context, url, error) => Container(
            width: 74,
            height: 74,
            color: const Color(0xFFEEC7D9),
            child: const Icon(Icons.image_not_supported_outlined),
          ),
        ),
      );
    }

    if (Helpers.isAssetImagePath(normalizedImageUrl)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          normalizedImageUrl,
          width: 74,
          height: 74,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 74,
            height: 74,
            color: const Color(0xFFEEC7D9),
            child: const Icon(Icons.image_not_supported_outlined),
          ),
        ),
      );
    }

    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        color: const Color(0xFFEEC7D9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE91E8C)),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFFE91E8C)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../models/product_model.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';

class AdminProductManagementScreen extends StatefulWidget {
  final String? editProductId;

  const AdminProductManagementScreen({super.key, this.editProductId});

  @override
  State<AdminProductManagementScreen> createState() =>
      _AdminProductManagementScreenState();
}

class _AdminProductManagementScreenState
    extends State<AdminProductManagementScreen> {
  final _firestore = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(child: Text('Admin access required')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Product Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined),
            tooltip: 'Seed mock products to Firestore',
            onPressed: () => _seedProducts(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showProductDialog(),
          ),
        ],
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: _firestore.getAllProductsForAdmin(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data!;
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2, size: 64, color: AppColors.grey),
                  const SizedBox(height: 16),
                  Text('No products yet', style: AppTextStyles.headingSmall),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showProductDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _ProductListItem(
                product: product,
                onEdit: () => _showProductDialog(product: product),
                onDelete: () => _confirmDelete(product),
              );
            },
          );
        },
      ),
    );
  }

  void _showProductDialog({ProductModel? product}) {
    final isEditing = product != null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ProductForm(
        product: product,
        onSave: (data) async {
          if (isEditing) {
            await _firestore.updateProduct(product.id, data);
          } else {
            await _firestore.addProduct(ProductModel.fromMap(data));
          }
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  void _confirmDelete(ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _firestore.deleteProduct(product.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _seedProducts() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Seed Products'),
        content: const Text(
          'This will upload all built-in mock products to Firestore. '
          'Existing products will NOT be overwritten. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Seed Now'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seeding products...')),
    );

    final provider = ProductProvider();
    // Access mock products by calling fetchProducts first
    await provider.fetchProducts();
    final mockProducts = provider.allProducts;

    final count = await _firestore.seedProducts(mockProducts);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$count new products seeded to Firestore!')),
    );
  }
}

class _ProductListItem extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductListItem({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 64,
                height: 64,
                child: product.images.isNotEmpty
                    ? _buildProductImage(product.images.first)
                    : Container(
                        color: AppColors.lightGrey,
                        child: const Icon(Icons.image, color: AppColors.grey),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: AppTextStyles.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: AppTextStyles.priceSmall,
                  ),
                  Text(
                    'Stock: ${product.stock} | ${product.category}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: onEdit),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: AppColors.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String url) {
    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        memCacheWidth: 128,
        fadeInDuration: const Duration(milliseconds: 300),
        placeholder: (_, _) => Container(
          color: AppColors.lightGrey,
          child: const Icon(Icons.image, color: AppColors.grey),
        ),
        errorWidget: (_, _, _) => Container(
          color: AppColors.lightGrey,
          child: const Icon(Icons.broken_image, color: AppColors.grey),
        ),
      );
    } else if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: AppColors.lightGrey,
          child: const Icon(Icons.broken_image, color: AppColors.grey),
        ),
      );
    }
    return Container(
      color: AppColors.lightGrey,
      child: const Icon(Icons.image, color: AppColors.grey),
    );
  }
}

class _ProductForm extends StatefulWidget {
  final ProductModel? product;
  final Function(Map<String, dynamic>) onSave;

  const _ProductForm({this.product, required this.onSave});

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late String _category;
  late List<String> _colors;
  late List<String> _sizes;
  final TextEditingController _imageUrlCtrl = TextEditingController();
  late List<String> _imageUrls;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl = TextEditingController(
        text: p != null ? p.price.toString() : '');
    _stockCtrl = TextEditingController(
        text: p != null ? p.stock.toString() : '');
    _category = AppConstants.categories.contains(p?.category) 
        ? p!.category 
        : AppConstants.categories.first;
    _colors = List.from(p?.colors ?? []);
    _sizes = List.from(p?.sizes ?? []);
    _imageUrls = List.from(p?.images ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.product != null ? 'Edit Product' : 'Add Product',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      decoration: const InputDecoration(labelText: 'Stock'),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: AppConstants.categories.map((c) {
                  return DropdownMenuItem<String>(value: c, child: Text(c));
                }).toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Colors (comma separated)',
                ),
                initialValue: _colors.join(', '),
                onChanged: (v) {
                  _colors = v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Sizes (comma separated)',
                ),
                initialValue: _sizes.join(', '),
                onChanged: (v) {
                  _sizes = v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _imageUrlCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Paste image URL',
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      final url = _imageUrlCtrl.text.trim();
                      if (url.isNotEmpty) {
                        setState(() {
                          _imageUrls.add(url);
                          _imageUrlCtrl.clear();
                        });
                      }
                    },
                    icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  ),
                ],
              ),
              if (_imageUrls.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imageUrls.length,
                    separatorBuilder: (_, _)=> const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: _imageUrls[index],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => Container(
                                width: 80,
                                height: 80,
                                color: AppColors.lightGrey,
                                child: const Icon(Icons.broken_image, color: AppColors.grey),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => setState(() => _imageUrls.removeAt(index)),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(2),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Save Product'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final productId = widget.product?.id ??
        FirebaseFirestore.instance
            .collection(AppConstants.collectionProducts)
            .doc()
            .id;

    final data = <String, dynamic>{
      'id': productId,
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'price': double.tryParse(_priceCtrl.text.trim()) ?? 0,
      'category': _category,
      'colors': _colors,
      'sizes': _sizes,
      'stock': int.tryParse(_stockCtrl.text.trim()) ?? 0,
      'images': _imageUrls,
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
    };

    widget.onSave(data);
  }
}

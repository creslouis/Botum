import 'package:flutter/material.dart';

// Placeholder — Thebdey will implement this.

class ProductDetailScreen extends StatelessWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Detail')),
      body: Center(
        child: Text('Product Detail — Thebdey (ID: $productId)'),
      ),
    );
  }
}

import 'package:flutter/material.dart';

// Placeholder — Hokdo will implement this.

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;

  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Success')),
      body: Center(
        child: Text('Order Placed! ID: ${orderId.substring(0, 8)}...'),
      ),
    );
  }
}

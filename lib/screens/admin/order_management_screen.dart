import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/order_model.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/helpers.dart';

class AdminOrderManagementScreen extends StatelessWidget {
  const AdminOrderManagementScreen({super.key});

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
      appBar: AppBar(title: const Text('Order Management')),
      body: StreamBuilder<List<OrderModel>>(
        stream: FirestoreService().getAllOrders(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long, size: 64, color: AppColors.grey),
                  const SizedBox(height: 16),
                  Text('No orders yet', style: AppTextStyles.headingSmall),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderCard(order: order);
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: CircleAvatar(
          backgroundColor: _statusColor.withValues(alpha: 0.2),
          child: Text(
            order.itemCount.toString(),
            style: TextStyle(
              color: _statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          'Order ${Helpers.shortenOrderId(order.orderId)}',
          style: AppTextStyles.bodyLarge,
        ),
        subtitle: Text(
          '${Helpers.formatDate(order.createdAt)} • \$${order.totalPrice.toStringAsFixed(2)}',
          style: AppTextStyles.caption,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            order.status.toUpperCase(),
            style: TextStyle(
              color: _statusColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                Text('Customer: ${order.shippingInfo.fullName}'),
                Text('Phone: ${order.shippingInfo.phone}'),
                Text('Address: ${order.shippingInfo.street}, ${order.shippingInfo.city}'),
                Text('Payment: ${order.paymentMethod}'),
                const SizedBox(height: 8),
                const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text('${item.productName} x${item.quantity} - \$${item.totalPrice.toStringAsFixed(2)}'),
                )),
                const SizedBox(height: 12),
                const Text('Update Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['pending', 'confirmed', 'shipped', 'delivered'].map((status) {
                    final isActive = order.status == status;
                    return ActionChip(
                      label: Text(status),
                      backgroundColor: isActive ? _getStatusColor(status) : null,
                      labelStyle: TextStyle(
                        color: isActive ? Colors.white : null,
                      ),
                      onPressed: () async {
                        await FirestoreService()
                            .updateOrderStatus(order.orderId, status);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color get _statusColor => _getStatusColor(order.status);

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF57C00);
      case 'confirmed':
        return const Color(0xFF1976D2);
      case 'shipped':
        return const Color(0xFFE91E8C);
      case 'delivered':
        return const Color(0xFF388E3C);
      default:
        return AppColors.grey;
    }
  }
}

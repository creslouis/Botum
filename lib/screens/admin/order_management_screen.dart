import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../models/order_model.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/helpers.dart';

class AdminOrderManagementScreen extends StatefulWidget {
  const AdminOrderManagementScreen({super.key});

  @override
  State<AdminOrderManagementScreen> createState() =>
      _AdminOrderManagementScreenState();
}

class _AdminOrderManagementScreenState
    extends State<AdminOrderManagementScreen> {
  String _filterStatus = 'all';
  DateTime? _filterDate;

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
        title: const Text(
          'Orders',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: FirestoreService().getAllOrders(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final allOrders = snapshot.data!;
          if (allOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: AppColors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text('No orders yet', style: AppTextStyles.headingSmall),
                ],
              ),
            );
          }

          // Calculate stats
          final totalRevenue = allOrders.fold<double>(
            0,
            (sum, o) => sum + o.totalPrice,
          );
          final pendingCount = allOrders
              .where((o) => o.status == 'pending')
              .length;
          final deliveredCount = allOrders
              .where((o) => o.status == 'delivered')
              .length;

          // Filter by status
          final statusFiltered = _filterStatus == 'all'
              ? allOrders
              : allOrders.where((o) => o.status == _filterStatus).toList();

          // Filter by date
          final orders = _filterDate == null
              ? statusFiltered
              : statusFiltered.where((o) {
                  final orderDate = DateTime(
                    o.createdAt.year,
                    o.createdAt.month,
                    o.createdAt.day,
                  );
                  final filterDate = DateTime(
                    _filterDate!.year,
                    _filterDate!.month,
                    _filterDate!.day,
                  );
                  return orderDate.isAtSameMomentAs(filterDate);
                }).toList();

          return Column(
            children: [
              // Revenue stats bar
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF283593)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A237E).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MiniStat(
                      label: 'Revenue',
                      value: '\$${totalRevenue.toStringAsFixed(2)}',
                      icon: Icons.attach_money,
                    ),
                    Container(width: 1, height: 40, color: Colors.white24),
                    _MiniStat(
                      label: 'Pending',
                      value: pendingCount.toString(),
                      icon: Icons.hourglass_top,
                    ),
                    Container(width: 1, height: 40, color: Colors.white24),
                    _MiniStat(
                      label: 'Delivered',
                      value: deliveredCount.toString(),
                      icon: Icons.check_circle_outline,
                    ),
                  ],
                ),
              ),

              // Filter controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Status dropdown
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _filterStatus,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down),
                            style: const TextStyle(
                              color: AppColors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            items: [
                              'all',
                              'pending',
                              'confirmed',
                              'shipped',
                              'delivered',
                            ].map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(
                                  status == 'all'
                                      ? 'All Status'
                                      : status[0].toUpperCase() +
                                          status.substring(1),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _filterStatus = value);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_filterStatus != 'all')
                      GestureDetector(
                        onTap: () =>
                            setState(() => _filterStatus = 'all'),
                        child: Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: const Icon(
                            Icons.clear,
                            size: 18,
                            color: AppColors.grey,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    // Date filter
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _filterDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _filterDate = picked);
                          }
                        },
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _filterDate != null
                                  ? AppColors.primary
                                  : const Color(0xFFE0E0E0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: _filterDate != null
                                    ? AppColors.primary
                                    : AppColors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _filterDate != null
                                      ? Helpers.formatDate(_filterDate!)
                                      : 'Pick date',
                                  style: TextStyle(
                                    color: _filterDate != null
                                        ? AppColors.black
                                        : AppColors.grey,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_filterDate != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _filterDate = null),
                        child: Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: const Icon(
                            Icons.clear,
                            size: 18,
                            color: AppColors.grey,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Order list
              Expanded(
                child: orders.isEmpty
                    ? Center(
                        child: Text(
                          'No${_filterStatus == 'all' ? '' : ' $_filterStatus'} orders${_filterDate != null ? ' on ${Helpers.formatDate(_filterDate!)}' : ''}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: orders.length,
                        itemBuilder: (context, index) =>
                            _OrderCard(order: orders[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final isGuest = order.userId.startsWith('guest-');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                order.itemCount.toString(),
                style: TextStyle(
                  color: _statusColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  Helpers.shortenOrderId(order.orderId),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              if (isGuest)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Guest',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Row(
            children: [
              Text(
                Helpers.formatDate(order.createdAt),
                style: const TextStyle(fontSize: 12, color: AppColors.grey),
              ),
              const SizedBox(width: 8),
              Text(
                '\$${order.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              order.status.toUpperCase(),
              style: TextStyle(
                color: _statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            _infoRow(
              Icons.person_outline,
              'Customer',
              order.shippingInfo.fullName,
            ),
            _infoRow(Icons.phone_outlined, 'Phone', order.shippingInfo.phone),
            _infoRow(
              Icons.location_on_outlined,
              'Address',
              '${order.shippingInfo.street}, ${order.shippingInfo.city}',
            ),
            _infoRow(Icons.payment_outlined, 'Payment', order.paymentMethod),
            const SizedBox(height: 12),
            const Text(
              'Items',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: item.productImage.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: item.productImage,
                                fit: BoxFit.cover,
                              )
                            : item.productImage.startsWith('assets/')
                            ? Image.asset(
                                item.productImage,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image, size: 18),
                              )
                            : const Icon(Icons.image, size: 18),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.productName,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'x${item.quantity}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${item.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Update Status',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.orderStatuses.map((status) {
                final isActive = order.status == status;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      await FirestoreService().updateOrderStatus(
                        order.orderId,
                        status,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? _getStatusColor(status)
                            : Colors.transparent,
                        border: Border.all(color: _getStatusColor(status)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status[0].toUpperCase() + status.substring(1),
                        style: TextStyle(
                          color: isActive
                              ? Colors.white
                              : _getStatusColor(status),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.grey),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

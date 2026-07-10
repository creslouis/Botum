import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../app/routes.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text('You do not have admin access.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick stats
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.primary,
            child: Column(
              children: [
                Text(
                  'Welcome, ${auth.userModel?.displayName ?? 'Admin'}',
                  style: AppTextStyles.headingMedium.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatCard(
                      icon: Icons.inventory_2,
                      label: 'Products',
                      stream: FirebaseFirestore.instance
                          .collection('products')
                          .snapshots()
                          .map((s) => s.docs.length.toString()),
                    ),
                    _StatCard(
                      icon: Icons.shopping_cart,
                      label: 'Orders',
                      stream: FirebaseFirestore.instance
                          .collection('orders')
                          .snapshots()
                          .map((s) => s.docs.length.toString()),
                    ),
                    _StatCard(
                      icon: Icons.people,
                      label: 'Users',
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .snapshots()
                          .map((s) => s.docs.length.toString()),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Menu options
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _AdminMenuItem(
                    icon: Icons.inventory_2,
                    title: 'Product Management',
                    subtitle: 'Add, edit, or delete products',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.adminProducts);
                    },
                  ),
                  const SizedBox(height: 12),
                  _AdminMenuItem(
                    icon: Icons.receipt_long,
                    title: 'Order Management',
                    subtitle: 'View and update order status',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.adminOrders);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Stream<String> stream;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: stream,
      builder: (context, snapshot) {
        return Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              snapshot.data ?? '...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        );
      },
    );
  }
}

class _AdminMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryWithOpacity,
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: AppTextStyles.headingSmall),
        subtitle: Text(subtitle, style: AppTextStyles.caption),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

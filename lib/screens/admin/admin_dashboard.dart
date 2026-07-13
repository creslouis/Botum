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
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            tooltip: 'Log Out',
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            // Welcome Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFFC2185B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auth.userModel?.displayName ?? 'Administrator',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatCard(
                        icon: Icons.inventory_2_outlined,
                        label: 'Products',
                        stream: FirebaseFirestore.instance.collection('products').snapshots().map((s) => s.docs.length.toString()),
                      ),
                      _StatCard(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Orders',
                        stream: FirebaseFirestore.instance.collection('orders').snapshots().map((s) => s.docs.length.toString()),
                      ),
                      _StatCard(
                        icon: Icons.people_outline,
                        label: 'Users',
                        stream: FirebaseFirestore.instance.collection('users').snapshots().map((s) => s.docs.length.toString()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Management',
              style: AppTextStyles.headingSmall.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            
            _AdminMenuItem(
              icon: Icons.inventory_2_outlined,
              title: 'Products',
              subtitle: 'Add, edit, or remove inventory',
              iconColor: const Color(0xFF4A148C),
              backgroundColor: const Color(0xFFF3E5F5),
              onTap: () => Navigator.pushNamed(context, AppRoutes.adminProducts),
            ),
            _AdminMenuItem(
              icon: Icons.receipt_long_outlined,
              title: 'Orders',
              subtitle: 'Track and fulfill customer orders',
              iconColor: const Color(0xFF004D40),
              backgroundColor: const Color(0xFFE0F2F1),
              onTap: () => Navigator.pushNamed(context, AppRoutes.adminOrders),
            ),
            _AdminMenuItem(
              icon: Icons.payment_outlined,
              title: 'Payment Methods',
              subtitle: 'Configure checkout options & icons',
              iconColor: const Color(0xFFE65100),
              backgroundColor: const Color(0xFFFFF3E0),
              onTap: () => Navigator.pushNamed(context, AppRoutes.adminPaymentMethods),
            ),
            _AdminMenuItem(
              icon: Icons.settings_outlined,
              title: 'App Settings',
              subtitle: 'Store info & maintenance mode',
              iconColor: const Color(0xFF37474F),
              backgroundColor: const Color(0xFFECEFF1),
              onTap: () => Navigator.pushNamed(context, AppRoutes.adminSettings),
            ),
            const SizedBox(height: 24),
          ],
        ),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              snapshot.data ?? '-',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
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
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _AdminMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

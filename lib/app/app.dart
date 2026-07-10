import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../screens/welcome/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/products/product_list_screen.dart';
import '../screens/products/product_detail_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/checkout/order_success_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/order_history_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/product_management_screen.dart';
import '../screens/admin/order_management_screen.dart';
import 'routes.dart';

class BotumApp extends StatelessWidget {
  const BotumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Botum',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.welcome,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned.fill(
              child: Container(color: Colors.white),
            ),
            Positioned.fill(
              child: Image.asset(
                'assets/images/background_pattern.png',
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(0.80),
              ),
            ),
            child!,
          ],
        );
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.welcome:
            return MaterialPageRoute(
              builder: (_) => const WelcomeScreen(),
            );
          case AppRoutes.login:
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            );
          case AppRoutes.register:
            return MaterialPageRoute(
              builder: (_) => const RegisterScreen(),
            );
          case AppRoutes.home:
            return MaterialPageRoute(
              builder: (_) => const HomeScreen(),
            );
          case AppRoutes.products:
            return MaterialPageRoute(
              builder: (_) => const ProductListScreen(),
            );
          case AppRoutes.productDetail:
            final productId = settings.arguments as String?;
            return MaterialPageRoute(
              builder: (_) => ProductDetailScreen(productId: productId ?? ''),
            );
          case AppRoutes.cart:
            return MaterialPageRoute(
              builder: (_) => const CartScreen(),
            );
          case AppRoutes.checkout:
            return MaterialPageRoute(
              builder: (_) => const CheckoutScreen(),
            );
          case AppRoutes.orderSuccess:
            final orderId = settings.arguments as String?;
            return MaterialPageRoute(
              builder: (_) => OrderSuccessScreen(orderId: orderId ?? ''),
            );
          case AppRoutes.favorites:
            return MaterialPageRoute(
              builder: (_) => const FavoritesScreen(),
            );
          case AppRoutes.profile:
            return MaterialPageRoute(
              builder: (_) => const ProfileScreen(),
            );
          case AppRoutes.orderHistory:
            return MaterialPageRoute(
              builder: (_) => const OrderHistoryScreen(),
            );
          case AppRoutes.adminDashboard:
            return MaterialPageRoute(
              builder: (_) => const AdminDashboard(),
            );
          case AppRoutes.adminProducts:
            return MaterialPageRoute(
              builder: (_) => const AdminProductManagementScreen(),
            );
          case AppRoutes.adminOrders:
            return MaterialPageRoute(
              builder: (_) => const AdminOrderManagementScreen(),
            );
          case AppRoutes.adminAddProduct:
            return MaterialPageRoute(
              builder: (_) => const AdminProductManagementScreen(),
            );
          case AppRoutes.adminEditProduct:
            final productId = settings.arguments as String?;
            return MaterialPageRoute(
              builder: (_) => AdminProductManagementScreen(
                editProductId: productId,
              ),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const WelcomeScreen(),
            );
        }
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/cart_provider.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/checkout/checkout_screen.dart';
import 'screens/checkout/order_success_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFE91E8C),
        primary: const Color(0xFFE91E8C),
      ),
      scaffoldBackgroundColor: const Color(0xFFFDF7FA),
      useMaterial3: true,
    );

    return ChangeNotifierProvider(
      create: (_) => CartProvider()..loadCart(),
      child: MaterialApp(
        title: 'Botum',
        debugShowCheckedModeBanner: false,
        theme: baseTheme.copyWith(
          textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            foregroundColor: Colors.black,
          ),
        ),
        routes: {
          '/': (_) => const CartScreen(),
          CheckoutScreen.routeName: (_) => const CheckoutScreen(),
          OrderSuccessScreen.routeName: (_) => const OrderSuccessScreen(),
        },
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as app;
import 'providers/cart_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/product_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  try {
    await GoogleSignIn.instance.initialize();
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'main',
        context: ErrorDescription('while initializing Google Sign-In'),
      ),
    );

    if (kDebugMode) {
      debugPrint('Google Sign-In initialization failed: $error');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app.AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()..loadCart()),
        ChangeNotifierProvider(
          create: (context) {
            final provider = FavoritesProvider();
            provider.initAuthListener(
              FirebaseAuth.instance.authStateChanges(),
            );
            return provider;
          },
        ),
      ],
      child: const BotumApp(),
    ),
  );
}

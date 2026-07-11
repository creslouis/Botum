import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../app/routes.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().registerWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            displayName: _nameController.text.trim(),
          );
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().signInWithGoogle();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } on AccountCollisionException catch (e) {
      if (mounted) {
        await _showCollisionDialog(e);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _facebookSignIn() async {
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().signInWithFacebook();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } on AccountCollisionException catch (e) {
      if (mounted) {
        await _showCollisionDialog(e);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCollisionDialog(AccountCollisionException collision) async {
    final auth = context.read<AuthProvider>();

    Future<void> handleProviderChoice(String providerId) async {
      Navigator.of(context).pop();
      setState(() => _isLoading = true);
      try {
        if (providerId == 'password') {
          await _showPasswordLinkDialog(collision);
          return;
        }

        await auth.resolveCollisionWithProvider(
          providerId: providerId,
          pendingCredential: collision.pendingCredential,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Signed in with ${auth.providerLabel(providerId)} and linked your new social account.',
            ),
          ),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Account Already Exists'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                collision.email.isEmpty
                    ? 'This social account matches an existing Botum account.'
                    : 'The email ${collision.email} is already used in Botum.',
              ),
              const SizedBox(height: 12),
              const Text('Sign in with the existing method below to link this social account:'),
              const SizedBox(height: 12),
              for (final providerId in collision.existingProviders)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => handleProviderChoice(providerId),
                      child: Text(auth.providerLabel(providerId)),
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPasswordLinkDialog(AccountCollisionException collision) async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final auth = context.read<AuthProvider>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Use Existing Password'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter your existing password';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(dialogContext).pop();
                try {
                  await auth.resolveCollisionWithEmail(
                    email: collision.email,
                    password: passwordController.text,
                    pendingCredential: collision.pendingCredential,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Signed in with email and linked your social account.',
                      ),
                    ),
                  );
                  Navigator.pushReplacementNamed(context, AppRoutes.home);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceAll('Exception: ', ''),
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('Sign In and Link'),
            ),
          ],
        );
      },
    );

    passwordController.dispose();
  }

  Future<void> _guestSignIn() async {
    setState(() => _isLoading = true);
    try {
      await context.read<AuthProvider>().signInAsGuest();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
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
          SafeArea(
            child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                // Logo
                Text(
                  'Botum',
                  style: AppTextStyles.logo,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign up',
                  style: AppTextStyles.headingMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Username field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Username',
                    hintStyle: TextStyle(color: AppColors.grey),
                    prefixIcon: const Icon(Icons.person_outlined, color: AppColors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: AppColors.primary),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(color: AppColors.grey),
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: AppColors.primary),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Phone field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Phone number',
                    hintStyle: TextStyle(color: AppColors.grey),
                    prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(color: AppColors.grey),
                    prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.grey,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  style: const TextStyle(color: AppColors.primary),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Confirm password field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    hintText: 'Confirm password',
                    hintStyle: TextStyle(color: AppColors.grey),
                    prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.grey,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                  ),
                  style: const TextStyle(color: AppColors.primary),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Register button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Create an account',
                            style: AppTextStyles.button,
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.grey)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or continue with',
                        style: AppTextStyles.caption,
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.grey)),
                  ],
                ),
                const SizedBox(height: 24),
                // Google
                _SocialButton(
                  icon: FontAwesomeIcons.google,
                  label: 'Continue with Google',
                  onPressed: _googleSignIn,
                ),
                const SizedBox(height: 12),
                // Facebook
                _SocialButton(
                  icon: FontAwesomeIcons.facebook,
                  label: 'Continue with Facebook',
                  backgroundColor: const Color(0xFF1877F2),
                  onPressed: _facebookSignIn,
                ),
                const SizedBox(height: 24),
                // Guest option
                TextButton(
                  onPressed: _guestSignIn,
                  child: Text(
                    'Continue as a Guest',
                    style: AppTextStyles.link,
                  ),
                ),
                const SizedBox(height: 24),
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTextStyles.caption,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(
                            context, AppRoutes.login);
                      },
                      child: Text(
                        'Log in',
                        style: AppTextStyles.link,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      ],
    ),
  );
  }
}

class _SocialButton extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: FaIcon(icon, color: Colors.white, size: 20),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.darkGrey,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildHeader(context, authProvider),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Account',
            children: [
              _buildConnectionRow(context, authProvider, 'google.com', Icons.g_mobiledata_rounded),
              _buildConnectionRow(context, authProvider, 'facebook.com', Icons.facebook),
              _buildConnectionRow(context, authProvider, 'telegram', Icons.send),
              _buildPasswordRow(context, authProvider),
              if (!authProvider.isGuest)
                _buildPhotoRow(context, authProvider),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Shopping',
            children: [
              _menuTile(
                icon: Icons.inventory_2_outlined,
                title: 'My Orders',
                onTap: authProvider.isGuest
                    ? () => _showGuestOnlyMessage(context)
                    : () => Navigator.pushNamed(context, AppRoutes.orderHistory),
              ),
              _menuTile(
                icon: Icons.favorite_outline,
                title: 'My Favorites',
                onTap: authProvider.isGuest
                    ? () => _showGuestOnlyMessage(context)
                    : () => Navigator.pushNamed(context, AppRoutes.favorites),
              ),
              _menuTile(
                icon: Icons.location_on_outlined,
                title: 'Shipping Address',
                subtitle: 'Manage delivery details',
                onTap: () => _showShippingDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Settings',
            children: [
              _menuTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) => setState(() => _notificationsEnabled = value),
                  activeThumbColor: AppColors.primary,
                ),
              ),
              _menuTile(
                icon: Icons.language_outlined,
                title: 'Language',
                subtitle: 'English',
                onTap: () => _showLanguageDialog(context),
              ),
              _menuTile(
                icon: Icons.info_outline,
                title: 'About Botum',
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Session',
            children: [
              _menuTile(
                icon: Icons.logout,
                title: 'Log Out',
                iconColor: AppColors.error,
                textColor: AppColors.error,
                showChevron: false,
                onTap: () => _confirmLogout(context),
              ),
            ],
          ),
          if (user != null && user.providers.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Signed in with: ${user.providers.map(authProvider.providerLabel).join(', ')}',
                style: AppTextStyles.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.userModel;
    final displayName = user?.displayName.isNotEmpty == true ? user!.displayName : 'User';
    final email = user?.email.isNotEmpty == true ? user!.email : 'Guest account';
    final hasPhoto = user?.photoUrl?.isNotEmpty == true;

    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 46,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: hasPhoto ? NetworkImage(user!.photoUrl!) : null,
              child: hasPhoto
                  ? null
                  : Text(
                      displayName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: InkWell(
                onTap: authProvider.photoSources.isEmpty
                    ? null
                    : () => _showPhotoSourcePicker(context, authProvider),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: authProvider.photoSources.isEmpty
                        ? AppColors.grey
                        : AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(displayName, style: AppTextStyles.headingSmall.copyWith(fontSize: 24)),
        const SizedBox(height: 4),
        Text(email, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey)),
      ],
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: AppTextStyles.headingSmall.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildConnectionRow(
    BuildContext context,
    AuthProvider authProvider,
    String providerId,
    IconData icon,
  ) {
    final connection = authProvider.socialConnections.firstWhere(
      (item) => item.providerId == providerId,
    );

    String subtitle;
    if (!connection.isAvailable) {
      subtitle = 'Coming soon';
    } else if (connection.isConnected) {
      subtitle = connection.email ?? 'Connected';
    } else {
      subtitle = 'Not connected';
    }

    final trailing = !connection.isAvailable
        ? Text('Soon', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey))
        : TextButton(
            onPressed: authProvider.isGuest
                ? null
                : () => connection.isConnected
                    ? _disconnectProvider(context, providerId)
                    : _connectProvider(context, providerId),
            child: Text(connection.isConnected ? 'Disconnect' : 'Connect'),
          );

    return _menuTile(
      icon: icon,
      title: connection.label,
      subtitle: subtitle,
      trailing: trailing,
      showChevron: false,
    );
  }

  Widget _buildPasswordRow(BuildContext context, AuthProvider authProvider) {
    return _menuTile(
      icon: Icons.lock_outline,
      title: authProvider.hasPasswordProvider ? 'App Password' : 'Set Password',
      subtitle: authProvider.hasPasswordProvider
          ? 'Send a reset email'
          : 'Add a Botum password for this social account',
      trailing: TextButton(
        onPressed: authProvider.isGuest
            ? null
            : () => authProvider.hasPasswordProvider
                ? _sendPasswordReset(context)
                : _showSetPasswordDialog(context),
        child: Text(authProvider.hasPasswordProvider ? 'Reset' : 'Set'),
      ),
      showChevron: false,
    );
  }

  Widget _buildPhotoRow(BuildContext context, AuthProvider authProvider) {
    return _menuTile(
      icon: Icons.photo_camera_outlined,
      title: 'Profile Photo Source',
      subtitle: authProvider.photoSources.isEmpty
          ? 'Link Google or Facebook to import a profile photo'
          : 'Choose from linked social accounts',
      onTap: authProvider.photoSources.isEmpty
          ? null
          : () => _showPhotoSourcePicker(context, authProvider),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? iconColor,
    Color? textColor,
    bool showChevron = true,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: iconColor ?? AppColors.primary),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.black,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: AppTextStyles.bodySmall)
          : null,
      trailing: trailing ??
          (showChevron ? const Icon(Icons.chevron_right, color: AppColors.grey) : null),
      onTap: onTap,
    );
  }

  Future<void> _connectProvider(BuildContext context, String providerId) async {
    final authProvider = context.read<AuthProvider>();
    try {
      await authProvider.linkProvider(providerId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${authProvider.providerLabel(providerId)} connected successfully.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _disconnectProvider(BuildContext context, String providerId) async {
    final authProvider = context.read<AuthProvider>();
    try {
      await authProvider.unlinkProvider(providerId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${authProvider.providerLabel(providerId)} disconnected.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showSetPasswordDialog(BuildContext context) async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final messenger = ScaffoldMessenger.of(context);
    final authProvider = context.read<AuthProvider>();

    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Set Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Use at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm password'),
                validator: (value) {
                  if (value != passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext, passwordController.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    passwordController.dispose();
    confirmController.dispose();

    if (password == null || password.isEmpty) {
      return;
    }

    try {
      await authProvider.setPassword(password);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Password added to your Botum account.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _sendPasswordReset(BuildContext context) async {
    try {
      await context.read<AuthProvider>().sendPasswordSetupEmail();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showPhotoSourcePicker(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(title: Text('Choose Profile Photo')),
              for (final source in authProvider.photoSources)
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(source.photoUrl!),
                  ),
                  title: Text(source.label),
                  subtitle: Text(source.email ?? 'Linked account'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    try {
                      await authProvider.chooseProfilePhoto(source.photoUrl!);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Profile photo updated from ${source.label}.'),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString().replaceAll('Exception: ', '')),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showGuestOnlyMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sign in to use this section. Guest accounts can only browse.'),
      ),
    );
  }

  void _showShippingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Shipping Address'),
        content: const Text('Shipping address management coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              trailing: const Icon(Icons.check, color: AppColors.primary),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              title: const Text('Khmer'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About Botum'),
        content: const Text(
          'Botum is an Authentic Khmer Handmade Souvenir e-commerce app. '
          'We connect you with skilled Cambodian artisans to bring traditional '
          'craftsmanship right to your doorstep.\n\n'
          'Version 1.0.0',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.welcome,
                (route) => false,
              );
            },
            child: const Text('Log Out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

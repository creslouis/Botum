import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final _firestoreService = FirestoreService();
  final _searchController = TextEditingController();
  String _query = '';
  String? _updatingUid;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(child: Text('You do not have admin access.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
        ),
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.24),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Manage Team Access',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Promote teammates to admin or return them to user access.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black),
                    onChanged: (value) =>
                        setState(() => _query = value.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search by name or email',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.primary,
                      ),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(
                                Icons.close,
                                color: Colors.black45,
                              ),
                            ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.96),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: Color(0xFFF0D7E4)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: Color(0xFFF0D7E4)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: _firestoreService.getAllUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _CenteredMessage(
                      icon: Icons.cloud_off_outlined,
                      title: 'Could not load users',
                      subtitle: 'Check Firestore permissions or try again.',
                    );
                  }

                  final users = (snapshot.data ?? [])
                      .where(_matchesSearch)
                      .toList();

                  if (users.isEmpty) {
                    return _CenteredMessage(
                      icon: Icons.people_outline,
                      title: _query.isEmpty
                          ? 'No users yet'
                          : 'No matching users',
                      subtitle: _query.isEmpty
                          ? 'Users will appear here after they sign in or register.'
                          : 'Try another name or email.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: users.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final isCurrentUser = user.uid == auth.userModel?.uid;
                      return _UserRoleCard(
                        user: user,
                        isCurrentUser: isCurrentUser,
                        isUpdating: _updatingUid == user.uid,
                        onRoleChanged: (role) =>
                            _updateRole(user, role, isCurrentUser),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _matchesSearch(UserModel user) {
    if (_query.isEmpty) {
      return true;
    }
    return user.displayName.toLowerCase().contains(_query) ||
        user.email.toLowerCase().contains(_query) ||
        user.role.toLowerCase().contains(_query);
  }

  Future<void> _updateRole(
    UserModel user,
    String role,
    bool isCurrentUser,
  ) async {
    if (user.role == role || _updatingUid != null) {
      return;
    }

    if (isCurrentUser && role != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You cannot remove admin access from your own account here.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(role == 'admin' ? 'Make Admin?' : 'Remove Admin?'),
        content: Text(
          role == 'admin'
              ? 'Give ${user.displayName.isEmpty ? user.email : user.displayName} admin access?'
              : 'Change ${user.displayName.isEmpty ? user.email : user.displayName} back to normal user access?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _updatingUid = user.uid);
    try {
      await _firestoreService.updateUserRole(user.uid, role);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${user.email} is now ${role == 'admin' ? 'an admin' : 'a user'}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update role: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingUid = null);
      }
    }
  }
}

class _UserRoleCard extends StatelessWidget {
  const _UserRoleCard({
    required this.user,
    required this.isCurrentUser,
    required this.isUpdating,
    required this.onRoleChanged,
  });

  final UserModel user;
  final bool isCurrentUser;
  final bool isUpdating;
  final ValueChanged<String> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    final displayName = user.displayName.trim().isEmpty
        ? 'No name yet'
        : user.displayName.trim();
    final initials = _initials(displayName, user.email);
    final isAdmin = user.isAdmin;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isAdmin ? const Color(0xFFF2B6D8) : const Color(0xFFF0E0E8),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: isAdmin
                    ? AppColors.primary
                    : const Color(0xFFF7DCEB),
                backgroundImage: user.photoUrl == null || user.photoUrl!.isEmpty
                    ? null
                    : NetworkImage(user.photoUrl!),
                child: user.photoUrl == null || user.photoUrl!.isEmpty
                    ? Text(
                        initials,
                        style: TextStyle(
                          color: isAdmin ? Colors.white : AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 6),
                          const _MiniBadge(label: 'You'),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email.isEmpty ? 'No email' : user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _RoleBadge(isAdmin: isAdmin),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isUpdating || user.role == 'user'
                      ? null
                      : () => onRoleChanged('user'),
                  icon: const Icon(Icons.person_outline, size: 18),
                  label: const Text('User'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: Color(0xFFE7C8D8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isUpdating || user.role == 'admin'
                      ? null
                      : () => onRoleChanged('admin'),
                  icon: isUpdating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.shield_outlined, size: 18),
                  label: const Text('Admin'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isAdmin
                        ? AppColors.primary.withValues(alpha: 0.45)
                        : Colors.black12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _initials(String displayName, String email) {
    final source = displayName == 'No name yet' ? email : displayName;
    final parts = source
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAdmin
            ? AppColors.primary.withValues(alpha: 0.12)
            : const Color(0xFFF4EEF2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isAdmin ? 'Admin' : 'User',
        style: TextStyle(
          color: isAdmin ? AppColors.primaryDark : Colors.black54,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 54),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

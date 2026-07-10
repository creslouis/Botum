import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions = const [],
    this.backgroundColor = AppColors.white,
  });

  /// Title displayed in the app bar.
  final String title;

  /// Whether to show the back arrow button.
  final bool showBackButton;

  /// Additional widgets placed on the right side.
  final List<Widget> actions;

  /// Background color of the app bar.
  final Color backgroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      foregroundColor: AppColors.textOnLight,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(title),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.maybePop(context),
            )
          : null,
      actions: actions,
    );
  }
}

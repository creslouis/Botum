import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class PinkButton extends StatelessWidget {
  const PinkButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width,
    this.icon,
    this.height = 56,
    this.isLoading = false,
  });

  /// Label shown inside the button.
  final String text;

  /// Called when the user taps the button.
  final VoidCallback onPressed;

  /// Optional fixed width for the button.
  final double? width;

  /// Optional icon shown before the text.
  final Widget? icon;

  /// Height of the button.
  final double height;

  /// Shows a loading indicator when true.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          icon!,
          const SizedBox(width: 8),
        ],
        if (isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
            ),
          )
        else
          Text(text, style: AppTextStyles.button),
      ],
    );

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: child,
      ),
    );
  }
}

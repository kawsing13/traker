import 'package:flutter/material.dart';
import '../../config/theme.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color color;
  final bool isOutlined;
  final bool isLoading;
  final double? width;
  final bool small;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = AppTheme.primaryColor,
    this.isOutlined = false,
    this.isLoading = false,
    this.width,
    this.small = false,
    this.icon,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final buttonPadding = padding ??
        (small
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 24, vertical: 12));

    final buttonChild = isLoading
        ? SizedBox(
            width: small ? 16 : 20,
            height: small ? 16 : 20,
            child: CircularProgressIndicator(
              strokeWidth: small ? 1.5 : 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                  isOutlined ? color : Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: small ? 16 : 20,
                ),
                SizedBox(width: small ? 4 : 8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: small ? 12 : 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );

    return SizedBox(
      width: width,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                backgroundColor: color.withOpacity(0.15),
                side: BorderSide(color: color),
                foregroundColor: color,
                padding: buttonPadding,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: buttonChild,
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: buttonPadding,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: buttonChild,
            ),
    );
  }
}

// A new IconButton wrapper for consistent icon buttons
class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final double size;
  final String? tooltip;

  const CustomIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.size = 24,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        icon,
        color: color ?? AppTheme.primaryColor,
        size: size,
      ),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }
}

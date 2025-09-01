// lib/common_ui/uappbar.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class UAppBar extends StatelessWidget implements PreferredSizeWidget {
  const UAppBar({
    super.key,
    this.title,
    this.showBackArrow = false,
    this.onBackPressed,
    this.leadingIcon,
    this.actions,
    this.LeadingOnPressed,
    this.height,
  });

  final Widget? title;
  final bool showBackArrow;
  final IconData? leadingIcon;
  final List<Widget>? actions;
  final VoidCallback? LeadingOnPressed;
  final VoidCallback? onBackPressed;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      toolbarHeight: height ?? 56, // Default app bar height
      automaticallyImplyLeading: false,
      leading: showBackArrow
          ? IconButton(
              onPressed: LeadingOnPressed ?? () => Navigator.of(context).pop(),
              icon: Icon(
                Iconsax.arrow_left,
                color: dark ? Colors.white : Colors.black,
              ),
            )
          : leadingIcon != null
          ? IconButton(onPressed: LeadingOnPressed, icon: Icon(leadingIcon))
          : null,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: title,
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height ?? 56);
}

import 'package:flutter/material.dart';
import '../theme/custom_theme.dart';

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;

  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      title: Text(title),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      bottom: bottom,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: CustomTheme.gradientForBrightness(isDark),
        ),
      ),
      elevation: 0,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}

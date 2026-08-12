import 'package:flutter/material.dart';
import '../theme/custom_theme.dart';
import 'gradient_app_bar.dart';

enum DeviceType { mobile, tablet, desktop }

class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final PreferredSizeWidget? appBarBottom;
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.builder,
    this.actions,
    this.floatingActionButton,
    this.drawer,
    this.appBarBottom,
  });

  static DeviceType deviceTypeOf(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1024) return DeviceType.desktop;
    if (width >= 600) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: CustomTheme.gradientBackground(isDark: isDark),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: drawer,
        appBar: GradientAppBar(
          title: title,
          actions: actions,
          bottom: appBarBottom,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final device = deviceTypeOf(context);
            return builder(context, device);
          },
        ),
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}

extension DeviceTypeX on DeviceType {
  bool get isMobile => this == DeviceType.mobile;
  bool get isTablet => this == DeviceType.tablet;
  bool get isDesktop => this == DeviceType.desktop;
}

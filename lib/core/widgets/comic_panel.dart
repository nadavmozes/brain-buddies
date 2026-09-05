import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A bordered comic panel with the signature hard drop shadow.
class ComicPanel extends StatelessWidget {
  const ComicPanel({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 18,
    this.shadowColor = AppTheme.ink,
    this.shadowOffset = 5,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color shadowColor;
  final double shadowOffset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: AppTheme.comicBorder,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: AppTheme.comicShadow(
          color: shadowColor,
          offset: shadowOffset,
        ),
      ),
      child: child,
    );
  }
}

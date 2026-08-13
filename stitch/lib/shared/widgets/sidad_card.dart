/// Premium card with tonal layering and ambient shadow.
library;

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_shadows.dart';

class SidadCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? shadow;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const SidadCard({
    super.key,
    required this.child,
    this.color,
    this.radius = 16,
    this.padding,
    this.margin,
    this.shadow,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null
            ? (color ?? AppColors.surfaceContainerLowest)
            : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow ?? AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

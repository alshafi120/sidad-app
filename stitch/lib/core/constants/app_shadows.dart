/// Shadow and decoration tokens from the Stitch design system.
library;

import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppShadows {
  /// Premium ambient shadow — 6% opacity tint of deep purple.
  static const List<BoxShadow> premium = [
    BoxShadow(
      offset: Offset(0, 20),
      blurRadius: 40,
      color: Color(0x0F1B0062), // rgba(27, 0, 98, 0.06)
    ),
  ];

  /// Subtle card shadow for elevated surfaces.
  static const List<BoxShadow> card = [
    BoxShadow(offset: Offset(0, 4), blurRadius: 16, color: Color(0x0A1B0062)),
  ];

  /// Soft elevation for floating action elements.
  static const List<BoxShadow> floating = [
    BoxShadow(offset: Offset(0, 8), blurRadius: 24, color: Color(0x141B0062)),
  ];

  /// Bottom navigation glassmorphism shadow.
  static const List<BoxShadow> bottomNav = [
    BoxShadow(offset: Offset(0, -4), blurRadius: 20, color: Color(0x081B0062)),
  ];
}

abstract final class AppDecorations {
  /// Card decoration with premium shadow and rounded corners.
  static BoxDecoration card({
    Color? color,
    double radius = 16,
    List<BoxShadow>? shadow,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadow ?? AppShadows.card,
    );
  }

  /// Primary gradient button decoration.
  static BoxDecoration primaryButton({double radius = 24}) {
    return BoxDecoration(
      gradient: AppColors.primaryGradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        const BoxShadow(
          offset: Offset(0, 8),
          blurRadius: 24,
          color: Color(0x33532CD8),
        ),
      ],
    );
  }

  /// Recessed input field decoration (no border by default).
  static BoxDecoration inputField({bool focused = false}) {
    return BoxDecoration(
      color: focused
          ? AppColors.surfaceContainerLowest
          : AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      border: focused
          ? Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.15))
          : null,
    );
  }

  /// Section container background.
  static BoxDecoration section({double radius = 16}) {
    return BoxDecoration(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// Status chip decoration with full rounding.
  static BoxDecoration chip({required Color color}) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(9999),
    );
  }
}

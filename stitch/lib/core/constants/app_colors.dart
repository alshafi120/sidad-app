/// Application-wide color constants derived from the Sidad
/// design system.
library;

import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Primary Palette (Teal / Mint Green) ────────────────────────
  static const Color primary = Color(0xFF00BFA5); // The main button color
  static const Color primaryContainer = Color(0xFFE0F2F1);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF004D40);

  // ── Splash Screen (Dark Blue) ──────────────────────────────────
  static const Color splashBackground = Color(0xFF06152B); // Dark navy blue

  // ── Secondary Palette (Text & Accents) ─────────────────────────
  static const Color secondary = Color(0xFF1E293B);
  static const Color secondaryContainer = Color(0xFFF1F5F9);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF0F172A);

  // ── Tertiary / Success ───────────────────────────────────────────
  static const Color tertiary = Color(0xFF22C55E); // Green for success
  static const Color tertiaryContainer = Color(0xFFDCFCE7);
  static const Color success = Color(0xFF22C55E);
  static const Color onSuccess = Color(0xFFFFFFFF);

  // ── Error ────────────────────────────────────────────────────────
  static const Color error = Color(0xFFEF4444); // Red for debt/error
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF7F1D1D);

  // ── Surface Hierarchy ────────────────────────────────────────────
  static const Color surface = Color(0xFFF8FAFC); // Very light grey background
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF); // Pure white cards
  static const Color surfaceContainerLow = Color(0xFFF1F5F9); // Light gray input fields
  static const Color surfaceContainer = Color(0xFFE2E8F0);
  static const Color surfaceContainerHigh = Color(0xFFCBD5E1);

  // ── On-Surface (Text) ────────────────────────────────────────────
  static const Color onSurface = Color(0xFF0F172A); // Dark text
  static const Color onSurfaceVariant = Color(0xFF64748B); // Grey text (hint, unselected)

  // ── Outline ──────────────────────────────────────────────────────
  static const Color outline = Color(0xFF94A3B8);
  static const Color outlineVariant = Color(0xFFE2E8F0); // Subtle borders

  // ── Inverse ──────────────────────────────────────────────────────
  static const Color inverseSurface = Color(0xFF1E293B);
  static const Color inverseOnSurface = Color(0xFFF8FAFC);
  static const Color inversePrimary = Color(0xFFE0F2F1);

  // ── Semantic ─────────────────────────────────────────────────────
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ── Gradient Presets ─────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00BFA5), Color(0xFF00897B)], // Teal to Darker Teal
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0B192C), Color(0xFF050E18)],
  );

  // Aliases for backward compatibility with older components
  static const Color primaryFixed = primaryContainer;
  static const Color primaryFixedDim = primaryContainer;
}

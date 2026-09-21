import 'package:flutter/material.dart';

class AppColors {
  // Deep space / obsidian surfaces
  static const Color darkBg = Color(0xFF0A0B10);
  static const Color darkSurface = Color(0xFF131622);
  static const Color darkSurfaceElevated = Color(0xFF1B1E30);
  static const Color glassBackground = Color(0x99181B2D);
  static const Color glassBorder = Color(0x2EFFFFFF);
  static const Color glassHighlight = Color(0x1AFFFFFF);

  // Vibrant Accents
  static const Color primary = Color(0xFF7C3AED); // Electric Violet
  static const Color primaryLight = Color(0xFF9333EA);
  static const Color secondary = Color(0xFF06B6D4); // Cyber Cyan
  static const Color secondaryLight = Color(0xFF22D3EE);
  static const Color tertiary = Color(0xFFF43F5E); // Electric Rose

  // Status & Gamification
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Crimson
  static const Color gold = Color(0xFFFFB800);
  static const Color silver = Color(0xFFCBD5E1);
  static const Color bronze = Color(0xFFCD7F32);

  // Text
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Light Mode Surfaces & Text
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightGlassBackground = Color(0xE6FFFFFF);
  static const Color lightGlassBorder = Color(0x2964748B);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x33262A45), Color(0x1A181A2A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightGlassGradient = LinearGradient(
    colors: [Color(0xF0FFFFFF), Color(0xD9F8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dynamic Theme Helpers
  static bool _resolveIsDark(dynamic target) {
    if (target is BuildContext) {
      return Theme.of(target).brightness == Brightness.dark;
    }
    return target == true;
  }

  static Color adaptiveTextPrimary(dynamic target) => _resolveIsDark(target) ? textPrimary : lightTextPrimary;
  static Color adaptiveTextSecondary(dynamic target) => _resolveIsDark(target) ? textSecondary : lightTextSecondary;
  static Color adaptiveTextMuted(dynamic target) => _resolveIsDark(target) ? textMuted : lightTextMuted;
  static Color adaptiveBg(dynamic target) => _resolveIsDark(target) ? darkBg : lightBg;
  static Color adaptiveSurface(dynamic target) => _resolveIsDark(target) ? darkSurface : lightSurface;
  static Color adaptiveSurfaceElevated(dynamic target) => _resolveIsDark(target) ? darkSurfaceElevated : lightSurfaceElevated;
  static Color adaptiveBorder(dynamic target) => _resolveIsDark(target) ? glassBorder : lightBorder;
}


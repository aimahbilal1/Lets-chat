import 'package:flutter/material.dart';

/// Single source of truth for every colour and gradient in the app.
/// All screens and widgets must reference these tokens — never raw Color() values.
class AppColors {
  // ─── Brand ──────────────────────────────────────────────────────────────────
  static const Color accent = Color(0xFF3D7A5C);       // Forest green — primary action
  static const Color accentLight = Color(0xFFEAF3EE);  // Tinted surface for accent elements

  // ─── Backgrounds ────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF8F8F8);   // App scaffold
  static const Color surface = Color(0xFFFFFFFF);      // Cards, sheets, inputs
  static const Color surfaceSecondary = Color(0xFFF2F2F7); // Filled input bg, chips

  // ─── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F1115);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // ─── Semantic ───────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFE53935);
  static const Color errorSurface = Color(0xFFFDECEC);
  static const Color success = Color(0xFF22C55E);
  static const Color online = Color(0xFF22C55E);

  // ─── Structural ─────────────────────────────────────────────────────────────
  /// 1px borders — use where background contrast isn't enough
  static const Color border = Color(0x14000000);       // rgba(0,0,0,0.08)
  static const Color divider = Color(0x0A000000);      // rgba(0,0,0,0.04)

  // ─── Decorative gradient (brand background only) ────────────────────────────
  /// Softened from the original saturated palette — still brand, but calm.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFFC8DFCF), Color(0xFFF2D5E4), Color(0xFFE3D0F0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Legacy aliases (kept so existing refs compile) ─────────────────────────
  static const Color mint = Color(0xFFA8D5BA);
  static const Color pink = Color(0xFFF8C8DC);
  static const Color lavender = Color(0xFFE0B0FF);
  static const Color darkText = textPrimary;
  static const Color lightText = textSecondary;
  static const LinearGradient primaryGradient = brandGradient;
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [accent, Color(0xFF4F9E77)],
  );
}

import 'package:flutter/material.dart';

class AppColors {
  static const Color beige = Color(0xFFF5F5DC);
  static const Color mint = Color(0xFFA8D5BA);
  static const Color pink = Color(0xFFF8C8DC);
  static const Color lavender = Color(0xFFE0B0FF);

  static const Color darkText = Color(0xFF1E1E1E);
  static const Color lightText = Color(0xFF777777);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      mint,
      pink,
      lavender,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [
      Color(0xFF4D7C63),
      Color(0xFF7AAE8E),
      Color(0xFFB79CCF),
    ],
  );
}
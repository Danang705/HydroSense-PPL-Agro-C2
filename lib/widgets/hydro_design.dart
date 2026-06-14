import 'package:flutter/material.dart';

class HydroDesign {
  // Palet Warna Utama
  static const Color primaryGreen = Color(0xFF1E5C3A);
  static const Color secondaryGreen = Color(0xFF2D7A50);
  static const Color lightGreenBg = Color(0xFFF0F7F3);
  static const Color background = Color(0xFFF4F6F5);
  static const Color darkText = Color(0xFF1A1A2E);
  static const Color grayText = Color(0xFF718096);
  static const Color dangerRed = Color(0xFFE54D50);
  static const Color warningOrange = Color(0xFFDD6B20);
  static const Color infoTeal = Color(0xFF38B2AC);

  // Bayangan Lembut Premium (Soft Shadows)
  static List<BoxShadow> get premiumShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: primaryGreen.withValues(alpha: 0.2),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  // Dekorasi Input Teks Modern
  static InputDecoration inputStyle({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: primaryGreen.withValues(alpha: 0.7)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.08), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class HydroDesign {
  // Palet Warna FitBite Theme
  static const Color primaryGreen = Color(0xFF65A30D); // Hijau Apel Pekat (High contrast)
  static const Color secondaryGreen = Color(0xFF84CC16); // Hijau Lime Menyala (Highlight)
  static const Color lightGreenBg = Color(0xFFF1F8E9); // Latar Belakang Hijau Lime Halus
  static const Color accentGreenHighlight = Color(0xFFECFDF5); // Hijau Mint Sangat Terang
  static const Color background = Color(0xFFF9FAFB); // Latar Belakang Abu-Abu Bersih
  static const Color darkText = Color(0xFF1F2937); // Hitam Charcoal
  static const Color grayText = Color(0xFF6B7280); // Abu-Abu Sedang
  static const Color dangerRed = Color(0xFFEF4444); // Merah Terang
  static const Color warningOrange = Color(0xFFF97316); // Oranye
  static const Color infoTeal = Color(0xFF06B6D4); // Teal

  // Bayangan Lembut Premium FitBite (Ultra Soft Shadows)
  static List<BoxShadow> get premiumShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get buttonShadow => [
        BoxShadow(
          color: primaryGreen.withValues(alpha: 0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
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
      prefixIcon: Icon(prefixIcon, color: primaryGreen.withValues(alpha: 0.6)),
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
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.05), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
      ),
    );
  }
}

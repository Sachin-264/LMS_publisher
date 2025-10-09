// lib/utils/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // --- PRIMARY COLORS ---
  static const Color primaryGreen = Color(0xFF1A5F3F);
  static const Color accentGreen = Color(0xFF1E8E3E);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color bodyText = Color(0xFF6B7280);
  static const Color lightGrey = Color(0xFFF9FAFB);
  static const Color borderGrey = Color(0xFFE5E7EB);
  static const Color background = Color(0xFFFFFFFF); // Changed to pure white for a cleaner look
  static Color shadowColor = const Color(0xFF1E8E3E).withOpacity(0.1); // NEW: For focused shadow

  // --- BRAND COLORS ---
  static const Color mackColor = Color(0xFFBF6449);
  static const Color mackBorder = Color(0xFF733C2B);
  static const Color cleoColor = Color(0xFFDFAA3A);
  static const Color cleoBorder = Color(0xFF856622);
  static const Color particleColor = Color(0xFFE0E0E0);

  // --- GRADIENTS ---
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentGreen, primaryGreen],
    stops: [0.0, 1.0],
  );

  // --- TEXT STYLES ---
  static TextStyle get _baseTextStyle => GoogleFonts.plusJakartaSans();
  static TextStyle get logoStyle => GoogleFonts.playfairDisplay(
      fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: 1.2);
  static TextStyle get headline1 => _baseTextStyle.copyWith(
      fontSize: 28, fontWeight: FontWeight.w800, color: darkText);
  static TextStyle get headline2 => _baseTextStyle.copyWith(
      fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white);
  static TextStyle get bodyText1 => _baseTextStyle.copyWith(
      fontSize: 16, fontWeight: FontWeight.w500, color: bodyText);
  static TextStyle get labelText => _baseTextStyle.copyWith(
      fontSize: 14, fontWeight: FontWeight.w600, color: darkText);
  static TextStyle get buttonText => _baseTextStyle.copyWith(
      fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white);

  // --- PADDING & BORDERS ---
  static const double defaultPadding = 16.0;
  static final BorderRadius defaultBorderRadius = BorderRadius.circular(12.0);
}
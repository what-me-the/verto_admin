import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography system using Poppins font from design specifications
class AppTypography {
  AppTypography._();

  // Base text style
  static TextStyle get _baseStyle =>
      GoogleFonts.poppins(color: AppColors.darkCharcoal);

  // Headings
  static TextStyle get h1 => _baseStyle.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static TextStyle get h2 => _baseStyle.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static TextStyle get h3 => _baseStyle.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // Body Text
  static TextStyle get bodyLarge => _baseStyle.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get body => _baseStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodyMedium => _baseStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodySmall => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // Subtext/Secondary
  static TextStyle get caption => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w300,
    color: AppColors.slateGray,
    height: 1.4,
  );

  // Button Text
  static TextStyle get button => _baseStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  // Link Text
  static TextStyle get link => _baseStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.earthyCoral,
    height: 1.4,
  );
}

import 'package:alimenta_peru/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Estilos de texto, decoraciones y constantes de diseño reutilizables.
abstract final class AppStyles {
  AppStyles._();

  // ── Espaciado ────────────────────────────────────────────────────────────
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // ── Bordes redondeados ───────────────────────────────────────────────────
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 100.0;

  static const BorderRadius borderRadiusS =
      BorderRadius.all(Radius.circular(radiusS));
  static const BorderRadius borderRadiusM =
      BorderRadius.all(Radius.circular(radiusM));
  static const BorderRadius borderRadiusL =
      BorderRadius.all(Radius.circular(radiusL));
  static const BorderRadius borderRadiusXL =
      BorderRadius.all(Radius.circular(radiusXL));
  static const BorderRadius borderRadiusFull =
    BorderRadius.all(Radius.circular(radiusFull));

  // ── Elevaciones ──────────────────────────────────────────────────────────
  static const double elevationNone = 0;
  static const double elevationS = 2;
  static const double elevationM = 4;
  static const double elevationL = 8;

  // ── Padding estándar ─────────────────────────────────────────────────────
  static const EdgeInsets paddingScreen = EdgeInsets.all(spacingM);
  static const EdgeInsets paddingCard = EdgeInsets.all(spacingM);
  static const EdgeInsets paddingButton =
      EdgeInsets.symmetric(horizontal: spacingM, vertical: 14);

  // ── Estilos de texto ─────────────────────────────────────────────────────
  static TextStyle get displayLarge => GoogleFonts.nunito(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      );

  static TextStyle get displayMedium => GoogleFonts.nunito(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineLarge => GoogleFonts.nunito(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineMedium => GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleLarge => GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleMedium => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmall => GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get labelLarge => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.cardBackground,
        letterSpacing: 0.5,
      );

  static TextStyle get caption => GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  // ── Decoraciones de caja ─────────────────────────────────────────────────
  static BoxDecoration get cardDecoration => const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: borderRadiusL,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get successDecoration => BoxDecoration(
        color: AppColors.successGreen,
        borderRadius: borderRadiusM,
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
      );

  static BoxDecoration get warningDecoration => BoxDecoration(
        color: AppColors.warningOrange,
        borderRadius: borderRadiusM,
        border: Border.all(color: AppColors.primaryOrange.withOpacity(0.3)),
      );

  static BoxDecoration get errorDecoration => BoxDecoration(
        color: AppColors.errorRed,
        borderRadius: borderRadiusM,
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      );

  // ── Sombras ──────────────────────────────────────────────────────────────
  static List<BoxShadow> get shadowCard => [
        const BoxShadow(
          color: AppColors.shadowLight,
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowElevated => [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  // ── Duración de animaciones ──────────────────────────────────────────────
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
}

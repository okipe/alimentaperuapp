import 'package:flutter/material.dart';

/// Paleta de colores oficial de Alimenta Perú.
///
/// Todos los valores son [const] para máxima eficiencia en tiempo de
/// compilación.
abstract final class AppColors {
  AppColors._();

  // ── Primarios ────────────────────────────────────────────────────────────
  /// Verde principal — botones, AppBar, íconos activos.
  static const Color primaryGreen = Color(0xFF16A34A);

  /// Naranja principal — acentos, badges, CTAs secundarios.
  static const Color primaryOrange = Color(0xFFF97316);

  // ── Fondos ───────────────────────────────────────────────────────────────
  /// Fondo general de pantallas.
  static const Color backgroundLight = Color(0xFFFAFAFA);

  /// Fondo de tarjetas y campos de formulario.
  static const Color cardBackground = Color(0xFFFFFFFF);

  // ── Texto ────────────────────────────────────────────────────────────────
  /// Texto principal — títulos y cuerpo.
  static const Color textPrimary = Color(0xFF1A1A1A);

  /// Texto secundario — subtítulos, placeholders, labels.
  static const Color textSecondary = Color(0xFF6B7280);

  // ── Estados ──────────────────────────────────────────────────────────────
  /// Fondo suave para indicadores de éxito.
  static const Color successGreen = Color(0xFFD1FAE5);

  /// Fondo suave para advertencias y alertas de stock.
  static const Color warningOrange = Color(0xFFFFF3E0);

  /// Fondo suave para errores y cancelaciones.
  static const Color errorRed = Color(0xFFFEE2E2);

  // ── Auxiliares ───────────────────────────────────────────────────────────
  /// Color de borde neutro para inputs y dividers.
  static const Color borderNeutral = Color(0xFFE5E7EB);

  /// Sombra ligera para elevaciones sutiles.
  static const Color shadowLight = Color(0x14000000); // 8 % black

  // ── Helpers ──────────────────────────────────────────────────────────────
  /// Devuelve el color de fondo asociado a cada estado semántico.
  static Color backgroundForStatus({
    required bool isSuccess,
    required bool isWarning,
    required bool isError,
  }) {
    if (isSuccess) return successGreen;
    if (isWarning) return warningOrange;
    if (isError) return errorRed;
    return cardBackground;
  }
}

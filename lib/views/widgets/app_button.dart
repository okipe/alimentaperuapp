import 'package:alimenta_peru/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Botón reutilizable primario y secundario (outline).
class AppButton extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final Color color;
  final bool isLoading;
  final bool isOutline;
  final IconData? icono;

  const AppButton({
    super.key,
    required this.texto,
    required this.onPressed,
    this.color = AppColors.primaryGreen,
    this.isLoading = false,
    this.isOutline = false,
    this.icono,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    final labelStyle = GoogleFonts.nunito(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: isOutline
          ? (disabled ? AppColors.textSecondary : color)
          : AppColors.cardBackground,
      letterSpacing: 0.3,
    );

    Widget child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: isOutline ? color : AppColors.cardBackground,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icono != null) ...[
                Icon(
                  icono,
                  size: 20,
                  color: isOutline
                      ? (disabled ? AppColors.textSecondary : color)
                      : AppColors.cardBackground,
                ),
                const SizedBox(width: 8),
              ],
              Text(texto, style: labelStyle),
            ],
          );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    if (isOutline) {
      return SizedBox(
        width: double.infinity,
        height: 60,
        child: OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: disabled ? AppColors.borderNeutral : color,
              width: 2,
            ),
            shape: shape,
            backgroundColor: Colors.transparent,
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled ? AppColors.borderNeutral : color,
          foregroundColor: AppColors.cardBackground,
          elevation: disabled ? 0 : 2,
          shadowColor: color.withOpacity(0.3),
          shape: shape,
        ),
        child: child,
      ),
    );
  }
}

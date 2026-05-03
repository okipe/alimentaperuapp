import 'package:alimenta_peru/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Overlay semitransparente con indicador de carga centrado.
/// Úsalo apilado sobre el body del Scaffold con Stack.
class LoadingOverlay extends StatelessWidget {
  final bool visible;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.visible,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (visible)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.35),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryGreen,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Widget de estado vacío: ícono + mensaje + subtítulo opcional.
class EmptyState extends StatelessWidget {
  final String emoji;
  final String mensaje;
  final String? subtitulo;
  final Widget? accion;

  const EmptyState({
    super.key,
    required this.emoji,
    required this.mensaje,
    this.subtitulo,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              mensaje,
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitulo != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitulo!,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (accion != null) ...[
              const SizedBox(height: 24),
              accion!,
            ],
          ],
        ),
      ),
    );
  }
}

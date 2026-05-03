import 'package:alimenta_peru/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Header verde o naranja reutilizable con título, subtítulo opcional
/// y barra de progreso opcional.
class AppHeader extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final bool mostrarBack;
  final Color color;
  final VoidCallback? onBack;

  /// Si no es null, muestra una barra de progreso lineal (0.0 – 1.0).
  final double? progreso;

  /// Texto que se muestra debajo de la barra de progreso.
  final String? textoProgreso;

  /// Ícono opcional a la izquierda del título.
  final IconData? icono;

  const AppHeader({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.mostrarBack = false,
    this.color = AppColors.primaryGreen,
    this.onBack,
    this.progreso,
    this.textoProgreso,
    this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mostrarBack) ...[
            GestureDetector(
              onTap: onBack ?? () => Navigator.maybePop(context),
              child: const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
            ),
          ],
          Row(
            children: [
              if (icono != null) ...[
                Icon(icono, color: Colors.white, size: 28),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  titulo,
                  style: GoogleFonts.nunito(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitulo!,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
          if (progreso != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: progreso,
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.3),
                color: Colors.white,
              ),
            ),
            if (textoProgreso != null) ...[
              const SizedBox(height: 6),
              Text(
                textoProgreso!,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

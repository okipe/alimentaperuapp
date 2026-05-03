import 'package:alimenta_peru/core/constants/app_colors.dart';
import 'package:alimenta_peru/views/beneficiaria/seleccion_menu_screen.dart';
import 'package:alimenta_peru/views/shared/login_selector_screen.dart';
import 'package:alimenta_peru/views/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pantalla de confirmación tras registro exitoso de beneficiaria.
class ConfirmacionRegistroScreen extends StatelessWidget {
  final String nombre;
  final String dni;
  final String comedor;
  final int numPersonas;
  final String turno;

  const ConfirmacionRegistroScreen({
    super.key,
    required this.nombre,
    required this.dni,
    required this.comedor,
    required this.numPersonas,
    required this.turno,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ── Check verde ────────────────────────────────────────────
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 56,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                '¡Registro Exitoso!',
                style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ya eres parte del comedor',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),

              // ── Card resumen ───────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _ResumenFila(icono: Icons.person_outline, label: 'Nombre', valor: nombre),
                    const _Divider(),
                    _ResumenFila(icono: Icons.badge_outlined, label: 'DNI', valor: dni),
                    const _Divider(),
                    _ResumenFila(icono: Icons.store_outlined, label: 'Comedor', valor: comedor),
                    const _Divider(),
                    _ResumenFila(
                      icono: Icons.group_outlined,
                      label: 'Personas',
                      valor: '$numPersonas ${numPersonas == 1 ? 'persona' : 'personas'}',
                    ),
                    const _Divider(),
                    _ResumenFila(icono: Icons.schedule_outlined, label: 'Turno', valor: turno),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Card informativa ───────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.successGreen,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryGreen.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppColors.primaryGreen, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tu registro será revisado por la administradora del comedor.',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Botón ver menús ────────────────────────────────────────
              AppButton(
                texto: 'Ver menús disponibles',
                color: AppColors.primaryGreen,
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SeleccionMenuScreen()),
                ),
              ),
              const SizedBox(height: 12),

              // ── Botón volver al inicio ─────────────────────────────────
              TextButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LoginSelectorScreen()),
                  (route) => false,
                ),
                child: Text(
                  'Volver al inicio',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumenFila extends StatelessWidget {
  final IconData icono;
  final String label;
  final String valor;

  const _ResumenFila({
    required this.icono,
    required this.label,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icono, size: 18, color: AppColors.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  valor,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.borderNeutral);
  }
}

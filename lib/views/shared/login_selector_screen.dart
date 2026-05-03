import 'package:alimenta_peru/core/constants/app_colors.dart';
import 'package:alimenta_peru/views/beneficiaria/login_beneficiaria_screen.dart';
import 'package:alimenta_peru/views/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pantalla de bienvenida — selector de rol.
/// Basada en 01-bienvenido.png
class LoginSelectorScreen extends StatelessWidget {
  const LoginSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Logo ───────────────────────────────────────────────────
              Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.restaurant,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Título ─────────────────────────────────────────────────
              Text(
                'ComederApp',
                style: GoogleFonts.nunito(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Comedores Populares de Lima',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Spacer(flex: 2),

              // ── Ilustración de dos personas ────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Persona naranja (beneficiaria)
                    _PersonaCard(
                      color: AppColors.primaryOrange,
                      accentColor: const Color(0xFFFBBF24),
                    ),
                    const SizedBox(width: 16),
                    // Cara neutra
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6B896),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sentiment_satisfied_alt,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Persona verde (administradora)
                    _PersonaCard(
                      color: AppColors.primaryGreen,
                      accentColor: const Color(0xFFFBBF24),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // ── Botones de rol ─────────────────────────────────────────
              AppButton(
                texto: 'Soy Beneficiaria',
                color: AppColors.primaryGreen,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginBeneficiariaScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              AppButton(
                texto: 'Soy Administradora',
                color: AppColors.primaryOrange,
                onPressed: () {
                  // Navega al login de administradora (usando el login genérico)
                  Navigator.pushNamed(context, '/login');
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonaCard extends StatelessWidget {
  final Color color;
  final Color accentColor;

  const _PersonaCard({required this.color, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Cabeza
          const CircleAvatar(backgroundColor: Colors.white, radius: 12),
          const SizedBox(height: 6),
          // Cuerpo (rectángulo con acento)
          Container(
            width: 28,
            height: 22,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

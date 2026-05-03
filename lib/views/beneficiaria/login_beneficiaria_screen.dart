import 'package:alimenta_peru/core/constants/app_colors.dart';
import 'package:alimenta_peru/core/constants/app_styles.dart';
import 'package:alimenta_peru/viewmodels/auth_viewmodel.dart';
import 'package:alimenta_peru/views/beneficiaria/registro_beneficiaria_p1_screen.dart';
import 'package:alimenta_peru/views/shared/widgets/app_button.dart';
import 'package:alimenta_peru/views/shared/widgets/app_text_field.dart';
import 'package:alimenta_peru/views/shared/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Pantalla de login para beneficiarias (DNI + contraseña).
class LoginBeneficiariaScreen extends StatefulWidget {
  const LoginBeneficiariaScreen({super.key});

  @override
  State<LoginBeneficiariaScreen> createState() =>
      _LoginBeneficiariaScreenState();
}

class _LoginBeneficiariaScreenState extends State<LoginBeneficiariaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dniCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _dniCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _onIngresar() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<AuthViewModel>();
    await vm.loginBeneficiaria(_dniCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (vm.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/beneficiaria/dashboard');
    } else if (vm.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.error!),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, vm, _) {
        return LoadingOverlay(
          visible: vm.cargando,
          child: Scaffold(
            backgroundColor: AppColors.backgroundLight,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back
                      GestureDetector(
                        onTap: () => Navigator.maybePop(context),
                        child: const Icon(Icons.arrow_back,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 32),

                      // Logo
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            color: AppColors.successGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.restaurant,
                              size: 40, color: AppColors.primaryGreen),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          'Ingresar como Beneficiaria',
                          style: GoogleFonts.nunito(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          'Ingresa tu DNI y contraseña',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // DNI
                      AppTextField(
                        label: 'DNI',
                        hint: '12345678',
                        controller: _dniCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 8,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        prefixIcon: const Icon(Icons.badge_outlined,
                            color: AppColors.textSecondary),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'El DNI es requerido';
                          }
                          if (v.length != 8) {
                            return 'El DNI debe tener 8 dígitos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Contraseña
                      AppTextField(
                        label: 'Contraseña',
                        hint: 'Mínimo 6 caracteres',
                        controller: _passCtrl,
                        obscureText: true,
                        prefixIcon: const Icon(Icons.lock_outlined,
                            color: AppColors.textSecondary),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'La contraseña es requerida';
                          }
                          if (v.length < 6) {
                            return 'Mínimo 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Botón ingresar
                      AppButton(
                        texto: 'Ingresar',
                        onPressed: vm.cargando ? null : _onIngresar,
                        isLoading: vm.cargando,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(height: 20),

                      // Link registro
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const RegistroBeneficiariaP1Screen(),
                            ),
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              children: [
                                const TextSpan(
                                    text: '¿Aún no tienes cuenta? '),
                                TextSpan(
                                  text: 'Regístrate',
                                  style: GoogleFonts.nunito(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

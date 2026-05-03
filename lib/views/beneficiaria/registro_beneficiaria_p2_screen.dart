import 'package:alimenta_peru/core/constants/app_colors.dart';
import 'package:alimenta_peru/viewmodels/auth_viewmodel.dart';
import 'package:alimenta_peru/views/beneficiaria/confirmacion_registro_screen.dart';
import 'package:alimenta_peru/views/shared/widgets/app_button.dart';
import 'package:alimenta_peru/views/shared/widgets/app_header.dart';
import 'package:alimenta_peru/views/shared/widgets/app_text_field.dart';
import 'package:alimenta_peru/views/shared/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Paso 2 de 2 del registro de beneficiaria.
class RegistroBeneficiariaP2Screen extends StatefulWidget {
  final String nombre;
  final String dni;
  final String comedor;
  final String comedorId;

  const RegistroBeneficiariaP2Screen({
    super.key,
    required this.nombre,
    required this.dni,
    required this.comedor,
    required this.comedorId,
  });

  @override
  State<RegistroBeneficiariaP2Screen> createState() =>
      _RegistroBeneficiariaP2ScreenState();
}

class _RegistroBeneficiariaP2ScreenState
    extends State<RegistroBeneficiariaP2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  int _numPersonas = 1;
  String? _turnoSeleccionado;
  bool _aceptaTerminos = false;

  static const List<String> _turnos = [
    '11:00am - 12:00pm',
    '12:00pm - 1:00pm',
    '1:00pm - 2:00pm',
  ];

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _onCrearCuenta() async {
    if (!_formKey.currentState!.validate()) return;
    if (_turnoSeleccionado == null) {
      _showError('Selecciona un turno preferido');
      return;
    }
    if (!_aceptaTerminos) {
      _showError('Debes aceptar los términos y condiciones');
      return;
    }
    if (_passCtrl.text != _confirmPassCtrl.text) {
      _showError('Las contraseñas no coinciden');
      return;
    }

    final vm = context.read<AuthViewModel>();
    final ok = await vm.registrarBeneficiaria({
      'nombre': widget.nombre,
      'dni': widget.dni,
      'email': _emailCtrl.text.trim(),
      'password': _passCtrl.text,
      'comedorId': widget.comedorId,
      'numPersonasFamilia': _numPersonas,
      'turnoPreferido': _turnoSeleccionado!,
    });

    if (!mounted) return;
    if (ok) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmacionRegistroScreen(
            nombre: widget.nombre,
            dni: widget.dni,
            comedor: widget.comedor,
            numPersonas: _numPersonas,
            turno: _turnoSeleccionado!,
          ),
        ),
        (route) => false,
      );
    } else {
      _showError(vm.error ?? 'Error al crear la cuenta');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, vm, _) {
        return LoadingOverlay(
          visible: vm.cargando,
          child: Scaffold(
            backgroundColor: AppColors.backgroundLight,
            body: Column(
              children: [
                AppHeader(
                  titulo: 'Registro Beneficiaria',
                  mostrarBack: true,
                  progreso: 1.0,
                  textoProgreso: 'Paso 2 de 2',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Número de personas ──────────────────────────
                          _SectionTitle('Número de personas en tu familia'),
                          const SizedBox(height: 14),
                          _PersonasStepper(
                            value: _numPersonas,
                            onDecrement: _numPersonas > 1
                                ? () =>
                                    setState(() => _numPersonas--)
                                : null,
                            onIncrement: _numPersonas < 6
                                ? () =>
                                    setState(() => _numPersonas++)
                                : null,
                          ),
                          const SizedBox(height: 28),

                          // ── Turno preferido ─────────────────────────────
                          _SectionTitle('Turno preferido'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _turnos
                                .map((t) => _TurnoChip(
                                      label: t,
                                      selected: _turnoSeleccionado == t,
                                      onTap: () => setState(
                                          () => _turnoSeleccionado = t),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 28),

                          // ── Email ───────────────────────────────────────
                          _SectionTitle('Correo electrónico'),
                          const SizedBox(height: 8),
                          AppTextField(
                            label: 'Email',
                            hint: 'usuario@correo.com',
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined,
                                color: AppColors.textSecondary),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'El email es requerido';
                              }
                              if (!v.contains('@')) return 'Email inválido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // ── Contraseña ──────────────────────────────────
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
                              if (v.length < 6) return 'Mínimo 6 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // ── Confirmar contraseña ────────────────────────
                          AppTextField(
                            label: 'Confirmar contraseña',
                            hint: 'Repite tu contraseña',
                            controller: _confirmPassCtrl,
                            obscureText: true,
                            prefixIcon: const Icon(Icons.lock_outline,
                                color: AppColors.textSecondary),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Confirma tu contraseña';
                              }
                              if (v != _passCtrl.text) {
                                return 'Las contraseñas no coinciden';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // ── Términos ────────────────────────────────────
                          GestureDetector(
                            onTap: () => setState(
                                () => _aceptaTerminos = !_aceptaTerminos),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _aceptaTerminos,
                                  onChanged: (v) => setState(
                                      () => _aceptaTerminos = v ?? false),
                                  activeColor: AppColors.primaryGreen,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(4)),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(
                                      'Acepto los términos y condiciones del programa',
                                      style: GoogleFonts.nunito(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── Botón crear cuenta ──────────────────────────
                          AppButton(
                            texto: 'Crear mi cuenta',
                            onPressed: vm.cargando ? null : _onCrearCuenta,
                            isLoading: vm.cargando,
                            color: AppColors.primaryGreen,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _PersonasStepper extends StatelessWidget {
  final int value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const _PersonasStepper({
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderNeutral),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StepButton(
            icon: Icons.remove,
            onTap: onDecrement,
          ),
          const SizedBox(width: 32),
          Column(
            children: [
              Text(
                '$value',
                style: GoogleFonts.nunito(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryGreen,
                ),
              ),
              Text(
                value == 1 ? 'persona' : 'personas',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 32),
          _StepButton(
            icon: Icons.add,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: disabled
              ? AppColors.borderNeutral
              : AppColors.primaryGreen.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                disabled ? AppColors.borderNeutral : AppColors.primaryGreen,
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: disabled ? AppColors.textSecondary : AppColors.primaryGreen,
          size: 24,
        ),
      ),
    );
  }
}

class _TurnoChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TurnoChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryGreen
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected
                ? AppColors.primaryGreen
                : AppColors.borderNeutral,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color:
                selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

import 'package:alimenta_peru/app/routes.dart';
import 'package:alimenta_peru/core/constants/app_colors.dart';
import 'package:alimenta_peru/core/constants/app_strings.dart';
import 'package:alimenta_peru/core/constants/app_styles.dart';
import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:alimenta_peru/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _dniController = TextEditingController();
  final _codigoAdminController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  RolUsuario _rolSeleccionado = RolUsuario.beneficiaria;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _obscureCodigo = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _dniController.dispose();
    _codigoAdminController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.passwordsDoNotMatch),
          backgroundColor: Color(0xFFB00020),
        ),
      );
      return;
    }

    final authVM = context.read<AuthViewModel>();
    final ok = await authVM.register(
      email: _emailController.text,
      password: _passwordController.text,
      nombreCompleto: _nombreController.text.trim(),
      rol: _rolSeleccionado,
      dni: _dniController.text.trim(),
      codigoAdmin: _rolSeleccionado == RolUsuario.administradora
          ? _codigoAdminController.text.trim()
          : null,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.registerSuccess),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
      Navigator.pushReplacementNamed(
        context,
        _rolSeleccionado.dashboardRoute,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authVM.errorMessage ?? AppStrings.errorGenerico),
          backgroundColor: const Color(0xFFB00020),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.register),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppStyles.paddingScreen,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppStyles.spacingM),
                Text('Crea tu cuenta', style: AppStyles.headlineLarge),
                Text(
                  'Completa tus datos para comenzar',
                  style: AppStyles.bodyMedium,
                ),
                const SizedBox(height: AppStyles.spacingL),

                // ── Nombre completo ──────────────────────────────────────
                TextFormField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: AppStrings.fullNameLabel,
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? AppStrings.campoRequerido
                      : null,
                ),
                const SizedBox(height: AppStyles.spacingM),

                // ── Correo ───────────────────────────────────────────────
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: AppStrings.emailLabel,
                    hintText: AppStrings.emailHint,
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return AppStrings.campoRequerido;
                    }
                    if (!v.contains('@')) return 'Correo inválido';
                    return null;
                  },
                ),
                const SizedBox(height: AppStyles.spacingM),

                // ── DNI ──────────────────────────────────────────────────
                TextFormField(
                  controller: _dniController,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  decoration: const InputDecoration(
                    labelText: AppStrings.dniLabel,
                    hintText: '12345678',
                    prefixIcon: Icon(Icons.badge_outlined),
                    counterText: '',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return AppStrings.campoRequerido;
                    }
                    if (v.trim().length != 8) {
                      return 'El DNI debe tener 8 dígitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppStyles.spacingM),

                // ── Selección de rol ─────────────────────────────────────
                Text('Tipo de cuenta', style: AppStyles.titleMedium),
                const SizedBox(height: AppStyles.spacingS),
                _buildRolSelector(),
                const SizedBox(height: AppStyles.spacingM),

                // ── Código de administradora (condicional) ───────────────
                AnimatedSize(
                  duration: AppStyles.animationNormal,
                  curve: Curves.easeInOut,
                  child: _rolSeleccionado == RolUsuario.administradora
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _codigoAdminField(),
                            const SizedBox(height: AppStyles.spacingM),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),

                // ── Contraseña ───────────────────────────────────────────
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    labelText: AppStrings.passwordLabel,
                    hintText: AppStrings.passwordHint,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return AppStrings.campoRequerido;
                    if (v.length < 6) return AppStrings.passwordHint;
                    return null;
                  },
                ),
                const SizedBox(height: AppStyles.spacingM),

                // ── Confirmar contraseña ─────────────────────────────────
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: AppStrings.confirmPasswordLabel,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return AppStrings.campoRequerido;
                    if (v != _passwordController.text) {
                      return AppStrings.passwordsDoNotMatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppStyles.spacingL),

                // ── Botón registrar ──────────────────────────────────────
                ElevatedButton(
                  onPressed: authVM.isLoading ? null : _onRegister,
                  child: authVM.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(AppStrings.register),
                ),
                const SizedBox(height: AppStyles.spacingM),

                // ── Ir al login ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('¿Ya tienes cuenta?', style: AppStyles.bodyMedium),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, AppRoutes.login),
                      child: Text(
                        AppStrings.login,
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppStyles.spacingM),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Widgets auxiliares ────────────────────────────────────────────────────

  Widget _buildRolSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderNeutral),
        borderRadius: AppStyles.borderRadiusM,
      ),
      child: Column(
        children: RolUsuario.values.map((rol) {
          final isLast = rol == RolUsuario.values.last;
          return Column(
            children: [
              RadioListTile<RolUsuario>(
                value: rol,
                groupValue: _rolSeleccionado,
                onChanged: (v) => setState(() {
                  _rolSeleccionado = v!;
                  // Limpia el campo de código al cambiar de rol
                  _codigoAdminController.clear();
                }),
                title: Text(rol.label, style: AppStyles.bodyLarge),
                subtitle: Text(
                  _subtitleParaRol(rol),
                  style: AppStyles.bodySmall,
                ),
                activeColor: AppColors.primaryGreen,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: AppStyles.spacingM),
              ),
              if (!isLast)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _codigoAdminField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Aviso informativo
        Container(
          padding: const EdgeInsets.all(AppStyles.spacingS),
          decoration: AppStyles.warningDecoration,
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  color: AppColors.primaryOrange, size: 18),
              const SizedBox(width: AppStyles.spacingS),
              Expanded(
                child: Text(
                  'Las cuentas de administradora requieren un código institucional.',
                  style:
                      AppStyles.bodySmall.copyWith(color: AppColors.primaryOrange),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppStyles.spacingS),
        // Campo de código
        TextFormField(
          controller: _codigoAdminController,
          obscureText: _obscureCodigo,
          decoration: InputDecoration(
            labelText: 'Código institucional',
            hintText: 'Ingresa el código proporcionado',
            prefixIcon: const Icon(Icons.vpn_key_outlined),
            suffixIcon: IconButton(
              icon: Icon(_obscureCodigo
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              onPressed: () =>
                  setState(() => _obscureCodigo = !_obscureCodigo),
            ),
          ),
          validator: _rolSeleccionado == RolUsuario.administradora
              ? (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'El código institucional es requerido';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  String _subtitleParaRol(RolUsuario rol) {
    return switch (rol) {
      RolUsuario.beneficiaria => 'Reserva tu ración diaria',
      RolUsuario.administradora => 'Gestiona el comedor · requiere código',
      RolUsuario.donante => 'Registra tus donaciones',
    };
  }
}

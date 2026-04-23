import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_styles.dart';
import '../../core/enums/enums.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../app/routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  RolUsuario _rolSeleccionado = RolUsuario.beneficiaria;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
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

                // Nombre completo
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

                // Email
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

                // Contraseña
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

                // Confirmar contraseña
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
                  validator: (v) => (v == null || v.isEmpty)
                      ? AppStrings.campoRequerido
                      : null,
                ),
                const SizedBox(height: AppStyles.spacingL),

                // Selección de rol
                Text('Tipo de cuenta', style: AppStyles.titleMedium),
                const SizedBox(height: AppStyles.spacingS),
                ...RolUsuario.values.map((rol) => RadioListTile<RolUsuario>(
                      value: rol,
                      groupValue: _rolSeleccionado,
                      onChanged: (v) =>
                          setState(() => _rolSeleccionado = v!),
                      title: Text(rol.label, style: AppStyles.bodyLarge),
                      activeColor: AppColors.primaryGreen,
                      contentPadding: EdgeInsets.zero,
                    )),
                const SizedBox(height: AppStyles.spacingL),

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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

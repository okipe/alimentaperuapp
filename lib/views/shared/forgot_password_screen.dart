import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_styles.dart';
import '../../viewmodels/auth_viewmodel.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _enviado = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onEnviar() async {
    if (!_formKey.currentState!.validate()) return;
    final authVM = context.read<AuthViewModel>();
    final ok = await authVM.sendPasswordReset(_emailController.text);
    if (!mounted) return;
    if (ok) {
      setState(() => _enviado = true);
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
      appBar: AppBar(title: const Text(AppStrings.resetPassword)),
      body: SafeArea(
        child: Padding(
          padding: AppStyles.paddingScreen,
          child: _enviado ? _buildSuccess() : _buildForm(authVM),
        ),
      ),
    );
  }

  Widget _buildForm(AuthViewModel authVM) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppStyles.spacingL),
          Text('Recuperar contraseña', style: AppStyles.headlineLarge),
          const SizedBox(height: AppStyles.spacingS),
          Text(
            'Te enviaremos un enlace a tu correo para que puedas restablecer tu contraseña.',
            style: AppStyles.bodyMedium,
          ),
          const SizedBox(height: AppStyles.spacingXL),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: AppStrings.emailLabel,
              hintText: AppStrings.emailHint,
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return AppStrings.campoRequerido;
              if (!v.contains('@')) return 'Correo inválido';
              return null;
            },
          ),
          const SizedBox(height: AppStyles.spacingL),
          ElevatedButton(
            onPressed: authVM.isLoading ? null : _onEnviar,
            child: authVM.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Enviar enlace'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(AppStyles.spacingL),
          decoration: AppStyles.successDecoration,
          child: const Icon(Icons.mark_email_read_outlined,
              size: 64, color: AppColors.primaryGreen),
        ),
        const SizedBox(height: AppStyles.spacingL),
        Text('¡Correo enviado!', style: AppStyles.headlineMedium),
        const SizedBox(height: AppStyles.spacingS),
        Text(
          AppStrings.resetEmailSent,
          style: AppStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppStyles.spacingXL),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.volver),
        ),
      ],
    );
  }
}

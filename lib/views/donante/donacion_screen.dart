import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_styles.dart';
import '../../core/enums/enums.dart';
import '../../models/donacion_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/donacion_viewmodel.dart';

class DonacionScreen extends StatefulWidget {
  const DonacionScreen({super.key});

  @override
  State<DonacionScreen> createState() => _DonacionScreenState();
}

class _DonacionScreenState extends State<DonacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  TipoDonacion _tipoSeleccionado = TipoDonacion.dinero;
  bool _enviado = false;

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRegistrar() async {
    if (!_formKey.currentState!.validate()) return;
    final authVM = context.read<AuthViewModel>();
    final donacionVM = context.read<DonacionViewModel>();

    final donacion = DonacionModel(
      id: '',
      donanteId: authVM.currentUser?.uid ?? '',
      nombreDonante: authVM.currentUser?.displayName ?? 'Donante',
      tipo: _tipoSeleccionado,
      descripcion: _descripcionCtrl.text.trim(),
      monto: _tipoSeleccionado == TipoDonacion.dinero
          ? double.tryParse(_montoCtrl.text)
          : null,
      fechaCreacion: DateTime.now(),
    );

    final ok = await donacionVM.registrarDonacion(donacion);
    if (!mounted) return;
    if (ok) {
      setState(() => _enviado = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              donacionVM.errorMessage ?? AppStrings.errorGenerico),
          backgroundColor: const Color(0xFFB00020),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final donacionVM = context.watch<DonacionViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.nuevaDonacion)),
      body: _enviado
          ? _buildExito()
          : _buildForm(donacionVM),
    );
  }

  Widget _buildForm(DonacionViewModel vm) {
    return SingleChildScrollView(
      padding: AppStyles.paddingScreen,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppStyles.spacingM),
            Text('¿Qué deseas donar?', style: AppStyles.headlineMedium),
            const SizedBox(height: AppStyles.spacingL),

            // Selección de tipo
            Text(AppStrings.tipoDonacion, style: AppStyles.titleMedium),
            const SizedBox(height: AppStyles.spacingS),
            Wrap(
              spacing: AppStyles.spacingS,
              children: TipoDonacion.values
                  .map((tipo) => ChoiceChip(
                        label: Text('${tipo.icono} ${tipo.label}'),
                        selected: _tipoSeleccionado == tipo,
                        onSelected: (_) =>
                            setState(() => _tipoSeleccionado = tipo),
                        selectedColor: AppColors.primaryGreen.withOpacity(0.2),
                        labelStyle: AppStyles.bodyMedium.copyWith(
                          color: _tipoSeleccionado == tipo
                              ? AppColors.primaryGreen
                              : AppColors.textSecondary,
                          fontWeight: _tipoSeleccionado == tipo
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: AppStyles.spacingL),

            // Monto (solo dinero)
            if (_tipoSeleccionado == TipoDonacion.dinero) ...[
              TextFormField(
                controller: _montoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: AppStrings.montoDonacion,
                  hintText: '0.00',
                  prefixText: 'S/ ',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return AppStrings.campoRequerido;
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Ingresa un monto válido';
                  return null;
                },
              ),
              const SizedBox(height: AppStyles.spacingM),
            ],

            // Descripción
            TextFormField(
              controller: _descripcionCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: AppStrings.descripcionDonacion,
                hintText: _tipoSeleccionado == TipoDonacion.dinero
                    ? 'Ej: Donación para el programa de raciones diarias'
                    : _tipoSeleccionado == TipoDonacion.alimentos
                        ? 'Ej: 10 kg de arroz y 5 kg de azúcar'
                        : 'Ej: Envases, cubiertos desechables, etc.',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty)
                      ? AppStrings.campoRequerido
                      : null,
            ),
            const SizedBox(height: AppStyles.spacingM),

            // Aviso
            Container(
              padding: AppStyles.paddingCard,
              decoration: AppStyles.successDecoration,
              child: Row(
                children: [
                  const Icon(Icons.favorite_outline,
                      color: AppColors.primaryGreen),
                  const SizedBox(width: AppStyles.spacingS),
                  Expanded(
                    child: Text(
                      'Tu donación ayuda a proporcionar nutrición con dignidad a nuestras beneficiarias.',
                      style: AppStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppStyles.spacingL),

            ElevatedButton(
              onPressed: vm.isLoading ? null : _onRegistrar,
              child: vm.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(AppStrings.confirmar),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExito() {
    return Center(
      child: Padding(
        padding: AppStyles.paddingScreen,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🙏', style: TextStyle(fontSize: 72)),
            const SizedBox(height: AppStyles.spacingL),
            Text(AppStrings.graciasDonar, style: AppStyles.headlineMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: AppStyles.spacingS),
            Text(
              AppStrings.donacionRegistrada,
              style: AppStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppStyles.spacingXL),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.volver),
            ),
          ],
        ),
      ),
    );
  }
}

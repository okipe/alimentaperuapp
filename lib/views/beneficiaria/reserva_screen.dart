import 'package:alimenta_peru/core/constants/app_colors.dart';
import 'package:alimenta_peru/core/constants/app_strings.dart';
import 'package:alimenta_peru/core/constants/app_styles.dart';
import 'package:alimenta_peru/viewmodels/auth_viewmodel.dart';
import 'package:alimenta_peru/viewmodels/racion_viewmodel.dart';
import 'package:alimenta_peru/viewmodels/reserva_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ReservaScreen extends StatefulWidget {
  const ReservaScreen({super.key});

  @override
  State<ReservaScreen> createState() => _ReservaScreenState();
}

class _ReservaScreenState extends State<ReservaScreen> {
  bool _reservaCreada = false;
  String? _codigoQR;

  Future<void> _onReservar() async {
  final authVM = context.read<AuthViewModel>();
  final racionVM = context.read<RacionViewModel>();
  final reservaVM = context.read<ReservaViewModel>();

  final uid = authVM.currentUser?.uid;
  final racion = racionVM.racionDelDia;

  // ✅ Obtener comedorId del perfil de la beneficiaria
  final beneficiaria = authVM.usuario;
  final comedorId = (beneficiaria != null)
      ? (beneficiaria as dynamic).comedorId as String? ?? ''
      : '';

  if (uid == null || racion == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No hay ración disponible para reservar')),
    );
    return;
  }

  final ok = await reservaVM.crearReserva(
    beneficiariaId: uid,
    menuId: racion.id,   // ✅ esto funciona si los menús están en 'raciones'
    comedorId: comedorId, // ✅ ya no está vacío
    turno: 'mañana',
  );

  if (!mounted) return;
  if (ok) {
    setState(() {
      _reservaCreada = true;
      _codigoQR = reservaVM.reservaActiva?.codigoQR ?? uid;
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(reservaVM.errorMessage ?? 'Error al crear la reserva'),
        backgroundColor: const Color(0xFFB00020),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final racionVM = context.watch<RacionViewModel>();
    final reservaVM = context.watch<ReservaViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.nuevaReserva)),
      body: _reservaCreada
          ? _buildQrView()
          : _buildConfirmacion(context, racionVM, reservaVM),
    );
  }

  Widget _buildConfirmacion(BuildContext context, RacionViewModel racionVM,
      ReservaViewModel reservaVM) {
    final racion = racionVM.racionDelDia;
    return ListView(
      padding: AppStyles.paddingScreen,
      children: [
        const SizedBox(height: AppStyles.spacingM),
        Container(
          padding: AppStyles.paddingCard,
          decoration: AppStyles.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resumen de tu reserva', style: AppStyles.titleLarge),
              const Divider(height: AppStyles.spacingL),
              _fila('Menú del día', racion?.nombre ?? '-'),
              _fila('Porciones disponibles',
                  '${racion?.porcionesDisponibles ?? 0}'),
              _fila('Fecha', racion?.fecha ?? '-'),
            ],
          ),
        ),
        const SizedBox(height: AppStyles.spacingM),
        Container(
          padding: AppStyles.paddingCard,
          decoration: AppStyles.warningDecoration,
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primaryOrange),
              const SizedBox(width: AppStyles.spacingS),
              Expanded(
                child: Text(
                  'Al confirmar, se generará tu código QR para retirar tu ración.',
                  style: AppStyles.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppStyles.spacingL),
        ElevatedButton(
          onPressed: reservaVM.isLoading ? null : _onReservar,
          child: reservaVM.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text(AppStrings.confirmarReserva),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancelar),
        ),
      ],
    );
  }

  Widget _buildQrView() {
    return Center(
      child: Padding(
        padding: AppStyles.paddingScreen,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingL),
              decoration: AppStyles.successDecoration,
              child: const Icon(Icons.check_circle_outline,
                  size: 64, color: AppColors.primaryGreen),
            ),
            const SizedBox(height: AppStyles.spacingL),
            Text(AppStrings.reservaConfirmada, style: AppStyles.headlineMedium),
            const SizedBox(height: AppStyles.spacingS),
            Text(
              'Muestra este código QR al retirar tu ración.',
              style: AppStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppStyles.spacingL),
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingM),
              decoration: AppStyles.cardDecoration,
              child: QrImageView(
                data: _codigoQR ?? 'reserva-sin-id',
                version: QrVersions.auto,
                size: 200,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.primaryGreen,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppStyles.spacingL),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.volver),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fila(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppStyles.bodyMedium),
          Text(valor,
              style:
                  AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

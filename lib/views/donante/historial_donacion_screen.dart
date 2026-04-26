import 'package:alimenta_peru/core/constants/app_colors.dart';
import 'package:alimenta_peru/core/constants/app_strings.dart';
import 'package:alimenta_peru/core/constants/app_styles.dart';
import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:alimenta_peru/models/donacion_model.dart';
import 'package:alimenta_peru/viewmodels/donacion_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HistorialDonacionScreen extends StatelessWidget {
  const HistorialDonacionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DonacionViewModel>();
    final donaciones = vm.donaciones;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.historialDonaciones)),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : donaciones.isEmpty
              ? _buildVacio()
              : Column(
                  children: [
                    _buildResumen(vm),
                    Expanded(
                      child: ListView.separated(
                        padding: AppStyles.paddingScreen,
                        itemCount: donaciones.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppStyles.spacingS),
                        itemBuilder: (_, i) =>
                            _DonacionCard(donacion: donaciones[i]),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💝', style: TextStyle(fontSize: 64)),
          const SizedBox(height: AppStyles.spacingM),
          Text(AppStrings.sinResultados, style: AppStyles.headlineMedium),
          const SizedBox(height: AppStyles.spacingS),
          Text('Aún no tienes donaciones registradas.',
              style: AppStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildResumen(DonacionViewModel vm) {
    return Container(
      margin: const EdgeInsets.all(AppStyles.spacingM),
      padding: AppStyles.paddingCard,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGreen, Color(0xFF14532D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppStyles.borderRadiusL,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _resumenItem(
              '${vm.donaciones.length}', 'Total', AppColors.cardBackground),
          _resumenItem(
              'S/ ${vm.totalDinero.toStringAsFixed(2)}',
              'En dinero',
              AppColors.cardBackground),
          _resumenItem(
              '${vm.donacionesPorTipo[TipoDonacion.alimentos]?.length ?? 0}',
              'Alimentos',
              AppColors.cardBackground),
        ],
      ),
    );
  }

  Widget _resumenItem(String valor, String label, Color color) {
    return Column(
      children: [
        Text(valor,
            style: AppStyles.headlineMedium.copyWith(color: color)),
        Text(label,
            style: AppStyles.caption.copyWith(
                color: color.withValues(alpha: 0.8))),
      ],
    );
  }
}

class _DonacionCard extends StatelessWidget {
  final DonacionModel donacion;
  const _DonacionCard({required this.donacion});

  @override
  Widget build(BuildContext context) {
    // ← fix: donacion.fecha en lugar de donacion.fechaCreacion
    final fechaStr =
        DateFormat('dd MMM yyyy', 'es').format(donacion.fecha);

    return Container(
      padding: AppStyles.paddingCard,
      decoration: AppStyles.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.successGreen,
              borderRadius: AppStyles.borderRadiusM,
            ),
            child: Center(
              child: Text(donacion.tipo.icono,
                  style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: AppStyles.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(donacion.tipo.label, style: AppStyles.titleMedium),
                Text(donacion.descripcion,
                    style: AppStyles.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                Text(fechaStr, style: AppStyles.caption),
              ],
            ),
          ),
          if (donacion.monto != null) ...[
            const SizedBox(width: AppStyles.spacingS),
            Text(
              'S/ ${donacion.monto!.toStringAsFixed(2)}',
              style: AppStyles.titleMedium
                  .copyWith(color: AppColors.primaryOrange),
            ),
          ],
        ],
      ),
    );
  }
}

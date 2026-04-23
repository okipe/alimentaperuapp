import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_styles.dart';
import '../../core/enums/enums.dart';
import '../../models/reserva_model.dart';
import '../../viewmodels/reserva_viewmodel.dart';

class HistorialReservaScreen extends StatelessWidget {
  const HistorialReservaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reservaVM = context.watch<ReservaViewModel>();
    final reservas = reservaVM.reservas;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.historialReservas)),
      body: reservaVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : reservas.isEmpty
              ? _buildVacio()
              : ListView.separated(
                  padding: AppStyles.paddingScreen,
                  itemCount: reservas.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppStyles.spacingS),
                  itemBuilder: (_, i) => _ReservaCard(reserva: reservas[i]),
                ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📋', style: TextStyle(fontSize: 64)),
          const SizedBox(height: AppStyles.spacingM),
          Text(AppStrings.sinResultados, style: AppStyles.headlineMedium),
          const SizedBox(height: AppStyles.spacingS),
          Text('Aún no tienes reservas registradas.',
              style: AppStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _ReservaCard extends StatelessWidget {
  final ReservaModel reserva;
  const _ReservaCard({required this.reserva});

  @override
  Widget build(BuildContext context) {
    final color = Color(reserva.estado.colorValue);
    final fechaStr = DateFormat('dd MMM yyyy · HH:mm', 'es')
        .format(reserva.fechaCreacion);

    return Container(
      padding: AppStyles.paddingCard,
      decoration: AppStyles.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: AppStyles.borderRadiusM,
            ),
            child: Icon(_iconForEstado(reserva.estado), color: color, size: 24),
          ),
          const SizedBox(width: AppStyles.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reserva.estado.label,
                    style: AppStyles.titleMedium.copyWith(color: color)),
                const SizedBox(height: 2),
                Text(fechaStr, style: AppStyles.bodyMedium),
              ],
            ),
          ),
          if (reserva.estado == EstadoReserva.confirmada)
            const Icon(Icons.qr_code_2,
                color: AppColors.primaryGreen, size: 28),
        ],
      ),
    );
  }

  IconData _iconForEstado(EstadoReserva estado) {
    switch (estado) {
      case EstadoReserva.confirmada:
        return Icons.bookmark_added_outlined;
      case EstadoReserva.completada:
        return Icons.check_circle_outline;
      case EstadoReserva.cancelada:
        return Icons.cancel_outlined;
      case EstadoReserva.ausente:
        return Icons.person_off_outlined;
    }
  }
}

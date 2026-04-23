import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_styles.dart';
import '../../viewmodels/reporte_viewmodel.dart';

class ReporteScreen extends StatefulWidget {
  const ReporteScreen({super.key});

  @override
  State<ReporteScreen> createState() => _ReporteScreenState();
}

class _ReporteScreenState extends State<ReporteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReporteViewModel>().generarReporte();
    });
  }

  Future<void> _seleccionarFechaInicio(ReporteViewModel vm) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.fechaInicio,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      vm.setPeriodo(picked, vm.fechaFin);
      await vm.generarReporte();
    }
  }

  Future<void> _seleccionarFechaFin(ReporteViewModel vm) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.fechaFin,
      firstDate: vm.fechaInicio,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      vm.setPeriodo(vm.fechaInicio, picked);
      await vm.generarReporte();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReporteViewModel>();
    final fmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.reportes),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: AppStrings.exportarPdf,
            onPressed: vm.datosReporte == null
                ? null
                : () {
                    // TODO: Implementar exportación PDF con el paquete pdf+printing
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Exportación PDF — próximamente')),
                    );
                  },
          ),
        ],
      ),
      body: ListView(
        padding: AppStyles.paddingScreen,
        children: [
          // Selector de período
          Container(
            padding: AppStyles.paddingCard,
            decoration: AppStyles.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Período', style: AppStyles.titleMedium),
                const SizedBox(height: AppStyles.spacingS),
                Row(
                  children: [
                    Expanded(
                      child: _FechaChip(
                        label: 'Inicio',
                        fecha: fmt.format(vm.fechaInicio),
                        onTap: () => _seleccionarFechaInicio(vm),
                      ),
                    ),
                    const SizedBox(width: AppStyles.spacingS),
                    const Icon(Icons.arrow_forward,
                        color: AppColors.textSecondary, size: 16),
                    const SizedBox(width: AppStyles.spacingS),
                    Expanded(
                      child: _FechaChip(
                        label: 'Fin',
                        fecha: fmt.format(vm.fechaFin),
                        onTap: () => _seleccionarFechaFin(vm),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppStyles.spacingM),

          // Datos del reporte
          if (vm.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (vm.datosReporte == null)
            const Center(child: Text(AppStrings.sinResultados))
          else ...[
            _buildKpis(vm),
            const SizedBox(height: AppStyles.spacingM),
            _buildDetalleReservas(vm),
          ],
        ],
      ),
    );
  }

  Widget _buildKpis(ReporteViewModel vm) {
    final datos = vm.datosReporte!;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppStyles.spacingS,
      mainAxisSpacing: AppStyles.spacingS,
      childAspectRatio: 1.3,
      children: [
        _KpiCard(
            icon: '📋',
            label: 'Total reservas',
            valor: '${datos.totalReservas}',
            color: AppColors.primaryGreen),
        _KpiCard(
            icon: '✅',
            label: 'Completadas',
            valor: '${datos.reservasCompletadas}',
            color: AppColors.primaryGreen),
        _KpiCard(
            icon: '❌',
            label: 'Canceladas',
            valor: '${datos.reservasCanceladas}',
            color: const Color(0xFFEF4444)),
        _KpiCard(
            icon: '👻',
            label: 'Ausentes',
            valor: '${datos.reservasAusentes}',
            color: AppColors.textSecondary),
        _KpiCard(
            icon: '💵',
            label: 'Donaciones',
            valor: 'S/ ${datos.totalDonaciones.toStringAsFixed(2)}',
            color: AppColors.primaryOrange),
        _KpiCard(
            icon: '⚠️',
            label: 'Alertas stock',
            valor: '${datos.insumosConAlerta}',
            color: AppColors.primaryOrange),
      ],
    );
  }

  Widget _buildDetalleReservas(ReporteViewModel vm) {
    final datos = vm.datosReporte!;
    final tasa = datos.tasaAsistencia.toStringAsFixed(1);

    return Container(
      padding: AppStyles.paddingCard,
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tasa de asistencia', style: AppStyles.titleMedium),
          const SizedBox(height: AppStyles.spacingS),
          Row(
            children: [
              Text('$tasa%', style: AppStyles.displayMedium
                  .copyWith(color: AppColors.primaryGreen)),
              const SizedBox(width: AppStyles.spacingS),
              Text('de las reservas fueron completadas',
                  style: AppStyles.bodyMedium),
            ],
          ),
          const SizedBox(height: AppStyles.spacingS),
          ClipRRect(
            borderRadius: AppStyles.borderRadiusFull,
            child: LinearProgressIndicator(
              value: datos.tasaAsistencia / 100,
              minHeight: 10,
              backgroundColor: AppColors.borderNeutral,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _FechaChip extends StatelessWidget {
  final String label;
  final String fecha;
  final VoidCallback onTap;

  const _FechaChip(
      {required this.label, required this.fecha, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppStyles.spacingM, vertical: AppStyles.spacingS),
        decoration: BoxDecoration(
          color: AppColors.successGreen,
          borderRadius: AppStyles.borderRadiusM,
          border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppStyles.caption),
            Text(fecha,
                style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String icon;
  final String label;
  final String valor;
  final Color color;

  const _KpiCard(
      {required this.icon,
      required this.label,
      required this.valor,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppStyles.paddingCard,
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(valor,
              style: AppStyles.headlineMedium.copyWith(color: color)),
          Text(label, style: AppStyles.bodySmall),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_styles.dart';
import '../../core/enums/enums.dart';
import '../../viewmodels/racion_viewmodel.dart';
import '../../models/racion_model.dart';
import '../../app/routes.dart';

class RacionDisponibleScreen extends StatefulWidget {
  const RacionDisponibleScreen({super.key});

  @override
  State<RacionDisponibleScreen> createState() => _RacionDisponibleScreenState();
}

class _RacionDisponibleScreenState extends State<RacionDisponibleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RacionViewModel>().cargarRacionDelDia();
    });
  }

  @override
  Widget build(BuildContext context) {
    final racionVM = context.watch<RacionViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.racionesDisponibles)),
      body: racionVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : racionVM.racionDelDia == null
              ? _buildVacio()
              : _buildDetalle(racionVM.racionDelDia!),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🍽️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: AppStyles.spacingM),
          Text(AppStrings.sinResultados, style: AppStyles.headlineMedium),
          const SizedBox(height: AppStyles.spacingS),
          Text('No hay menú disponible para hoy.', style: AppStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildDetalle(RacionModel racion) {
    final color = racion.estado == EstadoMenu.activo
        ? AppColors.primaryGreen
        : AppColors.primaryOrange;

    return ListView(
      padding: AppStyles.paddingScreen,
      children: [
        Container(
          padding: AppStyles.paddingCard,
          decoration: AppStyles.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🥘', style: TextStyle(fontSize: 48)),
                  const SizedBox(width: AppStyles.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(racion.nombre, style: AppStyles.headlineMedium),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: AppStyles.borderRadiusFull,
                          ),
                          child: Text(
                            racion.estado.label,
                            style: AppStyles.caption.copyWith(color: color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (racion.descripcion != null) ...[
                const SizedBox(height: AppStyles.spacingM),
                Text(racion.descripcion!, style: AppStyles.bodyMedium),
              ],
              const SizedBox(height: AppStyles.spacingM),
              const Divider(),
              const SizedBox(height: AppStyles.spacingS),
              _infoRow(Icons.people_outline, 'Porciones disponibles',
                  '${racion.porcionesDisponibles} / ${racion.porcionesTotal}'),
              _infoRow(Icons.calendar_today_outlined, 'Fecha', racion.fecha),
              const SizedBox(height: AppStyles.spacingM),
              // Datos nutricionales
              if (racion.calorias != null) ...[
                Text('Información nutricional', style: AppStyles.titleMedium),
                const SizedBox(height: AppStyles.spacingS),
                _gridNutricional(racion),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppStyles.spacingL),
        ElevatedButton.icon(
          onPressed: racion.estaDisponible
              ? () => Navigator.pushNamed(context, AppRoutes.reserva)
              : null,
          icon: const Icon(Icons.bookmark_add_outlined),
          label: Text(racion.estaDisponible
              ? AppStrings.nuevaReserva
              : 'No disponible'),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppStyles.spacingS),
          Text('$label: ', style: AppStyles.bodyMedium),
          Text(valor,
              style: AppStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _gridNutricional(RacionModel r) {
    final items = [
      ('${r.calorias!.toInt()} kcal', 'Calorías', '🔥'),
      ('${r.proteinas?.toStringAsFixed(1) ?? '-'}g', 'Proteínas', '💪'),
      ('${r.carbohidratos?.toStringAsFixed(1) ?? '-'}g', 'Carbos', '🌾'),
      ('${r.grasas?.toStringAsFixed(1) ?? '-'}g', 'Grasas', '🫒'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      crossAxisSpacing: AppStyles.spacingS,
      mainAxisSpacing: AppStyles.spacingS,
      children: items
          .map((e) => Container(
                decoration: BoxDecoration(
                  color: AppColors.successGreen,
                  borderRadius: AppStyles.borderRadiusM,
                ),
                padding: const EdgeInsets.all(AppStyles.spacingS),
                child: Row(
                  children: [
                    Text(e.$3, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(e.$1,
                            style: AppStyles.titleMedium.copyWith(
                                color: AppColors.primaryGreen)),
                        Text(e.$2, style: AppStyles.bodySmall),
                      ],
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

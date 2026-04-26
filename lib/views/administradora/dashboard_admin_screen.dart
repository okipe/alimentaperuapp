import 'package:alimenta_peru/app/routes.dart';
import 'package:alimenta_peru/core/constants/app_colors.dart';
import 'package:alimenta_peru/core/constants/app_strings.dart';
import 'package:alimenta_peru/core/constants/app_styles.dart';
import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:alimenta_peru/viewmodels/auth_viewmodel.dart';
import 'package:alimenta_peru/viewmodels/insumo_viewmodel.dart';
import 'package:alimenta_peru/viewmodels/racion_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsumoViewModel>().suscribirAInsumos();
      context.read<RacionViewModel>().cargarRacionDelDia();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final insumoVM = context.watch<InsumoViewModel>();
    final racionVM = context.watch<RacionViewModel>();
    final nombre = authVM.currentUser?.displayName ?? 'Administradora';

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: AppStrings.logout,
            onPressed: () async {
              await authVM.logout();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        ],
      ),
      body: ListView(
        padding: AppStyles.paddingScreen,
        children: [
          const SizedBox(height: AppStyles.spacingS),
          Text('Hola, ${nombre.split(' ').first}',
              style: AppStyles.displayMedium),
          Text(AppStrings.resumen, style: AppStyles.bodyMedium),
          const SizedBox(height: AppStyles.spacingL),

          // Tarjetas de resumen
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.warning_amber_rounded,
                  label: 'Alertas de stock',
                  valor: '${insumoVM.cantidadAlertas}',
                  color: insumoVM.cantidadAlertas > 0
                      ? AppColors.primaryOrange
                      : AppColors.primaryGreen,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.insumoList),
                ),
              ),
              const SizedBox(width: AppStyles.spacingM),
              Expanded(
                child: _StatCard(
                  icon: Icons.restaurant_menu_outlined,
                  label: 'Porciones hoy',
                  valor: racionVM.racionDelDia != null
                      ? '${racionVM.racionDelDia!.porcionesDisponibles}'
                      : '-',
                  color: AppColors.primaryGreen,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.racionPlan),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spacingL),

          // Alertas de stock
          if (insumoVM.cantidadAlertas > 0) ...[
            Text('⚠️ Insumos con alerta', style: AppStyles.titleLarge),
            const SizedBox(height: AppStyles.spacingS),
            ...insumoVM.insumosConAlerta.take(3).map(
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: AppStyles.spacingS),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppStyles.spacingM,
                          vertical: AppStyles.spacingS),
                      decoration: AppStyles.warningDecoration,
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined,
                              color: AppColors.primaryOrange),
                          const SizedBox(width: AppStyles.spacingS),
                          Expanded(
                            child: Text(i.nombre, style: AppStyles.bodyLarge),
                          ),
                          Text(
                            '${i.cantidadActual} ${i.unidad.label}',
                            style: AppStyles.bodyMedium.copyWith(
                                color: AppColors.primaryOrange,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: AppStyles.spacingL),
          ],

          // Módulos de gestión
          Text('Gestión', style: AppStyles.titleLarge),
          const SizedBox(height: AppStyles.spacingS),
          _buildModulos(context),
        ],
      ),
    );
  }

  Widget _buildModulos(BuildContext context) {
    final modulos = [
      const _Modulo(
          icon: Icons.inventory_2_outlined,
          label: AppStrings.insumos,
          route: AppRoutes.insumoList,
          color: AppColors.primaryGreen),
      const _Modulo(
          icon: Icons.restaurant_menu_outlined,
          label: AppStrings.planDiario,
          route: AppRoutes.racionPlan,
          color: AppColors.primaryOrange),
      const _Modulo(
          icon: Icons.bar_chart_outlined,
          label: AppStrings.reportes,
          route: AppRoutes.reporte,
          color: Color(0xFF6366F1)),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppStyles.spacingM,
      mainAxisSpacing: AppStyles.spacingM,
      children: modulos
          .map((m) => GestureDetector(
                onTap: () => Navigator.pushNamed(context, m.route),
                child: Container(
                  decoration: AppStyles.cardDecoration,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(m.icon, size: 32, color: m.color),
                      const SizedBox(height: AppStyles.spacingS),
                      Text(m.label,
                          style: AppStyles.bodySmall,
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valor;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.valor,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppStyles.paddingCard,
        decoration: AppStyles.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppStyles.spacingS),
            Text(valor,
                style: AppStyles.displayMedium.copyWith(color: color)),
            Text(label, style: AppStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _Modulo {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  const _Modulo(
      {required this.icon,
      required this.label,
      required this.route,
      required this.color});
}

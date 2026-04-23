import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_styles.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/donacion_viewmodel.dart';
import '../../app/routes.dart';

class DashboardDonanteScreen extends StatefulWidget {
  const DashboardDonanteScreen({super.key});

  @override
  State<DashboardDonanteScreen> createState() =>
      _DashboardDonanteScreenState();
}

class _DashboardDonanteScreenState extends State<DashboardDonanteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthViewModel>().currentUser?.uid ?? '';
      if (uid.isNotEmpty) {
        context.read<DonacionViewModel>().suscribirADonaciones(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final donacionVM = context.watch<DonacionViewModel>();
    final nombre = authVM.currentUser?.displayName ?? 'Donante';

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
          Text(AppStrings.graciasDonar,
              style: AppStyles.bodyMedium
                  .copyWith(color: AppColors.primaryOrange)),
          const SizedBox(height: AppStyles.spacingL),

          // Resumen de donaciones
          Container(
            padding: AppStyles.paddingCard,
            decoration: AppStyles.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tu impacto', style: AppStyles.titleLarge),
                const SizedBox(height: AppStyles.spacingM),
                Row(
                  children: [
                    Expanded(
                      child: _impactoItem(
                        '${donacionVM.donaciones.length}',
                        'Donaciones',
                        Icons.volunteer_activism_outlined,
                        AppColors.primaryGreen,
                      ),
                    ),
                    Expanded(
                      child: _impactoItem(
                        'S/ ${donacionVM.totalDinero.toStringAsFixed(2)}',
                        'En dinero',
                        Icons.monetization_on_outlined,
                        AppColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppStyles.spacingL),

          // Acciones
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.donacion),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text(AppStrings.nuevaDonacion),
          ),
          const SizedBox(height: AppStyles.spacingS),
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.historialDonacion),
            icon: const Icon(Icons.history_outlined),
            label: const Text(AppStrings.historialDonaciones),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              foregroundColor: AppColors.primaryGreen,
              side: const BorderSide(color: AppColors.primaryGreen),
              shape: RoundedRectangleBorder(
                borderRadius: AppStyles.borderRadiusM,
              ),
            ),
          ),
          const SizedBox(height: AppStyles.spacingL),

          // Últimas donaciones
          if (donacionVM.donaciones.isNotEmpty) ...[
            Text('Últimas donaciones', style: AppStyles.titleLarge),
            const SizedBox(height: AppStyles.spacingS),
            ...donacionVM.donaciones.take(3).map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: AppStyles.spacingS),
                    child: Container(
                      padding: AppStyles.paddingCard,
                      decoration: AppStyles.cardDecoration,
                      child: Row(
                        children: [
                          Text(d.tipo.icono,
                              style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: AppStyles.spacingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.tipo.label,
                                    style: AppStyles.titleMedium),
                                Text(d.descripcion,
                                    style: AppStyles.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          if (d.monto != null)
                            Text(
                              'S/ ${d.monto!.toStringAsFixed(2)}',
                              style: AppStyles.bodyLarge.copyWith(
                                  color: AppColors.primaryOrange,
                                  fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Widget _impactoItem(
      String valor, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(valor,
            style: AppStyles.headlineMedium.copyWith(color: color)),
        Text(label, style: AppStyles.bodySmall),
      ],
    );
  }
}

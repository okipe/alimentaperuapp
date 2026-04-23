import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_styles.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/racion_viewmodel.dart';
import '../../viewmodels/reserva_viewmodel.dart';
import '../../app/routes.dart';

class DashboardBeneficiariaScreen extends StatefulWidget {
  const DashboardBeneficiariaScreen({super.key});

  @override
  State<DashboardBeneficiariaScreen> createState() =>
      _DashboardBeneficiariaScreenState();
}

class _DashboardBeneficiariaScreenState
    extends State<DashboardBeneficiariaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RacionViewModel>().cargarRacionDelDia();
      final uid = context.read<AuthViewModel>().currentUser?.uid ?? '';
      if (uid.isNotEmpty) {
        context.read<ReservaViewModel>().suscribirAReservas(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final racionVM = context.watch<RacionViewModel>();
    final reservaVM = context.watch<ReservaViewModel>();
    final nombre = authVM.currentUser?.displayName ?? 'Beneficiaria';
    final fechaHoy = DateFormat("EEEE d 'de' MMMM", 'es').format(DateTime.now());

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
      body: RefreshIndicator(
        onRefresh: () => racionVM.cargarRacionDelDia(),
        child: ListView(
          padding: AppStyles.paddingScreen,
          children: [
            // Saludo
            const SizedBox(height: AppStyles.spacingS),
            Text('${AppStrings.bienvenida},', style: AppStyles.bodyMedium),
            Text(nombre.split(' ').first, style: AppStyles.displayMedium),
            Text(fechaHoy, style: AppStyles.bodyMedium),
            const SizedBox(height: AppStyles.spacingL),

            // Estado de reserva activa
            if (reservaVM.tieneReservaActiva) ...[
              _buildReservaActivaBanner(context, reservaVM),
              const SizedBox(height: AppStyles.spacingM),
            ],

            // Menú del día
            Text(AppStrings.racionesDisponibles, style: AppStyles.titleLarge),
            const SizedBox(height: AppStyles.spacingS),
            racionVM.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMenuDelDia(context, racionVM),

            const SizedBox(height: AppStyles.spacingL),

            // Accesos rápidos
            Text('Accesos rápidos', style: AppStyles.titleLarge),
            const SizedBox(height: AppStyles.spacingS),
            _buildAccesosRapidos(context),
            const SizedBox(height: AppStyles.spacingL),
          ],
        ),
      ),
    );
  }

  Widget _buildReservaActivaBanner(
      BuildContext context, ReservaViewModel reservaVM) {
    return Container(
      padding: AppStyles.paddingCard,
      decoration: AppStyles.successDecoration,
      child: Row(
        children: [
          const Icon(Icons.qr_code_2, color: AppColors.primaryGreen, size: 40),
          const SizedBox(width: AppStyles.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.reservaConfirmada,
                    style: AppStyles.titleMedium.copyWith(
                        color: AppColors.primaryGreen)),
                Text('Muestra tu QR al retirar tu ración.',
                    style: AppStyles.bodyMedium),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.historialReserva),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuDelDia(
      BuildContext context, RacionViewModel racionVM) {
    final racion = racionVM.racionDelDia;
    if (racion == null) {
      return Container(
        padding: AppStyles.paddingCard,
        decoration: AppStyles.warningDecoration,
        child: Row(
          children: [
            const Text('🍽️', style: TextStyle(fontSize: 32)),
            const SizedBox(width: AppStyles.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sin menú disponible', style: AppStyles.titleMedium),
                  Text('No hay ración planificada para hoy.',
                      style: AppStyles.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: AppStyles.cardDecoration,
      padding: AppStyles.paddingCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🥘', style: TextStyle(fontSize: 32)),
              const SizedBox(width: AppStyles.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(racion.nombre, style: AppStyles.titleMedium),
                    Text('${racion.porcionesDisponibles} porciones disponibles',
                        style: AppStyles.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          if (racion.calorias != null) ...[
            const SizedBox(height: AppStyles.spacingM),
            const Divider(),
            const SizedBox(height: AppStyles.spacingS),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _nutriente('${racion.calorias!.toInt()} kcal', 'Calorías'),
                _nutriente('${racion.proteinas?.toStringAsFixed(1) ?? '-'}g',
                    'Proteínas'),
                _nutriente(
                    '${racion.carbohidratos?.toStringAsFixed(1) ?? '-'}g',
                    'Carbos'),
                _nutriente(
                    '${racion.grasas?.toStringAsFixed(1) ?? '-'}g', 'Grasas'),
              ],
            ),
          ],
          const SizedBox(height: AppStyles.spacingM),
          ElevatedButton.icon(
            onPressed: racion.estaDisponible
                ? () => Navigator.pushNamed(context, AppRoutes.reserva)
                : null,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text(AppStrings.nuevaReserva),
          ),
        ],
      ),
    );
  }

  Widget _nutriente(String valor, String label) {
    return Column(
      children: [
        Text(valor,
            style:
                AppStyles.titleMedium.copyWith(color: AppColors.primaryGreen)),
        Text(label, style: AppStyles.bodySmall),
      ],
    );
  }

  Widget _buildAccesosRapidos(BuildContext context) {
    final opciones = [
      _Acceso(
          icon: Icons.bookmark_outlined,
          label: AppStrings.historialReservas,
          route: AppRoutes.historialReserva),
      _Acceso(
          icon: Icons.restaurant_menu_outlined,
          label: AppStrings.racionesDisponibles,
          route: AppRoutes.racionDisponible),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppStyles.spacingM,
      mainAxisSpacing: AppStyles.spacingM,
      childAspectRatio: 1.2,
      children: opciones
          .map((o) => GestureDetector(
                onTap: () => Navigator.pushNamed(context, o.route),
                child: Container(
                  decoration: AppStyles.cardDecoration,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(o.icon,
                          size: 36, color: AppColors.primaryGreen),
                      const SizedBox(height: AppStyles.spacingS),
                      Text(o.label,
                          style: AppStyles.bodyMedium,
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _Acceso {
  final IconData icon;
  final String label;
  final String route;
  const _Acceso({required this.icon, required this.label, required this.route});
}

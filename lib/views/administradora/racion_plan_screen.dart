import 'package:alimenta_peru/core/constants/app_colors.dart';
import 'package:alimenta_peru/core/constants/app_strings.dart';
import 'package:alimenta_peru/core/constants/app_styles.dart';
import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:alimenta_peru/models/racion_model.dart';
import 'package:alimenta_peru/viewmodels/racion_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RacionPlanScreen extends StatefulWidget {
  const RacionPlanScreen({super.key});

  @override
  State<RacionPlanScreen> createState() => _RacionPlanScreenState();
}

class _RacionPlanScreenState extends State<RacionPlanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RacionViewModel>().suscribirARaciones();
    });
  }

  @override
  Widget build(BuildContext context) {
    final racionVM = context.watch<RacionViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.planDiario)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva ración'),
        backgroundColor: AppColors.primaryGreen,
      ),
      body: racionVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : racionVM.raciones.isEmpty
              ? _buildVacio()
              : ListView.separated(
                  padding: AppStyles.paddingScreen,
                  itemCount: racionVM.raciones.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppStyles.spacingS),
                  itemBuilder: (_, i) => _RacionCard(
                    racion: racionVM.raciones[i],
                    onCambiarEstado: (estado) =>
                        racionVM.cambiarEstadoMenu(
                            racionVM.raciones[i].id, estado),
                  ),
                ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🥘', style: TextStyle(fontSize: 64)),
          const SizedBox(height: AppStyles.spacingM),
          Text('Sin planes registrados', style: AppStyles.headlineMedium),
          const SizedBox(height: AppStyles.spacingS),
          Text('Crea el menú del día para las beneficiarias.',
              style: AppStyles.bodyMedium),
        ],
      ),
    );
  }

  void _showFormDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _RacionForm(),
    );
  }
}

class _RacionCard extends StatelessWidget {
  final RacionModel racion;
  final Future<bool> Function(EstadoMenu) onCambiarEstado;

  const _RacionCard(
      {required this.racion, required this.onCambiarEstado});

  @override
  Widget build(BuildContext context) {
    final colorEstado = racion.estado == EstadoMenu.activo
        ? AppColors.primaryGreen
        : racion.estado == EstadoMenu.agotado
            ? AppColors.primaryOrange
            : AppColors.textSecondary;

    return Container(
      padding: AppStyles.paddingCard,
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🥘', style: TextStyle(fontSize: 28)),
              const SizedBox(width: AppStyles.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(racion.nombre, style: AppStyles.titleMedium),
                    Text(racion.fecha, style: AppStyles.bodyMedium),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorEstado.withOpacity(0.12),
                  borderRadius: AppStyles.borderRadiusFull,
                ),
                child: Text(racion.estado.label,
                    style:
                        AppStyles.caption.copyWith(color: colorEstado)),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spacingS),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${racion.porcionesDisponibles}/${racion.porcionesTotal} porciones',
                style: AppStyles.bodyMedium,
              ),
              PopupMenuButton<EstadoMenu>(
                onSelected: onCambiarEstado,
                child: const Row(
                  children: [
                    Text('Cambiar estado'),
                    Icon(Icons.arrow_drop_down),
                  ],
                ),
                itemBuilder: (_) => EstadoMenu.values
                    .map((e) => PopupMenuItem(
                          value: e,
                          child: Text(e.label),
                        ))
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RacionForm extends StatefulWidget {
  const _RacionForm();

  @override
  State<_RacionForm> createState() => _RacionFormState();
}

class _RacionFormState extends State<_RacionForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _porcionesCtrl = TextEditingController();
  final _caloriasCtrl = TextEditingController();
  DateTime _fecha = DateTime.now();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _porcionesCtrl.dispose();
    _caloriasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<RacionViewModel>();
    final fechaStr = DateFormat('yyyy-MM-dd').format(_fecha);

    return Padding(
      padding: EdgeInsets.only(
        left: AppStyles.spacingM,
        right: AppStyles.spacingM,
        top: AppStyles.spacingL,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppStyles.spacingL,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nueva ración del día', style: AppStyles.titleLarge),
            const SizedBox(height: AppStyles.spacingM),
            TextFormField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre del menú'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? AppStrings.campoRequerido : null,
            ),
            const SizedBox(height: AppStyles.spacingM),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _porcionesCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Porciones totales'),
                    validator: (v) => (v == null || v.isEmpty)
                        ? AppStrings.campoRequerido
                        : null,
                  ),
                ),
                const SizedBox(width: AppStyles.spacingS),
                Expanded(
                  child: TextFormField(
                    controller: _caloriasCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: AppStrings.calorias),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppStyles.spacingM),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined,
                  color: AppColors.primaryGreen),
              title: Text(fechaStr, style: AppStyles.bodyLarge),
              subtitle: const Text('Fecha del menú'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _fecha,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) setState(() => _fecha = picked);
              },
            ),
            const SizedBox(height: AppStyles.spacingL),
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final porciones = int.tryParse(_porcionesCtrl.text) ?? 0;
                final racion = RacionModel(
                  id: '',
                  nombre: _nombreCtrl.text.trim(),
                  fecha: DateFormat('yyyy-MM-dd').format(_fecha),
                  porcionesTotal: porciones,
                  porcionesDisponibles: porciones,
                  estado: EstadoMenu.activo,
                  calorias: double.tryParse(_caloriasCtrl.text),
                );
                final ok = await vm.crearPlanDiario(racion);
                if (!mounted) return;
                if (ok) Navigator.pop(context);
              },
              child: const Text(AppStrings.guardar),
            ),
          ],
        ),
      ),
    );
  }
}

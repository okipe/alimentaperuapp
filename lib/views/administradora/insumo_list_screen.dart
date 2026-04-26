import 'package:alimenta_peru/core/constants/app_colors.dart';
import 'package:alimenta_peru/core/constants/app_strings.dart';
import 'package:alimenta_peru/core/constants/app_styles.dart';
import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:alimenta_peru/models/insumo_model.dart';
import 'package:alimenta_peru/viewmodels/insumo_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InsumoListScreen extends StatefulWidget {
  const InsumoListScreen({super.key});

  @override
  State<InsumoListScreen> createState() => _InsumoListScreenState();
}

class _InsumoListScreenState extends State<InsumoListScreen> {
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final insumoVM = context.watch<InsumoViewModel>();
    final filtrados = insumoVM.insumos
        .where((i) =>
            i.nombre.toLowerCase().contains(_busqueda.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.insumos)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(context),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.nuevoInsumo),
        backgroundColor: AppColors.primaryGreen,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(AppStyles.spacingM),
            child: TextField(
              onChanged: (v) => setState(() => _busqueda = v),
              decoration: InputDecoration(
                hintText: '${AppStrings.buscar} insumo...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _busqueda = ''),
                      )
                    : null,
              ),
            ),
          ),
          // Alerta resumen
          if (insumoVM.cantidadAlertas > 0)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppStyles.spacingM),
              child: Container(
                padding: const EdgeInsets.all(AppStyles.spacingS),
                decoration: AppStyles.warningDecoration,
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.primaryOrange),
                    const SizedBox(width: AppStyles.spacingS),
                    Text(
                      '${insumoVM.cantidadAlertas} insumo(s) con stock bajo',
                      style: AppStyles.bodyMedium
                          .copyWith(color: AppColors.primaryOrange),
                    ),
                  ],
                ),
              ),
            ),
          // Lista
          Expanded(
            child: insumoVM.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtrados.isEmpty
                    ? const Center(child: Text(AppStrings.sinResultados))
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppStyles.spacingM),
                        itemCount: filtrados.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppStyles.spacingS),
                        itemBuilder: (_, i) => _InsumoCard(
                          insumo: filtrados[i],
                          onEditar: () =>
                              _showFormDialog(context, insumo: filtrados[i]),
                          onEliminar: () => _confirmarEliminar(
                              context, insumoVM, filtrados[i].id),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarEliminar(
      BuildContext context, InsumoViewModel vm, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(AppStrings.eliminarInsumo),
        content: const Text(AppStrings.confirmarEliminar),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.cancelar)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(AppStrings.eliminar,
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) await vm.eliminarInsumo(id);
  }

  void _showFormDialog(BuildContext context, {InsumoModel? insumo}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _InsumoForm(insumo: insumo),
    );
  }
}

class _InsumoCard extends StatelessWidget {
  final InsumoModel insumo;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _InsumoCard({
    required this.insumo,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final alertaColor =
        insumo.tieneAlertaStock ? AppColors.primaryOrange : AppColors.primaryGreen;

    return Container(
      padding: AppStyles.paddingCard,
      decoration: AppStyles.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: alertaColor.withOpacity(0.12),
              borderRadius: AppStyles.borderRadiusM,
            ),
            child:
                Icon(Icons.inventory_2_outlined, color: alertaColor, size: 24),
          ),
          const SizedBox(width: AppStyles.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insumo.nombre, style: AppStyles.titleMedium),
                Text(
                  '${insumo.cantidadActual} ${insumo.unidad.label} · mín. ${insumo.cantidadMinima}',
                  style: AppStyles.bodyMedium,
                ),
                if (insumo.tieneAlertaStock)
                  Text('⚠️ ${AppStrings.stockBajo}',
                      style: AppStyles.caption.copyWith(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'editar') onEditar();
              if (v == 'eliminar') onEliminar();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'editar', child: Text(AppStrings.editar)),
              const PopupMenuItem(
                  value: 'eliminar', child: Text(AppStrings.eliminar)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsumoForm extends StatefulWidget {
  final InsumoModel? insumo;
  const _InsumoForm({this.insumo});

  @override
  State<_InsumoForm> createState() => _InsumoFormState();
}

class _InsumoFormState extends State<_InsumoForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _cantidadCtrl;
  late TextEditingController _minimoCtrl;
  UnidadIngrediente _unidad = UnidadIngrediente.kg;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.insumo?.nombre ?? '');
    _cantidadCtrl = TextEditingController(
        text: widget.insumo?.cantidadActual.toString() ?? '');
    _minimoCtrl = TextEditingController(
        text: widget.insumo?.cantidadMinima.toString() ?? '');
    _unidad = widget.insumo?.unidad ?? UnidadIngrediente.kg;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cantidadCtrl.dispose();
    _minimoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<InsumoViewModel>();
    final esEdicion = widget.insumo != null;

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
            Text(
              esEdicion ? AppStrings.editarInsumo : AppStrings.nuevoInsumo,
              style: AppStyles.titleLarge,
            ),
            const SizedBox(height: AppStyles.spacingM),
            TextFormField(
              controller: _nombreCtrl,
              decoration:
                  const InputDecoration(labelText: AppStrings.nombreInsumo),
              validator: (v) =>
                  (v == null || v.isEmpty) ? AppStrings.campoRequerido : null,
            ),
            const SizedBox(height: AppStyles.spacingM),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cantidadCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: AppStrings.cantidadStock),
                    validator: (v) => (v == null || v.isEmpty)
                        ? AppStrings.campoRequerido
                        : null,
                  ),
                ),
                const SizedBox(width: AppStyles.spacingS),
                Expanded(
                  child: TextFormField(
                    controller: _minimoCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: AppStrings.stockMinimo),
                    validator: (v) => (v == null || v.isEmpty)
                        ? AppStrings.campoRequerido
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppStyles.spacingM),
            DropdownButtonFormField<UnidadIngrediente>(
              value: _unidad,
              decoration:
                  const InputDecoration(labelText: AppStrings.unidadMedida),
              items: UnidadIngrediente.values
                  .map((u) => DropdownMenuItem(
                        value: u,
                        child: Text(u.labelLargo),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _unidad = v!),
            ),
            const SizedBox(height: AppStyles.spacingL),
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final insumo = InsumoModel(
                  id: widget.insumo?.id ?? '',
                  nombre: _nombreCtrl.text.trim(),
                  cantidadActual: double.tryParse(_cantidadCtrl.text) ?? 0,
                  cantidadMinima: double.tryParse(_minimoCtrl.text) ?? 0,
                  unidad: _unidad,
                );
                bool ok;
                if (esEdicion) {
                  ok = await vm.actualizarInsumo(insumo);
                } else {
                  ok = await vm.crearInsumo(insumo);
                }
                if (!mounted) return;
                if (ok) Navigator.pop(context);
              },
              child: Text(
                  esEdicion ? AppStrings.guardar : AppStrings.nuevoInsumo),
            ),
          ],
        ),
      ),
    );
  }
}

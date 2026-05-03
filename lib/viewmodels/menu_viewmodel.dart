import 'dart:async';

import 'package:alimenta_peru/models/menu_model.dart';
import 'package:alimenta_peru/services/firestore_service.dart';
import 'package:flutter/foundation.dart';

/// ViewModel de menús diarios — capa ViewModel de MVVM.
///
/// Suscribe a un stream reactivo de [FirestoreService] para mantener la
/// lista de menús del comedor actualizada en tiempo real.
///
/// ## Ciclo de vida
/// Llamar [cargarMenus] una vez al inicializar el widget raíz del módulo.
/// El [dispose] cancela automáticamente la suscripción al stream.
class MenuViewModel extends ChangeNotifier {
  final FirestoreService _service;

  MenuViewModel({FirestoreService? service})
      : _service = service ?? FirestoreService();

  // ── Estado interno ────────────────────────────────────────────────────────
  List<MenuModel> _menus = [];
  MenuModel? _menuSeleccionado;
  bool _cargando = false;
  String? _error;
  StreamSubscription<List<MenuModel>>? _suscripcion;

  // ── Getters públicos ──────────────────────────────────────────────────────
  List<MenuModel> get menus => List.unmodifiable(_menus);
  MenuModel? get menuSeleccionado => _menuSeleccionado;
  bool get cargando => _cargando;
  String? get error => _error;

  /// Menú activo del día actual, o `null` si no existe.
  MenuModel? get menuDeHoy {
    final hoy = DateTime.now();
    try {
      return _menus.firstWhere(
        (m) =>
            m.fecha.year == hoy.year &&
            m.fecha.month == hoy.month &&
            m.fecha.day == hoy.day,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Stream ────────────────────────────────────────────────────────────────

  /// Suscribe al stream de menús del [comedorId] en Firestore.
  ///
  /// Cancela cualquier suscripción previa antes de crear una nueva.
  /// Los menús se actualizan en tiempo real ante cualquier cambio.
  void cargarMenus(String comedorId) {
    if (comedorId.isEmpty) return;

    _suscripcion?.cancel();
    _cargando = true;
    _error = null;
    notifyListeners();

    _suscripcion = _service.getMenusPorComedor(comedorId).listen(
      (lista) {
        _menus = lista;
        _cargando = false;
        notifyListeners();
      },
      onError: (Object e) {
        _error = 'Error al cargar menús: $e';
        _cargando = false;
        notifyListeners();
        debugPrint('[MenuViewModel] Error en stream: $e');
      },
    );
  }

  // ── Selección ─────────────────────────────────────────────────────────────

  /// Marca [menu] como el menú actualmente seleccionado en la UI.
  void seleccionarMenu(MenuModel menu) {
    _menuSeleccionado = menu;
    notifyListeners();
  }

  /// Limpia la selección actual.
  void limpiarSeleccion() {
    _menuSeleccionado = null;
    notifyListeners();
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  /// Crea un nuevo menú en Firestore.
  ///
  /// Retorna `true` si la operación fue exitosa.
  Future<bool> crearMenu(MenuModel menu) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      await _service.crearMenu(menu);
      _cargando = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al crear menú: $e';
      _cargando = false;
      notifyListeners();
      debugPrint('[MenuViewModel] crearMenu error: $e');
      return false;
    }
  }

  // ── Ciclo de vida ─────────────────────────────────────────────────────────

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }
}

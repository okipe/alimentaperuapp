import 'dart:async';

import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:alimenta_peru/models/ingrediente_model.dart';
import 'package:alimenta_peru/models/racion_diaria_model.dart';
import 'package:alimenta_peru/models/racion_model.dart';
import 'package:alimenta_peru/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ViewModel de raciones — capa ViewModel de MVVM.
///
/// Cubre dos dominios complementarios que las Views necesitan:
///
/// **A) Menú del día para beneficiarias** (`RacionModel`)
/// - [cargarRacionDelDia] / [racionDelDia] / [hayRacionDisponible]
/// - [suscribirARaciones] / [raciones]
/// - [crearPlanDiario] / [cambiarEstadoMenu] / [reducirPorcion]
///
/// **B) Registro diario de raciones servidas** (`RacionDiariaModel`)
/// - [cargarDatosHoy] / [racionDiaria]
/// - [incrementarRaciones] / [decrementarRaciones]
/// - [agregarIngrediente] / [eliminarIngrediente]
class RacionViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final FirebaseFirestore _db;

  RacionViewModel({
    FirestoreService? firestoreService,
    FirebaseFirestore? db,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _db = db ?? FirebaseFirestore.instance;

  // ── Estado interno ────────────────────────────────────────────────────────

  // — Dominio A: RacionModel (menú del día) —
  List<RacionModel> _raciones = [];
  RacionModel? _racionDelDia;

  // — Dominio B: RacionDiariaModel (registro servidas) —
  RacionDiariaModel? _racionDiaria;
  List<IngredienteModel> _ingredientes = [];
  int _totalRaciones = 0;

  // — Estado común —
  bool _cargando = false;
  String? _error;

  StreamSubscription<List<RacionModel>>? _racionesSub;
  StreamSubscription<RacionDiariaModel?>? _racionDiariaSub;
  StreamSubscription<List<IngredienteModel>>? _ingredientesSub;
  String? _menuIdActivo;

  // ── Getters públicos ──────────────────────────────────────────────────────

  // — Dominio A —
  List<RacionModel> get raciones => List.unmodifiable(_raciones);
  RacionModel? get racionDelDia => _racionDelDia;
  bool get isLoading => _cargando;
  bool get cargando => _cargando;
  bool get hayRacionDisponible =>
      _racionDelDia?.estado == EstadoMenu.activo &&
      (_racionDelDia?.porcionesDisponibles ?? 0) > 0;

  // — Dominio B —
  RacionDiariaModel? get racionDiaria => _racionDiaria;
  List<IngredienteModel> get ingredientes =>
      List.unmodifiable(_ingredientes);
  int get totalRaciones => _totalRaciones;
  double get porcentajeServido => _racionDiaria?.porcentajeServido ?? 0.0;
  bool get todoServido => _racionDiaria?.todoServido ?? false;

  String? get error => _error;
  String? get errorMessage => _error;

  // ── DOMINIO A — Menú del día (RacionModel) ────────────────────────────────

  /// Carga la ración activa del día desde Firestore (one-shot).
  /// Usado por dashboards y [RacionDisponibleScreen].
  Future<void> cargarRacionDelDia() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final hoy = DateTime.now();
      final fechaStr =
          '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';

      final snap = await _db
          .collection('raciones')
          .where('fecha', isEqualTo: fechaStr)
          .where('estado', isEqualTo: EstadoMenu.activo.name)
          .limit(1)
          .get();

      _racionDelDia =
          snap.docs.isNotEmpty ? RacionModel.fromFirestore(snap.docs.first) : null;
    } catch (e) {
      _error = 'Error al cargar ración del día: $e';
      debugPrint('[RacionViewModel] cargarRacionDelDia: $e');
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Suscribe al stream de raciones (plan diario) desde Firestore.
  /// Usado por [RacionPlanScreen].
  void suscribirARaciones() {
    _racionesSub?.cancel();
    _cargando = true;
    _error = null;
    notifyListeners();

    _racionesSub = _db
        .collection('raciones')
        .orderBy('fecha', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => RacionModel.fromFirestore(d)).toList())
        .listen(
      (lista) {
        _raciones = lista;
        _cargando = false;
        notifyListeners();
      },
      onError: (Object e) {
        _error = 'Error al escuchar raciones: $e';
        _cargando = false;
        notifyListeners();
      },
    );
  }

  /// Crea un nuevo plan diario de ración en Firestore.
  Future<bool> crearPlanDiario(RacionModel racion) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      await _db.collection('raciones').add(racion.toMap());
      _cargando = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al crear plan diario: $e';
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  /// Cambia el estado del menú (activo / cerrado / agotado).
  Future<bool> cambiarEstadoMenu(
      String racionId, EstadoMenu nuevoEstado) async {
    try {
      await _db.collection('raciones').doc(racionId).update({
        'estado': nuevoEstado.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _error = 'Error al cambiar estado del menú: $e';
      notifyListeners();
      return false;
    }
  }

  /// Descuenta 1 porción disponible del menú (operación atómica).
  Future<bool> reducirPorcion(String racionId) async {
    try {
      await _db.collection('raciones').doc(racionId).update({
        'porcionesDisponibles': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _error = 'Error al reducir porción: $e';
      notifyListeners();
      return false;
    }
  }

  // ── DOMINIO B — Registro diario (RacionDiariaModel) ───────────────────────

  /// Suscribe al stream del registro diario del [comedorId] para hoy.
  void cargarDatosHoy(String comedorId) {
    if (comedorId.isEmpty) return;
    _racionDiariaSub?.cancel();
    _ingredientesSub?.cancel();
    _cargando = true;
    _error = null;
    notifyListeners();

    _racionDiariaSub = _firestoreService
        .getRacionDiaria(comedorId, DateTime.now())
        .listen(
      (model) {
        _racionDiaria = model;
        _totalRaciones = model?.totalRaciones ?? 0;
        _cargando = false;
        notifyListeners();
      },
      onError: (Object e) {
        _error = 'Error al cargar datos del día: $e';
        _cargando = false;
        notifyListeners();
      },
    );
  }

  /// Suscribe a los ingredientes del [menuId].
  void cargarIngredientes(String menuId) {
    if (menuId.isEmpty || menuId == _menuIdActivo) return;
    _menuIdActivo = menuId;
    _ingredientesSub?.cancel();

    _ingredientesSub = _firestoreService
        .getIngredientesPorMenu(menuId)
        .listen(
      (lista) {
        _ingredientes = lista;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('[RacionViewModel] ingredientes error: $e');
      },
    );
  }

  /// Incrementa en 1 las raciones servidas del día y persiste.
  Future<void> incrementarRaciones() async {
    final racion = _racionDiaria;
    if (racion == null || racion.racionesServidas >= racion.totalRaciones) {
      return;
    }
    await _persistirRacion(
        racion.copyWith(racionesServidas: racion.racionesServidas + 1));
  }

  /// Decrementa en 1 las raciones servidas del día (mínimo 0).
  Future<void> decrementarRaciones() async {
    final racion = _racionDiaria;
    if (racion == null || racion.racionesServidas <= 0) return;
    await _persistirRacion(
        racion.copyWith(racionesServidas: racion.racionesServidas - 1));
  }

  Future<void> _persistirRacion(RacionDiariaModel racion) async {
    try {
      await _firestoreService.actualizarRacionDiaria(racion);
    } catch (e) {
      _error = 'Error al actualizar raciones servidas.';
      notifyListeners();
    }
  }

  /// Agrega un ingrediente al [menuId].
  Future<bool> agregarIngrediente(
    String nombre,
    double cantidad,
    UnidadIngrediente unidad,
    String menuId,
  ) async {
    if (nombre.trim().isEmpty || cantidad <= 0 || menuId.isEmpty) {
      _error = 'Datos de ingrediente inválidos.';
      notifyListeners();
      return false;
    }
    try {
      await _firestoreService.agregarIngrediente(
        IngredienteModel(
          id: '',
          menuId: menuId,
          nombre: nombre.trim(),
          cantidad: cantidad,
          unidad: unidad,
        ),
      );
      return true;
    } catch (e) {
      _error = 'Error al agregar ingrediente.';
      notifyListeners();
      return false;
    }
  }

  /// Elimina el ingrediente con [id].
  Future<bool> eliminarIngrediente(String id) async {
    try {
      await _firestoreService.eliminarIngrediente(id);
      return true;
    } catch (e) {
      _error = 'Error al eliminar ingrediente.';
      notifyListeners();
      return false;
    }
  }

  // ── Limpieza ──────────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    if (_cargando == false) notifyListeners();
  }

  @override
  void dispose() {
    _racionesSub?.cancel();
    _racionDiariaSub?.cancel();
    _ingredientesSub?.cancel();
    super.dispose();
  }
}

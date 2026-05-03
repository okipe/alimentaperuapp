import 'dart:async';

import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:alimenta_peru/models/donacion_model.dart';
import 'package:alimenta_peru/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum DonacionStatus { idle, loading, success, error }

/// ViewModel de donaciones — capa ViewModel de MVVM.
///
/// Expone tanto la API nueva ([registrarDonacion] con parámetros nombrados,
/// [cargarDonaciones]) como los alias de compatibilidad que las Views
/// existentes usan ([suscribirADonaciones], [isLoading], [errorMessage],
/// [donacionesPorTipo], y [registrarDonacion] aceptando un [DonacionModel]).
class DonacionViewModel extends ChangeNotifier {
  final FirestoreService _service;
  final FirebaseFirestore _db;

  DonacionViewModel({
    FirestoreService? service,
    FirebaseFirestore? db,
  })  : _service = service ?? FirestoreService(),
        _db = db ?? FirebaseFirestore.instance;

  // ── Estado interno ────────────────────────────────────────────────────────
  DonacionStatus _status = DonacionStatus.idle;
  List<DonacionModel> _donaciones = [];
  String? _error;
  StreamSubscription<List<DonacionModel>>? _suscripcion;

  // ── Getters públicos ──────────────────────────────────────────────────────
  DonacionStatus get status => _status;
  List<DonacionModel> get donaciones => List.unmodifiable(_donaciones);
  bool get isLoading => _status == DonacionStatus.loading;
  bool get cargando => _status == DonacionStatus.loading;
  String? get error => _error;

  /// Alias de [error] — usado por las Views existentes.
  String? get errorMessage => _error;

  /// Total acumulado en soles de donaciones en dinero.
  double get totalDinero => _donaciones
      .where((d) => d.tipo == TipoDonacion.dinero)
      .fold(0.0, (sum, d) => sum + (d.monto ?? 0.0));

  /// Donaciones agrupadas por tipo.
  /// Alias: las Views usan [donacionesPorTipo], internamente es [porTipo].
  Map<TipoDonacion, List<DonacionModel>> get donacionesPorTipo {
    final mapa = <TipoDonacion, List<DonacionModel>>{};
    for (final d in _donaciones) {
      mapa.putIfAbsent(d.tipo, () => []).add(d);
    }
    return mapa;
  }

  // ── Stream de donaciones ──────────────────────────────────────────────────

  /// Suscribe al historial de donaciones de un donante por [donanteId].
  /// Alias usado por [DashboardDonanteScreen].
  void suscribirADonaciones(String donanteId) {
    if (donanteId.isEmpty) return;
    _suscripcion?.cancel();
    _status = DonacionStatus.loading;
    _error = null;
    notifyListeners();

    _suscripcion = _db
        .collection('donaciones')
        .where('donanteId', isEqualTo: donanteId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => DonacionModel.fromFirestore(d)).toList())
        .listen(
      (lista) {
        _donaciones = lista;
        _status = DonacionStatus.success;
        notifyListeners();
      },
      onError: (Object e) {
        _error = 'Error al cargar donaciones: $e';
        _status = DonacionStatus.error;
        notifyListeners();
      },
    );
  }

  /// Suscribe al historial de donaciones del [comedorId].
  /// Usada por la administradora.
  void cargarDonaciones(String comedorId) {
    if (comedorId.isEmpty) return;
    _suscripcion?.cancel();
    _status = DonacionStatus.loading;
    _error = null;
    notifyListeners();

    _suscripcion = _service.getDonaciones(comedorId).listen(
      (lista) {
        _donaciones = lista;
        _status = DonacionStatus.success;
        notifyListeners();
      },
      onError: (Object e) {
        _error = 'Error al cargar donaciones: $e';
        _status = DonacionStatus.error;
        notifyListeners();
      },
    );
  }

  // ── Registro ──────────────────────────────────────────────────────────────

  /// Registra una donación aceptando directamente un [DonacionModel].
  /// Usado por [DonacionScreen] existente.
  ///
  /// También puede llamarse con parámetros nombrados — ver sobrecarga abajo.
  Future<bool> registrarDonacion(DonacionModel donacion) async {
    if (!_validar(donacion)) return false;
    _setLoading();
    try {
      await _db.collection('donaciones').add(donacion.toMap());
      _status = DonacionStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al registrar la donación. Verifica tu conexión.');
      return false;
    }
  }

  /// Versión con parámetros nombrados para la API nueva.
  Future<bool> registrarDonacionParams({
    required String donanteId,
    required String comedorId,
    required TipoDonacion tipo,
    required String descripcion,
    double? monto,
  }) async {
    final donacion = DonacionModel(
      id: '',
      donanteId: donanteId,
      comedorId: comedorId,
      tipo: tipo,
      descripcion: descripcion.trim(),
      monto: tipo == TipoDonacion.dinero ? monto : null,
      fecha: DateTime.now(),
    );
    return registrarDonacion(donacion);
  }

  // ── Validaciones ──────────────────────────────────────────────────────────

  bool _validar(DonacionModel donacion) {
    if (donacion.tipo == TipoDonacion.dinero &&
        (donacion.monto == null || donacion.monto! <= 0)) {
      _setError('El monto de la donación debe ser mayor a 0.');
      return false;
    }
    if (donacion.descripcion.trim().isEmpty) {
      _setError('La descripción de la donación es obligatoria.');
      return false;
    }
    return true;
  }

  // ── Limpieza ──────────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    if (_status == DonacionStatus.error) _status = DonacionStatus.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }

  // ── Helpers privados ──────────────────────────────────────────────────────

  void _setLoading() {
    _status = DonacionStatus.loading;
    _error = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _error = msg;
    _status = DonacionStatus.error;
    notifyListeners();
    debugPrint('[DonacionViewModel] Error: $msg');
  }
}

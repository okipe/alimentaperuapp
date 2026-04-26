import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:alimenta_peru/models/donacion_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum DonacionStatus { idle, loading, success, error }

/// ViewModel de donaciones.
///
/// Registro, validación e historial de donaciones por tipo.
class DonacionViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DonacionStatus _status = DonacionStatus.idle;
  List<DonacionModel> _donaciones = [];
  String? _errorMessage;

  // ── Getters ──────────────────────────────────────────────────────────────
  DonacionStatus get status => _status;
  List<DonacionModel> get donaciones => List.unmodifiable(_donaciones);
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == DonacionStatus.loading;

  /// Total acumulado de donaciones en dinero.
  double get totalDinero => _donaciones
      .where((d) => d.tipo == TipoDonacion.dinero)
      .fold(0.0, (sum, d) => sum + (d.monto ?? 0.0));

  /// Donaciones agrupadas por tipo.
  Map<TipoDonacion, List<DonacionModel>> get donacionesPorTipo {
    final mapa = <TipoDonacion, List<DonacionModel>>{};
    for (final d in _donaciones) {
      mapa.putIfAbsent(d.tipo, () => []).add(d);
    }
    return mapa;
  }

  // ── Stream de donaciones por usuario ─────────────────────────────────────
  void suscribirADonaciones(String donanteId) {
    _status = DonacionStatus.loading;
    notifyListeners();

    _db
        .collection('donaciones')
        .where('donanteId', isEqualTo: donanteId)
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _donaciones =
            snapshot.docs.map((d) => DonacionModel.fromFirestore(d)).toList();
        _status = DonacionStatus.success;
        notifyListeners();
      },
      onError: (e) => _setError('Error al cargar donaciones: $e'),
    );
  }

  // ── Registrar donación ───────────────────────────────────────────────────
  Future<bool> registrarDonacion(DonacionModel donacion) async {
    _setLoading();
    try {
      if (!_validar(donacion)) return false;

      await _db.collection('donaciones').add(donacion.toMap());
      _status = DonacionStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al registrar donación: $e');
      return false;
    }
  }

  // ── Validaciones ─────────────────────────────────────────────────────────
  bool _validar(DonacionModel donacion) {
    if (donacion.tipo == TipoDonacion.dinero &&
        (donacion.monto == null || donacion.monto! <= 0)) {
      _setError('El monto de la donación debe ser mayor a 0');
      return false;
    }
    if (donacion.descripcion.trim().isEmpty) {
      _setError('Ingresa una descripción para la donación');
      return false;
    }
    return true;
  }

  // ── Helpers privados ─────────────────────────────────────────────────────
  void _setLoading() {
    _status = DonacionStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _status = DonacionStatus.error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == DonacionStatus.error) _status = DonacionStatus.idle;
    notifyListeners();
  }
}

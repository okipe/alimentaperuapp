import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/enums/enums.dart';
import '../models/racion_model.dart';

enum RacionStatus { idle, loading, success, error }

/// ViewModel de planificación de raciones.
///
/// Gestiona el plan diario, cálculo automático de porciones y
/// disponibilidad del menú del día.
class RacionViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  RacionStatus _status = RacionStatus.idle;
  List<RacionModel> _raciones = [];
  RacionModel? _racionDelDia;
  String? _errorMessage;

  // ── Getters ──────────────────────────────────────────────────────────────
  RacionStatus get status => _status;
  List<RacionModel> get raciones => List.unmodifiable(_raciones);
  RacionModel? get racionDelDia => _racionDelDia;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == RacionStatus.loading;
  bool get hayRacionDisponible =>
      _racionDelDia?.estado == EstadoMenu.activo &&
      (_racionDelDia?.porcionesDisponibles ?? 0) > 0;

  // ── Cargar plan del día ──────────────────────────────────────────────────
  Future<void> cargarRacionDelDia() async {
    _setLoading();
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

      if (snap.docs.isNotEmpty) {
        _racionDelDia = RacionModel.fromFirestore(snap.docs.first);
      } else {
        _racionDelDia = null;
      }

      _status = RacionStatus.success;
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar ración del día: $e');
    }
  }

  // ── Stream de raciones ───────────────────────────────────────────────────
  void suscribirARaciones() {
    _status = RacionStatus.loading;
    notifyListeners();

    _db
        .collection('raciones')
        .orderBy('fecha', descending: true)
        .limit(30)
        .snapshots()
        .listen(
      (snapshot) {
        _raciones =
            snapshot.docs.map((d) => RacionModel.fromFirestore(d)).toList();
        _status = RacionStatus.success;
        notifyListeners();
      },
      onError: (error) {
        _setError('Error al escuchar raciones: $error');
      },
    );
  }

  // ── Crear plan diario ────────────────────────────────────────────────────
  Future<bool> crearPlanDiario(RacionModel racion) async {
    _setLoading();
    try {
      await _db.collection('raciones').add(racion.toMap());
      _status = RacionStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al crear plan diario: $e');
      return false;
    }
  }

  // ── Cambiar estado del menú ──────────────────────────────────────────────
  Future<bool> cambiarEstadoMenu(String racionId, EstadoMenu nuevoEstado) async {
    try {
      await _db.collection('raciones').doc(racionId).update({
        'estado': nuevoEstado.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _setError('Error al cambiar estado del menú: $e');
      return false;
    }
  }

  // ── Reducir porciones disponibles ────────────────────────────────────────
  Future<bool> reducirPorcion(String racionId) async {
    try {
      await _db.collection('raciones').doc(racionId).update({
        'porcionesDisponibles': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _setError('Error al reducir porción: $e');
      return false;
    }
  }

  // ── Helpers privados ─────────────────────────────────────────────────────
  void _setLoading() {
    _status = RacionStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _status = RacionStatus.error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == RacionStatus.error) _status = RacionStatus.idle;
    notifyListeners();
  }
}

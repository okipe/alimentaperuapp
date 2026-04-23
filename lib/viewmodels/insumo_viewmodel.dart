import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/enums/enums.dart';
import '../models/insumo_model.dart';

enum InsumoStatus { idle, loading, success, error }

/// ViewModel de gestión de insumos (stock, alertas, CRUD).
class InsumoViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  InsumoStatus _status = InsumoStatus.idle;
  List<InsumoModel> _insumos = [];
  String? _errorMessage;

  // ── Getters ──────────────────────────────────────────────────────────────
  InsumoStatus get status => _status;
  List<InsumoModel> get insumos => List.unmodifiable(_insumos);
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == InsumoStatus.loading;

  /// Insumos con stock por debajo del mínimo.
  List<InsumoModel> get insumosConAlerta =>
      _insumos.where((i) => i.tieneAlertaStock).toList();

  /// Cantidad total de alertas activas.
  int get cantidadAlertas => insumosConAlerta.length;

  // ── Stream de Firestore ──────────────────────────────────────────────────
  void suscribirAInsumos() {
    _status = InsumoStatus.loading;
    notifyListeners();

    _db.collection('insumos').orderBy('nombre').snapshots().listen(
      (snapshot) {
        _insumos = snapshot.docs
            .map((doc) => InsumoModel.fromFirestore(doc))
            .toList();
        _status = InsumoStatus.success;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Error al cargar insumos: $error';
        _status = InsumoStatus.error;
        notifyListeners();
      },
    );
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────
  Future<bool> crearInsumo(InsumoModel insumo) async {
    _setLoading();
    try {
      await _db.collection('insumos').add(insumo.toMap());
      _status = InsumoStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al crear insumo: $e');
      return false;
    }
  }

  Future<bool> actualizarInsumo(InsumoModel insumo) async {
    _setLoading();
    try {
      await _db.collection('insumos').doc(insumo.id).update(insumo.toMap());
      _status = InsumoStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al actualizar insumo: $e');
      return false;
    }
  }

  Future<bool> eliminarInsumo(String id) async {
    _setLoading();
    try {
      await _db.collection('insumos').doc(id).delete();
      _status = InsumoStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al eliminar insumo: $e');
      return false;
    }
  }

  Future<bool> actualizarStock(String id, double nuevaCantidad) async {
    try {
      await _db.collection('insumos').doc(id).update({
        'cantidadActual': nuevaCantidad,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _setError('Error al actualizar stock: $e');
      return false;
    }
  }

  // ── Helpers privados ─────────────────────────────────────────────────────
  void _setLoading() {
    _status = InsumoStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _status = InsumoStatus.error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == InsumoStatus.error) _status = InsumoStatus.idle;
    notifyListeners();
  }
}

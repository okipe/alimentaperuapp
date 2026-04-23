import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/enums/enums.dart';
import '../models/reserva_model.dart';

enum ReservaStatus { idle, loading, success, error }

/// ViewModel de reservas de raciones.
///
/// Cubre crear, confirmar (por QR), cancelar y listar historial.
class ReservaViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ReservaStatus _status = ReservaStatus.idle;
  List<ReservaModel> _reservas = [];
  ReservaModel? _reservaActiva;
  String? _errorMessage;

  // ── Getters ──────────────────────────────────────────────────────────────
  ReservaStatus get status => _status;
  List<ReservaModel> get reservas => List.unmodifiable(_reservas);
  ReservaModel? get reservaActiva => _reservaActiva;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ReservaStatus.loading;
  bool get tieneReservaActiva =>
      _reservaActiva != null &&
      _reservaActiva!.estado == EstadoReserva.confirmada;

  // ── Cargar reservas de usuario ───────────────────────────────────────────
  void suscribirAReservas(String usuarioId) {
    _status = ReservaStatus.loading;
    notifyListeners();

    _db
        .collection('reservas')
        .where('usuarioId', isEqualTo: usuarioId)
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _reservas =
            snapshot.docs.map((d) => ReservaModel.fromFirestore(d)).toList();
        _reservaActiva = _reservas
            .where((r) => r.estado == EstadoReserva.confirmada)
            .firstOrNull;
        _status = ReservaStatus.success;
        notifyListeners();
      },
      onError: (e) => _setError('Error al cargar reservas: $e'),
    );
  }

  // ── Crear reserva ────────────────────────────────────────────────────────
  Future<bool> crearReserva({
    required String usuarioId,
    required String racionId,
    required String nombreUsuario,
  }) async {
    _setLoading();
    try {
      // Verificar que el usuario no tenga ya una reserva activa hoy
      final hoy = DateTime.now();
      final inicioDelDia = DateTime(hoy.year, hoy.month, hoy.day);
      final finDelDia = inicioDelDia.add(const Duration(days: 1));

      final existente = await _db
          .collection('reservas')
          .where('usuarioId', isEqualTo: usuarioId)
          .where('estado', isEqualTo: EstadoReserva.confirmada.name)
          .where('fechaCreacion', isGreaterThanOrEqualTo: inicioDelDia)
          .where('fechaCreacion', isLessThan: finDelDia)
          .get();

      if (existente.docs.isNotEmpty) {
        _setError('Ya tienes una reserva activa para hoy');
        return false;
      }

      final nuevaReserva = ReservaModel(
        id: '',
        usuarioId: usuarioId,
        racionId: racionId,
        nombreUsuario: nombreUsuario,
        estado: EstadoReserva.confirmada,
        fechaCreacion: DateTime.now(),
      );

      await _db.collection('reservas').add(nuevaReserva.toMap());
      _status = ReservaStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al crear reserva: $e');
      return false;
    }
  }

  // ── Confirmar retiro por QR ──────────────────────────────────────────────
  Future<bool> confirmarRetiro(String reservaId) async {
    _setLoading();
    try {
      await _db.collection('reservas').doc(reservaId).update({
        'estado': EstadoReserva.completada.name,
        'fechaRetiro': FieldValue.serverTimestamp(),
      });
      _status = ReservaStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al confirmar retiro: $e');
      return false;
    }
  }

  // ── Cancelar reserva ─────────────────────────────────────────────────────
  Future<bool> cancelarReserva(String reservaId) async {
    _setLoading();
    try {
      await _db.collection('reservas').doc(reservaId).update({
        'estado': EstadoReserva.cancelada.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _status = ReservaStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al cancelar reserva: $e');
      return false;
    }
  }

  // ── Marcar ausente ───────────────────────────────────────────────────────
  Future<bool> marcarAusente(String reservaId) async {
    try {
      await _db.collection('reservas').doc(reservaId).update({
        'estado': EstadoReserva.ausente.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _setError('Error al marcar ausente: $e');
      return false;
    }
  }

  // ── Helpers privados ─────────────────────────────────────────────────────
  void _setLoading() {
    _status = ReservaStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _status = ReservaStatus.error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == ReservaStatus.error) _status = ReservaStatus.idle;
    notifyListeners();
  }
}

import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:alimenta_peru/models/reserva_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

enum ReservaStatus { idle, loading, success, error }

/// ViewModel de reservas de raciones.
///
/// Cubre crear, confirmar (por QR), cancelar y listar historial.
class ReservaViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _uuid = Uuid();

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
  void suscribirAReservas(String beneficiariaId) {
    _status = ReservaStatus.loading;
    notifyListeners();

    _db
        .collection('reservas')
        .where('beneficiariaId', isEqualTo: beneficiariaId)
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
      onError: (Object e) => _setError('Error al cargar reservas: $e'),
    );
  }

  // ── Crear reserva ────────────────────────────────────────────────────────
  Future<bool> crearReserva({
    required String beneficiariaId,
    required String menuId,
    required String comedorId,
    required String turno,
    int numRaciones = 1,
  }) async {
    _setLoading();
    try {
      final hoy = DateTime.now();
      final inicioDelDia = DateTime(hoy.year, hoy.month, hoy.day);
      final finDelDia = inicioDelDia.add(const Duration(days: 1));

      // Verificar que la beneficiaria no tenga una reserva activa hoy
      final existente = await _db
          .collection('reservas')
          .where('beneficiariaId', isEqualTo: beneficiariaId)
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
        beneficiariaId: beneficiariaId,
        menuId: menuId,
        comedorId: comedorId,
        fecha: hoy,
        turno: turno,
        numRaciones: numRaciones.clamp(1, 3),
        estado: EstadoReserva.confirmada,
        codigoQR: _uuid.v4(),
        horaLimite: DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 0),
        fechaCreacion: hoy,
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
        'updatedAt': FieldValue.serverTimestamp(),
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

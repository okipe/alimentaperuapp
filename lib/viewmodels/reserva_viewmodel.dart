import 'dart:async';

import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:alimenta_peru/core/exceptions/app_exception.dart';
import 'package:alimenta_peru/models/reserva_model.dart';
import 'package:alimenta_peru/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// ViewModel de reservas de raciones — capa ViewModel de MVVM.
///
/// Cubre el ciclo completo de una reserva:
/// creación → QR → cancelación → confirmación de presencia.
///
/// Expone la API nueva ([crearReserva] con parámetros nombrados,
/// [cargarReservasHoy]) y también alias de compatibilidad con las Views
/// existentes ([suscribirAReservas], [tieneReservaActiva],
/// [reservaActiva], [isLoading], [errorMessage]).
class ReservaViewModel extends ChangeNotifier {
  final FirestoreService _service;
  final FirebaseFirestore _db;
  static const _uuid = Uuid();

  ReservaViewModel({
    FirestoreService? service,
    FirebaseFirestore? db,
  })  : _service = service ?? FirestoreService(),
        _db = db ?? FirebaseFirestore.instance;

  // ── Estado interno ────────────────────────────────────────────────────────
  List<ReservaModel> _reservas = [];
  ReservaModel? _reservaActual;
  int _numRaciones = 1;
  bool _cargando = false;
  String? _error;
  StreamSubscription<List<ReservaModel>>? _suscripcion;

  // ── Getters públicos ──────────────────────────────────────────────────────
  List<ReservaModel> get reservas => List.unmodifiable(_reservas);

  /// Reserva confirmada activa (primera que encontremos en la lista).
  ReservaModel? get reservaActual => _reservaActual;

  /// Alias de [reservaActual] — usado por [ReservaScreen].
  ReservaModel? get reservaActiva => _reservaActual;

  int get numRaciones => _numRaciones;
  bool get isLoading => _cargando;
  bool get cargando => _cargando;
  String? get error => _error;

  /// Alias de [error] — usado por las Views existentes.
  String? get errorMessage => _error;

  /// `true` si hay una reserva en estado [EstadoReserva.confirmada].
  bool get tieneReservaActiva =>
      _reservaActual != null &&
      _reservaActual!.estado == EstadoReserva.confirmada;

  /// Alias de [tieneReservaActiva].
  bool get hayReservaActiva => tieneReservaActiva;

  // ── Stream de reservas ────────────────────────────────────────────────────

  /// Suscribe al historial de reservas de la [beneficiariaId].
  /// Alias esperado por [DashboardBeneficiariaScreen] e [HistorialReservaScreen].
  void suscribirAReservas(String beneficiariaId) {
    if (beneficiariaId.isEmpty) return;
    _suscripcion?.cancel();
    _cargando = true;
    _error = null;
    notifyListeners();

    _suscripcion = _db
        .collection('reservas')
        .where('beneficiariaId', isEqualTo: beneficiariaId)
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ReservaModel.fromFirestore(d)).toList())
        .listen(
      (lista) {
        _reservas = lista;
        _reservaActual = lista
            .where((r) => r.estado == EstadoReserva.confirmada)
            .cast<ReservaModel?>()
            .firstOrNull;
        _cargando = false;
        notifyListeners();
      },
      onError: (Object e) {
        _error = 'Error al cargar reservas: $e';
        _cargando = false;
        notifyListeners();
      },
    );
  }

  /// Suscribe a las reservas del [comedorId] para el día de hoy.
  /// Usado por la administradora.
  void cargarReservasHoy(String comedorId) {
    if (comedorId.isEmpty) return;
    _suscripcion?.cancel();
    _cargando = true;
    _error = null;
    notifyListeners();

    _suscripcion = _service
        .getReservasPorFecha(comedorId, DateTime.now())
        .listen(
      (lista) {
        _reservas = lista;
        _cargando = false;
        notifyListeners();
      },
      onError: (Object e) {
        _error = 'Error al cargar reservas de hoy: $e';
        _cargando = false;
        notifyListeners();
      },
    );
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  /// Crea una reserva atómica (descuenta raciones del menú).
  ///
  /// Valida que [numRaciones] <= 3. El parámetro [turno] es opcional;
  /// si no se indica, se deduce de la hora actual.
  Future<bool> crearReserva({
    required String menuId,
    required String beneficiariaId,
    required String comedorId,
    String? turno,
    int? numRaciones,
  }) async {
    final raciones = numRaciones ?? _numRaciones;
    if (raciones < 1 || raciones > 3) {
      _setError('El número de raciones debe estar entre 1 y 3.');
      return false;
    }
    _setLoading();
    try {
      final hoy = DateTime.now();
      final turnoFinal =
          turno ?? (hoy.hour < 12 ? 'mañana' : 'tarde');
      final horaLimite =
          DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 0);

      final reserva = ReservaModel(
        id: '',
        beneficiariaId: beneficiariaId,
        menuId: menuId,
        comedorId: comedorId,
        fecha: hoy,
        turno: turnoFinal,
        numRaciones: raciones.clamp(1, 3),
        estado: EstadoReserva.confirmada,
        codigoQR: _uuid.v4(),
        horaLimite: horaLimite,
        fechaCreacion: hoy,
      );

      await _service.crearReserva(reserva);
      // Actualizamos la reserva actual leyendo la lista actualizada
      _reservaActual = reserva;
      _cargando = false;
      _error = null;
      notifyListeners();
      return true;
    } on ReservaException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Error al crear la reserva. Verifica tu conexión.');
      return false;
    }
  }

  /// Cancela la reserva y devuelve las raciones al menú.
  Future<bool> cancelarReserva(String reservaId) async {
    _setLoading();
    try {
      await _service.cancelarReserva(reservaId);
      if (_reservaActual?.id == reservaId) _reservaActual = null;
      _cargando = false;
      _error = null;
      notifyListeners();
      return true;
    } on ReservaException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Error al cancelar la reserva.');
      return false;
    }
  }

  /// Marca la reserva como completada (retiro por QR).
  Future<bool> confirmarRetiro(String reservaId) async {
    _setLoading();
    try {
      await _service.marcarPresencia(reservaId);
      _cargando = false;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al confirmar retiro.');
      return false;
    }
  }

  /// Alias de [confirmarRetiro] — API nueva.
  Future<bool> marcarPresencia(String reservaId) =>
      confirmarRetiro(reservaId);

  /// Marca la reserva como ausente.
  Future<bool> marcarAusente(String reservaId) async {
    try {
      await _db.collection('reservas').doc(reservaId).update({
        'estado': EstadoReserva.ausente.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      _setError('Error al marcar ausente.');
      return false;
    }
  }

  // ── Control de raciones ───────────────────────────────────────────────────

  /// Incrementa el contador de raciones (máximo 3).
  void incrementarRaciones() {
    if (_numRaciones < 3) {
      _numRaciones++;
      notifyListeners();
    }
  }

  /// Decrementa el contador de raciones (mínimo 1).
  void decrementarRaciones() {
    if (_numRaciones > 1) {
      _numRaciones--;
      notifyListeners();
    }
  }

  // ── Limpieza ──────────────────────────────────────────────────────────────

  void limpiarReservaActual() {
    _reservaActual = null;
    _numRaciones = 1;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    if (_cargando == false) notifyListeners();
  }

  @override
  void dispose() {
    _suscripcion?.cancel();
    super.dispose();
  }

  // ── Helpers privados ──────────────────────────────────────────────────────

  void _setLoading() {
    _cargando = true;
    _error = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _error = msg;
    _cargando = false;
    notifyListeners();
    debugPrint('[ReservaViewModel] Error: $msg');
  }
}

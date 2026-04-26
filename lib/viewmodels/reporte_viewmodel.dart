import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum ReporteStatus { idle, loading, success, error }

/// Datos consolidados para un reporte de período.
class DatosReporte {
  final int totalReservas;
  final int reservasCompletadas;
  final int reservasCanceladas;
  final int reservasAusentes;
  final double totalDonaciones;
  final int insumosConAlerta;
  final DateTime fechaInicio;
  final DateTime fechaFin;

  const DatosReporte({
    required this.totalReservas,
    required this.reservasCompletadas,
    required this.reservasCanceladas,
    required this.reservasAusentes,
    required this.totalDonaciones,
    required this.insumosConAlerta,
    required this.fechaInicio,
    required this.fechaFin,
  });

  double get tasaAsistencia => totalReservas == 0
      ? 0
      : (reservasCompletadas / totalReservas) * 100;
}

/// ViewModel de reportes consolidados.
class ReporteViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ReporteStatus _status = ReporteStatus.idle;
  DatosReporte? _datosReporte;
  String? _errorMessage;
  DateTime _fechaInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fechaFin = DateTime.now();

  // ── Getters ──────────────────────────────────────────────────────────────
  ReporteStatus get status => _status;
  DatosReporte? get datosReporte => _datosReporte;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ReporteStatus.loading;
  DateTime get fechaInicio => _fechaInicio;
  DateTime get fechaFin => _fechaFin;

  // ── Selección de período ─────────────────────────────────────────────────
  void setPeriodo(DateTime inicio, DateTime fin) {
    _fechaInicio = inicio;
    _fechaFin = fin;
    notifyListeners();
  }

  // ── Generar reporte ──────────────────────────────────────────────────────
  Future<void> generarReporte() async {
    _setLoading();
    try {
      // Consultar reservas del período
      final snapReservas = await _db
          .collection('reservas')
          .where('fechaCreacion', isGreaterThanOrEqualTo: _fechaInicio)
          .where('fechaCreacion', isLessThanOrEqualTo: _fechaFin)
          .get();

      int completadas = 0, canceladas = 0, ausentes = 0;
      for (final doc in snapReservas.docs) {
        final estado = doc.data()['estado'] as String? ?? '';
        if (estado == EstadoReserva.completada.name) completadas++;
        if (estado == EstadoReserva.cancelada.name) canceladas++;
        if (estado == EstadoReserva.ausente.name) ausentes++;
      }

      // Consultar donaciones del período
      final snapDonaciones = await _db
          .collection('donaciones')
          .where('tipo', isEqualTo: TipoDonacion.dinero.name)
          .where('fechaCreacion', isGreaterThanOrEqualTo: _fechaInicio)
          .where('fechaCreacion', isLessThanOrEqualTo: _fechaFin)
          .get();

      double totalDonaciones = 0;
      for (final doc in snapDonaciones.docs) {
        totalDonaciones += (doc.data()['monto'] as num? ?? 0).toDouble();
      }

      // Insumos con alerta
      final snapInsumos = await _db.collection('insumos').get();
      int alertas = 0;
      for (final doc in snapInsumos.docs) {
        final data = doc.data();
        final actual = (data['cantidadActual'] as num? ?? 0).toDouble();
        final minimo = (data['cantidadMinima'] as num? ?? 0).toDouble();
        if (actual <= minimo) alertas++;
      }

      _datosReporte = DatosReporte(
        totalReservas: snapReservas.docs.length,
        reservasCompletadas: completadas,
        reservasCanceladas: canceladas,
        reservasAusentes: ausentes,
        totalDonaciones: totalDonaciones,
        insumosConAlerta: alertas,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
      );

      _status = ReporteStatus.success;
      notifyListeners();
    } catch (e) {
      _setError('Error al generar reporte: $e');
    }
  }

  // ── Helpers privados ─────────────────────────────────────────────────────
  void _setLoading() {
    _status = ReporteStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _status = ReporteStatus.error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == ReporteStatus.error) _status = ReporteStatus.idle;
    notifyListeners();
  }
}

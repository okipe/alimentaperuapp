import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:alimenta_peru/services/reporte_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';

/// Datos consolidados para la vista de reportes.
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

enum ReporteStatus { idle, loading, success, error }

/// ViewModel de reportes — capa ViewModel de MVVM.
///
/// Expone la API que [ReporteScreen] ya usa:
/// - [generarReporte()] — consulta Firestore y calcula [DatosReporte].
/// - [fechaInicio] / [fechaFin] / [setPeriodo] — selector de período.
/// - [datosReporte] / [isLoading] / [errorMessage]
///
/// También ofrece [generarPDF(comedorId)] que delega en [ReporteService]
/// y abre el visor del sistema con `printing`.
class ReporteViewModel extends ChangeNotifier {
  final FirebaseFirestore _db;
  final ReporteService _reporteService;

  ReporteViewModel({
    FirebaseFirestore? db,
    ReporteService? reporteService,
  })  : _db = db ?? FirebaseFirestore.instance,
        _reporteService = reporteService ?? ReporteService();

  // ── Estado interno ────────────────────────────────────────────────────────
  ReporteStatus _status = ReporteStatus.idle;
  DatosReporte? _datosReporte;
  String? _error;
  DateTime _fechaInicio =
      DateTime.now().subtract(const Duration(days: 30));
  DateTime _fechaFin = DateTime.now();

  // Para el selector de mes del PDF
  DateTime _mesSeleccionado = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  // ── Getters públicos ──────────────────────────────────────────────────────
  ReporteStatus get status => _status;
  DatosReporte? get datosReporte => _datosReporte;
  String? get errorMessage => _error;
  String? get error => _error;
  bool get isLoading => _status == ReporteStatus.loading;
  bool get generando => _status == ReporteStatus.loading;

  // Selector de período (usado por ReporteScreen)
  DateTime get fechaInicio => _fechaInicio;
  DateTime get fechaFin => _fechaFin;

  // Selector de mes (usado por generarPDF)
  DateTime get mesSeleccionado => _mesSeleccionado;

  // ── Selector de período ───────────────────────────────────────────────────

  void setPeriodo(DateTime inicio, DateTime fin) {
    _fechaInicio = inicio;
    _fechaFin = fin;
    notifyListeners();
  }

  void seleccionarMes(DateTime fecha) {
    _mesSeleccionado = DateTime(fecha.year, fecha.month);
    notifyListeners();
  }

  // ── Generar reporte en pantalla ───────────────────────────────────────────

  /// Consulta Firestore y calcula los [DatosReporte] para el período actual.
  /// Usado directamente por [ReporteScreen].
  Future<void> generarReporte() async {
    _setLoading();
    try {
      final snapReservas = await _db
          .collection('reservas')
          .where('fechaCreacion',
              isGreaterThanOrEqualTo: _fechaInicio)
          .where('fechaCreacion', isLessThanOrEqualTo: _fechaFin)
          .get();

      int completadas = 0, canceladas = 0, ausentes = 0;
      for (final doc in snapReservas.docs) {
        final estado = doc.data()['estado'] as String? ?? '';
        if (estado == EstadoReserva.completada.name) completadas++;
        if (estado == EstadoReserva.cancelada.name) canceladas++;
        if (estado == EstadoReserva.ausente.name) ausentes++;
      }

      final snapDonaciones = await _db
          .collection('donaciones')
          .where('tipo', isEqualTo: TipoDonacion.dinero.name)
          .where('fechaCreacion',
              isGreaterThanOrEqualTo: _fechaInicio)
          .where('fechaCreacion', isLessThanOrEqualTo: _fechaFin)
          .get();

      double totalDonaciones = 0;
      for (final doc in snapDonaciones.docs) {
        totalDonaciones +=
            (doc.data()['monto'] as num? ?? 0).toDouble();
      }

      final snapInsumos = await _db.collection('insumos').get();
      int alertas = 0;
      for (final doc in snapInsumos.docs) {
        final d = doc.data();
        final actual = (d['cantidadActual'] as num? ?? 0).toDouble();
        final minimo = (d['cantidadMinima'] as num? ?? 0).toDouble();
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
      _error = 'Error al generar reporte: $e';
      _status = ReporteStatus.error;
      notifyListeners();
      debugPrint('[ReporteViewModel] generarReporte error: $e');
    }
  }

  // ── Generar PDF y abrir visor ─────────────────────────────────────────────

  /// Genera el PDF mensual para [comedorId] y lo abre con el visor del sistema.
  Future<void> generarPDF(String comedorId) async {
    if (comedorId.isEmpty) {
      _error = 'No hay comedor seleccionado.';
      notifyListeners();
      return;
    }
    _setLoading();
    try {
      final bytes =
          await _reporteService.generarReportePDF(comedorId, _mesSeleccionado);
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'reporte_${comedorId}_${_mesSeleccionado.year}_${_mesSeleccionado.month}.pdf',
      );
      _status = ReporteStatus.success;
      notifyListeners();
    } catch (e) {
      _error = 'Error al generar el PDF. Verifica tu conexión.';
      _status = ReporteStatus.error;
      notifyListeners();
      debugPrint('[ReporteViewModel] generarPDF error: $e');
    }
  }

  // ── Limpieza ──────────────────────────────────────────────────────────────

  void clearError() {
    _error = null;
    if (_status == ReporteStatus.error) _status = ReporteStatus.idle;
    notifyListeners();
  }

  // ── Helpers privados ──────────────────────────────────────────────────────

  void _setLoading() {
    _status = ReporteStatus.loading;
    _error = null;
    notifyListeners();
  }
}

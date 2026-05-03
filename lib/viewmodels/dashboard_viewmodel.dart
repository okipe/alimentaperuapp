import 'package:alimenta_peru/services/firestore_service.dart';
import 'package:flutter/foundation.dart';

/// ViewModel del dashboard de administradora — capa ViewModel de MVVM.
///
/// Consolida en una sola llamada los KPIs del día: reservas, raciones,
/// donaciones, beneficiarias y distribución semanal.
///
/// ## Uso típico
/// ```dart
/// final vm = context.read<DashboardViewModel>();
/// await vm.cargarDatos(comedorId);
/// ```
class DashboardViewModel extends ChangeNotifier {
  final FirestoreService _service;

  DashboardViewModel({FirestoreService? service})
      : _service = service ?? FirestoreService();

  // ── Estado interno ────────────────────────────────────────────────────────
  int _reservasHoy = 0;
  int _racionesDisponibles = 0;
  double _totalDonaciones = 0.0;
  int _totalBeneficiarias = 0;
  Map<String, int> _reservasPorDia = {};
  bool _cargando = false;
  String? _error;

  // ── Getters públicos ──────────────────────────────────────────────────────
  int get reservasHoy => _reservasHoy;
  int get racionesDisponibles => _racionesDisponibles;
  double get totalDonaciones => _totalDonaciones;
  int get totalBeneficiarias => _totalBeneficiarias;
  Map<String, int> get reservasPorDia =>
      Map.unmodifiable(_reservasPorDia);
  bool get cargando => _cargando;
  String? get error => _error;

  /// `true` si ya se cargaron datos al menos una vez.
  bool get tieneDatos => _totalBeneficiarias > 0 || _reservasHoy > 0;

  // ── Carga de datos ────────────────────────────────────────────────────────

  /// Carga todos los KPIs del [comedorId] desde Firestore en paralelo.
  Future<void> cargarDatos(String comedorId) async {
    if (comedorId.isEmpty) return;
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final resumen = await _service.getResumenDashboard(comedorId);
      _reservasHoy = resumen['reservasHoy'] as int? ?? 0;
      _racionesDisponibles = resumen['racionesDisponibles'] as int? ?? 0;
      _totalDonaciones =
          (resumen['totalDonacionesSoles'] as num? ?? 0).toDouble();
      _totalBeneficiarias = resumen['totalBeneficiarias'] as int? ?? 0;
      _reservasPorDia =
          (resumen['reservasPorDia'] as Map<String, dynamic>? ?? {})
              .map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (e) {
      _error = 'Error al cargar el resumen del dashboard.';
      debugPrint('[DashboardViewModel] cargarDatos error: $e');
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Fuerza una recarga completa de los datos del [comedorId].
  Future<void> recargar(String comedorId) => cargarDatos(comedorId);

  void limpiarError() {
    _error = null;
    notifyListeners();
  }
}

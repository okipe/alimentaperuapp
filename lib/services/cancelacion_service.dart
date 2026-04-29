import 'dart:async';

import 'package:alimenta_peru/services/firestore_service.dart';
import 'package:flutter/foundation.dart';

/// Servicio que verifica periódicamente reservas vencidas y las marca
/// como [EstadoReserva.ausente] — capa Services de MVVM.
///
/// ## Uso
/// ```dart
/// final svc = CancelacionService();
/// svc.iniciarVerificacionPeriodica(comedorId);
/// ```
///
/// ## Ciclo de vida
/// - Llama a [iniciarVerificacionPeriodica] una sola vez al iniciar
///   la sesión de administradora.
/// - Llama a [detener] al cerrar sesión para cancelar el timer y
///   evitar memory leaks.
class CancelacionService {
  final FirestoreService _firestoreService;

  Timer? _timer;

  /// Intervalo entre verificaciones: 30 minutos.
  static const _intervalo = Duration(minutes: 30);

  CancelacionService({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  // ── API pública ───────────────────────────────────────────────────────────

  /// Inicia un [Timer.periodic] que cada 30 minutos llama a
  /// [FirestoreService.cancelarReservasVencidas] para el comedor indicado.
  ///
  /// Si ya hay un timer activo, lo cancela antes de crear uno nuevo.
  /// También ejecuta una verificación inmediata al arrancar.
  void iniciarVerificacionPeriodica(String comedorId) {
    detener(); // Cancela timer previo si existe

    debugPrint(
        '[CancelacionService] Iniciando verificación periódica para comedor: $comedorId');

    // Verificación inmediata al iniciar
    _verificar(comedorId);

    _timer = Timer.periodic(_intervalo, (_) => _verificar(comedorId));
  }

  /// Cancela el timer periódico. Llamar al cerrar sesión o al hacer dispose
  /// del widget raíz de la sesión de administradora.
  void detener() {
    _timer?.cancel();
    _timer = null;
    debugPrint('[CancelacionService] Timer detenido.');
  }

  /// Indica si el servicio tiene un timer activo.
  bool get activo => _timer?.isActive ?? false;

  // ── Helpers privados ──────────────────────────────────────────────────────

  Future<void> _verificar(String comedorId) async {
    debugPrint(
        '[CancelacionService] Verificando reservas vencidas — ${DateTime.now().toIso8601String()}');
    try {
      await _firestoreService.cancelarReservasVencidas(comedorId);
    } catch (e) {
      // El servicio no debe crashear la app; solo logueamos el error.
      debugPrint('[CancelacionService] Error en verificación: $e');
    }
  }
}

import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:alimenta_peru/core/exceptions/app_exception.dart';
import 'package:alimenta_peru/models/beneficiaria_model.dart';
import 'package:alimenta_peru/models/comedor_model.dart';
import 'package:alimenta_peru/models/donacion_model.dart';
import 'package:alimenta_peru/models/ingrediente_model.dart';
import 'package:alimenta_peru/models/menu_model.dart';
import 'package:alimenta_peru/models/racion_diaria_model.dart';
import 'package:alimenta_peru/models/reserva_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Servicio centralizado de acceso a Firestore — capa Services de MVVM.
///
/// Encapsula todas las operaciones de lectura/escritura sobre las colecciones
/// del proyecto y expone métodos tipados para cada entidad de dominio.
///
/// ## Colecciones principales
/// `usuarios` · `menus` · `reservas` · `donaciones` · `comedores` ·
/// `raciones_diarias` · `ingredientes`
///
/// ## Excepciones lanzadas
/// - [ReservaException] — reglas de negocio de reservas violadas.
/// - [NetworkException] — errores de red o Firestore inesperados.
class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // MENÚS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream de menús del comedor con fecha >= hoy y estado != agotado.
  Stream<List<MenuModel>> getMenusPorComedor(String comedorId) {
    final hoy = Timestamp.fromDate(
      DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      ),
    );

    return _db
        .collection('menus')
        .where('comedorId', isEqualTo: comedorId)
        .where('fecha', isGreaterThanOrEqualTo: hoy)
        .where('estado', isNotEqualTo: EstadoMenu.agotado.name)
        .orderBy('fecha')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => MenuModel.fromFirestore(d)).toList(),
        );
  }

  /// Crea un nuevo menú en Firestore.
  Future<void> crearMenu(MenuModel menu) async {
    try {
      await _db.collection('menus').add({
        ...menu.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _handleError('crearMenu', e);
    }
  }

  /// Actualiza el campo `racionesDisponibles` de un menú.
  Future<void> actualizarRacionesMenu(
    String menuId,
    int nuevasRaciones,
  ) async {
    try {
      await _db.collection('menus').doc(menuId).update({
        'racionesDisponibles': nuevasRaciones,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _handleError('actualizarRacionesMenu', e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RESERVAS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Crea una reserva y descuenta raciones del menú de forma atómica.
  ///
  /// Lanza [ReservaException] si ya existe una reserva activa para esa
  /// beneficiaria en esa fecha, o si no quedan raciones disponibles.
  ///
  /// Retorna el ID del documento generado.
  Future<String> crearReserva(ReservaModel reserva) async {
    try {
      // Verificar duplicado
      final yaExiste = await verificarReservaExistente(
        reserva.beneficiariaId,
        reserva.fecha,
      );
      if (yaExiste) {
        throw const ReservaException(
            'Ya tienes una reserva activa para ese día.');
      }

      late String reservaId;

      await _db.runTransaction((tx) async {
        // Leer el menú dentro de la transacción
        final menuRef = _db.collection('menus').doc(reserva.menuId);
        final menuSnap = await tx.get(menuRef);

        if (!menuSnap.exists) {
          throw const ReservaException('El menú seleccionado no existe.');
        }

        final disponibles =
            (menuSnap.data()!['racionesDisponibles'] as num? ?? 0).toInt();

        if (disponibles < reserva.numRaciones) {
          throw const ReservaException(
              'No hay suficientes raciones disponibles.');
        }

        // Crear la reserva
        final reservaRef = _db.collection('reservas').doc();
        reservaId = reservaRef.id;
        tx.set(reservaRef, {
          ...reserva.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Descontar raciones del menú
        tx.update(menuRef, {
          'racionesDisponibles': disponibles - reserva.numRaciones,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      return reservaId;
    } on ReservaException {
      rethrow;
    } catch (e) {
      _handleError('crearReserva', e);
    }
  }

  /// Cambia la reserva a `cancelada` y devuelve las raciones al menú.
  Future<void> cancelarReserva(String reservaId) async {
    try {
      await _db.runTransaction((tx) async {
        final reservaRef = _db.collection('reservas').doc(reservaId);
        final reservaSnap = await tx.get(reservaRef);

        if (!reservaSnap.exists) {
          throw const ReservaException('Reserva no encontrada.');
        }

        final data = reservaSnap.data()!;
        final estado = data['estado'] as String? ?? '';

        if (estado != EstadoReserva.confirmada.name) {
          throw const ReservaException(
              'Solo se pueden cancelar reservas confirmadas.');
        }

        final menuId = data['menuId'] as String? ?? '';
        final numRaciones = (data['numRaciones'] as num? ?? 1).toInt();

        // Actualizar estado de la reserva
        tx.update(reservaRef, {
          'estado': EstadoReserva.cancelada.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Devolver raciones al menú
        if (menuId.isNotEmpty) {
          final menuRef = _db.collection('menus').doc(menuId);
          tx.update(menuRef, {
            'racionesDisponibles': FieldValue.increment(numRaciones),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } on ReservaException {
      rethrow;
    } catch (e) {
      _handleError('cancelarReserva', e);
    }
  }

  /// Marca la reserva como `completada` (retiro confirmado por QR).
  Future<void> marcarPresencia(String reservaId) async {
    try {
      await _db.collection('reservas').doc(reservaId).update({
        'estado': EstadoReserva.completada.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _handleError('marcarPresencia', e);
    }
  }

  /// Stream de reservas de un comedor para una fecha específica.
  Stream<List<ReservaModel>> getReservasPorFecha(
    String comedorId,
    DateTime fecha,
  ) {
    final inicio = Timestamp.fromDate(
        DateTime(fecha.year, fecha.month, fecha.day));
    final fin = Timestamp.fromDate(
        DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59));

    return _db
        .collection('reservas')
        .where('comedorId', isEqualTo: comedorId)
        .where('fecha', isGreaterThanOrEqualTo: inicio)
        .where('fecha', isLessThanOrEqualTo: fin)
        .orderBy('fecha')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => ReservaModel.fromFirestore(d)).toList(),
        );
  }

  /// Retorna `true` si la beneficiaria ya tiene una reserva confirmada
  /// para la fecha indicada.
  Future<bool> verificarReservaExistente(
    String beneficiariaId,
    DateTime fecha,
  ) async {
    try {
      final inicio = Timestamp.fromDate(
          DateTime(fecha.year, fecha.month, fecha.day));
      final fin = Timestamp.fromDate(
          DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59));

      final snap = await _db
          .collection('reservas')
          .where('beneficiariaId', isEqualTo: beneficiariaId)
          .where('estado', isEqualTo: EstadoReserva.confirmada.name)
          .where('fecha', isGreaterThanOrEqualTo: inicio)
          .where('fecha', isLessThanOrEqualTo: fin)
          .limit(1)
          .get();

      return snap.docs.isNotEmpty;
    } catch (e) {
      _handleError('verificarReservaExistente', e);
    }
  }

  /// Busca reservas CONFIRMADAS cuya `horaLimite` < ahora y las marca AUSENTE.
  Future<void> cancelarReservasVencidas(String comedorId) async {
    try {
      final ahora = Timestamp.fromDate(DateTime.now());

      final snap = await _db
          .collection('reservas')
          .where('comedorId', isEqualTo: comedorId)
          .where('estado', isEqualTo: EstadoReserva.confirmada.name)
          .where('horaLimite', isLessThan: ahora)
          .get();

      if (snap.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {
          'estado': EstadoReserva.ausente.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      debugPrint(
          '[FirestoreService] ${snap.docs.length} reservas marcadas como ausente.');
    } catch (e) {
      _handleError('cancelarReservasVencidas', e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DONACIONES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Registra una donación en Firestore.
  Future<void> registrarDonacion(DonacionModel donacion) async {
    try {
      await _db.collection('donaciones').add({
        ...donacion.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _handleError('registrarDonacion', e);
    }
  }

  /// Stream de todas las donaciones de un comedor.
  Stream<List<DonacionModel>> getDonaciones(String comedorId) {
    return _db
        .collection('donaciones')
        .where('comedorId', isEqualTo: comedorId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => DonacionModel.fromFirestore(d)).toList(),
        );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMEDOR
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene los datos de un comedor por ID (one-shot).
  Future<ComedorModel> getComedor(String comedorId) async {
    try {
      final doc = await _db.collection('comedores').doc(comedorId).get();
      if (!doc.exists) {
        throw const NetworkException('Comedor no encontrado.');
      }
      return ComedorModel.fromFirestore(doc);
    } on NetworkException {
      rethrow;
    } catch (e) {
      _handleError('getComedor', e);
    }
  }

  /// Actualiza los datos de un comedor.
  Future<void> actualizarComedor(ComedorModel comedor) async {
    try {
      await _db.collection('comedores').doc(comedor.id).update({
        ...comedor.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _handleError('actualizarComedor', e);
    }
  }

  /// Retorna la lista de beneficiarias asignadas a un comedor.
  Future<List<BeneficiariaModel>> getBeneficiariasPorComedor(
    String comedorId,
  ) async {
    try {
      final snap = await _db
          .collection('usuarios')
          .where('comedorId', isEqualTo: comedorId)
          .where('rol', isEqualTo: RolUsuario.beneficiaria.name)
          .where('estado', isEqualTo: EstadoUsuario.activo.name)
          .get();

      return snap.docs
          .map((d) => BeneficiariaModel.fromFirestore(d))
          .toList();
    } catch (e) {
      _handleError('getBeneficiariasPorComedor', e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RACIONES DIARIAS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream del registro diario de raciones de un comedor para una fecha.
  Stream<RacionDiariaModel?> getRacionDiaria(
    String comedorId,
    DateTime fecha,
  ) {
    final inicio = Timestamp.fromDate(
        DateTime(fecha.year, fecha.month, fecha.day));
    final fin = Timestamp.fromDate(
        DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59));

    return _db
        .collection('raciones_diarias')
        .where('comedorId', isEqualTo: comedorId)
        .where('fecha', isGreaterThanOrEqualTo: inicio)
        .where('fecha', isLessThanOrEqualTo: fin)
        .limit(1)
        .snapshots()
        .map(
          (snap) => snap.docs.isEmpty
              ? null
              : RacionDiariaModel.fromFirestore(snap.docs.first),
        );
  }

  /// Crea o actualiza el registro diario de raciones.
  Future<void> actualizarRacionDiaria(RacionDiariaModel racion) async {
    try {
      if (racion.id.isEmpty) {
        await _db.collection('raciones_diarias').add({
          ...racion.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _db
            .collection('raciones_diarias')
            .doc(racion.id)
            .update({
          ...racion.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      _handleError('actualizarRacionDiaria', e);
    }
  }

  /// Agrega un ingrediente a la colección `ingredientes`.
  Future<void> agregarIngrediente(IngredienteModel ingrediente) async {
    try {
      await _db.collection('ingredientes').add({
        ...ingrediente.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _handleError('agregarIngrediente', e);
    }
  }

  /// Elimina un ingrediente por ID.
  Future<void> eliminarIngrediente(String ingredienteId) async {
    try {
      await _db.collection('ingredientes').doc(ingredienteId).delete();
    } catch (e) {
      _handleError('eliminarIngrediente', e);
    }
  }

  /// Stream de ingredientes de un menú específico.
  Stream<List<IngredienteModel>> getIngredientesPorMenu(String menuId) {
    return _db
        .collection('ingredientes')
        .where('menuId', isEqualTo: menuId)
        .orderBy('nombre')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => IngredienteModel.fromFirestore(d)).toList(),
        );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DASHBOARD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Consulta consolidada para el dashboard de administradora.
  ///
  /// Retorna un mapa con:
  /// - `reservasHoy` (int)
  /// - `racionesDisponibles` (int)
  /// - `totalDonacionesSoles` (double)
  /// - `totalBeneficiarias` (int)
  /// - `reservasPorDia` (Map<String, int> con claves 'lun'…'dom')
  Future<Map<String, dynamic>> getResumenDashboard(String comedorId) async {
    try {
      final ahora = DateTime.now();
      final inicioHoy =
          Timestamp.fromDate(DateTime(ahora.year, ahora.month, ahora.day));
      final finHoy = Timestamp.fromDate(
          DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59));

      // Inicio de la semana (lunes)
      final diasDesdelunes = ahora.weekday - 1;
      final inicioSemana = Timestamp.fromDate(
        DateTime(ahora.year, ahora.month, ahora.day - diasDesdelunes),
      );
      final finSemana = Timestamp.fromDate(
        DateTime(ahora.year, ahora.month,
            ahora.day - diasDesdelunes + 6, 23, 59, 59),
      );

      // Lanzar consultas en paralelo
      final results = await Future.wait([
        // [0] Reservas de hoy
        _db
            .collection('reservas')
            .where('comedorId', isEqualTo: comedorId)
            .where('fecha', isGreaterThanOrEqualTo: inicioHoy)
            .where('fecha', isLessThanOrEqualTo: finHoy)
            .get(),
        // [1] Menú de hoy (raciones disponibles)
        _db
            .collection('menus')
            .where('comedorId', isEqualTo: comedorId)
            .where('fecha', isGreaterThanOrEqualTo: inicioHoy)
            .where('fecha', isLessThanOrEqualTo: finHoy)
            .where('estado', isEqualTo: EstadoMenu.activo.name)
            .limit(1)
            .get(),
        // [2] Donaciones en dinero (total acumulado)
        _db
            .collection('donaciones')
            .where('comedorId', isEqualTo: comedorId)
            .where('tipo', isEqualTo: TipoDonacion.dinero.name)
            .get(),
        // [3] Beneficiarias activas del comedor
        _db
            .collection('usuarios')
            .where('comedorId', isEqualTo: comedorId)
            .where('rol', isEqualTo: RolUsuario.beneficiaria.name)
            .where('estado', isEqualTo: EstadoUsuario.activo.name)
            .get(),
        // [4] Reservas de la semana actual
        _db
            .collection('reservas')
            .where('comedorId', isEqualTo: comedorId)
            .where('fecha', isGreaterThanOrEqualTo: inicioSemana)
            .where('fecha', isLessThanOrEqualTo: finSemana)
            .get(),
      ]);

      final reservasHoySnap = results[0] as QuerySnapshot;
      final menuHoySnap = results[1] as QuerySnapshot;
      final donacionesSnap = results[2] as QuerySnapshot;
      final beneficiariasSnap = results[3] as QuerySnapshot;
      final reservasSemanaSnap = results[4] as QuerySnapshot;

      // Raciones disponibles del menú activo de hoy
      int racionesDisponibles = 0;
      if (menuHoySnap.docs.isNotEmpty) {
        racionesDisponibles = (menuHoySnap.docs.first.data()
                    as Map<String, dynamic>)['racionesDisponibles']
                as int? ??
            0;
      }

      // Total donaciones en soles
      double totalDonacionesSoles = 0;
      for (final doc in donacionesSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalDonacionesSoles += (data['monto'] as num? ?? 0).toDouble();
      }

      // Reservas agrupadas por día de la semana
      const dias = ['lun', 'mar', 'mie', 'jue', 'vie', 'sab', 'dom'];
      final reservasPorDia = <String, int>{
        for (final d in dias) d: 0,
      };

      for (final doc in reservasSemanaSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final ts = data['fecha'] as Timestamp?;
        if (ts != null) {
          final fecha = ts.toDate();
          // weekday: 1=lunes … 7=domingo
          final diaKey = dias[fecha.weekday - 1];
          reservasPorDia[diaKey] = (reservasPorDia[diaKey] ?? 0) + 1;
        }
      }

      return {
        'reservasHoy': reservasHoySnap.docs.length,
        'racionesDisponibles': racionesDisponibles,
        'totalDonacionesSoles': totalDonacionesSoles,
        'totalBeneficiarias': beneficiariasSnap.docs.length,
        'reservasPorDia': reservasPorDia,
      };
    } catch (e) {
      _handleError('getResumenDashboard', e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS PRIVADOS
  // ═══════════════════════════════════════════════════════════════════════════

  Never _handleError(String method, Object e) {
    debugPrint('[FirestoreService.$method] Error: $e');
    if (e is ReservaException || e is NetworkException) throw e as AppException;
    throw NetworkException('Error en $method. Verifica tu conexión.');
  }
}

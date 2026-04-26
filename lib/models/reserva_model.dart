import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa una reserva de ración realizada por una beneficiaria.
///
/// ## Validaciones de negocio
/// - [numRaciones] debe estar entre 1 y 3 (igual al máximo de personas por familia).
/// - Una beneficiaria solo puede tener una reserva activa ([EstadoReserva.confirmada])
///   por día en el mismo comedor.
/// - La reserva vence cuando [horaLimite] es anterior a [DateTime.now()].
///
/// ## Ciclo de vida
/// ```
/// confirmada ──→ completada  (se escaneó el QR y se entregó la ración)
/// confirmada ──→ cancelada   (beneficiaria cancela antes de horaLimite)
/// confirmada ──→ ausente     (venció horaLimite sin presentarse)
/// ```
class ReservaModel {
  /// ID único de la reserva (documento en Firestore).
  final String id;

  /// ID de la beneficiaria que realizó la reserva.
  final String beneficiariaId;

  /// ID del menú reservado.
  final String menuId;

  /// ID del comedor donde se realizará el retiro.
  final String comedorId;

  /// Fecha para la que se realizó la reserva.
  final DateTime fecha;

  /// Turno de retiro (p. ej. `"mañana"` o `"tarde"`).
  final String turno;

  /// Número de raciones reservadas. Mínimo 1, máximo 3.
  final int numRaciones;

  /// Estado actual de la reserva.
  final EstadoReserva estado;

  /// Código QR único que identifica esta reserva para el retiro.
  final String codigoQR;

  /// Hora límite para retirar la ración. Pasada esta hora, la reserva
  /// se marca como [EstadoReserva.ausente].
  final DateTime horaLimite;

  /// Timestamp de creación de la reserva en Firestore.
  final DateTime fechaCreacion;

  const ReservaModel({
    required this.id,
    required this.beneficiariaId,
    required this.menuId,
    required this.comedorId,
    required this.fecha,
    required this.turno,
    required this.numRaciones,
    required this.estado,
    required this.codigoQR,
    required this.horaLimite,
    required this.fechaCreacion,
  });

  // ── Getters de lógica de negocio ─────────────────────────────────────────

  /// Retorna `true` si la hora límite ya pasó y la reserva sigue confirmada.
  bool get estaVencida =>
      estado == EstadoReserva.confirmada &&
      DateTime.now().isAfter(horaLimite);

  /// Retorna `true` si la reserva puede ser escaneada para completarse.
  bool get puedeRetirarse =>
      estado == EstadoReserva.confirmada && !estaVencida;

  /// Retorna `true` si la reserva está en un estado terminal (no modificable).
  bool get esFinal => estado.esFinal;

  // ── Serialización ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'beneficiariaId': beneficiariaId,
        'menuId': menuId,
        'comedorId': comedorId,
        'fecha': Timestamp.fromDate(fecha),
        'turno': turno,
        'numRaciones': numRaciones.clamp(1, 3),
        'estado': estado.name,
        'codigoQR': codigoQR,
        'horaLimite': Timestamp.fromDate(horaLimite),
        'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      };

  factory ReservaModel.fromMap(Map<String, dynamic> map, String id) {
    return ReservaModel(
      id: id,
      beneficiariaId: map['beneficiariaId'] as String? ?? '',
      menuId: map['menuId'] as String? ?? '',
      comedorId: map['comedorId'] as String? ?? '',
      fecha: (map['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      turno: map['turno'] as String? ?? '',
      numRaciones:
          ((map['numRaciones'] as num?) ?? 1).toInt().clamp(1, 3),
      estado: EstadoReservaX.fromString(map['estado'] as String? ?? ''),
      codigoQR: map['codigoQR'] as String? ?? '',
      horaLimite:
          (map['horaLimite'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fechaCreacion:
          (map['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Constructor alternativo desde un [DocumentSnapshot] de Firestore.
  factory ReservaModel.fromFirestore(DocumentSnapshot doc) =>
      ReservaModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  // ── copyWith ──────────────────────────────────────────────────────────────

  ReservaModel copyWith({
    EstadoReserva? estado,
    String? turno,
    int? numRaciones,
  }) =>
      ReservaModel(
        id: id,
        beneficiariaId: beneficiariaId,
        menuId: menuId,
        comedorId: comedorId,
        fecha: fecha,
        turno: turno ?? this.turno,
        numRaciones: numRaciones ?? this.numRaciones,
        estado: estado ?? this.estado,
        codigoQR: codigoQR,
        horaLimite: horaLimite,
        fechaCreacion: fechaCreacion,
      );

  @override
  String toString() =>
      'ReservaModel(id: $id, beneficiaria: $beneficiariaId, estado: ${estado.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReservaModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

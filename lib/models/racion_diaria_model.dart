import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que consolida el registro diario de raciones entregadas
/// en un comedor.
///
/// Este modelo actúa como resumen estadístico del día:
/// cuántas raciones se planificaron ([totalRaciones]) y cuántas
/// se entregaron efectivamente ([racionesServidas]).
///
/// Se crea o actualiza al final de cada jornada cuando la administradora
/// cierra el servicio o ejecuta el proceso de consolidación.
class RacionDiariaModel {
  /// ID único del registro (documento en Firestore).
  final String id;

  /// ID del comedor al que pertenece este registro diario.
  final String comedorId;

  /// Fecha del registro. Solo se usa la parte de la fecha (sin hora).
  final DateTime fecha;

  /// Total de raciones planificadas para el día.
  final int totalRaciones;

  /// Número de raciones efectivamente entregadas.
  final int racionesServidas;

  const RacionDiariaModel({
    required this.id,
    required this.comedorId,
    required this.fecha,
    required this.totalRaciones,
    required this.racionesServidas,
  });

  // ── Getters de lógica de negocio ─────────────────────────────────────────

  /// Porcentaje de raciones servidas respecto al total planificado.
  /// Retorna `0.0` si no hay raciones planificadas (evita división por cero).
  double get porcentajeServido =>
      totalRaciones == 0 ? 0.0 : (racionesServidas / totalRaciones) * 100;

  /// Raciones que no fueron retiradas (ausentes + canceladas).
  int get racionesNoRetiradas =>
      (totalRaciones - racionesServidas).clamp(0, totalRaciones);

  /// Retorna `true` si se sirvieron todas las raciones planificadas.
  bool get todoServido => racionesServidas >= totalRaciones;

  // ── Serialización ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'comedorId': comedorId,
        'fecha': Timestamp.fromDate(
          DateTime(fecha.year, fecha.month, fecha.day),
        ),
        'totalRaciones': totalRaciones,
        'racionesServidas': racionesServidas,
      };

  factory RacionDiariaModel.fromMap(Map<String, dynamic> map, String id) {
    return RacionDiariaModel(
      id: id,
      comedorId: map['comedorId'] as String? ?? '',
      fecha: (map['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalRaciones: (map['totalRaciones'] as num? ?? 0).toInt(),
      racionesServidas: (map['racionesServidas'] as num? ?? 0).toInt(),
    );
  }

  /// Constructor alternativo desde un [DocumentSnapshot] de Firestore.
  factory RacionDiariaModel.fromFirestore(DocumentSnapshot doc) =>
      RacionDiariaModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  // ── copyWith ──────────────────────────────────────────────────────────────

  RacionDiariaModel copyWith({
    int? totalRaciones,
    int? racionesServidas,
  }) =>
      RacionDiariaModel(
        id: id,
        comedorId: comedorId,
        fecha: fecha,
        totalRaciones: totalRaciones ?? this.totalRaciones,
        racionesServidas: racionesServidas ?? this.racionesServidas,
      );

  @override
  String toString() =>
      'RacionDiariaModel(comedor: $comedorId, fecha: ${fecha.toIso8601String().split('T').first}, '
      'servidas: $racionesServidas/$totalRaciones, ${porcentajeServido.toStringAsFixed(1)}%)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RacionDiariaModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

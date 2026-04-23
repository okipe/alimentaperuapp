import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/enums/enums.dart';

/// Entidad de dominio para una reserva de ración.
class ReservaModel {
  final String id;
  final String usuarioId;
  final String racionId;
  final String nombreUsuario;
  final EstadoReserva estado;
  final DateTime fechaCreacion;
  final DateTime? fechaRetiro;
  final String? codigoQr; // UUID de la reserva como payload del QR

  const ReservaModel({
    required this.id,
    required this.usuarioId,
    required this.racionId,
    required this.nombreUsuario,
    required this.estado,
    required this.fechaCreacion,
    this.fechaRetiro,
    this.codigoQr,
  });

  bool get puedeRetirarse => estado == EstadoReserva.confirmada;

  // ── Firestore ─────────────────────────────────────────────────────────────
  factory ReservaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReservaModel(
      id: doc.id,
      usuarioId: data['usuarioId'] as String? ?? '',
      racionId: data['racionId'] as String? ?? '',
      nombreUsuario: data['nombreUsuario'] as String? ?? '',
      estado: EstadoReservaX.fromString(data['estado'] as String? ?? ''),
      fechaCreacion:
          (data['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fechaRetiro: (data['fechaRetiro'] as Timestamp?)?.toDate(),
      codigoQr: data['codigoQr'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'usuarioId': usuarioId,
        'racionId': racionId,
        'nombreUsuario': nombreUsuario,
        'estado': estado.name,
        'fechaCreacion': Timestamp.fromDate(fechaCreacion),
        if (fechaRetiro != null)
          'fechaRetiro': Timestamp.fromDate(fechaRetiro!),
        if (codigoQr != null) 'codigoQr': codigoQr,
      };

  ReservaModel copyWith({
    EstadoReserva? estado,
    DateTime? fechaRetiro,
    String? codigoQr,
  }) =>
      ReservaModel(
        id: id,
        usuarioId: usuarioId,
        racionId: racionId,
        nombreUsuario: nombreUsuario,
        estado: estado ?? this.estado,
        fechaCreacion: fechaCreacion,
        fechaRetiro: fechaRetiro ?? this.fechaRetiro,
        codigoQr: codigoQr ?? this.codigoQr,
      );

  @override
  String toString() =>
      'ReservaModel(id: $id, usuario: $nombreUsuario, estado: ${estado.name})';
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/enums/enums.dart';

/// Entidad de dominio para una donación registrada.
class DonacionModel {
  final String id;
  final String donanteId;
  final String nombreDonante;
  final TipoDonacion tipo;
  final String descripcion;
  final double? monto; // Solo aplica para TipoDonacion.dinero
  final String? comprobante; // URL en Firebase Storage
  final DateTime fechaCreacion;

  const DonacionModel({
    required this.id,
    required this.donanteId,
    required this.nombreDonante,
    required this.tipo,
    required this.descripcion,
    this.monto,
    this.comprobante,
    required this.fechaCreacion,
  });

  // ── Firestore ─────────────────────────────────────────────────────────────
  factory DonacionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DonacionModel(
      id: doc.id,
      donanteId: data['donanteId'] as String? ?? '',
      nombreDonante: data['nombreDonante'] as String? ?? '',
      tipo: TipoDonacionX.fromString(data['tipo'] as String? ?? ''),
      descripcion: data['descripcion'] as String? ?? '',
      monto: (data['monto'] as num?)?.toDouble(),
      comprobante: data['comprobante'] as String?,
      fechaCreacion:
          (data['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'donanteId': donanteId,
        'nombreDonante': nombreDonante,
        'tipo': tipo.name,
        'descripcion': descripcion,
        if (monto != null) 'monto': monto,
        if (comprobante != null) 'comprobante': comprobante,
        'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      };

  DonacionModel copyWith({
    String? descripcion,
    double? monto,
    String? comprobante,
  }) =>
      DonacionModel(
        id: id,
        donanteId: donanteId,
        nombreDonante: nombreDonante,
        tipo: tipo,
        descripcion: descripcion ?? this.descripcion,
        monto: monto ?? this.monto,
        comprobante: comprobante ?? this.comprobante,
        fechaCreacion: fechaCreacion,
      );

  @override
  String toString() =>
      'DonacionModel(id: $id, tipo: ${tipo.name}, monto: $monto)';
}

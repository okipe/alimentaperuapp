import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa una donación registrada en el sistema.
///
/// Soporta tres tipos de donación mediante [TipoDonacion]:
/// - **Dinero**: requiere el campo [monto] (mayor a 0).
/// - **Alimentos**: descripción del producto y cantidad donada.
/// - **Insumos**: materiales para la operación del comedor.
class DonacionModel {
  /// ID único de la donación (documento en Firestore).
  final String id;

  /// ID del usuario con rol [RolUsuario.donante] que realizó la donación.
  final String donanteId;

  /// ID del comedor beneficiario de la donación.
  final String comedorId;

  /// Tipo de donación: [TipoDonacion.dinero], [TipoDonacion.alimentos]
  /// o [TipoDonacion.insumos].
  final TipoDonacion tipo;

  /// Descripción detallada de lo donado (producto, cantidad, observaciones).
  final String descripcion;

  /// Monto en soles. Solo aplica cuando [tipo] es [TipoDonacion.dinero].
  /// Puede ser `null` para donaciones de alimentos o insumos.
  final double? monto;

  /// Fecha en que se registró la donación.
  final DateTime fecha;

  const DonacionModel({
    required this.id,
    required this.donanteId,
    required this.comedorId,
    required this.tipo,
    required this.descripcion,
    this.monto,
    required this.fecha,
  });

  // ── Getters de presentación ───────────────────────────────────────────────

  /// Representación legible del monto para donaciones en dinero.
  /// Retorna `null` para otros tipos.
  String? get montoFormateado =>
      monto != null ? 'S/ ${monto!.toStringAsFixed(2)}' : null;

  // ── Serialización ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'donanteId': donanteId,
        'comedorId': comedorId,
        'tipo': tipo.name,
        'descripcion': descripcion,
        if (monto != null) 'monto': monto,
        'fecha': Timestamp.fromDate(fecha),
      };

  factory DonacionModel.fromMap(Map<String, dynamic> map, String id) {
    return DonacionModel(
      id: id,
      donanteId: map['donanteId'] as String? ?? '',
      comedorId: map['comedorId'] as String? ?? '',
      tipo: TipoDonacionX.fromString(map['tipo'] as String? ?? ''),
      descripcion: map['descripcion'] as String? ?? '',
      monto: (map['monto'] as num?)?.toDouble(),
      fecha: (map['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Constructor alternativo desde un [DocumentSnapshot] de Firestore.
  factory DonacionModel.fromFirestore(DocumentSnapshot doc) =>
      DonacionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  // ── copyWith ──────────────────────────────────────────────────────────────

  DonacionModel copyWith({
    String? descripcion,
    double? monto,
    TipoDonacion? tipo,
  }) =>
      DonacionModel(
        id: id,
        donanteId: donanteId,
        comedorId: comedorId,
        tipo: tipo ?? this.tipo,
        descripcion: descripcion ?? this.descripcion,
        monto: monto ?? this.monto,
        fecha: fecha,
      );

  @override
  String toString() =>
      'DonacionModel(id: $id, tipo: ${tipo.name}, monto: $montoFormateado)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DonacionModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

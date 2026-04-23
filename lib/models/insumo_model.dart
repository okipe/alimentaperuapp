import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/enums/enums.dart';

/// Entidad de dominio que representa un insumo del almacén.
class InsumoModel {
  final String id;
  final String nombre;
  final double cantidadActual;
  final double cantidadMinima;
  final UnidadIngrediente unidad;
  final String? descripcion;
  final DateTime? updatedAt;

  const InsumoModel({
    required this.id,
    required this.nombre,
    required this.cantidadActual,
    required this.cantidadMinima,
    required this.unidad,
    this.descripcion,
    this.updatedAt,
  });

  /// Retorna [true] cuando el stock está en o por debajo del mínimo.
  bool get tieneAlertaStock => cantidadActual <= cantidadMinima;

  /// Porcentaje de stock respecto al mínimo (puede superar 100 %).
  double get porcentajeStock =>
      cantidadMinima == 0 ? 100 : (cantidadActual / cantidadMinima) * 100;

  // ── Firestore ─────────────────────────────────────────────────────────────
  factory InsumoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InsumoModel(
      id: doc.id,
      nombre: data['nombre'] as String? ?? '',
      cantidadActual: (data['cantidadActual'] as num? ?? 0).toDouble(),
      cantidadMinima: (data['cantidadMinima'] as num? ?? 0).toDouble(),
      unidad: UnidadIngredienteX.fromString(
        data['unidad'] as String? ?? '',
      ),
      descripcion: data['descripcion'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'cantidadActual': cantidadActual,
        'cantidadMinima': cantidadMinima,
        'unidad': unidad.name,
        if (descripcion != null) 'descripcion': descripcion,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  InsumoModel copyWith({
    String? nombre,
    double? cantidadActual,
    double? cantidadMinima,
    UnidadIngrediente? unidad,
    String? descripcion,
  }) =>
      InsumoModel(
        id: id,
        nombre: nombre ?? this.nombre,
        cantidadActual: cantidadActual ?? this.cantidadActual,
        cantidadMinima: cantidadMinima ?? this.cantidadMinima,
        unidad: unidad ?? this.unidad,
        descripcion: descripcion ?? this.descripcion,
        updatedAt: updatedAt,
      );

  @override
  String toString() =>
      'InsumoModel(id: $id, nombre: $nombre, stock: $cantidadActual ${unidad.label})';
}

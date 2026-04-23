import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/enums/enums.dart';

/// Entidad que representa el menú/ración planificada para un día.
class RacionModel {
  final String id;
  final String nombre;
  final String fecha; // 'YYYY-MM-DD'
  final int porcionesTotal;
  final int porcionesDisponibles;
  final EstadoMenu estado;
  final double? calorias;
  final double? proteinas;
  final double? carbohidratos;
  final double? grasas;
  final String? descripcion;
  final DateTime? updatedAt;

  const RacionModel({
    required this.id,
    required this.nombre,
    required this.fecha,
    required this.porcionesTotal,
    required this.porcionesDisponibles,
    required this.estado,
    this.calorias,
    this.proteinas,
    this.carbohidratos,
    this.grasas,
    this.descripcion,
    this.updatedAt,
  });

  bool get estaDisponible =>
      estado == EstadoMenu.activo && porcionesDisponibles > 0;

  // ── Firestore ─────────────────────────────────────────────────────────────
  factory RacionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RacionModel(
      id: doc.id,
      nombre: data['nombre'] as String? ?? '',
      fecha: data['fecha'] as String? ?? '',
      porcionesTotal: (data['porcionesTotal'] as num? ?? 0).toInt(),
      porcionesDisponibles:
          (data['porcionesDisponibles'] as num? ?? 0).toInt(),
      estado: EstadoMenuX.fromString(data['estado'] as String? ?? ''),
      calorias: (data['calorias'] as num?)?.toDouble(),
      proteinas: (data['proteinas'] as num?)?.toDouble(),
      carbohidratos: (data['carbohidratos'] as num?)?.toDouble(),
      grasas: (data['grasas'] as num?)?.toDouble(),
      descripcion: data['descripcion'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'fecha': fecha,
        'porcionesTotal': porcionesTotal,
        'porcionesDisponibles': porcionesDisponibles,
        'estado': estado.name,
        if (calorias != null) 'calorias': calorias,
        if (proteinas != null) 'proteinas': proteinas,
        if (carbohidratos != null) 'carbohidratos': carbohidratos,
        if (grasas != null) 'grasas': grasas,
        if (descripcion != null) 'descripcion': descripcion,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  RacionModel copyWith({
    String? nombre,
    int? porcionesTotal,
    int? porcionesDisponibles,
    EstadoMenu? estado,
    double? calorias,
    double? proteinas,
    double? carbohidratos,
    double? grasas,
    String? descripcion,
  }) =>
      RacionModel(
        id: id,
        nombre: nombre ?? this.nombre,
        fecha: fecha,
        porcionesTotal: porcionesTotal ?? this.porcionesTotal,
        porcionesDisponibles: porcionesDisponibles ?? this.porcionesDisponibles,
        estado: estado ?? this.estado,
        calorias: calorias ?? this.calorias,
        proteinas: proteinas ?? this.proteinas,
        carbohidratos: carbohidratos ?? this.carbohidratos,
        grasas: grasas ?? this.grasas,
        descripcion: descripcion ?? this.descripcion,
        updatedAt: updatedAt,
      );
}

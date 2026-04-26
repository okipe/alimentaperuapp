import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa un comedor comunitario del programa.
///
/// Cada comedor es gestionado por una administradora y puede tener
/// múltiples beneficiarias asignadas, menús diarios y donaciones.
class ComedorModel {
  /// ID único del comedor (documento en Firestore).
  final String id;

  /// Nombre del comedor comunitario.
  final String nombre;

  /// Dirección física del comedor.
  final String direccion;

  /// Teléfono de contacto del comedor.
  final String telefono;

  /// ID del usuario con rol [RolUsuario.administradora] que gestiona este comedor.
  final String administradoraId;

  /// Indica si el comedor está activo ([true]) o inactivo ([false]).
  final bool estado;

  const ComedorModel({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.administradoraId,
    required this.estado,
  });

  // ── Getters de presentación ───────────────────────────────────────────────

  /// Retorna `"Activo"` o `"Inactivo"` según el estado.
  String get estadoLabel => estado ? 'Activo' : 'Inactivo';

  // ── Serialización ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'direccion': direccion,
        'telefono': telefono,
        'administradoraId': administradoraId,
        'estado': estado,
      };

  factory ComedorModel.fromMap(Map<String, dynamic> map, String id) {
    return ComedorModel(
      id: id,
      nombre: map['nombre'] as String? ?? '',
      direccion: map['direccion'] as String? ?? '',
      telefono: map['telefono'] as String? ?? '',
      administradoraId: map['administradoraId'] as String? ?? '',
      estado: map['estado'] as bool? ?? true,
    );
  }

  /// Constructor alternativo desde un [DocumentSnapshot] de Firestore.
  factory ComedorModel.fromFirestore(DocumentSnapshot doc) =>
      ComedorModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );

  // ── copyWith ──────────────────────────────────────────────────────────────

  ComedorModel copyWith({
    String? nombre,
    String? direccion,
    String? telefono,
    String? administradoraId,
    bool? estado,
  }) =>
      ComedorModel(
        id: id,
        nombre: nombre ?? this.nombre,
        direccion: direccion ?? this.direccion,
        telefono: telefono ?? this.telefono,
        administradoraId: administradoraId ?? this.administradoraId,
        estado: estado ?? this.estado,
      );

  @override
  String toString() =>
      'ComedorModel(id: $id, nombre: $nombre, estado: $estadoLabel)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComedorModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

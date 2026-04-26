import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:alimenta_peru/models/usuario_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para usuarios con rol [RolUsuario.donante].
///
/// Extiende [UsuarioModel] agregando un teléfono de contacto opcional
/// para coordinación de donaciones físicas (alimentos e insumos).
class DonanteModel extends UsuarioModel {
  /// Número de teléfono de contacto. Puede ser null.
  final String? telefono;

  const DonanteModel({
    required super.id,
    required super.nombre,
    required super.dni,
    required super.email,
    required super.estado,
    required super.fechaRegistro,
    this.telefono,
  }) : super(rol: RolUsuario.donante);

  // ── Serialización ─────────────────────────────────────────────────────────

  @override
  Map<String, dynamic> toMap() => {
        ...super.toMap(),
        if (telefono != null) 'telefono': telefono,
      };

  factory DonanteModel.fromMap(Map<String, dynamic> map, String id) {
    return DonanteModel(
      id: id,
      nombre: map['nombre'] as String? ?? '',
      dni: map['dni'] as String? ?? '',
      email: map['email'] as String? ?? '',
      estado: EstadoUsuarioX.fromString(map['estado'] as String? ?? ''),
      fechaRegistro:
          (map['fechaRegistro'] as Timestamp?)?.toDate() ?? DateTime.now(),
      telefono: map['telefono'] as String?,
    );
  }

  /// Constructor alternativo desde un [DocumentSnapshot] de Firestore.
  factory DonanteModel.fromFirestore(DocumentSnapshot doc) =>
      DonanteModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );

  // ── copyWith ──────────────────────────────────────────────────────────────

  DonanteModel copyWith({
    String? nombre,
    String? dni,
    EstadoUsuario? estado,
    String? telefono,
  }) =>
      DonanteModel(
        id: id,
        nombre: nombre ?? this.nombre,
        dni: dni ?? this.dni,
        email: email,
        estado: estado ?? this.estado,
        fechaRegistro: fechaRegistro,
        telefono: telefono ?? this.telefono,
      );

  @override
  String toString() =>
      'DonanteModel(id: $id, nombre: $nombre, telefono: $telefono)';
}

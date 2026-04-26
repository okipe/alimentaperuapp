import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Clase base abstracta que representa a cualquier usuario del sistema.
///
/// Cada subclase ([BeneficiariaModel], [AdministradoraModel], [DonanteModel])
/// extiende esta clase y agrega los campos propios de su rol.
///
/// ## Compatibilidad Firestore
/// - [toMap] serializa todos los campos base para escritura en Firestore.
/// - El campo [id] nunca se incluye en [toMap] (es la clave del documento).
/// - Los [DateTime] se convierten a [Timestamp] para Firestore.
abstract class UsuarioModel {
  final String id;
  final String nombre;
  final String dni;
  final String email;
  final RolUsuario rol;
  final EstadoUsuario estado;
  final DateTime fechaRegistro;

  const UsuarioModel({
    required this.id,
    required this.nombre,
    required this.dni,
    required this.email,
    required this.rol,
    required this.estado,
    required this.fechaRegistro,
  });

  // ── Serialización ─────────────────────────────────────────────────────────

  /// Campos base serializados para Firestore.
  ///
  /// Las subclases deben llamar a [super.toMap()] y agregar sus propios campos:
  /// ```dart
  /// @override
  /// Map<String, dynamic> toMap() => {
  ///   ...super.toMap(),
  ///   'campoExtra': campoExtra,
  /// };
  /// ```
  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'dni': dni,
        'email': email,
        'rol': rol.name,
        'estado': estado.name,
        'fechaRegistro': Timestamp.fromDate(fechaRegistro),
      };

  @override
  String toString() =>
      'UsuarioModel(id: $id, nombre: $nombre, rol: ${rol.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsuarioModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

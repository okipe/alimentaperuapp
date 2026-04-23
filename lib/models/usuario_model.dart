import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/enums/enums.dart';

/// Entidad de dominio que representa a un usuario del sistema.
class UsuarioModel {
  final String id;
  final String nombreCompleto;
  final String email;
  final String? telefono;
  final String? dni;
  final RolUsuario rol;
  final EstadoUsuario estado;
  final DateTime fechaRegistro;
  final DateTime? ultimaConexion;

  const UsuarioModel({
    required this.id,
    required this.nombreCompleto,
    required this.email,
    this.telefono,
    this.dni,
    required this.rol,
    required this.estado,
    required this.fechaRegistro,
    this.ultimaConexion,
  });

  // ── Firestore ─────────────────────────────────────────────────────────────
  factory UsuarioModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UsuarioModel(
      id: doc.id,
      nombreCompleto: data['nombreCompleto'] as String? ?? '',
      email: data['email'] as String? ?? '',
      telefono: data['telefono'] as String?,
      dni: data['dni'] as String?,
      rol: RolUsuarioX.fromString(data['rol'] as String? ?? ''),
      estado: EstadoUsuarioX.fromString(data['estado'] as String? ?? ''),
      fechaRegistro: (data['fechaRegistro'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      ultimaConexion:
          (data['ultimaConexion'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'nombreCompleto': nombreCompleto,
        'email': email,
        if (telefono != null) 'telefono': telefono,
        if (dni != null) 'dni': dni,
        'rol': rol.name,
        'estado': estado.name,
        'fechaRegistro': Timestamp.fromDate(fechaRegistro),
        if (ultimaConexion != null)
          'ultimaConexion': Timestamp.fromDate(ultimaConexion!),
      };

  // ── copyWith ──────────────────────────────────────────────────────────────
  UsuarioModel copyWith({
    String? nombreCompleto,
    String? telefono,
    String? dni,
    EstadoUsuario? estado,
    DateTime? ultimaConexion,
  }) =>
      UsuarioModel(
        id: id,
        nombreCompleto: nombreCompleto ?? this.nombreCompleto,
        email: email,
        telefono: telefono ?? this.telefono,
        dni: dni ?? this.dni,
        rol: rol,
        estado: estado ?? this.estado,
        fechaRegistro: fechaRegistro,
        ultimaConexion: ultimaConexion ?? this.ultimaConexion,
      );

  @override
  String toString() =>
      'UsuarioModel(id: $id, nombre: $nombreCompleto, rol: ${rol.name})';
}

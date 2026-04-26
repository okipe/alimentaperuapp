import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:alimenta_peru/models/usuario_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para usuarios con rol [RolUsuario.administradora].
///
/// Además de los campos base, agrega el comedor que gestiona,
/// el código de registro institucional y el estado de verificación.
class AdministradoraModel extends UsuarioModel {
  /// ID del comedor que administra.
  final String comedorId;

  /// Código de registro institucional asignado al momento de crear la cuenta.
  final String codigoRegistro;

  /// Indica si la administradora ha sido verificada por el sistema.
  final bool verificada;

  const AdministradoraModel({
    required super.id,
    required super.nombre,
    required super.dni,
    required super.email,
    required super.estado,
    required super.fechaRegistro,
    required this.comedorId,
    required this.codigoRegistro,
    required this.verificada,
  }) : super(rol: RolUsuario.administradora);

  // ── Serialización ─────────────────────────────────────────────────────────

  @override
  Map<String, dynamic> toMap() => {
        ...super.toMap(),
        'comedorId': comedorId,
        'codigoRegistro': codigoRegistro,
        'verificada': verificada,
      };

  factory AdministradoraModel.fromMap(Map<String, dynamic> map, String id) {
    return AdministradoraModel(
      id: id,
      nombre: map['nombre'] as String? ?? '',
      dni: map['dni'] as String? ?? '',
      email: map['email'] as String? ?? '',
      estado: EstadoUsuarioX.fromString(map['estado'] as String? ?? ''),
      fechaRegistro:
          (map['fechaRegistro'] as Timestamp?)?.toDate() ?? DateTime.now(),
      comedorId: map['comedorId'] as String? ?? '',
      codigoRegistro: map['codigoRegistro'] as String? ?? '',
      verificada: map['verificada'] as bool? ?? false,
    );
  }

  /// Constructor alternativo desde un [DocumentSnapshot] de Firestore.
  factory AdministradoraModel.fromFirestore(DocumentSnapshot doc) =>
      AdministradoraModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );

  // ── copyWith ──────────────────────────────────────────────────────────────

  AdministradoraModel copyWith({
    String? nombre,
    String? dni,
    EstadoUsuario? estado,
    String? comedorId,
    String? codigoRegistro,
    bool? verificada,
  }) =>
      AdministradoraModel(
        id: id,
        nombre: nombre ?? this.nombre,
        dni: dni ?? this.dni,
        email: email,
        estado: estado ?? this.estado,
        fechaRegistro: fechaRegistro,
        comedorId: comedorId ?? this.comedorId,
        codigoRegistro: codigoRegistro ?? this.codigoRegistro,
        verificada: verificada ?? this.verificada,
      );

  @override
  String toString() =>
      'AdministradoraModel(id: $id, nombre: $nombre, verificada: $verificada)';
}

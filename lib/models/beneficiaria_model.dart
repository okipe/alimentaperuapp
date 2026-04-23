import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/enums/enums.dart';
import 'usuario_model.dart';

/// Entidad extendida para usuarios con rol beneficiaria.
///
/// Agrega campos específicos del programa (número de beneficiaria,
/// núcleo familiar y datos de elegibilidad).
class BeneficiariaModel extends UsuarioModel {
  final String numeroBeneficiaria;
  final int integrantesFamilia;
  final String? direccion;
  final String? distrito;
  final bool esVulnerable;
  final DateTime? fechaVencimientoElegibilidad;

  const BeneficiariaModel({
    required super.id,
    required super.nombreCompleto,
    required super.email,
    super.telefono,
    super.dni,
    required super.fechaRegistro,
    super.ultimaConexion,
    super.estado,
    required this.numeroBeneficiaria,
    required this.integrantesFamilia,
    this.direccion,
    this.distrito,
    this.esVulnerable = false,
    this.fechaVencimientoElegibilidad,
  }) : super(rol: RolUsuario.beneficiaria);

  bool get elegibilidadVigente {
    if (fechaVencimientoElegibilidad == null) return true;
    return fechaVencimientoElegibilidad!.isAfter(DateTime.now());
  }

  // ── Firestore ─────────────────────────────────────────────────────────────
  factory BeneficiariaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BeneficiariaModel(
      id: doc.id,
      nombreCompleto: data['nombreCompleto'] as String? ?? '',
      email: data['email'] as String? ?? '',
      telefono: data['telefono'] as String?,
      dni: data['dni'] as String?,
      estado: EstadoUsuarioX.fromString(data['estado'] as String? ?? ''),
      fechaRegistro:
          (data['fechaRegistro'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ultimaConexion: (data['ultimaConexion'] as Timestamp?)?.toDate(),
      numeroBeneficiaria: data['numeroBeneficiaria'] as String? ?? '',
      integrantesFamilia: (data['integrantesFamilia'] as num? ?? 1).toInt(),
      direccion: data['direccion'] as String?,
      distrito: data['distrito'] as String?,
      esVulnerable: data['esVulnerable'] as bool? ?? false,
      fechaVencimientoElegibilidad:
          (data['fechaVencimientoElegibilidad'] as Timestamp?)?.toDate(),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        ...super.toMap(),
        'numeroBeneficiaria': numeroBeneficiaria,
        'integrantesFamilia': integrantesFamilia,
        if (direccion != null) 'direccion': direccion,
        if (distrito != null) 'distrito': distrito,
        'esVulnerable': esVulnerable,
        if (fechaVencimientoElegibilidad != null)
          'fechaVencimientoElegibilidad':
              Timestamp.fromDate(fechaVencimientoElegibilidad!),
      };
}

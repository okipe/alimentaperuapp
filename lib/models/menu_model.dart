import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:alimenta_peru/models/ingrediente_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa el menú diario planificado por un comedor.
///
/// Cada menú pertenece a un comedor y tiene un número máximo de raciones.
/// Las raciones disponibles se reducen atómicamente con cada reserva confirmada.
///
/// ## Ciclo de vida del estado
/// ```
/// activo ──→ agotado  (cuando racionesDisponibles llega a 0)
/// activo ──→ cerrado  (cuando la administradora cierra el menú)
/// ```
class MenuModel {
  /// ID único del menú (documento en Firestore).
  final String id;

  /// ID del comedor que publica este menú.
  final String comedorId;

  /// Fecha para la que está planificado el menú.
  final DateTime fecha;

  /// Nombre del plato principal (p. ej. "Arroz con pollo").
  final String nombrePlato;

  /// Descripción del menú, puede incluir acompañamientos y bebida.
  final String descripcion;

  /// Número total de raciones planificadas para el día.
  final int racionesMaximas;

  /// Raciones que aún pueden reservarse. Se reduce con cada reserva.
  final int racionesDisponibles;

  /// Estado actual del menú: [EstadoMenu.activo], [EstadoMenu.cerrado]
  /// o [EstadoMenu.agotado].
  final EstadoMenu estado;

  /// Lista de ingredientes del menú. Puede estar vacía si se carga
  /// desde una subcolección por separado.
  final List<IngredienteModel> ingredientes;

  const MenuModel({
    required this.id,
    required this.comedorId,
    required this.fecha,
    required this.nombrePlato,
    required this.descripcion,
    required this.racionesMaximas,
    required this.racionesDisponibles,
    required this.estado,
    this.ingredientes = const [],
  });

  // ── Getters de lógica de negocio ─────────────────────────────────────────

  /// Retorna `true` si el menú está activo y quedan raciones disponibles.
  bool get tieneRacionesDisponibles =>
      estado == EstadoMenu.activo && racionesDisponibles > 0;

  /// Porcentaje de raciones consumidas respecto al total.
  double get porcentajeOcupacion => racionesMaximas == 0
      ? 0.0
      : ((racionesMaximas - racionesDisponibles) / racionesMaximas) * 100;

  // ── Serialización ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'comedorId': comedorId,
        'fecha': Timestamp.fromDate(fecha),
        'nombrePlato': nombrePlato,
        'descripcion': descripcion,
        'racionesMaximas': racionesMaximas,
        'racionesDisponibles': racionesDisponibles,
        'estado': estado.name,
        // Los ingredientes se guardan embebidos o en subcolección.
        // Si se usan embebidos, descomenta la siguiente línea:
        // 'ingredientes': ingredientes.map((i) => {...i.toMap(), 'id': i.id}).toList(),
      };

  factory MenuModel.fromMap(Map<String, dynamic> map, String id) {
    // Ingredientes embebidos (opcional — pueden cargarse como subcolección)
    final ingredientesRaw = map['ingredientes'] as List?;
    final ingredientes = ingredientesRaw
            ?.map((e) =>
                IngredienteModel.fromEmbedded(e as Map<String, dynamic>))
            .toList() ??
        [];

    return MenuModel(
      id: id,
      comedorId: map['comedorId'] as String? ?? '',
      fecha: (map['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      nombrePlato: map['nombrePlato'] as String? ?? '',
      descripcion: map['descripcion'] as String? ?? '',
      racionesMaximas: (map['racionesMaximas'] as num? ?? 0).toInt(),
      racionesDisponibles: (map['racionesDisponibles'] as num? ?? 0).toInt(),
      estado: EstadoMenuX.fromString(map['estado'] as String? ?? ''),
      ingredientes: ingredientes,
    );
  }

  /// Constructor alternativo desde un [DocumentSnapshot] de Firestore.
  factory MenuModel.fromFirestore(DocumentSnapshot doc) =>
      MenuModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

  // ── copyWith ──────────────────────────────────────────────────────────────

  MenuModel copyWith({
    String? nombrePlato,
    String? descripcion,
    int? racionesMaximas,
    int? racionesDisponibles,
    EstadoMenu? estado,
    List<IngredienteModel>? ingredientes,
  }) =>
      MenuModel(
        id: id,
        comedorId: comedorId,
        fecha: fecha,
        nombrePlato: nombrePlato ?? this.nombrePlato,
        descripcion: descripcion ?? this.descripcion,
        racionesMaximas: racionesMaximas ?? this.racionesMaximas,
        racionesDisponibles: racionesDisponibles ?? this.racionesDisponibles,
        estado: estado ?? this.estado,
        ingredientes: ingredientes ?? this.ingredientes,
      );

  @override
  String toString() =>
      'MenuModel(id: $id, plato: $nombrePlato, raciones: $racionesDisponibles/$racionesMaximas)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

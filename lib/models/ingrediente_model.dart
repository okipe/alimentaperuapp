import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa un ingrediente dentro de un menú diario.
///
/// Los ingredientes se almacenan como subcolección o lista embebida
/// dentro de la colección `menus` en Firestore.
///
/// ## Ejemplo de uso
/// ```dart
/// final ingrediente = IngredienteModel(
///   id: '',
///   menuId: 'menu123',
///   nombre: 'Arroz',
///   cantidad: 5.0,
///   unidad: UnidadIngrediente.kg,
/// );
/// ```
class IngredienteModel {
  /// ID único del ingrediente.
  final String id;

  /// ID del menú al que pertenece este ingrediente.
  final String menuId;

  /// Nombre del ingrediente (p. ej. "Arroz", "Aceite vegetal").
  final String nombre;

  /// Cantidad necesaria para el menú completo.
  final double cantidad;

  /// Unidad de medida: [UnidadIngrediente.kg], [UnidadIngrediente.litros]
  /// o [UnidadIngrediente.unidad].
  final UnidadIngrediente unidad;

  const IngredienteModel({
    required this.id,
    required this.menuId,
    required this.nombre,
    required this.cantidad,
    required this.unidad,
  });

  // ── Presentación ──────────────────────────────────────────────────────────

  /// Representación legible de la cantidad con unidad.
  /// Ejemplo: `"5.0 kg"` o `"200.0 und"`.
  String get cantidadConUnidad =>
      '${cantidad.toStringAsFixed(cantidad.truncateToDouble() == cantidad ? 0 : 1)} ${unidad.label}';

  // ── Serialización ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'menuId': menuId,
        'nombre': nombre,
        'cantidad': cantidad,
        'unidad': unidad.name,
      };

  factory IngredienteModel.fromMap(Map<String, dynamic> map, String id) {
    return IngredienteModel(
      id: id,
      menuId: map['menuId'] as String? ?? '',
      nombre: map['nombre'] as String? ?? '',
      cantidad: (map['cantidad'] as num? ?? 0).toDouble(),
      unidad: UnidadIngredienteX.fromString(map['unidad'] as String? ?? ''),
    );
  }

  /// Constructor desde un [DocumentSnapshot] de Firestore.
  factory IngredienteModel.fromFirestore(DocumentSnapshot doc) =>
      IngredienteModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );

  /// Constructor desde un Map embebido (sin ID de documento propio).
  ///
  /// Útil cuando los ingredientes se guardan como lista dentro del menú:
  /// ```dart
  /// final ingredientes = (data['ingredientes'] as List?)
  ///     ?.map((e) => IngredienteModel.fromEmbedded(e))
  ///     .toList() ?? [];
  /// ```
  factory IngredienteModel.fromEmbedded(Map<String, dynamic> map) =>
      IngredienteModel.fromMap(map, map['id'] as String? ?? '');

  @override
  String toString() =>
      'IngredienteModel(nombre: $nombre, cantidad: $cantidadConUnidad)';
}

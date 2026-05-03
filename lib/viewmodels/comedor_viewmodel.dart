import 'package:alimenta_peru/models/comedor_model.dart';
import 'package:alimenta_peru/services/firestore_service.dart';
import 'package:flutter/foundation.dart';

/// ViewModel del comedor — capa ViewModel de MVVM.
///
/// Carga y actualiza los datos del comedor que gestiona la administradora
/// autenticada.
///
/// ## Modo edición
/// Llama [toggleEdicion] para alternar entre vista y edición. Al guardar,
/// pasa los datos actualizados a [actualizarComedor].
class ComedorViewModel extends ChangeNotifier {
  final FirestoreService _service;

  ComedorViewModel({FirestoreService? service})
      : _service = service ?? FirestoreService();

  // ── Estado interno ────────────────────────────────────────────────────────
  ComedorModel? _comedor;
  bool _editando = false;
  bool _cargando = false;
  String? _error;

  // ── Getters públicos ──────────────────────────────────────────────────────
  ComedorModel? get comedor => _comedor;
  bool get editando => _editando;
  bool get cargando => _cargando;
  String? get error => _error;

  // ── Carga ─────────────────────────────────────────────────────────────────

  /// Carga los datos del comedor identificado por [id] desde Firestore.
  Future<void> cargarComedor(String id) async {
    if (id.isEmpty) return;
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _comedor = await _service.getComedor(id);
    } catch (e) {
      _error = 'Error al cargar los datos del comedor.';
      debugPrint('[ComedorViewModel] cargarComedor error: $e');
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  // ── Actualización ─────────────────────────────────────────────────────────

  /// Actualiza el comedor con los datos del [mapa].
  ///
  /// Claves válidas: `nombre`, `direccion`, `telefono`, `estado` (bool).
  ///
  /// Retorna `true` si la operación fue exitosa.
  Future<bool> actualizarComedor(Map<String, dynamic> mapa) async {
    final actual = _comedor;
    if (actual == null) {
      _error = 'No hay comedor cargado para actualizar.';
      notifyListeners();
      return false;
    }

    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final actualizado = actual.copyWith(
        nombre: mapa['nombre'] as String? ?? actual.nombre,
        direccion: mapa['direccion'] as String? ?? actual.direccion,
        telefono: mapa['telefono'] as String? ?? actual.telefono,
        estado: mapa['estado'] as bool? ?? actual.estado,
      );
      await _service.actualizarComedor(actualizado);
      _comedor = actualizado;
      _editando = false;
      return true;
    } catch (e) {
      _error = 'Error al actualizar el comedor.';
      debugPrint('[ComedorViewModel] actualizarComedor error: $e');
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  // ── Modo edición ──────────────────────────────────────────────────────────

  /// Alterna entre modo vista y modo edición.
  void toggleEdicion() {
    _editando = !_editando;
    notifyListeners();
  }

  void limpiarError() {
    _error = null;
    notifyListeners();
  }
}

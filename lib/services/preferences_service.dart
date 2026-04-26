import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de almacenamiento local usando SharedPreferences.
///
/// Persiste preferencias de usuario, sesión ligera y configuraciones de UI
/// que deben sobrevivir entre sesiones sin requerir conexión a internet.
class PreferencesService {
  static const String _keyRolUsuario = 'rol_usuario';
  static const String _keyUid = 'uid_usuario';
  static const String _keyNombre = 'nombre_usuario';
  static const String _keyOnboardingVisto = 'onboarding_visto';
  static const String _keyTemaOscuro = 'tema_oscuro';

  final SharedPreferences _prefs;

  PreferencesService._(this._prefs);

  /// Crea e inicializa el servicio.
  static Future<PreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService._(prefs);
  }

  // ── Sesión de usuario ─────────────────────────────────────────────────────

  Future<void> guardarSesion({
    required String uid,
    required String nombre,
    required RolUsuario rol,
  }) async {
    await _prefs.setString(_keyUid, uid);
    await _prefs.setString(_keyNombre, nombre);
    await _prefs.setString(_keyRolUsuario, rol.name);
  }

  Future<void> limpiarSesion() async {
    await _prefs.remove(_keyUid);
    await _prefs.remove(_keyNombre);
    await _prefs.remove(_keyRolUsuario);
  }

  String? get uid => _prefs.getString(_keyUid);
  String? get nombreUsuario => _prefs.getString(_keyNombre);

  RolUsuario? get rolUsuario {
    final rol = _prefs.getString(_keyRolUsuario);
    if (rol == null) return null;
    return RolUsuarioX.fromString(rol);
  }

  bool get haySesionGuardada => uid != null && rolUsuario != null;

  // ── Onboarding ────────────────────────────────────────────────────────────

  bool get onboardingVisto =>
      _prefs.getBool(_keyOnboardingVisto) ?? false;

  Future<void> marcarOnboardingVisto() =>
      _prefs.setBool(_keyOnboardingVisto, true);

  // ── Preferencias de UI ────────────────────────────────────────────────────

  bool get temaOscuro => _prefs.getBool(_keyTemaOscuro) ?? false;

  Future<void> setTemaOscuro(bool valor) =>
      _prefs.setBool(_keyTemaOscuro, valor);

  // ── Limpiar todo ──────────────────────────────────────────────────────────

  Future<void> limpiarTodo() => _prefs.clear();
}

import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:alimenta_peru/core/exceptions/app_exception.dart';
import 'package:alimenta_peru/models/administradora_model.dart';
import 'package:alimenta_peru/models/beneficiaria_model.dart';
import 'package:alimenta_peru/models/donante_model.dart';
import 'package:alimenta_peru/models/usuario_model.dart';
import 'package:alimenta_peru/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Estados posibles del proceso de autenticación.
enum AuthStatus { idle, loading, authenticated, unauthenticated, error }

/// ViewModel de autenticación — capa ViewModel de MVVM.
///
/// Gestiona login (genérico y por rol), registro, recuperación de
/// contraseña y cierre de sesión.
///
/// Expone tanto la API nueva ([loginBeneficiaria], [loginAdmin],
/// [loginDonante]) como alias de compatibilidad ([login], [register],
/// [sendPasswordReset]) que las Views existentes ya usan.
class AuthViewModel extends ChangeNotifier {
  final AuthService _service;
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthViewModel({
    AuthService? service,
    FirebaseAuth? auth,
    FirebaseFirestore? db,
  })  : _service = service ?? AuthService(),
        _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance {
    _init();
  }

  // ── Estado interno ────────────────────────────────────────────────────────
  AuthStatus _status = AuthStatus.idle;
  UsuarioModel? _usuario;
  User? _firebaseUser;
  RolUsuario? _rolSeleccionado;
  String? _error;

  // ── Getters públicos ──────────────────────────────────────────────────────
  AuthStatus get authStatus => _status;
  UsuarioModel? get usuario => _usuario;

  /// Usuario de Firebase Auth (necesario para acceder a [displayName] y [uid]).
  User? get currentUser => _firebaseUser;

  /// Rol del usuario autenticado.
  RolUsuario? get rolUsuario => _rolSeleccionado;

  /// Alias de [rolUsuario] — usado en el flujo de selección de rol.
  RolUsuario? get rolSeleccionado => _rolSeleccionado;

  /// Mensaje de error legible por el usuario.
  String? get errorMessage => _error;

  /// Alias de [errorMessage].
  String? get error => _error;

  bool get isLoading => _status == AuthStatus.loading;
  bool get cargando => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // ── Inicialización ────────────────────────────────────────────────────────

  void _init() {
    _auth.authStateChanges().listen((user) async {
      _firebaseUser = user;
      if (user == null) {
        _usuario = null;
        _rolSeleccionado = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }
      try {
        final perfil = await _service.usuarioActual();
        _usuario = perfil;
        _rolSeleccionado = perfil?.rol;
        _status = perfil != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated;
      } catch (_) {
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  // ── Selección de rol ──────────────────────────────────────────────────────

  void seleccionarRol(RolUsuario rol) {
    _rolSeleccionado = rol;
    notifyListeners();
  }

  // ── Login genérico (usado por LoginScreen existente) ──────────────────────

  /// Login genérico por email/contraseña.
  /// Detecta el rol del usuario en Firestore y redirige al dashboard correcto.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _firebaseUser = credential.user;
      await _fetchRol(credential.user!.uid);
      _status = AuthStatus.authenticated;
      _error = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthException.fromCode(e.code).message);
      return false;
    } catch (e) {
      _setError('Error de conexión. Verifica tu internet.');
      return false;
    }
  }

  // ── Login por rol ─────────────────────────────────────────────────────────

  Future<void> loginBeneficiaria(String dni, String pwd) async {
    _setLoading();
    try {
      final perfil = await _service.loginBeneficiaria(dni.trim(), pwd);
      _usuario = perfil;
      _firebaseUser = _auth.currentUser;
      _rolSeleccionado = RolUsuario.beneficiaria;
      _status = AuthStatus.authenticated;
      _error = null;
      notifyListeners();
    } on AppException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Error de conexión. Verifica tu internet.');
    }
  }

  Future<void> loginAdmin(String email, String pwd) async {
    _setLoading();
    try {
      final perfil = await _service.loginAdministradora(email.trim(), pwd);
      _usuario = perfil;
      _firebaseUser = _auth.currentUser;
      _rolSeleccionado = RolUsuario.administradora;
      _status = AuthStatus.authenticated;
      _error = null;
      notifyListeners();
    } on AppException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Error de conexión. Verifica tu internet.');
    }
  }

  Future<void> loginDonante(String email, String pwd) async {
    _setLoading();
    try {
      final perfil = await _service.loginDonante(email.trim(), pwd);
      _usuario = perfil;
      _firebaseUser = _auth.currentUser;
      _rolSeleccionado = RolUsuario.donante;
      _status = AuthStatus.authenticated;
      _error = null;
      notifyListeners();
    } on AppException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Error de conexión. Verifica tu internet.');
    }
  }

  // ── Registro genérico (usado por RegisterScreen existente) ────────────────

  /// Registro genérico — la View existente pasa [rol] para elegir el flujo.
  Future<bool> register({
    required String email,
    required String password,
    required String nombreCompleto,
    required RolUsuario rol,
    String dni = '',
    String? codigoAdmin,
  }) async {
    _setLoading();
    try {
      if (rol == RolUsuario.administradora) {
        if (codigoAdmin == null || codigoAdmin.trim() != 'ADMIN2026') {
          _setError(
              'Código institucional incorrecto. Contacta a tu institución.');
          return false;
        }
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(nombreCompleto);

      await _db.collection('usuarios').doc(credential.user!.uid).set({
        'nombre': nombreCompleto,
        'email': email.trim(),
        'dni': dni.trim(),
        'rol': rol.name,
        'estado': EstadoUsuario.activo.name,
        'fechaRegistro': FieldValue.serverTimestamp(),
        if (rol == RolUsuario.administradora) ...{
          'comedorId': '',
          'codigoRegistro': codigoAdmin?.trim() ?? '',
          'verificada': false,
        },
        if (rol == RolUsuario.beneficiaria) ...{
          'comedorId': '',
          'numPersonasFamilia': 1,
          'turnoPreferido': '',
        },
      });

      _firebaseUser = credential.user;
      _rolSeleccionado = rol;
      _status = AuthStatus.authenticated;
      _error = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthException.fromCode(e.code).message);
      return false;
    } catch (e) {
      _setError('Error de conexión. Verifica tu internet.');
      return false;
    }
  }

  // ── Registro por rol (API nueva) ──────────────────────────────────────────

  Future<bool> registrarBeneficiaria(Map<String, dynamic> data) async {
    _setLoading();
    try {
      final modelo = BeneficiariaModel(
        id: '',
        nombre: _str(data, 'nombre'),
        email: _str(data, 'email'),
        dni: _str(data, 'dni'),
        estado: EstadoUsuario.activo,
        fechaRegistro: DateTime.now(),
        comedorId: _str(data, 'comedorId'),
        numPersonasFamilia:
            (data['numPersonasFamilia'] as int? ?? 1).clamp(1, 3),
        turnoPreferido: _str(data, 'turnoPreferido'),
      );
      await _service.registrarBeneficiaria(modelo, _str(data, 'password'));
      _status = AuthStatus.idle;
      _error = null;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Error de conexión. Verifica tu internet.');
      return false;
    }
  }

  Future<bool> registrarAdmin(
      Map<String, dynamic> data, String codigo) async {
    _setLoading();
    try {
      final modelo = AdministradoraModel(
        id: '',
        nombre: _str(data, 'nombre'),
        email: _str(data, 'email'),
        dni: _str(data, 'dni'),
        estado: EstadoUsuario.activo,
        fechaRegistro: DateTime.now(),
        comedorId: _str(data, 'comedorId'),
        codigoRegistro: codigo.trim(),
        verificada: false,
      );
      await _service.registrarAdministradora(
          modelo, _str(data, 'password'), codigo);
      _status = AuthStatus.idle;
      _error = null;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Error de conexión. Verifica tu internet.');
      return false;
    }
  }

  Future<bool> registrarDonante(Map<String, dynamic> data) async {
    _setLoading();
    try {
      final modelo = DonanteModel(
        id: '',
        nombre: _str(data, 'nombre'),
        email: _str(data, 'email'),
        dni: _str(data, 'dni'),
        estado: EstadoUsuario.activo,
        fechaRegistro: DateTime.now(),
        telefono: data['telefono'] as String?,
      );
      await _service.registrarDonante(modelo, _str(data, 'password'));
      _status = AuthStatus.idle;
      _error = null;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Error de conexión. Verifica tu internet.');
      return false;
    }
  }

  // ── Recuperación de contraseña ────────────────────────────────────────────

  /// Envía un email de recuperación de contraseña.
  /// Usado por [ForgotPasswordScreen].
  Future<bool> sendPasswordReset(String email) async {
    _setLoading();
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _status = AuthStatus.idle;
      _error = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(AuthException.fromCode(e.code).message);
      return false;
    } catch (e) {
      _setError('Error de conexión. Verifica tu internet.');
      return false;
    }
  }

  // ── Sesión ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _service.cerrarSesion();
    _usuario = null;
    _firebaseUser = null;
    _rolSeleccionado = null;
    _error = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void limpiarError() {
    _error = null;
    if (_status == AuthStatus.error) _status = AuthStatus.idle;
    notifyListeners();
  }

  /// Alias de [limpiarError] — compatibilidad con Views que llaman clearError.
  void clearError() => limpiarError();

  // ── Helpers privados ──────────────────────────────────────────────────────

  Future<void> _fetchRol(String uid) async {
    try {
      final doc = await _db.collection('usuarios').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _rolSeleccionado =
            RolUsuarioX.fromString(data['rol'] as String? ?? '');
      } else {
        _rolSeleccionado = null;
      }
    } catch (e) {
      _rolSeleccionado = null;
      debugPrint('[AuthViewModel] _fetchRol error: $e');
    }
  }

  String _str(Map<String, dynamic> d, String key) =>
      (d[key] as String? ?? '').trim();

  void _setLoading() {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _error = msg;
    _status = AuthStatus.error;
    notifyListeners();
    debugPrint('[AuthViewModel] Error: $msg');
  }
}

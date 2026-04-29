import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:alimenta_peru/core/exceptions/app_exception.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Estados posibles del proceso de autenticación.
enum AuthStatus { idle, loading, authenticated, unauthenticated, error }

/// ViewModel de autenticación.
///
/// Gestiona login, registro, recuperación de contraseña y sesión activa.
/// Expone [authStatus] y [currentUser] como estado observable.
class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AuthStatus _status = AuthStatus.idle;
  User? _currentUser;
  RolUsuario? _rolUsuario;
  String? _errorMessage;

  // ── Getters ──────────────────────────────────────────────────────────────
  AuthStatus get authStatus => _status;
  User? get currentUser => _currentUser;
  RolUsuario? get rolUsuario => _rolUsuario;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthViewModel() {
    _init();
  }

  // ── Inicialización ────────────────────────────────────────────────────────
  void _init() {
    _auth.authStateChanges().listen((User? user) async {
      if (user == null) {
        _status = AuthStatus.unauthenticated;
        _currentUser = null;
        _rolUsuario = null;
        notifyListeners();
      } else {
        _currentUser = user;
        await _fetchRol(user.uid);
        _status = AuthStatus.authenticated;
        notifyListeners();
      }
    });
  }

  // ── Login ─────────────────────────────────────────────────────────────────
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
      _currentUser = credential.user;
      await _fetchRol(credential.user!.uid);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = AuthException.fromCode(e.code).message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error de conexión. Verifica tu internet.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ── Registro ──────────────────────────────────────────────────────────────
  /// Registra un nuevo usuario.
  ///
  /// - [dni] es requerido para beneficiaria y administradora.
  /// - [codigoAdmin] solo aplica para [RolUsuario.administradora];
  ///   debe ser `'ADMIN2026'` o el registro será rechazado.
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
      // Validación del código de administradora antes de llamar a Firebase
      if (rol == RolUsuario.administradora) {
        if (codigoAdmin == null || codigoAdmin.trim() != 'ADMIN2026') {
          _errorMessage =
              'Código institucional incorrecto. Contacta a tu institución.';
          _status = AuthStatus.error;
          notifyListeners();
          return false;
        }
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(nombreCompleto);

      // Persistir perfil en Firestore incluyendo DNI
      await _db.collection('usuarios').doc(credential.user!.uid).set({
        'nombre': nombreCompleto,
        'email': email.trim(),
        'dni': dni.trim(),
        'rol': rol.name,
        'estado': EstadoUsuario.activo.name,
        'fechaRegistro': FieldValue.serverTimestamp(),
        // Campos extra según rol
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

      _currentUser = credential.user;
      _rolUsuario = rol;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _errorMessage = AuthException.fromCode(e.code).message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error de conexión. Verifica tu internet.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ── Recuperar contraseña ──────────────────────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    _setLoading();
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _status = AuthStatus.idle;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = AuthException.fromCode(e.code).message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    _rolUsuario = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ── Helpers privados ──────────────────────────────────────────────────────
  Future<void> _fetchRol(String uid) async {
    try {
      final doc = await _db.collection('usuarios').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _rolUsuario =
            RolUsuarioX.fromString(data['rol'] as String? ?? '');
      } else {
        _rolUsuario = null;
        debugPrint('[AuthVM] Documento de usuario no encontrado: $uid');
      }
    } catch (e) {
      _rolUsuario = null;
      debugPrint('[AuthVM] Error al cargar rol: $e');
    }
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) _status = AuthStatus.idle;
    notifyListeners();
  }
}

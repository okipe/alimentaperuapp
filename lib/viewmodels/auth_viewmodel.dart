import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/enums/enums.dart';

/// Estados posibles del proceso de autenticación.
enum AuthStatus { idle, loading, authenticated, unauthenticated, error }

/// ViewModel de autenticación.
///
/// Gestiona login, registro, recuperación de contraseña y sesión activa.
/// Expone [authStatus] y [currentUser] como estado observable.
class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  // ── Inicialización ───────────────────────────────────────────────────────
  void _init() {
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        _status = AuthStatus.unauthenticated;
        _currentUser = null;
        _rolUsuario = null;
      } else {
        _currentUser = user;
        _status = AuthStatus.authenticated;
        // El rol se carga desde Firestore en la implementación real
      }
      notifyListeners();
    });
  }

  // ── Login ────────────────────────────────────────────────────────────────
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
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ── Registro ─────────────────────────────────────────────────────────────
  Future<bool> register({
    required String email,
    required String password,
    required String nombreCompleto,
    required RolUsuario rol,
  }) async {
    _setLoading();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(nombreCompleto);
      _currentUser = credential.user;
      _rolUsuario = rol;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ── Recuperar contraseña ─────────────────────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    _setLoading();
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _status = AuthStatus.idle;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    _rolUsuario = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ── Helpers privados ─────────────────────────────────────────────────────
  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con ese correo';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'El correo ya está registrado';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres';
      case 'invalid-email':
        return 'El correo no tiene un formato válido';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      default:
        return 'Ocurrió un error. Intenta de nuevo';
    }
  }

  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) _status = AuthStatus.idle;
    notifyListeners();
  }
}

import 'package:alimenta_peru/core/enums/enums.dart';
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

  // ── Inicialización ───────────────────────────────────────────────────────
  /// Escucha cambios de sesión de Firebase Auth.
  ///
  /// BUG ORIGINAL: cuando el usuario ya tenía sesión activa (reabrir la app),
  /// `_rolUsuario` quedaba null porque nunca se fetcheaba desde Firestore.
  /// Ahora se llama a [_fetchRol] antes de notificar a los listeners,
  /// garantizando que el splash pueda redirigir al dashboard correcto.
  void _init() {
    _auth.authStateChanges().listen((User? user) async {
      if (user == null) {
        _status = AuthStatus.unauthenticated;
        _currentUser = null;
        _rolUsuario = null;
        notifyListeners();
      } else {
        _currentUser = user;
        // FIX: cargar el rol desde Firestore antes de marcar como autenticado
        await _fetchRol(user.uid);
        _status = AuthStatus.authenticated;
        notifyListeners();
      }
    });
  }

  // ── Login ────────────────────────────────────────────────────────────────
  /// BUG ORIGINAL: tras el login exitoso, `_rolUsuario` quedaba null porque
  /// solo se asignaba `_currentUser`. Ahora se llama a [_fetchRol]
  /// para que `login_screen.dart` pueda redirigir al dashboard correcto.
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
      // FIX: cargar el rol desde Firestore antes de retornar
      await _fetchRol(credential.user!.uid);
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
  /// BUG ORIGINAL: el registro solo creaba la cuenta en Firebase Auth pero
  /// nunca escribía el documento en Firestore. Al hacer login posterior,
  /// [_fetchRol] no encontraba el documento y el rol quedaba null.
  /// Ahora escribe el perfil completo en la colección `usuarios`.
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

      // FIX: persistir el perfil en Firestore para que _fetchRol funcione
      await _db.collection('usuarios').doc(credential.user!.uid).set({
        'nombre': nombreCompleto,
        'email': email.trim(),
        'dni': '',
        'rol': rol.name,
        'estado': EstadoUsuario.activo.name,
        'fechaRegistro': FieldValue.serverTimestamp(),
      });

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

  /// Lee el campo `rol` del documento del usuario en Firestore y lo asigna
  /// a [_rolUsuario]. Si el documento no existe o hay un error, el rol
  /// queda como `null` y el usuario será enviado al login.
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
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos';
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

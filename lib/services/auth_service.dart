import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/enums/enums.dart';
import '../models/usuario_model.dart';

/// Servicio de autenticación Firebase.
///
/// Abstrae las llamadas directas al SDK de FirebaseAuth y Firestore.
/// Los ViewModels consumen este servicio en lugar de invocar Firebase directamente,
/// manteniendo la lógica de infraestructura fuera de la capa de presentación.
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  // ── Usuario actual ────────────────────────────────────────────────────────
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Login ────────────────────────────────────────────────────────────────
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

  // ── Registro ─────────────────────────────────────────────────────────────
  Future<UsuarioModel> registerWithEmail({
    required String email,
    required String password,
    required String nombreCompleto,
    required RolUsuario rol,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user!.updateDisplayName(nombreCompleto);

    final usuario = UsuarioModel(
      id: cred.user!.uid,
      nombreCompleto: nombreCompleto,
      email: email.trim(),
      rol: rol,
      estado: EstadoUsuario.activo,
      fechaRegistro: DateTime.now(),
    );

    // Guardar perfil en Firestore
    await _db
        .collection('usuarios')
        .doc(cred.user!.uid)
        .set(usuario.toMap());

    return usuario;
  }

  // ── Recuperar contraseña ─────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  // ── Logout ───────────────────────────────────────────────────────────────
  Future<void> signOut() => _auth.signOut();

  // ── Perfil desde Firestore ────────────────────────────────────────────────
  Future<UsuarioModel?> fetchUsuarioPerfil(String uid) async {
    final snap = await _db.collection('usuarios').doc(uid).get();
    if (!snap.exists) return null;
    return UsuarioModel.fromFirestore(snap);
  }

  Stream<UsuarioModel?> usuarioStream(String uid) {
    return _db.collection('usuarios').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UsuarioModel.fromFirestore(snap);
    });
  }

  // ── Actualizar última conexión ────────────────────────────────────────────
  Future<void> actualizarUltimaConexion(String uid) async {
    await _db.collection('usuarios').doc(uid).update({
      'ultimaConexion': FieldValue.serverTimestamp(),
    });
  }

  // ── Cambiar estado de usuario (Admin) ─────────────────────────────────────
  Future<void> cambiarEstadoUsuario(
      String uid, EstadoUsuario nuevoEstado) async {
    await _db.collection('usuarios').doc(uid).update({
      'estado': nuevoEstado.name,
    });
  }
}

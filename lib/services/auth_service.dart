import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:alimenta_peru/models/administradora_model.dart';
import 'package:alimenta_peru/models/beneficiaria_model.dart';
import 'package:alimenta_peru/models/donante_model.dart';
import 'package:alimenta_peru/models/usuario_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio de autenticación Firebase.
///
/// Abstrae las llamadas directas al SDK de FirebaseAuth y Firestore.
/// Los ViewModels consumen este servicio en lugar de invocar Firebase
/// directamente, manteniendo la lógica de infraestructura fuera de la
/// capa de presentación.
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
  /// Crea la cuenta en Firebase Auth y el perfil en Firestore.
  ///
  /// El [nombre] se mapea al campo `nombre` del modelo.
  /// El `dni` queda vacío por defecto y el usuario lo completa más tarde
  /// en la pantalla de perfil.
  Future<UsuarioModel> registerWithEmail({
    required String email,
    required String password,
    required String nombre,
    required RolUsuario rol,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user!.updateDisplayName(nombre);

    final usuario = _crearUsuarioBase(
      uid: cred.user!.uid,
      nombre: nombre,
      email: email.trim(),
      rol: rol,
    );

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
    return _usuarioFromSnapshot(snap);
  }

  Stream<UsuarioModel?> usuarioStream(String uid) {
    return _db.collection('usuarios').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return _usuarioFromSnapshot(snap);
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

  // ── Helpers privados ──────────────────────────────────────────────────────

  /// Crea la subclase correcta de [UsuarioModel] según el rol.
  /// Los campos específicos del perfil (comedorId, dni, etc.) se completan
  /// con valores vacíos y el usuario los actualiza en la pantalla de perfil.
  UsuarioModel _crearUsuarioBase({
    required String uid,
    required String nombre,
    required String email,
    required RolUsuario rol,
  }) {
    final now = DateTime.now();
    switch (rol) {
      case RolUsuario.beneficiaria:
        return BeneficiariaModel(
          id: uid,
          nombre: nombre,
          dni: '',
          email: email,
          estado: EstadoUsuario.activo,
          fechaRegistro: now,
          comedorId: '',
          numPersonasFamilia: 1,
          turnoPreferido: '',
        );
      case RolUsuario.administradora:
        return AdministradoraModel(
          id: uid,
          nombre: nombre,
          dni: '',
          email: email,
          estado: EstadoUsuario.activo,
          fechaRegistro: now,
          comedorId: '',
          codigoRegistro: '',
          verificada: false,
        );
      case RolUsuario.donante:
        return DonanteModel(
          id: uid,
          nombre: nombre,
          dni: '',
          email: email,
          estado: EstadoUsuario.activo,
          fechaRegistro: now,
        );
    }
  }

  /// Despacha la construcción del modelo correcto leyendo el campo `rol`
  /// del documento de Firestore. Nunca retorna null (fallback: [DonanteModel]).
  UsuarioModel _usuarioFromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    final rol = RolUsuarioX.fromString(data['rol'] as String? ?? '');
    switch (rol) {
      case RolUsuario.beneficiaria:
        return BeneficiariaModel.fromFirestore(snap);
      case RolUsuario.administradora:
        return AdministradoraModel.fromFirestore(snap);
      case RolUsuario.donante:
        return DonanteModel.fromFirestore(snap);
    }
  }
}

import 'package:alimenta_peru/core/enums/enums.dart';
import 'package:alimenta_peru/core/exceptions/app_exception.dart';
import 'package:alimenta_peru/models/administradora_model.dart';
import 'package:alimenta_peru/models/beneficiaria_model.dart';
import 'package:alimenta_peru/models/donante_model.dart';
import 'package:alimenta_peru/models/usuario_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Código de registro institucional requerido para crear cuentas de administradora.
const _codigoAdmin = 'ADMIN2026';

/// Servicio de autenticación — capa Services de MVVM.
///
/// Abstrae Firebase Auth y Firestore para la gestión de sesión y perfiles.
/// Los ViewModels consumen únicamente este servicio; nunca llaman a Firebase
/// directamente.
///
/// ## Excepciones lanzadas
/// - [AuthException] — credenciales incorrectas, usuario no encontrado,
///   código de administradora inválido.
/// - [NetworkException] — error de red o tiempo de espera agotado.
class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  // ── Acceso directo al estado de sesión ────────────────────────────────────

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── LOGIN ─────────────────────────────────────────────────────────────────

  /// Login de beneficiaria por DNI.
  ///
  /// 1. Busca en Firestore colección `usuarios` donde `dni == dni`
  ///    y `rol == beneficiaria`.
  /// 2. Con el email encontrado autentica contra Firebase Auth.
  /// 3. Retorna el [BeneficiariaModel] completo.
  Future<BeneficiariaModel> loginBeneficiaria(
    String dni,
    String password,
  ) async {
    try {
      // Buscar el documento de usuario por DNI
      final query = await _db
          .collection('usuarios')
          .where('dni', isEqualTo: dni.trim())
          .where('rol', isEqualTo: RolUsuario.beneficiaria.name)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw const AuthException('No existe una beneficiaria con ese DNI.');
      }

      final doc = query.docs.first;
      final email = doc.data()['email'] as String? ?? '';

      if (email.isEmpty) {
        throw const AuthException('La cuenta no tiene un correo asociado.');
      }

      // Autenticar con Firebase Auth
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return BeneficiariaModel.fromFirestore(doc);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e) {
      _handleGenericError(e);
    }
  }

  /// Login de administradora por email y contraseña.
  Future<AdministradoraModel> loginAdministradora(
    String email,
    String password,
  ) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final doc = await _db
          .collection('usuarios')
          .doc(cred.user!.uid)
          .get();

      if (!doc.exists) {
        throw const AuthException('Perfil de administradora no encontrado.');
      }

      final rol = doc.data()?['rol'] as String? ?? '';
      if (rol != RolUsuario.administradora.name) {
        await _auth.signOut();
        throw const AuthException(
            'Esta cuenta no tiene rol de administradora.');
      }

      return AdministradoraModel.fromFirestore(doc);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e) {
      _handleGenericError(e);
    }
  }

  /// Login de donante por email y contraseña.
  Future<DonanteModel> loginDonante(
    String email,
    String password,
  ) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final doc = await _db
          .collection('usuarios')
          .doc(cred.user!.uid)
          .get();

      if (!doc.exists) {
        throw const AuthException('Perfil de donante no encontrado.');
      }

      final rol = doc.data()?['rol'] as String? ?? '';
      if (rol != RolUsuario.donante.name) {
        await _auth.signOut();
        throw const AuthException('Esta cuenta no tiene rol de donante.');
      }

      return DonanteModel.fromFirestore(doc);
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e) {
      _handleGenericError(e);
    }
  }

  // ── REGISTRO ──────────────────────────────────────────────────────────────

  /// Registra una beneficiaria: crea cuenta en Auth y documento en Firestore.
  Future<void> registrarBeneficiaria(
    BeneficiariaModel data,
    String password,
  ) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: data.email.trim(),
        password: password,
      );
      await cred.user!.updateDisplayName(data.nombre);

      final perfil = BeneficiariaModel(
        id: cred.user!.uid,
        nombre: data.nombre,
        dni: data.dni,
        email: data.email.trim(),
        estado: EstadoUsuario.activo,
        fechaRegistro: DateTime.now(),
        comedorId: data.comedorId,
        numPersonasFamilia: data.numPersonasFamilia,
        turnoPreferido: data.turnoPreferido,
        fotoUrl: data.fotoUrl,
      );

      await _db
          .collection('usuarios')
          .doc(cred.user!.uid)
          .set(perfil.toMap());
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e) {
      _handleGenericError(e);
    }
  }

  /// Registra una administradora validando el código institucional.
  ///
  /// Lanza [AuthException] si [codigoIngresado] != `'ADMIN2026'`.
  Future<void> registrarAdministradora(
    AdministradoraModel data,
    String password,
    String codigoIngresado,
  ) async {
    if (codigoIngresado.trim() != _codigoAdmin) {
      throw const AuthException(
          'Código de registro incorrecto. Contacta a tu institución.');
    }

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: data.email.trim(),
        password: password,
      );
      await cred.user!.updateDisplayName(data.nombre);

      final perfil = AdministradoraModel(
        id: cred.user!.uid,
        nombre: data.nombre,
        dni: data.dni,
        email: data.email.trim(),
        estado: EstadoUsuario.activo,
        fechaRegistro: DateTime.now(),
        comedorId: data.comedorId,
        codigoRegistro: codigoIngresado.trim(),
        verificada: false,
      );

      await _db
          .collection('usuarios')
          .doc(cred.user!.uid)
          .set(perfil.toMap());
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e) {
      _handleGenericError(e);
    }
  }

  /// Registra un donante: crea cuenta en Auth y documento en Firestore.
  Future<void> registrarDonante(
    DonanteModel data,
    String password,
  ) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: data.email.trim(),
        password: password,
      );
      await cred.user!.updateDisplayName(data.nombre);

      final perfil = DonanteModel(
        id: cred.user!.uid,
        nombre: data.nombre,
        dni: data.dni,
        email: data.email.trim(),
        estado: EstadoUsuario.activo,
        fechaRegistro: DateTime.now(),
        telefono: data.telefono,
      );

      await _db
          .collection('usuarios')
          .doc(cred.user!.uid)
          .set(perfil.toMap());
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromCode(e.code);
    } catch (e) {
      _handleGenericError(e);
    }
  }

  // ── SESIÓN ────────────────────────────────────────────────────────────────

  /// Cierra la sesión activa en Firebase Auth.
  Future<void> cerrarSesion() async {
    try {
      await _auth.signOut();
    } catch (e) {
      _handleGenericError(e);
    }
  }

  /// Retorna el [UsuarioModel] del usuario autenticado leyendo su rol desde
  /// Firestore y construyendo la subclase correcta.
  ///
  /// Retorna `null` si no hay sesión activa o no se encuentra el documento.
  Future<UsuarioModel?> usuarioActual() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _db.collection('usuarios').doc(user.uid).get();
      if (!doc.exists) return null;
      return _modelFromSnapshot(doc);
    } catch (e) {
      debugPrint('[AuthService] Error al leer usuarioActual: $e');
      return null;
    }
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  UsuarioModel _modelFromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rol = RolUsuarioX.fromString(data['rol'] as String? ?? '');
    return switch (rol) {
      RolUsuario.beneficiaria => BeneficiariaModel.fromFirestore(doc),
      RolUsuario.administradora => AdministradoraModel.fromFirestore(doc),
      RolUsuario.donante => DonanteModel.fromFirestore(doc),
    };
  }

  /// Convierte errores genéricos (red, etc.) en [NetworkException].
  /// Nunca retorna — siempre lanza.
  Never _handleGenericError(Object e) {
    debugPrint('[AuthService] Error genérico: $e');
    throw NetworkException('Error de conexión. Verifica tu internet.');
  }
}

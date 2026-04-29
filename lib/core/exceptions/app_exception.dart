/// Jerarquía de excepciones de dominio para Alimenta Perú.
///
/// Todos los servicios capturan [FirebaseException] y otras excepciones
/// de infraestructura y las relanzan como subclases de [AppException],
/// evitando que la capa ViewModel dependa de Firebase directamente.
sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

// ── Autenticación ─────────────────────────────────────────────────────────────

/// Credenciales inválidas, usuario no encontrado, código de registro incorrecto.
class AuthException extends AppException {
  const AuthException(super.message);

  /// Traduce los códigos de error de Firebase Auth a mensajes en español.
  factory AuthException.fromCode(String code) {
    final msg = switch (code) {
      'user-not-found' => 'No existe una cuenta con ese correo o DNI.',
      'wrong-password' => 'Contraseña incorrecta.',
      'invalid-credential' => 'Credenciales inválidas.',
      'email-already-in-use' => 'El correo ya está registrado.',
      'weak-password' => 'La contraseña debe tener al menos 6 caracteres.',
      'invalid-email' => 'El correo no tiene un formato válido.',
      'too-many-requests' => 'Demasiados intentos. Intenta más tarde.',
      'user-disabled' => 'Esta cuenta ha sido deshabilitada.',
      _ => 'Ocurrió un error de autenticación. Intenta de nuevo.',
    };
    return AuthException(msg);
  }
}

// ── Reservas ──────────────────────────────────────────────────────────────────

/// Reserva ya existente para ese día, sin raciones disponibles, etc.
class ReservaException extends AppException {
  const ReservaException(super.message);
}

// ── Red ───────────────────────────────────────────────────────────────────────

/// Sin conexión a internet o tiempo de espera agotado.
class NetworkException extends AppException {
  const NetworkException([String message = 'Sin conexión a internet.'])
      : super(message);
}

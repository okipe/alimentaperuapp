/// Enumeraciones centralizadas de dominio para Alimenta Perú.
///
/// Cada enum incluye una extensión con utilidades de presentación
/// para no contaminar la UI con lógica de strings.

// ── Rol de usuario ───────────────────────────────────────────────────────────

enum RolUsuario {
  beneficiaria,
  administradora,
  donante;
}

extension RolUsuarioX on RolUsuario {
  String get label {
    switch (this) {
      case RolUsuario.beneficiaria:
        return 'Beneficiaria';
      case RolUsuario.administradora:
        return 'Administradora';
      case RolUsuario.donante:
        return 'Donante';
    }
  }

  /// Ruta del dashboard correspondiente al rol.
  String get dashboardRoute {
    switch (this) {
      case RolUsuario.beneficiaria:
        return '/beneficiaria/dashboard';
      case RolUsuario.administradora:
        return '/admin/dashboard';
      case RolUsuario.donante:
        return '/donante/dashboard';
    }
  }

  static RolUsuario fromString(String value) {
    return RolUsuario.values.firstWhere(
      (r) => r.name == value,
      orElse: () => RolUsuario.beneficiaria,
    );
  }
}

// ── Estado de reserva ────────────────────────────────────────────────────────

enum EstadoReserva {
  confirmada,
  cancelada,
  completada,
  ausente;
}

extension EstadoReservaX on EstadoReserva {
  String get label {
    switch (this) {
      case EstadoReserva.confirmada:
        return 'Confirmada';
      case EstadoReserva.cancelada:
        return 'Cancelada';
      case EstadoReserva.completada:
        return 'Completada';
      case EstadoReserva.ausente:
        return 'Ausente';
    }
  }

  /// Código hexadecimal del color representativo de cada estado.
  int get colorValue {
    switch (this) {
      case EstadoReserva.confirmada:
        return 0xFF16A34A; // primaryGreen
      case EstadoReserva.cancelada:
        return 0xFFEF4444; // rojo
      case EstadoReserva.completada:
        return 0xFF3B82F6; // azul
      case EstadoReserva.ausente:
        return 0xFF9CA3AF; // gris
    }
  }

  bool get esFinal =>
      this == EstadoReserva.cancelada ||
      this == EstadoReserva.completada ||
      this == EstadoReserva.ausente;

  static EstadoReserva fromString(String value) {
    return EstadoReserva.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoReserva.confirmada,
    );
  }
}

// ── Tipo de donación ─────────────────────────────────────────────────────────

enum TipoDonacion {
  dinero,
  alimentos,
  insumos;
}

extension TipoDonacionX on TipoDonacion {
  String get label {
    switch (this) {
      case TipoDonacion.dinero:
        return 'Dinero';
      case TipoDonacion.alimentos:
        return 'Alimentos';
      case TipoDonacion.insumos:
        return 'Insumos';
    }
  }

  String get icono {
    switch (this) {
      case TipoDonacion.dinero:
        return '💵';
      case TipoDonacion.alimentos:
        return '🥘';
      case TipoDonacion.insumos:
        return '📦';
    }
  }

  static TipoDonacion fromString(String value) {
    return TipoDonacion.values.firstWhere(
      (t) => t.name == value,
      orElse: () => TipoDonacion.dinero,
    );
  }
}

// ── Estado de menú/ración ────────────────────────────────────────────────────

enum EstadoMenu {
  activo,
  cerrado,
  agotado;
}

extension EstadoMenuX on EstadoMenu {
  String get label {
    switch (this) {
      case EstadoMenu.activo:
        return 'Activo';
      case EstadoMenu.cerrado:
        return 'Cerrado';
      case EstadoMenu.agotado:
        return 'Agotado';
    }
  }

  bool get disponible => this == EstadoMenu.activo;

  static EstadoMenu fromString(String value) {
    return EstadoMenu.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoMenu.cerrado,
    );
  }
}

// ── Estado de usuario ────────────────────────────────────────────────────────

enum EstadoUsuario {
  activo,
  pendiente,
  inactivo;
}

extension EstadoUsuarioX on EstadoUsuario {
  String get label {
    switch (this) {
      case EstadoUsuario.activo:
        return 'Activo';
      case EstadoUsuario.pendiente:
        return 'Pendiente';
      case EstadoUsuario.inactivo:
        return 'Inactivo';
    }
  }

  bool get puedeOperar => this == EstadoUsuario.activo;

  static EstadoUsuario fromString(String value) {
    return EstadoUsuario.values.firstWhere(
      (e) => e.name == value,
      orElse: () => EstadoUsuario.pendiente,
    );
  }
}

// ── Unidad de ingrediente ────────────────────────────────────────────────────

enum UnidadIngrediente {
  kg,
  litros,
  unidad;
}

extension UnidadIngredienteX on UnidadIngrediente {
  String get label {
    switch (this) {
      case UnidadIngrediente.kg:
        return 'kg';
      case UnidadIngrediente.litros:
        return 'L';
      case UnidadIngrediente.unidad:
        return 'und';
    }
  }

  String get labelLargo {
    switch (this) {
      case UnidadIngrediente.kg:
        return 'Kilogramos';
      case UnidadIngrediente.litros:
        return 'Litros';
      case UnidadIngrediente.unidad:
        return 'Unidades';
    }
  }

  static UnidadIngrediente fromString(String value) {
    return UnidadIngrediente.values.firstWhere(
      (u) => u.name == value,
      orElse: () => UnidadIngrediente.unidad,
    );
  }
}

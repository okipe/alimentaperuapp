/// Todas las cadenas de texto de la aplicación centralizadas.
///
/// Facilita la futura internacionalización (i18n) y evita strings
/// duplicados/hardcodeados a lo largo del código.
abstract final class AppStrings {
  AppStrings._();

  // ── App General ──────────────────────────────────────────────────────────
  static const String appName = 'Alimenta Perú';
  static const String appTagline = 'Nutrición con dignidad';
  static const String version = '1.0.0';

  // ── Autenticación ────────────────────────────────────────────────────────
  static const String login = 'Iniciar sesión';
  static const String logout = 'Cerrar sesión';
  static const String register = 'Registrarse';
  static const String forgotPassword = '¿Olvidaste tu contraseña?';
  static const String resetPassword = 'Restablecer contraseña';
  static const String emailLabel = 'Correo electrónico';
  static const String emailHint = 'usuario@correo.com';
  static const String passwordLabel = 'Contraseña';
  static const String passwordHint = 'Mínimo 6 caracteres';
  static const String confirmPasswordLabel = 'Confirmar contraseña';
  static const String fullNameLabel = 'Nombre completo';
  static const String dniLabel = 'DNI';
  static const String phoneLabel = 'Teléfono';
  static const String loginSuccess = 'Bienvenida/o de vuelta';
  static const String loginError = 'Correo o contraseña incorrectos';
  static const String registerSuccess = 'Cuenta creada exitosamente';
  static const String passwordsDoNotMatch = 'Las contraseñas no coinciden';
  static const String resetEmailSent =
      'Se envió un correo para restablecer tu contraseña';

  // ── Roles ────────────────────────────────────────────────────────────────
  static const String rolBeneficiaria = 'Beneficiaria';
  static const String rolAdministradora = 'Administradora';
  static const String rolDonante = 'Donante';

  // ── Dashboard ────────────────────────────────────────────────────────────
  static const String dashboard = 'Panel principal';
  static const String bienvenida = 'Bienvenida';
  static const String resumen = 'Resumen del día';

  // ── Insumos ──────────────────────────────────────────────────────────────
  static const String insumos = 'Insumos';
  static const String insumo = 'Insumo';
  static const String nuevoInsumo = 'Nuevo insumo';
  static const String editarInsumo = 'Editar insumo';
  static const String eliminarInsumo = 'Eliminar insumo';
  static const String nombreInsumo = 'Nombre del insumo';
  static const String cantidadStock = 'Cantidad en stock';
  static const String stockMinimo = 'Stock mínimo';
  static const String unidadMedida = 'Unidad de medida';
  static const String stockBajo = 'Stock bajo';
  static const String alertaStock = 'Alerta de stock';
  static const String insumoGuardado = 'Insumo guardado correctamente';
  static const String insumoEliminado = 'Insumo eliminado';

  // ── Raciones ─────────────────────────────────────────────────────────────
  static const String raciones = 'Raciones';
  static const String racion = 'Ración';
  static const String planDiario = 'Plan diario';
  static const String racionesDisponibles = 'Raciones disponibles';
  static const String racionesPlanificadas = 'Raciones planificadas';
  static const String racionAsignada = 'Ración asignada';
  static const String calorias = 'Calorías';
  static const String proteinas = 'Proteínas';
  static const String carbohidratos = 'Carbohidratos';
  static const String grasas = 'Grasas';

  // ── Reservas ─────────────────────────────────────────────────────────────
  static const String reservas = 'Reservas';
  static const String reserva = 'Reserva';
  static const String nuevaReserva = 'Nueva reserva';
  static const String cancelarReserva = 'Cancelar reserva';
  static const String confirmarReserva = 'Confirmar reserva';
  static const String historialReservas = 'Historial de reservas';
  static const String reservaConfirmada = 'Reserva confirmada';
  static const String reservaCancelada = 'Reserva cancelada';
  static const String reservaCompletada = 'Reserva completada';
  static const String ausente = 'Ausente';
  static const String codigoQr = 'Código QR';
  static const String escanearQr = 'Escanear QR';

  // ── Donaciones ───────────────────────────────────────────────────────────
  static const String donaciones = 'Donaciones';
  static const String donacion = 'Donación';
  static const String nuevaDonacion = 'Nueva donación';
  static const String historialDonaciones = 'Historial de donaciones';
  static const String tipoDonacion = 'Tipo de donación';
  static const String montoDonacion = 'Monto';
  static const String descripcionDonacion = 'Descripción';
  static const String donacionRegistrada = 'Donación registrada exitosamente';
  static const String graciasDonar = '¡Gracias por tu generosidad!';

  // ── Reportes ─────────────────────────────────────────────────────────────
  static const String reportes = 'Reportes';
  static const String reporte = 'Reporte';
  static const String generarReporte = 'Generar reporte';
  static const String exportarPdf = 'Exportar PDF';
  static const String reporteGenerado = 'Reporte generado';
  static const String fechaInicio = 'Fecha inicio';
  static const String fechaFin = 'Fecha fin';
  static const String seleccionarFecha = 'Seleccionar fecha';

  // ── Acciones comunes ─────────────────────────────────────────────────────
  static const String guardar = 'Guardar';
  static const String cancelar = 'Cancelar';
  static const String confirmar = 'Confirmar';
  static const String eliminar = 'Eliminar';
  static const String editar = 'Editar';
  static const String cerrar = 'Cerrar';
  static const String aceptar = 'Aceptar';
  static const String buscar = 'Buscar';
  static const String filtrar = 'Filtrar';
  static const String cargarMas = 'Cargar más';
  static const String actualizar = 'Actualizar';
  static const String volver = 'Volver';

  // ── Estados y mensajes de UI ─────────────────────────────────────────────
  static const String cargando = 'Cargando...';
  static const String sinResultados = 'Sin resultados';
  static const String sinConexion = 'Sin conexión a internet';
  static const String errorGenerico = 'Ocurrió un error, intenta de nuevo';
  static const String campoRequerido = 'Este campo es requerido';
  static const String exitoGenerico = 'Operación realizada con éxito';
  static const String confirmarEliminar =
      '¿Estás segura de que deseas eliminar este elemento?';
  static const String accionIrreversible = 'Esta acción no se puede deshacer';

  // ── Fechas y tiempo ──────────────────────────────────────────────────────
  static const String hoy = 'Hoy';
  static const String ayer = 'Ayer';
  static const String semanaActual = 'Esta semana';
  static const String mesActual = 'Este mes';
}

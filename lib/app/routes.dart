import 'package:flutter/material.dart';

// Shared Views
import '../views/shared/splash_screen.dart';
import '../views/shared/login_screen.dart';
import '../views/shared/register_screen.dart';
import '../views/shared/forgot_password_screen.dart';

// Beneficiaria Views
import '../views/beneficiaria/dashboard_beneficiaria_screen.dart';
import '../views/beneficiaria/racion_disponible_screen.dart';
import '../views/beneficiaria/reserva_screen.dart';
import '../views/beneficiaria/historial_reserva_screen.dart';

// Administradora Views
import '../views/administradora/dashboard_admin_screen.dart';
import '../views/administradora/insumo_list_screen.dart';
import '../views/administradora/racion_plan_screen.dart';
import '../views/administradora/reporte_screen.dart';

// Donante Views
import '../views/donante/dashboard_donante_screen.dart';
import '../views/donante/donacion_screen.dart';
import '../views/donante/historial_donacion_screen.dart';

/// Centraliza todas las rutas nombradas de la aplicación.
class AppRoutes {
  AppRoutes._();

  // ── Shared ──────────────────────────────────────────────────────────────
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // ── Beneficiaria ────────────────────────────────────────────────────────
  static const String dashboardBeneficiaria = '/beneficiaria/dashboard';
  static const String racionDisponible = '/beneficiaria/racion';
  static const String reserva = '/beneficiaria/reserva';
  static const String historialReserva = '/beneficiaria/historial';

  // ── Administradora ──────────────────────────────────────────────────────
  static const String dashboardAdmin = '/admin/dashboard';
  static const String insumoList = '/admin/insumos';
  static const String racionPlan = '/admin/racion-plan';
  static const String reporte = '/admin/reporte';

  // ── Donante ─────────────────────────────────────────────────────────────
  static const String dashboardDonante = '/donante/dashboard';
  static const String donacion = '/donante/donacion';
  static const String historialDonacion = '/donante/historial';

  /// Genera la ruta correspondiente al [RouteSettings] recibido.
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      // Shared
      case splash:
        return _route(const SplashScreen(), settings);
      case login:
        return _route(const LoginScreen(), settings);
      case register:
        return _route(const RegisterScreen(), settings);
      case forgotPassword:
        return _route(const ForgotPasswordScreen(), settings);

      // Beneficiaria
      case dashboardBeneficiaria:
        return _route(const DashboardBeneficiariaScreen(), settings);
      case racionDisponible:
        return _route(const RacionDisponibleScreen(), settings);
      case reserva:
        return _route(const ReservaScreen(), settings);
      case historialReserva:
        return _route(const HistorialReservaScreen(), settings);

      // Administradora
      case dashboardAdmin:
        return _route(const DashboardAdminScreen(), settings);
      case insumoList:
        return _route(const InsumoListScreen(), settings);
      case racionPlan:
        return _route(const RacionPlanScreen(), settings);
      case reporte:
        return _route(const ReporteScreen(), settings);

      // Donante
      case dashboardDonante:
        return _route(const DashboardDonanteScreen(), settings);
      case donacion:
        return _route(const DonacionScreen(), settings);
      case historialDonacion:
        return _route(const HistorialDonacionScreen(), settings);

      default:
        return _errorRoute(settings.name);
    }
  }

  static PageRouteBuilder<dynamic> _route(
    Widget page,
    RouteSettings settings,
  ) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  }

  static MaterialPageRoute<dynamic> _errorRoute(String? name) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Text('Ruta no encontrada: $name'),
        ),
      ),
    );
  }
}

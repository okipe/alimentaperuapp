import 'package:alimenta_peru/services/auth_service.dart';
import 'package:alimenta_peru/services/cancelacion_service.dart';
import 'package:alimenta_peru/services/firestore_service.dart';
import 'package:alimenta_peru/services/notification_service.dart';
import 'package:alimenta_peru/services/pdf_service.dart';
import 'package:alimenta_peru/services/preferences_service.dart';
import 'package:alimenta_peru/services/reporte_service.dart';
import 'package:alimenta_peru/services/storage_service.dart';
import 'package:alimenta_peru/viewmodels/auth_viewmodel.dart';
import 'package:alimenta_peru/viewmodels/comedor_viewmodel.dart';
import 'package:alimenta_peru/viewmodels/dashboard_viewmodel.dart';
import 'package:alimenta_peru/viewmodels/donacion_viewmodel.dart';
import 'package:alimenta_peru/viewmodels/insumo_viewmodel.dart';
import 'package:alimenta_peru/viewmodels/menu_viewmodel.dart';
import 'package:alimenta_peru/viewmodels/racion_viewmodel.dart';
import 'package:alimenta_peru/viewmodels/reporte_viewmodel.dart';
import 'package:alimenta_peru/viewmodels/reserva_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Construye el árbol de [MultiProvider] con todos los servicios y
/// ViewModels de la aplicación pre-inyectados.
///
/// ## Orden de declaración
/// 1. **Services** (sin estado de UI, singleton durante la sesión).
/// 2. **ViewModels** (dependen de los services mediante inyección).
///
/// Los services se exponen con [Provider] (no ChangeNotifier) para
/// que no propaguen cambios innecesariamente.
///
/// ## Uso
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp(...);
///
///   runApp(
///     buildProviders(child: const AlimentaPeruApp()),
///   );
/// }
/// ```
Widget buildProviders({required Widget child}) {
  // ── Instancias singleton de servicios ────────────────────────────────────
  final authService = AuthService();
  final firestoreService = FirestoreService();
  final reporteService = ReporteService();
  final storageService = StorageService();
  final notificationService = NotificationService();
  final cancelacionService = CancelacionService(
    firestoreService: firestoreService,
  );

  return MultiProvider(
    providers: [
      // ── Services ──────────────────────────────────────────────────────────
      Provider<AuthService>.value(value: authService),
      Provider<FirestoreService>.value(value: firestoreService),
      Provider<ReporteService>.value(value: reporteService),
      Provider<StorageService>.value(value: storageService),
      Provider<NotificationService>.value(value: notificationService),
      Provider<CancelacionService>.value(value: cancelacionService),

      // PreferencesService requiere inicialización asíncrona; se carga
      // antes de runApp en main.dart y se pasa como Provider estático.
      // Si se necesita acceder desde widgets, añadir:
      // Provider<PreferencesService>.value(value: prefsService),

      // ── ViewModels ────────────────────────────────────────────────────────
      ChangeNotifierProvider<AuthViewModel>(
        create: (_) => AuthViewModel(service: authService),
      ),
      ChangeNotifierProvider<InsumoViewModel>(
        create: (_) => InsumoViewModel(),
      ),
      ChangeNotifierProvider<MenuViewModel>(
        create: (_) => MenuViewModel(service: firestoreService),
      ),
      ChangeNotifierProvider<ReservaViewModel>(
        create: (_) => ReservaViewModel(service: firestoreService),
      ),
      ChangeNotifierProvider<DashboardViewModel>(
        create: (_) => DashboardViewModel(service: firestoreService),
      ),
      ChangeNotifierProvider<RacionViewModel>(
        create: (_) => RacionViewModel(firestoreService: firestoreService),
      ),
      ChangeNotifierProvider<DonacionViewModel>(
        create: (_) => DonacionViewModel(service: firestoreService),
      ),
      ChangeNotifierProvider<ComedorViewModel>(
        create: (_) => ComedorViewModel(service: firestoreService),
      ),
      ChangeNotifierProvider<ReporteViewModel>(
        create: (_) => ReporteViewModel(reporteService: reporteService),
      ),
    ],
    child: child,
  );
}

/// Versión alternativa para entornos de prueba con servicios mock.
///
/// ```dart
/// testWidgets('...', (tester) async {
///   await tester.pumpWidget(
///     buildProvidersForTest(
///       authService: FakeAuthService(),
///       child: const MyWidget(),
///     ),
///   );
/// });
/// ```
Widget buildProvidersForTest({
  AuthService? authService,
  FirestoreService? firestoreService,
  ReporteService? reporteService,
  required Widget child,
}) {
  final auth = authService ?? AuthService();
  final firestore = firestoreService ?? FirestoreService();
  final reporte = reporteService ?? ReporteService();

  return MultiProvider(
    providers: [
      Provider<AuthService>.value(value: auth),
      Provider<FirestoreService>.value(value: firestore),
      Provider<ReporteService>.value(value: reporte),
      ChangeNotifierProvider<AuthViewModel>(
        create: (_) => AuthViewModel(service: auth),
      ),
      ChangeNotifierProvider<InsumoViewModel>(
        create: (_) => InsumoViewModel(),
      ),
      ChangeNotifierProvider<MenuViewModel>(
        create: (_) => MenuViewModel(service: firestore),
      ),
      ChangeNotifierProvider<ReservaViewModel>(
        create: (_) => ReservaViewModel(service: firestore),
      ),
      ChangeNotifierProvider<DashboardViewModel>(
        create: (_) => DashboardViewModel(service: firestore),
      ),
      ChangeNotifierProvider<RacionViewModel>(
        create: (_) => RacionViewModel(firestoreService: firestore),
      ),
      ChangeNotifierProvider<DonacionViewModel>(
        create: (_) => DonacionViewModel(service: firestore),
      ),
      ChangeNotifierProvider<ComedorViewModel>(
        create: (_) => ComedorViewModel(service: firestore),
      ),
      ChangeNotifierProvider<ReporteViewModel>(
        create: (_) => ReporteViewModel(reporteService: reporte),
      ),
    ],
    child: child,
  );
}

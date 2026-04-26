import 'package:alimenta_peru/app/app.dart';
// NOTA: Descomenta la siguiente línea una vez que hayas ejecutado
// "flutterfire configure" y generado el archivo firebase_options.dart real.
import 'package:alimenta_peru/firebase_options.dart';
// ViewModels
import 'package:alimenta_peru/viewmodels/auth_viewmodel.dart';
import 'package:alimenta_peru/viewmodels/donacion_viewmodel.dart';
import 'package:alimenta_peru/viewmodels/insumo_viewmodel.dart';
import 'package:alimenta_peru/viewmodels/racion_viewmodel.dart';
import 'package:alimenta_peru/viewmodels/reporte_viewmodel.dart';
import 'package:alimenta_peru/viewmodels/reserva_viewmodel.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientación fija: solo vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Inicializar Firebase
  // NOTA: Reemplaza por DefaultFirebaseOptions.currentPlatform cuando
  // tengas configurado firebase_options.dart con flutterfire configure.
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => InsumoViewModel()),
        ChangeNotifierProvider(create: (_) => RacionViewModel()),
        ChangeNotifierProvider(create: (_) => ReservaViewModel()),
        ChangeNotifierProvider(create: (_) => DonacionViewModel()),
        ChangeNotifierProvider(create: (_) => ReporteViewModel()),
      ],
      child: const AlimentaPeruApp(),
    ),
  );
}

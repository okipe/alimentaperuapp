import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';

// ViewModels
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/insumo_viewmodel.dart';
import 'viewmodels/racion_viewmodel.dart';
import 'viewmodels/reserva_viewmodel.dart';
import 'viewmodels/donacion_viewmodel.dart';
import 'viewmodels/reporte_viewmodel.dart';

// NOTA: Descomenta la siguiente línea una vez que hayas ejecutado
// "flutterfire configure" y generado el archivo firebase_options.dart real.
// import 'firebase_options.dart';

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
    // options: DefaultFirebaseOptions.currentPlatform,
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

# 🥗 Alimenta Perú

> Plataforma móvil de gestión alimentaria con dignidad — Flutter + Firebase + MVVM

---

## Índice

- [Descripción](#descripción)
- [Arquitectura](#arquitectura)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Requisitos previos](#requisitos-previos)
- [Configuración inicial](#configuración-inicial)
- [Ejecución](#ejecución)
- [Módulos funcionales](#módulos-funcionales)
- [Colores y tipografía](#colores-y-tipografía)
- [Convenciones de código](#convenciones-de-código)
- [Roadmap](#roadmap)

---

## Descripción

**Alimenta Perú** es una aplicación Android diseñada para gestionar programas de
alimentación comunitaria. Conecta tres actores clave:

| Actor | Rol |
|---|---|
| 👩 Beneficiaria | Reserva su ración diaria y genera un QR de retiro |
| 👩‍💼 Administradora | Gestiona insumos, planifica el menú y genera reportes PDF |
| 🤝 Donante | Registra donaciones (dinero, alimentos, insumos) |

---

## Arquitectura

El proyecto sigue el patrón **MVVM** (Model · ViewModel · View) con **Provider**
como sistema de gestión de estado reactivo.

```
┌─────────────────────────────────────────────┐
│  VIEW  — Widgets Flutter / UI Reactiva       │
│  views/shared · beneficiaria · admin · donante│
└──────────────────┬──────────────────────────┘
                   │ observa / notifica
┌──────────────────▼──────────────────────────┐
│  VIEWMODEL  — Provider / ChangeNotifier      │
│  AuthVM · InsumoVM · RacionVM · ReservaVM    │
│  DonacionVM · ReporteVM                      │
└──────────────────┬──────────────────────────┘
                   │ repositorios / streams
┌──────────────────▼──────────────────────────┐
│  MODEL  — Entidades Dart / Servicios         │
│  models/ · services/                         │
└──────────────────┬──────────────────────────┘
                   │ SDK Firebase
┌──────────────────▼──────────────────────────┐
│  FIREBASE  — Backend en la nube              │
│  Auth · Firestore · FCM · Storage            │
└─────────────────────────────────────────────┘
```

### Servicios disponibles

| Servicio | Responsabilidad |
|---|---|
| `AuthService` | Login, registro, sesión y perfiles en Firestore |
| `FirestoreService` | CRUD genérico, paginación y transacciones |
| `NotificationService` | FCM — topics por rol, tokens, handlers |
| `PdfService` | Generación de reportes y comprobantes PDF |
| `StorageService` | Subida/descarga de archivos en Firebase Storage |
| `PreferencesService` | Sesión ligera y preferencias UI con SharedPreferences |

---

## Estructura del proyecto

```
alimenta_peru/
├── android/
│   ├── app/
│   │   ├── build.gradle                 # Config Android (minSdk 21, packageId)
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       ├── kotlin/.../MainActivity.kt
│   │       └── res/
│   │           ├── values/colors.xml
│   │           ├── values/styles.xml
│   │           └── xml/
│   │               ├── file_paths.xml
│   │               └── network_security_config.xml
│   ├── build.gradle
│   ├── gradle.properties
│   └── settings.gradle
├── lib/
│   ├── main.dart                        # Punto de entrada, MultiProvider
│   ├── firebase_options.dart            # Placeholder → generado con flutterfire
│   ├── app/
│   │   ├── app.dart                     # MaterialApp + ThemeData (Nunito)
│   │   └── routes.dart                  # Rutas nombradas centralizadas
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart          # Paleta de colores corporativos
│   │   │   ├── app_strings.dart         # Strings de la UI centralizados
│   │   │   └── app_styles.dart          # Tipografía, espaciado, decoraciones
│   │   └── enums/
│   │       └── enums.dart               # Todos los enums + extensiones
│   ├── models/
│   │   ├── usuario_model.dart
│   │   ├── beneficiaria_model.dart
│   │   ├── insumo_model.dart
│   │   ├── racion_model.dart
│   │   ├── reserva_model.dart
│   │   └── donacion_model.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   ├── notification_service.dart
│   │   ├── pdf_service.dart
│   │   ├── storage_service.dart
│   │   └── preferences_service.dart
│   ├── viewmodels/
│   │   ├── auth_viewmodel.dart
│   │   ├── insumo_viewmodel.dart
│   │   ├── racion_viewmodel.dart
│   │   ├── reserva_viewmodel.dart
│   │   ├── donacion_viewmodel.dart
│   │   └── reporte_viewmodel.dart
│   └── views/
│       ├── shared/
│       │   ├── splash_screen.dart
│       │   ├── login_screen.dart
│       │   ├── register_screen.dart
│       │   └── forgot_password_screen.dart
│       ├── beneficiaria/
│       │   ├── dashboard_beneficiaria_screen.dart
│       │   ├── racion_disponible_screen.dart
│       │   ├── reserva_screen.dart          # Genera QR con qr_flutter
│       │   └── historial_reserva_screen.dart
│       ├── administradora/
│       │   ├── dashboard_admin_screen.dart
│       │   ├── insumo_list_screen.dart      # CRUD + alertas stock
│       │   ├── racion_plan_screen.dart      # Planificación de menú diario
│       │   └── reporte_screen.dart          # Exportación PDF
│       └── donante/
│           ├── dashboard_donante_screen.dart
│           ├── donacion_screen.dart
│           └── historial_donacion_screen.dart
├── test/
│   └── widget_test.dart                 # Tests unitarios de enums y constantes
├── pubspec.yaml
└── analysis_options.yaml
```

---

## Requisitos previos

| Herramienta | Versión mínima |
|---|---|
| Flutter SDK | 3.3.0 |
| Dart SDK | 3.3.0 |
| Android Studio | Hedgehog (2023.1) o superior |
| Java JDK | 17 |
| Firebase CLI | 13+ |
| FlutterFire CLI | 1.0+ |

---

## Configuración inicial

### 1. Clonar e instalar dependencias

```bash
# Instalar dependencias
flutter pub get
```

### 2. Crear proyecto en Firebase Console

1. Ve a [console.firebase.google.com](https://console.firebase.google.com)
2. Crea un proyecto llamado **alimenta-peru**
3. Habilita los servicios:
   - **Authentication** → Email/Contraseña
   - **Firestore** → modo producción
   - **Cloud Messaging** (FCM)
   - **Storage**

### 3. Configurar FlutterFire

```bash
# Instalar FlutterFire CLI (solo la primera vez)
dart pub global activate flutterfire_cli

# Asociar la app con Firebase (genera firebase_options.dart)
flutterfire configure --project=alimenta-peru
```

Esto reemplazará el placeholder `lib/firebase_options.dart` con la
configuración real. Luego descomenta en `main.dart`:

```dart
import 'firebase_options.dart';

// En main():
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

Y en `android/app/build.gradle`, descomenta:

```gradle
id "com.google.gms.google-services"
```

Y en `android/build.gradle`:

```gradle
classpath 'com.google.gms:google-services:4.4.1'
```

### 4. Reglas de Firestore (seguridad básica)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Usuarios: solo el propio usuario o admins
    match /usuarios/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }

    // Insumos: solo administradoras
    match /insumos/{doc} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && get(/databases/$(database)/documents/usuarios/$(request.auth.uid))
              .data.rol == 'administradora';
    }

    // Raciones: lectura abierta para autenticados, escritura solo admins
    match /raciones/{doc} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && get(/databases/$(database)/documents/usuarios/$(request.auth.uid))
              .data.rol == 'administradora';
    }

    // Reservas: el usuario solo ve las suyas
    match /reservas/{doc} {
      allow read: if request.auth != null
        && (resource.data.usuarioId == request.auth.uid
            || get(/databases/$(database)/documents/usuarios/$(request.auth.uid))
                  .data.rol == 'administradora');
      allow create: if request.auth != null;
      allow update: if request.auth != null;
    }

    // Donaciones: el donante ve las suyas, admin ve todas
    match /donaciones/{doc} {
      allow read: if request.auth != null
        && (resource.data.donanteId == request.auth.uid
            || get(/databases/$(database)/documents/usuarios/$(request.auth.uid))
                  .data.rol == 'administradora');
      allow create: if request.auth != null;
    }
  }
}
```

---

## Ejecución

```bash
# Verificar dispositivos disponibles
flutter devices

# Ejecutar en modo debug
flutter run

# Ejecutar en modo release (más rendimiento)
flutter run --release

# Compilar APK de release
flutter build apk --release

# Compilar APK dividido por ABI (menor tamaño)
flutter build apk --split-per-abi --release
```

---

## Módulos funcionales

### 🔐 Autenticación (`auth_viewmodel.dart`)

- Login / Registro / Recuperación de contraseña con Firebase Auth
- Redireccionamiento automático al dashboard según rol tras autenticación
- Mapeo de errores Firebase a mensajes en español

### 📦 Insumos (`insumo_viewmodel.dart`)

- CRUD completo con Firestore en tiempo real (stream)
- Detección automática de stock bajo (`tieneAlertaStock`)
- Badge de alertas en el dashboard de administradora

### 🥘 Raciones (`racion_viewmodel.dart`)

- Planificación del menú diario con porciones totales/disponibles
- Control de estado del menú: `activo | cerrado | agotado`
- Reducción atómica de porciones al confirmar retiro

### 📅 Reservas (`reserva_viewmodel.dart`)

- Una reserva activa por beneficiaria por día (validación en Firestore)
- Generación de código QR con `qr_flutter` como payload de la reserva
- Estados: `confirmada → completada | cancelada | ausente`

### 💝 Donaciones (`donacion_viewmodel.dart`)

- Tipos: `dinero | alimentos | insumos`
- Validación de monto para donaciones en dinero
- Historial agrupado por tipo con totales

### 📊 Reportes (`reporte_viewmodel.dart` + `pdf_service.dart`)

- Consulta consolidada de reservas y donaciones por período configurable
- Cálculo de tasa de asistencia
- Exportación a PDF con logo, KPIs, tabla y pie de página numerado

---

## Colores y tipografía

### Paleta (`app_colors.dart`)

| Token | Hex | Uso |
|---|---|---|
| `primaryGreen` | `#16A34A` | AppBar, botones primarios, íconos activos |
| `primaryOrange` | `#F97316` | Acentos, badges, CTAs secundarios |
| `backgroundLight` | `#FAFAFA` | Fondo de pantallas |
| `cardBackground` | `#FFFFFF` | Tarjetas y formularios |
| `textPrimary` | `#1A1A1A` | Títulos y cuerpo principal |
| `textSecondary` | `#6B7280` | Subtítulos y placeholders |
| `successGreen` | `#D1FAE5` | Fondos de estado éxito |
| `warningOrange` | `#FFF3E0` | Fondos de advertencia |
| `errorRed` | `#FEE2E2` | Fondos de error |

### Tipografía

- **Familia:** Nunito (Google Fonts)
- **Pesos:** 400 (regular) · 600 (semibold) · 700 (bold) · 800 (extrabold)

---

## Convenciones de código

- Archivos en `snake_case`, clases en `PascalCase`, variables en `camelCase`
- Cada ViewModel tiene su propio enum de estado (e.g. `AuthStatus`, `InsumoStatus`)
- Los modelos implementan `fromFirestore()` y `toMap()` para serialización
- Los modelos son inmutables con método `copyWith()` para actualizaciones
- Strings de UI siempre en `AppStrings`, nunca hardcodeados
- Colores siempre en `AppColors`, estilos siempre en `AppStyles`
- `context.read<VM>()` para acciones, `context.watch<VM>()` para reactividad

---

## Roadmap

- [ ] Integrar escáner QR para confirmar retiros (módulo admin)
- [ ] Notificaciones push por FCM al publicar menú del día
- [ ] Exportación de reporte en formato Excel (`.xlsx`)
- [ ] Soporte para iOS
- [ ] Modo offline con Firestore persistence habilitado
- [ ] Internacionalización (i18n) — soporte multilenguaje
- [ ] Tests de integración con `integration_test`
- [ ] CI/CD con GitHub Actions + Fastlane

---

*Desarrollado con 💚 para Alimenta Perú — Lima, Perú*

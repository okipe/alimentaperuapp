import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Tipos de notificación push que maneja la aplicación.
enum TipoNotificacion {
  alertaStock,
  reservaConfirmada,
  nuevaDonacion,
  menuDisponible,
}

extension TipoNotificacionX on TipoNotificacion {
  String get topicName {
    switch (this) {
      case TipoNotificacion.alertaStock:
        return 'alerta_stock';
      case TipoNotificacion.reservaConfirmada:
        return 'reserva_confirmada';
      case TipoNotificacion.nuevaDonacion:
        return 'nueva_donacion';
      case TipoNotificacion.menuDisponible:
        return 'menu_disponible';
    }
  }
}

/// Servicio de notificaciones push mediante Firebase Cloud Messaging (FCM).
///
/// ## Flujo de inicialización:
/// 1. Llamar [initialize] al arrancar la app (después de Firebase.initializeApp).
/// 2. Suscribir al usuario a los topics correspondientes a su rol.
/// 3. Escuchar mensajes en primer plano con [onMessageStream].
///
/// ## Topics por rol:
/// - Administradora → `alerta_stock`, `nueva_donacion`
/// - Beneficiaria   → `menu_disponible`
/// - Donante        → (sin topics automáticos)
class NotificationService {
  final FirebaseMessaging _fcm;
  final FirebaseFirestore _db;

  NotificationService({
    FirebaseMessaging? fcm,
    FirebaseFirestore? db,
  })  : _fcm = fcm ?? FirebaseMessaging.instance,
        _db = db ?? FirebaseFirestore.instance;

  // ── Inicialización ────────────────────────────────────────────────────────

  /// Solicita permisos y configura los handlers de FCM.
  ///
  /// Debe llamarse una sola vez en [main.dart] o en un initState raíz.
  Future<void> initialize() async {
    // Solicitar permiso (relevante en iOS; en Android se concede por defecto)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Estado permiso: ${settings.authorizationStatus}');

    // Handler para mensajes recibidos en background / terminated
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

    // Mensaje que abrió la app desde estado terminado
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // App en background → se hace tap en notificación
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    debugPrint('[FCM] Servicio inicializado');
  }

  // ── Token ─────────────────────────────────────────────────────────────────

  /// Obtiene el token FCM del dispositivo actual.
  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('[FCM] Error al obtener token: $e');
      return null;
    }
  }

  /// Guarda el token FCM en el perfil del usuario en Firestore.
  Future<void> saveTokenToUser(String uid) async {
    final token = await getToken();
    if (token == null) return;
    await _db.collection('usuarios').doc(uid).update({
      'fcmToken': token,
      'fcmUpdatedAt': FieldValue.serverTimestamp(),
    });
    debugPrint('[FCM] Token guardado para usuario $uid');
  }

  // ── Topics ────────────────────────────────────────────────────────────────

  Future<void> subscribeToTopic(TipoNotificacion tipo) async {
    await _fcm.subscribeToTopic(tipo.topicName);
    debugPrint('[FCM] Suscrito a topic: ${tipo.topicName}');
  }

  Future<void> unsubscribeFromTopic(TipoNotificacion tipo) async {
    await _fcm.unsubscribeFromTopic(tipo.topicName);
    debugPrint('[FCM] Desuscrito de topic: ${tipo.topicName}');
  }

  /// Suscribe los topics correspondientes al rol del usuario.
  Future<void> suscribirSegunRol(String rol) async {
    switch (rol) {
      case 'administradora':
        await subscribeToTopic(TipoNotificacion.alertaStock);
        await subscribeToTopic(TipoNotificacion.nuevaDonacion);
        break;
      case 'beneficiaria':
        await subscribeToTopic(TipoNotificacion.menuDisponible);
        await subscribeToTopic(TipoNotificacion.reservaConfirmada);
        break;
      case 'donante':
        // Sin topics automáticos por ahora
        break;
    }
  }

  // ── Stream de mensajes en primer plano ────────────────────────────────────

  /// Stream de mensajes FCM recibidos mientras la app está en foreground.
  Stream<RemoteMessage> get onMessageStream =>
      FirebaseMessaging.onMessage;

  // ── Handlers ─────────────────────────────────────────────────────────────

  void _handleMessage(RemoteMessage message) {
    debugPrint('[FCM] Notificación abierta: ${message.notification?.title}');
    // TODO: navegar a la pantalla correspondiente según message.data['tipo']
  }
}

/// Handler de background — debe ser una función de nivel superior (no método).
@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Mensaje en background: ${message.messageId}');
}

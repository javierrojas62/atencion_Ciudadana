import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

// Servicio de notificaciones locales (como vimos en clase).
// Solo uso notificaciones instantáneas: avisan en el momento si el
// reclamo se envió o no. Por eso no hace falta el paquete timezone,
// que es para las notificaciones programadas.
class NotificationService {
  // Una sola instancia para toda la app: NotificationService() siempre
  // devuelve la misma, así el init() del main sirve para todas las pantallas
  static final NotificationService _instancia = NotificationService._interno();
  factory NotificationService() => _instancia;
  NotificationService._interno();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool initialized = false;
  bool get isInitialized => initialized;

  Future<void> init() async {
    // En el navegador no hay notificaciones del sistema
    if (kIsWeb || isInitialized) return;

    // Configuración inicial para Android (usa el ícono de la app)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración inicial para iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    // Desde Android 13 hay que pedir permiso para mostrar notificaciones
    await Permission.notification.request();

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
    initialized = true;
  }

  // Canal de notificaciones de la app
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'reclamos',
        'Reclamos',
        channelDescription: 'Avisos sobre el envío de reclamos',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  Future<void> showInstantNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    if (kIsWeb) return;

    // Si la notificación falla, no quiero que se rompa el resto de la app
    try {
      if (!isInitialized) {
        await init();
      }
      await flutterLocalNotificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails(),
      );
    } catch (e) {
      debugPrint('No se pudo mostrar la notificación: $e');
    }
  }
}

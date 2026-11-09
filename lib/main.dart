import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';
import 'src/config/supabase_config.dart';
import 'src/services/notification_service.dart';

// Punto de entrada de la app.
// Antes de arrancar conecto con Supabase e inicializo las notificaciones,
// así cualquier pantalla las puede usar.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  // Notificaciones locales (como vimos en clase)
  await NotificationService().init();

  runApp(const App());
}
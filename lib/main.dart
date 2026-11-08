import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';
import 'src/config/supabase_config.dart';

// Punto de entrada de la app.
// Antes de arrancar conecto con Supabase, así cualquier pantalla
// puede usarlo con Supabase.instance.client
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
    // PRUEBA DE CONEXIÓN (borrar después)
  try {
    final datos = await Supabase.instance.client
        .from('categorias')
        .select('nombre');
    debugPrint('✅ Conectado a Supabase: $datos');
  } catch (e) {
    debugPrint('❌ Error de conexión: $e');
  }

  runApp(const App());
}
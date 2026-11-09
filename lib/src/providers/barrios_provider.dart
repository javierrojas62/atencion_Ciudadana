import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:atencion_ciudadana/src/models/barrio_model.dart';

// Provider de barrios: los lee de Supabase.
// Se puede usar sin iniciar sesión (lo necesita la pantalla de registro).
class BarriosProvider {
  final _supabase = Supabase.instance.client;

  // Solo los barrios activos, ordenados por nombre
  Future<List<BarrioModel>> cargarActivos() async {
    final datos = await _supabase
        .from('barrios')
        .select('id, nombre')
        .eq('activo', true)
        .order('nombre');

    return datos.map((barrio) => BarrioModel.fromJson(barrio)).toList();
  }
}

// Instancia que uso desde las pantallas
final barriosProvider = BarriosProvider();

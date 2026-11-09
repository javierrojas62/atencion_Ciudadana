import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:atencion_ciudadana/src/models/categoria_model.dart';

// Provider que lee las categorías de reclamo desde Supabase.
// Antes las leía de data/categorias.json; ahora están en la base,
// así una categoría nueva aparece en la app sin tocar el código.
class CategoriasProvider {
  final _supabase = Supabase.instance.client;

  // Es un Future porque la consulta no es instantánea,
  // la pantalla lo espera con un FutureBuilder
  Future<List<CategoriaModel>> cargarData() async {
    final datos = await _supabase
        .from('categorias')
        .select('id, slug, nombre, descripcion, icono')
        .eq('activa', true)
        .order('id');

    return datos.map((cat) => CategoriaModel.fromJson(cat)).toList();
  }
}

// Instancia que uso desde las pantallas
final categoriasProvider = CategoriasProvider();

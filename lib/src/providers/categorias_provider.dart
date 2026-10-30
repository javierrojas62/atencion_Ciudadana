import 'dart:convert';

// De services solo necesito rootBundle para leer el json de los assets
import 'package:flutter/services.dart' show rootBundle;

// Provider que lee las categorías de reclamo desde data/categorias.json.
// Así si quiero agregar una categoría nueva solo toco el json.
class CategoriasProvider {
  List<dynamic> categorias = [];

  // Es un Future porque leer el archivo no es instantáneo,
  // la pantalla lo espera con un FutureBuilder
  Future<List<dynamic>> cargarData() async {
    final resp = await rootBundle.loadString('data/categorias.json');
    Map dataMap = json.decode(resp);
    categorias = dataMap['categorias'];
    return categorias;
  }
}

// Instancia que uso desde las pantallas
final categoriasProvider = CategoriasProvider();

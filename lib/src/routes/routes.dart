import 'package:flutter/material.dart';

import 'package:atencion_ciudadana/src/pages/home_page.dart';
import 'package:atencion_ciudadana/src/pages/login_page.dart';
import 'package:atencion_ciudadana/src/pages/reclamos_page.dart';
import 'package:atencion_ciudadana/src/pages/reclamo_page.dart';

// Todas las rutas de la app en un solo lugar.
// Los nombres de las categorías ('cuneta', 'bache', etc.) son los mismos
// que la propiedad "ruta" del json, así el menú navega directo con pushNamed.
Map<String, WidgetBuilder> getAplicationRoutes() {
  return <String, WidgetBuilder>{
    '/': (BuildContext context) => const HomePage(),
    'login': (BuildContext context) => const LoginPage(),
    'reclamos': (BuildContext context) => const ReclamosPage(),

    // Las 4 categorías usan la misma pantalla, solo cambia lo que le paso
    'cuneta': (BuildContext context) =>
        const ReclamoPage(categoria: 'Cuneta sucia'),
    'bache': (BuildContext context) => const ReclamoPage(categoria: 'Bache'),
    'luminaria': (BuildContext context) =>
        const ReclamoPage(categoria: 'Luminaria rota'),
    'basura': (BuildContext context) =>
        const ReclamoPage(categoria: 'Basura acumulada'),
  };
}

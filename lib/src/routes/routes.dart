import 'package:flutter/material.dart';

import 'package:atencion_ciudadana/src/models/categoria_model.dart';
import 'package:atencion_ciudadana/src/pages/admin_page.dart';
import 'package:atencion_ciudadana/src/pages/home_page.dart';
import 'package:atencion_ciudadana/src/pages/login_page.dart';
import 'package:atencion_ciudadana/src/pages/operario_page.dart';
import 'package:atencion_ciudadana/src/pages/reclamo_page.dart';
import 'package:atencion_ciudadana/src/pages/reclamos_page.dart';
import 'package:atencion_ciudadana/src/pages/registro_page.dart';

// Todas las rutas de la app en un solo lugar.
Map<String, WidgetBuilder> getAplicationRoutes() {
  return <String, WidgetBuilder>{
    '/': (BuildContext context) => const HomePage(),
    'login': (BuildContext context) => const LoginPage(),
    'registro': (BuildContext context) => const RegistroPage(),

    // Pantalla de inicio de cada rol (el login elige a cuál ir)
    'reclamos': (BuildContext context) => const ReclamosPage(),
    'operario': (BuildContext context) => const OperarioPage(),
    'admin': (BuildContext context) => const AdminPage(),

    // Formulario del reclamo: una sola ruta para todas las categorías.
    // La categoría elegida llega como argumento desde ReclamosPage.
    'reclamo': (BuildContext context) => ReclamoPage(
      categoria: ModalRoute.of(context)!.settings.arguments as CategoriaModel,
    ),
  };
}

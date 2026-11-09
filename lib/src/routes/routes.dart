import 'package:flutter/material.dart';

import 'package:atencion_ciudadana/src/models/barrio_pendientes_model.dart';
import 'package:atencion_ciudadana/src/models/categoria_model.dart';
import 'package:atencion_ciudadana/src/models/reclamo_model.dart';
import 'package:atencion_ciudadana/src/pages/admin_page.dart';
import 'package:atencion_ciudadana/src/pages/home_page.dart';
import 'package:atencion_ciudadana/src/pages/login_page.dart';
import 'package:atencion_ciudadana/src/pages/operario_barrio_page.dart';
import 'package:atencion_ciudadana/src/pages/operario_page.dart';
import 'package:atencion_ciudadana/src/pages/reclamo_detalle_page.dart';
import 'package:atencion_ciudadana/src/pages/reclamo_page.dart';
import 'package:atencion_ciudadana/src/pages/reclamos_page.dart';
import 'package:atencion_ciudadana/src/pages/registro_page.dart';

// Todas las rutas de la app en un solo lugar.
// Las que necesitan un dato (la categoría, el barrio o el reclamo)
// lo reciben como argumento de la ruta.
Map<String, WidgetBuilder> getAplicationRoutes() {
  return <String, WidgetBuilder>{
    '/': (BuildContext context) => const HomePage(),
    'login': (BuildContext context) => const LoginPage(),
    'registro': (BuildContext context) => const RegistroPage(),

    // Pantalla de inicio de cada rol (el login elige a cuál ir)
    'reclamos': (BuildContext context) => const ReclamosPage(),
    'operario': (BuildContext context) => const OperarioPage(),
    'admin': (BuildContext context) => const AdminPage(),

    // Vecino: formulario del reclamo de la categoría elegida
    'reclamo': (BuildContext context) => ReclamoPage(
      categoria: ModalRoute.of(context)!.settings.arguments as CategoriaModel,
    ),

    // Operario: reclamos de un barrio y detalle de un reclamo
    'operario_barrio': (BuildContext context) => OperarioBarrioPage(
      barrio:
          ModalRoute.of(context)!.settings.arguments as BarrioPendientesModel,
    ),
    'reclamo_detalle': (BuildContext context) => ReclamoDetallePage(
      reclamo: ModalRoute.of(context)!.settings.arguments as ReclamoModel,
    ),
  };
}

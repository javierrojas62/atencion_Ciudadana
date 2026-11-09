import 'package:flutter/material.dart';

import 'package:atencion_ciudadana/src/widgets/boton_cerrar_sesion.dart';
import 'package:atencion_ciudadana/src/widgets/en_construccion.dart';

// Pantalla del administrador. Acá van a ir el dashboard, usuarios y barrios.
class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de administración'),
        actions: const [BotonCerrarSesion()],
      ),
      body: const EnConstruccion(),
    );
  }
}

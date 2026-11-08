import 'package:flutter/material.dart';

import 'package:atencion_ciudadana/src/widgets/boton_cerrar_sesion.dart';

// Pantalla del operario. Acá van a ir los barrios con reclamos pendientes.
class OperarioPage extends StatelessWidget {
  const OperarioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reclamos pendientes'),
        actions: const [BotonCerrarSesion()],
      ),
      body: const Center(child: Text('Vista del operario (próximamente)')),
    );
  }
}
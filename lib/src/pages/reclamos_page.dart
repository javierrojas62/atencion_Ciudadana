import 'package:flutter/material.dart';

import 'package:atencion_ciudadana/src/providers/categorias_provider.dart';
import 'package:atencion_ciudadana/src/utils/icono_string_util.dart';

// Pantalla a la que llega el vecino después del login.
// Muestra las categorías de reclamo que lee del json y al tocar una
// abre la pantalla para cargar el reclamo.
class ReclamosPage extends StatelessWidget {
  const ReclamosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('¿Qué querés reportar?'),
        actions: [
          // Cerrar sesión: vuelvo a la HomePage y borro el historial de pantallas
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/',
              (route) => false,
            ),
          ),
        ],
      ),
      body: _lista(),
    );
  }

  // El FutureBuilder espera a que el provider termine de leer el json
  // y recién ahí dibuja la lista
  Widget _lista() {
    return FutureBuilder<List<dynamic>>(
      future: categoriasProvider.cargarData(),
      initialData: const [],
      builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
        return ListView(
          children: _listaItems(snapshot.data ?? [], context),
        );
      },
    );
  }

  // Armo un ListTile por cada categoría del json
  List<Widget> _listaItems(List<dynamic> data, BuildContext context) {
    final List<Widget> opciones = [];

    for (var opt in data) {
      final widgetTemp = ListTile(
        title: Text(opt['texto']),
        subtitle: Text(opt['descripcion']),
        leading: getIcon(opt['icon']),
        trailing: const Icon(Icons.arrow_forward_ios),
        // La ruta sale del json, así no tengo que hacer un if por categoría
        onTap: () => Navigator.pushNamed(context, opt['ruta']),
      );

      opciones.add(widgetTemp);
      opciones.add(const Divider());
    }

    return opciones;
  }
}

import 'package:flutter/material.dart';

import 'package:atencion_ciudadana/src/providers/auth_provider.dart';
import 'package:atencion_ciudadana/src/providers/categorias_provider.dart';
import 'package:atencion_ciudadana/src/utils/icono_string_util.dart';
import 'package:atencion_ciudadana/src/widgets/boton_cerrar_sesion.dart';

// Pantalla a la que llega el vecino después del login.
// Lo saluda por su nombre y muestra las categorías de reclamo que lee
// del json. Al tocar una abre la pantalla para cargar el reclamo.
class ReclamosPage extends StatelessWidget {
  const ReclamosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atención Ciudadana'),
        actions: const [BotonCerrarSesion()],
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
          padding: const EdgeInsets.only(bottom: 16),
          children: _listaItems(snapshot.data ?? [], context),
        );
      },
    );
  }

  // Saludo arriba y una tarjeta por cada categoría del json
  List<Widget> _listaItems(List<dynamic> data, BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final List<Widget> opciones = [_crearEncabezado(context)];

    for (var opt in data) {
      final widgetTemp = Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: colores.primaryContainer,
            child: getIcon(opt['icon']),
          ),
          title: Text(
            opt['texto'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(opt['descripcion']),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          // La ruta sale del json, así no tengo que hacer un if por categoría
          onTap: () => Navigator.pushNamed(context, opt['ruta']),
        ),
      );

      opciones.add(widgetTemp);
    }

    return opciones;
  }

  // Saludo con el nombre del vecino que inició sesión
  Widget _crearEncabezado(BuildContext context) {
    final nombre = authProvider.perfilActual?.nombre ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nombre.isEmpty ? 'Hola' : 'Hola, $nombre',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '¿Qué problema querés reportar?',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

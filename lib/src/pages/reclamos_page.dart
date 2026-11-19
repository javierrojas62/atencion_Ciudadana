import 'package:flutter/material.dart';

import 'package:atencion_ciudadana/src/models/categoria_model.dart';
import 'package:atencion_ciudadana/src/providers/auth_provider.dart';
import 'package:atencion_ciudadana/src/providers/categorias_provider.dart';
import 'package:atencion_ciudadana/src/utils/icono_string_util.dart';
import 'package:atencion_ciudadana/src/widgets/boton_cerrar_sesion.dart';

// Pantalla a la que llega el vecino después del login.
class ReclamosPage extends StatelessWidget {
  const ReclamosPage({super.key});

  // ===== BUILD =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atención Ciudadana'),
        actions: [
          // Acceso al historial de reclamos del vecino
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Mis reclamos',
            onPressed: () => Navigator.pushNamed(context, 'mis_reclamos'),
          ),
          const BotonCerrarSesion(),
        ],
      ),
      body: _lista(),
    );
  }

  // ===== WIDGETS =====
  // El FutureBuilder espera a que el provider traiga las categorías y recién ahí dibuja la lista
  Widget _lista() {
    return FutureBuilder<List<CategoriaModel>>(
      future: categoriasProvider.cargarData(),
      builder: (BuildContext context, snapshot) {
        final List<Widget> items = [
          _crearEncabezado(context),
          _crearTarjetaMisReclamos(context),
        ];

        if (snapshot.hasError) {
          items.add(
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No se pudieron cargar las categorías. Revisá tu conexión.',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        } else if (!snapshot.hasData) {
          items.add(
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        } else {
          items.addAll(_listaItems(snapshot.data!, context));
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: items,
        );
      },
    );
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
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
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

  // Tarjeta para entrar al historial 
  Widget _crearTarjetaMisReclamos(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      color: colores.secondaryContainer,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colores.surface,
          child: Icon(Icons.history, color: colores.primary),
        ),
        title: const Text(
          'Mis reclamos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Mirá el estado de lo que reportaste'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.pushNamed(context, 'mis_reclamos'),
      ),
    );
  }

  // Una tarjeta por cada categoría
  List<Widget> _listaItems(List<CategoriaModel> data, BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final List<Widget> opciones = [];

    for (var categoria in data) {
      final widgetTemp = Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: colores.primaryContainer,
            child: getIcon(categoria.icono),
          ),
          title: Text(
            categoria.nombre,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(categoria.descripcion),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          // Una sola ruta para todas las categorías: le paso la elegida
          onTap: () =>
              Navigator.pushNamed(context, 'reclamo', arguments: categoria),
        ),
      );

      opciones.add(widgetTemp);
    }

    return opciones;
  }
}

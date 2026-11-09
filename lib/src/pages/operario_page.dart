import 'package:flutter/material.dart';

import 'package:atencion_ciudadana/src/models/barrio_pendientes_model.dart';
import 'package:atencion_ciudadana/src/providers/auth_provider.dart';
import 'package:atencion_ciudadana/src/providers/reclamos_provider.dart';
import 'package:atencion_ciudadana/src/widgets/boton_cerrar_sesion.dart';

// Pantalla de inicio del operario.
// Muestra los barrios que tienen reclamos pendientes, con la cantidad.
// Al tocar uno, ve los reclamos de ese barrio.
class OperarioPage extends StatefulWidget {
  const OperarioPage({super.key});

  @override
  State<OperarioPage> createState() => _OperarioPageState();
}

class _OperarioPageState extends State<OperarioPage> {
  late Future<List<BarrioPendientesModel>> _barrios =
      reclamosProvider.barriosConPendientes();

  // Vuelve a pedir los datos (al deslizar hacia abajo o al volver
  // de un barrio, porque puede haber resuelto reclamos)
  Future<void> _recargar() async {
    setState(() {
      _barrios = reclamosProvider.barriosConPendientes();
    });
    await _barrios;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reclamos pendientes'),
        actions: const [BotonCerrarSesion()],
      ),
      // Deslizando hacia abajo se actualiza la lista
      body: RefreshIndicator(onRefresh: _recargar, child: _lista()),
    );
  }

  Widget _lista() {
    return FutureBuilder<List<BarrioPendientesModel>>(
      future: _barrios,
      builder: (context, snapshot) {
        final List<Widget> items = [_crearEncabezado()];

        if (snapshot.hasError) {
          items.add(
            _crearMensaje(
              Icons.wifi_off,
              'No se pudieron cargar los reclamos. Deslizá hacia abajo para reintentar.',
            ),
          );
        } else if (!snapshot.hasData) {
          items.add(
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        } else if (snapshot.data!.isEmpty) {
          items.add(
            _crearMensaje(Icons.check_circle, 'No hay reclamos pendientes.'),
          );
        } else {
          items.addAll(snapshot.data!.map(_crearTarjetaBarrio));
        }

        // AlwaysScrollable para que se pueda deslizar aunque haya pocos items
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 16),
          children: items,
        );
      },
    );
  }

  Widget _crearEncabezado() {
    final nombre = authProvider.perfilActual?.nombre ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nombre.isEmpty ? 'Hola' : 'Hola, $nombre',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Barrios con reclamos para resolver',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _crearTarjetaBarrio(BarrioPendientesModel barrio) {
    final colores = Theme.of(context).colorScheme;
    final texto = barrio.pendientes == 1
        ? '1 reclamo pendiente'
        : '${barrio.pendientes} reclamos pendientes';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colores.primaryContainer,
          child: Icon(Icons.location_city, color: colores.primary),
        ),
        title: Text(
          barrio.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(texto),
        trailing: CircleAvatar(
          radius: 14,
          backgroundColor: Colors.orange,
          child: Text(
            '${barrio.pendientes}',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
        onTap: () async {
          await Navigator.pushNamed(
            context,
            'operario_barrio',
            arguments: barrio,
          );
          // Al volver actualizo, por si resolvió alguno
          _recargar();
        },
      ),
    );
  }

  Widget _crearMensaje(IconData icono, String texto) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(icono, size: 70, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

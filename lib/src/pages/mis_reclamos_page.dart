import 'package:flutter/material.dart';

import 'package:atencion_ciudadana/src/models/reclamo_model.dart';
import 'package:atencion_ciudadana/src/providers/reclamos_provider.dart';

// Historial del vecino: todos los reclamos que cargó, con su estado.
// Se pueden filtrar por pendientes o resueltos. Al tocar uno abre el
// detalle, donde ve el antes y después, o lo edita/elimina si sigue pendiente.
class MisReclamosPage extends StatefulWidget {
  const MisReclamosPage({super.key});

  @override
  State<MisReclamosPage> createState() => _MisReclamosPageState();
}

class _MisReclamosPageState extends State<MisReclamosPage> {
  late Future<List<ReclamoModel>> _reclamos = reclamosProvider.misReclamos();

  // Filtro elegido: 'todos', 'pendientes' o 'resueltos'
  String _filtro = 'todos';

  // Vuelve a pedir los datos (al deslizar hacia abajo o al volver
  // del detalle, porque puede haber editado o eliminado uno)
  Future<void> _recargar() async {
    setState(() {
      _reclamos = reclamosProvider.misReclamos();
    });
    await _reclamos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis reclamos')),
      body: RefreshIndicator(onRefresh: _recargar, child: _lista()),
    );
  }

  Widget _lista() {
    return FutureBuilder<List<ReclamoModel>>(
      future: _reclamos,
      builder: (context, snapshot) {
        final List<Widget> items = [_crearFiltro()];

        if (snapshot.hasError) {
          items.add(
            _crearMensaje(
              Icons.wifi_off,
              'No se pudieron cargar tus reclamos. Deslizá hacia abajo para reintentar.',
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
          items.add(_crearMensaje(Icons.inbox, 'Todavía no hiciste reclamos'));
        } else {
          final filtrados = _filtrar(snapshot.data!);
          if (filtrados.isEmpty) {
            items.add(
              _crearMensaje(Icons.inbox, 'No hay reclamos con este filtro'),
            );
          } else {
            items.addAll(filtrados.map(_crearTarjetaReclamo));
          }
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

  // El filtro se aplica sobre la lista que ya trajo, sin volver a consultar
  List<ReclamoModel> _filtrar(List<ReclamoModel> reclamos) {
    if (_filtro == 'pendientes') {
      return reclamos.where((r) => r.pendiente).toList();
    }
    if (_filtro == 'resueltos') {
      return reclamos.where((r) => !r.pendiente).toList();
    }
    return reclamos;
  }

  Widget _crearFiltro() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'todos', label: Text('Todos')),
          ButtonSegment(value: 'pendientes', label: Text('Pendientes')),
          ButtonSegment(value: 'resueltos', label: Text('Resueltos')),
        ],
        selected: {_filtro},
        onSelectionChanged: (seleccion) {
          setState(() {
            _filtro = seleccion.first;
          });
        },
      ),
    );
  }

  // Tarjeta con miniatura de la foto, título, barrio, fecha y estado
  Widget _crearTarjetaReclamo(ReclamoModel reclamo) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            reclamo.fotoUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            // Si la foto no carga muestro un ícono en su lugar
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox(width: 60, height: 60, child: Icon(Icons.image)),
          ),
        ),
        title: Text(
          reclamo.titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reclamo.barrio),
            const SizedBox(height: 4),
            Text(
              reclamo.fecha,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: _crearEtiquetaEstado(reclamo),
        onTap: () async {
          final cambio = await Navigator.pushNamed(
            context,
            'mi_reclamo_detalle',
            arguments: reclamo,
          );
          // Si lo editó o eliminó, actualizo la lista
          if (cambio == true) _recargar();
        },
      ),
    );
  }

  // Etiqueta naranja si está pendiente, verde si está resuelto
  Widget _crearEtiquetaEstado(ReclamoModel reclamo) {
    final color = reclamo.pendiente ? Colors.orange : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        reclamo.pendiente ? 'Pendiente' : 'Resuelto',
        style: const TextStyle(color: Colors.white, fontSize: 12),
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

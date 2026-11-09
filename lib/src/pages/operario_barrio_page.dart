import 'package:flutter/material.dart';

import 'package:atencion_ciudadana/src/models/barrio_pendientes_model.dart';
import 'package:atencion_ciudadana/src/models/reclamo_model.dart';
import 'package:atencion_ciudadana/src/providers/reclamos_provider.dart';

// Reclamos pendientes de un barrio (vista del operario).
// Al tocar uno abre el detalle, donde lo puede realizar.
class OperarioBarrioPage extends StatefulWidget {
  final BarrioPendientesModel barrio;

  const OperarioBarrioPage({super.key, required this.barrio});

  @override
  State<OperarioBarrioPage> createState() => _OperarioBarrioPageState();
}

class _OperarioBarrioPageState extends State<OperarioBarrioPage> {
  late Future<List<ReclamoModel>> _reclamos = reclamosProvider
      .pendientesDeBarrio(widget.barrio.id);

  Future<void> _recargar() async {
    setState(() {
      _reclamos = reclamosProvider.pendientesDeBarrio(widget.barrio.id);
    });
    await _reclamos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.barrio.nombre)),
      body: RefreshIndicator(onRefresh: _recargar, child: _lista()),
    );
  }

  Widget _lista() {
    return FutureBuilder<List<ReclamoModel>>(
      future: _reclamos,
      builder: (context, snapshot) {
        final List<Widget> items = [];

        if (snapshot.hasError) {
          items.add(
            _crearMensaje(
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
            _crearMensaje('Este barrio no tiene más reclamos pendientes.'),
          );
        } else {
          items.addAll(snapshot.data!.map(_crearTarjetaReclamo));
        }

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: items,
        );
      },
    );
  }

  // Tarjeta con una miniatura de la foto, la categoría y la descripción
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
          reclamo.categoria,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reclamo.descripcion,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              reclamo.fecha,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          final resuelto = await Navigator.pushNamed(
            context,
            'reclamo_detalle',
            arguments: reclamo,
          );
          // Si lo realizó, actualizo la lista para que desaparezca
          if (resuelto == true) _recargar();
        },
      ),
    );
  }

  Widget _crearMensaje(String texto) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.check_circle, size: 70, color: Colors.grey.shade400),
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

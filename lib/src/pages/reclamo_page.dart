import 'package:flutter/material.dart';

import 'package:atencion_ciudadana/src/models/barrio_model.dart';
import 'package:atencion_ciudadana/src/providers/auth_provider.dart';
import 'package:atencion_ciudadana/src/providers/barrios_provider.dart';

// Pantalla para cargar un reclamo.
// Es la misma para todas las categorías, la categoría me llega por el constructor
// desde routes.dart.
class ReclamoPage extends StatefulWidget {
  final String categoria;

  const ReclamoPage({super.key, required this.categoria});

  @override
  State<ReclamoPage> createState() => _ReclamoPageState();
}

class _ReclamoPageState extends State<ReclamoPage> {
  String _descripcion = '';

  // Barrios de Rawson desde Supabase. Se piden una sola vez al abrir la pantalla.
  late final Future<List<BarrioModel>> _barrios =
      barriosProvider.cargarActivos();

  // Arranca con el barrio del vecino, pero lo puede cambiar
  // si el problema está en otro lado
  int? _barrioSeleccionado = authProvider.perfilActual?.barrioId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reclamo: ${widget.categoria}')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _crearTarjetaCategoria(),
          const SizedBox(height: 20),
          _crearDropdown(),
          const SizedBox(height: 20),
          _crearDescripcion(),
          const SizedBox(height: 20),
          _crearFotoPendiente(),
          const SizedBox(height: 30),
          _crearBoton(),
        ],
      ),
    );
  }

  // Tarjeta arriba de todo para que el vecino vea qué está reportando
  Widget _crearTarjetaCategoria() {
    return Card(
      child: ListTile(
        leading: Icon(
          Icons.report_problem,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(widget.categoria),
        subtitle: const Text('Completá los datos del problema'),
      ),
    );
  }

  // Lista de barrios. Como vienen de Supabase, uso un FutureBuilder.
  Widget _crearDropdown() {
    return FutureBuilder<List<BarrioModel>>(
      future: _barrios,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(
            'No se pudieron cargar los barrios. Revisá tu conexión.',
            style: TextStyle(color: Colors.red),
          );
        }

        final barrios = snapshot.data ?? [];

        // El valor elegido tiene que estar en la lista, si no el
        // DropdownButton da error (pasa mientras carga, o si el barrio
        // del vecino fue desactivado)
        final existe = barrios.any((b) => b.id == _barrioSeleccionado);

        return Row(
          children: [
            const Icon(Icons.location_on),
            const SizedBox(width: 20),
            Expanded(
              child: DropdownButton<int>(
                isExpanded: true,
                value: existe ? _barrioSeleccionado : null,
                hint: Text(barrios.isEmpty ? 'Cargando barrios...' : 'Elegí el barrio'),
                items: barrios
                    .map(
                      (barrio) => DropdownMenuItem(
                        value: barrio.id,
                        child: Text(barrio.nombre),
                      ),
                    )
                    .toList(),
                onChanged: (opt) {
                  setState(() {
                    _barrioSeleccionado = opt;
                  });
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // Campo para describir el problema
  Widget _crearDescripcion() {
    return TextField(
      textCapitalization: TextCapitalization.sentences,
      maxLines: 4,
      decoration: InputDecoration(
        counter: Text('Letras ${_descripcion.length}'),
        labelText: 'Descripción',
        hintText: 'Ej: hay un bache grande frente a la escuela',
        helperText: 'Contá qué pasa y alguna referencia del lugar',
        alignLabelWithHint: true,
      ),
      onChanged: (valor) {
        setState(() {
          _descripcion = valor;
        });
      },
    );
  }

  // Lugar reservado para la foto y el GPS, lo hago en el próximo paso
  Widget _crearFotoPendiente() {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.camera_alt),
        title: Text('Foto y ubicación GPS'),
        subtitle: Text('Próximamente'),
      ),
    );
  }

  Widget _crearBoton() {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      icon: const Icon(Icons.send),
      label: const Text('Enviar reclamo'),
      onPressed: _enviarReclamo,
    );
  }

  Future<void> _enviarReclamo() async {
    if (_barrioSeleccionado == null) {
      _avisar('Elegí el barrio donde está el problema');
      return;
    }

    // Sin descripción no lo dejo enviar
    if (_descripcion.trim().isEmpty) {
      _avisar('Escribí una descripción del problema');
      return;
    }

    // Busco el nombre del barrio elegido para mostrarlo en el mensaje
    final barrios = await _barrios;
    final nombreBarrio = barrios
        .firstWhere((b) => b.id == _barrioSeleccionado)
        .nombre;

    if (!mounted) return;

    // TODO: guardar el reclamo en Supabase (próximo paso, con foto y GPS)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: const Text('Reclamo enviado'),
          content: Column(
            // Para que la alerta se adapte al contenido
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 12),
              Text(
                'Tu reclamo de "${widget.categoria}" en $nombreBarrio '
                'quedó en estado pendiente.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Cierro la alerta y vuelvo a la lista de categorías
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }
}

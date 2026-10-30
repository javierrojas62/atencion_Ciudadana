import 'package:flutter/material.dart';

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

  // Barrios de prueba. Después van a venir de la API según el departamento del vecino
  final List<String> _barrios = [
    'Centro',
    'Trinidad',
    'Concepción',
    'Desamparados',
  ];
  String _barrioSeleccionado = 'Centro';

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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
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

  // Lista de opciones para el dropdown de barrios
  List<DropdownMenuItem<String>> _getOpcionesDropdown() {
    List<DropdownMenuItem<String>> lista = [];
    for (var barrio in _barrios) {
      lista.add(DropdownMenuItem(value: barrio, child: Text(barrio)));
    }
    return lista;
  }

  Widget _crearDropdown() {
    return Row(
      children: [
        const Icon(Icons.location_on),
        const SizedBox(width: 20),
        Expanded(
          child: DropdownButton<String>(
            isExpanded: true,
            value: _barrioSeleccionado,
            items: _getOpcionesDropdown(),
            onChanged: (opt) {
              setState(() {
                _barrioSeleccionado = opt!;
              });
            },
          ),
        ),
      ],
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

  void _enviarReclamo() {
    // Sin descripción no lo dejo enviar
    if (_descripcion.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribí una descripción del problema')),
      );
      return;
    }

    // TODO: mandar el reclamo a la API de Laravel
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
                'Tu reclamo de "${widget.categoria}" en $_barrioSeleccionado '
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
}

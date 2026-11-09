import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:atencion_ciudadana/src/models/reclamo_model.dart';
import 'package:atencion_ciudadana/src/providers/reclamos_provider.dart';
import 'package:atencion_ciudadana/src/utils/foto_util.dart';
import 'package:atencion_ciudadana/src/utils/icono_string_util.dart';
import 'package:atencion_ciudadana/src/widgets/mapa_ubicacion.dart';
import 'package:atencion_ciudadana/src/widgets/vista_foto.dart';

// Detalle de un reclamo (vista del operario).
// Arriba ve lo que cargó el vecino: foto, descripción y mapa.
// Abajo realiza el trabajo: saca la foto del arreglo, agrega una
// observación (opcional) y lo marca como realizado.
class ReclamoDetallePage extends StatefulWidget {
  final ReclamoModel reclamo;

  const ReclamoDetallePage({super.key, required this.reclamo});

  @override
  State<ReclamoDetallePage> createState() => _ReclamoDetallePageState();
}

class _ReclamoDetallePageState extends State<ReclamoDetallePage> {
  final _observacionController = TextEditingController();

  // Foto del trabajo terminado
  Uint8List? _fotoArreglo;
  bool _enviando = false;

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reclamo = widget.reclamo;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del reclamo')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _crearFotoVecino(),
          const SizedBox(height: 12),
          _crearTarjetaCategoria(),
          const SizedBox(height: 20),
          _crearTitulo('Descripción del vecino'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                reclamo.descripcion,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _crearTitulo('Ubicación'),
          MapaUbicacion(punto: reclamo.punto),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _crearTitulo('Realizar el trabajo'),
          VistaFoto(
            foto: _fotoArreglo,
            onTomarFoto: _tomarFoto,
            texto: 'Tocá para sacar la foto del arreglo',
          ),
          const SizedBox(height: 16),
          _crearObservacion(),
          const SizedBox(height: 24),
          _crearBoton(),
        ],
      ),
    );
  }

  // Foto que sacó el vecino
  Widget _crearFotoVecino() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        widget.reclamo.fotoUrl,
        height: 240,
        width: double.infinity,
        fit: BoxFit.cover,
        // Circulito mientras carga
        loadingBuilder: (context, child, progreso) {
          if (progreso == null) return child;
          return const SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stackTrace) => const SizedBox(
          height: 240,
          child: Center(child: Text('No se pudo cargar la foto')),
        ),
      ),
    );
  }

  Widget _crearTarjetaCategoria() {
    final reclamo = widget.reclamo;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: getIcon(reclamo.categoriaIcono),
        ),
        title: Text(
          reclamo.categoria,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${reclamo.barrio} · ${reclamo.fecha}'),
      ),
    );
  }

  Widget _crearTitulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _crearObservacion() {
    return TextField(
      controller: _observacionController,
      textCapitalization: TextCapitalization.sentences,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Observación (opcional)',
        hintText: 'Ej: se limpió la cuneta y se retiró la basura',
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _crearBoton() {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      icon: _enviando
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.check),
      label: Text(_enviando ? 'Guardando...' : 'Marcar como realizado'),
      onPressed: _enviando ? null : _realizar,
    );
  }

  Future<void> _tomarFoto() async {
    final foto = await tomarFotoConPermiso(
      context,
      motivo: 'Necesitamos la cámara para sacar la foto del arreglo',
    );
    if (foto == null || !mounted) return;

    setState(() {
      _fotoArreglo = foto;
    });
  }

  Future<void> _realizar() async {
    // La foto del arreglo es obligatoria; la observación no
    if (_fotoArreglo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sacá una foto del trabajo terminado')),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      await reclamosProvider.realizarReclamo(
        reclamoId: widget.reclamo.id,
        fotoArreglo: _fotoArreglo!,
        observacion: _observacionController.text,
      );
    } on ReclamoException catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      _mostrarAlerta(
        titulo: 'No se pudo guardar',
        mensaje: e.mensaje,
        icono: Icons.error,
        color: Colors.red,
      );
      return;
    }

    if (!mounted) return;
    setState(() => _enviando = false);

    _mostrarAlerta(
      titulo: 'Reclamo resuelto',
      mensaje: 'El reclamo quedó cerrado con la foto del arreglo.',
      icono: Icons.check_circle,
      color: Colors.green,
      // Al cerrar vuelvo a la lista avisando que se resolvió
      alCerrar: () => Navigator.of(context).pop(true),
    );
  }

  void _mostrarAlerta({
    required String titulo,
    required String mensaje,
    required IconData icono,
    required Color color,
    VoidCallback? alCerrar,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Text(titulo),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, color: color, size: 60),
              const SizedBox(height: 12),
              Text(mensaje, textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                alCerrar?.call();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

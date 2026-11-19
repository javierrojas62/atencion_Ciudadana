import 'package:flutter/material.dart';

import 'package:atencion_ciudadana/src/models/reclamo_model.dart';
import 'package:atencion_ciudadana/src/providers/reclamos_provider.dart';
import 'package:atencion_ciudadana/src/utils/icono_string_util.dart';
import 'package:atencion_ciudadana/src/widgets/mapa_ubicacion.dart';

// Detalle de un reclamo del vecino (desde su historial).
// - Resuelto: ve el antes y después, la observación y cuándo se resolvió.
// - Pendiente: ve su foto y puede editar la descripción o eliminarlo.
// Al volver devuelve true si cambió algo, así la lista se actualiza.
class MiReclamoDetallePage extends StatefulWidget {
  final ReclamoModel reclamo;

  const MiReclamoDetallePage({super.key, required this.reclamo});

  @override
  State<MiReclamoDetallePage> createState() => _MiReclamoDetallePageState();
}

class _MiReclamoDetallePageState extends State<MiReclamoDetallePage> {
  // ===== VARIABLES DE ESTADO =====
  // Mientras se guarda o se elimina deshabilito los botones
  bool _guardando = false;

  bool _eliminando = false;

  bool get _ocupado => _guardando || _eliminando;

  // ===== LLAMADAS Y ACCIONES =====
  // ---------------------------------------------------------------------
  // MODIFICACIÓN
  // ---------------------------------------------------------------------

  // Abre un diálogo con un Form para editar la descripción.
  // Si es "Otro", también deja cambiar qué problema es.
  Future<void> _editar() async {
    final reclamo = widget.reclamo;
    final formKey = GlobalKey<FormState>();
    final esOtro = reclamo.tipoOtro != null;

    String descripcion = reclamo.descripcion;
    String tipoOtro = reclamo.tipoOtro ?? '';

    // El diálogo devuelve true si tocó Guardar y el form es válido
    final guardar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: const Text('Editar descripción'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (esOtro) ...[
                    TextFormField(
                      initialValue: tipoOtro,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 60,
                      decoration: const InputDecoration(
                        labelText: '¿Qué problema es?',
                        hintText: 'Ej: árbol caído',
                      ),
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) {
                          return 'Contá qué tipo de problema es';
                        }
                        return null;
                      },
                      onSaved: (valor) => tipoOtro = valor!.trim(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    initialValue: descripcion,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      alignLabelWithHint: true,
                    ),
                    // Mismas reglas que la base: obligatoria y 5 letras mínimo
                    validator: (valor) {
                      final texto = valor?.trim() ?? '';
                      if (texto.isEmpty) {
                        return 'Escribí una descripción del problema';
                      }
                      if (texto.length < 5) {
                        return 'La descripción tiene que tener al menos 5 letras';
                      }
                      return null;
                    },
                    onSaved: (valor) => descripcion = valor!.trim(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (guardar != true || !mounted) return;

    setState(() => _guardando = true);

    try {
      await reclamosProvider.editarReclamo(
        reclamoId: reclamo.id,
        descripcion: descripcion,
        tipoOtro: esOtro ? tipoOtro : null,
      );
    } on ReclamoException catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _mostrarError('No se pudo modificar', e.mensaje);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Reclamo actualizado')));
    // Vuelvo a la lista avisando que cambió
    Navigator.pop(context, true);
  }

  // ---------------------------------------------------------------------
  // ELIMINACIÓN
  // ---------------------------------------------------------------------

  // Pido confirmación antes de eliminar porque no se puede deshacer
  Future<void> _confirmarEliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: const Text('¿Eliminar este reclamo?'),
          content: const Text('No se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) return;

    setState(() => _eliminando = true);

    try {
      await reclamosProvider.eliminarReclamo(widget.reclamo);
    } on ReclamoException catch (e) {
      if (!mounted) return;
      setState(() => _eliminando = false);
      _mostrarError('No se pudo eliminar', e.mensaje);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Reclamo eliminado')));
    Navigator.pop(context, true);
  }

  // ===== BUILD =====
  @override
  Widget build(BuildContext context) {
    final reclamo = widget.reclamo;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi reclamo')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          if (reclamo.pendiente) ...[
            _crearFoto(reclamo.fotoUrl, alto: 240),
            const SizedBox(height: 12),
            _crearAvisoPendiente(),
          ] else
            _crearAntesDespues(),
          const SizedBox(height: 12),
          _crearTarjetaCategoria(),
          const SizedBox(height: 20),
          _crearTitulo('Descripción'),
          _crearTexto(reclamo.descripcion),
          // Lo que anotó el operario al resolverlo (es opcional)
          if (!reclamo.pendiente && reclamo.observacion != null) ...[
            const SizedBox(height: 20),
            _crearTitulo('Observación del operario'),
            _crearTexto(reclamo.observacion!),
          ],
          const SizedBox(height: 20),
          _crearTitulo('Ubicación'),
          MapaUbicacion(punto: reclamo.punto),
          // Solo mientras está pendiente se puede modificar o eliminar
          if (reclamo.pendiente) ...[
            const SizedBox(height: 24),
            _crearBotonEditar(),
            const SizedBox(height: 12),
            _crearBotonEliminar(),
          ],
        ],
      ),
    );
  }

  // ===== WIDGETS =====
  // Foto desde la URL de Storage, con circulito mientras carga
  Widget _crearFoto(String url, {double alto = 180}) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        url,
        height: alto,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progreso) {
          if (progreso == null) return child;
          return SizedBox(
            height: alto,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stackTrace) => SizedBox(
          height: alto,
          child: const Center(child: Text('No se pudo cargar la foto')),
        ),
      ),
    );
  }

  Widget _crearAvisoPendiente() {
    return Card(
      color: Colors.orange.shade50,
      child: const ListTile(
        leading: Icon(Icons.schedule, color: Colors.orange),
        title: Text('Pendiente: todavía no fue atendido'),
      ),
    );
  }

  // Foto del vecino y foto del arreglo, una al lado de la otra
  Widget _crearAntesDespues() {
    final reclamo = widget.reclamo;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [_crearTitulo('Antes'), _crearFoto(reclamo.fotoUrl)],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                  _crearTitulo('Después'),
                  // Un reclamo resuelto siempre tiene foto del arreglo,
                  // pero por las dudas muestro un aviso si falta
                  reclamo.fotoReparacionUrl == null
                      ? const SizedBox(
                          height: 180,
                          child: Center(child: Text('Sin foto')),
                        )
                      : _crearFoto(reclamo.fotoReparacionUrl!),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          color: Colors.green.shade50,
          child: ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('Resuelto'),
            subtitle: Text(reclamo.fechaResuelto),
          ),
        ),
      ],
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

  Widget _crearTarjetaCategoria() {
    final reclamo = widget.reclamo;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: getIcon(reclamo.categoriaIcono),
        ),
        title: Text(
          reclamo.titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${reclamo.barrio} · ${reclamo.fecha}'),
      ),
    );
  }

  Widget _crearTexto(String texto) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(texto, style: const TextStyle(fontSize: 15)),
        ),
      ),
    );
  }

  Widget _crearBotonEditar() {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      icon: _guardando ? _circulito() : const Icon(Icons.edit),
      label: Text(_guardando ? 'Guardando...' : 'Editar descripción'),
      onPressed: _ocupado ? null : _editar,
    );
  }

  // Circulito para los botones mientras se espera a la base
  Widget _circulito() {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

  Widget _crearBotonEliminar() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      icon: _eliminando ? _circulito() : const Icon(Icons.delete),
      label: Text(_eliminando ? 'Eliminando...' : 'Eliminar reclamo'),
      onPressed: _ocupado ? null : _confirmarEliminar,
    );
  }

  // ===== DIÁLOGOS Y AVISOS =====
  void _mostrarError(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Text(titulo),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 60),
              const SizedBox(height: 12),
              Text(mensaje, textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

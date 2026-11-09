import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:atencion_ciudadana/src/models/barrio_model.dart';
import 'package:atencion_ciudadana/src/models/categoria_model.dart';
import 'package:atencion_ciudadana/src/providers/auth_provider.dart';
import 'package:atencion_ciudadana/src/providers/barrios_provider.dart';
import 'package:atencion_ciudadana/src/providers/reclamos_provider.dart';
import 'package:atencion_ciudadana/src/services/notification_service.dart';
import 'package:atencion_ciudadana/src/services/ubicacion_service.dart';
import 'package:atencion_ciudadana/src/utils/foto_util.dart';
import 'package:atencion_ciudadana/src/utils/icono_string_util.dart';
import 'package:atencion_ciudadana/src/widgets/mapa_ubicacion.dart';
import 'package:atencion_ciudadana/src/widgets/vista_foto.dart';

// Pantalla para cargar un reclamo.
// Es la misma para todas las categorías: la categoría elegida me llega
// como argumento de la ruta (ver routes.dart).
class ReclamoPage extends StatefulWidget {
  final CategoriaModel categoria;

  const ReclamoPage({super.key, required this.categoria});

  @override
  State<ReclamoPage> createState() => _ReclamoPageState();
}

class _ReclamoPageState extends State<ReclamoPage> {
  String _descripcion = '';

  // Foto del problema (en bytes, así sirve en el celular y en la web)
  Uint8List? _foto;

  // Barrios de Rawson desde Supabase. Se piden una sola vez al abrir la pantalla.
  late final Future<List<BarrioModel>> _barrios =
      barriosProvider.cargarActivos();

  // Arranca con el barrio del vecino, pero lo puede cambiar
  // si el problema está en otro lado
  int? _barrioSeleccionado = authProvider.perfilActual?.barrioId;

  // Ubicación actual del GPS (null mientras se busca o si hubo error)
  LatLng? _ubicacion;
  bool _buscandoUbicacion = false;
  UbicacionException? _errorUbicacion;

  // Mientras se sube la foto y se guarda el reclamo
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    // Apenas se abre el formulario busco la ubicación
    _buscarUbicacion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo reclamo')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _crearTarjetaCategoria(),
          const SizedBox(height: 20),
          _crearDropdown(),
          const SizedBox(height: 20),
          _crearDescripcion(),
          const SizedBox(height: 20),
          _crearTitulo('Foto del problema'),
          VistaFoto(foto: _foto, onTomarFoto: _tomarFoto),
          const SizedBox(height: 20),
          _crearTitulo('Ubicación del problema'),
          _crearUbicacion(),
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
        // Mismo ícono que en la lista de categorías
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: getIcon(widget.categoria.icono),
        ),
        title: Text(
          widget.categoria.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Completá los datos del problema'),
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
                hint: Text(
                  barrios.isEmpty ? 'Cargando barrios...' : 'Elegí el barrio',
                ),
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

  // Mapa con la ubicación actual. Tiene 3 estados:
  // buscando, error (con opción de reintentar) y listo (muestra el mapa)
  Widget _crearUbicacion() {
    if (_buscandoUbicacion) {
      return const Card(
        child: ListTile(
          leading: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          title: Text('Obteniendo tu ubicación...'),
        ),
      );
    }

    if (_errorUbicacion != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.location_off, color: Colors.red),
                title: Text(_errorUbicacion!.mensaje),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_errorUbicacion!.permanente)
                    TextButton(
                      onPressed: ubicacionService.abrirAjustes,
                      child: const Text('Abrir ajustes'),
                    ),
                  TextButton.icon(
                    onPressed: _buscarUbicacion,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_ubicacion == null) return const SizedBox.shrink();

    return Column(
      children: [
        // La key hace que el mapa se vuelva a centrar si cambia la ubicación
        MapaUbicacion(key: ValueKey(_ubicacion), punto: _ubicacion!),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _buscarUbicacion,
            icon: const Icon(Icons.my_location),
            label: const Text('Actualizar ubicación'),
          ),
        ),
      ],
    );
  }

  // Pide la ubicación al servicio y actualiza la pantalla según el resultado
  Future<void> _buscarUbicacion() async {
    setState(() {
      _buscandoUbicacion = true;
      _errorUbicacion = null;
    });

    try {
      final ubicacion = await ubicacionService.obtenerUbicacionActual();
      if (!mounted) return;
      setState(() => _ubicacion = ubicacion);
    } on UbicacionException catch (e) {
      if (!mounted) return;
      setState(() => _errorUbicacion = e);
    } finally {
      if (mounted) setState(() => _buscandoUbicacion = false);
    }
  }

  // Mientras se envía deshabilito el botón y muestro el circulito,
  // así no se manda dos veces el mismo reclamo
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
          : const Icon(Icons.send),
      label: Text(_enviando ? 'Enviando...' : 'Enviar reclamo'),
      onPressed: _enviando ? null : _enviarReclamo,
    );
  }

  // Pide el permiso y, si lo da, abre la cámara (ver utils/foto_util.dart)
  Future<void> _tomarFoto() async {
    final foto = await tomarFotoConPermiso(
      context,
      motivo: 'Necesitamos la cámara para sacar la foto del problema',
    );
    if (foto == null || !mounted) return;

    setState(() {
      _foto = foto;
    });
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

    if (_foto == null) {
      _avisar('Sacá una foto del problema');
      return;
    }

    if (_ubicacion == null) {
      _avisar('Esperá a que se cargue la ubicación del problema');
      return;
    }

    setState(() => _enviando = true);

    try {
      await reclamosProvider.crearReclamo(
        categoriaId: widget.categoria.id,
        barrioId: _barrioSeleccionado!,
        descripcion: _descripcion.trim(),
        foto: _foto!,
        latitud: _ubicacion!.latitude,
        longitud: _ubicacion!.longitude,
      );
    } on ReclamoException catch (e) {
      // Aviso en la barra de notificaciones del celular
      NotificationService().showInstantNotification(
        id: 2,
        title: 'No se pudo enviar el reclamo',
        body: e.mensaje,
      );

      if (!mounted) return;
      setState(() => _enviando = false);
      _mostrarError(e.mensaje);
      return;
    }

    // Busco el nombre del barrio elegido para mostrarlo en el mensaje
    final barrios = await _barrios;
    final nombreBarrio = barrios
        .firstWhere((b) => b.id == _barrioSeleccionado)
        .nombre;

    // Aviso en la barra de notificaciones del celular
    NotificationService().showInstantNotification(
      id: 1,
      title: 'Reclamo enviado',
      body:
          'Tu reclamo de "${widget.categoria.nombre}" en $nombreBarrio '
          'quedó pendiente.',
    );

    if (!mounted) return;
    setState(() => _enviando = false);

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
                'Tu reclamo de "${widget.categoria.nombre}" en $nombreBarrio '
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

  // Si falló el envío, el formulario queda como estaba para reintentar
  void _mostrarError(String mensaje) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: const Text('No se pudo enviar'),
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

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }
}

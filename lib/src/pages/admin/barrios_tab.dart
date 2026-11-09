import 'package:flutter/material.dart';

import 'package:atencion_ciudadana/src/models/barrio_model.dart';
import 'package:atencion_ciudadana/src/pages/admin/barrio_form_dialog.dart';
import 'package:atencion_ciudadana/src/providers/admin_provider.dart';
import 'package:atencion_ciudadana/src/widgets/ancho_maximo.dart';

// Pestaña Barrios: el admin los crea, les cambia el nombre y los
// activa o desactiva. Un barrio desactivado no aparece en el registro
// ni en los reclamos nuevos, pero sus reclamos viejos se conservan.
class BarriosTab extends StatefulWidget {
  const BarriosTab({super.key});

  @override
  State<BarriosTab> createState() => _BarriosTabState();
}

class _BarriosTabState extends State<BarriosTab> {
  late Future<List<BarrioModel>> _barrios = adminProvider.barrios();

  Future<void> _recargar() async {
    setState(() {
      _barrios = adminProvider.barrios();
    });
    await _barrios;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crear,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Nuevo barrio'),
      ),
      body: AnchoMaximo(
        ancho: 700,
        child: RefreshIndicator(
          onRefresh: _recargar,
          child: FutureBuilder<List<BarrioModel>>(
            future: _barrios,
            builder: (context, snapshot) {
              final List<Widget> items = [];

              if (snapshot.hasError) {
                items.add(
                  _crearMensaje(
                    'No se pudieron cargar los barrios. Deslizá hacia abajo para reintentar.',
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
                items.add(_crearMensaje('Todavía no hay barrios cargados.'));
              } else {
                items.addAll(snapshot.data!.map(_crearTarjeta));
              }

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: items,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _crearTarjeta(BarrioModel barrio) {
    final colores = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
        leading: CircleAvatar(
          backgroundColor: barrio.activo
              ? colores.primaryContainer
              : Colors.grey.shade300,
          child: Icon(
            Icons.location_city,
            color: barrio.activo ? colores.primary : Colors.grey,
          ),
        ),
        title: Text(
          barrio.nombre,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: barrio.activo ? null : Colors.grey,
          ),
        ),
        subtitle: Text(barrio.activo ? 'Activo' : 'Desactivado'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Editar nombre',
              icon: const Icon(Icons.edit),
              onPressed: () => _editar(barrio),
            ),
            Switch(
              value: barrio.activo,
              onChanged: (valor) => _cambiarEstado(barrio, valor),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _crear() async {
    final creado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BarrioFormDialog(),
    );
    if (creado == true) {
      _avisar('Barrio creado');
      _recargar();
    }
  }

  Future<void> _editar(BarrioModel barrio) async {
    final editado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BarrioFormDialog(barrio: barrio),
    );
    if (editado == true) {
      _avisar('Barrio actualizado');
      _recargar();
    }
  }

  Future<void> _cambiarEstado(BarrioModel barrio, bool activo) async {
    try {
      await adminProvider.cambiarEstadoBarrio(barrio.id, activo);
      _avisar(
        activo
            ? '${barrio.nombre} fue activado'
            : '${barrio.nombre} fue desactivado: ya no aparece para elegir',
      );
      _recargar();
    } on AdminException catch (e) {
      _avisar(e.mensaje);
    }
  }

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Widget _crearMensaje(String texto) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
      ),
    );
  }
}

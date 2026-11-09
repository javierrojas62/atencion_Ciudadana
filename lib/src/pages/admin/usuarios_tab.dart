import 'package:flutter/material.dart';

import 'package:atencion_ciudadana/src/models/usuario_model.dart';
import 'package:atencion_ciudadana/src/pages/admin/usuario_form_dialog.dart';
import 'package:atencion_ciudadana/src/providers/admin_provider.dart';
import 'package:atencion_ciudadana/src/widgets/ancho_maximo.dart';

// Pestaña Usuarios: lista de vecinos y operarios.
// El admin los crea, los edita y los activa o desactiva (no se eliminan).
class UsuariosTab extends StatefulWidget {
  const UsuariosTab({super.key});

  @override
  State<UsuariosTab> createState() => _UsuariosTabState();
}

class _UsuariosTabState extends State<UsuariosTab> {
  late Future<List<UsuarioModel>> _usuarios = adminProvider.usuarios();

  // 'todos', 'vecino' u 'operario'
  String _filtro = 'todos';

  Future<void> _recargar() async {
    setState(() {
      _usuarios = adminProvider.usuarios();
    });
    await _usuarios;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crear,
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo usuario'),
      ),
      body: AnchoMaximo(
        child: RefreshIndicator(
          onRefresh: _recargar,
          child: FutureBuilder<List<UsuarioModel>>(
            future: _usuarios,
            builder: (context, snapshot) {
              final List<Widget> items = [_crearFiltro()];

              if (snapshot.hasError) {
                items.add(
                  _crearMensaje(
                    'No se pudieron cargar los usuarios. Deslizá hacia abajo para reintentar.',
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
                final usuarios = snapshot.data!
                    .where((u) => _filtro == 'todos' || u.rol == _filtro)
                    .toList();

                if (usuarios.isEmpty) {
                  items.add(_crearMensaje('No hay usuarios para mostrar.'));
                } else {
                  items.add(_crearLista(usuarios));
                }
              }

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                // Espacio abajo para que el botón flotante no tape el último
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: items,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _crearFiltro() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'todos', label: Text('Todos')),
          ButtonSegment(value: 'vecino', label: Text('Vecinos')),
          ButtonSegment(value: 'operario', label: Text('Operarios')),
        ],
        selected: {_filtro},
        onSelectionChanged: (seleccion) {
          setState(() => _filtro = seleccion.first);
        },
      ),
    );
  }

  // En pantalla ancha (Chrome) muestro una tabla;
  // en el celular, una tarjeta por usuario
  Widget _crearLista(List<UsuarioModel> usuarios) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 700) {
          return _crearTabla(usuarios);
        }
        return Column(children: usuarios.map(_crearTarjeta).toList());
      },
    );
  }

  Widget _crearTabla(List<UsuarioModel> usuarios) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Nombre')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Rol')),
            DataColumn(label: Text('Barrio')),
            DataColumn(label: Text('Activo')),
            DataColumn(label: Text('')),
          ],
          rows: usuarios
              .map(
                (u) => DataRow(
                  cells: [
                    DataCell(Text(u.nombreCompleto)),
                    DataCell(Text(u.email)),
                    DataCell(_crearEtiquetaRol(u)),
                    DataCell(Text(u.barrioNombre ?? '-')),
                    DataCell(
                      Switch(
                        value: u.activo,
                        onChanged: (valor) => _cambiarEstado(u, valor),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        tooltip: 'Editar',
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editar(u),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _crearTarjeta(UsuarioModel usuario) {
    final colores = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        leading: CircleAvatar(
          backgroundColor: usuario.activo
              ? colores.primaryContainer
              : Colors.grey.shade300,
          child: Icon(
            usuario.esVecino ? Icons.person : Icons.engineering,
            color: usuario.activo ? colores.primary : Colors.grey,
          ),
        ),
        title: Text(
          usuario.nombreCompleto,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: usuario.activo ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(usuario.email),
            const SizedBox(height: 4),
            Row(
              children: [
                _crearEtiquetaRol(usuario),
                if (usuario.barrioNombre != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      usuario.barrioNombre!,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit),
              onPressed: () => _editar(usuario),
            ),
            Switch(
              value: usuario.activo,
              onChanged: (valor) => _cambiarEstado(usuario, valor),
            ),
          ],
        ),
      ),
    );
  }

  // Etiqueta de color con el rol
  Widget _crearEtiquetaRol(UsuarioModel usuario) {
    final color = usuario.esVecino ? Colors.teal : Colors.indigo;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        usuario.rolTexto,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  Future<void> _crear() async {
    final creado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const UsuarioFormDialog(),
    );
    if (creado == true) {
      _avisar('Usuario creado');
      _recargar();
    }
  }

  Future<void> _editar(UsuarioModel usuario) async {
    final editado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UsuarioFormDialog(usuario: usuario),
    );
    if (editado == true) {
      _avisar('Cambios guardados');
      _recargar();
    }
  }

  Future<void> _cambiarEstado(UsuarioModel usuario, bool activo) async {
    try {
      await adminProvider.cambiarEstadoUsuario(usuario.id, activo);
      _avisar(
        activo
            ? '${usuario.nombreCompleto} fue activado'
            : '${usuario.nombreCompleto} fue desactivado y ya no puede entrar',
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

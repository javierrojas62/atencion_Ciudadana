import 'package:flutter/material.dart';

import 'package:atencion_ciudadana/src/models/barrio_model.dart';
import 'package:atencion_ciudadana/src/models/usuario_model.dart';
import 'package:atencion_ciudadana/src/providers/admin_provider.dart';
import 'package:atencion_ciudadana/src/providers/barrios_provider.dart';

// Formulario para crear o editar un usuario.
// - Sin usuario: lo crea (eligiendo si es vecino u operario).
// - Con usuario: lo edita. El rol y el email no se pueden cambiar.
// Devuelve true al cerrarse si se guardó algo.
class UsuarioFormDialog extends StatefulWidget {
  final UsuarioModel? usuario;

  const UsuarioFormDialog({super.key, this.usuario});

  @override
  State<UsuarioFormDialog> createState() => _UsuarioFormDialogState();
}

class _UsuarioFormDialogState extends State<UsuarioFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final _nombreController = TextEditingController(
    text: widget.usuario?.nombre,
  );
  late final _apellidoController = TextEditingController(
    text: widget.usuario?.apellido,
  );
  late final _parcelaController = TextEditingController(
    text: widget.usuario?.parcela,
  );
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late String _rol = widget.usuario?.rol ?? 'vecino';
  late int? _barrioId = widget.usuario?.barrioId;

  // Solo los barrios activos, igual que en el registro
  late final Future<List<BarrioModel>> _barrios = barriosProvider
      .cargarActivos();

  bool _guardando = false;
  String? _error;

  bool get _editando => widget.usuario != null;
  bool get _esVecino => _rol == 'vecino';

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _parcelaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      title: Text(_editando ? 'Editar usuario' : 'Nuevo usuario'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _crearRol(),
                const SizedBox(height: 16),
                _crearCampo(_nombreController, 'Nombre', Icons.person),
                const SizedBox(height: 12),
                _crearCampo(
                  _apellidoController,
                  'Apellido',
                  Icons.person_outline,
                ),
                const SizedBox(height: 12),

                // Email y contraseña solo al crear
                if (_editando)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.email),
                    title: Text(widget.usuario!.email),
                    subtitle: const Text('El email no se puede cambiar'),
                  )
                else ...[
                  _crearEmail(),
                  const SizedBox(height: 12),
                  _crearPassword(),
                ],

                // Barrio y parcela solo para vecinos
                if (_esVecino) ...[
                  const SizedBox(height: 12),
                  _crearDropdownBarrios(),
                  const SizedBox(height: 12),
                  _crearCampo(
                    _parcelaController,
                    'Número de parcela',
                    Icons.home,
                  ),
                ],

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }

  // Al crear se elige el rol; al editar solo se muestra (no se cambia)
  Widget _crearRol() {
    if (_editando) {
      return Text(
        'Rol: ${widget.usuario!.rolTexto}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
    }

    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'vecino',
          label: Text('Vecino'),
          icon: Icon(Icons.person),
        ),
        ButtonSegment(
          value: 'operario',
          label: Text('Operario'),
          icon: Icon(Icons.engineering),
        ),
      ],
      selected: {_rol},
      onSelectionChanged: (seleccion) {
        setState(() => _rol = seleccion.first);
      },
    );
  }

  Widget _crearCampo(
    TextEditingController controller,
    String label,
    IconData icono,
  ) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icono)),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Completá este campo';
        }
        return null;
      },
    );
  }

  Widget _crearEmail() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(Icons.email),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingresá el email';
        }
        if (!value.contains('@')) {
          return 'El email no es válido';
        }
        return null;
      },
    );
  }

  Widget _crearPassword() {
    return TextFormField(
      controller: _passwordController,
      decoration: const InputDecoration(
        labelText: 'Contraseña inicial',
        helperText: 'Mínimo 6 caracteres. Pasásela al usuario.',
        prefixIcon: Icon(Icons.lock),
      ),
      validator: (value) {
        if (value == null || value.length < 6) {
          return 'Mínimo 6 caracteres';
        }
        return null;
      },
    );
  }

  Widget _crearDropdownBarrios() {
    return FutureBuilder<List<BarrioModel>>(
      future: _barrios,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(
            'No se pudieron cargar los barrios.',
            style: TextStyle(color: Colors.red),
          );
        }

        final barrios = snapshot.data ?? [];

        // Si el barrio del vecino fue desactivado no está en la lista:
        // en ese caso hay que elegir otro
        final existe = barrios.any((b) => b.id == _barrioId);

        return DropdownButtonFormField<int>(
          // La key hace que se redibuje cuando llegan los barrios
          key: ValueKey(barrios.length),
          initialValue: existe ? _barrioId : null,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: barrios.isEmpty ? 'Cargando barrios...' : 'Barrio',
            prefixIcon: const Icon(Icons.location_on),
          ),
          items: barrios
              .map(
                (barrio) => DropdownMenuItem(
                  value: barrio.id,
                  child: Text(barrio.nombre),
                ),
              )
              .toList(),
          onChanged: (valor) => setState(() => _barrioId = valor),
          validator: (valor) => valor == null ? 'Elegí el barrio' : null,
        );
      },
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
      _error = null;
    });

    final nombre = _nombreController.text.trim();
    final apellido = _apellidoController.text.trim();
    final parcela = _parcelaController.text.trim();

    try {
      if (_editando) {
        await adminProvider.editarUsuario(
          id: widget.usuario!.id,
          nombre: nombre,
          apellido: apellido,
          barrioId: _esVecino ? _barrioId : null,
          parcela: _esVecino ? parcela : null,
        );
      } else if (_esVecino) {
        await adminProvider.crearVecino(
          nombre: nombre,
          apellido: apellido,
          email: _emailController.text.trim(),
          password: _passwordController.text,
          barrioId: _barrioId!,
          parcela: parcela,
        );
      } else {
        await adminProvider.crearOperario(
          nombre: nombre,
          apellido: apellido,
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AdminException catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = e.mensaje;
      });
    }
  }
}

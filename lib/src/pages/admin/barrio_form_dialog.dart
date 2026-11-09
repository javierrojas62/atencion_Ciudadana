import 'package:flutter/material.dart';

import 'package:atencion_ciudadana/src/models/barrio_model.dart';
import 'package:atencion_ciudadana/src/providers/admin_provider.dart';

// Formulario para crear un barrio o cambiarle el nombre.
// Devuelve true al cerrarse si se guardó algo.
class BarrioFormDialog extends StatefulWidget {
  final BarrioModel? barrio;

  const BarrioFormDialog({super.key, this.barrio});

  @override
  State<BarrioFormDialog> createState() => _BarrioFormDialogState();
}

class _BarrioFormDialogState extends State<BarrioFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreController = TextEditingController(
    text: widget.barrio?.nombre,
  );

  bool _guardando = false;
  String? _error;

  bool get _editando => widget.barrio != null;

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      title: Text(_editando ? 'Editar barrio' : 'Nuevo barrio'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre del barrio',
                  hintText: 'Ej: Barrio Los Álamos',
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Escribí el nombre del barrio';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
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

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
      _error = null;
    });

    final nombre = _nombreController.text.trim();

    try {
      if (_editando) {
        await adminProvider.editarBarrio(widget.barrio!.id, nombre);
      } else {
        await adminProvider.crearBarrio(nombre);
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

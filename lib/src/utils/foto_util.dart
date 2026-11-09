import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:atencion_ciudadana/src/services/camara_service.dart';

// Pide el permiso de cámara y, si lo da, saca la foto.
// Devuelve los bytes de la foto, o null si no se pudo o canceló.
// La usan el vecino (foto del problema) y el operario (foto del arreglo).
Future<Uint8List?> tomarFotoConPermiso(
  BuildContext context, {
  String motivo = 'Necesitamos la cámara para sacar la foto',
}) async {
  final permiso = await camaraService.pedirPermisoCamara();
  if (!context.mounted) return null;

  if (permiso == ResultadoPermiso.denegadoPermanente) {
    _mostrarPermisoBloqueado(context);
    return null;
  }

  if (permiso == ResultadoPermiso.denegado) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(motivo)));
    return null;
  }

  final foto = await camaraService.tomarFoto();

  // Si canceló la cámara no hago nada
  if (foto == null) return null;

  return foto.readAsBytes();
}

// El usuario rechazó el permiso varias veces: ya no se puede volver a
// pedir, así que le ofrezco ir a los ajustes del celular
void _mostrarPermisoBloqueado(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        title: const Text('Permiso de cámara bloqueado'),
        content: const Text(
          'Para sacar la foto tenés que habilitar la cámara '
          'desde los ajustes del celular.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              camaraService.abrirAjustes();
            },
            child: const Text('Abrir ajustes'),
          ),
        ],
      );
    },
  );
}

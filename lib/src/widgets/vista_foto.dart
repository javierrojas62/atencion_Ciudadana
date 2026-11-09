import 'dart:typed_data';

import 'package:flutter/material.dart';

// Recuadro para la foto: si todavía no hay foto muestra un botón para
// sacarla, y si ya hay, la muestra con la opción de sacar otra.
// Uso Image.memory (bytes) en lugar de Image.file porque así funciona
// también en el navegador.
class VistaFoto extends StatelessWidget {
  final Uint8List? foto;
  final VoidCallback onTomarFoto;
  final String texto;

  const VistaFoto({
    super.key,
    required this.foto,
    required this.onTomarFoto,
    this.texto = 'Tocá para sacar una foto',
  });

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    // Todavía no sacó la foto
    if (foto == null) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTomarFoto,
          child: SizedBox(
            height: 160,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, size: 50, color: colores.primary),
                  const SizedBox(height: 8),
                  Text(texto, style: TextStyle(color: colores.primary)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Ya tiene foto: la muestro
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Image.memory(
            foto!,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          TextButton.icon(
            onPressed: onTomarFoto,
            icon: const Icon(Icons.refresh),
            label: const Text('Sacar otra'),
          ),
        ],
      ),
    );
  }
}

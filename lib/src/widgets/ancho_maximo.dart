import 'package:flutter/material.dart';

// Limita el ancho del contenido y lo centra.
// En el celular no cambia nada; en Chrome evita que las listas
// se estiren de punta a punta de la pantalla.
class AnchoMaximo extends StatelessWidget {
  final Widget child;
  final double ancho;

  const AnchoMaximo({super.key, required this.child, this.ancho = 1000});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: ancho),
        child: child,
      ),
    );
  }
}

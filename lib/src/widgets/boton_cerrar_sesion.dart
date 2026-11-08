import 'package:atencion_ciudadana/src/models/auth_provider.dart';
import 'package:flutter/material.dart';

// Botón de cerrar sesión para el AppBar de cualquier pantalla.
// Cierra la sesión en Supabase y vuelve al inicio borrando el historial.
class BotonCerrarSesion extends StatelessWidget {
  const BotonCerrarSesion({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Cerrar sesión',
      onPressed: () async {
        await authProvider.cerrarSesion();
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      },
    );
  }
}
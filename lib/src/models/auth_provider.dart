import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:atencion_ciudadana/src/models/perfil_model.dart';

// Error con un mensaje listo para mostrarle al usuario
class LoginException implements Exception {
  final String mensaje;
  LoginException(this.mensaje);
}

// Provider de autenticación: iniciar sesión, leer el perfil y salir.
class AuthProvider {
  final _supabase = Supabase.instance.client;

  Future<PerfilModel> iniciarSesion(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw LoginException(_traducirError(e.message));
    } catch (_) {
      throw LoginException('No se pudo conectar. Revisá tu conexión.');
    }

    final perfil = await obtenerPerfil();

    // Si el admin lo desactivó, no lo dejo entrar
    if (!perfil.activo) {
      await cerrarSesion();
      throw LoginException(
        'Tu cuenta está desactivada. Comunicate con la municipalidad.',
      );
    }

    return perfil;
  }

  // Lee de la tabla perfiles los datos del usuario logueado
  Future<PerfilModel> obtenerPerfil() async {
    try {
      final datos = await _supabase
          .from('perfiles')
          .select('id, email, nombre, apellido, rol, activo')
          .eq('id', _supabase.auth.currentUser!.id)
          .single();
      return PerfilModel.fromJson(datos);
    } catch (_) {
      await cerrarSesion();
      throw LoginException('No se pudieron cargar los datos de tu cuenta.');
    }
  }

  Future<void> cerrarSesion() async {
    await _supabase.auth.signOut();
  }

  // Supabase devuelve los errores en inglés, acá los paso a castellano
  String _traducirError(String mensaje) {
    if (mensaje.contains('Invalid login credentials')) {
      return 'El email o la contraseña son incorrectos.';
    }
    if (mensaje.contains('Email not confirmed')) {
      return 'Todavía no confirmaste tu email.';
    }
    return 'No se pudo iniciar sesión. Intentá de nuevo.';
  }
}

// Instancia que uso desde las pantallas (igual que categoriasProvider)
final authProvider = AuthProvider();

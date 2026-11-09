import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:atencion_ciudadana/src/models/perfil_model.dart';

// Error con un mensaje listo para mostrarle al usuario
// (lo uso tanto en el login como en el registro)
class LoginException implements Exception {
  final String mensaje;
  LoginException(this.mensaje);
}

// Provider de autenticación: registrarse, iniciar sesión, leer el perfil y salir.
class AuthProvider {
  final _supabase = Supabase.instance.client;

  // Perfil del usuario logueado, para usarlo en cualquier pantalla
  PerfilModel? perfilActual;

  Future<PerfilModel> iniciarSesion(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
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

  // Crea la cuenta de un vecino.
  // Los datos extra viajan como metadata y la base arma el perfil sola,
  // siempre con rol vecino (nadie puede elegir su rol al registrarse).
  // Devuelve null si Supabase pide confirmar el email antes de entrar.
  Future<PerfilModel?> registrarVecino({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
    required int barrioId,
    required String parcela,
  }) async {
    try {
      final resp = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'nombre': nombre,
          'apellido': apellido,
          'barrio_id': barrioId,
          'parcela': parcela,
        },
      );

      // Sin sesión = Supabase está esperando la confirmación del email
      if (resp.session == null) return null;
    } on AuthException catch (e) {
      throw LoginException(_traducirError(e.message));
    } catch (_) {
      throw LoginException('No se pudo conectar. Revisá tu conexión.');
    }

    return obtenerPerfil();
  }

  // Lee de la tabla perfiles los datos del usuario logueado
  Future<PerfilModel> obtenerPerfil() async {
    try {
      final datos = await _supabase
          .from('perfiles')
          .select('id, email, nombre, apellido, rol, activo, barrio_id')
          .eq('id', _supabase.auth.currentUser!.id)
          .single();
      perfilActual = PerfilModel.fromJson(datos);
      return perfilActual!;
    } catch (_) {
      await cerrarSesion();
      throw LoginException('No se pudieron cargar los datos de tu cuenta.');
    }
  }

  Future<void> cerrarSesion() async {
    perfilActual = null;
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
    if (mensaje.contains('already registered')) {
      return 'Ya existe una cuenta con ese email.';
    }
    if (mensaje.contains('Password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (mensaje.contains('invalid') && mensaje.contains('mail')) {
      return 'El email no es válido.';
    }
    if (mensaje.contains('Database error saving new user')) {
      // La base rechazó el registro (falta barrio, parcela, nombre, etc.)
      return 'No se pudo crear la cuenta. Revisá que todos los datos estén completos.';
    }
    return 'Ocurrió un error. Intentá de nuevo.';
  }
}

// Instancia que uso desde las pantallas (igual que categoriasProvider)
final authProvider = AuthProvider();

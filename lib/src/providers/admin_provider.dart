import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:atencion_ciudadana/src/config/supabase_config.dart';
import 'package:atencion_ciudadana/src/models/barrio_model.dart';
import 'package:atencion_ciudadana/src/models/dashboard_model.dart';
import 'package:atencion_ciudadana/src/models/usuario_model.dart';

// Error con un mensaje listo para mostrarle al admin
class AdminException implements Exception {
  final String mensaje;
  AdminException(this.mensaje);
}

// Provider del administrador: dashboard, usuarios y barrios.
// Nunca elimina nada: usuarios y barrios se desactivan.
class AdminProvider {
  final _supabase = Supabase.instance.client;

  // ---------------------------------------------------------------------
  // DASHBOARD
  // ---------------------------------------------------------------------

  Future<ResumenModel> resumen() async {
    final datos = await _supabase.from('resumen_reclamos').select().single();
    return ResumenModel.fromJson(datos);
  }

  Future<List<OperarioResueltosModel>> resueltosPorOperario() async {
    final datos = await _supabase.from('resueltos_por_operario').select();
    return datos.map((o) => OperarioResueltosModel.fromJson(o)).toList();
  }

  // Últimos 20 reclamos resueltos, con el operario que los resolvió.
  // Como reclamos tiene dos relaciones con perfiles (vecino y operario),
  // le indico a Supabase cuál usar con el nombre de la relación.
  Future<List<ReclamoResueltoModel>> ultimosResueltos() async {
    final datos = await _supabase
        .from('reclamos')
        .select(
          'id, resuelto_en, hash_inicial, hash_cierre, '
          'categorias(nombre), barrios(nombre), '
          'operario:perfiles!reclamos_operario_id_fkey(nombre, apellido)',
        )
        .eq('estado', 'resuelto')
        .order('resuelto_en', ascending: false)
        .limit(20);

    return datos.map((r) => ReclamoResueltoModel.fromJson(r)).toList();
  }

  // ---------------------------------------------------------------------
  // USUARIOS (solo vecinos y operarios)
  // ---------------------------------------------------------------------

  Future<List<UsuarioModel>> usuarios() async {
    final datos = await _supabase
        .from('perfiles')
        .select(
          'id, email, nombre, apellido, rol, activo, barrio_id, parcela, '
          'barrios(nombre)',
        )
        .neq('rol', 'admin')
        .order('apellido');

    return datos.map((u) => UsuarioModel.fromJson(u)).toList();
  }

  // Crear un operario: primero autorizo el email (solo el admin puede)
  // y después creo la cuenta. Al registrarse, la base ve la
  // autorización y lo crea como operario.
  Future<void> crearOperario({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.rpc(
        'admin_autorizar_operario',
        params: {'p_email': email},
      );
    } on PostgrestException catch (e) {
      // Los mensajes los escribí en castellano en la base
      throw AdminException(e.message);
    } catch (_) {
      throw AdminException('No se pudo conectar. Revisá tu conexión.');
    }

    await _crearCuenta(
      email: email,
      password: password,
      datos: {'nombre': nombre, 'apellido': apellido},
    );
  }

  // Crear un vecino: igual que cuando se registra solo desde la app
  Future<void> crearVecino({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
    required int barrioId,
    required String parcela,
  }) async {
    await _crearCuenta(
      email: email,
      password: password,
      datos: {
        'nombre': nombre,
        'apellido': apellido,
        'barrio_id': barrioId,
        'parcela': parcela,
      },
    );
  }

  // Crea la cuenta con una SEGUNDA conexión a Supabase.
  // Si usara la conexión normal, Supabase cerraría la sesión del admin
  // y lo dejaría logueado como el usuario nuevo. Esta conexión no guarda
  // la sesión en el celular y la cierro al terminar.
  Future<void> _crearCuenta({
    required String email,
    required String password,
    required Map<String, dynamic> datos,
  }) async {
    final conexionTemporal = SupabaseClient(
      SupabaseConfig.url,
      SupabaseConfig.publishableKey,
      authOptions: const AuthClientOptions(
        authFlowType: AuthFlowType.implicit,
        autoRefreshToken: false,
      ),
    );

    try {
      await conexionTemporal.auth.signUp(
        email: email,
        password: password,
        data: datos,
      );
    } on AuthException catch (e) {
      throw AdminException(_traducirError(e.message));
    } catch (_) {
      throw AdminException('No se pudo crear el usuario. Revisá tu conexión.');
    } finally {
      await conexionTemporal.dispose();
    }
  }

  // Editar datos de un usuario. El rol y el email no se pueden cambiar.
  Future<void> editarUsuario({
    required String id,
    required String nombre,
    required String apellido,
    int? barrioId,
    String? parcela,
  }) async {
    final Map<String, dynamic> cambios = {
      'nombre': nombre,
      'apellido': apellido,
    };
    // Barrio y parcela solo para vecinos
    if (barrioId != null) cambios['barrio_id'] = barrioId;
    if (parcela != null) cambios['parcela'] = parcela;

    try {
      await _supabase.from('perfiles').update(cambios).eq('id', id);
    } catch (_) {
      throw AdminException('No se pudieron guardar los cambios.');
    }
  }

  // Activar o desactivar (un usuario desactivado no puede entrar)
  Future<void> cambiarEstadoUsuario(String id, bool activo) async {
    try {
      await _supabase.from('perfiles').update({'activo': activo}).eq('id', id);
    } catch (_) {
      throw AdminException('No se pudo cambiar el estado del usuario.');
    }
  }

  // ---------------------------------------------------------------------
  // BARRIOS
  // ---------------------------------------------------------------------

  // Todos los barrios, activos y desactivados
  Future<List<BarrioModel>> barrios() async {
    final datos = await _supabase
        .from('barrios')
        .select('id, nombre, activo')
        .order('nombre');

    return datos.map((b) => BarrioModel.fromJson(b)).toList();
  }

  Future<void> crearBarrio(String nombre) async {
    try {
      // Hay un solo departamento (Rawson): los barrios nuevos van ahí
      final departamento = await _supabase
          .from('departamentos')
          .select('id')
          .limit(1)
          .single();

      await _supabase.from('barrios').insert({
        'departamento_id': departamento['id'],
        'nombre': nombre,
      });
    } on PostgrestException catch (e) {
      throw AdminException(_errorBarrio(e));
    } catch (_) {
      throw AdminException('No se pudo guardar el barrio.');
    }
  }

  Future<void> editarBarrio(int id, String nombre) async {
    try {
      await _supabase.from('barrios').update({'nombre': nombre}).eq('id', id);
    } on PostgrestException catch (e) {
      throw AdminException(_errorBarrio(e));
    } catch (_) {
      throw AdminException('No se pudo guardar el barrio.');
    }
  }

  // Desactivado = no aparece en el registro ni en los reclamos nuevos
  Future<void> cambiarEstadoBarrio(int id, bool activo) async {
    try {
      await _supabase.from('barrios').update({'activo': activo}).eq('id', id);
    } catch (_) {
      throw AdminException('No se pudo cambiar el estado del barrio.');
    }
  }

  // ---------------------------------------------------------------------
  // MENSAJES DE ERROR
  // ---------------------------------------------------------------------

  // 23505 = la base rechazó un dato repetido (dos barrios con el mismo nombre)
  String _errorBarrio(PostgrestException e) {
    if (e.code == '23505') return 'Ya existe un barrio con ese nombre.';
    return 'No se pudo guardar el barrio.';
  }

  String _traducirError(String mensaje) {
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
      return 'No se pudo crear el usuario. Revisá que todos los datos estén completos.';
    }
    return 'No se pudo crear el usuario. Intentá de nuevo.';
  }
}

// Instancia que uso desde las pantallas
final adminProvider = AdminProvider();

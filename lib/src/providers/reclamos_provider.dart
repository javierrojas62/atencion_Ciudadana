import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:atencion_ciudadana/src/models/barrio_pendientes_model.dart';
import 'package:atencion_ciudadana/src/models/reclamo_model.dart';

// Error con un mensaje listo para mostrarle al usuario
class ReclamoException implements Exception {
  final String mensaje;
  ReclamoException(this.mensaje);
}

// Provider de reclamos: todo lo que tiene que ver con la tabla reclamos
// y las fotos en Storage.
class ReclamosProvider {
  final _supabase = Supabase.instance.client;

  // Bucket de Storage donde se guardan las fotos
  static const String _bucket = 'reclamos';

  // Columnas que trae cada reclamo, junto con el nombre de su
  // categoría y de su barrio (Supabase une las tablas solo)
  static const String _columnas =
      'id, descripcion, foto_url, latitud, longitud, creado_en, '
      'categorias(nombre, icono), barrios(nombre)';

  // ---------------------------------------------------------------------
  // VECINO
  // ---------------------------------------------------------------------

  // Crea un reclamo nuevo. Pasos:
  //  1) sube la foto a Storage, dentro de la carpeta del vecino
  //  2) guarda el reclamo con la dirección (URL) de esa foto
  // El estado, la fecha y el hash los completa la base sola.
  Future<void> crearReclamo({
    required int categoriaId,
    required int barrioId,
    required String descripcion,
    required Uint8List foto,
    required double latitud,
    required double longitud,
  }) async {
    final vecinoId = _supabase.auth.currentUser!.id;

    // 1) Subir la foto: reclamos/<id_del_vecino>/<fecha>.jpg
    final String fotoUrl;
    try {
      fotoUrl = await _subirFoto(vecinoId, foto);
    } catch (_) {
      throw ReclamoException('No se pudo subir la foto. Revisá tu conexión.');
    }

    // 2) Guardar el reclamo.
    // No pido que me devuelva la fila (.select()) porque el vecino
    // no tiene permiso para leer reclamos: no ve historial.
    try {
      await _supabase.from('reclamos').insert({
        'vecino_id': vecinoId,
        'categoria_id': categoriaId,
        'barrio_id': barrioId,
        'descripcion': descripcion,
        'foto_url': fotoUrl,
        'latitud': latitud,
        'longitud': longitud,
      });
    } catch (_) {
      throw ReclamoException('No se pudo guardar el reclamo. Intentá de nuevo.');
    }
  }

  // ---------------------------------------------------------------------
  // OPERARIO
  // ---------------------------------------------------------------------

  // Barrios que tienen al menos un reclamo pendiente, con la cantidad
  Future<List<BarrioPendientesModel>> barriosConPendientes() async {
    final datos = await _supabase.from('barrios_con_pendientes').select();
    return datos.map((b) => BarrioPendientesModel.fromJson(b)).toList();
  }

  // Reclamos pendientes de un barrio, del más viejo al más nuevo
  Future<List<ReclamoModel>> pendientesDeBarrio(int barrioId) async {
    final datos = await _supabase
        .from('reclamos')
        .select(_columnas)
        .eq('barrio_id', barrioId)
        .eq('estado', 'pendiente')
        .order('creado_en');

    return datos.map((r) => ReclamoModel.fromJson(r)).toList();
  }

  // El operario marca el reclamo como realizado. Pasos:
  //  1) sube la foto del arreglo a su carpeta
  //  2) pasa el reclamo a resuelto con esa foto y la observación (opcional)
  // Qué operario lo hizo, la fecha y el hash de cierre los pone la base.
  Future<void> realizarReclamo({
    required int reclamoId,
    required Uint8List fotoArreglo,
    String? observacion,
  }) async {
    final operarioId = _supabase.auth.currentUser!.id;

    final String fotoUrl;
    try {
      fotoUrl = await _subirFoto(operarioId, fotoArreglo);
    } catch (_) {
      throw ReclamoException(
        'No se pudo subir la foto del arreglo. Revisá tu conexión.',
      );
    }

    final texto = observacion?.trim() ?? '';

    final List<dynamic> actualizados;
    try {
      // Solo si sigue pendiente: así dos operarios no cierran el mismo
      actualizados = await _supabase
          .from('reclamos')
          .update({
            'estado': 'resuelto',
            'foto_reparacion_url': fotoUrl,
            'observacion': texto.isEmpty ? null : texto,
          })
          .eq('id', reclamoId)
          .eq('estado', 'pendiente')
          .select('id');
    } catch (_) {
      throw ReclamoException(
        'No se pudo marcar como realizado. Intentá de nuevo.',
      );
    }

    // No se actualizó ninguna fila: otro operario lo cerró antes
    if (actualizados.isEmpty) {
      throw ReclamoException('Este reclamo ya fue resuelto por otro operario.');
    }
  }

  // ---------------------------------------------------------------------
  // FOTOS
  // ---------------------------------------------------------------------

  // Sube una foto a la carpeta del usuario y devuelve su URL pública
  Future<String> _subirFoto(String usuarioId, Uint8List foto) async {
    final nombre = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ruta = '$usuarioId/$nombre';

    await _supabase.storage
        .from(_bucket)
        .uploadBinary(
          ruta,
          foto,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

    return _supabase.storage.from(_bucket).getPublicUrl(ruta);
  }
}

// Instancia que uso desde las pantallas
final reclamosProvider = ReclamosProvider();

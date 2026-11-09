import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

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

  // Sube una foto a la carpeta del usuario y devuelve su URL pública.
  // La va a usar también el operario para la foto de la reparación.
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

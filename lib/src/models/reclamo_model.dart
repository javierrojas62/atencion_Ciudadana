import 'package:latlong2/latlong.dart';

// Reclamo tal como lo ve el operario: con el nombre de la categoría y
// del barrio (Supabase los trae junto con el reclamo).
class ReclamoModel {
  final int id;
  final String categoria;
  final String categoriaIcono;
  final String barrio;
  final String descripcion;
  final String fotoUrl;
  final double latitud;
  final double longitud;
  final DateTime creadoEn;

  ReclamoModel({
    required this.id,
    required this.categoria,
    required this.categoriaIcono,
    required this.barrio,
    required this.descripcion,
    required this.fotoUrl,
    required this.latitud,
    required this.longitud,
    required this.creadoEn,
  });

  factory ReclamoModel.fromJson(Map<String, dynamic> json) {
    // Datos de las tablas relacionadas (pueden venir vacíos si, por
    // ejemplo, la categoría fue desactivada)
    final categoria = json['categorias'] as Map<String, dynamic>?;
    final barrio = json['barrios'] as Map<String, dynamic>?;

    return ReclamoModel(
      id: json['id'],
      categoria: categoria?['nombre'] ?? 'Sin categoría',
      categoriaIcono: categoria?['icono'] ?? '',
      barrio: barrio?['nombre'] ?? '',
      descripcion: json['descripcion'],
      fotoUrl: json['foto_url'],
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      creadoEn: DateTime.parse(json['creado_en']).toLocal(),
    );
  }

  // Punto para el mapa
  LatLng get punto => LatLng(latitud, longitud);

  // Fecha en formato dd/mm/aaaa hh:mm
  String get fecha {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(creadoEn.day)}/${dos(creadoEn.month)}/${creadoEn.year} '
        '${dos(creadoEn.hour)}:${dos(creadoEn.minute)}';
  }
}

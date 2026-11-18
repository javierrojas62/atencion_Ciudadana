import 'package:latlong2/latlong.dart';

// Reclamo con el nombre de la categoría y del barrio (Supabase los trae
// junto con el reclamo). Lo usan el operario (pendientes de un barrio)
// y el vecino (su historial, con los datos del arreglo si se resolvió).
class ReclamoModel {
  final int id;
  final String categoria;
  final String categoriaIcono;
  final String barrio;
  final String descripcion;
  final String? tipoOtro; // solo en la categoría "Otro"
  final String fotoUrl;
  final double latitud;
  final double longitud;
  final DateTime creadoEn;
  final String estado; // 'pendiente' o 'resuelto'

  // Datos del arreglo: solo los tiene si está resuelto
  final String? fotoReparacionUrl;
  final String? observacion;
  final DateTime? resueltoEn;

  ReclamoModel({
    required this.id,
    required this.categoria,
    required this.categoriaIcono,
    required this.barrio,
    required this.descripcion,
    this.tipoOtro,
    required this.fotoUrl,
    required this.latitud,
    required this.longitud,
    required this.creadoEn,
    required this.estado,
    this.fotoReparacionUrl,
    this.observacion,
    this.resueltoEn,
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
      tipoOtro: json['tipo_otro'],
      fotoUrl: json['foto_url'],
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      creadoEn: DateTime.parse(json['creado_en']).toLocal(),
      estado: json['estado'] ?? 'pendiente',
      fotoReparacionUrl: json['foto_reparacion_url'],
      observacion: json['observacion'],
      resueltoEn: json['resuelto_en'] == null
          ? null
          : DateTime.parse(json['resuelto_en']).toLocal(),
    );
  }

  // Título para mostrar en listas y detalles:
  // en "Otro" uso lo que escribió el vecino, en el resto la categoría
  String get titulo => tipoOtro != null ? 'Otro: $tipoOtro' : categoria;

  // Mientras está pendiente el vecino lo puede editar o eliminar
  bool get pendiente => estado == 'pendiente';

  // Punto para el mapa
  LatLng get punto => LatLng(latitud, longitud);

  // Fecha en que se cargó, en formato dd/mm/aaaa hh:mm
  String get fecha => _formatear(creadoEn);

  // Fecha en que se resolvió (vacío si sigue pendiente)
  String get fechaResuelto => resueltoEn == null ? '' : _formatear(resueltoEn!);

  static String _formatear(DateTime f) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(f.day)}/${dos(f.month)}/${f.year} '
        '${dos(f.hour)}:${dos(f.minute)}';
  }
}
